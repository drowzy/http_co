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
    test "generates values using next" do
      next_fn = fn
        count when count < 10 -> {:cont, count + 1}
        count -> {:halt, count}
      end

      process = &Function.identity/1

      opts = [next: next_fn, process: process, state: 0]
      itr = Iterator.new(opts)

      assert Enum.take(itr, 1) == [1]
    end

    test "calls process for each iteration" do
      next_fn = fn
        count when count < 1 -> {:cont, count + 1}
        count -> {:halt, count}
      end

      process = &(&1 + 1)

      opts = [next: next_fn, process: process, state: 0]

      values =
        opts
        |> Iterator.new()
        |> Enum.take(1)

      assert values == [2]
    end
  end
end
