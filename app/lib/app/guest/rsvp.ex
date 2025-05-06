defmodule App.Guest.RSVP do
  use Ecto.Schema
  import Ecto.Changeset
  alias App.Guest.Guest

  schema "rsvps" do
    field :attending, Ecto.Enum, values: [:unkown, :yes, :no]
    field :event, Ecto.Enum, values: [:wedding_day, :rehersal_dinner]
    belongs_to :guest, Guest

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rsvp, attrs \\ %{}) do
    rsvp
    |> cast(attrs, [:attending, :event, :guest_id])
    |> validate_required([:attending, :event, :guest_id])
    |> assoc_constraint(:guest)
  end
end
