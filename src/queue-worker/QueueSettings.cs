namespace QueueWorker;

public sealed class QueueSettings
{
    public string RedisConnectionString { get; set; } = "redis:6379";
    public string QueueKey { get; set; } = "keda-demo-queue";
    public int PollIntervalMs { get; set; } = 500;
    public int ProcessingDelayMs { get; set; } = 2000;
}
