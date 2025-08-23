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
