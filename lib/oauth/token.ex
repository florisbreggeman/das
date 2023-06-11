defmodule OAuth.Token do

  @moduledoc """
  This module is responsible for managing OAuth session tokens.
  Note that since this server is only intended for authentication and does not authorize any APIs, tokens are fairly short lived, can't be refreshed, and do not persist when the service restarts.
  """

  @timeout 4*60*60*1000 #4 hours

  defp loop_func(state, token, timeout \\ @timeout) do
    start = System.monotonic_time(:millisecond)
    receive do
      {:get, pid, ref} -> send(pid, {:ok, ref, state})
      _ -> nil
    after timeout -> nil #simply exit
    end
    finish = System.monotonic_time(:millisecond)
    loop_func(state, token, finish-start)
  end

  def generate(state) do
    token = :crypto.strong_rand_bytes(32) |> Base.encode16()
    spawn(fn ->
      Registry.register(OAuth.TokenRegistry, token, nil)
      loop_func(state, token)
    end)
    token
  end

  def retrieve(token) do
    holders = Registry.lookup(OAuth.TokenRegistry, token)
    if Enum.empty?(holders) do
      nil
    else
      [{pid, _} | _] = holders
      ref = make_ref()
      send(pid, {:get, self(), ref})
      receive_loop(ref)
    end
  end

  defp receive_loop(ref, buffer \\ []) do
    receive do 
      {:ok, ^ref, state} ->
        Enum.reverse(buffer) |> Enum.each(fn x -> send(self(), x) end)
        state
      other -> receive_loop([other | buffer])
    after 1000 -> nil
    end
  end
end

