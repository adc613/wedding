defmodule App.MyGuest do
  import Ecto.Query, warn: false

  alias App.Repo
  alias App.Guest.Guest

  def list_guests() do
    Repo.all(Guest)
  end

  def get_guest!(id) do
    Repo.get!(Guest, id)
  end

  def change_guest(%Guest{} = guest, attrs \\ %{}) do
    Guest.changeset(guest, attrs)
  end

  def update(%Guest{} = guest, attrs \\ %{}) do
    guest
    |> Guest.changeset(attrs)
    |> Repo.update()
  end

  def delete(%Guest{} = guest) do
    Repo.delete(guest)
  end

  def create(attrs \\ %{}) do
    %Guest{}
    |> Guest.changeset(attrs)
    |> Repo.insert()
  end
end
