-- [nfnl] fnl/conjure-spec/client/go/yaegi_spec.fnl
local _local_1_ = require("plenary.busted")
local describe = _local_1_["describe"]
local it = _local_1_["it"]
local assert = require("luassert.assert")
local yaegi = require("conjure.client.go.yaegi")
local function _2_()
  local function _3_()
    return assert.equal(0, #yaegi["to-import-replacements-map"](""))
  end
  it("import-replacements-map returns empty table with empty string", _3_)
  local function _4_()
    return assert.equal(0, #yaegi["to-import-replacements-map"]("require require hello test module"))
  end
  it("import-replacements-map with invalid input returns empty structure", _4_)
  local function _5_()
    local actual = yaegi["to-import-replacements-map"]("module github.com/user/module\n\ngo 1.25\n\nrequire (\n\9go.opentelemetry.io/otel/trace v1.38.0\n\9golang.org/x/crypto v0.42.0\n)")
    assert.equal(".", actual["github.com/user/"])
    assert.equal("./vendor/go.opentelemetry.io/otel/trace", actual["go.opentelemetry.io/otel/trace"])
    return assert.equal("./vendor/golang.org/x/crypto", actual["golang.org/x/crypto"])
  end
  it("import-replacements-map with valid input", _5_)
  local function _6_()
    local actual = yaegi["to-import-replacements-map"]("\n\9\9\9\9\9\9\9\9  \n\9\9\9\9\9\9\9\9  \n\9\9\9\9\9\9\9\9  module github.com/user/module\n\ngo 1.25\n\nrequire (\n\9go.opentelemetry.io/otel/trace v1.38.0\n\9golang.org/x/crypto v0.42.0\n)")
    return assert.equal(".", actual["github.com/user/"])
  end
  it("import-replacements-map with module not on first line", _6_)
  local function _7_()
    local actual = yaegi["to-import-replacements-map"]("// testing\n                                                                  // testing\n                                                                  // this is a module\n\9\9\9\9\9\9\9\9  module github.com/user/module // this is a comment after the module\n\ngo 1.25\n\n// require list\nrequire ( // requiring require\n\9go.opentelemetry.io/otel/trace v1.38.0\n\9golang.org/x/crypto v0.42.0\n)")
    assert.equal(".", actual["github.com/user/"])
    assert.equal("./vendor/go.opentelemetry.io/otel/trace", actual["go.opentelemetry.io/otel/trace"])
    return assert.equal("./vendor/golang.org/x/crypto", actual["golang.org/x/crypto"])
  end
  return it("import-replacements-map with comments before module", _7_)
end
return describe("yaegi", _2_)
