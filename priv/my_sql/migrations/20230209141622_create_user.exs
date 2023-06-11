defmodule Storage.MySQL.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table("user") do
      add :username, :string
      add :given_names, :string
      add :family_name, :string
      add :email, :string
      add :admin, :boolean
      add :password, :string
    end
  end
end
