defmodule Storage.MySQL.Migrations.AddTotpSecret do
  use Ecto.Migration

  def change do
    alter table ("user") do
      add :totp_secret, :binary, size: 20
      add :totp_ldap, :boolean, default: false
      add :totp_last_used, :integer #we'll just store a Unix timestamp
    end
  end
end
