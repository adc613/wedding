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
    <h2 class="text-lg font-semibold mt-4">RSVPs</h2>
    <.scorecards cards={build_rsvp_cards(@invitations)} />
    <h2 class="text-lg font-semibold mt-4">Invites</h2>
    <.scorecards cards={build_invite_cards(@invitations)} />
    <h2 class="text-lg font-semibold">Database</h2>
    <.scorecards cards={build_guest_cards(@guests, @invitations)} />
    <%= if @need_std.ok? do %>
      <h2 class="text-lg font-semibold mt-8">STDs</h2>
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

    <%= if @need_rsvp.ok? do %>
      <h2 class="text-lg font-semibold mt-8">Pending RSVPs</h2>
      <%= if length(@need_rsvp.result) == 0 do %>
        <p>All Sent!</p>
      <% else %>
        <div>
          <div :for={guest <- @need_rsvp.result} class="flex justify-between mb-4">
            <div>
              {guest.first_name} {guest.last_name}
            </div>
            <div class="flex-grow-0">
              <.sms_rsvp_reminder_link guest={guest} />
            </div>
          </div>
        </div>
      <% end %>
    <% end %>
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

  defp build_guest_cards(guests, invitations) do
    [
      build_guest_count(guests),
      build_plus_one_count(invitations),
      build_invite_count(invitations),
      build_kid_invite_count(invitations)
    ]
    |> Enum.filter(&(&1 != nil))
  end

  defp build_guest_count(%AsyncResult{ok?: false}), do: nil

  defp build_guest_count(%AsyncResult{ok?: true, result: guests}) do
    %{
      title: "Guests",
      info: length(guests)
    }
  end

  defp build_plus_one_count(%AsyncResult{ok?: false}), do: nil

  defp build_plus_one_count(%AsyncResult{ok?: true, result: invitations}) do
    %{
      title: "Additional guests",
      info: count_additionals(invitations)
    }
  end

  defp build_kid_invite_count(%AsyncResult{ok?: false}), do: nil

  defp build_kid_invite_count(%AsyncResult{ok?: true, result: invitations}) do
    %{
      title: "Invitations w/ Kids",
      info: invitations |> Enum.filter(& &1.permit_kids) |> Enum.count()
    }
  end

  defp build_invite_count(%AsyncResult{ok?: false}), do: nil

  defp build_invite_count(%AsyncResult{ok?: true, result: invitations}) do
    %{
      title: "Invites",
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
    |> then(&Map.put(&1, :outstanding, &1.total - &1.wedding))
    |> then(fn counts ->
      [
        %{
          title: "Responses",
          info: to_string(counts.outstanding) <> " / " <> to_string(counts.total)
        },
        %{
          title: "Wedding",
          info: counts.wedding
        },
        %{
          title: "Brunch",
          info: counts.brunch
        },
        %{
          title: "Rehearsal",
          info: counts.rehersal
        }
      ]
    end)
  end

  defp assign_guests(conn) do
    conn
    |> assign_async([:guests, :need_std, :need_rsvp], fn ->
      guests = MyGuest.list_guests()
      need_std = Enum.filter(guests, &(not &1.sent_std))
      need_rsvp = Enum.filter(guests, &(&1.rsvp == nil))
      {:ok, %{guests: guests, need_std: need_std, need_rsvp: need_rsvp}}
    end)
  end

  defp build_invite_cards(%AsyncResult{ok?: false}), do: []

  defp build_invite_cards(%AsyncResult{ok?: true, result: invitations}) do
    MyGuest.load(invitations, preload: [guests: [:rsvp]])
    |> Enum.map(&Invitation.count_invites(&1))
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
          title: "Wedding",
          info: counts.wedding
        },
        %{
          title: "Rehearsal",
          info: counts.rehersal
        },
        %{
          title: "Brunch",
          info: counts.brunch
        }
      ]
    end)
  end

  defp count_additionals(invitations),
    do: invitations |> Enum.map(& &1.additional_guests) |> Enum.sum()
end
