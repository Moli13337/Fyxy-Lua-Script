---
--- Created by BY.
--- DateTime: 2023/10/6 11:16:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEvent2:LWnd
local UIHopeEvent2 = LxWndClass("UIHopeEvent2", LWnd)

UIHopeEvent2.NOTCOMBAT = 0
UIHopeEvent2.COMBAT = 1
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEvent2:UIHopeEvent2()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEvent2:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEvent2:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEvent2:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self:InitToogleList()
	self:RefreshView()
end

function UIHopeEvent2:OnDrawToogleCell(list,item,itemdata,itempos)
	local OnImage = self:FindWndTrans(item,"OnImage")
	local Text = self:FindWndTrans(item,"Text")
	local text = itemdata.text
	local selAns = itemdata.selAns
	self:SetWndText(Text,text)
	local show = selAns	 == self._selAnswer
	CS.ShowObject(OnImage,show)
	self:SetWndClick(item,function()
		self:SelAnsEvent(selAns)
	end)
end

function UIHopeEvent2:InitCommand()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")
	self._duibai = {
		{
			text = ccClientText(20428),
			selAns = UIHopeEvent2.COMBAT,
		},
		{
			text = ccClientText(20429),
			selAns = UIHopeEvent2.NOTCOMBAT,
		},
	}
	self._selAnswer = nil
end

function UIHopeEvent2:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function(...) self:OnClickConfirm() end)
end

function UIHopeEvent2:SelAnsEvent(selAns)
	if self._selAnswer == selAns then return end
	self._selAnswer = selAns
	local uiToogleList = self._uiToogleList
	if uiToogleList then
		local uiList = uiToogleList:GetList()
		uiList:RefreshList()
	end
end

function UIHopeEvent2:InitToogleList()
	local list = self._duibai

	local uiToogleList = self._uiToogleList
	if uiToogleList then
		uiToogleList:RefreshList(list)
	else
		uiToogleList = self:GetUIScroll("uiToogleList")
		self._uiToogleList = uiToogleList
		uiToogleList:Create(self.mToogleList,list,function(...) self:OnDrawToogleCell(...) end)
	end
end

function UIHopeEvent2:InitMessage()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb,ret)
		if pb.eventId ~= self._eventId then return end
		self:WndClose()
	end)
end

function UIHopeEvent2:OnClickConfirm()
	if not self._eventId then return end
	if not self._selAnswer then return end
	if self._selAnswer == 1 then
		gModelDreamTrip:OpenDreamTripEvent1Wnd({eventId = self._eventId,index = self._index})
		self:WndClose()
	else
		gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{self._selAnswer})
	end
end

function UIHopeEvent2:RefreshView()
	local eventId = self._eventId
	local index = self._index
	local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(eventId)
	if not eventData then return end
	local eventRefId = eventData.eventRefId
	local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
	if not eventRef then return end
	local prefab = eventRef.prefab
	if prefab then
		self:CreateWndSpine(self.mSpine,prefab,prefab,false,function(dpSpine)
			dpSpine:SetScale(eventRef.prefabSize or 1)
		end)
	end
	local temp = string.split(eventRef.choose,"|")
	local choose = tonumber(temp[1])
	if choose then
		local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(choose)
		if textRef then
			local dec = ccLngText(textRef.dec)
			self:SetWndText(self.mDesText,dec)
		end
	end
end

function UIHopeEvent2:InitText()
	self:SetWndText(self.mTitleText,ccClientText(20462))
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(10102))
end
------------------------------------------------------------------
return UIHopeEvent2


