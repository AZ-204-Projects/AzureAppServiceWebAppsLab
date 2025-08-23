# 03-configure-application.ps1
# Configure the application with proper settings and logging

. .\config.ps1

Write-Host "Configuring Application..." -ForegroundColor Yellow

# Update Program.cs with proper configuration
$programContent = @'
using Microsoft.ApplicationInsights.Extensibility;
using Serilog;
using Serilog.Events;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog for structured logging
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.Hosting.Lifetime", LogEventLevel.Information)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.ApplicationInsights(
        builder.Configuration.GetConnectionString("ApplicationInsights") ?? 
        builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"], 
        TelemetryConverter.Traces)
    .CreateLogger();

builder.Host.UseSerilog();

// Add services to the container
builder.Services.AddControllersWithViews();

// Add Application Insights telemetry
builder.Services.AddApplicationInsightsTelemetry();

// Add health checks for monitoring
builder.Services.AddHealthChecks()
    .AddCheck("self", () => Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy());

var app = builder.Build();

// Configure the HTTP request pipeline
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // HSTS header for security (HTTP Strict Transport Security)
    app.UseHsts();
}

// Redirect HTTP to HTTPS
app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();
app.UseAuthorization();

// Map health check endpoint
app.MapHealthChecks("/health");

// Map default controller route
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

// Log application startup
app.Logger.LogInformation("Application started successfully");

app.Run();
'@

$programContent | Out-File -FilePath "$WEB_PROJECT_FOLDER/Program.cs" -Encoding UTF8

# Create enhanced appsettings.json
$appSettingsContent = @'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.ApplicationInsights": "Information"
    }
  },
  "ApplicationInsights": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "AllowedHosts": "*"
}
'@

$appSettingsContent | Out-File -FilePath "$WEB_PROJECT_FOLDER/appsettings.json" -Encoding UTF8

# Create production-specific settings
$appSettingsProdContent = @'
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Error",
      "AZ204WebApp": "Information"
    }
  }
}
'@

$appSettingsProdContent | Out-File -FilePath "$WEB_PROJECT_FOLDER/appsettings.Production.json" -Encoding UTF8

Write-Host "Application configuration completed!" -ForegroundColor Green