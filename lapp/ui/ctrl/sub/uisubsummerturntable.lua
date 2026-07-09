---
--- Created by BY.
--- DateTime: 2023/10/22 20:11:04
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSummerTurntable:LChildWnd
local UISubSummerTurntable = LxWndClass("UISubSummerTurntable", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSummerTurntable:UISubSummerTurntable()
	self._timeKey = "UISubSummerTurntableTimeKey"									--轮换TimeKey
	self._timeOpenRwardKey = "UISubSummerTurntableOpenRwardTimeKey"				--转盘延迟奖励界面TimeKey
	self._playItemTweenKey = "UISubSummerTurntablePlayItemTweenKey"				--轮换TweenKey
	self._timeTurnRwardKey = "UISubSummerTurntable_TurnRwardKey"					--转盘延迟奖励界面TimeKey
	self._rurnTime_Common = 0.6			--平常转时间
	self._rurnTime_Stage1 = 0.1			--抽奖阶段1时间
	self._rurnTime_Stage2 = 0.2			--抽奖阶段2时间
	self._openTime = 0.3				--打开奖励弹窗时间
	self._rurnNum = 2					--要转的圈数
	self._rurnStage2Nums = 3			--阶段2要转的次数

	self._itemMovePos = {
		showPos = Vector3.New(0,0,0),
		leftHidePos = Vector3.New(-140,0,0),
		rightHidePos = Vector3.New(140,0,0),
	}
	self._iconTransPath = "iconTrans"
	self._itemNumTransPath = "itemNum"
	self._tweenItemTime = 0.5													--轮换移动时间
	self._gridBgImgEmptyPath = "activity_magicSchool_ui_icon_jia"	--空格子
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSummerTurntable:OnWndClose()
	self:TimerStop(self._timeKey)
	self:TimerStop(self._timeOpenRwardKey)
	self:TimerStop(self._timeTurnRwardKey)

	self:TweenSeqKill(self._playItemTweenKey)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSummerTurntable:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSummerTurntable:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
--------------------------------------------延时处理------------------------------------------------

--------------------------------------------Tween动画-----------------------------------------------
function UISubSummerTurntable:PlayItemTween()
	local _itemMovePos = self._itemMovePos		--Item轮换坐标
	local iconTranPath = self._iconTransPath
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

			local iconTrans1 = transData[iconTranPath..curIconIndex]
			local move1 = iconTrans1:DOLocalMove(_itemMovePos.leftHidePos, moveTime)
			seq:Join(move1)

			local iconTrans2 = transData[iconTranPath..nexIconIndex]
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
-- 打开奖励弹窗
function UISubSummerTurntable:OpenUIAward()
	local data = self._actDropGiftData
	if not data then return end
	GF.OpenWndTop("UIOrdinYellAward",data)
	self._actDropGiftData = nil
	self._isWndCall = false
end
function UISubSummerTurntable:ListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local itemBg = self:FindWndTrans(root,"ItemBg")
	local itemIcon = self:FindWndTrans(itemBg,"ItemIcon")
	--local itemAdd = self:FindWndTrans(itemBg,"ItemAdd")
	local itemText = self:FindWndTrans(itemBg,"ItemText")

	local itemId = itemdata.itemId
	local icon,iconBg = gModelItem:GetItemImgByRefId(itemId)
	local itemNum = gModelItem:GetNumByRefId(itemId)

	self:SetWndEasyImage(itemIcon,icon)
	self:SetWndText(itemText,LUtil.NumberCoversion(itemNum))

	self:SetWndClick(root,function ()
		local wndName = self:GetParentWndName() -- self._modelMagList[self._modelId]
		gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = wndName})
	end)
end
function UISubSummerTurntable:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config


	self._helpTitle,self._helpTxt = ccClientText(23216),data.probabilityTxt
	self._turntableTime = data.turntableTime or 3
	self:SetWndText(self.mTxtDeSText,data.guaraTxt)
	--self._logTitle,self._logTips = data.logTitle,data.logTips

	--if LxUiHelper.IsImgPathValid(data.turntableImage) then
	--	CS.ShowObject(self.mMask,true)
	--	self:SetWndEasyImage(self.mMask,data.turntableImage)
	--end
	--if LxUiHelper.IsImgPathValid(guaTxt) then
	--	CS.ShowObject(self.mGuaTxtImg,true)
	--	self:SetWndEasyImage(self.mGuaTxtImg,guaTxt,nil,true)
	--end
	--if not string.isempty(guaRewardTxt) then
	--	local parent = self.mGuaTipsText
	--	CS.ShowObject(parent,true)
	--	self:SetWndText(parent,guaRewardTxt)
	--	if not string.isempty(guaRewardTxtPos) then
	--		local pos = LxDataHelper.ParseVector2NotEmpty2(guaRewardTxtPos)
	--		self:SetAnchorPos(parent, pos)
	--	end
	--end

	local str = data.skipTxt or ccClientText(23211)
	self:SetTextTile(self.mShowToggle,str)
	--self:SetWndText(self.mToggleText,data.skipTxt or ccClientText(23211))

	local enterHero = data.enterHero4
	if string.isempty(enterHero) or enterHero == "0" or enterHero == 0 then
		enterHero = data.enterHeroLH4
	end
	local pbName = gModelHero:GetHeroDrawing(tonumber(enterHero))
	if pbName then
		self:CreateWndSpine(self.mRoleRoot,pbName,"drawing")
	end

	self._shopJump = data.shopJump

	self:RefreshData()
	self:RefreshRed()
end
--------------------------------------------格子道具------------------------------------------------
function UISubSummerTurntable:RefreshTurntableItem()
	local _pages = self._pages
	if not _pages then return end
	local _tablepage = _pages[self._turnTableEnum]
	if not _tablepage then return end
	self:GetPoolPageData()
	local len = #_tablepage.entry
	for i, v in ipairs(_tablepage.entry) do
		local item = self:FindWndTrans(self.mItemList,"Item_"..i)
		self:TurnTableListItem(item,v,i)
	end
	self._len = len
	CS.ShowObject(self.mItemList,len > 0)

	local _timeKey = self._timeKey
	if not self:IsTimerExist(_timeKey)then
		self:TimerStart(_timeKey,self._turntableTime,false,-1)
	end
	if not self._isWndCall then
		local _timeTurnRwardKey = self._timeTurnRwardKey
		self:TimerStop(_timeTurnRwardKey)
		self:TimerStart(_timeTurnRwardKey,self._rurnTime_Common,false,-1)
	end

	self._isExecute = true	--固定不变，奖励格子只执行一次初始化
end
function UISubSummerTurntable:RefreshData()
	local sid = self._sid
	if not sid then return end
	local activityDataS = gModelActivity:GetActivityBySid(sid)
	local activityDataW = gModelActivity:GetWebActivityDataById(sid)
	if not activityDataS or not activityDataW then
		return
	end
	--------------------------------------后端数据------------------------------------------------
	local dataS = JSON.decode(activityDataS.moreInfo)
	local freeNum = dataS.freeNum or 0				--免费次数
	local callNum = dataS.remainBuyNum or 0			--剩余钻石购买次数
	local dropNumToday = dataS.usedBuyNum or 0		--今天总掉落次数
	local awardKey = string.format("%s-%s-%s",sid,self._turnTableEnum,5)
	local sid_pageId_type = dataS[awardKey]			--转盘最后一次转到的条目
	self._freeNum,self._callNum,self._dropNumToday = freeNum,callNum,dropNumToday
	self._sid_pageId_type = sid_pageId_type
	local guaranteeScore = dataS.guaranteeScore
	----------------------------------------------------------------------------------------------
	--------------------------------------配置数据------------------------------------------------
	local dataW = activityDataW.config
	local callBtnTxt = dataW.btnText
	local callLimitTips = dataW.callLimitTips or ccClientText(23224)
	local callMaxNum = dataW.callMaxNum
	local diaCallLimitTips = dataW.diaCallLimitTips or ccClientText(23226)
	self._showItem = dataW.showItem
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
	local guaraImg,guaraImgPos = dataW.guaraImg,dataW.guaraImgPos
	if LxUiHelper.IsImgPathValid(guaraImg) then
		CS.ShowObject(self.mTxtImg,true)
		self:SetWndText(self.mTxtNumText,guaranteeScore == 0 and ccClientText(24725) or guaranteeScore + 1)
		self:SetWndEasyImage(self.mTxtImg,guaraImg,nil,true)
		if not string.isempty(guaraImgPos) then
			local Arr = string.split(guaraImgPos,"|")
			self.mTxtImg.anchoredPosition = Vector3(tonumber(Arr[1]),tonumber(Arr[2]),0)
		end
	end
	if not string.isempty(diaCallLimitTips) then
		local str = LUtil.FormatColorStr(callNum,callNum <= 0 and "lightRed" or "lightGreen")
		self:SetWndText(self.mTipsText,string.replace(diaCallLimitTips,str))
	end
	--local dropScore = dataS.guaranteeScore or 0
	--local guaNum = dropScore + 1
	--self:SetWndText(self.mGuaText,guaNum <= 1 and ccClientText(24725)or guaNum)


	self:RefreshTextInfo()

	self:RefreshBtnText()
	self:RefreshItem()
	self:RefreshTurntableItem()
end
function UISubSummerTurntable:RefreshBtnText()
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

	CS.ShowObject(self.mTenCostText,freeNum < 10)

	if freeNum < 10 then
		local isItemCost = bagItemNum >= 10
		local tenCostStr = isItemCost and _costTen2.itemNum or _costTen1.itemNum
		local tenCostRefId = isItemCost and _costTen2.itemId or _costTen1.itemId
		local icon,iconBg = gModelItem:GetItemImgByRefId(tenCostRefId)
		self:SetWndText(self.mTenCostText,tenCostStr)
		self:SetWndEasyImage(self.mTenCostIcon,icon)
	end

end
--刷新格子数据
function UISubSummerTurntable:TurnTableListItem(item, itemdata, itempos)
	local _itemEffectTransList = self._itemEffectTransList or {}
	local _itemEffectTrans = _itemEffectTransList[itempos]
	if not _itemEffectTrans then
		--local IndexBg = self:FindWndTrans(item,"IndexBg")
		--local IndexBgIndexText = self:FindWndTrans(IndexBg,"IndexText")
		local IconRoot = self:FindWndTrans(item,"IconRoot")
		local IconRootAddImg = self:FindWndTrans(IconRoot,"AddImg")
		local IconRootIconBg1 = self:FindWndTrans(IconRoot,"IconBg1")
		local IconRootIconBg2 = self:FindWndTrans(IconRoot,"IconBg2")
		local IconRootItemIcon1 = self:FindWndTrans(IconRoot,"ItemIcon1")
		local ItemIcon1ItemNum = self:FindWndTrans(IconRootItemIcon1,"itemNum")
		local IconRootItemIcon2 = self:FindWndTrans(IconRoot,"ItemIcon2")
		local ItemIcon2ItemNum = self:FindWndTrans(IconRootItemIcon2,"itemNum")
		local ShiftIcon = self:FindWndTrans(item,"ShiftIcon")
		local ShiftIconIcon = self:FindWndTrans(ShiftIcon,"Icon")
		local Effect = self:FindWndTrans(item,"Effect")





		_itemEffectTrans = {
			itemTrans = item,
			iconRootTrans = IconRoot,
			addImg = IconRootAddImg,
			iconBg1 = IconRootIconBg1,
			iconBg2 = IconRootIconBg2,
			iconTrans1 = IconRootItemIcon1,
			itemNum1   = ItemIcon1ItemNum,
			iconTrans2 = IconRootItemIcon2,
			itemNum2   = ItemIcon2ItemNum,
			shiftIconTrans = ShiftIcon,
			effectTrans = Effect,
		}
		_itemEffectTransList[itempos] = _itemEffectTrans

		CS.ShowObject(item,true)
		--self:SetWndText(indexText, itempos)
	end
	self._itemEffectTransList = _itemEffectTransList

	_itemEffectTrans.itempos = itempos
	_itemEffectTrans.entry = itemdata
	_itemEffectTrans.entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	self:RefreshTurnTableGrid(_itemEffectTrans)
end
function UISubSummerTurntable:RefreshRed()
	--local red = gModelRedPoint:GetActivityRedPointPage(self._sid,self._turnShopEnum)
	--CS.ShowObject(self.mShopRed,red)

	local redTran = self:FindWndTrans(self.mBtnOne,"redPoint")
	-- local showRed = gModelRedPoint:GetActivityRedPointPage(self._sid,ModelActivity.BAND_THEME_TURN_TABLE)
	-- CS.ShowObject(redTran,showRed)
end

function UISubSummerTurntable:OnClickShop()
	if not self._shopJump then
		return
	end

	gModelFunctionOpen:Jump(self._shopJump)

	--local _sid = self._sid
	--GF.OpenWndBottom("UIDian",{page = ModelShop.ACTIVITY,subPage = _sid})
	--local _turnShopEnum = self._turnShopEnum
	--local bool = gModelRedPoint:GetActivityRedPointPage(_sid,_turnShopEnum)
	--if bool then
	--	gModelActivity:OnActivitySpecialOpReq(_sid,_turnShopEnum,nil,ModelActivity.CANCEL_RED_POINT, "1")
	--end
	--self:WndCloseParentWnd()
end
function UISubSummerTurntable:RefreshShowList()
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
--设置固定格子数据
function UISubSummerTurntable:SetGridItemData(itempos)
	local transData = self._itemEffectTransList[itempos]
	local poolDatas = self._poolPageDataList[itempos]
	if not transData or not poolDatas then return end

	local iconTransPath = self._iconTransPath
	local itemNumTransPath = self._itemNumTransPath
	local len = #poolDatas
	local _itemShowTransList = self._itemShowTransList or {}
	local itemShowTransData = _itemShowTransList[itempos]
	if not itemShowTransData then
		itemShowTransData = {
			index = 1,
			len = len,
			dataIndex = 1,
		}
		_itemShowTransList[itempos] = itemShowTransData
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
	local iconBg1 = transData.iconBg1
	local iconBg2 = transData.iconBg2

	local itemBg = gModelGeneral:GetCommonItemWaterBg(itemData)
	if LxUiHelper.IsImgPathValid(itemBg) then
		self:SetWndEasyImage(iconBg1, itemBg)
		self:SetWndEasyImage(iconBg2, itemBg)
	end
	--local qualityId  = gModelGeneral:GetCommonItemQualityRef(itemData)
	--local qualityRef = gModelItem:GetQualityRef(qualityId)
	--local bgImgPath = qualityRef.roundBg
	local itemNumStr1 = LUtil.NumberCoversion(itemData.itemNum) or ""
	local itemImgPath = gModelGeneral:GetCommonItemImgRef(itemData)
	self:SetWndText(itemNum1, itemNumStr1)
	if LxUiHelper.IsImgPathValid(itemImgPath) then
		self:SetWndEasyImage(iconTrans1, itemImgPath)
	end
	--if LxUiHelper.IsImgPathValid(bgImgPath) then
	--	self:SetWndEasyImage(iconRootTrans, bgImgPath)
	--end
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
		GF.OpenWnd("WndBandThemeTurnTableItemsPop",{sid = self._sid, posIndex = itempos})
	end)
end
--------------------------------------------兑换道具------------------------------------------------

--------------------------------------------点击事件------------------------------------------------
function UISubSummerTurntable:CheckIsAllSelect()
	local itemList = self._itemEffectTransList
	for k,v in ipairs(itemList) do
		local moreInfo = string.split(v.entryCfg.moreInfo, '|')
		local isCustomGrid = tonumber(moreInfo[1]) == 1
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
function UISubSummerTurntable:OnClickHelp()
	local _helpTxt = self._helpTxt
	_helpTxt = string.gsub(_helpTxt,"\\n","\n")
	GF.OpenWnd("UIBzTips",{title = self._helpTitle,text = _helpTxt})
end

function UISubSummerTurntable:RefreshTextInfo()
	local webCfg = gModelActivity:GetWebActivityDataById(self._sid)
	if not webCfg then
		return
	end
	local data = webCfg.config

	local str = string.replace(data.callDiamondTips,self._callNum)
	self:SetWndText(self.mTipsText,str)

	local turnNum = self._dropNumToday or 0
	local callMaxNum = data.callMaxNum
	str = string.replace(data.todayMax, turnNum, callMaxNum)
	self:SetWndText(self.mCallNumText,str)
end
--刷新格子显示
function UISubSummerTurntable:RefreshTurnTableGrid(_itemEffectTrans)
	local entry = _itemEffectTrans.entry
	local entryCfg = _itemEffectTrans.entryCfg
	local itempos = _itemEffectTrans.itempos

	local moreInfo = string.split(entryCfg.moreInfo, '|')
	local isCustomGrid = tonumber(moreInfo[1]) == 1
	if isCustomGrid then
		local selectEntryId
		local entryMoreInfo = JSON.decode(entry.moreInfo)
		for a,b in pairs(entryMoreInfo) do
			selectEntryId = tonumber(b)
			break
		end
		self:SetCustomGridItemData(_itemEffectTrans,selectEntryId,itempos)
	elseif not self._isExecute then
		self:SetGridItemData(itempos)
	end
end
function UISubSummerTurntable:InitCommand()
	local sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	local pages = self:GetWndArg("pages")
	self._pageId = entry[1].pageId
	self._entry = entry
	self._pages = pages
	self._sid = sid
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._modelId = modelId

	local enums = self._modelEnumList[modelId]
	self._turnTableEnum = enums[1]					--转盘表
	self._turnPoolEnum = enums[2]					--转盘奖池
	self._turnShopEnum = enums[3]					--商店兑换

	self:OnActivityConfigData()
	self:SetWndText(self.mDetailsText,ccClientText(25913))
	self:SetWndText(self.mLogText,ccClientText(25914))
	self:SetWndText(self.mShopText,ccClientText(25915))

	--是否跳过抽奖动画，直接显示奖励
	self._isJumpTurnAnim = toboolean(LPlayerPrefs.bandThemeJumpTurnTable)
	self:SetWndToggleValue(self.mShowToggle, self._isJumpTurnAnim)
end
function UISubSummerTurntable:OnClickOpenSelect(itempos)
	GF.OpenWnd("WndBandThemeCustomSelect",{sid = self._sid, itemIndex = itempos,pages = self._pages})
end
function UISubSummerTurntable:OnClickLog()
	local titleStr,tipsStr = self._logTitle,self._logTips
	GF.OpenWnd("UIYellLog",{sid = self._sid,callType = 3,titleStr = titleStr,tipsStr = tipsStr})
end

function UISubSummerTurntable:OnClickDetails()
	GF.OpenWnd("WndBandThemeTurnTableRatePop",{sid = self._sid})
end
function UISubSummerTurntable:OnClickOneTen(num)
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
	local wndName = self:GetParentWndName() -- self._modelMagList[self._modelId]
	gModelActivity:GetCallDataBySid(self._sid,self._turnTableEnum,num == 1 and 1 or 2,wndName,nil,function ()
		self._isWndCall = true
	end)
end
--初始化池子
function UISubSummerTurntable:GetPoolPageData()
	local _pages = self._pages
	local _poolPage = _pages[self._turnPoolEnum]
	if not _poolPage then return end
	local _poolPageDataList = self._poolPageDataList
	if not _poolPageDataList then
		_poolPageDataList = {}
		for i, v in ipairs(_poolPage.entry) do
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
			local moreInfo = entryCfg.moreInfo
			local arr = string.split(moreInfo,"|")
			local poolId = tonumber(arr[1])
			local poolList = _poolPageDataList[poolId] or {}
			local data = {
				entry = v,
				entryCfg = entryCfg,
			}
			table.insert(poolList,data)
			_poolPageDataList[poolId] = poolList
		end
		self._poolPageDataList = _poolPageDataList
	end
end
--------------------------------------------点击事件------------------------------------------------

--------------------------------------------延时处理------------------------------------------------
function UISubSummerTurntable:OnTimer(key)
	if(key == self._timeKey)then
		self:PlayItemTween()
	elseif key == self._timeOpenRwardKey then
		self:OpenUIAward()
		local _timeTurnRwardKey = self._timeTurnRwardKey
		self:TimerStop(_timeTurnRwardKey)
		self:TimerStart(_timeTurnRwardKey,self._rurnTime_Common,false,-1)
	elseif key == self._timeTurnRwardKey then
		self:TurnRwardBg()
	end
end
function UISubSummerTurntable:InitMessage()
	self:WndEventRecv(EventNames.ON_ACT_PAGE_RED_CHANGE,function (redMap)
		if not redMap[self._sid] then
			return
		end
		self:RefreshRed()
	end)
	--self:WndNetMsgRecv(LProtoIds.RedPointResp,function (pb)
	--	self:RefreshRed()
	--end)
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp,function (pb)
		self:RefreshItem()
		self:RefreshBtnText()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			local sid = v.sid
			if sid == self._sid then
				self:RefreshData()
				return
			end
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		local sid = pb.sid
		if sid ~= self._sid then return end
		self:RefreshData()
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

	self:WndEventRecv(EventNames.ON_ACTIVITY_DROP_GIFT,function(data)
		local sid = data.sid
		if self._sid ~= sid then return end
		LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_LUCKY_MIRROR)
		self._actDropGiftData = data
		if self._isJumpTurnAnim or GF.FindFirstWndByName("UIOrdinYellAward") then
			self:OpenUIAward()
		else
			local _rurnNum = self._rurnNum						--要转的圈数
			local _sid_pageId_type = self._sid_pageId_type		--转盘最后一次转到的条目
			local _trunIdex = self._trunIdex or 1					--当前跑到的索引
			local _len = self._len								--格子数

			local tarNum = _sid_pageId_type <= _trunIdex and _sid_pageId_type + _len - _trunIdex or _sid_pageId_type - _trunIdex
			tarNum = _len * _rurnNum + tarNum - 3

			local _rurnTime_Stage1 = self._rurnTime_Stage1

			self._cnt = tarNum
			--播放动画
			local _timeTurnRwardKey = self._timeTurnRwardKey
			self:TimerStop(_timeTurnRwardKey)
			self:TimerStart(_timeTurnRwardKey,_rurnTime_Stage1,false,tarNum)

		end
	end)
end

function UISubSummerTurntable:InitEvent()

	self._modelEnumList =
	{
		-- [ModelActivity.SUMMER_DAY] = {ModelActivity.BAND_THEME_TURN_TABLE,ModelActivity.BAND_THEME_TURN_POOL,ModelActivity.BAND_THEME_SHOP},
	}
	self:SetWndClick(self.mBtnHelp,function (...)self:OnClickHelp() end)
	self:SetWndClick(self.mBtnOne,function (...)self:OnClickOneTen(1) end)
	self:SetWndClick(self.mBtnTen,function (...)self:OnClickOneTen(10) end)
	self:SetWndClick(self.mBtnLog,function (...)self:OnClickLog() end)
	--self:SetWndClick(self.mBtnShop, function() self:OnClickShop() end)
	self:SetWndClick(self.mDrawing,function ()
		self:OnClickShop()
	end)
	self:SetWndClick(self.mBtnDetails,function () self:OnClickDetails() end)
	self:SetWndToggleDelegate(self.mShowToggle,function (value)
		LPlayerPrefs.SetBandThemeJumpTurnTable(tostring(value))
		self._isJumpTurnAnim = value
	end)
end

function UISubSummerTurntable:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = page.pageId
		_pages[pageId] = page
	end
	self._pages = _pages
	self:RefreshData()
end
function UISubSummerTurntable:TurnRwardBg()
	local _itemEffectTransList = self._itemEffectTransList
	if not _itemEffectTransList then return end
	local trunIndex = self._trunIdex
	if trunIndex then
		local data = _itemEffectTransList[trunIndex]
		CS.ShowObject(data.iconBg2,false)
	end
	trunIndex = trunIndex and trunIndex + 1 or 1
	if trunIndex > #_itemEffectTransList then
		trunIndex = 1
	end
	local data = _itemEffectTransList[trunIndex]
	CS.ShowObject(data.iconBg2,true)
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
	self._rurnStage2Num = nil
	--延迟self._openTime秒后弹奖励
	local _timeOpenRwardKey = self._timeOpenRwardKey
	self:TimerStop(_timeOpenRwardKey)
	self:TimerStart(_timeOpenRwardKey,self._openTime,false,1)
end
--设置自选格子数据
function UISubSummerTurntable:SetCustomGridItemData(item,selectEntryId,itempos)
	local iconTrans1 = item.iconTrans1
	local iconTrans2 = item.iconTrans2
	local itemNum1   = item.itemNum1
	local iconRootTrans = item.iconRootTrans
	local addImg = item.addImg
	local iconBg1 = item.iconBg1
	local iconBg2 = item.iconBg2
	local shiftIconTrans= item.shiftIconTrans
	local effectTrans = item.effectTrans

	local _poolPageDataList = self._poolPageDataList or {}
	local _poolPages = _poolPageDataList[itempos] or {}
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
	CS.ShowObject(iconBg1,haveItem)
	CS.ShowObject(effectTrans,false)

	if haveItem then
		--已选择
		local qualityId  = gModelGeneral:GetCommonItemQualityRef(itemData)
		local qualityRef = gModelItem:GetQualityRef(qualityId)
		bgImgPath        = qualityRef.roundBg
		local waterBg = gModelGeneral:GetCommonItemWaterBg(itemData)
		if LxUiHelper.IsImgPathValid(waterBg) then
			self:SetWndEasyImage(iconBg1, waterBg)
			self:SetWndEasyImage(iconBg2, waterBg)
		end
		local itemImgPath = gModelGeneral:GetCommonItemImgRef(itemData)
		if LxUiHelper.IsImgPathValid(itemImgPath) then
			self:SetWndEasyImage(iconTrans1, itemImgPath)
		end
		self:SetWndClick(iconRootTrans, function()
			gModelGeneral:ShowCommonItemTipWnd(itemData)
		end)
	else
		--未选择
		--bgImgPath = self._gridBgImgEmptyPath
		--if LxUiHelper.IsImgPathValid(bgImgPath) then
		--	self:SetWndEasyImage(addImg, bgImgPath)
		--end

		self:SetWndEasyImage(addImg,"activity_summer_bubble_7")
		self:SetWndEasyImage(iconBg2,"activity_summer_bubble_7")


		self:SetWndClick(iconRootTrans, function()
			self:OnClickOpenSelect(itempos)
		end)
	end

	self:SetWndText(itemNum1, itemNumStr)
	CS.ShowObject(iconTrans1, haveItem)
	CS.ShowObject(iconTrans2, false)
	local isShowShiftIcon = haveItem
	CS.ShowObject(shiftIconTrans, isShowShiftIcon)
	if isShowShiftIcon then
		self:SetWndClick(shiftIconTrans, function()
			self:OnClickOpenSelect(itempos)
		end)
	end
end
--------------------------------------------格子道具------------------------------------------------

--------------------------------------------兑换道具------------------------------------------------
function UISubSummerTurntable:RefreshItem()
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
		_uiCellList = self:GetUIScroll("mItemScroll_UISubSummerTurntable")
		_uiCellList:Create(self.mItemScroll,list,function (...) self:ListItem(...) end)
		self._uiCellList = _uiCellList
	end
end
--------------------------------------------Tween动画-----------------------------------------------
------------------------------------------------------------------
return UISubSummerTurntable