defmodule Clients.CallbackURI do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:uri, :client_id]}
  schema "callback_uri" do
    field :uri, :string
    belongs_to :client, Clients.Client, type: :binary_id
  end
end
