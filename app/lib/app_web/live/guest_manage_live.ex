defmodule AppWeb.GuestManageLive do
  alias App.Guest
  alias App.Guest
  alias App.Guest.Guest
  alias App.MyGuest
  use AppWeb, :live_view
  import AppWeb.GuestsHTML

  def render(assigns) do
    ~H"""
    <.header class="text-center mb-8">
      Admin page
      <:subtitle>Manage guest</:subtitle>
    </.header>

    <.button phx-click={show_modal("add-guest-modal")}>Add guest</.button>
    <.button phx-click={show_modal("confirm-delete")}>Delete selected</.button>
    <.button phx-click={show_modal("std-modal")}>Send Save the Dates</.button>

    <.guests_table
      :if={guests = @guests.ok? && @guests.result}
      guests={guests}
      selected={@selected}
      row_click={fn guest -> toggle_guest(guest) end}
      checkbox_click={fn guest -> toggle_guest(guest) end}
    />

    <.modal id="add-guest-modal">
      <.guest_form
        :if={changeset = @changeset.ok? && @changeset.result}
        changeset={changeset}
        submit_action="guest_submit"
      >
        <:actions>
          <.button class="btn-action" phx-click={hide_modal("add-guest-modal")}>
            Add
          </.button>
        </:actions>
      </.guest_form>
    </.modal>

    <.modal id="confirm-delete">
      <.header class="mb-4">Are you sure you'd like to Delete Guest</.header>
      <ul :if={@guests.ok?} class="list-disc ml-4 mb-8">
        <%= for guest <- @guests.result do %>
          <li :if={@selected[guest.id]}>{guest.first_name} {guest.last_name}</li>
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

    <.modal id="std-modal">
      <.header class="mb-4">Send save the dates to:</.header>
      <ul :if={@guests.ok?} class="list-disc ml-4 mb-8">
        <%= for guest <- @guests.result do %>
          <li :if={@selected[guest.id]}>{guest.first_name} {guest.last_name}</li>
        <% end %>
      </ul>
      <h2 class="text-lg mb-4 mt-8  font-semibold leading-8 text-zinc-800">
        Recipients
      </h2>
      <p class="mb-8">
        <.guest_emails :if={@guests.ok?} guests={@guests.result} selected={@selected} />
      </p>
      <h2 class="text-lg mb-4 mt-8 font-semibold leading-8 text-zinc-800">
        Subject
      </h2>
      <p>[Helen & Adam Wedding] Save the Date 2026-04-04</p>
      <h2 class="text-lg mb-4 mt-8 font-semibold leading-8 text-zinc-800">
        Body
      </h2>
      <p class="max-w-2xl mb-4">
        Hi, <br /> <br /> We've got a venue. Save the date. <br /> <br />
        <a href="http://wedding.adamcollins.io">http://wedding.adamcollins.io</a> <br /> <br />
        Hope to see you on 2026.04.04, <br /> <br /> Helen & Adam <br />
      </p>
      <.button class="btn-action" phx-click={JS.push("mark_sent") |> hide_modal("std-modal")}>
        Mark Sent
      </.button>

      <.button phx-click={hide_modal("std-modal")}>
        Cancel
      </.button>
    </.modal>
    """
  end

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:hello, "world")
      |> assign(:selected, %{})
      |> assign_async([:guests, :changeset], fn ->
        {:ok,
         %{
           guests: MyGuest.list_guests(),
           changeset:
             Guest.changeset(%Guest{
               first_name: "Test",
               last_name: "User",
               email: "adc613@gmail.com"
             })
         }}
      end),
      layout: {AppWeb.Layouts, :admin}
    }
  end

  def handle_event("mark_sent", _value, socket) do
    selected = socket.assigns.selected

    {
      :noreply,
      socket
      |> assign(:selected, %{})
      |> assign_async(:guests, fn ->
        selected
        |> Map.to_list()
        |> Enum.filter(fn {_key, value} -> value end)
        |> Enum.map(fn {key, _value} -> MyGuest.get_guest!(key) end)
        |> Enum.map(&MyGuest.mark_sent!(&1))

        {:ok, %{guests: MyGuest.list_guests()}}
      end)
    }
  end

  def handle_event("delete_selected", _value, socket) do
    selected = socket.assigns.selected

    {
      :noreply,
      socket
      |> assign(:selected, %{})
      |> assign_async(:guests, fn ->
        selected
        |> Map.to_list()
        |> Enum.filter(fn {_key, value} -> value end)
        |> Enum.map(fn {key, _value} -> MyGuest.get_guest!(key) end)
        |> Enum.map(&MyGuest.delete(&1))

        {:ok, %{guests: MyGuest.list_guests()}}
      end)
    }
  end

  def handle_event("toggle_guest", %{"id" => id}, socket) do
    {
      :noreply,
      socket
      |> update(:selected, &toggle(&1, id))
    }
  end

  def handle_event("guest_submit", %{"guest" => guest_params}, socket) do
    {
      :noreply,
      socket
      |> assign_async([:guests, :changeset], fn ->
        case MyGuest.create_guest(guest_params) do
          {:ok, _} ->
            {:ok,
             %{
               guests: MyGuest.list_guests(),
               changeset:
                 Guest.changeset(%Guest{
                   first_name: "",
                   last_name: "",
                   email: ""
                 })
             }}

          {:error, _} ->
            {:ok, %{}}
        end
      end)
    }
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
