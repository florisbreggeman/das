defmodule LDAP.Socket do

  @moduledoc """
  Opens the LDAP socket, and forwards any incoming connections to the right place
  """

  def child_spec(link_spec) do
    %{
      id: LDAP.Socket,
      start: {LDAP.Socket, :init, [link_spec]}
    }
  end

  def init(link_spec) do
    :ranch.start_listener(:ldap_socket, :ranch_tcp, %{socket_opts: link_spec}, LDAP.Handler, [])
  end


end
