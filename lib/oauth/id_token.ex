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
    pem = OAuth.Key.get_priv()
    signer = Joken.Signer.create("RS256", %{"pem" => pem})
    Agent.start_link(fn -> signer end, name: OAuth.IDToken.Signer)
  end

  def get() do
    Agent.get(OAuth.IDToken.Signer, fn x -> x end)
  end
end

