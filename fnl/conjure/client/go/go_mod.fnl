(local {: autoload : define} (require :conjure.nfnl.module))
(local str (autoload :conjure.aniseed.string))
(local a (autoload :conjure.aniseed.core))

(local M (define :conjure.client.go.go_mod))

(fn str-starts-with [str start]
  (= (string.sub str 1 (length start)) start))

(fn first-matching [tbl str]
  "gets the first string that contains the second arg to this function"
  (each [_ val (pairs tbl)]
    (when (not= (string.find val str) nil)
      (lua "return val"))))

(fn remove-comments [mod-file]
  (->> (icollect [_ line (ipairs (vim.split mod-file "\n"))]
         (string.gsub line "//.*" ""))
       (str.join "\n")))

(fn mod-name [raw]
  (-?> raw
       (vim.trim)
       (vim.split "\n")
       (first-matching :module)
       (string.gsub :module "")
       (vim.trim)))

(fn parse-deps-to-vendor-table [raw-reqs]
  "takes in a raw string and returns a table that maps dependencies to the local
  vendor location. e.g. {:golang.org/x/crypto :./vendor/golang.org/x/crypto }"
  (fn list-to-map [reqstbl]
    (collect [_ v (ipairs reqstbl)]
      (let [rqr (-> v
                    (vim.trim)
                    (vim.split " ")
                    (a.first))]
        (when (not (or (str-starts-with rqr "(") (str-starts-with rqr ")")
                       (= rqr "")))
          (values rqr (.. :./vendor/ rqr))))))

  (-> raw-reqs
      (vim.split "\n")
      (list-to-map)))

(fn import-rep-map [btwn-reqs]
  "Accepts a list where the first element is the first thing before 'require'
and the second element is everything after but before the second.
Returns the map of modules to their local versions."
  (local res {})
  (local module-name (mod-name (a.first btwn-reqs)))
  (local required-modules (a.second btwn-reqs))
  (when (not= module-name nil)
    (tset res module-name "."))
  (when (not= required-modules nil)
    (each [actual replacement (pairs (-> required-modules
                                         (parse-deps-to-vendor-table)))]
      (tset res actual replacement)))
  res)

(fn M.to-import-replacements-map [mod-file]
  (fn first-2 [tbl] [(a.first tbl) (a.second tbl)])

  (-> mod-file (remove-comments) (vim.split :require) (first-2)
      (import-rep-map)))

M
