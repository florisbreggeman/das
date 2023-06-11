defmodule Storage.MySQL.Migrations.AddClients do
  use Ecto.Migration

  def up do

    create table("client", primary_key: false) do
      add :id, :uuid, primary_key: true
      add :type, :string, null: false
      add :secret, :string
      add :name, :string
    end
  end

  def down do
    drop table("client")
  end

end
