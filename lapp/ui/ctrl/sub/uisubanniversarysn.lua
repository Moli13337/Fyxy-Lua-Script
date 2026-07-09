---
---活动82 皮肤礼包子窗口
--- Created by Ease.
--- DateTime: 2023/10/7 21:12:53
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubAnniversarySn:LChildWnd
local UISubAnniversarySn = LxWndClass("UISubAnniversarySn", LChildWnd)

local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISkillCtrl = LxRequire("LApp.UI.Display.LUISkillCtrl")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubAnniversarySn:UISubAnniversarySn()
	self._timeKey = "UISubAnniversarySn"
	self._isImage = true--false                --是否显示立绘
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubAnniversarySn:OnWndClose()
	self:ClearSkill()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubAnniversarySn:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubAnniversarySn:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitBtnEvent()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubAnniversarySn:AutoPlayAni()
	local interval = gModelHero:GeConfigByKey("skinAutoPlayAniTime")
	if interval == nil then
		interval = 2
	end
	local para =
	{
		key = self._autoPlayAni,
		loop = -1,
		interval = interval,
		func = function()
			self:OnClickHeroSpine()
		end
	}

	self:TimerStartImpl(para)
end

function UISubAnniversarySn:InitBtnEvent()
	self:SetWndClick(self.mBtnCut1, function()
		self:OnClickCut(1)
	end)
	self:SetWndClick(self.mBtnCut2, function()
		self:OnClickCut(2)
	end)
	self:SetWndClick(self.mBtnImageCut, function()
		self:OnClickImageCut()
	end)
	self:SetWndClick(self.mBtnPreview, function(...)
		self:OnClickBattle()
	end)
	self:SetWndClick(self.mBtnBuy, function(...)
		self:OnClickBuy()
	end)
	self:SetWndClick(self.mBtnItemBuy, function(...)
		self:OnClickBuy()
	end)

	self:SetWndClick(self.mAcitveBtn, function(...)
		self:OnClickActive()
	end)

	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UISubAnniversarySn:OnClickSkinItem(itemdata)
	local entryId = itemdata.entryId
	if self._entryId == entryId then
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, self._pageId, entryId)
		local reward = entryCfg.reward
		local itemList = LxDataHelper.ParseItem(reward)
		local skinItem = nil
		for k,v in ipairs(itemList) do
			if gModelItem:IsSkinItem(v) then
				skinItem = v
				break
			end
		end

		gModelGeneral:ShowCommonItemTipWnd(skinItem)

	else
		self:OnClickSkin(itemdata.pageId, entryId)
		--local uiHeroList = self:FindUIScroll("mHeroSuper")
		--if uiHeroList then
		--	uiHeroList:DrawAllItems()
		--end
		for i, v in pairs(self.skinBtnList) do
			local itemTrans = v.item
			local itemData = v.itemData
			local onImg = self:FindWndTrans(itemTrans, "Root/OnImg")
			CS.ShowObject(onImg,itemData.entryId == entryId)
		end
	end
end

function UISubAnniversarySn:OnClickHeroSpine()
	local heroObj = self._curUIHeroObj
	local spine = heroObj:GetDpObject()
	if not spine then
		return
	end
	local nowPlayAniName = spine:GetCurTrackEntryName()
	if nowPlayAniName == nil or nowPlayAniName == "idle" then
		local panelPlayEff = heroObj:RandomOneSkill()
		if not panelPlayEff then
			heroObj:PlayAttackAni()
			return
		end
		local skillCtr = self._uiSkillCtrl
		if skillCtr then
			skillCtr:Destroy()
			skillCtr = nil
		end
		skillCtr = LUISkillCtrl:New(self)
		self._uiSkillCtrl = skillCtr
		local scale = self._scale *100
		skillCtr:InitData(heroObj, panelPlayEff, self.mHeroEff, 5, 12, scale)
		skillCtr:PreLoadPlaySkill()
	end
end
function UISubAnniversarySn:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
		if sid ~= self._sid then
			return
		end
		self:OnActivityConfigData()
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end

function UISubAnniversarySn:OnClickCut(cut)
	local _entryId = self._entryId
	local _skinList = self._skinList or {}
	local len = #_skinList
	local index = 1
	local itemdata = nil
	for i, v in ipairs(_skinList) do
		if _entryId == v.entryId then
			index = i
			break
		end
	end
	if cut == 1 then
		index = index - 1
		if index < 1 then
			index = len
		end
	else
		index = index + 1
		if index > len then
			index = 1
		end
	end
	itemdata = _skinList[index]
	self:OnClickSkin(itemdata.pageId, itemdata.entryId)
	local _uiHeroList = self._uiHeroList
	if not _uiHeroList then
		return
	end
	_uiHeroList:MoveToPos(index)
end

--奖励列表
function UISubAnniversarySn:SetReward(entryCfg)
	local reward = entryCfg.reward
	local list = LxDataHelper.ParseItem(reward)
	local rewardList = self._rewardList
	----当拥有购买次数且拥有拥有永久皮肤时隐藏奖励列表
	local dontShowReward = self._hasBuyTimes and self._hasFovSkinItem
	CS.ShowObject(self.mRewardScroll, not dontShowReward)
	if (dontShowReward) then
		return
	end
	-------
	if (rewardList) then
		rewardList:RefreshList(list)
	else
		rewardList = self:GetUIScroll("rewardList")
		self._rewardList = rewardList
		rewardList:Create(self.mRewardScroll, list, function(...)
			self:OnDrawCell(...)
		end, UIItemList.NORMAL)
	end
end

function UISubAnniversarySn:OnTimer(key)
	if (key == self._timeKey) then
		self:SetTime()
	end
end

function UISubAnniversarySn:SetBgImgAndPos(imgTrans, imgPath, offset)
	if (imgPath) then
		self:SetWndEasyImage(imgTrans, imgPath)
		if (offset and not string.isempty(offset)) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(offset)
			self:SetAnchorPos(imgTrans, pos)
		end
	end
	CS.ShowObject(imgTrans, imgPath ~= nil)
end

-- 创建spine
function UISubAnniversarySn:StartHeroSkillShow(refId,star,skinId,scale)
	local effectRef = gModelHero:GetShowEffectById(skinId)
	if not effectRef then
		return
	end
	self:ClearSkill()

	local prefabName = effectRef.prefabName
	local heroObj = LUIHeroObject:New(self)
	self._curUIHeroObj = heroObj
	heroObj:Create(self.mHeroSpine,prefabName,prefabName)
	heroObj:SetScale(scale)
	heroObj:SetClickFunc(function(...) self:OnClickHeroSpine(...) end)
	heroObj:SetHeroData(nil,refId,star,skinId,true)
	heroObj:ShowHero(true)
	heroObj:StartLoad()

	local para =
	{
		key = self._loopHeroObjTimerKey,
		loopcnt = -1,
		interval = 0,
		func = function()
			self:OnSkillRun()
		end
	}

	self:TimerStartImpl(para)

	self:AutoPlayAni()
end

function UISubAnniversarySn:InitMessage()
	self:WndNetMsgRecv(LProtoIds.HeroSkinSelectResp, function()
		self:RefreshData(self._entryId)
		self:RefreshSkinData()
	end)
end

--左上角货币列表
function UISubAnniversarySn:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item, "Root")
	local itemBg = self:FindWndTrans(root, "ItemBg")
	local itemIcon = self:FindWndTrans(itemBg, "ItemIcon")
	local itemText = self:FindWndTrans(itemBg, "ItemText")
	local itemId = itemdata.itemId
	local icon = gModelItem:GetItemImgByRefId(itemId)
	local itemNum = gModelItem:GetNumByRefId(itemId)

	self:SetWndEasyImage(itemIcon, icon)
	self:SetWndText(itemText, LUtil.NumberCoversion(itemNum))

	self:SetWndClick(root, function()
		-- gModelGeneral:OpenGetWayWnd({ itemId = itemId, srcWnd = "WndHappyCountryChildMag" })
	end)
end
--设置底部伙伴礼包列表
function UISubAnniversarySn:SkinListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item, "Root")
	local icon = self:FindWndTrans(root, "Icon")
	local race = self:FindWndTrans(root, "Race")
	local onImg = self:FindWndTrans(root, "OnImg")
	local hasImg = self:FindWndTrans(root, "HasImg")
	local itemName = self:FindWndTrans(root, "ItemName")
	local jsonDate = JSON.decode(itemdata.moreInfo)
	local moreInfo = jsonDate.moreInfo
	local arr = string.split(moreInfo, "|")
	local effectId = tonumber(arr[1])
	local effRef = gModelHero:GetShowEffectById(effectId)
	local ref = gModelHero:GetHeroRef(effRef.heroType)
	local raceRef = gModelHero:GetHeroRaceRefByRefId(ref.raceType)
	local heroName = gModelHero:GetHeroNameByRefId(effRef.heroType)
	local entryId = itemdata.entryId
	local _entryId = self._entryId or 1
	self:SetWndEasyImage(icon, effRef.icon)
	self:SetWndEasyImage(race, raceRef.icon)
	if gLGameLanguage:IsForeignRegion() then
		heroName = ""
	end
	self:SetWndText(itemName, heroName)  --伙伴名
	table.insert(self.skinBtnList,{item = item,itemData = itemdata})
	CS.ShowObject(onImg, _entryId == entryId)

	local entry = self:GetEntry(entryId, self._entry)
	local MarketData = entry.MarketData
	local personalGoal = MarketData.personalGoal
	local personal = MarketData.personal
	local hasBuyTimes = personalGoal - personal > 0
	local hadSkin = gModelHero:CheckHeroHadSkin(effectId)
	local hasFovSkinItem = gModelHero:CheckFovSkinItem(effectId, effRef.heroType)
	local isBuy = hadSkin or not hasBuyTimes
	if not hadSkin and hasFovSkinItem then
		isBuy = false
	else
		isBuy = hasBuyTimes and not hasFovSkinItem
	end
	CS.ShowObject(hasImg, not isBuy)
	self:SetWndClick(root, function()
		--self:OnClickSkin(itemdata.pageId, entryId)
		--local _uiHeroList = self._uiHeroList
		--if not _uiHeroList then
		--	return
		--end
		--_uiHeroList:DrawAllItems()

		self:OnClickSkinItem(itemdata)
	end)
end

function UISubAnniversarySn:OnClickImageCut()
	self._isImage = not self._isImage
	self:SetWndText(self.mImageCutText, not self._isImage and ccClientText(25904) or ccClientText(25903))
	self:SetWndEasyImage(self.mImageCutIcon, not self._isImage and "role_btn_1" or "role_btn_2")
	--self:RefreshSkinData()

	self._oldEntryId = nil

	self:RefreshHeroShow()
end


--底部伙伴皮肤礼包按钮
function UISubAnniversarySn:OnClickSkin(pageId, entryId)
	self._pageId = pageId
	self._entryId = entryId
	self:RefreshSkinData()
end

function UISubAnniversarySn:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config
	local skinShowBg = data.signImage
	self._skinCurrency = data.skinCurrency
	self:SetBgImgAndPos(self.mBg, skinShowBg)
	self:RefreshTime()
end

function UISubAnniversarySn:GetEntry(entryId, _entry)
	for i, v in ipairs(_entry) do
		if entryId == v.entryId then
			return v
		end
	end
end

function UISubAnniversarySn:ClearSkill()
	if self._curUIHeroObj then
		self._curUIHeroObj:Destroy()
		self._curUIHeroObj = nil
	end

	if self._uiSkillCtrl then
		self._uiSkillCtrl:Destroy()
		self._uiSkillCtrl= nil
	end

	self:TimerStop(self._loopHeroObjTimerKey)
	self:TimerStop(self._autoPlayAni)
end

function UISubAnniversarySn:OnWndRefresh()
	self._sid = self:GetWndArg("sid")
	self._entry = self:GetWndArg("entry")
	self._pageId = self:GetWndArg("pageId")
	local isClickBot = self:GetWndArg("isClickBot")
	if (not isClickBot) then
		self:RefreshData(self._entryId)
	else
		self:RefreshData()
	end
	self:RefreshSkinData()
	self._isFirRef = true
end
function UISubAnniversarySn:GetHeroIndexFromList(list)
	local index
	for i, v in ipairs(list) do
		if (v.entryId == self._entryId) then
			index = i
			return index
		end
	end
end

function UISubAnniversarySn:CheckWearHeroList(heroRefIde)
	local heroRefIdList = gModelHero:GetServerHeroListByRefId(heroRefIde) -- 判断是否有该类型的英雄
	local maxPowerHeroId = gModelHero:GetRefIdTypeList(heroRefIde)--最高战力流水ID
	return { heroListCnt = #heroRefIdList, maxPowerId = maxPowerHeroId }
end
function UISubAnniversarySn:OnDrawCell(list, item, itemdata, itempos)
	local Root = self:FindWndTrans(item, "Root")
	local CommonUI = self:FindWndTrans(Root, "CommonUI")
	local Icon = self:FindWndTrans(CommonUI, "Icon")
	local ownMask = self:FindWndTrans(item, "OwnMask")
	CS.ShowObject(ownMask, not self._showBuy)
	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	baseClass:DoApply()
	self:SetIconClickScale(Icon, true)
	self:SetWndClick(Icon, function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
	self:SetWndClick(ownMask, function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end
function UISubAnniversarySn:InitCommand()
	self._sid = self:GetWndArg("sid")
	self._entry = self:GetWndArg("entry")
	self._pageId = self:GetWndArg("pageId")
	self._entryId = self:GetWndArg("entryId") or nil
	self:OnActivityConfigData()
	self:RefreshData(self._entryId)
	self:RefreshSkinData()
	self:SetWndText(self.mTipsText, ccClientText(25906))
	self:SetWndText(self.mPreviewText, ccClientText(25905))
	self:InitTextSizeWithLanguage(self.mPreviewText, -4)
	self:SetWndText(self.mImageCutText, not self._isImage and ccClientText(25904) or ccClientText(25903))
	self:SetWndEasyImage(self.mImageCutIcon, not self._isImage and "role_btn_1" or "role_btn_2")
	self._isFirRef = true
end

function UISubAnniversarySn:InitData()
	self._loopHeroObjTimerKey = "_loopHeroObjTimerKey"
	self._autoPlayAni = "_autoPlayAni"
end

function UISubAnniversarySn:InitSkinData()
	CS.ShowObject(self.mHeroPaint, false)
	CS.ShowObject(self.mHeroImg, true)
	self:SetWndText(self.mTitleText, ccClientText(25901))
	CS.ShowObject(self.mRaceIcon, false)
	CS.ShowObject(self.mArrBg, false)
	CS.ShowObject(self.mCostText, false)
	CS.ShowObject(self.mBtnItemBuy, false)
	CS.ShowObject(self.mBtnBuy, false)
	CS.ShowObject(self.mBtnImageCut, false)
	CS.ShowObject(self.mBtnPreview, false)
	CS.ShowObject(self.mBuyMask, false)
	CS.ShowObject(self.mOwnMask, false)
end

function UISubAnniversarySn:SetTime()
	local _timeKey = self._timeKey
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local endTime = activityData.endTime
	if endTime <= 0 then
		self:TimerStop(_timeKey)
		self:SetWndText(self.mTimeText, ccClientText(18404))
		CS.ShowObject(self.mTimeBg, true)
		return
	end
	local time = GetTimestamp()
	local timespan = endTime - time
	local timeStr = ""
	if (timespan < 0) then
		timeStr = ccClientText(14301)
		self:TimerStop(_timeKey)
	else
		local timeF = ccClientText(25900)
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(timeF, timeStr)
	end
	self:SetWndText(self.mTimeText, timeStr)
	CS.ShowObject(self.mTimeBg, true)
end

function UISubAnniversarySn:OnClickBuy()
	local entryId = self._entryId
	local _entry = self._entry
	if not _entry or not entryId then
		if ccLog.logEnabled then
			printInfoNR("UISubAnniversarySn line 706 : OnClickBuy : _entry or entryId is nil")
		end
		return
	end
	local entry = self:GetEntry(entryId, _entry)
	local sid = self._sid
	local entryCfg = gModelActivity:GetWebActivityEntryData(sid, entry.pageId, entry.entryId)
	local expend2 = entryCfg.expend2
	gModelPay:GiftPayCtrl(entry.entryId, expend2, ModelPay.PAY_TYPE_ACTIVITY, nil, sid, entry.pageId)
end

function UISubAnniversarySn:RefreshSkinData()
	local pageId = self._pageId
	local entryId = self._entryId
	local _entry = self._entry
	if not _entry then
		return
	end
	local entry = self:GetEntry(entryId, _entry)
	local MarketData = entry.MarketData
	local personalGoal = MarketData.personalGoal
	local personal = MarketData.personal
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pageId, entryId)
	local moreInfo = entryCfg.moreInfo
	local arr = string.split(moreInfo, "|")
	local effectId = tonumber(arr[1])
	--local scale = arr[2] and tonumber(arr[2]) or 1
	--local v2 = arr[3] and LxDataHelper.ParseVector2NotEmpty(arr[3]) or nil
	--local scale2 = arr[4] and tonumber(arr[4]) or 1
	--local v22 = arr[5] and LxDataHelper.ParseVector2NotEmpty(arr[5]) or nil
	local effRef = gModelHero:GetShowEffectById(effectId)
	local ref = gModelHero:GetHeroRef(effRef.heroType)
	local raceRef = gModelHero:GetHeroRaceRefByRefId(ref.raceType)
	--local isImage = self._isImage
	--local _spineName = self._spineName
	self._battlePreview = effRef.previewReport
	local expend1 = entryCfg.expend1
	local expend2 = entryCfg.expend2
	local isItemBuy1 = string.find(expend1, "=")
	local isItemBuy2 = string.find(expend2, "=")

	CS.ShowObject(self.mBuyMask, false)
	CS.ShowObject(self.mOwnMask, false)
	CS.ShowObject(self.mCostText, false)
	CS.ShowObject(self.mCostText2, false)

	if not isItemBuy1 then
		local cost1 = gModelPay:GetShowByWelfareId(tonumber(expend1))
		CS.ShowObject(self.mCostText, true)
		self:SetWndText(self.mCostText, cost1)
	else
		local costList = LxDataHelper.ParseItem_3List(tostring(expend1))
		local cost = costList[1]
		CS.ShowObject(self.mCostText2, true)
		self:SetWndText(self.mCostText2, cost.itemNum)
		local icon = gModelItem:GetItemIconByRefId(cost.itemId)
		self:SetWndEasyImage(self.mCost2Icon, icon)
	end
	CS.ShowObject(self.mBtnItemBuy, false)
	CS.ShowObject(self.mBtnBuy, false)
	if not isItemBuy2 then
		local cost2 = gModelPay:GetShowByWelfareId(tonumber(expend2))
		CS.ShowObject(self.mBtnBuy, true)
		self:SetWndButtonText(self.mBtnBuy, cost2)
	else
		local costList = LxDataHelper.ParseItem_3List(tostring(expend2))
		local cost = costList[1]
		CS.ShowObject(self.mBtnItemBuy, true)
		self:SetWndText(self.mItemBuyText, cost.itemId)
		local icon = gModelItem:GetItemIconByRefId(cost.itemId)
		self:SetWndEasyImage(self.mItemBuyIcon, icon)
	end
	CS.ShowObject(self.mArrBg, true)
	local attrList = gModelHero:GetEffectRefAttrByRefId(effectId)
	CS.ShowObject(self.mArrtBg, attrList)
	if attrList then
		local constAttrStr = ccClientText(25907)
		local addStr = ""
		for i, v in ipairs(attrList) do
			local attrName = v.name
			local attrStr = v.attr
			local tempStr = string.replace(constAttrStr, attrName, attrStr)
			if string.isempty(addStr) then
				addStr = tempStr
			else
				addStr = addStr .. "  " .. tempStr
			end
		end
		self:SetWndText(self.mArrtText, string.replace(ccClientText(25902), addStr))
	end

	CS.ShowObject(self.mTitleBg, true)
	self:SetWndText(self.mTitleText, entryCfg.name)
	CS.ShowObject(self.mRaceIcon, true)
	self:SetWndEasyImage(self.mRaceIcon, raceRef.icon)
	CS.ShowObject(self.mBtnImageCut, true)
	CS.ShowObject(self.mBtnPreview, true)
	CS.ShowObject(self.mRewardScroll, true)
	local hasBuyTimes = personalGoal - personal > 0
	local heroIsWear = gModelHero:CheckHeroWear(effRef.heroType, effectId)
	local hadSkin = gModelHero:CheckHeroHadSkin(effectId) --检测已激活
	local hasFovSkinItem = gModelHero:CheckFovSkinItem(effectId, effRef.heroType) --检测是否拥有道具
	--local hasSkinItem2 = gModelHero:CheckOpenSkinItemStatus(effectId, effRef.heroType) --检测是否拥有道具
	local showBuy
	if not hadSkin and hasFovSkinItem then
		showBuy = false
	else
		--showBuy = hasBuyTimes and not hadSkin
		showBuy = hasBuyTimes and not hasFovSkinItem
	end
	self._showBuy = showBuy
	self._hasBuyTimes = hasBuyTimes
	self._hasFovSkinItem = hasFovSkinItem
	--购买按钮
	if (showBuy) then
		CS.ShowObject(self.mBtnBuy, not isItemBuy2)
		CS.ShowObject(self.mBtnItemBuy, isItemBuy2)
		CS.ShowObject(self.mCostText, not isItemBuy1)
		CS.ShowObject(self.mCostText2, isItemBuy1)
		CS.ShowObject(self.mAcitveBtn, false)
	else
		CS.ShowObject(self.mBtnBuy, false)
		CS.ShowObject(self.mBtnItemBuy, false)
		CS.ShowObject(self.mCostText, false)
		CS.ShowObject(self.mCostText2, false)
		--激活按钮 	--前往穿戴
		if (not heroIsWear) then
			CS.ShowObject(self.mAcitveBtn, true)
			CS.ShowObject(self.mBtnBuy, false) --effectId ==450101
			CS.ShowObject(self.mBtnItemBuy, false)
			CS.ShowObject(self.mCostText, false)
			CS.ShowObject(self.mCostText2, false)
			CS.ShowObject(self.mOwnMask, false)
			local actTxtId = hadSkin and 17411 or 17410 --17411 前往穿戴 17410 激活
			self:SetWndText(self.mActiveText, ccClientText(actTxtId))
		else
			CS.ShowObject(self.mOwnMask, true)
			CS.ShowObject(self.mAcitveBtn, false)
			CS.ShowObject(self.mBtnBuy, false) --effectId ==450101
			CS.ShowObject(self.mBtnItemBuy, false)
			CS.ShowObject(self.mCostText, false)
			CS.ShowObject(self.mCostText2, false)
		end
	end
	self:SetReward(entryCfg)
	--local spineName = isImage and effRef.heroDrawing or effRef.prefabName
	--if _spineName and _spineName == spineName then
	--	return
	--elseif _spineName then
	--	self:DestroyWndSpineByKey(_spineName)
	--end
	--local _scale = isImage and scale or scale2
	--local _v2 = isImage and v2 or v22
	--CS.ShowObject(self.mHeroPaint, true)
	--self:CreateWndSpine(self.mHeroPaint, spineName, spineName, false, function(dpSpine)
	--	dpSpine:SetScale(_scale)
	--end)
	--if _v2 then
	--	self:SetAnchorPos(self.mHeroPaint, _v2)
	--end
	--self._spineName = spineName

	self:RefreshHeroShow()
end

function UISubAnniversarySn:RefreshTime()
	local _sid = self._sid
	local _timeKey = self._timeKey
	local activityDatas = gModelActivity:GetActivityBySid(_sid)
	local _endTime = activityDatas.endTime
	if (_endTime and _endTime > 0) then
		self:TimerStop(_timeKey)
		self:TimerStart(_timeKey, 1, false, -1)
		self:SetTime()
	end
end

function UISubAnniversarySn:OnSkillRun()
	local time = Time.unscaledTime
	if self._curUIHeroObj then
		self._curUIHeroObj:OnRun(time)
	end
	if self._uiSkillCtrl then
		self:TimerStop(self._autoPlayAni)
		self._uiSkillCtrl:OnRun(time)
		local isWait = self._uiSkillCtrl._isWait
		if not isWait then
			self._uiSkillCtrl:Destroy()
			self._uiSkillCtrl = nil
			self:AutoPlayAni()
		end
	end
end
function UISubAnniversarySn:GetHeroSurpSortData(data)
	local marketData = data.MarketData
	local personalGoal = marketData.personalGoal
	local personal = marketData.personal
	local jsonDate = JSON.decode(data.moreInfo)
	local moreInfo = jsonDate.moreInfo
	local arr = string.split(moreInfo, "|")
	local effectId = tonumber(arr[1])
	local effRef = gModelHero:GetShowEffectById(effectId)
	local hasSkin = gModelHero:CheckHeroHadSkin(effectId)
	local heroWear = gModelHero:CheckHeroWear(effRef.heroType, effectId)
	local hasItem = gModelHero:CheckFovSkinItem(effectId, effRef.heroType)
	local isBuy = personalGoal - personal > 0 and 0 or 1
	local hasSkinI = hasSkin and 1 or 0
	local isWear = heroWear and 1 or 0
	local intHasItem = hasItem and 1 or 0
	return isBuy, hasSkinI, isWear, intHasItem, effectId
end

function UISubAnniversarySn:RefreshHeroShow()
	-- printInfoNR(self._oldEntryId,self._entryId)
	-- if self._oldEntryId == self._entryId then
	-- 	return
	-- end
	self:ClearSkill()
	self:DestroyWndSpineByKey("heroPaint")

	self._oldEntryId = self._entryId

	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, self._pageId, self._entryId)
	local moreInfo = entryCfg.moreInfo
	local arr = string.split(moreInfo, "|")
	local effectId = tonumber(arr[1])
	local scale = arr[2] and tonumber(arr[2]) or 1
	local v2 = arr[3] and LxDataHelper.ParseVector2NotEmpty(arr[3])
	local scale2 = arr[4] and tonumber(arr[4]) or 1
	local v22 = arr[5] and LxDataHelper.ParseVector2NotEmpty(arr[5])
	local effRef = gModelHero:GetShowEffectById(effectId)

	local isImage = self._isImage
	local pos = isImage and v2 or v22
	local scale = isImage and scale or scale2
	if isImage then
		local spineName = isImage and effRef.heroDrawing


		CS.ShowObject(self.mHeroPaint, true)
		self:CreateWndSpine(self.mHeroPaint, spineName, "heroPaint", false, function(dpSpine)
			dpSpine:SetScale(scale)
		end)
		if pos then
			self:SetAnchorPos(self.mHeroPaint, pos)
		end
	else
		if pos then
			self:SetAnchorPos(self.mSkillRoot,pos)
		end
		self._scale = scale
		local star = gModelHero:GetHeroInitStarByRefId(effRef.heroType)
		self:StartHeroSkillShow(effRef.heroType,star,effectId,scale)
	end

end

function UISubAnniversarySn:OnClickBattle()
	local _battlePreview = self._battlePreview
	if not _battlePreview then
		return
	end
	local wndIns = GF.FindFirstWndByName("UISnGift")
	if wndIns then
		wndIns:SetJumpData({
			pageId = self._pageId,
			entryId = self._entryId,
		})
	end
	gModelBattle:OnClickShamBattle(_battlePreview)
end
--激活按钮
function UISubAnniversarySn:OnClickActive()
	local pageId = self._pageId
	local entryId = self._entryId
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pageId, entryId)
	local itemList = LxDataHelper.ParseItem_3List(entryCfg.reward)
	local skinItemId = itemList[1].itemId --皮肤道具id
	local moreInfo = entryCfg.moreInfo
	local arr = string.split(moreInfo, "|")
	local effId = tonumber(arr[1])
	local ref = gModelItem:GetRefByRefId(skinItemId)
	local typeDate = string.split(ref.typeDate, "=")
	local skinRefId = tonumber(typeDate[1])
	local heroRefId = tonumber(typeDate[3])
	local effRef = gModelHero:GetShowEffectById(effId)
	local heroListData = self:CheckWearHeroList(heroRefId) -- 判断是否有该类型的英雄
	local heroListCnt = heroListData.heroListCnt -- 判断是否有该类型的英雄
	local hadSkin = gModelHero:CheckHeroHadSkin(effId)
	-- 17410 激活 17411 前往穿戴
	if heroListCnt <= 0 then
		gModelGeneral:OpenHeroSkin({ refId = effRef.heroType, skinRefId = skinRefId,preview = true })
		GF.ShowMessage(ccClientText(17420))--17420 您暂未获得该英雄无法激活使用皮肤
	else
		local maxPowerHeroId = heroListData.maxPowerId--最高战力流水ID
		if maxPowerHeroId then
			local code = 1015 --皮肤激活
			local itemType = gModelItem:GetType(skinItemId)
			if (not hadSkin) then
				gModelItem:GetWndNameByType(itemType, skinItemId, code)
			else
				local gotoHeroId = maxPowerHeroId
				gModelGeneral:OpenHeroSkin({ refId = effRef.heroType, id = gotoHeroId, gotoSkin = effId })
			end
			self:RefreshSkinData()

		end
	end
end

function UISubAnniversarySn:RefreshData(eId)
	local _entry = self._entry
	if not _entry then
		return
	end
	local entryId = self._entryId
	local pageId = self._pageId
	--------------------------------------------皮肤列表------------------------------------------------
	local skinList = {}
	self.skinBtnList = {}
	for i, v in ipairs(_entry) do
		table.insert(skinList, v)
	end
	if #skinList > 1 then
		table.sort(skinList, function(a,b)
			local aIsBuy, aHasSkinI, aIsWear, aIntHasItem, aEffectId = self:GetHeroSurpSortData(a)
			local bIsBuy, bHasSkinI, bIsWear, bIntHasItem, bEffectId = self:GetHeroSurpSortData(b)
			if(aIsBuy ~= bIsBuy)then
				return aIsBuy < bIsBuy
			end
			if(aIntHasItem ~= bIntHasItem)then
				return aIntHasItem < bIntHasItem
			end
			return aIsWear < bIsWear
		end)
	end
	local _uiHeroList = self._uiHeroList
	if _uiHeroList then
		_uiHeroList:RefreshList(skinList)
	else
		_uiHeroList = self:GetUIScroll("mHeroSuper")
		_uiHeroList:Create(self.mHeroSuper, skinList, function(...)
			self:SkinListItem(...)
		end, UIItemList.SUPER)
		self._uiHeroList = _uiHeroList
		_uiHeroList:EnableScroll(true, true)
	end
	local skinLen = #skinList
	CS.ShowObject(self.mTipsText, skinLen <= 0)
	if entryId and pageId then
		if (self._isFirRef) then
			self._isFirRef = false
			self._entryId = eId or skinList[1].entryId
			entryId = self._entryId
		end
		self:OnClickSkin(pageId, entryId)
	else
		local itemdata = skinList[1]
		self:OnClickSkin(itemdata.pageId, itemdata.entryId)
	end
	_uiHeroList:DrawAllItems()
	local index = self:GetHeroIndexFromList(skinList)
	_uiHeroList:MoveToPos(index)
	CS.ShowObject(self.mBtnCut1, skinLen > 1)
	CS.ShowObject(self.mBtnCut2, skinLen > 1)
	self._skinList = skinList
	if skinLen <= 0 then
		self:InitSkinData()
	end
	----------------------------------------------------------------------------------------------------
	--------------------------------------------兑换道具------------------------------------------------
	local _currency = self._skinCurrency
	local list = {}
	if not string.isempty(_currency) then
		local arr = string.split(_currency, "|")
		for i, v in ipairs(arr) do
			table.insert(list, { itemId = tonumber(v) })
		end
	end
	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
	else
		_uiCellList = self:GetUIScroll("mItemScroll")
		_uiCellList:Create(self.mItemScroll, list, function(...)
			self:ListItem(...)
		end)
		self._uiCellList = _uiCellList
	end
	----------------------------------------------------------------------------------------------------
end






------------------------------------------------------------------
return UISubAnniversarySn


