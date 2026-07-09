---
--- Created by Administrator.
--- DateTime: 2025/5/22 19:59:01
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubActivity165Puzzle:LChildWnd
local UISubActivity165Puzzle = LxWndClass("UISubActivity165Puzzle", LChildWnd)
------------------------------------------------------------------

local PAGE_PUZZLE_ID = 2

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubActivity165Puzzle:UISubActivity165Puzzle()
	---@typ UIObjPool
	self._objPool = nil

	self._pages = {}

	self._actCDTimerKey = "_actCDTimerKey"

	self._previewTimerKey = "_previewTimerKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubActivity165Puzzle:OnWndClose()
	if self._objPool then
		self._objPool:DestroyAllObj()
		self._objPool = nil
	end
	
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubActivity165Puzzle:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubActivity165Puzzle:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitPool()
	self:InitRewardItems()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
end

function UISubActivity165Puzzle:InitData()
	local sid = self:GetWndArg("sid")
	self._sid = sid

	gModelActivity:ReqActivityConfigData(sid)
end

function UISubActivity165Puzzle:RefreshPreviewTimer(key)
	key = key or self._actCDTimerKey

	local sid = self._sid
	---@type StructActivity
	local activity = gModelActivity:GetActivityBySid(sid)
	local previewShowInfos = self._previewShowInfos or {}
	local len = #previewShowInfos
	local showPreviewRoot = activity and len > 0
	CS.ShowObject(self.mPreviewRoot,showPreviewRoot)
	if not showPreviewRoot then
		self:TimerStop(key)
		return
	end

	local uiPreviewShowItems = self._uiPreviewShowItems or {}
	local curTime = GetTimestamp()
	local lastTimeSpan = curTime - activity.startTime
	local actOpenDay = LUtil.GetCurTimeDayNum(lastTimeSpan)

	for k,v in pairs(uiPreviewShowItems) do
		local data = v.data
		local openDay = data and data.openDay or 0
		CS.ShowObject(v.item,actOpenDay >= openDay)
	end
end

function UISubActivity165Puzzle:InitEvent()
	--- 返回按钮必备
	-- self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtn() end)
	self:SetWndClick(self.mImgBox,function() self:OnClickBtnBox() end)
	self:SetWndClick(self.mBtnActive,function() self:OnClickBtnActive() end)
	self:SetWndClick(self.mBtnTask,function() self:OnClickBtnTask() end)
end

function UISubActivity165Puzzle:InitRewardItems()
	local rewardItemTransList = {}
	local rewardItems = {
		self.mRwdItem1,self.mRwdItem2,self.mRwdItem3,self.mRwdItem4,self.mRwdItem5,
		self.mRwdItem6,self.mRwdItem7,self.mRwdItem8,self.mRwdItem9,self.mRwdItem10,self.mRwdItem11,
	}
	for i,v in ipairs(rewardItems) do
		table.insert(rewardItemTransList,{
			root = v,
			baseIconKey = v:GetInstanceID(),
			imgIcon = self:FindWndTrans(v,"ImgIcon"),
			imgMaks = self:FindWndTrans(v,"ImgMaks"),
			redPoint = self:FindWndTrans(v,"redPoint"),
		})
	end
	self._rewardItemTransList = rewardItemTransList
end

function UISubActivity165Puzzle:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end

	local pages = self._pages
	if not pages then
		pages = {}
		self._pages = pages
	end
	for i, v in ipairs(pb.pages) do
		---@type StructActivityPage
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		pages[page.pageId] = page
	end

	self:DisposeTasks()
	self:DisposePuzzle()

	if self._isAllActive then
		local timeKey = self._previewTimerKey
		self:RefreshPreviewTimer(timeKey)
		self:TimerStop(timeKey)
		self:TimerStart(timeKey,1,false,-1)
	end

	self:InitPayItemList()
	self:RefreshBtnActiveRP()

	self:RefreshListPuzzle()
	self:RefreshRewards()
end

function UISubActivity165Puzzle:OnClickBtnBox()
	local boxEntryId = self._boxEntryId
	if not boxEntryId then return end

	if not self._canGetBoxReward then
		local boxEntryItems = self._boxEntryItems
		if boxEntryItems and #boxEntryItems > 0 then
			GF.OpenWnd("UIringBoxDetail",{self.mImgBox,boxEntryItems})
		end
	else
		self:ReqActivitySpecialOp("2|" .. boxEntryId)
	end
end

function UISubActivity165Puzzle:OnClickHelpBtn()
	GF.OpenWnd("UIBzTips", { title = self._puzzleHelpTitle, text = self._puzzleHelpText })
end

function UISubActivity165Puzzle:InitPool()
	---@type UIObjPool
	local objPool = UIObjPool:New()
	objPool:Create(self.mPreviewRoot,self.mPreviewItem)
	self._objPool = objPool
end

function UISubActivity165Puzzle:OnActivityListResp(pb)
	local sid = self._sid
	local activities = pb.activities
	for i, v in ipairs(activities) do
		if v.sid == sid and v.status ~= 3 then
			gModelActivity:OnActivityPageReq(sid)
			return
		end
	end
end

function UISubActivity165Puzzle:OnClickBtnTask()
	GF.OpenWnd("UIActivity165Quest",{
		sid = self._sid,
		pageId = 1
	})
end



function UISubActivity165Puzzle:RefreshRewards()
	local rewardItems = self._rewardItems
	local canActPosMap = self._canActPosMap or {}
	local puzzleRewardMap = self._puzzleRewardMap
	local rewardItemTransList = self._rewardItemTransList
	for i,v in ipairs(rewardItemTransList) do
		local root = v.root
		local showItem = false
		local isGet = false
		local showRP = false
		local rewardItemInfo = rewardItems[i]
		---@type StructRewardItem[]
		local items = rewardItemInfo and rewardItemInfo.items
		if items and #items > 0 then
			local baseIconKey = v.baseIconKey

			local imgIcon = v.imgIcon
			local item = items[1]
			local baseClass = self:GetCommonIcon(baseIconKey)
			baseClass:Create(imgIcon)
			baseClass:SetCommonReward(item.type, item.itemId, item.count)
			baseClass:EnableShowNum(false)
			baseClass:DoApply()

			local entryId = rewardItemInfo.refId
			isGet = puzzleRewardMap[entryId] and true or false

			local createEff = false
			local canGet = false
			if canActPosMap[entryId] then
				showRP = true
				canGet = true
				createEff = true
			end

			if createEff then
				self:CreateWndEffect(root,"fx_ui_pintu_kelingqu",baseIconKey,100,false,false,nil,nil,nil,nil,nil)
			else
				self:DestroyWndEffectByKey(baseIconKey)
			end

			self:SetWndClick(root,function()
				if canGet then
					self:ReqActivitySpecialOp("2|"..entryId)
					return
				end

				if not isGet then
					GF.ShowMessage(ccClientText(45109))
				end
				gModelGeneral:ShowCommonItemTipWnd(item)
			end)

			showItem = true
		end
		CS.ShowObject(v.redPoint,showRP)
		CS.ShowObject(v.imgMaks,isGet)
		CS.ShowObject(root,showItem)
	end
end

function UISubActivity165Puzzle:InitPayItemList()
	local list = self:GetPayItemList()
	local uiPayItemList = self._uiPayItemList
	if uiPayItemList then
		uiPayItemList:RefreshList(list)
	else
		uiPayItemList = self:GetUIScroll("mPayItemList")
		self._uiPayItemList = uiPayItemList
		uiPayItemList:Create(self.mPayItemList, list, function(...) self:OnDrawPayItem(...) end)
	end
end



function UISubActivity165Puzzle:RefreshBtnActiveRP()
	local showRP = false
	if not self._isAllActive then
		local list = self:GetPayItemList()
		if #list > 0 then
			local itemList = {}
			for i,v in ipairs(list) do
				table.insert(itemList,v.data)
			end
			if gModelGeneral:CheckItemListEnoughStatus(itemList) then
				showRP = true
			end
		end
	end
	self:SetRed(self.mBtnActive,showRP)
end


local testStatus = false

function UISubActivity165Puzzle:SetContent()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end

	local config = webData.config

	self._puzzleNums = checknumber(config.puzzleNums)

	local puzzleBgBig = config.puzzleBgBig
	if LxUiHelper.IsImgPathValid(puzzleBgBig) then
		self:SetWndEasyImage(self.mBg,puzzleBgBig,function()
			CS.ShowObject(self.mBg,true)
		end)
	else
		CS.ShowObject(self.mBg,true)
	end

	local puzzleBg = config.puzzleBg
	if LxUiHelper.IsImgPathValid(puzzleBg) then
		local trans = self.mImgPuzzleBg
		self:SetWndEasyImage(trans,puzzleBg,function()
			CS.ShowObject(trans,true)
			self:InitListPuzzle()
		end,true)
	else
		CS.ShowObject(self.mImgPuzzleBg,true)
		self:InitListPuzzle()
	end

	CS.ShowObject(self.mSpine,false)
	CS.ShowObject(self.mSpineImg,false)

	local ImageHero = config.ImageHero
	if not string.isempty(ImageHero) then
		local upPosFunc = function(trans)
			if not self:IsWndValid() then return end
			local ImageHeroPos = config.ImageHeroPos
			if testStatus then
				ImageHeroPos = "-112,-241"
			end

			self:SetAnchorPos(trans,LxDataHelper.ParseVector2NotEmpty(ImageHeroPos))
		end
		local ImageHeroInfo = string.split(ImageHero,"=")
		local isImg = checknumber(ImageHeroInfo[1]) == 1
		local res = ImageHeroInfo[2]
		if isImg then
			local trans = self.mSpineImg
			self:SetWndEasyImage(trans,res,function()
				CS.ShowObject(trans,true)
				upPosFunc(trans)
			end,true)
		else
			local trans = self.mSpine
			---@param dpSpine LDisplaySpine
			self:CreateWndSpine(trans,res,res,nil,function(dpSpine)
				CS.ShowObject(trans,true)
				upPosFunc(trans)
			end)
		end
	end

	local puzzleTitle = config.puzzleTitle
	if LxUiHelper.IsImgPathValid(puzzleTitle) then
		local trans = self.mImgText
		self:SetWndEasyImage(trans,puzzleTitle,function ()
			self:SetAnchorPos(trans,LxDataHelper.ParseVector2NotEmpty(config.puzzleTitlePos))
			CS.ShowObject(trans,true)
		end,true)
	end

	self:SetAnchorPos(self.mImgTime,LxDataHelper.ParseVector2NotEmpty(config.timePos))

	local puzzleHelpText = config.puzzleHelpText
	local isShowHelpBtn = not string.isempty(puzzleHelpText)
	if isShowHelpBtn then
		self._puzzleHelpTitle = config.name
		self._puzzleHelpText = puzzleHelpText
		self:SetAnchorPos(self.mHelpBtn,LxDataHelper.ParseVector2NotEmpty(config.puzzleHelpPos))
	end
	CS.ShowObject(self.mHelpBtn,isShowHelpBtn)

	self._puzzleConsume = LxDataHelper.ParseItem_3(config.puzzleConsume)

	local puzzleReward = checknumber(config.puzzleReward)
	local hasPuzzleReward = puzzleReward and puzzleReward > 0
	if hasPuzzleReward then
		self._puzzleReward = puzzleReward
	end
	CS.ShowObject(self.mImgBox,hasPuzzleReward)

	local taskIcon = config.taskIcon
	if testStatus then
		taskIcon = "activity152_btn1"
	end
	if LxUiHelper.IsImgPathValid(taskIcon) then
		self:SetWndEasyImage(self.mBtnTask,taskIcon,nil,true)
	end
	self:SetWndText(self:FindWndTrans(self.mBtnTask,"BtnName"),config.taskName)
	local taskIconPos = config.taskIconPos
	if testStatus then
		taskIconPos = "250,170"
	end
	self:SetAnchorPos(self.mBtnTask,LxDataHelper.ParseVector2NotEmpty(taskIconPos))

	local taskInfos = {}
	local taskTab = string.split(config.taskTab,"|")
	for i,v in ipairs(taskTab) do
		v = string.split(v,"=")
		table.insert(taskInfos,{
			taskId = checknumber(v[1]),
			taskName = v[2],
		})
	end
	self._taskInfos = taskInfos

	local previewShowInfos = {}
	local pos
	local previewShow = string.split(config.previewShow,"|")
	local previewShowPos = string.split(config.previewShowPos,"|")
	for i,v in ipairs(previewShow) do
		v = string.split(v,"=")
		pos = string.split(previewShowPos[i],"=")
		table.insert(previewShowInfos,{
			type = checknumber(v[1]),
			refId = checknumber(v[2]),
			openDay = checknumber(v[3]),
			btnNamePos = LxDataHelper.ParseVector2NotEmpty(pos[1]),
			btnPos = LxDataHelper.ParseVector2NotEmpty(pos[2]),
		})
	end
	self._previewShowInfos = previewShowInfos

	self:CreatePreviewShowItems()

	self:SetWndButtonText(self.mBtnActive,config.actBtnName)

	self._tipsTxt = config.tipsTxt
	self._completedTxt = config.completedTxt

	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if activityData then
		self._endTime = checknumber(activityData.endTime)
		local timerKey = self._actCDTimerKey
		self:SetCDTimer(timerKey)
		self:TimerStop(timerKey)
		self:TimerStart(timerKey,1,false,-1)
	end
end

function UISubActivity165Puzzle:InitListPuzzle()
	local list = self:GetListPuzzle()

	---@type UIItemList
	local uiListPuzzle = self._uiListPuzzle
	if uiListPuzzle then
		uiListPuzzle:RefreshList(list)
	else
		uiListPuzzle = self:GetUIScroll("mListPuzzle")
		self._uiListPuzzle = uiListPuzzle
		uiListPuzzle:Create(self.mListPuzzle, list, function(...) self:OnDrawPuzzleCell(...) end)
	end
end

function UISubActivity165Puzzle:OnDrawPuzzleCell(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			NoActImg = self:FindWndTrans(item,"NoActImg"),
			Eff = self:FindWndTrans(item,"Eff"),
		}
		self:SetComponentCache(instanceID,itemCache)
	end
	local isAct = self:CheckIsActivePuzzle(itemdata)
	CS.ShowObject(itemCache.NoActImg,not isAct)

	local Eff = itemCache.Eff
	local effKey = Eff:GetInstanceID()
	local showEff = self:CheckIsShowActEff(itemdata)
	if showEff then
		self:CreateWndEffect(Eff,"fx_ui_pintu_jihuo",effKey,100,false,false,nil,nil,nil,nil,nil,function()
			CS.ShowObject(Eff,true)
		end)
	else
		CS.ShowObject(Eff,false)
	end
end

function UISubActivity165Puzzle:RefreshListPuzzle()
	---@type UIItemList
	local uiListPuzzle = self._uiListPuzzle
	if not uiListPuzzle then return end

	local uiList = uiListPuzzle:GetList()
	uiList:RefreshList()
end


function UISubActivity165Puzzle:CheckIsShowActEff(itemdata)
	local curActivatePosMap = self._curActivatePosMap or {}
	return curActivatePosMap[itemdata.index] and true or false
end

function UISubActivity165Puzzle:DisposePuzzle()
	local pages = self._pages
	if not pages then return end

	---@type StructActivityPage
	local taskPage = pages[PAGE_PUZZLE_ID]
	if not taskPage then return end

	local boxEntryItems = {}

	---@type table<number,StructRewardItem[]>
	local rewardItems = {}
	local conditionCheckIdMap = {}
	local conditionCheckMap = {}
	local condition,sort
	local sid = self._sid
	---@type StructActivityEntry[]
	local entry = taskPage.entry
	local boxEntryId
	local isEnd = false
	local len = #entry
	for i,v in ipairs(entry) do
		isEnd = i == len
		local entryId = v.entryId
		local cfg = gModelActivity:GetWebActivityEntryData(sid, PAGE_PUZZLE_ID, entryId)
		if cfg then
			sort = cfg.sort

			local conditionMap = {}
			condition = string.split(cfg.condition,";")
			for idx,val in ipairs(condition) do
				val = checknumber(val)
				conditionMap[val] = true
			end
			conditionCheckMap[sort] = conditionMap
			conditionCheckIdMap[entryId] = conditionMap

			rewardItems[sort] = {
				items = v.items,
				refId = entryId,
			}

			if isEnd then
				boxEntryItems = LxDataHelper.ParseItem(cfg.reward)
			end
		end

		if isEnd then
			boxEntryId = entryId
		end
	end
	self._conditionCheckMap = conditionCheckMap
	self._rewardItems = rewardItems
	self._boxEntryId = boxEntryId
	self._boxEntryItems = boxEntryItems

	local moreInfo = JSON.decode(taskPage.moreInfo)
	local activatePost = JSON.decode(moreInfo.activatePost)
	local puzzleReward = JSON.decode(moreInfo.puzzleReward)


	local isInitPuzzle = self._isInitPuzzle
	local curActivatePosMap = {}
	local oldActivatePostMap = self._activatePostMap or {}
	local actPosCnt = 0
	local activatePostMap = {}
	if activatePost and #activatePost > 0 then
		for i,v in ipairs(activatePost) do
			activatePostMap[v] = true
			if not oldActivatePostMap[v] and isInitPuzzle then
				curActivatePosMap[v] = true
			end
			actPosCnt = actPosCnt + 1
		end
	end
	--- 已激活的位置列表
	self._activatePostMap = activatePostMap
	self._isInitPuzzle = true
	self._curActivatePosMap = curActivatePosMap


	local puzzleRewardMap = {}
	if puzzleReward and #puzzleReward > 0 then
		for i,v in ipairs(puzzleReward) do
			puzzleRewardMap[v] = true
		end
	end
	--- 已领取的激活奖励列表
	self._puzzleRewardMap = puzzleRewardMap

	local canActPosMap = {}
	for k,v in pairs(conditionCheckIdMap) do
		if not puzzleRewardMap[k] then
			local actCnt = 0
			local allCnt = 0
			for idx,val in pairs(v) do
				if activatePostMap[idx] then
					actCnt = actCnt + 1
				end
				allCnt = allCnt + 1
			end
			if actCnt >= allCnt then
				canActPosMap[k] = true
			end
		end
	end
	self._canActPosMap = canActPosMap

	local boxEffRoot = self.mImgBoxEffRoot
	local key = boxEffRoot:GetInstanceID()
	local showBoxEff = canActPosMap[boxEntryId] and true or false
	self._canGetBoxReward = showBoxEff
	if showBoxEff then
		self:CreateWndEffect(boxEffRoot,"fx_VIPchongzhiwupo",key,100)
	else
		self:DestroyWndEffectByKey(key)
	end
	CS.ShowObject(boxEffRoot,showBoxEff)

	local puzzleNums = self._puzzleNums
	local isAllActive = actPosCnt >= puzzleNums
	self._isAllActive = isAllActive
	if isAllActive and self._clickActive then
		local effName = "fx_ui_pintu_jihuo_wancheng"
		self:CreateWndEffect(self.mImgPuzzleBg,effName,effName,100,false,false)
	end
	self._clickActive = false
end

function UISubActivity165Puzzle:OnClickBtnActive()
	local list = self:GetPayItemList()
	if #list < 1 then return end

	if self._isAllActive then
		if not string.isempty(self._completedTxt) then
			GF.ShowMessage(self._completedTxt)
		end
		return
	end

	local itemList = {}
	for i,v in ipairs(list) do
		table.insert(itemList,v.data)
	end
	if not gModelGeneral:CheckItemListEnough(itemList,"UIActivity165Main") then
		if not string.isempty(self._tipsTxt) then
			GF.ShowMessage(self._tipsTxt)
		end
		return
	end

	self._clickActive = true
	self:ReqActivitySpecialOp("1|")
end

function UISubActivity165Puzzle:GetListPuzzle()
	local list = {}
	local puzzleNums = self._puzzleNums or 0
	for i = 1,puzzleNums do
		table.insert(list,{
			index = i,
		})
	end
	return list
end




function UISubActivity165Puzzle:GetPayItemList()
	local list = {}
	if self._puzzleConsume then
		table.insert(list,{
			data = self._puzzleConsume,
		})
	end
	return list
end

function UISubActivity165Puzzle:SetCDTimer(key)
	key = key or self._actCDTimerKey
	local endTime = self._endTime
	if not endTime or endTime < 0 then
		self:TimerStop(key)
		CS.ShowObject(self.mImgTime,false)
		return
	end

	local timeStr = ""
	local curTime = GetTimestamp()
	local timeSpan = endTime - curTime
	if timeSpan > 0 then
		timeStr = LUtil.FormatTimespanCn(timeSpan,{hTextId = 10371})
		timeStr = string.replace(ccClientText(11637),timeStr)
	else
		self:TimerStop(key)
		timeStr = ccClientText(14301)
	end
	self:SetWndText(self.mTxtTime,timeStr)
	CS.ShowObject(self.mImgTime,true)
end

--- 是否激活
function UISubActivity165Puzzle:CheckIsActivePuzzle(itemdata)
	if not self._activatePostMap then return false end
	local activatePostMap = self._activatePostMap
	if activatePostMap[itemdata.index] then
		return true
	end
	return false
end

function UISubActivity165Puzzle:OnActivityResp(pb)
	local sid = self._sid
	local activity = pb.activity
	if activity.sid == sid and activity.status ~= 3 then
		gModelActivity:OnActivityPageReq(sid)
	end
end

function UISubActivity165Puzzle:DisposeTasks()
	local showRed = false
	local pages = self._pages
	---@type StructActivityPage
	local taskPage = pages and pages[1]
	---@type StructActivityEntry[]
	local entry = taskPage and taskPage.entry or {}
	for i,v in ipairs(entry) do
		local goalData = v.goalData
		if goalData and goalData.status == 1 then
			showRed = true
			break
		end
	end
	CS.ShowObject(self.mRedPoint,showRed)
end

function UISubActivity165Puzzle:OnDrawPayItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			Icon = self:FindWndTrans(item,"Icon"),
			Num = self:FindWndTrans(item,"Num"),
		}
		self:SetComponentCache(instanceID,itemCache)
	end
	local data = itemdata.data
	local itemId = data.itemId

	self:SetWndEasyImage(itemCache.Icon,gModelItem:GetItemIconByRefId(itemId),function()
		CS.ShowObject(itemCache.Icon,true)
	end)

	local itemNum = data.itemNum
	local hasNum = gModelItem:GetNumByRefId(itemId)
	local hasNumStr = LUtil.NumberCoversion(hasNum)
	if hasNum < itemNum then
		hasNumStr = LUtil.FormatColorStr(hasNumStr,"#ff7676")
	end
	local numStr = string.replace("#a1#/#a2#",hasNumStr,LUtil.NumberCoversion(itemNum))
	self:SetWndText(itemCache.Num,numStr)
end

function UISubActivity165Puzzle:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end
	self:SetContent()
	self:InitPayItemList()
	gModelActivity:OnActivityPageReq(sid)
end

function UISubActivity165Puzzle:ReqActivitySpecialOp(args)
	gModelActivity:OnActivitySpecialOpReq(self._sid,PAGE_PUZZLE_ID,nil,nil,args,ModelActivity.LUCKY_PUZZLE_OPS)
end

function UISubActivity165Puzzle:OnItemChange()
	self:InitPayItemList()
	self:RefreshBtnActiveRP()
end

function UISubActivity165Puzzle:InitMsg()
	self:WndEventRecv(EventNames.On_Item_Change,function(...) self:OnItemChange(...) end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function(...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function(pb) self:OnActivityListResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
end



function UISubActivity165Puzzle:OnTimer(key)
	if key == self._actCDTimerKey then
		self:SetCDTimer(key)
	elseif key == self._previewTimerKey then
		self:RefreshPreviewTimer(key)
	end
end

function UISubActivity165Puzzle:InitText()
end

function UISubActivity165Puzzle:CreatePreviewShowItems()
	local previewShowInfos = self._previewShowInfos or {}
	if #previewShowInfos < 1 then return end

	local objPool = self._objPool
	if not objPool then return end

	local uiPreviewShowItems = {}
	for i,v in ipairs(previewShowInfos) do
		---@type Transform
		local item = objPool:GetObj()
		if item then
			local itemTrans = item.transform
			itemTrans:SetParent(self.mPreviewRoot, false)

			--- 配置格式：展示类型=内容ID=活动天数，多个使用“|”分割。类型1=宠物ID；类型2=少女ID
			local type = v.type
			self:SetAnchorPos(itemTrans,v.btnPos)

			local refId = v.refId
			local name = ""
			if type == 1 then
				name = gModelPet:GetPetNameByRefId(refId)
			elseif type == 2 then
				name = gModelHero:GetHeroNameByRefId(refId)
			end
			local UIText = self:FindWndTrans(itemTrans,"UIText")
			self:SetAnchorPos(UIText,v.btnNamePos)
			self:SetWndText(UIText,name)

			self:SetWndClick(itemTrans,function()
				if type == 1 then
					GF.OpenWnd("UIPeView",{refId = refId,isPreview = true})
				elseif type == 2 then
					gModelGeneral:OpenHeroSimpleTip(refId)
				end
			end)

			CS.ShowObject(item,false)
			uiPreviewShowItems[i] = {
				item = itemTrans,
				data = v,
			}
		end
	end
	self._uiPreviewShowItems = uiPreviewShowItems
end

------------------------------------------------------------------
return UISubActivity165Puzzle