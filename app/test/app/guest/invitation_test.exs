defmodule App.Guest.InvitationTest do
  alias App.Guest.RSVP
  alias App.Guest.Guest
  alias App.Guest.Invitation
  use App.DataCase

  test "Changeset happy case" do
    invite = %Invitation{
      guests: [
        %Guest{
          rsvp: %RSVP{
            events: [:brunch, :wedding]
          }
        },
        %Guest{
          rsvp: %RSVP{
            events: [:wedding]
          }
        },
        %Guest{
          rsvp: nil
        }
      ]
    }

    assert Invitation.count_rsvps(invite) == %{total: 3, wedding: 2, brunch: 1, rehersal: 0}
  end
end
