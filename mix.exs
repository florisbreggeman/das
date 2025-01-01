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
      {:ecto, "~> 3.12"},
      {:ecto_sql, "~>3.12"},
      {:myxql, "~>0.7"},
      {:postgrex, "~>0.19"},
      {:ecto_sqlite3, "~>0.11"},
      {:bcrypt_elixir, "~> 3.2"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:ldap_asn, path: "ldap_asn/", manager: :rebar3},
      {:joken, "~> 2.6"},
      {:castore, "~> 1.0"},
      {:mint, "~> 1.6"},
      {:nimble_totp, "~> 1.0"},
      {:eqrcode, "~> 0.2"}
    ]
  end
end
