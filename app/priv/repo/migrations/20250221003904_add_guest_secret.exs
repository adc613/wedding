defmodule App.Repo.Migrations.AddGuestSecret do
  use Ecto.Migration

  def change do
    alter table(:guests) do
      add :secret, :string, size: 6
    end
  end
end
