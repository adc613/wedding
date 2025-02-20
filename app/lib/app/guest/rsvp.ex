defmodule App.Guest.RSVP do
  use Ecto.Schema
  import Ecto.Changeset
  alias App.Guest.Guest

  schema "rsvps" do
    field :confirmed, :boolean, default: false
    belongs_to :guest, Guest

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rsvp, attrs \\ %{}) do
    rsvp
    |> cast(attrs, [:confirmed, :guest_id])
    |> validate_required([:confirmed, :guest_id])
    |> assoc_constraint(:guest)
  end
end
