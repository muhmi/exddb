defmodule Exddb.Mixfile do
  use Mix.Project

  def project do
    [app: :exddb,
     version: "0.1.3",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     description: description,
     package: package,
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
      {:erlcloud, "~> 0.9.2"},
      {:ex_doc, "~> 0.9", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    Simple library for working with data in DynamoDB.
    """
  end

  defp package do
    [
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Roope Kangas"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/muhmi/exddb"}
    ]
  end

  # Include some support code for :test
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/mix/tasks"]
  defp elixirc_paths(_), do: ["lib"]

end
