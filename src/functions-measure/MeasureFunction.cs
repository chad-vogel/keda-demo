using System.Diagnostics;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace FunctionsMeasure;

public sealed class MeasureFunction
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);

    private readonly ILogger<MeasureFunction> _logger;
    private readonly ProcessingCostCalculator _calculator;

    public MeasureFunction(ILogger<MeasureFunction> logger, ProcessingCostCalculator calculator)
    {
        _logger = logger;
        _calculator = calculator;
    }

    [Function("Measure")]
    public async Task<HttpResponseData> RunAsync(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "measure")] HttpRequestData request,
        FunctionContext executionContext)
    {
        var payload = await JsonSerializer.DeserializeAsync<MeasurementRequest>(
            request.Body,
            SerializerOptions,
            executionContext.CancellationToken) ?? MeasurementRequest.Default;

        var sw = Stopwatch.StartNew();
        var cost = _calculator.ExecuteWork(payload.Iterations, payload.Parallelism);
        sw.Stop();

        _logger.LogInformation(
            "Processed measurement {SensorId} value={Value} iterations={Iterations} parallel={Parallelism} cost={Cost} in {Elapsed} ms",
            payload.SensorId,
            payload.Value,
            payload.Iterations,
            payload.Parallelism,
            cost,
            sw.ElapsedMilliseconds);

        var response = request.CreateResponse();
        response.Headers.Add("Content-Type", "application/json");
        await JsonSerializer.SerializeAsync(
            response.Body,
            new MeasurementResponse(
                payload.SensorId,
                payload.Value,
                cost,
                sw.ElapsedMilliseconds),
            SerializerOptions,
            executionContext.CancellationToken);

        return response;
    }
}

public sealed record MeasurementRequest(
    string SensorId,
    double Value,
    int Iterations,
    int Parallelism)
{
    public static MeasurementRequest Default =>
        new("demo-sensor", 42.0, 25_000, Environment.ProcessorCount);
}

public sealed record MeasurementResponse(
    string SensorId,
    double Value,
    double ComputedCost,
    long DurationMilliseconds);
