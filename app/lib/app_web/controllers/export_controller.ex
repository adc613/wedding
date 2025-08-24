defmodule AppWeb.ExportController do
  alias App.MyGuest
  use AppWeb, :controller

  def guest_list(conn, _params) do
    MyGuest.list_guests()
    |> CSV.encode(headers: [first_name: "First name", last_name: "Last name", phone: "Phone"])
    |> Enum.join("")
    |> render_file(conn, "guests")
  end

  defp render_file(data, conn, name) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{name}.csv\"")
    |> put_root_layout(false)
    |> send_resp(200, data)
  end
end
