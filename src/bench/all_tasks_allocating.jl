#

include("../common.jl")

@noinline mul_barrier(a,b) = a*b
@noinline mul_barrier(a::Vector,b) = a[1]*b
@noinline mul_barrier(a,b::Vector) = a*b[1]

function work(i, v, n)
    ALLOC_EVERY_N = 100
    out = v
    for i in 1:n
        out_temp = if (i % ALLOC_EVERY_N == 0)
            vi = rand([[v], v])
            typeof(v)(mul_barrier(out, v))
        else
            out * v
        end
        out_temp::typeof(v)
        out = out_temp
    end
    return out
end

measure_work()
