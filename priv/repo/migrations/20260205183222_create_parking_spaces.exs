defmodule JumboParking.Repo.Migrations.CreateParkingSpaces do
  use Ecto.Migration

  def change do
    create table(:parking_spaces) do
      add :number, :string, null: false
      add :zone, :string, null: false
      add :status, :string, null: false, default: "available"
      add :customer_id, references(:customers, on_delete: :nilify_all)
      add :reserved_from, :date
      add :reserved_until, :date

      timestamps(type: :utc_datetime)
    end

    create unique_index(:parking_spaces, [:number])
    create index(:parking_spaces, [:customer_id])
    create index(:parking_spaces, [:zone])
    create index(:parking_spaces, [:status])
  end
end
