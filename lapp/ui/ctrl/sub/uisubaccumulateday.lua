---
--- Created by BY.
--- DateTime: 2023/10/10 15:01:03
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubAccumulateDay:LChildWnd
local UISubAccumulateDay = LxWndClass("UISubAccumulateDay", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubAccumulateDay:UISubAccumulateDay()
	---@type table<number,CommonIcon>
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubAccumulateDay:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubAccumulateDay:OnCreate()
	LChildWnd.OnCreate(self)
	self.pages={}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubAccumulateDay:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubAccumulateDay:OnClickGoOn(jump)--前往
	if(not jump or jump == "")then
		GF.ShowMessage(ccClientText(16002))
		return
	end
	gModelFunctionOpen:Jump(jump,self:GetWndName())
end

function UISubAccumulateDay:InitEvent()
	self:SetWndClick(self.mHelpBtn,function ()
		self:OnClickHelp()
	end)
end

function UISubAccumulateDay:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityData then
		return
	end
	local data = activityData.config
	self._description = data.description
	if data then
		local showHelp = data.helpTips == 1
		local pos = data.helpTipsPosition
		CS.ShowObject(self.mHelpBtn,showHelp)
		if showHelp then
			self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(pos))
		end
	end
	local text = data.text
	if text then
		self:SetWndText(self.mDesText,text)
	end

	gModelActivity:OnActivityPageReq(self._sid)
end

function UISubAccumulateDay:ResetData(pb)
	local sid=pb.sid
	if(self._sid~=sid)then
		return
	end
	for i, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		self.pages[v.pageId]=page
	end
	self:RefreshData()
end

function UISubAccumulateDay:RefreshData()
	if table.isempty(self.pages) then return end
	local list = {}
	for k,v in pairs(self.pages[1].entry) do
		table.insert(list, v)
	end

	table.sort(list,function (a,b)
		local aStatus = a.goalData.status == 2 and 1 or 0
		local bStatus = b.goalData.status == 2 and 1 or 0
		if(aStatus ~= bStatus)then
			return aStatus < bStatus
		end
		return a.sort < b.sort
	end)

	if(not self._uiList)then
		self._uiList = self:GetUIScroll("uiList")
		self._uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end,UIItemList.WRAP)
	else
		self._uiList:RefreshList(list)
	end
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	local data = JSON.decode(activityData.moreInfo)
	local day = data.day
	if(self._description)then
		self:SetWndText(self.mTimeText,string.replace(self._description,day))
		CS.ShowObject(self.mTimeBg,true)
	end
end

function UISubAccumulateDay:OnClickHelp()--点击帮助
	local _sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	if not activityData then
		return
	end
	local data = activityData.config
	local title = gModelActivity:GetLngNameByActivitySid(_sid)
	local content = data.helpTipsContent
	GF.OpenWnd("UIBzTips",{title= title,text = content})
end

function UISubAccumulateDay:ListItem(list , item, itemdata, itempos)
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local title = CS.FindTrans(item,"titleBg/title")
	local titleBg = CS.FindTrans(item,"titleBg")
	local rewardList = CS.FindTrans(item,"rewardList")
	local goBtnTrans = CS.FindTrans(item,"GoBtn")
	local getBtnTrans = CS.FindTrans(item,"GetBtn")
	local ShowTrans = CS.FindTrans(item,"Show")

	local status = itemdata.goalData.status

	self:SetWndEasyImage(titleBg,entryCfg.icon)
	self:SetWndText(title,entryCfg.description)
	CS.ShowObject(goBtnTrans, status == 0)
	CS.ShowObject(getBtnTrans, status == 1)
	CS.ShowObject(ShowTrans,status == 2)

	self:SetWndButtonText(goBtnTrans, entryCfg.jumpDesc)
	self:SetWndClick(goBtnTrans,function ()
		self:OnClickGoOn(entryCfg.jumpId)
	end)
	self:SetWndButtonText(getBtnTrans, ccClientText(16000))
	self:SetWndClick(getBtnTrans,function ()
		self:OnClickGet(itemdata.pageId,itemdata.entryId)
	end)

	local InstanceID = item:GetInstanceID()
	local itemList = LxDataHelper.ParseItem(entryCfg.reward)
	local uiIconEasyList = self._uiList:GetItemCls(InstanceID)
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiList:SetItemCls(InstanceID, uiIconEasyList)
		uiIconEasyList:Create(self, rewardList)
		uiIconEasyList:SetIconParentPath("itemRoot")
	end
	uiIconEasyList:RefreshList(itemList)
end
function UISubAccumulateDay:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...)
		self:OnActivityConfigData(...)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UISubAccumulateDay:OnClickGet(pageId, entryId)--领取
	gModelActivity:OnActivityReceiveGoalReq(self._sid,pageId,entryId)
end

function UISubAccumulateDay:InitCommand()
	self._sid = self:GetWndArg("sid")
	gModelActivity:ReqActivityConfigData(self._sid)
end
------------------------------------------------------------------
return UISubAccumulateDay


