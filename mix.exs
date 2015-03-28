defmodule Exddb.Mixfile do
  use Mix.Project

  def project do
    [app: :exddb,
     version: "0.0.2",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :erlcloud]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:jsx, "~> 2.5.2", override: true},
      {:erlcloud, "~> 0.9.2"}
    ]
  end
end
