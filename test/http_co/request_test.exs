defmodule HTTPCo.RequestTest do
  use ExUnit.Case
  doctest HTTPCo.Request

  describe "constructors" do
    test "build/4" do
      assert %HTTPCo.Request{} =
               req = HTTPCo.Request.build(:get, "http://localhost/path?key=value", [], [])

      assert req.scheme == :http
      assert req.path == "/path"
      assert req.port == 80
      assert req.query == %{"key" => "value"}
      assert req.headers == []
      assert req.host == "localhost"
    end

    test "post/1 returns a request struct with method :post" do
      assert %HTTPCo.Request{method: :post} = HTTPCo.Request.post("http://localhost")
    end

    test "put/1 returns a request struct with method :put" do
      assert %HTTPCo.Request{method: :put} = HTTPCo.Request.put("http://localhost")
    end

    test "get/1 returns a request struct with method :get" do
      assert %HTTPCo.Request{method: :get} = HTTPCo.Request.get("http://localhost")
    end

    test "delete/1 returns a request struct with method :delete" do
      assert %HTTPCo.Request{method: :delete} = HTTPCo.Request.delete("http://localhost")
    end
  end

  describe "set_header/2" do
    test "adds the header pair to headers" do
      header = {"Content-type", "application/json"}
      req = %HTTPCo.Request{query: %{}}
      assert %HTTPCo.Request{headers: headers} = HTTPCo.Request.set_header(req, header)

      assert hd(headers) == header
    end
  end

  describe "request_path/1" do
    test "returns `path` only if there's no query params" do
      req = %HTTPCo.Request{query: %{}, path: "/foo"}
      assert "/foo" == HTTPCo.Request.request_path(req)
    end

    test "returns `<path>?<query0>&<query..n>` if query params are set" do
      req = %HTTPCo.Request{query: %{"key" => "value", "key2" => "value2"}, path: "/foo"}
      assert "/foo?key=value&key2=value2" == HTTPCo.Request.request_path(req)
    end
  end

  describe "setters" do
    test "adds the header pair to headers" do
      header = {"Content-type", "application/json"}
      req = %HTTPCo.Request{}
      assert %HTTPCo.Request{headers: headers} = HTTPCo.Request.set_header(req, header)

      assert hd(headers) == header
    end

    test "adds query kv-pari to query" do
      req = %HTTPCo.Request{query: %{}}
      assert %HTTPCo.Request{query: query} = HTTPCo.Request.set_query_item(req, {"key", "value"})

      assert Map.get(query, "key") == "value"
    end
  end
end
