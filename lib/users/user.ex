defmodule Users.User do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :username, :name, :email, :admin]}
  schema "user" do
    field :username, :string
    field :name, :string
    field :email, :string
    field :admin, :boolean
    field :password, :string, [redact: true]
  end
end
