defmodule Session do
  @behaviour Plug.Session.Store

  @timeout_multiplier 60*1000

  def init(opts) do
    Keyword.fetch!(opts, :registry)
  end

  def delete(_conn, sid, registry) do
    [{pid, _data}] = Registry.lookup(registry, sid)
    send(pid, :stop)
  end

  def get(_conn, cookie, registry) do
    return = Registry.lookup(registry, cookie)
    case return do
      [{_pid, data}] -> {cookie, data}
      [] -> {nil, %{}}
    end
  end

  def put(_conn, nil, data, registry) do
    sid = Base.encode64(:crypto.strong_rand_bytes(96))

    spawn(fn ->
      Registry.register(registry, sid, data)
      listener(sid, Application.get_env(:das, :session_timeout, 8*60)*@timeout_multiplier, registry)
    end)

    sid
  end

  def put(_conn, sid, data, registry) do
    [{pid, _data}] = Registry.lookup(registry, sid)
    send(pid, {:update, data})
  end

  defp listener(sid, time_left, registry) do
    if time_left >= 0 do
      start = System.monotonic_time(:millisecond)
      receive do
        {:update, data} -> 
          Registry.update_value(registry, sid, fn _ -> data end)
          finish = System.monotonic_time(:millisecond)
          spent = finish - start
          listener(sid, time_left-spent, registry)
        :stop -> 
          Registry.unregister(registry, sid)
        _ ->
          finish = System.monotonic_time(:millisecond)
          spent = finish - start
          listener(sid, time_left-spent, registry)
      after 
        time_left -> Registry.unregister(registry, sid)
      end
    end
  end

end

