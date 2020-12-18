defmodule Junex.MixProject do
  use Mix.Project

  def project do
    [
      app: :junex,
      version: "0.2.0",
      elixir: "~> 1.11",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      name: "Junex",
      source_url: "https://github.com/boostingtech/junex",
      description: description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4.0"},
      {:hackney, "~> 1.16.0"},
      {:jason, ">= 1.0.0"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:git_hooks, "~> 0.5.0", only: [:test, :dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "A simple wrapper to help you interect with the Juno API!"
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/boostingtech/junex"}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end
