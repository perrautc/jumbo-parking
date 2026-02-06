defmodule JumboParking.Parking.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookings" do
    field :start_date, :date
    field :end_date, :date
    field :status, :string, default: "pending"
    field :total_amount, :integer
    field :stripe_session_id, :string
    field :stripe_payment_intent_id, :string

    belongs_to :customer, JumboParking.Parking.Customer
    belongs_to :space, JumboParking.Parking.ParkingSpace

    timestamps(type: :utc_datetime)
  end

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [:start_date, :end_date, :status, :total_amount, :customer_id, :space_id, :stripe_session_id, :stripe_payment_intent_id])
    |> validate_required([:start_date, :status, :total_amount, :customer_id])
    |> validate_inclusion(:status, ~w(pending confirmed active completed cancelled))
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:space_id)
  end
end
