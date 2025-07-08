defmodule AppWeb.GuestManageLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.AccountsFixtures
  alias App.MyGuest

  setup do
    user = user_fixture()
    conn = log_in_user(build_conn(), user)

    {:ok, guest} = 
      MyGuest.create_guest(%{
        "email" => "test@test.com",
        "first_name" => "Adam",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    {:ok, conn: conn, guest: guest}
  end

  test "displays dietary restrictions in the guest table", %{conn: conn} do
    guest = MyGuest.get_guest!(1)
    MyGuest.update_rsvp!(guest.id, %{"dietary_restrictions" => "no nuts"})

    {:ok, view, _html} = live(conn, ~p"/admin/guest")

    assert render(view) =~ "no nuts"
  end
end