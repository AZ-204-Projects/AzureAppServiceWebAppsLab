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

# Add scale-out rule (CPU > 70%) - using the syntax from Azure CLI examples
Write-Host "Adding scale-out rule..." -ForegroundColor Cyan
az monitor autoscale rule create `
    --resource-group $RG_NAME `
    --autoscale-name $AUTOSCALE_PROFILE_NAME `
    --condition "CpuPercentage > 70 avg 5m" `
    --scale out 1

# Add scale-in rule (CPU < 30%)
Write-Host "Adding scale-in rule..." -ForegroundColor Cyan
az monitor autoscale rule create `
    --resource-group $RG_NAME `
    --autoscale-name $AUTOSCALE_PROFILE_NAME `
    --condition "CpuPercentage < 30 avg 5m" `
    --scale in 1 `
    --cooldown 5

# Verify the autoscale configuration
Write-Host "Verifying autoscale configuration..." -ForegroundColor Cyan
az monitor autoscale show `
    --resource-group $RG_NAME `
    --name $AUTOSCALE_PROFILE_NAME `
    --query "profiles[0].rules[].{Metric:metricTrigger.metricName,Condition:metricTrigger.operator,Threshold:metricTrigger.threshold,Action:scaleAction.direction}" `
    --output table

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
Write-Host ""
Write-Host "Check current metrics:" -ForegroundColor Cyan
Write-Host "az monitor metrics list --resource-group $RG_NAME --resource $SERVICE_PLAN_NAME --resource-type Microsoft.Web/serverfarms --metric CpuPercentage"