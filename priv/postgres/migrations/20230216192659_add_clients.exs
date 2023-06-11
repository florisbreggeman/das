defmodule Storage.MySQL.Migrations.AddClients do
  use Ecto.Migration

  def up do

    create table("client", primary_key: false) do
      add :id, :uuid, primary_key: true
      add :type, :string, null: false
      add :secret, :string
      add :name, :string
      add :url, :string
      add :destination, :string
    end

    create unique_index("client", :url)
  end

  def down do
    drop table("client")
  end

end
