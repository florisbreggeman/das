defmodule OAuth.IDToken do
  use Joken.Config

  @moduledoc """
  Provides a Joken-style ID Token object
  """

  def token_config() do
    default_claims(skip: [:aud, :iss, :jti, :nbf])
    #we do need aud and iss, but we have to generate them at runtime and don't need validation
  end

  @doc """
  Gets an RSA signer
  """
  def get_signer() do
    OAuth.IDToken.Signer.get()
  end
end
defmodule OAuth.IDToken.Signer do
  use Agent

  @moduledoc """
  Stores a signer object somewhere, so we don't need to parse the PEM every time
  """

  def start_link(_opts) do
    Agent.start_link(fn ->
      pem = OAuth.Key.get_priv()
      Joken.Signer.create("RS256", %{"pem" => pem})
    end, name: OAuth.IDToken.Signer)
  end

  def get() do
    Agent.get(OAuth.IDToken.Signer, fn x -> x end)
  end
end
defmodule OAuth.IDToken.JWK do
  use Agent

  @moduledoc """
  Stores the JWK encoded parameters, because they're quite a lot of effort to parse
  """

  def start_link(_opts) do
    Agent.start_link(fn -> 
      pem = OAuth.Key.get_pub()
      pem_entry = :public_key.pem_decode(pem) |> Enum.at(0)
      {_, modulus, pubex} = :public_key.pem_entry_decode(pem_entry)
  
      modulus_digits = Integer.digits(modulus, 256)
      modulus_bin = Enum.into(modulus_digits, <<>>, fn digit -> <<digit>> end)
      modulus_encoded = Base.url_encode64(modulus_bin)
  
      pubex_digits = Integer.digits(pubex, 256)
      pubex_bin = Enum.into(pubex_digits, <<>>, fn digit -> <<digit>> end)
      pubex_encoded = Base.url_encode64(pubex_bin)
  
      %{
        kty: "RSA",
        alg: "RS256",
        n: modulus_encoded,
        e: pubex_encoded,
      }
    end, name: OAuth.IDToken.JWK)
  end

  def get() do
    Agent.get(OAuth.IDToken.JWK, fn x -> x end)
  end
end

