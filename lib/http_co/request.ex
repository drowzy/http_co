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

  @spec get(url()) :: t()
  def get(url) do
    build(:get, url, [], [])
  end

  @spec post(url()) :: t()
  def post(url) do
    build(:post, url, [], [])
  end

  @spec put(url()) :: t()
  def put(url) do
    build(:put, url, [], [])
  end

  @spec delete(url()) :: t()
  def delete(url) do
    build(:delete, url, [], [])
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

  @spec into_conn(t()) :: {term(), term()}
  def into_conn(%__MODULE__{
        method: method,
        path: path,
        host: host,
        port: port,
        scheme: scheme
      }) do
    method = method_to_string(method)

    case scheme do
      :unix -> {method, {:http, {:local, path}, 0}}
      scheme -> {method, {scheme, host, port}}
    end
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
    scheme = parse_scheme(uri.scheme, uri)

    {scheme, uri.host, uri.port, path, query}
  end

  defp parse_scheme("https", _), do: :https
  defp parse_scheme("http", _), do: :http
  defp parse_scheme("http+unix", _), do: :unix
  defp parse_scheme("unix", _), do: :unix

  defp parse_scheme(nil, uri),
    do: raise(ArgumentError, "scheme is required for url: #{URI.to_string(uri)}")

  defp parse_scheme(scheme, uri),
    do: raise(ArgumentError, "invalid scheme \"#{scheme}\" for url: #{URI.to_string(uri)}")

  defp qs(query) when map_size(query) == 0, do: ""
  defp qs(query), do: "?" <> URI.encode_query(query)
  defp method_to_string(method), do: method |> Atom.to_string() |> String.upcase()
end
