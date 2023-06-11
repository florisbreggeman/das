defmodule Storage do
  @moduledoc """
  This module is responsible for providing the correct storage repository as configured in the configuration
  """

  def child_spec(options) do
    get().child_spec(options)
  end

  @doc """
  Returns the active Ecto.Repo object
  """
  def get() do
    case Application.get_env(:das, :db_type) do
      :mysql -> Storage.MySQL
      :postgres -> Storage.Postgres
      _ -> Storage.SQLite
    end
  end


end
