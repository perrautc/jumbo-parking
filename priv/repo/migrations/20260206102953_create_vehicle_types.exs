defmodule JumboParking.Repo.Migrations.CreateVehicleTypes do
  use Ecto.Migration

  def change do
    create table(:vehicle_types) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :icon, :string, default: "truck"

      # Typical dimensions for this vehicle type (in feet)
      add :length_ft, :decimal, precision: 6, scale: 2
      add :width_ft, :decimal, precision: 6, scale: 2
      add :height_ft, :decimal, precision: 6, scale: 2

      # Min/max dimensions for matching spaces
      add :min_length_ft, :decimal, precision: 6, scale: 2
      add :max_length_ft, :decimal, precision: 6, scale: 2
      add :min_width_ft, :decimal, precision: 6, scale: 2
      add :max_width_ft, :decimal, precision: 6, scale: 2

      add :active, :boolean, default: true, null: false
      add :sort_order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:vehicle_types, [:slug])
    create index(:vehicle_types, [:active])

    # Seed the default vehicle types
    flush()

    execute """
    INSERT INTO vehicle_types (name, slug, description, icon, length_ft, width_ft, height_ft, min_length_ft, max_length_ft, min_width_ft, max_width_ft, active, sort_order, inserted_at, updated_at)
    VALUES
      ('Truck & Trailer', 'truck', 'Semi-trucks, 18-wheelers, and truck-trailer combinations', 'truck', 75.0, 8.5, 13.5, 40.0, 80.0, 8.0, 10.0, true, 1, NOW(), NOW()),
      ('RV', 'rv', 'Recreational vehicles, motorhomes, and campers', 'rv', 35.0, 8.5, 12.0, 20.0, 45.0, 7.0, 9.0, true, 2, NOW(), NOW()),
      ('Car or SUV', 'car', 'Standard passenger vehicles, SUVs, and pickup trucks', 'car', 18.0, 7.0, 6.0, 12.0, 22.0, 5.5, 8.0, true, 3, NOW(), NOW())
    """
  end
end
