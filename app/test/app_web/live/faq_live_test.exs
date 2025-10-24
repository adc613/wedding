defmodule AppWeb.FaqLiveTest do
  alias App.MyGuest
  alias App.MyQuestions
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest

  setup do
    {:ok, g} =
      MyGuest.create_guest(%{
        "first_name" => "fn1",
        "last_name" => "ln1",
        "email" => "guest1@gmail.com"
      })

    {:ok, q0} =
      MyQuestions.create_question(%{
        question: "Are we in the matrix?",
        guest_id: g.id
      })

    {:ok, q1} =
      MyQuestions.create_question(%{
        question: "Is this a test?",
        guest_id: g.id
      })

    {:ok, q2} =
      MyQuestions.create_question(%{
        question: "Seriously is this a test?",
        guest_id: g.id
      })

    %{
      g1: g,
      q0: q0,
      q1: q1,
      q2: q2
    }
  end

  test "renders page with questions", %{conn: conn, q1: q1} do
    {:ok, lv, html} =
      conn
      |> live(~p"/faq")

    assert html =~ "FAQ"
    assert html =~ "Loading questions..."
    render_async(lv) =~ q1.question
    render_async(lv) =~ "Waiting for Helen or Adam to respond"
    assert not has_element?(lv, ~s|button|, "Answer")
    assert not has_element?(lv, ~s|button|, "Ask")
  end

  test "reners answer", %{conn: conn, q1: q1} do
    MyQuestions.answer_question(%{id: q1.id, answer: "Something incredible"})

    {:ok, lv, html} =
      conn
      |> live(~p"/faq")

    assert html =~ "FAQ"
    assert html =~ "Loading questions..."
    render_async(lv) =~ "Something incredible"
  end

  describe "guest" do
    setup %{conn: conn, g1: g} do
      conn =
        conn
        |> post(~p"/rsvp/lookup", %{"guest" => %{"email" => g.email}})

      %{conn: conn}
    end

    test "renders answer textarea", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> live(~p"/faq")

      assert has_element?(lv, ~s|button|, "Ask")
      assert not has_element?(lv, ~s|button|, "Answer")
      assert has_element?(lv, ~s|textarea|)
    end

    test "Submit question", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> live(~p"/faq")

      assert length(MyQuestions.list_questions()) == 3

      assert lv
             |> element("#question-form")
             |> render_submit(%{
               "question" => %{"question" => "Are we in a CI env?"}
             })

      assert length(MyQuestions.list_questions()) == 4
    end
  end
end
