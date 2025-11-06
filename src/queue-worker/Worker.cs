using StackExchange.Redis;

namespace QueueWorker;

public class Worker : BackgroundService
{
    private readonly ILogger<Worker> _logger;
    private readonly IConnectionMultiplexer _redis;
    private readonly QueueSettings _settings;
    private readonly TimeSpan _pollInterval;
    private readonly TimeSpan _processingDelay;

    public Worker(ILogger<Worker> logger, IConnectionMultiplexer redis, QueueSettings settings)
    {
        _logger = logger;
        _redis = redis;
        _settings = settings;
        _pollInterval = TimeSpan.FromMilliseconds(Math.Clamp(settings.PollIntervalMs, 100, 10_000));
        _processingDelay = TimeSpan.FromMilliseconds(Math.Clamp(settings.ProcessingDelayMs, 0, 600_000));
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var db = _redis.GetDatabase();
        _logger.LogInformation(
            "Queue worker listening on Redis list '{QueueKey}' (poll interval: {PollMs} ms, simulated processing delay: {DelayMs} ms).",
            _settings.QueueKey,
            _pollInterval.TotalMilliseconds,
            _processingDelay.TotalMilliseconds);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var value = await db.ListLeftPopAsync(_settings.QueueKey);
                if (value.HasValue)
                {
                    var message = value.ToString();
                    _logger.LogInformation("Dequeued message '{Message}'", message);

                    if (_processingDelay > TimeSpan.Zero)
                    {
                        await Task.Delay(_processingDelay, stoppingToken);
                    }

                    _logger.LogInformation("Finished processing message '{Message}'", message);
                    continue;
                }

                await Task.Delay(_pollInterval, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error while processing queue. Retrying in {Seconds}s", 2);
                await Task.Delay(TimeSpan.FromSeconds(2), stoppingToken);
            }
        }

        _logger.LogInformation("Queue worker stopping.");
    }
}
