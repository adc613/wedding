defmodule App.Questions.Vote do
  use Ecto.Schema
  import Ecto.Changeset
  alias App.Guest.Guest
  alias App.Questions.Question

  schema "votes" do
    belongs_to :guest, Guest
    belongs_to :question, Question

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vote, attrs \\ %{}) do
    vote
    |> cast(attrs, [:question_id, :guest_id])
    |> validate_required([:guest_id, :question_id])
    |> assoc_constraint(:guest)
    |> assoc_constraint(:question)
  end
end
