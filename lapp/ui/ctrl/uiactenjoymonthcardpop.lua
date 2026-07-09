---
--- Created by Administrator.
--- DateTime: 2023/10/12 22:28:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActEnjoyMonthCardPop:LWnd
local UIActEnjoyMonthCardPop = LxWndClass("UIActEnjoyMonthCardPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActEnjoyMonthCardPop:UIActEnjoyMonthCardPop()
	---@type UIIconEasyList
	self._rewardListCls1 = nil
	---@type UIIconEasyList
	self._rewardListClsMax1 = nil
	---@type UIIconEasyList
	self._rewardListCls2 = nil
	---@type UIIconEasyList
	self._rewardListClsMax2 = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActEnjoyMonthCardPop:OnWndClose()
	if self._rewardListCls1 then
		self._rewardListCls1:Destroy()
		self._rewardListCls1 = nil
	end

	if self._rewardListClsMax1 then
		self._rewardListClsMax1:Destroy()
		self._rewardListClsMax1 = nil
	end

	if self._rewardListCls2 then
		self._rewardListCls2:Destroy()
		self._rewardListCls2 = nil
	end

	if self._rewardListClsMax2 then
		self._rewardListClsMax2:Destroy()
		self._rewardListClsMax2 = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActEnjoyMonthCardPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActEnjoyMonthCardPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
	self:InitStaticInfo()
end

function UIActEnjoyMonthCardPop:InitStaticInfo()
	self:SetWndButtonText(self.mGetBtn, ccClientText(10151))
end

function UIActEnjoyMonthCardPop:OnClickGetBtn()
	local itemdata = self._cardPageData[self._page]
	local state = itemdata.dataState
	if state == 1 then
		local sid = self._sid
		local pageId = itemdata.dataPageId
		local entryId = itemdata.dataEntryId
		gModelActivity:OnActivityReceiveGoalReq(sid,pageId,entryId)
	else
		GF.ShowMessage(ccClientText(12208))
	end

end

function UIActEnjoyMonthCardPop:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end

	self:ResetActivePageData(pb)
	self:RefreshUI()
end

function UIActEnjoyMonthCardPop:RefreshRewardList(listTransIndex, itemDataList)
	local itemList = itemDataList
	local listNum = #itemList
	local isMax   = listNum > 4
	local rewardList = self["mRewardList"..listTransIndex]
	local rewardListMax = self["mRewardListMax"..listTransIndex]

	CS.ShowObject(rewardList, not isMax)
	CS.ShowObject(rewardListMax, isMax)

	local targetRewardList = isMax and rewardListMax or rewardList
	local uiList
	local rewardListCls = isMax and self["_rewardListClsMax"..listTransIndex] or self["_rewardListCls"..listTransIndex]
	uiList = rewardListCls
	if not uiList then
		uiList = UIIconEasyList:New(self)
		if isMax then
			self["_rewardListClsMax"..listTransIndex] = uiList
		else
			self["_rewardListCls"..listTransIndex] = uiList
		end
		uiList:Create(self,targetRewardList)
		uiList:SetIconParentPath("itemRoot/CommonUI/Icon")
	end
	uiList:SetItemEff("fx_daoju_orange",75)
	--uiList:SetItemEff(nil,100)
	uiList:EnableScroll(isMax, true)
	uiList:RefreshList(itemList)
end

--#####################################################################################################################
--## Content ##########################################################################################################
--#####################################################################################################################
function UIActEnjoyMonthCardPop:SetTop()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

	local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityCfg then return end

	local config = activityCfg.config
	self._config = config

	local moreInfo = JSON.decode(activityData.moreInfo)
	local overTime_1 = moreInfo.overTime_1
	if overTime_1 and overTime_1 > 0 then
		self._overTime1 = overTime_1/1000
	end

	local overTime_2 = moreInfo.overTime_2
	if overTime_2 and overTime_2 > 0 then
		self._overTime2 = overTime_2/1000
	end

	self._popupImages = {
		config.popupImage1 or "activity_mooncard_role_1",
		config.popupImage2 or "activity_mooncard_role_2",
	}

	local firstTimeType = config.fristTimeType or 0
	local fristTimeLimit = config.fristTimeLimit
	local fristTimeLimitValue = fristTimeLimit * 3600
	local startTime
	if firstTimeType == 0 then
		--创角时间
		startTime = gModelPlayer:GetRegTime()
	else
		--活动开启时间
		startTime = activityData.startTime
	end
	self._fristTimeLimitEndTime = startTime + fristTimeLimitValue

	self._desc1 = config.desc1
	self._desc5 = config.desc5

	local desc = config.desc3
	if not string.isempty(desc) then
		self:SetWndText(self.mText1, desc)
		CS.ShowObject(self.mText1, true)
	end

	desc = config.desc6
	if not string.isempty(desc) then
		self:SetWndText(self.mText2, desc)
		CS.ShowObject(self.mText2, true)
	end

	self:RefreshCountDown()
	self:TimerStart(self._countDownKey, 1, false, -1)

	self._fristTimeReward = {
		LxDataHelper.ParseItem_3List(config.fristTimeReward1),
		LxDataHelper.ParseItem_3List(config.fristTimeReward2),
	}

	self._rewardId = config.Rewardid
end

function UIActEnjoyMonthCardPop:RefreshUI()
	self:RefreshTab()
	self:RefreshContent()
	self:RefreshCountDown()
end

--#####################################################################################################################
--## TabList ##########################################################################################################
--#####################################################################################################################
function UIActEnjoyMonthCardPop:RefreshTab()
	local data = self._cardPageData
	if not data then return end

	local uiList =  self._uiTabList
	if not uiList then
		uiList =  self:GetUIScroll("_uiTabList")
		self._uiTabList = uiList
		uiList:Create(self.mTabList,data,function (...) self:TabListItem(...) end, UIItemList.NORMAL)
		uiList:EnableScroll(false)
	else
		uiList:RefreshList(data)
	end
end

function UIActEnjoyMonthCardPop:OnDrawInfoItem(list,item,itemdata,itempos)
	local textTrans = self:FindWndTrans(item, "Text")
	local goBtn = self:FindWndTrans(item, "GoBtn")

	local description = itemdata.description
	self:SetWndText(textTrans, description)

	local jump = itemdata.jumpId
	self:SetWndClick(goBtn, function()
		if gModelFunctionOpen:CheckIsOpened(jump, true) then
			gModelFunctionOpen:Jump(jump)
		end
	end)
end

function UIActEnjoyMonthCardPop:RefreshReward()
	local page = self._page

	local fristTimeReward = self._fristTimeReward[page]
	if fristTimeReward then
		self:RefreshRewardList(1, fristTimeReward)
	end

	local cardPageData = self._cardPageData[self._page]
	if cardPageData then
		local reward = cardPageData.reward
		if reward then
			self:RefreshRewardList(2, reward)
		end
	end
end

function UIActEnjoyMonthCardPop:RefreshContent()
	if not self._cardPageData then return end

	local cardPageData = self._cardPageData[self._page]
	if not cardPageData then return end

	self:RefreshHeroImg()
	self:RefreshBuyBtnState()
	self:RefreshInfoList()
	self:RefreshReward()
end

function UIActEnjoyMonthCardPop:RefreshBuyBtnState()
	local cardPageData = self._cardPageData[self._page]
	if not cardPageData then return end
	local state = cardPageData.dataState
	local isShowBuyBtn = state == 0
	CS.ShowObject(self.mBuyBtn, isShowBuyBtn)
	CS.ShowObject(self.mGetBtn, state == 1)
	CS.ShowObject(self.mGetEnd, state == 2)

	if isShowBuyBtn then
		local expend2 = cardPageData.expend2
		local expendId = tonumber(expend2)
		local setTextStr = gModelPay:GetShowByWelfareId(expendId)
		self:SetWndButtonText(self.mBuyBtn, setTextStr)
	end
end



function UIActEnjoyMonthCardPop:RefreshCountDown()
	local now = GetTimestamp()
	local dayEnd = self._fristTimeLimitEndTime
	local timeDif = os.difftime(dayEnd,now)
	if timeDif < 0 then
		self:WndClose()
		return
	end

	if not self._cardPageData then return end

	local timeStr = LUtil.FormatTimespanToMin(timeDif)

	local pageIndex = self._page
	local activityPageData = self._cardPageData[pageIndex]
	local overTime = self["_overTime"..pageIndex]
	if overTime and overTime > 0 then
		timeDif = os.difftime(overTime,now)
		timeStr = LUtil.FormatTimespanToMin(timeDif)
	end

	local buyState = activityPageData.dataState
	local str
	if buyState == 0 then
		str = self._desc1
	else
		str = self._desc5
	end
	str = string.replace(str,timeStr)
	self:SetWndText(self.mTitleTimeText,str)
end

function UIActEnjoyMonthCardPop:InitData()
	local sid = self:GetWndArg("sid")
	self._page = self:GetWndArg("page") or 1--支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end

	self._sid = sid

	self._countDownKey = "_countDownKey"

	gModelActivity:ReqActivityConfigData(self._sid)
end


function UIActEnjoyMonthCardPop:RefreshHeroImg()
	if not self._popupImages then return end
	local page = self._page
	local path = self._popupImages[page]
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mHeroImg, path, function()
			CS.ShowObject(self.mHeroImg, true)
		end,true)
	end
end


--#####################################################################################################################
--## Timer ############################################################################################################
--#####################################################################################################################
function UIActEnjoyMonthCardPop:OnTimer(key)
	if key == self._countDownKey then
		self:RefreshCountDown()
	end
end

function UIActEnjoyMonthCardPop:OnActivityListResp(pb)
	local activities = pb.activities
	for i, v in ipairs(activities) do
		local sid = v.sid
		if self._sid == sid then
			self:SetTop()
			self:RefreshUI()
			break
		end
	end
end

--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIActEnjoyMonthCardPop:ResetActivePageData(pb)
	if not self._cardPageData then
		self._cardPageData = {}
	end

	local needSort = false
	for k, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		if page then
			local pageId = v.pageId
			if pageId == ModelActivity.MODEL_ACTIVITY_ENJOY_MONTH_CARD then
				for i,u in ipairs(page.entry) do
					local cardPageId = u.pageId
					local cardEntryId = u.entryId
					local entryData = gModelActivity:GetWebActivityEntryData(self._sid,cardPageId,cardEntryId)
					if entryData then
						local id = entryData.id
						local data = self._cardPageData[id]
						if not data then
							data = {}
							self._cardPageData[id] = data
						end

						data.id = id
						data.pageId = cardPageId
						data.entryId = cardEntryId
						data.sort = entryData.sort
						data.name = entryData.name
						data.expend2 = entryData.expend2
						data.state = u.goalData.status  --(0-不可领取, 1-可领取，2-已领取)

						needSort = true
					end
				end
			elseif pageId == ModelActivity.MODEL_ACTIVITY_ENJOY_MONTH_CARD_WELFARE then
				local welfareData = {}
				for i,u in ipairs(page.entry) do
					local entryData = gModelActivity:GetWebActivityEntryData(self._sid,u.pageId,u.entryId)
					if entryData then
						local moreInfo = entryData.moreInfo
						local cardIndexList = string.split(moreInfo, '|')
						local data = {
							description 	= entryData.description,
							jumpId 			= entryData.jumpId,
							sort			= entryData.sort,
						}
						for p,q in ipairs(cardIndexList) do
							local cardId = tonumber(q)
							if not welfareData[cardId] then
								welfareData[cardId] = {}
							end

							table.insert(welfareData[cardId], data)
						end
					end
				end

				local extraRewardId = self._rewardId
				if extraRewardId then
					local data = {
						description 	= ccClientText(36004),
						jumpId			= 15000000,
						sort			= 999,
					}
					table.insert(welfareData[extraRewardId], data)
				end

				for i,u in ipairs(welfareData) do
					table.sort(welfareData[i], function(a,b)
						return a.sort < b.sort
					end)
				end

				self._welfareData = welfareData
			elseif pageId == ModelActivity.MODEL_ACTIVITY_ENJOY_MONTH_CARD_DATA then
				for i,u in ipairs(page.entry) do
					local dataPageId = u.pageId
					local dataEntryId = u.entryId
					local entryData = gModelActivity:GetWebActivityEntryData(self._sid,dataPageId, dataEntryId)
					if entryData then
						local id = entryData.id
						local data = self._cardPageData[id]
						if not data then
							data = {}
							self._cardPageData[id] = data
						end

						local moreInfoList = string.split(entryData.moreInfo, '=')

						data.reward = LxDataHelper.ParseItem_3List(entryData.reward)
						data.day = tonumber(moreInfoList[1])
						data.dataPageId = dataPageId
						data.dataEntryId = dataEntryId
						data.dataState = u.goalData.status  --(0-不可领取, 1-可领取，2-已领取)
					end
				end
			end
		end
	end

	if needSort then
		table.sort(self._cardPageData, function(a,b)
			return a.sort < b.sort
		end)
	end
end


function UIActEnjoyMonthCardPop:OnActivityResp(pb)
	if self._sid ~= pb.sid then return end

	self:RefreshUI()
end

function UIActEnjoyMonthCardPop:OnClickBuyBtn()
	local itemdata = self._cardPageData[self._page]
	local entryId = itemdata.entryId
	local expend2 = itemdata.expend2
	local pageId = itemdata.pageId
	gModelPay:GiftPayCtrl(entryId,expend2,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,pageId)
end

function UIActEnjoyMonthCardPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (...) self:OnActivityResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb) self:OnActivityListResp(pb) end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function ()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end

function UIActEnjoyMonthCardPop:OnClickTab(itempos)
	if(self._page == itempos)then return end

	self._page = itempos
	self:RefreshUI()
end

function UIActEnjoyMonthCardPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBuyBtn, function(...) self:OnClickBuyBtn() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mGetBtn, function(...) self:OnClickGetBtn() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIActEnjoyMonthCardPop:TabListItem(list, item, itemdata, itempos)
	local tabBtn 	= self:FindWndTrans(item,"TabBtn")
	local redPoint 	= self:FindWndTrans(item,"redPoint")

	self:SetWndTabText(tabBtn, itemdata.name)
	local state = itemdata.dataState
	local showRed = state == 1
	CS.ShowObject(redPoint, showRed)

	local tabStatus = self._page == itempos and self.StateOn or self.StateOff
	self:SetWndTabStatus(tabBtn, tabStatus)

	self:SetWndClick(tabBtn, function(...)
		self:OnClickTab(itempos)
	end)
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIActEnjoyMonthCardPop:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:SetTop()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UIActEnjoyMonthCardPop:RefreshInfoList()
	local data = self._welfareData[self._page]
	if not data then return end

	local isMax = #data > 2
	CS.ShowObject(self.mInfoList, not isMax)
	CS.ShowObject(self.mInfoListMax, isMax)

	if isMax then
		local uiList = self._infoListMax
		if not uiList then
			uiList = self:GetUIScroll("infoListMax")
			self._infoListMax = uiList
			uiList:Create(self.mInfoListMax,data,function (...) self:OnDrawInfoItem(...)  end)
		else
			uiList:EnableScroll(true, false)
			uiList:RefreshList(data)
		end
	else
		local uiList = self._infoList
		if not uiList then
			uiList = self:GetUIScroll("infoList")
			self._infoList = uiList
			uiList:Create(self.mInfoList,data,function (...) self:OnDrawInfoItem(...)  end)
			uiList:EnableScroll(false, false)
		else
			uiList:EnableScroll(false, false)
			uiList:RefreshList(data)
		end
	end
end

------------------------------------------------------------------
return UIActEnjoyMonthCardPop


