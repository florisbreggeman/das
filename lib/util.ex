defmodule Util do

  @moduledoc """
  Random utility functions that don't really belong anywhere else in the program
  """

  @doc """
  Puts a 400 error and some text on keys not being correct into the connection
  """
  def incorrect_keys(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(400, "Incorrect keys")
  end

  @doc """
  Verifies that a map has all required keys
  """
  def verify_keys(map, keys) do
    Enum.all?(keys, fn x -> Map.has_key?(map, x) end)
  end

  @doc """
  Run some basic code that relies on a JSON body from an HTTP request.
  takes in the connection object, keys that must be in the HTTP body, and a function that takes a connection object and the already parsed body.
  Will run the function if the JSON parses correctly and has a property corresponding to each of the keys.
  Otherwise returns an error message with 400 code back to the caller
  """
  def basic_query(conn, keys, function) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    body = Jason.decode(body)
    case body do
      {:ok, body} -> 
        if verify_keys(body, keys) do
          function.(conn, body)
        else
          incorrect_keys(conn)
        end
      _ -> conn |> Plug.Conn.put_resp_content_type("text/plain") |> Plug.Conn.send_resp(400, "Could not parse Json")
    end
  end

  @doc """
  Turns Ecto errors into something that is more presentable to the user
  """
  def parse_ecto_error(msg) do
    try do
      {field, msg} = Enum.at(msg.errors, 0)
      {msg, _} = msg
      Atom.to_string(field) <> " " <> msg
    rescue
      #Unexpectedly formatted error, time to try stuff:
      _ -> try do
          inspect(msg.errors)
      rescue
        _ -> inspect(msg)
      end
    end
  end


end
