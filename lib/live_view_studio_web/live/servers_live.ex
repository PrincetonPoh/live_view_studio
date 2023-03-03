defmodule LiveViewStudioWeb.ServersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Servers

  def mount(_params, _session, socket) do
    servers = Servers.list_servers()

    socket =
      assign(socket,
        servers: servers,
        coffees: 0
      )

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _url, socket) do
    {:noreply, assign(socket, selected_server: Servers.get_server!(id))}
  end

  def handle_params(_, _url, socket) do
    IO.inspect(hd(socket.assigns.servers), label: "SERVER")
    IO.inspect(3)

    {:noreply,
     assign(socket,
       selected_server: hd(socket.assigns.servers)
     )}
  end

  def render(assigns) do
    IO.inspect(self(), label: "RENDER")

    ~H"""
    <h1>Servers</h1>
    <div id="servers">
      <div class="sidebar">
        <div class="nav">
          <.link
            :for={server <- @servers}
            patch={~p"/servers/#{server}"}
            class={if server == @selected_server, do: "selected"}
          >
            <span class={server.status}></span>
            <%= server.name %>
          </.link>
        </div>
        <div class="coffees">
          <button phx-click="drink">
            <img src="/images/coffee.svg" />
            <%= @coffees %>
          </button>
        </div>
      </div>
      <.server selected_server={@selected_server} />
    </div>
    """
  end

  def handle_event("drink", _, socket) do
    {:noreply, update(socket, :coffees, &(&1 + 1))}
  end

  attr :selected_server, LiveViewStudio.Servers.Server, required: true

  def server(assigns) do
    ~H"""
    <div class="main">
      <div class="wrapper">
        <div class="server">
          <div class="header">
            <h2><%= @selected_server.name %></h2>
            <span class={@selected_server.status}>
              <%= @selected_server.status %>
            </span>
          </div>
          <div class="body">
            <div class="row">
              <span>
                <%= @selected_server.deploy_count %> deploys
              </span>
              <span>
                <%= @selected_server.size %> MB
              </span>
              <span>
                <%= @selected_server.framework %>
              </span>
            </div>
            <h3>Last Commit Message:</h3>
            <blockquote>
              <%= @selected_server.last_commit_message %>
            </blockquote>
          </div>
        </div>
        <div class="links">
          <.link navigate={~p"/light"}>Adjust light</.link>
        </div>
      </div>
    </div>
    """
  end
end
