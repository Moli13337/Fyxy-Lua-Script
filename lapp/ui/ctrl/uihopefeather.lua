---
--- Created by Administrator.
--- DateTime: 2023/10/8 23:35:23
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeFeather:LWnd
local UIHopeFeather = LxWndClass("UIHopeFeather", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeFeather:UIHopeFeather()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeFeather:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeFeather:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeFeather:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self:InitTxt()
	self:InitToogleList()
end

function UIHopeFeather:InitCommand()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")
	self._selGrid = nil
end

function UIHopeFeather:InitMessage()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb,ret)
		if pb.eventId ~= self._eventId then return end
		gModelDreamTrip:OnDreamTripRobberInfoReq()
		self:WndClose()
	end)
end

function UIHopeFeather:OnDrawToogleCell(list,item,itemdata,itempos)
	local OnImage = self:FindWndTrans(item,"OnImage")
	local Text = self:FindWndTrans(item,"Text")
	local index = itemdata.index
	local grid = itemdata.grid
	local gridTxt = string.replace(ccClientText(20409),grid)
	self:SetWndText(Text,gridTxt)
	local show = grid	 == self._selGrid
	CS.ShowObject(OnImage,show)
	self:SetWndClick(item,function()
		self:SelAnsEvent(grid)
	end)
end

function UIHopeFeather:InitToogleList()
	local list = self:GetToogleList()
	local uiToogleList = self._uiToogleList
	if uiToogleList then
		uiToogleList:RefreshData(list)
	else
		uiToogleList = self:GetUIScroll("uiToogleList")
		self._uiToogleList = uiToogleList
		uiToogleList:Create(self.mToogleList,list,function(...) self:OnDrawToogleCell(...) end)
	end
end

function UIHopeFeather:GetToogleList()
	local list = {}
	local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(self._eventId)
	if eventData then
		local eventRefId = eventData.eventRefId
		local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
		if eventRef then
			local parameter = string.split(eventRef.parameter,";")
			for i,v in ipairs(parameter) do
				v = string.split(v,"=")
				table.insert(list,{
					index = tonumber(v[1]),
					grid = tonumber(v[2]),
				})
			end
		end
	end
	return list
end

function UIHopeFeather:SelAnsEvent(selAns)
	if self._selGrid == selAns then return end
	self._selGrid = selAns
	local uiToogleList = self._uiToogleList
	if uiToogleList then
		local uiList = uiToogleList:GetList()
		uiList:RefreshList()
	end
end

function UIHopeFeather:OnClickConfirm()
	if self._selGrid then
		gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{tostring(self._selGrid)})
	else
		GF.ShowMessage(ccClientText(20431))
	end
end

function UIHopeFeather:InitTxt()
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(10102))
	local index = self._index
	local eventId = self._eventId
	local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(eventId,index)
	if not eventData then return end
	local eventRefId = eventData.eventRefId
	local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
	if not eventRef then return end
	local choose = tonumber(eventRef.choose)
	local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(choose)
	if not textRef then return end
	local dec = ccLngText(textRef.dec)
	self:SetWndText(self.mDesText,dec)
	local prefab = eventRef.prefab
	self:CreateWndSpine(self.mSpine,prefab,prefab,false,function(dpSpine)
		dpSpine:SetScale(eventRef.prefabSize)
	end)
	self:SetWndText(self.mTitleText,ccLngText(eventRef.name))
end

function UIHopeFeather:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnConfirm, function(...) self:OnClickConfirm() end)
end



------------------------------------------------------------------
return UIHopeFeather


