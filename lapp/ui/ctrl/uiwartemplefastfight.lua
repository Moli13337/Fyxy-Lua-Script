---
--- Created by wzz.
--- DateTime: 2024/7/25 16:43:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWarTempleFastFight:LWnd
local UIWarTempleFastFight = LxWndClass("UIWarTempleFastFight", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWarTempleFastFight:UIWarTempleFastFight()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWarTempleFastFight:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWarTempleFastFight:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWarTempleFastFight:OnStart()
	LWnd.OnStart(self)
	self:InitUI()



	self._isVie = gLGameLanguage:IsVieVersion()
	self._pb = self:GetWndArg("pb")
	self:InitTexts()
	self:InitEvents()
	self:PlayEffect()
	self:Refresh()
end

-- 初始事件
function UIWarTempleFastFight:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

-- 初始化item列表
function UIWarTempleFastFight:RefreshItemList(root, itemList)
	local instanceID = root:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {}
		local uiList = UIIconEasyList:New()
		uiList:Create(self, root)
		uiList:SetShowNum(true)
		uiList:SetIconParentPath("itemRoot")
		-- uiList:SetShowExtraNum(true, "itemNum")

		itemCache.uiList = uiList
		self:SetComponentCache(instanceID, itemCache)
	end
	itemCache.uiList:RefreshList(itemList)
end

-- 初始界面化文本
function UIWarTempleFastFight:InitTexts()
	self:SetWndText(self.mTxtTips, ccClientText(42073))
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndText(self.mTxtAward, ccClientText(42075))
	if self._isVie then
		self:SetAnchorPos(self.mTxtRank,Vector2.New(-220,20))
		local parent = self.mTxtAward.parent
		self:SetAnchorPos(parent,Vector2.New(70.5,-19))
	end
end

-- 播特效
function UIWarTempleFastFight:PlayEffect()
	self:CreateWndEffect(self.mEff1, "fx_ui_wushendian_wqny_1", 1, 100)
	self:CreateWndEffect(self.mEff2, "fx_ui_wushendian_wqny_2", 2, 100)
end

-- 刷新界面
function UIWarTempleFastFight:Refresh()
	local pb = self._pb
	if not pb then
		return
	end

	local ref = GameTable.BattleTemplePalaceRef[pb.afterPalace]
	local palaceName = ccLngText(ref.name)

	self:SetWndText(self.mTxtRank, ccClientText(42074, palaceName, pb.afterPalaceRank))

	self:SetWndText(self.mTxtRankAll, ccClientText(42076, pb.afterMaxRank))

	local beforeAtkAllRank = pb.beforeAtkAllRank
	if beforeAtkAllRank == 0 then
		beforeAtkAllRank = gModelWarTemple:GetZeroRank()
	end
	local upStr = ""
	if beforeAtkAllRank > pb.afterAtkAllRank then
		upStr = ccClientText(42077, beforeAtkAllRank - pb.afterAtkAllRank)
		self:SetWndText(self.mTxtRankUp, upStr)
	end

	upStr = ""
	if beforeAtkAllRank > pb.afterMaxRank then
		upStr = ccClientText(42077, beforeAtkAllRank - pb.afterMaxRank)
		self:SetWndText(self.mTxtRankAllUp, upStr)
	end
	CS.ShowObject(self.mTxtRankAllUp.parent, upStr ~= "")

	local itemList = gModelWarTemple:GetDailyRewardItem(pb.afterPalace, pb.afterPalaceRank)
	for i = 1, 2 do
		local data = itemList[i]
		local str = ""
		if data then
			local path = gModelItem:GetItemIconByRefId(data.refId)
			self:SetWndEasyImage(self["mItemIcon" .. i], path)
			str = ccClientText(44334, data.itemNum)
		end
		CS.ShowObject(self["mItemIcon" .. i].parent, data ~= nil)
		CS.ShowObject(self["mTxtItemNum" .. i], data ~= nil)
		self:SetWndText(self["mTxtItemNum" .. i], str)
	end

	local list = {}
	for k, v in ipairs(pb.reward) do
		list[k] = {

			itemId = v.itemId,
			itemNum = v.count,
			itemType = v.type,
		}
	end
	-- 奖励
	self:RefreshItemList(self.mItemList, list)
end

------------------------------------------------------------------
return UIWarTempleFastFight