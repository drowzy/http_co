defmodule HTTPCo.Iterator do
  @type state :: term()
  @type next_fn :: (state() -> {:cont, state()} | {:halt, state()})
  @type process_fn :: (state() -> term())
  @type t :: %__MODULE__{
          next: next_fn(),
          process: process_fn(),
          state: state()
        }

  defstruct [
    :next,
    :process,
    :state
  ]

  @spec new(Keyword.t()) :: t()
  def new(opts) do
    struct(__MODULE__, opts)
  end

  @spec next(t()) :: {:cont, t()} | {:halt, t()}
  def next(%__MODULE__{next: next_fn, state: state} = itr) do
    {proc_state, state} = next_fn.(state)
    {proc_state, %{itr | state: state}}
  end
end

defimpl Enumerable, for: HTTPCo.Iterator do
  alias HTTPCo.Iterator

  def reduce(%Iterator{}, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  def reduce(%Iterator{} = itr, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce(itr, &1, fun)}
  end

  def reduce(%Iterator{process: process} = itr, {:cont, acc}, fun) do
    case Iterator.next(itr) do
      {:cont, itr} ->
        acc = do_process(itr, process, acc, fun)

        reduce(itr, acc, fun)

      {:halt, itr} ->
        acc = do_process(itr, process, acc, fun)

        {:done, acc}
    end
  end

  def count(_stream) do
    {:error, HTTPCo.Iterator}
  end

  def member?(_stream, _term) do
    {:error, HTTPCo.Iterator}
  end

  def slice(_stream) do
    {:error, HTTPCo.Iterator}
  end

  defp do_process(itr, process, acc, fun) do
    itr.state
    |> process.()
    |> fun.(acc)
  end
end
