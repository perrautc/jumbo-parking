defmodule JumboParking.Store.Cart do
  use Ecto.Schema
  import Ecto.Changeset

  alias JumboParking.Store.CartItem

  schema "carts" do
    field :session_id, :string
    field :expires_at, :utc_datetime

    has_many :items, CartItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cart, attrs) do
    cart
    |> cast(attrs, [:session_id, :expires_at])
    |> validate_required([:session_id])
    |> unique_constraint(:session_id)
  end

  @doc """
  Returns the total number of items in the cart.
  """
  def item_count(%__MODULE__{items: items}) when is_list(items) do
    Enum.reduce(items, 0, fn item, acc -> acc + item.quantity end)
  end

  def item_count(_), do: 0

  @doc """
  Returns the subtotal of all items in the cart (in cents).
  """
  def subtotal(%__MODULE__{items: items}) when is_list(items) do
    Enum.reduce(items, 0, fn item, acc ->
      acc + (item.unit_price * item.quantity)
    end)
  end

  def subtotal(_), do: 0
end
