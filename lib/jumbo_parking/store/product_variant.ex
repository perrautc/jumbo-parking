defmodule JumboParking.Store.ProductVariant do
  use Ecto.Schema
  import Ecto.Changeset

  alias JumboParking.Parking.MerchItem

  schema "product_variants" do
    field :sku, :string
    field :name, :string
    field :size, :string
    field :color, :string
    field :color_hex, :string
    field :price, :integer
    field :printful_variant_id, :integer
    field :stock_quantity, :integer, default: 0
    field :active, :boolean, default: true

    belongs_to :merch_item, MerchItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(variant, attrs) do
    variant
    |> cast(attrs, [
      :merch_item_id, :sku, :name, :size, :color, :color_hex, :price,
      :printful_variant_id, :stock_quantity, :active
    ])
    |> validate_required([:merch_item_id, :sku])
    |> validate_number(:price, greater_than: 0)
    |> unique_constraint(:sku)
  end

  def display_name(%__MODULE__{} = variant) do
    cond do
      variant.name && variant.name != "" -> variant.name
      variant.size && variant.color -> "#{variant.color} / #{variant.size}"
      variant.size -> variant.size
      variant.color -> variant.color
      true -> "Default"
    end
  end
end
