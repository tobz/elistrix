defmodule Elistrix do
  use Application

  @metrics_name Elistrix.Metrics
  @dispatcher_name Elistrix.Dispatcher

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Elistrix.Dispatcher, [[name: @dispatcher_name]])
    ]

    opts = [strategy: :one_for_one, name: Elistrix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
