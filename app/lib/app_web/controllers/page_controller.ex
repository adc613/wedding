defmodule AppWeb.PageController do
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

  def story(conn, _params) do
    render(conn, :story)
  end

  def photos(conn, _params) do
    render(conn, :photos)
  end

  def travel(conn, _params) do
    render(conn, :travel)
  end

  def things_to_do(conn, _params) do
    render(conn, :things_to_do)
  end
end
