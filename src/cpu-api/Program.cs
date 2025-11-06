using CpuApi;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<CpuLoadScheduler>();

var app = builder.Build();

app.MapGet("/", () => Results.Ok(new
{
    message = "KEDA CPU demo",
    endpoints = new[]
    {
        new { method = "GET", path = "/loads", description = "List active CPU load jobs" },
        new { method = "POST", path = "/load", description = "Start a CPU load job" }
    }
}));

app.MapGet("/healthz", () => Results.Ok("ok"));

app.MapGet("/loads", (CpuLoadScheduler scheduler) => Results.Ok(scheduler.GetActiveJobs()));

app.MapPost("/load", (LoadRequest request, CpuLoadScheduler scheduler, CancellationToken cancellationToken) =>
{
    var durationSeconds = request.DurationSeconds ?? 30;
    if (durationSeconds <= 0 || durationSeconds > 900)
    {
        return Results.BadRequest("DurationSeconds must be between 1 and 900 seconds.");
    }

    var workerCount = request.Workers ?? Environment.ProcessorCount;
    workerCount = Math.Clamp(workerCount, 1, 64);

    var job = scheduler.StartLoad(TimeSpan.FromSeconds(durationSeconds), workerCount, cancellationToken);
    return Results.Accepted($"/loads/{job.Id}", job);
});

app.Run();

record LoadRequest
{
    public int? DurationSeconds { get; init; }
    public int? Workers { get; init; }
}
