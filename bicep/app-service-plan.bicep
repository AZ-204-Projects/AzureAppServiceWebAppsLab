// bicep/app-service-plan.bicep
// App Service Plan defines compute resources for web applications

@description('Name of the App Service Plan')
param servicePlanName string

@description('Location for the App Service Plan')
param location string = resourceGroup().location

@description('Pricing tier and size')
@allowed(['F1', 'D1', 'B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1', 'P2', 'P3'])
param skuName string = 'B1'

@description('Number of worker instances')
@minValue(1)
@maxValue(20)
param capacity int = 1

@description('Operating system for the App Service Plan')
@allowed(['Windows', 'Linux'])
param operatingSystem string = 'Windows'

// Variables for SKU mapping using conditional logic instead of indexing
var skuTier = skuName == 'F1' ? 'Free' : skuName == 'D1' ? 'Shared' : contains(['B1', 'B2', 'B3'], skuName) ? 'Basic' : contains(['S1', 'S2', 'S3'], skuName) ? 'Standard' : 'Premium'
var skuFamily = skuName == 'F1' ? 'F' : skuName == 'D1' ? 'D' : contains(['B1', 'B2', 'B3'], skuName) ? 'B' : contains(['S1', 'S2', 'S3'], skuName) ? 'S' : 'P'

// App Service Plan - defines the compute environment
resource servicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: servicePlanName
  location: location
  sku: {
    name: skuName      // B1 = Basic tier, dedicated compute
    tier: skuTier      // Free, Shared, Basic, Standard, or Premium
    size: skuName      // Specific size within the tier
    family: skuFamily  // Family: F=Free, D=Shared, B=Basic, S=Standard, P=Premium
    capacity: capacity // Initial number of instances
  }
  properties: {
    // Operating system selection
    reserved: operatingSystem == 'Linux' ? true : false  // false = Windows, true = Linux
    
    // Zone redundancy (requires Premium tier)
    zoneRedundant: false  // Would require Premium tier for zone redundancy
  }
  tags: {
    Environment: 'Lab'
    Purpose: 'AZ-204-Training'
    Service: 'Compute'
    Tier: skuTier
  }
}

// Outputs for dependent resources
output servicePlanId string = servicePlan.id
output servicePlanName string = servicePlan.name
output skuTier string = servicePlan.sku.tier
output skuSize string = servicePlan.sku.size
