defmodule PhoenixTest.WebApp.ContractPageController do
  use Phoenix.Controller, formats: [html: "View"]

  def show(conn, %{"contract" => contract}) do
    case contract do
      "c001" -> html(conn, c001_html())
      "c002" -> html(conn, c002_html())
      "c003" -> html(conn, c003_html())
      "c004" -> html(conn, c004_html())
      "c005" -> html(conn, c005_html())
      "c006" -> html(conn, c006_html())
      "c007" -> html(conn, c007_html())
      "c008" -> html(conn, c008_html())
      "c009" -> html(conn, c009_html())
      _ -> send_resp(conn, 404, "Unknown contract fixture")
    end
  end

  defp c001_html do
    """
    <main data-contract="c001">
      <h1>C001</h1>

      <form id="c001-form" action="/page/create_record" method="post">
        <input type="hidden" name="token" value="abc" disabled />
        <input type="text" name="name" value="Aragorn" />
      </form>
    </main>
    """
  end

  defp c002_html do
    """
    <main data-contract="c002">
      <h1>C002</h1>

      <form id="c002-form" action="/page/create_record" method="post">
        <label for="c002-admin">Admin</label>
        <input id="c002-admin" type="checkbox" name="admin" checked />
      </form>
    </main>
    """
  end

  defp c003_html do
    """
    <main data-contract="c003">
      <h1>C003</h1>

      <form id="c003-form" action="/page/create_record" method="post">
        <input type="text" name="outside" value="included" />

        <fieldset disabled>
          <legend>
            First legend
            <input type="text" name="legend_allowed" value="yes" />
          </legend>
          <input type="text" name="fieldset_blocked" value="no" />
        </fieldset>
      </form>
    </main>
    """
  end

  defp c004_html do
    """
    <main data-contract="c004">
      <h1>C004</h1>

      <form id="c004-form" action="/page/create_record" method="post"></form>
      <label for="c004-name">External Name</label>
      <input id="c004-name" form="c004-form" type="text" name="name" value="outside" />
    </main>
    """
  end

  defp c005_html do
    """
    <main data-contract="c005">
      <h1>C005</h1>

      <form id="c005-form" action="/page/create_record" method="post"></form>
      <label for="c005-race">Race</label>
      <select id="c005-race" form="c005-form" name="race">
        <option value="human">Human</option>
        <option value="elf" selected>Elf</option>
      </select>
    </main>
    """
  end

  defp c006_html do
    """
    <main data-contract="c006">
      <h1>C006</h1>

      <form id="c006-form" action="/page/create_record" method="post">
        <input type="text" name="name" value="Aragorn" />
      </form>

      <button id="c006-external-button" type="button" form="c006-form">External Action</button>
    </main>
    """
  end

  defp c007_html do
    """
    <main data-contract="c007">
      <h1>C007</h1>

      <form id="c007-form" action="/page/create_record" method="post">
        <input type="text" name="name" value="Aragorn" />
        <input type="submit" name="save" value="Save" />
      </form>
    </main>
    """
  end

  defp c008_html do
    """
    <main data-contract="c008">
      <h1>C008</h1>

      <form id="c008-form-a" action="/page/create_record" method="post">
        <input type="hidden" name="subscribe" value="off_a" />
        <label for="c008-subscribe-a">Subscribe A</label>
        <input id="c008-subscribe-a" type="checkbox" name="subscribe" value="on_a" checked />
      </form>

      <form id="c008-form-b" action="/page/create_record" method="post">
        <input type="hidden" name="subscribe" value="off_b" />
        <label for="c008-subscribe-b">Subscribe B</label>
        <input id="c008-subscribe-b" type="checkbox" name="subscribe" value="on_b" checked />
      </form>
    </main>
    """
  end

  defp c009_html do
    """
    <main data-contract="c009">
      <h1>C009</h1>

      <form id="c009-form" action="/page/create_record" method="post">
        <input type="text" name="name" value="Aragorn" />
        <button id="c009-disabled-submit" type="submit" disabled>Disabled Save</button>
      </form>
    </main>
    """
  end
end
