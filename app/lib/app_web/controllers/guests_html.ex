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

  attr :submit_action, :string,
    required: false,
    default: "guest_submit",
    doc: "the phx-submit string"

  attr :redirect, :string,
    required: false,
    default: nil,
    doc: "Redirect path for post form submission"

  attr :changeset, :any, required: true, doc: "Guest changeset"
  slot :actions

  def guest_form(assigns) do
    ~H"""
    <.simple_form
      :let={f}
      id="guest-form"
      for={@changeset}
      phx-submit={@submit_action}
      action={@action || ""}
    >
      <.error :if={@changeset.action}>
        Oops, something went wrong! Please check the errors below.
      </.error>
      <input :if={@redirect} type="hidden" name="redirect" value={@redirect} />
      <.input field={f[:first_name]} type="text" label="First Name" />
      <.input field={f[:last_name]} type="text" label="Last Name" />
      <.input field={f[:email]} type="text" label="Email" />
      {render_slot(@actions)}
    </.simple_form>
    """
  end

  attr :guests, :any, required: true, doc: "Guest who's emails need to be listed"
  attr :selected, :any, required: true, doc: "Map of selected guest"

  def guest_emails(assigns) do
    ~H"""
    <div>
      {get_emails(@guests, @selected)}
    </div>
    """
  end

  attr :guests, :any, required: true, doc: "List of guests"
  attr :selected, :any, required: true, doc: "Map of selected guest"
  attr :row_click, :fun, required: false, doc: "The function that's called on row click"

  attr :checkbox_click, :fun, doc: "The function that's called on checkbox click"

  def guests_table(assigns) do
    ~H"""
    <.table
      id="guests"
      rows={@guests}
      selected={@selected}
      row_click={@row_click}
      checkbox_click={@checkbox_click}
    >
      <:col :let={guest} label="Guest">{guest.first_name} {guest.last_name}</:col>
      <:col :let={guest} label="Email">{guest.email}</:col>
      <:col :let={guest} label="Sent Save the Date">
        <.check_icon checked={guest.sent_std} />
      </:col>
      <:col :let={guest} label="Links">
        <.link
          class="text-blue-500 hover:underline hover:text-blue-600 text-sm"
          href={~p"/guest/#{guest}/edit?#{[redirect: ~p"/guest"]}"}
        >
          Edit
        </.link>
      </:col>
    </.table>
    """
  end

  defp get_emails(guests, selected) do
    guests
    |> Enum.filter(&selected[&1.id])
    |> Enum.map(fn guest ->
      guest.email
    end)
    |> Enum.join(",")
  end
end
