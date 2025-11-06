namespace QueueProducer;

public sealed class ProducerSettings
{
    public string RedisConnectionString { get; set; } = "redis:6379";
    public string QueueKey { get; set; } = "keda-demo-queue";
    public string MessagePrefix { get; set; } = "msg";
    public int MessageCount { get; set; } = 100;
    public int DelayMs { get; set; } = 0;
}
