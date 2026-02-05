defmodule JumboParking.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :citext, null: false
      add :phone, :string
      add :company, :string
      add :vehicle_plate, :string
      add :vehicle_model, :string
      add :vehicle_type, :string, null: false
      add :plan, :string, null: false
      add :status, :string, null: false, default: "active"
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:customers, [:email])
  end
end
