defmodule LiveViewStudioWeb.ServerFormComponent do
  use LiveViewStudioWeb, :live_component

  alias LiveViewStudio.Servers
  alias LiveViewStudio.Servers.Server

  def mount(socket) do
    changeset = Servers.change_server(%Server{})

    {:ok, assign(socket, :form, to_form(changeset))}
  end

  attr(:form, Phoenix.HTML.Form, required: true)

  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
        <div class="field">
          <.input
            field={@form[:name]}
            placeholder="Name"
            phx-debounce="2000"
          />
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
    </div>
    """
  end

  def handle_event("save", %{"server" => server_params}, socket) do
    case Servers.create_server(server_params) do
      {:ok, server} ->
        send(self(), {__MODULE__, :server_created, server})

        socket = put_flash(socket, :info, "Server successfully created!")
        {:noreply, socket}

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
end