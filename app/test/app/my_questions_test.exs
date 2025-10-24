defmodule App.MyQuestionsTest do
  alias App.MyGuest
  alias App.MyQuestions
  use App.DataCase

  setup do
    {:ok, g1} =
      MyGuest.create_guest(%{
        "email" => "test1@test.com",
        "first_name" => "Adam1",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    {:ok, g2} =
      MyGuest.create_guest(%{
        "email" => "test2@test.com",
        "first_name" => "Adam2",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    {:ok, g3} =
      MyGuest.create_guest(%{
        "email" => "test3@test.com",
        "first_name" => "Adam3",
        "last_name" => "Collins",
        "secret" => "123456"
      })

    %{g1: g1, g2: g2, g3: g3}
  end

  describe "create_question()" do
    test "Happy case", %{g1: g} do
      question = "Is this a test?"

      {:ok, q} =
        MyQuestions.create_question(%{question: question, guest_id: g.id})

      assert MyQuestions.get_question!(q.id) == q
      assert q.question == question
      assert q.upvotes == 1
    end
  end

  describe "answer_question()" do
    test "Happy case", %{g1: g} do
      question = "Is this a test?"

      {:ok, q} =
        MyQuestions.create_question(%{question: question, guest_id: g.id})

      {:ok, q} = MyQuestions.answer_question(%{id: q.id, answer: "Yes"})

      assert q.answer == "Yes"
      assert q == MyQuestions.get_question(q.id)
    end
  end

  describe "delete_question()" do
    test "Happy case", %{g1: g} do
      question = "Is this a test?"

      {:ok, q} =
        MyQuestions.create_question(%{question: question, guest_id: g.id})

      MyQuestions.delete_question(q.id)

      assert nil == MyQuestions.get_question(q.id)
    end
  end

  describe "list_questions()" do
    test "Happy case", %{g1: g} do
      assert MyQuestions.list_questions() == []

      MyQuestions.create_question(%{
        question: "Is this a test?",
        guest_id: g.id
      })

      MyQuestions.create_question(%{
        question: "Seriously is this a test?",
        guest_id: g.id
      })

      assert length(MyQuestions.list_questions()) == 2
    end

    test "Sort by upvotes", %{g1: g, g2: g2, g3: g3} do
      assert MyQuestions.list_questions() == []

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

      MyQuestions.upvote(%{question_id: q1.id, guest_id: g2.id})
      MyQuestions.upvote(%{question_id: q1.id, guest_id: g3.id})
      MyQuestions.upvote(%{question_id: q0.id, guest_id: g3.id})

      assert MyQuestions.list_questions() |> Enum.map(& &1.id) == [q1.id, q0.id, q2.id]
    end
  end

  describe "upvote()" do
    setup %{g1: g} do
      {:ok, q} =
        MyQuestions.create_question(%{
          question: "Is this a test?",
          guest_id: g.id
        })

      %{q: q}
    end

    test "Happy case", %{g2: g2, g3: g3, q: q} do
      {:ok, :ok} = MyQuestions.upvote(%{question_id: q.id, guest_id: g2.id})

      assert MyQuestions.get_question(q.id).upvotes == 2

      {:ok, :ok} = MyQuestions.upvote(%{question_id: q.id, guest_id: g3.id})

      assert MyQuestions.get_question(q.id).upvotes == 3
    end

    test "Should block duplicate votes", %{g2: g2, q: q} do
      {:ok, :ok} = MyQuestions.upvote(%{question_id: q.id, guest_id: g2.id})

      {:ok, :duplicate_vote} = MyQuestions.upvote(%{question_id: q.id, guest_id: g2.id})

      assert MyQuestions.get_question(q.id).upvotes == 2
    end

    test "Question createion should create a vote", %{g1: g1, q: q} do
      {:ok, :duplicate_vote} = MyQuestions.upvote(%{question_id: q.id, guest_id: g1.id})

      assert MyQuestions.get_question(q.id).upvotes == 1
    end
  end
end
