defmodule PhysioWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS
  alias Physio.Accounts
  alias Physio.Accounts.User
  alias Physio.Accounts.Doctor
  alias Physio.Accounts.Admin
  alias PhysioWeb.Router.Helpers, as: Routes

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={Routes.appointment_index_path(@socket, :index)}>
        <.live_component
          module={PhysioWeb.AppointmentLive.FormComponent}
          id={@appointment.id || :new}
          title={@page_title}
          action={@live_action}
          return_to={Routes.appointment_index_path(@socket, :index)}
          appointment: @appointment
        />
      </.modal>
  """
  def modal(assigns) do
    assigns = assign_new(assigns, :return_to, fn -> nil end)

    ~H"""
    <div id="modal" class="phx-modal fade-in" phx-remove={hide_modal()}>
      <div
        id="modal-content"
        class="phx-modal-content fade-in-scale"
        phx-click-away={JS.dispatch("click", to: "#close")}
        phx-window-keydown={JS.dispatch("click", to: "#close")}
        phx-key="escape"
      >
        <%= if @return_to do %>
          <%= live_patch "✖",
            to: @return_to,
            id: "close",
            class: "phx-modal-close",
            phx_click: hide_modal()
          %>
        <% else %>
          <a id="close" href="#" class="phx-modal-close" phx-click={hide_modal()}>✖</a>
        <% end %>

        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end

  def find_current_admin(session) do
    with admin_token when not is_nil(admin_token) <- session["admin_token"],
         %Admin{} = admin <- Accounts.get_admin_by_session_token(admin_token),
         do: admin
  end

  def find_current_user(session) do
    with user_token when not is_nil(user_token) <- session["user_token"],
         %User{} = user <- Accounts.get_user_by_session_token(user_token),
         do: user
         |> Physio.Repo.preload(:user_profile)
  end

  def find_current_doctor(session) do
    with doctor_token when not is_nil(doctor_token) <- session["doctor_token"],
         %Doctor{} = doctor <- Accounts.get_doctor_by_session_token(doctor_token),
         do: doctor
         |> Physio.Repo.preload([:doctor_profile, :doctor_category])
  end

  def upload_photos(socket, key) do
    consume_uploaded_entries(socket, key, fn meta, entry ->
      file = Path.join("priv/static/uploads", filename(entry))
      File.cp!(meta.path, file)
     {:postpone, Routes.static_path(socket, "/uploads/#{filename(entry)}")}
    end)
  end

  def filename(entry) do
    ext = MIME.extensions(entry.client_type)
    "#{entry.uuid}.#{List.first (ext)}"
  end
end
