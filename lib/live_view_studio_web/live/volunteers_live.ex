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

  def handle_event("delete", %{"id" => id}, socket) do
    volunteer = Volunteers.get_volunteer!(id)
    {:ok, _} = Volunteers.delete_volunteer(volunteer)

    {:noreply, stream_delete(socket, :volunteers, volunteer)}
  end
end
