defmodule ExWorkflow.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_workflow,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ecto, "~> 3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    "A minimal workflow implementation for Ecto schemas."
  end

  defp package do
    [
      name: "ex_workflow",
      files: ~w[lib .formatter.exs mix.exs README*],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/Aetherus/ex_workflow"
      }
    ]
  end
end
