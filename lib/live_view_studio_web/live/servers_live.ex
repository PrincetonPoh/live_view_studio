defmodule LiveViewStudioWeb.ServersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Servers
  alias LiveViewStudio.Servers.Server

  def mount(_params, _session, socket) do
    servers = Servers.list_servers()

    changeset = Servers.change_server(%Server{})

    socket =
      assign(socket,
        servers: servers,
        coffees: 0,
        form: to_form(changeset)
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

  def render(assigns) do
    IO.inspect(self(), label: "RENDER")

    ~H"""
    <h1>Servers</h1>
    <div id="servers">
      <div class="sidebar">
        <div class="nav">
          <.link patch={~p"/servers/new"} class="add">
            + Add New Server
          </.link>
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
      <div class="main">
        <div class="wrapper">
          <%= if @live_action == :new do %>
            <.new_server form={@form} />
          <%= else %>
            <.server selected_server={@selected_server} />
          <%= end %>
        </div>
      </div>
    </div>
    """
  end

  attr(:selected_server, LiveViewStudio.Servers.Server, required: true)

  def server(assigns) do
    ~H"""
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
      <br>
      <br>
      <br>
    """
  end

  attr(:form, Phoenix.HTML.Form, required: true)

  def new_server(assigns) do
    ~H"""
      <.form for={@form} phx-submit="save">
        <div class="field">
          <.input field={@form[:name]} placeholder="Name" />
        </div>
        <div class="field">
          <.input field={@form[:framework]} placeholder="Framework" />
        </div>
        <div class="field">
          <.input
            field={@form[:size]}
            placeholder="Size (MB)"
            type="number"
          />
        </div>
        <.button phx-disable-with="Saving...">
          Save
        </.button>
        <.link patch={~p"/servers"} class="cancel">
          Cancel
        </.link>
      </.form>
    """
  end

  def handle_event("drink", _, socket) do
    {:noreply, update(socket, :coffees, &(&1 + 1))}
  end

  def handle_event("save", %{"server" => server_params}, socket) do
    case Servers.create_server(server_params) do
      {:ok, server} ->
        socket =
          update(
            socket,
            :servers,
            fn servers -> [server | servers] end
          )

        socket = put_flash(socket, :info, "Server successfully created!")
        changeset = Servers.change_server(%Server{})
        socket = assign(socket, :form, to_form(changeset))
        {:noreply, push_patch(socket, to: ~p"/servers/#{server.id}")}

      {:error, changeset} ->
        socket = put_flash(socket, :error, "Failed to save!")
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
