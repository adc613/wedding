defmodule AppWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use AppWeb, :html

  embed_templates "page_html/*"

  def brunch_event(assigns) do
    ~H"""
    <.event
      title="Brunch"
      date="2026.04.04"
      time="5:00 PM - 7:00 PM"
      location="Garfield Park Conservatory"
      attire="Cocktail"
      location_link="https://maps.app.goo.gl/39aRmoqY6hVrzzGE7"
      suffix=""
    />
    """
  end

  def ceremony_event(assigns) do
    ~H"""
    <.event
      title="Ceremony"
      date="2026.04.04"
      time="5:00 PM - 7:00 PM"
      location="Garfield Park Conservatory"
      attire="Cocktail"
      location_link="https://maps.app.goo.gl/39aRmoqY6hVrzzGE7"
      suffix=""
    />
    """
  end

  def reception_event(assigns) do
    ~H"""
    <.event
      title="Reception"
      date="2026.04.04"
      time="7:00 PM - TBD"
      location="Ovation"
      attire="Cocktail"
      location_link="https://maps.app.goo.gl/5fnzavcBJPoiYeN96"
      suffix=""
    />
    """
  end

  def cocktail_event(assigns) do
    ~H"""
    <.event
      title="Cocktail Hour"
      date="2026.04.04"
      time="5:00 PM - 7:00 PM"
      location="Garfield Park Conservatory"
      attire="Cocktail"
      location_link="https://maps.app.goo.gl/39aRmoqY6hVrzzGE7"
      suffix=""
    />
    """
  end

  def rehersal_event(assigns) do
    ~H"""
    <.event
      title="Rehearsal"
      date="2026.04.04"
      time="5:00 PM - 7:00 PM"
      location="Garfield Park Conservatory"
      attire="Cocktail"
      location_link="https://maps.app.goo.gl/39aRmoqY6hVrzzGE7"
      suffix=""
    />
    """
  end
end
