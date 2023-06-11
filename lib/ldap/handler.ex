defmodule LDAP.Handler do

  import Ecto.Query

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
            {responses, new_bind} = handle(request, bind)
            IO.inspect(responses)
            cond do
              is_list(responses) ->
                Enum.map(responses, fn response ->
                  IO.inspect(response)
                  {:ok, response} = :ldap_asn.encode(:LDAPMessage, {:LDAPMessage, seq, response, :asn1_NOVALUE})
                  transport.send(socket, response)
                end)
              responses != nil ->
                {:ok, response} = :ldap_asn.encode(:LDAPMessage, {:LDAPMesssage, seq, responses, :asn1_NOVALUE})
                transport.send(socket, response)
              true -> nil #response is nil, don't do anything
            end
            if new_bind == :close do
              transport.close(socket)
            else
              loop(socket, transport, new_bind)
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

  defp handle({:searchRequest, {:SearchRequest, _domain, _subtree, _deref, size, _time, _typesonly, filters, attributes}}, bind) do
    if bind == nil do
      response = {:searchResDone, {:LDAPResult, :insufficientAccessRights, "", "You must be authenticated to search", :asn1_NOVALUE}}
      {response, bind}
    else
      query = from Users.User
      query = build_query(filters, query)
      repo = Storage.get()
      users = repo.all(query)
      #Below we see the most efficient way to put a predefined value at the end of a generated list (prepending is very efficient, appending is not)
      responses = [{:searchResDone, {:LDAPResult, :success, "", "", :asn1_NOVALUE}}]
      responses = Enum.reduce(users, responses, fn user, responses ->
        [{:searchResEntry, {:SearchResEntry, "cn=" <> user.username <> ",dc=das,dc=nl", []}} | responses]
      end)
      {responses, bind}
    end
  end

  # unknown requests, also handles unbinds
  defp handle(request, _bind) do
    IO.inspect(request)
    {nil, :close}
  end

  def build_query(filters, query, type \\ :where)

  def build_query({:and, filters}, query, _type) do
    Enum.reduce(filters, query, fn filter, query ->
      build_query(filter, query, :where)
    end)
  end

  def build_query({:or, filters}, query, _type) do
    Enum.reduce(filters, query, fn filter, query ->
      build_query(filter, query, :or_where)
    end)
  end

  def build_query({:equalityMatch, {_attributeValueAssertion, field, value}}, query, :where) do
    field = String.to_atom(field)
    if Users.User.__schema__(:fields) |> Enum.member?(field) do
      from query, [{:where, ^Keyword.new([{field, value}])}]
    else
      query
    end
  end

  def build_query({:equalityMatch, {_attributeValueAssertion, field, value}}, query, :or_where) do
    field = String.to_atom(field)
    if Users.User.__schema__(:fields) |> Enum.member?(field) do
      from query, [{:or_where, ^Keyword.new([{field, value}])}]
    else
      query
    end
  end

end
