defmodule AppWeb.PageController do
  use AppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def story(conn, _params) do
    render(conn, :story)
  end

  def photos(conn, _params) do
    render(conn, :photos)
  end

  def registry(conn, _params) do
    render(conn, :registry)
  end

  def rsvp(conn, _params) do
    render(conn, :rsvp)
  end

  def travel(conn, _params) do
    render(conn, :travel)
  end

  def things_to_do(conn, _params) do
    render(conn, :things_to_do)
  end
end
