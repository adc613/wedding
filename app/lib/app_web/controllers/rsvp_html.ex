defmodule AppWeb.RSVPHTML do
  use AppWeb, :html
  import AppWeb.PageHTML
  import AppWeb.GuestsHTML

  embed_templates "rsvp_html/*"

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

  attr :name, :string, required: true, doc: "Name of the response input"
  attr :guest, :any, required: true, doc: "Guest that are being answer for"
  attr :event, :any, required: true

  def response_input(assigns) do
    ~H"""
    <div class="w-full p-4 rounded-xl border-2 rounded-2xl">
      <.radio_group
        legend={@guest.first_name <> " " <> @guest.last_name}
        name={@name}
        options={[yes: "Will be attending", no: "Regretfully, declines"]}
        current_value={
          cond do
            @guest.rsvp == nil -> nil
            @event in @guest.rsvp.events -> :yes
            @event in @guest.rsvp.declined_events -> :no
            true -> nil
          end
        }
      />
    </div>
    """
  end

  attr :guests, :any, required: true, doc: "Guest that are being answer for"
  attr :event, :atom, required: true

  def response(assigns) do
    ~H"""
    <.event_group event={@event} full_width_footer={true}>
      <:footer>
        <%= for guest <- @guests do %>
          <.response_input
            event={@event}
            name={Atom.to_string(@event) <> "-" <> to_string(guest.id)}
            guest={guest}
          />
          <br />
        <% end %>
      </:footer>
    </.event_group>
    """
  end

  attr :header, :string, required: true
  attr :step_id, :integer, required: true
  attr :hide_next, :boolean, default: false
  slot :inner_block, required: true
  slot :action, required: false

  def confirmation_step(assigns) do
    ~H"""
    <div class="rounded-2xl border-zinc-300 border-2 p-4">
      <h2 class="text-lg mt-2 mb-4 font-semibold">{@header}</h2>
      <div>
        {render_slot(@inner_block)}
      </div>
      <div :if={not @hide_next or @action} class="mt-8 flex justify-between">
        <div :if={@action}>
          {render_slot(@action)}
        </div>
        <div :if={not @hide_next}>
          <.link href={~p"/rsvp/confirm/#{@step_id + 1}"}>
            <.button>
              Next
            </.button>
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
