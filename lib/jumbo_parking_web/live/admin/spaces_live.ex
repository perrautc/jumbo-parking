defmodule JumboParkingWeb.Admin.SpacesLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Parking

  @impl true
  def mount(_params, _session, socket) do
    spaces = Parking.list_spaces()
    spaces_by_zone = Parking.list_spaces_by_zone()
    stats = space_stats(spaces)

    socket =
      socket
      |> assign(:page_title, "Parking Spaces")
      |> assign(:active_tab, :spaces)
      |> assign(:spaces, spaces)
      |> assign(:spaces_by_zone, spaces_by_zone)
      |> assign(:stats, stats)
      |> assign(:search, "")
      |> assign(:zone_filter, "all")
      |> assign(:status_filter, "all")
      |> assign(:show_detail_modal, false)
      |> assign(:selected_space, nil)

    {:ok, socket, layout: {JumboParkingWeb.Layouts, :admin}}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    filter_and_assign(socket, search: search)
  end

  @impl true
  def handle_event("filter_zone", %{"zone" => zone}, socket) do
    filter_and_assign(socket, zone: zone)
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    filter_and_assign(socket, status: status)
  end

  @impl true
  def handle_event("open_detail", %{"id" => id}, socket) do
    space = Parking.get_space!(String.to_integer(id))

    socket =
      socket
      |> assign(:selected_space, space)
      |> assign(:show_detail_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("release_space", %{"id" => id}, socket) do
    space = Parking.get_space!(String.to_integer(id))

    case Parking.release_space(space) do
      {:ok, _space} ->
        {:noreply, reload_spaces(socket) |> assign(:show_detail_modal, false) |> put_flash(:info, "Space released")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to release space")}
    end
  end

  @impl true
  def handle_event("set_maintenance", %{"id" => id}, socket) do
    space = Parking.get_space!(String.to_integer(id))

    case Parking.set_space_maintenance(space) do
      {:ok, _space} ->
        {:noreply, reload_spaces(socket) |> assign(:show_detail_modal, false) |> put_flash(:info, "Space set to maintenance")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update space")}
    end
  end

  @impl true
  def handle_event("mark_available", %{"id" => id}, socket) do
    space = Parking.get_space!(String.to_integer(id))

    case Parking.mark_space_available(space) do
      {:ok, _space} ->
        {:noreply, reload_spaces(socket) |> assign(:show_detail_modal, false) |> put_flash(:info, "Space marked as available")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update space")}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_detail_modal: false, selected_space: nil)}
  end

  defp filter_and_assign(socket, opts) do
    search = Keyword.get(opts, :search, socket.assigns.search)
    zone = Keyword.get(opts, :zone, socket.assigns.zone_filter)
    status = Keyword.get(opts, :status, socket.assigns.status_filter)

    spaces = Parking.filter_spaces(%{"search" => search, "zone" => zone, "status" => status})
    spaces_by_zone = spaces |> Enum.group_by(& &1.zone) |> Enum.sort_by(fn {z, _} -> z end)

    socket =
      socket
      |> assign(:spaces, spaces)
      |> assign(:spaces_by_zone, spaces_by_zone)
      |> assign(:stats, space_stats(spaces))
      |> assign(:search, search)
      |> assign(:zone_filter, zone)
      |> assign(:status_filter, status)

    {:noreply, socket}
  end

  defp reload_spaces(socket) do
    spaces = Parking.filter_spaces(%{"search" => socket.assigns.search, "zone" => socket.assigns.zone_filter, "status" => socket.assigns.status_filter})
    spaces_by_zone = spaces |> Enum.group_by(& &1.zone) |> Enum.sort_by(fn {z, _} -> z end)

    socket
    |> assign(:spaces, spaces)
    |> assign(:spaces_by_zone, spaces_by_zone)
    |> assign(:stats, space_stats(spaces))
  end

  defp space_stats(spaces) do
    %{
      total: length(spaces),
      available: Enum.count(spaces, &(&1.status == "available")),
      occupied: Enum.count(spaces, &(&1.status == "occupied")),
      reserved: Enum.count(spaces, &(&1.status == "reserved")),
      maintenance: Enum.count(spaces, &(&1.status == "maintenance"))
    }
  end

  defp space_color("available"), do: "bg-green-500/20 border-green-500/30 hover:border-green-500/60 text-green-400"
  defp space_color("occupied"), do: "bg-[#c8d935]/20 border-[#c8d935]/30 hover:border-[#c8d935]/60 text-[#c8d935]"
  defp space_color("reserved"), do: "bg-blue-500/20 border-blue-500/30 hover:border-blue-500/60 text-blue-400"
  defp space_color("maintenance"), do: "bg-gray-500/20 border-gray-500/30 hover:border-gray-500/60 text-gray-400"
  defp space_color(_), do: "bg-gray-500/20 border-gray-500/30 text-gray-400"

  defp customer_initials(nil), do: ""
  defp customer_initials(customer) do
    "#{String.first(customer.first_name || "")}#{String.first(customer.last_name || "")}"
  end
end
