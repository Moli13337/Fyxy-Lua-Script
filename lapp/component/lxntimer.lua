--------------------------------------------------------------------------------
--      Copyright (c) 2015 , 蒙占志(topameng) topameng@gmail.com
--      All rights reserved.
--      Use, modification and distribution are subject to the "MIT License"
--------------------------------------------------------------------------------
local setmetatable = setmetatable
local UpdateBeat = UpdateBeat
local CoUpdateBeat = CoUpdateBeat
local Time = Time

---@class LxNTimer
LxNTimer = {}

local LxNTimer = LxNTimer
local mt = {__index = LxNTimer}

--unscaled false 采用deltaTime计时，true 采用 unscaledDeltaTime计时
function LxNTimer.New(func, obj, duration, loop, unscaled, stopFunc)
    unscaled = unscaled or false and true
    loop = loop or 1
    return setmetatable({id = 0, key = 0, timerType = 1, func = func, obj = obj, stopFunc=stopFunc, duration = duration, time = duration, loop = loop, unscaled = unscaled, running = false}, mt)
end

function LxNTimer:Start()
    self.running = true

    if not self.handle then
        self.handle = UpdateBeat:CreateListener(self.Update, self)
    end

    UpdateBeat:AddListener(self.handle)
end

function LxNTimer:Reset(func, obj, duration, loop, unscaled)
    self.obj        = obj
    self.duration 	= duration
    self.loop		= loop or 1
    self.unscaled	= unscaled
    self.func		= func
    self.time		= duration
end

function LxNTimer:Stop()
    if not self.running then return end

    self.running = false

    if self.handle then
        UpdateBeat:RemoveListener(self.handle)
    end

    if self.stopFunc then
        self.stopFunc(self)
    end
end

function LxNTimer:Recycle()
    self.handle = nil
    self.func = nil
    self.obj = nil
    self.key = 0
    self.stopFunc = nil
end

function LxNTimer:Dispose()
    self.stopFunc = nil

    if self.running then
        self:Stop()
    end
    self.handle = nil
    self.func = nil
    self.obj = nil
    self.stopFunc = nil
    self.key = 0
end

function LxNTimer:Update()
    if not self.running then
        return
    end

    local delta = self.unscaled and Time.unscaledDeltaTime or Time.deltaTime
    if self.duration <= 0 then
        self.time = 0
    else
        self.time = self.time - delta
    end
    if self.time <= 0 then
        ---防止func中重复调用同一个timer开始， 被后面调用stop暂停了
        local obj = self.obj
        local key = self.key
        local func = self.func

        if self.loop > 0 then
            self.loop = self.loop - 1
            self.time = self.time + self.duration
        end

        if self.loop == 0 then
            self:Stop()
        elseif self.loop < 0 then
            self.time = self.time + self.duration
        end

        if obj then
            func(obj, key)
        else
            func(key)
        end

    end
end

--给协同使用的帧计数timer
LxNFrameTimer = {}

local LxNFrameTimer = LxNFrameTimer
local mt2 = {__index = LxNFrameTimer}

function LxNFrameTimer.New(func, obj, count, loop, stopFunc)
    local c = Time.frameCount + count
    loop = loop or 1
    return setmetatable({id = 0, key = 0, timerType = 2,func = func, stopFunc = stopFunc, obj = obj, loop = loop, duration = count, count = c, running = false}, mt2)
end

function LxNFrameTimer:Reset(func, obj, count, loop)
    self.func = func
    self.obj = obj
    self.duration = count
    self.loop = loop
    self.count = Time.frameCount + count
end

function LxNFrameTimer:Start()
    if not self.handle then
        self.handle = CoUpdateBeat:CreateListener(self.Update, self)
    end

    CoUpdateBeat:AddListener(self.handle)
    self.running = true
end

function LxNFrameTimer:Stop()
    if not self.running then return end

    self.running = false

    if self.handle then
        CoUpdateBeat:RemoveListener(self.handle)
    end

    if self.stopFunc then
        self.stopFunc(self)
    end
end

function LxNFrameTimer:Recycle()
    self.handle = nil
    self.func = nil
    self.obj = nil
    self.key = 0
    self.stopFunc = nil
end

function LxNFrameTimer:Dispose()
    self.stopFunc = nil

    if self.running then
        self:Stop()
    end
    self.handle = nil
    self.func = nil
    self.obj = nil
    self.key = 0
    self.stopFunc = nil
end

function LxNFrameTimer:Update()
    if not self.running then
        return
    end

    if Time.frameCount >= self.count then
        ---防止func中重复调用同一个timer开始， 被后面调用stop暂停了
        local obj = self.obj
        local key = self.key
        local func = self.func

        if self.loop > 0 then
            self.loop = self.loop - 1
        end
        if self.loop == 0 then
            self:Stop()
        else
            self.count = Time.frameCount + self.duration
        end

        if obj then
            func(obj, key)
        else
            func(key)
        end
    end
end

LxNCoTimer = {}

local LxNCoTimer = LxNCoTimer
local mt3 = {__index = LxNCoTimer}

function LxNCoTimer.New(func, obj, duration, loop, stopFunc)
    loop = loop or 1
    return setmetatable({id =0, key = 0, timerType = 3,obj = obj, stopFunc = stopFunc, duration = duration, loop = loop, func = func, time = duration, running = false}, mt3)
end

function LxNCoTimer:Start()
    if not self.handle then
        self.handle = CoUpdateBeat:CreateListener(self.Update, self)
    end

    self.running = true
    CoUpdateBeat:AddListener(self.handle)
end

function LxNCoTimer:Reset(func, duration, loop)
    self.duration 	= duration
    self.loop		= loop or 1
    self.func		= func
    self.time		= duration
end

function LxNCoTimer:Stop()
    if not self.running then return end

    self.running = false

    if self.handle then
        CoUpdateBeat:RemoveListener(self.handle)
    end

    if self.stopFunc then
        self.stopFunc(self)
    end

end

function LxNCoTimer:Recycle()
    self.handle = nil
    self.func = nil
    self.obj = nil
    self.stopFunc = nil
    self.key = 0
end

function LxNCoTimer:Dispose()
    self.stopFunc = nil

    if self.running then
        self:Stop()
    end
    self.handle = nil
    self.func = nil
    self.obj = nil
    self.stopFunc = nil
    self.key = 0
end

function LxNCoTimer:Update()
    if not self.running then
        return
    end

    if self.time <= 0 then
        ---防止func中重复调用同一个timer开始， 被后面调用stop暂停了
        local obj = self.obj
        local key = self.key
        local func = self.func

        if self.loop > 0 then
            self.loop = self.loop - 1
            self.time = self.time + self.duration
        end

        if self.loop == 0 then
            self:Stop()
        elseif self.loop < 0 then
            self.time = self.time + self.duration
        end

        if obj then
            func(obj, key)
        else
            func(key)
        end
    end

    self.time = self.time - Time.deltaTime
end