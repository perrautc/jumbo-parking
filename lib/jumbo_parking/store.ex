defmodule JumboParking.Store do
  @moduledoc """
  The Store context - handles shopping cart, orders, and product variants.
  """

  import Ecto.Query, warn: false
  alias JumboParking.Repo

  alias JumboParking.Store.{ProductVariant, Cart, CartItem, Order, OrderItem}
  alias JumboParking.Parking.MerchItem

  # ── Product Variants ─────────────────────────────────────

  def list_variants_for_item(merch_item_id) do
    from(v in ProductVariant,
      where: v.merch_item_id == ^merch_item_id and v.active == true,
      order_by: [asc: v.size, asc: v.color]
    )
    |> Repo.all()
  end

  def get_variant!(id), do: Repo.get!(ProductVariant, id)

  def get_variant(id), do: Repo.get(ProductVariant, id)

  def get_variant_with_product!(id) do
    ProductVariant
    |> Repo.get!(id)
    |> Repo.preload(:merch_item)
  end

  def create_variant(attrs) do
    %ProductVariant{}
    |> ProductVariant.changeset(attrs)
    |> Repo.insert()
  end

  def update_variant(%ProductVariant{} = variant, attrs) do
    variant
    |> ProductVariant.changeset(attrs)
    |> Repo.update()
  end

  def delete_variant(%ProductVariant{} = variant) do
    Repo.delete(variant)
  end

  def change_variant(%ProductVariant{} = variant, attrs \\ %{}) do
    ProductVariant.changeset(variant, attrs)
  end

  # ── Shopping Cart ────────────────────────────────────────

  @cart_expiry_days 30

  def get_or_create_cart(session_id) do
    case Repo.get_by(Cart, session_id: session_id) do
      nil ->
        expires_at = DateTime.utc_now() |> DateTime.add(@cart_expiry_days, :day)

        {:ok, cart} =
          %Cart{}
          |> Cart.changeset(%{session_id: session_id, expires_at: expires_at})
          |> Repo.insert()

        cart |> Repo.preload(items: [variant: :merch_item])

      cart ->
        cart |> Repo.preload(items: [variant: :merch_item])
    end
  end

  def get_cart(session_id) do
    Cart
    |> Repo.get_by(session_id: session_id)
    |> case do
      nil -> nil
      cart -> Repo.preload(cart, items: [variant: :merch_item])
    end
  end

  def get_cart_by_id!(id) do
    Cart
    |> Repo.get!(id)
    |> Repo.preload(items: [variant: :merch_item])
  end

  def add_to_cart(cart, variant_id, quantity \\ 1) do
    variant = get_variant!(variant_id)
    price = variant.price || variant.merch_item && Repo.preload(variant, :merch_item).merch_item.price

    case Repo.get_by(CartItem, cart_id: cart.id, variant_id: variant_id) do
      nil ->
        %CartItem{}
        |> CartItem.changeset(%{
          cart_id: cart.id,
          variant_id: variant_id,
          quantity: quantity,
          unit_price: price
        })
        |> Repo.insert()

      existing ->
        existing
        |> CartItem.changeset(%{quantity: existing.quantity + quantity})
        |> Repo.update()
    end
    |> case do
      {:ok, _item} ->
        {:ok, get_cart_by_id!(cart.id)}

      error ->
        error
    end
  end

  def update_cart_item_quantity(cart, variant_id, quantity) do
    case Repo.get_by(CartItem, cart_id: cart.id, variant_id: variant_id) do
      nil ->
        {:error, :not_found}

      item when quantity <= 0 ->
        Repo.delete(item)
        {:ok, get_cart_by_id!(cart.id)}

      item ->
        item
        |> CartItem.changeset(%{quantity: quantity})
        |> Repo.update()
        |> case do
          {:ok, _} -> {:ok, get_cart_by_id!(cart.id)}
          error -> error
        end
    end
  end

  def remove_from_cart(cart, variant_id) do
    case Repo.get_by(CartItem, cart_id: cart.id, variant_id: variant_id) do
      nil -> {:ok, cart}
      item ->
        Repo.delete(item)
        {:ok, get_cart_by_id!(cart.id)}
    end
  end

  def clear_cart(cart) do
    from(i in CartItem, where: i.cart_id == ^cart.id)
    |> Repo.delete_all()

    {:ok, get_cart_by_id!(cart.id)}
  end

  def cart_item_count(nil), do: 0

  def cart_item_count(%Cart{items: items}) when is_list(items) do
    Enum.reduce(items, 0, fn item, acc -> acc + item.quantity end)
  end

  def cart_item_count(_), do: 0

  def cart_subtotal(nil), do: 0

  def cart_subtotal(%Cart{items: items}) when is_list(items) do
    Enum.reduce(items, 0, fn item, acc ->
      acc + (item.unit_price * item.quantity)
    end)
  end

  def cart_subtotal(_), do: 0

  def cleanup_expired_carts do
    now = DateTime.utc_now()

    from(c in Cart, where: c.expires_at < ^now)
    |> Repo.delete_all()
  end

  # ── Orders ───────────────────────────────────────────────

  def list_orders(opts \\ %{}) do
    Order
    |> maybe_filter_order_status(opts["status"])
    |> maybe_search_orders(opts["search"])
    |> order_by([o], desc: o.inserted_at)
    |> preload(:items)
    |> Repo.all()
  end

  defp maybe_filter_order_status(query, nil), do: query
  defp maybe_filter_order_status(query, ""), do: query
  defp maybe_filter_order_status(query, "all"), do: query
  defp maybe_filter_order_status(query, status), do: where(query, [o], o.status == ^status)

  defp maybe_search_orders(query, nil), do: query
  defp maybe_search_orders(query, ""), do: query

  defp maybe_search_orders(query, search) do
    search = "%#{search}%"

    where(
      query,
      [o],
      ilike(o.order_number, ^search) or ilike(o.email, ^search) or
        ilike(o.shipping_name, ^search)
    )
  end

  def get_order!(id) do
    Order
    |> Repo.get!(id)
    |> Repo.preload(items: [variant: :merch_item])
  end

  def get_order_by_number(order_number) do
    Order
    |> Repo.get_by(order_number: order_number)
    |> case do
      nil -> nil
      order -> Repo.preload(order, items: [variant: :merch_item])
    end
  end

  def get_order_by_stripe_session(session_id) do
    Order
    |> Repo.get_by(stripe_session_id: session_id)
    |> case do
      nil -> nil
      order -> Repo.preload(order, items: [variant: :merch_item])
    end
  end

  def create_order(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  def create_order_from_cart(cart, order_attrs) do
    cart = Repo.preload(cart, items: [variant: :merch_item])
    subtotal = cart_subtotal(cart)
    shipping_cost = order_attrs[:shipping_cost] || 0
    tax = order_attrs[:tax] || 0
    total = subtotal + shipping_cost + tax

    order_number = generate_order_number()

    order_attrs =
      order_attrs
      |> Map.put(:order_number, order_number)
      |> Map.put(:subtotal, subtotal)
      |> Map.put(:total, total)

    Repo.transaction(fn ->
      {:ok, order} = create_order(order_attrs)

      Enum.each(cart.items, fn cart_item ->
        variant = cart_item.variant
        merch_item = variant.merch_item

        %OrderItem{}
        |> OrderItem.changeset(%{
          order_id: order.id,
          variant_id: variant.id,
          fulfillment_type: merch_item.fulfillment_type,
          product_name: merch_item.name,
          variant_name: ProductVariant.display_name(variant),
          sku: variant.sku,
          quantity: cart_item.quantity,
          unit_price: cart_item.unit_price,
          line_total: cart_item.quantity * cart_item.unit_price
        })
        |> Repo.insert!()
      end)

      get_order!(order.id)
    end)
  end

  defp generate_order_number do
    # Get current count + 1
    count =
      from(o in Order, select: count(o.id))
      |> Repo.one()

    "JP-#{String.pad_leading("#{count + 1001}", 4, "0")}"
  end

  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  # ── Order Items ──────────────────────────────────────────

  def update_order_item(%OrderItem{} = item, attrs) do
    item
    |> OrderItem.changeset(attrs)
    |> Repo.update()
  end

  def get_order_items_by_fulfillment(order_id, fulfillment_type) do
    from(i in OrderItem,
      where: i.order_id == ^order_id and i.fulfillment_type == ^fulfillment_type,
      preload: [variant: :merch_item]
    )
    |> Repo.all()
  end

  # ── Products with Variants ───────────────────────────────

  def list_products_with_variants do
    from(m in MerchItem,
      where: m.active == true,
      order_by: m.sort_order,
      preload: [variants: ^from(v in ProductVariant, where: v.active == true, order_by: [asc: v.size])]
    )
    |> Repo.all()
  end

  def get_product_with_variants!(id) do
    MerchItem
    |> Repo.get!(id)
    |> Repo.preload(variants: from(v in ProductVariant, where: v.active == true, order_by: [asc: v.size]))
  end

  # ── Price Formatting ─────────────────────────────────────

  def format_price(nil), do: "$0.00"
  def format_price(cents) when is_integer(cents) do
    "$#{:erlang.float_to_binary(cents / 100, decimals: 2)}"
  end
  def format_price(_), do: "$0.00"
end
