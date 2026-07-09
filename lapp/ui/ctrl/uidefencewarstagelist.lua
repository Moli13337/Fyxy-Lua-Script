---
--- Created by wzz.
--- DateTime: 2025/3/4 11:58:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDefenceWarStageList:LWnd
local UIDefenceWarStageList = LxWndClass("UIDefenceWarStageList", LWnd)
------------------------------------------------------------------

local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
local typeOfImage = typeof(UnityEngine.UI.Image)

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarStageList:UIDefenceWarStageList()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarStageList:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarStageList:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDefenceWarStageList:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 绘制列表item项
function UIDefenceWarStageList:OnDrawListItem(list, item, itemData, itemPos)
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

	local monsterList = gModelDefenceWar:GetMonsterList(nil, ref)

	itemCache.scrollRect.horizontal = #monsterList > 5
	itemCache.viewPortImg.raycastTarget = #monsterList > 5

	self:SetComList(itemCache.list, monsterList, function(...) return self:OnDrawMonsterItem(...) end)
end

-- 初始界面化文本
function UIDefenceWarStageList:InitTexts()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndText(self.mTitle, ccClientText(46822))
end

-- 初始事件
function UIDefenceWarStageList:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
end

-- 刷新界面
function UIDefenceWarStageList:Refresh()
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

-- 怪物列表 item
function UIDefenceWarStageList:OnDrawMonsterItem(uilist, root, data)
	if not uilist then
		uilist = {}
		uilist.icon = CS.FindTrans(root, "Icon")
		uilist.txtName = CS.FindTrans(root, "TxtName")

		uilist.baseClass = CommonIcon:New()
		uilist.baseClass:Create(uilist.icon)
	end

	local monsterRefId = data
	local ref = gModelDefenceWar:GetMonsterRef(monsterRefId)
	local heroRefId = ref.monsterShow
	-- local heroRef = gModelHero:GetHeroRef(heroRefId)
	local heroEffectRef = gModelHero:GetHeroEffectRef(heroRefId)
	local heroData = {
		refId = heroRefId,
		star  = gModelHero:GetHeroInitStarByRefId(heroRefId)
	}

	local baseClass = uilist.baseClass
	baseClass:SetHeroDataSet(heroData)
	baseClass:EnableShowNum(false)
	baseClass:SetNoShowLv(true)
	baseClass:SetShowStarList(false)
	baseClass:DoApply()

	self:SetWndText(uilist.txtName, ccLngText(ref.name))

	self:SetWndClick(root, function()
		GF.OpenWnd("UIDefenceWarMonsterTips", {monsterRefId = monsterRefId})
	end)

	return uilist
end

------------------------------------------------------------------
return UIDefenceWarStageList