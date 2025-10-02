defmodule AppWeb.RegistryHTML do
  @moduledoc """
  This module contains pages rendered by RegistryController.

  See the `page_html` directory for all templates available.
  """
  use AppWeb, :html

  embed_templates "registry_html/*"
end
