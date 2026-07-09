---
--- Created by BY.
--- DateTime: 2023/10/30 15:47:36
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringBoxDetailTop:LWnd
local UIringBoxDetailTop = LxWndClass("UIringBoxDetailTop", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringBoxDetailTop:UIringBoxDetailTop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringBoxDetailTop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringBoxDetailTop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringBoxDetailTop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetWndClick(self.mMask,function () self:WndClose() end)

	self:InitData()
	self:InitScrollView()
	--self:SetPos()

	self:TimerStart(self._delayTimer,0.2,false,1)
end

function UIringBoxDetailTop:OnTimer(key)
	self:SetPos()
end

function UIringBoxDetailTop:SetPos()
	local follow = self:GetWndArg(1)
	if not CS.IsValidObject(follow) then
		self:WndClose()
		return
	end
	local target = self.mAniRoot:GetComponent(typeofRectTransform)

	local canvasRect =LGameUI.GetUICanvasRoot()
	local targetPos=YXUIPointUtil.GetScreenPoint(canvasRect,follow)

	local canvasRectTran = canvasRect:GetComponent(typeofRectTransform)
	local area = canvasRectTran.rect
	local min = -area.width/2 + 5
	local max = area.width/2- target.rect.width/2-5

	local pos = Vector3.New(targetPos.x,targetPos.y,0) + Vector3(0,150,0)

	if pos.x <min then
		pos.x = min
	elseif pos.x>max then
		pos.x = max
	end

	target.localPosition = pos

	local arrowPos =Vector3.New(targetPos.x,targetPos.y,0) + Vector3(0,45,0)

	self.mArrow.localPosition = arrowPos
end

function UIringBoxDetailTop:InitScrollView()
	local itemList = self:GetWndArg(2)
	if not itemList then
		return
	end
	local t ={}
	for k,v in pairs(itemList) do
		if v.itemType ==2 then
			local cnt = v.itemNum
			for i=1,cnt do
				local data = {
					itemType = v.itemType,
					itemId = v.itemId,
				}
				table.insert(t,data)
			end
		else
			table.insert(t,v)
		end
	end


	local uiItemList = self:FindUIScroll("rewardList") -- UIItemList:New(self)
	if not uiItemList then
		uiItemList = self:GetUIScroll("rewardList")
		uiItemList:Create(self.mItemList,t, function (...)  self:OnDrawItem(...)	end)
	else
		uiItemList:RefreshList(t)
	end

	local cnt = #t
	if cnt>3 then
		uiItemList:EnableScroll(true,true)
	end



end

function UIringBoxDetailTop:OnDrawItem(list, item, itemdata, itemPos)
	local iconTrans = CS.FindTrans(item, "CommonUI/Icon")
	self:CreateCommonIconImpl(iconTrans,itemdata)
end

function UIringBoxDetailTop:InitData()

	self._delayTimer = "_delayTimer"
end
------------------------------------------------------------------
return UIringBoxDetailTop


