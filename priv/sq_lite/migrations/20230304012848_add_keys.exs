defmodule Storage.MySQL.Migrations.AddKeys do
  use Ecto.Migration

  def up do
    create table("key", primary_key: false) do
      add :type, :string, primary_key: true
      add :value, :text
    end
  end
end
