// bicep/web-app.bicep
// Web App configuration with security and monitoring settings

@description('Name of the Web App')
param webAppName string

@description('Location for the Web App')
param location string = resourceGroup().location

@description('Resource ID of the App Service Plan')
param servicePlanId string

@description('Application Insights instrumentation key')
@secure()
param appInsightsInstrumentationKey string

@description('Application Insights connection string')
@secure()
param appInsightsConnectionString string

@description('.NET runtime version')
@allowed(['v6.0', 'v7.0', 'v8.0'])
param netFrameworkVersion string = 'v8.0'

@description('Minimum TLS version')
@allowed(['1.0', '1.1', '1.2', '1.3'])
param minTlsVersion string = '1.2'

@description('Environment name for the application')
@allowed(['Development', 'Staging', 'Production'])
param environment string = 'Production'

// Web App - the actual application hosting service
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: servicePlanId  // Link to App Service Plan for compute resources
    
    siteConfig: {
      // Runtime configuration
      netFrameworkVersion: netFrameworkVersion  // .NET runtime version
      defaultDocuments: [
        'Default.htm'
        'Default.html' 
        'index.html'
        'index.htm'
      ]
      
      // Logging configuration
      httpLoggingEnabled: true              // Log HTTP requests for debugging
      detailedErrorLoggingEnabled: true     // Detailed error pages for troubleshooting
      requestTracingEnabled: true           // Failed request tracing
      logsDirectorySizeLimit: 100           // Limit log directory size (MB)
      
      // Application settings - injected as environment variables
      appSettings: [
        // Application Insights configuration
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'  
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'  // Use latest stable Application Insights agent
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'Recommended'  // Enable recommended Application Insights features
        }
        {
          name: 'APPINSIGHTS_PROFILERFEATURE_VERSION'
          value: '1.0.0'  // Enable Application Insights Profiler
        }
        
        // ASP.NET Core configuration
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environment
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'  // Run from deployment package for better performance
        }
      ]
      
      // Security configuration
      minTlsVersion: minTlsVersion           // Enforce minimum TLS version
      scmMinTlsVersion: minTlsVersion       // SCM site (Kudu) also uses same TLS version
      ftpsState: 'Disabled'                 // Disable FTP, require FTPS for file transfers
      
      // Performance settings
      alwaysOn: true                        // Keep app warm (prevents cold starts)
      http20Enabled: true                   // Enable HTTP/2 for better performance
      
      // Platform settings
      use32BitWorkerProcess: false          // Use 64-bit worker process for better performance
      webSocketsEnabled: false              // Disable WebSockets unless needed
      managedPipelineMode: 'Integrated'     // IIS pipeline mode
    }
    
    // Security settings
    httpsOnly: true                         // Redirect all HTTP traffic to HTTPS
    clientAffinityEnabled: false            // Disable session affinity for better load balancing
    
    // Note: Authentication disabled for basic lab
    // Modern authentication would be configured via Microsoft.Web/sites/config resource
  }
  
  // Managed Identity for secure access to Azure services
  identity: {
    type: 'SystemAssigned'  // Azure automatically manages the identity lifecycle
  }
  
  tags: {
    Environment: 'Lab'
    Purpose: 'AZ-204-Training' 
    Service: 'WebApp'
    Runtime: 'dotnet-8'
  }
}

// Outputs for dependent resources and validation
output webAppId string = webApp.id
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output outboundIpAddresses string = webApp.properties.outboundIpAddresses
output managedIdentityPrincipalId string = webApp.identity.principalId
