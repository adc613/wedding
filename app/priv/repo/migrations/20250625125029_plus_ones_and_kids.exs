defmodule App.Repo.Migrations.PlusOnesAndKids do
  use Ecto.Migration

  def change do
    alter table(:invitations) do
      add :additional_guests, :integer, default: 0
      add :permit_kids, :boolean, default: false
    end

    alter table(:guests) do
      add :is_kid, :boolean, default: false
    end
  end
end
