module MultithreadingBenchmarks

"""
    MultithreadingBenchmarks.measure_work(f)
The main interface for the code to be benchmarked: provide a work function, `f(i,v,n)` which
will be called repeatedly in a loop based on the provided NUM_QUERIES and QUERY_SIZE
environment variables.
"""
function measure_work end


include("bench_harness.jl")
include("common.jl")

end # module
