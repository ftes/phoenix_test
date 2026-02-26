defmodule PhoenixTest.DOM.SubmissionPlanTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.DOM.SubmissionPlan
  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Form
  alias PhoenixTest.FormData

  describe "merge_form_data/2" do
    test "merges runtime data over form defaults" do
      form =
        form("""
        <input type="text" name="name" value="Bilbo" />
        <input type="text" name="role" value="burglar" />
        """)

      runtime =
        FormData.new()
        |> FormData.add_data("name", "Frodo")
        |> FormData.add_data("level", "ring-bearer")

      merged = SubmissionPlan.merge_form_data(form, runtime)

      assert merged.data == %{
               "name" => "Frodo",
               "role" => "burglar",
               "level" => "ring-bearer"
             }
    end
  end

  describe "merge_active_form_data/3" do
    test "merges active form data when selector matches" do
      form = form("<input type=\"text\" name=\"name\" value=\"Aragorn\" />")
      active = FormData.add_data(FormData.new(), "name", "Strider")

      merged = SubmissionPlan.merge_active_form_data(form, form.selector, active)

      assert merged.data["name"] == "Strider"
    end

    test "returns form defaults when selector does not match" do
      form = form("<input type=\"text\" name=\"name\" value=\"Aragorn\" />")
      active = FormData.add_data(FormData.new(), "name", "Strider")

      merged = SubmissionPlan.merge_active_form_data(form, "#other-form", active)

      assert merged == form.form_data
    end
  end

  describe "merge_submitter_data/2" do
    test "includes submitter name/value for submit buttons" do
      form =
        form("""
        <input type="text" name="name" value="Galadriel" />
        <button type="submit" name="commit" value="save">Save</button>
        """)

      merged = SubmissionPlan.merge_submitter_data(form.form_data, submitter(form, "Save"))

      assert merged.data["commit"] == "save"
      assert merged.data["name"] == "Galadriel"
    end

    test "ignores non-submit buttons" do
      form = form("<button type=\"button\" name=\"commit\" value=\"preview\">Preview</button>")

      merged = SubmissionPlan.merge_submitter_data(FormData.new(), submitter(form, "Preview"))

      assert merged == FormData.new()
    end
  end

  describe "merge_additional_data/2" do
    test "keeps additional data precedence over submitter contribution" do
      form = form("<button type=\"submit\" name=\"commit\" value=\"save\">Save</button>")
      additional = FormData.add_data(FormData.new(), "commit", "override")

      merged = SubmissionPlan.merge_additional_data(additional, submitter(form, "Save"))

      assert merged.data["commit"] == "override"
    end
  end

  defp form(inner, attrs \\ "") do
    Form.find!(
      """
      <form id="submission-form" action="/records" method="post" #{attrs}>
        #{inner}
      </form>
      """,
      "#submission-form"
    )
  end

  defp submitter(form, text) do
    Button.find!(form.parsed, "button", text)
  end
end
