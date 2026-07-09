---
--- Created by BY.
--- DateTime: 2023/10/9 15:03:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UILotteryRltsPop:LWnd
local UILotteryRltsPop = LxWndClass("UILotteryRltsPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UILotteryRltsPop:UILotteryRltsPop()
	self._uiCommonList = {}
	self._effEndTimeKey = "_effEndTimeKey"
	self._heroEffectList = {
		[4] = "fx_ui_ZHJS_yingxiong_zise",
		[5] = "fx_ui_ZHJS_yingxiong_chengse",
	}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UILotteryRltsPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UILotteryRltsPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UILotteryRltsPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetStatic()

	local wndType = self:GetWndArg("wndType") or 1
	self._wndType = wndType
	if wndType == 1 then
		self:ShowTypeOne()
	elseif wndType == 2 then
		self:ShowTypeTwo()
	end

end
function UILotteryRltsPop:OnClickEndEff()
	self:EndAni()
end



function UILotteryRltsPop:OnTryTcpReconnect()
	self:WndClose()
end
function UILotteryRltsPop:OnClickQuit()
	if self._isAniEff then return end
	local _result = self._result
	local select = _result and _result.select or 0
	if select ~= 0 then
		self:WndClose()
		return
	end

	gModelGeneral:OpenUIOrdinTips({
		refId = 470404,
		func = function ()
			local params = string.replace("#a1#,#a2#,#a3#",self._round,0,self._index)
			gModelActivity:OnActivityDropSelectReq(2, self._sid, self._pageId, params)
			self:WndClose()
		end
	})
end

function UILotteryRltsPop:InitEventTwo()
	self:SetWndClick(self.mTheGasBg,function ()self:OnClickShareTwo() end)
	self:SetWndClick(self.mBtnQuit,function ()self:OnClickQuitTwo() end)
	self:SetWndClick(self.mBtnSave,function ()self:OnClickSaveTwo() end)
	self:SetWndClick(self.mBtnSummon,function ()self:OnClickSummonTwo() end)
	self:SetWndClick(self.mAniEff,function ()self:OnClickEndEff() end)
end

function UILotteryRltsPop:OnDrawReward(list, item, itemdata, itempos)
	local Root = self:FindWndTrans(item,"Root")
	local RootItemRoot = self:FindWndTrans(Root,"itemRoot")
	local itemRootIcon = self:FindWndTrans(RootItemRoot,"Icon")
	local itemRootEffectRoot = self:FindWndTrans(RootItemRoot,"EffectRoot")
	local RootName = self:FindWndTrans(Root,"Name")


	self:CreateCommonIconImpl(itemRootIcon,itemdata)
	local itemName = gModelGeneral:GetCommonItemName({itemType = itemdata.itemType,itemId = itemdata.itemId})
	self:SetWndText(RootName,itemName)
	self:InitTextShowWithLanguage(RootName)

	local instanceID = itemRootEffectRoot:GetInstanceID()
	self:DestroyWndEffectByKey(instanceID)
	if itemdata.itemType == LItemTypeConst.TYPE_HERO then
		self:ShowHeroEff(itemRootEffectRoot,instanceID,itemdata.itemId)
	end
end


function UILotteryRltsPop:SetStatic()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mTheGasText,ccClientText(30913))

	self:SetWndButtonText(self.mBtnSave,ccClientText(30905))
	self:SetWndButtonText(self.mBtnSummon,ccClientText(30902))
	self:SetWndClick(self.mMask,function() self:OnClickClose() end)

end
function UILotteryRltsPop:SetPageData()
	if not self._awardEntrys then
		local _pages = self._pages
		local awardPage = _pages[self._pageId]
		if not awardPage then return end
		local list = {}
		for i, v in ipairs(awardPage.entry) do
			list[v.entryId] = v
		end
		self._awardEntrys = list
	end
end
function UILotteryRltsPop:EndAni()
	self:TimerStop(self._effEndTimeKey)

	local endFunc = function ()
		CS.ShowObject(self.mAniEff, false)
		self:RefreshData()
		self._isAniEff = false
	end

	if self._wndType == 1 then
		self:ShowUpHeroList(endFunc)
	else
		self:ShowUpHeroListTwo(endFunc)
	end
end
function UILotteryRltsPop:InitEvent()
	self:SetWndClick(self.mTheGasBg,function ()self:OnClickShare() end)
	self:SetWndClick(self.mBtnQuit,function ()self:OnClickQuit() end)
	self:SetWndClick(self.mBtnSave,function ()self:OnClickSave() end)
	self:SetWndClick(self.mBtnSummon,function ()self:OnClickSummon() end)
	self:SetWndClick(self.mAniEff,function ()self:OnClickEndEff() end)
end


function UILotteryRltsPop:InitCommand()
	--self:SetWndText(self.mCloseTip,ccClientText(10103))
	--self:SetWndText(self.mTheGasText,ccClientText(30913))
	--
	--self:SetWndButtonText(self.mBtnSave,ccClientText(30905))
	--self:SetWndButtonText(self.mBtnSummon,ccClientText(30902))

	local sid = self:GetWndArg("sid")
	local pageId = self:GetWndArg("pageId")
	local result = self:GetWndArg("result")
	local isNoEff = self:GetWndArg("isNoEff")

	self._sid = sid
	self._pageId = pageId
	self._result = result
	self._round = result.round
	self._index = result.index
	self._isAniEff = not isNoEff

	self:SetWndButtonText(self.mBtnQuit,result.select ~= 0 and ccClientText(30904) or ccClientText(30921))

	self:OnActivityConfigData()
end

function UILotteryRltsPop:OnTimer(key)
	if key == self._effEndTimeKey then
		self:EndAni()
	elseif key == self._canCloseTimeKey then
		self._canClose = true
		CS.ShowObject(self.mCloseTip, true)
	end
end

function UILotteryRltsPop:ShowTypeTwo()
	self:InitEventTwo()
	local result = self:GetWndArg("result")
	local str = result.select ~= 0 and ccClientText(30904) or ccClientText(30921)
	self:SetWndButtonText(self.mBtnQuit,str)
	self._callLeftShow = ModelItem.THOUSAND_CALL_TOTAL - result.index

	self._isAniEff = not self:GetWndArg("isNoEff")
	if self._isAniEff then
		self:StarAniEff()
	else
		self:RefreshContentTwo()
	end
end
function UILotteryRltsPop:GetShareJsonData()
	local _awardEntrys = self._awardEntrys or {}
	local currData = self._result
	if not currData then return end
	local playerName = gModelPlayer:GetPlayerName()
	local drops = currData.drops
	local list = {}
	for i, v in ipairs(drops) do
		local itemData = _awardEntrys[v]
		if itemData then
			local rewards = LxDataHelper.SevenParseItems(itemData.items)
			local reward = rewards[1]
			local data = {
				count = reward.itemNum,
				effect = reward.isShowEff,
				itemId = reward.itemId,
				type = reward.itemType
			}
			table.insert(list,data)
		end
	end

	local data = {
		extraReward = list,
		createTime 	= currData.createTime,
		rankValue	= currData.rankValue,
		callPlayerName = playerName,
		shareType = ModelChat.CHAT_SHARE_33
	}
	return JSON.encode(data)
end
function UILotteryRltsPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)


end

function UILotteryRltsPop:OnClickClose()
	if self._isAniEff then return end
	self:WndClose()
end
function UILotteryRltsPop:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		_pages[page.pageId] = page
	end
	self._pages = _pages
	self:SetPageData()
	if self._isAniEff then
		return
	end
	self:RefreshData()
end

function UILotteryRltsPop:OnClickShareTwo()
	local result = self:GetWndArg("result")
	gModelItem:ShareCallResult({result=result,root = self.mBtnShare})
end

function UILotteryRltsPop:RefreshRewardShow()
	local showData = self:GetWndArg("result")

	self:SetWndText(self.mTheGasValueText,showData.rankValue)
	local dataList = LxDataHelper.ParseItem(showData.reward)

	local index = showData.index

	local showBtn = index >3

	CS.ShowObject(self.mBtnSave,showBtn)
	CS.ShowObject(self.mBtnQuit,showBtn)


	self:CreateUIScrollImpl("rewardList",self.mRewardList,dataList,function (...)
		self:OnDrawReward(...)
	end,UIItemList.SUPER_GRID)
end
function UILotteryRltsPop:OnClickShare()
	local jsonStr = self:GetShareJsonData()
	local data = {
		root = self.mBtnShare,
		shareType = ModelChat.CHAT_SHARE_33,
		shareData = jsonStr
	}
	gModelGeneral:OpenShareTip(data)
end

function UILotteryRltsPop:OnClickSaveTwo()
	local oldData = self:GetWndArg("itemdata")
	local itemdata = gModelItem:FormatItemUniqueData(oldData.refId,oldData.id)
	local para = {
		result = self:GetWndArg("result"),
		round = self:GetWndArg("round"),
		itemdata = itemdata,
		wndType = 2,
	}
	GF.OpenWnd("UILotteryRltsSelect",para)
	self:WndClose()
end

function UILotteryRltsPop:OnClickQuitTwo()
	if self._isAniEff then
		return
	end
	local result = self:GetWndArg("result")
	local select = result and result.select or 0
	if select ~= 0 then
		self:WndClose()
		return
	end
	local itemdata = self:GetWndArg("itemdata")
	local refId = itemdata.refId
	local id = itemdata.id
	local round = self:GetWndArg("round")

	local para = {
		refId = 470404,
		func = function ()
			gModelItem:ItemUseThousandQuit(refId,1,{id = id,round = round,index =result.index})
			self:WndClose()
		end
	}

	gModelGeneral:OpenUIOrdinTips(para)
end

function UILotteryRltsPop:OnWndRefresh()
	if self._wndType == 2 then
		self:ShowTypeTwo()
	end
end

function UILotteryRltsPop:RefreshContentOne()
	CS.ShowObject(self.mAniRoot,true)

	local _sid = self._sid
	local _round = self._round
	if not _sid or not _round then return end

	local activityData = gModelActivity:GetActivityBySid(_sid)
	local moreInfo = JSON.decode(activityData.moreInfo)

	local playerCallNum = moreInfo["playerCallNum".._round]
	self._playerCallNum = playerCallNum
	local playerCallNumStr = LUtil.FormatColorStr(playerCallNum,playerCallNum > 0 and "green" or "red")
	self:SetWndText(self.mSummonText,string.replace(ccClientText(30903),playerCallNumStr))
	self:RefreshReward()
end

function UILotteryRltsPop:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	if not activityData then
		gModelActivity:ReqActivityConfigData(sid)
		return
	end
	local data = activityData.config
	local titleTwo = data.titleTwo
	self._alternativeHeroNum = data.alternativeHeroNum
	if LxUiHelper.IsImgPathValid(titleTwo) then
		self:SetWndEasyImage(self.mTitleImg,titleTwo,function()
			CS.ShowObject(self.mTitleImg,true)
		end,true)
	end
	self._tipsFour = data.tipsFour
	if not string.isempty(data.heroCallEffect) then
		self._heroCallEffect = data.heroCallEffect
	end

	if self._isAniEff then
		self:StarAniEff()
	end

	gModelActivity:OnActivityPageReq(sid)
end
function UILotteryRltsPop:RewardListItem(list, item, itemdata, itempos)
	local Root = self:FindWndTrans(item,"Root")
	local RootItemRoot = self:FindWndTrans(Root,"itemRoot")
	local itemRootIcon = self:FindWndTrans(RootItemRoot,"Icon")
	local RootName = self:FindWndTrans(Root,"Name")
	local RootEffectRoot = self:FindWndTrans(Root,"EffectRoot")

	local _awardEntrys = self._awardEntrys or {}
	local itemData = _awardEntrys[itemdata]
	if not itemData then return end
	local rewards = LxDataHelper.SevenParseItems(itemData.items)
	local reward = rewards[1]
	local itemType = reward.itemType
	local itemId = reward.itemId
	local itemNum = reward.itemNum

	local uicommonlist = self._uiCommonList
	local instanceID = item:GetInstanceID()
	local baseClass = uicommonlist[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uicommonlist[instanceID] = baseClass
		baseClass:Create(itemRootIcon)
	end
	baseClass:SetCommonReward(itemType, itemId, itemNum)
	baseClass:DoApply()

	self:DestroyWndEffectByKey(instanceID)
	if itemType == LItemTypeConst.TYPE_HERO then
		self:ShowHeroEff(RootEffectRoot,instanceID,itemId)
	end

	local itemName = gModelGeneral:GetCommonItemName({itemType = itemType,itemId = itemId})
	self:SetWndText(RootName,itemName)
	self:InitTextShowWithLanguage(RootName)

	self:SetWndClick(item,function()
		if itemType == LItemTypeConst.TYPE_HERO then
			gModelGeneral:OpenHeroSimpleTip(itemId,true)
		else
			gModelGeneral:OpenItemInfoTip(itemId,itemNum)
		end
	end)
end

function UILotteryRltsPop:ShowTypeOne()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UILotteryRltsPop:StarAniEff()
	local effRoot = self.mAniEff
	local effName = self._heroCallEffect or "fx_ui_slc_ZH"
	local effEndTimeKey = self._effEndTimeKey

	CS.ShowObject(effRoot, true)
	CS.ShowObject(self.mAniRoot, false)

	local fullPath = LxResPathUtil.GetEffectPath(effName)
	if fullPath then
		self:CreateWndEffect(effRoot, effName, effName, 100,false,false, nil , function(dpTrans)
			dpTrans.gameObject:SetActive(true)
			LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_MIRROR)
			self:TimerStart(effEndTimeKey, 0.5, false, 1)
		end)
	else
		printInfoNR("AutoEffectRef[effectname] is not find, effectname = " .. (effName or "nil"))
		self:TimerStart(effEndTimeKey, 1, false, 1)
	end
end
function UILotteryRltsPop:OnClickSave()
	GF.OpenWnd("UILotteryRltsSelect",{
		sid = self._sid,
		pageId = self._pageId,
		round = self._round,
		pages = self._pages
	})
	self:WndClose()
end
function UILotteryRltsPop:RefreshReward()
	local currData = self._result
	if not currData then return end
	local rankValue = currData.rankValue
	self:SetWndText(self.mTheGasValueText,rankValue)
	local dataList = currData.drops
	local uiList = self._itemSuperList
	if uiList then
		uiList:RefreshList(dataList)
		uiList:DrawAllItems()
	else
		uiList = self:GetUIScroll("mRewardList_UITwoHundredLottery")
		self._itemSuperList = uiList
		uiList:Create(self.mRewardList,dataList,function (...) self:RewardListItem(...) end,UIItemList.SUPER_GRID)
	end
	uiList:EnableScroll(#dataList > 10,false)
end


function UILotteryRltsPop:RefreshContentTwo()
	CS.ShowObject(self.mAniRoot,true)
	local callNumLeft = self._callLeftShow
	local str = LUtil.FormatColorStr(callNumLeft,callNumLeft > 0 and "green" or "red")
	self:SetWndText(self.mSummonText,string.replace(ccClientText(30903),str))

	self:RefreshRewardShow()

end

function UILotteryRltsPop:OnClickSummonTwo()
	local itemData = self:GetWndArg("itemdata")
	local refId = itemData.refId
	local id = itemData.id
	local round = self:GetWndArg("round")
	gModelItem:OnClickSummon(refId,id,round)


end
function UILotteryRltsPop:RefreshData()

	if self._wndType == 1 then
		self:RefreshContentOne()
	elseif self._wndType == 2 then
		self:RefreshContentTwo()
	end

	--local _sid = self._sid
	--local _round = self._round
	--if not _sid or not _round then return end
	--
	--local activityData = gModelActivity:GetActivityBySid(_sid)
	--local moreInfo = JSON.decode(activityData.moreInfo)
	--
	--local playerCallNum = moreInfo["playerCallNum".._round]
	--self._playerCallNum = playerCallNum
	--local playerCallNumStr = LUtil.FormatColorStr(playerCallNum,playerCallNum > 0 and "green" or "red")
	--self:SetWndText(self.mSummonText,string.replace(ccClientText(30903),playerCallNumStr))
	--self:RefreshReward()
end
function UILotteryRltsPop:ShowUpHeroList(func)
	local currData = self._result
	if not currData then return end
	local dataList = currData.drops
	local _awardEntrys = self._awardEntrys or {}
	local upHeroList = {}
	for i,v in ipairs(dataList) do
		local itemData = _awardEntrys[v]
		if itemData then
			local rewards = LxDataHelper.SevenParseItems(itemData.items)
			local reward = rewards[1]
			local itype = reward.itemType
			if itype == LItemTypeConst.TYPE_HERO then
				local heroRefId = reward.itemId
				local initStar = gModelHero:GetHeroInitStarByRefId(heroRefId)
				if initStar and initStar >= 4 then
					table.insert(upHeroList,{refId = heroRefId})
				end
			end
		end
	end
	gModelGeneral:ShowUpHero(upHeroList,func)
end
function UILotteryRltsPop:OnClickSummon()
	local playerCallNum = self._playerCallNum or 0
	if playerCallNum <= 0 then
		GF.ShowMessage(self._tipsFour)
		return
	end
	local sid = self._sid
	local pageId = self._pageId
	local round = self._round
	local index = self._index
	local result = self._result
	local select = result and result.select or 0

	if select ~= 0 then
		local params = string.format("%s,%s",round,index + 1)
		gModelActivity:OnActivityDropSelectReq(1,sid,pageId, params)
		self:WndClose()
		return
	end

	gModelGeneral:OpenUIOrdinTips({
		refId = 470404,
		func = function ()
			local params = string.replace("#a1#,#a2#,#a3#",round,0,index)
			gModelActivity:OnActivityDropSelectReq(2,sid,pageId, params)

			local params1 = string.replace("#a1#,#a2#",round,index + 1)
			gModelActivity:OnActivityDropSelectReq(1,sid,pageId, params1)
			self:WndClose()
		end
	})
end

function UILotteryRltsPop:ShowUpHeroListTwo(func)
	local result = self:GetWndArg("result")
	if not result then
		return
	end
	local dataList = LxDataHelper.ParseItem(result.reward)
	local upHeroList = {}
	for i,v in ipairs(dataList) do
		if v.itemType == LItemTypeConst.TYPE_HERO then
			local heroRefId = v.itemId
			local initStar = gModelHero:GetHeroInitStarByRefId(heroRefId)
			if initStar >= 4 then
				table.insert(upHeroList,{refId = heroRefId})
			end
		end
	end
	gModelGeneral:ShowUpHero(upHeroList,func)
end
function UILotteryRltsPop:ShowHeroEff(effRoot,instanceId,heroId)
	local effScaleSize = 100
	local eff
--[[	if gModelHero:CheckIsShowHeroQualityForeign() then
	else
	end]]
	local heroRef  = gModelHero:GetHeroRef(heroId)
	if heroRef then
		local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
		if qualityRef then
			local heroCallFxList = string.split(qualityRef.heroCallFx, '=')
			eff = heroCallFxList[1]
			local fxEffSize = heroCallFxList[2]
			if not string.isempty(fxEffSize) then
				effScaleSize = tonumber(fxEffSize) * 100
			end
		end
	end
	local initStar = gModelHero:GetHeroInitStarByRefId(heroId)
	if not initStar or initStar < 1 then return end

	if initStar < 4 then
		LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_HERO_NORMAL)
	end
	if not eff then
		eff = self._heroEffectList[initStar]
	end
	if eff then
		self:CreateWndEffect(effRoot,eff,instanceId,effScaleSize,false,false)
	end
end

------------------------------------------------------------------
return UILotteryRltsPop


