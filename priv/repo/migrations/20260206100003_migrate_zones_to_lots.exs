defmodule JumboParking.Repo.Migrations.MigrateZonesToLots do
  use Ecto.Migration

  def up do
    # Create default lot
    execute """
    INSERT INTO parking_lots (name, city, state, description, active, inserted_at, updated_at)
    VALUES ('Main Lot', 'Columbia', 'SC', 'Main parking facility', true, NOW(), NOW())
    """

    # Get the lot id
    execute """
    UPDATE parking_spaces
    SET parking_lot_id = (SELECT id FROM parking_lots WHERE name = 'Main Lot' LIMIT 1)
    """

    # Migrate zone data to vehicle_type and section
    # Zone A - Trucks -> vehicle_type: truck, section: Section A
    execute """
    UPDATE parking_spaces
    SET vehicle_type = 'truck', section = 'Section A'
    WHERE zone = 'Zone A - Trucks'
    """

    # Zone B - RVs -> vehicle_type: rv, section: Section B
    execute """
    UPDATE parking_spaces
    SET vehicle_type = 'rv', section = 'Section B'
    WHERE zone = 'Zone B - RVs'
    """

    # Zone C - Cars -> vehicle_type: car, section: Section C
    execute """
    UPDATE parking_spaces
    SET vehicle_type = 'car', section = 'Section C'
    WHERE zone = 'Zone C - Cars'
    """

    # Make parking_lot_id required and vehicle_type required
    alter table(:parking_spaces) do
      modify :parking_lot_id, :bigint, null: false
      modify :vehicle_type, :string, null: false
    end

    # Drop zone column
    alter table(:parking_spaces) do
      remove :zone
    end
  end

  def down do
    # Add zone column back
    alter table(:parking_spaces) do
      add :zone, :string
    end

    # Restore zone data from vehicle_type and section
    execute """
    UPDATE parking_spaces
    SET zone = 'Zone A - Trucks'
    WHERE vehicle_type = 'truck'
    """

    execute """
    UPDATE parking_spaces
    SET zone = 'Zone B - RVs'
    WHERE vehicle_type = 'rv'
    """

    execute """
    UPDATE parking_spaces
    SET zone = 'Zone C - Cars'
    WHERE vehicle_type = 'car'
    """

    # Make parking_lot_id nullable
    alter table(:parking_spaces) do
      modify :parking_lot_id, :bigint, null: true
      modify :vehicle_type, :string, null: true
    end

    # Clear parking_lot_id
    execute "UPDATE parking_spaces SET parking_lot_id = NULL"

    # Delete default lot
    execute "DELETE FROM parking_lots WHERE name = 'Main Lot'"
  end
end
