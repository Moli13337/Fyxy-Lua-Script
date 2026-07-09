---
--- Created by LCM.
--- DateTime: 2024/3/10 21:02:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeFeatherNew:LWnd
local UIHopeFeatherNew = LxWndClass("UIHopeFeatherNew", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeFeatherNew:UIHopeFeatherNew()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeFeatherNew:OnWndClose()
	if self._sendEvent then
		gModelCommonDreamTrip:CheckSendSpeedUpEvent(self:GetExtraData())
	end
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeFeatherNew:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeFeatherNew:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end


function UIHopeFeatherNew:RefreshView()
	self:SetWndText(self.mTitle,ccClientText(20489))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(10102))
	self:InitPointShowList()
	self:RefreshShow()
end

function UIHopeFeatherNew:InitData()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")
	self._selGrid = nil

	local extraData = self:GetWndArg("extraData")
	self._extraData = extraData
end

function UIHopeFeatherNew:InitEvent()
	self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)
	self:SetWndClick(self.mBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIHopeFeatherNew:OnCommonStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end
	--gModelDreamTrip:OnDreamTripRobberInfoReq()

	gModelCommonDreamTrip:OnDreamTripRobberInfoProcessor(self:GetExtraData())
	self._sendEvent = true
	self:WndClose()
end

------------------------- List -------------------------

function UIHopeFeatherNew:RefreshShow()
	--local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(self._eventId)

	local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,self:GetExtraData())
	if not eventData then return end

	local eventRefId = eventData.eventRefId
	local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
	if not eventRef then return end

	local res = eventRef.res
	local resType = eventRef.resType
	if resType == 1 then
		self:SetWndEasyImage(self.mEventIcon,res,function()
			CS.ShowObject(self.mEventIcon,true)
		end)
	elseif resType == 2 then
		self:CreateWndSpine(self.mSpine,res,res,false)
		CS.ShowObject(self.mSpine,true)
	end


	local str = string.replace(ccClientText(20488),ccLngText(eventRef.name))
	self:SetWndText(self.mCurDescTxt,str)
end

function UIHopeFeatherNew:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb,ret) self:OnCommonStartEventResp(pb) end)

	--- 7.20新增活动梦境之旅
	--self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret) self:OnCommonStartEventResp(pb) end)

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIHopeFeatherNew:SelAnsEvent(selAns)
	if self._selGrid == selAns then return end
	self._selGrid = selAns
	self:InitPointShowList(true)
end

function UIHopeFeatherNew:GetExtraData()
	return self._extraData
end

function UIHopeFeatherNew:OnDrawPointShowCell(list,item,itemdata,itempos)
	local BgTrans = self:FindWndTrans(item,"Bg")
	local PointImgTrans = self:FindWndTrans(item,"PointImg")
	local SelImgTrans = self:FindWndTrans(item,"SelImg")

	local img = itemdata.img
	self:SetWndEasyImage(PointImgTrans,img,function() CS.ShowObject(PointImgTrans,true) end)

	local grid = itemdata.grid
	local show = grid	 == self._selGrid
	CS.ShowObject(SelImgTrans,show)

	self:SetWndClick(BgTrans,function()
		self:SelAnsEvent(grid)
	end)
end
------------------------- List -------------------------


function UIHopeFeatherNew:GetPointShowList()
	local list = {}
	--local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(self._eventId)

	local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,self:GetExtraData())
	if eventData then
		local eventRefId = eventData.eventRefId
		local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
		if eventRef then
			local grid
			local parameter = string.split(eventRef.parameter,";")
			for i,v in ipairs(parameter) do
				v = string.split(v,"=")
				grid = tonumber(v[2])
				table.insert(list,{
					index = tonumber(v[1]),
					grid = grid,
					img = "dreamTrip_icon_" .. grid,
				})
			end
		end
	end
	return list
end

function UIHopeFeatherNew:OnClickEnterBtnFunc()
	if self._selGrid then
		--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{tostring(self._selGrid)})

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
			mapType = extraData.mapType,
			sid = extraData.sid,
			argList = {tostring(self._selGrid)},
		})
	else
		GF.ShowMessage(ccClientText(20490))
	end
end

function UIHopeFeatherNew:InitPointShowList(click)
	local list = self:GetPointShowList()
	local uiPointShowList = self._uiPointShowList
	if uiPointShowList then
		if click then
			uiPointShowList:RefreshData(list)
		else
			uiPointShowList:RefreshList(list)
		end
	else
		uiPointShowList = self:GetUIScroll("uiPointShowList")
		self._uiPointShowList = uiPointShowList
		uiPointShowList:Create(self.mPointShowList,list,function(...) self:OnDrawPointShowCell(...) end)
	end
end

------------------------------------------------------------------
return UIHopeFeatherNew



