---
--- Created by BY.
--- DateTime: 2023/10/8 16:25:28
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPrigeTips:LWnd
local UIPrigeTips = LxWndClass("UIPrigeTips", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local YXUIPointUtil = CS.YXUIPointUtil
local typeof_LayoutElement = typeof(UnityEngine.UI.LayoutElement)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPrigeTips:UIPrigeTips()
	self._tweenKey = "_tweenKey"
	self._delayTimer = "_delayTimer"
	self._closeTimer = "_closeTimer"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPrigeTips:OnWndClose()
	self:TweenSeqKill(self._tweenKey)
	if gLGameTouch then gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_BT_WNDCLOSE) end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPrigeTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPrigeTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIPrigeTips:SetPos()
	local follow = self._root
	if not follow then
		return
	end
	if not CS.IsValidObject(follow) then
		return
	end
	local target = self.mPosMar:GetComponent(typeofRectTransform)
	local canvasRect =LGameUI.GetUICanvasRoot()
	local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,follow)
	local y = targetPos.y
	local pos = Vector3.New(targetPos.x,y,0)
	target.localPosition = pos
	local type = target.localPosition.x > 0 and 2 or 1
	self:SetListByType(type)
end

function UIPrigeTips:SetListByType(type)
	local para = self._para
	if para then
		local uiCell = type == 1 and self.mCellScroll or self.mCellScroll2
		local name = para.name
		local icon = para.icon
		local list = para.list
		local len = #list

		self:SetWndText(self.mNameText,name)
		self:SetWndEasyImage(self.mIcon,icon)

		CS.ShowObject(self.mListBg,len > 0 and type == 1)
		CS.ShowObject(self.mListBg2,len > 0 and type == 2)
		local uiList = self:GetUIScroll("privilegeList")
		uiList:Create(uiCell,list,function (...) self:ListItem(...) end)
		if len <= 3 then
			if type == 1 then
				self.mListBg.anchoredPosition = Vector2.New(self.mListBg.anchoredPosition.x,-20)
				self.mArrow.anchoredPosition = Vector2.New(self.mArrow.anchoredPosition.x,-10)
			else
				self.mListBg2.anchoredPosition = Vector2.New(self.mListBg2.anchoredPosition.x,-20)
				self.mArrow2.anchoredPosition = Vector2.New(self.mArrow2.anchoredPosition.x,-10)
			end
		end
	end
end

function UIPrigeTips:InitEvent()
	local op = LGameTouch.TOUCH_BT_WNDCLOSE
	gLGameTouch:TouchRegister(op,LGameTouch.TOUCH_EVT_START,function (screenPos)
		self:WndClose()
	end)
end

function UIPrigeTips:TweenAlpha()
	local seqTween
	self:TweenSeqKill(self._tweenKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._tweenKey,function(seq)
			local canvasGroup = self.mPosMar:GetComponent(typeofCanvasGroup)
			if canvasGroup then
				local tween = canvasGroup:DOFade(0,0.5)
				seq:Join(tween)
			end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:WndClose()
	end)
end

function UIPrigeTips:InitCommand()
	self._root = self:GetWndArg("root")
	self._para = self:GetWndArg("para")
	local type = self:GetWndArg("type") or 1		--2类型自动2秒后开始关闭界面

	self:TimerStart(self._delayTimer,0.1,false,1)
	if type == 2 then
		self:TimerStart(self._closeTimer,2,false,1)
	end
end

function UIPrigeTips:ListItem(list, item, itemdata, itempos)
	local desText = self:FindWndTrans(item,"DesText")

	local des = itemdata
	local testUIText = LxUiHelper.FindXTextCtrl(self.mTestText)
	testUIText.text = des
	local width = testUIText.preferredWidth
	if width > 400 then
		width = 400
	end
	desText.sizeDelta = Vector2.New(width,0)
	--LxUiHelper.SetSizeWithCurAnchor(item,0,width)

	local desUIText = LxUiHelper.FindXTextCtrl(desText)
	self:SetWndText(desText, des)
	local height = desUIText.preferredHeight
	--LxUiHelper.SetSizeWithCurAnchor(item,1,height)
	local csLayoutElement = item:GetComponent(typeof_LayoutElement)
	if(csLayoutElement)then
		csLayoutElement.preferredWidth = width
		csLayoutElement.preferredHeight = height
	end
	local arrow2LayoutElement = self.mArrow2:GetComponent(typeof_LayoutElement)
	if(arrow2LayoutElement)then
		local oldWidth = self._oldWidth or 0
		if oldWidth < width then
			self._oldWidth = width
			oldWidth = width
			csLayoutElement.preferredWidth = oldWidth
		end
	end
end

function UIPrigeTips:OnTimer(key)
	if self._closeTimer == key then
		self:TweenAlpha()
	elseif self._delayTimer == key then
		self:SetPos()
	end
end
------------------------------------------------------------------
return UIPrigeTips


