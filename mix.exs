defmodule Trie.Mixfile do
  use Mix.Project

  @name "Trie"
  @version "0.2.0"

  def project do
    [
      app: :trie,
      version: @version,
      elixir: "~> 1.8",
      name: @name,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      docs: [
        source_ref: "v#{@version}",
        main: "readme",
        extras: ["README.md"]
      ],
      deps: deps(),

      # dependency: `excoveralls`-specific.
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:benchee, "~> 1.0", only: :dev},
      {:dialyxir, "~> 0.5", only: :dev},
      {:ex_doc, "~> 0.20", only: :dev},
      {:excoveralls, "~> 0.11", only: [:dev, :test]}
    ]
  end
end
