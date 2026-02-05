defmodule JumboParking.Repo.Migrations.CreateActivityLogs do
  use Ecto.Migration

  def change do
    create table(:activity_logs) do
      add :action, :string, null: false
      add :description, :text, null: false
      add :entity_type, :string
      add :entity_id, :integer

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:activity_logs, [:entity_type, :entity_id])
    create index(:activity_logs, [:inserted_at])
  end
end
