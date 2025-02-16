defmodule App.Guest.Guest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "guests" do
    field :first_name, :string
    field :last_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(guest, attrs) do
    guest
    |> cast(attrs, [:first_name, :last_name])
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 3)
    |> validate_length(:last_name, min: 3)
  end
end
