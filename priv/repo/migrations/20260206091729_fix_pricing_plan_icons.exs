defmodule JumboParking.Repo.Migrations.FixPricingPlanIcons do
  use Ecto.Migration

  def change do
    # Update any rows with "default" icon to use their vehicle type as the icon
    execute(
      "UPDATE pricing_plans SET icon = vehicle_type WHERE icon = 'default' OR icon IS NULL",
      "SELECT 1"
    )

    # Change the default value for new rows
    alter table(:pricing_plans) do
      modify :icon, :string, default: "truck"
    end
  end
end
