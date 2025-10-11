-- [nfnl] fnl/conjure/client/go/go_mod.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_["autoload"]
local define = _local_1_["define"]
local str = autoload("conjure.aniseed.string")
local a = autoload("conjure.aniseed.core")
local M = define("conjure.client.go.go_mod")
local function str_starts_with(str0, start)
  return (string.sub(str0, 1, #start) == start)
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
local function remove_comments(mod_file)
  local function _3_()
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
  return str.join("\n", _3_())
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
local function parse_deps_to_vendor_table(raw_reqs)
  local function list_to_map(reqstbl)
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
  return list_to_map(vim.split(raw_reqs, "\n"))
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
    for actual, replacement in pairs(parse_deps_to_vendor_table(required_modules)) do
      res[actual] = replacement
    end
  else
  end
  return res
end
M["to-import-replacements-map"] = function(mod_file)
  local function first_2(tbl)
    return {a.first(tbl), a.second(tbl)}
  end
  return import_rep_map(first_2(vim.split(remove_comments(mod_file), "require")))
end
return M
