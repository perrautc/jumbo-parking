defmodule JumboParking.Parking.VehicleType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vehicle_types" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :icon, :string, default: "truck"

    # Dimensions in feet
    field :length_ft, :decimal
    field :width_ft, :decimal
    field :height_ft, :decimal

    # Min/max dimensions for this category (for space matching)
    field :min_length_ft, :decimal
    field :max_length_ft, :decimal
    field :min_width_ft, :decimal
    field :max_width_ft, :decimal

    field :active, :boolean, default: true
    field :sort_order, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def changeset(vehicle_type, attrs) do
    vehicle_type
    |> cast(attrs, [
      :name, :slug, :description, :icon,
      :length_ft, :width_ft, :height_ft,
      :min_length_ft, :max_length_ft, :min_width_ft, :max_width_ft,
      :active, :sort_order
    ])
    |> validate_required([:name, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "must be lowercase letters, numbers, and hyphens only")
    |> unique_constraint(:slug)
    |> validate_number(:length_ft, greater_than: 0)
    |> validate_number(:width_ft, greater_than: 0)
    |> validate_number(:height_ft, greater_than: 0)
    |> validate_number(:min_length_ft, greater_than_or_equal_to: 0)
    |> validate_number(:max_length_ft, greater_than: 0)
    |> validate_number(:min_width_ft, greater_than_or_equal_to: 0)
    |> validate_number(:max_width_ft, greater_than: 0)
  end
end
