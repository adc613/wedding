defmodule App.Guest.Invitation do
  use Ecto.Schema
  import Ecto.Changeset
  alias App.Guest.RSVP
  alias App.Guest.Invitation
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

  def num_of_people(%Invitation{} = invitation) do
    length(invitation.guests)
  end

  def count_rsvps(%Invitation{} = invitation) do
    Enum.reduce(invitation.guests, {0, 0, 0}, fn guest, {wedding, brunch, rehersal} ->
      case guest.rsvp do
        %RSVP{events: events} ->
          {w, b, r} = count_events(events)
          {wedding + w, brunch + b, rehersal + r}

        _ ->
          {wedding, brunch, rehersal}
      end
    end)
    |> then(fn {wedding, brunch, rehersal} ->
      %{
        total: num_of_people(invitation),
        wedding: wedding,
        brunch: brunch,
        rehersal: rehersal
      }
    end)
  end

  defp count_events(events) do
    Enum.reduce(events, {0, 0, 0}, fn event, {wedding, brunch, rehersal} ->
      case event do
        :wedding -> {wedding + 1, brunch, rehersal}
        :brunch -> {wedding, brunch + 1, rehersal}
        :rehersal -> {wedding, brunch, rehersal + 1}
      end
    end)
  end
end
