defmodule Admin.Client do

  import Ecto.Changeset

  @moduledoc"""
  Administrative functions that interact with clients
  """

  def get() do
    Clients.get_all()
  end

  def post(data) do
    repo = Storage.get()
    client = %Clients.Client{}
    secret = :crypto.strong_rand_bytes(32) |> Base.encode16()
    data = Map.put(data, "secret", secret)
    cast(client, data, [:type, :name, :secret])
    |> validate_required([:type, :name])
    |> validate_inclusion(:type, ["ldap", "oauth", "proxy"])
    |> repo.insert()
  end

  def get(id) do
    if Util.uuid?(id) do
      Clients.get(id)
    else nil end
  end

  def put(id, data) do
    if Util.uuid?(id) do
      repo = Storage.get()
      client = Clients.get(id)
      if client == nil do
        {:not_found, "No client with id #{id}"}
      else
        data = Map.drop(data, ["id", "type", "secret"]) #ignore bad updates
        cast(client, data, [:name])
        |> validate_subset(:type, ["ldap", "oauth", "saml"])
        |> repo.update()
      end
    else {:not_found, "invalid id format"} end
  end

  def delete(id) do
    if Util.uuid?(id) do
      repo = Storage.get()
      client = Clients.get(id)
      if client == nil do
        {:not_found, "No client with id #{id}"}
      else
        repo.delete(client)
      end
    else {:not_found, "invalid id format"} end
  end

  def credentials(id) do
    if Util.uuid?(id) do
      client = Clients.get(id)
      if client == nil do
        nil
      else
        %{id: client.id, type: client.type, secret: client.secret}
      end
    else nil end
  end

end


