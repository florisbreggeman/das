defmodule OAuth.Code do

  @moduledoc """
  Responsible for keeping track of OAuth codes.
  This module can generate codes, store them in ETS for a certain amount of time, and ensure they can only be used once
  """

  @timeout 5*60*1000 #5 minutes

  defp loop_func(state, code, timeout \\ @timeout) do
    start = System.monotonic_time(:millisecond)
    receive do
      {:get, pid, ref} -> send(pid, {:ok, ref, state})
      _ -> 
        finish = System.monotonic_time(:millisecond)
        diff = finish - start
        loop_func(state, code, diff) #simply continue
    after timeout -> nil #simply exit
    end
  end

  @doc """
  Generate a new code for a client id.
  The code can redeemed for the next 5 minutes.

  Returns the code.
  """
  def generate(state) do
    code = :crypto.strong_rand_bytes(32) |> Base.encode16()
    spawn(fn -> 
      Registry.register(OAuth.CodeRegistry, code, nil)
      loop_func(state, code)
    end)
    code
  end

  @doc """
  Verify that a code was indeed requested by this client id, and has not been used before.
  If it is returns the state

  NB: redeeming a code with an incorrect client id will still invalidate the code!
  """
  def redeem(code) do
    holders = Registry.lookup(OAuth.CodeRegistry, code)
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



