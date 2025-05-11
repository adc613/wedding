defmodule App.Guest.Invitation do
  use Ecto.Schema
  import Ecto.Changeset
  alias App.Guest.Guest

  schema "invitations" do
    field :events, {:array, Ecto.Enum}, values: [:wedding, :brunch, :rehersal]
    has_many :guests, Guest

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invitation, attrs \\ %{}) do
    invitation
    |> cast(attrs, [:events])
    |> validate_required([:events])
  end
end
