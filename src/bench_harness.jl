# This test harness executes the specified BENCH_FILE several times, each with different
# JULIA_NUM_THREADS settings, to measure performance scaling of the benchmark with more
# threads. This is needed because currently Julia does not allow dynamically changing the
# number of available threads.
# To change which benchmark is being run, set the BENCH_FILE constant below.

using DataFrames
#using Plots
#using Plots.PlotMeasures
using Statistics

# ----------------------------------------------------------------
# Params for this test file -- EDIT THESE
const NUM_CORES = Sys.CPU_THREADS

function run_bench_file(file, nthreads, nqueries, query_size)
    withenv(
        "JULIA_NUM_THREADS" => nthreads,
        "NUM_QUERIES" => nqueries,
        "QUERY_SIZE" => query_size,
    ) do
         @assert Base.active_project() != nothing "Must run this benchmark w/ an active Julia Project.toml (and ideally Manifest.toml)!"
         lines = readlines(`$(Base.julia_cmd()) --project=$(Base.active_project()) $file`)
         return (;
             time_secs            = parse(Float64, lines[end-5]) / 1e9            ,
             allocs               = parse(Int,     lines[end-4])                  ,
             memory               = parse(Int,     lines[end-3])                  ,
             gctime_secs          = parse(Float64, lines[end-2]) / 1e9            ,
             thread_counts        = Vector{Int}(Meta.parse(lines[end-1]).args)    ,
             query_latencies_secs = Vector{Float64}(Meta.parse(lines[end]).args)  ,
         )
    end
end

function bench_nthreads_scaling(file, nqueries, query_size, all_nthreads, preprocess_results)
    println("NUM_QUERIES: $nqueries")
    println("WORK_SIZE: $query_size")
    results = DataFrame(nthreads=Int[], time_secs=Float64[], allocs=Int[], memory=Int[], gctime_secs=Float64[],
                                        thread_counts=Vector{Int}[], query_latencies_secs=Vector{Float64}[])
    for NTHREADS in all_nthreads
        println("$NTHREADS threads: ")
        benchresults = run_bench_file(file, NTHREADS, nqueries, query_size)
        push!(results, (; nthreads = NTHREADS, benchresults...))
        println("$(benchresults.time_secs) secs")
    end

    # ------------
    # Run provided preprocess_results()
    # ------------
    results = preprocess_results(results)

    println("Results (omitted printing latencies column):")
    println(results[:, 1:end-1])  # Pretty-print and hide latencies column (too long)

    #-------------
    # Plot the results
    #-------------

    df = DataFrame(nthreads = results.nthreads, time_secs = results.time_secs,
            speedup_factor = [results[1,:].time_secs / t for t in results.time_secs])

    utilization = df.speedup_factor ./ df.nthreads
    marginal_speedup = let out = Float64[]
         push!(out, 1.0)
         for i in 2:size(df, 1)
            push!(out, (df.speedup_factor[i] - df.speedup_factor[i-1]) ./ (df.nthreads[i] - df.nthreads[i-1]))
         end
         out
     end
     query_latencies_ms = sort.(results.query_latencies_secs .* 1e3)
     quantiles = (0.1, 0.5, 0.9, 0.99, 1)
     processed = DataFrame(nthreads = df.nthreads, time_secs = df.time_secs,
                           speedup_factor = df.speedup_factor,
                           marginal_speedup = marginal_speedup, utilization = utilization,
                           latency_quantiles_ms = [((q=>quantile(l, q) for q in quantiles)...,) for l in query_latencies_ms],
                           )

    println("Processed:")
    println(processed)  # Print the full processed results DataFrame
    return results, processed
end

# To run these, you must manually run `use_plots()` locally, to avoid having Plots as a dependency...
use_plots() = @eval using Plots

plot_speedup(args...) = plot_speedup!(plot(), args...)
function plot_speedup!(p, processed, label)
    Plots.plot!(p, processed.nthreads, processed.speedup_factor,
        xticks = processed.nthreads,
        yticks = processed.nthreads,
        ylims = (1, min(Sys.CPU_THREADS, maximum(processed.nthreads))),
        xlabel = "JULIA_NUM_THREADS",
        ylabel = "speedup factor",
        label = label,
        left_margin=50px,
        bottom_margin=50px
    )
end
plot_abs_time(args...) = plot_abs_time!(plot(), args...)
function plot_abs_time!(p, processed, label)
    yticks = range(minimum(processed.time_secs), maximum(processed.time_secs), length=6)
    Plots.plot!(p, processed.nthreads, processed.time_secs,
        xticks = processed.nthreads,
        yticks = (yticks, ["$(Int(round(t))) secs" for t in yticks]),
        #yscale = :log10,
        xlabel = "JULIA_NUM_THREADS",
        #ylabel = "absolute time (secs)",
        label = label,
        left_margin=50px,
        bottom_margin=50px
    )
end
scalevec(v) = v ./ sum(v)
function plot_thread_counts(results, label)
    numrows = size(results, 1)
    range = numrows÷2 : numrows÷2 + 2
    normalized_tc = scalevec.(results.thread_counts[range])
    Plots.bar(normalized_tc,
        xlabel = "Thread ID",
        ylabel = "Num Queries",
        fillalpha = 0.2,
        title = label,
        labels = ["$(results.nthreads[r]) threads" for r in range],
        left_margin=50px,
        bottom_margin=50px
    )
end
function plot_latencies(results, label)
    nqueries = length(results.query_latencies_secs[1])
    xticks_labels = 0:0.10:1
    Plots.plot(sort.(results.query_latencies_secs),
        xticks = (xticks_labels * nqueries, ["$(Int(round(x*100)))%" for x in xticks_labels]),
        xlabel = "Percentile",
        yscale = :log10,
        labels = ["$t threads" for t in results.nthreads],
        title = "Query latencies (secs, log): \"$label\"",
        left_margin=50px,
        bottom_margin=50px
    )
end

function perform_scaling_experiment(;
        bench_file, nqueries, num_ops, plot_series_name, num_datapoints,
        # Test from 1 ... NUM_CORES, because julia doesn't let you go over that maximum
        nthreads_to_test = [1, Int.(round.(range(0, stop=NUM_CORES, length=num_datapoints)))[2:end]...],
        preprocess_results = identity,
        )

    println("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    println("Running benchmark for $bench_file")
    println("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")

    println("------ TEST PARAMETERS ------")
    @show nthreads_to_test
    @show nqueries
    @show num_ops

    println("warmup")
    bench_nthreads_scaling(bench_file, 1,  10, [5,6], # Warmup w/ nthreads > 1 (some tests require it)
                           preprocess_results);

    println("run benchmark")
    global results,processed = bench_nthreads_scaling(bench_file, nqueries,  num_ops,
                                                      nthreads_to_test, preprocess_results)

    plot_basename = splitext(basename(bench_file))[1]

    println("plot results")
    println("-- saving figures in $(pwd()) --")
    pp = plot_speedup(processed, plot_series_name)
    savefig(pp, "$plot_basename-speedup_plot.png")

    ap = plot_abs_time(processed, plot_series_name)
    savefig(ap, "$plot_basename-abs_time_plot.png")

    tp = plot_thread_counts(results, plot_series_name)
    savefig(tp, "$plot_basename-thread_counts.png")

    lp = plot_latencies(results, plot_series_name)
    savefig(lp, "$plot_basename-query_latencies.png")
end
