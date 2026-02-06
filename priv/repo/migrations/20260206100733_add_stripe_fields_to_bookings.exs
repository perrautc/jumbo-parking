defmodule JumboParking.Repo.Migrations.AddStripeFieldsToBookings do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      add :stripe_session_id, :string
      add :stripe_payment_intent_id, :string
    end

    create index(:bookings, [:stripe_session_id])
  end
end
