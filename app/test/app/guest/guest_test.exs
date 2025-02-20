defmodule App.Guest.GuestTest do
  alias App.Guest.Guest
  use App.DataCase

  test "Changeset happy case" do
    errors =
      %Guest{}
      |> Guest.changeset(%{"first_name" => "Adam", "last_name" => "Collins"})
      |> errors_on()

    assert errors == %{}
  end

  test "Require first name" do
    errors =
      %Guest{}
      |> Guest.changeset(%{"last_name" => "Collins"})
      |> errors_on()

    assert %{first_name: _} = errors
  end

  test "Require first name of minimum length" do
    errors =
      %Guest{}
      |> Guest.changeset(%{"first_name" => "a", "last_name" => "Collins"})
      |> errors_on()

    assert %{first_name: _} = errors
  end

  test "Require last name" do
    errors =
      %Guest{}
      |> Guest.changeset(%{"first_name" => "Adam"})
      |> errors_on()

    assert %{last_name: _} = errors
  end

  test "Require last name of minimum length" do
    errors =
      %Guest{}
      |> Guest.changeset(%{"first_name" => "Adam", "last_name" => "C"})
      |> errors_on()

    assert %{last_name: _} = errors
  end
end
