defmodule AppWeb.DashboardLive do
  alias App.Guest.Invitation
  alias Phoenix.LiveView.AsyncResult
  alias App.MyGuest
  use AppWeb, :live_view
  import AppWeb.GuestsHTML

  def render(assigns) do
    ~H"""
    <.header class="text-center mb-8">
      Admin page
      <:subtitle>Dashboard</:subtitle>
    </.header>
    <%= if @need_std.ok? do %>
      <h2 class="text-lg font-semibold">STDs</h2>
      <%= if length(@need_std.result) == 0 do %>
        <p>All Sent!</p>
      <% else %>
        <div>
          <div :for={guest <- @need_std.result} class="flex justify-between mb-4">
            <div>
              {guest.first_name} {guest.last_name}
            </div>
            <div class="flex-grow-0">
              <.button
                class="mr-8 btn-action"
                phx-click={JS.push("mark_sent", value: %{id: guest.id})}
              >
                Mark Sent
              </.button>
              <.sms_std_link guests={[guest]} />
            </div>
          </div>
        </div>
      <% end %>
    <% end %>
    <h2 class="text-lg font-semibold">Guest Info</h2>
    <.scorecards cards={build_cards(@guests, @invitations)} />
    <h2 class="text-lg font-semibold">RSVPs</h2>
    <.scorecards cards={build_rsvp_cards(@invitations)} />
    """
  end

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign_guests()
      |> assign_async([:invitations], fn ->
        invitations = MyGuest.list_invitations()
        {:ok, %{invitations: invitations}}
      end),
      layout: {AppWeb.Layouts, :admin}
    }
  end

  def handle_event("mark_sent", %{"id" => id}, socket) do
    guest = Enum.find(socket.assigns.guests.result, &(&1.id == id))
    MyGuest.mark_sent!(guest)

    {
      :noreply,
      socket |> assign_guests()
    }
  end

  defp build_cards(guests, invitations) do
    [build_guest_count(guests), build_invite_count(invitations)]
    |> Enum.filter(&(&1 != nil))
  end

  defp build_guest_count(%AsyncResult{ok?: false}), do: nil

  defp build_guest_count(%AsyncResult{ok?: true, result: guests}) do
    %{
      title: "Guest count",
      info: length(guests)
    }
  end

  defp build_invite_count(%AsyncResult{ok?: false}), do: nil

  defp build_invite_count(%AsyncResult{ok?: true, result: invitations}) do
    %{
      title: "Invite count",
      info: length(invitations)
    }
  end

  defp build_rsvp_cards(%AsyncResult{ok?: false}), do: []

  defp build_rsvp_cards(%AsyncResult{ok?: true, result: invitations}) do
    MyGuest.load(invitations, preload: [guests: [:rsvp]])
    |> Enum.map(&Invitation.count_rsvps(&1))
    |> Enum.reduce(fn acc, counts ->
      %{
        total: acc.total + counts.total,
        wedding: acc.wedding + counts.wedding,
        brunch: acc.brunch + counts.brunch,
        rehersal: acc.rehersal + counts.rehersal
      }
    end)
    |> then(fn counts ->
      [
        %{
          title: "Total Guest Invite",
          info: counts.total
        },
        %{
          title: "Yes to Wedding",
          info: counts.wedding
        },
        %{
          title: "Yes to Brunch",
          info: counts.brunch
        },
        %{
          title: "Yes to Rehersal",
          info: counts.rehersal
        }
      ]
    end)
  end

  defp assign_guests(conn) do
    conn
    |> assign_async([:guests, :need_std], fn ->
      guests = MyGuest.list_guests()
      need_std = Enum.filter(guests, &(not &1.sent_std))
      {:ok, %{guests: guests, need_std: need_std}}
    end)
  end
end
