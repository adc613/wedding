defmodule App.Guest.Guest do
  use Ecto.Schema
  import Ecto.Changeset
  alias App.Guest.Guest
  alias App.Guest.RSVP
  alias App.Guest.Invitation

  schema "guests" do
    field :first_name, :string
    field :last_name, :string
    # Important to note this is not a password, and should not be used for anything
    # that needs to be remotely secure. It's only to prevent users from making
    # uninteional changes
    # TODO: Clean up secret field. Ended up using email address as the key to
    # guest lookup
    field :secret, :string
    # TODO: Clean up, invites should be looked up through the guest's invitation
    field :rehersal_dinner, :boolean, default: false
    # TODO: Clean up, invites should be looked up through the guest's invitation
    field :brunch, :boolean, default: false
    field :sent_std, :boolean, default: false
    field :email, :string
    field :phone, :string, virtual: true, redact: true
    field :phone_legacy, :string, default: "", redact: true
    field :phone_number, :integer, default: 0
    field :country_code, :integer, default: 0
    field :is_kid, :boolean, default: false
    has_one :rsvp, RSVP
    belongs_to :invitation, Invitation, on_replace: :update

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(guest, attrs \\ %{}) do
    attrs = clean_attrs(attrs)

    guest
    |> cast(attrs, [
      :first_name,
      :last_name,
      :secret,
      :brunch,
      :rehersal_dinner,
      :email,
      :sent_std,
      :invitation_id,
      :is_kid,
      :phone,
      :phone_number,
      :phone_legacy,
      :country_code
    ])
    |> cast_assoc(:invitation, with: &Invitation.changeset/2)
    |> validate_email()
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 3)
    |> validate_length(:last_name, min: 3)
    |> assoc_constraint(:invitation)
  end

  @doc """
  Returns a changeset for doing a %Guest{} lookup in the database. Not meant
  to be used for DB write actions.
  """
  @spec lookup_changeset(map()) :: %Ecto.Changeset{}
  def lookup_changeset(guest, attrs \\ %{}) do
    guest
    |> cast(attrs, [:email, :phone])
    |> validate_email()
  end

  def apply_lookup(guest, attrs \\ %{}) do
    attrs = clean_attrs(attrs)

    lookup_changeset(guest, attrs) |> apply_action(:validate_attrs)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  def gen_secret() do
    Enum.random(100_000..999_999)
    |> Integer.to_string()
  end

  def convert_phone(phone), do: translate_legacy_to_number(phone)

  def add_phone(nil), do: nil

  def add_phone(%Guest{} = guest) do
    Map.put(guest, :phone, get_phone_str(guest))
  end

  defp get_phone_str(%Guest{country_code: nil, phone_number: nil}), do: nil
  defp get_phone_str(%Guest{country_code: 0, phone_number: 0}), do: nil

  defp get_phone_str(%Guest{country_code: country_code, phone_number: phone_number}) do
    Integer.to_string(phone_number)
    |> then(
      &Regex.named_captures(~r/(?<area_code>\d{3})(?<local_code>\d{3})(?<suffix>\d{4})/, &1)
    )
    |> case do
      nil ->
        Integer.to_string(phone_number)

      %{"area_code" => area_code, "local_code" => local_code, "suffix" => suffix} ->
        "(#{area_code})#{local_code}-#{suffix}"
    end
    |> then(&"+#{country_code}#{&1}")
  end

  defp clean_attrs(attrs) do
    attrs |> clean_phone()
  end

  defp clean_phone(%{"phone" => _phone} = attrs) do
    {country_code, phone_number} =
      Map.get(attrs, "phone", "") |> translate_legacy_to_number()

    # Ecto throws an error where there's a mix of string keys and atom keys.
    if Map.keys(attrs) |> Enum.all?(&is_atom(&1)) do
      attrs
      |> Map.put(:phone_number, phone_number)
      |> Map.put(:country_code, country_code)
    else
      attrs
      |> Map.put("phone_number", phone_number)
      |> Map.put("country_code", country_code)
    end
  end

  defp clean_phone(attrs), do: attrs

  defp translate_legacy_to_number(""), do: {0, 0}

  defp translate_legacy_to_number(number_str) do
    num_list =
      to_charlist(number_str)
      |> Enum.filter(&(&1 >= ?0 and &1 <= ?9))

    if length(num_list) == 10 do
      {[?1], num_list}
    else
      num_list
      |> Enum.reverse()
      |> Enum.reduce({[], []}, fn num, {country_code, phone_number} ->
        if length(phone_number) < 10 do
          {country_code, [num | phone_number]}
        else
          {[num | country_code], phone_number}
        end
      end)
    end
    |> then(fn {country_code, phone_number} ->
      {List.to_string(country_code), List.to_string(phone_number)}
    end)
    |> then(fn {country_code, phone_number} ->
      {String.to_integer(country_code), String.to_integer(phone_number)}
    end)
  end
end
