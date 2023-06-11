defmodule LDAP.Handler do

  @dont_include [:admin, :password]
  @no_permission {:LDAPResult, :insufficientAccessRights, "", "You do not have a client bind", :asn1_NOVALUE}
  @unsupported_text "Operation not supported"
  @unsupported {:LDAPResult, :insufficientAccessRights, "", @unsupported_text, :asn1_NOVALUE}

  import Ecto.Query
  require Logger

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
            Logger.debug("LDAP request: " <> inspect(request))
            {responses, new_bind} = handle(request, bind)
            cond do
              is_list(responses) ->
                Enum.map(responses, fn response ->
                  Logger.debug("LDAP response: " <> inspect(response))
                  {:ok, response} = :ldap_asn.encode(:LDAPMessage, {:LDAPMessage, seq, response, :asn1_NOVALUE})
                  transport.send(socket, response)
                end)
              responses != nil ->
                Logger.debug("LDAP response: " <> inspect(responses))
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

  def handle({:bindRequest, {:BindRequest, _version, dn, {:simple, password}}}, old_bind) do
    #first filter on whether we are trying to authenticate a client application or a user,
    #Notable difference: applications have an id, whereas users have a username
    
    #Return two parameters: the client to respond with, and the client we'll actually consider bound
    {result, bind} = case dn do
      "id=" <> id -> 
        id = String.split(id, ",") |> Enum.at(0) #we only care about the first RDN
        client = Clients.verify(id, password)
        {client, if client == nil do old_bind else client end}
      "username=" <> username ->
        username = String.split(username, ",") |> Enum.at(0)
        user = Users.verify(username, password)
        {user, nil} #users have no rights, so we might as well treat them as anonymous binds.
      _ -> 
        {nil, old_bind}
    end
    if result == nil do
      response = {:bindResponse, {:BindResponse, :invalidCredentials, dn, "", :asn1_NOVALUE, :asn1_NOVALUE}}
      {response, bind}
    else
      response = {:bindResponse, {:BindResponse, :success, dn, "", :asn1_NOVALUE, :asn1_NOVALUE}}
      {response, bind}
    end
  end
  def handle({:bindRequest, {:BindRequest, _version, _name, {_sasl, _password}}}, bind) do
    response = {:bindResponse, {:BindResponse, :authMethodNotSupported, "", "Only simple authentication is supported", :asn1_NOVALUE, :asn1_NOVALUE}}
    {response, bind}
  end

  def handle({:searchRequest, _}, nil) do
    response = {:searchResDone, @no_permission}
    {response, nil}
  end
  def handle({:searchRequest, {:SearchRequest, _domain, _subtree, _deref, size, _time, _typesonly, filters, _attributes}}, bind) do
    #TODO: actually use the attribute selection
    query = from Users.User
    query = build_query(filters, query)
    query = if size > 0 do
      from query, limit: ^size
    else
      query
    end
    repo = Storage.get()
    users = repo.all(query)
    #Below we see the most efficient way to put a predefined value at the end of a generated list (prepending is very efficient, appending is not)
    responses = [{:searchResDone, {:LDAPResult, :success, "", "", :asn1_NOVALUE}}]
    responses = Enum.reduce(users, responses, fn user, responses ->
      [{:searchResEntry, {:SearchResEntry, "username=" <> user.username <> ",dc=das,dc=nl", 
        Enum.map(Users.User.__schema__(:fields), fn field ->
          if Enum.member?(@dont_include, field) do
            nil
          else
            value = Map.get(user, field)
            value = if field == :id do Integer.to_string(value) else value end
            if value == nil do
              nil
            else
              {:partialAttribute, Atom.to_string(field), [value]}
            end
          end
        end)
        |> Enum.filter(fn x -> x != nil end) 
      }} | responses]
    end)
    {responses, bind}
  end

  def handle({:compareRequest, _}, nil) do
    response = {:compareResponse, @no_permission}
    {response, nil}
  end
  def handle({:compareRequest, {:CompareRequest, dn, {:AttributeValueAssertion, field, value}}}, bind) do
    field = String.to_atom(field)
    result = if Enum.member?(Users.User.__schema__(:fields), field) do
      username = case dn do
        "username=" <> username -> String.split(username, ",") |> Enum.at(0)
        _ -> nil
      end
      if username == nil do
        :noSuchObject      
      else
        query = from Users.User, where: [username: ^username]
        repo = Storage.get()
        user = repo.one(query)
        cond do
          user == nil -> :noSuchObject
          Map.get(user, field) == value -> :compareTrue
          true -> :compareFalse
        end
      end
    else
      :noSuchAttribute
    end
    {{:compareResponse, {:LDAPResult, result, "", "", :asn1_NOVALUE}}, bind}
  end

  #Abandon request, simply ignore
  def handle({:abandonRequest, _}, bind) do
    {nil, bind}
  end

  #handle requests that are not supported
  def handle({:addRequest, _}, bind) do
    {{:addResponse, @unsupported}, bind}
  end
  def handle({:delRequest, _}, bind) do
    {{:delResponse, @unsupported}, bind}
  end
  def handle({:modifyRequest, _}, bind) do
    {{:modifyResponse, @unsupported}, bind}
  end
  def handle({:modDNRequest, _}, bind) do
    {{:modDNResponse, @unsupported}, bind}
  end
  def handle({:extendedReq, _}, bind) do
    {{:extendedResp, {:ExtendedResp, :insufficientAccessRights, "", @unsupported_text, :asn1_NOVALUE, :asn1_NOVALUE, :asn1_NOVALUE}}, bind}
  end

  # unknown requests, also handles unbinds
  def handle(_request, _bind) do
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
