---
--- Created by wzz.
--- DateTime: 2024/7/9 18:19:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishIllustratedDetail:LWnd
local UIFishIllustratedDetail = LxWndClass("UIFishIllustratedDetail", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishIllustratedDetail:UIFishIllustratedDetail()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishIllustratedDetail:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishIllustratedDetail:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishIllustratedDetail:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._viewSize = self.mPanel.sizeDelta

	self:InitData()
	self:InitTexts()
	self:InitEvents()

	self:Refresh()
end

-- 点击前往
function UIFishIllustratedDetail:OnClickBtnGoto()
	gModelFish:SwitchFishSceneReq(self._ref.refId)

	GF.CloseWndByName("UIFishIllustrated")
	self:WndClose()
end

-- 数据
function UIFishIllustratedDetail:InitData()
	local refId = self:GetWndArg("refId")
	self._ref = gModelFish:GetRef(refId)
	local refList = self:GetWndArg("refList")

	local map = {}
	for i, v in ipairs(refList) do
		if not map[v.type] then
			map[v.type] = {}
		end
		table.insert(map[v.type], v)
	end
	local list = {}
	for k, v in pairs(map) do
		table.sort(v, function(a, b)
			return a.refId < b.refId
		end)
		table.insert(list, v)
	end
	table.sort(list, function(a, b)
		return a[1].type < b[1].type
	end)
	self._dataList = list
end

-- 列表 item
function UIFishIllustratedDetail:OnDrawItem(uilist, root, data)
	if not uilist then
		uilist = {}
		uilist.lock = CS.FindTrans(root, "lock")
		uilist.itemRoot = CS.FindTrans(root, "itemRoot")
	end
	local obj = gModelFish:GetFishHandbookObjObj(data.refId)
	CS.ShowObject(uilist.lock, obj == nil)

	local itemData = { itemId = data.refId, itemType = CommonIcon.ICON_TYPE_FISH }
	local showRed = gModelFish:HadRedByFishRefId(data.refId)
	local showOver = (not showRed and obj ~= nil) and gModelFish:IsOver(data.refId) or false
	self:CreateCommonIconImpl(uilist.itemRoot, itemData, { showNum = false, showOver = showOver,  clickFunc = function() self:OnClickItem(data) end })
	self:SetRed(root, showRed)

	return uilist
end

-- 绘制列表item项
function UIFishIllustratedDetail:OnDrawListItem(list, item, itemData, itemPos)
	local title    = CS.FindTrans(item, "Title/TxtTitle")
	local lock     = CS.FindTrans(item, "Lock")
	local refList  = itemData
	local fishType = refList[1].type
	local fishRef  = gModelFish:GetFishTypeRef(fishType)
	self:SetWndText(title, ccLngText(fishRef.name))

	local num = #refList
	local minH = 170
	local lineNum = math.ceil(num / 5)
	local itemH = minH + (lineNum - 1) * 110

	LxUiHelper.SetSizeWithCurAnchor(item, 1, itemH)
	self:SetComList(item, refList, function(...) return self:OnDrawItem(...) end)
end

-- 点击列表item
function UIFishIllustratedDetail:OnClickItem(data)
	GF.OpenWnd("UIFishTips", { refId = data.refId })
end

-- 初始界面化文本
function UIFishIllustratedDetail:InitTexts()
	self:SetWndText(self.mTitle, ccLngText(self._ref.name))
	self:SetWndButtonText(self.mBtnGoto, ccClientText(44222))
end

-- 初始事件
function UIFishIllustratedDetail:InitEvents()
	self:SetWndClick(self.mBtnGoto, function() self:OnClickBtnGoto() end)
	self:SetWndClick(self.mMask, function() self:WndClose() end)

	self:WndEventRecv(EventNames.FISH_BASE_INFO, function(...) self:Refresh(...) end)
end

-- 刷新界面
function UIFishIllustratedDetail:Refresh()

	local curRef = gModelFish:GetCurRef()
	local maxUnlockRefId = gModelFish:GetMaxUnlockRefId()

	local showGoTog = self._ref.refId <= maxUnlockRefId and curRef.refId ~= self._ref.refId
	CS.ShowObject(self.mBtnGoto, showGoTog)
	if not showGoTog then
		self.mPanel.sizeDelta = Vector2(self._viewSize.x, self._viewSize.y - 60)
	end

	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList
		uiList:Create(self.mList, self._dataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER)
	else
		self._uiList:DrawAllItems()
	end
end

------------------------------------------------------------------
return UIFishIllustratedDetail