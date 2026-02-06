defmodule JumboParkingWeb.Plugs.CartSession do
  @moduledoc """
  Plug to manage cart session for the store.
  Creates or retrieves a cart based on a session ID stored in a cookie.
  """

  import Plug.Conn
  alias JumboParking.Store

  @session_key "cart_session_id"

  def init(opts), do: opts

  def call(conn, _opts) do
    session_id = get_or_create_session_id(conn)

    conn
    |> put_session(@session_key, session_id)
    |> assign(:cart_session_id, session_id)
    |> assign(:cart, Store.get_or_create_cart(session_id))
  end

  defp get_or_create_session_id(conn) do
    case get_session(conn, @session_key) do
      nil -> generate_session_id()
      id -> id
    end
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64()
  end
end

defmodule JumboParkingWeb.CartSessionHook do
  @moduledoc """
  LiveView hook to inject cart into socket assigns.
  """

  import Phoenix.Component, only: [assign: 2]
  alias JumboParking.Store

  def on_mount(:default, _params, session, socket) do
    cart_session_id = session["cart_session_id"]

    cart =
      if cart_session_id do
        Store.get_or_create_cart(cart_session_id)
      else
        nil
      end

    {:cont, assign(socket, cart: cart, cart_session_id: cart_session_id)}
  end
end
