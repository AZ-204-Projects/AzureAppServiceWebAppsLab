// bicep/diagnostic-settings.bicep
// Diagnostic settings to route Web App logs to Log Analytics

@description('Name of the Web App to configure diagnostics for')
param webAppName string

@description('Resource ID of the Log Analytics workspace')
param logWorkspaceId string

@description('Name for the diagnostic setting')
param diagnosticSettingName string = 'comprehensive-logging'

// Reference to existing Web App
resource webApp 'Microsoft.Web/sites@2023-01-01' existing = {
  name: webAppName
}

// Diagnostic Settings - routes logs and metrics to Log Analytics
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingName
  scope: webApp  // Apply to the Web App
  properties: {
    workspaceId: logWorkspaceId  // Send logs to Log Analytics workspace
    
    // Log categories to capture
    logs: [
      {
        category: 'AppServiceHTTPLogs'      // HTTP access logs (requests, responses, status codes)
        enabled: true
        // retentionPolicy: {
        //   enabled: false  // Let Log Analytics handle retention
        //   days: 0
        // }
      }
      {
        category: 'AppServiceConsoleLogs'   // Console output from the application
        enabled: true
        // retentionPolicy: {
        //   enabled: false
        //   days: 0
        // }
      }
      {
        category: 'AppServiceAppLogs'       // Application-specific logs
        enabled: true
        // retentionPolicy: {
        //   enabled: false
        //   days: 0
        // }
      }
      {
        category: 'AppServicePlatformLogs'  // Platform-level events (deployments, configuration changes)
        enabled: true
        // retentionPolicy: {
        //   enabled: false
        //   days: 0
        // }
      }
      {
        category: 'AppServiceAuditLogs'     // Security and access audit logs
        enabled: true
        // retentionPolicy: {
        //   enabled: false
        //   days: 0
        // }
      }
      {
        category: 'AppServiceIPSecAuditLogs' // IP security audit logs
        enabled: true
        // retentionPolicy: {
        //   enabled: false
        //   days: 0
        // }
      }
    ]
    
    // Metrics to collect
    metrics: [
      {
        category: 'AllMetrics'              // Performance counters, resource utilization
        enabled: true
        // retentionPolicy: {
        //   enabled: false  // Let Log Analytics handle retention
        //   days: 0
        // }
      }
    ]
  }
}

// Outputs for verification
output diagnosticSettingId string = diagnosticSettings.id
output diagnosticSettingName string = diagnosticSettings.name
