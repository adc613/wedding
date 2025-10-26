defmodule AppWeb.InvitationHTML do
  use AppWeb, :html
  import AppWeb.GuestsHTML
  embed_templates "invitation_html/*"

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

  def invitation_form(assigns) do
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
      <.input field={f[:additional_guests]} type="number" label="Additional Guests" />
      <.input field={f[:permit_kids]} type="checkbox" label="Permit kids" />
      <.input field={f[:brunch]} id="brunch" type="checkbox" label="Brunch" />
      <.input field={f[:rehersal]} id="rehersal" type="checkbox" label="Rehearsal" />
      <.input field={f[:wedding]} id="rehersal" type="checkbox" label="Wedding" />
      <.input field={f[:robey]} id="robey" type="checkbox" label="Robey group" />
      {render_slot(@actions)}
    </.simple_form>
    """
  end

  attr :invitation, :any, required: true, doc: "The display name for an inviation"

  def invitation_display(assigns) do
    ~H"""
    <%= for guest <- Enum.intersperse(@invitation.guests, :seperator) do %>
      <%= if guest == :seperator do %>
        |
      <% else %>
        {guest.first_name} {guest.last_name}
      <% end %>
    <% end %>
    """
  end
end
