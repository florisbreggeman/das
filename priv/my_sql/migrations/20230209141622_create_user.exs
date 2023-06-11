defmodule Storage.MySQL.Migrations.CreateUser do
  use Ecto.Migration

  def up do
    create table("user") do
      add :username, :string, null: false
      add :name, :string, default: "", null: false
      add :email, :string, null: false
      add :admin, :boolean, default: false, null: false
      add :password, :string, null: false
    end
    create unique_index("user", [:username])
    create unique_index("user", [:email])
  end

  def down do
    drop table("user")
  end

end
