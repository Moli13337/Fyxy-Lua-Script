---
--- Created by wzz.
--- DateTime: 2025/3/4 17:05:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDefenceWarAwardList:LWnd
local UIDefenceWarAwardList = LxWndClass("UIDefenceWarAwardList", LWnd)
------------------------------------------------------------------

local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
local typeOfImage = typeof(UnityEngine.UI.Image)

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarAwardList:UIDefenceWarAwardList()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarAwardList:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarAwardList:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------

function UIDefenceWarAwardList:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 怪物列表 item
function UIDefenceWarAwardList:OnDrawItem(uilist, root, data)
	if not uilist then
		uilist = {}
		uilist.icon = CS.FindTrans(root, "Icon")
		uilist.txtName = CS.FindTrans(root, "TxtName")

		uilist.baseClass = CommonIcon:New()
		uilist.baseClass:Create(uilist.icon)
	end

	local strName = gModelItem:GetItemNameRichText(data.refId)
	self:SetWndText(uilist.txtName, strName)

	self:CreateCommonIconImpl(uilist.icon, data, { showNum = true})

	return uilist
end

-- 刷新界面
function UIDefenceWarAwardList:Refresh()
	local dataList = gModelDefenceWar:GetStageRefList()

	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList

		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList:RefreshList(dataList)
		self._uiList:DrawAllItems()
	end
end

-- 初始界面化文本
function UIDefenceWarAwardList:InitTexts()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndText(self.mTitle, ccClientText(46818))
end

-- 绘制列表item项
function UIDefenceWarAwardList:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			txtTitle = CS.FindTrans(item, "AniRoot/Title/TxtTitle"),
			list = CS.FindTrans(item, "AniRoot/View/Viewport/List"),
			view = CS.FindTrans(item, "AniRoot/View"),
			viewPort = CS.FindTrans(item, "AniRoot/View/Viewport"),
		}

		itemCache.scrollRect = itemCache.view:GetComponent(typeOfScrollRect)
		itemCache.viewPortImg = itemCache.viewPort:GetComponent(typeOfImage)
		self:SetComponentCache(instanceID, itemCache)
	end

	local ref = itemData
	self:SetWndText(itemCache.txtTitle, ccLngText(ref.name))


	local itemList = LUtil.GetRefItemDataList(ref.reward1)

	itemCache.scrollRect.horizontal = #itemList > 5
	itemCache.viewPortImg.raycastTarget = #itemList > 5

	self:SetComList(itemCache.list, itemList, function(...) return self:OnDrawItem(...) end)
end

-- 初始事件
function UIDefenceWarAwardList:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
end


return UIDefenceWarAwardList