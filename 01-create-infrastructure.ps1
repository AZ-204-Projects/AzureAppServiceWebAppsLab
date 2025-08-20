# 01-create-infrastructure.ps1
# Deploy core infrastructure using modular Bicep templates
# Educational approach: Each Bicep template focuses on a specific Azure service

. .\config.ps1

Write-Host "Creating Azure Infrastructure with Modular Bicep Templates..." -ForegroundColor Yellow
Write-Host "This approach demonstrates Infrastructure as Code best practices by separating concerns" -ForegroundColor Cyan
Write-Host ""

# Create resource group (idempotent operation)
Write-Host "Step 1: Creating resource group: $RG_NAME" -ForegroundColor Cyan
Write-Host "  Purpose: Logical container for all lab resources" -ForegroundColor White
Write-Host "  Tags: Help with cost tracking and resource management" -ForegroundColor White

az group create `
    --name $RG_NAME `
    --location $LOCATION `
    --tags "Environment=Lab" "Purpose=AZ-204-Training" "Owner=$OWNER_OBJECT_ID"

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to create resource group" 
}
Write-Host "  ✓ Resource group created successfully" -ForegroundColor Green
Write-Host ""

# Deploy Log Analytics Workspace first (dependency for other services)
Write-Host "Step 2: Deploying Log Analytics Workspace" -ForegroundColor Cyan
Write-Host "  Purpose: Centralized logging platform for all Azure services" -ForegroundColor White
Write-Host "  Template: log-analytics.bicep" -ForegroundColor White

$logWorkspaceResult = az deployment group create `
    --resource-group $RG_NAME `
    --template-file "bicep/log-analytics.bicep" `
    --parameters `
        workspaceName=$LOG_WORKSPACE_NAME `
        location=$LOCATION `
    --query "properties.outputs" `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to deploy Log Analytics Workspace" 
}

$logWorkspaceId = $logWorkspaceResult.workspaceId.value
Write-Host "  ✓ Log Analytics Workspace deployed" -ForegroundColor Green
Write-Host "  Resource ID: $logWorkspaceId" -ForegroundColor Gray
Write-Host ""

# Deploy Application Insights (depends on Log Analytics)
Write-Host "Step 3: Deploying Application Insights" -ForegroundColor Cyan
Write-Host "  Purpose: Application Performance Monitoring (APM)" -ForegroundColor White
Write-Host "  Dependency: Links to Log Analytics for data storage" -ForegroundColor White
Write-Host "  Template: app-insights.bicep" -ForegroundColor White

$appInsightsResult = az deployment group create `
    --resource-group $RG_NAME `
    --template-file "bicep/app-insights.bicep" `
    --parameters `
        appInsightsName=$APP_INSIGHTS_NAME `
        location=$LOCATION `
        logWorkspaceId=$logWorkspaceId `
    --query "properties.outputs" `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to deploy Application Insights" 
}

$appInsightsKey = $appInsightsResult.instrumentationKey.value
$appInsightsConnectionString = $appInsightsResult.connectionString.value
Write-Host "  ✓ Application Insights deployed" -ForegroundColor Green
Write-Host "  Instrumentation Key: $($appInsightsKey.Substring(0,8))..." -ForegroundColor Gray
Write-Host ""

# Deploy App Service Plan
Write-Host "Step 4: Deploying App Service Plan" -ForegroundColor Cyan
Write-Host "  Purpose: Defines compute resources (CPU, memory, scaling)" -ForegroundColor White
Write-Host "  Tier: Basic B1 (dedicated compute, manual scaling)" -ForegroundColor White
Write-Host "  Template: app-service-plan.bicep" -ForegroundColor White

$servicePlanResult = az deployment group create `
    --resource-group $RG_NAME `
    --template-file "bicep/app-service-plan.bicep" `
    --parameters `
        servicePlanName=$SERVICE_PLAN_NAME `
        location=$LOCATION `
    --query "properties.outputs" `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to deploy App Service Plan" 
}

$servicePlanId = $servicePlanResult.servicePlanId.value
Write-Host "  ✓ App Service Plan deployed" -ForegroundColor Green
Write-Host "  SKU: Basic B1 (1 core, 1.75GB memory)" -ForegroundColor Gray
Write-Host ""

# Deploy Web App (depends on App Service Plan and Application Insights)
Write-Host "Step 5: Deploying Web App" -ForegroundColor Cyan
Write-Host "  Purpose: Hosts the actual web application" -ForegroundColor White
Write-Host "  Runtime: .NET 8" -ForegroundColor White
Write-Host "  Security: HTTPS-only, TLS 1.2 minimum" -ForegroundColor White
Write-Host "  Template: web-app.bicep" -ForegroundColor White

$webAppResult = az deployment group create `
    --resource-group $RG_NAME `
    --template-file "bicep/web-app.bicep" `
    --parameters `
        webAppName=$WEB_APP_SERVICE_NAME `
        location=$LOCATION `
        servicePlanId=$servicePlanId `
        appInsightsInstrumentationKey=$appInsightsKey `
        appInsightsConnectionString=$appInsightsConnectionString `
    --query "properties.outputs" `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to deploy Web App" 
}

$webAppUrl = $webAppResult.webAppUrl.value
Write-Host "  ✓ Web App deployed" -ForegroundColor Green
Write-Host "  URL: $webAppUrl" -ForegroundColor Gray
Write-Host ""

# Deploy Diagnostic Settings (links Web App logs to Log Analytics)
Write-Host "Step 6: Deploying Diagnostic Settings" -ForegroundColor Cyan
Write-Host "  Purpose: Route Web App logs to Log Analytics" -ForegroundColor White
Write-Host "  Log Categories: HTTP, Console, Application, Platform logs" -ForegroundColor White
Write-Host "  Template: diagnostic-settings.bicep" -ForegroundColor White

az deployment group create `
    --resource-group $RG_NAME `
    --template-file "bicep/diagnostic-settings.bicep" `
    --parameters `
        webAppName=$WEB_APP_SERVICE_NAME `
        logWorkspaceId=$logWorkspaceId `
    --query "properties.provisioningState" `
    --output tsv | Out-Null

if ($LASTEXITCODE -ne 0) { 
    throw "Failed to deploy Diagnostic Settings" 
}
Write-Host "  ✓ Diagnostic Settings configured" -ForegroundColor Green
Write-Host ""

# Summary and next steps
Write-Host "=== Infrastructure Deployment Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Resources Created:" -ForegroundColor Cyan
Write-Host "  Resource Group: $RG_NAME" -ForegroundColor White
Write-Host "  Log Analytics: $LOG_WORKSPACE_NAME" -ForegroundColor White
Write-Host "  Application Insights: $APP_INSIGHTS_NAME" -ForegroundColor White
Write-Host "  App Service Plan: $SERVICE_PLAN_NAME (Basic B1)" -ForegroundColor White
Write-Host "  Web App: $WEB_APP_SERVICE_NAME" -ForegroundColor White
Write-Host "  Web App URL: $webAppUrl" -ForegroundColor White
Write-Host ""

Write-Host "Educational Investigation Opportunities:" -ForegroundColor Yellow
Write-Host "1. Azure Portal Exploration:" -ForegroundColor Cyan
Write-Host "   - Navigate to Resource Group: $RG_NAME" -ForegroundColor White
Write-Host "   - Examine App Service Plan pricing tier and scaling options" -ForegroundColor White
Write-Host "   - Review Web App Configuration settings" -ForegroundColor White
Write-Host "   - Explore Application Insights Live Metrics" -ForegroundColor White
Write-Host "   - Check Log Analytics workspace setup" -ForegroundColor White
Write-Host ""

Write-Host "2. CLI Investigation Commands:" -ForegroundColor Cyan
Write-Host "   az appservice plan show --name $SERVICE_PLAN_NAME --resource-group $RG_NAME" -ForegroundColor White
Write-Host "   az webapp show --name $WEB_APP_SERVICE_NAME --resource-group $RG_NAME" -ForegroundColor White
Write-Host "   az webapp config show --name $WEB_APP_SERVICE_NAME --resource-group $RG_NAME" -ForegroundColor White
Write-Host "   az monitor app-insights component show --app $APP_INSIGHTS_NAME --resource-group $RG_NAME" -ForegroundColor White
Write-Host ""

Write-Host "3. Key Concepts to Research:" -ForegroundColor Cyan
Write-Host "   - App Service Plan vs Web App relationship" -ForegroundColor White
Write-Host "   - Basic tier limitations (no autoscaling, no deployment slots)" -ForegroundColor White
Write-Host "   - Application Insights vs Log Analytics roles" -ForegroundColor White
Write-Host "   - Managed Identity for secure service-to-service authentication" -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  - Infrastructure is ready for application deployment" -ForegroundColor White
Write-Host "  - Proceed to: 02-create-sample-app.ps1" -ForegroundColor White
Write-Host "  - Or spend time investigating the created resources first" -ForegroundColor White