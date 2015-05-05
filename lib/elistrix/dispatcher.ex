defmodule Elistrix.Dispatcher do
  @moduledoc """
  Registers commands and dispatches calls to them.

    Currently, the dispatcher is also responsible for figuring out if a command's trip status is accurate
(seeing if we've updated values recently enough) and updating it before call requests are fulfilled.
  """

  use GenServer

  @default_threshold %Elistrix.Thresholds{}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %{:commands => %{}}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
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
        case command_requires_update(cmd) do
          true ->
            cmd = update_command_status(cmd)
            state = put_in(state, [:commands, cmd_name], cmd)
          false -> true
        end

        case cmd.tripped do
          true -> {:reply, {:tripped, cmd.trip_reason}, state}
          false -> {:reply, {:ok, cmd}, state}
        end
    end
  end

  def handle_cast({:track, :ok, cmd_name, delta}, state) do
    {:noreply, mark_call_ok(state, cmd_name, delta)}
  end

  def handle_cast({:track, :error, cmd_name, delta}, state) do
    {:noreply, mark_call_error(state, cmd_name, delta)}
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

  defp command_requires_update(cmd) do
    cmd.last_updated_ms + 500 < get_time_msecs
  end

  defp update_command_status(cmd) do
    cmd = %{cmd | requests: cmd.requests |> prune_requests(cmd.thresholds)}

    status = get_command_status(cmd)
    case status do
      :ok ->
        cmd = %{cmd | tripped: false}
      {:tripped, reason} ->
        cmd = %{cmd | tripped: true}
        cmd = %{cmd | trip_reason: reason}
    end

    cmd = %{cmd | last_updated_ms: get_time_msecs}
    cmd
  end

  defp get_command_status(cmd) do
    totals = Enum.reduce(cmd.requests, {0, 0, 0, 0}, fn request, {count, latency, errors, successes} ->
      {_, result, delta} = request

      error_count = 0
      success_count = 0
      case result do
        :error -> error_count = 1
        :ok -> success_count = 1
      end

      {count + 1, latency + delta, errors + error_count, successes + success_count}
    end)

    {request_count, latency_total, error_count, success_count} = totals
    case request_count do
      0 -> :ok
      _ ->
        avg_latency = latency_total / request_count
        error_percentage = error_count / request_count

        result = :ok
        if avg_latency > cmd.thresholds.latency_threshold do
          result = {:tripped, "exceeded latency threshold"}
        end

        if error_percentage > cmd.thresholds.error_threshold do
          result = {:tripped, "exceeded error threshold"}
        end

        result
    end
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
        requests = cmd.requests ++ [{get_time, :ok, delta}]
        |> prune_requests(cmd.thresholds)

        cmd = %{cmd | requests: requests}
        put_in(state, [:commands, cmd_name], cmd)
    end
  end

  defp mark_call_error(state, cmd_name, delta) do
    cmd = get_in(state, [:commands, cmd_name])
    case cmd do
      nil -> state
      _ ->
        requests = cmd.requests ++ [{get_time, :error, delta}]
        |> prune_requests(cmd.thresholds)

        cmd = %{cmd | requests: requests}
        put_in(state, [:commands, cmd_name], cmd)
    end
  end

  defp prune_requests(requests, thresholds) do
    ts = get_time - thresholds.window_length
    _prune_requests(requests, ts)
  end

  defp _prune_requests(requests, ts) do
    case requests do
      [{rts, _, _} | tail] when rts < ts -> _prune_requests(tail, ts)
      _ -> requests
    end
  end
end
