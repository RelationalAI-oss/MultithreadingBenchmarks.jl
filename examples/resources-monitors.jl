# An example of handling incomming connections via "low-level" concurrency primitives:
# - Locks and Condition Variables (i.e. Monitors)
# In Julia, you should prefer to use Channels for this sort of thing whenever possible!
# See the simpler example in `resources-channels.jl` in this directory.
module ResourcesExample__Monitors

using Base.Threads: @spawn

const connections = Vector{IO}()
const cv = Threads.Condition()

finish(io::IO) = @info "Result: " readline(io)

function make_new_connection()
    @info "👋 New Connection"
    lock(cv) do
        push!(connections, IOBuffer())
        notify(cv)
    end
    @info "done"
end
function handle_connection(i)
    @info "Handler $i: online"
    lock(cv) do
        while isempty(connections)
            @info "Handler $i: waiting"
            wait(cv)
        end
        @info "Handler $i: got Connection!"
        c = pop!(connections)
        # Whoops, these two lines below actually don't need to be in the `lock`ed section.
        # We could move them out, but then `c` isn't defined. Not a problem in julia; we can
        # "return" `c` from the `lock`-block, but notice that it's easy to make this mistake.
        println(c, "HELLO")
        finish(c)
    end
end

function go()  # Ctrl-c to stop the "server" handlers
    @sync begin
        for _ in 1:3  # Create new connections
            @spawn begin
                sleep(rand(0.0:0.1:3.0))
                make_new_connection()
            end
        end
        for i in 1:2  # Handlers
            @spawn while true handle_connection(i) end
        end
    end
end

end # module
