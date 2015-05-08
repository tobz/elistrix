defmodule Elistrix.Metrics do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, "", opts)
  end

  def init(prefix) do
    {:ok, {prefix}}
  end

  def handle_call({:register, cmd_name}, _from, {prefix}) do
    get_metric_name(prefix, cmd_name, "requests") |> :folsom_metrics.new_counter
    get_metric_name(prefix, cmd_name, "successes") |> :folsom_metrics.new_counter
    get_metric_name(prefix, cmd_name, "errors") |> :folsom_metrics.new_counter
    get_metric_name(prefix, cmd_name, "latency") |> :folsom_metrics.new_histogram(:exdec)
    get_metric_name(prefix, cmd_name, "tripped") |> :folsom_metrics.new_gauge

    {:reply, :ok, {prefix}}
  end

  def handle_call({:get_metrics}, _from, state) do
    metrics = :folsom_metrics.get_metrics |> get_metric_values
    {:reply, metrics, state}
  end

  def handle_cast({:track, result, cmd_name, latency}, {prefix}) do
    :folsom_metrics.notify({get_metric_name(prefix, cmd_name, "requests"), {:inc, 1}})

    case result do
      :error -> :folsom_metrics.notify({get_metric_name(prefix, cmd_name, "errors"), {:inc, 1}})
      :success -> :folsom_metrics.notify({get_metric_name(prefix, cmd_name, "successes"), {:inc, 1}})
    end

    :folsom_metrics.notify({get_metric_name(prefix, cmd_name, "latency"), latency})

    {:noreply, {prefix}}
  end

  def handle_cast({:tripped, cmd_name, value}, {prefix}) do
    :folsom_metrics.notify({get_metric_name(prefix, cmd_name, "tripped"), value})
    {:noreply, {prefix}}
  end

  defp get_metric_name("", cmd_name, category) do
    "elistrix." <> cmd_name <> "." <> category
  end

  defp get_metric_name(prefix, cmd_name, category) do
    prefix <> "." <> get_metric_name("", cmd_name, category)
  end

  @doc """
  Registers a command with the metrics collector.

  There are pre-defined metrics -- request count, latency, etc -- that we want to track
  for commands, and we register them here before they can be updated/set.
  """
  def register(cmd_name) do
    GenServer.call(__MODULE__, {:register, cmd_name})
  end

  @doc """
  Tracks a successful command call.

  This increments the request count, the successful request count, and tracks the latency of the call.
  """
  def track_success(cmd_name, latency) do
    GenServer.cast(__MODULE__, {:track, :success, cmd_name, latency})
  end

  @doc """
  Tracks an unsuccessful command call.

  This increments the request count, the unsuccessful (errors) request count, and tracks the latency of the call.
  """
  def track_error(cmd_name, latency) do
    GenServer.cast(__MODULE__, {:track, :error, cmd_name, latency})
  end

  @doc """
  Tracks a command that has been tripped.
  """
  def track_command_tripped(cmd_name) do
    GenServer.cast(__MODULE__, {:tripped, cmd_name, 1})
  end

  @doc """
  Tracks a command that has been reset.
  """
  def track_command_reset(cmd_name) do
    GenServer.cast(__MODULE__, {:tripped, cmd_name, 0})
  end

  @doc """
  Gets all registered metrics.
  """
  def get_metrics do
    GenServer.call(__MODULE__, {:get_metrics})
  end

  defp get_metric_values(metric_names) do
    metric_names |> Enum.map(fn name ->
      {_, info} = :folsom_metrics.get_metric_info(name)
      case info[:type] do
        :counter -> {name, :folsom_metrics.get_metric_value(name)}
        :gauge -> {name, :folsom_metrics.get_metric_value(name)}
        :histogram -> {name, :folsom_metrics.get_histogram_statistics(name)}
      end
    end)
  end
end
