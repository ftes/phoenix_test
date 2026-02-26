defmodule PhoenixTest.ActiveFormState do
  @moduledoc false

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.Element.Field

  @doc """
  Writes a field interaction to `session.active_form`.

  Returns `{updated_session, owner_form}` so callers can continue driver-specific
  behavior (for example, LiveView `phx-change` handling) with the resolved form.
  """
  def put_field(session, field) do
    html = session.current_operation.html
    Field.validate_name!(field)
    form = Field.parent_form!(field, html)

    session =
      Map.update!(session, :active_form, fn active_form ->
        if active_form.selector == form.selector do
          ActiveForm.add_form_data(active_form, field)
        else
          [id: form.id, selector: form.selector]
          |> ActiveForm.new()
          |> ActiveForm.add_form_data(field)
        end
      end)

    {session, form}
  end
end
