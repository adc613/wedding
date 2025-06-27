defmodule App.Repo.Migrations.PhoneNumber do
  use Ecto.Migration

  def change do
    rename table(:guests), :phone, to: :phone_legacy

    alter table(:guests) do
      add :country_code, :integer, default: 0
      add :phone_number, :integer, default: 0
    end
  end
end
