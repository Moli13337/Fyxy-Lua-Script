---
---	道具抽奖弹框 - 愿望火柴
--- Created by Ease.
--- DateTime: 2023/10/13 19:57:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIItewPop:LWnd
local UIItewPop = LxWndClass("UIItewPop", LWnd)
--local typeImage = typeof(UnityEngine.UI.Image)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIItewPop:UIItewPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIItewPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIItewPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIItewPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitMessage()
	self:InitEvent()
	self:InitData()
end
function UIItewPop:OnDrawRewardItemCell(list, item, itemdata, itempos, fromHeadTail)
	local aniNode = CS.FindTrans(item, "AniRoot")
	local iconRoot = CS.FindTrans(aniNode, "IconRoot")
	local iconTrans = CS.FindTrans(iconRoot, "Icon")
	local effRootTrans = CS.FindTrans(aniNode, "Eff")
	local itemData = LxDataHelper.ParseItem_4(itemdata.reward)
	local instanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(iconTrans)
	baseClass:SetCommonReward(itemData.itemType,itemData.itemId,itemData.itemNum)
	baseClass:DoApply()
	local itemRef = gModelItem:GetRefByRefId(itemData.itemId)
	local effName = itemRef and itemRef.bgEff or nil
	if(effName and itemData.isShowEff)then
		self:CreateWndEffect(effRootTrans,effName,effRootTrans:GetInstanceID(),88,false)
	end
	self:SetWndClick(iconRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)
	CS.ShowObject(effRootTrans,effName and itemData.isShowEff)
end
function UIItewPop:InitPbData(pbInfo)
	self._itemRefId = pbInfo.refId
	self._itemId = pbInfo.id
	self._extra = pbInfo.extra
	if(self._extra)then
		self._endTime = self._extra.endTime / 1000
		self._drop = self._extra.drop
		self._dayNum = tonumber(self._extra.dayNum)
		self._allNum = tonumber(self._extra.allNum)
	end
	self._dropCntList = {}
	self:SetDropCntList()
	gModelWishingMatch:SetItemExtraInfo(pbInfo)
end
function UIItewPop:RefreshUI()
	self:SetTimeTxt()
	self:SetTxtList()
	self:SetBotGroup()
end
function UIItewPop:SetRewardList()
	local dataList = self._dropList
	local uiList = self._uiRewardList
	if not uiList then
		uiList = self:GetUIScroll("_uiRewardList")
		self._uiRewardList = uiList
		uiList:Create(self.mRewardList, dataList, function(...)
			self:OnDrawRewardItemCell(...)
		end, UIItemList.SUPER_GRID, false)
	else
		uiList:RefreshList(dataList)
	end
	uiList:DrawAllItems(false)
end
function UIItewPop:GetTxtList()
	local dropList = self._dropList
	local list = {}
	for i, v in ipairs(dropList) do
		if(v.type == 1)then
			table.insert(list,v)
		end
	end
	table.sort(list, function(a,b)
		return a.sort<b.sort
	end)
	return list
end
--region 倒计时 SetTimeTxt
function UIItewPop:SetTimeTxt()
	self:ShowTimerFunc()
	self:TimerStop(self._inDataTimerKey)
	self:TimerStart(self._inDataTimerKey, 1, false, -1)
end
function UIItewPop:OnClickDrawBtn()
	local canDraw = self:CheckCanDraw()
	if(canDraw)then
		local itemUseInfos = gModelWishingMatch:GetItemUseInfos(self._itemRefId,self._itemId)
		gModelItem:OnItemUseReq(itemUseInfos)
	end
end
function UIItewPop:GetItemUseInfos()
	local itemUseInfos = {
		refId = self._itemRefId,
		num = 1,
		params = tostring(self._itemId),
	}
	return itemUseInfos
end
function UIItewPop:SetEffectGroup()
	local effectCfg = self._rewardCfg.effect
	if(not effectCfg or string.isempty(effectCfg))then
		return
	end
	local effArr = string.split(effectCfg,"|")
	for i, v in ipairs(effArr) do
		local dataArr = string.split(v,"=")
		local effName = dataArr[1]
		if(effName)then
			local effRoot = self:FindWndTrans(self.mEffectRoot,"Eff"..i)
			self:CreateEffect(effRoot,effName,effName)
			if(dataArr[2])then
				self:SetAnchorPos(effRoot, LxDataHelper.ParseVector2NotEmpty3(dataArr[2]))
			end
		end
	end
end
function UIItewPop:InitBtnEvent()
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpBtn, function()
		self:OnClickHelpBtn()
	end)
	self:SetWndClick(self.mDrawBtn, function()
		self:OnClickDrawBtn()
	end)
end
--endregion
function UIItewPop:SetTxtList()
	local trans = self.mTxtList
	local list = self:GetTxtList()
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawTxtListItemCell(...) end)
	end
	uiList:EnableScroll(true,false)
end
function UIItewPop:GetDrawTimesStr(curDrawTimes,drawLimit,txtIndex)
	local curColor = curDrawTimes<drawLimit and "30e055" or "c81212"
	local str = string.replace(ccClientText(txtIndex),"30e055",curColor,curDrawTimes,drawLimit)
	return str
end
function UIItewPop:SetWndTransPos(trans,posStr)
	if(not posStr)then
		return
	end
	local pos = LxDataHelper.ParseVector2NotEmpty3(posStr)
	self:SetAnchorPos(trans,pos)
end
function UIItewPop:InitEvent()
end
function UIItewPop:CreateEffect(trans,effectName,effectKey,effectSize)
	effectKey = effectKey or trans:GetInstanceID()
	effectSize = effectSize or 100
	self:CreateWndEffect(trans,effectName,effectKey,effectSize,false,false)
end
function UIItewPop:InitData(info)
	self._pbInfo = info or self:GetWndArg("info")
	self:InitPbData(self._pbInfo)
	self._mainCfg = gModelWishingMatch:GetConfigByType(ModelWishingMatch.Main)
	self._rewardCfg = gModelWishingMatch:GetConfigByTypeAndKey(ModelWishingMatch.Item,self._itemRefId)
	self._itemRef = gModelItem:GetRefByRefId(self._itemRefId)
	self._inDataTimerKey = "_inDataTimerKey"
	self._dropList = gModelWishingMatch:GetItemDropList(self._itemRefId)
	self:SetDefultUI()
	self:RefreshUI()
	self:SetEffectGroup()
end
function UIItewPop:OnTimer(key)
	if(key == self._inDataTimerKey)then
		self:ShowTimerFunc()
	end
end
function UIItewPop:SetBotGroup()
	local allDrawStr = self:GetDrawTimesStr(self._allNum,self._rewardCfg.allDropNum,37803)
	self:SetWndText(self.mDrawTimesTxt,allDrawStr)
	local lastDrawCnt = self._rewardCfg.dayDropNum - self._dayNum
	local drawBtnStr = string.format("%s(%s)",ccClientText(37805),tostring(lastDrawCnt))
	self:SetWndButtonText(self.mDrawBtn,drawBtnStr)
end

function UIItewPop:OnClickHelpBtn()
	local data = {
		refId = self._mainCfg.helpTipsRefId
	}
	GF.OpenWnd("UIBzTips",data)
end
function UIItewPop:OnDrawTxtListItemCell(list,item,itemdata,itempos)
	local title = self:FindWndTrans(item,"Title")
	local finishIcon = self:FindWndTrans(title,"FinishIcon")
	local itemData = LxDataHelper.ParseItem_4(itemdata.reward)
	--local itemId = itemData.itemId
	local itemCnt = itemData.itemNum
	local itemName = gModelGeneral:GetCommonItemName(itemData)
	local itemName = itemName
	--local titleStr = string.replace(ccClientText(37802),itemName,"30e055",itemdata.guaranteeTime)
	local titleStr = string.replace(ccClientText(37802),itemName.."*"..itemCnt,itemdata.guaranteeTime)
	self:SetWndText(title,titleStr)
	local getCnt = self._dropCntList[itemdata.refId]
	CS.ShowObject(finishIcon,getCnt and itemdata.guaranteeTime and getCnt>=itemdata.guaranteeTime)
end
function UIItewPop:SetDropCntList()
	if(self._pbInfo and self._pbInfo.extra and self._pbInfo.extra.drop and #self._pbInfo.extra.drop>0)then
		for i, v in ipairs(self._pbInfo.extra.drop) do
			self._dropCntList[v] = self._dropCntList[v] and self._dropCntList[v] + 1 or 1
		end
	end
end
function UIItewPop:ShowTimerFunc()
	local nowTime = GetTimestamp()
	local timeDif = os.difftime(self._endTime, nowTime)
	local timeStr = gModelWishingMatch:GetInDataStrByTime2(timeDif)
	timeStr = string.replace(ccClientText(37800),"30e055",timeStr)
	if timeDif <= 0 then
		self:TimerStop(self._inDataTimerKey)
		timeStr = ccClientText(10254)
	end
	self:SetWndText(self.mTimeTxt, timeStr)
end

function UIItewPop:SetDefultUI()
	self:SetWndEasyImage(self.mTitleImg,self._rewardCfg.title)
	self:SetWndTransPos(self.mTitleImg,self._rewardCfg.titlePos)
	self:SetWndTransPos(self.mTimeTxtBg,self._mainCfg.timePos)
	self:SetWndTransPos(self.mHelpBtn,self._mainCfg.signHelpTipsPos)
	CS.ShowObject(self.mDescTxtBg,false)--UI反馈 永久隐藏

	local descStr = string.replace(ccClientText(37801),"30e055")
	self:SetWndText(self.mDescTxt,descStr)
	self:SetWndButtonText(self.mDrawBtn,ccClientText(37805))
	self:SetRewardList()
end
function UIItewPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ItemUseResp, function(...)
		if(self._itemId)then
			gModelItem:OnItemExtraInfoReq(self._itemId)
			--self:WndClose()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ItemExtraInfoResp, function(pb)
		if(pb)then
			local info = gModelGeneral:GetStructItemExtraInfoByPb(pb)
			self:InitData(info)
		end
	end)
end
function UIItewPop:CheckCanDraw()
	if(self._dayNum and self._allNum)then
		return gModelWishingMatch:CheckCanDraw(self._itemRefId,self._dayNum,self._allNum,self._endTime*1000,true)
	end
end
------------------------------------------------------------------
return UIItewPop


