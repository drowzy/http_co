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
