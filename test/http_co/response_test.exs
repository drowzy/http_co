defmodule HTTPCo.ResponseTest do
  use ExUnit.Case
  alias HTTPCo.Response

  @http_response "HTTP/1.1 200 OK\r\ncache-control: max-age=0, private, must-revalidate\r\ncontent-length: 2\r\ndate: Sat, 20 Mar 2021 10:48:30 GMT\r\nserver: Cowboy\r\n\r\nOK"
  @msg {:tcp, :ok, @http_response}

  describe "await/2" do
    setup do
      ref = make_ref()
      {:ok, response: Response.new(conn: %{}, ref: ref, message_handler: make_handler(ref))}
    end

    test "should receive message and loop until done", %{response: res} do
      send(self(), @msg)

      assert %Response{} = res = Response.await(res)
      assert res.headers == [{"content-type", "application/json"}]
      assert res.body == ["OK"]
      assert res.status_code == 200
    end
  end

  describe "into" do
    test "into_raw_response/1 returns the raw body" do
      body = ["OK"]
      res = Response.new(body: body)

      assert body == Response.into_raw_response(res)
    end

    test "into_binary/1 returns a binary the http body" do
      body = ["OK"]
      res = Response.new(body: body)

      assert "OK" == Response.into_binary(res)
    end

    test "into_response/1 returns the raw response when fns are empty" do
      body = ["OK"]
      res = Response.new(body: body)

      assert body == Response.into_response(res)
    end

    test "into_response/1 returns runs the functions serially over the response body" do
      body = ["OK"]

      res =
        [body: body]
        |> Response.new()
        |> Response.map_ok(&["ADDED" | &1])

      assert ["ADDED", "OK"] == Response.into_response(res)
    end
  end

  defp make_handler(ref) do
    fn conn, {_, _, _} ->
      {:ok, conn,
       [
         {:status, ref, 200},
         {:headers, ref, [{"content-type", "application/json"}]},
         {:data, ref, "OK"},
         {:done, ref}
       ]}
    end
  end
end
