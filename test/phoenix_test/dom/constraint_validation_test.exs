defmodule PhoenixTest.DOM.ConstraintValidationTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.DOM.ConstraintValidation
  alias PhoenixTest.Element.Button
  alias PhoenixTest.Element.Form
  alias PhoenixTest.FormData

  describe "valid_for_submit?/3" do
    test "blocks required and email violations" do
      form =
        form("""
        <input type="text" name="required_name" required />
        <input type="email" name="email" value="not-an-email" />
        <button type="submit">Save</button>
        """)

      refute ConstraintValidation.valid_for_submit?(form, form.form_data, submitter(form, "Save"))
    end

    test "respects form novalidate" do
      form =
        form(
          """
          <input type="text" name="required_name" required />
          <input type="email" name="email" value="not-an-email" />
          """,
          "novalidate"
        )

      assert ConstraintValidation.valid_for_submit?(form, form.form_data)
    end

    test "respects submitter formnovalidate" do
      form =
        form("""
        <input type="text" name="required_name" required />
        <input type="email" name="email" value="not-an-email" />
        <button type="submit">Save</button>
        <button type="submit" formnovalidate>Bypass</button>
        """)

      refute ConstraintValidation.valid_for_submit?(form, form.form_data, submitter(form, "Save"))
      assert ConstraintValidation.valid_for_submit?(form, form.form_data, submitter(form, "Bypass"))
    end

    test "blocks pattern mismatches" do
      form =
        form("""
        <input type="text" name="code" pattern="[A-Z]{3}" value="ab1" />
        """)

      refute ConstraintValidation.valid_for_submit?(form, form.form_data)
    end

    test "blocks minlength and maxlength mismatches" do
      form =
        form("""
        <input type="text" name="too_short" minlength="4" value="abc" />
        <textarea name="too_long" maxlength="4">abcde</textarea>
        """)

      refute ConstraintValidation.valid_for_submit?(form, form.form_data)
    end

    test "blocks numeric min and max mismatches" do
      form =
        form("""
        <input type="number" name="min_age" min="18" value="17" />
        <input type="number" name="max_age" max="65" value="66" />
        """)

      refute ConstraintValidation.valid_for_submit?(form, form.form_data)
    end

    test "blocks numeric step mismatch" do
      form =
        form("""
        <input type="number" name="age" min="1" step="2" value="6" />
        """)

      refute ConstraintValidation.valid_for_submit?(form, form.form_data)
    end

    test "uses min as step base for numeric step validation" do
      form =
        form("""
        <input type="number" name="age" min="1" step="2" value="5" />
        """)

      assert ConstraintValidation.valid_for_submit?(form, form.form_data)
    end

    test "uses merged runtime form data values during validation" do
      form =
        form("""
        <input type="text" name="name" minlength="5" value="Legolas" />
        """)

      assert ConstraintValidation.valid_for_submit?(form, form.form_data)

      invalid_data =
        FormData.merge(form.form_data, FormData.add_data(FormData.new(), "name", "Sam"))

      refute ConstraintValidation.valid_for_submit?(form, invalid_data)
    end
  end

  defp form(inner, attrs \\ "") do
    Form.find!(
      """
      <form id="constraint-form" action="/page/create_record" method="post" #{attrs}>
        #{inner}
      </form>
      """,
      "#constraint-form"
    )
  end

  defp submitter(form, text) do
    Button.find!(form.parsed, "button", text)
  end
end
