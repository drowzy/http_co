defmodule HTTPCo.Request do
  @type t :: %__MODULE__{}

  defstruct [
    :scheme,
    :host,
    :port,
    :method,
    :headers,
    :path,
    :query,
    :body
  ]

  @type http_method :: :post | :put | :get | :delete
  @type url :: String.t() | Uri.t()
  @type header_value :: {String.t(), String.t()}

  @spec get(url(), list()) :: t()
  def get(url, headers \\ []) do
    build(:get, url, headers, [])
  end

  @spec post(url(), list()) :: t()
  def post(url, headers \\ []) do
    build(:post, url, headers, [])
  end

  @spec put(url(), list()) :: t()
  def put(url, headers \\ []) do
    build(:put, url, headers, [])
  end

  @spec delete(url(), list()) :: t()
  def delete(url, headers \\ []) do
    build(:delete, url, headers, [])
  end

  @spec build(http_method(), url(), list(), iodata()) :: t()
  def build(method, url, headers, body) do
    {scheme, host, port, path, query} = parse_url(url)

    %__MODULE__{
      scheme: scheme,
      host: host,
      port: port,
      method: method,
      headers: headers,
      path: path,
      query: query,
      body: body
    }
  end

  @spec request_path(t()) :: String.t()
  def request_path(%__MODULE__{path: path, query: query}) do
    path <> qs(query)
  end

  @spec set_header(t(), header_value()) :: t()
  def set_header(%__MODULE__{headers: headers} = req, header) do
    %{req | headers: [header | headers]}
  end

  @spec set_query_item(t(), {String.t(), String.t()}) :: t()
  def set_query_item(%__MODULE__{query: query} = req, {key, value}) do
    %{req | query: Map.put(query, key, value)}
  end

  @spec body(t(), iodata()) :: t()
  def body(%__MODULE__{} = req, body) do
    %{req | body: body}
  end

  defp parse_url(url) when is_binary(url) do
    url
    |> URI.parse()
    |> parse_url()
  end

  defp parse_url(%URI{} = uri) do
    path = uri.path || "/"
    query = URI.decode_query(uri.query || "")
    scheme = parse_scheme(uri.scheme)

    {scheme, uri.host, uri.port, path, query}
  end

  defp parse_scheme("https"), do: :https
  defp parse_scheme("http"), do: :http
  defp parse_scheme("http+unix"), do: :unix
  defp parse_scheme("unix"), do: :unix

  defp qs(query) when map_size(query) == 0, do: ""
  defp qs(query), do: "?" <> URI.encode_query(query)
end
