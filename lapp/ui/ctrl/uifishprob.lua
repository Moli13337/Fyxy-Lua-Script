---
--- Created by wzz.
--- DateTime: 2025/6/17 11:04:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishProb:LWnd
local UIFishProb = LxWndClass("UIFishProb", LWnd)
------------------------------------------------------------------

-- 类型排序
local function SortFishType(a, b)
	return a.fishType < b.fishType
end

-- 鱼排序
local function SortFish(a, b)
	if a.fishRef.quality ~= b.fishRef.quality then
		return a.fishRef.quality < b.fishRef.quality
	end
	return a.fishRef.refId < b.fishRef.refId
end


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishProb:UIFishProb()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishProb:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishProb:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishProb:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._curTabIndex = 1

	self:InitTexts()
	self:InitEvents()
	self:InitTab()
	self:Refresh()
end

-- 点击列表item
function UIFishProb:OnClickItem(data)
	GF.OpenWnd("UIFishTips", { refId = data.refId })
end

-- 列表 item
function UIFishProb:OnDrawItem(uilist, root, data)
	if not uilist then
		uilist = {}
		uilist.itemRoot = CS.FindTrans(root, "itemRoot")
		uilist.txtPer = CS.FindTrans(root, "txtPer")
	end

	self:SetWndText(uilist.txtPer, data.ref.probabilityShow * 100 .. "%")

	self:CreateCommonIconImpl(uilist.itemRoot, data.item,
		{ showNum = false, clickFunc = function() self:OnClickItem(data.item) end })

	return uilist
end

-- 绘制列表item项
function UIFishProb:OnDrawListItem(list, item, itemData, itemPos)
	local title    = CS.FindTrans(item, "Title/TxtTitle")
	local fishType = itemData.fishType
	local fishRef  = gModelFish:GetFishTypeRef(fishType)

	self:SetWndText(title, ccClientText(44364, ccLngText(fishRef.name), itemData.per * 100))

	local num = #itemData.list
	local minH = 205
	local lineNum = math.ceil(num / 5)
	local itemH = minH + (lineNum - 1) * 135 + (lineNum - 2) * 10

	LxUiHelper.SetSizeWithCurAnchor(item, 1, itemH)
	self:SetComList(item, itemData.list, function(...) return self:OnDrawItem(...) end)
end

-- tab item
function UIFishProb:OnDrawTabItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			root   = item,
			btnTab = CS.FindTrans(item, "BtnTab1"),

		}
		self:SetComponentCache(instanceID, itemCache)
	end

	self:SetWndTabStatus(itemCache.btnTab, self._curTabIndex ~= itempos and 1 or 0)
	self:SetWndTabText(itemCache.btnTab, ccLngText(itemdata.name))
	self:SetWndClick(itemCache.btnTab, function()
		if self._curTabIndex == itempos then
			return
		end
		self._curTabIndex = itempos
		list:DrawAllItems()
		self:Refresh()
	end)
end

-- 初始界面化文本
function UIFishProb:InitTexts()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndText(self.mTxtTips, ccClientText(44365))
end

-- 初始tab
function UIFishProb:InitTab()
	local dataList = gModelFish:GetAllFishRefList()
	local uilist = self:GetUIScroll("mTabScroll")
	uilist:Create(self.mTabScroll, dataList, function(...)
		self:OnDrawTabItem(...)
	end)
	uilist:EnableScroll(true, true)
	self._tabDataList = dataList
end

-- 初始事件
function UIFishProb:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

-- 刷新界面
function UIFishProb:Refresh()
	local map = {}
	local fishPoolRef = self._tabDataList[self._curTabIndex]
	self:SetWndText(self.mTitle, ccLngText(fishPoolRef.name))

	local _type = tonumber(fishPoolRef.reward)

	for _, v in pairs(gModelFish:GetFishingJackpotRef()) do
		if v.type == _type then
			local item = LUtil.GetRefItemData(v.reward)
			local fishRef = gModelFish:GetFishRef(item.refId)
			local fishType = fishRef.type
			if not map[fishType] then
				map[fishType] = {}
				map[fishType].per = 0
				map[fishType].fishType = fishType
				map[fishType].list = {}
			end
			local tab = {}
			tab.item = item
			tab.ref = v
			tab.fishRef = fishRef
			map[fishType].per = map[fishType].per + v.probabilityShow
			table.insert(map[fishType].list, tab)
		end
	end

	local dataList = {}
	for k, v in pairs(map) do
		table.insert(dataList, v)
		table.sort(v.list, SortFish)
	end
	table.sort(dataList, SortFishType)

	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList
		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER)
	else
		self._uiList:RefreshList(dataList)
		self._uiList:DrawAllItems()
	end
end

------------------------------------------------------------------
return UIFishProb