-- [nfnl] fnl/conjure/client/go/yaegi.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_["autoload"]
local a = autoload("conjure.aniseed.core")
local core = autoload("conjure.nfnl.core")
local str = autoload("conjure.aniseed.string")
local stdio = autoload("conjure.remote.stdio")
local config = autoload("conjure.config")
local mapping = autoload("conjure.mapping")
local client = autoload("conjure.client")
local log = autoload("conjure.log")
config.merge({client = {go = {yaegi = {command = "yaegi", prompt_pattern = "> ", value_prefix_pattern = "^: ", ["delay-stderr-ms"] = 16}}}})
if config["get-in"]({"mapping", "enable_defaults"}) then
  config.merge({client = {go = {yaegi = {mapping = {start = "cs", stop = "cS", interrupt = "ei"}}}}})
else
end
local localstate = {}
local import_replacements_key = "import-replacements"
local cfg = config["get-in-fn"]({"client", "go", "yaegi"})
local state
local function _3_()
  return {repl = nil}
end
state = client["new-state"](_3_)
local buf_suffix = ".go"
local comment_prefix = "// "
local function form_node_3f(node)
  local _4_ = node:type()
  if (_4_ == "short_var_declaration") then
    return true
  elseif (_4_ == "const_declaration") then
    return true
  elseif (_4_ == "var_declaration") then
    return true
  elseif (_4_ == "expression_statement") then
    return true
  elseif (_4_ == "call_expression") then
    return true
  elseif (_4_ == "assignment_statement") then
    return true
  elseif (_4_ == "binary_expression") then
    return true
  elseif (_4_ == "parenthesized_expression") then
    return true
  elseif (_4_ == "type_declaration") then
    return true
  elseif (_4_ == "function_declaration") then
    return true
  elseif (_4_ == "method_declaration") then
    return true
  elseif (_4_ == "import_declaration") then
    return true
  elseif (_4_ == "with_statement") then
    return true
  elseif (_4_ == "decorated_definition") then
    return true
  elseif (_4_ == "for_statement") then
    return true
  else
    local _ = _4_
    return false
  end
end
local function with_repl_or_warn(f, _)
  local repl = state("repl")
  if repl then
    return f(repl)
  else
    return log.append({(comment_prefix .. "No REPL running")})
  end
end
local function unbatch(msgs)
  local function _7_(_241)
    return (a.get(_241, "out") or a.get(_241, "err"))
  end
  return {out = str.join("", a.map(_7_, msgs))}
end
local function format_msg(msg)
  local function _8_(_241)
    return not str["blank?"](_241)
  end
  local function _9_(line)
    if not cfg({"value_prefix_pattern"}) then
      return line
    elseif string.match(line, cfg({"value_prefix_pattern"})) then
      return string.gsub(line, cfg({"value_prefix_pattern"}), "")
    else
      return line
    end
  end
  return a.filter(_8_, a.map(_9_, str.split(a.get(msg, "out"), "\n")))
end
local function first_2(tbl)
  return {a.first(tbl), a.second(tbl)}
end
local function first_matching(tbl, str0)
  for _, val in pairs(tbl) do
    if (string.find(val, str0) ~= nil) then
      return val
    else
    end
  end
  return nil
end
local function mod_name(raw)
  if (nil ~= raw) then
    local tmp_3_auto = vim.trim(raw)
    if (nil ~= tmp_3_auto) then
      local tmp_3_auto0 = vim.split(tmp_3_auto, "\n")
      if (nil ~= tmp_3_auto0) then
        local tmp_3_auto1 = first_matching(tmp_3_auto0, "module")
        if (nil ~= tmp_3_auto1) then
          local tmp_3_auto2 = string.gsub(tmp_3_auto1, "module", "")
          if (nil ~= tmp_3_auto2) then
            return vim.trim(tmp_3_auto2)
          else
            return nil
          end
        else
          return nil
        end
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end
local function str_starts_with(str0, start)
  return (string.sub(str0, 1, #start) == start)
end
local function reqs_map(reqstbl)
  local tbl_16_auto = {}
  for _, v in ipairs(reqstbl) do
    local k_17_auto, v_18_auto = nil, nil
    do
      local rqr = a.first(vim.split(vim.trim(v), " "))
      if not (str_starts_with(rqr, "(") or str_starts_with(rqr, ")") or (rqr == "")) then
        k_17_auto, v_18_auto = rqr, ("./vendor/" .. rqr)
      else
        k_17_auto, v_18_auto = nil
      end
    end
    if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then
      tbl_16_auto[k_17_auto] = v_18_auto
    else
    end
  end
  return tbl_16_auto
end
local function req_names(raw_reqs)
  return reqs_map(vim.split(raw_reqs, "\n"))
end
local function import_rep_map(btwn_reqs)
  local res = {}
  local module_name = mod_name(a.first(btwn_reqs))
  local required_modules = a.second(btwn_reqs)
  if (module_name ~= nil) then
    res[module_name] = "."
  else
  end
  if (required_modules ~= nil) then
    for actual, replacement in pairs(req_names(required_modules)) do
      res[actual] = replacement
    end
  else
  end
  return res
end
local function remove_comments(mod_file)
  local function _21_()
    local tbl_21_auto = {}
    local i_22_auto = 0
    for _, line in ipairs(vim.split(mod_file, "\n")) do
      local val_23_auto = string.gsub(line, "//.*", "")
      if (nil ~= val_23_auto) then
        i_22_auto = (i_22_auto + 1)
        tbl_21_auto[i_22_auto] = val_23_auto
      else
      end
    end
    return tbl_21_auto
  end
  return str.join("\n", _21_())
end
local function to_import_replacements_map(mod_file)
  return import_rep_map(first_2(vim.split(remove_comments(mod_file), "require")))
end
local function req_lines(lines, reps)
  local tbl_21_auto = {}
  local i_22_auto = 0
  for _, line in ipairs(lines) do
    local val_23_auto
    if string.match(line, "\"") then
      local new_line = line
      for from, to in pairs(reps) do
        new_line = string.gsub(new_line, from, to)
      end
      val_23_auto = new_line
    else
      val_23_auto = line
    end
    if (nil ~= val_23_auto) then
      i_22_auto = (i_22_auto + 1)
      tbl_21_auto[i_22_auto] = val_23_auto
    else
    end
  end
  return tbl_21_auto
end
local function localise_imports(imports)
  local import_replacements = localstate[import_replacements_key]
  log.dbg("modules >>", vim.inspect(import_replacements))
  return table.concat(req_lines(vim.split(imports, "\n"), import_replacements), "\n")
end
local function eval_str(opts)
  local code
  if (a["pr-str"](opts.node) == "#<<node import_declaration>>") then
    code = localise_imports(opts.code)
  else
    code = opts.code
  end
  local function _26_(repl)
    local function _27_(msgs)
      local msgs0 = format_msg(unbatch(msgs))
      opts["on-result"](a.last(msgs0))
      return log.append(msgs0)
    end
    return repl.send((code .. "\n"), _27_, {["batch?"] = true})
  end
  return with_repl_or_warn(_26_)
end
local function eval_file(opts)
  return eval_str(core.assoc(opts, "code", core.slurp(opts["file-path"])))
end
local function display_repl_status(status)
  return log.append({(comment_prefix .. cfg({"command"}) .. " (" .. (status or "no status") .. ")")}, {["break?"] = true})
end
local function stop()
  local repl = state("repl")
  if repl then
    repl.destroy()
    display_repl_status("stopped")
    return a.assoc(state(), "repl", nil)
  else
    return nil
  end
end
local function start()
  localstate[import_replacements_key] = to_import_replacements_map(core.slurp((vim.fn.getcwd() .. "/go.mod")))
  if state("repl") then
    return log.append({(comment_prefix .. "Can't start, REPL is already running."), (comment_prefix .. "Stop the REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "stop"}))}, {["break?"] = true})
  else
    local function _29_()
      return display_repl_status("started")
    end
    local function _30_(err)
      return display_repl_status(err)
    end
    local function _31_(code, signal)
      if (("number" == type(code)) and (code > 0)) then
        log.append({(comment_prefix .. "process exited with code " .. code)})
      else
      end
      if (("number" == type(signal)) and (signal > 0)) then
        log.append({(comment_prefix .. "process exited with signal " .. signal)})
      else
      end
      return stop()
    end
    local function _34_(msg)
      return log.append(format_msg(msg))
    end
    return a.assoc(state(), "repl", stdio.start({["prompt-pattern"] = cfg({"prompt_pattern"}), cmd = cfg({"command"}), ["on-success"] = _29_, ["on-error"] = _30_, ["on-exit"] = _31_, ["on-stray-output"] = _34_}))
  end
end
local function interrupt()
  local function _36_(repl)
    log.append({(comment_prefix .. " Sending interrupt signal.")}, {["break?"] = true})
    return repl["send-signal"]("sigint")
  end
  return with_repl_or_warn(_36_)
end
local function on_load()
  return start()
end
local function on_filetype()
  mapping.buf("GoStart", cfg({"mapping", "start"}), start, {desc = "Start the Go REPL"})
  mapping.buf("GoStop", cfg({"mapping", "stop"}), stop, {desc = "Stop the Go REPL"})
  return mapping.buf("GoInterrupt", cfg({"mapping", "interrupt"}), interrupt, {desc = "Interrupt the Go REPL"})
end
local function on_exit()
  return stop()
end
return {["buf-suffix"] = buf_suffix, ["comment-prefix"] = comment_prefix, ["form-node?"] = form_node_3f, unbatch = unbatch, ["format-msg"] = format_msg, ["eval-str"] = eval_str, ["eval-file"] = eval_file, stop = stop, start = start, interrupt = interrupt, ["on-load"] = on_load, ["on-filetype"] = on_filetype, ["on-exit"] = on_exit, ["to-import-replacements-map"] = to_import_replacements_map}
