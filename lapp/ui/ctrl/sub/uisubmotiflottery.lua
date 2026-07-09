---
--- Created by BY.
--- DateTime: 2023/10/19 10:11:40
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubMotifLottery:LChildWnd
local UISubMotifLottery = LxWndClass("UISubMotifLottery", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubMotifLottery:UISubMotifLottery()
	self._timeKey = "UISubExtractAwardTimeKey"								--轮换TimeKey
	self._timeOpenRwardKey = "UISubTurntableOpenRwardTimeKey"				--转盘延迟奖励界面TimeKey
	self._playItemTweenKey = "UISubExtractAwardTweenKey"					--轮换TweenKey
	self._timeTurnRwardKey = "UISubTurntable_TurnRwardKey"					--转盘延迟奖励界面TimeKe
	self._rurnTime_Common = 0.6			--平常转时间
	self._rurnTime_Stage1 = 0.2			--抽奖阶段1时间
	self._rurnTime_Stage2 = 0.3			--抽奖阶段2时间
	self._openTime = 0.3				--打开奖励弹窗时间
	self._rurnNum = 2					--要转的圈数
	self._rurnStage2Nums = 3			--阶段2要转的次数

	self._itemMovePos = {
		showPos = Vector3.New(0,-1,0),
		leftHidePos = Vector3.New(-93,-1,0),
		rightHidePos = Vector3.New(97,-1,0),
	}

	self._iconTransPath = "iconTrans"
	self._itemNumTransPath = "itemNum"
	self._tweenItemTime = 0.5													--轮换移动时间
	self._gridBgImgEmptyPath = "activity_candy_icon_1"	--空格子
	self._timeRankKey = "_timeRankKey"								--排行榜倒计时
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubMotifLottery:OnWndClose()
	self:TimerStop(self._timeKey)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubMotifLottery:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubMotifLottery:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitDate()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISubMotifLottery:InitCommand()
	local sid = self:GetWndArg("sid")
	self._sid = sid
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	if not modelId then return end
	local enums = self._modelEnumList[modelId]
	self._modelId = modelId
	self._turnTableEnum = enums[1]
	self._turnPoolEnum = enums[2]
	self._roomTaskEnum = enums[3]
	local pageids = self._modelPageIdList[modelId]
	self._turnShopEnum = pageids[1]
	--是否跳过抽奖动画，直接显示奖励
	self._isJumpTurnAnim = toboolean(LPlayerPrefs.bandThemeJumpTurnTable)
	self:SetWndToggleValue(self.mShowToggle, self._isJumpTurnAnim)
	self:OnActivityConfigData()
end

function UISubMotifLottery:GetRankList()
	local list = {}
	local rankList = self:GetRankServerDataList()
	local showRankNum = 3
	local insNum = 0
	local rank
	for k,v in ipairs(rankList) do
		rank = v.rank
		if rank <= showRankNum then
			insNum = insNum + 1
			table.insert(list,{
				name = v.info._name,
				rank = rank,
				score = v.score,
				playerId = v.info._playerId,
			})
		end
	end
	if insNum < showRankNum then
		for i = insNum + 1,showRankNum do
			table.insert(list,{
				name = ccClientText(25203),
				rank = i,
				score = 0,
				playerId = "-1",
			})
		end
	end
	return list
end
function UISubMotifLottery:TurnRwardBg()
	local _itemEffectTransList = self._itemEffectTransList
	if not _itemEffectTransList then return end
	local list = self._currLayerList or {}
	if #list <= 0 then
		local _gradation = self._gradation
		for i, v in pairs(_itemEffectTransList) do
			local layer = v.layer
			if layer == _gradation then
				table.insert(list,v)
			end
		end
		table.sort(list,function (a,b)
			return a.entryId < b.entryId
		end)
		self._currLayerList = list
	end
	local trunIndex = self._trunIdex or 1
	if self._oldData then
		CS.ShowObject(self._oldData.iconBg2,false)
	end
	trunIndex = trunIndex + 1
	if trunIndex > #list then
		trunIndex = 1
	end
	local data = list[trunIndex]
	if not data then return end
	CS.ShowObject(data.iconBg2,true)
	self._oldData = data
	self._trunIdex = trunIndex

	local _cnt = self._cnt
	if _cnt then
		_cnt = _cnt - 1
		if _cnt > 0 then
			self._cnt = _cnt
			return
		end
		local _timeTurnRwardKey = self._timeTurnRwardKey
		local _rurnStage2Num = self._rurnStage2Nums
		self:TimerStop(_timeTurnRwardKey)
		self:TimerStart(_timeTurnRwardKey,self._rurnTime_Stage2,false,_rurnStage2Num)
		self._cnt = nil
		self._rurnStage2Num = _rurnStage2Num
		return
	end
	local _rurnStage2Num = self._rurnStage2Num
	if not _rurnStage2Num then return end
	_rurnStage2Num = _rurnStage2Num - 1
	if _rurnStage2Num > 0 then
		self._rurnStage2Num = _rurnStage2Num
		return
	end
	--print("--------------------"..trunIndex)
	self._rurnStage2Num = nil
	--延迟self._openTime秒后弹奖励
	local _timeOpenRwardKey = self._timeOpenRwardKey
	self:TimerStop(_timeOpenRwardKey)
	self:TimerStart(_timeOpenRwardKey,self._openTime,false,1)
	self._oldIconBg2 = data.iconBg2
end
--设置固定格子数据
function UISubMotifLottery:SetGridItemData(entryId)
	local transData = self._itemEffectTransList[entryId]
	local _poolList = self._poolList or {}
	local poolDatas = _poolList[entryId]
	if not transData or not poolDatas then return end

	local iconTransPath = self._iconTransPath
	local itemNumTransPath = self._itemNumTransPath
	local len = #poolDatas
	local _itemShowTransList = self._itemShowTransList or {}
	local itemShowTransData = _itemShowTransList[entryId]
	if not itemShowTransData then
		itemShowTransData = {
			index = 1,
			len = len,
			dataIndex = 1,
		}
		_itemShowTransList[entryId] = itemShowTransData
	end
	self._itemShowTransList = _itemShowTransList

	local dataIndex = itemShowTransData.dataIndex
	local nexDataIndex = dataIndex + 1
	local index = itemShowTransData.index
	local nexIndex = index + 1
	if nexDataIndex > len then nexDataIndex = 1 end
	if nexIndex > 2 then nexIndex = 1 end
	local randomData = poolDatas[dataIndex]
	local itemData = LxDataHelper.ParseItem_4(randomData.entryCfg.reward)
	if not itemData then return end
	local nexData = poolDatas[nexDataIndex]
	local nextItemData = LxDataHelper.ParseItem_4(nexData.entryCfg.reward)

	local iconTrans1 = transData[iconTransPath..index]
	local itemNum1   = transData[itemNumTransPath..index]
	local iconTrans2 = transData[iconTransPath..nexIndex]
	local itemNum2   = transData[itemNumTransPath..nexIndex]
	local iconRootTrans = transData.iconRootTrans
	local shiftIconTrans = transData.shiftIconTrans
	local itemNumStr1 = LUtil.NumberCoversion(itemData.itemNum) or ""
	local itemImgPath = gModelGeneral:GetCommonItemImgRef(itemData)
	self:SetWndText(itemNum1, itemNumStr1)
	if LxUiHelper.IsImgPathValid(itemImgPath) then
		self:SetWndEasyImage(iconTrans1, itemImgPath)
	end
	CS.ShowObject(iconTrans1, true)
	if nextItemData then
		local itemNumStr2 = LUtil.NumberCoversion(nextItemData.itemNum) or ""
		local nextItemImgPath = gModelGeneral:GetCommonItemImgRef(nextItemData)
		if LxUiHelper.IsImgPathValid(nextItemImgPath) then
			self:SetWndEasyImage(iconTrans2, nextItemImgPath)
		end
		self:SetWndText(itemNum2, itemNumStr2)
		CS.ShowObject(iconTrans2, true)
	end
	CS.ShowObject(shiftIconTrans, false)
	self:SetWndClick(iconRootTrans, function()
		self:OnClickPrizeSlot(entryId)
	end)
end

function UISubMotifLottery:GetRankServerDataList()
	return gModelRank:GetRankListInfo(2, self._rankId)
end
function UISubMotifLottery:OnClickOpenSelect(entryId)
	GF.OpenWnd("UIActPrizeSlotSelectPop",{sid = self._sid, entryId = entryId,pages = self._pages})
end
function UISubMotifLottery:RefreshRed()
	local _sid = self._sid
	local taskRed = gModelRedPoint:GetActivityRedPointPage(_sid,self._roomTaskEnum)
	CS.ShowObject(self.mTaskRedPoint,taskRed)
	local red = gModelRedPoint:GetActivityRedPointPage(_sid,self._turnShopEnum)
	CS.ShowObject(self.mShopRed,red)
end
--------------------------------------------格子道具------------------------------------------------

--------------------------------------------Tween动画-----------------------------------------------
function UISubMotifLottery:PlayItemTween()
	local _itemMovePos = self._itemMovePos		--Item轮换坐标
	local iconTransPath = self._iconTransPath
	local moveTime      = self._tweenItemTime
	local seqKey = self._playItemTweenKey

	local _itemShowTransList = self._itemShowTransList
	if not _itemShowTransList then return end

	local curIconIndex
	local _itemShowTransList = _itemShowTransList
	for i, v in pairs(_itemShowTransList) do
		curIconIndex = v.index
		break
	end
	local nexIconIndex = curIconIndex + 1
	if nexIconIndex > 2 then
		nexIconIndex = 1
	end

	self:TweenSeqKill(seqKey)
	local seqTween = self:TweenSeqCreate(seqKey, function(seq)
		for k,v in pairs(_itemShowTransList) do
			local transData  = self._itemEffectTransList[k]

			local iconTrans1 = transData[iconTransPath..curIconIndex]
			local move1 = iconTrans1:DOLocalMove(_itemMovePos.leftHidePos, moveTime)
			seq:Join(move1)

			local iconTrans2 = transData[iconTransPath..nexIconIndex]
			iconTrans2.localPosition = _itemMovePos.rightHidePos
			local move2 = iconTrans2:DOLocalMove(_itemMovePos.showPos, moveTime)
			seq:Join(move2)
		end
		return seq
	end)

	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)
		self:RefreshShowList()
	end)
	seqTween:PlayForward()
end
function UISubMotifLottery:LayerListItem(item, itemdata, itempos)
	local layer = itemdata.layer
	local layerList = self._layerList or {}
	local list = layerList[layer]
	for i, v in ipairs(list) do
		local cell = self:FindWndTrans(item,"Item"..i)
		self:CellListItem(cell,v,i)
	end
end
--------------------------------------------点击事件------------------------------------------------

--------------------------------------------延时处理------------------------------------------------
function UISubMotifLottery:OnTimer(key)
	if(key == self._timeKey)then
		self:PlayItemTween()
	elseif key == self._timeOpenRwardKey then
		self:OpenUIAward()
		local _timeTurnRwardKey = self._timeTurnRwardKey
		self:TimerStop(_timeTurnRwardKey)
		self:TimerStart(_timeTurnRwardKey,self._rurnTime_Common,false,-1)
	elseif key == self._timeTurnRwardKey then
		self:TurnRwardBg()
	elseif key == self._timeRankKey then
		self:OnRankTimeText()
	end
end

function UISubMotifLottery:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config

	local skipTxt,shopId,callBg,costOne1,costOne2,goodsOne,lotteryImage,lotteryImagePos,boxIcon,boxIconPos
	= data.skipTxt,data.shopId,data.callBg,data.costOne1,data.costOne2,data.goodsOne,data.lotteryImage,data.lotteryImagePos,data.boxIcon,data.boxIconPos
	self._helpTitle,self._helpTxt = data.wishCallHelpTitle,data.wishCallHelpTxt
	self._turnTipImg,self._turnTipPos = data.turnTipImg,data.turnTipPos
	self._logTitle,self._logTips,self._logTimeTips = data.logTitle,data.logTips,data.logTimeTips
	self._policyTitle,self._policyTxt = data.weightShowTitle,data.policyTxt
	self._costOne1,self._costOne2,self._goodsOne = LxDataHelper.ParseItem_3(costOne1),LxDataHelper.ParseItem_3(costOne2),LxDataHelper.ParseItem_3(goodsOne)
	self._tipRefId = data.tipRefId or 110008
	self._tipRefId2 = data.tipRefId2 or self._tipRefId
	self._turntableTime = data.turntableTime or 3

	-----------------------------------
	local unselectIcon = string.split(data.unselectIcon,"=")
	self._unselectIcon = unselectIcon and unselectIcon[1] or ""
	self._unselectIconScale = unselectIcon and tonumber(unselectIcon[2]) or 1

	local selectIcon = string.split(data.selectIcon,"=")
	self._selectIconIcon = selectIcon and selectIcon[1] or ""
	self._selectIconScale = selectIcon and tonumber(selectIcon[2]) or 1

	local grandSelectIcon = string.split(data.grandSelectIcon,"=")
	self._grandSelectIcon = grandSelectIcon and grandSelectIcon[1] or ""
	self._grandSelectIconScale = grandSelectIcon and tonumber(grandSelectIcon[2]) or 1

	local grandUnselectIcon = string.split(data.grandUnselectIcon,"=")
	self._grandUnselectIcon = grandUnselectIcon and grandUnselectIcon[1] or ""
	self._grandUnselectIconScale = grandUnselectIcon and tonumber(grandUnselectIcon[2]) or 1
	-------------------------------------
	local wishCallHelpPos = data.wishCallHelpPos
	local arrowFlip = data.arrowFlip
	local rankClear = data.rankClear
	if not string.isempty(arrowFlip)then
		self._arrowFlip = arrowFlip
	end
	if not string.isempty(rankClear)then
		self._rankClear = rankClear == 1
		self.mRankGroup.sizeDelta = Vector2.New(232,175)
		self:RefreshRankTime()
	end
	if LxUiHelper.IsImgPathValid(callBg) then
		self:SetWndEasyImage(self.mBg,callBg,function ()
			CS.ShowObject(self.mBg,true)
		end)
	end
	self:SetWndText(self.mToggleText,skipTxt or ccClientText(23211))

	if LxUiHelper.IsImgPathValid(lotteryImage) then
		local parnt = self.mBgImage
		self:SetWndEasyImage(parnt,lotteryImage,function ()
			CS.ShowObject(parnt,true)
		end ,true)
		if not string.isempty(lotteryImagePos)then
			local pos = LxDataHelper.ParseVector2NotEmpty2(lotteryImagePos)
			self:SetAnchorPos(parnt, pos)
		end
	end
	if LxUiHelper.IsImgPathValid(boxIcon) then
		local parnt = self.mTaskBox
		self:SetWndEasyImage(parnt,boxIcon,function ()
			CS.ShowObject(parnt,true)
		end ,true)

		if not string.isempty(boxIconPos)then
			local pos = LxDataHelper.ParseVector2NotEmpty2(boxIconPos)
			self:SetAnchorPos(parnt, pos)
		end
	end
	if not string.isempty(wishCallHelpPos)then
		local pos = LxDataHelper.ParseVector2NotEmpty2(wishCallHelpPos)
		self:SetAnchorPos(self.mBtnHelp, pos)
	end
	local isShowShop = not string.isempty(shopId) and shopId > 0
	CS.ShowObject(self.mBtnShop,isShowShop)
	local enums = self._modelEnumList[self._modelId]
	gModelActivity:OnActivityPageReq(self._sid,enums)

	self._rankId = self:GetRankId(activityData)
	if(self._rankId)then
		self._rankScoreImgList = {
			[1] = "public_num_1",
			[2] = "public_num_2",
			[3] = "public_num_3",
		}
		self:SetWndText(self.mDetailsRankTxt,ccClientText(14111))
	end
	local showRank = data.isShowRank and data.isShowRank == 1
	CS.ShowObject(self.mRankGroup,showRank == true and self._rankId)
end
function UISubMotifLottery:GetRankId(activityData)
	local modelId = gModelActivity:GetActivityModeIdBySid(self._sid )
	if(modelId == ModelActivity.MODEL_ACTIVITY_TYPE_96)then
		local chuck = activityData.chunk
		local rankCfg
		for i, v in ipairs(chuck) do
			if(v.id == ModelActivity.MOTIF_ACTIVITY_LOTTERY_7)then
				rankCfg = v
				break
			end
		end
		if(rankCfg)then
			local entryData = rankCfg.entries[1]
			local condition = entryData.condition
			local conditionArr = string.split(condition,",")
			local eventArr = string.split(conditionArr[1],"=")
			local id = tonumber(eventArr[3])
			return id
		end
	end
end
--刷新格子显示
function UISubMotifLottery:RefreshTurnTableGrid(_itemEffectTrans)
	local entry = _itemEffectTrans.entry
	local entryId = _itemEffectTrans.entryId

	local isCustomGrid = _itemEffectTrans.selectId > 0
	if isCustomGrid then
		local selectEntryId
		local entryMoreInfo = JSON.decode(entry.moreInfo)
		for a,b in pairs(entryMoreInfo) do
			selectEntryId = tonumber(b)
			break
		end
		self:SetCustomGridItemData(_itemEffectTrans,selectEntryId,entryId)
	elseif not self._isExecute then
		self:SetGridItemData(entryId)
	end
end
function UISubMotifLottery:OnClickTaskBox()
	GF.OpenWnd("UIActLotteryTkPop",{sid = self._sid,pages = self._pages})
end
function UISubMotifLottery:OnClickShop()
	local _sid = self._sid
	GF.OpenWndBottom("UIDian",{page = ModelShop.ACTIVITY,subPage = _sid})
	local _turnShopEnum = self._turnShopEnum
	if not _turnShopEnum then return end
	local bool = gModelRedPoint:GetActivityRedPointPage(_sid,_turnShopEnum)
	if bool then
		gModelActivity:OnActivitySpecialOpReq(_sid,_turnShopEnum,nil,ModelActivity.CANCEL_RED_POINT, "1")
	end
end
function UISubMotifLottery:InitEvent()
	self:SetWndClick(self.mBtnOne,function (...)self:OnClickOneTen(1) end)
	self:SetWndClick(self.mBtnTen,function (...)self:OnClickOneTen(2) end)
	self:SetWndClick(self.mBtnHelp,function (...)self:OnClickHelp() end)
	self:SetWndClick(self.mBtnLog,function (...)self:OnClickLog() end)
	self:SetWndClick(self.mBtnShop, function() self:OnClickShop() end)
	self:SetWndClick(self.mBtnDetails,function () self:OnClickDetails() end)
	self:SetWndClick(self.mTaskBox,function ()self:OnClickTaskBox() end)
	self:SetWndToggleDelegate(self.mShowToggle,function (value)
		LPlayerPrefs.SetBandThemeJumpTurnTable(tostring(value))
		self._isJumpTurnAnim = value
	end)

	self:SetWndClick(self.mRankClickArea,function ()self:OpenRankWnd() end)
end
function UISubMotifLottery:ListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local itemBg = self:FindWndTrans(root,"ItemBg")
	local itemIcon = self:FindWndTrans(itemBg,"ItemIcon")
	local itemText = self:FindWndTrans(itemBg,"ItemText")

	local itemId = itemdata.itemId
	local icon,iconBg = gModelItem:GetItemImgByRefId(itemId)
	local itemNum = gModelItem:GetNumByRefId(itemId)

	self:SetWndEasyImage(itemIcon,icon)
	self:SetWndText(itemText,LUtil.NumberCoversion(itemNum))

	self:SetWndClick(root,function ()
		self:OnClickItemIcon(itemId)
	end)
end
function UISubMotifLottery:OnClickDetails()
	local _policyTitle,_policyTxt,_helpTitle,_helpTxt,_turnTipImg,_turnTipPos
	= self._policyTitle,self._policyTxt,self._helpTitle,self._helpTxt,self._turnTipImg,self._turnTipPos
	_policyTxt = string.gsub(_policyTxt,"\\n","\n")
	_helpTxt = string.gsub(_helpTxt,"\\n","\n")

	local _layerList = self._layerList or {}
	local _poolList = self._poolList or {}

	local list = {}
	for i, v in pairs(_layerList) do
		local layer = i
		for k, j in ipairs(v) do
			local moreInfo = string.split(j.entryCfg.moreInfo,"|")
			local entryId = j.entryId
			local pools = _poolList[entryId]
			local poolList = {}
			for a, b in ipairs(pools) do
				local moreInfo = string.split(b.entryCfg.moreInfo,"|")
				local reward = LxDataHelper.ParseItem_3(b.entryCfg.reward)
				table.insert(poolList,{
					reward = reward,
					prob = moreInfo[4] and moreInfo[4] .. "%" or "",
				})
			end
			local data = {
				layer = layer,
				index = k,
				prob = moreInfo[5] and moreInfo[5] .. "%" or "",
				poolList = poolList,
			}
			table.insert(list,data)
		end
	end

	local argList = {
		policyTitle = _policyTitle,
		policyTxt = _policyTxt,
		helpTitle = _helpTitle,
		helpTxt = _helpTxt,
		turnTipImg = _turnTipImg,
		turnTipPos = _turnTipPos,
		list = list,
	}
	GF.OpenWnd("UIActPrizeSlotProbabilityPop",argList)
end
function UISubMotifLottery:CheckIsAllSelect()
	local itemList = self._itemEffectTransList
	for k,v in pairs(itemList) do
		local isCustomGrid = v.selectId > 0
		if isCustomGrid then
			local selectEntryId
			local entryMoreInfo = JSON.decode(v.entry.moreInfo)
			for a,b in pairs(entryMoreInfo) do
				selectEntryId = tonumber(b)
				break
			end
			if selectEntryId == nil then
				return v.entry.entryId
			end
		end
	end
	return 0
end
--------------------------------------------兑换道具------------------------------------------------

--------------------------------------------点击事件------------------------------------------------
function UISubMotifLottery:OnClickItemIcon(itemId)
	local wndName = self:GetParentWndName() -- self._modelMagList[self._modelId]
	gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = wndName})
end
function UISubMotifLottery:GetCurItem(entry)
	local curLv = nil
	for i, v in ipairs(entry) do
		local goalData = v.goalData
		local status = goalData.status
		if status ~= 2 then
			curLv = v
			break
		end
	end
	if not curLv then
		curLv = entry[#entry]
	end
	return curLv
end

function UISubMotifLottery:RefreshBtnText()
	local sid = self._sid
	if not sid then return end
	local activityDataW = gModelActivity:GetWebActivityDataById(sid)
	local dataW = activityDataW.config
	local costOne1,costOne2,costTen1,costTen2 = dataW.costOne1,dataW.costOne2,dataW.costTen1,dataW.costTen2

	local _costOne1 = LxDataHelper.ParseItem_3(costOne1)
	local _costOne2 = LxDataHelper.ParseItem_3(costOne2)
	local _costTen1 = LxDataHelper.ParseItem_3(costTen1)
	local _costTen2 = LxDataHelper.ParseItem_3(costTen2)
	local bagItemNum = gModelItem:GetNumByRefId(_costOne2.itemId)
	local freeNum = self._freeNum
	CS.ShowObject(self.mOneCostText,freeNum < 1)
	if freeNum < 1 then
		local isItemCost = bagItemNum >= 1
		local oneCostStr = isItemCost and _costOne2.itemNum or _costOne1.itemNum
		local oneCostRefId = isItemCost and _costOne2.itemId or _costOne1.itemId
		local icon,iconBg = gModelItem:GetItemImgByRefId(oneCostRefId)
		self:SetWndText(self.mOneCostText,oneCostStr)
		self:SetWndEasyImage(self.mOneCostIcon,icon)
	end
	CS.ShowObject(self.mTenCostText,false)
end
function UISubMotifLottery:RefreshData()
	local sid = self._sid
	if not sid then return end
	local activityDataS = gModelActivity:GetActivityBySid(sid)
	local activityDataW = gModelActivity:GetWebActivityDataById(sid)
	if not activityDataS or not activityDataW then return end
	--------------------------------------后端数据------------------------------------------------
	local dataS = JSON.decode(activityDataS.moreInfo)
	local freeNum = dataS.freeNum or 0				--免费次数
	local callNum = dataS.remainBuyNum or 0			--剩余钻石购买次数
	local dropNumToday = dataS.usedBuyNum or 0		--今天总掉落次数
	local gradation = dataS.gradation or 1			--当前所处层
	local awardKey = string.format("%s-%s-%s",sid,self._turnTableEnum,5)
	local sid_pageId_type = dataS[awardKey]			--转盘最后一次转到的条目
	self._sid_pageId_type = sid_pageId_type
	self._freeNum = freeNum
	self._gradation = gradation
	----------------------------------------------------------------------------------------------
	--------------------------------------配置数据------------------------------------------------
	local dataW = activityDataW.config
	local callBtnTxt = dataW.callBtnTxt
	local callLimitTips = dataW.callLimitTips or ccClientText(23224)
	local callMaxNum = dataW.callMaxNum
	local diaCallLimitTips = dataW.diaCallLimitTips or ccClientText(23226)
	self._showItem = dataW.callCurrencyBar
	----------------------------------------------------------------------------------------------
	if not string.isempty(callBtnTxt) then
		local _callBtnTxt = string.split(callBtnTxt,"=")
		local btnOneStr = freeNum > 0 and _callBtnTxt[1] or _callBtnTxt[2]
		self:SetWndButtonText(self.mBtnOne,btnOneStr)
		self:SetWndButtonText(self.mBtnTen,_callBtnTxt[3])
	end
	if not string.isempty(callLimitTips) then
		CS.ShowObject(self.mCallNumBg,true)
		local str = LUtil.FormatColorStr(dropNumToday,dropNumToday >= callMaxNum and "lightRed" or "lightGreen")
		self:SetWndText(self.mCallNumText,string.replace(callLimitTips,str,callMaxNum))
	end
	if not string.isempty(diaCallLimitTips) then
		CS.ShowObject(self.mTipsBg,true)
		local str = LUtil.FormatColorStr(callNum,callNum <= 0 and "lightRed" or "lightGreen")
		self:SetWndText(self.mTipsText,string.replace(diaCallLimitTips,str))
	end
	self:RefreshItem()
	self:RefreshBtnText()
	self:RefreshGridItem()
	self:RefreshTaskBox()
	self:RefreshRankRewardList()
	self:RefreshRed()
end
function UISubMotifLottery:OnClickOneTen(type)
	local sid = self._sid
	local nilEntryId = self:CheckIsAllSelect()
	if nilEntryId > 0 then
		GF.ShowMessage(ccClientText(23228))
		local effTr = self._itemEffectTransList[nilEntryId]
		if effTr then
			CS.ShowObject(effTr.effectTrans,true)
			self:CreateWndEffect(effTr.effectTrans,"fx_ui_shou_2","nilEntryId",100)
		end
		return
	end
	if self._isWndCall then
		return
	end
	local _lotteryEnum = self._modelLotteryList[self._modelId]
	gModelActivity:SendActivityCallReq2(sid,self._turnTableEnum,type,self:GetParentWndName(),_lotteryEnum,function ()
		self._isWndCall = true
	end)
end
function UISubMotifLottery:OnRankTimeText()
	local _rankTimeValue = self._rankTimeValue
	if not _rankTimeValue then return end

	local time = _rankTimeValue - GetTimestamp()
	if time <= 0 then
		self:TimerStop(self._timeRankKey)
		self:SetWndText(self.mRankTimeTxt, ccClientText(23253))
		return
	end
	local timeStr = LUtil.FormatTimespanCn(time)
	timeStr = string.replace(ccClientText(23252), timeStr)
	self:SetWndText(self.mRankTimeTxt, timeStr)
end
function UISubMotifLottery:OnClickPrizeSlot(entryId)
	local _poolList = self._poolList or {}
	local poolDatas = _poolList[entryId] or {}
	if #poolDatas <= 0 then return end
	local list = {}
	for i, v in ipairs(poolDatas) do
		table.insert(list,v.entryCfg)
	end
	GF.OpenWnd("UIActPrizeSlotPop",{list = list,des = ccClientText(23242)})
end
function UISubMotifLottery:CellListItem(item, itemdata, itempos)
	local entryId = itemdata.entryId
	local _itemEffectTransList = self._itemEffectTransList or {}
	local _itemEffectTrans = _itemEffectTransList[entryId]
	if not _itemEffectTrans then
		local iconRootTrans = self:FindWndTrans(item,"IconRoot")
		local addImg = self:FindWndTrans(item,"IconRoot/AddImg")
		local iconBg1 = self:FindWndTrans(item,"IconRoot/IconBg1")
		local iconBg2 = self:FindWndTrans(item,"IconRoot/IconBg2")
		local iconTrans1 = self:FindWndTrans(item,"IconRoot/ItemIcon1")
		local itemNum1   = self:FindWndTrans(item, "IconRoot/ItemIcon1/itemNum")
		local iconTrans2 = self:FindWndTrans(item,"IconRoot/ItemIcon2")
		local itemNum2   = self:FindWndTrans(item, "IconRoot/ItemIcon2/itemNum")
		local shiftIconTrans = self:FindWndTrans(item, "ShiftIcon")
		local itemEffectTrans = self:FindWndTrans(item,"Effect")

		local upIcon = self:FindWndTrans(item,"UpIcon")
		local rareIcon = self:FindWndTrans(item,"RareIcon")

		local iconBg1Path, iconBg2Path, iconBg1Scale, iconBg2Scale
		if(itemdata.layer == 6)then
			iconBg1Path = self._grandUnselectIcon
			iconBg2Path = self._grandSelectIcon
			iconBg1Scale = self._grandUnselectIconScale
			iconBg2Scale = self._grandSelectIconScale
		else
			iconBg1Path = self._unselectIcon
			iconBg2Path = self._selectIconIcon
			iconBg1Scale = self._unselectIconScale
			iconBg2Scale = self._selectIconScale
		end
		self:SetWndEasyImage(iconBg1,iconBg1Path)
		self:SetWndEasyImage(iconBg2,iconBg2Path)
		iconBg1.localScale = Vector3.New(iconBg1Scale,iconBg1Scale,1)
		iconBg2.localScale = Vector3.New(iconBg2Scale,iconBg1Scale,1)

		_itemEffectTrans = {
			itemTrans = item,
			iconRootTrans = iconRootTrans,
			addImg = addImg,
			iconBg2 = iconBg2,
			iconTrans1 = iconTrans1,
			itemNum1   = itemNum1,
			iconTrans2 = iconTrans2,
			itemNum2   = itemNum2,
			shiftIconTrans = shiftIconTrans,
			effectTrans = itemEffectTrans,
			entryCfg = itemdata.entryCfg,

			selectId = itemdata.selectId,
			jumpLayer = itemdata.jumpLayer,
			entryId = entryId,
			layer = itemdata.layer,
		}

		local moreInfo = itemdata.entryCfg.moreInfo
		local moreArr = string.split(moreInfo,"|")
		CS.ShowObject(upIcon,moreArr[2] and moreArr[2] == "1")
		CS.ShowObject(rareIcon,moreArr[6] and moreArr[6] == "1")
		if not string.isempty(moreArr[7])then
			local pos = LxDataHelper.ParseVector2NotEmpty(moreArr[7])
			self:SetAnchorPos(item, pos)
			CS.ShowObject(item,true)
		else
			CS.ShowObject(item, true)
		end
		if not string.isempty(self._arrowFlip)then
			if self._arrowFlip == 0 then
				self:SetAnchorPos(upIcon, Vector2.New(0,-130))
				upIcon.localRotation = Quaternion.Euler(0, 0, 180)
			end

		end
	end
	_itemEffectTrans.entry = itemdata.entry
	_itemEffectTransList[entryId] = _itemEffectTrans
	self._itemEffectTransList = _itemEffectTransList
	self:RefreshTurnTableGrid(_itemEffectTrans)
end
function UISubMotifLottery:RefreshShowList()
	local _itemShowTransList = self._itemShowTransList
	for i, v in pairs(_itemShowTransList) do
		local index = v.index
		local len = v.len
		local dataIndex = v.dataIndex
		local nexDataIndex = dataIndex + 1
		local nexIndex = index + 1
		if nexDataIndex > len then nexDataIndex = 1 end
		if nexIndex > 2 then nexIndex = 1 end
		v.index = nexIndex
		v.dataIndex = nexDataIndex
	end
	for i, v in pairs(_itemShowTransList) do
		self:SetGridItemData(i)
	end
end
function UISubMotifLottery:OnClickHelp()
	local _helpTxt = self._helpTxt
	_helpTxt = string.gsub(_helpTxt,"\\n","\n")
	GF.OpenWnd("UIBzTips",{title = self._helpTitle,text = _helpTxt})
end

function UISubMotifLottery:InitDate()
	self._modelLotteryList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = ModelActivity.SWEETS_COUNTRY_LOTTERY,
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_96] = ModelActivity.DROP_REWARD_LOTTERY,
	}
	self._modelOptionalAwardList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = ModelActivity.SWEETS_COUNTRY_OPTIONAL_AWARD,
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_96] = ModelActivity.DROP_REWARD_OPTIONAL_AWARD,
	}
	self._modelEnumList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = {
		-- 	ModelActivity.SWEET_COUNTRY_7,
		-- 	ModelActivity.SWEET_COUNTRY_8,
		-- 	ModelActivity.SWEET_COUNTRY_22
		-- },
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_96] = {
		-- 	ModelActivity.MOTIF_ACTIVITY_LOTTERY_1,
		-- 	ModelActivity.MOTIF_ACTIVITY_LOTTERY_2,
		-- 	ModelActivity.MOTIF_ACTIVITY_LOTTERY_6,
		-- 	ModelActivity.MOTIF_ACTIVITY_LOTTERY_7,
		-- },
	}
	self._modelPageIdList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = {
		-- 	ModelActivity.SWEET_COUNTRY_11,
		-- },
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_96] = {
		-- 	ModelActivity.MOTIF_ACTIVITY_LOTTERY_5,
		-- },
	}
	self:SetWndText(self.mDetailsText,ccClientText(25913))
	self:SetWndText(self.mLogText,ccClientText(25914))
	self:SetWndText(self.mShopText,ccClientText(25915))
end
--------------------------------------------延时处理------------------------------------------------

--------------------------------------------格子道具------------------------------------------------
function UISubMotifLottery:RefreshGridItem()
	self:InitGridPoolInfo()
	local layerList = self._layerList or {}

	local layers = {}
	for i, v in pairs(layerList) do
		table.insert(layers,{layer = i})
	end
	table.sort(layers,function (a,b)
		return a.layer > b.layer
	end)
	for i, v in ipairs(layers) do
		local layer = self:FindWndTrans(self.mLayerList,"Layer"..i)
		self:LayerListItem(layer,v,i)
	end

	local _timeKey = self._timeKey
	if not self:IsTimerExist(_timeKey)then
		self:TimerStart(_timeKey,self._turntableTime,false,-1)
	end
	if not self._isOnTurnRward then
		local _timeTurnRwardKey = self._timeTurnRwardKey
		self:TimerStop(_timeTurnRwardKey)
		self:TimerStart(_timeTurnRwardKey,self._rurnTime_Common,false,-1)
		self._isOnTurnRward = true
	end
end
function UISubMotifLottery:RefreshRankTime()
	local _rankClear = self._rankClear
	if not _rankClear then return end
	local _timeKey = self._timeRankKey
	local GetTimestamp = GetTimestamp()
	local timeTbl = LUtil.OSDate("*t", GetTimestamp)
	local year				= timeTbl.year
	local month				= timeTbl.month
	local day				= timeTbl.day
	local initialTime 		= LUtil.GetTimeByDateTable(year, month, day + 1)
	self._rankTimeValue = initialTime
	if not self:IsTimerExist(_timeKey)then
		self:OnRankTimeText()
		self:TimerStart(_timeKey,1,false,-1)
	end
end

function UISubMotifLottery:OnDrawRankCell(list,item,itemdata,itempos)
	local RankImgTrans = self:FindWndTrans(item,"RankImg")
	local NameTrans = self:FindWndTrans(item,"Name")
	local ScoreTrans = self:FindWndTrans(item,"Score")
	local rank = itemdata.rank
	local name = itemdata.name
	local score = itemdata.score
	local playerId = itemdata.playerId
	local myPlayerId = gModelPlayer:GetPlayerId()
	local color = myPlayerId == playerId and "lightGreen" or "yellow_2"
	name = LUtil.FormatColorStr(name,color)
	self:SetWndText(NameTrans,name)
	self:SetWndText(ScoreTrans,score)
	local rankScoreImgList = self._rankScoreImgList
	local img = rankScoreImgList and rankScoreImgList[rank]
	if img and RankImgTrans then
		self:SetWndEasyImage(RankImgTrans,img)
	end
end
function UISubMotifLottery:OpenRankWnd()
	local _rankId = self._rankId
	if _rankId then
		GF.OpenWndBottom("UIRkPop",{refId = _rankId,sid = self._sid,page = 1,rewardList = self._rewardList})
	end
end

function UISubMotifLottery:RefreshRankRewardList()
	local _rankId = self._rankId
	if not _rankId then return end
	local _sid = self._sid
	local _pages = self._pages or {}
	local modelId = gModelActivity:GetActivityModeIdBySid(_sid )
	self._rewardList = {}
	if(modelId == ModelActivity.MODEL_ACTIVITY_TYPE_96)then
		local _page = _pages[ModelActivity.MOTIF_ACTIVITY_LOTTERY_7]
		if not _page then return end
		local entry = _page.entry
		for i, v in ipairs(entry) do
			local rewardData = {}
			local entryCfg = gModelActivity:GetWebActivityEntryData(_sid,v.pageId,v.entryId)
			if not entryCfg then return end
			local entryId = v.entryId
			local items = LxDataHelper.ParseItem(entryCfg.reward)
			rewardData.index = entryId
			rewardData.reward = items
			local str = string.split(entryCfg.name,"~")
			local left = tonumber(str[1])
			local right = (str[2] and tonumber(str[2])) or left
			local rank = {}
			table.insert(rank,left)
			table.insert(rank,right)
			rewardData.rank = rank
			table.insert(self._rewardList,rewardData)
		end
		gModelRank:OnRankReq(2,_rankId,1,25,self._sid)
	end
end
-- 打开奖励弹窗
function UISubMotifLottery:OpenUIAward()
	local _oldIconBg2 = self._oldIconBg2
	if _oldIconBg2 then
		CS.ShowObject(_oldIconBg2,false)
	end
	local data = self._actDropGiftData
	if not data then return end
	GF.OpenWndTop("UIOrdinYellAward",data)
	self._actDropGiftData = nil
	self._isWndCall = false
end

function UISubMotifLottery:RefreshRank()
	local list = self:GetRankList()
	local listTrans = self.mRankList
	local key = listTrans:GetInstanceID()
	local uiRankList = self:FindUIScroll(key)
	if uiRankList then
		uiRankList:RefreshList(list)
	else
		uiRankList = self:GetUIScroll(key)
		uiRankList:Create(listTrans,list,function(...) self:OnDrawRankCell(...) end)
	end
end

function UISubMotifLottery:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = page.pageId
		_pages[pageId] = page
	end
	self._pages = _pages
	self:RefreshData()
end
function UISubMotifLottery:RefreshTaskBox()
	local _sid = self._sid
	local _pages = self._pages or {}
	local _page = _pages[self._roomTaskEnum]
	if not _page then return end
	local entry = _page.entry

	local curLv = self:GetCurItem(entry)
	if curLv then
		self._taskItemData = curLv
		local goalData = curLv.goalData
		local status = goalData.status
		local schedule = goalData.schedules[1]
		local goal = tonumber(schedule.goal)
		local schedule = tonumber(schedule.schedule)
		local entryCfg = gModelActivity:GetWebActivityEntryData(_sid,curLv.pageId,curLv.entryId)

		local isGet = schedule >= goal
		local str = LUtil.FormatColorStr(goal,isGet and "lightGreen" or "lightRed")
		local des = string.replace(entryCfg.name,str)
		-- local des = LUtil.FormatColorStr(entryCfg.name, isGet and "lightGreen" or "lightRed")
		self:SetWndText(self.mTaskText,des)
		-- if status == 2 then
		-- 	self:SetWndText(self.mTaskText,ccClientText(21713))
		-- end
	end
end
--------------------------------------------兑换道具------------------------------------------------
function UISubMotifLottery:RefreshItem()
	local _showItem = self._showItem
	local _currency = _showItem
	local list = {}
	if not string.isempty(_currency) then
		local arr = string.split(_currency,"|")
		for i, v in ipairs(arr) do
			table.insert(list,{itemId = tonumber(v)})
		end
	end
	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
	else
		_uiCellList = self:GetUIScroll("mItemScroll_UISubExtractAward")
		_uiCellList:Create(self.mItemScroll,list,function (...) self:ListItem(...) end)
		self._uiCellList = _uiCellList
	end
end
function UISubMotifLottery:OnClickLog()
	local titleStr,tipsStr,timeStr = self._logTitle,self._logTips,self._logTimeTips
	GF.OpenWnd("UIYellLog",{sid = self._sid,callType = 3,titleStr = titleStr,tipsStr = tipsStr,timeStr = timeStr,emptyRefId = 14008})
end
function UISubMotifLottery:InitGridPoolInfo()
	local _pages = self._pages
	if not _pages then return end
	local _tablepage = _pages[self._turnTableEnum]
	local _poolPage = _pages[self._turnPoolEnum]
	if not _tablepage or not _poolPage then return end
	local _tableEntrys = _tablepage.entry
	local _poolEntrys = _poolPage.entry
	local layerList =  {}
	local selectList = {}
	for i, v in ipairs(_tableEntrys) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		local moreInfo = string.split(entryCfg.moreInfo,"|")
		local layerIndex = tonumber(moreInfo[1])
		local isSel = tonumber(moreInfo[4]) > 0
		local list = layerList[layerIndex] or {}
		local data = {
			entryCfg = entryCfg,
			entry = v,
			selectId = isSel and v.entryId or 0,
			jumpLayer = tonumber(moreInfo[3]),
			entryId = v.entryId,
			layer = layerIndex,
		}
		table.insert(list,data)
		layerList[layerIndex] = list
		if isSel then
			selectList[v.entryId] = true
		end
	end
	for i, v in pairs(layerList) do
		local list = v
		table.sort(list,function (a,b)
			return a.entryId < b.entryId
		end)
	end
	self._layerList = layerList							--奖槽列表
	self._selectList = selectList						--自选格子列表
	--end
	local _poolList = self._poolList or {}
	local isOne = true
	for i, v in pairs(_poolList) do
		isOne = false
		break
	end
	if isOne then
		for i, v in ipairs(_poolEntrys) do
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
			local moreInfo = string.split(entryCfg.moreInfo,"|")
			local id = tonumber(moreInfo[1])
			local list = _poolList[id] or {}
			local data = {
				entryCfg = entryCfg,
				entry = v,
				entryId = v.entryId,
				rare = tonumber(moreInfo[2])
			}
			table.insert(list,data)
			_poolList[id] = list
		end
		for i, v in pairs(_poolList) do
			local list = v
			table.sort(list,function (a,b)
				return a.entryId < b.entryId
			end)
		end
		self._poolList = _poolList							--奖池列表
	end
end
--设置自选格子数据
function UISubMotifLottery:SetCustomGridItemData(item,selectEntryId,entryId)
	local iconTrans1 = item.iconTrans1
	local iconTrans2 = item.iconTrans2
	local itemNum1   = item.itemNum1
	local iconRootTrans = item.iconRootTrans
	local addImg = item.addImg
	local shiftIconTrans= item.shiftIconTrans
	local effectTrans = item.effectTrans

	local _poolList = self._poolList or {}
	local _poolPages = _poolList[entryId] or {}
	local itemData
	for i, v in ipairs(_poolPages) do
		if selectEntryId == v.entry.entryId then
			local reward = v.entryCfg.reward
			itemData = LxDataHelper.ParseItem_4(reward)
			break
		end
	end
	local itemId 	= itemData and itemData.itemId or nil
	local itemNumStr = itemData and LUtil.NumberCoversion(itemData.itemNum) or ""
	local haveItem 	= itemId and itemId > 0
	local bgImgPath
	CS.ShowObject(addImg,not haveItem)
	CS.ShowObject(effectTrans,false)
	if haveItem then
		--已选择
		local itemImgPath = gModelGeneral:GetCommonItemImgRef(itemData)
		if LxUiHelper.IsImgPathValid(itemImgPath) then
			self:SetWndEasyImage(iconTrans1, itemImgPath)
		end
		self:SetWndClick(iconRootTrans, function()
			self:OnClickOpenSelect(entryId)
		end)
	else
		--未选择
		bgImgPath = self._gridBgImgEmptyPath
		if LxUiHelper.IsImgPathValid(bgImgPath) then
			self:SetWndEasyImage(addImg, bgImgPath)
		end
		self:SetWndClick(iconRootTrans, function()
			self:OnClickOpenSelect(entryId)
		end)
	end
	self:SetWndText(itemNum1, itemNumStr)
	CS.ShowObject(iconTrans1, haveItem)
	CS.ShowObject(iconTrans2, false)
	local isShowShiftIcon = haveItem
	CS.ShowObject(shiftIconTrans, isShowShiftIcon)
	if isShowShiftIcon then
		self:SetWndClick(shiftIconTrans, function()
			self:OnClickOpenSelect(entryId)
		end)
	end
end
function UISubMotifLottery:InitMessage()
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshRed() end)
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp,function (pb)
		self:RefreshItem()
		self:RefreshBtnText()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			local sid = v.sid
			if self._sid == sid then
				self:RefreshData()
				self:RefreshRankTime()
				return
			end
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)

	local pbId = LProtoHelper.GetProtoId("ActivityDropGiftResp")
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(msgId, error, args ,errorStr)
		if pbId == msgId then
			self._isWndCall = false
		end
	end)

	self:WndEventRecv(EventNames.RANK_UPDATE_END,function (rankType,rankRefId)
		if rankRefId ~= self._rankId then return end
		self:RefreshRank()
	end)

	self:WndEventRecv(EventNames.ON_ACTIVITY_DROP_GIFT,function(data)
		local sid = data.sid
		if self._sid ~= sid then return end
		local num = data.callNum
		LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_LUCKY_MIRROR)
		self._actDropGiftData = data
		self._currLayerList = {}
		if self._isJumpTurnAnim or GF.FindFirstWndByName("UIOrdinYellAward") or num > 1 then
			self:OpenUIAward()
		else
			local _rurnNum = self._rurnNum						--要转的圈数
			local _sid_pageId_type = self._sid_pageId_type		--转盘最后一次转到的条目
			local _gradation = self._gradation					--当前所处层
			local _trunIdex = self._trunIdex					--当前跑到的索引
			local _len = 0								--格子数
			local _itemEffectTransList = self._itemEffectTransList
			if not _itemEffectTransList then return end
			local list =  {}
			for i, v in pairs(_itemEffectTransList) do
				local layer = v.layer
				if layer == _gradation then
					table.insert(list,v)
					_len = _len + 1
				end
			end
			table.sort(list,function (a,b)
				return a.entryId < b.entryId
			end)
			self._currLayerList = list
			local goIndex = 1
			for i, v in ipairs(list) do
				if _sid_pageId_type == v.entryId then
					goIndex = i
				end
			end

			local tarNum = goIndex <= _trunIdex and goIndex + _len - _trunIdex or goIndex - _trunIdex
			tarNum = _len * _rurnNum + tarNum - self._rurnStage2Nums
			local _rurnTime_Stage1 = self._rurnTime_Stage1
			self._cnt = tarNum
			--播放动画
			local _timeTurnRwardKey = self._timeTurnRwardKey
			self:TimerStop(_timeTurnRwardKey)
			self:TimerStart(_timeTurnRwardKey,_rurnTime_Stage1,false,tarNum)
		end
	end)
end
--------------------------------------------Tween动画-----------------------------------------------
------------------------------------------------------------------
return UISubMotifLottery