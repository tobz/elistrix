defmodule Elistrix.Metrics do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_opts) do
    {:ok, {}}
  end
end
