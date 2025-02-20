defmodule AppWeb.GuestControllerTest do
  alias App.Guest.RSVP
  alias App.MyGuest
  use AppWeb.ConnCase

  setup do
    {result, _guest} =
      MyGuest.create_guest(%{
        "first_name" => "Adam",
        "last_name" => "Collins"
      })

    result
  end

  test "GET /guest", %{conn: conn} do
    conn = get(conn, ~p"/guest")
    resp = html_response(conn, 200)

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

  test "GET /guest/:guests_id/rsvp 404", %{conn: conn} do
    conn = get(conn, ~p"/guest/42/rsvp")

    resp = html_response(conn, 404)

    assert resp =~ "404"
  end

  test "GET /guest/:guests_id/rsvp", %{conn: conn} do
    conn = get(conn, ~p"/guest/1/rsvp")

    resp = html_response(conn, 200)

    assert resp =~ "RSVP: Adam Collins"
  end

  test "POST /guest/:guests_id/rsvp", %{conn: conn} do
    conn = post(conn, ~p"/guest/1/rsvp", %{"rsvp" => %{"confirmed" => true}})

    resp = html_response(conn, 302)

    assert resp =~ ~p"/guest/1/rsvp"
    assert %RSVP{confirmed: true, guest_id: 1} = MyGuest.get_guest!(1).rsvp
  end
end
