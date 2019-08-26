ccall((:init_thread_pool, "build/cpp-native-threads.dylib"), Cvoid, ())

function cppcall(x::Int)
    response = Ref(x) # heap-allocated
    ch = Channel{Int}(0)
    t = Task(()->put!(ch, response[]))
    t.sticky = false
    ccall((:enqueue, "build/cpp-native-threads.dylib"), Cvoid,
          (Cint, Any, Csize_t, Any), x, response, sizeof(eltype(response)), t)
    ch
end

ch = cppcall(2)
take!(ch)

chs = Any[]
for x in 1:5
    push!(chs, cppcall(x))
end
outs = collect(take!(ch) for ch in chs)
display(outs)
