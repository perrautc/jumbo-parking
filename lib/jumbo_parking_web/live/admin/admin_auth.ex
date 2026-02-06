defmodule JumboParkingWeb.Admin.AdminAuth do
  @moduledoc """
  LiveView on_mount hook for admin authentication.
  Ensures the user is authenticated on WebSocket reconnects.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  alias JumboParking.Accounts
  alias JumboParking.Accounts.{Role, Scope}

  @doc """
  on_mount hook for admin authentication.

  Available hooks:
  - `:ensure_admin` - Ensures the user is authenticated (any role can view). Used for dashboard and view-only pages.
  - `:ensure_can_manage` - Ensures the user can manage parking operations (superadmin or admin). Used for customers, lots, spaces, pricing pages.
  - `:ensure_superadmin` - Ensures the user is a superadmin. Used for team management page.
  """
  def on_mount(hook, params, session, socket)

  def on_mount(:ensure_admin, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/admin/login")}
    end
  end

  def on_mount(:ensure_can_manage, _params, session, socket) do
    socket = assign_current_user(socket, session)

    cond do
      socket.assigns.current_scope == nil ->
        {:halt, redirect(socket, to: "/admin/login")}

      socket.assigns.current_scope.user == nil ->
        {:halt, redirect(socket, to: "/admin/login")}

      Role.can_manage_operations?(socket.assigns.current_scope.user.role) ->
        {:cont, socket}

      true ->
        {:halt,
         socket
         |> put_flash(:error, "You don't have permission to access this page.")
         |> redirect(to: "/admin")}
    end
  end

  def on_mount(:ensure_superadmin, _params, session, socket) do
    socket = assign_current_user(socket, session)

    cond do
      socket.assigns.current_scope == nil ->
        {:halt, redirect(socket, to: "/admin/login")}

      socket.assigns.current_scope.user == nil ->
        {:halt, redirect(socket, to: "/admin/login")}

      Role.can_manage_team?(socket.assigns.current_scope.user.role) ->
        {:cont, socket}

      true ->
        {:halt,
         socket
         |> put_flash(:error, "You don't have permission to access this page.")
         |> redirect(to: "/admin")}
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
