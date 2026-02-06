defmodule JumboParkingWeb.Admin.LotsLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Parking
  alias JumboParking.Parking.ParkingLot

  @impl true
  def mount(_params, _session, socket) do
    lots = Parking.all_lots_with_counts()

    socket =
      socket
      |> assign(:page_title, "Parking Lots")
      |> assign(:active_tab, :lots)
      |> assign(:lots, lots)
      |> assign(:show_form_modal, false)
      |> assign(:show_delete_modal, false)
      |> assign(:selected_lot, nil)
      |> assign(:lot_form, nil)

    {:ok, socket, layout: {JumboParkingWeb.Layouts, :admin}}
  end

  @impl true
  def handle_event("new_lot", _params, socket) do
    changeset = Parking.change_lot(%ParkingLot{})

    socket =
      socket
      |> assign(:selected_lot, nil)
      |> assign(:lot_form, to_form(changeset))
      |> assign(:show_form_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("edit_lot", %{"id" => id}, socket) do
    lot = Parking.get_lot!(String.to_integer(id))
    changeset = Parking.change_lot(lot)

    socket =
      socket
      |> assign(:selected_lot, lot)
      |> assign(:lot_form, to_form(changeset))
      |> assign(:show_form_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("save_lot", %{"parking_lot" => params}, socket) do
    case socket.assigns.selected_lot do
      nil ->
        case Parking.create_lot(params) do
          {:ok, _lot} ->
            {:noreply,
             socket
             |> assign(:lots, Parking.all_lots_with_counts())
             |> assign(:show_form_modal, false)
             |> put_flash(:info, "Parking lot created successfully")}

          {:error, changeset} ->
            {:noreply, assign(socket, :lot_form, to_form(changeset))}
        end

      lot ->
        case Parking.update_lot(lot, params) do
          {:ok, _lot} ->
            {:noreply,
             socket
             |> assign(:lots, Parking.all_lots_with_counts())
             |> assign(:show_form_modal, false)
             |> put_flash(:info, "Parking lot updated successfully")}

          {:error, changeset} ->
            {:noreply, assign(socket, :lot_form, to_form(changeset))}
        end
    end
  end

  @impl true
  def handle_event("open_delete", %{"id" => id}, socket) do
    lot = Parking.get_lot!(String.to_integer(id))

    socket =
      socket
      |> assign(:selected_lot, lot)
      |> assign(:show_delete_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    lot = socket.assigns.selected_lot

    case Parking.delete_lot(lot) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:lots, Parking.all_lots_with_counts())
         |> assign(:show_delete_modal, false)
         |> assign(:selected_lot, nil)
         |> put_flash(:info, "Parking lot deleted successfully")}

      {:error, :has_spaces} ->
        {:noreply,
         socket
         |> assign(:show_delete_modal, false)
         |> put_flash(:error, "Cannot delete lot with spaces. Delete all spaces first.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete parking lot")}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_form_modal, false)
      |> assign(:show_delete_modal, false)
      |> assign(:selected_lot, nil)

    {:noreply, socket}
  end

  defp format_address(lot) do
    parts =
      [lot.street, lot.city, lot.state, lot.zip]
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&(&1 == ""))

    case parts do
      [] -> "No address"
      [city, state] -> "#{city}, #{state}"
      [street, city, state] -> "#{street}, #{city}, #{state}"
      [street, city, state, zip] -> "#{street}, #{city}, #{state} #{zip}"
      _ -> Enum.join(parts, ", ")
    end
  end
end
