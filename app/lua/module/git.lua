-- Ensure that a Git repository is cloned or pull.
-- @module git
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, git = {}, {}, {}
local cfg = require"configi"
local lib = require"lib"
local stat = require"posix.sys.stat"
local cmd = lib.cmd
_ENV = ENV

M.required = { "path" }
M.alias = {}
M.alias.repository = { "repo", "url" }

local found = function(P)
    local gitconfig = P.path .. "/.git/config"
    if not stat.stat(gitconfig) then
        return nil
    else
        local config = lib.file_to_tbl(gitconfig)
        P.repository = P.repository or "" -- to accomodate git.pull
        -- confident that Git URLs do not contain Lua magic characters
        if lib.find_string(config, "url = " .. P.repository, true) then
            return true
        else
            return false -- nil has a distinction
        end
    end
end

--- Ensure that a Git repository is cloned into a specified path.
-- @aliases repo
-- @aliases cloned
-- @param repository The URL of the repository. [ALIAS: url,repo] [REQUIRED]
-- @param path absolute path where to clone the repository [REQUIRED]
-- @usage git.repo {
--   repo = "https://github.com/torvalds/linux.git"
--   path = "/home/user/work"
-- }
function git.clone(B)
    M.parameters = { "repository" }
    M.report = {
        repaired = "git.clone: Successfully cloned Git repository.",
            kept = "git.clone: Already a git repository.",
          failed = "git.clone: Error running `git clone`."
    }
    local F, P, R = cfg.init(B, M)
    local ret = found(P)
    local dir, res, err
    if ret then
        return F.kept(P.repository)
    elseif ret == nil then
        dir, res = cmd.mkdir{ "-p", P.path }
        err = lib.exit_string(res.bin, res.status, res.bin)
        if not dir then
            return F.result(P.path, false, err)
        end
    elseif ret == false then
        return F.result(P.path, false, "Directory not empty")
    end
    local args = { "clone", P.repository, P.path }
    return F.result(P.repository, F.run(cmd["/usr/bin/git"], args))
end

--- Run `git pull` for a repository.
-- This always attempts to run the command. Useful as a handler.
-- @param repository The URL of the repository. [ALIAS: url,repo] [REQUIRED]
-- @param path absolute path where to run the pull command [REQUIRED]
-- @usage git.pull {
--   repo = "https://github.com/torvalds/linux.git"
--   path = "/home/user/work"
-- }
function git.pull(B)
    M.report = {
        repaired = "git.pull: Successfully pulled Git repository.",
            kept = "git.pull: Path is non-existent or not a Git repository.",
          failed = "git.pull: Error running `git pull`."
    }
    local F, P, R = cfg.init(B, M)
    if not found(P) then
        return F.kept(P.path) -- piggyback on kept()
    end
    local args = { _cwd = P.path, "pull" }
    return F.result(P.path, F.run(cmd["/usr/bin/git"], args))
end

git.cloned = git.clone
git.repo = git.clone
return git
