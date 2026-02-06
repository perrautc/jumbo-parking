defmodule JumboParking.Parking.PricingPlan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pricing_plans" do
    field :vehicle_type, :string
    field :vehicle_name, :string
    field :description, :string
    field :icon, :string, default: "default"
    field :price_daily, :integer
    field :price_weekly, :integer
    field :price_monthly, :integer
    field :price_yearly, :integer
    field :savings, :map, default: %{}
    field :features, {:array, :string}, default: []

    timestamps(type: :utc_datetime)
  end

  @icons ~w(truck truck-emoji rv rv-emoji car car-emoji warehouse forklift container trailer)

  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:vehicle_type, :vehicle_name, :description, :icon, :price_daily, :price_weekly, :price_monthly, :price_yearly, :savings, :features])
    |> validate_required([:vehicle_type, :vehicle_name, :price_monthly, :price_yearly])
    |> validate_inclusion(:icon, @icons)
    |> unique_constraint(:vehicle_type)
  end

  def available_icons, do: @icons
end
