defmodule AppWeb.GuestManageLiveTest do
  alias App.Guest.Guest
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
        |> live(~p"/admin/guest")

      assert html =~ "Admin page"
      assert html =~ "Manage guest"
    end

    test "allows guest creation", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/admin/guest")

      render_async(lv)

      assert has_element?(lv, ~s|button|, "Add guest")

      assert length(MyGuest.list_guests()) == 3

      assert lv
             |> element("#guest-form")
             |> render_submit(%{
               "guest" => %{"first_name" => "fn4", "last_name" => "ln4", "phone" => "8475556149"}
             })

      render_async(lv)

      assert length(MyGuest.list_guests()) == 4
      assert match?(%Guest{phone: "8475556149"}, MyGuest.get_guest!(4))
    end

    test "prevents duplicate guests", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/admin/guest")

      render_async(lv)

      assert has_element?(lv, ~s|button|, "Add guest")

      assert length(MyGuest.list_guests()) == 3

      assert lv
             |> element("#guest-form")
             |> render_submit(%{"guest" => %{"first_name" => "fn1", "last_name" => "ln1"}})

      render_async(lv)

      assert length(MyGuest.list_guests()) == 3
    end
  end
end
