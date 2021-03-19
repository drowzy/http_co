defmodule HTTPCoTest do
  use ExUnit.Case
  alias HTTPCo.Response

  describe "connect/1" do
    setup do
      bypass = Bypass.open()
      {:ok, bypass: bypass}
    end

    test "connects successfully to provided host", %{bypass: bypass} do
      req = HTTPCo.get(endpoint_url(bypass))

      assert {:ok, _conn} = HTTPCo.connect(req)
    end

    test "returns error if connection is unsuccessful" do
      req = HTTPCo.get(endpoint_url(%{port: 5000}))

      assert {:error, reason} = HTTPCo.connect(req)
      assert reason == %Mint.TransportError{reason: :econnrefused}
    end
  end

  describe "run/1" do
    setup do
      bypass = Bypass.open()
      {:ok, bypass: bypass}
    end

    test "returns a %Response if the request is successfull", %{bypass: bypass} do
      req = HTTPCo.get(endpoint_url(bypass))
      # Bypass.expect_once(bypass, "GET", "/", &Plug.Conn.send_resp(&1, 200, "OK"))

      assert %Response{} = HTTPCo.run(req)
    end

    test "returns a %Response that can be awaited", %{bypass: bypass} do
      req = HTTPCo.get(endpoint_url(bypass))
      Bypass.expect_once(bypass, "GET", "/", &Plug.Conn.send_resp(&1, 200, "OK"))

      assert %Response{body: body} = req |> HTTPCo.run() |> Response.await()
      assert body == "OK"
    end
  end

  defp endpoint_url(%{port: port}), do: "http://localhost:#{port}/"
end
