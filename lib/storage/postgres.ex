defmodule Storage.Postgres do
  use Ecto.Repo,
    otp_app: :das,
    adapter: Ecto.Adapters.Postgres
end
