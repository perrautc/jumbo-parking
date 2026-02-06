defmodule JumboParking.Repo.Migrations.AddIconToPricingPlans do
  use Ecto.Migration

  def change do
    alter table(:pricing_plans) do
      add :icon, :string, default: "default"
    end
  end
end
