import Base.Threads: @spawn
using BenchmarkTools
using TimerOutputs

const n = parse(Int, ENV["QUERY_SIZE"])
const N = parse(Int, ENV["NUM_QUERIES"])

const thread_counts = fill(0, Threads.nthreads())
const query_latencies_secs = fill(0.0, N)

function main(n, N)
    vs = fill(0, N)
    thread_counts[:] = fill(0, Threads.nthreads())[:]
    query_latencies_secs[:] = fill(0.0, N)[:]

    @sync begin
        for i in 1:N
            @spawn begin
                # Record value in vs (so work isn't compiled away)
                # Record latency for this query
                vs[i], query_latencies_secs[i] = @timed work(i, 2, n)
                # Count how many queries are handled on each thread
                thread_counts[Threads.threadid()] += 1
            end
        end
    end
    sum(vs)
end

function measure_work()
    b = @benchmark main($n, $N);

    # RETURN RESULTS TO test_harness.jl BY PRINTING THEM
    println(minimum(b).time)
    println(minimum(b).allocs)
    println(minimum(b).memory)
    println(minimum(b).gctime)
    println(repr(thread_counts))
    println(repr(query_latencies_secs))
end
