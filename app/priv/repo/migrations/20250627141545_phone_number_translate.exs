defmodule App.Repo.Migrations.PhoneNumberTranslate do
  use Ecto.Migration
  alias App.Guest.Guest

  def change do
    App.Repo.all(Guest)
    |> Enum.each(fn guest ->
      {country_code, phone_number} =
        if String.length(guest.phone_legacy) >= 10 do
          translate_legacy_to_number(guest.phone_legacy)
        else
          {0, 0}
        end

      Guest.changeset(guest, %{
        phone_number: phone_number,
        country_code: country_code
      })
      |> App.Repo.update()
    end)
  end

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
