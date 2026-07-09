---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringPkRecord:LWnd
local UIringPkRecord = LxWndClass("UIringPkRecord", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringPkRecord:UIringPkRecord()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringPkRecord:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringPkRecord:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringPkRecord:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:WndNetMsgRecv(LProtoIds.PinnaclePaceGuessListResp,function (...) self:OnPinnaclePaceGuessListResp(...)  end)
	gModelArena:PinnaclePaceGuessListReq(1)
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIringPkRecord:ShowDetail(data)
	local wnd = GF.FindFirstWndByName("UIringPk")
	local pagePara = {}
	if wnd then
		pagePara = wnd:GetPagePara()
	end
	local extraData = {
		closeAfterVideo = function() self:OnPlayEnd(pagePara) end,
		meName = data.leftName,
		otherName = data.rightName,
		videoType = LVideoTypeConst.PEAK,
		serverId = data.serverId
	}

	gLFightManager:OnOpenBattleDetails(data.reportId,extraData,data.serverId)
end

function UIringPkRecord:OnPlayEnd(pagePara,itempos)
	GF.ChangeMap("LCityMap")

	GF.OpenWndBottom("UIringPk",{page=pagePara.page,para =pagePara.para})
	GF.OpenWnd("UIringPkRecord",{itempos = itempos})
end

function UIringPkRecord:OnPinnaclePaceGuessListResp(pb)
	local cnt = #pb.combatInfos
	local noRecord = false
	if cnt ==0 then
		noRecord= true
	end
	CS.ShowObject(self.mNoRecord2,noRecord)
	CS.ShowObject(self.mRecordList,not noRecord)

	if not noRecord then
		self:ShowList(pb.combatInfos)
	end
end

function UIringPkRecord:Watch(data,itempos)
	local reportId = data.reportId
	local wnd = GF.FindFirstWndByName("UIringPk")
	local pagePara = {}
	if wnd then
		pagePara = wnd:GetPagePara()
	end
	local combatExtraDatas = {
		battleEndfun = function() self:OnPlayEnd(pagePara,itempos) end,
		canSkip = true,
		meName = data.leftName,
		otherName = data.rightName,
		videoType = LVideoTypeConst.PEAK,
		serverId = data.serverId
	}
	gLFightManager:OnPlayBattleVideo(reportId,combatExtraDatas,LCombatTypeConst.COMBAT_BATTLE_VIDEO)

end

function UIringPkRecord:SetStaticContent()
	self:SetWndText(self.mTitle,ccClientText(11820))
	local text = self.mEmptyText
	local emptyList = self:GetCommonEmptyList("_empty")
	local data =
	{
		refId= 5002,
		IntroTran= text,
		--TextBgTran,
		--IconTran,
		--GetBtn,
		--GetBtnText
		--ButtonRoot,
	}
	emptyList:RefreshUI(data)
end

function UIringPkRecord:InitData()
	self._arrowPathList=
	{
		"public_arrow_3",
		"actionarena_ui_arrow_1",
	}
end

function UIringPkRecord:ShowList(infos)

	local itemPos = self:GetWndArg("itempos") or 0

	local records = self:GetRecordList(infos)
	local cnt = #records
	local noRecord = false
	if cnt ==0 then
		noRecord= true
	end
	CS.ShowObject(self.mNoRecord2,noRecord)
	CS.ShowObject(self.mRecordList,not noRecord)
	if noRecord then
		return
	end

	local uiList = self:GetUIScroll("recordList")
	uiList:Create(self.mRecordList,records,function (...) self:OnDrawItem(...) end,UIItemList.SUPER)

	if itemPos<= cnt then
		uiList:MoveToPos(itemPos)
	end
end

function UIringPkRecord:GetRecordList(infos)
	local recordList = {}
	--local curStage = 0
	local selfPlayerId = gModelPlayer:GetPlayerId()

	--local needTitle = {
	--	[ModelArena.PEAK_STAGE_SELECTION]=true,
	--	[ModelArena.PEAK_STAGE_32]=true,
	--	[ModelArena.PEAK_STAGE_SEMIFINAL]=true,
	--	[ModelArena.PEAK_STAGE_FINAL]=true,
	--}
	local cnt = #infos

	for i = cnt, 1, -1 do
		local data = infos[i]
		-- local isEnd = gModelArena:GetCombatIsEnd(data.round)
		-- local winner = isEnd and data.winner or 0
		local winner = data.winner

		local isEndRound = data.round < gModelArena:GetPeakRound() or gModelArena:GetPeakState() == 3
		if winner ~= 0 and isEndRound then
			local itemdata = {}
			local otherPlayer = nil
			local selfPlayer = nil
			local result = nil
			if selfPlayerId == data.attack.playerId then
				selfPlayer = data.attack
				otherPlayer = data.defense
				result = winner == 1
			else
				selfPlayer = data.defense
				otherPlayer = data.attack
				result = winner == 2
			end

			itemdata.playerId = otherPlayer.playerId
			itemdata.name = otherPlayer.name
			itemdata.power = otherPlayer.power
			itemdata.level = otherPlayer.grade
			itemdata.result = result
			itemdata.change = selfPlayer.change
			itemdata.head = otherPlayer.head
			itemdata.reportId = data.reportId
			itemdata.serverId = data.serverId


			itemdata.round = data.round

			itemdata.leftName = data.attack.name
			itemdata.rightName = data.defense.name

			local stage = gModelArena:GetCombatStage(data.round)
			itemdata.stage = stage
			--if stage~=curStage and needTitle[stage] then
			--	local title = {}
			--	title.isTitle = true
			--	title.stage = stage
			--	curStage = stage
			--	table.insert(recordList,title)
			--end
			table.insert(recordList, itemdata)
		end
	end
	return recordList
end

function UIringPkRecord:OnDrawItem(list,item,itemdata,itempos)
	local lookBtn = self:FindWndTrans(item,"LookBtn")
	local lookBtnText = self:FindWndTrans(lookBtn,"XUIText")

	local reportBtn = self:FindWndTrans(item,"ReportBtn")
	local reportBtnText = self:FindWndTrans(reportBtn,"XUIText")

	local playertext = self:FindWndTrans(item,"PlayerText")
	local headIcon = self:FindWndTrans(item,"HeadIcon")

	local force = self:FindWndTrans(item,"PowerBg")
	local forceText = self:FindWndTrans(force,"PowerText")

	local score = self:FindWndTrans(item,"Score")
	local scoreIcon = self:FindWndTrans(score,"icon")
	local scoreSign = self:FindWndTrans(score,"sign")
	local scoreText = self:FindWndTrans(score,"text")

	local title = self:FindWndTrans(item,"TitleImg")
	local titleResult = self:FindWndTrans(title,"TitleText")


	local str = ccClientText(10357)
	local color = "#c81212"
	if itemdata.result then
		str=ccClientText(10356)--  "成功"
		color = "#1b62a3"
	end

	-- local roundStr =""
	-- if itemdata.stage ==1 then
	local roundStr = gModelArena:GetPeakRoundStr(itemdata.round)
	-- end

	-- local stageStr = self._stageStrList[itemdata.stage]
	-- str =string.format("%s(%s%s)",str,stageStr,roundStr)
	str = string.replace("#a1#(#a2#)", str, roundStr)

	self:SetWndText(titleResult,LUtil.FormatColorStr(str,color))


	self:SetWndText(lookBtnText,ccClientText(11844))
	self:SetWndText(reportBtnText,ccClientText(10359))
	self:SetWndText(playertext,itemdata.name)

	local upOrDownPath = nil
	local color ="green"
	local changeStr = nil
	local showArrow = true
	if itemdata.change>0 then
		upOrDownPath= self._arrowPathList[1]
		changeStr =LUtil.FormatColorStr(math.abs(itemdata.change),color)
	elseif itemdata.change == 0 then
		changeStr =LUtil.FormatColorStr(ccClientText(10333),color)
		showArrow = false
	else
		color = "red"
		upOrDownPath= self._arrowPathList[2]
		changeStr =LUtil.FormatColorStr(math.abs(itemdata.change),color)
	end
	if upOrDownPath then
		self:SetWndEasyImage(scoreSign,upOrDownPath)
	end

	CS.ShowObject(scoreSign,showArrow)
	self:SetWndText(scoreText,changeStr)

	self:SetWndText(forceText,LUtil.PowerNumberCoversion(itemdata.power))
	self:SetWndClick(lookBtn,function() self:Watch(itemdata,itempos) end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(reportBtn,function() self:ShowDetail(itemdata) end,LSoundConst.CLICK_BUTTON_COMMON)

	local playerInfo={
		trans=headIcon,
		icon=itemdata.head,
		headFrame=itemdata.headFrame,
		name=itemdata.name,
		level=itemdata.grade,
	}

	local InstanceID = item:GetInstanceID()
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)

	self:SetWndClick(headIcon,function ()
		gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)
end


------------------------------------------------------------------
return UIringPkRecord


