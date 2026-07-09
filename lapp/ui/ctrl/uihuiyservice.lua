---
---活动102 VIP专属客服
--- Created by Ease.
--- DateTime: 2023/10/28 12:00:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHuiYService:LWnd
local UIHuiYService = LxWndClass("UIHuiYService", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHuiYService:UIHuiYService()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHuiYService:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHuiYService:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHuiYService:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent() --初始化事件
	self:InitBtnEvent()
	self:InitMessage()   --初始化协议
	self:InitData()
end
function UIHuiYService:OnActivityConfigData()
	self.isCHN = gLGameLanguage:IsChinaRegion()

	self._activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
	self._activityData = gModelActivity:GetActivityBySid(self._sid)
	local config = self._activityWebData.config --main表
	self._config = config
	self._cfgEntryList = self._activityWebData.chunk --条目表
	self._entry = self._cfgEntryList[1]
	if LxUiHelper.IsImgPathValid(config.title) then
		self:SetWndEasyImage(self.mTitleImg, config.title,function()
			CS.ShowObject(self.mTitleImg,true)
		end)
	end
	self:SetWndEasyImage(self.mHeadImg, config.image)
	self:SetWndText(self.mSloganTxt, config.descText)
	self:InitTextSizeWithLanguage(self.mSloganTxt, -2)
	self:SetWndText(self.mLineTitleTxt, config.descContact1)
	self:SetWndText(self.mWeChatTitleTxt, config.descContact2)
	local isCHN = self.isCHN
	if isCHN then
		local contactImgPath = config.descimage
		local isShowImg = not string.isempty(contactImgPath)

		if isShowImg then
			CS.ShowObject(self.mGroupListImg, isShowImg)
			self:SetWndEasyImage(self.mGroupListImg,contactImgPath,nil,false)
		end

		CS.ShowObject(self.mGroupList, not isShowImg)
	end


	local rewardText = config.rewardText
	local showTitleDiv = not string.isempty(rewardText)
	if showTitleDiv then
		self:SetTextTile(self.mTitle, rewardText)
	end
	CS.ShowObject(self.mTitleNode,showTitleDiv)

	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetTxtList()
	self:SetItemList()
	self:SetUIByEntry()

	self.mShowItemCG.alpha = 1
	CS.ShowObject(self.mAniRoot,true)
end
function UIHuiYService:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
		self:OnActivityConfigData(...)
	end)
end
function UIHuiYService:SetTxtList()
	local descPrivilege = self._config.descPrivilege
	local txtArr = string.split(descPrivilege,"|")
	local list = txtArr
	local itemList =  self._txtList
	if itemList then
		itemList:RefreshList(list)
	else
		itemList = self:GetUIScroll("mTxtList")
		itemList:Create(self.mTxtList, list, function(...)
			self:OnTxtList(...)
		end)
		self._txtList = itemList
		self._txtList:EnableScroll(true,false)
	end
end
function UIHuiYService:InitMessage()
end
function UIHuiYService:InitData()
	self._sid = self:GetWndArg("sid")
	gModelActivity:ReqActivityConfigData(self._sid)

end
function UIHuiYService:SetUIByEntry()
	local entryData
	local playerServerId = gLGameLogin:GetServerId()
	playerServerId = tostring(playerServerId)
	for i, v in pairs(self._entry.entries) do
		local serverIdArr = string.split(v.serverId, ";")
		for j, k in pairs(serverIdArr) do
			local sIdArr = string.split(k, ",")
			if (sIdArr[1] == sIdArr[2]) then
				if (playerServerId == sIdArr[1]) then
					entryData = v
				end
			elseif (sIdArr[2] == -1) then
				if (playerServerId >= sIdArr[1]) then
					entryData = v
				end
			elseif (sIdArr[1] < sIdArr[2]) then
				if (playerServerId >= sIdArr[1] and playerServerId <= sIdArr[2]) then
					entryData = v
				end
			end
		end
	end
	entryData = not entryData and self._entry.entries[1] or entryData
	if (entryData) then
		self._entryData = entryData
		self:SetWndText(self.mServiceNameTxt, entryData.name)

		local type = entryData.type or 1
		self._copyType = type
		local btnStr = type == 1 and ccClientText(20856) or ccClientText(11934)
		local contact1 = entryData.contact1

		--if gLGameLanguage:IsJapanRegion() then
		--	CS.ShowObject(self.mGroupListJa, true)
		--	self:SetWndText(self.mLineTitleTxtJa, self._config.descContact1)
		--	self:SetWndText(self.mLineCopyTextJa, btnStr)
		--else
		--	local isShow = not string.isempty(contact1)
		--	CS.ShowObject(self.mLineGroup, isShow)
		--	if isShow then
		--		self:SetWndText(self.mLineNameTxt, contact1)
		--		self:SetWndText(self.mLineCopyText, btnStr)
		--	end
		--
		--	local contact2 = entryData.contact2
		--	isShow = not string.isempty(contact2)
		--	CS.ShowObject(self.mWeChatGroup, isShow)
		--	if isShow then
		--		self:SetWndText(self.mWeChatNameTxt, contact2)
		--		self:SetWndText(self.mWeChatCopyText, ccClientText(24213))
		--	end
		--
		--	CS.ShowObject(self.mGroupList, true)
		--end
		local isShow = not string.isempty(contact1)
		CS.ShowObject(self.mLineGroup, isShow)
		if isShow then
			self:SetWndText(self.mLineNameTxt, contact1)
			local isJa = gLGameLanguage:IsJapanRegion() or gLGameLanguage:IsJapanVersion()
			if isJa then
				local config = self._config
				local btnContact1 = config and config.btnContact1
				if string.isempty(btnContact1 ) then
					btnContact1 = ccClientText(24213)
				end
				self:SetWndText(self.mLineCopyText, btnContact1)
			else
				self:SetWndText(self.mLineCopyText, btnStr)
			end
		end

		local contact2 = entryData.contact2
		isShow = not string.isempty(contact2)
		CS.ShowObject(self.mWeChatGroup, isShow)
		if isShow then
			self:SetWndText(self.mWeChatNameTxt, contact2)

			local config = self._config
			local btnContact2 = config and config.btnContact2
			if string.isempty(btnContact2 ) then
				btnContact2 = ccClientText(24213)
			end
			self:SetWndText(self.mWeChatCopyText,btnContact2)
		end

		CS.ShowObject(self.mGroupList, true)
	end
end
function UIHuiYService:OnTxtList(list, item, itemdata, itempos)
	local txtTrans = self:FindWndTrans(item, "desTxt")
	self:SetWndText(txtTrans,itemdata)
end
function UIHuiYService:SetItemList()
	local reward = self._config.reward
	local rewardArr = string.split(reward, ",")
	local list = rewardArr
	local itemList = #rewardArr <= 5 and self._itemList or self._moreItemList

	local listTrans = #rewardArr <= 5 and self.mItemList or self.mMoreItemList
	local listKey = #rewardArr <= 5 and "mItemList" or "mMoreItemList"
	CS.ShowObject(self.mItemList, #rewardArr <= 5)
	CS.ShowObject(self.mMoreItemList, #rewardArr > 5)

	if itemList then
		itemList:RefreshList(list)
	else
		itemList = self:GetUIScroll(listKey)
		itemList:Create(listTrans, list, function(...)
			self:OnItemList(...)
		end)
		self._itemList = itemList
		self._itemList:EnableScroll(#list > 5, true)
	end
end
function UIHuiYService:OnItemList(list, item, itemdata, itempos)
	local iconRoot = self:FindWndTrans(item, "IconRoot")
	local icon = self:FindWndTrans(iconRoot, "Icon")
	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	local dataArr = string.split(itemdata,"=")
	local itemData = {
		itemType = tonumber(dataArr[1]),
		itemId = tonumber(dataArr[2]),
		itemNum = tonumber(dataArr[3]),
	}
	baseClass:Create(icon)
	baseClass:SetCommonReward(itemData.itemType, itemData.itemId, itemData.itemNum)
	baseClass:DoApply()
	self:SetWndClick(iconRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)
end

function UIHuiYService:OnJumpBtn(btnType)
	if not self._entryData then
		return
	end

	local link = btnType == 1 and self._entryData.contact1 or self._entryData.contact2
	if string.isempty(link) then
		return
	end

	CS.UApplication.OpenURL(link)
end
function UIHuiYService:InitBtnEvent()
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mLineCopyBtn, function()
		self:OnClickCopyBtn(1)
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mWeChatCopyBtn, function()
		self:OnClickCopyBtn(2)
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mLineCopyBtnJa, function()
		self:OnClickCopyBtn(1)
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIHuiYService:OnClickCopyBtn(btnType)

	if btnType == 2 then
		self:OnJumpBtn(btnType)
	else
		local isJa = gLGameLanguage:IsJapanRegion() or gLGameLanguage:IsJapanVersion()
		if isJa then
			self:OnJumpBtn(btnType)
		else
			self:OnCopyBtn(btnType)
		end
	end
end

function UIHuiYService:OnCopyBtn(btnType)
	if not self._entryData then
		return
	end
	local str = btnType == 1 and self._entryData.contact1 or self._entryData.contact2
	if string.isempty(str) then
		return
	end
	if CS.IsOSIos() then
		if LNativeHelper.CopyToClipboard(str) then
			GF.ShowMessage(str)
		end
	else
		if LNativeHelper.CopyToClipboard(str) then
			LNativeHelper.ShowToast(str)
		end
	end
end

------------------------------------------------------------------
return UIHuiYService


