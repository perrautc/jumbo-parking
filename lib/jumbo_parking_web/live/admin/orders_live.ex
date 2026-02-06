defmodule JumboParkingWeb.Admin.OrdersLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Store
  alias JumboParking.Store.Order
  alias JumboParking.Fulfillment

  @impl true
  def mount(_params, _session, socket) do
    orders = Store.list_orders()

    socket =
      socket
      |> assign(:page_title, "Orders")
      |> assign(:active_tab, :orders)
      |> assign(:orders, orders)
      |> assign(:filter_status, "all")
      |> assign(:search, "")
      |> assign(:show_order_modal, false)
      |> assign(:selected_order, nil)

    {:ok, socket, layout: {JumboParkingWeb.Layouts, :admin}}
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    orders = Store.list_orders(%{"status" => status, "search" => socket.assigns.search})

    {:noreply,
     socket
     |> assign(:orders, orders)
     |> assign(:filter_status, status)}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    orders = Store.list_orders(%{"status" => socket.assigns.filter_status, "search" => search})

    {:noreply,
     socket
     |> assign(:orders, orders)
     |> assign(:search, search)}
  end

  @impl true
  def handle_event("view_order", %{"id" => id}, socket) do
    order = Store.get_order!(String.to_integer(id))

    {:noreply,
     socket
     |> assign(:selected_order, order)
     |> assign(:show_order_modal, true)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_order_modal, false)
     |> assign(:selected_order, nil)}
  end

  @impl true
  def handle_event("update_status", %{"id" => id, "status" => status}, socket) do
    order = Store.get_order!(String.to_integer(id))

    case Store.update_order(order, %{status: status}) do
      {:ok, _order} ->
        orders = Store.list_orders(%{"status" => socket.assigns.filter_status, "search" => socket.assigns.search})

        {:noreply,
         socket
         |> assign(:orders, orders)
         |> put_flash(:info, "Order status updated")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update order status")}
    end
  end

  @impl true
  def handle_event("process_fulfillment", %{"id" => id}, socket) do
    case Fulfillment.process_order(String.to_integer(id)) do
      {:ok, _} ->
        orders = Store.list_orders(%{"status" => socket.assigns.filter_status, "search" => socket.assigns.search})

        {:noreply,
         socket
         |> assign(:orders, orders)
         |> put_flash(:info, "Order sent for fulfillment")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Fulfillment error: #{inspect(reason)}")}
    end
  end

  def format_price(cents), do: Store.format_price(cents)

  def format_date(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y %I:%M %p")
  end

  def status_color(status), do: Order.status_color(status)
  def status_label(status), do: Order.status_label(status)
  def statuses, do: Order.statuses()
end
