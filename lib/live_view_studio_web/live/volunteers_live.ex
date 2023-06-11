defmodule LiveViewStudioWeb.VolunteersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Volunteers
  alias LiveViewStudio.Volunteers.Volunteer

  def mount(_params, _session, socket) do
    volunteers = Volunteers.list_volunteers()

    changeset = Volunteers.change_volunteer(%Volunteer{})

    socket =
      socket
      |> stream(:volunteers, volunteers)
      |> assign(form: to_form(changeset))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Volunteer Check-In</h1>
    <.flash_group flash={@flash} />

    <div id="volunteer-checkin">

      <.form for={@form} phx-submit="save" phx-change="validate">
        <.input field={@form[:name]} placeholder="Name" autocomplete="off" phx-debounce="2000"/>
        <.input field={@form[:phone]} type="tel" placeholder="Phone" autocomplete="off" phx-debounce="blur"/>
        <.button phx-disable-with="Saving...">
          Check In
        </.button>
      </.form>

      <div id="volunteers" phx-update="stream">
        <div
          :for={{volunteer_id, volunteer} <- @streams.volunteers}
          class={"volunteer #{if volunteer.checked_out, do: "out"}"}
          id={volunteer_id}
        >
          <div class="name">
            <%= volunteer.name %>
          </div>
          <div class="phone">
            <%= volunteer.phone %>
          </div>
          <div class="status" phx-click="toggle_state" phx-value-id={volunteer.id}>
            <button>
              <%= if volunteer.checked_out, do: "Check In", else: "Check Out" %>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("save", %{"volunteer" => volunteer_params}, socket) do
    IO.inspect(volunteer_params)

    case Volunteers.create_volunteer(volunteer_params) do
      {:ok, volunteer} ->
        socket = stream_insert(socket, :volunteers, volunteer, at: 0)

        socket = put_flash(socket, :info, "Volunteer successfully checked in!")

        changeset = Volunteers.change_volunteer(%Volunteer{})
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, changeset} ->
        socket = put_flash(socket, :error, "Check in failure!")
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("validate", %{"volunteer" => volunteer_params}, socket) do
    changeset =
      %Volunteer{}
      |> Volunteers.change_volunteer(volunteer_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("toggle_state", %{"id" => id}, socket) do
    volunteer = Volunteers.get_volunteer!(id)

    {:ok, updated_volunteer} = Volunteers.toggle_status_volunteer(volunteer)

    {:noreply, stream_insert(socket, :volunteers, updated_volunteer)}
  end
end
