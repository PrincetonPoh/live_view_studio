defmodule LiveViewStudioWeb.LightLive do
  use LiveViewStudioWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      assign(
        socket,
        brightness: 10,
        temp: "3000"
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Front Porch Light</h1>

    <div id="light">
      <div class="meter">
        <span style={"width: #{@brightness}%; background: #{temp_color(@temp)}"}>
          <%= @brightness %>%
        </span>
      </div>
      <button phx-click="off">
        <img src="/images/light-off.svg" />
      </button>
      <button phx-click="down">
        <img src="/images/down.svg" />
      </button>
      <button phx-click="up">
        <img src="/images/up.svg" />
      </button>
      <button phx-click="on">
        <img src="/images/light-on.svg" />
      </button>
      <br />
      <br />
      <button phx-click="fire">
        <img src="/images/fire.svg" />
      </button>
      <form phx-change="slider">
        <input
          type="range"
          min="0"
          max="100"
          name="brightness"
          value={@brightness}
          phx-debounce="250"
        />
      </form>
      <form phx-change="temperature">
        <div class="temps">
          <%= for temp <- ["3000", "4000", "5000"] do %>
            <div>
              <input
                type="radio"
                id={temp}
                name="temp"
                value={temp}
                checked={temp == @temp}
              />
              <label for={temp}><%= temp %></label>
            </div>
          <% end %>
        </div>
      </form>
    </div>

    <%!-- flashes --%>
    <div id="flash" class="hidden bg-emerald-400 w-41 h-10" phx-mounted={JS.show(transition: "bg-rose-100 0.5s ease")}>  Welcome back!  </div>
    <div id="status" class="hidden" phx-disconnected={JS.show()} phx-connected={JS.hide()}>  Attempting to reconnect...  </div>
    <p class="alert" phx-click="lv:clear-flash" phx-value-key="info">  <%= live_flash(@flash, :info) %>  </p>
    <%!-- phx events --%>
    <h1 phx-click="inc" phx-value-myvar1="val1" phx-value-myvar2="val2">Yomana</h1>
    <h1 phx-click="inc" phx-value-myvar2="val2">Yomana2</h1>
    <input name="email" phx-focus="myfocus" phx-blur="myblur" phx-keydown="Escape"/>
    <div id="thermostat" phx-window-keyup="update_temp">
      Current temperature: <%= @brightness %>
    </div>
    <%!-- Live navigation --%>
    <.link navigate={~p"/boats"}>LINK TO BOATS</.link>
    <%!-- JS commands --%>
    <div id="modal" class="modal bg-[#50d71e] w-40 h-10">  My Modal  </div>
    <button phx-click={JS.show(to: "#modal", transition: "fade-in")}>  show modal  </button>
    <button phx-click={JS.hide(to: "#modal", transition: "fade-out")}>  hide modal  </button>
    <button phx-click={JS.toggle(to: "#modal", in: "fade-in", out: "fade-out")}>  toggle modal  </button>

    <div id="modal" class="modal bg-rose-400 w-40 h-10">  Another modal  </div>
    <button phx-click={JS.add_class("show", to: "#modal", transition: "fade-in")}>  show modal   </button>
    <button phx-click={JS.remove_class("show", to: "#modal", transition: "fade-out")}>  hide modal   </button>

    <div id="modal" class="modal bg-slate-400 w-40 h-10">  My Modal  </div>
    <button phx-click={JS.push("modal-closed") |> JS.remove_class("show", to: "#modal", transition: "fade-out")}>  hide modal  </button>

    """
  end

  def handle_event("off", _, socket) do
    socket = assign(socket, brightness: 0)
    {:noreply, socket}
  end

  def handle_event("on", _, socket) do
    socket = assign(socket, brightness: 100)
    {:noreply, socket}
  end

  def handle_event("down", _, socket) do
    brightness = max(socket.assigns.brightness - 10, 0)
    socket = assign(socket, brightness: brightness)
    {:noreply, socket}
  end

  def handle_event("up", _, socket) do
    socket = update(socket, :brightness, &min(&1 + 10, 100))
    {:noreply, socket}
  end

  def handle_event("fire", _, socket) do
    socket = assign(socket, brightness: Enum.random(1..100))
    {:noreply, socket}
  end

  def handle_event("slider", params, socket) do
    %{"brightness" => brightness} = params
    socket = assign(socket, brightness: String.to_integer(brightness))
    {:noreply, socket}
  end

  def handle_event("temperature", params, socket) do
    IO.inspect(params)
    %{"temp" => temp} = params
    socket = assign(socket, temp: temp)
    {:noreply, socket}
  end

  defp temp_color("3000"), do: "#F1C40D"
  defp temp_color("4000"), do: "#FEFF66"
  defp temp_color("5000"), do: "#99CCFF"

  def handle_event("inc", params, socket) do
    IO.puts("hey")
    IO.inspect(params)

    case params do
      %{"myvar1" => "val1"} -> IO.puts("first one")
      %{"myvar2" => "val2"} -> IO.puts("second one")
      _ -> socket
    end

    {:noreply, socket}
  end

  def handle_event("myfocus", _, socket) do
    IO.puts("FOCUS")
    {:noreply, socket}
  end

  def handle_event("myblur", _, socket) do
    IO.puts("BLUR")
    {:noreply, socket}
  end

  def handle_event("Escape", params, socket) do
    IO.puts("esc")
    IO.inspect(params)
    {:noreply, socket}
  end

  def handle_event("update_temp", %{"key" => "ArrowUp"}, socket) do
    IO.puts("up")
    socket = update(socket, :brightness, &min(&1 + 1, 100))
    {:noreply, socket}
  end

  def handle_event("update_temp", %{"key" => "ArrowDown"}, socket) do
    IO.puts("down")
    {:noreply, assign(socket, brightness: max(socket.assigns.brightness - 1, 0))}
  end

  def handle_event("update_temp", _, socket) do
    {:noreply, socket}
  end
end
