defmodule App.Questions.Question do
  use Ecto.Schema
  import Ecto.Changeset
  alias App.Guest.Guest

  schema "questions" do
    field :question, :string
    field :answer, :string, default: ""
    field :upvotes, :integer, default: 0

    belongs_to :guest, Guest

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(question, attrs \\ %{}) do
    question
    |> cast(attrs, [:question, :answer, :upvotes, :guest_id])
    |> validate_required([:guest_id, :question])
    |> assoc_constraint(:guest)
  end
end
