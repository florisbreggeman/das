defmodule Storage.MySQL.Migrations.CreateUser do
  use Ecto.Migration

  def up do
    create table("user") do
      add :username, :string, null: false
      add :given_names, :string, default: "", null: false
      add :family_name, :string, default: "", null: false
      add :email, :string, null: false
      add :admin, :boolean, default: false, null: false
      add :password, :string, null: false
    end
    unique_index("users", [:username])
    unique_index("users", [:email])
  end

  def down do
    drop table("user")
  end

end
