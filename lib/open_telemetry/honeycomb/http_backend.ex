defmodule OpenTelemetry.Honeycomb.HttpBackend do
  @moduledoc """
  HTTP back end.

  The OpenTelemetry Honeycomb Exporter uses a Hackney-style HTTP client via a behaviour so
  you can adapt it to your preferred JSON encoder.
  """

  alias OpenTelemetry.Honeycomb.HttpBackend.HackneyBackend

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

  @doc """
  Return the default back end's module.
  """
  def default_module, do: HackneyBackend

  @doc """
  Return the default back end's options.
  """
  def default_options,
    do: [
      recv_timeout: 30_000,
      max_connections: 4,
      pool: :opentelemetry_honeycomb
    ]

  @typedoc "Configuration for `request!/5`."
  @type config :: %{
          required(:http_module) => module(),
          required(:http_options) => Keyword.t(),
          optional(any()) => any()
        }

  @doc """
  Make an HTTP request using the configured back end and options.

  Heavy on guards to limit the exporter's use of the API to the back end's documented subset of
  `:hackney.request/5`.
  """
  @spec request(
          config :: config(),
          method :: method(),
          url :: url(),
          headers :: headers(),
          body :: body(),
          opts :: keyword()
        ) :: response()
  def request(
        %{http_module: http_module, http_options: http_options},
        method,
        url,
        headers,
        body,
        opts
      )
      when is_atom(method) and method in [:post] and
             is_binary(url) and
             is_list(headers) and
             (is_binary(body) or is_list(body)) and
             is_list(opts) do
    opts = Keyword.merge(http_options, opts)
    http_module.request(method, url, headers, body, opts)
  end
end

defmodule OpenTelemetry.Honeycomb.HttpBackend.HackneyBackend do
  @moduledoc false
  @behaviour OpenTelemetry.Honeycomb.HttpBackend
  @impl true
  def request(method, url, body, headers, opts) do
    opts = Keyword.merge([with_body: true], opts)
    :hackney.request(method, url, body, headers, opts)
  end
end
