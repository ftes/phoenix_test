defmodule PhoenixTest.WebApp.SimpleMailingList do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:title, :string)

    embeds_many :emails, Email, on_replace: :delete do
      field(:email, :string)
      field(:name, :string)
    end
  end

  def changeset(list, attrs) do
    list
    |> cast(attrs, [:title])
    |> cast_embed(:emails,
      with: &email_changeset/2,
      sort_param: :emails_sort,
      drop_param: :emails_drop
    )
  end

  def email_changeset(email_notification, attrs) do
    cast(email_notification, attrs, [:email, :name])
  end
end

defmodule PhoenixTest.WebApp.SimpleOrdinalInputsLive do
  @moduledoc false
  use Phoenix.LiveView
  use Phoenix.Component

  import PhoenixTest.WebApp.Components

  alias Phoenix.LiveView.JS
  alias PhoenixTest.WebApp.SimpleMailingList

  def mount(_params, _session, socket) do
    email = %SimpleMailingList.Email{}
    changeset = SimpleMailingList.changeset(%SimpleMailingList{emails: [email]}, %{})

    {:ok,
     socket
     |> assign_form(changeset)
     |> assign(submitted: false, emails: [])}
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} phx-change="validate" phx-submit="submit">
      <.input field={@form[:title]} label="Title" />

      <.inputs_for :let={ef} field={@form[:emails]}>
        <input type="hidden" name="mailing_list[emails_sort][]" value={ef.index} />
        <.input label="Email" type="text" field={ef[:email]} placeholder="email" />
        <.input label="Name" type="text" field={ef[:name]} placeholder="name" />
        <button
          type="button"
          name="mailing_list[emails_drop][]"
          value={ef.index}
          phx-click={JS.dispatch("change")}
        >
          <span class="sr-only">remove</span>
          <.icon name="hero-x-mark" class="w-6 h-6 relative -right-2 top-1" />
        </button>
      </.inputs_for>

      <input type="hidden" name="mailing_list[emails_drop][]" />

      <button
        type="button"
        name="mailing_list[emails_sort][]"
        value="new"
        phx-click={JS.dispatch("change")}
      >
        add more
      </button>
      <button type="submit">Submit</button>
    </.form>

    <div>
      <%= if @submitted do %>
        <h3>Submitted Values:</h3>
        <div>Title: {@form.params["title"]}</div>
        <%= for email <- @emails do %>
          <div data-role="email">{email}</div>
        <% end %>
      <% end %>
    </div>
    """
  end

  def handle_event("submit", %{"mailing_list" => params}, socket) do
    changeset = SimpleMailingList.changeset(%SimpleMailingList{}, params)

    emails =
      changeset
      |> Ecto.Changeset.get_field(:emails)
      |> Enum.map(fn email -> email.email end)
      |> Enum.reject(&is_nil/1)

    {:noreply, socket |> assign_form(changeset) |> assign(submitted: true, emails: emails)}
  end

  def handle_event("validate", %{"mailing_list" => params}, socket) do
    changeset = SimpleMailingList.changeset(%SimpleMailingList{}, params)
    {:noreply, assign_form(socket, changeset)}
  end

  attr :name, :string, required: true
  attr :class, :string, default: nil

  defp icon(%{name: "hero-x-mark"} = assigns) do
    ~H"""
    <span class={@class} aria-hidden="true">x</span>
    """
  end

  defp icon(assigns) do
    ~H"""
    <span class={@class} aria-hidden="true"></span>
    """
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: :mailing_list))
  end
end
