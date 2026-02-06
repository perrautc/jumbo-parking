defmodule JumboParkingWeb.Store.ProductLive do
  use JumboParkingWeb, :live_view

  alias JumboParking.Store

  @impl true
  def mount(%{"id" => id}, session, socket) do
    cart_session_id = session["cart_session_id"]
    cart = if cart_session_id, do: Store.get_or_create_cart(cart_session_id), else: nil

    product = Store.get_product_with_variants!(id)
    variants = product.variants

    # Group variants by size and color
    sizes = variants |> Enum.map(& &1.size) |> Enum.uniq() |> Enum.reject(&is_nil/1)
    colors = variants |> Enum.map(& &1.color) |> Enum.uniq() |> Enum.reject(&is_nil/1)

    # Select first variant by default
    selected_variant = List.first(variants)

    socket =
      socket
      |> assign(:page_title, product.name)
      |> assign(:product, product)
      |> assign(:variants, variants)
      |> assign(:sizes, sizes)
      |> assign(:colors, colors)
      |> assign(:selected_variant, selected_variant)
      |> assign(:selected_size, selected_variant && selected_variant.size)
      |> assign(:selected_color, selected_variant && selected_variant.color)
      |> assign(:quantity, 1)
      |> assign(:cart, cart)
      |> assign(:cart_session_id, cart_session_id)
      |> assign(:added_to_cart, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_size", %{"size" => size}, socket) do
    variant = find_variant(socket.assigns.variants, size, socket.assigns.selected_color)

    socket =
      socket
      |> assign(:selected_size, size)
      |> assign(:selected_variant, variant)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_color", %{"color" => color}, socket) do
    variant = find_variant(socket.assigns.variants, socket.assigns.selected_size, color)

    socket =
      socket
      |> assign(:selected_color, color)
      |> assign(:selected_variant, variant)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_quantity", %{"quantity" => qty}, socket) do
    quantity = max(1, String.to_integer(qty))
    {:noreply, assign(socket, :quantity, quantity)}
  end

  @impl true
  def handle_event("increment_quantity", _params, socket) do
    {:noreply, assign(socket, :quantity, socket.assigns.quantity + 1)}
  end

  @impl true
  def handle_event("decrement_quantity", _params, socket) do
    quantity = max(1, socket.assigns.quantity - 1)
    {:noreply, assign(socket, :quantity, quantity)}
  end

  @impl true
  def handle_event("add_to_cart", _params, socket) do
    cart = socket.assigns.cart
    variant = socket.assigns.selected_variant
    quantity = socket.assigns.quantity

    if variant do
      case Store.add_to_cart(cart, variant.id, quantity) do
        {:ok, updated_cart} ->
          {:noreply,
           socket
           |> assign(:cart, updated_cart)
           |> assign(:added_to_cart, true)
           |> put_flash(:info, "Added to cart!")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Could not add item to cart")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please select a variant")}
    end
  end

  defp find_variant(variants, size, color) do
    Enum.find(variants, fn v ->
      (is_nil(size) or v.size == size) and (is_nil(color) or v.color == color)
    end) || List.first(variants)
  end

  def variant_price(variant, product) do
    variant.price || product.price
  end

  def format_price(cents), do: Store.format_price(cents)
end
