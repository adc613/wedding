defmodule App.Repo.Migrations.AddGuestStd do
  use Ecto.Migration

  def change do
    alter table(:guests) do
      add :sent_std, :boolean, default: false
    end
  end
end
