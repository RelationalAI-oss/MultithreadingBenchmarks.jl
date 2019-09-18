#

include("../src/common.jl")

function work(i, v, n)
    out = v
    for i in 1:n
        mul = @eval (a) -> a*$v
        out = Base.invokelatest(mul, out)
    end
    return out
end

#@time work(1,2,100)
#
#using PProf
#PProf.clear(); @pprof @sync begin
#    Threads.@spawn work(1, 2, 100)
#    Threads.@spawn work(1, 2, 100)
#    Threads.@spawn work(1, 2, 100)
#    Threads.@spawn work(1, 2, 100)
#end

measure_work()
