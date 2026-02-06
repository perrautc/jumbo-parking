defmodule JumboParkingWeb.Store.StoreLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Store
  alias JumboParking.Parking

  @impl true
  def mount(_params, session, socket) do
    cart_session_id = session["cart_session_id"]
    cart = if cart_session_id, do: Store.get_or_create_cart(cart_session_id), else: nil
    products = Store.list_products_with_variants()
    merch_enabled = Parking.get_setting_bool("merch_store_enabled")

    socket =
      socket
      |> assign(:page_title, "Store")
      |> assign(:products, products)
      |> assign(:merch_enabled, merch_enabled)
      |> assign(:cart, cart)
      |> assign(:cart_session_id, cart_session_id)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("add_to_cart", %{"variant_id" => variant_id}, socket) do
    cart = socket.assigns.cart

    case Store.add_to_cart(cart, String.to_integer(variant_id)) do
      {:ok, updated_cart} ->
        {:noreply,
         socket
         |> assign(:cart, updated_cart)
         |> put_flash(:info, "Added to cart!")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not add item to cart")}
    end
  end

  def format_price(cents), do: Store.format_price(cents)
end
