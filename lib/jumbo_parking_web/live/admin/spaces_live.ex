defmodule JumboParkingWeb.Admin.SpacesLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Parking

  @impl true
  def mount(params, _session, socket) do
    lots = Parking.list_lots()
    initial_lot_id = params["lot_id"]

    filters = %{
      "lot_id" => initial_lot_id || "all",
      "vehicle_type" => "all",
      "status" => "all",
      "search" => ""
    }

    spaces = Parking.filter_spaces(filters)
    spaces_by_lot = group_spaces_by_lot(spaces)
    stats = space_stats(spaces)

    socket =
      socket
      |> assign(:page_title, "Parking Spaces")
      |> assign(:active_tab, :spaces)
      |> assign(:spaces, spaces)
      |> assign(:spaces_by_lot, spaces_by_lot)
      |> assign(:lots, lots)
      |> assign(:stats, stats)
      |> assign(:search, "")
      |> assign(:lot_filter, initial_lot_id || "all")
      |> assign(:vehicle_filter, "all")
      |> assign(:status_filter, "all")
      |> assign(:show_detail_modal, false)
      |> assign(:show_create_modal, false)
      |> assign(:show_bulk_modal, false)
      |> assign(:show_delete_modal, false)
      |> assign(:selected_space, nil)
      |> assign(:create_form, new_space_form())
      |> assign(:bulk_form, new_bulk_form())

    {:ok, socket, layout: {JumboParkingWeb.Layouts, :admin}}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    if lot_id = params["lot_id"] do
      {:noreply, filter_and_assign(socket, lot: lot_id) |> elem(1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    filter_and_assign(socket, search: search)
  end

  @impl true
  def handle_event("filter_lot", %{"lot_id" => lot_id}, socket) do
    filter_and_assign(socket, lot: lot_id)
  end

  @impl true
  def handle_event("filter_vehicle", %{"vehicle_type" => vehicle_type}, socket) do
    filter_and_assign(socket, vehicle_type: vehicle_type)
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
  def handle_event("open_create", _params, socket) do
    socket =
      socket
      |> assign(:create_form, new_space_form())
      |> assign(:show_create_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_bulk", _params, socket) do
    socket =
      socket
      |> assign(:bulk_form, new_bulk_form())
      |> assign(:show_bulk_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_space", %{"space" => params}, socket) do
    case Parking.create_space(params) do
      {:ok, _space} ->
        {:noreply,
         socket
         |> reload_spaces()
         |> assign(:show_create_modal, false)
         |> put_flash(:info, "Space created successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :create_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("bulk_create", %{"bulk" => params}, socket) do
    lot_id = String.to_integer(params["parking_lot_id"])
    prefix = params["prefix"]
    start_num = String.to_integer(params["start_num"])
    end_num = String.to_integer(params["end_num"])
    vehicle_type = params["vehicle_type"]
    section = if params["section"] == "", do: nil, else: params["section"]

    case Parking.bulk_create_spaces(lot_id, prefix, start_num, end_num, vehicle_type, section) do
      {:ok, %{created: created, errors: 0}} ->
        {:noreply,
         socket
         |> reload_spaces()
         |> assign(:show_bulk_modal, false)
         |> put_flash(:info, "#{created} spaces created successfully")}

      {:ok, %{created: created, errors: errors}} ->
        {:noreply,
         socket
         |> reload_spaces()
         |> assign(:show_bulk_modal, false)
         |> put_flash(:warning, "#{created} spaces created, #{errors} failed (likely duplicates)")}

      _ ->
        {:noreply, put_flash(socket, :error, "Failed to create spaces")}
    end
  end

  @impl true
  def handle_event("open_delete", %{"id" => id}, socket) do
    space = Parking.get_space!(String.to_integer(id))

    socket =
      socket
      |> assign(:selected_space, space)
      |> assign(:show_delete_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    space = socket.assigns.selected_space

    case Parking.delete_space(space) do
      {:ok, _} ->
        {:noreply,
         socket
         |> reload_spaces()
         |> assign(:show_delete_modal, false)
         |> assign(:show_detail_modal, false)
         |> assign(:selected_space, nil)
         |> put_flash(:info, "Space deleted successfully")}

      {:error, :not_available} ->
        {:noreply,
         socket
         |> assign(:show_delete_modal, false)
         |> put_flash(:error, "Cannot delete space that is not available")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete space")}
    end
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
    {:noreply,
     assign(socket,
       show_detail_modal: false,
       show_create_modal: false,
       show_bulk_modal: false,
       show_delete_modal: false,
       selected_space: nil
     )}
  end

  defp filter_and_assign(socket, opts) do
    search = Keyword.get(opts, :search, socket.assigns.search)
    lot = Keyword.get(opts, :lot, socket.assigns.lot_filter)
    vehicle_type = Keyword.get(opts, :vehicle_type, socket.assigns.vehicle_filter)
    status = Keyword.get(opts, :status, socket.assigns.status_filter)

    spaces =
      Parking.filter_spaces(%{
        "search" => search,
        "lot_id" => lot,
        "vehicle_type" => vehicle_type,
        "status" => status
      })

    spaces_by_lot = group_spaces_by_lot(spaces)

    socket =
      socket
      |> assign(:spaces, spaces)
      |> assign(:spaces_by_lot, spaces_by_lot)
      |> assign(:stats, space_stats(spaces))
      |> assign(:search, search)
      |> assign(:lot_filter, lot)
      |> assign(:vehicle_filter, vehicle_type)
      |> assign(:status_filter, status)

    {:noreply, socket}
  end

  defp reload_spaces(socket) do
    spaces =
      Parking.filter_spaces(%{
        "search" => socket.assigns.search,
        "lot_id" => socket.assigns.lot_filter,
        "vehicle_type" => socket.assigns.vehicle_filter,
        "status" => socket.assigns.status_filter
      })

    spaces_by_lot = group_spaces_by_lot(spaces)

    socket
    |> assign(:spaces, spaces)
    |> assign(:spaces_by_lot, spaces_by_lot)
    |> assign(:stats, space_stats(spaces))
    |> assign(:lots, Parking.list_lots())
  end

  defp group_spaces_by_lot(spaces) do
    spaces
    |> Enum.group_by(& &1.parking_lot)
    |> Enum.sort_by(fn {lot, _} -> if lot, do: lot.name, else: "" end)
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

  defp new_space_form do
    to_form(%{"parking_lot_id" => "", "number" => "", "vehicle_type" => "truck", "section" => ""})
  end

  defp new_bulk_form do
    to_form(%{
      "parking_lot_id" => "",
      "prefix" => "",
      "start_num" => "1",
      "end_num" => "10",
      "vehicle_type" => "truck",
      "section" => ""
    })
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
