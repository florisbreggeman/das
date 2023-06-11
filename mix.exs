defmodule Das.MixProject do
  use Mix.Project

  def project do
    [
      app: :das,
      version: "1.0.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      config_providers: [
        {Config.Reader, "config/config.exs"}
      ],
      releases: [
        das: [
          version: "1.0",
          applications: [das: :permanent]
        ]
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
      {:bcrypt_elixir, "~> 3.0"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:ldap_asn, path: "ldap_asn/", manager: :rebar3},
      {:joken, "~> 2.6"},
      {:castore, "~> 1.0"},
      {:mint, "~> 1.0"},
      {:nimble_totp, "~> 1.0"},
      {:eqrcode, "~> 0.1.10"}
    ]
  end
end
