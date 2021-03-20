defmodule HTTPCo.Response do
  @type t :: %__MODULE__{}
  defstruct ref: nil,
            conn: nil,
            errors: nil,
            status_code: nil,
            content_length: 0,
            message_handler: &Mint.HTTP.stream/2,
            headers: [],
            body: []

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
end
