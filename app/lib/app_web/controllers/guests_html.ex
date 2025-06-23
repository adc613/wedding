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
      <.input field={f[:email]} type="email" label="Email" inputmode="email" />
      <.input field={f[:phone]} type="tel" label="Phone" inputmode="tel" />
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
  attr :selected, :any, required: true, doc: "Map of selected guest"
  attr :row_click, :fun, required: false, doc: "The function that's called on row click"
  attr :redirect, :string, default: "/guest", doc: "The rediret path for guest links"

  attr :fields, :list,
    required: false,
    default: [:guest, :std, :email, :phone, :links],
    doc: "The included column types"

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
    </.table>
    """
  end

  attr :guests, :list, required: true, doc: "TODO"

  def sms_std_link(assigns) do
    ~H"""
    <a href={sms_link(@guests)}>
      <.button>Open text</.button>
    </a>
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

  defp sms_link(guests) do
    "sms:#{sms_phone(guests)}?body=#{URI.encode(sms_body(), &(&1 != ?& and URI.char_unescaped?(&1)))}"
  end

  defp sms_phone(guests) do
    guests
    |> Enum.filter(&(&1.phone != ""))
    |> Enum.map(& &1.phone)
    |> Enum.join(",")
  end

  defp sms_body() do
    """
    https://wedding.adamcollins.io/std

    We’re getting married on April 4th, 2026. Please save the date!

    Note: We’ll share more details including any information about hotel blocks when we send out invites in the coming months. 

    Can't wait to see you in Chicago,
    Helen & Adam
    """
  end
end
