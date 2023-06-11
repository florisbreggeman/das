defmodule OAuth.IDToken do
  use Joken.Config

  @moduledoc """
  Provides a Joken-style ID Token object
  """

  def token_config() do
    default_claims(skip: [:aud, :iss, :jti, :nbf])
    #we do need aud and iss, but we have to generate them at runtime and don't need validation
  end
end

