defmodule JumboParking.Store.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias JumboParking.Store.{Order, ProductVariant}

  @statuses ~w(pending processing shipped delivered cancelled)

  schema "order_items" do
    field :fulfillment_type, :string
    field :product_name, :string
    field :variant_name, :string
    field :sku, :string
    field :quantity, :integer
    field :unit_price, :integer
    field :line_total, :integer
    field :status, :string, default: "pending"
    field :printful_order_id, :integer
    field :tracking_number, :string
    field :tracking_url, :string

    belongs_to :order, Order
    belongs_to :variant, ProductVariant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [
      :order_id, :variant_id, :fulfillment_type, :product_name, :variant_name,
      :sku, :quantity, :unit_price, :line_total, :status,
      :printful_order_id, :tracking_number, :tracking_url
    ])
    |> validate_required([:order_id, :variant_id, :product_name, :quantity, :unit_price, :line_total])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:fulfillment_type, ["in_stock", "printful", nil])
  end

  def statuses, do: @statuses
end
