defmodule App.Guest.Invitation do
  use Ecto.Schema
  import Ecto.Changeset
  alias App.Guest.RSVP
  alias App.Guest.Invitation
  alias App.Guest.Guest

  schema "invitations" do
    field :events, {:array, Ecto.Enum}, values: [:wedding, :brunch, :rehersal]
    has_many :guests, Guest
    field :additional_guests, :integer
    field :permit_kids, :boolean
    field :dietary_restrictions, :string
    field :sent, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invitation, attrs \\ %{}) do
    invitation
    |> cast(attrs, [:events, :additional_guests, :permit_kids, :dietary_restrictions, :sent])
    |> validate_required([:events])
  end

  def num_of_people(%Invitation{} = invitation) do
    length(invitation.guests) + invitation.additional_guests
  end

  def count_invites(%Invitation{events: events} = invitation) do
    total = num_of_people(invitation)

    wedding =
      if :wedding in events do
        1
      else
        0
      end

    brunch =
      if :brunch in events do
        1
      else
        0
      end

    rehersal =
      if :rehersal in events do
        1
      else
        0
      end

    %{
      total: total,
      wedding: total * wedding,
      brunch: total * brunch,
      rehersal: total * rehersal
    }
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

  def add_form_attrs(invitation) do
    Enum.reduce(invitation.events, invitation, fn event, invitation ->
      Map.put(invitation, event, true)
    end)
  end

  def cast_form_attrs(attrs) do
    events =
      [
        "brunch",
        "rehersal",
        "wedding"
      ]
      |> Enum.filter(&(attrs[&1] == "true"))

    Map.put(attrs, "events", events)
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
