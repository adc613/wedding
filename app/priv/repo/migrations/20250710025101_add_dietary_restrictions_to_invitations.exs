defmodule App.Repo.Migrations.AddDietaryRestrictionsToInvitations do
  use Ecto.Migration

  def change do
    alter table(:invitations) do
      add :dietary_restrictions, :text
    end
  end
end
