---
--- Created by LCM.
--- DateTime: 2024/3/9 20:39:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWarhjkes:LWnd
local UIWarhjkes = LxWndClass("UIWarhjkes", LWnd)

UIWarhjkes.TYPE_BOSSTOWER = 1
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWarhjkes:UIWarhjkes()
	self._endKey = "_endKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWarhjkes:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWarhjkes:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWarhjkes:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitText()
	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIWarhjkes:OnClickOneKeyGet()
	local list ={}
	local activityDataList = self._activityDataList
	if not activityDataList then return end
	local oneActivityData = activityDataList[2]
	if not oneActivityData then return end
	for idx,val in ipairs(oneActivityData.entry) do
		if val.goalData.status == 1 then
			table.insert(list,{sid = self._sid , pageId = 2,entryId = val.entryId})
		end
	end
	local moreActivityData = activityDataList[3]
	if self._isBuy and moreActivityData then
		for idx,val in ipairs(moreActivityData.entry) do
			if val.goalData.status == 1 then
				table.insert(list,{sid = self._sid , pageId = 3,entryId = val.entryId})
			end
		end
	end
	gModelActivity:OnActivityReceiveGoalListReq(list)
end

function UIWarhjkes:OnActivityPageResp(pb)
	if self._sid ~= pb.sid then return end
	self:DisposeOpenTypeActivity(pb)
end

function UIWarhjkes:DisposeBossTowerActivityData(pb)
	-- local activityDataList = self._activityDataList
	-- if not activityDataList then
	-- 	activityDataList = {}
	-- 	self._activityDataList = activityDataList
	-- end

	-- local bossTowerPageIdList = self._bossTowerPageIdList

	-- local pages = pb.pages
	-- local pageId
	-- for i, v in ipairs(pages) do
	-- 	pageId = v.pageId
	-- 	if bossTowerPageIdList[pageId] or pageId == 1 then
	-- 		local page = gModelActivity:GenerateActivePageDataFromPb(v)
	-- 		activityDataList[pageId] = page
	-- 	end
	-- end

	-- self:RefreshData()
end

function UIWarhjkes:OnDrawRewardCell(list,item,itemdata,itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local Icon = self:FindWndTrans(itemRoot,"Icon")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local Mask = self:FindWndTrans(item,"Mask")

	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(itemdata.type,itemdata.itemId, itemdata.count)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()

	self:SetWndClick(Icon,function() gModelGeneral:ShowCommonItemTipWnd(itemdata) end)

	self:SetWndText(itemNum,itemdata.count)

	CS.ShowObject(Mask,not self._isBuy)
end

function UIWarhjkes:DisposeOpenTypeActivity(pb)
	-- local openType = self._openType
	-- if openType == UIWarhjkes.TYPE_BOSSTOWER then
	-- 	self:DisposeBossTowerActivityData(pb)
	-- end
end

function UIWarhjkes:CreateRewardList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawRewardCell(...) end)
		uiList:EnableScroll(true,true)
	end
end

function UIWarhjkes:InitText()
	local str = ccClientText(23771)
	local hyper = UIHyperText:New()
	hyper:Create(self.mDesText)
	str = hyper:AddHyper(str, {func = function()
		self:WndClose()
	end})
	self:SetWndText(self.mDesText, str)
	CS.ShowObject(self.mDesText,true)


	local bossTowerInsInfo = false
	if not bossTowerInsInfo then return end
	local insRefId = bossTowerInsInfo.refId
	local ref = gModelBossTower:GetBossTowerInsRefByRefId(insRefId)
	if not ref then return end
	local type = ref.type
	local name = ccLngText(ref.name)
	local chapterName = gModelBossTower:GetBossTowerChapterNameByRefId(type)
	local chapterList = {}
	for k,v in pairs(GameTable.BossTowerChapterRef) do
		table.insert(chapterList,{
			refId = v.refId,
			floor = v.floor,
		})
	end
	table.sort(chapterList,function(a,b)
		return a.refId < b.refId
	end)
	local chapterNum = 0
	for i,v in ipairs(chapterList) do
		if type > i then
			chapterNum = chapterNum + v.floor
		end
	end
	chapterNum = chapterNum + ref.sort
	--local str = string.replace(ccClientText(23770),chapterName,name,chapterNum)
	local str = string.replace(ccClientText(23770),chapterNum)
	self:SetWndText(self.mScheduleText,str)
	CS.ShowObject(self.mScheduleText,true)

	self:SetWndText(self.mText1, ccClientText(23781))
	self:SetWndText(self.mText2, ccClientText(23782))

	local text = ccClientText(156)
	if not string.isempty(text) then
		self:SetWndText(self.mBuyTipsText, text)
		CS.ShowObject(self.mBuyTipsText, true)
	end
end

function UIWarhjkes:GoToTaskFunc()
	-- GF.OpenWnd("UIActTower",{page = 2,sid = self._sid})
	self:WndClose()
end

function UIWarhjkes:OnDrawWarMakesCell(list,item,itemdata,itempos)
	local NoFullImg = self:FindWndTrans(item,"NoFullImg")
	local FullImg = self:FindWndTrans(item,"FullImg")

	local TopLineBg = self:FindWndTrans(item,"TopLineBg")
	local TShowFull = self:FindWndTrans(TopLineBg,"TShowFull")
	local BotLineBg = self:FindWndTrans(item,"BotLineBg")
	local BShowFull = self:FindWndTrans(BotLineBg,"BShowFull")

	local rewardList1 = self:FindWndTrans(item,"RewardList1")
	local rewardList2 = self:FindWndTrans(item,"RewardList2")
	local payBtn = self:FindWndTrans(item,"PayBtn")
	local goBtn = self:FindWndTrans(item,"GoBtn")
    local goBtnEff = self:FindWndTrans(goBtn,"Eff")
	local getImage = self:FindWndTrans(item,"GetImage")

	local completeIndex = self._completeIndex or 0

	self:SetTextTile(NoFullImg,itemdata.name)
	self:SetTextTile(FullImg,itemdata.name)

	local showFull = itempos <= completeIndex
	CS.ShowObject(FullImg,showFull)

	local showTopLineBg = itempos ~= 1
	CS.ShowObject(TopLineBg,showTopLineBg)
	if showTopLineBg then
		CS.ShowObject(TShowFull,showFull)
	end

	local showBotLineBg = itempos < self._allLen
	CS.ShowObject(BotLineBg,showBotLineBg)
	if showBotLineBg then
		CS.ShowObject(BShowFull,showFull)
	end

	local status1 = itemdata.status1
	local status2 = itemdata.status2


	local btnStr = ccClientText(15804)
	local showGoBtn = false
    local effName
	local btnImg = "public_btn_2_1"
	local func
	if status1 == 0 then
		showGoBtn = true
		func = function()
			-- 前往完成
			self:GoToTaskFunc()
		end
	else
		btnStr = ccClientText(15802)
		if status1 == 2 then
			if status2 == 2 then
				showGoBtn = false
				btnStr = ccClientText(15807)
				func = function()
					-- 已完成
				end
			elseif self._isBuy then
				btnImg = "public_btn_2_2"
				showGoBtn = true
				btnStr = ccClientText(15802)
				func = function()
					-- 领取协议
					self:OnClickOneKeyGet()
				end
                effName = "fx_anniu_02"
			else
				btnImg = "public_btn_2_2"
				showGoBtn = true
				btnStr = ccClientText(15803)
				func = function()
					-- 购买
					self:OnClickBuyAdvance()
				end
			end
		else
			btnImg = "public_btn_2_2"
			showGoBtn = true
			func = function()
				-- 领取协议
				self:OnClickOneKeyGet()
			end
            effName = "fx_anniu_02"
		end
	end

    local showEff = false
    if showGoBtn and effName then
        local key = goBtnEff:GetInstanceID()
        self:DestroyWndEffectByKey(key)
        self:CreateWndEffect(goBtnEff,effName,key,100,false,false)
        showEff = true
    end
    CS.ShowObject(goBtnEff,showEff)


	if func then
		self:SetWndClick(goBtn,function()
			func()
		end)
	end

	local mat = LUtil.GetOutlineMatByImg(btnImg)
	self:SetWndButtonTextMat(goBtn,mat)
	self:SetWndButtonImg(goBtn,btnImg)
	self:SetWndButtonText(goBtn,btnStr)
	CS.ShowObject(goBtn,showGoBtn)
	CS.ShowObject(getImage,not showGoBtn)


	self:CreateRewardList(rewardList1,itemdata.oneReward)
	self:CreateRewardList(rewardList2,itemdata.moreReward)
end

function UIWarhjkes:OnClickBuyAdvance()--购买进阶令
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local activityDataList = self._activityDataList
	if not activityDataList then return end
	local curPage = activityDataList[1]
	if not curPage then return end
	local entry = curPage.entry[1]
	-- GF.OpenWnd("UIPkBuyPopBig",{sid = self._sid,entry = entry, modelActivityType = ModelActivity.ACTIVITY_TOWER})
end

function UIWarhjkes:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtnFunc() end)
	self:SetWndClick(self.mBuyBtn,function() self:OnClickBuyAdvance() end)
end

function UIWarhjkes:OnClickHelpBtnFunc()
	GF.OpenWnd("UIBzTips",{title = self._title,text = self._warBuyHelpTxt})
end

function UIWarhjkes:OnTimer(key)
	if key == self._endKey then
		self:RefreshCountDown()
	end
end

function UIWarhjkes:OnActivityListResp(pb)
	local activities = pb.activities
	local sid = self._sid
	for i, v in ipairs(activities) do
		if v.sid == sid then
			gModelActivity:OnActivityPageReq(sid)
			break
		end
	end
end

function UIWarhjkes:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function(pb) self:OnActivityListResp(pb) end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
end

function UIWarhjkes:InitData()
	local openType = self:GetWndArg("openType")
	if openType == nil then
		openType = UIWarhjkes.TYPE_BOSSTOWER
	end
	self._openType = openType

	self._sid = self:GetWndArg("sid")

	self._bossTowerPageIdList = {
		[2] = self.mText1,
		[3] = self.mText2,
	}
end

function UIWarhjkes:RefreshBuyGiftStatus()
	local activityDataList = self._activityDataList
	if not activityDataList then return end
	local giftData = activityDataList[1]
	if not giftData then return end
	local entry = giftData.entry[1]
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,giftData.pageId,entry.entryId)
	if not entryCfg1 then return end
	local expend2 = tonumber(entryCfg1.expend2)
	local buyBtnStr = gModelPay:GetShowByWelfareId(expend2)
	self:SetWndButtonText(self.mBuyBtn,buyBtnStr)
	local showBtn = self._isBuy
	CS.ShowObject(self.mBuyBtn,not showBtn)
	CS.ShowObject(self.mShowImg,showBtn)

	local config = self._config
	if not config then return end

--[[
	--- 新版界面去掉顶部栏图片
	local path = config.bgTwo
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTopDiv ,path)
	end
	CS.ShowObject(self.mTopDiv, true)]]

	local path = config.titleOne or "activity_spring_txt_13"
	if LxUiHelper.IsImgPathValid(path) then
		local pos = config.titleOnePos
		self:SetWndEasyImage(self.mTextImg, path, function()
			if not string.isempty(pos) then
				self:SetAnchorPos(self.mTextImg, LxDataHelper.ParseVector2NotEmpty(pos))
			end
		end, true)
	end
	CS.ShowObject(self.mTextImg,true)
end

function UIWarhjkes:RefreshCountDown()
	local endTime = self._endTime
	if not endTime then
		self:TimerStop(self._endKey)
		self:SetWndText(self.mTimeText,"")
		CS.ShowObject(self.mTimeBg,false)
		return
	end
	local curTime = GetTimestamp()
	local lastTime = endTime - curTime
	local timeStr
	if lastTime > 0 then
		timeStr = string.replace(ccClientText(23200), LUtil.FormatTimespanCn(lastTime))
	else
		timeStr = ccClientText(14301)
		self:TimerStop(self._endKey)
	end
	self:SetWndText(self.mTimeText,timeStr)
	CS.ShowObject(self.mTimeBg,true)
end

function UIWarhjkes:RefreshData()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = JSON.decode(activityData.moreInfo)
	local buyPassNum = data.buyPassNum
	self._isBuy = tonumber(buyPassNum) > 0

	local config = activityWebData.config
	if config then
		self._title = config.warBuyHelpName
		self._warBuyHelpTxt = config.warBuyHelpTxt
		self._config = config
	end

	self:RefreshBuyGiftStatus()


	self:TimerStop(self._endKey)
	self._endTime = tonumber(activityData.endTime)
	self:RefreshCountDown()
	self:TimerStart(self._endKey,1,false,-1)

	local pageTypeDataList = {}
	local activityDataList = self._activityDataList
	local bossTowerPageIdList = self._bossTowerPageIdList
	self._completeIndex = 0
	for pageId,v in pairs(bossTowerPageIdList) do
		local pageData = activityDataList[pageId]
		if pageData then
			for idx,val in ipairs(pageData.entry) do
				local entryId = val.entryId
				local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,pageId,entryId)
				if entryCfg then
					if val.goalData.status ~= 0 then
						self._completeIndex = idx
					end
					local id = entryCfg.id
					local pageTypeData = pageTypeDataList[id]
					if not pageTypeData then
						pageTypeData = {}
						pageTypeDataList[id] = pageTypeData
					end
					pageTypeData[pageId] = {
						description = entryCfg.description,
						icon = entryCfg.icon,
						moreInfo = entryCfg.moreInfo,
						name = entryCfg.name,
						sort = entryCfg.sort,
						reward = val.items,
						serverData = val,
					}
				end
			end
		end
	end
	local dataList = {}
	for id,tPageTypeDataList in pairs(pageTypeDataList) do
		local oneData,moreData = tPageTypeDataList[2],tPageTypeDataList[3]
		if oneData and moreData then
			local oneSD,moreSD = oneData.serverData,moreData.serverData
			table.insert(dataList,{
				oneReward = oneData.reward,
				moreReward = moreData.reward,
				name = oneData.name,
				icon = oneData.icon,
				moreInfo = oneData.moreInfo,
				sort = oneData.sort,
				oneServerData = oneSD,
				moreServerData = moreSD,
				status1 = oneSD.goalData.status,
				status2 = moreSD.goalData.status,
			})
		end
	end
	table.sort(dataList,function(a,b)
		return a.sort < b.sort
	end)
	self:InitWarMakesList(dataList)
end

function UIWarhjkes:OnActivityResp(pb)
	if self._sid ~= pb.sid then return end
	gModelActivity:OnActivityPageReq(self._sid)
end

function UIWarhjkes:InitWarMakesList(list)
	self._allLen = #list
	local uiWarMakesList = self._uiWarMakesList
	if uiWarMakesList then
		uiWarMakesList:RefreshData(list)
	else
		uiWarMakesList = self:GetUIScroll("uiWarMakesList")
		self._uiWarMakesList = uiWarMakesList
		uiWarMakesList:Create(self.mWarMakesList,list,function(...) self:OnDrawWarMakesCell(...) end,UIItemList.WRAP,false)
	end
	local uiList = uiWarMakesList:GetList()
	if uiList then
		local index = self._completeIndex - 1
		if index < 4 then
			index = 0
		end
		uiList:RefreshList(UIListWrap.RefreshMode.Custom,index)
	end
end

function UIWarhjkes:OnActivityConfigData(data,sid)
	if sid ~= self._sid then return end
	local webData = gModelActivity:GetWebActivityDataById(sid)

	local config = webData.config
	if not config then return end
	local warBuyBg = config.warBuyBg
	if LxUiHelper.IsImgPathValid(warBuyBg) then
		self:SetWndEasyImage(self.mBg, warBuyBg, function()
			CS.ShowObject(self.mBg,true)
		end)
	else
		CS.ShowObject(self.mBg,true)
	end

	gModelActivity:OnActivityPageReq(sid)
end


------------------------------------------------------------------
return UIWarhjkes


