defmodule PhoenixTest.DOM.FormDataPrunerTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.DOM.FormDataPruner
  alias PhoenixTest.Element.Form
  alias PhoenixTest.FormData

  describe "prune_removed_fields/3" do
    test "keeps names still present in the form and associated controls" do
      html = """
      <form id="profile-form">
        <input name="inside" value="inside-default" />
      </form>
      <input name="associated" form="profile-form" value="associated-default" />
      <input name="foreign" form="other-form" value="foreign-default" />
      """

      form = Form.find!(html, "form")

      form_data =
        FormData.new()
        |> FormData.add_data("inside", "inside-updated")
        |> FormData.add_data("associated", "associated-updated")
        |> FormData.add_data("removed", "removed-value")
        |> FormData.add_data("foreign", "foreign-value")

      pruned = FormDataPruner.prune_removed_fields(form_data, form, html)

      assert FormData.has_data?(pruned, "inside", "inside-updated")
      assert FormData.has_data?(pruned, "associated", "associated-updated")
      refute FormData.has_data?(pruned, "removed", "removed-value")
      refute FormData.has_data?(pruned, "foreign", "foreign-value")
    end

    test "does not include associated controls when form id is absent" do
      html = """
      <form>
        <input name="inside" value="inside-default" />
      </form>
      <input name="associated" form="profile-form" value="associated-default" />
      """

      form = Form.find!(html, "form")

      form_data =
        FormData.new()
        |> FormData.add_data("inside", "inside-updated")
        |> FormData.add_data("associated", "associated-updated")

      pruned = FormDataPruner.prune_removed_fields(form_data, form, html)

      assert FormData.has_data?(pruned, "inside", "inside-updated")
      refute FormData.has_data?(pruned, "associated", "associated-updated")
    end
  end
end
