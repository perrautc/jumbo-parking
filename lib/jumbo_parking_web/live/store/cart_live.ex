defmodule JumboParkingWeb.Store.CartLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Store
  alias JumboParking.Store.ProductVariant

  @impl true
  def mount(_params, session, socket) do
    cart_session_id = session["cart_session_id"]
    cart = if cart_session_id, do: Store.get_or_create_cart(cart_session_id), else: nil

    socket =
      socket
      |> assign(:page_title, "Shopping Cart")
      |> assign(:cart, cart)
      |> assign(:cart_session_id, cart_session_id)

    {:ok, socket}
  end

  @impl true
  def handle_event("update_quantity", %{"variant_id" => variant_id, "quantity" => quantity}, socket) do
    cart = socket.assigns.cart
    qty = String.to_integer(quantity)

    case Store.update_cart_item_quantity(cart, String.to_integer(variant_id), qty) do
      {:ok, updated_cart} ->
        {:noreply, assign(socket, :cart, updated_cart)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not update quantity")}
    end
  end

  @impl true
  def handle_event("remove_item", %{"variant_id" => variant_id}, socket) do
    cart = socket.assigns.cart

    case Store.remove_from_cart(cart, String.to_integer(variant_id)) do
      {:ok, updated_cart} ->
        {:noreply,
         socket
         |> assign(:cart, updated_cart)
         |> put_flash(:info, "Item removed from cart")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not remove item")}
    end
  end

  @impl true
  def handle_event("clear_cart", _params, socket) do
    cart = socket.assigns.cart

    case Store.clear_cart(cart) do
      {:ok, updated_cart} ->
        {:noreply,
         socket
         |> assign(:cart, updated_cart)
         |> put_flash(:info, "Cart cleared")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not clear cart")}
    end
  end

  def format_price(cents), do: Store.format_price(cents)

  def item_line_total(item) do
    item.quantity * item.unit_price
  end

  def variant_display_name(variant) do
    ProductVariant.display_name(variant)
  end
end
