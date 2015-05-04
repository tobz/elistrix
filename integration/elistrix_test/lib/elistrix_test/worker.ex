defmodule ElistrixTest.Worker do
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    :ok == Elistrix.Dispatcher.register("remote_service", &ElistrixTest.Remote.call/1, %Elistrix.Thresholds{latency_threshold: 50})

    # send ~20 msgs/sec to ourselves
    :timer.send_interval(50, self(), {:call})

    {:ok, []}
  end

  def handle_info({:call}, state) do
    result = Elistrix.Dispatcher.run("remote_service", [:random.uniform(100)])
    IO.inspect result

    {:noreply, state}
  end
end
