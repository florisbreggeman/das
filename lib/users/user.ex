defmodule Users.User do
  use Ecto.Schema

  #derive {Jason.Encoder, only: [:id, :username, :name, :email, :admin]}
  schema "user" do
    field :username, :string
    field :name, :string
    field :email, :string
    field :admin, :boolean
    field :password, :string, [redact: true]
    field :totp_secret, :binary
  end

  defimpl Jason.Encoder do
    def encode(user, opts) do
      totp_enabled = user.totp_secret != nil
      map = Map.take(user, [:id, :username, :name, :email, :admin])
            |> Map.put(:totp_enabled, totp_enabled)
      Jason.Encode.map(map, opts)
    end
  end

end
