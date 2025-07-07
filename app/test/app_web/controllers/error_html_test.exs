defmodule AppWeb.ErrorHTMLTest do
  use AppWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(AppWeb.ErrorHTML, "404", "html", []) =~ "Found Love"
  end

  test "renders 500.html" do
    assert render_to_string(AppWeb.ErrorHTML, "500", "html", []) =~ "Server error"
  end
end
