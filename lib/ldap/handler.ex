defmodule LDAP.Handler do

  def start_link(ref, socket, transport, opts) do
    pid = spawn_link(fn -> init(ref, socket, transport, opts) end)
    {:ok, pid}
  end

  def init(ref, socket, transport, _ \\ []) do
    :ok = :ranch.accept_ack(ref)
    handle(socket, transport)
  end

  def handle(socket, transport) do
    input = transport.recv(socket, 0, 5000)
    case input do
      {:ok, data} -> 
        msg = :ldap_asn.decode(:LDAPMessage, data)
        case msg do
          {:ok, {:LDAPMessage, seq, request, _controls}} ->
            IO.inspect(seq)
            IO.inspect(request)
            transport.close(socket)
            #handle(socket, transport)
          _ -> 
            IO.inspect(msg)
            transport.close(socket)
        end
      _ -> 
        transport.close(socket)
    end
  end
end
