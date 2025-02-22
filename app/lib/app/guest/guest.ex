defmodule App.Guest.Guest do
  use Ecto.Schema
  import Ecto.Changeset
  alias App.Guest.RSVP

  schema "guests" do
    field :first_name, :string
    field :last_name, :string
    # Important to note this is not a password, and should not be used for anything
    # that needs to be remotely secure. It's only to prevent users from making
    # uninteional changes
    field :secret, :string
    has_one :rsvp, RSVP

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(guest, attrs \\ %{}) do
    guest
    |> cast(attrs, [:first_name, :last_name, :secret])
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 3)
    |> validate_length(:last_name, min: 3)
  end

  def gen_secret() do
    Enum.random(100_000..999_999)
    |> Integer.to_string()
  end
end
