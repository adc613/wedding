defmodule App.Repo.Migrations.CreateRsvps do
  use Ecto.Migration

  def change do
    create table(:rsvps) do
      add :confirmed, :boolean, default: false, null: false
      add :guest_id, references(:guests, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:rsvps, [:guest_id])
  end
end
