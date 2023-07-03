defmodule LiveViewStudioWeb.ServersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Servers
  alias LiveViewStudioWeb.ServerFormComponent

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Servers.subscribe()
    end

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
    case socket.assigns.live_action == :new do
      true ->
        {:noreply, assign(socket, selected_server: nil)}

      _ ->
        {:noreply,
         assign(socket,
           selected_server: hd(socket.assigns.servers)
         )}
    end
  end

  attr(:selected_server, LiveViewStudio.Servers.Server, required: true)

  def server(assigns) do
    ~H"""
    <div class="server">
      <div class="header">
        <h2><%= @selected_server.name %></h2>
        <button
          phx-click="toggle-status"
          phx-value-id={@selected_server.id}
          class={@selected_server.status}
        >
          <%= @selected_server.status %>
        </button>
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
    <br />
    <br />
    <br />
    """
  end

  def handle_event("drink", _, socket) do
    {:noreply, update(socket, :coffees, &(&1 + 1))}
  end

  def handle_event("toggle-status", %{"id" => server_id}, socket) do
    # update database
    server = Servers.get_server!(String.to_integer(server_id))
    {:ok, updated_server} = Servers.update_server(server, %{status: toggle_status(server.status)})

    {:noreply,
     assign(socket,
       selected_server: updated_server,
     )}
  end

  def handle_info({ServerFormComponent, :server_created, server}, socket) do
    socket =
      update(
        socket,
        :servers,
        fn servers -> [server | servers] end
      )

    {:noreply, push_patch(socket, to: ~p"/servers/#{server.id}")}
  end

  def handle_info({:toggle_status, updated_server}, socket) do
    # update sidebar
    updated_servers =
      Enum.map(socket.assigns.servers, fn s ->
        if s.id == updated_server.id, do: updated_server, else: s
      end)

    {:noreply,
     assign(socket,
       servers: updated_servers
     )}
  end

  defp toggle_status(old_status) do
    case old_status do
      "up" -> "down"
      "down" -> "up"
    end
  end
end
