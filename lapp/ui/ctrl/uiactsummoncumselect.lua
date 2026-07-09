---
--- Created by BY.
--- DateTime: 2023/10/7 16:42:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActSummonCumSelect:LWnd
local UIActSummonCumSelect = LxWndClass("UIActSummonCumSelect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActSummonCumSelect:UIActSummonCumSelect()
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActSummonCumSelect:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActSummonCumSelect:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActSummonCumSelect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIActSummonCumSelect:OnActivityConfigData()
	local _sid = self._sid
	if not self.pages then
		gModelActivity:OnActivityPageReq(_sid)
		return
	end
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	local data = activityData.config
	local guaRewardTitle,guaRewardBgImage = data.guaRewardTitle,data.guaRewardBgImage

	if LxUiHelper.IsImgPathValid(guaRewardBgImage) then
		self:SetWndEasyImage(self.mBg,guaRewardBgImage)
	end
	if not string.isempty(guaRewardTitle) then
		self:SetWndText(self.mLblBiaoti,guaRewardTitle)
		self._guaRewardTitle = guaRewardTitle
	end
	self:RefreshData()
end

function UIActSummonCumSelect:OnClickOk()
	local _itemData = self._itemData
	if not _itemData then
		GF.ShowMessage(string.replace(ccClientText(26804),self._guaRewardTitle or ccClientText(23218)))
		return
	end
	gModelActivity:OnActivitySelectDropGiftReq(self._sid,_itemData.pageId,_itemData.entryId)
end

function UIActSummonCumSelect:OnDrawCellCustomItem(list, item, itemData, itemPos)
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemData.pageId,itemData.entryId)
	local limitInfo = self:FindWndTrans(item,"LimitInfo")
	local itemRoot = self:FindWndTrans(item,"ItemRoot")
	local icon = self:FindWndTrans(itemRoot,"Icon")
	local selImg = self:FindWndTrans(itemRoot,"SelImg")
	local itemName = self:FindWndTrans(item,"ItemName")
	local mask = self:FindWndTrans(itemRoot,"Mask")

	local InstanceID = item:GetInstanceID()
	local reward = LxDataHelper.ParseItem_3(entryCfg.reward)
	local nameStr = gModelGeneral:GetCommonItemName(reward)
	--local _mySelect = self._mySelect or 0
    --
	--CS.ShowObject(mask,_mySelect > 0 and _mySelect == itemData.entryId)
	local isSel = self._itemData and itemData.entryId == self._itemData.entryId
	CS.ShowObject(selImg,isSel)
	CS.ShowObject(mask,isSel)
	reward.trans = icon
	reward.instanceID = InstanceID
	self:CreateCommonIcon(reward)

	if gLGameLanguage:IsForeignRegion() then
		CS.ShowObject(itemName, false)
	else
		self:SetWndText(itemName,nameStr)
	end

	self:InitTextLineWithLanguage(itemName, -30)
	self:SetWndClick(itemRoot,function ()
		self:OnClickSelect(itemData)
	end)
	self:SetWndLongClick(itemRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end,0.5,false)
end
function UIActSummonCumSelect:InitCommand()
	local sid = self:GetWndArg("sid")
	self.pages = self:GetWndArg("pages")
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._sid = sid
	local enum = self._modelEnumList[modelId]
	self._turnTableEnum = enum					--奖池表枚举
	--gModelActivity:ReqActivityConfigData(sid)
	self:OnActivityConfigData()
end

function UIActSummonCumSelect:RefreshIconRoot()
	local itemData = self._itemData
	local _entryIds = self._entryIds
	CS.ShowObject(self.mIconRoot,itemData)
	CS.ShowObject(self.mProbText,itemData)
	CS.ShowObject(self.mProbTipsText,itemData)
	if itemData then
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemData.pageId,itemData.entryId)
		local reward = LxDataHelper.ParseItem_3(entryCfg.reward)
		local moreInfo = string.split(entryCfg.moreInfo,"|")
		reward.trans = self.mIconRoot
		reward.instanceID = "UIActSummonCumSelect_instanceID"
		self:CreateCommonIcon(reward)
		self:SetWndText(self.mProbText,string.replace(ccClientText(26801), moreInfo[2]))
		self:SetWndText(self.mProbTipsText,string.replace(ccClientText(26807), _entryIds[itemData.entryId]))
	end
end

function UIActSummonCumSelect:CreateCommonIcon(data)
	local instanceID = data.instanceID
	local trans = data.trans
	local itemType,itemId,itemNum = data.itemType, data.itemId, data.itemNum
	local baseClass = self._uiCommonList[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[instanceID] = baseClass
		baseClass:Create(trans)
	end
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	local showNum = itemNum > 0
	baseClass:EnableShowNum(showNum)
	baseClass:DoApply()
end
function UIActSummonCumSelect:ResetData(pb)
	if pb.sid ~= self._sid then return end
	local pages = self.pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		pages[v.pageId] = page
	end
	self.pages = pages
	self:RefreshData()
end

function UIActSummonCumSelect:OnClickSelect(itemData)
	self._itemData = itemData
	self._uiList:DrawAllItems()
	self:RefreshIconRoot()
end
function UIActSummonCumSelect:InitEvent()
	self:SetWndClick(self.mBg, function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnOk, function() self:OnClickOk() end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIActSummonCumSelect:OnTryTcpReconnect()
	self:WndClose()
end
function UIActSummonCumSelect:InitData()
	self._modelEnumList = {
		[ModelActivity.MODEL_ACTIVITY_TYPE_68] = ModelActivity.KING_STREET_3,
	}
	self:SetWndText(self.mLblBiaoti, ccClientText(23218))
	self:SetWndText(self.mLblBiaoti2, ccClientText(23231))
	self:SetWndText(self.mNoCustomItemTxt, ccClientText(18604))
	self:SetWndButtonText(self.mBtnOk,ccClientText(26800))
end
function UIActSummonCumSelect:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...) self:ResetData(...) end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ActivitySelectDropGiftResp,function (...) self:WndClose() end)
end

function UIActSummonCumSelect:RefreshData()
	local pages = self.pages
	local _turnTableEnum = self._turnTableEnum
	local sid = self._sid
	if not sid or not _turnTableEnum or not pages then return end
	local pageEntry = pages[_turnTableEnum]
	if not pageEntry then return end
	local activityDataS = gModelActivity:GetActivityBySid(sid)
	local activityDataW = gModelActivity:GetWebActivityDataById(sid)
	if not activityDataS or not activityDataW then return end
	--------------------------------------后端数据------------------------------------------------
	local dataS = JSON.decode(activityDataS.moreInfo)
	local mySelect = dataS.mySelect					--我的选择
	self._mySelect = mySelect
	--------------------------------------配置数据------------------------------------------------
	local dataW = activityDataW.config
	local wishHero = dataW.wishHero					--抽奖：奖池表条目id=所需积分=概率，多个用【;】分隔
	if string.isempty(wishHero) then return end
	local wishHeroArr = string.split(wishHero,";")
	local entryIds = {}
	for i, v in ipairs(wishHeroArr) do
		local arr = string.split(v,"=")
		entryIds[tonumber(arr[1])] = tonumber(arr[2])
	end
	local _itemData = nil
	local list = {}
	for i, v in ipairs(pageEntry.entry) do
		local entryId = v.entryId
		if entryIds[entryId] then
			if mySelect and mySelect == entryId then
				_itemData = v
			end
			table.insert(list,v)
		end
	end
	self._itemData = _itemData
	self._entryIds = entryIds

	CS.ShowObject(self.mNoCustomItemTxt,#list <= 0)
	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
		uiList:DrawAllItems()
	else
		uiList	 = self:GetUIScroll("customItemList")
		uiList:Create(self.mCustomItemList, list, function(...) self:OnDrawCellCustomItem(...) end,UIItemList.SUPER_GRID)
		uiList:EnableScroll(true, false)
		self._uiList = uiList
	end
	self:RefreshIconRoot()
end
------------------------------------------------------------------
return UIActSummonCumSelect


