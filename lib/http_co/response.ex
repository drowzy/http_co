defmodule HTTPCo.Response do
  @type t :: %__MODULE__{}
  defstruct ref: nil,
            conn: nil,
            errors: nil,
            status_code: nil,
            content_length: 0,
            headers: [],
            body: [],
            message_handler: &Mint.HTTP.stream/2,
            response_funs: []

  @spec new(Keyword.t()) :: t()
  def new(opts) do
    struct(__MODULE__, opts)
  end

  @spec await(t()) :: t()
  def await(%__MODULE__{errors: errors} = res) when not is_nil(errors), do: res

  def await(%__MODULE__{conn: conn, message_handler: handler} = res) do
    receive do
      message ->
        {:ok, conn, responses} = handler.(conn, message)

        case handle_messages(%{res | conn: conn}, responses) do
          {:cont, res} -> await(res)
          {:halt, res} -> res
        end
    end
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

  @spec with_transform(t(), (term() -> term())) :: t()
  def with_transform(%__MODULE__{} = res, fun) when is_function(fun) do
    %{res | response_funs: [fun | res.response_funs]}
  end

  @spec with_error(t(), term()) :: t()
  def with_error(res, _reason) do
    res
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

  defp apply_fns(%__MODULE__{response_funs: [], body: body}), do: body

  defp apply_fns(%__MODULE__{response_funs: rfs, body: body}),
    do: Enum.reduce(rfs, body, & &1.(&2))
end
