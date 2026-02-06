defmodule JumboParking.Parking.MerchItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias JumboParking.Store.ProductVariant

  schema "merch_items" do
    field :name, :string
    field :description, :string
    field :price, :integer  # in cents
    field :image_url, :string
    field :badge, :string  # "popular", "new", "sale", or nil
    field :external_url, :string  # link to POD provider product page
    field :sku, :string  # for POD integration
    field :active, :boolean, default: true
    field :sort_order, :integer, default: 0

    # Fulfillment fields
    field :fulfillment_type, :string, default: "in_stock"  # "printful" or "in_stock"
    field :printful_sync_product_id, :integer
    field :track_inventory, :boolean, default: false
    field :stock_quantity, :integer, default: 0

    has_many :variants, ProductVariant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(merch_item, attrs) do
    merch_item
    |> cast(attrs, [
      :name, :description, :price, :image_url, :badge, :external_url, :sku,
      :active, :sort_order, :fulfillment_type, :printful_sync_product_id,
      :track_inventory, :stock_quantity
    ])
    |> validate_required([:name, :price])
    |> validate_number(:price, greater_than: 0)
    |> validate_inclusion(:badge, [nil, "", "popular", "new", "sale"])
    |> validate_inclusion(:fulfillment_type, ["in_stock", "printful"])
  end
end
