---
--- Created by BY.
--- DateTime: 2023/10/16 11:35:02
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAdLogNotion:LWnd
local UIAdLogNotion = LxWndClass("UIAdLogNotion", LWnd)

local typeof = typeof
local typeofRectTransform = typeof(CS.RectTransform)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAdLogNotion:UIAdLogNotion()
	self._timeKey = "UIAdLogNotion_timeKey"
	self._tweenKey = "UIAdLogNotion_tweenKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAdLogNotion:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAdLogNotion:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAdLogNotion:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIAdLogNotion:OnClickJump()
	local playerId = gModelPlayer:GetPlayerId()
	gModelPlayerSpace:OpenSpaceWnd(playerId,2,2)
end

function UIAdLogNotion:InitEvent()
	self:SetWndClick(self.mPop, function(...) self:OnClickJump() end)
end

function UIAdLogNotion:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(21174))
	local aHeight,height,mbHeight
	local ainRect = self.mAinRoot:GetComponent(typeofRectTransform)
	local rect = self.mPop:GetComponent(typeofRectTransform)
	if ainRect and rect then
		aHeight = ainRect.rect.height/2
		height = rect.rect.height/2
		mbHeight = aHeight - height - 10
	end
	self._mbHeight = mbHeight or 510

	local info = self:GetWndArg("info")		--StructAdventureInfo
	local ref = gModelPlayerSpace:GetRoleAdventureLogRefByRefId(info.refId)
	local desStr = LUtil.GetReplacedContent(ccLngText(ref.description),info.params,ref.shiftNumIndex)
	self:SetWndText(self.mDesText,desStr)

	self:SetToweenMove()
	self:TimerStart(self._timeKey,5,false,1)
end

function UIAdLogNotion:OnTimer(key)
	if(key == self._timeKey)then
		self:WndClose()
	end
end

function UIAdLogNotion:SetToweenMove()
	local key = self._tweenKey
	local transs = self.mPop
	local seqTween
	self:TweenSeqKill(key)
	if not seqTween then
		seqTween = self:TweenSeqCreate(key,function(seq)
			local moveTween = transs:DOLocalMove(Vector2.New(0,self._mbHeight),0.5)
			seq:Append(moveTween)
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(key)
	end)
end
------------------------------------------------------------------
return UIAdLogNotion


