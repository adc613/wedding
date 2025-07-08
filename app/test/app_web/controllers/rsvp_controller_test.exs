defmodule AppWeb.RSVPControllerTest do
  use AppWeb.ConnCase

  alias App.MyGuest

  setup do
    {:ok, guest} = 
      MyGuest.create_guest(%{
        "email" => "test@test.com",
        "first_name" => "Adam",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    {:ok, invitation} = 
      MyGuest.create_invitation(
        guests: [guest],
        events: [:wedding, :rehersal],
        kids: false,
        plus_one: false
      )

    %{guest: guest, invitation: invitation}
  end

  test "update_rsvp with dietary restrictions", %{conn: conn, guest: guest, invitation: invitation} do
    conn = 
      put(conn, ~p"/rsvp/invite", %{
        "invitation_id" => invitation.id,
        "wedding-#{guest.id}" => "yes",
        "dietary_restrictions_#{guest.id}" => "peanuts"
      })

    assert redirected_to(conn) == ~p"/rsvp/thanks"

    rsvp = MyGuest.get_guest!(guest.id, preload: :rsvp).rsvp
    assert rsvp.dietary_restrictions == "peanuts"
  end
end