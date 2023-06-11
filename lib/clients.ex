defmodule Clients do

  import Ecto.Query

  @moduledoc """
  All function required to operate on the user database
  """

  @doc """
  Gets all the users
  """
  def get_all() do
    repo = Storage.get()
    query = from c in Clients.Client
    repo.all(query)
  end
  
  @doc """
  Gets a single client that matches the id
  """
  def get(id) do
    try do
      query = from c in Clients.Client,
        where: c.id == ^id
      repo = Storage.get()
      repo.one(query)
    rescue
      Ecto.Query.CastError -> nil #incorrectly formatted client id
      e -> reraise e, __STACKTRACE__
    end
  end

  @doc """
  Get a single client by name
  """
  def get_by_name(name) do
    query = from c in Clients.Client,
      where: c.name == ^name
    repo = Storage.get()
    repo.one(query)
  end


  @doc """
  Verifies that the client has entered the correct credentialso
  Returns nil if incorrect (including if the client does not exist, etc.)
  Returns the client object if credentials are correct.
  """
  def verify(id, secret) do
    try do
      client = get(id)
      if client != nil and client.secret == secret do
        client
      else
        nil
      end
    rescue
      #probably a cast error, i.e. the username provided is not a valid ID
      _ -> nil
    end
  end

  def get_callbackuris(id) do
    try do
      repo = Storage.get()
      query = from c in Clients.CallbackURI,
      where: c.client_id == ^id
      result = repo.all(query)
      Enum.map(result, fn callback -> callback.uri end)
    rescue
      _ -> nil
    end
  end

  def get_callbackuri_object(client, uri) do
    try do
      repo = Storage.get()
      query = from c in Clients.CallbackURI,
      where: c.client_id==^client and c.uri==^uri
      repo.one(query)
    rescue
      _ -> nil
    end
  end
end
