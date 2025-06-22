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

    test "Cache cookie for the RSVP page", %{conn: conn} do
      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => "test@test.com"}})
        |> get(~p"/rsvp")
        |> html_response(200)

      assert resp =~ "You're invited"
      assert resp =~ "Adam Collins"
      assert resp =~ "Ceremony"
      assert resp =~ "Reception"
    end
  end

  describe "GET /rsvp/lookup" do
    test "Find invitations", %{conn: conn} do
      guest = MyGuest.get_guest!(1)

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> html_response(302)

      assert resp =~ "/rsvp"
    end

    test "Not found invitations", %{conn: conn} do
      bad_email = "not@found.com"
      conn = post(conn, ~p"/rsvp/lookup", %{"guest" => %{"email" => bad_email}})

      resp = html_response(conn, 200)

      assert resp =~ "Unable to find invitation"
      assert resp =~ "for: \"#{bad_email}\""
    end
  end

  describe "PUT /rsvp/invite" do
    test "Create RSVP", %{conn: conn} do
      guest = MyGuest.get_guest!(1)

      conn =
        put(conn, ~p"/rsvp/invite", %{
          "invitation_id" => 1,
          "wedding-1" => "yes",
          "rehersal-1" => "no"
        })

      assert html_response(conn, 200) =~ "Thanks"

      %RSVP{events: events, declined_events: declined_events} = MyGuest.get_or_create_rsvp!(guest)

      assert events == [:wedding]
      assert declined_events == [:rehersal]
    end
  end
end
