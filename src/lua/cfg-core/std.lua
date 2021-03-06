local lib = require"lib"
local syslog = require"posix.syslog"
local getopt = require"posix.getopt"
local strings = require"cfg-core.strings"

local Path = function()
    local path
    for r, optarg, _, _ in getopt.getopt(arg, strings.short_args, strings.long_args) do
        if r == "f" then
            path, _, _ = lib.decomp_path(optarg)
            break
        end
    end
    return path
end

local File = function(f)
    local default = "./"
    local path, base, ext = lib.decomp_path(f)
    if path and string.find(path, "^/.*") and not (path == ".") then
        path = f
    elseif path == "." then
        path = Path() .. "/" .. f
    else
        path = default .. f
    end
    return path, base, ext
end


local Log = function(sys, file, str, level)
    level = level or syslog.LOG_DEBUG
    if sys then
        return lib.log(file, strings.IDENT, str, syslog.LOG_NDELAY | syslog.LOG_PID, syslog.LOG_DAEMON, level)
    elseif not sys and file then
        return lib.log(file, strings.IDENT, str)
    end
end

return { path = Path, file = File, log = Log }
