using Microsoft.Extensions.Options;
using QueueWorker;
using StackExchange.Redis;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.Configure<QueueSettings>(builder.Configuration.GetSection("Queue"));
builder.Services.AddSingleton(sp => sp.GetRequiredService<IOptions<QueueSettings>>().Value);
var configuration = builder.Configuration;

builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var settings = sp.GetRequiredService<QueueSettings>();
    var connectionString = configuration.GetValue<string>("Redis:ConnectionString")
                           ?? settings.RedisConnectionString;
    return ConnectionMultiplexer.Connect(connectionString);
});

builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();
