defmodule AppWeb.GuestsHTML do
  use AppWeb, :html

  embed_templates "guests_html/*"

  attr :rsvp, :any, required: true, doc: "Render RSVP status"

  def status(assigns) do
    ~H"""
    <div>
      TODO
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

  attr :invitation_id, :string,
    required: false,
    default: nil,
    doc: "The invitaiton the guest should be added to"

  attr :is_kid, :boolean,
    required: false,
    default: nil,
    doc: "Hidden is kid field value"

  attr :inputs, :list,
    required: false,
    default: [:first_name, :last_name, :email, :phone],
    doc: "Input for what fields should be rendered in the guest form."

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
      <input :if={@invitation_id} name="guest[invitation_id]" type="hidden" value={@invitation_id} />
      <input :if={@is_kid} name="guest[is_kid]" type="hidden" value="true" />
      <%= for input <- @inputs do %>
        <.input
          :if={input == :first_name}
          required
          field={f[:first_name]}
          type="text"
          label="First Name"
        />
        <.input
          :if={input == :last_name}
          required
          field={f[:last_name]}
          type="text"
          label="Last Name"
        />
        <.input :if={input == :email} field={f[:email]} type="email" label="Email" inputmode="email" />
        <.input :if={input == :phone} field={f[:phone]} type="tel" label="Phone" inputmode="tel" />
      <% end %>
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

  attr :guests, :any, required: true, doc: "Guest who's emails need to be listed"
  attr :selected, :any, required: true, doc: "Map of selected guest"

  def guest_phones(assigns) do
    ~H"""
    <div>
      {get_phones(@guests, @selected)}
    </div>
    """
  end

  attr :guests, :any, required: true, doc: "List of guests"
  attr :selected, :any, default: nil, doc: "Map of selected guest"

  attr :row_click, :fun,
    default: nil,
    required: false,
    doc: "The function that's called on row click"

  attr :redirect, :string, default: "/guest", doc: "The redirect path for guest links"

  attr :fields, :list,
    required: false,
    default: [:guest, :std, :email, :phone, :links],
    doc: "The included column types"

  attr :checkbox_click, :fun, default: nil, doc: "The function that's called on checkbox click"

  slot :action, required: false

  def guests_table(assigns) do
    ~H"""
    <.table
      id="guests"
      rows={@guests}
      selected={@selected}
      row_click={@row_click}
      checkbox_click={@checkbox_click}
    >
      <:col :let={guest} :for={field <- @fields} label={get_label(field)}>
        <%= if field == :guest do %>
          {guest.first_name} {guest.last_name}
        <% end %>
        <.check_icon :if={field == :std} checked={guest.sent_std} />
        <%= if field == :email do %>
          {guest.email}
        <% end %>
        <p :if={field == :phone}>{guest.phone}</p>
        <.link
          :if={field == :links}
          class="text-blue-500 hover:underline hover:text-blue-600 text-sm"
          href={~p"/guest/#{guest}/edit?#{[redirect: @redirect]}"}
        >
          Edit
        </.link>
      </:col>
      <:col :let={guest} :if={@action} label="Action">
        {render_slot(@action, guest)}
      </:col>
    </.table>
    """
  end

  attr :guests, :list, required: true, doc: "TODO"

  def sms_std_link(assigns) do
    ~H"""
    <a href={sms_link(@guests, :std)}>
      <.button>Open text</.button>
    </a>
    """
  end

  attr :guest, :any, required: true, doc: "TODO"

  def sms_rsvp_reminder_link(assigns) do
    ~H"""
    <a href={sms_link([@guest], :rsvp)}>
      <.button>Send reminder text</.button>
    </a>
    """
  end

  attr :guest, :any, required: true, doc: "TODO"
  attr :invitation, :any, required: true, doc: "TODO"

  def sms_invite_link(assigns) do
    ~H"""
    <%= if @invitation.robey do %>
      <a href={sms_link([@guest], :invite_robey)}>
        <.button>Invite {@guest.first_name} {@guest.last_name}</.button>
      </a>
    <% else %>
      <a href={sms_link([@guest], :invite)}>
        <.button>Invite {@guest.first_name} {@guest.last_name}</.button>
      </a>
    <% end %>
    """
  end

  defp get_label(:guest), do: "Guest"
  defp get_label(:links), do: "Links"
  defp get_label(:email), do: "Email"
  defp get_label(:std), do: "Sent Save the Date"
  defp get_label(:phone), do: "Phone"
  defp get_label(_), do: "Placeholder"

  defp get_phones(guests, selected) do
    guests
    |> Enum.filter(&selected[&1.id])
    |> Enum.map(fn guest ->
      guest.phone
    end)
    |> Enum.join(",")
  end

  defp get_emails(guests, selected) do
    guests
    |> Enum.filter(&selected[&1.id])
    |> Enum.map(fn guest ->
      guest.email
    end)
    |> Enum.join(",")
  end

  defp sms_link(guests, :std) do
    "sms:#{sms_phone(guests)}?body=#{URI.encode(std_text(), &(&1 != ?& and URI.char_unescaped?(&1)))}"
  end

  defp sms_link(guests, :rsvp) do
    "sms:#{sms_phone(guests)}?body=#{URI.encode(rsvp_reminder_text(), &(&1 != ?& and URI.char_unescaped?(&1)))}"
  end

  defp sms_link(guests, :invite) do
    "sms:#{sms_phone(guests)}?body=#{URI.encode(invite_text(:default), &(&1 != ?& and URI.char_unescaped?(&1)))}"
  end

  defp sms_link(guests, :invite_robey) do
    "sms:#{sms_phone(guests)}?body=#{URI.encode(invite_text(:robey), &(&1 != ?& and URI.char_unescaped?(&1)))}"
  end

  defp sms_phone(guests) do
    guests
    |> Enum.filter(&(&1.phone != ""))
    |> Enum.map(& &1.phone)
    |> Enum.join(",")
  end

  defp std_text() do
    """
    https://wedding.adamcollins.io/std

    We’re getting married on April 4th, 2026. Please save the date!

    Note: We’ll share more details including any information about hotel blocks when we send out invites in the coming months. 

    Can't wait to see you in Chicago,
    Helen & Adam
    """
  end

  defp rsvp_reminder_text() do
    """
    Hi,

    We're trying to finalize our guest counts can you respond to your RSVP:

    https://wedding.adamcollins.io/rsvp

    Hope to see you there,
    Helen & Adam
    """
  end

  defp invite_text(:robey) do
    """
    https://wedding.adamcollins.io/rsvp
    Hi,

    You're formally invited to our wedding. Please RSVP at your earliest convenience.

    Once you've RSVP'd you should gain access to The Robey booking link in the travel section. 

    We're asking all our VIPs (you included) to stay at The Robey. If this does not work, please let us know; we are on the hook for a minimum number of rooms.

    Looking forward to seeing you there,
    Helen & Adam
    """
  end

  defp invite_text(_default) do
    """
    https://wedding.adamcollins.io/rsvp
    Hi,

    You're formally invited to our wedding. Please RSVP at your earliest convience.

    Hope to see you there,
    Helen & Adam
    """
  end
end
