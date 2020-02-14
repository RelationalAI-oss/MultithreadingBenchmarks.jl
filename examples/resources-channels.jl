# An example of handling incomming connections via Channels, which is the prefered,
# CSP-style approach to concurrency.
# Note that the code is simpler, and the locked regions are much smaller.
module ResourcesExample__Channels

using Base.Threads: @spawn

const connections = Channel{IO}()

finish(io::IO) = @info "Result: " readline(io)

function make_new_connection()
    @info "👋 New Connection"
    put!(connections, IOBuffer())
    @info "done"
end
function handle_connection(i)
    @info "Handler $i: online"
    c = take!(connections)
    @info "Handler $i: got Connection!"
    println(c, "HELLO")
    finish(c)
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
