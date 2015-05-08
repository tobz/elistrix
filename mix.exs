defmodule Elistrix.Mixfile do
  use Mix.Project

  def project do
    [app: :elistrix,
     version: "0.0.4",
     elixir: "~> 1.0",
     name: "Elistrix",
     description: description,
     source_url: "https://github.com/tobz/elistrix",
     homepage_url: "https://github.com/tobz/elistrix",
     package: package,
     deps: deps,
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    [applications: [:folsom],
     mod: {Elistrix, []}]
  end

  defp description do
    "A latency / fault tolerance library to help isolate your applications from an uncertain world of slow or failed services."
  end

  defp package do
    [ files: ["lib","mix.exs","README.md","LICENSE"],
      contributors: ["Toby Lawrence"],
      licenses: ["MIT"],
      links: %{"GitHub": "https://github.com/tobz/elistrix"} ]
  end

  defp deps do
    [{:timex, "~> 0.13.4"},
     {:folsom, git: "https://github.com/boundary/folsom.git"},
     {:earmark, "~> 0.1.15", only: :dev},
     {:ex_doc, "~> 0.7.2", only: :dev},
     {:excoveralls, "~> 0.3", only: :dev},
     {:inch_ex, only: :dev}]
  end
end
