defmodule App.Guest.Guest do
  use Ecto.Schema
  import Ecto.Changeset
  alias App.Guest.RSVP
  alias App.Guest.Invitation

  schema "guests" do
    field :first_name, :string
    field :last_name, :string
    # Important to note this is not a password, and should not be used for anything
    # that needs to be remotely secure. It's only to prevent users from making
    # uninteional changes
    field :secret, :string
    field :rehersal_dinner, :boolean, default: false
    field :brunch, :boolean, default: false
    field :sent_std, :boolean, default: false
    field :email, :string
    has_one :rsvp, RSVP
    belongs_to :invitation, Invitation, on_replace: :update

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(guest, attrs \\ %{}) do
    guest
    |> cast(attrs, [
      :first_name,
      :last_name,
      :secret,
      :brunch,
      :rehersal_dinner,
      :email,
      :sent_std,
      :invitation_id
    ])
    |> cast_assoc(:invitation, with: &Invitation.changeset/2)
    |> validate_email()
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 3)
    |> validate_length(:last_name, min: 3)
    |> assoc_constraint(:invitation)
  end

  # def changeset_assoc(guest, attrs \\ %{}) do
  # guest
  # end

  @doc """
  Returns a changeset for doing a %Guest{} lookup in the database. Not meant
  to be used for DB write actions.
  """
  @spec lookup_changeset(map()) :: %Ecto.Changeset{}
  def lookup_changeset(guest, attrs \\ %{}) do
    guest
    |> cast(attrs, [:email])
    |> validate_email()
  end

  def apply_lookup(guest, attrs \\ %{}) do
    lookup_changeset(guest, attrs)
    |> apply_action(:validate_attrs)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  def gen_secret() do
    Enum.random(100_000..999_999)
    |> Integer.to_string()
  end
end
