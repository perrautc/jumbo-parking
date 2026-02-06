defmodule JumboParking.Store.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias JumboParking.Store.OrderItem

  @statuses ~w(pending paid processing shipped delivered cancelled refunded)

  schema "orders" do
    field :order_number, :string
    field :email, :string
    field :status, :string, default: "pending"

    # Shipping address
    field :shipping_name, :string
    field :shipping_address1, :string
    field :shipping_address2, :string
    field :shipping_city, :string
    field :shipping_state, :string
    field :shipping_zip, :string
    field :shipping_country, :string, default: "US"

    # Financials (cents)
    field :subtotal, :integer
    field :shipping_cost, :integer
    field :tax, :integer, default: 0
    field :total, :integer

    # Stripe
    field :stripe_session_id, :string
    field :stripe_payment_intent_id, :string
    field :shipping_method, :string

    has_many :items, OrderItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [
      :order_number, :email, :status,
      :shipping_name, :shipping_address1, :shipping_address2,
      :shipping_city, :shipping_state, :shipping_zip, :shipping_country,
      :subtotal, :shipping_cost, :tax, :total,
      :stripe_session_id, :stripe_payment_intent_id, :shipping_method
    ])
    |> validate_required([:order_number, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:order_number)
  end

  @doc """
  Creates a changeset for checkout with shipping address validation.
  """
  def checkout_changeset(order, attrs) do
    order
    |> changeset(attrs)
    |> validate_required([
      :shipping_name, :shipping_address1, :shipping_city,
      :shipping_state, :shipping_zip
    ])
  end

  def statuses, do: @statuses

  def status_label("pending"), do: "Pending Payment"
  def status_label("paid"), do: "Paid"
  def status_label("processing"), do: "Processing"
  def status_label("shipped"), do: "Shipped"
  def status_label("delivered"), do: "Delivered"
  def status_label("cancelled"), do: "Cancelled"
  def status_label("refunded"), do: "Refunded"
  def status_label(status), do: String.capitalize(status)

  def status_color("pending"), do: "bg-yellow-500/20 text-yellow-400"
  def status_color("paid"), do: "bg-green-500/20 text-green-400"
  def status_color("processing"), do: "bg-blue-500/20 text-blue-400"
  def status_color("shipped"), do: "bg-purple-500/20 text-purple-400"
  def status_color("delivered"), do: "bg-green-500/20 text-green-400"
  def status_color("cancelled"), do: "bg-red-500/20 text-red-400"
  def status_color("refunded"), do: "bg-gray-500/20 text-gray-400"
  def status_color(_), do: "bg-gray-500/20 text-gray-400"
end
