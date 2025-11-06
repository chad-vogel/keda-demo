using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;

namespace QueueProducer;

public sealed class ProducerService : BackgroundService
{
    private readonly ILogger<ProducerService> _logger;
    private readonly IConnectionMultiplexer _redis;
    private readonly ProducerSettings _settings;
    private readonly IHostApplicationLifetime _lifetime;

    public ProducerService(ILogger<ProducerService> logger, IConnectionMultiplexer redis, ProducerSettings settings, IHostApplicationLifetime lifetime)
    {
        _logger = logger;
        _redis = redis;
        _settings = settings;
        _lifetime = lifetime;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var db = _redis.GetDatabase();
        var batchId = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        var total = Math.Max(0, _settings.MessageCount);
        var delay = TimeSpan.FromMilliseconds(Math.Clamp(_settings.DelayMs, 0, 60_000));

        if (total == 0)
        {
            _logger.LogWarning("MessageCount resolved to zero. Nothing to enqueue.");
            return;
        }

        _logger.LogInformation(
            "Enqueueing {Count} message(s) onto Redis list '{QueueKey}' using prefix '{Prefix}' (delay {Delay} ms).",
            total,
            _settings.QueueKey,
            _settings.MessagePrefix,
            delay.TotalMilliseconds);

        for (var i = 1; i <= total && !stoppingToken.IsCancellationRequested; i++)
        {
            var payload = $"{_settings.MessagePrefix}-{batchId}-{i}";
            await db.ListLeftPushAsync(_settings.QueueKey, payload);
            if (delay > TimeSpan.Zero)
            {
                await Task.Delay(delay, stoppingToken);
            }
        }

        var length = await db.ListLengthAsync(_settings.QueueKey);
        _logger.LogInformation("Finished enqueueing. List '{QueueKey}' length is now {Length}.", _settings.QueueKey, length);
        _lifetime.StopApplication();
    }
}
