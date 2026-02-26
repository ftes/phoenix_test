defmodule PhoenixTest.ElementTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Element
  alias PhoenixTest.Element.Field
  alias PhoenixTest.Query

  describe "build_selector/2" do
    test "builds a selector based on id if id is present" do
      data =
        Query.find!(
          """
          <input id="name" type="text" name="name" value="Hello world"/>
          """,
          "input"
        )

      selector = Element.build_selector(data)

      assert ~s|[id="name"]| = selector
    end

    test "builds a composite selector if id isn't present" do
      data =
        Query.find!(
          """
          <input type="text" name="name" />
          """,
          "input"
        )

      selector = Element.build_selector(data)

      assert ~s(input[type="text"][name="name"]) = selector
    end

    test "includes simple phx-* attributes when id isn't present" do
      data =
        Query.find!(
          """
          <input phx-click="save-user" type="text" name="name" />
          """,
          "input"
        )

      selector = Element.build_selector(data)

      assert ~s(input[phx-click="save-user"][type="text"][name="name"]) = selector
    end

    test "ignores complex `phx-*` LiveView.JS attributes when id isn't present" do
      %{ops: data} = Phoenix.LiveView.JS.navigate("/live/page_2")
      {:ok, encoded_action} = Jason.encode(data)

      data =
        Query.find!(
          """
          <input phx-click=#{encoded_action} type="text" name="name" />
          """,
          "input"
        )

      selector = Element.build_selector(data)

      assert ~s(input[type="text"][name="name"]) = selector
    end
  end

  describe "selector_has_id?/2" do
    test "returns true if selector has #<id>" do
      selector = "#name"

      assert Element.selector_has_id?(selector, "name")
      refute Element.selector_has_id?(selector, "nome")
    end

    test "returns true if selector has [id=<id>] with single quotes" do
      selector = "[id='name']"

      assert Element.selector_has_id?(selector, "name")
      refute Element.selector_has_id?(selector, "nome")
    end

    test "returns true if selector has [id=<id>] with double quotes" do
      selector = ~s|[id="user_name"]|

      assert Element.selector_has_id?(selector, "user_name")
      refute Element.selector_has_id?(selector, "user_nome")
    end

    test "returns false if selector doesn't have id" do
      selector = "[data-role='name']"

      refute Element.selector_has_id?(selector, "name")
      refute Element.selector_has_id?(selector, "nome")
    end
  end

  describe "has_ancestor?/3" do
    test "returns true when descendant has matching ancestor" do
      html = """
      <form id="user-form">
        <label>
          Email
          <input type="text" name="email" />
        </label>
      </form>
      """

      field = Field.find_input!(html, "input", "Email", exact: true)

      assert Element.has_ancestor?(html, "form", field)
    end

    test "returns false when descendant has no matching ancestor" do
      html = """
      <div>
        <label>
          Email
          <input type="text" name="email" />
        </label>
      </div>
      """

      field = Field.find_input!(html, "input", "Email", exact: true)

      refute Element.has_ancestor?(html, "form", field)
    end

    test "accepts a {selector, text} descendant tuple" do
      html = """
      <form>
        <button>Save</button>
      </form>
      """

      assert Element.has_ancestor?(html, "form", {"button", "Save"})
      refute Element.has_ancestor?(html, "form", {"button", "Delete"})
    end
  end
end
