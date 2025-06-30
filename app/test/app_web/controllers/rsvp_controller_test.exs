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
        "secret" => "123456",
        "phone" => "8475551234"
      })

    {:ok, invitation} =
      MyGuest.create_invitation(
        guests: [guest],
        events: ["wedding"],
        kids: false,
        plus_one: false
      )

    %{guest: guest, invitation: MyGuest.load(invitation, preload: :guests)}
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
        |> html_response(302)

      assert resp =~ "/rsvp/edit"
    end

    test "Lookup phone number", %{conn: conn} do
      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"phone" => "8475551234"}})
        |> get(~p"/rsvp")
        |> html_response(302)

      assert resp =~ "/rsvp/edit"
    end

    test "Redirect to thanks when the user has submitted an RSVP in the past", %{conn: conn} do
      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"phone" => "8475551234"}})
        |> put(~p"/rsvp/invite", %{
          "invitation_id" => 1,
          "wedding-1" => "yes",
          "rehersal-1" => "no"
        })
        |> get(~p"/rsvp")
        |> html_response(302)

      assert resp =~ "/rsvp/thanks"
    end
  end

  describe "GET /rsvp/edit" do
    test "Loads page successfully", %{conn: conn} do
      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => "test@test.com"}})
        |> get(~p"/rsvp/edit")
        |> html_response(200)

      assert resp =~ "You're invited"
      assert resp =~ "Adam Collins"
      assert resp =~ "Ceremony"
      assert resp =~ "Reception"
    end

    test "Does not create RSVP until submit action", %{conn: conn, guest: guest} do
      conn
      |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
      |> get(~p"/rsvp/edit")
      |> html_response(200)

      guest = MyGuest.get_guest(guest.id, preload: :rsvp)

      assert guest.rsvp == nil
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

    test "Allows user to edit their info", %{conn: conn} do
      guest = MyGuest.get_guest!(1)

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> get(~p"/guest/#{guest.id}/edit")
        |> html_response(200)

      assert resp =~ guest.first_name
    end

    test "Allows user to edit invite guests", %{conn: conn} do
      guest = MyGuest.get_guest!(1)

      {:ok, g2} =
        MyGuest.create_guest(%{
          "email" => "test2@test.com",
          "first_name" => "Test",
          "last_name" => "User",
          "secret" => "123456"
        })

      assert {:ok, _invitation} =
               MyGuest.create_invitation(
                 guests: [guest, g2],
                 events: [:brunch],
                 kids: false,
                 plus_one: false
               )

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> get(~p"/guest/#{g2.id}/edit")
        |> html_response(200)

      assert resp =~ g2.first_name
    end

    test "Redirect user editing a page thats not there's", %{conn: conn} do
      guest = MyGuest.get_guest!(1)

      {:ok, g2} =
        MyGuest.create_guest(%{
          "email" => "test@test.com",
          "first_name" => "Test",
          "last_name" => "User",
          "secret" => "123456"
        })

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> get(~p"/guest/42/edit")
        |> html_response(302)

      assert resp =~ "/users/log_in"

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> get(~p"/guest/#{g2.id}/edit")
        |> html_response(302)

      assert resp =~ "/users/log_in"
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

      resp =
        put(conn, ~p"/rsvp/invite", %{
          "invitation_id" => 1,
          "wedding-1" => "yes",
          "rehersal-1" => "no"
        })
        |> html_response(302)

      assert resp =~ "/rsvp/thanks"

      %RSVP{events: events, declined_events: declined_events} = MyGuest.get_or_create_rsvp!(guest)

      assert events == [:wedding]
      assert declined_events == [:rehersal]
    end
  end

  describe("confirmation flow") do
    test "Lookup redirect to confirm only when there's not an existing RSVP", %{conn: conn} do
      guest = MyGuest.get_guest!(1)

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> html_response(302)

      assert resp =~ "/rsvp/confirm"

      conn =
        put(conn, ~p"/rsvp/invite", %{
          "invitation_id" => 1,
          "wedding-1" => "yes",
          "rehersal-1" => "no"
        })

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> html_response(302)

      refute resp =~ "/rsvp/confirm"
    end

    test "Redirect to /rsvp when no guest ID is found", %{conn: conn} do
      resp =
        conn
        |> get(~p"/rsvp/confirm")
        |> html_response(302)

      assert resp =~ "/rsvp"
      refute resp =~ "/rsvp/confirm"
    end

    test "Redirect to /rsvp/confirm0 as first step", %{conn: conn} do
      guest = MyGuest.get_guest!(1)

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> get(~p"/rsvp/confirm")
        |> html_response(302)

      assert resp =~ "/rsvp/confirm/0"
    end

    test "Render step 0", %{conn: conn, guest: guest} do
      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> get(~p"/rsvp/confirm/0")
        |> html_response(200)

      assert resp =~ "s a good email?"
    end

    test "Only render step 1 when invitation has permission to add guests", %{
      conn: conn,
      guest: guest,
      invitation: invitation
    } do
      assert invitation.additional_guests == 0

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> get(~p"/rsvp/confirm/1")
        |> html_response(200)

      assert resp =~ "confirm contact information"
      refute resp =~ "got a plus one"

      MyGuest.update(invitation, %{"additional_guests" => 1})

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> get(~p"/rsvp/confirm/1")
        |> html_response(200)

      refute resp =~ "confirm contact information"
      assert resp =~ "got a plus one"
    end

    test "Only render step 2 when invitation has permission to add kids", %{
      conn: conn,
      guest: guest,
      invitation: invitation
    } do
      assert invitation.permit_kids == false

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> get(~p"/rsvp/confirm/2")
        |> html_response(200)

      assert resp =~ "confirm contact information"
      refute resp =~ "family-friendly"

      MyGuest.update(invitation, %{"permit_kids" => "true"})

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> get(~p"/rsvp/confirm/2")
        |> html_response(200)

      refute resp =~ "confirm contact information"
      assert resp =~ "family-friendly"
    end

    test "Render step 3", %{
      conn: conn,
      guest: guest,
      invitation: invitation
    } do
      assert invitation.permit_kids == false

      resp =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
        |> get(~p"/rsvp/confirm/3")
        |> html_response(200)

      assert resp =~ "confirm contact information"
    end

    test "Block users from adding guests when they don't have permission", %{
      conn: conn,
      guest: guest,
      invitation: invitation
    } do
      assert invitation.additional_guests == 0
      assert length(invitation.guests) == 1

      conn
      |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
      |> post(~p"/rsvp/add_guest", %{
        "guest" => %{
          "email" => "test@test.test",
          "first_name" => "Adam 2",
          "last_name" => "Collins",
          "invitation_id" => invitation.id
        },
        "redirect" => "/test"
      })

      assert MyGuest.get_invitation(invitation.id, preload: :guests)
             |> then(&length(&1.guests)) == 1

      MyGuest.update(invitation, %{"additional_guests" => 1})

      conn
      |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
      |> post(~p"/rsvp/add_guest", %{
        "guest" => %{
          "email" => "test@test.test",
          "first_name" => "Adam 2",
          "last_name" => "Collins",
          "invitation_id" => invitation.id
        },
        "redirect" => "/test"
      })

      invitation = MyGuest.get_invitation(invitation.id, preload: :guests)
      assert length(invitation.guests) == 2
      {:ok, new_guest} = Enum.fetch(invitation.guests, 1)
      assert new_guest.first_name == "Adam 2"
    end

    test "Block users from adding kids when they don't have permission", %{
      conn: conn,
      guest: guest,
      invitation: invitation
    } do
      assert invitation.permit_kids == false

      conn
      |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
      |> post(~p"/rsvp/add_guest", %{
        "guest" => %{
          "email" => "test@test.test",
          "first_name" => "Adam 2",
          "last_name" => "Collins",
          "is_kid" => "true",
          "invitation_id" => invitation.id
        },
        "redirect" => "/test"
      })

      assert MyGuest.get_invitation(invitation.id, preload: :guests)
             |> then(&length(&1.guests)) == 1

      MyGuest.update(invitation, %{"permit_kids" => "true"})

      conn
      |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
      |> post(~p"/rsvp/add_guest", %{
        "guest" => %{
          "email" => "test@test.test",
          "first_name" => "Adam 2",
          "last_name" => "Collins",
          "is_kid" => "true",
          "invitation_id" => invitation.id
        },
        "redirect" => "/test"
      })

      invitation = MyGuest.get_invitation(invitation.id, preload: :guests)
      assert length(invitation.guests) == 2
      {:ok, new_guest} = Enum.fetch(invitation.guests, 1)
      assert new_guest.first_name == "Adam 2"
    end

    test "Block users from adding guests to invites they're not on", %{
      conn: conn,
      guest: guest,
      invitation: invitation
    } do
      assert invitation.additional_guests == 0
      assert length(invitation.guests) == 1

      {:ok, i2} =
        MyGuest.create_invitation(guests: [], events: ["wedding"], kids: false, plus_one: true)

      conn
      |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => guest.email}})
      |> post(~p"/rsvp/add_guest", %{
        "guest" => %{
          "email" => "test@test.test",
          "first_name" => "Adam 2",
          "last_name" => "Collins",
          "invitation_id" => i2.id
        },
        "redirect" => "/test"
      })

      assert MyGuest.get_invitation(i2.id, preload: :guests)
             |> then(&length(&1.guests)) == 0
    end
  end
end
