defmodule App.Repo.Migrations.AddGuestFields do
  use Ecto.Migration

  def change do
    alter table(:guests) do
      add :email, :string, size: 160
      add :brunch, :boolean, default: false
      add :rehersal_dinner, :boolean, default: false
    end
  end
end
