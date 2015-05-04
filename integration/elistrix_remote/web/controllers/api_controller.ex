defmodule ElistrixRemote.ApiController do
  use ElistrixRemote.Web, :controller

  plug :action

  def lossy(conn, %{"a" => a}) do
    case Integer.parse(a) do
      :error ->
        put_status(conn, 500)
        |> text "'a' must be a valid integer."
      {val, _} ->
        case process_request(val) do
          {:ok, data} -> text conn, data
          {:error, reason} ->
            put_status(conn, 500)
            |> text reason
        end
    end
  end

  def process_request(a) when a > 7 do
    # normal mode.  wait a few milliseconds and return a 200.
    :timer.sleep(5)
    {:ok, "Foobar"}
  end

  def process_request(a) when a > 2 do
    # slow mode.  wait a few hundred milliseconds and return a 200.
    :timer.sleep(250)
    {:ok, "Foobar"}
  end

  def process_request(a) do
    # error mode.  wait a few milliseconds and return a 500.
    :timer.sleep(5)
    {:error, "Failed to get data."}
  end
end
