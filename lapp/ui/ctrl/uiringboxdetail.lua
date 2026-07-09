---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringBoxDetail:LWnd
local UIringBoxDetail = LxWndClass("UIringBoxDetail", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringBoxDetail:UIringBoxDetail()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringBoxDetail:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringBoxDetail:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringBoxDetail:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetWndClick(self.mMask,function () self:WndClose() end)

	self:InitData()
	self:InitScrollView()
	--self:SetPos()

	self:TimerStart(self._delayTimer,0.2,false,1)
end

function UIringBoxDetail:OnTimer(key)
	self:SetPos()
end

function UIringBoxDetail:InitScrollView()
	local itemList = self:GetWndArg(2)

	self._isSpecialQuest = self:GetWndArg(3)
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

				if 	self._isSpecialQuest then
					data.isGray = v.isGray
				end
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

function UIringBoxDetail:SetPos()
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

	local min = -area.width/2 + target.rect.width/2+5
	local max = area.width/2- target.rect.width/2-5

	local pos = Vector3.New(targetPos.x,targetPos.y,0) + Vector3(0,-20,0)

	if pos.x <min then
		pos.x = min
	elseif pos.x>max then
		pos.x = max
	end

	target.localPosition = pos

	local arrowPos =Vector3.New(targetPos.x,targetPos.y,0) + Vector3(0,-12,0)

	self.mArrow.localPosition = arrowPos
end

function UIringBoxDetail:OnDrawItem(list, item, itemdata, itemPos)
	local iconTrans = CS.FindTrans(item, "CommonUI/Icon")
	self:CreateCommonIconImpl(iconTrans,itemdata,{showshowGou= self._isSpecialQuest and itemdata.isGray })
end

function UIringBoxDetail:InitData()

	self._delayTimer = "_delayTimer"
end

------------------------------------------------------------------
return UIringBoxDetail


