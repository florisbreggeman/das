defmodule Storage.MySQL do
  use Ecto.Repo,
    otp_app: :das,
    adapter: Ecto.Adapters.MyXQL
end
