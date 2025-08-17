# config.ps1
# Centralized configuration promotes maintainability and repeatability

# Resource Configuration
$RG_NAME = "az-204-web-app-lab-rg"              # Resource group for organized resource management
$LOCATION = "westus"                            # Azure region for deployment
$SERVICE_PLAN_NAME = "az-204-web-app-plan"      # App Service Plan name (compute resources)

# Application Configuration  
$WEB_APP_NAME = "Az204WebApp"                   # Internal reference name
$WEB_APP_DISPLAY_NAME = "Az-204 Web App"        # Human-readable display name
$WEB_APP_SERVICE_NAME = "az-204-web-app-svc-20250817AM"  # Must be globally unique
$WEB_PROJECT_FOLDER = "AZ204WebApp"             # Local project directory

# Monitoring and Insights
$APP_INSIGHTS_NAME = "az-204-web-app-insights"  # Application Insights for telemetry
$LOG_WORKSPACE_NAME = "az-204-web-app-logs"     # Log Analytics workspace

# Deployment Configuration
$DEPLOYMENT_SLOT_NAME = "staging"               # Staging slot for blue-green deployments
$AUTOSCALE_PROFILE_NAME = "DefaultAutoscale"    # Autoscaling configuration name

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