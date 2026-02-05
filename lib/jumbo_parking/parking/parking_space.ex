defmodule JumboParking.Parking.ParkingSpace do
  use Ecto.Schema
  import Ecto.Changeset

  schema "parking_spaces" do
    field :number, :string
    field :zone, :string
    field :status, :string, default: "available"
    field :reserved_from, :date
    field :reserved_until, :date

    belongs_to :customer, JumboParking.Parking.Customer

    timestamps(type: :utc_datetime)
  end

  def changeset(space, attrs) do
    space
    |> cast(attrs, [:number, :zone, :status, :customer_id, :reserved_from, :reserved_until])
    |> validate_required([:number, :zone, :status])
    |> validate_inclusion(:status, ~w(available occupied reserved maintenance))
    |> unique_constraint(:number)
  end
end
