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
      <p
        :if={@new_guest != nil and @new_guest.ok?}
        class="mr-2 rounded-lg p-3 ring-1 bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900"
      >
        Successfully created {@new_guest.result.first_name} {@new_guest.result.last_name}
      </p>
      <.flash_group id="modal" flash={@flash} />
      <.guest_form
        :if={changeset = @changeset.ok? && @changeset.result}
        changeset={changeset}
        submit_action="guest_submit"
      >
        <:actions>
          <.button class="btn-action">
            Add
          </.button>
          <.button type="reset" phx-click={hide_modal("add-guest-modal")}>
            Close
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
        Emails
      </h2>
      <p class="mb-8">
        <.guest_emails :if={@guests.ok?} guests={@guests.result} selected={@selected} />
      </p>
      <h2 class="text-lg mb-4 mt-8  font-semibold leading-8 text-zinc-800">
        Phones
      </h2>
      <p class="mb-8">
        <.guest_phones :if={@guests.ok?} guests={@guests.result} selected={@selected} />
      </p>
      <h2 class="text-lg mb-4 mt-8 font-semibold leading-8 text-zinc-800">
        Subject
      </h2>
      <p>[Helen & Adam Wedding] Save the Date 2026-04-04</p>
      <h2 class="text-lg mb-4 mt-8 font-semibold leading-8 text-zinc-800">
        Body
      </h2>
      <pre class="max-w-2xl mb-4 overflow-scroll">
        {sms_body()}
      </pre>
      <.button class="btn-action" phx-click={JS.push("mark_sent") |> hide_modal("std-modal")}>
        Mark Sent
      </.button>

      <.button phx-click={hide_modal("std-modal")}>
        Cancel
      </.button>
      <a
        :if={@guests.ok? and sms_phone(@selected, @guests.result) != ""}
        href={sms_link(@selected, @guests.result)}
      >
        <.button>Open text</.button>
      </a>
    </.modal>
    """
  end

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:new_guest, nil)
      |> assign(:selected, %{})
      |> assign_async([:guests, :changeset], fn ->
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
    guests = socket.assigns.guests

    guests =
      if guests.ok? do
        guests.result
      else
        []
      end

    has_duplicate =
      Enum.any?(
        guests,
        &(&1.first_name == guest_params["first_name"] and
            &1.last_name == guest_params["last_name"])
      )

    if not has_duplicate do
      {
        :noreply,
        socket
        |> assign_async([:guests, :changeset, :new_guest], fn ->
          case MyGuest.create_guest(guest_params) do
            {:ok, guest} ->
              {:ok,
               %{
                 guests: MyGuest.list_guests(),
                 changeset:
                   Guest.changeset(%Guest{
                     first_name: "Placeholder",
                     last_name: "",
                     email: ""
                   }),
                 new_guest: guest
               }}

            {:error, err} ->
              IO.puts("Something happened")
              IO.inspect(err)
              {:error, %{}}
          end
        end)
      }
    else
      {:noreply, socket |> put_flash(:error, "Duplicate guest")}
    end
  end

  defp toggle_guest(guest) do
    %JS{}
    |> JS.push("toggle_guest", value: %{id: guest.id})
  end

  defp toggle(selected, id) do
    new_value = not Map.get(selected, id, false)
    Map.put(selected, id, new_value)
  end

  defp sms_link(selected, guests) do
    "sms:#{sms_phone(selected, guests)}?body=#{URI.encode(sms_body())}"
  end

  defp sms_phone(selected, guests) do
    guests
    |> Enum.filter(&selected[&1.id])
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
