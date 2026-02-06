defmodule JumboParking.Parking.SiteSetting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "site_settings" do
    field :key, :string
    field :value, :string
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(site_setting, attrs) do
    site_setting
    |> cast(attrs, [:key, :value, :description])
    |> validate_required([:key, :value])
    |> unique_constraint(:key)
  end

  # Default settings with their default values
  @defaults %{
    "merch_store_enabled" => "true",
    "merch_store_title" => "Rep the Brand",
    "merch_store_subtitle" => "Show your Jumbo pride with our exclusive merchandise"
  }

  def defaults, do: @defaults

  def default_value(key) do
    Map.get(@defaults, key)
  end
end
