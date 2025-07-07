defmodule AppWeb.InvitationControllerTest do
  alias App.Accounts
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

    {:ok, _invite} =
      MyGuest.create_invitation(
        %{
          "events" => [:wedding],
          "additional_guests" => 1,
          "permit_kids" => true
        },
        guests: [guest]
      )

    {:ok, _user} =
      Accounts.register_user(%{
        "email" => "test@test.com",
        "password" => "password123456789",
        "confirm_password" => "password123456789"
      })

    :ok
  end

  describe "When uesr is logged in" do
    setup %{conn: conn} do
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})

      {:ok, %{conn: conn, user: user}}
    end

    test "GET /invitation", %{conn: conn} do
      resp =
        conn
        |> get(~p"/invitation")
        |> html_response(200)

      assert resp =~ "</html>"
      assert resp =~ "Adam Collins"
    end

    test "GET /invitation/:id", %{conn: conn} do
      conn = get(conn, ~p"/invitation/1")
      resp = html_response(conn, 200)

      assert resp =~ "</html>"
      assert resp =~ "Adam Collins"
    end

    test "GET /invitation/:id 404", %{conn: conn} do
      conn = get(conn, ~p"/invitation/42")
      resp = html_response(conn, 404)

      assert resp =~ "Found Love"
    end

    test "GET /invitation/new", %{conn: conn} do
      conn = get(conn, ~p"/invitation/new")
      resp = html_response(conn, 200)

      assert resp =~ "</html>"
      assert resp =~ "Create invitation"
    end

    test "POST /invitation", %{conn: conn} do
      conn =
        post(conn, ~p"/invitation", %{
          "invitation" => %{
            "events" => [:wedding],
            "additional_guests" => 1,
            "permit_kids" => true
          }
        })

      resp = html_response(conn, 302)

      assert resp =~ ~p"/invitation/2"
    end

    test "PUT /invitation/:id", %{conn: conn} do
      conn =
        put(conn, ~p"/invitation/1", %{
          "invitation" => %{
            "wedding" => "true",
            "rehersal" => "true",
            "brunch" => "false",
            "additional_guests" => 2,
            "permit_kids" => "false"
          }
        })

      resp = html_response(conn, 302)

      assert resp =~ ~p"/invitation/1"

      assert :wedding in MyGuest.get_invitation!(1).events
      assert :rehersal in MyGuest.get_invitation!(1).events
      refute :brunch in MyGuest.get_invitation!(1).events
      assert MyGuest.get_invitation!(1).additional_guests == 2
      assert MyGuest.get_invitation!(1).permit_kids == false
    end

    test "PATCH /invitation/:id", %{conn: conn} do
      conn =
        patch(conn, ~p"/invitation/1", %{
          "invitation" => %{
            "wedding" => "true",
            "rehersal" => "true",
            "additional_guests" => 2,
            "permit_kids" => "false"
          }
        })

      resp = html_response(conn, 302)

      assert resp =~ ~p"/invitation/1"

      assert :wedding in MyGuest.get_invitation!(1).events
      assert :rehersal in MyGuest.get_invitation!(1).events
      refute :brunch in MyGuest.get_invitation!(1).events
      assert MyGuest.get_invitation!(1).additional_guests == 2
      assert MyGuest.get_invitation!(1).permit_kids == false
    end

    test "DELETE /invitation/:id", %{conn: conn} do
      conn = delete(conn, ~p"/invitation/1")

      resp = html_response(conn, 302)

      assert resp =~ ~p"/invitation"
      assert MyGuest.list_invitations([]) == []
    end
  end
end
