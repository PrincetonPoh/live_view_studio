defmodule LiveViewStudioWeb.PizzaOrdersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.PizzaOrders
  import Number.Currency

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        pizza_orders: PizzaOrders.list_pizza_orders()
      )

    {:ok, socket, temporary_assigns: [pizza_orders: []]}
  end

  def handle_params(params, _url, socket) do
    sort_by = valid_sort_by(params)
    sort_order = valid_sort_order(params)

    page = param_to_integer(params["page"], 1)
    per_page = param_to_integer(params["per_page"], 5)

    options = %{
      sort_by: sort_by,
      sort_order: sort_order,
      page: page,
      per_page: per_page
    }

    {:noreply,
     assign(
       socket,
       options: options,
       pizza_orders: PizzaOrders.list_pizza_orders(options),
       pizza_count: PizzaOrders.count_pizza_orders()
     )}
  end

  def handle_event("select-per-page", %{"per-page" => per_page}, socket) do
    params = %{socket.assigns.options | per_page: per_page}
    socket = push_patch(socket, to: ~p"/pizza-orders?#{params}")
    {:noreply, socket}
  end

  def handle_event("create-pizza", _, socket) do
    # randomly create pizza object
    size_list = ["Personal", "Family", "Small", "Large", "Medium", "Extra-Large"]

    style_list = [
      "Deep Fried Pizza	",
      "Flatbread",
      "Fugazza",
      "Pizza Rustica",
      "Thin Crust",
      "Wood Fired",
      "Pizza Bread",
      "Gluten-Free Quinoa",
      "Sicilian Style",
      "	Neapolitan",
      "Hand Tossed",
      "Detroit-style",
      "Tomato Pie",
      "Greek"
    ]

    topping_list = [
      "Peppers 🌶",
      "Bacon 🥓",
      "Tomatoes 🍅",
      "Mushrooms 🍄",
      "Garlic 🧄",
      "Onions 🧅",
      "Salmon 🐠",
      "Eggplants 🍆",
      "Shrimp 🍤",
      "Basil 🌿",
      "Broccoli 🥦",
      "Pineapples 🍍"
    ]

    size = Enum.random(size_list)
    style = Enum.random(style_list)
    topping_1 = Enum.random(topping_list)
    topping_2 = Enum.random(topping_list)
    price = Float.round(100 * :random.uniform(), 2)

    # try create 1 pizza object first
    {_, new_pizza} =
      PizzaOrders.create_pizza_order(%{
        size: size,
        style: style,
        topping_1: topping_1,
        topping_2: topping_2,
        price: price
      })

    pizza_orders = PizzaOrders.list_pizza_orders(socket.assigns.options)

    socket = assign(socket, pizza_orders: pizza_orders)
    {:noreply, socket}
  end

  defp link_sort(assigns) do
    ~H"""
      <.link patch={~p"/pizza-orders?#{%{@options | sort_by: @sort_by, sort_order: next_sort_order(@options.sort_order)}}"}>
        <%= render_slot(@inner_block) %>
        <%= sort_indicator(@sort_by, @options) %>
      </.link>
    """
  end

  attr(:options, :map, required: true)
  slot(:inner_block, required: true)

  def move_page_up(assigns) do
    ~H"""
    <.link
    :if={more_pages?(@options, @pizza_count)}
      patch={
        ~p"/pizza-orders?#{%{@options | page: @options.page + 1}}"
        }
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  attr(:options, :map, required: true)
  slot(:inner_block, required: true)

  def move_page_down(assigns) do
    ~H"""
    <.link
      :if={@options.page > 1}
      patch={
        ~p"/pizza-orders?#{%{@options | page: @options.page - 1}}"
        }
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp next_sort_order(sort_order) do
    case sort_order do
      :asc -> :desc
      :desc -> :asc
    end
  end

  defp sort_indicator(column, %{sort_by: sort_by, sort_order: sort_order})
       when column == sort_by do
    case sort_order do
      :asc -> "👆"
      :desc -> "👇"
    end
  end

  defp sort_indicator(_, _), do: ""

  defp valid_sort_by(%{"sort_by" => sort_by})
       when sort_by in ~w( size style topping_1 topping_2 price ) do
    String.to_atom(sort_by)
  end

  defp valid_sort_by(_params), do: :id

  defp valid_sort_order(%{"sort_order" => sort_order})
       when sort_order in ~w(asc desc) do
    String.to_atom(sort_order)
  end

  defp valid_sort_order(_params), do: :asc

  defp param_to_integer(nil, default), do: default

  defp param_to_integer(param, default) do
    case Integer.parse(param) do
      {number, _} ->
        number

      :error ->
        default
    end
  end

  defp more_pages?(options, pizza_count) do
    options.page * options.per_page < pizza_count
  end
end
