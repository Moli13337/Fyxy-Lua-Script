---
--- Created by Administrator.
--- DateTime: 2025/6/18 10:51:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITwoHundredLottery:LWnd
local UITwoHundredLottery = LxWndClass("UITwoHundredLottery", LWnd)
------------------------------------------------------------------

local taskEnum = ModelActivity.HERO_SELECT_H5_1
local lotteryEnum = ModelActivity.HERO_SELECT_H5_2
local shareType = ModelChat.CHAT_SHARE_33

-- 抽奖
local STATUS_0 = 0
-- 领取
local STATUS_1 = 1
-- 已领取
local STATUS_2 = 2

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITwoHundredLottery:UITwoHundredLottery()
	--改为国内也显示
	self._isShowNewTop = true

	---@type number 当前轮次
	self._curRound = 1

	---@type StructActivityPage[]
	self._pages = nil

	self._timeKey = "_timeKey"

	self._status = STATUS_0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITwoHundredLottery:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITwoHundredLottery:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITwoHundredLottery:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
end

function UITwoHundredLottery:OnClickRoundCell(itemdata)
	if self:CheckIsSelRound(itemdata)then return end

	self:JumpRound(itemdata)
end

function UITwoHundredLottery:RefreshReward()
	local roundList = self._roundList or {}
	local len = #roundList
	local hasLen = len > 0
	--CS.ShowObject(self.mRewardBg,hasLen)
	local currData
	local maxData
	if hasLen then
		local isReceive = false
		for i = 1, len do
			local data = roundList[len - i + 1]
			local select = data.select
			if select == 1 then
				if data.receive == 1 then
					isReceive = true
					maxData = data
				elseif not isReceive then
					if (not maxData or maxData.rankValue < data.rankValue) then
						maxData = data
					end
				end
			elseif select == 0 then
				currData = data
			end
		end
		self._currData = currData

		self._maxData = maxData
	end
	CS.ShowObject(self.mBtnRecord,currData ~= nil)

	local awardEntrys = self._awardEntrys
	if not awardEntrys then
		local pages = self._pages
		local awardPage = pages[lotteryEnum]
		if not awardPage then return end

		local list = {}
		for i, v in ipairs(awardPage.entry) do
			list[v.entryId] = v
		end
		self._awardEntrys = list
	end

	local dataList = {}
	local showTheGasBg = maxData ~= nil
	if showTheGasBg then
		local rankValue = maxData.rankValue
		self:SetWndText(self.mTheGasValueText,rankValue)
		dataList = maxData.drops
	else
		for i = 1,10 do
			table.insert(dataList,-1)
		end
	end
	CS.ShowObject(self.mTheGasDesc,not showTheGasBg)
	CS.ShowObject(self.mTheGasBg,showTheGasBg)

	local uiRewardList = self._uiRewardList
	if uiRewardList then
		uiRewardList:RefreshList(dataList)
		uiRewardList:DrawAllItems()
	else
		uiRewardList = self:GetUIScroll("uiRewardList")
		self._uiRewardList = uiRewardList
		uiRewardList:Create(self.mRewardList,dataList,function (...) self:OnDrawRewardCell(...) end,UIItemList.SUPER_GRID)
	end
	uiRewardList:EnableScroll(#dataList > 10,false)
end

function UITwoHundredLottery:OnTimer(key)
	if key == self._timeKey then
		self:SetCDTime(key)
		self:SetTaskTime()
	end
end

function UITwoHundredLottery:OnDrawRewardCell(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		local Sel = self:FindWndTrans(item,"Sel")
		itemCache = {
			NoSel = self:FindWndTrans(item,"NoSel"),
			Sel = Sel,
			Icon = self:FindWndTrans(Sel,"CommonUI/Icon"),
		}
		self:SetComponentCache(instanceID,itemCache)
	end
	local awardEntrys = self._awardEntrys or {}
	local entryData = awardEntrys[itemdata]
	local hasData = entryData ~= nil
	if hasData then
		local rewards = LxDataHelper.SevenParseItems(entryData.items)
		local reward = rewards[1]
		local itemType = reward.itemType
		local itemId = reward.itemId
		local itemNum = reward.itemNum

		local baseClass = self:GetCommonIcon(instanceID)
		baseClass:Create(itemCache.Icon)
		baseClass:SetCommonReward(itemType, itemId, itemNum)
		baseClass:DoApply()

		self:SetWndClick(item,function()
			if itemType == LItemTypeConst.TYPE_HERO then
				gModelGeneral:OpenHeroSimpleTip(itemId,true)
			else
				gModelGeneral:OpenItemInfoTip(itemId,itemNum)
			end
		end)
	end
	CS.ShowObject(itemCache.NoSel,not hasData)
	CS.ShowObject(itemCache.Sel,hasData)
end

function UITwoHundredLottery:RefreshTime()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

	local endTime = activityData.endTime
	if endTime and endTime > 0 then
		self._endTime = endTime
		local timeKey = self._timeKey
		self:TimerStop(timeKey)
		self:TimerStart(timeKey,1,false,-1)
		self:SetCDTime(timeKey)
	end
end

function UITwoHundredLottery:OnDrawTaskCell(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		local Btn = self:FindWndTrans(item,"Btn")
		itemCache = {
			Btn = Btn,
			DescText = self:FindWndTrans(Btn,"DescText"),
			ProgressText = self:FindWndTrans(Btn,"ProgressText"),
		}
		self:SetComponentCache(instanceID,itemCache)
	end
	local entryCfg = itemdata.entryCfg
	local entry = itemdata.entry

	local jumpId = checknumber(entryCfg.jumpId) or 0

	local goalData = entry.goalData
	local status = goalData.status
	local isFinish = status > 0

	local callNums = self._callNums or {}
	local callNumInfo = callNums[entry.entryId]
	local addNum = callNumInfo and callNumInfo.count or 0
	local addStr = string.replace(ccClientText(30922),addNum)

	local color = isFinish and "#138c3d" or "#777676"
	self:SetWndText(itemCache.DescText,LUtil.FormatColorStr(entryCfg.description,color))
	self:SetWndText(itemCache.ProgressText,LUtil.FormatColorStr(addStr,color))

	local Btn = itemCache.Btn
	self:SetIconClickScale(Btn,not isFinish)
	self:SetWndClick(Btn,function ()
		if isFinish then return end
		self:OnClickTaskFunc(jumpId)
	end)
end

function UITwoHundredLottery:InitTaskSuper()
	local list = self:GetTaskSuperList()

	---@type UIItemList
	local uiTaskSuper = self._uiTaskSuper
	if uiTaskSuper then
		uiTaskSuper:RefreshList(list)
		uiTaskSuper:DrawAllItems()
	else
		uiTaskSuper = self:GetUIScroll("uiTaskSuper")
		self._uiTaskSuper = uiTaskSuper

		local isShowNewTop = self._isShowNewTop
		local showTaskBg = isShowNewTop and self.mTaskBgEn or self.mTaskBg
		local hideTaskBgRoot = isShowNewTop and self.mTaskBg or self.mTaskBgEn
		CS.ShowObject(showTaskBg,true)
		CS.ShowObject(hideTaskBgRoot,false)

		local taskSuperRoot = isShowNewTop and self.mTaskSuperEn or self.mTaskSuper
		uiTaskSuper:Create(taskSuperRoot, list, function(...) self:OnDrawTaskCell(...) end,UIItemList.SUPER)
	end
	uiTaskSuper:EnableScroll(#list > 3,false)
end

function UITwoHundredLottery:CheckGetRed(round)
	local maxCallNum = self:GetCallMaxNum(round)

	local curOpenRound = self._curOpenRound
	local dropRecordList = self._dropRecordList or {}
	local roundList = dropRecordList[round]
	if not roundList then return false end

	-- 是否已经领取过
	local isAlreadyGet = self:CheckIsGet(round)
	return not isAlreadyGet and (#roundList >= maxCallNum or curOpenRound > round or self._openDay > round)
end

function UITwoHundredLottery:OnClickBtnRecordList()
	GF.OpenWnd("UILotteryRltsSelect",{
		sid = self._sid,
		pageId = lotteryEnum,
		round = self._curRound,
		pages = self._pages
	})
end

function UITwoHundredLottery:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function(data,sid) self:OnActivityConfigData(data,sid) end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function(pb) self:OnActivityListResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)
end

function UITwoHundredLottery:OnClickBtnHelp()
	GF.OpenWnd("UIBzTips",{ title = self._title, text = self._helpTip })
end

function UITwoHundredLottery:CheckIsSelRound(itemdata)
	return self._curRound == itemdata.round
end


function UITwoHundredLottery:InitData()
	local sid = self:GetWndArg("sid")
	if not sid then
		local dataList = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_ACTIVITY_TYPE_4105)
		if dataList[1] then
			sid = dataList[1].sid
		end
	end
	if not sid then
		self:WndClose()
		return
	end

	self._sid = sid
	gModelActivity:ReqActivityConfigData(sid)
end

function UITwoHundredLottery:SetPagesData(sid,pb)
	local pages = self._pages
	if not pages then
		pages = {}
		self._pages = pages
	end
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		pages[page.pageId] = page
	end


	local roundIdDataMap = self._roundIdDataMap
	if not roundIdDataMap then
		roundIdDataMap = {}
		self._roundIdDataMap = roundIdDataMap
	end
	---@type StructActivityPage
	local callPage = pages[2]
	if callPage then
		local moreInfo,probability
		local showPro
		local roundIds = {}
		local callEntrys = callPage.entry or {}
		for i,v in ipairs(callEntrys) do
			local entryId = v.entryId
			local entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,entryId)
			if entryCfg then
				moreInfo = string.split(entryCfg.moreInfo,"|")
				probability = checknumber(moreInfo[2]) or 0
				showPro = probability and probability > 0
				if showPro then
					probability = probability * 100
					table.insert(roundIds,{
						probability = string.replace("#a1#%",probability),
						entryId = entryId,
						item = LxDataHelper.ParseItem_3(entryCfg.reward),
					})
				end
			end
		end
		roundIdDataMap[1] = roundIds
	end

	self:InitShowData()
end

function UITwoHundredLottery:OnClickBtnRecord()
	if not self._currData then return end

	GF.OpenWnd("UILotteryRltsPop",{
		sid = self._sid,
		pageId = lotteryEnum,
		result = self._currData,
		isNoEff = true
	})
end

function UITwoHundredLottery:SetContent()
	local sid = self._sid
	local webData = gModelActivity:GetWebActivityDataById(sid)
	if not webData then return end

	local config = webData.config

	self._countDownOne = config.countDownOne or ccClientText(18400)
	self._countDownTwo = config.countDownTwo or ccClientText(30911)

	self:SetWndText(self.mTheGasDesc,config.tipsOne)

	local titleOne = config.titleOne
	if LxUiHelper.IsImgPathValid(titleOne) then
		self:SetWndEasyImage(self.mTopTitle,titleOne,function()
			CS.ShowObject(self.mTopTitle, true)
		end,true)

		self:SetAnchorPos(self.mTopTitle, LxDataHelper.ParseVector2NotEmpty3(config.titleOnePos))
	end

	local image = config.image
	if LxUiHelper.IsImgPathValid(image) then
		self:SetWndEasyImage(self.mBg,image,function()
			CS.ShowObject(self.mBg,true)
		end)
	else
		CS.ShowObject(self.mBg,true)
	end

	local character = config.character
	if character and character > 0 then
		local effRef = gModelHero:GetShowEffectById(character)
		if effRef then
			local heroDrawing = effRef.heroDrawing
			local spineRoot = self.mHeroSpine
			local spineKey = spineRoot:GetInstanceID()
			local characterSize = config.characterSize
			self:CreateWndSpine(spineRoot,heroDrawing,spineKey,false,function (dpSpine)
				if characterSize and characterSize > 0 then
					dpSpine:SetScale(characterSize)
				end
			end)

			self:SetAnchorPos(spineRoot, LxDataHelper.ParseVector2NotEmpty3(config.characterPos))
		end
	end
	self:SetAnchorPos(self.mBtnPro, LxDataHelper.ParseVector2NotEmpty3(config.helpBtnPos))

	local callNums = {}
	local callNum = config.callNum
	if not string.isempty(callNum) then
		local arrs = string.split(callNum,";")
		for i, v in ipairs(arrs) do
			local arr = string.split(v,"=")
			table.insert(callNums,{
				entryId = checknumber(arr[1]),
				count = checknumber(arr[2]),
			})
		end
	end
	self._callNums = callNums

	self._maxCallNum = config.maxCallNum or 10

	self._errorCodeOne = config.errorCodeOne
	self._tipsFour = config.tipsFour

	self._title = gModelActivity:GetLngNameByActivitySid(sid)
	self._helpTip = string.gsub(config.helpTip,'\\n','\n')

	local round = config.round or 1
	self._round = round
end

function UITwoHundredLottery:GetRoundList()
	local list = {}
	local round = self._round
	local curOpenRound = self._curOpenRound or 999
	for i = 1,round do
		table.insert(list,{
			round = i,
			btnName = tostring(i),
			lock = i > curOpenRound,
		})
	end
	return list
end

function UITwoHundredLottery:GetShareJsonData()
	local currData = self._maxData
	if not currData then return end

	local awardEntrys = self._awardEntrys or {}
	local playerName = gModelPlayer:GetPlayerName()
	local drops = currData.drops
	local list = {}
	for i, v in ipairs(drops) do
		local itemData = awardEntrys[v]
		if itemData then
			local rewards = LxDataHelper.SevenParseItems(itemData.items)
			local reward = rewards[1]
			local data = {
				count = reward.itemNum,
				effect = reward.isShowEff,
				itemId = reward.itemId,
				type = reward.itemType
			}
			table.insert(list,data)
		end
	end

	local data = {
		extraReward = list,
		createTime = currData.createTime,
		rankValue = currData.rankValue,
		callPlayerName = playerName,
		shareType = shareType
	}
	return JSON.encode(data)
end

function UITwoHundredLottery:OnClickBtnPro()
	local sid = self._sid

	local actWebData = gModelActivity:GetWebActivityDataById(sid)
	if not actWebData then return end

	local config = actWebData.config
	local explainList = {}
	local callHelpTitle = string.split(config.helpTip,"|")
	for i,v in ipairs(callHelpTitle) do
		table.insert(explainList,v)
	end

	GF.OpenWnd("UIActivity166CallRule",{
		title = config.binWeightShow,
		policyTxt = config.policyTxt,
		showExplainStatus = 1,
		explainTxt = config.callHelpTitleTxt,
		explainList = explainList,
		btnList = {},
		ruleMap = self._roundIdDataMap,
	})
end

function UITwoHundredLottery:InitText()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mRecordText,ccClientText(30912))
	self:SetWndText(self.mProText,ccClientText(20920))
	self:InitTextSizeWithLanguage(self.mTaskText, -2)
	self:SetWndButtonText(self.mBtnRecord,ccClientText(30912))
	self:SetWndButtonText(self.mBtnSummon,ccClientText(30902))
	self:SetWndText(self.mTheGasText,ccClientText(30913))

	local isShowNewTop = self._isShowNewTop
	if isShowNewTop then
		self:SetWndText(self.mTaskTextEn,ccClientText(30900))
	else
		self:SetWndText(self.mTaskText,ccClientText(30900))
	end
	CS.ShowObject(self.mTaskBg, not isShowNewTop)
	CS.ShowObject(self.mTaskBgEn, isShowNewTop)
end


function UITwoHundredLottery:RefreshRoundList()
	local uiRoundList = self._uiRoundList
	local uiList = uiRoundList:GetList()
	uiList:RefreshList()
	uiRoundList:DrawAllItems()
	if not self._isJumpIndex then
		self._isJumpIndex = true
		uiRoundList:MoveToPos(self._curRound)
	end
end

function UITwoHundredLottery:SetTaskTimeTxt(timeStr)
	timeStr = timeStr or ""
	if self._isShowNewTop then
		self:SetWndText(self.mTaskTimeTextEn,timeStr)
	else
		self:SetWndText(self.mTaskTimeText,timeStr)
	end
end

function UITwoHundredLottery:InitShowData()
	local sid = self._sid

	local activityData = gModelActivity:GetActivityBySid(sid)
	local moreInfo = JSON.decode(activityData.moreInfo)
	local curOpenRound = moreInfo.round
	self._curOpenRound = curOpenRound
	self._openDay = moreInfo.openDay or curOpenRound

	self:InitRoundList()
	if not self._isOne then
		self._isOne = true
		if curOpenRound > 1 then
			self:JumpRound({
				round = curOpenRound
			})
			return
		end
	end
	self:RefreshView()
end

function UITwoHundredLottery:GetCallMaxNum(round)
	local maxCallNum = self._maxCallNum or 10
	--refs #12262 【运营活动】模板4105的领取条件优化
	--http://192.168.5.2:3000/issues/12262
	--日服版本的抽取次数,改为动态计算
	local maxLotteryNumList = self._maxLotteryNumList
	if gLGameLanguage:IsJapanRegion() and maxLotteryNumList then
		maxCallNum = maxLotteryNumList[round] or maxCallNum
	end
	return maxCallNum
end

function UITwoHundredLottery:OnActivityPageResp(pb)
	local sid = pb.sid
	if self._sid ~= sid then return end

	self:SetPagesData(sid,pb)

	--self:ResetData(pb)
	--self:RefreshRoundList()
	--self:OnLotteryHmtRecord()
end

function UITwoHundredLottery:OnActivityListResp(pb)
	local sid = self._sid
	local activities = pb.activities
	for i, v in ipairs(activities) do
		if v.sid == sid and v.status ~= 3 then
			gModelActivity:OnActivityPageReq(sid)
			return
		end
	end
end

function UITwoHundredLottery:InitRoundList()
	local list = self:GetRoundList()
	---@type UIItemList
	local uiRoundList = self._uiRoundList
	if uiRoundList then
		uiRoundList:RefreshList(list)
		uiRoundList:DrawAllItems()
	else
		uiRoundList = self:GetUIScroll("uiRoundList")
		self._uiRoundList = uiRoundList
		uiRoundList:Create(self.mRoundList, list, function(...) self:OnDrawRoundCell(...) end, UIItemList.SUPER)
	end
end



function UITwoHundredLottery:GetTaskSuperList()
	local pages = self._pages
	local taskPage = pages[taskEnum]
	if not taskPage then return {} end

	local sid = self._sid
	local curRound = self._curRound
	local taskList = {}
	for i, v in ipairs(taskPage.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,v.entryId)
		if entryCfg then
			if checknumber(entryCfg.moreInfo) == curRound then
				table.insert(taskList,{
					entry = v,
					entryCfg = entryCfg
				})
			end
		end
	end
	return taskList
end

function UITwoHundredLottery:OnActivityConfigData(data,sid)
	if sid ~= self._sid then return end
	self:SetContent()
	self:RefreshTime()
	gModelActivity:OnActivityPageReq(sid)
end

function UITwoHundredLottery:SetTaskTime()
	local endTime = LUtil.GetNextDayTimes(nil,1)
	local time = GetTimestamp()
	local curOpenRound = self._curOpenRound
	local isCurRound = self._curRound == curOpenRound and curOpenRound == self._openDay
	local timespan = endTime - time
	local timeStr = ""
	if timespan <= 0 or not isCurRound then
		timeStr = self._countDownTwo
	else
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(self._countDownOne,LUtil.FormatColorStr(timeStr,"#61ff36"))
	end
	self:SetTaskTimeTxt(timeStr)
end

function UITwoHundredLottery:CheckSommunIsGet()
	local curRound = self._curRound
	local dropRecordList = self._dropRecordList or {}
	local roundList = dropRecordList[curRound]
	if not roundList then return false end

	local maxCallNum = self._maxCallNum or 10
	local maxLotteryNumList = self._maxLotteryNumList
	local roundMaxRound = maxLotteryNumList and maxLotteryNumList[curRound]
	if roundMaxRound and roundMaxRound > 0 then
		maxCallNum = roundMaxRound
	end
	local len = #roundList
	return len >= maxCallNum
end

function UITwoHundredLottery:OnClickBtnSummon()
	local status = self._status
	if status == STATUS_0 then
		local currData = self._currData
		if currData then
			gModelGeneral:OpenUIOrdinTips({
				refId = 470403,
				func = function ()
					GF.OpenWnd("UILotteryRltsPop",{
						sid = self._sid,
						pageId = lotteryEnum,
						result = currData,
						isNoEff = true
					})
				end
			})
		else
			local playerCallNum = self._playerCallNum or 0
			if playerCallNum <= 0 then
				GF.ShowMessage(self._tipsFour)
				return
			end
			local params = string.replace("#a1#,#a2#",self._curRound,self._index)
			gModelActivity:OnActivityDropSelectReq(1, self._sid, lotteryEnum, params)
		end
	elseif status == STATUS_1 then
		self:OnClickBtnRecordList()
	elseif status == STATUS_2 then
	end
end

function UITwoHundredLottery:OnClickBtnShare()
	local jsonStr = self:GetShareJsonData()
	if not jsonStr then return end

	gModelGeneral:OpenShareTip({
		root = self.mBtnShare,
		shareType = shareType,
		shareData = jsonStr
	})
end

function UITwoHundredLottery:CheckIsGet(round)
	local dropRecordList = self._dropRecordList or {}
	local roundList = dropRecordList[round]
	if not roundList then return false end
	-- 是否已经领取过
	local isAlreadyGet = false
	for i, v in ipairs(roundList) do
		if v.receive == 1 then
			--领取过
			isAlreadyGet = true
			break
		end
	end
	return isAlreadyGet
end

function UITwoHundredLottery:InitEvent()
	self:SetWndClick(self.mBgImage,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnRecordList,function() self:OnClickBtnRecordList() end)
	self:SetWndClick(self.mBtnPro,function() self:OnClickBtnPro() end)
	self:SetWndClick(self.mBtnHelp, function() self:OnClickBtnHelp() end)
	self:SetWndClick(self.mBtnRecord,function ()self:OnClickBtnRecord() end)
	self:SetWndClick(self.mBtnSummon,function ()self:OnClickBtnSummon() end)

	self:SetWndClick(self.mTheGasBg,function ()self:OnClickBtnShare() end)
	self:SetWndClick(self.mBtnShare,function ()self:OnClickBtnShare() end)
end

function UITwoHundredLottery:OnClickTaskFunc(jumpId)
	if not jumpId or jumpId < 1 then return end

	if not gModelFunctionOpen:CheckIsOpened(jumpId,true) then return end

	gModelFunctionOpen:Jump(jumpId, self:GetWndName())
	self:WndClose()
end

function UITwoHundredLottery:SetCDTime(timeKey)
	local endTime = self._endTime
	if not endTime then
		self:TimerStop(timeKey)
		CS.ShowObject(self.mTimeBg,false)
		return
	end

	if endTime < 1 then
		self:TimerStop(timeKey)
		self:SetWndText(self.mTimeText,ccClientText(18404))
		CS.ShowObject(self.mTimeBg,true)
		return
	end

	local timespan = endTime - GetTimestamp()
	local timeStr = ""
	if timespan < 0 then
		timeStr = ccClientText(14301)
		self:TimerStop(timeKey)
	else
		timeStr = string.replace(ccClientText(18400),LUtil.FormatTimespanCn(timespan))
	end
	self:SetWndText(self.mTimeText,timeStr)
	CS.ShowObject(self.mTimeBg,true)
end

function UITwoHundredLottery:RefreshView()
	self:RefreshRoundList()
	self._status = STATUS_0

	local sid = self._sid
	local activityData = gModelActivity:GetActivityBySid(sid)
	if not activityData then return end

	local moreInfo = JSON.decode(activityData.moreInfo)
	local curRound = self._curRound
	local playerCallNum = moreInfo["playerCallNum"..curRound]
	self._playerCallNum = playerCallNum

	local dropRecord = moreInfo.dropRecord
	local dropRecordList = {}
	for i, v in ipairs(dropRecord) do
		local dropRound = v.round
		local list = dropRecordList[dropRound]
		if not list then
			list = {}
			dropRecordList[dropRound] = list
		end
		table.insert(list,{
			round = dropRound,--轮次
			index = v.index,--序号
			drops = v.drops,--掉落记录数组 条目id
			select = v.select,--备选id
			receive = v.receive,--是否领取，同一轮次只能领取一个
			rankValue = v.rankValue,-- 欧气值
			createTime = v.createTime,--创建时间
		})
	end

	local roundList = dropRecordList[curRound] or {}
	local len = #roundList
	self._index = len + 1
	self._roundList = roundList
	self._dropRecordList = dropRecordList

	self:OnMaxLotteryNumList()

	local isRed = self:CheckGetRed(curRound)
	CS.ShowObject(self.mRedPoint,isRed)


--[[	已领取后，主界面不显示剩余次数
	未领取，当前轮次，全部次数已经耗尽且无未保存抽取数据显示为领取
	未领取，非当天轮次，若该轮次剩余抽奖次数，仍是显示十连抽奖
	未领取，非当天轮次，若该轮次无抽奖次数，显示领取按钮
	非当天轮次，无法获得更多的抽奖次数的，所以不需要判断是否用完全部次数]]

	local hasPlayerCall = playerCallNum > 0
	local showEffect = hasPlayerCall
	local status = STATUS_0
	local isCurRound = curRound == self._curOpenRound
	if isCurRound then
		--- 次数是否用完
		if self:CheckSommunIsGet() then
			if self:CheckIsGet(curRound) then
				status = STATUS_2
			else
				status = STATUS_1
			end
		elseif curRound == self._curOpenRound then
			if self:CheckIsGet(curRound) then
				status = STATUS_2
			elseif len > 0 and self:CheckSommunIsGet() then
				status = STATUS_1
			end
		end
	else
		if self:CheckIsGet(curRound) then
			status = STATUS_2
		else
			--- 非当天轮次，没有次数的情况
			if not hasPlayerCall and len > 0 then
				status = STATUS_1
			end
		end
	end
	self._status = status

	local isGray = false
	local btnName = ccClientText(30902)
	if status == STATUS_1 then
		btnName = ccClientText(30908)
	elseif status == STATUS_2 then
		showEffect = false
		isGray = true
		btnName = ccClientText(30918)
	end
	self:SetWndButtonText(self.mBtnSummon,btnName)
	self:SetWndButtonGray(self.mBtnSummon,isGray)
	self:SetWndImageGray(self.mGray, true)
	if showEffect then
		self:CreateWndEffect(self.mSummonEff,"fx_shouchong_anniu","summonEffKey",100)
	end
	CS.ShowObject(self.mSummonEff,showEffect)

	local showHasTimes = status ~= STATUS_2
	local playerCallNumStr = ""
	if showHasTimes then
		playerCallNumStr = string.replace(ccClientText(30903),
				LUtil.FormatColorStr(playerCallNum,hasPlayerCall and "white" or "lightRed"))
	end
	self:SetWndText(self.mSummonText,playerCallNumStr)

	self:InitTaskSuper()
	self:RefreshReward()
end

function UITwoHundredLottery:OnActivityResp(pb)
	local sid = self._sid
	local activity = pb.activity
	if activity.sid == sid and activity.status ~= 3 then
		gModelActivity:OnActivityPageReq(sid)
	end
end

function UITwoHundredLottery:JumpRound(itemdata)
	if itemdata.round > self._curOpenRound then
		local errorCodeOne = self._errorCodeOne
		if not string.isempty(errorCodeOne) then
			GF.ShowMessage(errorCodeOne)
		end
		return
	end

	self._curRound = itemdata.round
	self:SetTaskTimeTxt()

	self:RefreshView()
end


function UITwoHundredLottery:OnMaxLotteryNumList()
	local callNums = self._callNums
	if not callNums then return end

	local pages = self._pages
	if not pages then return end

	local taskPage = pages[taskEnum]
	if not taskPage then return end

	local maxLotteryNumList = {}
	for i, v in ipairs(taskPage.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,taskEnum,v.entryId)
		if entryCfg then
			local roundIndex = entryCfg.moreInfo
			local maxLotteryNum = maxLotteryNumList[roundIndex] or 0
			local callNumInfo = callNums[i]
			local callNum = callNumInfo and callNumInfo.count or 0
			maxLotteryNumList[roundIndex] = maxLotteryNum + callNum
		end
	end
	self._maxLotteryNumList = maxLotteryNumList
end

function UITwoHundredLottery:OnDrawRoundCell(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		local NoSelBg = self:FindWndTrans(item,"NoSelBg")
		local SelBg = self:FindWndTrans(item,"SelBg")
		itemCache = {
			NoSelBg = NoSelBg,
			NoSelBtnName = self:FindWndTrans(NoSelBg,"BtnName"),
			SelBg = SelBg,
			SelBtnName = self:FindWndTrans(SelBg,"BtnName"),
			Lock = self:FindWndTrans(item,"Lock")
		}
		self:SetComponentCache(instanceID,itemCache)

		local btnName = itemdata.btnName
		self:SetWndText(itemCache.NoSelBtnName,btnName)
		self:SetWndText(itemCache.SelBtnName,btnName)
	end
	local isSel = self:CheckIsSelRound(itemdata)
	CS.ShowObject(itemCache.NoSelBg,not isSel)
	CS.ShowObject(itemCache.SelBg,isSel)

	local lock = itemdata.lock
	CS.ShowObject(itemCache.Lock,lock)
	local showName = not lock
	CS.ShowObject(itemCache.NoSelBtnName,showName)
	CS.ShowObject(itemCache.SelBtnName,showName)


	self:SetWndClick(item,function()
		self:OnClickRoundCell(itemdata)
	end)
end

------------------------------------------------------------------
return UITwoHundredLottery