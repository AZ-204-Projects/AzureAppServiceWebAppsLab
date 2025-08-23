# 11-cleanup.ps1
# Clean up all Azure resources

. .\config.ps1

Write-Host "Azure Resource Cleanup..." -ForegroundColor Red

Write-Host ""
Write-Host "This will delete the following resources:" -ForegroundColor Yellow
Write-Host "- Resource Group: $RG_NAME"
Write-Host "- App Service Plan: $SERVICE_PLAN_NAME" 
Write-Host "- Web App: $WEB_APP_SERVICE_NAME"
Write-Host "- Application Insights: $APP_INSIGHTS_NAME"
Write-Host "- Log Analytics Workspace: $LOG_WORKSPACE_NAME"
Write-Host "- All deployment slots and configurations"
Write-Host ""

$confirmation = Read-Host "Are you sure you want to delete all resources? Type 'DELETE' to confirm"

if ($confirmation -eq 'DELETE') {
    Write-Host "Deleting resource group and all contained resources..." -ForegroundColor Yellow
    
    # Delete the entire resource group (removes all contained resources)
    az group delete `
        --name $RG_NAME `
        --yes `
        --no-wait
    
    Write-Host "Deletion initiated. Resources will be removed in the background." -ForegroundColor Green
    Write-Host "You can monitor progress in the Azure portal." -ForegroundColor Cyan
    
    # Clean up local files
    Write-Host "Cleaning up local project files..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $WEB_PROJECT_FOLDER -ErrorAction SilentlyContinue
    Remove-Item "deployment.zip" -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "Cleanup completed!" -ForegroundColor Green
    Write-Host "Verify resource deletion: az group show --name $RG_NAME" -ForegroundColor Cyan
} else {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
}
