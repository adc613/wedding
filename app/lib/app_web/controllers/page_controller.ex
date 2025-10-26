defmodule AppWeb.PageController do
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

    render(conn, :home, %{image: image})
  end

  def std(conn, _params) do
    render(conn, :std, %{page_title: "Save the Date"})
  end

  def robey(conn, _params) do
    can_book_robey(conn)
    |> case do
      true -> render(conn, :robey)
      false -> redirect(conn, to: ~p"/travel")
    end
  end

  def story(conn, _params) do
    render(conn, :story)
  end

  def photos(conn, _params) do
    render(conn, :photos)
  end

  def travel(conn, _params) do
    render(conn, :travel, can_book_robey: can_book_robey(conn))
  end

  def things_to_do(conn, _params) do
    render(conn, :things_to_do, can_book_robey: can_book_robey(conn))
  end

  def schedule(conn, _params) do
    render(conn, :schedule)
  end

  defp can_book_robey(conn) do
    get_guest_id(conn)
    |> case do
      nil -> nil
      id -> MyGuest.get_guest(id, preload: :invitation)
    end
    |> case do
      %Guest{} = guest -> guest.invitation.robey
      _ -> false
    end
  end
end
