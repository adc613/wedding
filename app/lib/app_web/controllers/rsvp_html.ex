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

  def response_input(assigns) do
    ~H"""
    <div class="w-full flex flex-col gap-8 justify-between p-4 rounded-xl border-2 rounded-2xl">
      <h2 class="text-lg font-semibold m-auto">
        {@guest.first_name} {@guest.last_name}
      </h2>
      <div class="flex flex-col gap-8">
        <div>
          <input type="radio" required name={@name} value={:yes} />
          <label> Will be attending</label>
        </div>
        <div>
          <input type="radio" required name={@name} value={:no} />
          <label> Regretfully, declines</label>
        </div>
      </div>
    </div>
    """
  end

  attr :guests, :any, required: true, doc: "Guest that are being answer for"
  attr :name, :string, required: true, doc: "Name of the response input"
  attr :group_name, :string, required: true, doc: "Title for the group"

  slot :inner_block, required: true

  def response(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-8 rounded-2xl border-2 p-4 mb-8  border-zinc-300">
      <div class="border-b-2 text-center">
        <h2 class="text-xl font-semibold">{@group_name}</h2>
        {render_slot(@inner_block)}
      </div>

      <div class="w-full">
        <%= for guest <- @guests do %>
          <.response_input name={@name <> "-" <> to_string(guest.id)} guest={guest} />
          <br />
        <% end %>
      </div>
    </div>
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
