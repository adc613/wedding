defmodule App.Repo.Migrations.RsvpEventsRepeated do
  use Ecto.Migration

  def change do
    alter table(:rsvps) do
      remove :event
      add :events, {:array, :string}, default: []
      add :declined_events, {:array, :string}, default: []
    end
  end
end
