# Simple parallelism test to measure scaling of completely independent tasks.

using MultithreadingBenchmarks

function work(i, v, n)  # For n=10000000, takes ~2ms
    out = v
    for i in 1:n
        out *= v
    end
    out
end

MultithreadingBenchmarks.measure_work(work)
