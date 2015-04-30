defmodule Elistrix do
  use Application

  @metrics_name Elistrix.Metrics
  @runner_sup_name Elistrix.Runner.Supervisor
  @runner_name Elistrix.Runner

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Elistrix.Metrics, [[name: @metrics_name]]),
      supervisor(Elistrix.Runner.Supervisor, [[name: @runner_sup_name]]),
      worker(Elistrix.Runner, [@metrics_name, @runner_sup_name, [name: @runner_name]])
    ]

    opts = [strategy: :one_for_one, name: Elistrix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
