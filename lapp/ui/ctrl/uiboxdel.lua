---
--- Created by BY.
--- DateTime: 2023/10/20 14:46:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBoxDel:LWnd
local UIBoxDel = LxWndClass("UIBoxDel", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBoxDel:UIBoxDel()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBoxDel:OnWndClose()
	--if self._uiItemList then
	--	self._uiItemList:Destroy()
	--	self._uiItemList =nil
	--end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBoxDel:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBoxDel:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	--self:InitMessage()
	self:InitCommand()
end

function UIBoxDel:InitScrollView()
	local itemList = self._reward
	local t ={}
	for k,v in pairs(itemList) do
		if v.itemType == 1 or v.itemType == 3 then
			table.insert(t,v)
		elseif v.itemType ==2 then
			local cnt = v.itemNum
			for i=1,cnt do
				local data = {
					itemType = v.itemType,
					itemId = v.itemId,
				}
				table.insert(t,data)
			end
		end
	end

	local uiItemList = self:FindUIScroll("rewardList") -- UIItemList:New(self)
	if not uiItemList then
		uiItemList = self:GetUIScroll("rewardList")
		uiItemList:Create(self.mItemList,t, function (...) self:OnDrawItem(...) end)
	else
		uiItemList:RefreshList(t)
	end
	--self._uiItemList = uiItemList
	--uiItemList:Create(self.mItemList,t, function (...)
	--	self:OnDrawItem(...)
	--end)
	local cnt = #t
	if cnt>3 then
		uiItemList:EnableScroll(true,true)
	end

	if cnt == 1 then
		self._offset = self._offsetList[1]
	else
		self._offset = self._offsetList[2]
	end
end

function UIBoxDel:InitCommand()
	self._root=self:GetWndArg("root")
	self._reward=self:GetWndArg("reward")
	self._state=self:GetWndArg("state")
	self._func = self:GetWndArg("func")
	self._onfunc = self:GetWndArg("onfunc")
	self:InitData()
	self:InitScrollView()
	self:TimerStart(self._delayTimer,0,false,1)

	CS.ShowObject(self.mTab1Image,false)
	CS.ShowObject(self.mTab2Image,false)
	CS.ShowObject(self.mGetBtn,false)
	if(self._state==1)then
		CS.ShowObject(self.mTab2Image,true)
	elseif(self._state==2)then
		CS.ShowObject(self.mGetBtn,true)
		self:SetWndText(self.mGetBtn,ccClientText(10613))
	else
		CS.ShowObject(self.mTab1Image,true)
	end
end

function UIBoxDel:OnDrawItem(list, item, itemdata, itemPos)
	local iconTrans = CS.FindTrans(item, "CommonUI/Icon")
	self:CreateCommonIconImpl(iconTrans,itemdata)
end

function UIBoxDel:OnClickGet()
	if self._onfunc ~= nil then
		self._onfunc()
	end
	self:WndClose()
end

function UIBoxDel:InitData()
	self._offsetList =
	{
		[1] = Vector3(-83,158,0),
		[2] = Vector3(-138,158,0)
	}
	self._delayTimer = "_delayTimer"
end

function UIBoxDel:InitEvent()
	self:SetWndClick(self.mMask, function(...)
		self:WndClose()
	end)
	self:SetWndClick(self.mGetBtn, function(...)
		self:OnClickGet()
	end)
end

function UIBoxDel:OnTimer(key)
	self:SetPos()
end

function UIBoxDel:OnClickCloseWnd()
	if self._func ~= nil then
		self._func()
	end
	self:WndClose()
end

function UIBoxDel:SetPos()
	local follow = self._root
	local target = self.mRoot:GetComponent(typeofRectTransform)

	local canvasRect =LGameUI.GetUICanvasRoot()
	local targetPos=YXUIPointUtil.GetScreenPoint(canvasRect,follow)

	local canvasRectTran = canvasRect:GetComponent(typeofRectTransform)
	local area = canvasRectTran.rect
	local min = -area.width/2
	local max = area.width/2- target.rect.width

	local pos = Vector3.New(targetPos.x,targetPos.y,0)+ self._offset

	if pos.x <min then
		pos.x = min
	elseif pos.x>max then
		pos.x = max
	end
	target.localPosition = pos
end
------------------------------------------------------------------
return UIBoxDel


