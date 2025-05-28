defmodule AppWeb.RSVPHTML do
  use AppWeb, :html
  import AppWeb.PageHTML

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
    <div class="flex gap-8">
      <h2 class="text-lg font-semibold">{@guest.first_name} {@guest.last_name}</h2>
      <div class="flex flex-col">
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
    <div class="flex flex-col items-center gap-8 rounded-2xl border-2 p-4 mb-8">
      <div class="border-b-2 text-center">
        <h2 class="text-xl font-semibold">{@group_name}</h2>
        {render_slot(@inner_block)}
      </div>

      <div>
        <%= for guest <- @guests do %>
          <.response_input name={@name <> "-" <> to_string(guest.id)} guest={guest} />
          <br />
        <% end %>
      </div>
    </div>
    """
  end
end
