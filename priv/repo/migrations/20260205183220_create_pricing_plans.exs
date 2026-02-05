defmodule JumboParking.Repo.Migrations.CreatePricingPlans do
  use Ecto.Migration

  def change do
    create table(:pricing_plans) do
      add :vehicle_type, :string, null: false
      add :vehicle_name, :string, null: false
      add :description, :text
      add :price_daily, :integer
      add :price_weekly, :integer
      add :price_monthly, :integer, null: false
      add :price_yearly, :integer, null: false
      add :savings, :map, default: %{}
      add :features, {:array, :string}, default: []

      timestamps(type: :utc_datetime)
    end

    create unique_index(:pricing_plans, [:vehicle_type])
  end
end
