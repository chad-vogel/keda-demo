using FunctionsMeasure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureLogging(builder =>
    {
        builder.ClearProviders();
        builder.AddConsole();
    })
    .ConfigureServices(services =>
    {
        services.AddSingleton<ProcessingCostCalculator>();
    })
    .Build();

await host.RunAsync();
