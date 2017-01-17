defmodule Trie.Mixfile do
  use Mix.Project

  def project do
    [app: :trie,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test,
                         "coveralls.detail": :test,
                         "coveralls.post": :test,
                         "coveralls.html": :test],
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:benchwarmer, "~> 0.0.2", only: :dev},
      {:ex_doc, "~> 0.14", only: :dev},
      {:dialyxir, "~> 0.3", only: :dev},
      {:excoveralls, "~> 0.5", only: :test}
    ]
  end
end
