# Opencensus.Honeycomb

Posts [OpenCensus] spans to [Honeycomb].

[OpenCensus]: https://opencensus.io
[Honeycomb]: https://www.honeycomb.io

## Installation

* Take the dependency
* Make sure it's supervised
* Configure it
* Check its all working

### Dependency

Add `opencensus_honeycomb` to your `deps` in `mix.exs`:

```elixir
{:opencensus_honeycomb, "~> 0.1"}
```

Then, `mix deps.get` and `mix deps.compile` as usual.

### Configuration

In your `config/config.exs`, configure `:opencensus` and
`:opencensus_honeycomb`:

```eixir
config :opencensus,
  reporters: [{Opencensus.Honeycomb.Reporter, []}],
  send_interval_ms: 1000

config :opencensus_honeycomb,
  dataset: "opencensus",
  service_name: "your_app",
  write_key: System.get_env("HONEYCOMB_WRITEKEY")
```

### Verification

`iex -S mix`, then:

    iex> Application.get_env(:opencensus, :reporters)
    [{Opencensus.Honeycomb.Reporter, []}]

    iex> Application.get_all_env(:opencensus_honeycomb)
    [write_key: "...", service_name: "...", dataset: "..."]

    iex> :ocp.with_child_span("test")
    :undefined

    iex> :ocp.current_span_ctx()
    {:span_ctx, 33234766236774033950150561980069751240,
     12010566695198730064, 1, :undefined}

    iex> :ocp.finish_span()
    true

If you don't notice any sending, check the registration in case the config
format changed again. Register manually, then try again:

    iex> :oc_reporter.register(Opencensus.Honeycomb.Reporter, [])
    :ok

Once you've seen some spans, try a stack of ten:

    iex> 1..10 |> Enum.map(&to_string/1) |> Enum.map(&:ocp.with_child_span/1)
    [
      :undefined,
      {:span_ctx, 322560190005584483565962561333424343439,
       7924041616779114111, 1, :undefined},
       ...
      {:span_ctx, 322560190005584483565962561333424343439,
       14682319351797855820, 1, :undefined},
    ]

    iex>  1..10 |> Enum.map(fn _ -> :ocp.finish_span() end)
    [true, true, true, true, true, true, true, true, true, true]

## Telemetry

Opencensus.Honeycomb calls `:telemetry.execute/2` before and after sending.
To get an idea without reading the in-code documentation, run the following
at the `iex -S mix` prompt:

```elixir
alias Opencensus.Honeycomb.{Config,Event,Sender}
Config.put(%{write_key: nil})
handle_event = fn n, measure, meta, _ -> IO.inspect({n, measure, meta}) end
:telemetry.attach_many("test", Sender.telemetry_events(), handle_event, nil)
[%Event{time: Event.now(), data: %{name: "hello"}}] |> Sender.send_batch()
```

You should see two events inspected:

```elixir
{[:opencensus, :honeycomb, :start], %{count: 1},
 %{
   events: [
     # ...
   ]
 }}

{[:opencensus, :honeycomb, :stop, :success], %{count: 1, ms: 5.535},
 %{
   events: [
     # ...
   ],
   payload: "..."
 }}
```

Want to see that against the production API?

```elixir
Config.put(%{
  write_key: System.get_env("HONEYCOMB_WRITEKEY"),
  dataset: "smoketest"
})
[%Event{time: Event.now(), data: %{name: "hello"}}] |> Sender.send_batch()
```

## Development

Dependency management:

* `mix deps.get` to get your dependencies
* `mix deps.compile` to compile them
* `mix licenses` to check their license declarations, recursively

Finding problems:

* `mix compile` to compile your code
* `mix credo` to suggest more idiomatic style for it
* `mix dialyzer` to find problems static typing might spot... *slowly*
* `mix test` to run unit tests
* `mix test.watch` to run the tests again whenever you change something
* `mix coveralls` to check test coverage

Documentation:

* `mix docs` to generate documentation for this project
* `mix help` to find out what else you can do with `mix`
