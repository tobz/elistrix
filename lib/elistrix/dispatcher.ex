defmodule Elistrix.Dispatcher do
  use GenServer

  def start_link(metrics, opts \\ []) do
    GenServer.start_link(__MODULE__, metrics, opts)
  end

  def init(metrics) do
    {:ok, %{metrics: metrics, functions: %{}}}
  end

  def handle_call({:register, fun_name, fun}, _from, state) do
  end

  def handle_call({:run, fun_name}, _from, state) do
  end

  def handle_cast({:track, :ok, fun_name, delta}, state) do
    {:noreply, mark_call_ok(state, fun_name, delta)}
  end

  def handle_cast({:track, :error, fun_name, delta}, state) do
    {:noreply, mark_call_error(state, fun_name, delta)}
  end

  def register(fun_name, fun) do
    GenServer.call(__MODULE__, {:register, fun_name, fun})
  end

  def run(fun_name, args \\ []) when is_list(args) do
    case get_runner(fun_name) do
      {:ok, run_fun} ->
        start = get_time
        result = apply(run_fun, args)
        delta = get_time - start

        case result do
          :error -> track_error(fun_name, delta)
          {:error, _} -> track_error(fun_name, delta)
          _ -> track_success(fun_name, delta)
        end

        result
      {:tripped, reason} -> {:error, {:tripped, reason}}
      _ -> :does_not_exist
    end
  end

  defp get_time do
    Timex.Time.now(:usecs)
  end

  defp get_runner(fun_name) do
    GenServer.call(__MODULE__, {:run, fun_name})
  end

  defp track_success(fun_name, delta) do
    track_call(fun_name, :ok, delta)
  end

  defp track_error(fun_name, delta) do
    track_call(fun_name, :error, delta)
  end

  defp track_call(fun_name, result, delta) do
    GenServer.cast(__MODULE__, {:track, result, fun_name, delta})
  end

  defp mark_call_ok(state, fun_name, delta) do
    fun = get_in(state, [:functions, fun_name])
    case fun do
      nil -> state
      _ -> state
    end
  end

  defp mark_call_error(state, fun_name, delta) do
    fun = get_in(state, [:functions, fun_name])
    case fun do
      nil -> state
      _ -> state
    end
  end
end
