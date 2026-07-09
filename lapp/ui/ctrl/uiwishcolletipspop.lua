---
--- Created by BY.
--- DateTime: 2023/10/24 17:43:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWishColleTipsPop:LWnd
local UIWishColleTipsPop = LxWndClass("UIWishColleTipsPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWishColleTipsPop:UIWishColleTipsPop()
	self._uiCommonIconList = {}
	self._timeTextList = {}
	self._timeKey = "itemTimeKey"
	self._maskList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWishColleTipsPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWishColleTipsPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWishColleTipsPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIWishColleTipsPop:SetTime()
	local time = GetTimestamp()
	local endTime = self._schoolInfo.goalEndTime
	local timespan = endTime/1000 - time
	if(timespan > 0)then
		for i, v in pairs(self._timeTextList) do
			local timeStr = LUtil.FormatTimespanCn(timespan)
			self:SetWndText(v,timeStr)
		end
	else
		self:TimerStop(self._timeKey)
		for i, v in pairs(self._timeTextList) do
			self:SetWndText(v,ccClientText(20314))
		end
		for i, v in pairs(self._maskList) do
			CS.ShowObject(v,true)
		end
	end

end

function UIWishColleTipsPop:InitCommand()
    self:SetWndText(self.mDes1Text,ccClientText(20319))
    self:SetWndText(self.mDes2Text,ccClientText(20320))
	local refId = self:GetWndArg("refId")
	local stage = self:GetWndArg("stage")
	local ref = gModelDreamSchool:GetSchoolThemeRefByRefId(refId)
	if not ref then return end

	self:SetWndText(self.mName,ccLngText(ref.name))
	local _schoolInfos = gModelDreamSchool:GetSchoolInfos()
	local _schoolInfo = _schoolInfos[refId]
	if not _schoolInfo then return end

	self._schoolInfo = _schoolInfo
	self:SetWndEasyImage(self.mTitleImage,ref.nameImg)
	local list = string.split(ccLngText(ref.description),"|")
	local _uiList = self:GetUIScroll("tipsDes")
	_uiList:Create(self.mDesSuper,list,function (...) self:ListItem(...) end, UIItemList.SUPER)
	_uiList:MoveToPos()

	local list = gModelDreamSchool:GetSchoolTargetRefByType(ref.refId,stage)
	local itemRef
	for i, v in ipairs(list) do
		if v.rewardSpecail and v.rewardSpecail ~= "" then
			itemRef = v
			break
		end
	end
	if not itemRef then
		return
	end
	local itemList1 = LxDataHelper.ParseItem(itemRef.rewardSpecail)
	local itemList2 = LxDataHelper.ParseItem(itemRef.rewardGeneral)
	for i, v in ipairs(itemList2) do
		v.rewardType = 1
		table.insert(itemList1,v)
	end
	local _uiList = self:GetUIScroll("itemcell")
	_uiList:Create(self.mItemScroll,itemList1,function (...) self:CellListItem(...) end)
end

function UIWishColleTipsPop:InitEvent()
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
end

function UIWishColleTipsPop:CellListItem(list,item, itemdata, itempos)
	local InstanceID = item:GetInstanceID()
	local timeText = CS.FindTrans(item,"TimeText")
	local itemRoot = CS.FindTrans(item,"ItemRoot")
	local itemRootCommonUI = CS.FindTrans(item,"ItemRoot/CommonUI")
	local itemLook = CS.FindTrans(item,"ItemRoot/mask")
	local nameText = CS.FindTrans(item,"NameText")
	local mask = CS.FindTrans(item,"Mask")

	CS.ShowObject(itemLook, itempos == 1 or itempos == 2)
	local rewardType = itemdata.rewardType
	local name = gModelItem:GetNameByRefId(itemdata.itemId)
	if rewardType and rewardType == 1 then
		self:SetWndText(timeText,ccClientText(20315))
	else
		self._maskList[InstanceID] = mask
		self._timeTextList[InstanceID] = timeText
		self:SetTime()
		if not self:IsTimerExist(self._timeKey)then
			self:TimerStart(self._timeKey,1,false,-1)
		end
	end
	self:SetWndText(nameText,name)
	self:InitTextLineWithLanguage(nameText, -30)
	self:InitTextSizeWithLanguage(nameText, -2)

	local baseClass = self._uiCommonIconList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonIconList[InstanceID] = baseClass
		baseClass:Create(itemRootCommonUI)
	end
	baseClass:SetCommonReward(itemdata.itemType,itemdata.itemId,itemdata.itemNum)
	baseClass:DoApply()

	self:SetWndClick(itemRoot,function ()
		gModelGeneral:ShowCommonItemTipWnd(itemdata,{showSkinCode=true})
	end)
end

function UIWishColleTipsPop:OnTimer(key)
	if self._timeKey == key then
		self:SetTime()
	end
end

function UIWishColleTipsPop:ListItem(list,item, itemdata, itempos)
	local desText = CS.FindTrans(item,"DesText")
	local uiText = LxUiHelper.FindXTextCtrl(desText)
	self:SetWndText(desText,itemdata)
	local height = uiText.preferredHeight
	LxUiHelper.SetSizeWithCurAnchor(item,1,height)
end

function UIWishColleTipsPop:InitMessage()
	--self:WndNetMsgRecv(LProtoIds.QuestListResp,function (...)
	--	self:RefreshDate()
	--end)
	--self:WndNetMsgRecv(LProtoIds.SchoolInfoListResp,function (...)
	--	self:RefreshDate()
	--end)
	--self:WndNetMsgRecv(LProtoIds.SchoolInfoChangeResp,function (...)
	--	self:RefreshDate()
	--end)
end
------------------------------------------------------------------
return UIWishColleTipsPop


