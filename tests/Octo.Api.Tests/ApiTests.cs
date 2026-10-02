using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace Octo.Api.Tests;

public class ApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient client;
    public ApiTests(WebApplicationFactory<Program> factory) => client = factory.CreateClient();

    [Fact]
    public async Task Health_is_available_without_external_services()
    {
        var response = await client.GetAsync("/health");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("Healthy", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Release_information_contains_build_identity_but_no_environment_configuration()
    {
        var response = await client.GetAsync("/api/info");
        response.EnsureSuccessStatusCode();
        using var payload = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var values = payload.RootElement;
        Assert.Equal("octo", values.GetProperty("service").GetString());
        Assert.False(string.IsNullOrWhiteSpace(values.GetProperty("version").GetString()));
        Assert.False(string.IsNullOrWhiteSpace(values.GetProperty("commit").GetString()));
        Assert.Equal(3, values.EnumerateObject().Count());
        Assert.Equal("no-store", response.Headers.CacheControl?.ToString());
        Assert.Equal("nosniff", response.Headers.GetValues("X-Content-Type-Options").Single());
    }

    [Fact]
    public async Task Home_explains_the_demo_and_links_to_health()
    {
        var response = await client.GetAsync("/");
        response.EnsureSuccessStatusCode();
        Assert.Equal("text/html", response.Content.Headers.ContentType?.MediaType);
        Assert.Contains("/health", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Unknown_routes_are_not_successful_health_checks()
    {
        var response = await client.GetAsync("/does-not-exist");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
