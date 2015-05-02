defmodule Elistrix.Dispatcher do
  use GenServer

  @default_threshold %Elistrix.Thresholds{}

  def start_link(metrics, opts \\ []) do
    GenServer.start_link(__MODULE__, metrics, opts)
  end

  def init(metrics) do
    {:ok, %{:functions => %{}, :metrics => metrics}}
  end

  def handle_call({:register, fun_name, fun, thresholds}, _from, state) do
    case Map.has_key?(state.functions, fun_name) do
      true -> {:reply, :already_exists, state}
      false ->
        runner = %Elistrix.Runner{fun: fun, thresholds: thresholds}
        state = put_in(state, [:functions, fun_name], runner)
        {:reply, :ok, state}
    end
  end

  def handle_call({:run, fun_name}, _from, state) do
  end

  def handle_cast({:track, :ok, fun_name, delta}, state) do
    {:noreply, mark_call_ok(state, fun_name, delta)}
  end

  def handle_cast({:track, :error, fun_name, delta}, state) do
    {:noreply, mark_call_error(state, fun_name, delta)}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  def register(fun_name, fun, thresholds \\ @default_threshold) do
    GenServer.call(__MODULE__, {:register, fun_name, fun, thresholds})
  end

  def run(fun_name, args \\ []) when is_list(args) do
    case get_runner(fun_name) do
      {:ok, run_fun} ->
        start = get_time_msecs
        result = apply(run_fun, args)
        delta = get_time_msecs - start

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
    Timex.Time.now(:secs)
  end

  defp get_time_msecs do
    Timex.Time.now(:msecs)
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
    fun_def = get_in(state, [:functions, fun_name])
    case fun_def do
      nil -> state
      _ ->
        requests = fun_def.requests ++ [{:ok, get_time, fun_name, delta}]
        |> prune_requests(fun_def.threshold_config)
        update_in(state, [:functions, fun_name, :requests], requests)
    end
  end

  defp mark_call_error(state, fun_name, delta) do
    fun_def = get_in(state, [:functions, fun_name])
    case fun_def do
      nil -> state
      _ ->
        requests = fun_def.requests ++ [{:error, get_time, fun_name, delta}]
        |> prune_requests(fun_def.threshold_config)
        update_in(state, [:functions, fun_name, :requests], requests)
    end
  end

  defp prune_requests(requests, threshold_config) do
    ts = get_time - threshold_config.window_length
    _prune_requests(requests, ts)
  end

  defp _prune_requests(requests, ts) do
    case requests do
      [{_, rts, _, _} | tail] when rts < ts -> _prune_requests(tail, ts)
      _ -> requests
    end
  end
end
