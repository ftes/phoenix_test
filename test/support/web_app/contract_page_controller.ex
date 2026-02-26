defmodule PhoenixTest.WebApp.ContractPageController do
  use Phoenix.Controller, formats: [html: "View"]

  def show(conn, %{"contract" => contract}) do
    case contract_html(contract) do
      nil -> send_resp(conn, 404, "Unknown contract fixture")
      html_content -> html(conn, html_content)
    end
  end

  def contract_html("c001") do
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

  def contract_html("c002") do
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

  def contract_html("c003") do
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

  def contract_html("c004") do
    """
    <main data-contract="c004">
      <h1>C004</h1>

      <form id="c004-form" action="/page/create_record" method="post"></form>
      <label for="c004-name">External Name</label>
      <input id="c004-name" form="c004-form" type="text" name="name" value="outside" />
    </main>
    """
  end

  def contract_html("c005") do
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

  def contract_html("c006") do
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

  def contract_html("c007") do
    """
    <main data-contract="c007">
      <h1>C007</h1>

      <form id="c007-form" action="/page/create_record" method="post">
        <label for="c007-name">Name</label>
        <input id="c007-name" type="text" name="name" value="Aragorn" />
        <input type="submit" name="save" value="Save" />
      </form>
    </main>
    """
  end

  def contract_html("c008") do
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

  def contract_html("c009") do
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

  def contract_html("c010") do
    """
    <main data-contract="c010">
      <h1>C010</h1>

      <form id="c010-form" action="/page/create_record" method="post">
        <label for="c010-contact">Contact</label>
        <input id="c010-contact" type="radio" name="contact" checked />
      </form>
    </main>
    """
  end

  def contract_html("c011") do
    """
    <main data-contract="c011">
      <h1>C011</h1>

      <form id="c011-form" action="/page/create_record" method="post">
        <input type="text" name="name" value="Aragorn" />
        <button type="submit" name="save_a" value="a">Save A</button>
        <button type="submit" name="save_b" value="b">Save B</button>
      </form>
    </main>
    """
  end

  def contract_html("c012") do
    """
    <main data-contract="c012">
      <h1>C012</h1>

      <form id="c012-form" action="/page/create_record" method="post">
        <input type="text" name="name" value="Aragorn" />
        <button
          id="c012-override"
          type="submit"
          name="save"
          value="override"
          formmethod="get"
          formaction="/page/get_record"
        >
          Save Override
        </button>
      </form>
    </main>
    """
  end

  def contract_html("c013") do
    """
    <main data-contract="c013">
      <h1>C013</h1>

      <form id="c013-form" action="/page/create_record" method="post">
        <label for="c013-no-name">No Name</label>
        <input id="c013-no-name" type="text" value="ignored" />

        <label for="c013-name">Name</label>
        <input id="c013-name" type="text" name="name" value="Aragorn" />
      </form>
    </main>
    """
  end

  def contract_html("c014") do
    """
    <main data-contract="c014">
      <h1>C014</h1>

      <form id="c014-form" action="/page/create_record" method="post">
        <label for="c014-race">Race</label>
        <select id="c014-race" name="race">
          <option value="human">Human</option>
          <option value="elf">Elf</option>
        </select>
      </form>
    </main>
    """
  end

  def contract_html("c015") do
    """
    <main data-contract="c015">
      <h1>C015</h1>

      <form id="c015-form" action="/page/create_record" method="post">
        <label for="c015-races">Races</label>
        <select id="c015-races" name="races[]" multiple>
          <option value="human">Human</option>
          <option value="elf">Elf</option>
        </select>
      </form>
    </main>
    """
  end

  def contract_html("c016") do
    """
    <main data-contract="c016">
      <h1>C016</h1>

      <form id="c016-form" action="/page/create_record" method="post">
        <label for="c016-explicit">Explicit Name</label>
        <input id="c016-explicit" type="text" name="explicit_name" />

        <label>
          Implicit Name
          <input id="c016-implicit" type="text" name="implicit_name" />
        </label>
      </form>
    </main>
    """
  end

  def contract_html("c017") do
    """
    <main data-contract="c017">
      <h1>C017</h1>

      <form id="c017-form" action="/page/create_record" method="post">
        <label for="c017-name">Name</label>
        <input id="c017-name" type="text" name="name" value="Aragorn" />

        <input
          id="c017-image"
          type="image"
          name="img"
          value="Image Save"
          alt="Image Save"
          src="/images/submit.png"
        />
      </form>
    </main>
    """
  end

  def contract_html("c018") do
    """
    <main data-contract="c018">
      <h1>C018</h1>

      <form id="c018-form" action="/page/create_record" method="post">
        <label for="c018-required">Required Name</label>
        <input id="c018-required" type="text" name="required_name" required />

        <label for="c018-email">Email</label>
        <input id="c018-email" type="email" name="email" value="not-an-email" />

        <label for="c018-pattern">Code</label>
        <input id="c018-pattern" type="text" name="code" pattern="[A-Z]{3}" value="ab1" />

        <label for="c018-age">Age</label>
        <input id="c018-age" type="number" name="age" min="18" max="65" step="2" value="17" />

        <label for="c018-bio">Bio</label>
        <textarea id="c018-bio" name="bio" minlength="5" maxlength="10">bad</textarea>

        <button type="submit">Save</button>
        <button type="submit" formnovalidate>Bypass Validation</button>
      </form>
    </main>
    """
  end

  def contract_html(_), do: nil
end
