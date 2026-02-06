defmodule JumboParking.Parking.ParkingSpace do
  use Ecto.Schema
  import Ecto.Changeset

  schema "parking_spaces" do
    field :number, :string
    field :vehicle_type, :string
    field :section, :string
    field :status, :string, default: "available"
    field :reserved_from, :date
    field :reserved_until, :date

    belongs_to :parking_lot, JumboParking.Parking.ParkingLot
    belongs_to :customer, JumboParking.Parking.Customer

    timestamps(type: :utc_datetime)
  end

  def changeset(space, attrs) do
    space
    |> cast(attrs, [:number, :parking_lot_id, :vehicle_type, :section, :status, :customer_id, :reserved_from, :reserved_until])
    |> validate_required([:number, :parking_lot_id, :vehicle_type, :status])
    |> validate_inclusion(:status, ~w(available occupied reserved maintenance))
    |> validate_inclusion(:vehicle_type, ~w(truck rv car))
    |> foreign_key_constraint(:parking_lot_id)
    |> unique_constraint(:number)
  end
end
