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
    <.button phx-click={show_modal("invitaiton-modal")}>Create invitation</.button>

    <.table
      :if={invitations = @invitations.ok? && @invitations.result}
      id="guests"
      rows={invitations}
      selected={@selected}
      row_click={fn invitation -> toggle_invitation(invitation) end}
      checkbox_click={fn invitation -> toggle_invitation(invitation) end}
    >
      <:col :let={invitation} label="Invitation ID">{invitation.id}</:col>
    </.table>

    <.modal id="invitaiton-modal">
      <.header class="mb-4">Are you sure you'd like to Delete Invitaitons</.header>
      <.guests_table
        :if={guests = @guests.ok? && @guests.result}
        guests={guests}
        selected={@selected_guest}
        row_click={fn guest -> toggle_guest(guest) end}
        checkbox_click={fn guest -> toggle_guest(guest) end}
      />
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

    <.modal id="confirm-delete">
      <.header class="mb-4">Are you sure you'd like to Delete Invitaitons</.header>
      <ul :if={@invitations.ok?} class="list-disc ml-4 mb-8">
        <%= for invitation <- @invitations.result do %>
          <li :if={@selected[invitation.id]}>{invitation.id}</li>
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
      |> assign(:changeset, Invitation.changeset(%Invitation{}))
      |> assign_async(:guests, fn ->
        {:ok, %{guests: MyGuest.list_guests()}}
      end)
      |> assign_async(:invitations, fn ->
        {:ok, %{invitations: MyGuest.list_invitations(preload: :guests)}}
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

  def handle_event("toggle_guests", %{"id" => id}, socket) do
    {
      :noreply,
      socket
      |> update(:selected_guest, &toggle(&1, id))
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
