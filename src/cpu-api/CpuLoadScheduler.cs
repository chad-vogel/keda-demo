using System.Collections.Concurrent;
using System.Diagnostics;

namespace CpuApi;

public sealed class CpuLoadScheduler
{
    private readonly ConcurrentDictionary<Guid, CpuLoadJob> _jobs = new();
    private readonly ILogger<CpuLoadScheduler> _logger;

    public CpuLoadScheduler(ILogger<CpuLoadScheduler> logger)
    {
        _logger = logger;
    }

    public CpuLoadJobStatus StartLoad(TimeSpan duration, int workers, CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        var job = new CpuLoadJob(Guid.NewGuid(), now, now.Add(duration), workers);

        if (!_jobs.TryAdd(job.Id, job))
        {
            throw new InvalidOperationException($"Failed to schedule CPU load job {job.Id}");
        }

        _ = RunJobAsync(job, cancellationToken);
        return ToStatus(job);
    }

    public IReadOnlyCollection<CpuLoadJobStatus> GetActiveJobs()
    {
        var snapshot = _jobs.Values.ToArray();
        return snapshot
            .Select(ToStatus)
            .OrderByDescending(j => j.EndsAt)
            .ToArray();
    }

    private CpuLoadJobStatus ToStatus(CpuLoadJob job)
    {
        var now = DateTimeOffset.UtcNow;
        return new CpuLoadJobStatus(
            job.Id,
            job.StartedAt,
            job.EndsAt,
            job.Workers,
            Math.Max(0, (job.EndsAt - now).TotalSeconds));
    }

    private async Task RunJobAsync(CpuLoadJob job, CancellationToken cancellationToken)
    {
        using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        var duration = job.EndsAt - job.StartedAt;
        linkedCts.CancelAfter(duration);

        _logger.LogInformation("CPU load job {JobId} starting for {Duration}s with {Workers} workers.",
            job.Id, duration.TotalSeconds, job.Workers);

        var workerTasks = Enumerable.Range(0, job.Workers)
            .Select(index => Task.Run(() => BurnCpu(job.Id, index, linkedCts.Token), CancellationToken.None))
            .ToArray();

        try
        {
            await Task.WhenAll(workerTasks);
            _logger.LogInformation("CPU load job {JobId} completed.", job.Id);
        }
        catch (Exception ex) when (ex is OperationCanceledException or TaskCanceledException)
        {
            _logger.LogInformation("CPU load job {JobId} cancelled.", job.Id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CPU load job {JobId} failed.", job.Id);
        }
        finally
        {
            _jobs.TryRemove(job.Id, out _);
        }
    }

    private void BurnCpu(Guid jobId, int workerIndex, CancellationToken cancellationToken)
    {
        var sw = Stopwatch.StartNew();
        try
        {
            while (!cancellationToken.IsCancellationRequested)
            {
                _ = MathF.Sqrt(Random.Shared.NextSingle());
            }
        }
        finally
        {
            sw.Stop();
            _logger.LogDebug("CPU load job {JobId} worker {WorkerIndex} ran for {Duration}s.",
                jobId, workerIndex, sw.Elapsed.TotalSeconds);
        }
    }

    private sealed record CpuLoadJob(Guid Id, DateTimeOffset StartedAt, DateTimeOffset EndsAt, int Workers);
}

public sealed record CpuLoadJobStatus(Guid Id, DateTimeOffset StartedAt, DateTimeOffset EndsAt, int Workers, double SecondsRemaining);
