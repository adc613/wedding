defmodule AppWeb.GuestManageLive do
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

    <.button :if={not @show_form} phx-click="toggle_form">Add guest</.button>
    <.button :if={@show_form} phx-click="toggle_form">Hide form</.button>
    <div :if={@show_form}>
      <.guest_form changeset={@changeset} />
    </div>

    <.button phx-click="delete_selected">Delete selected</.button>
    <.button phx-click="send_std">Send Save the Dates</.button>

    <.table
      :if={guests = @guests.ok? && @guests.result}
      id="guests"
      rows={guests}
      selected={@selected}
      row_click={fn guest -> toggle_guest(guest) end}
      checkbox_click={fn guest -> toggle_guest(guest) end}
    >
      <:col :let={guest} label="Guest">{guest.first_name} {guest.last_name}</:col>
      <:col :let={guest} label="Email">{guest.email}</:col>
      <:col :let={guest} label="Rehersal dinner">
        <.check_icon checked={guest.rehersal_dinner} />
      </:col>
      <:col :let={guest} label="Brunch"><.check_icon checked={guest.brunch} /></:col>
      <:col :let={guest} label="Sent Save the Date"><.check_icon checked={guest.sent_std} /></:col>
    </.table>
    """
  end

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:hello, "world")
      |> assign(:selected, %{})
      |> assign(:changeset, Guest.changeset(%Guest{}))
      |> assign(:show_form, false)
      |> assign_async(:guests, fn -> {:ok, %{guests: MyGuest.list_guests()}} end)
    }
  end

  def handle_event("send_std", _value, socket) do
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
        |> Enum.map(&MyGuest.send_std(&1))

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
    IO.puts("toggle: " <> Integer.to_string(id))

    {
      :noreply,
      socket
      |> update(:selected, &toggle(&1, id))
    }
  end

  def handle_event("toggle_form", _value, socket) do
    {
      :noreply,
      socket
      |> update(:show_form, &(not &1))
    }
  end

  def handle_event("guest_submit", %{"guest" => guest_params}, socket) do
    {
      :noreply,
      socket
      |> assign_async(:guests, fn ->
        case MyGuest.create_guest(guest_params) do
          {:ok, _} ->
            {:ok, %{guests: MyGuest.list_guests()}}

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
