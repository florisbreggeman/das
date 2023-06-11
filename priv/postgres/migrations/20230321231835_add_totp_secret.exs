defmodule Storage.MySQL.Migrations.AddTotpSecret do
  use Ecto.Migration

  def change do
    alter table ("user") do
      add :totp_secret, :binary, size: 20
    end
  end
end
