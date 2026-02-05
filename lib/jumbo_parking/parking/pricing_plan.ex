defmodule JumboParking.Parking.PricingPlan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pricing_plans" do
    field :vehicle_type, :string
    field :vehicle_name, :string
    field :description, :string
    field :price_daily, :integer
    field :price_weekly, :integer
    field :price_monthly, :integer
    field :price_yearly, :integer
    field :savings, :map, default: %{}
    field :features, {:array, :string}, default: []

    timestamps(type: :utc_datetime)
  end

  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:vehicle_type, :vehicle_name, :description, :price_daily, :price_weekly, :price_monthly, :price_yearly, :savings, :features])
    |> validate_required([:vehicle_type, :vehicle_name, :price_monthly, :price_yearly])
    |> unique_constraint(:vehicle_type)
  end
end
