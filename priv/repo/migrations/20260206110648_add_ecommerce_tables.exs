defmodule JumboParking.Repo.Migrations.AddEcommerceTables do
  use Ecto.Migration

  def change do
    # Add fulfillment fields to merch_items
    alter table(:merch_items) do
      add :fulfillment_type, :string, default: "in_stock"
      add :printful_sync_product_id, :integer
      add :track_inventory, :boolean, default: false
      add :stock_quantity, :integer, default: 0
    end

    # Product variants (size/color options)
    create table(:product_variants) do
      add :merch_item_id, references(:merch_items, on_delete: :delete_all), null: false
      add :sku, :string, null: false
      add :name, :string
      add :size, :string
      add :color, :string
      add :color_hex, :string
      add :price, :integer
      add :printful_variant_id, :integer
      add :stock_quantity, :integer, default: 0
      add :active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:product_variants, [:merch_item_id])
    create unique_index(:product_variants, [:sku])
    create index(:product_variants, [:active])

    # Shopping carts (session-based)
    create table(:carts) do
      add :session_id, :string, null: false
      add :expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:carts, [:session_id])

    # Cart items
    create table(:cart_items) do
      add :cart_id, references(:carts, on_delete: :delete_all), null: false
      add :variant_id, references(:product_variants, on_delete: :delete_all), null: false
      add :quantity, :integer, default: 1
      add :unit_price, :integer

      timestamps(type: :utc_datetime)
    end

    create index(:cart_items, [:cart_id])
    create index(:cart_items, [:variant_id])
    create unique_index(:cart_items, [:cart_id, :variant_id])

    # Orders
    create table(:orders) do
      add :order_number, :string, null: false
      add :email, :string, null: false
      add :status, :string, default: "pending"
      # Shipping address
      add :shipping_name, :string
      add :shipping_address1, :string
      add :shipping_address2, :string
      add :shipping_city, :string
      add :shipping_state, :string
      add :shipping_zip, :string
      add :shipping_country, :string, default: "US"
      # Financials (cents)
      add :subtotal, :integer
      add :shipping_cost, :integer
      add :tax, :integer, default: 0
      add :total, :integer
      # Stripe
      add :stripe_session_id, :string
      add :stripe_payment_intent_id, :string
      add :shipping_method, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:orders, [:order_number])
    create index(:orders, [:email])
    create index(:orders, [:status])
    create index(:orders, [:stripe_session_id])

    # Order items
    create table(:order_items) do
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :variant_id, references(:product_variants), null: false
      add :fulfillment_type, :string
      add :product_name, :string
      add :variant_name, :string
      add :sku, :string
      add :quantity, :integer
      add :unit_price, :integer
      add :line_total, :integer
      add :status, :string, default: "pending"
      add :printful_order_id, :integer
      add :tracking_number, :string
      add :tracking_url, :string

      timestamps(type: :utc_datetime)
    end

    create index(:order_items, [:order_id])
    create index(:order_items, [:variant_id])
    create index(:order_items, [:status])
  end
end
