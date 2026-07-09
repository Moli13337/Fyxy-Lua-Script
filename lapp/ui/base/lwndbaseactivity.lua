-- **********************************************************************
-- 作者: wzz
-- 时间: 2025-8-13
-- 描述: 大多数活动基类, 为了解决活动打开界面时，刷新卡顿或延迟刷新问题
-- 分析原因：
-- 1. 刷新卡顿：界面打开刷新，多个协议或事件的同时返回，导致界面同帧刷新多次
-- 2. 延迟刷新：活动配置请求在界面打开后才请求，返回后才刷新界面（部分界面，打开界面，请求web配置,返回后才）
-- **********************************************************************


local LWnd = LWnd
---@class LWndBaseActivity:LWnd
local LWndBaseActivity = LxClass("LWndBaseActivity", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function LWndBaseActivity:LWndBaseActivity()
	-- 界面有效性:OnStartFinish后,OnWndClose前才为true
	self._isWndValid = nil
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function LWndBaseActivity:OnWndClose()
	LWnd.OnWndClose(self)

	self._isWndValid = nil
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function LWndBaseActivity:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------

-- 设置参数结束
function LWndBaseActivity:OnWndArg()
	self.sid = self:GetWndArg("sid")
    local subpage = self:GetWndArg("subPage") --支持跳转
    if subpage then
        self.sid = gModelActivity:GetSidByUniqueJump(subpage)
    end

	if not self.sid then
		return
	end
	self:InitActivityEvents()

	gModelActivity:OnActivityPageReq(self.sid)
	gModelActivity:ReqActivityConfigData(self.sid)
end

function LWndBaseActivity:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:OnStartFinish()
	self._isWndValid = true

	self:OnLimitConfigRefresh()
	self:OnLimitPageRefresh()
end

-- 初始化活动事件
function LWndBaseActivity:InitActivityEvents()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...) self:OnConfigData(...) end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_PAGE_CHANGE, function(...) self:OnPageData(...) end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_LIST_CHANGE, function() self:OnActivityListChange() end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO, function() self:OnTimeZero() end)
end

-- 配置返回
function LWndBaseActivity:OnConfigData(webData, sid)
	if sid ~= self.sid or not self._isWndValid then
		return
	end
	self:OnLimitConfigRefresh()
end

-- page数据返回
function LWndBaseActivity:OnPageData(modelId, sid, pages)
	if sid ~= self.sid or not self._isWndValid then
		return
	end
	self:OnLimitPageRefresh()
end

-- 0 点
function LWndBaseActivity:OnTimeZero()
	if not self._isWndValid then
		return
	end
	gModelActivity:OnActivityPageReq(self.sid)
end

-- 活动列表刷新
function LWndBaseActivity:OnActivityListChange()
	if not self._isWndValid then
		return
	end
	gModelActivity:OnActivityPageReq(self.sid)
end

-- 防止同时刷新多次
function LWndBaseActivity:OnLimitConfigRefresh()
	local webData = gModelActivity:GetWebActivityDataById(self.sid)
	if not webData then
		return
	end

	local delayTime = 0.1

	local timerKey = "OnConfigRefresh"
	if self:IsTimerExist(timerKey) then
		self._needOnConfigRefresh = true
		return
	end

	self._needOnConfigRefresh = true
	local timePara = {
		func = function()
			if self._needOnConfigRefresh then
				self:OnConfigRefresh()
				self._needOnConfigRefresh = nil
				if self._needOnLimitRefresh then
					self:OnLimitPageRefresh()
				end
			else
				self:TimerStop(timerKey)
			end
		end,
		callOnStart = true,
		loopcnt = -1,
		interval = delayTime,
		key = timerKey
	}
	self:TimerStartImpl(timePara)
end

-- 防止同时刷新多次
function LWndBaseActivity:OnLimitPageRefresh()
	local pageList = gModelActivity:GetActivityPagesListBySid(self.sid)
	if not pageList then
		return
	end

	local webData = gModelActivity:GetWebActivityDataById(self.sid)
	if not webData then
		self._needOnLimitRefresh = true
		return
	end
	self._needOnLimitRefresh = nil

	local delayTime = 0.15

	local timerKey = "OnPageRefresh"
	if self:IsTimerExist(timerKey) then
		self._needOnRefresh = true
		return
	end

	self._needOnRefresh = true
	local timePara = {
		func = function()
			if self._needOnRefresh then
				self:OnPageRefresh()
				self._needOnRefresh = nil
			else
				self:TimerStop(timerKey)
			end
		end,
		callOnStart = true,
		loopcnt = -1,
		interval = delayTime,
		key = timerKey
	}
	self:TimerStartImpl(timePara)
end

--------------子类可能需要重写的函数--------------------------------


-- OnStart 执行完毕后 （只执行一次）
function LWndBaseActivity:OnStartFinish()
end

-- 配置返回刷新 （界面已完成且必定存在配置数据）
function LWndBaseActivity:OnConfigRefresh()
	-- local webData = gModelActivity:GetWebActivityDataById(self.sid)
end

-- page数据返回刷新 （界面已完成且必定存在配置数据和page数据）
function LWndBaseActivity:OnPageRefresh()
	-- local pageList = gModelActivity:GetActivityPagesListBySid(self.sid)
end

------------------------------------------------------------------
return LWndBaseActivity
