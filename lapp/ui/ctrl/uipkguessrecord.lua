---
--- Created by Administrator.
--- DateTime: 2023/10/10 20:07:57
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPkGuessRecord:LWnd
local UIPkGuessRecord = LxWndClass("UIPkGuessRecord", LWnd)

UIPkGuessRecord.GUESS_RESULT_YES = 1 --竞猜正确,已结算
UIPkGuessRecord.GUESS_RESULT_NO = 2 --竞猜错误,已结算
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPkGuessRecord:UIPkGuessRecord()
	self._recordTransList = {}
	self._recordIndexList ={}
	self._uiheadList = {}
	self._waitJumpRecordTimeKey = "_waitJumpRecordTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPkGuessRecord:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	self:ClearRecordInfo()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPkGuessRecord:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPkGuessRecord:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
	self:InitStaticContent()
end

function UIPkGuessRecord:GetGuessCondition(refId)
	local noticeType = self._noticeType
	if noticeType == ModelGeneral.NOTICE_ARENAPEAK_FOREIGN then
		-- local ref = gModelArena:GetArenaGuessConditionRef(refId)
		-- if not ref then
		-- 	printInfoNR("GameTable.ArenaGuessConditionRef[key] is not find, key = "..refId)
			return "", 0, 0
		-- end

		-- return ccLngText(ref.des)
	-- else
	-- 	local ref = gModelCrossServer:GetCrossGuessConditionRef(refId)
	-- 	if not ref then
	-- 		printInfoNR("GameTable.CrossGuessConditionRef[key] is not find, key = "..refId)
	-- 		return "", 0, 0
	-- 	end

	-- 	return ccLngText(ref.des)
	end
end

function UIPkGuessRecord:InitMessage()
	self:WndNetMsgRecv(LProtoIds.PinnacleGuessHistoryResp,function (...) self:OnPinnacleGuessHistoryResp(...) end)
	self:WndNetMsgRecv(LProtoIds.WeekChampGuessHistoryResp,function (...) self:OnWeekChampGuessHistoryRespResp(...) end)
end

function UIPkGuessRecord:GetGlobalGuessCoin()
	local noticeType = self._noticeType
	if noticeType == ModelGeneral.NOTICE_ARENAPEAK_FOREIGN then
		return gModelArena:GetArenaPara("globalGuessCoin")
	-- else
	-- 	return gModelCrossServer:GetChampionPara("globalGuessCoin")
	end
end

function UIPkGuessRecord:OnPinnacleGuessHistoryResp(pbData)
	if self._noticeType ~= ModelGeneral.NOTICE_ARENAPEAK_FOREIGN then return end
	if pbData.type ~= 1 then return end

	--竞猜历史请求返回(巅峰赛)
	self:SetWndVisible(true)

	self:RefreshCombatRecordData(pbData)
	self:RefreshView()
end

function UIPkGuessRecord:GuessCellListItem(list,item, itemdata, itempos)
	local heroTrans = self:FindWndTrans(item,"HeadIcon")
	local nameText  = self:FindWndTrans(item, "NameText")
	local tagImg    = self:FindWndTrans(item, "TagImg/TagImg")
	local desText	= self:FindWndTrans(item, "DesText")
	local resultText = self:FindWndTrans(item, "ResultText")
	local textContent = self:FindWndTrans(item, "TextContent")

	local InstanceID = item:GetInstanceID()
	local guessCondition = itemdata:GetGuessCondition()
	local resultObbs   = itemdata:GetOdds()
	local schedule = itemdata:GetSchedule()
	local targetInfo = itemdata:GetTargetInfo()
	local targetServerData = targetInfo:GetServerData()
	local playerId = targetServerData.playerId
	local name = targetServerData.name
	local power = targetServerData.power
	local playerInfo = {
		trans = heroTrans,
		playerId = playerId,
		name = name,
		icon = targetServerData.head,
		headFrame = targetServerData.headFrame or 20001,
		level = targetServerData.grade,
		power = power,
		figure = targetServerData.figure,
	}
	local uiheadlist = self._uiheadList
	local headIconClass = uiheadlist[InstanceID]
	if not headIconClass then
		headIconClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = headIconClass
	end
	headIconClass:SetHeadData(playerInfo)
	headIconClass:RefreshUI()

	self:SetWndClick(heroTrans,function()
		gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)

	self:SetWndText(nameText, name)

	local tagImgPath =  self._stateImgList[resultObbs]
	if LxUiHelper.IsImgPathValid(tagImgPath) then
		self:SetWndEasyImage(tagImg, tagImgPath)
	end

	local desStr = self:GetGuessCondition(guessCondition)
	self:SetWndText(desText, desStr)
	self:InitTextLineWithLanguage(desText, -30)
	self:InitTextSizeWithLanguage(desText, -2)

	local scheduleStr
	if not schedule or schedule<= 0 then
		scheduleStr = ccClientText(27429)
	else
		scheduleStr = string.replace(ccClientText(27428), schedule)
	end
	self:SetWndText(resultText, scheduleStr)

	local isShowTextContent = resultObbs == UIPkGuessRecord.GUESS_RESULT_YES or resultObbs == UIPkGuessRecord.GUESS_RESULT_NO
	CS.ShowObject(textContent, isShowTextContent)
	if isShowTextContent then
		local textTrans	 = self:FindWndTrans(textContent, "Text")
		local text2Trans = self:FindWndTrans(textContent, "Text2")
		local iconImg	 = self:FindWndTrans(textContent, "Icon/IconImg")

		local isCorrect = resultObbs == UIPkGuessRecord.GUESS_RESULT_YES
		local betCoinNum
		if isCorrect then
			betCoinNum = itemdata:GetResult()
		else
			betCoinNum = itemdata:GetGuessCoin()
		end

		local str  = betCoinNum
		local str2 = isCorrect and ccClientText(27410) or ccClientText(27411)
		local colorKey = isCorrect and "green" or "red"

		str = LUtil.FormatColorStr(str,colorKey)
		str2 = LUtil.FormatColorStr(str2,colorKey)

		local itemIconPath = self._globalGuessCoinIcon
		if LxUiHelper.IsImgPathValid(itemIconPath) then
			self:SetWndEasyImage(iconImg, itemIconPath)
		end
		self:SetWndText(text2Trans, str2)
		self:SetWndText(textTrans, str)
	end
end
--######################################################################################################################
--## View ##############################################################################################################
--######################################################################################################################
function UIPkGuessRecord:RefreshView()
	local haveRecord = not table.isempty(self._recordList)
	CS.ShowObject(self.mNoRecord4, not haveRecord)
	if haveRecord then
		self:RefreshRecordList()
	else
		self:ShowEmptyRecord()
	end
end

function UIPkGuessRecord:InitData()
	self._noticeType = self:GetWndArg("noticeType")

	self._isFirst = true
	self._recordList = {}
	self._stateImgList = {
		[0] = "actionarena_txt_10_1",-- 无记录也算未投注
		[1] = "actionarena_txt_9_1",
		[2] = "actionarena_txt_12_1",
		[3] = "actionarena_txt_10_1",
	}

	self._guessName = self:GetGuessName()
	self:SetWndVisible(false)

	local globalGuessCoin = self:GetGlobalGuessCoin()
	local itemData = LxDataHelper.ParseItem_3(globalGuessCoin)
	local itemId   = itemData.itemId
	self._coinItemId = itemData.itemId
	local itemIcon = gModelItem:GetItemIconByRefId(itemId)
	self._globalGuessCoinIcon = itemIcon

	self:OnGuessHistoryReq()

	self._isForeign = gLGameLanguage:IsForeignVersion()
end

function UIPkGuessRecord:ClearRecordInfo()
	self:ClearCommonIconList(self._recordList)
	self._recordList = {}
end

function UIPkGuessRecord:RecordListDrawItem(list, item, itemdata, itempos)
	self._recordTransList[itempos] = item
	local infoTrans = self:FindWndTrans(item, "Info")
	local nameText = self:FindWndTrans(infoTrans, "NameText")
	local timeText = self:FindWndTrans(infoTrans, "TimeText")
	local toggleBtn = self:FindWndTrans(infoTrans, "ToggleBtn")

	local nameStr = self._guessName
	self:SetWndText(nameText, nameStr)

	local timeStr = itemdata.timeStr
	self:SetWndText(timeText, timeStr)

    self:SetWndClick(toggleBtn, function(...)
        self:OnClickToggle(itempos)
    end)

	--第一次打开界面,自动展开一个
	if self._isFirst and itempos == 1 then
		self._isFirst = false
		self:OnClickToggle(itempos)
	end
end

function UIPkGuessRecord:OnClickToggle(index)
	local tempIndex = 0
	for i, v in pairs(self._recordIndexList) do
		if(v)then
			tempIndex = i
			break
		end
	end
	if(tempIndex>0)then
		local trans=self._recordTransList[tempIndex]
		self:ChangeRecordCell(trans,false,tempIndex)
	end
	if(tempIndex == index)then
		return
	end
	local trans=self._recordTransList[index]
	self:ChangeRecordCell(trans,true,index)

	local maxNum = #self._recordTransList
	if index >= maxNum then	--只有最后一个上提一下
		self._jumpRecordIndex = index
		self:TimerStop(self._waitJumpRecordTimeKey)
		self:TimerStart(self._waitJumpRecordTimeKey,0.1,false,1)
	end
end

function UIPkGuessRecord:CreateEmptyShow()
	local text = self:FindWndTrans(self.mEmptyBtn,"Light/Text")
	local data = {
		refId =  9010,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
		GetBtn = self.mEmptyBtn,
		GetBtnText = text,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIPkGuessRecord:InitStaticContent()
	self:SetWndText(self.mTitleText, ccClientText(27416))
end

function UIPkGuessRecord:GetGuessName()
	if self._noticeType == ModelGeneral.NOTICE_ARENAPEAK_FOREIGN then
		return ccClientText(27400)
	else
		return ccClientText(27401)
	end
end

function UIPkGuessRecord:InitEvent()
	self:SetWndClick(self.mBgBtn, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
end


function UIPkGuessRecord:OnTimer(key)
	if key == self._waitJumpRecordTimeKey then
		self:TimerStop(self._waitJumpRecordTimeKey)
		local list = self._recordUIList:GetList()
		if(not list)then
			return
		end
		list:ScrollToIndex(self._jumpRecordIndex)
	end
end

function UIPkGuessRecord:ShowEmptyRecord()
	self:CreateEmptyShow()
end


--######################################################################################################################
--## Common ############################################################################################################
--######################################################################################################################
function UIPkGuessRecord:RefreshCombatRecordData(pbData)
	self:ClearRecordInfo()
	local combatList = {}
	for k,v in ipairs(pbData.infos) do
		local combatInfo
		if self._noticeType == ModelGeneral.NOTICE_ARENAPEAK_FOREIGN then
			combatInfo = StructArenaGuessInfo:New()
		else
			combatInfo = StructCrossGuessInfo:New()
		end
		combatInfo:CreateByPb(v)
		local time = combatInfo:GetTime()
		local timeStr = LUtil.FormatTimestampSimple(time/1000)
		if not combatList[timeStr] then
			combatList[timeStr] = {}
		end

		table.insert(combatList[timeStr], combatInfo)
	end

	local tempList = {}
	for k,v in pairs(combatList) do
		local data = {
			timeStr = k,
			combatList = v,
		}
		table.insert(tempList, data)
	end

	table.sort(tempList, function(a, b)
		local aCombat = a.combatList[1]
		local bCombat = b.combatList[1]
		return aCombat:GetTime() > bCombat:GetTime()
	end)

	self._recordList = tempList
end

--######################################################################################################################
--## Server ############################################################################################################
--######################################################################################################################
function UIPkGuessRecord:OnGuessHistoryReq()
	if self._noticeType == ModelGeneral.NOTICE_ARENAPEAK_FOREIGN then
		gModelArena:OnPinnacleGuessHistoryReq(1)
	-- else
	-- 	gModelCrossServer:OnWeekChampGuessHistoryReq(1)
	end
end

function UIPkGuessRecord:RefreshRecordList()
	local recordList = self._recordList
	if(self._recordUIList)then
		self._recordUIList:RefreshList(recordList)
	else
		self._recordUIList = self:GetUIScroll("_recordUIList")
		self._recordUIList:Create(self.mRecordList,recordList,function (...) self:RecordListDrawItem(...) end)
		self._recordUIList:EnableScroll(true,false)
	end
end

function UIPkGuessRecord:OnWeekChampGuessHistoryRespResp(pbData)
	if self._noticeType ~= ModelGeneral.NOTICE_CHAMPION_FOREIGN then return end
	if pbData.type ~= 1 then return end

	--竞猜历史请求返回(巅峰赛)
	self:SetWndVisible(true)

	self:RefreshCombatRecordData(pbData)
	self:RefreshView()
end

function UIPkGuessRecord:ChangeRecordCell(trans,bool,index)
	self._recordIndexList [index]=bool
	local upArrow = self:FindWndTrans(trans, "Info/ToggleBtn/UpArrow")
	local downArrow = self:FindWndTrans(trans, "Info/ToggleBtn/DownArrow")
	local cellScroll = self:FindWndTrans(trans,"CellScroll")
	local cellScrollEn = self:FindWndTrans(trans,"CellScrollEn")
	CS.ShowObject(upArrow, bool)
	CS.ShowObject(downArrow, not bool)
	local isForeign = self._isForeign

	CS.ShowObject(cellScroll,bool and not isForeign)
	CS.ShowObject(cellScrollEn, bool and isForeign)
	if not bool then
		return
	end

	local recordData = self._recordList[index]
	local guessList = recordData.combatList

	local InstanceID = trans:GetInstanceID()
	local uiList = self:GetUIScroll(InstanceID)
	if(uiList:GetList())then
		uiList:RefreshData(guessList)
	else
		if isForeign then
			uiList:Create(cellScrollEn,guessList,function (...) self:GuessCellListItem(...) end)
		else
			uiList:Create(cellScroll,guessList,function (...) self:GuessCellListItem(...) end)
		end
	end
end

------------------------------------------------------------------
return UIPkGuessRecord


