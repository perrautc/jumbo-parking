defmodule JumboParking.Parking.ActivityLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "activity_logs" do
    field :action, :string
    field :description, :string
    field :entity_type, :string
    field :entity_id, :integer

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:action, :description, :entity_type, :entity_id])
    |> validate_required([:action, :description])
  end
end
