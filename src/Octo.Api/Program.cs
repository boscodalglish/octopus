using System.Reflection;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);
builder.Logging.ClearProviders();
builder.Logging.AddJsonConsole();
builder.Services.AddHealthChecks();
builder.Services.AddProblemDetails();

// Local execution has no telemetry destination. Azure configuration enables it.
if (!string.IsNullOrWhiteSpace(builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]))
{
    builder.Services.AddApplicationInsightsTelemetry();
}

var app = builder.Build();
app.UseExceptionHandler();
app.Use(async (context, next) =>
{
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["Cache-Control"] = "no-store";
    await next(context);
});

app.MapGet("/", () => Results.Content("""
    <!doctype html>
    <html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Octo · Azure delivery exercise</title></head>
    <body><main><h1>Octo</h1><p>A small .NET service demonstrating secure, repeatable Azure delivery.</p>
    <p>This demonstration uses synthetic information only.</p>
    <ul><li><a href="/api/info">Release information</a></li><li><a href="/health">Service health</a></li></ul>
    </main></body></html>
    """, "text/html"));

app.MapGet("/api/info", () =>
{
    var assembly = typeof(Program).Assembly;
    var commit = assembly.GetCustomAttributes<AssemblyMetadataAttribute>()
        .SingleOrDefault(attribute => attribute.Key == "Commit")?.Value ?? "unknown";
    var version = assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()
        ?.InformationalVersion.Split('+')[0] ?? "unknown";
    return Results.Ok(new { service = "octo", version, commit });
});

// No external dependencies: readiness and liveness have the same meaning here.
app.MapHealthChecks("/health", new HealthCheckOptions());
app.Run();

public partial class Program;
