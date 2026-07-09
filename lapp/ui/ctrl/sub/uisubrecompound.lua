---
--- Created by Administrator.
--- DateTime: 2024/4/2 15:17:51
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubReCompound:LChildWnd
local UISubReCompound = LxWndClass("UISubReCompound", LChildWnd)
local UIBtnTabList = LXImport('LApp.UI.Common.UIBtnTabList')

UISubReCompound.RUNE_MAX_NUM = 5				-- 符文数量
UISubReCompound.RUNE_SHOWCENTER_NUM = 2			-- 合成最少需要的数量
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubReCompound:UISubReCompound()
	self._runeQuality = 1
	---@type UIBtnTabList
	self._uiBtnTabList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubReCompound:OnWndClose()
	if self._func then self._func() end
	self:RunCompoundAni()
	if self._uiBtnTabList then
		self._uiBtnTabList:Destroy()
		self._uiBtnTabList = nil
	end
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubReCompound:OnCreate()
	LChildWnd.OnCreate(self)
	self._spinePeopelKey = "Fuwen_maerjina"
	self._runRuneCompoundAniKey = "runRuneCompoundAniKey"
	self._runRuneCompoundAniTimeKey = "runRuneCompoundAniTimeKey"
	self._sendMsg = false
	self._spineAniTimes = 1.6
	self._compoundAniKey = "_compoundAniKey"
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubReCompound:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEmptyList()
	CS.ShowObject(self.mCenterRuneIcon,false)
	self:CreateWndSpine(self.mSpineRoot,self._spinePeopelKey,self._spinePeopelKey)
	self:InitText()
	self:InitRuneQualityTabList()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshBar()
	self:InitShowItemList()
	self:InitRuneList()
	self:RefreshSelNum()
	self:RefreshChangeSelRune()
	self:UpdateScreen()

	self:SetSecretJumpBtn(self.mBtnSecret,6)
end

function UISubReCompound:AddItemEvent(refId)
	gModelGeneral:OpenGetWayWnd({itemId = refId,srcWnd = self:GetWndName()})
end

function UISubReCompound:OnClickCompoundBtnFunc()
	if self._sendMsg then return end
	local selRuneRefId = self._selRuneRefId
	if not selRuneRefId then
		GF.ShowMessage(ccClientText(24936))
		return
	end
	local selRuneNum = self._selRuneNum
	local selRuneList = self._selRuneList
	if not selRuneList then
		selRuneList = {}
		self._selRuneList = selRuneList
	end
	local compoundList = {}
	for k,v in pairs(selRuneList) do
		table.insert(compoundList,{
			id = v.id,
			refId = v.refId,
			limitId = v.limitId,
			itemType = v.itemType,
			runeRefId = v.runeRefId
		})
	end
	local len = #compoundList
	if len < self._minSelNum then
		GF.ShowMessage(ccClientText(13251))
		return
	end
	local compoundRef = gModelRune:GetRuneComposeRef(selRuneRefId,len)
	if not gModelFunctionOpen:CheckIsOpened(compoundRef.needLevel, true) then
		return
	end
	if not compoundRef then return end
	local runeDataList = {}
	local tipQuality = gModelRune:GetConfig("tipQuality")
	local isUpQuality = false
	local itemType = LItemTypeConst.TYPE_RUNE
	local list = {}
	local itemKeyList = {}
	local runeRefId,selItemType
	for i,v in ipairs(compoundList) do
		selItemType = v.itemType
		if selItemType == LItemTypeConst.TYPE_ITEM then
			runeRefId = v.runeRefId
		elseif selItemType == LItemTypeConst.TYPE_RUNE then
			runeRefId = v.refId
		end
		local id = v.id
		if not isUpQuality then
			local quality = gModelRune:GetRuneQualityByRefId(runeRefId)
			isUpQuality = quality >= tipQuality
		end

		if selItemType == LItemTypeConst.TYPE_ITEM then
			local itemRefId = v.refId
			local itemKeyInfo = itemKeyList[itemRefId] or 0
			itemKeyList[itemRefId] = itemKeyInfo + 1
			table.insert(runeDataList,{
				itype = selItemType,
				refId = v.refId,
				hideNum = true,
				id = id,
				count = 1
			})
		elseif selItemType == LItemTypeConst.TYPE_RUNE then
			table.insert(list,id)
			table.insert(runeDataList,{
				itype = itemType,
				refId = runeRefId,
				hideNum = true,
				id = id,
				limitId = v.limitId,
				count = 1
			})
		end
	end
	local itemList = {}
	for refId,num in pairs(itemKeyList) do
		table.insert(itemList,{
			refId = refId,
			num = num,
		})
	end
	local func = function()
		local compoundSplitRef = gModelRune:GetRuneComposeInfoByCompoundRefIdAndComnpoundNum(selRuneRefId,selRuneNum)
		if not compoundSplitRef then return end
		local composeNeedGlod = compoundSplitRef.composeNeedGlod or {}
		local itemId,itemNum = composeNeedGlod.itemId,composeNeedGlod.itemNum
		if not itemId or not itemNum then return end
		local haveNum = gModelItem:GetNumByRefId(itemId)
		if haveNum >= itemNum then
			gModelRune:OnRuneCompoundReq(list,itemList)
			self._sendMsg = true
		else
			gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
		end
	end
	local isFull = len == self._maxSelNum
	if isUpQuality and (not isFull) then
		--local name = gModelRune:GetRuneNameByRefId(selRuneRefId)
		local name = gModelRune:GetRuneNameByRefIdNew(selRuneRefId)
		local rate = compoundRef.rate
		local rateStr = rate * 100 .. "%"
		local color = gModelGeneral:GetCommonItemColor({itemType = itemType,itemId = selRuneRefId})
		local infoName = name .. "*" .. len
		local colorName = LUtil.FormatColorStr(infoName,color)
		gModelGeneral:OpenUIOrdinTips({refId = 52403,func = func,para = {colorName,rateStr},itemList = runeDataList},true)
	else
		func()
	end
end

function UISubReCompound:ShowIconEff(show)
	local runeIconRootList = self._runeIconRootList or {}
	for i,v in ipairs(runeIconRootList) do
		CS.ShowObject(v,show)
	end
end

function UISubReCompound:OnClickGetRuneBtnFunc()
	local jumpItem = gModelRune:GetConfig("jumpItem")
	gModelGeneral:OpenGetWayWnd({itemId = jumpItem,srcWnd = self:GetWndName()})
end

function UISubReCompound:ShowMoveEff(show)
	local moveEffRootList = self._moveEffRootList or {}
	for i,v in ipairs(moveEffRootList) do
		CS.ShowObject(v,show)
	end
end

function UISubReCompound:OnClickAutoSelBtnFunc()
	if self._sendMsg then return end
	local canSelRuneNum = self._canSelRuneNum
	local selRuneList = self._selRuneList
	if not selRuneList then
		selRuneList = {}
		self._selRuneList = selRuneList
	end
	local addNum = 0
	local tSelRuneList = {}
	if canSelRuneNum < self._selRuneNum then
		-- 先排序，保证选中符文的顺序是按照从低到高的
		local tempList = {}
		for k,v in pairs(selRuneList) do
			table.insert(tempList,v)
		end
		tempList = self:SortRuneList(tempList)

		for k,v in ipairs(tempList) do
			if addNum >= canSelRuneNum then break end
			if not self._selRuneRefId then
				self._selRuneRefId = v.refId
			end
			addNum = addNum + 1
			table.insert(tSelRuneList,v)
		end
		tSelRuneList = self:SortRuneList(tSelRuneList)
		selRuneList = {}
	else
		selRuneList = {}
		self._selRuneList = selRuneList
		local runeList = {}
		local list = self:GetRuneList()
		local runeRefId,itemType
		for i,v in ipairs(list) do
			itemType = v.itemType
			if itemType == LItemTypeConst.TYPE_ITEM then
				runeRefId = v.runeRefId
			else
				runeRefId = v.refId
			end
			local runeRef = gModelRune:GetRuneInfoByRefId(runeRefId)
			if runeRef then
				local quality = runeRef.quality
				local listData = runeList[quality]
				if not listData then
					listData = {}
					runeList[quality] = listData
				end
				table.insert(listData,v)
			end
		end

		local minList = {}
		for quality,qualityList in pairs(runeList) do
			local haveNum = #qualityList
			minList[quality] = haveNum
		end

		local minQua = 99
		for k,v in pairs(minList) do
			if v >= canSelRuneNum and v >= self._minSelNum and minQua > k then
				minQua = k
			end
		end

		if minQua == 99 then
			for k,v in pairs(minList) do
				if v >= self._minSelNum and minQua > k then
					minQua = k
				end
			end
		end

		self._selRuneRefId = nil
		local qualityList = runeList[minQua] or {}
		local qualityLen = #qualityList
		if qualityLen > 0 then
			local len = 0
			for i,v in ipairs(qualityList) do
				if len >= canSelRuneNum then break end
				local runeId = v.id
				local isSel = self:CheckRuneIsSel(runeId)
				if not isSel then
					if not self._selRuneRefId then
						itemType = v.itemType
						if itemType == LItemTypeConst.TYPE_ITEM then
							runeRefId = v.runeRefId
						else
							runeRefId = v.refId
						end
						self._selRuneRefId = runeRefId
					end
					addNum = addNum + 1
					table.insert(tSelRuneList,v)
					len = len + 1
				end
			end
		end
	end
	for i,v in ipairs(tSelRuneList) do
		selRuneList[v.id] = v
	end
	self._selRuneList = selRuneList
	self._selRuneNum = addNum
	if addNum == 0 then
		GF.ShowMessage(ccClientText(13206))
	end

	self:InitRuneList(true)
	self:RefreshChangeSelRune()
end

function UISubReCompound:OnRuneCompoundResp(pb)
	local result = pb.result
	local itemList = {}
	if result == 1 then
		local data = {
			itype = LItemTypeConst.TYPE_RUNE,
			itemId = pb.runeId,
			count = 1,
		}
		table.insert(itemList,data)
	else
		local rewards = pb.rewards
		for i = 1,#rewards do
			local reward = rewards[i]
			local data = {
				itype = reward.type,
				itemId = reward.itemId,
				count = reward.count
			}
			table.insert(itemList,data)
		end
	end

	local refreshFunc = function()
		if not self:IsWndValid() then return end
		self:InitInfoData()
		self:RefreshBar()
		self:RefreshChangeSelRune()
		self:InitRuneList()
		self._sendMsg = false
	end

	self._animationEndCall = function()
		refreshFunc()
		gModelWndPop:TryOpenPopWnd("UIAward",{itemList = itemList,callBackFunc = refreshFunc})
	end

	self:RuneCompoundEff()

	self:TimerStop(self._runRuneCompoundAniTimeKey)
	self:TimerStart(self._runRuneCompoundAniTimeKey,self._spineAniTimes,true,1)
end

function UISubReCompound:GetPayNum()
	local itemId,itemNum,rate = nil,0,0
	local selRuneNum = self._selRuneNum
	local selRuneRefId = self._selRuneRefId
	local showGetIcon
	print(selRuneNum)
	print(self._minSelNum)
	print(selRuneRefId)
	if selRuneNum >= self._minSelNum and selRuneRefId then
		local ref = gModelRune:GetRuneComposeInfoByCompoundRefIdAndComnpoundNum(selRuneRefId,selRuneNum)
		if ref then
			local composeNeedGlod = ref.composeNeedGlod
			itemId = composeNeedGlod.itemId
			itemNum = composeNeedGlod.itemNum
			rate = ref.rate
			local showGet = ref.showGet
			local showGetItemId = showGet.itemId
			local showItemType = showGet.itemType
			if showItemType == LItemTypeConst.TYPE_ITEM then
				showGetIcon = gModelItem:GetItemIconByRefId(showGetItemId)
			elseif showItemType == LItemTypeConst.TYPE_RUNE then
				showGetIcon = gModelRune:GetRuneImgByRefId(showGetItemId)
			end
		end
	end
	return itemId,itemNum,rate,showGetIcon
end

function UISubReCompound:InitShowItemList()
	local list = gModelRune:GetShowItemList()
	local uiNeedList = self._uiNeedList
	if uiNeedList then
		uiNeedList:RefreshData(list)
	else
		uiNeedList = self:GetUIScroll("uiNeedList")
		self._uiNeedList = uiNeedList
		uiNeedList:Create(self.mNeedItemList,list,function(...) self:OnDrawNeedItemCell(...) end)
	end
end

function UISubReCompound:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RuneMeltingResp,function()
		self:InitRuneList()
		self:RefreshBar()
	end)
	self:WndNetMsgRecv(LProtoIds.ChangeRuneResp,function(pb,ret)
		if self._sendMsg then return end
		self:InitRuneList()
	end)
	self:WndNetMsgRecv(LProtoIds.RuneCompoundResp,function(pb,ret)
		self:OnRuneCompoundResp(pb)
		self:RefreshUiBtnTabList()
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:InitShowItemList()
		self:RefreshConsume()
		self:RefreshUiBtnTabList()
	end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function()
		self._func = nil
	end)
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
		self._sendMsg = false
	end)
	self:WndEventRecv(EventNames.GAME_SCREEN_RESETSIZE, function()
		self:UpdateScreen()
	end)
end

function UISubReCompound:OnTcpReconnect()
	self._sendMsg = false
	local state = self:RunCompoundAni()
	if not state then
		self:InitInfoData()
		self:RefreshBar()
		self:RefreshChangeSelRune()
		self:InitRuneList()
	end
end

function UISubReCompound:RefreshConsume()
	local successStr = ""
	local needStr = "0"
	local itemId,itemNum,rate,centerIcon = self:GetPayNum()
	if itemId and itemNum and rate then
		local icon = gModelItem:GetItemIconByRefId(itemId)
		self:SetWndEasyImage(self.mPayImg,icon)

		local haveNum = gModelItem:GetNumByRefId(itemId)
		local color = haveNum >= itemNum and "#68E6AC" or "red"

		needStr = LUtil.FormatColorStr(LUtil.NumberCoversion(itemNum),color)

		successStr = string.replace(ccClientText(13257),rate * 100)

	end
	local isShowCenter = centerIcon ~= nil
	if isShowCenter then
		printInfoNR("=============")
		self:SetWndEasyImage(self.mCenterRuneIcon,centerIcon)
	end
	CS.ShowObject(self.mCenterRuneIcon,isShowCenter)
	CS.ShowObject(self.mSuccessNum.parent,successStr ~= "")
	self:SetWndText(self.mSuccessNum,successStr)
	self:SetWndText(self.mPayNumTxt,needStr)
end

function UISubReCompound:InitRuneList(refreshData)
	local list = self:GetRuneList()
	local uiRuneList = self._uiRuneList
	if uiRuneList then
		uiRuneList:RefreshList(list)
		uiRuneList:DrawAllItems()
		if not refreshData then
			uiRuneList:MoveToPos(0)
		end
		--if refreshData then
		--	uiRuneList:RefreshData(list)
		--else
		--	uiRuneList:RefreshList(list)
		--	local uiList = uiRuneList:GetList()
		--	uiList:RefreshList(UIListWrap.RefreshMode.Solid)
		--end
	else
		uiRuneList = self:GetUIScroll("uiRuneList")
		self._uiRuneList = uiRuneList
		uiRuneList:Create(self.mRuneList,list,function(...) self:OnDrawRuneCell(...)  end,UIItemList.SUPER_GRID)
	end
	local isEmpty = #list < 1
	CS.ShowObject(self.mNoRecord2,isEmpty)
end

function UISubReCompound:SelRuneInfo(itemdata,isCell)
	local runeId = itemdata.id
	local isSel = self:CheckRuneIsSel(runeId)
	local optNum = isSel and -1 or 1
	local newOptNum = self._selRuneNum + optNum
	if isCell then
		if newOptNum > self._maxSelNum then
			GF.ShowMessage(ccClientText(13242))
			return
		end
	else
		if newOptNum > self._canSelRuneNum then
			GF.ShowMessage(ccClientText(13242))
			return
		end
	end
	local selRuneList = self._selRuneList
	if not selRuneList then
		selRuneList = {}
		self._selRuneList = selRuneList
	end
	if isSel then
		selRuneList[runeId] = nil
	else
		selRuneList[runeId] = itemdata
	end
	self._selRuneNum = newOptNum
	if newOptNum == 0 then
		self._selRuneRefId = nil
	elseif not self._selRuneRefId then
		local selRuneRefId
		local itemType = itemdata.itemType
		if itemType == LItemTypeConst.TYPE_RUNE then
			selRuneRefId = itemdata.refId
		else
			selRuneRefId = itemdata.runeRefId
		end
		self._selRuneRefId = selRuneRefId
	end
end

function UISubReCompound:RunCompoundAni()
	local runState = false
	local animationEndCall = self._animationEndCall
	if animationEndCall then
		runState = true
		animationEndCall()
	end
	self._animationEndCall = nil
	return runState
end

function UISubReCompound:RefreshBar()
	local haveNum,needNum = gModelRune:GetHaveNumOrNeedNum()
	local txt = string.format("%s/%s",haveNum,needNum)
	self:SetWndText(self.mJDNum,txt)
	local showBox = true
	local effectKey = "fx_equip_exchange"
	local showEff = haveNum >= needNum
	if showEff then
		showBox = false
		self:CreateWndEffect(self.mBoxEffRoot,effectKey,effectKey,100,false,false)
	else
		self:DestroyWndEffectByKey(effectKey)
	end
	CS.ShowObject(self.mBoxItemImg,showBox)
	CS.ShowObject(self.mBoxRedPoint,showEff)

	local percentage = haveNum/needNum
	LxUiHelper.SetProgress(self.mJDBar,percentage)
end

function UISubReCompound:SortRuneList(list)
	table.sort(list,function(a,b)
		local itemTypeA,itemTypeB = a.itemType,b.itemType
		local refIdA = a.refId or a._refId
		local refIdB = b.refId or b._refId
		if itemTypeA == itemTypeB and itemTypeA == LItemTypeConst.TYPE_ITEM then
			if a.runeRefId ~= b.runeRefId then
				return refIdA < refIdB
			else
				return a.index < b.index
			end
		end
		if itemTypeA == itemTypeB and itemTypeA == LItemTypeConst.TYPE_RUNE then
			local qua1,qua2 = gModelRune:GetRuneQualityByRefId(refIdA),gModelRune:GetRuneQualityByRefId(refIdB)
			if qua1 ~= qua2 then
				return qua1 < qua2
			end
			local showStarA,showStarB = gModelRune:GetShowStarByRefId(refIdA) or 0,gModelRune:GetShowStarByRefId(refIdA) or 0
			if showStarA ~= showStarB then
				return showStarA < showStarB
			end
			local scoreA,scoreB = a._score or a.score,b._score or b.score
			return scoreA < scoreB
		end
		if itemTypeA ~= itemTypeB then
			if itemTypeA == LItemTypeConst.TYPE_ITEM then
				refIdA = a.runeRefId
			end
			if itemTypeB == LItemTypeConst.TYPE_ITEM then
				refIdB = b.runeRefId
			end
			if refIdA ~= refIdB then
				return refIdA < refIdB
			else
				return itemTypeA < itemTypeB
			end
		end
		return false
	end)
	return list
end

function UISubReCompound:OnDrawNeedItemCell(list,item,itemdata,itempos)
	local IconTrans = self:FindWndTrans(item,"Icon")
	local NumTrans = self:FindWndTrans(item,"Num")
	local AddBtnTrans = self:FindWndTrans(item,"BtnDiv/AddBtn")
	local refId = itemdata.itemId
	if IconTrans then
		local icon = gModelItem:GetItemIconByRefId(refId)
		self:SetWndEasyImage(IconTrans,icon)
	end
	if NumTrans then
		local haveNum = gModelItem:GetNumByRefId(refId)
		haveNum = LUtil.NumberCoversion(haveNum)
		self:SetWndText(NumTrans,haveNum)
	end
	if AddBtnTrans then
		self:SetWndClick(AddBtnTrans,function()
			self:AddItemEvent(refId)
		end)
	end
end

function UISubReCompound:RefreshSelInfo()
	local selRuneList = self._selRuneList
	local selList = {}
	for k,v in pairs(selRuneList) do
		table.insert(selList,v)
	end
	table.sort(selList,function(a,b)
		return a.id < b.id
	end)
	local runeTransList = self._runeTransList
	for i,v in ipairs(runeTransList) do
		self:CreateSelRuneInfo(v,selList[i])
	end
end

function UISubReCompound:OnClickSelRuneFunc(itemdata,itempos)
	local itemType = itemdata.itemType
	local runeRefId
	if itemType == LItemTypeConst.TYPE_RUNE then
		runeRefId = itemdata.refId
	elseif itemType == LItemTypeConst.TYPE_ITEM then
		runeRefId = itemdata.runeRefId
	end
	if self._selRuneRefId and self._selRuneRefId ~= runeRefId then
		GF.ShowMessage(ccClientText(13241))
		return
	end
	self:SelRuneInfo(itemdata,true)
	local uiRuneList = self._uiRuneList
	if uiRuneList then
		uiRuneList:DrawItemByIndex(itempos)
	end
	self:RefreshChangeSelRune()
end

function UISubReCompound:RefreshSelNum()
	local canSelRuneNum = self._canSelRuneNum
	self:SetWndText(self.mSelRuneNum,canSelRuneNum)
end

function UISubReCompound:InitText()
	self:SetWndText(self.mXHTxt,ccClientText(24929))
	-- self:SetTextTile(self.mReturnBtn,ccClientText(10320))
	self:SetTextTile(self.mSkillPreBtn,ccClientText(13205) ,-30)
	self:SetTextTile(self.mGetRuneBtn,ccClientText(13277), -30)
	self:SetWndButtonText(self.mAutoSelBtn,ccClientText(13204))
	self:SetWndButtonTextLine(self.mAutoSelBtn, -30)
	self:SetWndButtonText(self.mCompoundBtn,ccClientText(11316))
	self:SetWndButtonTextLine(self.mCompoundBtn, -30)
end

function UISubReCompound:OnTimer(key)
	if key == self._runRuneCompoundAniTimeKey then
		self:RunCompoundAni()
	end
	--self:TimerStop(key)
end

function UISubReCompound:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndCloseAndBack() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mSubBtn,function() self:OnClickChangeRuneNum(-1) end)
	self:SetWndClick(self.mAddBtn,function() self:OnClickChangeRuneNum(1) end)
	self:SetWndClick(self.mBox,function() GF.OpenWnd("UIReMelting") end)
	self:SetWndClick(self.mAutoSelBtn,function() self:OnClickAutoSelBtnFunc() end)
	self:SetWndClick(self.mCompoundBtn,function() self:OnClickCompoundBtnFunc() end)
	self:SetWndClick(self.mGetRuneBtn,function() self:OnClickGetRuneBtnFunc() end)
	self:SetWndClick(self.mSkillPreBtn,function() self:OnClickSkillPreBtnFunc() end)
	self:SetWndClick(self.mHelpTipBtn,function() GF.OpenWnd("UIBzTips",{refId = 25}) end)
end

function UISubReCompound:ShowCompoundEff(show)
	local runeCompoundEffRootList = self._runeCompoundEffRootList or {}
	for i,v in ipairs(runeCompoundEffRootList) do
		CS.ShowObject(v,show)
	end
end

function UISubReCompound:RefreshUiBtnTabList()
	if not self._uiBtnTabList then return end
	self._uiBtnTabList:RefreshTabScroll()
end

function UISubReCompound:InitRuneQualityTabList()
	local recordMap = {}
	local dataList = {}
	for k,v in pairs(GameTable.MagicRuneRef) do
		if not recordMap[v.quality] and gModelRune:CheckIsCanCompose(k) then
			table.insert(dataList,{
				quality = v.quality,
				btnType = v.quality,
				refId = k,
				btnName = ccLngText(v.name),
				clickFunc = function(itemdata)
					self._runeQuality = itemdata.quality
					self:InitRuneList()
				end,
				checkRPFunc = function(itemdata)
					return gModelRune:CheckRuneCompoundRPByQuality(itemdata.quality)
				end,
				specialReduceSize = -4,
			})
			recordMap[v.quality] = true
		end
	end

	table.sort(dataList,function(a, b) return a.quality < b.quality end)
	local selQuality
	for i,v in ipairs(dataList) do
		if v.checkRPFunc and v.checkRPFunc(v) then
			selQuality = v.quality
			break
		end
	end
	selQuality = selQuality or dataList[1].quality
	self._runeQuality = selQuality
	---@type UIBtnTabList
	self._uiBtnTabList = UIBtnTabList:New()
	self._uiBtnTabList:SetData(self,self.mTabBtnList,dataList,self._runeQuality)
end

function UISubReCompound:OnClickSkillPreBtnFunc()
	GF.OpenWnd("UIReJNPreView")
	--self:RuneCompoundEff()
end

function UISubReCompound:OnClickChangeRuneNum(optNum)
	local oldNum = self._canSelRuneNum
	local newNum = oldNum + optNum
	if newNum > self._maxSelNum or newNum < self._minSelNum then
		return
	end
	self._canSelRuneNum = newNum
	self:RefreshSelNum()
end

function UISubReCompound:InitSelRuneEffRoot()
	local yuanEffName = "fx_ui_meiriyunshi_zhanbu_03"
	local compoundEffName = "fx_ui_fuwenhecheng"
	local moveEffName = "fx_ui_fuwenhecheng_3"

	local position
	local CenterRuneEffRoot = self.mCenterRuneEffRoot
	self:CreateWndEffect(CenterRuneEffRoot,yuanEffName,CenterRuneEffRoot:GetInstanceID(),60,false,false)
	position = CenterRuneEffRoot.localPosition
	CenterRuneEffRoot.localPosition = Vector3(position.x,-75,position.z)


	local RuneEffRootTrans,CompoundEffRootTrans,RuneIconTrans
	local runeEffInstanceID,runeCompoundEffInstanceID
	local runeEffRootList = {}
	local runeCompoundEffRootList = {}
	local runeIconRootList = {}
	for i,v in ipairs(self._runeTransList) do
		RuneEffRootTrans = self:FindWndTrans(v,"RuneEffRoot")
		runeEffInstanceID = RuneEffRootTrans:GetInstanceID()
		self:CreateWndEffect(RuneEffRootTrans,yuanEffName,runeEffInstanceID,60,false,false)
		position = RuneEffRootTrans.localPosition
		RuneEffRootTrans.localPosition = Vector3(position.x,-75,position.z)
		table.insert(runeEffRootList,RuneEffRootTrans)

		CompoundEffRootTrans = self:FindWndTrans(v,"CompoundEffRoot")
		runeCompoundEffInstanceID = CompoundEffRootTrans:GetInstanceID()
		self:CreateWndEffect(CompoundEffRootTrans,compoundEffName,runeCompoundEffInstanceID,100,false,false)
		table.insert(runeCompoundEffRootList,CompoundEffRootTrans)

		RuneIconTrans = self:FindWndTrans(v,"RuneIcon")
		table.insert(runeIconRootList,RuneIconTrans)
	end
	self._runeEffRootList = runeEffRootList
	self._runeCompoundEffRootList = runeCompoundEffRootList
	self._runeIconRootList = runeIconRootList

	local MoveRootInstanceID
	local moveEffRootList = {
		self.mMoveRoot1,self.mMoveRoot2,self.mMoveRoot3,self.mMoveRoot4,self.mMoveRoot5
	}
	local moveEffRootPosList = {}
	for i,v in ipairs(moveEffRootList) do
		MoveRootInstanceID = v:GetInstanceID()
		self:CreateWndEffect(v,moveEffName,MoveRootInstanceID,100,false,false)
		table.insert(moveEffRootPosList,v.localPosition)
	end
	self._moveEffRootList = moveEffRootList
	self._moveEffRootPosList = moveEffRootPosList

	local centerEffName = "fx_ui_fuwenhecheng_2"
	self:CreateWndEffect(self.mCenterCompoundEffRoot,centerEffName,centerEffName,100,false,false)
end

function UISubReCompound:RuneCompoundEff()
	local dpSpine = self:FindWndSpineByKey(self._spinePeopelKey)
	if dpSpine:IsDpValid() then
		dpSpine:PlayAnimation(0,"attack",false)
	end
	self:InitMoveRootPos()
	local moveEffRootList = self._moveEffRootList or {}
	local centerTrans = self.mCenterCompoundEffRoot
	local seqTween
	self:TweenSeqKill(self._compoundAniKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._compoundAniKey,function(seq)
			local showCompoundTime = 0.7
			local showMoveTime = 0.3
			seq:AppendInterval(0.1)
			seq:AppendCallback(function()
				self:ShowCompoundEff(true)
			end)
			seq:AppendInterval(showCompoundTime)
			seq:AppendCallback(function()
				self:ShowCompoundEff(false)
				self:ShowIconEff(false)
				self:ShowMoveEff(true)
			end)
			local localPosition = centerTrans.position
			for i,v in ipairs(moveEffRootList) do
				local moveTween = v.transform:DOLocalMove(localPosition,showMoveTime)
				seq:Join(moveTween)
			end
			seq:AppendCallback(function()
				self:ShowMoveEff(false)
				CS.ShowObject(centerTrans,true)
			end)
			seq:AppendInterval(0.1)
			seq:AppendCallback(function()
				self:InitMoveRootPos()
			end)
			seq:AppendInterval(showMoveTime)
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		CS.ShowObject(centerTrans,false)
		self:TweenSeqKill(self._compoundAniKey)
		dpSpine:PlayAnimation(0,"idle",true)
	end)
end

function UISubReCompound:InitEmptyList()
	local data = {
		refId = 5102,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
end

function UISubReCompound:OnDrawRuneCell(list,item,itemdata,itempos)
	local CommonUI = self:FindWndTrans(item,"CommonUI")
	local Icon = self:FindWndTrans(CommonUI,"Icon")
	local SelImg = self:FindWndTrans(item,"SelImg")
	local itemType = itemdata.itemType
	local runeId = itemdata.id
	local isSel = self:CheckRuneIsSel(runeId)
	CS.ShowObject(SelImg,isSel)

	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(Icon)
	if itemType == LItemTypeConst.TYPE_RUNE then
		baseClass:SetRuneData(itemdata)
	else
		baseClass:SetCommonReward(itemdata.itemType,itemdata.refId,itemdata.num)
		baseClass:EnableShowNum(false)
	end
	baseClass:DoApply()
	self:SetIconClickScale(Icon, true)

	self:SetWndClick(Icon,function()
		if itemType == LItemTypeConst.TYPE_RUNE then
			printInfoNR("=== 符文")
		else
			printInfoNR("=== 道具")
		end
		self:OnClickSelRuneFunc(itemdata,itempos)
	end)
	self:SetWndLongClick(Icon,function()
		if itemType == LItemTypeConst.TYPE_RUNE then
			local data = {
				runeData = itemdata
			}
			gModelGeneral:OpenRuneInfoTip(data)
		else
			printInfoNR("=== 道具")
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end
	end)
end

function UISubReCompound:CreateSelRuneInfo(trans,itemdata)
	local AddBtn = self:FindWndTrans(trans,"AddBtn")
	local RuneIcon = self:FindWndTrans(trans,"RuneIcon")
	local isHave = itemdata ~= nil
	CS.ShowObject(AddBtn,not isHave)
	CS.ShowObject(RuneIcon,isHave)

	if isHave then
		local itemType = itemdata.itemType
		local refId = itemType == LItemTypeConst.TYPE_RUNE and itemdata.refId or itemdata.runeRefId
		local icon = gModelRune:GetRuneImgByRefId(refId)
		self:SetWndEasyImage(RuneIcon,icon)
	end

	self:SetWndClick(RuneIcon,function()
		if not isHave then return end
		self:SelRuneInfo(itemdata)
		self:RefreshChangeSelRune()
		self:InitRuneList(true)
	end)
	self:SetWndLongClick(RuneIcon,function()
		if not isHave then return end
		local itemType = itemdata.itemType
		if itemType == LItemTypeConst.TYPE_RUNE then
			local data = {
				runeData = itemdata
			}
			gModelGeneral:OpenRuneInfoTip(data)
		else
			printInfoNR("=== 道具")
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end
	end)
end

function UISubReCompound:GetRuneList()
	local list = gModelRune:GetCompoundRuneList(self._runeQuality)
	list = self:SortRuneList(list)
	return list
end

function UISubReCompound:CheckRuneIsSel(runeId)
	local selRuneList = self._selRuneList
	if not selRuneList then
		selRuneList = {}
		self._selRuneList = selRuneList
	end
	return selRuneList[runeId] ~= nil
end

function UISubReCompound:InitInfoData()
	self._selRuneList = {}							-- 已选择符文列表
	self._selRuneNum = 0							-- 已选择符文数量
	self._selRuneRefId = nil
end

function UISubReCompound:UpdateScreen()
	--local height = UnityEngine.Screen.height / UnityEngine.Screen.width * 268
	--self.mBot.sizeDelta = Vector2.New(self.mBot.rect.width, height)
end

function UISubReCompound:InitData()
	self._maxSelNum = UISubReCompound.RUNE_MAX_NUM					-- 最大选择的数量
	self._minSelNum = UISubReCompound.RUNE_SHOWCENTER_NUM				-- 最少选择的数量
	self._canSelRuneNum = UISubReCompound.RUNE_MAX_NUM				-- 可以选择的符文数量
	self._runeTransList = {
		self.mRune1,self.mRune2,self.mRune3,self.mRune4,self.mRune5,
	}
	self:InitSelRuneEffRoot()
	self:InitInfoData()
end

function UISubReCompound:RefreshChangeSelRune()
	self:RefreshConsume()
	self:RefreshSelInfo()
end

function UISubReCompound:InitMoveRootPos()
	local moveEffRootList = self._moveEffRootList or {}
	local moveEffRootPosList = self._moveEffRootPosList or {}
	for i,v in ipairs(moveEffRootList) do
		v.localPosition = moveEffRootPosList[i] or Vector3.zero
	end
end



------------------------------------------------------------------
return UISubReCompound