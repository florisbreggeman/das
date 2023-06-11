defmodule Users.User do
  use Ecto.Schema

  schema "user" do
    field :username, :string
    field :given_names, :string
    field :family_name, :string
    field :email, :string
    field :admin, :boolean
    field :password, :string
  end
end
