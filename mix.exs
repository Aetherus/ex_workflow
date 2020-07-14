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
      {:ecto, "~> 3.0"}
    ]
  end

  defp description do
    "A minimal workflow implementation for Ecto schemas."
  end

  defp package do
    [
      name: "ex_workflow",
      files: ~w[lib priv .formatter.exs mix.exs README* readme* LICENSE*
        license* CHANGELOG* changelog* src],
      license: ["MIT"],
      links: %{
        "GitHub" => "git@github.com:Aetherus/ex_workflow.git"
      }
    ]
  end
end
