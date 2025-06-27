defmodule App.MyGuestTest do
  alias App.Guest.Guest
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

  test "list_invitations()" do
    g1 = MyGuest.get_guest!(1, preload: :rsvp)

    {:ok, _invitation} =
      MyGuest.create_invitation(
        guests: [g1],
        events: [:wedding, :rehersal],
        kids: false,
        plus_one: false
      )

    g2 = MyGuest.get_guest!(2, preload: :rsvp)
    g3 = MyGuest.get_guest!(3, preload: :rsvp)

    {:ok, _invitaiton} =
      MyGuest.create_invitation(
        guests: [g2, g3],
        events: [:wedding],
        kids: false,
        plus_one: false
      )

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

  test "update()" do
    guest = MyGuest.get_guest(1, preload: :rsvp)
    MyGuest.update(guest, %{"first_name" => "Helen"})
    guest = MyGuest.get_guest!(guest.id, preload: :rsvp)

    assert %{first_name: "Helen"} = guest
  end

  test "delete() guest" do
    1..3
    |> Enum.map(&MyGuest.get_guest!(&1, preload: :rsvp))
    |> Enum.map(&MyGuest.delete(&1))

    assert MyGuest.list_guests() == []
  end

  test "delete() invitation" do
    assert length(MyGuest.list_invitations()) == 0

    g1 = MyGuest.get_guest!(1, preload: :rsvp)

    {:ok, _invitation} =
      MyGuest.create_invitation(
        guests: [g1],
        events: [:wedding, :rehersal],
        kids: false,
        plus_one: false
      )

    invitation = MyGuest.get_invitation(1)
    MyGuest.delete(invitation)

    assert length(MyGuest.list_invitations()) == 0
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

  describe "create_invitation()" do
    test "Happy case" do
      guest = MyGuest.get_guest(1, preload: :rsvp)

      MyGuest.create_invitation(
        guests: [guest],
        events: [:wedding, :rehersal],
        kids: false,
        plus_one: false
      )

      g2 = MyGuest.get_guest!(1, preload: :rsvp, preload: :invitation)

      assert guest != g2
      assert g2.invitation == MyGuest.get_invitation(guest_id: 1)
      assert nil == MyGuest.get_invitation(42)
      assert g2.invitation.additional_guests == 0
      assert g2.invitation.permit_kids == false
    end

    test "With additional guests" do
      guest = MyGuest.get_guest(1, preload: :rsvp)

      MyGuest.create_invitation(
        guests: [guest],
        events: [:rehersal],
        kids: true,
        plus_one: true
      )

      g2 = MyGuest.get_guest!(1, preload: :rsvp, preload: :invitation)

      assert guest != g2
      assert g2.invitation == MyGuest.get_invitation(guest_id: 1)
      assert nil == MyGuest.get_invitation(42)
      assert g2.invitation.additional_guests == 1
      assert g2.invitation.permit_kids == true
    end
  end

  describe "get_guest()" do
    @tag only: true
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

    test "with phone number" do
      {:ok, guest} =
        MyGuest.create_guest(%{
          "email" => "test4@test.com",
          "first_name" => "Adam4",
          "last_name" => "Collins",
          "secret" => "123456",
          "phone" => "+1(847)562-6149"
        })

      db_guest = MyGuest.get_guest(phone: "8475626149")

      assert guest == db_guest |> Guest.add_phone()

      MyGuest.create_guest(%{
        "email" => "test4@test.com",
        "first_name" => "Adam5",
        "last_name" => "Collins",
        "secret" => "123456",
        "phone" => "+1(847)562-6149"
      })

      db_guest = MyGuest.get_guest(phone: "8475626149")

      assert db_guest == :many_matches

      db_guest = MyGuest.get_guest(email: "8475554321")

      assert db_guest == nil
    end

    @tag only: true
    test "happy case" do
      {:ok, guest} =
        MyGuest.create_guest(%{
          "email" => "test4@test.com",
          "first_name" => "Adam4",
          "last_name" => "Collins",
          "secret" => "123456",
          "phone_number" => "8475551234",
          "country_code" => 1
        })

      db_guest = MyGuest.get_guest!(guest.id, preload: :rsvp)
      guest = Repo.preload(guest, :rsvp)

      assert guest |> Guest.add_phone() == db_guest
      assert nil == MyGuest.get_guest(42)
    end
  end

  describe("create_guests()") do
    test "with email" do
      {:ok, %{id: guest_id}} =
        MyGuest.create_guest(%{
          "email" => "test@test.test",
          "first_name" => "Adam",
          "last_name" => "Collins",
          "secret" => "123456",
          "phone" => "8475626149"
        })

      guest = MyGuest.get_guest!(guest_id, preload: :rsvp)

      assert guest.first_name == "Adam"
      assert guest.last_name == "Collins"
      assert guest.secret == "123456"
      assert guest.phone == "+1(847)562-6149"
    end

    test "supports no email addres" do
      {:ok, %{id: guest_id}} =
        MyGuest.create_guest(%{
          "email" => "",
          "first_name" => "Adam",
          "last_name" => "Collins",
          "secret" => "123456"
        })

      guest = MyGuest.get_guest!(guest_id, preload: :rsvp)

      assert guest.first_name == "Adam"
      assert guest.last_name == "Collins"
      assert guest.secret == "123456"
      assert guest.email == nil
    end

    @tag only: true
    test "supports phone number in various formats" do
      {:ok, %{id: guest_id}} =
        MyGuest.create_guest(%{
          "email" => "",
          "first_name" => "Adam",
          "last_name" => "Collins",
          "secret" => "123456",
          "phone" => "8475551234"
        })

      guest = MyGuest.get_guest!(guest_id)

      assert match?(%{first_name: "Adam", phone_number: 847_555_1234, country_code: 1}, guest)

      {:ok, %{id: guest_id}} =
        MyGuest.create_guest(%{
          "email" => "",
          "first_name" => "Adam",
          "last_name" => "Collins",
          "secret" => "123456",
          "phone" => "18475551234"
        })

      guest = MyGuest.get_guest!(guest_id)

      assert match?(%{first_name: "Adam", phone_number: 847_555_1234, country_code: 1}, guest)

      {:ok, %{id: guest_id}} =
        MyGuest.create_guest(%{
          "email" => "",
          "first_name" => "Adam",
          "last_name" => "Collins",
          "secret" => "123456",
          "phone" => "1(847)555-1234"
        })

      guest = MyGuest.get_guest!(guest_id)

      assert match?(%{first_name: "Adam", phone_number: 847_555_1234, country_code: 1}, guest)

      {:ok, %{id: guest_id}} =
        MyGuest.create_guest(%{
          "email" => "",
          "first_name" => "Adam",
          "last_name" => "Collins",
          "secret" => "123456",
          "phone" => "+1 (847) 555 - 1234"
        })

      guest = MyGuest.get_guest!(guest_id)

      assert match?(%{first_name: "Adam", phone_number: 847_555_1234, country_code: 1}, guest)
    end

    test "Adding guest to invitation" do
      {:ok, invitation} =
        MyGuest.create_invitation(%{
          "events" => ["wedding"],
          "additional_guests" => 2
        })

      assert invitation.additional_guests == 2

      {:ok, %{id: guest_id}} =
        MyGuest.create_guest(
          %{
            "email" => "",
            "first_name" => "Adam",
            "last_name" => "Collins",
            "secret" => "123456",
            "invitation_id" => invitation.id
          },
          invitation
        )

      invitation = MyGuest.get_invitation!(invitation.id, preload: :guests)

      assert length(invitation.guests) == 1
      {:ok, guest} = Enum.fetch(invitation.guests, 0)
      assert guest.id == guest_id
      assert invitation.additional_guests == 1

      {:ok, %{id: _guest_id}} =
        MyGuest.create_guest(
          %{
            "email" => "",
            "first_name" => "Adm",
            "last_name" => "Collins",
            "secret" => "123456",
            "invitation_id" => invitation.id
          },
          invitation
        )

      invitation = MyGuest.get_invitation!(invitation.id, preload: :guests)

      assert invitation.additional_guests == 0
    end

    test "Add kids to invitation" do
      {:ok, invitation} =
        MyGuest.create_invitation(%{
          "events" => ["wedding"],
          "additional_guests" => 2
        })

      assert invitation.additional_guests == 2

      {:ok, %{id: guest_id}} =
        MyGuest.create_guest(
          %{
            "email" => "",
            "first_name" => "Adam",
            "last_name" => "Collins",
            "secret" => "123456",
            "invitation_id" => invitation.id,
            "is_kid" => "true"
          },
          invitation
        )

      invitation = MyGuest.get_invitation!(invitation.id, preload: :guests)

      assert length(invitation.guests) == 1
      {:ok, guest} = Enum.fetch(invitation.guests, 0)
      assert guest.id == guest_id
      assert guest.is_kid == true
      assert invitation.additional_guests == 2
    end
  end
end
