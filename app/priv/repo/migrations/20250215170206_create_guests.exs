defmodule App.Repo.Migrations.CreateGuests do
  use Ecto.Migration

  def change do
    create table(:guests) do
      add :first_name, :string
      add :last_name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
