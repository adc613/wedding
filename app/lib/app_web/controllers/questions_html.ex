defmodule AppWeb.QuestionsHTML do
  use AppWeb, :html

  embed_templates "questions_html/*"

  attr :action, :string, required: false, doc: "action path for forms", default: ""

  attr :submit_action, :string,
    required: true,
    doc: "the phx-submit string"

  attr :guest_id, :string, required: true, doc: "The guest ID of the guest asking a question"

  attr :changeset, :any, required: true, doc: "Guest changeset"
  attr :disabled, :boolean, required: false, doc: "Guest changeset"

  slot :actions
  slot :guest_lookup

  def question_form(assigns) do
    ~H"""
    <.simple_form
      :let={f}
      :if={@guest_id != nil}
      id="question-form"
      for={@changeset}
      phx-submit={@submit_action}
    >
      <.error :if={@changeset.action}>
        Oops, something went wrong! Please check the errors below.
      </.error>
      <.input disabled={@disabled} field={f[:question]} required type="textarea" label="Question" />
      <.button class="btn-action">
        Ask H or A
      </.button>
    </.simple_form>
    <div :if={@guest_id == nil}>
      {render_slot(@guest_lookup)}
    </div>
    """
  end

  attr :question_id, :string, required: true, doc: "The guest ID of the guest asking a question"

  attr :submit_action, :string,
    required: true,
    doc: "the phx-submit string"

  attr :changeset, :any, required: true, doc: "Guest changeset"

  def answer_form(assigns) do
    ~H"""
    <.simple_form :let={f} id="answer-form" for={@changeset} phx-submit={@submit_action}>
      <.error :if={@changeset.action}>
        Oops, something went wrong! Please check the errors below.
      </.error>
      <input name="question_id" required type="hidden" value={@question_id} />
      <.input field={f[:answer]} required type="textarea" label="Answer" />
      <.button class="btn-action">
        Update Answer
      </.button>
    </.simple_form>
    """
  end

  attr :lookup_changeset, :any, required: true, doc: "Guest changeset"
  attr :redirect, :string, required: true, doc: "Redirect path for the lookup"

  def lookup(assigns) do
    ~H"""
    <p>
      Want to ask a question? Enter your phone number and we'll do our best
      to respond soon.
    </p>

    <.simple_form
      :let={f}
      for={@lookup_changeset}
      action={~p"/rsvp/lookup?#{[redirect: @redirect]}"}
      method="post"
    >
      <.input field={f[:phone]} type="tel" inputmode="tel" label="Phone" />
      <:actions>
        <.button class="btn-action">Lookup invitation</.button>
      </:actions>
    </.simple_form>
    """
  end

  attr :question_id, :string,
    required: true,
    doc: "Self explanatory silly"

  attr :click_action, :string,
    required: true,
    doc: "the phx-click string"

  attr :upvotes, :integer,
    required: true,
    doc: "number of upvotes"

  def upvote_btn(assigns) do
    ~H"""
    <div>
      <button
        class="fa fa-solid fa-plus action"
        phx-click={@click_action}
        phx-value-question-id={@question_id}
        data-tooltip="Click to upvote"
      >
      </button>
      <p>
        votes: {@upvotes}
      </p>
    </div>
    """
  end

  attr :question_id, :string,
    required: true,
    doc: "Self explanatory silly"

  attr :click_action, :string,
    required: true,
    doc: "the phx-click string"

  def delete_btn(assigns) do
    ~H"""
    <div>
      <button
        class="fa fa-solid fa-trash action"
        phx-click={show_modal("confirm-delete-q-#{@question_id}")}
        phx-value-question-id={@question_id}
        data-tooltip="Click to delete"
      >
      </button>
    </div>

    <.modal id={"confirm-delete-q-#{@question_id}"}>
      <.header class="mb-4">Are you sure you'd like to Delete Question</.header>
      <.button
        class="btn-action"
        phx-click={JS.push(@click_action) |> hide_modal("confirm-delete-q-#{@question_id}")}
        phx-value-question-id={@question_id}
      >
        Delete
      </.button>
      <.button phx-click={hide_modal("confirm-delete")}>
        Cancel
      </.button>
    </.modal>
    """
  end
end
