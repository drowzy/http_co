defmodule HTTPCo do
  @moduledoc """
  A composable HTTP client library for Elixir
  """

  alias HTTPCo.{Request, Response}

  defdelegate post(url), to: Request
  defdelegate put(url), to: Request
  defdelegate get(url), to: Request
  defdelegate delete(url), to: Request

  @spec run(Request.t()) :: Response.t()
  def run(%Request{headers: headers, body: body} = req) do
    path = Request.request_path(req)
    method = Request.method_to_string(req)

    with {:ok, conn} <- connect(req),
         {:ok, conn, ref} <- Mint.HTTP.request(conn, method, path, headers, body) do
      Response.new(conn: conn, ref: ref)
    else
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
