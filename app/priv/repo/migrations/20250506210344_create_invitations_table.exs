defmodule App.Repo.Migrations.CreateInvitationsTable do
  use Ecto.Migration

  def change do
    create table(:invitations) do
      add :events, {:array, :string}, default: []

      timestamps(type: :utc_datetime)
    end

    alter table(:guests) do
      add :invitation_id, references(:invitations, on_delete: :nothing)
    end

    create index(:guests, [:invitation_id])
  end
end
