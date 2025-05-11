defmodule App.Guest.RSVP do
  use Ecto.Schema
  import Ecto.Changeset
  alias App.Guest.Guest

  schema "rsvps" do
    field :events, {:array, Ecto.Enum}, values: [:wedding, :brunch, :rehersal], default: []

    field :declined_events, {:array, Ecto.Enum},
      values: [:wedding, :brunch, :rehersal],
      default: []

    belongs_to :guest, Guest

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rsvp, attrs \\ %{}) do
    rsvp
    |> cast(attrs, [:events, :declined_events, :guest_id])
    |> validate_required([:guest_id])
    |> assoc_constraint(:guest)
  end
end
