---
--- Created by BY.
--- DateTime: 2023/10/27 15:26:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITkTips:LWnd
local UITkTips = LxWndClass("UITkTips", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITkTips:UITkTips()
	self._delayTimer = "_delayTimer"
	self._taskPopSliderKey = "_taskPopSliderKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITkTips:OnWndClose()
	self:ReleaseTouchEvent()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITkTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITkTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UITkTips:ReleaseTouchEvent()
	if gLGameTouch then gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_UI) end
end

function UITkTips:OnTimer(key)
	self:SetPos()
end

function UITkTips:SetPos()
	local follow = self._root
	local target = self.mTaskPop:GetComponent(typeofRectTransform)
	--local target2 = self.mArrMag:GetComponent(typeofRectTransform)

	local canvasRect =LGameUI.GetUICanvasRoot()
	local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,follow)
	local x = targetPos.x
	local y = targetPos.y

	local pos = Vector3.New(x-60,y,0)
	--target2.localPosition = pos
	target.localPosition = pos
	CS.ShowObject(self.mTaskPop,true)
end
function UITkTips:InitCommand()
	self._root = self:GetWndArg("root")
	local sid = self:GetWndArg("sid")
	local itemdata = self:GetWndArg("itemdata")

	local pageId = itemdata.pageId
	local entryId = itemdata.entryId
	local entryCfg = gModelActivity:GetWebActivityEntryData(sid,pageId,entryId)
	local description = entryCfg.description
	local jumpId  = entryCfg.jumpId
	local jumpDesc  = entryCfg.jumpDesc
	local isShowJump  = jumpId and not string.isempty(jumpDesc)

	local goalData = itemdata.goalData
	local schedules = goalData.schedules
	local scheduleItem = schedules[1]
	if not scheduleItem then return end
	local schedule = scheduleItem.schedule
	local goal = scheduleItem.goal
	local des = schedule and string.replace(description,schedule) or description
	local progressValue = schedule/goal

	self:SetWndText(self.mTaskPopDesc,des)
	local slider 	  = self:UIProgressFind(self.mTaskPopProgressLine, self._taskPopSliderKey,progressValue)
	slider:SetUIProgress(progressValue)
	local strColor	  = schedule >= goal and "lightGreen" or "lightRed"
	local scheduleStr = LUtil.FormatColorStr(schedule, strColor)
	local progressStr = string.replace(ccClientText(23208), scheduleStr, goal)
	self:SetWndText(self.mTaskPopTxt, progressStr)
	CS.ShowObject(self.mTaskJumpTxt, isShowJump)
	if isShowJump then
		self:SetWndText(self.mTaskJumpTxt, jumpDesc)
		self:SetWndClick(self.mTaskTxts, function()
			if not gModelFunctionOpen:CheckIsOpened(jumpId,true) then
				return
			end
			gModelFunctionOpen:Jump(jumpId,self:GetWndName())
			self:WndClose()
		end)
	end

	self:TimerStart(self._delayTimer,0.1,false,1)
end

function UITkTips:InitEvent()
	local op = LGameTouch.TOUCH_UI
	gLGameTouch:TouchRegister(op,LGameTouch.TOUCH_EVT_START,function (screenPos)
		local touchObject = CS.YXTouchManager.EventSystemRaycastGameObject(screenPos)
		if touchObject then
			if touchObject.transform == self.mTaskTxts or touchObject.transform == self.mTaskPopTxt or touchObject.transform == self.mTaskJumpTxt then
				return
			end
			self:WndClose()
		end
	end)
end
------------------------------------------------------------------
return UITkTips


