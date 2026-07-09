---
--- Created by BY.
--- DateTime: 2023/10/5 17:38:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWishCellTips:LWnd
local UIWishCellTips = LxWndClass("UIWishCellTips", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWishCellTips:UIWishCellTips()
	self._delayTimer = "_delayTimer"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWishCellTips:OnWndClose()
	if gLGameTouch then gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_BT_WNDCLOSE) end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWishCellTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWishCellTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	--self:InitMessage()
	self:InitCommand()
end

function UIWishCellTips:OnTimer(key)
	self:SetPos()
end

function UIWishCellTips:ListItem(list, item, itemdata, itemPos)
	local text = CS.FindTrans(item,"UIText")
	self:SetWndText(text,itemdata.text)

	if itemPos == self._allListNum then
		self:TimerStart(self._delayTimer,0.2,false,1)
	end
end

function UIWishCellTips:InitCommand()
	self._root = self:GetWndArg("root")
	local list = self:GetWndArg("list")
	local other = self:GetWndArg("other")
	self._other = other
	CS.ShowObject(self.mTitleText,other)
	if other then
		self:SetWndText(self.mTitleText,other)
	end

    CS.ShowObject(self.mBtnScroll,list)
	if list then
		self._allListNum = #list
		local btnUIList = self:GetUIScroll("btnList")
		btnUIList:Create(self.mBtnScroll,list,function (...) self:ListItem(...) end)
	else
		self:TimerStart(self._delayTimer,0.1,false,1)
	end
end

function UIWishCellTips:InitEvent()
	self:SetWndClick(self.mBgImage, function(...)
		self:WndClose()
	end)
	local op = LGameTouch.TOUCH_BT_WNDCLOSE
	gLGameTouch:TouchRegister(op,LGameTouch.TOUCH_EVT_START,function (screenPos)
		self:WndClose()
	end)
end

function UIWishCellTips:SetPos()
	local follow = self._root
	local target = self.mPosMag:GetComponent(typeofRectTransform)
	local target2 = self.mArrMag:GetComponent(typeofRectTransform)

	local canvasRect =LGameUI.GetUICanvasRoot()
	local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,follow)
    local x = targetPos.x
	local y = targetPos.y
	local allWidth = target.rect.width
	if allWidth > 500 then
		x = 0
		y = y + 14
	elseif self._other then

		x = x + follow.rect.width/2
	else
		y = y + 14
		x = x + follow.rect.width/2
		local width = target.rect.width/2
		if x - width < -320 then
			x = x - (x + width)
		elseif x + width > 320 then
			x = x - (x - width)
		end

	end
	local pos = Vector3.New(x,y,0)
	target2.localPosition = pos
	target.localPosition = pos
end
------------------------------------------------------------------
return UIWishCellTips


