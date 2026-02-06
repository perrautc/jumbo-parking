defmodule JumboParking.Repo.Migrations.CreateMerchAndSettings do
  use Ecto.Migration

  def change do
    # Site settings table for toggles and config
    create table(:site_settings) do
      add :key, :string, null: false
      add :value, :text
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:site_settings, [:key])

    # Merch items table
    create table(:merch_items) do
      add :name, :string, null: false
      add :description, :text
      add :price, :integer, null: false  # in cents
      add :image_url, :string
      add :badge, :string  # "popular", "new", "sale", or null
      add :external_url, :string  # link to POD provider
      add :sku, :string  # for POD integration
      add :active, :boolean, default: true
      add :sort_order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:merch_items, [:active])
    create index(:merch_items, [:sort_order])

    # Seed default settings
    execute(
      """
      INSERT INTO site_settings (key, value, description, inserted_at, updated_at)
      VALUES
        ('merch_store_enabled', 'true', 'Toggle merch store visibility on homepage', NOW(), NOW()),
        ('merch_store_title', 'Rep the Brand', 'Title for merch section', NOW(), NOW()),
        ('merch_store_subtitle', 'Show your Jumbo pride with our exclusive merchandise', 'Subtitle for merch section', NOW(), NOW())
      """,
      """
      DELETE FROM site_settings WHERE key IN ('merch_store_enabled', 'merch_store_title', 'merch_store_subtitle')
      """
    )

    # Seed initial merch items (migrating from hardcoded data)
    execute(
      """
      INSERT INTO merch_items (name, description, price, image_url, badge, active, sort_order, inserted_at, updated_at)
      VALUES
        ('Classic Logo Tee', 'Premium cotton t-shirt with embroidered Jumbo logo', 2999, '/images/merch-tshirt.png', 'popular', true, 1, NOW(), NOW()),
        ('Snapback Hat', 'Adjustable snapback with iconic Jumbo branding', 2499, '/images/merch-hat.png', NULL, true, 2, NOW(), NOW()),
        ('Coffee Mug', 'Start your day right with our 12oz ceramic mug', 1499, '/images/merch-mug.png', NULL, true, 3, NOW(), NOW()),
        ('Executive Pen', 'Premium metal pen for the professional trucker', 999, '/images/merch-pen.png', NULL, true, 4, NOW(), NOW()),
        ('Vehicle Decal', 'Weather-resistant vinyl decal for your rig', 799, '/images/merch-decal.png', 'new', true, 5, NOW(), NOW()),
        ('Bumper Sticker Pack', 'Set of 3 high-quality bumper stickers', 599, '/images/merch-decal.png', NULL, true, 6, NOW(), NOW())
      """,
      """
      DELETE FROM merch_items WHERE name IN ('Classic Logo Tee', 'Snapback Hat', 'Coffee Mug', 'Executive Pen', 'Vehicle Decal', 'Bumper Sticker Pack')
      """
    )
  end
end
