defmodule OpenTelemetry.Honeycomb.Http do
  @moduledoc """
  HTTP back end.

  The OpenTelemetry Honeycomb Exporter uses a Hackney-style HTTP client via a behaviour so
  you can adapt it to your preferred HTTP client. We supply 2-3 clients:

  * `OpenTelemetry.Honeycomb.Http.HackneyBackend` (only if `:hackney` is present)
  * `OpenTelemetry.Honeycomb.Http.WriteKeyMissingBackend`
  * `OpenTelemetry.Honeycomb.Http.ConsoleBackend`
  """

  @typedoc "HTTP method"
  @type method :: :post

  @typedoc "HTTP headers"
  @type headers :: list({String.t(), String.t()})

  @typedoc "Request body"
  @type body :: iodata()

  @typedoc "URL"
  @type url :: String.t()

  @typedoc "HTTP status code"
  @type status :: integer()

  @typedoc "Client response"
  @type response ::
          {:ok, status(), headers(), body()} | {:ok, status(), headers()} | {:error, term()}

  @doc """
  Make an HTTP request.

  See `:hackney.request/5`.
  """
  @callback request(
              method :: method(),
              url :: url(),
              headers :: headers(),
              body :: body(),
              opts :: keyword()
            ) :: response()

  @typedoc """
  Configuration option for `request!/5`:

  * `http_module`: the HTTP back end module
  * `http_options`: options to pass to the HTTP back end
  """
  @type config_opt :: {:http_module, module()} | {:http_options, Keyword.t()}

  @doc """
  Return the default configuration for `request!/5`.
  """
  def default_config,
    do: [
      http_module: OpenTelemetry.Honeycomb.Http.HackneyBackend,
      http_options: [
        recv_timeout: 30_000,
        max_connections: 4,
        pool: :opentelemetry_honeycomb
      ]
    ]

  @doc """
  Make an HTTP request using the configured back end and options.

  Heavy on guards to limit the exporter's use of the API to the back end's documented subset of
  `:hackney.request/5`.
  """
  @spec request(
          config :: [config_opt()],
          method :: method(),
          url :: url(),
          headers :: headers(),
          body :: body(),
          opts :: keyword()
        ) :: response()
  def request(
        config,
        method,
        url,
        headers,
        body,
        opts
      )
      when is_list(config) and
             is_atom(method) and method in [:post] and
             is_binary(url) and
             is_list(headers) and
             (is_binary(body) or is_list(body)) and
             is_list(opts) do
    http_module = Keyword.fetch!(config, :http_module)
    http_options = Keyword.fetch!(config, :http_options)

    opts = Keyword.merge(http_options, opts)
    http_module.request(method, url, headers, body, opts)
  end
end
