defmodule OAuth.Key.Schema do
  use Ecto.Schema

  @moduledoc """
  Schema to store signing keys in the database, the only persistent storage we have
  """

  @primary_key {:type, :string, [autogenerate: false]}
  schema "key" do
    field :value, :string
  end
end

defmodule OAuth.Key do
  import Ecto.Query
  import Ecto.Changeset

  @moduledoc """
  Retrieve, store, and ensure the existence of encryption keys
  """

  @doc """
  Get the private key as PEM
  """
  def get_priv() do
    query = from k in OAuth.Key.Schema,
      where: k.type == "private",
      select: k.value
    repo = Storage.get()
    repo.one(query)
  end

  @doc """
  Get the public key as PEM
  """
  def get_pub() do
    query = from k in OAuth.Key.Schema,
      where: k.type == "public",
      select: k.value
    repo = Storage.get()
    repo.one(query)
  end

  @doc """
  Generates a new set of keys and puts them into the database, if they are not already there
  """
  def ensure() do
    query = from OAuth.Key.Schema
    repo = Storage.get()
    results = repo.all(query) 
    priv = Enum.filter(results, fn x -> Map.get(x, :type) == "private" end) |> Enum.at(0)
    pub = Enum.filter(results, fn x -> Map.get(x, :type) == "public" end) |> Enum.at(0)
    if priv == nil or pub == nil do
      replace(priv, pub)
    end
  end

  defp replace(priv, pub) do
    repo = Storage.get()

    priv_raw = :public_key.generate_key({:rsa, 2048, 65537})
    priv_pem_entry = :public_key.pem_entry_encode(:RSAPrivateKey, priv_raw)
    priv_pem = :public_key.pem_encode([priv_pem_entry])

    {_, _, modulus, pubex, _, _, _, _, _, _, _} = priv_raw
    pub_raw = {:RSAPublicKey, modulus, pubex}
    pub_pem_entry = :public_key.pem_entry_encode(:RSAPublicKey, pub_raw)
    pub_pem = :public_key.pem_encode([pub_pem_entry])

    if priv == nil do
      key = %OAuth.Key.Schema{}
      data = %{type: "private", value: priv_pem}
      cast(key, data, [:type, :value])
      |> repo.insert()
    else
      data = %{value: priv_pem}
      cast(priv, data, [:value])
      |> repo.update()
    end

    if pub == nil do
      key = %OAuth.Key.Schema{}
      data = %{type: "public", value: pub_pem}
      cast(key, data, [:type, :value])
      |> repo.insert()
    else
      data = %{value: pub_pem}
      cast(pub, data, [:value])
      |> repo.update()
    end
  end
end
