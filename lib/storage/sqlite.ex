defmodule Storage.SQLite do
  use Ecto.Repo,
    otp_app: :das,
    adapter: Ecto.Adapters.SQLite3
end
