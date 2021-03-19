defmodule HTTPCo.RequestTest do
  use ExUnit.Case
  alias HTTPCo.Request

  doctest Request

  describe "constructors" do
    test "build/4" do
      assert %Request{} = req = Request.build(:get, "http://localhost/path?key=value", [], [])

      assert req.scheme == :http
      assert req.path == "/path"
      assert req.port == 80
      assert req.query == %{"key" => "value"}
      assert req.headers == []
      assert req.host == "localhost"
    end

    test "post/1 returns a request struct with method :post" do
      assert %Request{method: :post} = Request.post("http://localhost")
    end

    test "put/1 returns a request struct with method :put" do
      assert %Request{method: :put} = Request.put("http://localhost")
    end

    test "get/1 returns a request struct with method :get" do
      assert %Request{method: :get} = Request.get("http://localhost")
    end

    test "delete/1 returns a request struct with method :delete" do
      assert %Request{method: :delete} = Request.delete("http://localhost")
    end
  end

  describe "set_header/2" do
    test "adds the header pair to headers" do
      header = {"Content-type", "application/json"}
      req = %Request{query: %{}}
      assert %Request{headers: headers} = Request.set_header(req, header)

      assert hd(headers) == header
    end
  end

  describe "request_path/1" do
    test "returns `path` only if there's no query params" do
      req = %Request{query: %{}, path: "/foo"}
      assert "/foo" == Request.request_path(req)
    end

    test "returns `<path>?<query0>&<query..n>` if query params are set" do
      req = %Request{query: %{"key" => "value", "key2" => "value2"}, path: "/foo"}
      assert "/foo?key=value&key2=value2" == Request.request_path(req)
    end
  end

  describe "setters" do
    test "adds the header pair to headers" do
      header = {"Content-type", "application/json"}
      req = %Request{}
      assert %Request{headers: headers} = Request.set_header(req, header)

      assert hd(headers) == header
    end

    test "adds query kv pair to query" do
      req = %Request{query: %{}}
      assert %Request{query: query} = Request.set_query_item(req, {"key", "value"})

      assert Map.get(query, "key") == "value"
    end
  end

  describe "into_conn/1" do
    test "for unix socket" do
      socket_path = "/var/run/docker.sock"
      url = "unix://#{socket_path}"
      req = Request.get(url)

      assert {:http, {:local, ^socket_path}, 0} = Request.into_conn(req)
    end

    test "for unix socket + http scheme" do
      socket_path = "/var/run/docker.sock"
      url = "http+unix://#{socket_path}"
      req = Request.get(url)

      assert {:http, {:local, ^socket_path}, 0} = Request.into_conn(req)
    end

    test "for http" do
      host = "httpbin.org"
      url = "http://#{host}"
      req = Request.get(url)

      assert {:http, ^host, 80} = Request.into_conn(req)
    end
  end
end
