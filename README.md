# HTTPCo

A composable HTTP client library for Elixir

```elixir
"http://httpbin.org"
|> HTTPCo.get()
|> HTTPCo.Request.set_header({"Accept", "application/json"})
|> HTTPCo.Request.set_query({"key", "value"})
|> HTTPCo.run()
|> HTTPCo.Response.map_ok(&:erlang.iolist_to_binary/1)
|> HTTPCo.Response.map_ok(&Jason.decode/1)
|> HTTPCo.Response.map_err(&Error.handler/1)
|> HTTPCo.Response.into_response()
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `http_co` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:http_co, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/http_co](https://hexdocs.pm/http_co).
