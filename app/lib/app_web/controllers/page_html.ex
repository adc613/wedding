defmodule AppWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use AppWeb, :html

  embed_templates "page_html/*"

  attr :event, :atom, required: true
  slot :footer, required: true
  attr :full_width_footer, :boolean, default: false

  def event_group(%{event: :wedding} = assigns) do
    ~H"""
    <.event_card group_name="Wedding day" full_width_footer={@full_width_footer}>
      <:events>
        <!-- Hide cocktail event for now -->
        <!--<.cocktail_event /> -->
        <.reception_event />
        <.ceremony_event />
      </:events>
      <:footer>
        {render_slot(@footer)}
      </:footer>
    </.event_card>
    """
  end

  def event_group(%{event: :brunch} = assigns) do
    ~H"""
    <.event_card group_name="Brunch" full_width_footer={@full_width_footer}>
      <:events>
        <.brunch_event />
      </:events>
      <:footer>
        {render_slot(@footer)}
      </:footer>
    </.event_card>
    """
  end

  def event_group(%{event: :rehersal} = assigns) do
    ~H"""
    <.event_card group_name="Reherseal dinner" full_width_footer={@full_width_footer}>
      <:events>
        <.rehersal_event />
      </:events>
      <:footer>
        {render_slot(@footer)}
      </:footer>
    </.event_card>
    """
  end

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
      time="TBD"
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
      time="TBD"
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

  attr :group_name, :string, required: true
  attr :full_width_footer, :boolean, required: true

  slot :events, required: true
  slot :footer, required: true

  defp event_card(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-8 rounded-2xl border-2 p-4 mb-8  border-zinc-300">
      <div class="border-b-2 text-center">
        <h2 class="text-xl font-semibold">{@group_name}</h2>
        {render_slot(@events)}
      </div>

      <div class={
        if @full_width_footer do
          "w-full"
        else
          ""
        end
      }>
        {render_slot(@footer)}
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :date, :string, required: true
  attr :time, :string, required: true
  attr :location_link, :string, required: true
  attr :location, :string, required: true
  attr :attire, :string, required: true
  attr :suffix, :string, required: true

  defp event(assigns) do
    ~H"""
    <div class="mb-8">
      <div class="mx-auto">
        <h2 class="text-2xl text-center">
          {@title}
        </h2>
      </div>
      <div class="mx-auto">
        <p class="text-xl text-center">
          {@date}
        </p>
      </div>
      <div class="mx-auto">
        <p class="text-md text-center">
          <b>Time: </b>
          {@time}
        </p>
      </div>
      <div class="mx-auto">
        <p class="text-md text-center">
          <b>Location: </b>
          <a href={@location_link}>{@location} <i class="fa fa-map-marker"></i></a>
        </p>
      </div>
      <div class="mx-auto">
        <p class="text-md text-center">
          <b>Attire: </b>{@attire}
        </p>
      </div>
      <div class="mx-auto">
        <p class="text-md text-center">
          {@suffix}
        </p>
      </div>
    </div>
    """
  end

  attr :messages, :list, required: true

  def conversation(assigns) do
    ~H"""
    <div class="chat-conversation">
      <.chat_bubble :for={message <- @messages} message={message} />
    </div>
    """
  end

  attr :message, :list, required: true

  def chat_bubble(assigns) do
    ~H"""
    <div class={
      if @message.adam? do
        "chat-group adam"
      else
        if @message.indicator? do
          "chat-group helen indicator"
        else
          "chat-group helen"
        end
      end
    }>
      <div :if={@message.adam?} class="chat-image">
        <img :if={@message.indicator?} src="/images/adam_headshot.jpg" class="headshot" />
        <div :if={@message.indicator?} class="indicator" />
      </div>
      <p class={
        if @message.adam? do
          "chat-message adam"
        else
          if @message.indicator? do
            "chat-message helen indicator"
          else
            "chat-message helen"
          end
        end
      }>
        {@message.text}
      </p>
    </div>
    """
  end
end
