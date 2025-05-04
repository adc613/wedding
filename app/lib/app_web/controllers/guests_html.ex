defmodule AppWeb.GuestsHTML do
  use AppWeb, :html

  embed_templates "guests_html/*"

  attr :rsvp, :any, required: true, doc: "Render RSVP status"

  def status(assigns) do
    rsvp =
      case assigns.rsvp do
        %{confirmed: true} -> :yes
        %{confirmed: false} -> :no
        nil -> :not_responded
      end

    assigns = assign(assigns, :rsvp, rsvp)

    ~H"""
    <div>
      <span :if={@rsvp == :yes}>Yes</span>
      <span :if={@rsvp == :no}>No</span>
      <span :if={@rsvp == :not_responded}>No response</span>
    </div>
    """
  end

  attr :action, :string, required: false, doc: "action path for forms", default: ""
  attr :changeset, :any, required: true, doc: "Guest changeset"

  def guest_form(assigns) do
    ~H"""
    <.simple_form :let={f} for={@changeset} phx-submit="guest_submit" action={@action || ""}>
      <.error :if={@changeset.action}>
        Oops, something went wrong! Please check the errors below.
      </.error>
      <.input field={f[:first_name]} type="text" label="First Name" />
      <.input field={f[:last_name]} type="text" label="Last Name" />
      <.input field={f[:email]} type="text" label="Email" />
      <.input field={f[:rehersal_dinner]} type="checkbox" label="Invite to rehersal dinner" />
      <.input field={f[:brunch]} type="checkbox" label="Invite to brunch" />
      <:actions>
        <.button class="btn-action">Save Guest</.button>
      </:actions>
    </.simple_form>
    """
  end
end
