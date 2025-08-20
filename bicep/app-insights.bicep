// bicep/app-insights.bicep
// Application Insights for application performance monitoring

@description('Name of the Application Insights instance')
param appInsightsName string

@description('Location for the Application Insights instance')
param location string = resourceGroup().location

@description('Resource ID of the Log Analytics workspace to link to')
param logWorkspaceId string

@description('Type of application being monitored')
@allowed(['web', 'other'])
param applicationType string = 'web'

@description('Ingestion mode for telemetry data')
@allowed(['ApplicationInsights', 'LogAnalytics'])
param ingestionMode string = 'LogAnalytics'

// Application Insights - Application Performance Monitoring (APM)
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: applicationType
  properties: {
    Application_Type: applicationType
    Flow_Type: 'Redfield'  // Server-side monitoring
    Request_Source: 'rest'  // Created via API/ARM
    
    // Link to Log Analytics workspace for data storage
    WorkspaceResourceId: logWorkspaceId
    IngestionMode: ingestionMode  // Store data in Log Analytics instead of classic AI storage
    
    // Network access settings
    publicNetworkAccessForIngestion: 'Enabled'  // Allow telemetry ingestion from internet
    publicNetworkAccessForQuery: 'Enabled'      // Allow queries from portal/tools
    
    // Disable IP masking for better debugging (lab environment only)
    DisableIpMasking: true
    
    // Sampling settings for cost control
    SamplingPercentage: 100  // Capture 100% of telemetry (reduce for high-volume apps)
  }
  tags: {
    Environment: 'Lab'
    Purpose: 'AZ-204-Training'
    Service: 'Monitoring'
  }
}

// Outputs for dependent resources (Web App will need these)
output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString
output appId string = appInsights.properties.AppId
output resourceId string = appInsights.id
