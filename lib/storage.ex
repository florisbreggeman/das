defmodule Storage do
  def child_spec(options) do
    case Application.get_env(:das, :db_type) do
      :mysql -> Storage.MySQL.child_spec(options)
      :postgres -> Storage.Postgres.child_spec(options)
      _ -> Storage.SQLite.child_spec(options)
    end
  end
end
