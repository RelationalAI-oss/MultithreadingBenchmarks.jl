#

using MultithreadingBenchmarks

function work(i, v, n)
    out = v
    for i in 1:n
        out *= v
    end
    out
end

@noinline mul_barrier(a,b) = a*b
@noinline mul_barrier(a::Vector,b) = a[1]*b
@noinline mul_barrier(a,b::Vector) = a*b[1]

# Allocate in a loop until anything is pushed into `signal` Channel.
function allocate_in_background(signal::Channel, v)
    # Since there is
    ALLOC_EVERY_N = 2
    GC_EVERY_N = 1024
    out = v
    i = 0
    while !isready(signal)
        out_temp = if (i % ALLOC_EVERY_N == 0)
            vi = rand([[v], v])
            typeof(v)(mul_barrier(out, v))
        else
            out * v
        end
        out_temp::typeof(v)
        out = out_temp
        i += 1

        # Manually trigger the GC every so often, since it wasn't running on its own
        if (i % GC_EVERY_N == 0)
            GC.gc()
        end

        # TODO: But if we add this yield-point does it occupy the thread correctly?
        #yield()  # We need this yield-point so this "background" task doesn't keep julia alive.
    end
    return out
end

# ----------------------------
# Start a Task that will take over one thread and allocate garbage in the background
signal = Channel(1)
t = Threads.@spawn allocate_in_background(signal, 2)
# ----------------------------

MultithreadingBenchmarks.measure_work(work)

# ------------------------
put!(signal, 0)
wait(t)
# ------------------------
