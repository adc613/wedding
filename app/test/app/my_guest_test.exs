defmodule App.MyGuestTest do
  alias App.Guest.RSVP
  alias App.MyGuest
  use App.DataCase

  setup do
    {:ok, _guest} =
      MyGuest.create_guest(%{
        "email" => "test1@test.com",
        "first_name" => "Adam1",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    {:ok, _guest} =
      MyGuest.create_guest(%{
        "email" => "test2@test.com",
        "first_name" => "Adam2",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    {:ok, _guest} =
      MyGuest.create_guest(%{
        "email" => "test3@test.com",
        "first_name" => "Adam3",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    :ok
  end

  describe "get_guest()" do
    test "with email" do
      {:ok, guest} =
        MyGuest.create_guest(%{
          "email" => "test4@test.com",
          "first_name" => "Adam4",
          "last_name" => "Collins",
          "secret" => "123456"
        })

      db_guest = MyGuest.get_guest(email: guest.email)

      assert guest == db_guest

      MyGuest.create_guest(%{
        "email" => "test4@test.com",
        "first_name" => "Adam5",
        "last_name" => "Collins",
        "secret" => "123456"
      })

      db_guest = MyGuest.get_guest(email: guest.email)

      assert db_guest == :many_matches

      db_guest = MyGuest.get_guest(email: "does@not.exist")

      assert db_guest == nil
    end

    test "happy case" do
      {:ok, guest} =
        MyGuest.create_guest(%{
          "email" => "test4@test.com",
          "first_name" => "Adam4",
          "last_name" => "Collins",
          "secret" => "123456"
        })

      db_guest = MyGuest.get_guest!(guest.id, preload: :rsvp)
      guest = Repo.preload(guest, :rsvp)

      assert guest == db_guest
      assert nil == MyGuest.get_guest(42)
    end
  end

  test "create_invitation()" do
    guest = MyGuest.get_guest(1, preload: :rsvp)
    MyGuest.create_invitation(guests: [guest], events: [:wedding, :rehersal])
    g2 = MyGuest.get_guest!(1, preload: :rsvp, preload: :invitation)

    assert guest != g2
    assert g2.invitation == MyGuest.get_invitation(guest_id: 1)
    assert nil == MyGuest.get_invitation(42)
  end

  test "list_invitations()" do
    g1 = MyGuest.get_guest!(1, preload: :rsvp)
    :ok = MyGuest.create_invitation(guests: [g1], events: [:wedding, :rehersal])
    g2 = MyGuest.get_guest!(2, preload: :rsvp)
    g3 = MyGuest.get_guest!(3, preload: :rsvp)
    :ok = MyGuest.create_invitation(guests: [g2, g3], events: [:wedding])
    i1 = MyGuest.get_invitation(guest_id: 1)
    i2 = MyGuest.get_invitation(guest_id: 2)
    i3 = MyGuest.get_invitation(guest_id: 3)

    assert [i1, i2] == MyGuest.list_invitations()
    assert i2 == i3

    i1 = Repo.preload(i1, :guests)
    i2 = Repo.preload(i2, :guests)
    assert [i1, i2] == MyGuest.list_invitations(preload: :guests)
  end

  test "list_guests()" do
    list_guests = MyGuest.list_guests()
    guests = 1..3 |> Enum.map(&MyGuest.get_guest!(&1, preload: :rsvp))

    assert list_guests == guests
  end

  test "create_guest()" do
    {:ok, %{id: guest_id}} =
      MyGuest.create_guest(%{
        "email" => "test@test.test",
        "first_name" => "Adam",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    guest = MyGuest.get_guest!(guest_id, preload: :rsvp)

    assert guest.first_name == "Adam"
    assert guest.last_name == "Collins"
    assert guest.secret == "123456"
  end

  test "update()" do
    guest = MyGuest.get_guest(1, preload: :rsvp)
    MyGuest.update(guest, %{"first_name" => "Helen"})
    guest = MyGuest.get_guest!(guest.id, preload: :rsvp)

    assert %{first_name: "Helen"} = guest
  end

  test "delete()" do
    1..3
    |> Enum.map(&MyGuest.get_guest!(&1, preload: :rsvp))
    |> Enum.map(&MyGuest.delete(&1))

    assert MyGuest.list_guests() == []
  end

  test "get_or_create_rsvp()" do
    guest = MyGuest.get_guest(1, preload: :rsvp)
    rsvp = MyGuest.get_or_create_rsvp!(guest)

    assert %RSVP{guest_id: 1} = rsvp
    assert_raise Ecto.NoResultsError, fn -> MyGuest.get_or_create_rsvp!(42) end
  end

  test "send_std()" do
    guest = MyGuest.get_guest(1, preload: :rsvp)
    {:ok, _guest} = MyGuest.send_std(guest)

    assert guest = %{sent_std: true}

    result = MyGuest.send_std(guest)
    assert {:error, :duplicate_std} = result
  end
end
