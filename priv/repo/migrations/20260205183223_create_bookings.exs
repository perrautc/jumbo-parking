defmodule JumboParking.Repo.Migrations.CreateBookings do
  use Ecto.Migration

  def change do
    create table(:bookings) do
      add :start_date, :date, null: false
      add :end_date, :date
      add :status, :string, null: false, default: "pending"
      add :total_amount, :integer, null: false
      add :customer_id, references(:customers, on_delete: :delete_all), null: false
      add :space_id, references(:parking_spaces, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:bookings, [:customer_id])
    create index(:bookings, [:space_id])
  end
end
