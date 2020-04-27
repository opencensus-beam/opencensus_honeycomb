# OpenTelemetry.Honeycomb

[![Build status badge](https://github.com/garthk/opentelemetry_honeycomb/workflows/Elixir%20CI/badge.svg)](https://github.com/garthk/opentelemetry_honeycomb/actions)
[![Hex version badge](https://img.shields.io/hexpm/v/opentelemetry_honeycomb.svg)](https://hex.pm/packages/opentelemetry_honeycomb)

<!-- MDOC !-->

`opentelemetry_honeycomb` provides an in-process [OpenTelemetry] exporter for [Honeycomb].

[OpenTelemetry]: https://opentelemetry.io
[Honeycomb]: https://www.honeycomb.io

## Installation

Add `opentelemetry`, `opentelemetry_api`, and `opentelemetry_honeycomb` to your `deps` in
`mix.exs`:

```elixir
{:opentelemetry, "~> 0.4.0"},
{:opentelemetry_api, "~> 0.3.1"},
{:opentelemetry_honeycomb, "~> 0.3.0-rc.0"},
```

If you're using the default back ends, you'll also need `hackney` and `poison`:

```elixir
{:hackney, ">= 1.11.0"},
{:poison, ">= 1.5.0"},
```

## Configuration

<!-- CDOC !-->

A compact `config/config.exs` for `opentelemetry_honeycomb` is:

```elixir
use Config

# You can also supply opentelemetry resources using environment variables, eg.:
# OTEL_RESOURCE_LABELS=service.name=name,service.namespace=namespace

config :opentelemetry, :resource,
  service: [
    name: "service-name",
    namespace: "service-namespace"
]

config :opentelemetry,
  processors: [
    ot_batch_processor: %{
    exporter:
      {OpenTelemetry.Honeycomb.Exporter, write_key: System.get_env("HONEYCOMB_WRITEKEY")}
    }
]
```

`processors` specifies `ot_batch_processor`, which specifies `exporter`, a 2-tuple of the
exporter's module name and options to be supplied to its `init/1`. Our exporter takes a list of
`t:OpenTelemetry.Honeycomb.Config.config_opt/0` as its options.

<!-- CDOC !-->

## Attribute Handling

<!-- ADOC !-->

OpenTelemetry supports a flat map of attribute keys to string, number, and boolean values (see
`t.OpenTelemetry.attribute_value/0`). The API does not _enforce_ this, implicitly supporting other
attribute value types _eg._ maps until export time.

Honeycomb expects a flat JSON-serialisable object, but can be configured to flatten maps and
stringify arrays at import time.

The data models being quite similar, we:

* Pass string, number, and boolean values through unmodified
* Flatten map values as described below
* Convert most other values to strings using `inspect/1` with a short `limit`
* Trim string values longer than [49127 bytes]

[49127 bytes]: https://docs.honeycomb.io/authentication-and-security/secure-tenancy/#product-limitations-when-using-secure-tenancy

<!-- TRIMDOC !-->
When trimming strings, we replace the last 3-7 characters of the trimmed string or so with an
ellipsis (`"..."`) of equal length. We choose the length of the ellipsis to avoid ending the
trimmed string with a high-bit character, _eg._ splitting a UTF-8 code point.
<!-- TRIMDOC !-->

We drop:

* Entire attribute lists that don't start as a list or map
* Entire list members that don't resemble key/value pairs

When flattening maps, we use periods (`.`) to delimit keys, for example this input:

```elixir
%{
  http: %{
    host:  "localhost",
    method: "POST",
    path: "/api"
  }
}
```

... to this output:

```elixir
%{
  "http.host" => "localhost",
  "http.method" => "POST",
  "http.path" => "/api",
}
```

<!-- ADOC !-->
<!-- MDOC !-->

## Verification

First, we need to check `:opentelemetry` and `:opentelemetry_api`. Fire up `iex -S mix` and paste
in the following code to install the `:ot_exporter_stdout` exporter:

```elixir
:ot_batch_processor.set_exporter(:ot_exporter_stdout, [])
```

After a delay, you should see:

```plain
*SPANS FOR DEBUG*
*SPANS FOR DEBUG*
*SPANS FOR DEBUG*
```

Now, paste in some trace-sending code:

```elixir
require OpenTelemetry.Tracer
require OpenTelemetry.Span

OpenTelemetry.Tracer.start_span("some-span")
OpenTelemetry.Tracer.current_span_ctx()
OpenTelemetry.Span.set_attributes(%{b: %{c: 2}})
OpenTelemetry.Tracer.end_span()
```

You should get output resembling:

```erlang
{span,243384816483509084844220162257481913277,10418680972954126737,undefined,
      undefined,<<"some-span">>,'SPAN_KIND_UNSPECIFIED',-576460736343282000,
      -576460736342566000,
      #{b => #{c => 2}},
      [],[],undefined,undefined,1,true,undefined}
```

Next, we need to check `OpenTelemetry.Honeycomb.Exporter`. Paste in:

```elixir
# hard way
:ot_batch_processor.set_exporter(OpenTelemetry.Honeycomb.Exporter,
  http_module: OpenTelemetry.Honeycomb.Http.ConsoleBackend,
  write_key: "HONEYCOMB_WRITEKEY"
)

# easy way
OpenTelemetry.Honeycomb.Http.ConsoleBackend.activate()
```

Paste in the trace-sending code again to see what the OpenTelemetry Honeycomb Exporter would have
sent to Honeycomb:

```plain
POST /1/batch/opentelemetry HTTP/1.1
Host: api.honeycomb.io
Content-Type: application/json
User-Agent: opentelemetry_honeycomb/0.3.0-rc.0
X-Honeycomb-Team: HONEYCOMB_WRITEKEY

[
  {
    "time": "2020-04-24T06:12:16.698425Z",
    "samplerate": 1,
    "data": {
      "trace.trace_id": "6c14288156831d40602dc1f5a61489c0",
      "trace.span_id": "377fce3346b92811",
      "trace.parent_id": null,
      "service.namespace": "service-namespace",
      "service.name": "service-name",
      "name": "some-span",
      "duration_ms": 6.06005859375,
      "b.c": 2
    }
  }
]
```

Restore your configured exporter by pasting:

```elixir
OpenTelemetry.Honeycomb.Http.ConsoleBackend.deactivate()
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

## Changes since Opencensus.Honeycomb

* Removed decorator: use resources or extra processors.
