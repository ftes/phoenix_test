defmodule PhoenixTest.DOM.ButtonSubmitPreflight do
  @moduledoc """
  Shared preflight for submitter-button interactions.

  Resolves owner form, merges active-form data for that owner, and applies
  constraint validation before adapters perform transport-specific submit paths.
  """

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.DOM.ConstraintValidation
  alias PhoenixTest.DOM.SubmissionPlan
  alias PhoenixTest.Element.Button

  @doc """
  Evaluates whether a clicked button is submittable for the current DOM/session.

  Returns:
  - `{:ok, %{form: ..., form_data: ..., active_form_matches?: boolean}}`
  - `:invalid` when constraint validation blocks submit
  - `:not_owner` when button is not a submitter for any owner form
  """
  def evaluate(%Button{} = button, html, %ActiveForm{} = active_form) do
    if Button.belongs_to_form?(button, html) do
      form = Button.parent_form!(button, html)
      active_form_matches? = active_form.selector == form.selector
      form_data = SubmissionPlan.merge_active_form_data(form, active_form.selector, active_form.form_data)

      if ConstraintValidation.valid_for_submit?(form, form_data, button) do
        {:ok, %{form: form, form_data: form_data, active_form_matches?: active_form_matches?}}
      else
        :invalid
      end
    else
      :not_owner
    end
  end
end
