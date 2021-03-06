# See https://github.com/JuliaWeb/HTTP.jl/pull/288

using Test
using HTTP

@testset "HTTP.Issues.288" begin

sz = 90

hex(n) = string(n, base=16)

encoded_data = "$(hex(sz + 9))\r\n" * "data: 1$(repeat("x", sz))\n\n" * "\r\n" *
               "$(hex(sz + 9))\r\n" * "data: 2$(repeat("x", sz))\n\n" * "\r\n" *
               "$(hex(sz + 9))\r\n" * "data: 3$(repeat("x", sz))\n\n" * "\r\n"

decoded_data = "data: 1$(repeat("x", sz))\n\n" * 
               "data: 2$(repeat("x", sz))\n\n" * 
               "data: 3$(repeat("x", sz))\n\n"

split1 = 106
split2 = 300

@async HTTP.listen("127.0.0.1", 8091) do http::HTTP.Stream
    startwrite(http)

    tcp = http.stream.c.io

    write(tcp, encoded_data[1:split1])
    flush(tcp)
    sleep(1)

    write(tcp, encoded_data[split1+1:split2])
    flush(tcp)
    sleep(1)

    write(tcp, encoded_data[split2+1:end])
    flush(tcp)
end

sleep(1)

r = HTTP.get("http://127.0.0.1:8091")

@test String(r.body) == decoded_data

r = ""

HTTP.open("GET", "http://127.0.0.1:8091") do io

    x = split(decoded_data, "\n")
    for i in 1:6
        l = readline(io)
        @test l == x[i]
        r *= l * "\n"
    end
end

@test r == decoded_data

end # @testset
