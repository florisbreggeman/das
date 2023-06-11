defmodule Users.User do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :username, :given_names, :family_name, :email, :admin]}
  schema "user" do
    field :username, :string
    field :given_names, :string
    field :family_name, :string
    field :email, :string
    field :admin, :boolean
    field :password, :string
  end
end
