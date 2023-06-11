defmodule Clients.Client do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :type, :name, :url, :destination]}
  @primary_key {:id, :binary_id, [autogenerate: true]}
  schema "client" do
    field :type, :string
    field :secret, :string, [redact: true]
    field :name, :string
    field :url, :string
    field :destination, :string
  end
end
