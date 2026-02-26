defmodule PhoenixTest.DOM.FormSerializer do
  @moduledoc false

  alias PhoenixTest.DOM.SuccessfulControls
  alias PhoenixTest.FormData

  def to_form_data(%LazyHTML{} = form) do
    FormData.add_data(FormData.new(), SuccessfulControls.entries(form))
  end
end
