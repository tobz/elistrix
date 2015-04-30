defmodule Elistrix.Runner.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    opts = [strategy: :one_for_one, name: Elistrix.Runner.Supervisor]
    supervise([], opts)
  end
end
