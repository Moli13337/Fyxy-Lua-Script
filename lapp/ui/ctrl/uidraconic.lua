---
--- Created by wzz.
--- DateTime: 2024/4/7 16:10:57
---

local FuncIdEnum = gModelDraconic.FuncIdEnum

-- 底部tab列表
local TabList = {
	[5] = { funcId = FuncIdEnum.Main, title = ccClientText(41000), icon = "draconic_btn_1" },
	[4] = { funcId = FuncIdEnum.Summon, title = ccClientText(41001), icon = "draconic_btn_2" },
	[3] = { funcId = FuncIdEnum.Speech, title = ccClientText(41002), icon = "draconic_btn_3" },
	[2] = { funcId = FuncIdEnum.Illustrated, title = ccClientText(41003), icon = "draconic_btn_4" },
	[1] = { funcId = FuncIdEnum.Resolve, title = ccClientText(41004), icon = "draconic_btn_5" },
}

-- 背景列表
local BagList = {
	[FuncIdEnum.Main]        = "draconic_bg_1",
	[FuncIdEnum.Summon]      = "draconic_bg_2",
	[FuncIdEnum.Speech]      = "draconic_bg_3",
	[FuncIdEnum.Illustrated] = "draconic_bg_4",
	[FuncIdEnum.Resolve]     = "draconic_bg_5",
}

-- 帮助Id
local HelpIdEnum = {
	[FuncIdEnum.Main] = 165,
	-- [FuncIdEnum.Summon] = 166,
	[FuncIdEnum.Illustrated] = 167,
	[FuncIdEnum.Resolve] = 168,
}

-- 一行卡片数量
local OneLineCardNum = 4

local SummonSpineKey = 1

------------------------------------------------------------------
local LWnd = LWnd
---@class UIDraconic:LWnd
local UIDraconic = LxWndClass("UIDraconic", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconic:UIDraconic()
	self._resolveSelectMap = {}
	gModelDraconic:DraconicInfoReq()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconic:OnWndClose()
	LWnd.OnWndClose(self)

	GF.CloseWndByName("UIDraconicUpStar")
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconic:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconic:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._curFuncId = self:GetWndArg("functionId") or FuncIdEnum.Main
	--兼容越南语
	self._isEnus = gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVieVersion()
	self._isJapaness  =gLGameLanguage:IsJapanVersion()
	self._isVie = gLGameLanguage:IsVieVersion()
	if self._isEnus or self._isJapaness  then 
		self.mImgBg_1.sizeDelta =Vector2.New(320,38)
		self.mImgBg_2.sizeDelta =Vector2.New(320,148)
		self:InitTextSizeWithLanguage(self.mTxtSpeechTips2,-8)
	end
	if self._isVie then
		self.mImgBg_1.sizeDelta =Vector2.New(500,38)
		self.mImgBg_2.sizeDelta =Vector2.New(500,148)
		local TxtResolveAwardTips =self.mTxtResolveAwardTips.parent
		TxtResolveAwardTips.sizeDelta = Vector2.New(360,30)
	end
	if self._isJapaness then
		local parent = self.mTxtResolveAwardTips.parent
		parent.sizeDelta = Vector2.New(240,30)
	end
	self:InitTexts()
	self:InitTabList()
	self:InitEvents()
	self:InitEmptyTips()

	self:Refresh()
end

-- 防止同时刷新多次
function UIDraconic:OnMsgRefresh()
	local delayTime = self._curFuncId == FuncIdEnum.Speech and 0.5 or 0.3

	local timerKey = "UpDataItemTime"
	if GF.FindFirstWndByName("UIDraconicDetail") then
		self:TimerStop(timerKey)
		return
	end

	if self:IsTimerExist(timerKey) then
		self._needRefresh = true
		return
	end
	self._needRefresh = true
	local timePara = {
		func = function()
			if self._needRefresh then
				self:Refresh()
				self._needRefresh = nil
			else
				self:TimerStop(timerKey)
			end
		end,
		callOnStart = false,
		loopcnt = -1,
		interval = delayTime,
		key = timerKey
	}
	self:TimerStartImpl(timePara)
end

-- 卡片
function UIDraconic:RefreshMainCard()
	if not self._uiCardList then
		self._uiCardList = {}
		for i = 1, 4 do
			local tab           = {}
			local trans         = self["mCard" .. i]
			tab.trans           = trans
			tab.lock            = CS.FindTrans(trans, "Lock")
			tab.txtLock         = CS.FindTrans(trans, "Lock/txtLock")
			tab.empty           = CS.FindTrans(trans, "Empty")
			tab.card            = CS.FindTrans(trans, "DraconicCard")
			tab.bg              = CS.FindTrans(trans, "Bg")
			self._uiCardList[i] = tab

			self:SetWndClick(trans, function() self:OnClickMainCard(i) end)
			self:InternalUIDragSetItem(i, tab.card, CS.YXUIDrag.DragMode.DragCloneHideOrigin, nil, nil,
				trans.parent.gameObject)

			--英语环境替换下控件
		 	if self._isEnus or self._isJapaness then
				tab.txtLock  = CS.FindTrans(trans, "Lock/txtLock_enus")
			end
		end
	end

	local lev = gModelDraconic:GetLev()
	for pos, tab in ipairs(self._uiCardList) do
		local needLev = gModelDraconic:GetSkillOpenLev(pos)
		local refId
		CS.ShowObject(tab.lock, lev < needLev)
		if lev < needLev then
			local str = string.replace(ccClientText(41014), needLev)
			self:SetWndText(tab.txtLock, str)
		else
			refId = gModelDraconic:GetUseRefId(pos)
		end
		local empty = refId == nil and lev >= needLev
		CS.ShowObject(tab.empty, empty)
		CS.ShowObject(tab.card, refId ~= nil)
		if refId then
			gModelDraconic:DrawCard(self, tab.card, { refId = refId })
		end

		local showRed = false
		if empty then
			showRed = gModelDraconic:HadCanUse()
		end
		CS.ShowObject(tab.bg, refId == nil)
		self:SetRed(tab.trans, showRed)
	end
end

-- 点击卡片
function UIDraconic:OnClickMainCard(pos)
	local lev = gModelDraconic:GetLev()
	local needLev = gModelDraconic:GetSkillOpenLev(pos)
	if lev < needLev then
		GF.ShowMessage(ccClientText(41060, needLev))
		return
	end


	GF.OpenWnd("UIDraconicSelect", { pos = pos })
end

-- 点击升级
function UIDraconic:OnClickBtnUp()
	if not gModelDraconic:CanUp(true) then
		return
	end
	gModelDraconic:DraconicSoulLevelUpReq()
end

-- 显示分解获得的物品列表
function UIDraconic:RefreshResolveItem()
	local list = {}
	for refId, count in pairs(self._resolveSelectMap or {}) do
		table.insert(list, { refId = refId, count = count })
	end
	local itemList = gModelDraconic:GetDraconicResolveItemList(list)

	local instanceID = self.mResolveAward:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {}
		local uiList = UIIconEasyList:New()
		uiList:Create(self, self.mResolveAward)
		-- uiList:SetShowNum(false)
		uiList:SetIconParentPath("itemRoot")
		-- uiList:SetShowExtraNum(true, "itemNum")

		itemCache.uiList = uiList
		self:SetComponentCache(instanceID, itemCache)
	end
	itemCache.uiList:RefreshList(itemList)
	CS.ShowObject(self.mResolveAward.parent, #itemList > 0)
end

-- 坐标是否在item内
function UIDraconic:ContainItem(pos, camera)
	local RectangleContainsScreenPoint = UnityEngine.RectTransformUtility.RectangleContainsScreenPoint
	for index, v in ipairs(self._uiCardList) do
		if RectangleContainsScreenPoint(v.trans, pos, camera) then
			return index
		end
	end
	return nil
end

-- 初始化底部列表
function UIDraconic:InitTabList()
	self._uiTabItemList = {}
	local uiTabList = self:GetUIScroll("mTabScroll")
	uiTabList:Create(self.mTabScroll, TabList, function(...) self:OnDrawTabItem(...) end)
end

-- item 标题
function UIDraconic:OnDerawTitle(item, itemdata)
	self:SetWndText(item.txtTitle, itemdata.strTitle)
	self:SetWndEasyImage(item.txtBg, itemdata.bgPath)
end

-- 点击图鉴升级
function UIDraconic:OnClickBtnIllustratedUp(ref)
	if not gModelDraconic:CanUpOrActiveIllustrated(ref.refId, true) then
		return
	end

	gModelDraconic:DraconicRelationLevelUpReq(ref.refId)
end

-- 顶部资产
function UIDraconic:RefreshTopAsset()
	local assetIdList = gModelDraconic:GetSummonTopAssetList()

	self:SetTopAssetList(self.mTopAsset, assetIdList)
end

-- 召唤1次
function UIDraconic:OnClickBtnOne()
	if self._playingSummonEff then
		return
	end

	local leftFreeTimes = gModelDraconic:GetLeftFreeSummonTimes()
	local leftDiamond = gModelDraconic:GetLeftDiamondSummonTimes()
	if leftFreeTimes <= 0 then
		local constList = gModelDraconic:GetSummonCost()
		local refId = constList[1].one.refId
		local haveNum = gModelItem:GetNumByRefId(refId)
		local needNum = constList[1].one.count
		local isItem = true
		if haveNum < needNum then
			refId = constList[2].one.refId
			haveNum = gModelItem:GetNumByRefId(refId)
			needNum = constList[2].one.count
			isItem = false
			if leftDiamond <= 0 then
				GF.ShowMessage(ccClientText(41022))
				return
			end
		end

		if haveNum < needNum then
			gModelGeneral:OpenGetWayWnd({ itemId = refId })
			return
		end
		self:SendSummonMsg(isItem, 1, refId, needNum)
		return
	end

	gModelDraconic:DraconicDropReq(1)
	self:PlaySummonEff()
	gModelGameHelper:TemporaryCloseSpeed()
	LxUiHelper.PlayAudioSoundName(29)
end

-- 发送召唤
function UIDraconic:SendSummonMsg(isItem, times, refId, itemNum)
	local item = gModelDraconic:GetSummonFixedReward()
	local needItemName = gModelItem:GetNameByRefId(refId)
	local itemName = gModelItem:GetNameByRefId(item.refId)
	local wndId = 420001
	if isItem then
		wndId = 420002
	end

	local para =
	{
		refId = wndId,
		para = { itemNum .. needItemName, times .. itemName, times },
		func = function()
			if times == 10 then
				gModelDraconic:DraconicDropReq(2)
			else
				gModelDraconic:DraconicDropReq(1)
			end
			self:PlaySummonEff()
			gModelGameHelper:TemporaryCloseSpeed()
			LxUiHelper.PlayAudioSoundName(29)
		end,
	}

	gModelGeneral:OpenUIOrdinTips(para)
end

-- 刷新tab列表
function UIDraconic:RefreshTabList()
	local uiTabList = self:GetUIScroll("mTabScroll")
	uiTabList:ResetList(TabList)
end

-- 播放动画
function UIDraconic:PlaySummonSpine()
	local spine = self:FindWndSpineByKey(SummonSpineKey)
	if not spine then
		self:CreateWndSpine(self.mSummonSpine, "ui_longyu", SummonSpineKey, false, function(dpSpine)
		end)
	end
end

-- 点击许愿
function UIDraconic:OnClickBtnWish()
	GF.OpenWnd("UIDraconicSummonPool")
end

-- 召唤成功返回
function UIDraconic:OnDropReturn(func)
	self._summonSuccessedFunc = func
end

-- 重新打开界面
function UIDraconic:OnWndRefresh()
	local id = self:GetWndArg("functionId")
	GF.CloseWndByName("UIDraconicDetail")
	if id then
		self._curFuncId = id
		self:Refresh()
	end
end

-- endregion ----------------------------------------------------

-- region 龙语 --------------------------------------------------

-- 将列表一行一个划成一行多个
-- 例如：{1，2，3，4，5，6}改成{{1,2,3}, {4,5,6}}
function UIDraconic:ChangeLineNum(list, one_line_num)
	local new_list = {}
	local tab = {}
	local amount = 0
	for k, v in ipairs(list) do
		if amount == 0 then
			tab = {}
		end
		table.insert(tab, v)
		amount = amount + 1

		if amount == one_line_num then
			amount = 0
			table.insert(new_list, tab)
		elseif k == #list then
			table.insert(new_list, tab)
		end
	end
	return new_list
end

-- 显示分解获得的物品列表
function UIDraconic:ShowResolveItemList(list)
	local itemList = gModelDraconic:GetDraconicResolveItemList(list)
	local function rightFunc()
		self._resolveSelectMap = {}
		gModelDraconic:DraconicDecomposeReq(list)
	end

	for k, v in ipairs(itemList) do
		v.itemId = v.refId
		v.itype = v.type
	end

	gModelGeneral:OpenUIOrdinTips({
		refId = 420000,
		itemList = itemList,
		func = rightFunc,
	})
end

-- 长按分解列表 item
function UIDraconic:OnLongClickResolveItem(refId, num)
	GF.OpenWndUp("UIInip", { refId = refId, showNum = num })
end

-- 点击 分解列表 item
function UIDraconic:OnCickResolveItem(refId, num)
	if self._resolveSelectMap[refId] then
		self._resolveSelectMap[refId] = nil
	else
		self._resolveSelectMap[refId] = num
	end
	self:RefreshResolve()
end

-- 一键分解
function UIDraconic:OnClickBtnResolveAll()
	local list = {}
	for k, v in ipairs(self._uiResolveDataList) do
		local refId = v:GetRefId()
		local count = v:GetNum()
		if gModelDraconic:IsStarMaxByItemRefId(refId) then
			table.insert(list, { refId = refId, count = count })
		end
	end
	if #list == 0 then
		GF.ShowMessage(ccClientText(41050))
		return
	end

	self._resolveSelectMap = {}
	for k, v in ipairs(list) do
		self._resolveSelectMap[v.refId] = v.count
	end
	self:RefreshResolve()

	self:ShowResolveItemList(list)
end

-- 图鉴 item
function UIDraconic:OnDrawIllustratedItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			txtTitle  = CS.FindTrans(item, "TitleBg/TxtTitle"),
			card1     = CS.FindTrans(item, "ItemCardList/Card1"),
			card2     = CS.FindTrans(item, "ItemCardList/Card2"),
			attrItem  = CS.FindTrans(item, "Attr/AttrItem"),
			txtUpTips = CS.FindTrans(item, "Up/TxtUpTips"),
			btnUp     = CS.FindTrans(item, "Up/BtnUp"),
			txtMax    = CS.FindTrans(item, "UpMax/TxtMax")

		}
		self:SetComponentCache(instanceID, itemCache)

		self:SetWndText(itemCache.txtMax, ccClientText(41043))
	end

	local ref = itemdata
	local lev = gModelDraconic:GetIllustratedLev(ref.refId)
	local upRef = gModelDraconic:GetIllustratedUpLevRef(ref.refId, lev)
	self:SetWndText(itemCache.txtTitle, ccLngText(ref.name))

	local enough = true
	for i = 1, 2 do
		local starNum = gModelDraconic:GetSpeechStar(ref.draconicId[i])
		local param = {
			refId      = ref.draconicId[i],
			starNum    = starNum,
			showMask   = starNum == -1,
			-- showSlider = starNum == -1,
			showName   = true
		}
		gModelDraconic:DrawCard(self, itemCache["card" .. i], param)
		self:SetWndClick(itemCache["card" .. i], function() self:OnClickCard(param.refId) end)

		if upRef.upNeed > starNum then
			enough = false
		end
	end
	local color = "ff0000"
	if enough then
		color = "68e6ac"
	end
	local strUpTips
	if upRef.upNeed == 0 then
		strUpTips = ccClientText(41075, color, upRef.upNeed)
	else
		strUpTips = ccClientText(41040, color, upRef.upNeed)
	end
	self:SetWndText(itemCache.txtUpTips, strUpTips)

	self:RefreshIllustratedAttr(itemCache, ref.refId, lev)

	local isMax = upRef.upNeed == -1
	if not isMax then
		local btnStr = ""
		if lev == 0 then
			btnStr = ccClientText(41033)
		else
			btnStr = ccClientText(41041)
		end
		self:SetWndButtonText(itemCache.btnUp, btnStr)

		self:SetWndClick(itemCache.btnUp, function() self:OnClickBtnIllustratedUp(ref) end)
	end
	CS.ShowObject(itemCache.btnUp.parent, not isMax)
	CS.ShowObject(itemCache.txtMax.parent, isMax)
	self:SetRed(itemCache.btnUp, enough)
end

-- 播放召唤动画
function UIDraconic:PlaySummonEff()
	local spine = self:FindWndSpineByKey(SummonSpineKey)
	if spine then
		self._playingSummonEff = true
		self:DestroyWndEffectByKey("effectKey")
		self:CreateWndEffect(self.mSummonEff, "fx_ui_longyu_zhaohuan", "effectKey", 100, false, false, 50)
		spine:SetAnimationCompleteFunc(function(aniName)
			spine:PlayAnimation(0, "idle", true)
			self:DestroyWndEffectByKey("effectKey")
			spine:SetAnimationCompleteFunc(nil)
			if self._summonSuccessedFunc then
				self._summonSuccessedFunc()
				self._summonSuccessedFunc = nil
			end
			self._playingSummonEff = nil
			gModelGameHelper:RefreshGameSpeed()
		end)
		spine:PlayAnimation(0, "turn")
	end
end

------------------------------------------------------------------
-- 初始界面化文本
function UIDraconic:InitTexts()
	self:SetWndText(self.mTxtClose, ccClientText(42010))
	self:SetWndText(self.mTxtScoreTips, ccClientText(41015))
	self:SetWndText(self.mTxtSummonFree, ccClientText(41020))
	self:SetWndText(self.mTxtSpeechTitle, ccClientText(41027))
	self:SetWndText(self.mTxtSpeechTips2, ccClientText(41030))
	self:SetWndText(self.mTxtIllustratedTitle, ccClientText(41038))
	self:SetWndText(self.mTxtIllustratedTitle2, ccClientText(41039))
	self:SetWndText(self.mTxtResolveTitle, ccClientText(41049))
	self:SetWndText(self.mTxtResolveAwardTips, ccClientText(41074))

	self:SetTextTile(self.mBtnDetails, ccClientText(41082))
	self:SetTextTile(self.mBtnWish, ccClientText(41016))
	self:SetTextTile(self.mBtnPrivilege, ccClientText(41085))
	self:SetTextTile(self.mBtnOne, ccClientText(41018))
	self:SetTextTile(self.mBtnTen, ccClientText(41019))
	self:SetWndButtonText(self.mBtnResolve, ccClientText(41048))
	self:SetWndButtonText(self.mBtnResolveAll, ccClientText(41047))
end

-- 点击宝箱
function UIDraconic:OnClickBox(boxTrans, pos)
	local progress = gModelDraconic:GetSummonProgress()
	local refList = gModelDraconic:GetSummonProgressRef()
	local needProgress = refList[pos].progress
	local map = gModelDraconic:GetSummonBoxReceivedPosMap()
	if needProgress <= progress and not map[pos] then
		-- 可领取
		gModelDraconic:DraconicGetProgressRewardReq(pos)
		return
	end

	local itemList = {}
	for k, v in ipairs(refList[pos].items) do
		table.insert(itemList, { itemId = v.refId, itemNum = v.count, itemType = v.type })
	end
	local on = CS.FindTrans(boxTrans, "On")
	GF.OpenWnd("UIringBoxDetail", { on, itemList })
end

-- 分解
function UIDraconic:OnClickBtnResolve()
	local list = {}
	for refId, count in pairs(self._resolveSelectMap) do
		table.insert(list, { refId = refId, count = count })
	end
	if #list == 0 then
		GF.ShowMessage(ccClientText(41049))
		return
	end

	self:ShowResolveItemList(list)
end

-- 卡片item
function UIDraconic:OnDrawSpeechCard(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		local ItemTitle = CS.FindTrans(item, "ItemTitle")
		local ItemCardList = CS.FindTrans(item, "ItemCardList")
		local uiTitle = {
			item     = ItemTitle,
			txtTitle = CS.FindTrans(ItemTitle, "Title/TxtTitle"),
			txtBg    = CS.FindTrans(ItemTitle, "Title")
		}
		local uiCardList = {
			item = ItemCardList,
			card1 = CS.FindTrans(ItemCardList, "Card1"),
			card2 = CS.FindTrans(ItemCardList, "Card2"),
			card3 = CS.FindTrans(ItemCardList, "Card3"),
			card4 = CS.FindTrans(ItemCardList, "Card4"),
		}

		itemCache = {
			uiTitle      = uiTitle,
			uiCardList   = uiCardList,
			titleSize    = ItemTitle.sizeDelta,
			cardListSize = ItemCardList.sizeDelta,
		}
		self:SetComponentCache(instanceID, itemCache)
	end

	local isTitle = itemdata.strTitle ~= nil
	CS.ShowObject(itemCache.uiTitle.item, isTitle)
	CS.ShowObject(itemCache.uiCardList.item, not isTitle)

	local size
	if isTitle then
		size = itemCache.titleSize
		self:OnDerawTitle(itemCache.uiTitle, itemdata)
	else
		size = itemCache.cardListSize
		self:OnDerawCardList(itemCache.uiCardList, itemdata)
	end
	item.sizeDelta = size
end

-- 点击特权
function UIDraconic:OnClickBtnPrivilege()
	if not gModelFunctionOpen:CheckIsOpened(gModelDraconic.FuncIdEnum.Privilege, true) then
		return
	end
	GF.OpenWnd("UIWishPrigeBuyPop", {
		extra = 10,
		callfunc = function()
			gModelDraconic:DraconicInfoReq()
		end
	})
end

-- 刷新许愿
function UIDraconic:RefreshWish()
	local wishDraconicId = gModelDraconic:GetWishDraconicRefId()
	local had = wishDraconicId ~= 0
	if had then
		local ref = gModelDraconic:GetSummonItemPoolRefById(wishDraconicId)
		local item = LUtil.GetRefItemData(ref.reward)
		local iconPath = GameTable.PlayerItemRef[item.refId].icon
		self:SetWndEasyImage(self.mItemIcon, iconPath)
	end

	CS.ShowObject(self.mAdd, not had)
	CS.ShowObject(self.mItemIcon, had)

	local canWish = gModelDraconic:IsCanWish()

	self:SetRed(self.mBtnWish, not had and canWish)

	CS.ShowObject(self.mBtnWish, canWish)
	CS.ShowObject(self.mBtnPrivilege, not canWish)
end

-- 消耗
function UIDraconic:RefreshMainCost()
	local lev = gModelDraconic:GetLev()
	local btnStr = ""
	local costItemList = gModelDraconic:GetLevCost(lev)
	if costItemList then
		for i = 1, 2 do
			if costItemList[i] then
				local refId = costItemList[i].refId
				local haveNum = gModelItem:GetNumByRefId(refId)
				local needNum = costItemList[i].count
				local color = "ff7676"
				if haveNum >= needNum then
					color = "68e6ac"
				end
				haveNum = LUtil.NumberCoversion(haveNum)
				needNum = LUtil.NumberCoversion(needNum)
				local str = string.replace(ccClientText(41010), color, haveNum, needNum)
				self:SetWndText(self["mCostValue" .. i], str)

				local iconPath = gModelItem:GetItemImgByRefId(refId)
				self:SetWndEasyImage(self["mCostIcon" .. i], iconPath)
			end
		end

		btnStr = ccClientText(41011)
	else
		-- 已满级
		btnStr = ccClientText(41012)
	end
	CS.ShowObject(self.mCostRoot, costItemList ~= nil)
	self:SetWndButtonText(self.mBtnUp, btnStr)

	self:SetRed(self.mBtnUp, gModelDraconic:CanUp())
end

-- 刷新界面
function UIDraconic:Refresh()
	self:RefreshBg()
	self:RefreshTabList()

	CS.ShowObject(self.mMain, self._curFuncId == FuncIdEnum.Main)
	CS.ShowObject(self.mSummon, self._curFuncId == FuncIdEnum.Summon)
	CS.ShowObject(self.mSpeech, self._curFuncId == FuncIdEnum.Speech)
	CS.ShowObject(self.mIllustrated, self._curFuncId == FuncIdEnum.Illustrated)
	CS.ShowObject(self.mResolve, self._curFuncId == FuncIdEnum.Resolve)


	local btnTipsStr = ""
	if self._curFuncId == FuncIdEnum.Main then
		self:RefreshMain()
		btnTipsStr = ccClientText(41005)
	elseif self._curFuncId == FuncIdEnum.Summon then
		self:RefreshSummon()
	elseif self._curFuncId == FuncIdEnum.Speech then
		self:RefreshSpeech()
	elseif self._curFuncId == FuncIdEnum.Illustrated then
		self:RefreshIllustrated()
	elseif self._curFuncId == FuncIdEnum.Resolve then
		self:RefreshResolve()
	end

	self:SetTextTile(self.mBtnHelpTips, btnTipsStr)
	CS.ShowObject(self.mBtnHelp, HelpIdEnum[self._curFuncId] ~= nil)
	CS.ShowObject(self.mBtnHelpTips, btnTipsStr ~= "")
end

-- 龙语属性
function UIDraconic:RefreshSpeechAttr()
	self._uiSpeechAttrList = self._uiSpeechAttrList or {}

	local notAttr = false
	local dataList = gModelDraconic:GetSpeechAttrList()
	if #dataList == 0 then
		notAttr = true
		dataList = gModelDraconic:GetTotalAttrList()
	end


	for i = 1, 4 do
		local data = dataList[i]
		local tab = self._uiSpeechAttrList[i]
		if data and not tab then
			local obj = CS.InstantObject(self.mSpeechAttrRoot.gameObject)
			local trans = obj.transform
			trans:SetParent(self.mSpeechAttrRoot.parent, false)
			tab = {}
			tab.obj = obj
			tab.icon = CS.FindTrans(trans, "AttrIcon")
			tab.txt = CS.FindTrans(trans, "AttrValue")
			tab.name = CS.FindTrans(trans, "AttrName")
			self._uiSpeechAttrList[i] = tab
		end
		if tab then
			CS.ShowObject(tab.obj, data ~= nil)

			if data then
				local iconPath = gModelHero:GetAttributeIconById(data.refId)
				self:SetWndEasyImage(tab.icon, iconPath)

				local value = notAttr and 0 or data.value
				local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.refId, 3, value)
				self:SetWndText(tab.txt, val)

				local name = gModelHero:GetAttributeNameById(data.refId)
				self:SetWndText(tab.name, name)
			end
		end
	end
end

-- 属性
function UIDraconic:RefreshMainAttr()
	self._uiAttrList = self._uiAttrList or {}
	local dataList = gModelDraconic:GetTotalAttrList()
	for i = 1, 4 do
		local data = dataList[i]
		local tab = self._uiAttrList[i]
		if data and not tab then
			local obj = CS.InstantObject(self.mAttr.gameObject)
			local trans = obj.transform
			trans:SetParent(self.mAttr.parent, false)
			tab = {}
			tab.obj = obj
			tab.icon = CS.FindTrans(trans, "AttrIcon")
			tab.txt = CS.FindTrans(trans, "AttrValue")
			self._uiAttrList[i] = tab
		end
		if tab then
			CS.ShowObject(tab.obj, data ~= nil)

			if data then
				local iconPath = gModelHero:GetAttributeIconById(data.refId)
				self:SetWndEasyImage(tab.icon, iconPath)

				local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.refId, 3, data.value)
				self:SetWndText(tab.txt, val)
			end
		end
	end
end

-- endregion ----------------------------------------------------

-- region 分解 --------------------------------------------------
function UIDraconic:RefreshResolve()
	local dataList = gModelItem:GetItemListByItemType(gModelItem.TTEM_TYPE_DRACONIC, true)

	self._uiResolveDataList = dataList
	if not self._uiResolveList then
		local uiList = self:GetUIScroll("mResolveList")
		self._uiResolveList = uiList

		uiList:Create(self.mResolveList, dataList, function(...)
			self:OnDrawResolveItem(...)
		end, UIItemList.SUPER_GRID, true)
	else
		self._uiResolveList:RefreshList(dataList)
		self._uiResolveList:DrawAllItems()
	end
	self:RefreshResolveItem()

	CS.ShowObject(self.mNoRecord, #dataList == 0)
end

-- 初始事件
function UIDraconic:InitEvents()
	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end)
	self:SetWndClick(self.mBtnUp, function() self:OnClickBtnUp() end)
	self:SetWndClick(self.mBtnHelp, function() self:OnClickBtnHelp() end)
	self:SetWndClick(self.mBtnOne, function() self:OnClickBtnOne() end)
	self:SetWndClick(self.mBtnTen, function() self:OnClickBtnTen() end)
	self:SetWndClick(self.mBtnWish, function() self:OnClickBtnWish() end)
	self:SetWndClick(self.mBtnPrivilege, function() self:OnClickBtnPrivilege() end)
	self:SetWndClick(self.mBtnIllustratedAttr, function() self:OnClickBtnIllustratedAttr() end)
	self:SetWndClick(self.mBtnResolve, function() self:OnClickBtnResolve() end)
	self:SetWndClick(self.mBtnResolveAll, function() self:OnClickBtnResolveAll() end)
	self:SetWndClick(self.mBtnDetails, function() self:OnClickBtnSummonDetails() end)

	self:WndEventRecv(EventNames.DRACONIC_INFO_RETURN, function(...) self:OnMsgRefresh(...) end)
	self:WndEventRecv(EventNames.DRACONIC_ATTRS_RETURN, function(...) self:OnMsgRefresh(...) end)
	self:WndEventRecv(EventNames.On_Item_Change, function(...) self:OnMsgRefresh(...) end)
	self:WndEventRecv(EventNames.DRACONIC_DROP_RETURN, function(...) self:OnDropReturn(...) end)
	self:WndEventRecv(EventNames.ON_WND_CLOSE, function(...) self:CloseWnd(...) end)
end

-- endregion ----------------------------------------------------


-- region 图鉴 --------------------------------------------------
function UIDraconic:RefreshIllustrated()
	self._IllustratedRefList = self._IllustratedRefList or {}
	if not self._uiIllustratList then
		local uiList = self:GetUIScroll("mIllustratedList")
		self._uiIllustratList = uiList

		local dataList = gModelDraconic:GetIllustratedRefList()
		self._IllustratedRefList = dataList
		uiList:Create(self.mIllustratedList, dataList, function(...)
			self:OnDrawIllustratedItem(...)
		end, UIItemList.SUPER, true)
	else
		self._uiIllustratList:DrawAllItems()
	end

	local pos
	for k, v in pairs(self._IllustratedRefList) do
		if gModelDraconic:CanUpOrActiveIllustrated(v.refId) then
			pos = k
			break
		end
	end
	if pos then
		self._uiIllustratList:MoveToPos(pos)
	end
end

-- endregion ----------------------------------------------------

-- region 召唤 --------------------------------------------------
function UIDraconic:RefreshSummon()
	local leftFreeTimes = gModelDraconic:GetLeftFreeSummonTimes()

	local leftDiamond = gModelDraconic:GetLeftDiamondSummonTimes()
	self:SetWndText(self.mTxtSummonTips1, string.replace(ccClientText(41017), leftDiamond))

	self:SetRed(self.mBtnOne, leftFreeTimes > 0)
	self:ShowBtnEff(self.mBtnOneEff, "mBtnOne", leftFreeTimes > 0, "fx_ui_putongzhaohuan_04")

	-- 按钮
	CS.ShowObject(self.mSummonCostValue1, leftFreeTimes <= 0)
	CS.ShowObject(self.mTxtSummonFree, leftFreeTimes > 0)
	local constList = gModelDraconic:GetSummonCost()
	for k, v in ipairs({ "one", "ten" }) do
		local refId = constList[1][v].refId
		local haveNum = gModelItem:GetNumByRefId(refId)
		local needNum = constList[1][v].count
		if haveNum < needNum then
			refId = constList[2][v].refId
			haveNum = gModelItem:GetNumByRefId(refId)
			needNum = constList[2][v].count
		end
		local color = "68e6ac"
		if haveNum < needNum then
			color = "c81212"
		end


		needNum = string.replace(ccClientText(41021), color, needNum)
		self:SetWndText(self["mSummonCostValue" .. k], needNum)

		local iconPath = gModelItem:GetItemImgByRefId(refId)
		self:SetWndEasyImage(self["mSummonCostIcon" .. k], iconPath)
	end

	local tenRed, isItem = gModelDraconic:EnoughSummonTen()
	self:SetRed(self.mBtnTen, tenRed and isItem)
	self:ShowBtnEff(self.mBtnTenEff, "mBtnTen", tenRed, "fx_ui_putongzhaohuan_05")

	self:RefreshSummonProgress()
	self:RefreshTopAsset()
	self:RefreshWish()
	self:PlaySummonSpine()
end

-- 底部列表 item
function UIDraconic:OnDrawTabItem(list, item, itemdata, itempos)
	local tab = self._uiTabItemList[item]
	if not tab then
		tab = {}
		tab.item = item
		self._uiTabItemList[item] = tab
	end
	self:SetWndTabText(tab.item, itemdata.title)
	self:SetWndTabIcon(tab.item, itemdata.icon)
	self:SetWndClick(tab.item, function() self:OnClickTab(itemdata.funcId) end)

	self:SetWndTabStatus(tab.item, self._curFuncId == itemdata.funcId and LWnd.StateOn or LWnd.StateOff, itempos)

	self:SetRed(item, gModelDraconic:GetRedNumByFuncId(itemdata.funcId) > 0)
end

-- 分解列表 item
function UIDraconic:OnDrawResolveItem(list, item, itemdata, itempos)
	local refId = itemdata:GetRefId()
	local num = tonumber(itemdata:GetNum())
	local select = self._resolveSelectMap[refId] ~= nil

	local param = {
		refId = refId,
		num = num,
		select = select,
		clickFunc = function() self:OnCickResolveItem(refId, num) end
	}
	local itemRoot = CS.FindTrans(item, "DraconicItem")
	gModelDraconic:DrawItem(self, itemRoot, param)
	self:SetWndLongClick(itemRoot, function() self:OnLongClickResolveItem(refId, num) end)
end

-- 点击tab
function UIDraconic:OnClickTab(funcId)
	if funcId == self._curFuncId then
		return
	end
	self._curFuncId = funcId

	self._resolveSelectMap = {}
	self:Refresh()
end

-- 刷新龙语
function UIDraconic:RefreshSpeech()
	self:RefreshCardList()
	self:RefreshSpeechAttr()
end

-- 刷新背景
function UIDraconic:RefreshBg()
	self:SetWndEasyImage(self.mBg, BagList[self._curFuncId])

	CS.ShowObject(self.mIcon, self._curFuncId == FuncIdEnum.Main)
	self:ShowBtnEff(self.mBgEff, FuncIdEnum.Main, self._curFuncId == FuncIdEnum.Main, "fx_longyuchangjing")
end

-- 空列表提示
function UIDraconic:InitEmptyTips()
	local text = self.mEmptyText
	local emptyList = self:GetCommonEmptyList("_empty")
	local data =
	{
		refId = 38001,
		IntroTran = text,
		--TextBgTran,
		--IconTran,
		--GetBtn,
		--GetBtnText
		--ButtonRoot,
	}
	emptyList:RefreshUI(data)
end

-- 点击图鉴属性
function UIDraconic:OnClickBtnIllustratedAttr()
	local dataList = gModelDraconic:GetIllustratedAttrList()
	if #dataList == 0 then
		GF.ShowMessage(ccClientText(41046))
		return
	end
	GF.OpenWnd("UIDraconicIllustratedAttr")
end

-- 图鉴属性
function UIDraconic:RefreshIllustratedAttr(itemCache, refId, lev)
	if lev == 0 then
		lev = 1
	end
	itemCache._uiAttrList = itemCache._uiAttrList or {}
	local dataList = gModelDraconic:GetIllustratedAttr(refId, lev)
	for i, data in ipairs(dataList) do
		local tab = itemCache._uiAttrList[i]
		if not tab then
			local obj = CS.InstantObject(itemCache.attrItem.gameObject)
			local trans = obj.transform
			trans:SetParent(itemCache.attrItem.parent, false)
			tab                      = {}
			tab.obj                  = obj
			tab.trans                = trans
			tab.icon                 = CS.FindTrans(trans, "AttrIcon")
			tab.txt                  = CS.FindTrans(trans, "AttrValue")
			tab.name                 = CS.FindTrans(trans, "AttrName")
			itemCache._uiAttrList[i] = tab
		end

		CS.ShowObject(tab.trans, true)

		local iconPath = gModelHero:GetAttributeIconById(data.attrId)
		self:SetWndEasyImage(tab.icon, iconPath)

		local name = gModelHero:GetAttributeNameById(data.attrId)
		self:SetWndText(tab.name, name)

		local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.attrId, data.type, data.value)
		self:SetWndText(tab.txt, val)
	end

	for i = #dataList + 1, #itemCache._uiAttrList do
		CS.ShowObject(itemCache._uiAttrList[i].trans, false)
	end
end

-- 刷新卡片列表
function UIDraconic:RefreshCardList()
	if not self._uiDataList then
		local list = gModelDraconic:GetAllSpeechRefList()
		local dataList = {}
		for k, v in ipairs(list) do
			table.insert(dataList, {
				strTitle = ccLngText(v[1].qualityTxt),
				bgPath = v[1].qualityBg
			}
			)
			local lineNums = self:ChangeLineNum(v, OneLineCardNum)
			for _, line in ipairs(lineNums) do
				table.insert(dataList, line)
			end
		end
		self._uiDataList = dataList
	end
	local pos
	for k, v in ipairs(self._uiDataList) do
		for _, data in ipairs(v) do
			if gModelDraconic:CanActiveOrUpStar(data.refId) then
				pos = k
				break
			end
		end
		if pos then
			break
		end
	end

	if not self._uiList then
		local uiList = self:GetUIScroll("mCardList")
		self._uiList = uiList

		uiList:Create(self.mCardList, self._uiDataList, function(...)
			self:OnDrawSpeechCard(...)
		end, UIItemList.SUPER, true)

		if pos then
			self._uiList:MoveToPos(pos)
		end
	else
		self._uiList:RefreshData(self._uiDataList, true)
		if pos then
			self._uiList:MoveToPos(pos)
		else
			self._uiList:DrawAllItems()
		end
	end
end

-- 关闭界面
function UIDraconic:CloseWnd(wndName)
	if wndName == "UIDraconicDetail" then
		self:Refresh()
	end
end

-- 召唤进度
function UIDraconic:RefreshSummonProgress()
	local progress = gModelDraconic:GetSummonProgress()
	self:SetWndText(self.mTxtScore, progress)

	local refList = gModelDraconic:GetSummonProgressRef()
	if not self._uiBoxList then
		self._uiBoxList = {}
		self._sliderW = self.mSlider.sizeDelta.x
		self._sliderMax = refList[#refList].progress

		local rootObj = self.mBox.gameObject
		local parent = self.mBox.parent
		local y = self.mBox.anchoredPosition.y
		for k, v in ipairs(refList) do
			local obj = CS.InstantObject(rootObj)
			local boxTrans = obj.transform
			boxTrans:SetParent(parent, false)
			obj:SetActive(true)
			self:SetTextTile(boxTrans, v.progress)
			boxTrans.anchoredPosition = Vector2(v.progress / self._sliderMax * self._sliderW - 30, y)
			self._uiBoxList[k] = boxTrans

			self:SetWndClick(boxTrans, function() self:OnClickBox(boxTrans, k) end)
		end
	end

	progress = math.min(progress, self._sliderMax)
	local size = self.mSlider.sizeDelta
	self.mSlider.sizeDelta = Vector2(progress / self._sliderMax * self._sliderW, size.y)

	local map = gModelDraconic:GetSummonBoxReceivedPosMap()
	for pos, trans in ipairs(self._uiBoxList) do
		local needProgress = refList[pos].progress

		local state
		local showRed = false
		if needProgress > progress then
			-- 不可领取
			state = LWnd.StateOff
		else
			if map[pos] then
				-- 已领取
				state = LWnd.StateOn
			else
				-- 可领取
				state = LWnd.StateOff
				showRed = true
			end
		end

		self:SetWndTabStatus(trans, state)
		self:SetRed(trans, showRed)
	end
end

-- 正在拖
function UIDraconic:UIDragTryOnDrag(pos, eventData)

end

-- region 龙魂 --------------------------------------------------
function UIDraconic:RefreshMain()
	local lev = gModelDraconic:GetLev()
	local strLev = string.replace(ccClientText(41006), lev)
	self:SetWndText(self.mTxtLev, strLev)

	self:SetWndText(self.mAttrTips1, gModelDraconic:GetBaseAttrConversionStr())
	self:SetWndText(self.mAttrTips2, gModelDraconic:GetHeroAttrConversionStr())

	self:RefreshMainAttr()
	self:RefreshMainCost()
	self:RefreshMainCard()
end

-- 卡列列表
function UIDraconic:OnDerawCardList(item, itemdata)
	for i = 1, OneLineCardNum do
		local data = itemdata[i]
		CS.ShowObject(item["card" .. i], data ~= nil)
		if data then
			local starNum = gModelDraconic:GetSpeechStar(data.refId)
			local showRed = gModelDraconic:CanActiveOrUpStar(data.refId)
			if not showRed then
				showRed = gModelDraconic:CanAttach(data.refId)
			end

			local showMask = starNum == -1
			local param = {
				refId       = data.refId,
				showType    = true,
				starNum     = starNum,
				showName    = true,
				showNameBg  = true,
				showSlider  = true,
				noSliderMax = true,
				showMask    = showMask,
				showRed     = showRed,
				showFullStar = true,
			}
			gModelDraconic:DrawCard(self, item["card" .. i], param)
			self:SetWndClick(item["card" .. i], function() self:OnClickCard(data.refId) end)
		end
	end
end

-- 点击帮助
function UIDraconic:OnClickBtnHelp()
	GF.OpenWnd("UIBzTips", { refId = HelpIdEnum[self._curFuncId] })
end

-- 结束拖
function UIDraconic:UIDragTryOnEnd(pos, eventData)
	local toPos = self:ContainItem(eventData.position, eventData.pressEventCamera)
	if not toPos then
		return
	end

	if pos == toPos then
		return
	end

	local lev = gModelDraconic:GetLev()
	local needLev = gModelDraconic:GetSkillOpenLev(toPos)
	if lev < needLev then
		return
	end

	local refId = gModelDraconic:GetUseRefId(pos)

	gModelDraconic:ChangePos(pos, toPos)
	gModelDraconic:DraconicOperateReq(3, refId, pos, toPos)
	self:RefreshMainCard()
end

-- 点击卡片
function UIDraconic:OnClickCard(refId)
	-- GF.OpenWnd("UIDraconicUpStar", { refId = refId })
	GF.OpenWnd("UIDraconicDetail", { refId = refId })
end

-- 点击召唤详情
function UIDraconic:OnClickBtnSummonDetails()
	GF.OpenWnd("UIDraconicSummonRule")
end

-- 召唤10次
function UIDraconic:OnClickBtnTen()
	if self._playingSummonEff then
		return
	end

	local enough, isItem, itemRefId, needNum = gModelDraconic:EnoughSummonTen(true)
	if not enough then
		return
	end
	self:SendSummonMsg(isItem, 10, itemRefId, needNum)
end

-- 开始拖
function UIDraconic:UIDragTryOnBegin(pos, eventData)

end

-- endregion ----------------------------------------------------



return UIDraconic