defmodule Elistrix.Mixfile do
  use Mix.Project

  def project do
    [app: :elistrix,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [],
     mod: {Elistrix, []}]
  end

  defp deps do
    [{:timex, "~> 0.13.4"}]
  end
end
