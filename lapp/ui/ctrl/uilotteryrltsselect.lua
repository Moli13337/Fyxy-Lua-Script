---
--- Created by BY.
--- DateTime: 2023/10/9 17:36:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UILotteryRltsSelect:LWnd
local UILotteryRltsSelect = LxWndClass("UILotteryRltsSelect", LWnd)

UILotteryRltsSelect.NO_SELECT = -1
UILotteryRltsSelect.INIT = 0
UILotteryRltsSelect.SELECT = 1

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UILotteryRltsSelect:UILotteryRltsSelect()
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UILotteryRltsSelect:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UILotteryRltsSelect:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UILotteryRltsSelect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStatic()

	local wndType = self:GetWndArg("wndType") or 1

	self._wndType = wndType

	if wndType == 1 then
		self:InitEvent()
		self:InitMessage()
		self:InitCommand()
	elseif wndType == 2 then
		self:InitDataTwo()
		self:InitMessageTwo()
		self:InitEventTwo()
		self:ShowTypeTwo()
	end

end
function UILotteryRltsSelect:GetShareJsonData(itemdata)
	local _awardEntrys = self._awardEntrys or {}
	local currData = itemdata
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
function UILotteryRltsSelect:OnClickShare(btnShare,itemdata)
	local jsonStr = self:GetShareJsonData(itemdata)
	local data = {
		root = btnShare,
		shareType = ModelChat.CHAT_SHARE_33,
		shareData = jsonStr
	}
	gModelGeneral:OpenShareTip(data)
end

function UILotteryRltsSelect:OnClickGetTwo()
	local isGet = self._isGet

	if isGet then
		GF.ShowMessage(ccClientText(30918))
		return
	end
	local refId = self._itemdata.refId
	local id = self._itemdata.id
	local round = self._round
	local index = nil

	--printInfoN("cur pos ".. self._curPos)

	local data = self._saveShowList[self._curPos]
	if data.type == 2 then
		index = data.data.index
	end

	if self._unsaveRecord then
		local param =
		{
			id = id,
			round = round,
			index = self._unsaveRecord.index,
			oldIndex = index
		}

		local para = {
			refId = 470401,
			func = function()
				gModelItem:ItemUseThousandSelect(refId,1,param)
			end
		}
		gModelGeneral:OpenUIOrdinTips(para)
		return
	end

	local canGet = self._canGet
	if not canGet then
		GF.ShowMessage(ccClientText(38303))
		return
	end

	if not index then
		GF.ShowMessage(ccClientText(38304))
		return
	end

	local param = {
		id = id,
		round = round,
		index = index,
	}
	local para = {
		refId = 470402,
		func = function()
			gModelItem:ItemUseThousandGet(refId,1,param)
		end
	}

	gModelGeneral:OpenUIOrdinTips(para)
end

function UILotteryRltsSelect:OnClickShareTwo(root,itemdata)

	gModelItem:ShareCallResult({root= root,result= itemdata.data})
end
function UILotteryRltsSelect:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		_pages[page.pageId] = page
	end
	self._pages = _pages

	self:RefreshData()
end

function UILotteryRltsSelect:OnClickCell(index)
	self._index = index
	self._cellUiList:DrawAllItems()
end

function UILotteryRltsSelect:ShowTypeTwo()
	local itemdata = self._itemdata
	local round = self:GetWndArg("round")

	--self._itemdata = itemdata
	self._round = round

	local extra = itemdata.extra
	local roundDataMap = {}
	for k,v in ipairs(extra.roundList) do
		roundDataMap[v.round]= v
	end
	local roundData = roundDataMap[round]

	local unsaveRecord = nil
	local isGet = false
	local cnt = #roundData.recordList
	local saveRecords = {}
	for k,v in ipairs(roundData.recordList) do
		if v.select == ModelItem.SELECT_STATE_INIT then
			unsaveRecord = v

			--print(JSON.encode(v))

		elseif v.select == ModelItem.SELECT_STATE_SEL then
			table.insert(saveRecords,v)
		end
	end

	local hasUnsave = unsaveRecord ~= nil
	isGet = roundData.recIndex>0

	self._recIndex = roundData.recIndex


	printInfoN("has unsave "..tostring(hasUnsave))
	local str = nil
	if isGet then
		str = ccClientText(30918)
	else
		str = hasUnsave and ccClientText(30915) or ccClientText(30908)
	end

	self:SetWndButtonText(self.mBtnGet,str)

	local canGet =not isGet and cnt >=10 and not hasUnsave
	self._isGet = isGet
	self._canGet = canGet
	self._unsaveRecord = unsaveRecord

	self:SetWndButtonGray(self.mBtnGet,not canGet and not hasUnsave)
	CS.ShowObject(self.mRedPoint,canGet)
	CS.ShowObject(self.mGetEff,canGet)
	self:CreateWndEffect(self.mGetEff,"fx_anniu_03","getEffect",100)

	local desStr = ccClientText(30920)
	if hasUnsave then
		desStr = ccClientText(30919)
	elseif canGet then
		desStr = ccClientText(30907)
	end
	self:SetWndText(self.mDesText,desStr)

	local saveShowList = {}
	for k=1,3 do
		local data = saveRecords[k]
		if data then
			table.insert(saveShowList,{type = 2,data = data})
		else
			table.insert(saveShowList,{type = 1})
		end
	end

	self._saveShowList = saveShowList
	self._curPos = 1

	self:CreateUIScrollImpl("recordList",self.mCellSuper,saveShowList,function (...)
		self:OnDrawRecord(...)
	end,UIItemList.SUPER)


end

function UILotteryRltsSelect:OnTryTcpReconnect()
	self:WndClose()
end

function UILotteryRltsSelect:OnActivityConfigData()
	local _sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	if not activityData then
		gModelActivity:ReqActivityConfigData(_sid)
		return
	end
	local data = activityData.config
	local reconfirm = data.reconfirm
	self._alternativeHeroNum = data.alternativeHeroNum
	self._maxCallNum = data.maxCallNum

	if not string.isempty(reconfirm) then
		self._reconfirm = string.split(reconfirm,"|")
	end

	self._config = data

	local callNums = {}
	local callNum = data.callNum
	if not string.isempty(callNum) then
		local arrs = string.split(callNum,";")
		for i, v in ipairs(arrs) do
			local arr = string.split(v,"=")
			callNums[checknumber(arr[1])] = checknumber(arr[2])
		end
	end
	self._callNums = callNums

	if self._pages then
		self:RefreshData()
		return
	end
	gModelActivity:OnActivityPageReq(_sid)
end

function UILotteryRltsSelect:OnClickCellTwo(itemPos)
	self._curPos = itemPos
	local list = self:FindUIScroll("recordList")
	list:DrawAllItems()
end
function UILotteryRltsSelect:InitEvent()
	self:SetWndClick(self.mBtnGet,function() self:OnClickGet() end)
end

function UILotteryRltsSelect:InitMessageTwo()
	self:WndEventRecv(EventNames.On_Item_Change,function ()
		if self._wndType == 2 then

			self:ResetDataTwo()
			self:ShowTypeTwo()
		end
	end)
end

function UILotteryRltsSelect:InitEventTwo()
	self:SetWndClick(self.mBtnGet,function() self:OnClickGetTwo() end)
end
function UILotteryRltsSelect:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityDropSelectResp,function(pb)
		local opType = pb.opType
		if opType == 2 then
			local data = self._config
			GF.ShowMessage(data.tipsThree)
		end
		self:WndClose()
	end)


end

function UILotteryRltsSelect:ListItem(list, item, itemdata, itempos)
	local root = item
	local newImage = self:FindWndTrans(root, "NewImage")
	local titleText = self:FindWndTrans(root,"TextTitle")
	local rewardList = self:FindWndTrans(root,"RewardList")
	local selImg = self:FindWndTrans(root,"SelImg")
	local getImage = self:FindWndTrans(root, "GetImage")
	local theGasBg = self:FindWndTrans(root,"TheGasBg")
	local theGasText = self:FindWndTrans(root,"TheGasBg/TheGasText")
	local theGasValueText = self:FindWndTrans(root,"TheGasBg/TheGasValueText")
	local btnShare = self:FindWndTrans(root,"TheGasBg/BtnShare")
	local noRecord3 = self:FindWndTrans(root,"NoRecord3")
	local emptyText = self:FindWndTrans(root,"NoRecord3/EmptyText")

	local instanceID = item:GetInstanceID()
	local index = itemdata.index
	local rankValue = itemdata.rankValue
	local type = itemdata.type
	local receive = itemdata.receive or 0
	local curIndex = itemdata.index
	local _index = self._index or 0

	self:SetTextTile(titleText,string.replace(ccClientText(30906),itempos))
	CS.ShowObject(selImg,_index == index)

	CS.ShowObject(noRecord3,type == 1)
	CS.ShowObject(theGasBg ,type == 2)
	CS.ShowObject(rewardList,type == 2)

	if gLGameLanguage:IsJapanRegion() then
		CS.ShowObject(getImage, receive == 1)
		CS.ShowObject(newImage, curIndex == self._newIndex)
	end

	self:SetWndClick(root,function ()
		if type == 2 then
			self:OnClickCell(index)
		end
	end)
	self:SetWndClick(theGasBg,function ()
		if type == 2 then
			self:OnClickShare(btnShare,itemdata)
		end
	end)
	if type == 1 then
		self:SetWndText(emptyText,ccClientText(30917))
		return
	end
	self:SetWndText(theGasText,ccClientText(30913))
	self:SetWndText(theGasValueText,rankValue)

	local dataList = itemdata.drops
	local len = #dataList

	local uiList = self:GetUIScroll(instanceID)
	if uiList:GetList() then
		uiList:RefreshList(dataList)
		--uiList:DrawAllItems()
	else
		uiList:Create(rewardList,dataList,function (...) self:RewardListItem(...) end)
		uiList:EnableScroll(false,false)
		--uiList:Create(rewardList,dataList,function (...) self:RewardListItem(...) end,UIItemList.SUPER_GRID)
	end
	--uiList:EnableScroll(len > 10,false)
end
function UILotteryRltsSelect:RefreshData()
	local _sid = self._sid
	local alternativeHeroNum = self._alternativeHeroNum or 3
	local _round = self._round


	self:OnMaxLotteryNumList()
	local maxCallCnt = self._maxCallNum
	local maxLotteryNumList = self._maxLotteryNumList
	local roundMaxRound = maxLotteryNumList and maxLotteryNumList[_round]
	if roundMaxRound and roundMaxRound > 0 then
		maxCallCnt = roundMaxRound
	end

	local _maxCallNum = self._maxCallNum

	local activityData = gModelActivity:GetActivityBySid(_sid)
	local moreInfo = JSON.decode(activityData.moreInfo)
	local dropRecord = moreInfo.dropRecord
	local _curOpenRound = moreInfo.round
	self._curOpenRound = _curOpenRound
	self._openDay = moreInfo.openDay or _curOpenRound

	local _awardEntrys = self._awardEntrys
	if not _awardEntrys then
		local _pages = self._pages
		local awardPage = _pages[self._pageId]
		if not awardPage then return end
		local list = {}
		for i, v in ipairs(awardPage.entry) do
			list[v.entryId] = v
		end
		self._awardEntrys = list
	end
	local _isGet = false
	local currData = nil
	local dataList = {}
	local saveNum = 0
	local list = {}
	local lotteryNum = 0
	local maxIndex = 1
	for i, v in ipairs(dropRecord) do
		if v.round == _round then
			lotteryNum = lotteryNum + 1
			if v.select == self.SELECT then
				saveNum = saveNum + 1
				table.insert(list,{
					round = v.round,--轮次
					index = v.index,--序号
					drops = v.drops,--掉落记录数组 条目id
					select = v.select,--备选id
					receive = v.receive,--是否领取，同一轮次只能领取一个
					rankValue = v.rankValue,-- 欧气值
					createTime = v.createTime,--创建时间
					type = 2,
				})

				local curIndex = v.index
				if curIndex >= maxIndex then
					maxIndex = curIndex
				end
			elseif v.select == self.INIT then
				currData = v
			end
			if v.receive == 1 then
				--领取过
				_isGet = true
			end
		end
	end

	self._newIndex = maxIndex

	--CS.ShowObject(self.mBtnLook,currData)
	local getStr = _isGet and ccClientText(30918) or (currData and ccClientText(30915) or ccClientText(30908))
	self:SetWndButtonText(self.mBtnGet,getStr)

	local isCurHasData = #list > 0
	local isYesGet = false
	local isGray = true
	local emptyList = #dropRecord < 1
	if not emptyList then
		--- 旧逻辑是抽完也要次日才能领取
		--isYesGet = not _isGet and (lotteryNum >= _maxCallNum or _curOpenRound > _round or self._openDay > _round)

		--- 所有次数都用尽了就可以领取
		if _curOpenRound > _round then
			if isCurHasData then
				isYesGet = true
			end
		elseif _curOpenRound == _round and isCurHasData then
			if lotteryNum >= maxCallCnt then
				isYesGet = true
			end
		else
			isYesGet = not _isGet and lotteryNum >= maxCallCnt and (_curOpenRound >= _round or self._openDay > _round)
		end
		if not _isGet then
			isGray = not isYesGet and not currData
		end
	end
	self:SetWndButtonGray(self.mBtnGet,isGray)

	local showRp = false
	if isCurHasData and not _isGet then

		showRp = isYesGet and not currData
	end
	CS.ShowObject(self.mRedPoint,showRp)
	CS.ShowObject(self.mGetEff,showRp)

	if showRp then
		self:CreateWndEffect(self.mGetEff,"fx_anniu_03","fx_anniu_03_UILotteryRltsSelect_",100)
	end
	self._isYesGet = isYesGet
	self._isGet = _isGet
	local desStr = ccClientText(30920)
	if currData then
		self._currData = currData
		desStr = ccClientText(30919)
	elseif isYesGet then
		desStr = ccClientText(30907)
	end
	self:SetWndText(self.mDesText,desStr)

	local selIdx = nil
	local maxIndex = 1
	local maxCreateTime = 0
	for i = 1, alternativeHeroNum do
		local data = list[i]
		if data then
			local createTime = data.createTime
			if createTime > maxCreateTime then
				maxCreateTime = createTime
				maxIndex = i
			end

			table.insert(dataList,data)
			if _isGet then
				if data.receive == 1 then
					selIdx = data.index
				end
			end
		else
			table.insert(dataList,{type = 1})
		end
	end

	self._newIndex = maxIndex

	local uiList = self._cellUiList
	if uiList then
		uiList:RefreshList(dataList)
		uiList:DrawAllItems()
	else
		uiList = self:GetUIScroll("mRewardList_UILotteryRltsSelect")
		self._cellUiList = uiList
		uiList:Create(self.mCellSuper,dataList,function (...) self:ListItem(...) end,UIItemList.SUPER)
		uiList:EnableScroll(false,false)
	end
	if #dataList > 0 and not self._isOne then
		self._isOne = true

		selIdx = selIdx or dataList[1].index
		self:OnClickCell(selIdx)
	end
end

function UILotteryRltsSelect:OnDrawRecord(list,item,itemdata,itempos)

	local Root = self:FindWndTrans(item,"Root")
	--local RootImage = self:FindWndTrans(Root,"Image")
	--local RootImage1 = self:FindWndTrans(Root,"Image1")
	--local Image1Image1 = self:FindWndTrans(RootImage1,"Image1")
	local RootTitleText = self:FindWndTrans(Root,"TextTitle")
	local RootGetTag = self:FindWndTrans(Root,"getTag")
	local RootSelImg = self:FindWndTrans(Root,"SelImg")
	local RootRewardList = self:FindWndTrans(Root,"RewardList")
	--local RewardListImageBg = self:FindWndTrans(RootRewardList,"ImageBg")
	local RootTheGasBg = self:FindWndTrans(Root,"TheGasBg")
	local TheGasBgTheGasText = self:FindWndTrans(RootTheGasBg,"TheGasText")
	local TheGasBgTheGasValueText = self:FindWndTrans(RootTheGasBg,"TheGasValueText")
	local TheGasBgBtnShare = self:FindWndTrans(RootTheGasBg,"BtnShare")
	local RootNoRecord3 = self:FindWndTrans(Root,"NoRecord3")
	--local NoRecord3EmptyIcon = self:FindWndTrans(RootNoRecord3,"EmptyIcon")
	--local NoRecord3EmptyTextBg = self:FindWndTrans(RootNoRecord3,"EmptyTextBg")
	local NoRecord3EmptyText = self:FindWndTrans(RootNoRecord3,"EmptyText")


	--local root = self:FindWndTrans(item,"Root")
	--local titleText = self:FindWndTrans(root,"TextTitle")
	--local rewardList = self:FindWndTrans(root,"RewardList")
	--local selImg = self:FindWndTrans(root,"SelImg")
	--local theGasBg = self:FindWndTrans(root,"TheGasBg")
	--local theGasText = self:FindWndTrans(root,"TheGasBg/TheGasText")
	--local theGasValueText = self:FindWndTrans(root,"TheGasBg/TheGasValueText")
	--local btnShare = self:FindWndTrans(root,"TheGasBg/BtnShare")
	--local noRecord3 = self:FindWndTrans(root,"NoRecord3")
	--local emptyText = self:FindWndTrans(root,"NoRecord3/EmptyText")

	local instanceID = item:GetInstanceID()

	local type = itemdata.type

	printInfoN("type "..type)

	local curPos = self._curPos or 1

	local isSel = curPos == itempos
	self:SetTextTile(RootTitleText,string.replace(ccClientText(30906),itempos))
	CS.ShowObject(RootSelImg,isSel)

	CS.ShowObject(RootNoRecord3,type == 1)
	CS.ShowObject(RootTheGasBg ,type == 2)
	CS.ShowObject(RootRewardList,type == 2)
	self:SetWndClick(Root,function ()
		if type == 2 then
			self:OnClickCellTwo(itempos)
		end
	end)
	self:SetWndClick(RootTheGasBg,function ()
		if type == 2 then
			self:OnClickShareTwo(TheGasBgBtnShare,itemdata)
		end
	end)
	if type == 1 then
		self:SetWndText(NoRecord3EmptyText,ccClientText(30917))
		return
	end

	local isGet = itemdata.data.index == self._recIndex
	CS.ShowObject(RootGetTag,isGet)
	local rankValue = itemdata.data.rankValue

	self:SetWndText(TheGasBgTheGasText,ccClientText(30913))
	self:SetWndText(TheGasBgTheGasValueText,rankValue)

	local dataList =LxDataHelper.ParseItem(itemdata.data.reward)
	local list = self:CreateUIScrollImpl(instanceID,RootRewardList,dataList,function (...)
		self:OnDrawReward(...)
	end)

	list:EnableScroll(false,false)
end

function UILotteryRltsSelect:OnMaxLotteryNumList()
	local callNums = self._callNums
	if not callNums then return end

	local _pages = self._pages
	if not _pages then return end

	local taskPage = _pages[1]
	if not taskPage then return end
	local maxLotteryNumList = {}
	for i, v in ipairs(taskPage.entry) do
		local entryId = v.entryId
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		local roundIndex = entryCfg.moreInfo
		if not maxLotteryNumList[roundIndex] then
			maxLotteryNumList[roundIndex] = 0
		end

		local callNum = callNums[entryId]
		local newNum = maxLotteryNumList[roundIndex] + callNum
		maxLotteryNumList[roundIndex] = newNum
	end

	self._maxLotteryNumList = maxLotteryNumList
end
function UILotteryRltsSelect:OnClickGet()
	local isGet = self._isGet
	local _isYesGet = self._isYesGet
	local currData = self._currData
	local data = self._config
	local _reconfirm = self._reconfirm
	if isGet then
		GF.ShowMessage(ccClientText(30918))
		return
	end
	if currData then
		local tipsWinId = _reconfirm[1] or 470401
		gModelGeneral:OpenUIOrdinTips({refId = tipsWinId,func = function ()
			local params = string.format("%s,%s,%s",self._round,currData.index,self._index)
			gModelActivity:OnActivityDropSelectReq(2, self._sid, self._pageId, params)
		end})
		return
	end
	if not _isYesGet then
		GF.ShowMessage(data.errorCodeThree)
		return
	end
	local tipsWinId = _reconfirm[2] or 470402
	gModelGeneral:OpenUIOrdinTips({refId = tipsWinId,func = function ()
		local params = string.format("%s,%s",self._round,self._index)
		gModelActivity:OnActivityDropSelectReq(3, self._sid, self._pageId, params)
	end})
end

function UILotteryRltsSelect:SetStatic()
	self:SetWndText(self.mLblBiaoti,ccClientText(30909))
	self:SetWndText(self.mDesText,ccClientText(30907))
	self:SetWndButtonText(self.mBtnLook,ccClientText(30914))
	CS.ShowObject(self.mBtnGet,true)
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)

end

function UILotteryRltsSelect:InitDataTwo()
	local itemdata = self:GetWndArg("itemdata")
	local refId = itemdata.refId
	local id = itemdata.id

	self._refId = refId
	self._id = id
	itemdata = gModelItem:FormatItemUniqueData(refId,id)

	self._itemdata = itemdata
end

function UILotteryRltsSelect:RewardListItem(list, item, itemdata, itempos)
	local Root = item
	local RootItem = self:FindWndTrans(Root,"CommonUI")
	local itemIcon = self:FindWndTrans(RootItem,"Icon")
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
		baseClass:Create(itemIcon)
	end
	baseClass:SetCommonReward(itemType, itemId, itemNum)
	baseClass:DoApply()


	self:SetWndClick(item,function()
		if itemType == LItemTypeConst.TYPE_HERO then
			gModelGeneral:OpenHeroSimpleTip(itemId,true)
		else
			gModelGeneral:ShowCommonItemTipWnd(reward)
		end
	end)

	if gLGameLanguage:IsJapanRegion() then
		local heroId = itemId
		local eff
		local effScaleSize = 90
		--if gModelHero:CheckIsShowHeroQualityForeign() then
		--else
		--end
		local heroRef  = gModelHero:GetHeroRef(heroId)
		if heroRef then
			local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
			if qualityRef then
				local heroCallFxList = string.split(qualityRef.heroCallFx, '=')
				eff = heroCallFxList[1]
				local fxEffSize = heroCallFxList[2]
				if not string.isempty(fxEffSize) then
					effScaleSize = tonumber(fxEffSize) * 90
				end
			end
		end
		if not eff then
			local initStar = gModelHero:GetHeroInitStarByRefId(heroId)
			if initStar >= 5 then
				eff = self._heroEffectList[initStar]
			end
		end

		self:DestroyWndEffectByKey(instanceID)
		if eff then
			self:CreateWndEffect(RootEffectRoot,eff,instanceID,effScaleSize,false,false)
		end
	end
end

function UILotteryRltsSelect:InitCommand()
	self._heroEffectList = {
		[4] = "fx_ui_ZHJS_yingxiong_zise",
		[5] = "fx_ui_ZHJS_yingxiong_chengse",
	}
	--self:SetWndText(self.mLblBiaoti,ccClientText(30909))
	--self:SetWndText(self.mDesText,ccClientText(30907))
	--self:SetWndButtonText(self.mBtnLook,ccClientText(30914))
	--CS.ShowObject(self.mBtnGet,true)

	local sid = self:GetWndArg("sid")
	local pageId = self:GetWndArg("pageId")
	local round = self:GetWndArg("round")
	local pages = self:GetWndArg("pages")

	self._sid = sid
	self._pageId = pageId
	self._round = round
	self._pages = pages

	self:OnActivityConfigData()
end

function UILotteryRltsSelect:ResetDataTwo()
	local refId = self._refId
	local id = self._id

	local itemdata = gModelItem:FormatItemUniqueData(refId,id)
	if not itemdata then

		self:WndClose()

		return
	end

	--printInfoN("reset data")
	self._itemdata = itemdata
end


function UILotteryRltsSelect:OnDrawReward(list,item,itemdata,itempos)
	local Root = self:FindWndTrans(item,"Root")
	local RootItem = self:FindWndTrans(Root,"CommonUI")
	local itemIcon = self:FindWndTrans(RootItem,"Icon")
	local RootEffectRoot = self:FindWndTrans(Root,"EffectRoot")

	self:CreateCommonIconImpl(itemIcon,itemdata)
end

------------------------------------------------------------------
return UILotteryRltsSelect


