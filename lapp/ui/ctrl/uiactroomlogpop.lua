---
--- Created by BY.
--- DateTime: 2023/10/20 16:41:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActRoomLogPop:LWnd
local UIActRoomLogPop = LxWndClass("UIActRoomLogPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActRoomLogPop:UIActRoomLogPop()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActRoomLogPop:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActRoomLogPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActRoomLogPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIActRoomLogPop:LogListItem(list, item, itemdata, itempos)
	local root1 = self:FindWndTrans(item,"Root1")
	local root2 = self:FindWndTrans(item,"Root2")

	local type = itemdata.type
	CS.ShowObject(root1,type == 1)
	CS.ShowObject(root2,type == 2)
	if type == 1 then
		self:TimeItem(root1, itemdata)
		LxUiHelper.SetSizeWithCurAnchor(item,1,34)
	else
		self:LogItem(root2, itemdata)
		LxUiHelper.SetSizeWithCurAnchor(item,1,100)
	end
end
function UIActRoomLogPop:TimeItem(item, itemdata)
	local timeText = self:FindWndTrans(item,"TimeText")

	local str = LUtil.FormatTimeStr(itemdata.time,ccClientText(27644))
	self:SetWndText(timeText,str)
end

function UIActRoomLogPop:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIActRoomLogPop:RefreshLog()
	local logs = gModelActivity:GetSweetsCountryLogs()
	if not logs then return end
	local list = {}
	if #logs > 0 then
		table.sort(logs,function (a,b)
			return a.time > b.time
		end)
		local time = tonumber(logs[1].time)
		table.insert(list,{type = 1,time = time})
		for i, v in ipairs(logs) do
			local _time = tonumber(v.time)
			local cTime = _time/60000/60/60/24 - time/60000/60/60/24
			if cTime < -1 then
				time = _time
				table.insert(list,{type = 1,time = time})
			end
			v.type = 2
			table.insert(list,v)
		end
	end

	local len = #list
	CS.ShowObject(self.mNoRecord3,len <= 0)
	if len <= 0 then
		self:CreateEmptyShow(14008)
	end

	local uiLogList = self._uiLogList
	if uiLogList then
		uiLogList:RefreshList(list)
	else
		uiLogList = self:GetUIScroll("UIActRoomLogPop_mLogSuper")
		self._uiLogList = uiLogList
		uiLogList:Create(self.mLogSuper,list,function (...) self:LogListItem(...) end,UIItemList.SUPER)
	end
end
function UIActRoomLogPop:InitEvent()
	self:SetWndClick(self.mBg,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function ()self:WndClose() end)
end
function UIActRoomLogPop:InitMessage()
	--self:WndNetMsgRecv(LProtoIds.ActivitySweetsCountryLogsResp,function (pb)
	--	self:RefreshLog()
	--end)
end
function UIActRoomLogPop:InitCommand()
	local sid = self:GetWndArg("sid")
	self:SetWndText(self.mLblBiaoti,ccClientText(27643))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	gModelActivity:OnActivitySweetsCountryLogsReq(sid)
end
function UIActRoomLogPop:LogItem(item, itemdata)
	local headIcon = self:FindWndTrans(item,"HeroRoot/HeadIcon")
	local desText = self:FindWndTrans(item,"DesText")
	local timeText = self:FindWndTrans(item,"TimeText")

	local timeStr = LUtil.FormatTimeStr(itemdata.time,"[%H:%M]")
	local playerName = itemdata.playerName
	local consume = LxDataHelper.ParseItem_3(itemdata.consume)
	local info = {
		icon = itemdata.head,
		headFrame = itemdata.headFrame,
	}
	local InstanceID = item:GetInstanceID()
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	info.trans = headIcon
	baseClass:SetHeadData(info)

	local desStr = ccClientText(27642)
	local name = gModelGeneral:GetCommonItemColorName(consume,"*")
	local _playerName = LUtil.FormatColorStr(playerName,"blue")
	self:SetWndText(desText,string.replace(desStr,_playerName,name))
	self:SetWndText(timeText,timeStr)
	self:SetWndClick(headIcon,function ()
		gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)
end
------------------------------------------------------------------
return UIActRoomLogPop


