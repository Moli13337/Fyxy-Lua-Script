---
--- Created by Administrator.
--- DateTime: 2021/1/13 14:57:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFlandSelectGift:LWnd
local UIFlandSelectGift = LxWndClass("UIFlandSelectGift", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFlandSelectGift:UIFlandSelectGift()
	---@type table<number,table>
		self._uiItemList = nil
	---@type table<number,CommonIcon>
	self._uiIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFlandSelectGift:OnWndClose()
	self:ClearEffectKeyList()
	if self._uiItemList then
		self._uiItemList:OnWndClose()
	end
	self._uiItemList = nil

	LUtil.ClearHashTable(self._uiIconList)
	self._uiIconList = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFlandSelectGift:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFlandSelectGift:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMsg()

	self:SetWndText(self.mTitleText, ccClientText(18717))
	self:SetWndText(self.mDescText, ccClientText(18724))
	self:SetWndText(self.mBottomDescText, ccClientText(18718))
	self:SetWndButtonText(self.mCancelBtn, ccClientText(10101))
	self:SetWndButtonText(self.mOkBtn, ccClientText(10102))
end

function UIFlandSelectGift:ClearEffectKeyList()
	if not self._effectKeyList then return end
	for k,v in pairs(self._effectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._effectKeyList={}
end

function UIFlandSelectGift:ResetSelectGift(itempos)
	local oldSelectPoint = self._curSelectPoint
	self._curSelectPoint = itempos
	self._uiItemList:DrawItemByIndex(oldSelectPoint)
	self._uiItemList:DrawItemByIndex(itempos)
end

function UIFlandSelectGift:SetItemList()
	if not self._data then
		return
	end

	self._allItemsList = self:GetDrawCellItemsData()
	if not self._allItemsList then
		return
	end

	--首次打开，设置当前选择道具
	local curSelectEntryId = self._curSelectEntryId
	local haveSelectBigDraw = curSelectEntryId ~= nil and curSelectEntryId ~= "" and curSelectEntryId ~= 0
	if haveSelectBigDraw then
		self._curSelectPoint = self:GetSelectPoint(curSelectEntryId)
		self._curSelectEntryId = nil
	end

	local uiList	 = self._uiItemList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self, self.mItemList)
		uiList:EnableScroll(true, false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawCellItem(...)
		end)
		self._uiItemList = uiList
	end

	uiList:RemoveAll()
	for k,v in pairs(self._allItemsList) do
		uiList:AddData(k,v)
	end

	uiList:RefreshList()
end

function UIFlandSelectGift:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	gModelActivity:OnActivityPageReq(self._sid)
end

function UIFlandSelectGift:GetDrawCellItemsData()
	if not self._data then
		return nil
	end

	local oldSuperGift	= self._activityPageData.oldSuperGift
	local oldSuperGiftList = oldSuperGift ~= nil and string.split(oldSuperGift, '|') or {}
	local oldSuperGiftNum = {}
	for k,v in ipairs(oldSuperGiftList) do
		local entryId = tonumber(v)
		local num     = oldSuperGiftNum[entryId]
		if not num then
			oldSuperGiftNum[entryId] = 1
		else
			oldSuperGiftNum[entryId] = num + 1
		end
	end

	local roundTime = self._activityPageData.roundTime

	local bigGiftData = {}
	for k,v in ipairs(self._data) do
		local entryId	= v.entryId
		local needRound = tonumber(v.needRound)
		local drawNum   = tonumber(v.drawNum)
		local oldGetNum = oldSuperGiftNum[entryId] or 0
		local curNum 	= drawNum - oldGetNum
		local haveNum 	= curNum > 0
		local isOpenRound = needRound <= roundTime
		local canSelect = haveNum and isOpenRound

		local data = {
			entryId = v.entryId,
			items	= v.items,
			sort	= v.sort,
			needRound = needRound,
			drawNum   = drawNum,
			curNum	  = curNum,
			haveNum	  = haveNum,
			isOpenRound = isOpenRound,
			canSelect = canSelect,
		}
		table.insert(bigGiftData, data)
	end

	table.sort(bigGiftData, function(ref1, ref2)
		--是否可选
		if ref1.canSelect ~= ref2.canSelect then
			return ref1.canSelect
		end

		--是否还有数量
		if ref1.haveNum ~= ref2.haveNum then
			return ref1.haveNum
		end

		--是否轮数相同
		if ref1.needRound ~= ref2.needRound then
			return ref1.needRound < ref2.needRound
		end

		--默认排序
		return ref1.sort < ref2.sort
	end)

	return bigGiftData
end

--####################################################################################################################
--### Server #########################################################################################################
--####################################################################################################################
function UIFlandSelectGift:OnActivityResp(pb,ret)
	if self._sid ~= pb.sid then return end

	self:SetItemList()
end

function UIFlandSelectGift:OnDrawCellItem(list, item, itemdata, itempos)
	local rootTrans = CS.FindTrans(item,"Root")
	local commonUI 	= CS.FindTrans(rootTrans,"CommonUI")
	local maskImg 	= CS.FindTrans(commonUI,"Mask")
	local eff 		= CS.FindTrans(commonUI,"Eff")
	local maskText 	= CS.FindTrans(commonUI,"MaskText")
	local text 		= CS.FindTrans(rootTrans,"Text")
	local instanceId = item:GetInstanceID()

	local entryId	= itemdata.entryId		--奖励唯一id
	local needRound	= itemdata.needRound	--开放轮数
	local drawNum	= itemdata.drawNum		--所需数量
	local curNum	= itemdata.curNum		--当前数量
	local haveNum 	= itemdata.haveNum		--是否有剩余数量
	local isOpenRound = itemdata.isOpenRound	--是否为轮数开放
	local canSelect = itemdata.canSelect	--是否可选
	local items		= itemdata.items		--展示道具数据
	local refId		= items.itemId
	local count		= items.itemNum
	local itemType  = items.itemType
	local effect	= items.isShowEff
	local isSelect	= self._curSelectPoint == itempos
	local formatData =
	{
		itemId = refId,
		itemType = itemType,
		itemNum = count,
	}
	local baseClass = self._uiIconList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiIconList[instanceId] = baseClass
		baseClass:Create(CS.FindTrans(commonUI, "Icon"))
	end

	baseClass:SetCommonReward(itemType,refId,count)
	baseClass:EnableShowNum(true)
	baseClass:ShowGouImg(isSelect)
	baseClass:ShowLock(not isOpenRound)
	baseClass:DoApply()

	--设置道具特效
	local show = effect ~= false
	if show and itemType == LItemTypeConst.TYPE_ITEM then
		LxResUtil.DestroyChildImmediate(eff)
		local itemRef = gModelItem:GetRefByRefId(refId)
		local bgEff = itemRef and itemRef.bgEff or nil
		show = not string.isempty(bgEff)
		if show then
			local key = "DrawItem"..tostring(entryId)
			table.insert(self._effectKeyList,key)
			self:CreateWndEffect(eff,bgEff,instanceId,100,false,false)
		end
	end
	CS.ShowObject(eff,show)
	CS.ShowObject(maskImg, not haveNum)
	CS.ShowObject(maskText,  not haveNum)

	local textStr
	if not haveNum then
		self:SetWndText(maskText, ccClientText(18719))
		self:InitTextLineWithLanguage(maskText, -30)
		textStr = string.replace(ccClientText(18721), 0, drawNum)
		textStr = string.replace(self._redColorFormat, textStr)
	elseif not canSelect then
		textStr = string.replace(ccClientText(18714), needRound)
	else
		textStr = string.replace(ccClientText(18721), curNum, drawNum)
	end
	self:SetWndText(text, textStr)

	self:SetIconClickScale(commonUI, true)
	self:SetWndClick(commonUI,  function()
		if isSelect then return end
		if not haveNum then
			GF.ShowMessage(ccClientText(18719))
			return
		end
		if not canSelect then
			GF.ShowMessage(ccClientText(18720))
			return
		end

		self:ResetSelectGift(itempos)
	end)

	self:SetWndLongClick(commonUI,function()
		gModelGeneral:ShowCommonItemTipWnd(formatData)
	end,0.2,true)
end

function UIFlandSelectGift:GetSelectPoint(entryId)
	if not self._allItemsList then
		return nil
	end

	for k,v in ipairs(self._allItemsList) do
		if entryId == v.entryId then
			return k
		end
	end

	return nil
end

function UIFlandSelectGift:OnClickOkBtn()
	if self._curSelectPoint then
		local data = self._uiItemList:GetDataByIndex(self._curSelectPoint)
		gModelActivity:OnActivityNoRepeatDropReq(1, self._sid, self._pageId, data.entryId, 18)
	end

	self:WndClose()
end

function UIFlandSelectGift:InitEvent()
	self:SetWndClick(self.mMaskBg, function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)
	self:SetWndClick(self.mCancelBtn, function() self:WndClose() end)
	self:SetWndClick(self.mOkBtn, function() self:OnClickOkBtn() end)
end

function UIFlandSelectGift:ResetActivePageData(pb)
	local pageData
	for i, v in ipairs(pb.pages) do
		if v.pageId == self._pageId then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			if page then
				pageData = page
				break
			end
		end
	end
	--大奖数据
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

	self._data = {}
	for k,v in ipairs(pageData.entry) do
		local moreInfo 		= JSON.decode(v.moreInfo)
		local type			= moreInfo.type
		if type == 2 then --大奖类型为2
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
			if not entryCfg then
				return
			end
			local extractMaxNum = string.split(moreInfo.extractMaxNum, '=')

			local data = {
				entryId = v.entryId,
				items	= LxDataHelper.ParseItem(entryCfg.reward)[1],
				sort	= entryCfg.sort,
				type	= type,
				needRound = extractMaxNum[1],
				drawNum   = extractMaxNum[2],
			}

			table.insert(self._data, data)
		end
	end
end


function UIFlandSelectGift:OnActivityPageResp(pb,ret)
	if self._sid ~= pb.sid then return end

	self:ResetActivePageData(pb)
	self:SetItemList()
end

function UIFlandSelectGift:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIFlandSelectGift:InitData()
	self._pageId 	= 3 			--翻牌抽奖id
	self._func 		= self:GetWndArg("func")
	self._sid 		= self:GetWndArg("sid")
	self._data 		= self:GetWndArg("data")
	self._activityPageData = self:GetWndArg("pageData")
	self._curSelectEntryId = self:GetWndArg("curEntryId")

	self._effectKeyList ={}
	self._curSelectPoint = nil
	self._redColorFormat = "<color=#c81212>#a1#</color>"
end


------------------------------------------------------------------
return UIFlandSelectGift