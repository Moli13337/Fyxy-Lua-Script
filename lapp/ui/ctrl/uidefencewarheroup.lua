---
--- Created by wzz.
--- DateTime: 2025/3/14 11:53:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDefenceWarHeroUp:LWnd
local UIDefenceWarHeroUp = LxWndClass("UIDefenceWarHeroUp", LWnd)
------------------------------------------------------------------

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
local Tweening = DG.Tweening

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarHeroUp:UIDefenceWarHeroUp()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarHeroUp:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarHeroUp:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDefenceWarHeroUp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local heroId = self:GetWndArg("heroId")
	self._heroId = heroId

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 刷新界面
function UIDefenceWarHeroUp:Refresh()
	local heroId         = self._heroId
	local heroLev        = gModelDefenceWar:GetHeroLev(heroId)
	local heroRef        = gModelDefenceWar:GetHeroRef(heroId)
	local heroLevRef     = gModelDefenceWar:GetHeroLevRef(heroId, heroLev)
	local heroNextLevRef = gModelDefenceWar:GetHeroLevRef(heroId, heroLev + 1)

	local color          = gModelItem:GetColorStringByQualityId(heroRef.quality)
	local strName        = ccClientText(46842, color, ccLngText(heroRef.name))
	self:SetWndText(self.mHeroName, strName)
	gModelDefenceWar:DrawCard(self, self.mDefenceWarCard, { heroId = heroId })

	-- 属性
	local attr1 = ccClientText(46828, heroLev)
	local attr2 = ""
	local attr3 = ccClientText(46830, heroLevRef.atk)
	local attr4 = ""
	local attr5 = ccClientText(46831, heroLevRef.addattr)
	local attr6 = ""
	if heroNextLevRef then
		attr2 = ccClientText(46829, heroLev + 1)
		attr4 = ccClientText(46830, heroNextLevRef.atk)
		attr6 = ccClientText(46831, heroNextLevRef.addattr)
	end
	self:SetWndText(self.mTxtAttr1, attr1)
	self:SetWndText(self.mTxtAttr2, attr2)
	self:SetWndText(self.mTxtAttr3, attr3)
	self:SetWndText(self.mTxtAttr4, attr4)
	self:SetWndText(self.mTxtAttr5, attr5)
	self:SetWndText(self.mTxtAttr6, attr6)

	self:RefreshCost()

	local btnStr = ccClientText(46834)
	if heroLev == 0 then
		btnStr = ccClientText(46835)
	end
	self:SetWndButtonText(self.mBtnConfirm, btnStr)

	CS.ShowObject(self.mMax, heroNextLevRef == nil)
	CS.ShowObject(self.mCostRoot, heroNextLevRef ~= nil)

	self:RefreshLevelList()
end

-- 刷新消耗
function UIDefenceWarHeroUp:RefreshCost()
	local heroId         = self._heroId
	local heroLev        = gModelDefenceWar:GetHeroLev(heroId)
	local heroNextLevRef = gModelDefenceWar:GetHeroLevRef(heroId, heroLev + 1)
	if not heroNextLevRef then
		return
	end
	local heroLevRef = gModelDefenceWar:GetHeroLevRef(heroId, heroLev)
	local itemList = LUtil.GetRefItemDataList(heroLevRef.upNeed)
	self:SetComList(self.mCostList, itemList, function(...) return self:OnDrawItem(...) end)

	self:SetRed(self.mBtnConfirm, gModelDefenceWar:HeroCanUp(heroId, false))
end

-- 怪物列表 item
function UIDefenceWarHeroUp:OnDrawItem(uilist, root, data)
	if not uilist then
		uilist = {}
		uilist.itemRoot = CS.FindTrans(root, "ItemRoot")
		uilist.txtNum = CS.FindTrans(root, "TxtNum")

		uilist.baseClass = CommonIcon:New()
		uilist.baseClass:Create(uilist.itemRoot)
	end

	local strNum = ""
	local needNum = data.itemNum
	local haveNum = gModelItem:GetNumByRefId(data.itemId)
	if needNum > haveNum then
		strNum = LUtil.FormatColorStr(haveNum, "lightRed") .. "/" .. needNum
	else
		strNum = LUtil.FormatColorStr(haveNum, "lightGreen") .. "/" .. needNum
	end

	self:SetWndText(uilist.txtNum, strNum)
	self:CreateCommonIconImpl(uilist.itemRoot, data, { showNum = false })

	return uilist
end

-- 星级列表 item
function UIDefenceWarHeroUp:OnDrawLevelListItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache         = {}
		itemCache.txtLev  = CS.FindTrans(item, "TxtLev")
		itemCache.txtDesc = CS.FindTrans(item, "TxtDesc")

		self:SetComponentCache(instanceID, itemCache)
	end

	local lev     = itemdata.level
	local heroLev = gModelDefenceWar:GetHeroLev(self._heroId)
	local strLev  = ccClientText(46832, lev)
	local strDesc = ccLngText(itemdata.desc)
	if heroLev >= lev then
		strLev = LUtil.FormatColorStr(strLev, "lightGreen")
		strDesc = LUtil.FormatColorStr(strDesc, "lightGreen")
	end

	self:SetWndText(itemCache.txtLev, strLev)
	self:SetWndText(itemCache.txtDesc, strDesc)
	LayoutRebuilder.ForceRebuildLayoutImmediate(item)
end

-- 初始事件
function UIDefenceWarHeroUp:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function() self:OnBtnConfirm() end)

	self:WndEventRecv(EventNames.DEFENCEWAR_HERO_UP, function() self:OnHeroUp() end)
	self:WndEventRecv(EventNames.On_Item_Change, function() self:RefreshCost() end)
end

-- 初始界面化文本
function UIDefenceWarHeroUp:InitTexts()
	self:SetWndText(self.mCloseTip, ccClientText(10103))

	self:SetTextTile(self.mMax, ccClientText(46833))
end

-- 刷新等级列表
function UIDefenceWarHeroUp:RefreshLevelList()
	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList

		local list = gModelDefenceWar:GetHeroRefList(self._heroId)
		table.sort(list, function(a, b)
			if a.level ~= b.level then
				return a.level < b.level
			end
			return a.refId < b.refId
		end)
		local dataList = {}
		for i = 2, #list do
			table.insert(dataList, list[i])
		end

		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawLevelListItem(...)
		end, UIItemList.SUPER, true)
	else
		self._uiList:DrawAllItems()
	end
end

-- 点击确认
function UIDefenceWarHeroUp:OnBtnConfirm()
	if not gModelDefenceWar:HeroCanUp(self._heroId, true) then
		return
	end

	local heroLev = gModelDefenceWar:GetHeroLev(self._heroId)
	local type = heroLev == 0 and 1 or 2

	gModelDefenceWar:ProtectCityUpLevelHeroReq(self._heroId, type)
end

-- 英雄升级返回
function UIDefenceWarHeroUp:OnHeroUp()
	local effName1 = "fx_ui_bwmnc_shengji_01"
	local effName2 = "fx_ui_bwmnc_shengji_02"

	self:CreateWndEffect(self.mHeroUpEff1, effName1, effName1, 100)

	local seqTween
	seqTween = self:TweenSeqCreate("UIDefenceWarHeroUp", function(seq)
		for i = 1, 6 do
			seq:AppendInterval(i * 0.02)
			seq:AppendCallback(function()
				self:CreateWndEffect(self["mAttrEff" .. i], effName2, i, 100)
			end)
		end

		return seq
	end)
	seqTween:Restart()

	self:Refresh()
end

------------------------------------------------------------------
return UIDefenceWarHeroUp