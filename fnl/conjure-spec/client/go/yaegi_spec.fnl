(local {: describe : it} (require :plenary.busted))
(local assert (require :luassert.assert))
(local yaegi (require :conjure.client.go.yaegi))

(describe :yaegi
          (fn []
            (it "import-replacements-map returns empty table with empty string"
                (fn []
                  (assert.equal 0
                                (length (yaegi.to-import-replacements-map "")))))
            (it "import-replacements-map with invalid input returns empty structure"
                (fn []
                  (assert.equal 0
                                (length (yaegi.to-import-replacements-map "require require hello test module")))))
            (it "import-replacements-map with valid input"
                (fn []
                  (local actual (yaegi.to-import-replacements-map "module github.com/user/module

go 1.25

require (
\tgo.opentelemetry.io/otel/trace v1.38.0
\tgolang.org/x/crypto v0.42.0
)"))
                  (assert.equal "." (. actual :github.com/user/))
                  (assert.equal :./vendor/go.opentelemetry.io/otel/trace
                                (. actual :go.opentelemetry.io/otel/trace))
                  (assert.equal :./vendor/golang.org/x/crypto
                                (. actual :golang.org/x/crypto))))
            (it "import-replacements-map with module not on first line"
                (fn []
                  (local actual (yaegi.to-import-replacements-map "
\t\t\t\t\t\t\t\t  
\t\t\t\t\t\t\t\t  
\t\t\t\t\t\t\t\t  module github.com/user/module

go 1.25

require (
\tgo.opentelemetry.io/otel/trace v1.38.0
\tgolang.org/x/crypto v0.42.0
)"))
                  (assert.equal "." (. actual :github.com/user/))))
            (it "import-replacements-map with comments before module"
                (fn []
                  (local actual (yaegi.to-import-replacements-map "// testing
                                                                  // testing
                                                                  // this is a module
\t\t\t\t\t\t\t\t  module github.com/user/module // this is a comment after the module

go 1.25

// require list
require ( // requiring require
\tgo.opentelemetry.io/otel/trace v1.38.0
\tgolang.org/x/crypto v0.42.0
)"))
                  (assert.equal "." (. actual :github.com/user/))
                  (assert.equal :./vendor/go.opentelemetry.io/otel/trace
                                (. actual :go.opentelemetry.io/otel/trace))
                  (assert.equal :./vendor/golang.org/x/crypto
                                (. actual :golang.org/x/crypto))))))
