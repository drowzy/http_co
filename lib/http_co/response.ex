defmodule HTTPCo.Response do
  alias HTTPCo.Iterator
  @type t :: %__MODULE__{}
  @type mfargs :: {m :: module(), f :: atom(), a :: [term()] | :undefined}

  defstruct ref: nil,
            conn: nil,
            errors: nil,
            status_code: nil,
            content_length: 0,
            headers: [],
            body: [],
            message_handler: &Mint.HTTP.recv/3,
            fns: [],
            err_fns: []

  @spec new(Keyword.t()) :: t()
  def new(opts) do
    struct(__MODULE__, opts)
  end

  @spec await(t()) :: t()
  def await(%__MODULE__{errors: errors} = res) when not is_nil(errors), do: res

  def await(%__MODULE__{} = res) do
    [state: res, next: &itr_reduce/1]
    |> Iterator.new()
    |> itr_next()
  end

  @spec into_stream(t()) :: Enumerable.t()
  def into_stream(%__MODULE__{} = res) do
    Iterator.new([state: res, next: &itr_reduce/1])
  end

  @spec into_response(t()) :: term()
  def into_response(%__MODULE__{} = res), do: apply_fns(res)

  @spec into_raw_response(t()) :: iodata()
  def into_raw_response(%__MODULE__{body: body}), do: body

  @spec into_binary(t()) :: binary()
  def into_binary(%__MODULE__{} = res) do
    res
    |> apply_fns()
    |> :erlang.iolist_to_binary()
  end

  @spec into_result(t()) :: {:ok, t(), term()} | {:error, t(), term()}
  def into_result(%__MODULE__{errors: nil} = res), do: {:ok, res, apply_fns(res)}
  # TODO
  def into_result(%__MODULE__{} = res), do: {:error, res, :reason}

  @spec map_ok(t(), (term() -> term()) | mfargs()) :: t()
  def map_ok(%__MODULE__{} = res, fun) when is_function(fun) do
    %{res | fns: [fun | res.fns]}
  end

  def map_ok(%__MODULE__{} = res, {_m, _f, _a} = mfa) do
    fun = wrap_mfa(mfa)
    %{res | fns: [fun | res.fns]}
  end

  @spec map_err(t(), (term() -> term()) | mfargs()) :: t()
  def map_err(%__MODULE__{} = res, fun) when is_function(fun) do
    %{res | err_fns: [fun | res.err_fns]}
  end

  def map_err(%__MODULE__{} = res, {_m, _f, _a} = mfa) do
    fun = wrap_mfa(mfa)
    %{res | err_fns: [fun | res.err_fns]}
  end

  @spec with_error(t(), term()) :: t()
  def with_error(res, reason) do
    %{res | errors: [reason | res.errors]}
  end

  defp itr_next(%Iterator{} = itr) do
    case Iterator.next(itr) do
      {:cont, %Iterator{} = itr} -> itr_next(itr)
      {:halt, %Iterator{state: res}} -> res
    end
  end

  defp itr_reduce(%__MODULE__{conn: conn, message_handler: fun} = res) do
    case fun.(conn, 0, 5000) do
      {:ok, conn, responses} -> handle_messages(%{res | conn: conn}, responses)
      _ -> {:halt, res}
    end
  end

  defp handle_messages(%__MODULE__{} = res, responses) do
    Enum.reduce(responses, {:cont, res}, &handle_message/2)
  end

  defp handle_message(response, {_, %__MODULE__{ref: ref} = res}) do
    case response do
      {:status, ^ref, status_code} -> {:cont, %{res | status_code: status_code}}
      {:headers, ^ref, headers} -> {:cont, %{res | headers: headers}}
      {:data, ^ref, data} -> {:cont, %{res | body: [data | res.body]}}
      {:done, ^ref} -> {:halt, res}
    end
  end

  defp wrap_mfa({m, f, a}) do
    fn data ->
      apply(m, f, [data | a])
    end
  end

  defp apply_fns(%__MODULE__{fns: [], body: body}), do: body

  defp apply_fns(%__MODULE__{fns: fns, body: body}),
    do: fns |> Enum.reverse() |> Enum.reduce(body, & &1.(&2))
end
