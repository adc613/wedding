defmodule App.Repo.Migrations.AdjustRsvpFields do
  use Ecto.Migration

  def change do
    alter table(:rsvps) do
      remove :confirmed
      add :attending, :string
      add :event, :string
    end
  end
end
