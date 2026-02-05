defmodule JumboParkingWeb.Admin.AdminAuth do
  @moduledoc """
  LiveView on_mount hook for admin authentication.
  Ensures the user is authenticated on WebSocket reconnects.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  alias JumboParking.Accounts
  alias JumboParking.Accounts.Scope

  def on_mount(:ensure_admin, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/admin/login")}
    end
  end

  defp assign_current_user(socket, session) do
    case session["user_token"] do
      nil ->
        assign(socket, :current_scope, nil)

      token ->
        case Accounts.get_user_by_session_token(token) do
          {user, _token_inserted_at} ->
            assign(socket, :current_scope, Scope.for_user(user))

          nil ->
            assign(socket, :current_scope, nil)
        end
    end
  end
end
