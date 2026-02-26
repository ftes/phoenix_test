defmodule PhoenixTest.DomOracle.ContractCatalog do
  @moduledoc false
  @contracts [
    %{
      id: "C001",
      name: "disabled hidden control excluded",
      path: "/page/contracts/c001",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c001-form"},
      expected: :match
    },
    %{
      id: "C002",
      name: "checked checkbox without value defaults to on",
      path: "/page/contracts/c002",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c002-form"},
      expected: :match
    },
    %{
      id: "C003",
      name: "disabled fieldset descendants excluded",
      path: "/page/contracts/c003",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c003-form"},
      expected: :match
    },
    %{
      id: "C004",
      name: "form associated input submit flow",
      path: "/page/contracts/c004",
      steps: [
        %{
          "op" => "fill_in",
          "selector" => "#c004-name",
          "label" => "External Name",
          "value" => "outside-updated",
          "exact" => true
        },
        %{"op" => "submit", "form_selector" => "#c004-form"}
      ],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C005",
      name: "form associated select submit flow",
      path: "/page/contracts/c005",
      steps: [
        %{
          "op" => "select",
          "selector" => "#c005-race",
          "from" => "Race",
          "option" => "Human",
          "exact" => true
        },
        %{"op" => "submit", "form_selector" => "#c005-form"}
      ],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C006",
      name: "type button with form is not submitter",
      path: "/page/contracts/c006",
      steps: [%{"op" => "click_button", "text" => "External Action", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C007",
      name: "default submitter supports input submit",
      path: "/page/contracts/c007",
      steps: [
        %{
          "op" => "fill_in",
          "selector" => "#c007-name",
          "label" => "Name",
          "value" => "Aragorn",
          "exact" => true
        },
        %{"op" => "submit", "form_selector" => "#c007-form"}
      ],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C008",
      name: "hidden fallback is scoped by form owner",
      path: "/page/contracts/c008",
      steps: [
        %{
          "op" => "uncheck",
          "selector" => "#c008-subscribe-a",
          "label" => "Subscribe A",
          "exact" => true
        }
      ],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c008-form-a"},
      expected: :match
    },
    %{
      id: "C009",
      name: "disabled button click blocked",
      path: "/page/contracts/c009",
      steps: [%{"op" => "click_button", "text" => "Disabled Save", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :match,
      timeout_ms: 2_000
    },
    %{
      id: "C010",
      name: "radio without value defaults to on",
      path: "/page/contracts/c010",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c010-form"},
      expected: :match
    },
    %{
      id: "C011",
      name: "only actual submitter contributes name value",
      path: "/page/contracts/c011",
      steps: [%{"op" => "click_button", "text" => "Save B", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C012",
      name: "submitter formmethod and formaction override",
      path: "/page/contracts/c012",
      steps: [%{"op" => "click_button", "text" => "Save Override", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C013",
      name: "controls without name are excluded",
      path: "/page/contracts/c013",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c013-form"},
      expected: :match
    },
    %{
      id: "C014",
      name: "single select no selected defaults to first option",
      path: "/page/contracts/c014",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c014-form"},
      expected: :match
    },
    %{
      id: "C015",
      name: "multiple select without selected options yields no entries",
      path: "/page/contracts/c015",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c015-form"},
      expected: :match
    },
    %{
      id: "C016",
      name: "explicit and implicit label association parity",
      path: "/page/contracts/c016",
      steps: [
        %{"op" => "fill_in", "label" => "Explicit Name", "value" => "Aragorn", "exact" => true},
        %{"op" => "fill_in", "label" => "Implicit Name", "value" => "Legolas", "exact" => true}
      ],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c016-form"},
      expected: :match
    },
    %{
      id: "C017",
      name: "image submitter coordinates handling",
      path: "/page/contracts/c017",
      steps: [%{"op" => "click_button", "text" => "Image Save", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :ignore
    },
    %{
      id: "C018",
      name: "constraint validation blocks invalid submit",
      path: "/page/contracts/c018",
      steps: [%{"op" => "click_button", "text" => "Save", "exact" => true}],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C019",
      name: "readonly controls are successful",
      path: "/page/contracts/c019",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c019-form"},
      expected: :match
    },
    %{
      id: "C020",
      name: "option text is value fallback when missing value attribute",
      path: "/page/contracts/c020",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c020-form"},
      expected: :match
    },
    %{
      id: "C021",
      name: "disabled optgroup options are excluded from single select fallback",
      path: "/page/contracts/c021",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c021-form"},
      expected: :match
    },
    %{
      id: "C022",
      name: "multiple select excludes disabled selected options",
      path: "/page/contracts/c022",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c022-form"},
      expected: :match
    },
    %{
      id: "C023",
      name: "external textarea with form attribute submits with owner form",
      path: "/page/contracts/c023",
      steps: [
        %{
          "op" => "fill_in",
          "selector" => "#c023-notes",
          "label" => "Notes",
          "value" => "outside-notes",
          "exact" => true
        },
        %{"op" => "submit", "form_selector" => "#c023-form"}
      ],
      capture: %{"type" => "submit_result"},
      expected: :match
    },
    %{
      id: "C024",
      name: "external checkbox hidden fallback is scoped per owner form",
      path: "/page/contracts/c024",
      steps: [
        %{
          "op" => "uncheck",
          "selector" => "#c024-subscribe-a",
          "label" => "Subscribe A",
          "exact" => true
        }
      ],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c024-form-a"},
      expected: :match
    },
    %{
      id: "C025",
      name: "checked hidden fallback retains both entries for same non-array name",
      path: "/page/contracts/c025",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c025-form"},
      expected: :match
    },
    %{
      id: "C026",
      name: "multiple checked checkboxes with same non-array name keep all entries",
      path: "/page/contracts/c026",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c026-form"},
      expected: :match
    },
    %{
      id: "C027",
      name: "repeated text controls with same non-array name keep ordered entries",
      path: "/page/contracts/c027",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c027-form"},
      expected: :match
    },
    %{
      id: "C028",
      name: "array names preserve duplicate values",
      path: "/page/contracts/c028",
      steps: [],
      capture: %{"type" => "form_snapshot", "form_selector" => "#c028-form"},
      expected: :match
    }
  ]

  def contracts, do: @contracts

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

  def contract_html("c019") do
    """
    <main data-contract="c019">
      <h1>C019</h1>

      <form id="c019-form" action="/page/create_record" method="post">
        <label for="c019-readonly-name">Readonly Name</label>
        <input id="c019-readonly-name" type="text" name="readonly_name" value="kept" readonly />

        <label for="c019-editable-name">Editable Name</label>
        <input id="c019-editable-name" type="text" name="editable_name" value="open" />
      </form>
    </main>
    """
  end

  def contract_html("c020") do
    """
    <main data-contract="c020">
      <h1>C020</h1>

      <form id="c020-form" action="/page/create_record" method="post">
        <label for="c020-race">Race</label>
        <select id="c020-race" name="race">
          <option selected>Human</option>
          <option value="elf">Elf</option>
        </select>
      </form>
    </main>
    """
  end

  def contract_html("c021") do
    """
    <main data-contract="c021">
      <h1>C021</h1>

      <form id="c021-form" action="/page/create_record" method="post">
        <label for="c021-pet">Pet</label>
        <select id="c021-pet" name="pet">
          <optgroup label="Disabled Group" disabled>
            <option value="cat" selected>Cat</option>
          </optgroup>
          <option value="dog">Dog</option>
        </select>
      </form>
    </main>
    """
  end

  def contract_html("c022") do
    """
    <main data-contract="c022">
      <h1>C022</h1>

      <form id="c022-form" action="/page/create_record" method="post">
        <label for="c022-roles">Roles</label>
        <select id="c022-roles" name="roles[]" multiple>
          <option value="admin" selected>Admin</option>
          <option value="editor" selected disabled>Editor</option>
          <option value="viewer">Viewer</option>
        </select>
      </form>
    </main>
    """
  end

  def contract_html("c023") do
    """
    <main data-contract="c023">
      <h1>C023</h1>

      <form id="c023-form" action="/page/create_record" method="post"></form>

      <label for="c023-notes">Notes</label>
      <textarea id="c023-notes" form="c023-form" name="notes">outside-default</textarea>
    </main>
    """
  end

  def contract_html("c024") do
    """
    <main data-contract="c024">
      <h1>C024</h1>

      <form id="c024-form-a" action="/page/create_record" method="post"></form>
      <input type="hidden" name="subscribe" form="c024-form-a" value="off_a" />
      <label for="c024-subscribe-a">Subscribe A</label>
      <input
        id="c024-subscribe-a"
        type="checkbox"
        form="c024-form-a"
        name="subscribe"
        value="on_a"
        checked
      />

      <form id="c024-form-b" action="/page/create_record" method="post"></form>
      <input type="hidden" name="subscribe" form="c024-form-b" value="off_b" />
      <label for="c024-subscribe-b">Subscribe B</label>
      <input
        id="c024-subscribe-b"
        type="checkbox"
        form="c024-form-b"
        name="subscribe"
        value="on_b"
        checked
      />
    </main>
    """
  end

  def contract_html("c025") do
    """
    <main data-contract="c025">
      <h1>C025</h1>

      <form id="c025-form" action="/page/create_record" method="post">
        <input type="hidden" name="notify" value="off" />
        <label for="c025-notify">Notify</label>
        <input id="c025-notify" type="checkbox" name="notify" value="on" checked />
      </form>
    </main>
    """
  end

  def contract_html("c026") do
    """
    <main data-contract="c026">
      <h1>C026</h1>

      <form id="c026-form" action="/page/create_record" method="post">
        <label for="c026-role-admin">Role Admin</label>
        <input id="c026-role-admin" type="checkbox" name="role" value="admin" checked />

        <label for="c026-role-editor">Role Editor</label>
        <input id="c026-role-editor" type="checkbox" name="role" value="editor" checked />
      </form>
    </main>
    """
  end

  def contract_html("c027") do
    """
    <main data-contract="c027">
      <h1>C027</h1>

      <form id="c027-form" action="/page/create_record" method="post">
        <label for="c027-tag-a">Tag A</label>
        <input id="c027-tag-a" type="text" name="tag" value="one" />

        <label for="c027-tag-b">Tag B</label>
        <input id="c027-tag-b" type="text" name="tag" value="two" />
      </form>
    </main>
    """
  end

  def contract_html("c028") do
    """
    <main data-contract="c028">
      <h1>C028</h1>

      <form id="c028-form" action="/page/create_record" method="post">
        <label for="c028-role-a">Role A</label>
        <input id="c028-role-a" type="checkbox" name="roles[]" value="viewer" checked />

        <label for="c028-role-b">Role B</label>
        <input id="c028-role-b" type="checkbox" name="roles[]" value="viewer" checked />
      </form>
    </main>
    """
  end

  def contract_html(_), do: nil
end
