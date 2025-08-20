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