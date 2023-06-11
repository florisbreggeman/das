defmodule OAuth.Code do

  @moduledoc """
  Responsible for keeping track of OAuth codes.
  This module can generate codes, store them in ETS for a certain amount of time, and ensure they can only be used once
  """

  @timeout 300_000 #5 minutes

  defp loop_func(client_id, code, timeout \\ @timeout) do
    start = System.monotonic_time(:millisecond)
    receive do
      {:get, pid} -> send(pid, {:ok, client_id})
      _ -> 
        finish = System.monotonic_time(:millisecond)
        diff = finish - start
        loop_func(client_id, code, diff) #simply continue
    after timeout -> nil #simply exit
    end
  end

  @doc """
  Generate a new code for a client id.
  The code can retrieved for the next 5 minutes

  Returns the code.
  """
  def generate(client_id) do
    code = :crypto.strong_rand_bytes(32) |> Base.encode16()
    spawn(fn -> 
      Registry.register(OAuth.CodeRegistry, code, nil)
      loop_func(client_id, code)
    end)
    code
  end

  @doc """
  Verify that a code was indeed requested by this client id, and has not been used before

  NB: retrieving a code with an incorrect client id will still invalidate the code!
  """
  def verify(client_id, code) do
    holders = Registry.lookup(OAuth.CodeRegistry, code)
    if Enum.empty?(holders) do
      false
    else
      [{pid, _} | _] = holders
      send(pid, {:get, self()})
      result = receive_loop()
      result == client_id 
    end
  end

  defp receive_loop(buffer \\ []) do
    receive do
      {:ok, client_id} -> 
        Enum.reverse(buffer) |> Enum.each(fn x -> send(self(), x) end)
        client_id
      other -> receive_loop([other | buffer])
    after 1000 -> nil
    end
  end
end   



