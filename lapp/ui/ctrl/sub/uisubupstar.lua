---
--- Created by BY.
--- DateTime: 2023/10/20 18:03:23
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubUpStar:LChildWnd
local UISubUpStar = LxWndClass("UISubUpStar", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubUpStar:UISubUpStar()
	self._getBtnEff = "fx_anniu_02"
	self._timeKey = "_timeKey"
	self._uiCommonList = {}
	self._tabSelList = {}
	self._tabRedPoint = {}
	self._tabType = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubUpStar:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
	self:ClearCommonIconList(self._hyperList)
	
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubUpStar:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubUpStar:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitDate()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISubUpStar:InitCommand()
	self:SetWndText(self.mTypeText1,ccClientText(21714))
	self:SetWndText(self.mTypeText2,ccClientText(21715))

	local sid = self:GetWndArg("sid")
	self._sid = sid
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	if not modelId then return end
	self._modelId = modelId
	self._enumList = self._modelEnumList[modelId]

	self:OnActivityConfigData()
end
function UISubUpStar:RefreshTabRed(_tabType,list)
	if _tabType == 0 then return end
	local redList = {}
	for i, v in ipairs(list) do
		local status = v.goalData.status
		if status == 1 then
			local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
			local moreInfo = string.split(entryCfg1.moreInfo,";")
			redList[tonumber(moreInfo[1])] = true
		end
	end
	for i, v in pairs(self._tabRedPoint) do
		CS.ShowObject(v,redList[i])
	end
end
------------------------------------------------------------------
function UISubUpStar:OnClickHelp()
	local config = self._config
	if not config then return end
	local content = config.upStarHelpDes
	local title = ccClientText(21747)
	GF.OpenWnd("UIBzTips",{title = title,text = content})
end
function UISubUpStar:InitEvent()
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end)
	self:SetWndClick(self.mBtnGoTo, function(...) self:OnClickGoTo() end)
end
function UISubUpStar:TabListItem(list,item, itemdata, itempos)
	local sel = self:FindWndTrans(item,"Sel")
	local icon = self:FindWndTrans(item,"Icon")
	local btnName = self:FindWndTrans(item,"BtnName")
	local btn = self:FindWndTrans(item,"Btn")
	local redPoint = self:FindWndTrans(item,"RedPoint")

	self._tabSelList[itemdata.type] = sel
	self:SetWndEasyImage(icon,itemdata.icon)
	self:SetWndText(btnName,itemdata.title)
	self._tabRedPoint[itemdata.type] = redPoint
	self:SetWndClick(btn,function ()
		self:OnClickTab(itemdata.type)
	end)
end
function UISubUpStar:SetTime()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local endTime = activityData.endTime
	local timespan = endTime - GetTimestamp()
	if endTime <= 0 or endTime <= 0 then
		self:TimerStop(self._timeKey)
		self:SetWndText(self.mTimeText,ccClientText(18404))
		return
	end
	local timeStr
	if timespan > 86400 then
		--N天N小时
		timeStr = LUtil.FormatTimespanCn(timespan)
	else
		--XX:XX:XX
		timeStr = LUtil.FormatTimespanNumber(timespan)
	end
	timeStr = string.replace(ccClientText(21700),timeStr)
	self:SetWndText(self.mTimeText,timeStr)
end
function UISubUpStar:OnClickUpStarGet(itemData)
	local sid = self._sid
	local list ={}
	if itemData.goalData.status == 1 then
		local entryId = itemData.entryId
		local data1 = { sid = sid,pageId = itemData.pageId,entryId = entryId}
		table.insert(list,data1)
	end
	if itemData.goalData2.status == 1 and itemData.isBuy then
		local data2 = { sid = sid,pageId = itemData.pageId2,entryId = itemData.entryId2}
		table.insert(list,data2)
	else
		--显示战令奖励弹窗
		local entryCfg2 = gModelActivity:GetWebActivityEntryData(sid,itemData.pageId2,itemData.entryId2)
		self._advanceUpStarData  = itemData
		self._passRewardItemList = LxDataHelper.ParseItem(entryCfg2.reward)
	end
	gModelActivity:OnActivityReceiveGoalListReq(list)
end
function UISubUpStar:RefreshTopTabShow(_tabType)
	local _upStarDes = self._upStarDes or {}
	local desc = _upStarDes[_tabType] or _upStarDes[1]
	self:SetWndText(self.mDesText, desc)
	local _upStarTitle = self._upStarTitle or {}
	local upStarTitle = _upStarTitle[_tabType] or _upStarTitle[1]
	local _upStarTitlePos = self._upStarTitlePos or {}
	local upStarTitlePos = _upStarTitlePos[_tabType] or _upStarTitlePos[1]
	if LxUiHelper.IsImgPathValid(upStarTitle) then
		local parent = self.mTextImg
		self:SetWndEasyImage(parent, upStarTitle, function ()
			CS.ShowObject(parent,true)
		end , true)
		if not string.isempty(upStarTitlePos) then
			local pos = LxDataHelper.ParseVector2NotEmpty(upStarTitlePos)
			self:SetAnchorPos(parent,pos)
		end
		CS.ShowObject(parent, true)
	end
    local _upStarImage = self._upStarImage or {}
    local upStarImage = _upStarImage[_tabType] or _upStarImage[1]
    if LxUiHelper.IsImgPathValid(upStarImage) then
        local parent = self.mBg
        self:SetWndEasyImage(parent, upStarImage,function ()
            CS.ShowObject(parent,true)
        end)
    end
    local _upStarHero = self._upStarHero or {}
    local upStarHero = _upStarHero[_tabType] or _upStarHero[1]
    local _upStarHeroPos = self._upStarHeroPos or {}
    local upStarHeroPos = _upStarHeroPos[_tabType] or _upStarHeroPos[1]
	self:ShowActivityHero(self.mRolepart,upStarHero,upStarHeroPos)

	--if LxUiHelper.IsImgPathValid(upStarHero) then
        --local parent = self.mHeroImg
        --self:SetWndEasyImage(parent, upStarHero,function ()
        --    CS.ShowObject(parent,true)
        --end,true)
        --if not string.isempty(upStarHeroPos) then
        --    local pos = LxDataHelper.ParseVector2NotEmpty(upStarHeroPos)
        --    self:SetAnchorPos(parent,pos)
        --end
    --end
    local _upStarDiImage = self._upStarDiImage or {}
    local upStarDiImage = _upStarDiImage[_tabType] or _upStarDiImage[1]
    if LxUiHelper.IsImgPathValid(upStarDiImage) then
        if LxUiHelper.IsImgPathValid(upStarDiImage) then
            self:SetWndEasyImage(self.mTextTypeBg, upStarDiImage)
        end
    end
    local _upStarPointImage = self._upStarPointImage or {}
    local upStarPointImage = _upStarPointImage[_tabType] or _upStarPointImage[1]
    if LxUiHelper.IsImgPathValid(upStarPointImage) then
        for i = 1, 3 do
            local starImg = self:FindWndTrans(self.mTextTypeBg,"Star"..i)
            self:SetWndEasyImage(starImg, upStarPointImage,nil,true)
        end
    end
end
function UISubUpStar:OnClickTab(type)
	local _tabSelList = self._tabSelList or {}
	local _tabType = self._tabType
	if _tabType and _tabType ~= type then
		local oldSel = _tabSelList[_tabType]
		CS.ShowObject(oldSel,false)
	end
	local newSel = _tabSelList[type]
	CS.ShowObject(newSel,true)
	self._tabType = type
	self:RefreshData()
end

function UISubUpStar:RefreshData()
	local _tabType = self._tabType or 0
	local sid = self._sid
	local pages = self._pages
	local enumList = self._enumList
	if not sid or not pages then return end
	if not pages[enumList[1]] or not pages[enumList[2]]then return end
	self:RefreshTopTabShow(_tabType)
	local eliteList = pages[enumList[1]].entry
	local advanceList = pages[enumList[2]].entry
	self:RefreshTabRed(_tabType,eliteList)
	local eList = {}
	for i, v in ipairs(eliteList) do
		if _tabType ~= 0 then
			local entryCfg1 = gModelActivity:GetWebActivityEntryData(sid,v.pageId,v.entryId)
			local moreInfo = string.split(entryCfg1.moreInfo,";")
			if _tabType == tonumber(moreInfo[1]) then
				table.insert(eList,v)
			end
		end
	end
	local listLen = #eList
	if listLen == 0 then return end
	local aList = {}
	for i, v in ipairs(advanceList) do
		aList[v.entryId] = v
	end
	local schedule,completeIndex = 0,0
	local canGetIndex,canBuyIndex
	for i, v in ipairs(eList) do
		--local data = aList[i]
		local data = aList[checknumber(v.entryId)]

		v.goalData2 = data.goalData
		v.pageId2 = data.pageId
		v.entryId2 = data.entryId
		local personal = data.MarketData.personal
		local personalGoal =data.MarketData.personalGoal
		local haveBuyNum = personalGoal - personal
		local status = v.goalData.status
		local isBuy  = personal > 0 and personalGoal > 0
		v.isBuy = isBuy
		v.haveBuyNum = haveBuyNum
		if status ~= 0 then
			completeIndex = i
			if not canGetIndex and status == 1 then
				canGetIndex = i
			end
			if not canBuyIndex or isBuy then
				canBuyIndex = i
			end
		end
		local scdle = tonumber(v.goalData.schedules[1].schedule)
		if scdle > 0 and schedule < scdle then
			schedule = scdle
		end
	end
	self._eliteMaxNum = listLen
	self._completeIndex = completeIndex
	table.sort(eList,function(a, b) return a.sort<b.sort end)
	local _upStarCellUIList = self._upStarCellUIList
	if _upStarCellUIList then
		_upStarCellUIList:RefreshList(eList)
		local superList = _upStarCellUIList:GetList()
		superList:DrawAllItems(true)
	else
		_upStarCellUIList = self:GetUIScroll("_upStarCell")
		self._upStarCellUIList = _upStarCellUIList
		local isShowTowScroll = self._isShotTowHero
		CS.ShowObject(self.mCellScroll1,not isShowTowScroll)
		CS.ShowObject(self.mCellScroll2,isShowTowScroll)
		local mCellScroll = isShowTowScroll and self.mCellScroll2 or self.mCellScroll1
		_upStarCellUIList:Create(mCellScroll,eList,function (...) self:UpStarListItem(...) end, UIItemList.SUPER_GRID)
	end
	local index
	if canGetIndex then
		index = canGetIndex
	elseif completeIndex < listLen then
		index = completeIndex
	else
		index = canBuyIndex or 1
	end
	index = math.range(index, 1, listLen)
	_upStarCellUIList:MoveToPos(index)
end
function UISubUpStar:RefreshTab()
	local upStarTabImage = self._upStarTabImage

	local list = {}
	local isShotTowHero = self._isShotTowHero

	CS.ShowObject(self.mTabScroll, isShotTowHero)

	if isShotTowHero then
		for i, v in ipairs(upStarTabImage) do
			local arr = string.split(v,"=")
			table.insert(list,{
				type = tonumber(arr[1]),
				title = arr[2],
				icon = arr[3],
			})
		end

		local _tabUIList = self._tabUIList
		if _tabUIList then
			_tabUIList:RefreshList(list)
		else
			_tabUIList = self:GetUIScroll("mTabList")
			self._tabUIList = _tabUIList
			_tabUIList:Create(self.mTabScroll,list,function (...) self:TabListItem(...) end)
		end
	end

	if self._tabType == 0 then
		if isShotTowHero then
			self:OnClickTab(list[1].type)
		else
			self._tabType = 1
			self:RefreshData()
		end
	end
end
------------------------------------------------------------------
function UISubUpStar:OnTimer(key)
	if key == self._timeKey then
		self:SetTime()
	end
end

function UISubUpStar:InitDate()
	self._modelEnumList = {
		[ModelActivity.MODEL_ACTIVITY_TYPE_122] = { ModelActivity.UpStarGift_3, ModelActivity.UpStarGift_4 },
	}
end
function UISubUpStar:UpStarListItem(list,item, itemdata, itempos)
	local sid = self._sid
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(sid,itemdata.pageId,itemdata.entryId)
	local entryCfg2 = gModelActivity:GetWebActivityEntryData(sid,itemdata.pageId2,itemdata.entryId2)
	if not entryCfg1 or not entryCfg2 then return end
	local lineBg = self:FindWndTrans(item, "LineBg")
	local lineBgTop = self:FindWndTrans(item, "LineBgTop")
	local lineBgBottem = self:FindWndTrans(item, "LineBgBottem")
	-- local wire1 = self:FindWndTrans(item,"Wire1")
	-- local wireCover1 = self:FindWndTrans(wire1, "Cover")
	-- local wire2 = self:FindWndTrans(item,"Wire2")
	-- local wireCover2 = self:FindWndTrans(wire2, "Cover")
	local numText = self:FindWndTrans(item,"NumText")
	local NumText2 = self:FindWndTrans(item,"NumText2")
	local TxtNum = self:FindWndTrans(item,"TxtNum")
	local imageBg = self:FindWndTrans(item, "ImageBg")
	local imageCover = self:FindWndTrans(item, "ImageCover")
	local rewardList1 = self:FindWndTrans(item,"RewardList1")
	local rewardList2 = self:FindWndTrans(item,"RewardList2")
	local payBtn = self:FindWndTrans(item,"PayBtn")
	local payBtnEff = self:FindWndTrans(payBtn,"Eff")
	local getImage = self:FindWndTrans(item,"GetImage")

	local entryId2 = itemdata.entryId2
	local isFirst = itempos == 1
	local isLast  = itempos == self._eliteMaxNum
	local status1 = itemdata.goalData.status
	local haveBuyNum = itemdata.haveBuyNum

	CS.ShowObject(lineBg, not (isFirst or isLast))
	CS.ShowObject(lineBgTop, isFirst)
	CS.ShowObject(lineBgBottem, isLast)
	-- CS.ShowObject(wire1,not isFirst)
	-- CS.ShowObject(wire2, not isLast)

	local completeIndex = self._completeIndex or 0
	local isComplete = itempos <= completeIndex
	local reward1List = LxDataHelper.ParseItem(entryCfg1.reward)
	local InstanceID = item:GetInstanceID()
	for i, v in ipairs(reward1List) do
		v.index = 1
	end
	local uiList = self:GetUIScroll(InstanceID.."A")
	if(uiList:GetList())then
		uiList:RefreshList(reward1List)
	else
		uiList:Create(rewardList1,reward1List,function (...) self:UpStarRewardListItem(...) end)
	end
	local reward2List = LxDataHelper.ParseItem(entryCfg2.reward)
	for i, v in ipairs(reward2List) do
		v.index = 2
		v.isBuy = itemdata.isBuy
		v.isComplete = isComplete
	end
	local uiList1 = self:GetUIScroll(InstanceID.."B")
	if(uiList1:GetList())then
		uiList1:RefreshList(reward2List)
	else
		uiList1:Create(rewardList2,reward2List,function (...) self:UpStarRewardListItem(...) end)
	end

	local fun
	local isGray = false
	local isGet  = false
	-- CS.ShowObject(wireCover1, status1 ~= 0)
	-- CS.ShowObject(wireCover2, isComplete)
	CS.ShowObject(imageBg, not isComplete)
	CS.ShowObject(imageCover, isComplete)

	local btnStr = ccClientText(21717)
	local isShowGetEff = false

	if(status1 == 1)then
		isShowGetEff = true
		CS.ShowObject(TxtNum,false)
		fun = function()self:OnClickUpStarGet(itemdata) end
	else
		if(haveBuyNum > 0)then
			btnStr = gModelPay:GetShowByWelfareId(tonumber(entryCfg2.expend2)) --string.replace(ccClientText(21718),rmb)
			CS.ShowObject(TxtNum,isComplete)
			if status1 == 0 then
				isGray = true
				fun = function()
					local str = ccClientText(21716)
					GF.ShowMessage(str)
				end
			else
				fun = function() self:OnClickBuyAdvance(entryId2) end
			end
		else
			isGet = true
		end
	end
	CS.ShowObject(getImage,isGet or isGray)
	local imgPath = isGray and "activity_turn_txt_16" or "public_txt_4_2"
	self:SetWndEasyImage(getImage,imgPath)
	self:SetWndButtonText(payBtn,btnStr)
	self:SetWndButtonGray(payBtn, isGray)
	CS.ShowObject(payBtn,not isGet and not isGray)

	-- local numStr = LUtil.FormatColorStr(entryCfg1.name,isComplete and "black" or "lightBlue")
	self:SetWndText(numText,entryCfg1.name)
	self:SetWndText(NumText2,entryCfg1.name)
	CS.ShowObject(numText,isComplete)
	CS.ShowObject(NumText2,not isComplete)
	self:SetWndText(TxtNum,ccClientText(15502)..math.max(haveBuyNum,0))

	if fun then
		self:SetWndClick(payBtn,fun)
	end

	if isShowGetEff then
		self:CreateWndEffect(payBtnEff,self._getBtnEff,InstanceID,100,false,false)
	end
	CS.ShowObject(payBtnEff,isShowGetEff)
end
function UISubUpStar:UpStarRewardListItem(list, item, itemdata, itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local root = self:FindWndTrans(item,"itemRoot/Icon")
	local mask = self:FindWndTrans(item,"Mask")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local EffTrans = self:FindWndTrans(item,"Eff")
	local showEff = false
	CS.ShowObject(mask,false)
	if itemdata.index == 2 and not itemdata.isComplete then
		showEff = false
		-- CS.ShowObject(mask,true)
	end
	if EffTrans then
		local show = false
		if itemdata.itemType == LItemTypeConst.TYPE_ITEM and showEff then
			LxResUtil.DestroyChildImmediate(EffTrans)
			local itemRef = gModelItem:GetRefByRefId(itemdata.itemId)
			local bgEff = itemRef and itemRef.bgEff or nil
			if not string.isempty(bgEff) then
				show = true
				local instanceId = item:GetInstanceID()
				self:CreateWndEffect(EffTrans,bgEff,instanceId,66,false,false)
			end
		end
		CS.ShowObject(EffTrans,show)
	end

	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
	self:SetIconClickScale(root, true)
	self:SetWndClick(root, function() gModelGeneral:ShowCommonItemTipWnd(itemdata) end)
	self:SetWndText(itemNum,LUtil.NumberCoversion(itemdata.itemNum))
end
function UISubUpStar:OnClickGoTo()
	local config = self._config
	if not config then return end
	local jump = config.upStarBtnJump
	if not gModelFunctionOpen:CheckIsOpened(jump,true) then return end
	gModelFunctionOpen:Jump(jump)
end
------------------------------------------------------------------
function UISubUpStar:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config
	self._config = data

	local upStarImage,upStarImagePos,upStarDes,upStarHelpPos,upStarTitle,upStarTitlePos,upStarTimePos,
	upStarBtn,upStarBtnText,upStarDiImage,upStarTabImage,upStarHero,upStarHeroPos,upStarPointImage
	= data.upStarImage,data.upStarImagePos,data.upStarDes,data.upStarHelpPos,data.upStarTitle,data.upStarTitlePos,data.upStarTimePos,
	data.upStarBtn,data.upStarBtnText,data.upStarDiImage,data.upStarTabImage,data.upStarHero,data.upStarHeroPos,data.upStarPointImage

	if not string.isempty(upStarTabImage)then
		self._upStarTabImage = string.split(upStarTabImage,"|")
	end
	self._isShotTowHero = self._upStarTabImage and self._upStarTabImage[1] ~= "0"
    if not string.isempty(upStarImage)then
        self._upStarImage = string.split(upStarImage,"|")
    end

	printErrorN("upStarHero "..upStarHero)
    if not string.isempty(upStarHero)then
        self._upStarHero = string.split(upStarHero,"|")
    end
    if not string.isempty(upStarHeroPos)then
        self._upStarHeroPos = string.split(upStarHeroPos,"|")
    end
    if not string.isempty(upStarDiImage)then
        self._upStarDiImage = string.split(upStarDiImage,"|")
    end
    if not string.isempty(upStarPointImage)then
        self._upStarPointImage = string.split(upStarPointImage,"|")
    end
	if not string.isempty(upStarDes) then
		local desc = string.gsub(upStarDes,"\\n","\n")
		self._upStarDes = string.split(desc,"|")
	end
	if not string.isempty(upStarHelpPos) then
		local pos = LxDataHelper.ParseVector2NotEmpty(upStarHelpPos)
		self:SetAnchorPos(self.mBtnHelp,pos)
	end
	if not string.isempty(upStarTitle) then
		self._upStarTitle = string.split(upStarTitle,"|")
	end
	if not string.isempty(upStarTitlePos) then
		self._upStarTitlePos = string.split(upStarTitlePos,"|")
	end
	if not string.isempty(upStarTimePos) then
		local pos = LxDataHelper.ParseVector2NotEmpty(upStarTimePos)
		self:SetAnchorPos(self.mTimeBg,pos)
	end
	if not string.isempty(upStarBtn) then
		local pos = LxDataHelper.ParseVector2NotEmpty(upStarBtn)
		self:SetAnchorPos(self.mBtnGoTo,pos)
	end
	if not string.isempty(upStarBtnText) then
		self:SetWndButtonText(self.mBtnGoTo, upStarBtnText)
		CS.ShowObject(self.mBtnGoTo,true)
	end
	local activityDatas = gModelActivity:GetActivityBySid(sid)
	local _endTime = activityDatas.endTime
	if _endTime and _endTime ~= -1 then
		CS.ShowObject(self.mTimeBg,true)
		self:TimerStop(self._timeKey)
		self:TimerStart(self._timeKey,1,false,-1)
		self:SetTime()
	end
	gModelActivity:OnActivityPageReq(self._sid,self._enumList)
end
function UISubUpStar:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = page.pageId
		_pages[pageId] = page
	end
	self._pages = _pages
	if self._tabType == 0 then
		self:RefreshTab()
	else
		self:RefreshData()
	end
end
function UISubUpStar:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		local activity = pb.activity
		local sid = activity.sid
		if self._sid ~= sid then return end
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			local sid = v.sid
			if self._sid == sid then
				self:RefreshData()
				return
			end
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
end
function UISubUpStar:OnClickBuyAdvance(entryId)--购买进阶令
	local sid = self._sid
	local pages = self._pages
	if table.isempty(pages) then return end
	local enumList = self._enumList
	if not enumList or not enumList[2] then return end
	local advanceList = pages[enumList[2]].entry
	if not advanceList then return end
	local entryData
	local posIndex
	for k,v in pairs(advanceList) do
		if v.entryId == entryId then
			entryData = v
			posIndex = k
			break
		end
	end
	if not entryData then
		printInfoNR("advanceList[entryId] is a nil, entryId = "..(entryId or "nil"))
		return
	end
	local entryCfg = gModelActivity:GetWebActivityEntryData(sid,entryData.pageId,entryId)
	local buyBtnStr = gModelPay:GetShowByWelfareId(tonumber(entryCfg.expend2))

	GF.OpenWnd("UIPkBuyPop", {
		sid = sid,
		entry = advanceList,
		defaultIndex = posIndex,
		buyBtnStr = buyBtnStr,
		passType = self._modelId
	})
end
------------------------------------------------------------------
return UISubUpStar


