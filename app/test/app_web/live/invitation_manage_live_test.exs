defmodule AppWeb.InvitationManageLiveTest do
  alias App.MyGuest
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.AccountsFixtures

  setup do
    MyGuest.create_guest(%{
      "first_name" => "fn1",
      "last_name" => "ln1",
      "email" => "guest1@gmail.com"
    })

    MyGuest.create_guest(%{
      "first_name" => "fn2",
      "last_name" => "ln2",
      "email" => "guest2@gmail.com"
    })

    MyGuest.create_guest(%{
      "first_name" => "fn3",
      "last_name" => "ln3",
      "email" => "guest3@gmail.com"
    })

    %{user: user_fixture()}
  end

  describe "Invitation Manage" do
    test "renders invitaion page", %{conn: conn, user: user} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/admin/invitation")

      assert html =~ "Admin page"
      assert html =~ "Manage invitations"
    end

    test "create invitation", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/admin/invitation")

      render_async(lv)

      assert has_element?(lv, ~s|button|, "Create invitation")

      assert lv
             |> element(~s|table [id="guests"] tr td|, "fn1 ln1")
             |> render_click()

      assert lv
             |> element(~s|table [id="guests"] tr td|, "fn2 ln2")
             |> render_click()

      assert length(MyGuest.list_invitations()) == 0

      assert lv
             |> element("#invite_form")
             |> render_submit(%{
               "rehersal" => true,
               "brunch" => false,
               "plus_one" => true,
               "permit_kids" => false
             })

      render_async(lv)

      assert length(MyGuest.list_invitations()) == 1

      assert MyGuest.get_invitation(1, preload: :guests).guests == [
               MyGuest.get_guest!(1),
               MyGuest.get_guest!(2)
             ]

      assert MyGuest.get_invitation(1).events == [:wedding, :rehersal]
    end

    test "delete invitation", %{conn: conn, user: user} do
      MyGuest.create_invitation(
        guests: [MyGuest.get_guest!(1)],
        events: [:wedding],
        kids: false,
        plus_one: false
      )

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/admin/invitation")

      render_async(lv)

      assert lv
             |> element(~s|table [id="invitations"] tr td|, MyGuest.get_guest!(1).first_name)
             |> render_click()

      assert lv
             |> element(~s|[id="confirm-delete"] button|, "Delete")
             |> render_click()

      render_async(lv)

      assert length(MyGuest.list_invitations()) == 0
    end
  end
end
