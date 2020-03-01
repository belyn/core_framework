-- logging 核心配置
local cf = require "cf"

local class = require "class"

local new_tab = require "sys".new_tab
local now = require "sys".now

local os_date = os.date

local type = type
local select = select
local assert = assert
local pairs = pairs
local tostring = tostring
local getmetatable = getmetatable

local modf = math.modf
local debug_getinfo = debug.getinfo
local io_open = io.open
local io_write = io.write
local io_flush = io.flush
local io_type = io.type
local fmt = string.format
local concat = table.concat

-- 可以在这里手动设置是否使用异步日志
local ASYNC = true

if ASYNC then
  if io_type(io.output()) == 'file' then
    io.output():setvbuf("full", 2 ^ 20)
    cf.at(0.5, function ()
      return io_flush() -- 定期刷新缓冲, 减少日志缓冲频繁导致的性能问题
    end)
  end
end

-- 格式化时间: [年-月-日 时:分:秒,毫秒]
local function fmt_Y_m_d_H_M_S()
  local ts, f = modf(now())
  return concat({'[', os_date('%Y-%m-%d %H:%M:%S', ts), ',', fmt("%003d", modf(f * 1e3)), ']'})
end

-- 格式化时间: [年-月-日 时:分:秒]
local function Y_m_d()
  return os_date('%Y-%m-%d')
end

-- LOG函数的调用信息
local function debuginfo ()
  local info = debug_getinfo(3, 'Sln')
  return concat({'[', info.source, ':', info.currentline, ']'})
end

-- 格式化
local function table_format(t)
  local tab = new_tab(16, 0)
  while 1 do
    local mt = getmetatable(t)
    for key, value in pairs(t) do
      local k, v
      if type(key) == 'number' then
          k = concat({'[', key, ']'})
      else
          k = concat({'["', key, '"]'})
      end
      if type(value) == 'table' then
        if t ~= value then
          v = table_format(value)
        else
          v = tostring(value)
        end
      elseif type(value) == 'string' then
        v = concat({'"', value, '"'})
      else
        v = tostring(value)
      end
      tab[#tab+1] = concat({k, '=', v})
    end
    if not mt or mt == t then
      break
    end
    t = mt
  end
  return concat({'{', concat(tab, ', '), '}'})
end

local function info_fmt(...)
  local args = {...}
  local index, len = 1, select('#', ...)
  local tab = new_tab(16, 0)
  while 1 do
    local arg = args[index]
    if type(arg) == 'table' then
      tab[#tab+1] = table_format(arg)
    else
      if type(arg) == 'string' then
        tab[#tab+1]= '"' .. tostring(arg) .. '"'
      else
        tab[#tab+1]= tostring(arg)
      end
    end
    if index >= len then
      break
    end
    index = index + 1
  end
  return concat(tab, ', ')
end

-- 格式化日志
local function FMT (where, level, ...)
  return concat({ fmt_Y_m_d_H_M_S(), where, level, ':', info_fmt(...), '\n'}, ' ')
end

local Log = class("Log")

function Log:ctor (opt)
  if type(opt) == 'table' then
    self.dumped = opt.dump
    self.path = opt.path
    self.today = Y_m_d()
  end
end

-- 常规日志
function Log:INFO (...)
  local info = debuginfo()
  io_write(FMT("\27[32m"..info, "[INFO]".."\27[0m", ...))
  if not self.dumped or type(self.path) ~= 'string' then
    return
  end
  self:dump(FMT(info, "[INFO]", ...))
end

-- 错误日志
function Log:ERROR (...)
  local info = debuginfo()
  io_write(FMT("\27[31m"..info, "[ERROR]".."\27[0m", ...))
  if not self.dumped or type(self.path) ~= 'string' then
    return
  end
  self:dump(FMT(info, "[ERROR]", ...))
end

-- 调试日志
function Log:DEBUG (...)
  local info = debuginfo()
  io_write(FMT("\27[36m"..info, "[DEBUG]".."\27[0m", ...))
  if not self.dumped or type(self.path) ~= 'string' then
    return
  end
  self:dump(FMT(info, "[DEBUG]", ...))
end

-- 警告日志
function Log:WARN (...)
  local info = debuginfo()
  io_write(FMT("\27[33m"..info, "[WARN]".."\27[0m", ...))
  if not self.dumped or type(self.path) ~= 'string' then
    return
  end
  self:dump(FMT(info, "[WARN]", ...))
end

-- 可以在这里手动设置日志路径
local LOG_FOLDER = 'logs/'

-- dump日志到磁盘
function Log:dump(log)
  local today = Y_m_d()
  if today ~= self.today then
    if self.file then
      self.file:close()
      self.file = nil
    end
    local file, err = io_open(LOG_FOLDER..self.path..'_'..today..'.log', 'a')
    if not file then
      return io_type(io.output()) == 'file' and io_write('打开文件失败: '..(('['..err..']') or '')..'\n')
    end
    self.file, self.today = file, today
    file:setvbuf("line")
  end
  if not self.file then
    local file, err = io_open(LOG_FOLDER..self.path..'_'..today..'.log', 'a')
    if not file then
      return io_type(io.output()) == 'file' and io_write('打开文件失败: '..(('['..err..']') or '')..'\n')
    end
    file:setvbuf("line")
    self.file = file
  end
  return self.file:write(log)
end

return Log
