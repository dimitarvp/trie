defmodule Trie.Mixfile do
  use Mix.Project

  def project do
    [app: :trie,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     test_coverage: [tool: Coverex.Task],
     dialyzer: [plt_add_deps: :app_true]
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
      {:coverex, "~> 1.4.10", only: :test}
    ]
  end
end
