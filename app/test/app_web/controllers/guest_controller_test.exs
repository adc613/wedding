defmodule AppWeb.GuestControllerTest do
  alias App.Accounts
  alias App.MyGuest
  use AppWeb.ConnCase

  setup do
    {:ok, _guest} =
      MyGuest.create_guest(%{
        "email" => "test@test.com",
        "first_name" => "Adam",
        "last_name" => "Collins",
        "secret" => "123456"
      })

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

    test "GET /guest", %{conn: conn} do
      resp =
        conn
        |> get(~p"/guest")
        |> html_response(200)

      assert resp =~ "</html>"
      assert resp =~ "Adam Collins"
    end

    test "GET /guest/:id", %{conn: conn} do
      conn = get(conn, ~p"/guest/1")
      resp = html_response(conn, 200)

      assert resp =~ "</html>"
      assert resp =~ "Adam Collins"
    end

    test "GET /guest/:id 404", %{conn: conn} do
      conn = get(conn, ~p"/guest/42")
      resp = html_response(conn, 404)

      assert resp =~ "Found Love"
    end

    test "GET /guest/new", %{conn: conn} do
      conn = get(conn, ~p"/guest/new")
      resp = html_response(conn, 200)

      assert resp =~ "</html>"
      assert resp =~ "Create guest"
    end

    test "POST /guest", %{conn: conn} do
      conn =
        post(conn, ~p"/guest", %{
          "guest" => %{
            "email" => "test@test.test",
            "first_name" => "Adam 2",
            "last_name" => "Collins"
          }
        })

      resp = html_response(conn, 302)

      assert resp =~ ~p"/guest/2"
      assert MyGuest.get_guest!(2).first_name == "Adam 2"
    end

    test "PUT /guest/:id", %{conn: conn} do
      conn =
        put(conn, ~p"/guest/1", %{
          "guest" => %{"first_name" => "Adam 2", "last_name" => "Collins"}
        })

      resp = html_response(conn, 302)

      assert resp =~ ~p"/guest/1"
      assert MyGuest.get_guest!(1).first_name == "Adam 2"
      assert MyGuest.get_guest!(1).last_name == "Collins"
    end

    test "PATCH /guest/:id", %{conn: conn} do
      conn =
        patch(conn, ~p"/guest/1", %{
          "guest" => %{"first_name" => "Adam 2"}
        })

      resp = html_response(conn, 302)

      assert resp =~ ~p"/guest/1"
      assert MyGuest.get_guest!(1).first_name == "Adam 2"
      assert MyGuest.get_guest!(1).last_name == "Collins"
    end

    test "DELETE /guest/:id", %{conn: conn} do
      conn = delete(conn, ~p"/guest/1")

      resp = html_response(conn, 302)

      assert resp =~ ~p"/guest"
      assert MyGuest.list_guests() == []
    end
  end
end
