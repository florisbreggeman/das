defmodule Das do

  require Logger

  use Application

  def start(_type, _args) do
    children = [
      Storage
    ]

    opts = [strategy: :one_for_one, name: Das.Supervisor]

    {:ok, supervisor} = Supervisor.start_link(children, opts)

    #just to easily populate the db
    repo = Storage.get()
    user = %Users.User{
      username: "floris",
      given_names: "Floris Tenzin",
      family_name: "Breggeman",
      email: "info@sfbtech.nl",
      admin: true,
      password: Bcrypt.hash_pwd_salt("admin")
    }
    repo.insert(user)

    {:ok, supervisor}
  end

end
