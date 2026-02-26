defmodule PhoenixTest.ActiveFormStateTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.ActiveFormState
  alias PhoenixTest.Element.Field
  alias PhoenixTest.FormData

  describe "put_field/2" do
    test "writes field data into the existing active form when selectors match" do
      html = """
      <form id="a">
        <label for="a-name">Name</label>
        <input id="a-name" name="name" value="Aragorn" />
      </form>
      """

      field = Field.find_input!(html, "input", "Name", exact: true)
      session = %{current_operation: %{html: html}, active_form: ActiveForm.new(id: "a", selector: "#a")}

      {updated_session, form} = ActiveFormState.put_field(session, field)

      assert updated_session.active_form.selector == form.selector
      assert FormData.has_data?(updated_session.active_form.form_data, "name", "Aragorn")
    end

    test "switches active form ownership when field belongs to a different form" do
      html = """
      <form id="a">
        <label for="a-name">Name A</label>
        <input id="a-name" name="name_a" value="Aragorn" />
      </form>

      <form id="b">
        <label for="b-name">Name B</label>
        <input id="b-name" name="name_b" value="Legolas" />
      </form>
      """

      field = Field.find_input!(html, "input", "Name B", exact: true)

      session = %{
        current_operation: %{html: html},
        active_form:
          [id: "a", selector: "#a"]
          |> ActiveForm.new()
          |> ActiveForm.add_form_data({"name_a", "Aragorn"})
      }

      {updated_session, form} = ActiveFormState.put_field(session, field)

      assert updated_session.active_form.selector == form.selector
      assert FormData.has_data?(updated_session.active_form.form_data, "name_b", "Legolas")
      refute FormData.has_data?(updated_session.active_form.form_data, "name_a", "Aragorn")
    end

    test "raises when field name is missing" do
      html = """
      <form id="a">
        <label for="unnamed">Unnamed</label>
        <input id="unnamed" value="x" />
      </form>
      """

      field = Field.find_input!(html, "input", "Unnamed", exact: true)
      session = %{current_operation: %{html: html}, active_form: ActiveForm.new(id: "a", selector: "#a")}

      assert_raise ArgumentError, ~r/missing a `name` attribute/, fn ->
        ActiveFormState.put_field(session, field)
      end
    end
  end
end
