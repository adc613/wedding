defmodule AppWeb.MyHomeController do 
  use AppWeb, :controller

  alias App.MyGuest

  def index(conn, _params) do
    guests = MyGuest.list_guests();
    render(conn, :index, guests: guests)
  end

  def detail(conn, %{"id" => id}) do
    guest = MyGuest.get_guest!(id)
    render(conn, :detail, guest: guest)
  end
end
