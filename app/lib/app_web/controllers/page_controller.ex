defmodule AppWeb.PageController do
  alias App.Guest.Invitation
  alias App.Guest
  alias App.MyGuest
  alias App.Guest.Guest
  use AppWeb, :controller

  def home(conn, _params) do
    image =
      Enum.random([
        "italy_rooftop.jpg",
        "shared_sausage.jpg",
        "ski_beard.jpg",
        "swing.jpg",
        "thrones.jpg",
        "boat_party.jpg",
        "gingerbread.jpg"
      ])

    guest = get_guest(conn)

    render(conn, :home, %{
      image: image,
      brunch?: invited_to_brunch(guest),
      rehearsal?: invited_to_rehearsal(guest)
    })
  end

  def std(conn, _params) do
    render(conn, :std, %{page_title: "Save the Date"})
  end

  def robey(conn, _params) do
    get_guest(conn)
    |> can_book_robey()
    |> case do
      true -> render(conn, :robey)
      false -> redirect(conn, to: ~p"/travel#robey")
    end
  end

  def story(conn, _params) do
    render(conn, :story)
  end

  def photos(conn, _params) do
    render(conn, :photos)
  end

  def travel(conn, _params) do
    guest = get_guest(conn)

    render(conn, :travel,
      can_book_robey: can_book_robey(guest),
      rehearsal?: invited_to_rehearsal(guest)
    )
  end

  def things_to_do(conn, _params) do
    render(conn, :things_to_do, guest: get_guest(conn))
  end

  def schedule(conn, _params) do
    guest = get_guest(conn)

    render(conn, :schedule,
      guest: guest,
      can_book_robey: can_book_robey(guest),
      brunch?: invited_to_brunch(guest),
      rehearsal?: invited_to_rehearsal(guest)
    )
  end

  defp get_guest(conn) do
    get_guest_id(conn)
    |> case do
      nil -> nil
      guest_id -> MyGuest.get_guest(guest_id, preload: :invitation)
    end
  end

  defp can_book_robey(guest) do
    guest != nil and guest.invitation != nil and guest.invitation.robey
  end

  defp invited_to_rehearsal(%Guest{invitation: %Invitation{events: events}}) do
    Enum.member?(events, :rehersal)
  end

  defp invited_to_rehearsal(_), do: false

  defp invited_to_brunch(%Guest{invitation: %Invitation{events: events}}) do
    Enum.member?(events, :brunch)
  end

  defp invited_to_brunch(_guest), do: false
end
