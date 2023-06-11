defmodule LDAP.Handler do

  def start_link(ref, socket, transport, opts) do
    pid = spawn_link(fn -> init(ref, socket, transport, opts) end)
    {:ok, pid}
  end

  def init(ref, socket, transport, _ \\ []) do
    :ok = :ranch.accept_ack(ref)
    loop(socket, transport, nil)
  end

  def loop(socket, transport, bind) do
    input = transport.recv(socket, 0, 5000)
    case input do
      {:ok, data} -> 
        msg = :ldap_asn.decode(:LDAPMessage, data)
        case msg do
          {:ok, {:LDAPMessage, seq, request, _controls}} ->
            {response, new_bind} = handle(request, bind)
            IO.inspect(response)
            if response != nil do
              {:ok, response} = :ldap_asn.encode(:LDAPMessage, {:LDAPMesssage, seq, response, :asn1_NOVALUE})
              transport.send(socket, response)
            end
            if new_bind == :close do
              transport.close(socket)
            else
              loop(socket, transport, bind)
            end
          _ -> 
            transport.close(socket)
        end
      _ -> 
        transport.close(socket)
    end
  end

  defp handle({:bindRequest, {:BindRequest, _version, dn, {:simple, password}}}, bind) do
    client = case dn do
      "id=" <> id -> 
        id = String.split(id, ",") |> Enum.at(0) #we only care about the first RDN
        IO.inspect(id)
        Clients.verify(id, password)
      _ -> 
        nil
    end
    if client == nil do
      response = {:bindResponse, {:BindResponse, :invalidCredentials, dn, "", :asn1_NOVALUE, :asn1_NOVALUE}}
      {response, bind}
    else
      response = {:bindResponse, {:BindResponse, :success, dn, "", :asn1_NOVALUE, :asn1_NOVALUE}}
      {response, client}
    end
  end
  defp handle({:bindRequest, {:BindRequest, _version, _name, {_sasl, _password}}}, bind) do
    response = {:bindResponse, {:BindResponse, :authMethodNotSupported, "", "Only simple authentication is supported", :asn1_NOVALUE, :asn1_NOVALUE}}
    {response, bind}
  end

  defp handle({:searchRequest, {:SearchRequest, _domain, _subtree, _deref, _typeonly, size, time, constraints, attributes}}, bind) do
    #TODO: actually implement search
    response = {:SearchResDone, {:LDAPResult, :insufficientAccessRights, "", "You must be authenticated to search", :asn1_NOVALUE}}
    {response, bind}
  end

  # unknown requests, also handles unbinds
  defp handle(request, _bind) do
    IO.inspect(request)
    {nil, :close}
  end
end
