---
--- Created by Administrator.
--- DateTime: 2021/1/12 18:30:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFlandDraw:LWnd
local UIFlandDraw = LxWndClass("UIFlandDraw", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFlandDraw:UIFlandDraw()
	self:SetHideHurdle()
	---@type table<number,table>
	self._uiItemList = nil
	---@type table<number,UIIconEasyList>
	self._uiCommonList = {}

	self._bigGiftUICommon = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFlandDraw:OnWndClose()
	self:TweenSeqDestroyAll()
	self:ClearBigGiftEffect()
	self:ClearEffectKeyList()

	self._bWaitClickDropReq = nil
	self:StopClickDropTimer()

	if self._bigGiftUICommon then
		self._bigGiftUICommon:Destroy()
	end
	self._bigGiftUICommon = nil

	LUtil.ClearHashTable(self._uiCommonList)
	self._uiCommonList = nil

	if self._uiItemList then
		self._uiItemList:OnWndClose()
	end
	self._uiItemList = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFlandDraw:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFlandDraw:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()

	self:SetWndText(self.mAllGiftTxt, ccClientText(18715))
	self:SetWndText(self.mNextClassBtnText, ccClientText(18723))
	self:SetWndButtonText(self.mBtnOnKey,ccClientText(18765))
	self:SetWndText(self.mTxtReturn, ccClientText(10320))


    local timePara = {
        key = 1,
        loopcnt = -1,
        interval = 1,
        timescale = false,
        callOnStart = false,
        func = function()
            self:Update()
        end
    }
    self:TimerStartImpl(timePara)

end

function UIFlandDraw:PlayDrawOverturnEmptyAnimTimerFunc()
	if self._curPlayIndex >= self._allPoint then return end

	local lineAnimFunc = function(seq, lineIndex,showTime)
		return self:InitDrawOverturnEmptyAnim(seq, lineIndex, showTime)
	end

	local completeFunc = function()
		if self._curCompleteIndex >= self._allPoint then
			self._showNextClassCommonAnim = true
			self:TimerStop(self._turnEmptyTimeKey)

			self:OnNextClass()
		end
	end

	self:InitColumnAnimFunc(self._turnEmptyPlayKey, lineAnimFunc, completeFunc)
end

function UIFlandDraw:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:CloseWndFunc() end)
	self:SetWndClick(self.mConsumeItemAddBtn,function() self:OnClickItemAddBtn() end)
	self:SetWndClick(self.mNextClassBtn,function() self:OnClickNextClassBtn() end)
	self:SetWndClick(self.mHelpBtn,function() self:OnClickHelp() end)
	self:SetWndClick(self.mAllGiftTxt,function() self:OpenShowAllGift() end)
	self:SetWndClick(self.mNoSel,function() self:OpenSelectedBigGift() end)
	self:SetWndClick(self.mShiftBtn,function() self:OpenSelectedBigGift() end)
	self:SetWndClick(self.mBtnOnKey,function ()
		self:OnClickKey()
	end)
end

function UIFlandDraw:StopClickDropTimer()
	if self._delayClickDropTimer then
		LxTimer.DelayTimeStop(self._delayClickDropTimer)
		self._delayClickDropTimer = nil
	end
end

--点击下一轮，将卡牌翻至背面
function UIFlandDraw:PlayDrawOverturnEmptyAnimTime()
	self:PlayDrawOverturnEmptyAnimTimerFunc()
	self:TimerStart(self._turnEmptyTimeKey,self._nextLinePlayInterval,false,-1)
end

function UIFlandDraw:RefreshBigGift()
	local haveSelect = self._curDrawState == self._drawState.DRAW or self._showOverturnAnim
	CS.ShowObject(self.mNoSel, not haveSelect)
	CS.ShowObject(self.mSel, haveSelect)
	CS.ShowObject(self.mShiftBtn, haveSelect)
	self:SetSleEffect(not haveSelect)
	self:SetWndButtonGray(self.mBtnOnKey,not haveSelect)
	if not haveSelect then return end

	local curSelectEntryId 	= self._activityPageData.nowSuperGift
	local bigDrawData  		= self._bigDrawDataByEntryId[curSelectEntryId]
	if not bigDrawData then
		LogError("self._bigDrawDataByEntryId[curSelectEntryId] is not find, curSelectEntryId = "..curSelectEntryId)
		return
	end

	local items 	  = bigDrawData.items
	local refId 	  = items.itemId
	local itemType 	  = items.itemType
	local itemNum	  = items.itemNum or -1
	local effect	  = items.isShowEff
	local formatData  = {itemType = itemType, itemId = refId, itemNum = itemNum}

	local baseClass 	= self._bigGiftUICommon
	if not baseClass then
		baseClass		= CommonIcon:New()
		self._bigGiftUICommon = baseClass
		baseClass:Create(self.mIcon)
	end
	baseClass:SetCommonReward(itemType, refId, itemNum)
	baseClass:DoApply()

	----设置道具特效
	local show = effect ~= false
	if show and itemType == LItemTypeConst.TYPE_ITEM then
		LxResUtil.DestroyChildImmediate(self.mSelEff)
		local itemRef = gModelItem:GetRefByRefId(refId)
		local bgEff = itemRef and itemRef.bgEff or nil
		show = not string.isempty(bgEff)
		if show then
			local key = "DrawItem"..tostring(curSelectEntryId)
			table.insert(self._effectKeyList,key)
			self:CreateWndEffect(self.mSelEff,bgEff,nil,100,false,false)
		end
	end
	CS.ShowObject(self.mSelEff,show)
	self:SetWndClick(self.mSel, function()
		gModelGeneral:ShowCommonItemTipWnd(formatData)
	end)
end
function UIFlandDraw:OnClickKey()
	local haveSelect = self._curDrawState == self._drawState.DRAW or self._showOverturnAnim
	if not haveSelect then
		GF.ShowMessage(ccClientText(18766))
		return
	end
	local dropReqFunc = function()
		local allItemsList = self:GetDrawCellItemsData()
		local points = {}
		for i, v in ipairs(allItemsList) do
			local hideContent
			if self._curDrawState == self._drawState.COMMON then
				hideContent = v.hideContent or false
			else
				local cfgData = self._activityDrawData[i]
				hideContent = cfgData.hideContent or false
			end
			if not hideContent and not v.entryId then
				table.insert(points,i)
			end
		end
		gModelActivity:OnActivityNoRepeatDropReq(2, self._sid, self._pageId, 0, 0,points)
	end

	local consumeData  	= self._consumeData
	local refId 		= consumeData.itemId
	local itemNum 		= consumeData.itemNum
	local haveNum		= gModelItem:GetNumByRefId(refId)
	local itemNameStr	= gModelItem:GetNameByRefId(refId)
	itemNameStr			= itemNameStr.."*"..itemNum

	if haveNum < itemNum then
		--道具不足
		gModelGeneral:OpenGetWayWnd({itemId = refId,srcWnd = self:GetWndName()})
		return
	elseif self._haveBigGift and self._bigGiftItemData then
		--已开出大奖
		local wndId = 110056
		local bigItem		= self._bigGiftItemData
		local bigRefId 		= bigItem.itemId
		local bigItemNum 	= bigItem.itemNum
		local bigItemNameStr = gModelItem:GetNameByRefId(bigRefId)
		bigItemNameStr		= bigItemNameStr.."*"..bigItemNum
		gModelGeneral:OpenUIOrdinTips({refId = wndId,func = dropReqFunc,para = {bigItemNameStr, itemNameStr}})
	else
		--正常开启大奖
		local wndId = 110060
		local num = gModelItem:GetNumByRefId(refId)
		itemNameStr	= gModelItem:GetNameByRefId(refId)
		itemNameStr			= itemNameStr.."*"..num
		gModelGeneral:OpenUIOrdinTips({refId = wndId,func = dropReqFunc,para = {itemNameStr}})
	end
end

function UIFlandDraw:SetContent()
	self:RefreshCurClass()
	self:RefreshBigGift()
	self:RefreshNextClassBtn()

	if not self._showDrawGiftPoint then
		--注册全部
		self:InitItemList()
	else
		--刷新目标位置
		self:ResetDrawCellItemByItemPos(self._showDrawGiftPoint)
	end

	if self._showOverturnAnim then
		self:PlayAllItemOverturnBackAnim()
	end

	if self._showNextClassCommonAnim then
		self:PlayDrawOverturnCommonAnim()
	end
end

function UIFlandDraw:InitDrawOverturnCommonAnim(seq, lineIndex, showTime)
	local uiList = self._uiItemList
	if not uiList then return end

	local curLineIndex 	= self._curPlayColumnIndex
	local itemPos 		= curLineIndex * 5 + lineIndex
	local itemTrans 	= uiList:GetItemByIndex(itemPos)
	local roteY 		= itemTrans.transform:DORotate(Vector3.New(0,90,0),showTime)
	seq:Append(roteY)
	seq:AppendCallback(function()
		uiList:DrawItemByIndex(itemPos)
	end)
	local roteReset 	= itemTrans.transform:DORotate(Vector3.New(0,0,0),showTime)
	seq:Append(roteReset)
	return seq
end

function UIFlandDraw:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:SetTop()

	local pbData = gModelActivity:GetActivityPageBySid(self._sid)
	if pbData then
		self:ResetActivePageData(pbData)
		self:InitItemList()
		self:RefreshCurClass()
	else
		gModelActivity:OnActivityPageReq(self._sid)
	end
end

function UIFlandDraw:RefreshCurClass()
	if not self._activityPageData then return end

	local roundTime = self._activityPageData.roundTime or 1
	self:SetWndText(self.mClassTxt, string.replace(ccClientText(18714), roundTime))
end

function UIFlandDraw:OnClickNextClassBtn()
	self:ClearEffectKeyList()
	self:PlayDrawOverturnEmptyAnim()
end

function UIFlandDraw:SetNextClassBtnEffect(isShow)
	local effect = self._nextClassEffectPaths
	if not isShow then
		self:DestroyWndEffectByKey(effect)
		self:TimerStop(self._replayNextClassEffTimeKey)
		return
	end

	if self:FindWndEffectByKey(effect) then
		return
	end
	self:CreateWndEffect(self.mNextClassEffectRoot,effect,effect,100)

	if self:IsTimerExist(self._replayNextClassEffTimeKey) then return end
	self:TimerStart(self._replayNextClassEffTimeKey,2,false,-1)
end

function UIFlandDraw:CloseWndFunc()
	-- GF.OpenWnd("UIFairylandMain",{sid = self._sid})
	-- local mainActivityData = gModelActivity:GetActivityBySid(self._sid)
	-- if mainActivityData then
	-- 	gLxTKData:OnMainUIActivityClick(mainActivityData)
	-- end
	self:WndClose()
end


--####################################################################################################################
--### Common #########################################################################################################
--####################################################################################################################
function UIFlandDraw:Update()
	local data = gModelActivity:GetActivityBySid(self._sid)
	if not data then
		return
	end
	local leftTime = data.endTime - GetTimestamp()

	if leftTime <= 0 then
		return
	end

	local timeStr  = LUtil.FormatTimeToCn3(leftTime)
	timeStr	 = ccClientText(18701, timeStr)
	self:SetTextTile(self.mTime, timeStr)
end

--选择大奖后，将卡牌翻至背面
function UIFlandDraw:PlayAllItemOverturnBackAnim()
	self._curDrawState = self._drawState.DRAW
	local uiList = self._uiItemList
	if not uiList then return end

	self._curPlayIndex = 0
	self._curCompleteIndex = 0
	self._curPlayColumnIndex = 0
	CS.ShowObject(self.mDrawMask, true)

	self:PlayAllItemOverturnBackAnimTime()
end

function UIFlandDraw:RefreshNextClassBtn()
	CS.ShowObject(self.mNextClassBtn, self._haveBigGift)
	self:SetNextClassBtnEffect(self._haveBigGift or false)
end

function UIFlandDraw:InitData()
	self._pageId = 3 			--翻牌抽奖id
	self._func = self:GetWndArg("func")
	self._sid = self:GetWndArg("sid")
	--self._cfgDataMoreInfo = self:GetWndArg("data")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end


	-- gModelActivity:OnActivitySpecialOpReq(self._sid,self._pageId, nil, nil, "1",26)

	self._centrePoint = 18
	self._allPoint = 35
	self._drawState = {
		COMMON = 1,--展示奖励中
		DRAW   = 2,--翻牌中
		EMPTY  = 3,--空格子
	}

	self._curDrawState = self._drawState.COMMON
	self._oldDrawState = nil
	self._oldHaveBigGift = nil
	self._haveBigGift  = false
	self._bigGiftItemData = nil

	--翻牌奖励特效
	self._showDrawGiftPoint = nil
	self._haveDrawEffectPointList = {}

	--控制翻转动画
	self._isClickSelectBigGift = false
	self._showOverturnAnim = false

	--控制下一轮翻转动画
	self._showNextClassEmptyAnim = false
	self._showNextClassCommonAnim = false

	--时间枚举
	self._nextLinePlayInterval = 0.1	--播放下一列间隔时间

	self._drawType = {
		COMMON = 1,	--常驻奖励
		BIG  = 2,	--大奖
	}

	self._effectKeyList ={}
	self._effectPaths = "fx_ui_shou_2"
	self._nextClassEffectPaths = "fx_GHJN_shengji"
	self._bigGiftEffectPaths = "fx_xianjing_fanpai"

	self._playKey = "drawItemAnim"
	self._turnEmptyPlayKey = "turnEmptyAnim"
	self._turnCommonPlayKey = "turnCommonAnim"
	self._turnBackTimeKey = "turnBackTime"
	self._turnEmptyTimeKey = "turnEmptyTime"
	self._turnCommonTimeKey = "turnCommonTime"
	self._showRewardTimeKey = "showRewardTime"
	self._replayNextClassEffTimeKey = "replayNextClassEffTime"
	self._curPlayLineIndex = 1
	self._curPlayColumnIndex = 0
	self._curPlayIndex = 0
	self._curCompleteIndex = 0
	self._showRewardList = {}
	self._curGetBigGift = false

	--奖励额外信息，用于获取背包数据，来显示道具详情
	self._itemExtraDataList = {}

	self._mesFormation = "#a1#=#a2#=#a3#=0"
	self._mesEndStr = "#path=3#"
	gModelActivity:ReqActivityConfigData(self._sid)
end


function UIFlandDraw:OnActivityPageResp(pb,ret)
	if self._sid ~= pb.sid then return end

	self:ResetActivePageData(pb)
	self:SetContent()
end
--####################################################################################################################
--### Animation ######################################################################################################
--####################################################################################################################
function UIFlandDraw:InitColumnAnimFunc(curPlayKey, lineAnimFunc, completeFunc)
	local seqTween
	local showTime = 0.2	--翻转时间
	for i = 1, 5 do
		self._curPlayIndex = self._curPlayIndex + 1
		local playKey = curPlayKey..self._curPlayIndex
		self:TweenSeqKill(playKey)
		seqTween = self:TweenSeqCreate(playKey,function(seq)
			return lineAnimFunc(seq, i, showTime)
		end)
		seqTween:OnComplete(function()
			self:TweenSeqKill(playKey)
			self._curCompleteIndex = self._curCompleteIndex + 1
			completeFunc()
		end)
		seqTween:PlayForward()
	end
	self._curPlayColumnIndex = self._curPlayColumnIndex + 1
end

function UIFlandDraw:OnTimer(key)
	if key == self._turnBackTimeKey then
		self:PlayAllItemOverturnBackAnimTime()
	elseif key == self._turnEmptyTimeKey then
		self:PlayDrawOverturnEmptyAnimTimerFunc()
	elseif key == self._turnCommonTimeKey then
		self:PlayDrawOverturnCommonAnimTimerFunc()
	elseif key == self._showRewardTimeKey then
		self:TimerStop(self._showRewardTimeKey)
		if self._showRewardList and #self._showRewardList > 0 then
			gModelWndPop:TryOpenPopWnd("UIAward", {itemList = self._showRewardList})
			self._showRewardList = {}
		end
		CS.ShowObject(self.mDrawMask, false)
	elseif self._replayNextClassEffTimeKey then
		CS.ShowObject(self.mNextClassEffectRoot, false)
		CS.ShowObject(self.mNextClassEffectRoot, true)
	end
end

--####################################################################################################################
--### ItemList #######################################################################################################
--####################################################################################################################
function UIFlandDraw:InitItemList()
	self:ClearBigGiftEffect()
	local allItemsList = self:GetDrawCellItemsData()

	local uiList	 = self._uiItemList
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self, self.mItemList)
		uiList:EnableScroll(false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawCellItem(...)
		end)
		self._uiItemList = uiList
	end

	uiList:RemoveAll()
	for k,v in pairs(allItemsList) do
		uiList:AddData(k,v)
	end

	uiList:RefreshList()
end

function UIFlandDraw:GetDrawCellItemsData()
	if self._curDrawState == self._drawState.COMMON then
		--展示阶段，展示所有奖励
		local centreItemData = {}
		if self._showOverturnAnim then
			local curSelectEntryId 	= self._activityPageData.nowSuperGift
			centreItemData  		= self._bigDrawDataByEntryId[curSelectEntryId] or {}
		end
		table.insert(self._activityDrawData, self._centrePoint, centreItemData)
		return self._activityDrawData
	else
		--翻牌阶段，展示已抽到道具
		return self._roundRecordData or {}
	end
end

function UIFlandDraw:PlayDrawOverturnCommonAnimTimerFunc()
	if self._curPlayIndex >= self._allPoint then return end

	local lineAnimFunc = function(seq, lineIndex,showTime)
		return self:InitDrawOverturnCommonAnim(seq, lineIndex, showTime)
	end

	local completeFunc = function()
		if self._curCompleteIndex >= self._allPoint then
			self:TimerStop(self._turnCommonTimeKey)
			self._showNextClassCommonAnim = false
			CS.ShowObject(self.mDrawMask, false)
		end
	end

	self:InitColumnAnimFunc(self._turnEmptyPlayKey, lineAnimFunc, completeFunc)
end

--点击下一轮2， 将翻到背面的卡牌，全部翻至正面，露出奖励
function UIFlandDraw:PlayDrawOverturnCommonAnim()
	self._showNextClassEmptyAnim = false
	local uiList = self._uiItemList
	if not uiList then return end

	self._curPlayIndex = 0
	self._curCompleteIndex = 0
	self._curPlayColumnIndex = 0
	self._showNextClassCommonAnim = true

	self:PlayDrawOverturnCommonAnimTime()
end
function UIFlandDraw:OnClickDrawImg(itemPos)
	local dropReqFunc = function()
		if self._bWaitClickDropReq then
			return
		end
		self._bWaitClickDropReq = true

		self:StopClickDropTimer()
		self._delayClickDropTimer = LxTimer.DelayTimeCall(function ()
			self._bWaitClickDropReq = nil
		end, 0.15)

		self._showDrawGiftPoint = itemPos

		if not self._haveBigGift then
			self._oldHaveBigGift = false
		else
			self._oldHaveBigGif = nil
		end

		ModelActivity:OnActivityNoRepeatDropReq(2, self._sid, self._pageId, 0, itemPos)
	end

	local consumeData  	= self._consumeData
	local refId 		= consumeData.itemId
	local itemNum 		= consumeData.itemNum
	local haveNum		= gModelItem:GetNumByRefId(refId)
	local itemNameStr	= gModelItem:GetNameByRefId(refId)
	itemNameStr			= itemNameStr.."*"..itemNum

    if haveNum < itemNum then
        --道具不足
        gModelGeneral:OpenGetWayWnd({itemId = refId,srcWnd = self:GetWndName()})
        return
	elseif self._haveBigGift and self._bigGiftItemData then
        --已开出大奖
		local wndId = 110010
		local bigItem		= self._bigGiftItemData
		local bigRefId 		= bigItem.itemId
		local bigItemNum 	= bigItem.itemNum
		local bigItemNameStr = gModelItem:GetNameByRefId(bigRefId)
		bigItemNameStr		= bigItemNameStr.."*"..bigItemNum
		gModelGeneral:OpenUIOrdinTips({refId = wndId,func = dropReqFunc,para = {bigItemNameStr, itemNameStr}})
	else
        --正常开启大奖
		local wndId = 110011
		gModelGeneral:OpenUIOrdinTips({refId = wndId,func = dropReqFunc,para = {itemNameStr}})
	end
end

function UIFlandDraw:ClearBigGiftEffect()
	for k,v in pairs(self._haveDrawEffectPointList) do
		if v then
			self:DestroyWndEffectByKey(v)
		end
	end
	self._haveDrawEffectPointList = {}
end

function UIFlandDraw:ShowRewardTime()
	if self:IsTimerExist(self._showRewardTimeKey) then return end
	CS.ShowObject(self.mDrawMask, true)
	self:TimerStart(self._showRewardTimeKey,0.3,false,1)
end

function UIFlandDraw:OnClickHelp()
	local flopName = self._cfgDataMoreInfo and self._cfgDataMoreInfo.flopName
	if string.isempty(flopName) then
		flopName = 	ccClientText(18757)
	end

	GF.OpenWnd("UIBzTips",{title =flopName, para = { },text = self._cfgDataMoreInfo.flopHelpText})
end


--####################################################################################################################
--### Server #########################################################################################################
--####################################################################################################################
function UIFlandDraw:OnActivityResp(pb,ret)
	if self._sid ~= pb.sid then return end

	self:SetTop()
end
--####################################################################################################################
--### Top ############################################################################################################
--####################################################################################################################
function UIFlandDraw:SetTop()
	if not self._cfgDataMoreInfo then
		local webData = gModelActivity:GetWebActivityDataById(self._sid)
		if not webData then
			return
		end

		self._cfgDataMoreInfo 	= webData.config
	end

	local pbData = gModelActivity:GetActivityPageBySid(self._sid)
	if pbData then
		self:ResetActivePageData(pbData)
		self:InitItemList()
		self:RefreshCurClass()
	else
		gModelActivity:OnActivityPageReq(self._sid)
	end
	local flopNeedItem = self._cfgDataMoreInfo.flopNeedItem
	local consumeData  = string.split(flopNeedItem, '=')
	self._consumeData	= {
		itemType = tonumber(consumeData[1]),
		itemId = tonumber(consumeData[2]),
		itemNum = tonumber(consumeData[3]),
		effect =  tonumber(consumeData[4]),
	}

	local flopImage 	= self._cfgDataMoreInfo.flopImage
	local flopTitleIcon = self._cfgDataMoreInfo.flopTitleIcon
	local flopTitlePos 	= self._cfgDataMoreInfo.flopTitlePos
	local flopHelpPos	= self._cfgDataMoreInfo.flopHelpPos
	local flopSuperSwitchIcon = self._cfgDataMoreInfo.flopSuperSwitchIcon
	local flopSuperSwitchIconPos = self._cfgDataMoreInfo.flopSuperSwitchIconPos
	local timePos = self._cfgDataMoreInfo.timePos

	self:SetWndEasyImage(self.mBottomBgImage, flopImage, nil, true)

	self:SetWndEasyImage(self.mTopTitleImg,flopTitleIcon,nil,true)

	self:SetWndEasyImage(self.mShiftBtn,flopSuperSwitchIcon,nil,true)
	self:SetAnchorPos(self.mTopTitleImg, LxDataHelper.ParseVector2NotEmpty(flopTitlePos))
	self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(flopHelpPos))
	self:SetAnchorPos(self.mShiftBtn, LxDataHelper.ParseVector2NotEmpty(flopSuperSwitchIconPos))
	self:SetAnchorPos(self.mTime, LxDataHelper.ParseVector2NotEmpty(timePos))

	self:SetWndEasyImage(self.mShiftBtn,flopSuperSwitchIcon,nil,true)

	self:RefreshConsumeItem()

	CS.ShowObject(self.mDrawMask, false)
end

function UIFlandDraw:SetSleEffect(isShow)
	local effect = self._effectPaths
	self:DestroyWndEffectByKey(effect)
	if not isShow then return end
	self:CreateWndEffect(self.mSelEffectRoot,effect,effect,100)
end

function UIFlandDraw:PlayAllItemOverturnBackAnimTimerFunc()
	if self._curPlayIndex >= self._allPoint then return end

	local lineAnimFunc = function(seq, lineIndex,showTime)
		return self:InitItemOverturnBackAnim(seq, lineIndex, showTime)
	end

	local completeFunc = function()
		if self._curCompleteIndex >= self._allPoint then
			self._showOverturnAnim = false
			self:TimerStop(self._turnBackTimeKey)
			CS.ShowObject(self.mDrawMask, false)
		end
	end

	self:InitColumnAnimFunc(self._turnBackTimeKey, lineAnimFunc, completeFunc)
end

function UIFlandDraw:OpenSelectedBigGift()
	if self._haveBigGift then
		GF.ShowMessage(ccClientText(18716))
		return
	end

	self._isClickSelectBigGift = true
	self._oldDrawState		   = self._curDrawState
	GF.OpenWnd("UIFlandSelectGift", {
		sid = self._sid,
		data = self._activityBigDrawData,
		pageData = self._activityPageData,
		curEntryId = self._activityPageData.nowSuperGift
	})
end

function UIFlandDraw:InitItemOverturnBackAnim(seq, lineIndex, showTime)
	return self:InitDrawOverturnCommonAnim(seq, lineIndex, showTime)
end

function UIFlandDraw:ResetActivePageData(pb)
	local pageData
	for i, v in ipairs(pb.pages) do
		if v.pageId == self._pageId then
			local page= gModelActivity:GenerateActivePageDataFromPb(v)
			if page then
				pageData = page
				break
			end
		end
	end

	if not pageData then return end

	self._activityPageData = {}
	local moreInfo = JSON.decode(pageData.moreInfo)
	self._activityPageData = {
		nowSuperGift 	= moreInfo.nowSuperGift,	--当前大奖
		oldSuperGift 	= moreInfo.oldSuperGift,	--历史大奖
		roundTime 		= tonumber(moreInfo.roundTime),	--当前第几轮
		roundRecord 	= moreInfo.roundRecord,		--当前轮记录
		nowDropNum 		= moreInfo.nowDropNum,		--当前轮抽取次数
	}

	local drawState = self._drawState
	local curSelectEntryId = self._activityPageData.nowSuperGift
	local haveSelectBigDraw = curSelectEntryId ~= nil and curSelectEntryId ~= "" and curSelectEntryId ~= 0
	local curDrawState		= haveSelectBigDraw and drawState.DRAW or drawState.COMMON

	self._activityDrawData = {}
	self._drawDataByEntryId = {}
	self._activityBigDrawData = {}
	self._bigDrawDataByEntryId	= {}
	self._itemExtraDataList = {}
	self._haveBigGift 		= false
	self._curGetBigGift 	= false
	self._showOverturnAnim  = self._isClickSelectBigGift and self._oldDrawState == drawState.COMMON and curDrawState == drawState.DRAW
	if self._showOverturnAnim then
		self._curDrawState = drawState.COMMON
	else
		self._curDrawState = curDrawState
	end

	for k,v in ipairs(pageData.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		if not entryCfg then
			return
		end

		local moreInfo 		= JSON.decode(v.moreInfo)
		local type			= moreInfo.type
		local extractMaxNum = string.split(moreInfo.extractMaxNum, '=')
		local entryId		= v.entryId
		local rewardData	= entryCfg.reward
		local haveReward 	= not string.isempty(rewardData)

		local data = {
			entryId = entryId,
			items	= haveReward and LxDataHelper.ParseItem(entryCfg.reward)[1] or nil,
			sort	= entryCfg.sort,
			moreInfo = moreInfo.moreInfo,
			type	= type,
			needRound = extractMaxNum[1],
			drawNum   = extractMaxNum[2],
			hideContent = not haveReward
		}

		if type == self._drawType.COMMON then
			if self._curDrawState ~= self._drawState.COMMON then
				self._drawDataByEntryId[entryId] = data
			end
			table.insert(self._activityDrawData, data)
		else
			self._bigDrawDataByEntryId[entryId] = data
			table.insert(self._activityBigDrawData, data)
		end
	end
	--展示道具阶段，需要按顺序展示
	table.sort(self._activityDrawData,function(ref1,ref2)
		return ref1.sort < ref2.sort
	end)

	if self._curDrawState ~= self._drawState.COMMON then
		--翻牌阶段，需要设置已抽到奖励
		local roundRecordData	= {}
		local roundRecord 		= self._activityPageData.roundRecord
		local roundRecordList 	= string.split(roundRecord, '|')
		for k,v in ipairs(roundRecordList) do
			local data 		= string.split(v, ',')
			local point 	= tonumber(data[1])
			local entryId 	= tonumber(data[2])
			local itemExtraData = data[3]
			if itemExtraData then
				local itemExtraDataList = string.split(itemExtraData, '=')
				self._itemExtraDataList[entryId] = {
					itemType = tonumber(itemExtraDataList[1]),
					id   	 = itemExtraDataList[2]--tonumber(itemExtraDataList[2]),
				}
			end
			roundRecordData[point] = entryId
		end

		self._roundRecordData = {}
		for i = 1,self._allPoint do
			local entryId = roundRecordData[i]
			local drawData = {}
			if entryId then
				--有需要展示的道具
				if self._drawDataByEntryId[entryId] then
					--普通奖励
					drawData = self._drawDataByEntryId[entryId]
				elseif self._bigDrawDataByEntryId[entryId] then
					--大奖
					drawData = self._bigDrawDataByEntryId[entryId]
					self._haveBigGift = true

					if self._oldHaveBigGift == false then
						self._oldHaveBigGift = nil
						self._curGetBigGift = true
					end

					self._bigGiftItemData = drawData.items
				else
					LogError("drawData is not find, entryId = "..entryId.."; point = "..i)
				end
			end
			table.insert(self._roundRecordData, drawData)
		end

		table.insert(self._activityDrawData, self._centrePoint, {})
	end

	self._isClickSelectBigGift = false
end

function UIFlandDraw:OnDrawCellItem(list, item, itemData, itemPos)
	local contentTrans = CS.FindTrans(item, "Content")
	local emptyImg = CS.FindTrans(contentTrans, "EmptyImg")
	local questionMarkImg = CS.FindTrans(contentTrans, "QuestionMarkImg")
	local iconTrans = CS.FindTrans(contentTrans, "CommonUI/Icon")
	local IconTips = CS.FindTrans(contentTrans, "CommonUI/IconTips")
	local eff 		= CS.FindTrans(contentTrans, "Eff")

	local instanceId = item:GetInstanceID()

	local cusStatus = self._drawState.COMMON
	local items 	= itemData.items		--展示道具数据
	local isCenterPoint = itemPos == self._centrePoint
	local hideContent
	if self._curDrawState == self._drawState.COMMON then
		hideContent = itemData.hideContent or false
	else
		local cfgData = self._activityDrawData[itemPos]
		hideContent = cfgData.hideContent or false
	end

	--空格子，不展示
	CS.ShowObject(contentTrans, not hideContent)
	if hideContent then	return end

	if self._curDrawState == self._drawState.COMMON then
		if self._showNextClassEmptyAnim then
			cusStatus = self._drawState.DRAW
		elseif not items then
			cusStatus = self._drawState.EMPTY
		end
	elseif self._curDrawState == self._drawState.DRAW then
		if self._showOverturnAnim or self._showNextClassEmptyAnim then
			cusStatus = self._drawState.DRAW
		else
			cusStatus = items and self._drawState.COMMON or self._drawState.DRAW
		end
	end

	local haveSelect = self._curDrawState == self._drawState.DRAW or self._showOverturnAnim
	CS.ShowObject(emptyImg, cusStatus == self._drawState.EMPTY)
	CS.ShowObject(questionMarkImg, cusStatus == self._drawState.DRAW)
	CS.ShowObject(IconTips,  cusStatus == self._drawState.COMMON and haveSelect)
	CS.ShowObject(iconTrans, cusStatus == self._drawState.COMMON)
	if cusStatus == self._drawState.EMPTY then
		self:SetWndClick(emptyImg, function() self:OpenSelectedBigGift() end)
		--self:SetWndEasyImage(emptyImg, self._cfgDataMoreInfo.flopSelectFrame)
	elseif cusStatus == self._drawState.DRAW then
		self:SetWndEasyImage(questionMarkImg, self._cfgDataMoreInfo.flopCardIcon)
		self:SetWndClick(questionMarkImg, function()
			self:OnClickDrawImg(itemPos)
		end)
	else
		--道具数据
		local entryId	= itemData.entryId		--道具流水id
		local itemType 	= items.itemType
		local itemId	= items.itemId
		local itemNum	= items.itemNum
		local effect	= items.isShowEff
		local formatData = {itemType = itemType, itemId = itemId, itemNum = itemNum}

		local commonUIList = self._uiCommonList
		local uiIconClass = commonUIList[instanceId]
		if not uiIconClass then
			uiIconClass = CommonIcon:New()
			commonUIList[instanceId] = uiIconClass
			uiIconClass:Create(iconTrans)
		end
		uiIconClass:SetCommonReward(itemType, itemId, itemNum)

		--设置道具特效
		local show = effect ~= false
		if show and itemType == LItemTypeConst.TYPE_ITEM then
			LxResUtil.DestroyChildImmediate(eff)
			local itemRef = gModelItem:GetRefByRefId(itemId)
			local bgEff = itemRef and itemRef.bgEff or nil
			show = not string.isempty(bgEff)
			if show then
				local key = "DrawItem"..tostring(entryId)
				table.insert(self._effectKeyList,key)
				self:CreateWndEffect(eff,bgEff,instanceId,100,false,false)
			end
		end

		uiIconClass:DoApply()
		local itemExtraData = self._itemExtraDataList[entryId]
		self:SetWndClick(iconTrans,function()
			local itemTypeConst = itemExtraData and itemExtraData.itemType
			if itemTypeConst == LItemTypeConst.TYPE_RUNE then
				--符文显示详情
				local id = itemExtraData.id
				local runeData = gModelRune:GetServerDataById(id)
				local runeInfo = {runeData = runeData}
				gModelGeneral:OpenRuneInfoTip(runeInfo)
			else
				gModelGeneral:ShowCommonItemTipWnd(formatData)
			end
		end)

		local isCurDrawPoint = self._showDrawGiftPoint == itemPos
		local isOldDrawPoint = self._haveDrawEffectPointList[itemPos] ~= nil

		if isCurDrawPoint then
			--为新翻转的奖
			self:SetBifGiftEffect(true, eff, itemPos)
			self._showDrawGiftPoint = nil
			show = true
		end

		if not isOldDrawPoint then --避免特效重复播放
			CS.ShowObject(eff,show)
		end
	end
end


function UIFlandDraw:OnActivityNoRepeatDropResp(pb,ret)
	-- 应策划改动，去掉弹获得奖励框, 只有获得大奖才弹
	if pb.opera == 2 then
		local reward = pb.reward
		for k,v in ipairs(reward) do
			if self._curGetBigGift then
				local tab = {
					itype = tonumber(v.type),
					itemId = tonumber(v.itemId),
					count = tonumber(v.count),
				}
				table.insert(self._showRewardList, tab)
			else
				local itemStr = string.replace(self._mesFormation, v.type, v.itemId, v.count)
				local errMsg = tostring(itemStr..self._mesEndStr)
				FireEvent(EventNames.ON_SYS_MSG,errMsg)
			end
		end
		self:ShowRewardTime()
	end
end

function UIFlandDraw:SetBifGiftEffect(isShow, itemEffectRoot, itemPos)
	local effect = self._bigGiftEffectPaths
	local effectKey = effect..itemPos
	self:DestroyWndEffectByKey(effectKey)
	if not isShow then
		return
	end

	self._haveDrawEffectPointList[itemPos] = effectKey
	self:CreateWndEffect(itemEffectRoot,effect,effectKey,120)
end

function UIFlandDraw:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityNoRepeatDropResp, function(...)
		self:OnActivityNoRepeatDropResp(...)
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function ()
		gModelActivity:OnActivityPageReq(self._sid)
	end)

	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:RefreshConsumeItem()
	end)
end

function UIFlandDraw:InitDrawOverturnEmptyAnim(seq, lineIndex, showTime)
	local uiList = self._uiItemList
	if not uiList then return end

	local curLineIndex = self._curPlayColumnIndex
	local itemPos = curLineIndex * 5 + lineIndex
	local getDrawData = self:GetDrawCellItemsData()

	local curGetDrawData = getDrawData[itemPos]
	if curGetDrawData and curGetDrawData.items then
		local itemTrans 	= uiList:GetItemByIndex(itemPos)
		local roteY 		= itemTrans.transform:DORotate(Vector3.New(0,90,0),showTime)
		seq:Append(roteY)
		seq:AppendCallback(function()
			uiList:DrawItemByIndex(itemPos)
		end)
		local roteReset 	= itemTrans.transform:DORotate(Vector3.New(0,0,0),showTime)
		seq:Append(roteReset)
	end
	return seq
end

function UIFlandDraw:OnNextClass()
	self:ClearBigGiftEffect()
	gModelActivity:OnActivityNoRepeatDropReq(3, self._sid, self._pageId, 0, 0)
end

function UIFlandDraw:OnClickItemAddBtn()
	local refId = self._consumeData.itemId
	gModelGeneral:OpenGetWayWnd({itemId = refId,srcWnd = self:GetWndName()})
end

--点击下一轮2， 将翻到背面的卡牌，全部翻至正面，露出奖励
function UIFlandDraw:PlayDrawOverturnCommonAnimTime()
	self:PlayDrawOverturnCommonAnimTimerFunc()
	self:TimerStart(self._turnCommonTimeKey,self._nextLinePlayInterval,false,-1)
end

function UIFlandDraw:OpenShowAllGift()
	GF.OpenWnd("UIFlandSurplus",{
		sid = self._sid,
		--pageData = self._activityPageData,
		--drawData = self._activityDrawData,
		--bigDrawData = self._activityBigDrawData,
	})
end

function UIFlandDraw:ResetDrawCellItemByItemPos(itempos)
	local uiList	 = self._uiItemList
	if not uiList then
		self:InitItemList()
	else
		local allItemsList = self:GetDrawCellItemsData()
		uiList:SetDataByIndex(itempos,allItemsList[itempos])
		uiList:DrawItemByIndex(itempos)
	end
end

--点击下一轮，将卡牌翻至背面
function UIFlandDraw:PlayDrawOverturnEmptyAnim()
	local uiList = self._uiItemList
	if not uiList then return end

	self._curPlayIndex = 0
	self._curCompleteIndex = 0
	self._curPlayColumnIndex = 0
	self._showNextClassEmptyAnim = true
	CS.ShowObject(self.mDrawMask, true)

	self:PlayDrawOverturnEmptyAnimTime()
end

function UIFlandDraw:ClearEffectKeyList()
	if not self._effectKeyList then return end
	for k,v in pairs(self._effectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._effectKeyList={}
end

function UIFlandDraw:RefreshConsumeItem()
	local refId = self._consumeData.itemId
	local icon = gModelItem:GetItemIconByRefId(refId)
	self:SetWndEasyImage(self.mConsumeItemIcon,icon)
	local num = gModelItem:GetNumByRefId(refId)
	num = LUtil.NumberCoversion(num)
	self:SetWndText(self.mConsumeItemNum,num)
end

--#####################################################################################################################
--## time #############################################################################################################
--#####################################################################################################################
--选择大奖后，将卡牌翻至背面
function UIFlandDraw:PlayAllItemOverturnBackAnimTime()
	self:PlayAllItemOverturnBackAnimTimerFunc()
	self:TimerStart(self._turnBackTimeKey,self._nextLinePlayInterval,false,-1)
end

------------------------------------------------------------------
return UIFlandDraw