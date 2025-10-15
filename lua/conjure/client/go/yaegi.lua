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
config.merge({client = {go = {yaegi = {command = "yaegi -syscall -unsafe -unrestricted", prompt_pattern = "> ", value_prefix_pattern = "^: ", ["delay-stderr-ms"] = 16}}}})
if config["get-in"]({"mapping", "enable_defaults"}) then
  config.merge({client = {go = {yaegi = {mapping = {start = "cs", stop = "cS", interrupt = "ei"}}}}})
else
end
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
  elseif (_4_ == "import_spec") then
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
local function eval_str(opts)
  local code
  do
    local _11_ = a["pr-str"](opts.node)
    if (_11_ == "#<<node import_spec>>") then
      code = ("import " .. opts.code)
    else
      local _ = _11_
      code = opts.code
    end
  end
  local function _13_(repl)
    local function _14_(msgs)
      local msgs0 = format_msg(unbatch(msgs))
      opts["on-result"](a.last(msgs0))
      return log.append(msgs0)
    end
    return repl.send((code .. "\n"), _14_, {["batch?"] = true})
  end
  return with_repl_or_warn(_13_)
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
  if state("repl") then
    return log.append({(comment_prefix .. "Can't start, REPL is already running."), (comment_prefix .. "Stop the REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "stop"}))}, {["break?"] = true})
  else
    local function _16_()
      return display_repl_status("started")
    end
    local function _17_(err)
      return display_repl_status(err)
    end
    local function _18_(code, signal)
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
    local function _21_(msg)
      return log.append(format_msg(msg))
    end
    return a.assoc(state(), "repl", stdio.start({["prompt-pattern"] = cfg({"prompt_pattern"}), cmd = cfg({"command"}), ["on-success"] = _16_, ["on-error"] = _17_, ["on-exit"] = _18_, ["on-stray-output"] = _21_}))
  end
end
local function interrupt()
  local function _23_(repl)
    log.append({(comment_prefix .. " Sending interrupt signal.")}, {["break?"] = true})
    return repl["send-signal"]("sigint")
  end
  return with_repl_or_warn(_23_)
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
return {["buf-suffix"] = buf_suffix, ["comment-prefix"] = comment_prefix, ["form-node?"] = form_node_3f, unbatch = unbatch, ["format-msg"] = format_msg, ["eval-str"] = eval_str, ["eval-file"] = eval_file, stop = stop, start = start, interrupt = interrupt, ["on-load"] = on_load, ["on-filetype"] = on_filetype, ["on-exit"] = on_exit}
