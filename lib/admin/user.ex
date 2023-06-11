defmodule Admin.User do

  import Ecto.Changeset
  import Ecto.Query

  @moduledoc"""
  Administrative functions that interact with users
  """

  def get() do
    Users.get_all()
  end

  def post(data) do
    repo = Storage.get()
    user = %Users.User{}
    data = Map.put(data, "password", Bcrypt.hash_pwd_salt(Map.get(data, "password", "")))
    cast(user, data, [:username, :email, :family_name, :given_names, :admin, :password])
    |> validate_required([:username, :email])
    |> repo.insert()
  end

  def get(id) do
    Users.get_by_id(id)
  end

  def put(id, data) do
    repo = Storage.get()
    user = Users.get_by_id(id)
    if user == nil do
      {:not_found, "No user with id #{id}"}
    else
      data = Map.drop(data, ["id", "username", "password"]) #ignore bad updates
      #check if we're not undoing the last administrator
      if not Map.get(data, "admin", true) do
        admins = get_admins()
        if Enum.count(admins) <= 1 and Enum.at(admins, 0) == id do
          {:error, "This is the last administrator"}
        else
          cast(user, data, [:email, :family_name, :given_names, :admin])
          |> validate_required([:email, :family_name, :given_names, :admin])
          |> repo.update()
        end
      else
        cast(user, data, [:email, :family_name, :given_names, :admin])
        |> repo.update()
      end
    end
  end

  def delete(id) do
    repo = Storage.get()
    user = Users.get_by_id(id)
    if user == nil do
      {:not_found, "No user with id #{id}"}
    else
      if user.admin do
        if Enum.count(get_admins()) <= 1 do
          {:error, "You can't delete the last administrator"}
        else
          repo.delete(user)
        end
      else
        repo.delete(user)
      end
    end
  end

  def change_password(id) do
    user = Users.get_by_id(id)
    if user == nil do
      nil
    else
      new_password = :crypto.strong_rand_bytes(32) |> Base.encode64()
      repo = Storage.get()
      cast(user, %{password: Bcrypt.hash_pwd_salt(new_password)}, [:password])
      |> repo.update()
      new_password
    end
  end

  defp get_admins() do
    repo = Storage.get()
    query = from u in Users.User, where: u.admin, select: u.id
    repo.all(query)
  end

end


