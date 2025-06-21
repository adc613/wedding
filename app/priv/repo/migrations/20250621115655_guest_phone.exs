defmodule App.Repo.Migrations.GuestPhone do
  use Ecto.Migration

  def change do
    alter table(:guests) do
      add :phone, :string, default: ""
    end
  end
end
