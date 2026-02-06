defmodule JumboParkingWeb.Store.OrderConfirmationLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Store
  alias JumboParking.Store.Order

  @impl true
  def mount(%{"order_number" => order_number}, _session, socket) do
    case Store.get_order_by_number(order_number) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Order not found")
         |> push_navigate(to: ~p"/store")}

      order ->
        socket =
          socket
          |> assign(:page_title, "Order Confirmed - #{order.order_number}")
          |> assign(:order, order)

        {:ok, socket}
    end
  end

  def format_price(cents), do: Store.format_price(cents)

  def status_color(status), do: Order.status_color(status)
  def status_label(status), do: Order.status_label(status)
end
