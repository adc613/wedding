defmodule App.MyGuest do
  import Ecto.Query, warn: false

  alias App.Repo
  alias App.Guest.Guest
  alias App.Guest.RSVP

  def list_guests() do
    Repo.all(Guest) |> Repo.preload(:rsvp)
  end

  def get_guest(id) do
    Repo.get(Guest, id) |> Repo.preload(:rsvp)
  end

  def get_guest!(id) do
    Repo.get!(Guest, id) |> Repo.preload(:rsvp)
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

  def delete(%Guest{} = guest) do
    Repo.delete(guest)
  end

  def create_guest(attrs \\ %{}) do
    %Guest{}
    |> Guest.changeset(attrs)
    |> Repo.insert()
  end

  def get_or_create_rsvp!(guest_id) do
    guest = get_guest!(guest_id)

    case guest.rsvp do
      nil = _assoc -> create_rsvp(guest)
      _ -> guest.rsvp
    end
  end

  defp create_rsvp(%Guest{} = guest) do
    %RSVP{}
    |> RSVP.changeset(%{"guest_id" => guest.id})
    |> Repo.insert!()
  end
end
