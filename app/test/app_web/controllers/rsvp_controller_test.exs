defmodule AppWeb.RSVPControllerTest do
  alias App.Guest.RSVP
  alias App.MyGuest
  use AppWeb.ConnCase

  setup do
    {:ok, guest} =
      MyGuest.create_guest(%{
        "email" => "test@test.com",
        "first_name" => "Adam",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    MyGuest.create_invitation(guests: [guest], events: ["wedding"])

    :ok
  end

  describe "GET /rsvp" do
    test "Sends valid response", %{conn: conn} do
      conn = get(conn, ~p"/rsvp")

      resp = html_response(conn, 200)

      assert resp =~ "Find Invitation"
    end
  end

  describe "GET /rsvp/lookup" do
    test "Find invitations", %{conn: conn} do
      guest = MyGuest.get_guest!(1)
      conn = get(conn, ~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})

      resp = html_response(conn, 302)

      assert resp =~ "/rsvp/1"
    end

    test "Not found invitations", %{conn: conn} do
      bad_email = "not@found.com"
      conn = get(conn, ~p"/rsvp/lookup", %{"guest" => %{"email" => bad_email}})

      resp = html_response(conn, 200)

      assert resp =~ "Unable to find invitation"
      assert resp =~ "for: \"#{bad_email}\""
    end
  end

  describe "GET /rsvp/1" do
    test "RSVP page", %{conn: conn} do
      conn = get(conn, ~p"/rsvp/1")

      resp = html_response(conn, 200)

      assert resp =~ "You're invited"
      assert resp =~ "Adam Collins"
      assert resp =~ "Ceremony"
      assert resp =~ "Reception"
    end
  end

  describe "PUT /rsvp/1" do
    test "Create RSVP", %{conn: conn} do
      guest = MyGuest.get_guest!(1)

      conn =
        put(conn, ~p"/rsvp", %{"invitation_id" => 1, "wedding-1" => "yes", "rehersal-1" => "no"})

      html_response(conn, 302)

      %RSVP{events: events, declined_events: declined_events} = MyGuest.get_or_create_rsvp!(guest)

      assert events == [:wedding]
      assert declined_events == [:rehersal]
    end
  end
end
