using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using QueueProducer;
using StackExchange.Redis;

var builder = Host.CreateApplicationBuilder(args);

var switchMappings = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
{
    ["--connection"] = "RedisConnectionString",
    ["--queue"] = "QueueKey",
    ["--prefix"] = "MessagePrefix",
    ["--count"] = "MessageCount",
    ["--delay"] = "DelayMs"
};

builder.Configuration.AddCommandLine(args, switchMappings);
builder.Configuration.AddEnvironmentVariables(prefix: "Producer__");

builder.Services.Configure<ProducerSettings>(builder.Configuration);
builder.Services.AddSingleton(sp => sp.GetRequiredService<IOptions<ProducerSettings>>().Value);
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var settings = sp.GetRequiredService<ProducerSettings>();
    return ConnectionMultiplexer.Connect(settings.RedisConnectionString);
});

builder.Services.AddHostedService<ProducerService>();

var host = builder.Build();
await host.RunAsync();
