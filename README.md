# Azure App Service Web Apps Professional Lab

## Overview: Core App Service Features and Deployment Patterns

This lab demonstrates essential Azure App Service Web Apps capabilities including creation, configuration, deployment, monitoring, and scaling. Designed for hands-on learning with a focus on understanding each CLI command and its purpose.

> **Learning Approach:** This lab is structured for investigative learning - pause at each CLI command to understand its purpose, parameters, and outcomes before proceeding.

> **Development Methodology:** This comprehensive lab was designed and structured with assistance from Claude 3.5 Sonnet (Anthropic) to ensure adherence to Azure best practices, comprehensive documentation standards, and optimal learning outcomes for hands-on Azure certification preparation. The AI assistance focused on creating well-commented, investigative learning materials that align with modern cloud development practices.

**Goals:**
- Master Azure App Service Web App creation and configuration
- Implement production-ready logging and diagnostics
- Demonstrate deployment automation and best practices
- Configure security settings including TLS
- Implement autoscaling policies
- Understand deployment slots for zero-downtime deployments
- Support AZ-204 certification preparation

---

## Architecture Overview

```
Developer → Azure CLI/Bicep → App Service Plan → Web App → Application Insights
                                    ↓              ↓              ↓
                              Compute Resources  App Settings   Monitoring
                                    ↓              ↓              ↓
                              Scaling Rules    TLS Config    Log Analytics
```

---

## Prerequisites

Before starting, ensure you have:

- **.NET 8 SDK** ([Installation Guide](https://dotnet.microsoft.com/download))
- **Azure CLI** ([Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- **An active Azure subscription**
- **Visual Studio Code** or **Visual Studio 2022** (recommended)
- **Git** (for source control best practices)

---

## Understanding App Service Tiers

Before deployment, understand the service tier implications:

```powershell
# Concept Reference - App Service Pricing Tiers (for investigation):
# Free (F1): Shared compute, 1GB storage, 165MB memory, no custom domains, no deployment slots
# Basic (B1-B3): Dedicated compute, custom domains, manual scaling up to 3 instances
# Standard (S1-S3): Dedicated compute, auto-scaling up to 10 instances, deployment slots
# Premium (P1-P4): Enhanced performance, up to 30 instances, advanced features
# 
# Shared vs Dedicated Compute:
# - Free/Shared: Resources shared with other customers, limited CPU quotas
# - Basic+: Dedicated VM instances, predictable performance
#
# Regional Availability: Not all tiers available in all regions
# Cost Optimization: Use Basic for development, Standard+ for production
```

---

## Step 1: Centralized Configuration

Create the foundational configuration file for consistent, repeatable deployments.

```powershell
# config.ps1
# Centralized configuration promotes maintainability and repeatability

# Resource Configuration
$RG_NAME = "az-204-web-app-lab-rg"              # Resource group for organized resource management
$LOCATION = "westus"                             # Azure region for deployment
$SERVICE_PLAN_NAME = "az-204-web-app-plan"     # App Service Plan name (compute resources)

# Application Configuration  
$WEB_APP_NAME = "Az204WebApp"                   # Internal reference name
$WEB_APP_DISPLAY_NAME = "Az-204 Web App"       # Human-readable display name
$WEB_APP_SERVICE_NAME = "az-204-web-app-svc-20250817AM"  # Must be globally unique
$WEB_PROJECT_FOLDER = "AZ204WebApp"            # Local project directory

# Monitoring and Insights
$APP_INSIGHTS_NAME = "az-204-web-app-insights" # Application Insights for telemetry
$LOG_WORKSPACE_NAME = "az-204-web-app-logs"    # Log Analytics workspace

# Deployment Configuration
$DEPLOYMENT_SLOT_NAME = "staging"               # Staging slot for blue-green deployments
$AUTOSCALE_PROFILE_NAME = "DefaultAutoscale"   # Autoscaling configuration name

# Get current user context for resource ownership
$OWNER_OBJECT_ID = (az ad signed-in-user show --query id -o tsv)

# Subscription handling
if ($env:AZURE_SUBSCRIPTION_ID) {
    $SUBSCRIPTION_ID = $env:AZURE_SUBSCRIPTION_ID
} else {
    $SUBSCRIPTION_ID = (az account show --query id -o tsv)
}

# Display configuration for verification
Write-Host "=== Lab Configuration ===" -ForegroundColor Green
Write-Host "Resource Group: $RG_NAME"
Write-Host "Location: $LOCATION"
Write-Host "Service Plan: $SERVICE_PLAN_NAME"
Write-Host "Web App Service: $WEB_APP_SERVICE_NAME"
Write-Host "Project Folder: $WEB_PROJECT_FOLDER"
Write-Host "Subscription: $SUBSCRIPTION_ID"
Write-Host "Owner: $OWNER_OBJECT_ID"
Write-Host "==============================" -ForegroundColor Green
```

---

## Step 2: Infrastructure as Code with Bicep

Create reusable infrastructure templates for consistent deployments.

```powershell
# 01-create-infrastructure.ps1
# Deploy core infrastructure using Bicep templates

. .\config.ps1

Write-Host "Creating Azure Infrastructure..." -ForegroundColor Yellow

# Create resource group (idempotent operation)
Write-Host "Creating resource group: $RG_NAME" -ForegroundColor Cyan
az group create `
    --name $RG_NAME `
    --location $LOCATION `
    --tags "Environment=Lab" "Purpose=AZ-204-Training" "Owner=$OWNER_OBJECT_ID"

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to create resource group" 
}

# Deploy infrastructure using Bicep template
Write-Host "Deploying infrastructure via Bicep..." -ForegroundColor Cyan
az deployment group create `
    --resource-group $RG_NAME `
    --template-file "infrastructure.bicep" `
    --parameters `
        servicePlanName=$SERVICE_PLAN_NAME `
        webAppName=$WEB_APP_SERVICE_NAME `
        appInsightsName=$APP_INSIGHTS_NAME `
        logWorkspaceName=$LOG_WORKSPACE_NAME `
        location=$LOCATION

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to deploy infrastructure" 
}

Write-Host "Infrastructure created successfully!" -ForegroundColor Green
```

Create the Bicep template for infrastructure:

```bicep
// infrastructure.bicep
// Azure App Service infrastructure template

@description('Name of the App Service Plan')
param servicePlanName string

@description('Name of the Web App')  
param webAppName string

@description('Name of Application Insights')
param appInsightsName string

@description('Name of Log Analytics Workspace')
param logWorkspaceName string

@description('Location for all resources')
param location string = resourceGroup().location

// Log Analytics Workspace for centralized logging
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'  // Pay-per-GB pricing model
    }
    retentionInDays: 30   // Log retention period
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
  tags: {
    Environment: 'Lab'
    Purpose: 'AZ-204-Training'
  }
}

// Application Insights for application performance monitoring
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logWorkspace.id  // Link to Log Analytics
    IngestionMode: 'LogAnalytics'         // Use Log Analytics for data ingestion
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    Environment: 'Lab'
    Purpose: 'AZ-204-Training'
  }
}

// App Service Plan - defines compute resources
resource servicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: servicePlanName
  location: location
  sku: {
    name: 'B1'     // Basic tier - dedicated compute, manual scaling
    tier: 'Basic'  // Supports custom domains, SSL certificates
    size: 'B1'     // 1 core, 1.75GB memory
    family: 'B'    // Basic family
    capacity: 1    // Initial instance count
  }
  properties: {
    reserved: false  // Windows hosting (true = Linux)
  }
  tags: {
    Environment: 'Lab'
    Purpose: 'AZ-204-Training'
  }
}

// Web App - the actual application hosting service
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: servicePlan.id  // Link to App Service Plan
    siteConfig: {
      netFrameworkVersion: 'v8.0'        // .NET 8 runtime
      defaultDocuments: ['Default.htm', 'Default.html', 'index.html']
      httpLoggingEnabled: true            // Enable HTTP request logging
      detailedErrorLoggingEnabled: true   // Enable detailed error pages
      requestTracingEnabled: true         // Enable failed request tracing
      
      // Application settings injected at runtime
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'  // Latest stable Application Insights agent
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
      
      // Security and performance settings
      minTlsVersion: '1.2'               // Enforce TLS 1.2 minimum
      scmMinTlsVersion: '1.2'           // SCM site also uses TLS 1.2
      ftpsState: 'Disabled'             // Disable FTP, use FTPS only
      httpLoggingEnabled: true          // Log HTTP requests
      logsDirectorySizeLimit: 100       // Limit log directory size (MB)
    }
    
    httpsOnly: true  // Redirect HTTP to HTTPS automatically
    clientAffinityEnabled: false  // Disable session affinity for better load balancing
  }
  
  // Enable managed identity for secure Azure service access
  identity: {
    type: 'SystemAssigned'
  }
  
  tags: {
    Environment: 'Lab'
    Purpose: 'AZ-204-Training'
  }
}

// Configure diagnostic settings for comprehensive logging
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'comprehensive-logging'
  scope: webApp
  properties: {
    workspaceId: logWorkspace.id
    
    // Log categories to capture
    logs: [
      {
        category: 'AppServiceHTTPLogs'    // HTTP access logs
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'AppServiceConsoleLogs'  // Console output
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'AppServiceAppLogs'     // Application logs
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'AppServicePlatformLogs' // Platform logs
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    
    // Metrics to collect
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}

// Output important values for use in deployment scripts
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output resourceGroupName string = resourceGroup().name
```

---

## Step 3: Create Sample Application

Generate a sample ASP.NET Core application with integrated monitoring.

```powershell
# 02-create-sample-app.ps1
# Create a sample ASP.NET Core application with monitoring integration

. .\config.ps1

Write-Host "Creating Sample Application..." -ForegroundColor Yellow

# Remove existing project directory if it exists (idempotent)
if (Test-Path $WEB_PROJECT_FOLDER) {
    Write-Warning "Project folder exists. Removing for fresh start..."
    Remove-Item -Recurse -Force $WEB_PROJECT_FOLDER
}

# Create new ASP.NET Core MVC project
Write-Host "Creating ASP.NET Core MVC project..." -ForegroundColor Cyan
dotnet new mvc -n $WEB_PROJECT_FOLDER

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to create ASP.NET Core project" 
}

# Navigate to project directory
Set-Location $WEB_PROJECT_FOLDER

# Add Application Insights SDK for telemetry
Write-Host "Adding Application Insights package..." -ForegroundColor Cyan
dotnet add package Microsoft.ApplicationInsights.AspNetCore

# Add health checks for monitoring endpoints
Write-Host "Adding health checks package..." -ForegroundColor Cyan
dotnet add package Microsoft.Extensions.Diagnostics.HealthChecks

# Add logging enhancements
Write-Host "Adding logging packages..." -ForegroundColor Cyan
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.ApplicationInsights

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to add required packages" 
}

Set-Location ..
Write-Host "Sample application created successfully!" -ForegroundColor Green
```

---

## Step 4: Configure Application Settings and Logging

Implement comprehensive application configuration and logging.

```powershell
# 03-configure-application.ps1
# Configure the application with proper settings and logging

. .\config.ps1

Write-Host "Configuring Application..." -ForegroundColor Yellow

# Update Program.cs with proper configuration
$programContent = @'
using Microsoft.ApplicationInsights.Extensibility;
using Serilog;
using Serilog.Events;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog for structured logging
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.Hosting.Lifetime", LogEventLevel.Information)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.ApplicationInsights(
        builder.Configuration.GetConnectionString("ApplicationInsights") ?? 
        builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"], 
        TelemetryConverter.Traces)
    .CreateLogger();

builder.Host.UseSerilog();

// Add services to the container
builder.Services.AddControllersWithViews();

// Add Application Insights telemetry
builder.Services.AddApplicationInsightsTelemetry();

// Add health checks for monitoring
builder.Services.AddHealthChecks()
    .AddCheck("self", () => Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy());

var app = builder.Build();

// Configure the HTTP request pipeline
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // HSTS header for security (HTTP Strict Transport Security)
    app.UseHsts();
}

// Redirect HTTP to HTTPS
app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();
app.UseAuthorization();

// Map health check endpoint
app.MapHealthChecks("/health");

// Map default controller route
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

// Log application startup
app.Logger.LogInformation("Application started successfully");

app.Run();
'@

$programContent | Out-File -FilePath "$WEB_PROJECT_FOLDER/Program.cs" -Encoding UTF8

# Create enhanced appsettings.json
$appSettingsContent = @'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.ApplicationInsights": "Information"
    }
  },
  "ApplicationInsights": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "AllowedHosts": "*"
}
'@

$appSettingsContent | Out-File -FilePath "$WEB_PROJECT_FOLDER/appsettings.json" -Encoding UTF8

# Create production-specific settings
$appSettingsProdContent = @'
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Error",
      "AZ204WebApp": "Information"
    }
  }
}
'@

$appSettingsProdContent | Out-File -FilePath "$WEB_PROJECT_FOLDER/appsettings.Production.json" -Encoding UTF8

Write-Host "Application configuration completed!" -ForegroundColor Green
```

---

## Step 5: Deploy Application to App Service

Deploy the application with proper build and release processes.

```powershell
# 04-deploy-application.ps1
# Deploy the application to Azure App Service

. .\config.ps1

Write-Host "Deploying Application to Azure..." -ForegroundColor Yellow

# Build the application in Release configuration
Write-Host "Building application..." -ForegroundColor Cyan
Set-Location $WEB_PROJECT_FOLDER

dotnet publish -c Release -o ./publish
if ($LASTEXITCODE -ne 0) { 
    throw "Failed to build application" 
}

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Cyan
Compress-Archive -Path "./publish/*" -DestinationPath "../deployment.zip" -Force

Set-Location ..

# Deploy to Azure App Service using ZIP deployment
Write-Host "Deploying to App Service..." -ForegroundColor Cyan
az webapp deployment source config-zip `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --src "deployment.zip"

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to deploy application" 
}

# Clean up deployment artifacts
Remove-Item "deployment.zip" -ErrorAction SilentlyContinue

# Get the application URL
$webAppUrl = az webapp show `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --query "defaultHostName" `
    --output tsv

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Application URL: https://$webAppUrl"
Write-Host "Health Check: https://$webAppUrl/health"
Write-Host ""
Write-Host "Allow 2-3 minutes for application to start completely."
Write-Host ""
```

---

## Step 6: Configure TLS and Security Settings

Implement security best practices and TLS configuration.

```powershell
# 05-configure-security.ps1
# Configure security settings and TLS

. .\config.ps1

Write-Host "Configuring Security Settings..." -ForegroundColor Yellow

# Configure HTTPS-only access
Write-Host "Enabling HTTPS-only access..." -ForegroundColor Cyan
az webapp update `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --https-only true

# Configure minimum TLS version
Write-Host "Setting minimum TLS version to 1.2..." -ForegroundColor Cyan
az webapp config set `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --min-tls-version "1.2"

# Disable FTP deployment (security best practice)
Write-Host "Disabling FTP deployment..." -ForegroundColor Cyan
az webapp config set `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --ftps-state "Disabled"

# Configure custom domain (optional - requires domain ownership)
# Write-Host "To configure custom domain:" -ForegroundColor Yellow
# Write-Host "az webapp config hostname add --webapp-name $WEB_APP_SERVICE_NAME --resource-group $RG_NAME --hostname your-domain.com"

# Configure managed certificate (requires custom domain)
# Write-Host "To add managed SSL certificate:" -ForegroundColor Yellow  
# Write-Host "az webapp config ssl create --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME --hostname your-domain.com"

Write-Host "Security configuration completed!" -ForegroundColor Green
```

---

## Step 7: Configure Monitoring and Diagnostics

Set up comprehensive monitoring and diagnostic capabilities.

```powershell
# 06-configure-monitoring.ps1
# Configure detailed monitoring and diagnostics

. .\config.ps1

Write-Host "Configuring Monitoring and Diagnostics..." -ForegroundColor Yellow

# Enable application logging
Write-Host "Enabling application logging..." -ForegroundColor Cyan
az webapp log config `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --application-logging filesystem `
    --level information `
    --web-server-logging filesystem

# Configure log retention
Write-Host "Configuring log retention..." -ForegroundColor Cyan
az webapp log config `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --web-server-logging filesystem `
    --retention-period 7

# Enable detailed error messages (development/testing only)
Write-Host "Configuring error handling..." -ForegroundColor Cyan
az webapp config set `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --generic-configurations '{"detailedErrorLoggingEnabled": true, "httpLoggingEnabled": true, "requestTracingEnabled": true}'

# Display monitoring URLs
$webAppUrl = az webapp show `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --query "defaultHostName" `
    --output tsv

Write-Host ""
Write-Host "=== Monitoring Endpoints ===" -ForegroundColor Green
Write-Host "Application: https://$webAppUrl"
Write-Host "Health Check: https://$webAppUrl/health"
Write-Host "Kudu Console: https://$WEB_APP_SERVICE_NAME.scm.azurewebsites.net"
Write-Host ""

Write-Host "Log Streaming Commands:" -ForegroundColor Cyan
Write-Host "az webapp log tail --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME"
Write-Host ""
```

---

## Step 8: Implement Autoscaling

Configure automatic scaling based on performance metrics.

```powershell
# 07-configure-autoscaling.ps1
# Configure autoscaling for the App Service Plan

. .\config.ps1

Write-Host "Configuring Autoscaling..." -ForegroundColor Yellow

# Note: Autoscaling requires Standard tier or higher
# First, upgrade the App Service Plan to Standard
Write-Host "Upgrading to Standard tier for autoscaling..." -ForegroundColor Cyan
az appservice plan update `
    --resource-group $RG_NAME `
    --name $SERVICE_PLAN_NAME `
    --sku S1

if ($LASTEXITCODE -ne 0) { 
    Write-Warning "Failed to upgrade to Standard tier. Autoscaling requires Standard or Premium tier."
    return
}

# Create autoscale settings
Write-Host "Creating autoscale profile..." -ForegroundColor Cyan

# Get the App Service Plan resource ID
$planResourceId = az appservice plan show `
    --resource-group $RG_NAME `
    --name $SERVICE_PLAN_NAME `
    --query "id" `
    --output tsv

# Create autoscale setting with CPU-based scaling
az monitor autoscale create `
    --resource-group $RG_NAME `
    --name $AUTOSCALE_PROFILE_NAME `
    --resource $planResourceId `
    --min-count 1 `
    --max-count 3 `
    --count 1

# Add scale-out rule (CPU > 70%)
az monitor autoscale rule create `
    --resource-group $RG_NAME `
    --autoscale-name $AUTOSCALE_PROFILE_NAME `
    --condition "Percentage CPU > 70 avg 5m" `
    --scale out 1

# Add scale-in rule (CPU < 30%)  
az monitor autoscale rule create `
    --resource-group $RG_NAME `
    --autoscale-name $AUTOSCALE_PROFILE_NAME `
    --condition "Percentage CPU < 30 avg 5m" `
    --scale in 1 `
    --cooldown 5

Write-Host ""
Write-Host "=== Autoscaling Configuration ===" -ForegroundColor Green
Write-Host "Min Instances: 1"
Write-Host "Max Instances: 3"
Write-Host "Scale Out: CPU > 70% for 5 minutes"
Write-Host "Scale In: CPU < 30% for 5 minutes"
Write-Host "Cooldown: 5 minutes"
Write-Host ""

Write-Host "Monitor autoscaling:" -ForegroundColor Cyan
Write-Host "az monitor autoscale show --resource-group $RG_NAME --name $AUTOSCALE_PROFILE_NAME"
```

---

## Step 9: Configure Deployment Slots

Implement staging deployment slots for zero-downtime deployments.

```powershell
# 08-configure-deployment-slots.ps1
# Configure deployment slots for blue-green deployments

. .\config.ps1

Write-Host "Configuring Deployment Slots..." -ForegroundColor Yellow

# Note: Deployment slots require Standard tier or higher
# Create staging deployment slot
Write-Host "Creating staging deployment slot..." -ForegroundColor Cyan
az webapp deployment slot create `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --slot $DEPLOYMENT_SLOT_NAME

if ($LASTEXITCODE -ne 0) { 
    Write-Warning "Failed to create deployment slot. Deployment slots require Standard tier or higher."
    return
}

# Configure slot-specific settings (optional)
Write-Host "Configuring slot settings..." -ForegroundColor Cyan
az webapp config appsettings set `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --slot $DEPLOYMENT_SLOT_NAME `
    --settings "ASPNETCORE_ENVIRONMENT=Staging" "SlotName=Staging"

# Get staging slot URL
$stagingUrl = az webapp show `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --slot $DEPLOYMENT_SLOT_NAME `
    --query "defaultHostName" `
    --output tsv

Write-Host ""
Write-Host "=== Deployment Slots ===" -ForegroundColor Green
Write-Host "Production: https://$WEB_APP_SERVICE_NAME.azurewebsites.net"
Write-Host "Staging: https://$stagingUrl"
Write-Host ""

Write-Host "Deployment Commands:" -ForegroundColor Cyan
Write-Host "Deploy to staging:"
Write-Host "az webapp deployment source config-zip --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME --slot $DEPLOYMENT_SLOT_NAME --src deployment.zip"
Write-Host ""
Write-Host "Swap slots (zero-downtime deployment):"
Write-Host "az webapp deployment slot swap --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME --slot $DEPLOYMENT_SLOT_NAME --target-slot production"
Write-Host ""
```

---

## Step 10: Testing and Validation

Comprehensive testing of all configured features.

```powershell
# 09-test-deployment.ps1
# Test all configured features and functionality

. .\config.ps1

Write-Host "Testing Deployment..." -ForegroundColor Yellow

# Get web app URL
$webAppUrl = az webapp show `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --query "defaultHostName" `
    --output tsv

Write-Host "Running comprehensive tests..." -ForegroundColor Cyan

# Test 1: Basic connectivity
Write-Host "1. Testing basic connectivity..." -ForegroundColor White
try {
    $response = Invoke-WebRequest -Uri "https://$webAppUrl" -Method GET -UseBasicParsing
    Write-Host "   ✓ Main page accessible (Status: $($response.StatusCode))" -ForegroundColor Green
}
catch {
    Write-Host "   ✗ Main page failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Health check endpoint
Write-Host "2. Testing health check..." -ForegroundColor White
try {
    $healthResponse = Invoke-WebRequest -Uri "https://$webAppUrl/health" -Method GET -UseBasicParsing
    Write-Host "   ✓ Health check passed (Status: $($healthResponse.StatusCode))" -ForegroundColor Green
}
catch {
    Write-Host "   ✗ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: HTTPS redirection
Write-Host "3. Testing HTTPS redirection..." -ForegroundColor White
try {
    $httpResponse = Invoke-WebRequest -Uri "http://$webAppUrl" -Method GET -UseBasicParsing -MaximumRedirection 0
    Write-Host "   ✗ HTTP should redirect to HTTPS" -ForegroundColor Red
}
catch {
    if ($_.Exception.Response.StatusCode -eq 301 -or $_.Exception.Response.StatusCode -eq 302) {
        Write-Host "   ✓ HTTP correctly redirects to HTTPS" -ForegroundColor Green
    } else {
        Write-Host "   ? Unexpected redirect behavior" -ForegroundColor Yellow
    }
}

# Test 4: View application logs
Write-Host "4. Checking recent application logs..." -ForegroundColor White
az webapp log show `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --lines 10

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Green
Write-Host "Application URL: https://$webAppUrl"
Write-Host "Health Endpoint: https://$webAppUrl/health"
Write-Host "Kudu Console: https://$WEB_APP_SERVICE_NAME.scm.azurewebsites.net"
Write-Host ""

Write-Host "Additional Testing Commands:" -ForegroundColor Cyan
Write-Host "Stream live logs: az webapp log tail --resource-group $RG_NAME --name $WEB_APP_SERVICE_NAME"
Write-Host "View metrics: az monitor metrics list --resource-group $RG_NAME --resource $WEB_APP_SERVICE_NAME --resource-type Microsoft.Web/sites"
Write-Host "Check autoscale status: az monitor autoscale show --resource-group $RG_NAME --name $AUTOSCALE_PROFILE_NAME"
Write-Host ""
```

---

## Step 11: Performance Testing and Monitoring

Generate load to test autoscaling and monitor application behavior.

```powershell
# 10-performance-testing.ps1
# Generate load to test autoscaling functionality

. .\config.ps1

Write-Host "Performance Testing and Monitoring..." -ForegroundColor Yellow

$webAppUrl = az webapp show `
    --resource-group $RG_NAME `
    --name $WEB_APP_SERVICE_NAME `
    --query "defaultHostName" `
    --output tsv

Write-Host "Application URL: https://$webAppUrl" -ForegroundColor Cyan

# Simple load testing function (for educational purposes)
function Start-LoadTest {
    param(
        [string]$Url,
        [int]$Requests = 100,
        [int]$Concurrent = 10
    )
    
    Write-Host "Generating load: $Requests requests with $Concurrent concurrent connections..." -ForegroundColor Yellow
    
    $jobs = @()
    for ($i = 1; $i -le $Concurrent; $i++) {
        $job = Start-Job -ScriptBlock {
            param($url, $requestsPerJob)
            
            for ($j = 1; $j -le $requestsPerJob; $j++) {
                try {
                    Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing | Out-Null
                    Write-Host "Job $using:i - Request $j completed"
                }
                catch {
                    Write-Host "Job $using:i - Request $j failed: $($_.Exception.Message)"
                }
                Start-Sleep -Milliseconds 100
            }
        } -ArgumentList $Url, ($Requests / $Concurrent)
        
        $jobs += $job
    }
    
    # Wait for all jobs to complete
    $jobs | Wait-Job
    $jobs | Remove-Job
    
    Write-Host "Load test completed!" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Performance Testing Options ===" -ForegroundColor Green
Write-Host "1. Monitor current metrics"
Write-Host "2. Run light load test (educational purposes)"
Write-Host "3. View autoscale configuration"
Write-Host "4. Stream application logs"
Write-Host ""

$choice = Read-Host "Select option (1-4, or Enter to skip)"

switch ($choice) {
    "1" {
        Write-Host "Current application metrics..." -ForegroundColor Cyan
        az monitor metrics list `
            --resource-group $RG_NAME `
            --resource $WEB_APP_SERVICE_NAME `
            --resource-type "Microsoft.Web/sites" `
            --metric "CpuPercentage,MemoryPercentage,Requests" `
            --interval PT5M `
            --start-time (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ss")
    }
    
    "2" {
        Write-Host "Starting educational load test..." -ForegroundColor Yellow
        Write-Host "This will generate moderate load to demonstrate autoscaling." -ForegroundColor Yellow
        Start-LoadTest -Url "https://$webAppUrl" -Requests 50 -Concurrent 5
        
        Write-Host "Monitor scaling activity:" -ForegroundColor Cyan
        Write-Host "az monitor autoscale show --resource-group $RG_NAME --name $AUTOSCALE_PROFILE_NAME"
    }
    
    "3" {
        Write-Host "Current autoscale configuration..." -ForegroundColor Cyan
        az monitor autoscale show `
            --resource-group $RG_NAME `
            --name $AUTOSCALE_PROFILE_NAME `
            --output table
    }
    
    "4" {
        Write-Host "Streaming application logs (Ctrl+C to stop)..." -ForegroundColor Cyan
        az webapp log tail `
            --resource-group $RG_NAME `
            --name $WEB_APP_SERVICE_NAME
    }
    
    default {
        Write-Host "Skipping performance testing." -ForegroundColor Yellow
    }
}
```

---

## Step 12: Resource Cleanup

Clean up all Azure resources when lab is complete.

```powershell
# 11-cleanup.ps1
# Clean up all Azure resources

. .\config.ps1

Write-Host "Azure Resource Cleanup..." -ForegroundColor Red

Write-Host ""
Write-Host "This will delete the following resources:" -ForegroundColor Yellow
Write-Host "- Resource Group: $RG_NAME"
Write-Host "- App Service Plan: $SERVICE_PLAN_NAME" 
Write-Host "- Web App: $WEB_APP_SERVICE_NAME"
Write-Host "- Application Insights: $APP_INSIGHTS_NAME"
Write-Host "- Log Analytics Workspace: $LOG_WORKSPACE_NAME"
Write-Host "- All deployment slots and configurations"
Write-Host ""

$confirmation = Read-Host "Are you sure you want to delete all resources? Type 'DELETE' to confirm"

if ($confirmation -eq 'DELETE') {
    Write-Host "Deleting resource group and all contained resources..." -ForegroundColor Yellow
    
    # Delete the entire resource group (removes all contained resources)
    az group delete `
        --name $RG_NAME `
        --yes `
        --no-wait
    
    Write-Host "Deletion initiated. Resources will be removed in the background." -ForegroundColor Green
    Write-Host "You can monitor progress in the Azure portal." -ForegroundColor Cyan
    
    # Clean up local files
    Write-Host "Cleaning up local project files..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $WEB_PROJECT_FOLDER -ErrorAction SilentlyContinue
    Remove-Item "deployment.zip" -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "Cleanup completed!" -ForegroundColor Green
    Write-Host "Verify resource deletion: az group show --name $RG_NAME" -ForegroundColor Cyan
} else {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
}
```

---

## Investigation Guide for CLI Commands

### Essential Commands to Investigate

As you work through each script, pause and investigate these commands:

```powershell
# Resource Group Operations
az group create --help              # Understand resource group concepts
az group list --output table       # View all your resource groups

# App Service Plan Operations  
az appservice plan create --help    # Learn about compute tiers and options
az appservice plan list --output table  # See all your service plans
az appservice plan show --name $SERVICE_PLAN_NAME --resource-group $RG_NAME

# Web App Operations
az webapp create --help             # Understand web app creation options
az webapp list --output table      # View all your web apps
az webapp show --name $WEB_APP_SERVICE_NAME --resource-group $RG_NAME
az webapp config show --name $WEB_APP_SERVICE_NAME --resource-group $RG_NAME

# Monitoring and Logging
az webapp log --help                # Explore logging options
az monitor metrics list --help      # Understand available metrics
az monitor autoscale --help         # Learn autoscaling concepts

# Deployment Operations
az webapp deployment --help         # Understand deployment methods
az webapp deployment slot --help    # Learn about deployment slots
```

### Key Concepts to Research

1. **App Service Plans**: Understand the relationship between plans and apps
2. **Pricing Tiers**: Research when to use Free, Basic, Standard, Premium
3. **Deployment Methods**: ZIP deploy vs Git deploy vs Container deploy
4. **Monitoring**: Application Insights vs App Service logs vs Azure Monitor
5. **Security**: TLS configuration, managed identities, authentication
6. **Scaling**: Manual vs automatic scaling, scaling triggers and cooldowns

---

## Troubleshooting Guide

### Common Issues and Solutions

**1. Deployment Failures**
```powershell
# Check deployment status
az webapp deployment list-publishing-profiles --name $WEB_APP_SERVICE_NAME --resource-group $RG_NAME

# View deployment logs
az webapp log deployment show --name $WEB_APP_SERVICE_NAME --resource-group $RG_NAME
```

**2. Application Not Starting**
```powershell
# Check application logs
az webapp log tail --name $WEB_APP_SERVICE_NAME --resource-group $RG_NAME

# Verify application settings
az webapp config appsettings list --name $WEB_APP_SERVICE_NAME --resource-group $RG_NAME
```

**3. Autoscaling Not Working**
```powershell
# Verify service plan tier (requires Standard+)
az appservice plan show --name $SERVICE_PLAN_NAME --resource-group $RG_NAME --query "sku"

# Check autoscale rules
az monitor autoscale rule list --autoscale-name $AUTOSCALE_PROFILE_NAME --resource-group $RG_NAME
```

**4. Monitoring Issues**
```powershell
# Verify Application Insights connection
az webapp config appsettings list --name $WEB_APP_SERVICE_NAME --resource-group $RG_NAME --query "[?contains(name, 'APPINSIGHTS')]"

# Test health endpoint
curl -i https://$WEB_APP_SERVICE_NAME.azurewebsites.net/health
```

---

## Extension Opportunities

### Advanced Features to Explore

1. **Custom Domains and SSL**
   - Configure custom domain names
   - Implement SSL certificates (managed or custom)

2. **Authentication and Authorization**
   - Azure AD integration
   - Social provider authentication

3. **Advanced Monitoring**
   - Custom Application Insights telemetry
   - Log Analytics queries (KQL)
   - Azure Monitor alerts

4. **CI/CD Integration**
   - GitHub Actions deployment
   - Azure DevOps pipelines

5. **Performance Optimization**
   - Application Request Routing (ARR) affinity
   - Content Delivery Network (CDN) integration
   - Caching strategies

---

## Learning Objectives Achieved

✅ **App Service Fundamentals**
- Understanding of App Service Plans vs Web Apps
- Knowledge of pricing tiers and their capabilities
- Hands-on experience with deployment methods

✅ **Configuration Management**
- Application settings and connection strings
- Environment-specific configurations
- Security configuration (TLS, HTTPS-only)

✅ **Monitoring and Diagnostics** 
- Application Insights integration
- Log Analytics workspace configuration
- Health check endpoints

✅ **Scaling and Performance**
- Manual and automatic scaling configuration
- Understanding scaling triggers and metrics
- Performance testing concepts

✅ **DevOps Practices**
- Deployment slots for zero-downtime deployments
- Infrastructure as Code with Bicep
- Automated deployment processes

✅ **Security Best Practices**
- HTTPS enforcement and TLS configuration
- Managed identity concepts
- Secure application settings management

---

## Cost Management

**Estimated Costs:**
- **Basic (B1) App Service Plan**: ~$13.14/month
- **Standard (S1) for autoscaling**: ~$73.00/month  
- **Application Insights**: Pay-per-GB (typically <$5/month for development)
- **Log Analytics**: Pay-per-GB (typically <$3/month for development)

**Cost Optimization:**
- Use Basic tier for development and learning
- Delete resources after each lab session
- Monitor usage through Azure Cost Management

---

## Summary

This lab provides comprehensive hands-on experience with Azure App Service Web Apps, covering all essential features from basic deployment through advanced monitoring and scaling. The investigative approach helps develop deep understanding of each component and its purpose.

The combination of PowerShell automation scripts and Bicep templates demonstrates both imperative and declarative infrastructure management approaches, preparing you for real-world Azure development scenarios and AZ-204 certification success. "
