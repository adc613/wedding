defmodule App.Guest.RSVPTest do
  alias App.Guest.RSVP
  use App.DataCase

  test "Changeset happy case for RSVP" do
    errors =
      %RSVP{}
      |> RSVP.changeset(%{"guest_id" => 1, "event" => :wedding})
      |> errors_on()

    assert errors == %{}
  end

  test "Changeset requires guest_id field" do
    errors =
      %RSVP{}
      |> RSVP.changeset(%{})
      |> errors_on()

    assert %{guest_id: _} = errors
  end
end
