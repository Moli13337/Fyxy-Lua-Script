---
--- Created by Administrator.
--- DateTime: 2024/5/27 11:06:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UINewAct18:LWnd
local UINewAct18 = LxWndClass("UINewAct18", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINewAct18:UINewAct18()
	self.tabBtn = {}
	self.downBtnList = {}
	self.BotBtnRedPoint = {}
	self.enByIndex = {
		"rank",
		"reward",
		"task"
	}
	self.childByIndex = {
		"UISubNewAct18Rk",
		"UISubNewAct18Award",
		"UISubNewAct18Tk"
	}
	self.redpointByIndex = {
		function()
			return false
		end,
		function()
			return false
		end,
		function()
			if self.sid then
				return gModelRedPoint:CheckActivityShowRed(self.sid)
			end
		end,
	}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINewAct18:OnWndClose()
	self:ClearTimer()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINewAct18:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINewAct18:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	-- self:InitData()
	self:InitCommand()
end

function UINewAct18:OnDrawTab(_, item, itemData, index)
	local On = self:FindWndTrans(item,"On")
	local Off = self:FindWndTrans(item,"Off")
	local Gray = self:FindWndTrans(item,"Gray")

	self:SetWndEasyImage(On, itemData.on)
	self:SetWndEasyImage(Off, itemData.off)
	self:SetWndEasyImage(Gray, itemData.off)

	self:SetWndTabText(item, itemData.name)
	self:SetWndTabStatus(item, 1)

	self.tabBtn[itemData.index] = item
	self.BotBtnRedPoint[itemData.index] = self:FindWndTrans(item, "redPoint")
	self:SetWndClick(item, function (...) self:ClickBotBtn(itemData.index) end)
end

function UINewAct18:InitData(_, sid)
	if sid ~= self.sid then return end

	local activityData = gModelActivity:GetActivityBySid(self.sid)
	if not activityData then return end

	local endTime = activityData.endTime
	self:CreateTimer(endTime)

	local activityCfg = gModelActivity:GetWebActivityDataById(self.sid)
	if not activityCfg then return end
	self.uiCfg = activityCfg.config
	local btnInfo = string.split(self.uiCfg.btnIcon, "|")
	for _, v in ipairs(btnInfo) do
		local btnData = string.split(v, "=")
		local data = {
			index = tonumber(btnData[1]),
			name = btnData[2],
			off = btnData[3],
			on = btnData[4],
		}
		table.insert(self.downBtnList, data)
	end

	local tipsPos = LxDataHelper.ParseVector(self.uiCfg.tipsPos)
	local timePos = LxDataHelper.ParseVector(self.uiCfg.timePos)
	self:SetAnchorPos(self.mTipsBtn, tipsPos)
	self:SetAnchorPos(self.mTimeObj, timePos)

	self:InitTabList()
	local index = self.downBtnList[1].index
	for i, func in ipairs(self.redpointByIndex) do
		if func() then
			index = i
			break
		end
	end
	self:ClickBotBtn(index)
	self:UpdateRedPoint()
end

function UINewAct18:SetTimeStr(times)
	local curTime = times - GetTimestamp()
	if curTime > 0 then
		local str = string.replace(ccClientText(15610), LUtil.FormatTimespanCn(curTime))
		self:SetWndText(self.mTimeText, str)
	else
		self:SetWndText(self.mTimeText, ccClientText(14301))
		self:ClearTimer()
	end
end

function UINewAct18:InitTabList()
	self.tabList = self:GetUIScroll("TabScroll")
	self.tabList:Create(self.mTabScroll, self.downBtnList, function(...) self:OnDrawTab(...) end)
end

function UINewAct18:ClickBotBtn(index)
	if self.curSelBtn == index then
		return
	end
	local oldIndex = self.curSelBtn
	self.curSelBtn = index
	self:SetWndTabStatus(self.tabBtn[oldIndex], 1)
	self:SetWndTabStatus(self.tabBtn[index], 0)
	if self.childByIndex[index] then
		self:CloseAllChild()
		self:CreateChildWnd(self.mChildRoot, self.childByIndex[index], {cfg = self.uiCfg, sid = self.sid})
	end

	local enName = self.enByIndex[index]
	local imageInfo = string.split(self.uiCfg[enName .. "Image"], "=")
	local imagePos = LxDataHelper.ParseVector(self.uiCfg[enName .. "ImagePos"])
	local title = self.uiCfg[enName .. "Title"]
	local titlePos = LxDataHelper.ParseVector(self.uiCfg[enName .. "TitlePos"])
	local bg = self.uiCfg[enName .. "Bg"]

	if imageInfo[1] == "1" then
		self:SetWndEasyImage(self.mRoleImage, imageInfo[2])
		self:SetAnchorPos(self.mRoleImage, imagePos)
		CS.ShowObject(self.mRoleImage, true)
		CS.ShowObject(self.mRoleSpine, false)
	else
		if imageInfo[2] ~= self.oldSpine then
			self.oldSpine = imageInfo[2]
			if self.heroSpine then
				self:DestroyWndSpineByKey("heroSpineKey")
			end
			self.heroSpine = self:CreateWndSpine(self.mRoleSpine, self.oldSpine, "heroSpineKey", false)
			self:SetAnchorPos(self.mRoleSpine, imagePos)
		end
		CS.ShowObject(self.mRoleImage, false)
		CS.ShowObject(self.mRoleSpine, true)
	end

	self:SetWndEasyImage(self.mBanner, title)
	self:SetAnchorPos(self.mBanner, titlePos)

	self:SetWndEasyImage(self.mBg, bg)
end

function UINewAct18:InitEvent()
	self:WndEventRecv(EventNames.ON_ACT_PAGE_RED_CHANGE, function() self:UpdateRedPoint() end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:InitData(...) end)

	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end)
	self:SetWndClick(self.mTipsBtn, function()
		GF.OpenWnd("UIBzTips", { title = self.uiCfg.name, text = self.uiCfg.tipsDescription })
	end)
end

function UINewAct18:ClearTimer()
	if self.timer then
		LxTimer.DelayTimeStop(self.timer)
		self.timer = nil
	end
end

function UINewAct18:UpdateRedPoint()
	for i, func in ipairs(self.redpointByIndex) do
		if self.BotBtnRedPoint[i] then
			CS.ShowObject(self.BotBtnRedPoint[i], func())
		end
	end
end

function UINewAct18:CreateTimer(times)
	self:ClearTimer()
	self:SetTimeStr(times)
	self.timer = LxTimer.LoopTimeCall(function()
		self:SetTimeStr(times)
	end, 1, false, -1)
end

function UINewAct18:InitCommand()
	self.sid = self:GetWndArg("sid")
	self:SetWndText(self:FindWndTrans(self.mCloseBtn, "TxtClose"), ccClientText(30205))
	gModelActivity:ReqActivityConfigData(self.sid)
end

------------------------------------------------------------------
return UINewAct18