defmodule Users do

  import Ecto.Query

  @moduledoc """
  All function required to operate on the user database
  """
  
  @doc """
  Gets a single user that matches the id
  """
  def get_by_id(id) do
    query = from u in Users.User,
      where: u.id == ^id
    repo = Storage.get()
    repo.one(query)
  end


  @doc """
  Gets a single user that matches the username
  """
  def get_by_username(username) do
    query = from u in Users.User,
      where: u.username == ^username
    repo = Storage.get()
    repo.one(query)
  end

  @doc """
  Verifies that the user is who they say they are given the provided credentials.
  Returns nil if incorrect (including if the user does not exist, etc.)
  Returns the user object if credentials are correct.
  """
  def verify(username, password) do
    user = get_by_username(username)
    if Bcrypt.verify_pass(password, user.password) do
      user
    else
      nil
    end
  end
end
