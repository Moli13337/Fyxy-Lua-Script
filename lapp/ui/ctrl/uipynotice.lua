---
--- Created by luofuwen.
--- DateTime: 2023/10/30 16:11:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPyNotice:LWnd
local UIPyNotice = LxWndClass("UIPyNotice", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPyNotice:UIPyNotice()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPyNotice:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPyNotice:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPyNotice:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitMessage()
	self:InitView()
end

function UIPyNotice:InitData()
	self._infoList = {}
	self._timeList = {}
	self._timeKey = "PlayNoticeTimeKey"

	self._itemDataList = {}
	local hadNoticeMap = {}

	local isAddOpenTitle = false
	local noticeList = gModelGeneral:GetNoticeWndList()
	if #noticeList > 0 then
		isAddOpenTitle = true
		local itemData = {}
		itemData.text = LUtil.FormatColorStr(ccClientText(13419), "lightGreen")
		itemData.itemType = 1
		table.insert(self._itemDataList, itemData)
	end
	-- 添加开启活动玩法--进行中
	for idx,data in ipairs(noticeList) do
		local itemData = {}
		local ref = data.ref
		itemData.ref = ref
		itemData.itemType = 2
		itemData.isOpen = 2
		itemData.text = ccClientText(13419)
		table.insert(self._itemDataList, itemData)

		hadNoticeMap[ref.refId] = ref
	end

	local ForeshowRefList = {}
	for refId,ref in pairs(GameTable.ForeshowRef) do
		table.insert(ForeshowRefList, ref)
	end
	table.sort(ForeshowRefList, function(a,b)
		return a.range < b.range
	end)

	-- 添加开启的非活动玩法--进行中
	for idx,ref in pairs(ForeshowRefList) do
		if not hadNoticeMap[ref.refId] and gModelFunctionOpen:CheckIsOpened(ref.activityFunction, false) then
			if string.isempty(ref.showTime) then
				if not isAddOpenTitle then
					isAddOpenTitle = true
					local itemData = {}
					itemData.text = LUtil.FormatColorStr(ccClientText(13419), "lightGreen")
					itemData.itemType = 1
					table.insert(self._itemDataList, itemData)
				end

				hadNoticeMap[ref.refId] = ref

				local itemData = {}
				itemData.ref = ref
				itemData.itemType = 2
				itemData.isOpen = 2
				itemData.text = ccClientText(13419)
				table.insert(self._itemDataList, itemData)
			end
		end
	end
	-- 添加即将开启活动玩法--即将到来
	isAddOpenTitle = false
	for idx,ref in pairs(ForeshowRefList) do
		if not hadNoticeMap[ref.refId] and gModelFunctionOpen:CheckIsOpened(ref.activityFunction, false) then
			if not isAddOpenTitle then
				isAddOpenTitle = true
				local itemData = {}
				itemData.text = LUtil.FormatColorStr(ccClientText(13420), "midYellow")
				itemData.itemType = 1
				table.insert(self._itemDataList, itemData)
			end
			hadNoticeMap[ref.refId] = ref

			local itemData = {}
			itemData.ref = ref
			itemData.itemType = 2
			itemData.isOpen = 1
			itemData.text = ccClientText(13420)
			table.insert(self._itemDataList, itemData)
		end
	end
	-- 添加未开启的玩法
	--local isAddNotOpenTitle = false
	--for idx,ref in pairs(ForeshowRefList) do
	--	if not hadNoticeMap[ref.refId] then
	--		if not isAddNotOpenTitle then
	--			isAddNotOpenTitle = true
	--			local itemData = {}
	--			itemData.text = LUtil.FormatColorStr(ccClientText(13421), "lightRed")
	--			itemData.itemType = 1
	--			table.insert(self._itemDataList, itemData)
	--		end
    --
	--		hadNoticeMap[ref.refId] = ref
    --
	--		local itemData = {}
	--		itemData.ref = ref
	--		itemData.itemType = 2
	--		itemData.isOpen = 0
	--		itemData.text = ccClientText(13421)
	--		table.insert(self._itemDataList, itemData)
	--	end
	--end

	for idx,itemData in pairs(self._itemDataList) do
		local onClickFun = nil
		local jump = nil
		if itemData.itemType == 2 then
			local ref = itemData.ref
			local refId = ref.refId
			if(refId == ModelGeneral.NOTICE_ENDLES)then
				onClickFun = function()
					if gModelEndles:HaveNewSelectBuff() then
						local combatData = gModelEndles:FormatEndlessCombatData()
						GF.OpenWnd("UIUendBfPop",{combatData = combatData})
					else
						jump = ref.activityFunction
						if gModelFunctionOpen:CheckIsOpened(jump,true) then
							gModelFunctionOpen:Jump(jump)
						end
					end
				end
			elseif(refId == ModelGeneral.NOTICE_MELEE)then
				local state = ref.state or 0
				if(state == 3)then
					jump = ref.activityFunction
				elseif(state == 4 or state == 5)then
					jump = ref.activityFunction2
				else
					jump = ref.foreshowFunction
				end
				onClickFun = function()
					if ModelGuild:GetBHaveGuild()then
						gModelFunctionOpen:Jump(jump)
					elseif gModelFunctionOpen:CheckIsOpened(12100000,true) then
						gModelFunctionOpen:Jump(12100000)
						GF.ShowMessage(ccClientText(17969))
					end
				end
			else

				local state = ref.state or 0
				if(state == 1)then
					jump = ref.foreshowFunction
				else
					jump = ref.activityFunction
				end
				onClickFun = function()
					if gModelFunctionOpen:CheckIsOpened(jump,true) then
						gModelFunctionOpen:Jump(jump)
					end
				end
			end
			itemData.jump = jump
			itemData.onClickFun = onClickFun
		end
	end

end
function UIPyNotice:GetOpenInfo(itemData, defaultText, effNode, openInfoNode)
	local ref = itemData.ref
	local text = defaultText or ""

	if ref.refId == ModelGeneral.NOTICE_ARENAPEAK then
		local state = gModelArena:GetPeakState()
		if state == ModelArena.PEAK_STATE_BEFORE then
			self:DestroyWndEffectByKey(ref.refId)
			local peakStartTime = gModelArena:GetPeakStartTime()
			local peakDate= LUtil.OSDate("*t",peakStartTime)
			local timeStr = string.format("%d%s%d%s%d:%02d%s",peakDate["month"],ccClientText(11808),
					peakDate["day"],ccClientText(11807),peakDate["hour"],peakDate["min"],ccClientText(11809))
			text = ccClientText(11810)..LUtil.FormatColorStr(timeStr,"lightGreen") --赛程
		elseif state ==ModelArena.PEAK_STATE_STARTED then
			local stateStr = gModelArena:GetPeakRoundStr(gModelArena:GetPeakRound())
			local peakStageStr = stateStr..ccClientText(11811)
			text = ccClientText(11810).. LUtil.FormatColorStr(peakStageStr,"lightGreen") --赛程

			if effNode then
				self:CreateWndEffect(effNode, "fx_jjc_gongnengkaiqi", ref.refId, Vector3.New(100,120,120), false, false)
			end
		elseif state ==ModelArena.PEAK_STATE_END then
			self:DestroyWndEffectByKey(ref.refId)
			text = ccClientText(11810)..LUtil.FormatColorStr(ccClientText(11812),"lightGreen")
		end
	-- 【G公共支持】删除跨服天梯和跨服周冠玩法
	-- elseif ref.refId == ModelGeneral.NOTICE_CHAMPION then
	-- 	local dailyGameId = 202
	-- 	local dailyGameRef = GameTable.DailyGamePlayRef[dailyGameId]
	-- 	text =  ccLngText(dailyGameRef.desc)
	-- 	if gModelCrossServer:IsChampOpen() then
	-- 		if effNode then
	-- 			self:CreateWndEffect(effNode, "fx_jjc_gongnengkaiqi", ref.refId, Vector3.New(100,120,120), false, false)
	-- 		end
	-- 	else
	-- 		self:DestroyWndEffectByKey(ref.refId)
	-- 	end
	elseif ref.refId == ModelGeneral.NOTICE_ENDLES then
		-- 无尽试炼
		text = ccClientText(12152)
		--[[
		local dailyGameId = 102
		local dailyGameRef = GameTable.DailyGamePlayRef[dailyGameId]
		local refId,timeTextR = dailyGameRef.refId,dailyGameRef.timeText
		self._timeList[refId] = {text = openInfoNode,str = timeTextR}
		--]]

	elseif ref.refId == ModelGeneral.NOTICE_MELEE then
		text = ccClientText(17972)
		local state = ref.state or 0
		if state == 4 or state == 5 then
			if effNode then
				self:CreateWndEffect(effNode, "fx_jjc_gongnengkaiqi", ref.refId, Vector3.New(100,120,120), false, false)
			end
		else
			self:DestroyWndEffectByKey(ref.refId)
		end
	elseif ref.refId == 105 then
		-- 奇境探险
		local dailyGameId = 104
		local dailyGameRef = GameTable.DailyGamePlayRef[dailyGameId]
		local refId,timeTextR = dailyGameRef.refId,dailyGameRef.timeText
		self._timeList[refId] = {text = openInfoNode,str = timeTextR}

	elseif ref.refId == 106 then
		-- 异界入侵
		local dailyGameId = 107
		local dailyGameRef = GameTable.DailyGamePlayRef[dailyGameId]
		local refId,timeTextR = dailyGameRef.refId,dailyGameRef.timeText
		self._timeList[refId] = {text = openInfoNode,str = timeTextR}

	elseif ref.refId == 107 then
		-- 梦境之旅
		local dailyGameId = 105
		local dailyGameRef = GameTable.DailyGamePlayRef[dailyGameId]
		local refId,timeTextR = dailyGameRef.refId,dailyGameRef.timeText
		self._timeList[refId] = {text = openInfoNode,str = timeTextR}
	end

	return text
end

function UIPyNotice:GetResidueTimeByRefId(refId,str)
	if not self._infoList then
		return ""
	end
	local info = self._infoList[refId]
	local timeText = info and info.timeText or ""
	if timeText == "" then
		return ""
	end
	local timespan = tonumber(timeText/1000 - GetTimestamp())
	if timespan < 0 then
		return ""
	end
	local timeStr = LUtil.FormatTimespanCn(timespan)
	return string.replace(ccLngText(str),timeStr)
end

function UIPyNotice:InitMessage()
	self:WndNetMsgRecv(LProtoIds.DailyGameInfoResp,function (pb)
		self._infoList = gModelGeneral:GetDailyGameInfoResp(pb)
		self:SetTime()
		self:TimerStart(self._timeKey, 1, false, -1)
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function()
		self:RefreshReq()
	end)

	local refList = gModelDungeonDaily:GetGameTypes()
	local list = {}
	for i, v in pairs(refList) do
		table.insert(list,v.refId)
	end
	gModelGeneral:OnDailyGameInfoReq(list)
end

function UIPyNotice:ShowCardItem(node, itemData)
	local bg = self:FindWndTrans(node,"bg")
	local titleImg = self:FindWndTrans(node,"titleImg")
	local playInfo = self:FindWndTrans(node,"playInfo")
	local lockMask = self:FindWndTrans(node,"lockMask")
	local infoBtn = self:FindWndTrans(node,"infoBtn")
	local openInfo = self:FindWndTrans(node,"openInfo")
	local gotoBtn = self:FindWndTrans(node,"gotoBtn")
	local effNode = self:FindWndTrans(node,"eff")

	local ref = itemData.ref
	self:SetWndEasyImage(bg, ref.cellBg)
	self:SetWndEasyImage(titleImg, ref.cellName)
	self:SetWndText(playInfo, ccLngText(ref.cellNameDec))

	self:SetWndClick(infoBtn,function()
		GF.OpenWnd("UIBzTips", {refId = ref.helpTip})
	end,LSoundConst.CLICK_ERROR_COMMON)

	if itemData.isOpen > 0 then
		CS.ShowObject(lockMask, false)
		local text = self:GetOpenInfo(itemData, itemData.text, effNode, openInfo)
		self:SetWndText(openInfo, text)
		self:SetWndClick(node,itemData.onClickFun)
		if itemData.isOpen == 1 then
			CS.ShowObject(gotoBtn, false)
		else
			CS.ShowObject(gotoBtn, true)
			self:CreateWndEffect(gotoBtn,"fx_qianwangcanyu",ref.refId,100)

		end
	else
		CS.ShowObject(lockMask, true)
		CS.ShowObject(gotoBtn, false)
		local functionId = ref.activityFunction

		local isOpen, msg = gModelFunctionOpen:CheckIsOpened(functionId,false)
		if string.isempty(msg) then
			msg = ccClientText(17561)
		end
		self:SetWndText(openInfo, msg)

		self:SetWndClick(node,function()
			if gModelFunctionOpen:CheckIsOpened(functionId,true) then
				gModelFunctionOpen:Jump(functionId)
			end
		end)
	end
end

function UIPyNotice:OnTimer(key)
	if(self._timeKey == key)then
		self:SetTime()
	end
end

function UIPyNotice:SetTime()
	for i, v in pairs(self._timeList) do
		local timeStr =self:GetResidueTimeByRefId(i,v.str)
		self:SetWndText(v.text,timeStr)
	end
end

function UIPyNotice:InitView()
	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)

	local list = self:GetUIScroll("uiList")
	list:Create(self.mItemList, self._itemDataList, function (...) self:OnDrawCardCell(...) end, UIItemList.NORMAL,false)
	local uiList = list:GetList()
	uiList:EnableScroll(true,false)
	uiList:RefreshList()

end

function UIPyNotice:ShowTitleItem(node, itemData)
	local title = CS.FindTrans(node,"title")
	self:SetWndText(title, itemData.text)
end

function UIPyNotice:OnDrawCardCell(list, item, itemdata, itempos)
	local titleNode = CS.FindTrans(item,"titleNode")
	local cardNode = CS.FindTrans(item,"cardNode")
	if itemdata.itemType == 1 then
		CS.ShowObject(titleNode, true)
		CS.ShowObject(cardNode, false)

		self:ShowTitleItem(titleNode, itemdata)
	else
		CS.ShowObject(titleNode, false)
		CS.ShowObject(cardNode, true)

		self:ShowCardItem(cardNode, itemdata)
	end
end

------------------------------------------------------------------
return UIPyNotice


