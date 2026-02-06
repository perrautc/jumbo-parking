defmodule JumboParking.Store.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias JumboParking.Store.{Cart, ProductVariant}

  schema "cart_items" do
    field :quantity, :integer, default: 1
    field :unit_price, :integer

    belongs_to :cart, Cart
    belongs_to :variant, ProductVariant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cart_item, attrs) do
    cart_item
    |> cast(attrs, [:cart_id, :variant_id, :quantity, :unit_price])
    |> validate_required([:cart_id, :variant_id, :quantity, :unit_price])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:unit_price, greater_than_or_equal_to: 0)
    |> unique_constraint([:cart_id, :variant_id])
  end

  @doc """
  Returns the line total for this cart item (in cents).
  """
  def line_total(%__MODULE__{quantity: qty, unit_price: price}) do
    qty * price
  end
end
