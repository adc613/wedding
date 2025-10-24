defmodule AppWeb.FaqLive do
  alias App.Questions.Question
  alias App.Guest.Guest
  alias App.MyQuestions
  use AppWeb, :live_view
  import AppWeb.QuestionsHTML

  def render(assigns) do
    assigns =
      assigns
      |> assign(helen_num: "+17039739638")
      |> assign(adam_num: "+18475626149")
      |> assign(
        reminder_text:
          "https://wedding.adamcollins.io/faq\nWith all do respect, answer your FAQs! Sheesh!!!"
      )

    ~H"""
    <h1 class="text-4xl text-center font-sans mb-8 ">
      Frequently Asked Questions
    </h1>

    <div :if={questions = @questions.ok? && @questions.result} class="gap-1 flex flex-col">
      <div :for={question <- questions} class="question border-2 border-zinc-300 rounded-2xl p-4">
        <div :if={@guest_id} class="gutter">
          <.upvote_btn question_id={question.id} click_action="upvote" upvotes={question.upvotes} />
        </div>
        <div class="content">
          <h2 class="text-xl font-bold font-sans mb-4">{question.question}</h2>
          <p :if={question.answer != ""}>{question.answer}</p>
          <p :if={question.answer == ""}>
            <i>
              Waiting for Helen or Adam to respond...
              <%= if @guest_id != nil do %>
                (<.a type={:phone} phone={@helen_num} body={@reminder_text}>Remind Helen</.a>
                or
                <.a type={:phone} phone={@adam_num} body={@reminder_text}>Remind Adam</.a>)
              <% end %>
            </i>
          </p>
          <div :if={@current_user}>
            <.answer_form
              question_id={question.id}
              changeset={Question.changeset(question, %{})}
              submit_action="answer_question"
            />
          </div>
        </div>
        <div :if={@current_user} class="gutter">
          <.delete_btn question_id={question.id} click_action="delete" />
        </div>
      </div>
    </div>
    <div :if={not @questions.ok?}>
      <div>
        <h2>"Loading questions..."</h2>
      </div>
    </div>
    <.question_form
      guest_id={@guest_id}
      submit_action="create_question"
      changeset={@question_changeset}
      disabled={not @questions.ok?}
    >
      <:guest_lookup>
        <.lookup lookup_changeset={@guest_changeset} redirect="/faq" />
      </:guest_lookup>
    </.question_form>
    """
  end

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(guest_id: socket.assigns.insecure_guest_id)
      |> assign(question_changeset: Question.changeset(%Question{}, %{}))
      |> assign(guest_changeset: Guest.lookup_changeset(%Guest{}))
      |> assign_questions()
      |> assign_async([:questions], fn ->
        {:ok,
         %{
           questions: MyQuestions.list_questions()
         }}
      end)
    }
  end

  def handle_event("delete", %{"question-id" => qid}, socket) do
    MyQuestions.delete_question(qid)

    {:noreply, socket |> assign_questions() |> put_flash(:info, "Deleted question")}
  end

  def handle_event("upvote", %{"question-id" => qid}, socket) do
    gid = socket.assigns.guest_id

    MyQuestions.upvote(%{question_id: qid, guest_id: gid})
    |> case do
      {:ok, :ok} -> {:noreply, socket |> assign_questions() |> put_flash(:info, "Upvoted")}
      {:ok, :duplicate_vote} -> {:noreply, socket |> put_flash(:error, "You can only vote once")}
      _ -> {:noreply, socket}
    end
  end

  def handle_event(
        "answer_question",
        %{"question" => %{"answer" => answer}, "question_id" => id},
        socket
      ) do
    {:ok, _q} = MyQuestions.answer_question(%{id: id, answer: answer})

    {
      :noreply,
      socket |> assign_questions() |> put_flash(:info, "Updated answer")
    }
  end

  def handle_event("create_question", %{"question" => params}, socket) do
    gid = socket.assigns.guest_id

    {:ok, _q} = MyQuestions.create_question(%{question: params["question"], guest_id: gid})

    {
      :noreply,
      socket
      |> assign(question_changeset: Question.changeset(%Question{}, %{}))
      |> assign_questions()
    }
  end

  defp assign_questions(socket) do
    socket
    |> assign_async([:questions], fn ->
      {:ok,
       %{
         questions: MyQuestions.list_questions()
       }}
    end)
  end
end
