defmodule App.MyGuestTest do
  alias App.Guest.RSVP
  alias App.Guest.Guest
  alias App.MyGuest
  use App.DataCase

  test "get_guest()" do
    guest = create_guest()

    assert guest == MyGuest.get_guest(1)
    assert nil == MyGuest.get_guest(42)
  end

  test "list_guests()" do
    guest = create_guest()
    guests = MyGuest.list_guests()

    assert guests == [guest]
  end

  test "create_guest()" do
    {:ok, %{:id => guest_id}} =
      MyGuest.create_guest(%{
        "email" => "test@test.test",
        "first_name" => "Adam",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    guest = MyGuest.get_guest!(guest_id)

    assert guest.first_name == "Adam"
    assert guest.last_name == "Collins"
    assert guest.secret == "123456"
  end

  test "update()" do
    guest = create_guest()
    MyGuest.update(guest, %{"first_name" => "Adam 2"})

    guest = MyGuest.get_guest!(guest.id)

    assert guest.first_name == "Adam 2"
  end

  test "delete()" do
    create_guest()
    |> MyGuest.delete()

    assert MyGuest.list_guests() == []
  end

  test "get_or_create_rsvp()" do
    guest = create_guest()
    rsvp = MyGuest.get_or_create_rsvp!(guest.id)

    assert %RSVP{guest_id: 1} = rsvp
    assert_raise Ecto.NoResultsError, fn -> MyGuest.get_or_create_rsvp!(42) end
  end

  defp create_guest() do
    MyGuest.create_guest(%{
      "email" => "test@test.test",
      "first_name" => "Adam",
      "last_name" => "Colins"
    })
    |> then(fn {:ok, guest} -> %Guest{guest | rsvp: nil} end)
  end
end
