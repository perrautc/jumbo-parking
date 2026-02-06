defmodule JumboParking.Repo.Migrations.CreateParkingLots do
  use Ecto.Migration

  def change do
    create table(:parking_lots) do
      add :name, :string, null: false
      add :street, :string
      add :city, :string, null: false
      add :state, :string, size: 2, null: false
      add :zip, :string
      add :description, :text
      add :capacity, :integer
      add :active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:parking_lots, [:name])
  end
end
