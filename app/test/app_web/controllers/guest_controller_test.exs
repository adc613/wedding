defmodule AppWeb.GuestControllerTest do
  alias App.Accounts
  alias App.Guest.RSVP
  alias App.MyGuest
  alias AppWeb.UserAuth
  use AppWeb.ConnCase

  setup do
    {:ok, _guest} =
      MyGuest.create_guest(%{
        "first_name" => "Adam",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    {:ok, _user} =
      Accounts.register_user(%{
        "email" => "test@test.com",
        "password" => "password123456789",
        "confirm_password" => "password123456789"
      })

    :ok
  end

  @tag only: true
  test "GET /guest", %{conn: conn} do
    user = Accounts.get_user!(1)
    conn = UserAuth.log_in_user(conn, user, %{"remember_me" => "true"})

    resp =
      conn
      |> get(~p"/guest")
      |> html_response(200)

    assert resp =~ "</html>"
    assert resp =~ "Adam Collins"
  end

  test "GET /guest/:id", %{conn: conn} do
    conn = get(conn, ~p"/guest/1")
    resp = html_response(conn, 200)

    assert resp =~ "</html>"
    assert resp =~ "Adam Collins"
  end

  test "GET /guest/:id 404", %{conn: conn} do
    conn = get(conn, ~p"/guest/42")
    resp = html_response(conn, 404)

    assert resp =~ "Not found"
  end

  test "GET /guest/new", %{conn: conn} do
    conn = get(conn, ~p"/guest/new")
    resp = html_response(conn, 200)

    assert resp =~ "</html>"
    assert resp =~ "Create guest"
  end

  test "POST /guest", %{conn: conn} do
    conn =
      post(conn, ~p"/guest", %{"guest" => %{"first_name" => "Adam 2", "last_name" => "Collins"}})

    resp = html_response(conn, 302)

    assert resp =~ ~p"/guest/2"
    assert MyGuest.get_guest!(2).first_name == "Adam 2"
  end

  test "PUT /guest/:id", %{conn: conn} do
    conn =
      put(conn, ~p"/guest/1", %{"guest" => %{"first_name" => "Adam 2", "last_name" => "Collins"}})

    resp = html_response(conn, 302)

    assert resp =~ ~p"/guest/1"
    assert MyGuest.get_guest!(1).first_name == "Adam 2"
    assert MyGuest.get_guest!(1).last_name == "Collins"
  end

  test "PATCH /guest/:id", %{conn: conn} do
    conn =
      patch(conn, ~p"/guest/1", %{
        "guest" => %{"first_name" => "Adam 2"}
      })

    resp = html_response(conn, 302)

    assert resp =~ ~p"/guest/1"
    assert MyGuest.get_guest!(1).first_name == "Adam 2"
    assert MyGuest.get_guest!(1).last_name == "Collins"
  end

  test "DELETE /guest/:id", %{conn: conn} do
    conn = delete(conn, ~p"/guest/1")

    resp = html_response(conn, 302)

    assert resp =~ ~p"/guest"
    assert MyGuest.list_guests() == []
  end

  test "POST /guest/:guests_id/rsvp", %{conn: conn} do
    conn = post(conn, ~p"/guest/1/rsvp", %{"rsvp" => %{"confirmed" => true}})

    resp = html_response(conn, 302)

    assert resp =~ ~p"/guest/1/rsvp"
    assert %RSVP{confirmed: true, guest_id: 1} = MyGuest.get_guest!(1).rsvp
  end

  describe "GET /guest/:guest_id/rsvp" do
    test "Sends valid response for users in the correct state", %{conn: conn} do
      conn = get(conn, ~p"/guest/1/rsvp?secret=123456")

      resp = html_response(conn, 200)

      assert resp =~ "RSVP: Adam Collins"
    end

    # Currently rendering a 404 for any 403 error, may change this behavior
    # in the future
    test "Returns 404 when secret is incorrect", %{conn: conn} do
      resp =
        get(conn, ~p"/guest/1/rsvp?secret=999999")
        |> html_response(404)

      assert resp =~ "404"
    end

    test "Writes a secret when none exist", %{conn: conn} do
      {:ok, %{id: id}} = MyGuest.create_guest(%{"first_name" => "Test", "last_name" => "User"})

      new_secret = "9999999"

      get(conn, ~p"/guest/#{id}/rsvp?secret=#{new_secret}")
      |> html_response(200)

      guest = MyGuest.get_guest(id)

      assert %{secret: ^new_secret} = guest
    end

    test "404 case", %{conn: conn} do
      conn = get(conn, ~p"/guest/42/rsvp")

      resp = html_response(conn, 404)

      assert resp =~ "404"
    end
  end
end
