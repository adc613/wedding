defmodule AppWeb.AdminController do
  use AppWeb, :controller

  def landing(conn, _params) do
    conn |> redirect(to: ~p"/admin/dash")
  end
end
