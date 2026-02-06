defmodule JumboParkingWeb.Admin.VehicleTypesLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Parking
  alias JumboParking.Parking.VehicleType

  @impl true
  def mount(_params, _session, socket) do
    vehicle_types = Parking.list_vehicle_types()

    socket =
      socket
      |> assign(:page_title, "Vehicle Types")
      |> assign(:active_tab, :vehicle_types)
      |> assign(:vehicle_types, vehicle_types)
      |> assign(:show_modal, false)
      |> assign(:editing_vehicle_type, nil)
      |> assign(:form, nil)

    {:ok, socket, layout: {JumboParkingWeb.Layouts, :admin}}
  end

  @impl true
  def handle_event("new", _params, socket) do
    changeset = Parking.change_vehicle_type(%VehicleType{})

    socket =
      socket
      |> assign(:editing_vehicle_type, nil)
      |> assign(:form, to_form(changeset))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    vehicle_type = Parking.get_vehicle_type!(String.to_integer(id))
    changeset = Parking.change_vehicle_type(vehicle_type)

    socket =
      socket
      |> assign(:editing_vehicle_type, vehicle_type)
      |> assign(:form, to_form(changeset))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, show_modal: false, editing_vehicle_type: nil, form: nil)}
  end

  @impl true
  def handle_event("validate", %{"vehicle_type" => params}, socket) do
    vehicle_type = socket.assigns.editing_vehicle_type || %VehicleType{}

    changeset =
      vehicle_type
      |> Parking.change_vehicle_type(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"vehicle_type" => params}, socket) do
    case socket.assigns.editing_vehicle_type do
      nil ->
        case Parking.create_vehicle_type(params) do
          {:ok, _vehicle_type} ->
            {:noreply,
             socket
             |> put_flash(:info, "Vehicle type created")
             |> assign(:show_modal, false)
             |> assign(:vehicle_types, Parking.list_vehicle_types())}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end

      vehicle_type ->
        case Parking.update_vehicle_type(vehicle_type, params) do
          {:ok, _vehicle_type} ->
            {:noreply,
             socket
             |> put_flash(:info, "Vehicle type updated")
             |> assign(:show_modal, false)
             |> assign(:vehicle_types, Parking.list_vehicle_types())}

          {:error, changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    vehicle_type = Parking.get_vehicle_type!(String.to_integer(id))

    case Parking.delete_vehicle_type(vehicle_type) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Vehicle type deleted")
         |> assign(:vehicle_types, Parking.list_vehicle_types())}

      {:error, :in_use} ->
        {:noreply, put_flash(socket, :error, "Cannot delete vehicle type that is in use by pricing plans, customers, or spaces")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete vehicle type")}
    end
  end

  @impl true
  def handle_event("toggle_active", %{"id" => id}, socket) do
    vehicle_type = Parking.get_vehicle_type!(String.to_integer(id))

    case Parking.update_vehicle_type(vehicle_type, %{active: !vehicle_type.active}) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Vehicle type #{if vehicle_type.active, do: "deactivated", else: "activated"}")
         |> assign(:vehicle_types, Parking.list_vehicle_types())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update vehicle type")}
    end
  end

  defp format_dimension(nil), do: "-"
  defp format_dimension(value), do: "#{Decimal.to_string(value)} ft"

  defp format_dimension_range(nil, nil), do: "-"
  defp format_dimension_range(min, max) do
    min_str = if min, do: Decimal.to_string(min), else: "?"
    max_str = if max, do: Decimal.to_string(max), else: "?"
    "#{min_str} - #{max_str} ft"
  end
end
