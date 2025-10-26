defmodule App.Repo.Migrations.Robey do
  use Ecto.Migration

  def change do
    alter table(:invitations) do
      add :robey, :boolean, default: false
    end
  end
end
