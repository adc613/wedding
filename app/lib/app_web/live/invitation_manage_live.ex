defmodule AppWeb.InvitationManageLive do
  alias App.Guest.Invitation
  alias App.MyGuest
  use AppWeb, :live_view
  import AppWeb.GuestsHTML

  def render(assigns) do
    ~H"""
    <.header class="text-center mb-8">
      Admin page
      <:subtitle>Manage invitations</:subtitle>
    </.header>

    <.button phx-click={show_modal("confirm-delete")}>Delete selected</.button>
    <.button id="create-invitation-btn" phx-click={show_modal("invitation-modal")}>
      Create invitation
    </.button>

    <.table
      :if={invitations = @invitations.ok? && @invitations.result}
      id="invitations"
      rows={invitations}
      selected={@selected}
      row_click={fn invitation -> toggle_invitation(invitation) end}
      checkbox_click={fn invitation -> toggle_invitation(invitation) end}
    >
      <:col :let={invitation} label="Guests">
        <%= for guest <- Enum.intersperse(invitation.guests, :seperator) do %>
          <%= if guest == :seperator do %>
            |
          <% else %>
            {guest.first_name} {guest.last_name}
          <% end %>
        <% end %>
      </:col>
      <:col :let={invitation} label="Rehersal">
        <.check_icon checked={:rehersal in invitation.events} />
      </:col>
      <:col :let={invitation} label="Wedding">
        <.check_icon checked={:wedding in invitation.events} />
      </:col>
      <:col :let={invitation} label="Brunch">
        <.check_icon checked={:brunch in invitation.events} />
      </:col>
    </.table>

    <.modal id="invitation-modal">
      <.header class="mb-4">Who would are you inviting?</.header>
      <.guests_table
        :if={guests = @guests.ok? && @guests.result}
        guests={guests}
        selected={@selected_guests}
        row_click={fn guest -> toggle_guest(guest) end}
        checkbox_click={fn guest -> toggle_guest(guest) end}
      />
      <.header class="mb-4">What events</.header>
      <div class="mb-4">
        <.form for={@invite_form} id="invite_form" phx-change="form_change">
          <.input field={@invite_form[:brunch]} id="brunch" type="checkbox" />
          <label for="brunch">
            Brunch
          </label>
          <.input field={@invite_form[:rehersal]} id="rehersal" type="checkbox" />
          <label for="rehersal">
            Rehersal
          </label>
        </.form>
      </div>
      <div>
        <.button
          class="btn-action"
          phx-click={JS.push("create_invite") |> hide_modal("invitation-modal")}
        >
          Create
        </.button>
        <.button phx-click={hide_modal("invitation-modal")}>
          Cancel
        </.button>
      </div>
    </.modal>

    <.modal id="confirm-delete">
      <.header class="mb-4">Are you sure you'd like to Delete Invitaitons</.header>
      <ul :if={@invitations.ok?} class="list-disc ml-4 mb-8">
        <%= for invitation <- @invitations.result do %>
          <li :if={@selected[invitation.id]}>
            <%= for guest <- Enum.intersperse(invitation.guests, :seperator) do %>
              <%= if guest == :seperator do %>
                |
              <% else %>
                {guest.first_name} {guest.last_name}
              <% end %>
            <% end %>
          </li>
        <% end %>
      </ul>
      <.button
        class="btn-action"
        phx-click={JS.push("delete_selected") |> hide_modal("confirm-delete")}
      >
        Delete
      </.button>
      <.button phx-click={hide_modal("confirm-delete")}>
        Cancel
      </.button>
    </.modal>
    """
  end

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:selected, %{})
      |> assign(:selected_guests, %{})
      |> assign(:invite_form, to_form(%{"brunch" => false, "rehersal" => false}))
      |> assign(:changeset, Invitation.changeset(%Invitation{}))
      |> assign(:events, %{brunch: false, rehersal: false})
      |> assign_async(:invitations, fn ->
        {:ok, %{invitations: MyGuest.list_invitations(preload: :guests)}}
      end)
      |> assign_async(:guests, fn ->
        {:ok, %{guests: MyGuest.list_guests()}}
      end),
      layout: {AppWeb.Layouts, :admin}
    }
  end

  def handle_event("toggle_invitation", %{"id" => id}, socket) do
    {
      :noreply,
      socket
      |> update(:selected, &toggle(&1, id))
    }
  end

  def handle_event("toggle_guest", %{"id" => id}, socket) do
    {
      :noreply,
      socket
      |> update(:selected_guests, &toggle(&1, id))
    }
  end

  def handle_event("form_change", %{"brunch" => brunch, "rehersal" => rehersal}, socket) do
    {
      :noreply,
      socket
      |> update(:events, &Map.put(&1, :brunch, brunch))
      |> update(:events, &Map.put(&1, :rehersal, rehersal))
    }
  end

  def handle_event("create_invite", _data, socket) do
    %{selected_guests: selected_guests, events: events_map} = socket.assigns

    ids =
      Map.to_list(selected_guests)
      |> Enum.filter(fn {_key, value} ->
        value
      end)
      |> Enum.map(fn {key, _value} ->
        key
      end)

    {
      :noreply,
      socket
      |> assign_async([:invitations], fn ->
        guests = ids |> Enum.map(&MyGuest.get_guest(&1))

        events =
          [
            :brunch,
            :rehersal
          ]
          |> Enum.filter(&(events_map[&1] == "true"))

        result =
          MyGuest.create_invitation(
            guests: guests,
            events: [:wedding | events]
          )

        {result,
         %{
           invitations: MyGuest.list_invitations(preload: :guests)
         }}
      end)
    }
  end

  def handle_event("delete_selected", _params, socket) do
    %{selected: selected} = socket.assigns

    {
      :noreply,
      socket
      |> assign_async(:invitations, fn ->
        selected
        |> Map.keys()
        |> Enum.filter(&selected[&1])
        |> Enum.map(&MyGuest.get_invitation(&1))
        |> Enum.each(&MyGuest.delete(&1))

        {:ok, %{invitations: MyGuest.list_invitations()}}
      end)
    }
  end

  defp toggle_invitation(invitation) do
    %JS{}
    |> JS.push("toggle_invitation", value: %{id: invitation.id})
  end

  defp toggle_guest(guest) do
    %JS{}
    |> JS.push("toggle_guest", value: %{id: guest.id})
  end

  defp toggle(selected, id) do
    new_value = not Map.get(selected, id, false)
    Map.put(selected, id, new_value)
  end
end
