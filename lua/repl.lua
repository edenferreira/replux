local module = {}
module.api = {}

local cache_dir = os.getenv('HOME') .. '/dotfiles/cache'
local cache_file = cache_dir .. '/myrepl_projects'
local dev_dir = os.getenv('HOME') .. '/dev'
local dev_nu_dir = dev_dir .. '/nu'

function lines_from(file)
    local lines = {}
    local count = 1
    for line in io.lines(file) do
        lines[count] = line
        count = count + 1
    end
    return lines
end

function write_lines_to(lines, path)
    local file = io.open(path, 'w')
    for _, line in pairs(lines) do
        file:write(line, '\n')
    end
end

function cache_data(cache_file)
    local success, result = pcall(lines_from, cache_file)
    if success then
        return result
    end
    return nil
end

function all_projects_without_cache()
    local result = io.popen('find ' .. dev_dir)
    local projects = map_pairs(
    function (str)
        return string.sub(str, 1, string.find(str, '/project.clj') - 1)
    end,
    filter(function (str)
        return string.find(str, 'project.clj')
    end, result:lines()))
    return projects
end

function all_projects ()
    local script_dir = vim.api.nvim_eval("expand(\"<sfile>:p:h\")")
    local cache_dir = script_dir .. '/cache'
    local cache_file = cache_dir .. '/repl_projects'

    local cache = cache_data(cache_file)
    if cache then return cache end
    local result = io.popen('find ' .. dev_dir)
    return projects
end

module.api.create_cache = function ()
    local script_dir = vim.api.nvim_eval("expand(\"<sfile>:p:h\")")
    local cache_dir = script_dir .. '/cache'
    io.popen('mkdir -p ' .. cache_dir)
    local cache_file = cache_dir .. '/repl_projects'
    local projects = all_projects_without_cache()
    write_lines_to(projects, cache_file)
    return script_dir
end

function map_pairs(fn, iter)
    local result = {}
    local count = 1
    for _, line in pairs(iter) do
        result[count] = fn(line)
        count = count + 1
    end
    return result
end

function map(fn, iter)
    local result = {}
    local count = 1
    for line in iter do
        result[count] = fn(line)
        count = count + 1
    end
    return result
end

function filter(fn, iter)
    local result = {}
    local count = 1
    for line in iter do
        if fn(line) then
            result[count] = line
            count = count + 1
        end
    end
    return result
end

function print_all(iter)
    for _, value in pairs(iter) do
        print(value)
    end
end

function run(cmd)
    return io.popen(cmd .. ' 2>&1'):read('*a')
end

function startswith(str, start)
    return string.sub(str,1,string.len(start))==start
end

function start_path(path)
    objProp = {}
    index = 1
    for value in string.gmatch(path, "%w+") do
        objProp[index] = value
        index = index + 1
    end
    local name  = objProp[index - 1]

    local cmd = 'tmux new-session -d -s ' .. name .. ' -c ' .. path .. ' lein repl'
    run(cmd)
    return name .. ' started'
end

module.kill_path = function (path)
    objProp = {}
    index = 1
    for value in string.gmatch(path, "%w+") do
        objProp[index] = value
        index = index + 1
    end
    local name  = objProp[index - 1]

    local cmd = 'tmux kill-session -t ' .. name
    run(cmd)
    return name .. ' killed'
end

module.start = function (name)
    local path = dev_nu_dir .. '/' .. name
    local cmd = 'tmux new-session -d -s ' .. name .. ' -c ' .. path .. ' lein repl'
    run(cmd)
    return name .. ' started'
end

module.kill = function (name)
    local cmd = 'tmux kill-session -t ' .. name
    run(cmd)
    return name .. ' killed'
end

module.kill_from = function (path)
    local projects = all_projects()
    for i, value in pairs(projects) do
        if startswith(path, value) then
            return kill_path(value)
        end
    end
end

module.ls = function ()
    local result = io.popen('tmux ls 2>&1')
    local list = map(
    function (line)
        return string.match(line, '(%a+):')
    end,
    result:lines())
    return list
end

module.startreplfrom =  function (path)
    local projects = all_projects()
    for i, value in pairs(projects) do
        if startswith(path, value) then
            return start_path(value)
        end
    end
end

return module
