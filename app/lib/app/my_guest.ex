defmodule App.MyGuest do
  import Ecto.Query, warn: false

  alias App.Accounts.UserNotifier
  alias App.Repo
  alias App.Guest.Guest
  alias App.Guest.RSVP

  def list_guests() do
    Repo.all(Guest) |> Repo.preload(:rsvp)
  end

  def get_guest(email: email) do
    IO.puts(email)
    g = Repo.get_by!(Guest, email: email)
    IO.inspect(g)
    g
  end

  def get_guest(id) do
    Repo.get(Guest, id) |> Repo.preload(:rsvp)
  end

  def get_guest!(id) do
    Repo.get!(Guest, id) |> Repo.preload(:rsvp)
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
end
