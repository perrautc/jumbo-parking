defmodule JumboParkingWeb.Admin.CustomersLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Parking

  @impl true
  def mount(_params, _session, socket) do
    customers = Parking.list_customers()

    socket =
      socket
      |> assign(:page_title, "Customers")
      |> assign(:active_tab, :customers)
      |> assign(:customers, customers)
      |> assign(:search, "")
      |> assign(:status_filter, "all")
      |> assign(:vehicle_filter, "all")
      |> assign(:show_edit_modal, false)
      |> assign(:show_delete_modal, false)
      |> assign(:show_assign_modal, false)
      |> assign(:selected_customer, nil)
      |> assign(:edit_form, nil)
      |> assign(:available_spaces, [])

    {:ok, socket, layout: {JumboParkingWeb.Layouts, :admin}}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    customers = Parking.filter_customers(%{"search" => search, "status" => socket.assigns.status_filter, "vehicle_type" => socket.assigns.vehicle_filter})
    {:noreply, assign(socket, customers: customers, search: search)}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    customers = Parking.filter_customers(%{"search" => socket.assigns.search, "status" => status, "vehicle_type" => socket.assigns.vehicle_filter})
    {:noreply, assign(socket, customers: customers, status_filter: status)}
  end

  @impl true
  def handle_event("filter_vehicle", %{"vehicle" => vehicle}, socket) do
    customers = Parking.filter_customers(%{"search" => socket.assigns.search, "status" => socket.assigns.status_filter, "vehicle_type" => vehicle})
    {:noreply, assign(socket, customers: customers, vehicle_filter: vehicle)}
  end

  @impl true
  def handle_event("open_edit", %{"id" => id}, socket) do
    customer = Parking.get_customer!(String.to_integer(id))
    changeset = Parking.change_customer(customer)

    socket =
      socket
      |> assign(:selected_customer, customer)
      |> assign(:edit_form, to_form(changeset))
      |> assign(:show_edit_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("save_customer", %{"customer" => params}, socket) do
    customer = socket.assigns.selected_customer

    case Parking.update_customer(customer, params) do
      {:ok, _customer} ->
        customers = reload_customers(socket)

        socket =
          socket
          |> assign(:customers, customers)
          |> assign(:show_edit_modal, false)
          |> assign(:selected_customer, nil)
          |> put_flash(:info, "Customer updated successfully")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :edit_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("open_delete", %{"id" => id}, socket) do
    customer = Parking.get_customer!(String.to_integer(id))

    socket =
      socket
      |> assign(:selected_customer, customer)
      |> assign(:show_delete_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    customer = socket.assigns.selected_customer

    case Parking.delete_customer(customer) do
      {:ok, _} ->
        customers = reload_customers(socket)

        socket =
          socket
          |> assign(:customers, customers)
          |> assign(:show_delete_modal, false)
          |> assign(:selected_customer, nil)
          |> put_flash(:info, "Customer deleted successfully")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete customer")}
    end
  end

  @impl true
  def handle_event("open_assign", %{"id" => id}, socket) do
    customer = Parking.get_customer!(String.to_integer(id))
    available_spaces = Parking.get_available_spaces()

    socket =
      socket
      |> assign(:selected_customer, customer)
      |> assign(:available_spaces, available_spaces)
      |> assign(:show_assign_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("assign_space", %{"space_id" => space_id}, socket) do
    customer = socket.assigns.selected_customer
    space = Parking.get_space!(String.to_integer(space_id))

    case Parking.assign_space(space, customer) do
      {:ok, _space} ->
        customers = reload_customers(socket)

        socket =
          socket
          |> assign(:customers, customers)
          |> assign(:show_assign_modal, false)
          |> assign(:selected_customer, nil)
          |> put_flash(:info, "Space assigned successfully")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to assign space")}
    end
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_edit_modal, false)
      |> assign(:show_delete_modal, false)
      |> assign(:show_assign_modal, false)
      |> assign(:selected_customer, nil)

    {:noreply, socket}
  end

  defp reload_customers(socket) do
    Parking.filter_customers(%{
      "search" => socket.assigns.search,
      "status" => socket.assigns.status_filter,
      "vehicle_type" => socket.assigns.vehicle_filter
    })
  end
end
