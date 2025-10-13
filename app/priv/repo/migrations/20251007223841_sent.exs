defmodule App.Repo.Migrations.Sent do
  use Ecto.Migration

  def change do
    alter table(:invitations) do
      add :sent, :boolean, default: false
    end
  end
end
