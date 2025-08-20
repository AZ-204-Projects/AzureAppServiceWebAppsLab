// bicep/log-analytics.bicep
// Log Analytics Workspace for centralized logging and monitoring

@description('Name of the Log Analytics Workspace')
param workspaceName string

@description('Location for the workspace')
param location string = resourceGroup().location

@description('Pricing tier for the workspace')
@allowed(['Free', 'Standalone', 'PerNode', 'PerGB2018'])
param sku string = 'PerGB2018'

@description('Data retention period in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

// Log Analytics Workspace - foundation for all logging in Azure
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: sku  // PerGB2018: Pay per GB ingested (most common for production)
    }
    retentionInDays: retentionInDays  // How long to keep log data
    features: {
      searchVersion: 1                // Version of search functionality
      legacy: 0                      // Disable legacy features for better performance
      enableLogAccessUsingOnlyResourcePermissions: true  // Modern access control
    }
    workspaceCapping: {
      dailyQuotaGb: 1  // Limit daily ingestion to control costs (remove for production)
    }
  }
  tags: {
    Environment: 'Lab'
    Purpose: 'AZ-204-Training'
    Service: 'Logging'
  }
}

// Outputs for dependent resources
output workspaceId string = logWorkspace.id
output workspaceName string = logWorkspace.name
output customerId string = logWorkspace.properties.customerId
