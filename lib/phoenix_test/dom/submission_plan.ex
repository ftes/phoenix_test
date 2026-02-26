defmodule PhoenixTest.DOM.SubmissionPlan do
  @moduledoc """
  Shared submission preflight/planning helpers used by Static and Live drivers.

  This module intentionally contains DOM/form semantics only. Transport concerns
  (conn dispatch, redirects, LiveView event rendering) remain in adapters.
  """

  alias PhoenixTest.DOM.Submitter
  alias PhoenixTest.Element.Form
  alias PhoenixTest.FormData

  @doc """
  Merges the form's serialized defaults with provided form data.
  """
  def merge_form_data(%Form{} = form, %FormData{} = form_data) do
    FormData.merge(form.form_data, form_data)
  end

  @doc """
  Merges active-form data only when it belongs to the target form selector.
  """
  def merge_active_form_data(%Form{} = form, active_form_selector, %FormData{} = active_form_data) do
    if active_form_selector == form.selector do
      merge_form_data(form, active_form_data)
    else
      form.form_data
    end
  end

  @doc """
  Appends submitter name/value contribution to form data.
  """
  def merge_submitter_data(%FormData{} = form_data, submitter) do
    FormData.merge(form_data, Submitter.submitter_data(submitter))
  end

  @doc """
  Merges submitter contribution into extra payload data while preserving caller
  overrides from `additional_data`.
  """
  def merge_additional_data(%FormData{} = additional_data, submitter) do
    FormData.merge(Submitter.submitter_data(submitter), additional_data)
  end
end
