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
          <% else %>
            <.server selected_server={@selected_server} />
          <% end %>
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

  attr(:form, Phoenix.HTML.Form, required: true)

  def new_server(assigns) do
    ~H"""
    <.form for={@form} phx-submit="save" phx-change="validate">
      <div class="field">
        <.input field={@form[:name]} placeholder="Name" phx-debounce="2000" />
      </div>
      <div class="field">
        <.input
          field={@form[:framework]}
          placeholder="Framework"
          phx-debounce="2000"
        />
      </div>
      <div class="field">
        <.input
          field={@form[:size]}
          placeholder="Size (MB)"
          type="number"
          phx-debounce="2000"
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

  def handle_event("validate", %{"server" => server_params}, socket) do
    changeset =
      %Server{}
      |> Servers.change_server(server_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("toggle-status", %{"id" => server_id}, socket) do
    # update database
    server = Servers.get_server!(String.to_integer(server_id))
    {:ok, updated_server} = Servers.update_server(server, %{status: toggle_status(server.status)})

    # update sidebar
    updated_servers =
      Enum.map(socket.assigns.servers, fn s ->
        if s.id == server.id, do: updated_server, else: s
      end)

    {:noreply,
     assign(socket,
       selected_server: updated_server,
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
