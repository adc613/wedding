# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     App.Repo.insert!(%App.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
App.Accounts.register_user(%{
  "email" => "adc613@gmail.com",
  "password" => System.get_env("DEFAULT_PASSWORD"),
  "confirmed_passwed" => System.get_env("DEFAULT_PASSWORD")
})

App.Accounts.register_user(%{
  "email" => "helen.clark.r@gmail.com",
  "password" => System.get_env("DEFAULT_PASSWORD"),
  "confirmed_passwed" => System.get_env("DEFAULT_PASSWORD")
})
