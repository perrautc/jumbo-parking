defmodule JumboParking.Repo.Migrations.AddLotToSpaces do
  use Ecto.Migration

  def change do
    alter table(:parking_spaces) do
      add :parking_lot_id, references(:parking_lots, on_delete: :restrict)
      add :vehicle_type, :string
      add :section, :string
    end

    create index(:parking_spaces, [:parking_lot_id])
    create index(:parking_spaces, [:vehicle_type])
  end
end
