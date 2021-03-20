defmodule HTTPCo do
  @moduledoc """
  A composable HTTP client library for Elixir
  """

  alias HTTPCo.{Request, Response}

  defdelegate post(url), to: Request
  defdelegate put(url), to: Request
  defdelegate get(url), to: Request
  defdelegate delete(url), to: Request

  @spec run(Mint.HTTP.t(), Request.t()) :: Response.t()
  def run(conn, %Request{headers: headers, body: body} = req) do
    path = Request.request_path(req)
    method = Request.method_to_string(req)

    case Mint.HTTP.request(conn, method, path, headers, body) do
      {:ok, conn, ref} ->
        Response.new(conn: conn, ref: ref)

      {:error, conn, reason} ->
        [conn: conn]
        |> Response.new()
        |> Response.with_error(reason)
    end
  end

  @spec run(Request.t()) :: Response.t()
  def run(%Request{} = req) do
    case connect(req) do
      {:ok, conn} ->
        run(conn, req)

      {:error, reason} ->
        []
        |> Response.new()
        |> Response.with_error(reason)
    end
  end

  @spec connect(Request.t()) :: {:ok, Mint.HTTP.t()} | {:error, Mint.Types.error()}
  def connect(%Request{} = req) do
    {scheme, host, port} = Request.into_conn(req)

    Mint.HTTP.connect(scheme, host, port)
  end
end
