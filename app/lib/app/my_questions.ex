defmodule App.MyQuestions do
  alias App.Repo

  alias App.Questions.Question
  alias App.Questions.Vote
  # alias App.Guest.Guest

  def create_question(%{question: q, guest_id: gid}) do
    {:ok, question} =
      Question.changeset(%Question{}, %{"question" => q, "guest_id" => gid})
      |> Repo.insert()

    upvote(%{question_id: question.id, guest_id: gid})

    {:ok, Repo.get(Question, question.id)}
  end

  def get_question(id) do
    Repo.get(Question, id)
  end

  def get_question!(id) do
    Repo.get!(Question, id)
  end

  def list_questions() do
    Repo.all(Question)
    |> Enum.sort_by(& &1.upvotes, :desc)
  end

  def answer_question(%{id: id, answer: answer}) do
    Repo.get(Question, id)
    |> Question.changeset(%{"answer" => answer})
    |> Repo.update()
  end

  def delete_question(id) do
    get_question(id) |> Repo.delete()
  end

  def upvote(%{question_id: qid, guest_id: gid}) do
    Repo.transaction(fn ->
      Vote.changeset(%Vote{}, %{"question_id" => qid, "guest_id" => gid})
      |> Repo.insert(on_conflict: :nothing)
      |> case do
        {:ok, %Vote{id: nil}} -> :duplicate_vote
        {:ok, _vote} -> :ok
        {:error, err} -> {:error, err}
      end
      |> case do
        :ok -> Repo.get(Question, qid)
        other -> other
      end
      |> case do
        %Question{} = q -> Question.changeset(q, %{"upvotes" => q.upvotes + 1}) |> Repo.update()
        other -> other
      end
      |> case do
        {:ok, _q} -> :ok
        other -> other
      end
    end)
  end
end
