defmodule LiveViewStudioWeb.BoatsLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Boats

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        filter: %{type: "", prices: []},
        boats: Boats.list_boats()
      )

    {:ok, socket, temporary_assigns: [boats: []]}
  end

  attr(:filter, :map, required: true)

  def filter_form(assigns) do
    ~H"""
    <form phx-change="filter">
      <div class="filters">
        <select name="type">
          <%= Phoenix.HTML.Form.options_for_select(
            type_options(),
            @filter.type
          ) %>
        </select>
        <div class="prices">
          <%= for price <- ["$", "$$", "$$$"] do %>
            <input
              type="checkbox"
              name="prices[]"
              value={price}
              id={price}
              checked={price in @filter.prices}
            />
            <label for={price}><%= price %></label>
          <% end %>
          <input type="hidden" name="prices[]" value="" />
        </div>
      </div>
    </form>
    """
  end

  attr(:boat, LiveViewStudio.Boats)

  def display_boats(assigns) do
    ~H"""
    <div class="boat">
      <img src={@boat.image} />
      <div class="content">
        <div class="model">
          <%= @boat.model %>
        </div>
        <div class="details">
          <span class="price">
            <%= @boat.price %>
          </span>
          <span class="type">
            <%= @boat.type %>
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp type_options do
    [
      "All Types": "",
      Fishing: "fishing",
      Sporting: "sporting",
      Sailing: "sailing"
    ]
  end

  def handle_event("filter", %{"type" => type, "prices" => prices}, socket) do
    IO.inspect(type)
    IO.inspect(prices)

    filter = %{type: type, prices: prices}

    {:noreply, push_patch(socket, to: ~p"/boats?#{filter}")}
  end

  def handle_params(params, _url, socket) do
    IO.inspect(params["sort_by"])

    filter = %{
      type: params["type"] || "",
      prices: params["prices"] || [""]
    }

    boats = Boats.list_boats(filter)
    socket = assign(socket, boats: boats, filter: filter)

    {:noreply, socket}
  end
end
