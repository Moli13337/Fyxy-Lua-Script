---
--- Created by LCM.
--- DateTime: 2024/3/10 10:47:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISowSpine:LWnd
local UISowSpine = LxWndClass("UISowSpine", LWnd)

--- 公平竞技
-- UISowSpine.TYPE_SHOW_FAIRCOMPETE = 1

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISowSpine:UISowSpine()
	self._spine = nil

	--- 通用 spine 时间
	self._commonTimeKey = "commonTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISowSpine:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISowSpine:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISowSpine:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:StartLoadSpine()
end

function UISowSpine:StartLoadSpine()
	local spineName = self._spineName
	local spine = self:CreateWndSpine(self.mSpineRoot, spineName, spineName,nil,
			function () self:OnSpineLoaded() end ,true)
	spine:StartLoad()
	self._spine = spine
end

function UISowSpine:InitMsg()
	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UISowSpine:InitEvent()
end

------------------------------- commonEnd
function UISowSpine:OnCommonEnd()
	local commonBackFunc = self._commonBackFunc
	self._commonBackFunc = nil
	if commonBackFunc then
		commonBackFunc()
	end
	self:WndClose()
end

function UISowSpine:InitData()
	self._showType = self:GetWndArg("showType")
	self._spineName = self:GetWndArg("spineName")
end

function UISowSpine:OnTimer(key)
	if key == self._commonTimeKey then
		self:OnCommonTimeEnd(key)
	end
end

function UISowSpine:OnSpineCommon()
	local commonTimeKey = self._commonTimeKey
	self:TimerStop(commonTimeKey)

	local spine = self._spine
	if not spine then
		self:WndClose()
		return
	end

	local nowName = spine:GetCurTrackEntryName()
	if string.isempty(nowName) then
		self:WndClose()
		return
	end

	local Duration = spine:GetAnimationDuration(nowName)
	if Duration <= 0 then
		self:OnCommonTimeEnd(commonTimeKey)
		return
	end

	self:TimerStart(commonTimeKey,Duration,false,1)
end


------------------------------- fairCompeteEnd
-- function UISowSpine:OnFairCompeteEnd()
-- 	self:WndClose()
-- end

-- function UISowSpine:OnSpineFairCompete()
-- 	local spine = self._spine
-- 	if not spine then
-- 		self:OnFairCompeteEnd()
-- 		return
-- 	end

-- 	local fairCompeteEffRunList = self._fairCompeteEffRunList or {}
-- 	if #fairCompeteEffRunList < 1 then
-- 		self:OnFairCompeteEnd()
-- 		return
-- 	end

-- 	local firstInfo = table.remove(fairCompeteEffRunList,1)

-- 	local effRunLen = #fairCompeteEffRunList
-- 	self._fairCompeteEffRunList = fairCompeteEffRunList

-- 	local firstEndFunc = firstInfo.firstEndFunc
-- 	local recordFirstEndFunc = firstEndFunc
-- 	if effRunLen < 1 then
-- 		firstEndFunc = function()
-- 			if recordFirstEndFunc then
-- 				recordFirstEndFunc()
-- 			end
-- 			self:OnFairCompeteEnd()
-- 		end
-- 	else
-- 		firstEndFunc = function()
-- 			if recordFirstEndFunc then
-- 				recordFirstEndFunc()
-- 			end
-- 			self:OnSpineFairCompete()
-- 		end
-- 	end

-- 	local aniName = firstInfo.aniName
-- 	local isLoop = firstInfo.isLoop
-- 	if isLoop == nil then
-- 		isLoop = false
-- 	end
-- 	local ignoreTimeScale = firstInfo.ignoreTimeScale
-- 	spine:SetAnimationCompleteFunc(firstEndFunc)
-- 	spine:PlayAnimationSolid(aniName,isLoop,ignoreTimeScale)
-- end


------------------------------- spineLoaded
function UISowSpine:OnSpineLoaded()
	local commonBackFunc = nil
	local showType = self._showType
	-- if showType == UISowSpine.TYPE_SHOW_FAIRCOMPETE then
	-- 	local fairCompeteEffRunList = self:GetWndArg("fairCompeteEffRunList") or {}
	-- 	if #fairCompeteEffRunList > 0 then
	-- 		self._fairCompeteEffRunList = fairCompeteEffRunList
	-- 		self:OnSpineFairCompete()
	-- 		return
	-- 	end
	-- end
	self._commonBackFunc = commonBackFunc
	self:OnSpineCommon()
end

------------------------- timer -------------------------
function UISowSpine:OnCommonTimeEnd(key)
	key = key or self._commonTimeKey
	self:TimerStop(key)
	self:OnCommonEnd()
end

------------------------- timer -------------------------

------------------------------------------------------------------
return UISowSpine



