defmodule App.MyGuest do
  import Ecto.Query, warn: false

  alias App.Guest.Invitation
  alias App.Accounts.UserNotifier
  alias App.Repo
  alias App.Guest.Guest
  alias App.Guest.RSVP

  def load(structs, preloads \\ []) do
    apply_preloads(structs, preloads)
  end

  def list_guests() do
    Repo.all(Guest) |> Repo.preload(:rsvp) |> Enum.map(&Guest.add_phone(&1))
  end

  def list_guests(:with_invitations) do
    Repo.all(Guest) |> Repo.preload([:rsvp, :invitation]) |> Enum.map(&Guest.add_phone(&1))
  end

  def get_guest(phone: phone) do
    {country_code, phone_number} = Guest.convert_phone(phone)

    query =
      from g in Guest, where: g.phone_number == ^phone_number and g.country_code == ^country_code

    Repo.all(query)
    |> case do
      [] -> nil
      [guest] -> guest
      _ -> :many_matches
    end
  end

  def get_guest(email: email) do
    email = String.trim(email)
    query = from g in Guest, where: g.email == ^email

    Repo.all(query)
    |> case do
      [] -> nil
      [guest] -> guest
      _ -> :many_matches
    end
  end

  def get_guest(id, keywords \\ []) do
    Repo.get(Guest, id)
    |> apply_preloads(keywords)
    |> then(&Guest.add_phone(&1))
  end

  def get_guest!(id, keywords \\ []) do
    Repo.get!(Guest, id)
    |> apply_preloads(keywords)
    |> then(&Guest.add_phone(&1))
  end

  def get_invitation(guest_id: id, preload: :guests) do
    get_guest!(id, preload: :invitation)
    |> then(& &1.invitation)
    |> Repo.preload(guests: :rsvp)
    |> load_phone_str()
  end

  def get_invitation(guest_id: id) do
    get_guest!(id, preload: :invitation)
    |> then(& &1.invitation)
    |> load_phone_str()
  end

  def get_invitation(id, keywords \\ []) do
    Repo.get(Invitation, id)
    |> apply_preloads(keywords)
    |> load_phone_str()
  end

  def get_invitation!(id, keywords \\ []) do
    Repo.get!(Invitation, id)
    |> apply_preloads(keywords)
    |> load_phone_str()
  end

  def update!(%Guest{} = guest, attrs) do
    guest
    |> Guest.changeset(attrs)
    |> Repo.update!()
  end

  def update(%Guest{} = guest, attrs) do
    guest
    |> Guest.changeset(attrs)
    |> Repo.update()
  end

  def update(%RSVP{} = rsvp, attrs) do
    rsvp
    |> RSVP.changeset(attrs)
    |> Repo.update()
  end

  def update(%Invitation{} = invitation, attrs) do
    invitation
    |> Invitation.changeset(attrs)
    |> Repo.update()
  end

  def update_invitation!(id, attrs) when is_binary(id) or is_integer(id) do
    get_invitation!(id)
    |> Invitation.changeset(attrs)
    |> Repo.update!()
  end

  def delete(%Guest{} = guest) do
    Repo.delete(guest)
  end

  def delete(%Invitation{} = invitation) do
    # Note for future self and any observers. This is less than ideal. If any
    # individual update call fails we could get into an undesired state. However,
    # the Adam at the time of writing doesn't care. This website is small and for
    # me and its feasible for me to manually clean the data and resolves issues.
    Repo.preload(invitation, :guests)
    |> then(& &1.guests)
    |> Enum.each(&App.MyGuest.update(&1, %{"invitation_id" => nil}))

    Repo.delete(invitation)
  end

  def create_invitation(attrs, guests: guests) do
    Repo.transaction(fn ->
      invitation =
        %Invitation{}
        |> Invitation.changeset(attrs)
        |> Repo.insert!()

      for guest <- guests do
        guest
        |> Guest.changeset(%{"invitation_id" => invitation.id})
        |> Repo.update!()
      end

      invitation |> load_phone_str()
    end)
  end

  def create_invitation(guests: guests, events: events, kids: kids?, plus_one: plus_one?) do
    Repo.transaction(fn ->
      invitation =
        %Invitation{}
        |> Invitation.changeset(%{
          "events" => events,
          "additional_guests" => cast_plus_one(plus_one?),
          "permit_kids" => kids?
        })
        |> Repo.insert!()

      for guest <- guests do
        guest
        |> Guest.changeset(%{"invitation_id" => invitation.id})
        |> Repo.update!()
      end

      invitation
    end)
  end

  def create_invitation(attrs) do
    create_invitation(attrs, guests: [])
  end

  def list_invitations(keywords \\ []) do
    Repo.all(Invitation)
    |> apply_preloads(keywords)
    |> Enum.map(&load_phone_str(&1))
  end

  def create_guest(attrs, %Invitation{} = invitation) do
    Repo.transaction(fn ->
      invitation = get_invitation(invitation.id)

      guest =
        %Guest{}
        |> Guest.changeset(attrs)
        |> Repo.insert!()

      if not guest.is_kid do
        invitation
        |> Invitation.changeset(%{"additional_guests" => invitation.additional_guests - 1})
        |> Repo.update!()
      end

      guest
    end)
  end

  def create_guest(attrs \\ %{}) do
    %Guest{}
    |> Guest.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, guest} -> {:ok, Guest.add_phone(guest)}
      result -> result
    end
  end

  def update_rsvp!(guest_id, attrs) do
    get_or_create_rsvp!(guest_id)
    |> RSVP.changeset(attrs)
    |> Repo.update!()
  end

  def get_or_create_rsvp!(%Guest{} = guest) do
    guest = Repo.preload(guest, :rsvp)

    case guest.rsvp do
      nil = _assoc -> create_rsvp(guest)
      _ -> guest.rsvp
    end
  end

  def get_or_create_rsvp!(guest_id) do
    get_guest!(guest_id)
    |> get_or_create_rsvp!()
  end

  defp create_rsvp(%Guest{} = guest) do
    %RSVP{}
    |> RSVP.changeset(%{"guest_id" => guest.id, "event" => :wedding})
    |> Repo.insert!()
  end

  def send_std(%{sent_std: true}) do
    {:error, :duplicate_std}
  end

  def send_std(%Guest{} = guest) do
    case UserNotifier.deliver_save_the_date(guest) do
      {:ok, _} ->
        guest
        |> Guest.changeset(%{sent_std: true})
        |> Repo.update()

      _ ->
        {:error, :failed_delivery}
    end
  end

  def mark_sent!(%Guest{} = guest) do
    guest
    |> Guest.changeset(%{sent_std: true})
    |> Repo.update!()
  end

  def mark_sent!(%Invitation{} = invite) do
    invite
    |> IO.inspect()
    |> Invitation.changeset(%{sent: true})
    |> IO.inspect()
    |> Repo.update!()
  end

  def all_rsvp?(nil), do: false

  def all_rsvp?(guests) when is_list(guests) do
    Enum.all?(guests, &(&1.rsvp != nil))
  end

  def all_rsvp?(%Invitation{guests: guests}) do
    all_rsvp?(guests)
  end

  def all_rsvp?(invitaiton_id) do
    get_invitation(invitaiton_id, preload: [guests: :rsvp]) |> all_rsvp?()
  end

  defp apply_preloads(element, keywords) do
    keywords
    |> Enum.map(fn keyword ->
      case keyword do
        {:preload, with} -> with
        _ -> nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
    |> Enum.reduce(element, fn with, element -> Repo.preload(element, with) end)
  end

  defp cast_plus_one(value) do
    case value do
      true -> 1
      false -> 0
    end
  end

  defp load_phone_str(%Invitation{} = invitation) do
    if is_list(invitation.guests) do
      updated_guests = Enum.map(invitation.guests, &Guest.add_phone(&1))
      Map.put(invitation, :guests, updated_guests)
    else
      invitation
    end
  end

  defp load_phone_str(nil), do: nil
end
