defmodule JumboParking.Parking.ParkingLot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "parking_lots" do
    field :name, :string
    field :street, :string
    field :city, :string
    field :state, :string
    field :zip, :string
    field :description, :string
    field :capacity, :integer
    field :active, :boolean, default: true

    has_many :parking_spaces, JumboParking.Parking.ParkingSpace

    timestamps(type: :utc_datetime)
  end

  def changeset(lot, attrs) do
    lot
    |> cast(attrs, [:name, :street, :city, :state, :zip, :description, :capacity, :active])
    |> validate_required([:name, :city, :state])
    |> validate_length(:state, is: 2)
    |> unique_constraint(:name)
  end
end
