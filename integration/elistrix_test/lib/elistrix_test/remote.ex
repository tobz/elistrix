defmodule ElistrixTest.Remote do
  def call(a) do
    a_str = Integer.to_string(a)
    case HTTPoison.get("http://localhost:4000/api/lossy?a=" <> a_str) do
      {:ok, %HTTPoison.Response{status_code: 200}} -> :ok
      _ -> :error
    end
  end
end
