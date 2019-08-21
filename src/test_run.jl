@noinline mul_barrier(a,b) = a*b
@noinline mul_barrier(a::Vector,b) = a[1]*b
@noinline mul_barrier(a,b::Vector) = a*b[1]

# Allocate in a loop until anything is pushed into `signal` Channel.
function allocate_in_background(signal::Channel, v)
# function allocate_in_background(v)
    # Since there is
    ALLOC_EVERY_N = 2048
    out = v
    i = 0
    while !isready(signal)
    #while true
        out_temp = if (i % ALLOC_EVERY_N == 0)
            vi = rand([[v], v])
            typeof(v)(mul_barrier(out, v))
        else
            out * v
        end
        out_temp::typeof(v)
        out = out_temp
        i += 1
    end
    return out
end

# Start a Task that will take over one thread and allocate garbage in the background
signal = Channel(1)
t = Threads.@spawn allocate_in_background(signal, 2)

@show t

put!(signal, 0)
wait(t)
