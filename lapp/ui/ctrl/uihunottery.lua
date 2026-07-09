---
--- Created by Administrator.
--- DateTime: 2023/10/29 17:41:28
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHunottery:LWnd
local UIHunottery = LxWndClass("UIHunottery", LWnd)

UIHunottery.NO_SELECT = -1
UIHunottery.INIT = 0
UIHunottery.SELECT = 1


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHunottery:UIHunottery()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHunottery:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHunottery:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHunottery:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStatic()
	self:InitUIEvent()
	self:InitEvent()
	self:InitData()
	self:RefreshContent()
end

function UIHunottery:InitUIEvent()
	self:SetWndClick(self.mBtnPro,function ()
		self:OnClickRate()
	end)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnRecord,function ()
		self:OnClickRecord()
	end)

	self:SetWndClick(self.mBtnSummon,function ()
		self:OnClickSummon()
	end)

	self:SetWndClick(self.mBtnShare,function ()
		self:OnClickShare()
	end)

	self:SetWndClick(self.mBtnHelp,function ()
		GF.OpenWnd("UIBzTips",{refId = 157})
	end)
end

function UIHunottery:OnDrawRound(list, item, itemdata, itempos)
	local image1 = self:FindWndTrans(item,"Image1")
	local image2 = self:FindWndTrans(item,"Image2")
	local commonIconTrans = self:FindWndTrans(item,"CommonUI")
	local coverIconTrans = self:FindWndTrans(item, "CoverIcon")
	local textTrans = self:FindWndTrans(item, "Text")
	local redPoint = self:FindWndTrans(item, "redPoint")

	local isSel = itempos == self._curRound
	local showRed = self:CheckShowRed(itempos)
	CS.ShowObject(redPoint,showRed)

	CS.ShowObject(image1,itempos ~= self._totalRound)
	CS.ShowObject(image2,itempos ~= 1)
	CS.ShowObject(commonIconTrans, not isSel)
	CS.ShowObject(coverIconTrans,  isSel)
	local str = LUtil.FormatColorStr(itemdata,isSel and "black" or "lightBlue")
	self:SetWndText(textTrans,str)

	self:SetWndClick(item, function()
		self:OnClickRound(itempos)
	end)
end

function UIHunottery:InitEvent()
	self:WndEventRecv(EventNames.On_Item_Change,function ()
		self:ResetData()
		self:RefreshContent()
	end)

	self:WndEventRecv(EventNames.ON_TIME_ZERO,function ()
		gModelItem:OnItemExtraInfoReq(self._id)
	end)
end

function UIHunottery:InitData()
	local itemdata = self:GetWndArg("itemdata")
	self._itemData = itemdata

	self._refId = itemdata.refId
	self._id = itemdata.id

	self:ResetData()

end

function UIHunottery:OnDrawReward(list, item, itemdata, itempos)
	local Root = self:FindWndTrans(item,"Root")
	local RootItemRoot = self:FindWndTrans(Root,"itemRoot")
	local itemRootIcon = self:FindWndTrans(RootItemRoot,"Icon")
	local RootName = self:FindWndTrans(Root,"Name")
	local RootEffectRoot = self:FindWndTrans(Root,"EffectRoot")

	self:CreateCommonIconImpl(itemRootIcon,itemdata)
	local itemName = gModelGeneral:GetCommonItemName({itemType = itemdata.itemType,itemId = itemdata.itemId})
	self:SetWndText(RootName,itemName)
	self:InitTextShowWithLanguage(RootName)
end


function UIHunottery:OnClickRecord()

	if gModelItem:CheckShowUnSave(self._refId,self._id,self._curRound) then
		return
	end

	local itemdata = self._itemData
	local round = self._curRound

	local para =
	{
		itemdata = itemdata,
		round = round,
		wndType = 2
	}

	GF.OpenWnd("UILotteryRltsSelect",para)
end



function UIHunottery:OnClickRound(round)
	if self._curRound == round then
		return
	end

	local left = round - self._curOpenRound
	if left == 1 then
		GF.ShowMessage(ccClientText(38302))
		return
	elseif left > 1 then
		GF.ShowMessage(ccClientText(38306))
		return
	end


	local hasUnGet = false
	for k,v in pairs(self._roundDataMap) do
		if v.round< round and v.recIndex == 0 then
			hasUnGet = true
			break
		end
	end

	if hasUnGet then
		GF.ShowMessage(ccClientText(38305))
		return
	end

	self._curRound = round

	local list = self:FindUIScroll("roundList")
	list:DrawAllItems()



	self:RefreshRewardShow()
end

function UIHunottery:SetStatic()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mProText,ccClientText(30901))
	self:SetWndButtonText(self.mBtnRecord,ccClientText(30912))
	self:SetWndButtonText(self.mBtnSummon,ccClientText(30902))
	self:SetWndText(self.mTheGasText,ccClientText(30913))
	local str =ccClientText(38300)  --"10次十连奖保底出传说伙伴"
	self:SetWndText(self.mSpeak,str)

	CS.ShowObject(self.mBtnSummon,true)

	self._romeNum = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "VX", "X",}

	local data = {
		refId = 34001,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
end



function UIHunottery:OnClickSummon()
	gModelItem:OnClickSummon(self._refId,self._id,self._curRound)


end

function UIHunottery:RefreshRewardShow()
	local round = self._curRound
	local maxData = self:GetMaxRankRecord(round)
	local isEmpty = maxData == nil
	local recordNum =# self._roundDataMap[round].recordList
	CS.ShowObject(self.mBtnRecord,recordNum>0)
	CS.ShowObject(self.mNoRecord3,isEmpty)
	CS.ShowObject(self.mRewardBg,not isEmpty)

	local showRed = self:CheckShowRed(round)
	local redTran = self:FindWndTrans(self.mBtnRecord,"redPoint")
	CS.ShowObject(redTran,showRed)

	local leftNum = gModelItem:GetCallNumLeft(self._refId,self._id,self._curRound)
	local playerCallNumStr = LUtil.FormatColorStr(leftNum,leftNum > 0 and "green" or "red")
	self:SetWndText(self.mSummonText,string.replace(ccClientText(30903),playerCallNumStr))




	if isEmpty then
		return
	end

	self:SetWndText(self.mTheGasValueText,maxData.rankValue)
	local dataList = LxDataHelper.ParseItem(maxData.reward)

	self:CreateUIScrollImpl("rewardList",self.mRewardList,dataList,function (...)
		self:OnDrawReward(...)
	end,UIItemList.SUPER_GRID)
end

function UIHunottery:RefreshContent()
	local itemdata = self._itemData
	self._extra = itemdata.extra

	self._roundDataMap = {}
	for k,v in ipairs(self._extra.roundList) do
		self._roundDataMap[v.round] = v
	end
	self._totalRound = #self._extra.roundList
	self._curOpenRound = self._extra.openDay or 1
	local dataList = {}
	local defaultSel = nil
	for k=1,self._totalRound  do
		table.insert(dataList,self._romeNum[k])

		local roundData = self._roundDataMap[k]
		if roundData.recIndex == 0 and k <= self._curOpenRound and not defaultSel then
			defaultSel = k
		end
		--if self:CheckShowRed(k) and not defaultSel then
		--	defaultSel = k
		--end

	end

	self._curRound = defaultSel or 1





	self:CreateUIScrollImpl("roundList",self.mRoundList,dataList,function (...)
		self:OnDrawRound(...)
	end)

	self:RefreshRewardShow()
end

function UIHunottery:CheckShowRed(round)
	local roundData = self._roundDataMap[round]
	if not roundData then
		return false
	end
	if round < self._curOpenRound then
		return roundData.recIndex == 0
	elseif round == self._curOpenRound then
		for k,v in ipairs(roundData.recordList) do
			if v.select == ModelItem.SELECT_STATE_INIT then
				return true
			end
		end

		local cnt = #roundData.recordList
		if cnt >= ModelItem.THOUSAND_CALL_TOTAL and roundData.recIndex == 0 then
			return true
		end
	end
end



function UIHunottery:GetMaxRankRecord(round)
	local roundData = self._roundDataMap[round]
	if not roundData then
		return
	end
	local maxRankValue = nil
	local maxRecord = nil
	for k,v in ipairs(roundData.recordList) do
		if v.select ~= UIHunottery.NO_SELECT then
			if maxRankValue == nil or maxRankValue < v.rankValue then
				maxRankValue = v.rankValue
				maxRecord = v
			end
		end
	end

	return maxRecord
end

function UIHunottery:OnClickRate()
	GF.OpenWnd("UIYellHRew",{callRefId = 4001,viewType = 2})
end

function UIHunottery:ResetData()
	local refId = self._refId
	local id = self._id

	local itemdata = gModelItem:FormatItemUniqueData(refId,id)
	if not itemdata then
		self:WndClose()
		return
	end

	self._itemData = itemdata

end

function UIHunottery:OnClickShare()
	local maxRecord = self:GetMaxRankRecord(self._curRound)
	if not maxRecord then
		return
	end

	gModelItem:ShareCallResult({result = maxRecord,root = self.mBtnShare})
end

------------------------------------------------------------------
return UIHunottery


