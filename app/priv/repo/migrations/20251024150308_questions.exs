defmodule App.Repo.Migrations.Questions do
  use Ecto.Migration

  def change do
    create table(:questions) do
      add :question, :string
      add :answer, :string, default: ""
      add :upvotes, :int, default: 0
      add :guest_id, references(:guests, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create table(:votes) do
      add :guest_id, references(:guests, on_delete: :delete_all)
      add :question_id, references(:questions, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:votes, [:guest_id, :question_id])
  end
end
