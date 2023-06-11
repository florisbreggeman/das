defmodule Proxy.Registry do

  @moduledoc """
  Registry that stores the bindings between hosts and proxy adresses, so that there's no need to consult the database on every request
  """

  def populate() do
    Clients.get_all()
    |> Enum.filter(fn client -> client.type == "proxy" end)
    |> Enum.each(fn client -> set(client.url, client.destination) end)
  end

  defp loop_func() do
    receive do
      :end -> nil
      _ -> loop_func()
    end
  end

  defp split_binding(binding) do
    parts = String.split(binding, ":")
    scheme = case Enum.at(parts, 0) do
      "https" -> :https
      _ -> :http
    end
    domain = Enum.at(parts, 1) |> String.trim_leading("/")
    port = Enum.at(parts, 2)
    port = if port == nil do
      if scheme == :http do
        80
      else
        443
      end
    else
      String.to_integer(port)
    end
    {scheme, domain, port}
  end

  def set(host, binding) do
    binding = split_binding(binding)
    holders = Registry.lookup(Proxy.Registry, host)
    unless Enum.empty?(holders) do
      [{pid, _dest} | _] = holders
      send(pid, :end)
    end
    spawn(fn ->
      Registry.register(Proxy.Registry, host, binding)
      loop_func()
    end)
  end

  def get(host) do
    holders = Registry.lookup(Proxy.Registry, host)
    if Enum.empty?(holders) do
      client = Clients.get_by_url(host)
      if client == nil do
        nil
      else
        set(client.url, client.destination)
        client.destination
      end
    else
      [{_pid, dest} | _] = holders
      dest
    end
  end

end
  
