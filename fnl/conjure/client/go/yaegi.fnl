(local {: autoload} (require :conjure.nfnl.module))
(local a (autoload :conjure.aniseed.core))
(local core (autoload :conjure.nfnl.core))
(local str (autoload :conjure.aniseed.string))
(local stdio (autoload :conjure.remote.stdio))
(local config (autoload :conjure.config))
(local mapping (autoload :conjure.mapping))
(local client (autoload :conjure.client))
(local log (autoload :conjure.log))
(local go-mod (autoload :conjure.client.go.go_mod))

(config.merge {:client {:go {:yaegi {:command :yaegi
                                     :prompt_pattern "> "
                                     :value_prefix_pattern "^: "
                                     :delay-stderr-ms 16}}}})

(when (config.get-in [:mapping :enable_defaults])
  (config.merge {:client {:go {:yaegi {:mapping {:start :cs
                                                 :stop :cS
                                                 :interrupt :ei}}}}}))

(local localstate {})
(local import-replacements-key :import-replacements)

(local cfg (config.get-in-fn [:client :go :yaegi]))
(local state (client.new-state #(do
                                  {:repl nil})))

(local buf-suffix :.go)
(local comment-prefix "// ")

(fn form-node? [node]
  (case (node:type)
    :short_var_declaration true
    :const_declaration true
    :var_declaration true
    :expression_statement true
    :call_expression true
    :assignment_statement true
    :binary_expression true
    :parenthesized_expression true
    :type_declaration true
    :function_declaration true
    :method_declaration true
    :import_declaration true
    :with_statement true
    :decorated_definition true
    :for_statement true
    _ false))

(fn with-repl-or-warn [f _]
  (let [repl (state :repl)]
    (if repl
        (f repl)
        (log.append [(.. comment-prefix "No REPL running")]))))

(fn unbatch [msgs]
  {:out (->> msgs
             (a.map #(or (a.get $1 :out) (a.get $1 :err)))
             (str.join ""))})

(fn format-msg [msg]
  (->> (-> msg
           (a.get :out)
           (str.split "\n"))
       (a.map (fn [line]
                (if (not (cfg [:value_prefix_pattern])) line
                    (string.match line (cfg [:value_prefix_pattern])) (string.gsub line
                                                                                   (cfg [:value_prefix_pattern])
                                                                                   "")
                    line)))
       (a.filter #(not (str.blank? $1)))))

; Takes in an import statement node and replaces any full package paths with a local 
; alias if one exists in the current project. E.g. "github.com/user/project/pkg" -> "./pkg"
(fn localise-imports [imports]
  (fn req-lines [lines reps]
    (icollect [_ line (ipairs lines)]
      (if (string.match line "\"")
          (accumulate [new-line line from to (pairs reps)]
            (string.gsub new-line from to))
          line)))

  (local import-replacements (. localstate import-replacements-key))
  (-> (vim.split imports "\n")
      (req-lines import-replacements)
      (table.concat "\n")))

(fn eval-str [opts]
  (let [code (if (= (a.pr-str opts.node) "#<<node import_declaration>>")
                 (localise-imports opts.code)
                 opts.code)]
    (with-repl-or-warn (fn [repl]
                         (repl.send (.. code "\n")
                                    (fn [msgs]
                                      (let [msgs (-> msgs unbatch format-msg)]
                                        (opts.on-result (a.last msgs))
                                        (log.append msgs)))
                                    {:batch? true})))))

(fn eval-file [opts]
  (->> (core.slurp opts.file-path)
       (core.assoc opts :code)
       eval-str))

(fn display-repl-status [status]
  (log.append [(.. comment-prefix (cfg [:command]) " (" (or status "no status")
                   ")")] {:break? true}))

(fn stop []
  (let [repl (state :repl)]
    (when repl
      (repl.destroy)
      (display-repl-status :stopped)
      (a.assoc (state) :repl nil))))

(fn start []
  (tset localstate import-replacements-key
        (-> (.. (vim.fn.getcwd) :/go.mod)
            (core.slurp)
            (go-mod.to-import-replacements-map)))
  (if (state :repl)
      (log.append [(.. comment-prefix "Can't start, REPL is already running.")
                   (.. comment-prefix "Stop the REPL with "
                       (config.get-in [:mapping :prefix]) (cfg [:mapping :stop]))]
                  {:break? true})
      (a.assoc (state) :repl
               (stdio.start {:prompt-pattern (cfg [:prompt_pattern])
                             :cmd (cfg [:command])
                             :on-success (fn []
                                           (display-repl-status :started))
                             :on-error (fn [err]
                                         (display-repl-status err))
                             :on-exit (fn [code signal]
                                        (when (and (= :number (type code))
                                                   (> code 0))
                                          (log.append [(.. comment-prefix
                                                           "process exited with code "
                                                           code)]))
                                        (when (and (= :number (type signal))
                                                   (> signal 0))
                                          (log.append [(.. comment-prefix
                                                           "process exited with signal "
                                                           signal)]))
                                        (stop))
                             :on-stray-output (fn [msg]
                                                (log.append (format-msg msg)))}))))

(fn interrupt []
  (with-repl-or-warn (fn [repl]
                       (log.append [(.. comment-prefix
                                        " Sending interrupt signal.")]
                                   {:break? true})
                       (repl.send-signal :sigint))))

(fn on-load []
  (start))

(fn on-filetype []
  (mapping.buf :GoStart (cfg [:mapping :start]) start
               {:desc "Start the Go REPL"})
  (mapping.buf :GoStop (cfg [:mapping :stop]) stop {:desc "Stop the Go REPL"})
  (mapping.buf :GoInterrupt (cfg [:mapping :interrupt]) interrupt
               {:desc "Interrupt the Go REPL"}))

(fn on-exit []
  (stop))

{: buf-suffix
 : comment-prefix
 : form-node?
 : unbatch
 : format-msg
 : eval-str
 : eval-file
 : stop
 : start
 : interrupt
 : on-load
 : on-filetype
 : on-exit}
