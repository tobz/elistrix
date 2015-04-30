defmodule Elistrix.Runner do
  use GenServer

  def start_link(metrics, run_sup, opts \\ []) do
    GenServer.start_link(__MODULE__, {metrics, run_sup}, opts)
  end

  def init({metrics, run_sup}) do
    {:ok, %{metrics: metrics, run_sup: run_sup, calls: %{}}}
  end
end
