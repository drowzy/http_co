defmodule HTTPCo.IteratorTest do
  use ExUnit.Case
  alias HTTPCo.Iterator

  describe "next/1" do
    test "calls the next function" do
      result =
        [next: &{:cont, &1}, state: :state]
        |> Iterator.new()
        |> Iterator.next()

      assert {:cont, %Iterator{state: :state}} = result
    end

    test "updates the state after running the next function" do
      result =
        [next: &{:halt, &1 <> " world"}, state: "hello"]
        |> Iterator.new()
        |> Iterator.next()

      assert {:halt, itr} = result
      assert itr.state == "hello world"
    end
  end

  describe "Enumerable impl" do
  end
end
