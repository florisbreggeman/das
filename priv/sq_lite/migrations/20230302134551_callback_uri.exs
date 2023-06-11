defmodule Storage.MySQL.Migrations.CallbackUri do
  use Ecto.Migration

  def up do
    create table("callback_uri") do
      add :uri, :string, null: false
      add :client_id, references("client", type: :uuid)
    end
  end

  def down do
    drop table("callback_uri")
  end
end

