defmodule PhoenixTest.DOM.FormSerializer do
  @moduledoc """
  Converts a parsed `<form>` into `PhoenixTest.FormData` using DOM-rule modules.

  Primary spec reference:

  - WHATWG HTML: constructing the form data set
    https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#constructing-the-form-data-set
  """

  alias PhoenixTest.DOM.SuccessfulControls
  alias PhoenixTest.FormData

  @doc """
  Builds `PhoenixTest.FormData` from successful control entries.
  """
  def to_form_data(%LazyHTML{} = form) do
    FormData.from_entries(SuccessfulControls.entries(form))
  end
end
