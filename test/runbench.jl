using MultithreadingBenchmarks
using Printf
using InteractiveUtils

# ---------------------------------------------------------------
println("------ JULIA VERSIONINFO ------")
InteractiveUtils.versioninfo()

println("------ JULIA CPU INFO ------")
@show Sys.CPU_THREADS
Sys.cpu_summary()

# ---------------------------------------------------------------

const BENCHDIR = joinpath(dirname(pathof(MultithreadingBenchmarks)), "bench")

const NUM_DATAPOINTS = 11  # Keep this odd, so we get a point at 50%

MultithreadingBenchmarks.perform_scaling_experiment(
    bench_file = "$BENCHDIR/simple_independent.jl",
    num_datapoints = NUM_DATAPOINTS,  # keep this odd, so we get a point at 50%
    nqueries = 1000,
    num_ops = 1_000_000_00,#0,
    plot_series_name = "1000 queries x 1e8 ops",
    )

#MultithreadingBenchmarks.perform_scaling_experiment(
#    bench_file = "$BENCHDIR/all_tasks_allocating.jl",
#    num_datapoints = 5,  # Use fewer datapoints since it's expensive and clear
#    nqueries = 1000,
#    num_ops = 1_000_000,
#    plot_series_name = "all tasks alloc garbage: 1000 queries x 1e6 ops",
#    )

# TODO: This benchmark is still very experimental
MultithreadingBenchmarks.perform_scaling_experiment(
    bench_file = "$BENCHDIR/onethread_alloc_garbage.jl",
    num_datapoints = NUM_DATAPOINTS,  # Unused -- we're setting it manually below:
    # Manually set the nthreads to test -- Skip nthreads=1 because one thread is occupied
    # allocating garbage and won't participate in the test. The test would deadlike for
    # nthreads=1, so we use nthreads=2 instead. Effectively, all these values are 1 higher
    # than are actually being tested, so we effectively test from [1, NUM_CPUS-1].
    # (NOTE: that we then also need to subtract 1 from all the nthreads in the results)
    nthreads_to_test = [2, Int.(round.(range(0, stop=MultithreadingBenchmarks.NUM_CORES, length=NUM_DATAPOINTS)))[2:end]...],
    # Subtract 1 from nthreads in result since 1 CPU is occupied allocating garbage.
    preprocess_results = results->(results.nthreads .-= 1; results),

    nqueries = 1000,
    num_ops = 1_000_000_00,#0,
    plot_series_name = "one task allocs garbage: 1000 queries x 1e8 ops",
    )
