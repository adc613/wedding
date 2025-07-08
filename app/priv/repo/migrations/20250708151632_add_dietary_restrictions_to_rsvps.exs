defmodule App.Repo.Migrations.AddDietaryRestrictionsToRsvps do
  use Ecto.Migration

  def change do
    alter table(:rsvps) do
      add :dietary_restrictions, :text
    end
  end
end
