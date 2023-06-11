defmodule Das.MixProject do
  use Mix.Project

  def project do
    [
      app: :das,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      config_providers: [
        {Config.Reader, "config/config.exs"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Das, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.8"},
      {:ecto_sql, "~>3.0"},
      {:myxql, "~>0.6.3"},
      {:postgrex, "~>0.16.0"},
      {:ecto_sqlite3, "~>0.9.0"},
      {:bcrypt_elixir, "~> 3.0"}
    ]
  end
end
