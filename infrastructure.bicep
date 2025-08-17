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
      // httpLoggingEnabled: true          // Log HTTP requests
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
        // retentionPolicy: {
        //   enabled: true
        //   days: 30
        // }
      }
      {
        category: 'AppServiceConsoleLogs'  // Console output
        enabled: true
        // retentionPolicy: {
        //   enabled: true
        //   days: 30
        // }
      }
      {
        category: 'AppServiceAppLogs'     // Application logs
        enabled: true
        // retentionPolicy: {
        //   enabled: true
        //   days: 30
        // }
      }
      {
        category: 'AppServicePlatformLogs' // Platform logs
        enabled: true
        // retentionPolicy: {
        //   enabled: true
        //   days: 30
        // }
      }
    ]
    
    // Metrics to collect
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        // retentionPolicy: {
        //   enabled: true
        //   days: 30
        // }
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
