defmodule PhoenixTest.DOM.ButtonSubmitPreflightTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.DOM.ButtonSubmitPreflight
  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Form
  alias PhoenixTest.FormData

  describe "evaluate/3" do
    test "returns merged owner-form data when active form matches" do
      html = """
      <form id="profile-form">
        <label for="name">Name</label>
        <input id="name" name="name" value="default" />
        <button type="submit">Save</button>
      </form>
      """

      form = Form.find!(html, "form")
      button = Button.find!(html, "button", "Save")

      active_form =
        [id: form.id, selector: form.selector]
        |> ActiveForm.new()
        |> ActiveForm.add_form_data({"name", "updated"})

      assert {:ok, %{form: owner_form, form_data: form_data, active_form_matches?: true}} =
               ButtonSubmitPreflight.evaluate(button, html, active_form)

      assert owner_form.selector == form.selector
      assert FormData.has_data?(form_data, "name", "updated")
    end

    test "uses only form defaults when active form does not match owner" do
      html = """
      <form id="profile-form">
        <label for="name">Name</label>
        <input id="name" name="name" value="default" />
        <button type="submit">Save</button>
      </form>
      """

      button = Button.find!(html, "button", "Save")

      active_form =
        [id: "other-form", selector: "#other-form"]
        |> ActiveForm.new()
        |> ActiveForm.add_form_data({"name", "updated"})

      assert {:ok, %{form_data: form_data, active_form_matches?: false}} =
               ButtonSubmitPreflight.evaluate(button, html, active_form)

      assert FormData.has_data?(form_data, "name", "default")
      refute FormData.has_data?(form_data, "name", "updated")
    end

    test "returns invalid when constraint validation blocks submit" do
      html = """
      <form id="profile-form">
        <label for="name">Name</label>
        <input id="name" name="name" required />
        <button type="submit">Save</button>
      </form>
      """

      button = Button.find!(html, "button", "Save")

      assert :invalid = ButtonSubmitPreflight.evaluate(button, html, ActiveForm.new())
    end

    test "supports external submitter associated by form attribute" do
      html = """
      <form id="profile-form">
        <input name="name" value="default" />
      </form>
      <button type="submit" form="profile-form">External Save</button>
      """

      button = Button.find!(html, "button", "External Save")

      assert {:ok, %{form: owner_form, active_form_matches?: false}} =
               ButtonSubmitPreflight.evaluate(button, html, ActiveForm.new())

      assert owner_form.id == "profile-form"
    end

    test "returns not_owner for non-submit buttons" do
      html = """
      <button type="button">Preview</button>
      """

      button = Button.find!(html, "button", "Preview")

      assert :not_owner = ButtonSubmitPreflight.evaluate(button, html, ActiveForm.new())
    end
  end
end
