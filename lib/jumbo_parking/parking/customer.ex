defmodule JumboParking.Parking.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customers" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone, :string
    field :company, :string
    field :vehicle_plate, :string
    field :vehicle_model, :string
    field :vehicle_type, :string
    field :plan, :string
    field :status, :string, default: "active"
    field :notes, :string

    has_many :bookings, JumboParking.Parking.Booking
    has_one :parking_space, JumboParking.Parking.ParkingSpace

    timestamps(type: :utc_datetime)
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:first_name, :last_name, :email, :phone, :company, :vehicle_plate, :vehicle_model, :vehicle_type, :plan, :status, :notes])
    |> validate_required([:first_name, :last_name, :email, :vehicle_type, :plan])
    |> validate_inclusion(:vehicle_type, ~w(truck rv car))
    |> validate_inclusion(:plan, ~w(daily weekly monthly yearly))
    |> validate_inclusion(:status, ~w(active pending inactive))
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/)
    |> unique_constraint(:email)
  end

  def full_name(%__MODULE__{first_name: first, last_name: last}), do: "#{first} #{last}"

  def initials(%__MODULE__{first_name: first, last_name: last}) do
    "#{String.first(first || "")}#{String.first(last || "")}"
  end
end
