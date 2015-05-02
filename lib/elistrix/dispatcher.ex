defmodule Elistrix.Dispatcher do
  use GenServer

  @default_threshold %Elistrix.Thresholds{}

  def start_link(metrics, opts \\ []) do
    GenServer.start_link(__MODULE__, metrics, opts)
  end

  def init(metrics) do
    {:ok, %{:commands => %{}, :metrics => metrics}}
  end

  def handle_call({:register, cmd_name, fun, thresholds}, _from, state) do
    case Map.has_key?(state.commands, cmd_name) do
      true -> {:reply, :already_exists, state}
      false ->
        cmd = %Elistrix.Command{fun: fun, thresholds: thresholds}
        state = put_in(state, [:commands, cmd_name], cmd)
        {:reply, :ok, state}
    end
  end

  def handle_call({:run, cmd_name}, _from, state) do
    case Map.has_key?(state.commands, cmd_name) do
      false -> {:reply, :does_not_exist, state}
      true ->
        cmd = state.commands[cmd_name]
        case get_command_status(cmd) do
          {:tripped, reason} -> {:reply, {:tripped, reason}, state}
          :ok -> {:reply, {:ok, cmd}, state}
        end
    end
  end

  def handle_cast({:track, :ok, cmd_name, delta}, state) do
    {:noreply, mark_call_ok(state, cmd_name, delta)}
  end

  def handle_cast({:track, :error, cmd_name, delta}, state) do
    {:noreply, mark_call_error(state, cmd_name, delta)}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  def register(cmd_name, fun, thresholds \\ @default_threshold) do
    GenServer.call(__MODULE__, {:register, cmd_name, fun, thresholds})
  end

  def run(cmd_name, args \\ []) when is_list(args) do
    case get_command(cmd_name) do
      {:ok, cmd} ->
        start = get_time_msecs
        result = apply(cmd.fun, args)
        delta = get_time_msecs - start

        case result do
          :error -> track_error(cmd_name, delta)
          {:error, _} -> track_error(cmd_name, delta)
          _ -> track_success(cmd_name, delta)
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

  defp get_command(cmd_name) do
    GenServer.call(__MODULE__, {:run, cmd_name})
  end

  defp get_command_status(cmd) do
    :ok
  end

  defp track_success(cmd_name, delta) do
    track_call(cmd_name, :ok, delta)
  end

  defp track_error(cmd_name, delta) do
    track_call(cmd_name, :error, delta)
  end

  defp track_call(cmd_name, result, delta) do
    GenServer.cast(__MODULE__, {:track, result, cmd_name, delta})
  end

  defp mark_call_ok(state, cmd_name, delta) do
    cmd = get_in(state, [:commands, cmd_name])
    case cmd do
      nil -> state
      _ ->
        requests = cmd.requests ++ [{:ok, get_time, cmd_name, delta}]
        |> prune_requests(cmd.thresholds)
        update_in(state, [:commands, cmd_name, :requests], requests)
    end
  end

  defp mark_call_error(state, cmd_name, delta) do
    cmd = get_in(state, [:commands, cmd_name])
    case cmd do
      nil -> state
      _ ->
        requests = cmd.requests ++ [{:error, get_time, cmd_name, delta}]
        |> prune_requests(cmd.thresholds)
        update_in(state, [:commands, cmd_name, :requests], requests)
    end
  end

  defp prune_requests(requests, thresholds) do
    ts = get_time - thresholds.window_length
    _prune_requests(requests, ts)
  end

  defp _prune_requests(requests, ts) do
    case requests do
      [{_, rts, _, _} | tail] when rts < ts -> _prune_requests(tail, ts)
      _ -> requests
    end
  end
end
