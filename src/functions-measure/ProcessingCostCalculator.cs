namespace FunctionsMeasure;

public sealed class ProcessingCostCalculator
{
    public double ExecuteWork(int iterations, int parallelism)
    {
        var cappedParallelism = Math.Max(1, Math.Min(parallelism, Environment.ProcessorCount));
        var results = new double[cappedParallelism];

        Parallel.For(
            0,
            cappedParallelism,
            new ParallelOptions { MaxDegreeOfParallelism = cappedParallelism },
            worker =>
            {
                var subtotal = 0.0;
                var random = new Random(Environment.TickCount ^ worker);
                for (var i = 0; i < iterations; i++)
                {
                    var seed = random.NextDouble() + 1;
                    subtotal += Math.Sqrt(seed) * Math.Log(seed);
                }

                results[worker] = subtotal;
            });

        return results.Sum();
    }
}
