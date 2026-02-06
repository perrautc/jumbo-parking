defmodule JumboParkingWeb.Admin.TeamLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Accounts
  alias JumboParking.Accounts.{Role, User}

  @impl true
  def mount(_params, _session, socket) do
    members = Accounts.list_team_members()

    socket =
      socket
      |> assign(:page_title, "Team Members")
      |> assign(:active_tab, :team)
      |> assign(:members, members)
      |> assign(:show_create_modal, false)
      |> assign(:show_edit_modal, false)
      |> assign(:show_delete_modal, false)
      |> assign(:show_password_modal, false)
      |> assign(:selected_member, nil)
      |> assign(:form, nil)
      |> assign(:password_form, nil)

    {:ok, socket, layout: {JumboParkingWeb.Layouts, :admin}}
  end

  @impl true
  def handle_event("new", _params, socket) do
    changeset = Accounts.change_team_member(%User{})

    socket =
      socket
      |> assign(:form, to_form(changeset))
      |> assign(:show_create_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    member = Accounts.get_team_member!(String.to_integer(id))
    changeset = Accounts.change_team_member_update(member)

    socket =
      socket
      |> assign(:selected_member, member)
      |> assign(:form, to_form(changeset))
      |> assign(:show_edit_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_delete", %{"id" => id}, socket) do
    member = Accounts.get_team_member!(String.to_integer(id))

    socket =
      socket
      |> assign(:selected_member, member)
      |> assign(:show_delete_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_password", %{"id" => id}, socket) do
    member = Accounts.get_team_member!(String.to_integer(id))
    changeset = Accounts.change_team_member_password(member)

    socket =
      socket
      |> assign(:selected_member, member)
      |> assign(:password_form, to_form(changeset))
      |> assign(:show_password_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_create_modal, false)
      |> assign(:show_edit_modal, false)
      |> assign(:show_delete_modal, false)
      |> assign(:show_password_modal, false)
      |> assign(:selected_member, nil)
      |> assign(:form, nil)
      |> assign(:password_form, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_create", %{"user" => params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_team_member(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate_edit", %{"user" => params}, socket) do
    member = socket.assigns.selected_member

    changeset =
      member
      |> Accounts.change_team_member_update(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate_password", %{"user" => params}, socket) do
    member = socket.assigns.selected_member

    changeset =
      member
      |> Accounts.change_team_member_password(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :password_form, to_form(changeset))}
  end

  @impl true
  def handle_event("create", %{"user" => params}, socket) do
    case Accounts.create_team_member(params) do
      {:ok, _member} ->
        {:noreply,
         socket
         |> put_flash(:info, "Team member created successfully")
         |> assign(:show_create_modal, false)
         |> assign(:form, nil)
         |> assign(:members, Accounts.list_team_members())}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("update", %{"user" => params}, socket) do
    member = socket.assigns.selected_member
    current_user = socket.assigns.current_scope.user
    new_role = params["role"]

    if !Accounts.can_change_role?(current_user, member, new_role) do
      {:noreply,
       socket
       |> put_flash(:error, "Cannot change role. You may be trying to demote yourself or remove the last superadmin.")}
    else
      case Accounts.update_team_member(member, params) do
        {:ok, _member} ->
          {:noreply,
           socket
           |> put_flash(:info, "Team member updated successfully")
           |> assign(:show_edit_modal, false)
           |> assign(:selected_member, nil)
           |> assign(:form, nil)
           |> assign(:members, Accounts.list_team_members())}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    end
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    member = socket.assigns.selected_member
    current_user = socket.assigns.current_scope.user

    if !Accounts.can_delete_user?(current_user, member) do
      {:noreply,
       socket
       |> put_flash(:error, "Cannot delete this user. You may be trying to delete yourself or the last superadmin.")
       |> assign(:show_delete_modal, false)
       |> assign(:selected_member, nil)}
    else
      case Accounts.delete_team_member(member) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "Team member deleted successfully")
           |> assign(:show_delete_modal, false)
           |> assign(:selected_member, nil)
           |> assign(:members, Accounts.list_team_members())}

        {:error, :last_superadmin} ->
          {:noreply,
           socket
           |> put_flash(:error, "Cannot delete the last superadmin")
           |> assign(:show_delete_modal, false)
           |> assign(:selected_member, nil)}

        {:error, _} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to delete team member")
           |> assign(:show_delete_modal, false)
           |> assign(:selected_member, nil)}
      end
    end
  end

  @impl true
  def handle_event("reset_password", %{"user" => params}, socket) do
    member = socket.assigns.selected_member

    case Accounts.reset_team_member_password(member, params) do
      {:ok, _member} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully")
         |> assign(:show_password_modal, false)
         |> assign(:selected_member, nil)
         |> assign(:password_form, nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :password_form, to_form(changeset))}
    end
  end

  defp format_date(nil), do: "-"
  defp format_date(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end

  defp role_badge_color("superadmin"), do: "bg-purple-500/10 text-purple-400"
  defp role_badge_color("admin"), do: "bg-blue-500/10 text-blue-400"
  defp role_badge_color("staff"), do: "bg-green-500/10 text-green-400"
  defp role_badge_color(_), do: "bg-gray-500/10 text-gray-400"

  defp role_options, do: Role.role_options()
end
