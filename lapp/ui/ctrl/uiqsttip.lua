---
--- Created by Administrator.
--- DateTime: 2023/10/26 14:50:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIQstTip:LWnd
local UIQstTip = LxWndClass("UIQstTip", LWnd)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local Tweening = DG.Tweening
local EaseOutCubic = Tweening.Ease.OutCubic
local EaseInCubic = Tweening.Ease.InCubic
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIQstTip:UIQstTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIQstTip:OnWndClose()
	if self._seqCom then
		self._seqCom:Destroy()
		self._seqCom = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIQstTip:OnCreate()
	LWnd.OnCreate(self)
	self._seqCom = SequenceCom:New()
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIQstTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:OnWndRefresh()
end


function UIQstTip:ShowTaskTip(taskData)
	self:SetWndText(self.mTaskDesc,taskData.desc)
	self:SetWndText(self.mTaskTitle,taskData.title)
	self:SetWndClick(self.mTaskTip,function ()
		local curMap = GF.GetCurMap()
		if curMap and curMap:IsSameMap("LOneNightSpaceMap") then
			GF.ChangeMap("LCityMap")
		end
		if taskData.jumpId then
			gModelFunctionOpen:Jump(taskData.jumpId)
		end
		self:WndClose()
	end)
	local time = gModelQuest:GetQuestConfigRefByKey("questPopupTime")
	local seq = self._seqCom:CreateSeq("showTask")
	self.mTaskTip.anchoredPosition = Vector2.New(0,47)
	local canvasGroup = self.mTaskTip:GetComponent(typeofCanvasGroup)
	canvasGroup.alpha = 0
	local tween = canvasGroup:DOFade(1,0.5)
	seq:Append(tween)
	tween = self.mTaskTip:DOLocalMoveY(-100,0.5):SetEase(EaseOutCubic):SetRelative(true)
	seq:Join(tween)
	seq:AppendInterval(time)
	tween = canvasGroup:DOFade(0,0.5)
	seq:Append(tween)
	tween = self.mTaskTip:DOLocalMoveY(100,0.5):SetEase(EaseInCubic):SetRelative(true)
	seq:Join(tween)
	seq:OnComplete(function()
		FireEvent(EventNames.CHECK_SHOW_TASK_FINISH)
	end)

	seq:OnKill(function ()
		self.mTaskTip.anchoredPosition = Vector2.New(0,47)
	end)

	seq:PlayForward()
end

function UIQstTip:OnWndRefresh()
	local taskData = self:GetWndArg("data")
	self:ShowTaskTip(taskData)
end

------------------------------------------------------------------
return UIQstTip


