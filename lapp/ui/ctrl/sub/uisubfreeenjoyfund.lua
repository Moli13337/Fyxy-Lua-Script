---
--- Created by Administrator.
--- DateTime: 2023/10/16 17:08:20
---
---活动39 超值基金
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubFreeEnjoyFund:LChildWnd
local UISubFreeEnjoyFund = LxWndClass("UISubFreeEnjoyFund", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubFreeEnjoyFund:UISubFreeEnjoyFund()
	---@type table<number,CommonIcon>
	self._uiIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubFreeEnjoyFund:OnWndClose()
	if self._uiIconList then
		local list = self._uiIconList
		for k,v in pairs(self._uiIconList) do
			v:Destroy()
			list[k] = nil
		end
		self._uiIconList = nil
	end
	if self._uiList then
		self._uiList:OnWndClose()
	end

	self._curClickPos = nil

	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubFreeEnjoyFund:OnCreate()
	LChildWnd.OnCreate(self)

	self._tips2Format = "#a1##a2#"
	self._endTimeKey = "endTimeKey"
	self._constBuyStr = "buy_"
	self._constBuyNumStr = "buy_num_"
	self._constPayDay = "buy_day_"
	self._effList = {}

	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubFreeEnjoyFund:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	self._isEnus = gLGameLanguage:IsEnglishVersion()
	self.jpj = gLGameLanguage:IsJapanVersion()
	if self._isEnus or self._isVie then 
		self:InitTextSizeWithLanguage(self.mTimeText,-2)
	end
	if self.jpj then
		self:InitTextSizeWithLanguage(self.mTimeText,-4)
	end
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	
	self:RefreshForeign()
end

function UISubFreeEnjoyFund:InitData()
	self._sid = self:GetWndArg("sid")
	self._curClickPos = nil
	self._pageData = {}
	self._buyDataList = {}

	gModelActivity:ReqActivityConfigData(self._sid)
end
--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UISubFreeEnjoyFund:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:SetTop()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UISubFreeEnjoyFund:OnActivityListResp(pb)
	local activities = pb.activities
	for i, v in ipairs(activities) do
		local sid = v.sid
		if sid == self._sid then
			self:SetTop()
			self:InitPayBtn()
			return
		end
	end
end

function UISubFreeEnjoyFund:InitEvent()
	self:SetWndClick(self.mHelpBtn, function()
		local str = self._helpTipsContent
		local title = self._helpTipsTitle
		GF.OpenWnd("UIBzTips", {title = title, text = str})
	end)

	self:SetWndClick(self.mPayBtn, function()
		self:OnClickBuy()
	end)

    self:SetWndClick(self.mBuyTipsBtn, function(...) self:OnClickByTips() end)
end

function UISubFreeEnjoyFund:OnActivityPageResp(pb, ret)
	local sid = pb.sid
	if self._sid ~= sid then
		return
	end

	for k,v in ipairs(pb.pages) do
		local pageId = v.pageId
		self._pageData[pageId] = gModelActivity:GenerateActivePageDataFromPb(v)
	end

	self:InitParam()
	self:RefreshUI()
end

function UISubFreeEnjoyFund:OnDrawItemCell(list, item, itemdata, itempos, fromHeadTail)
	if self:IsWndClosed() then return end
	local aniRootTrans = self:FindWndTrans(item,"AniRoot")
	if not aniRootTrans then return end
	local instanceId = item:GetInstanceID()
	local bg   		= self:FindWndTrans(aniRootTrans, "Bg")
	local coverBg   = self:FindWndTrans(aniRootTrans, "CoverBg")
	local mask 		= self:FindWndTrans(aniRootTrans,"Mask")
	local dayText 	= self:FindWndTrans(aniRootTrans,"DayText")
	local maskImg 	= self:FindWndTrans(aniRootTrans,"GetImg")
	local eff 		= self:FindWndTrans(aniRootTrans,"Eff")
	local commonUI 	= self:FindWndTrans(aniRootTrans,"CommonUI")
	local DayBg 	= self:FindWndTrans(aniRootTrans,"DayBg")

	local index = itemdata.entryId
	local pageId = itemdata.pageId
	local title = string.replace(ccClientText(21400), index)
	local rewardList = itemdata.rewards
	local reward = rewardList[1]
	local itemId = reward.itemId
	local status = tonumber(itemdata.status)

	local baseClass = self._uiIconList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiIconList[instanceId] = baseClass
		baseClass:Create(self:FindWndTrans(commonUI, "Icon"))
	end

	baseClass:SetCommonReward(reward.itemType,itemId,reward.itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	local dayStr = title
	local isShowCover = false
	local isShowMask  = status == 2
	local isActiveDay = index <= self._openDay and not isShowMask

	local effKey = eff:GetInstanceID()
	if(isActiveDay)then --已激活
		if(status == 1 and not self:FindWndEffectByKey(effKey))then--可领取时显示特效
			isShowCover = true
			local effectName = self._iconEffectName
			self:CreateWndEffect(eff,effectName,effKey,100, false, false)
		end
	end

	if isShowMask and self:FindWndEffectByKey(effKey) then
		self:DestroyWndEffectByKey(effKey)
	end

	CS.ShowObject(eff,isShowCover)
	CS.ShowObject(bg,not isShowCover)
	CS.ShowObject(coverBg,isShowCover)
	CS.ShowObject(maskImg,isShowMask)
	CS.ShowObject(mask,isShowMask)

	CS.ShowObject(bg,isActiveDay)
	CS.ShowObject(coverBg,isActiveDay)
	CS.ShowObject(DayBg,not isActiveDay)

	self:SetWndText(dayText,dayStr)
	local clickFunc = function()
		if(status == 1)then --可领取
			self:OnClickGet(itempos)
		else
			gModelGeneral:ShowCommonItemTipWnd(reward)
		end
	end
	self:SetWndClick(aniRootTrans,  clickFunc)
	self:SetIconClickScale(commonUI, true)
	self:SetWndClick(commonUI,  clickFunc)
end

function UISubFreeEnjoyFund:InitPayBtn()

	local buyData = self._buyDataList and self._buyDataList[1]

	self:SetWndText(self.mTopText,tostring(math.floor(buyData.flbNum / 100) or ""))

	local isBuy = self._isBuy
	CS.ShowObject(self.mPayBtn,not isBuy)
	CS.ShowObject(self.mMaskImg, isBuy)
	CS.ShowObject(self.mUpRedImg,not isBuy)
	if isBuy then return end
	if not buyData then return end


	local flbNum  = buyData.flbNum
	--local money = gModelPay:GetRMBValueByWelfareId(buyData.marketData.expend2)
	local moneyStr =gModelPay:GetShowByWelfareId(buyData.marketData.expend2) -- string.replace(ccClientText(11906),money)
	self._moneyStr = moneyStr
	self:SetWndButtonText(self.mPayBtn, moneyStr)
	local flbStr = string.replace(ccClientText(21401),flbNum)
	self:SetWndText(self.mUpRedTxt,flbStr)

	local expend2Info =  string.split(buyData.marketData.expend2,"=")
	if(expend2Info and expend2Info[2])then
		local iconPath = gModelItem:GetItemIconByRefId(tonumber(expend2Info[2]))
		local iconTrans = self:FindWndTrans(self.mPayBtn,"PayText/Image")
		self:SetWndEasyImage(iconTrans,iconPath)
	end
end

function UISubFreeEnjoyFund:InitTipTxt()
	local data = self._webCfg
	local str = data.tipsTxt
	CS.ShowObject(self.mTipsTxt, str ~= nil)
	if not str then return end

	local rewards = self._buyDataList[1].rewards
	local reward  = rewards[1]
	local itemId  = reward.itemId
	local itemNum = reward.itemNum
	local iconPath = gModelItem:GetItemImgByRefId(itemId)
	local strList = string.split(str, "#a1#")
	self:SetWndText(self.mTipsTxt1, strList[1])
	self:InitTextLineWithLanguage(self.mTipsTxt1, -30)
	self:SetWndText(self.mTipsTxt2, string.replace(self._tips2Format, itemNum, strList[2]))
	self:InitTextLineWithLanguage(self.mTipsTxt2, -30)
	self:SetWndEasyImage(self.mItemIcon, iconPath)
end

function UISubFreeEnjoyFund:RefreshScrollView()
	local list = self._activityEntryList
	if(self._uiList)then
		self._uiList:RefreshList(list)
	else
		self._uiList = self:GetUIScroll("uiList")
		self._uiList:Create(self.mItemList,list,function (...) self:OnDrawItemCell(...) end, UIItemList.SUPER_GRID)
	end

	local canGetIndex = self:GetActivityListCanGetIndex() or 1
	local _index = canGetIndex > 0 and canGetIndex or 1

	if not self._isBuy then
		_index = 1
	end
	self._uiList:DrawAllItems()
	self._uiList:MoveToPos(_index)
	self._curClickPos = nil
end

function UISubFreeEnjoyFund:SetEndTimer()
	local time = GetTimestamp()
	local timespan = self._endTimes - time
	if(timespan <= 0)then
		self:TimerStop(self._endTimeKey)
		CS.ShowObject(self.mTime, false)
		return
	end

	local timerStr = LUtil.FormatTimeToCn3(timespan)
	timerStr = string.replace(ccClientText(21405), timerStr)
	self:SetWndText(self.mTimeText, timerStr)
end

function UISubFreeEnjoyFund:InitParam()
	-- 商品条目
	local pageData = self._pageData[ModelActivity.FREE_ENJOY_BUY]
	for k, v in ipairs(pageData.entry) do
		local pageId = v.pageId
		local entryId = v.entryId
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,pageId,entryId)
		if not entryCfg then
			return
		end

		local data = {
			pageId = pageId,
			entryId = entryId,
			title   = entryCfg.name,
			desc	= entryCfg.description,
			rewards	= LxDataHelper.ParseItem(entryCfg.reward),
			sort	= entryCfg.sort,
			--expend2 = entryCfg.expend2,
		}

		local marketData = v.MarketData
		data.marketData = {
			personalGoal = marketData.personalGoal,
			serverGoal = marketData.serverGoal,
			expend1 = marketData.expend1,
			expend2 = tonumber(marketData.expend2),
		}
		--------------------------------------------------
		local str = string.split(entryCfg.moreInfo, "=")
		local fundType = tonumber(str[1])               -- 基金类型
		data.fundType = fundType
		data.level = tonumber(str[2])                   -- 折扣档次
		data.dis = tonumber(str[3])                     -- 折扣力度
		data.nameImg = str[4]                           -- 名称
		data.nameBgImg = str[5]                         -- 名称底
		data.zongJZNum = tonumber(str[6])               -- 总价值
		data.gmldNum = tonumber(str[7])                 -- 购买立即获得钻石
		data.flbNum = tonumber(str[8])                  -- 返利比
		data.other = {}
		self._buyDataList[fundType] = data
	end

	-- 活动条目
	local pageData2 = self._pageData[ModelActivity.FREE_ENJOY_REWARD]
	local entrys = pageData2.entry or {}
	self._activityEntryList = {}
	for k,v in ipairs(entrys) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		if entryCfg then
			local data = {
				pageId  = v.pageId,
				entryId = v.entryId,
				--title   = entryCfg.name,
				--desc	= entryCfg.description,
				--icon	= entryCfg.icon,
				rewards	= LxDataHelper.ParseItem(entryCfg.reward),
				sort	= entryCfg.sort,
				status  = v.goalData.status,
				--moreInfo = JSON.decode(v.moreInfo)
			}
			table.insert(self._activityEntryList, data)
		end
	end

	table.sort(self._activityEntryList,function (a,b)
		return a.entryId < b.entryId
	end)
end

function UISubFreeEnjoyFund:OnClickByTips()
    if not self._helpTipsContent2 then return end

    local title = gModelActivity:GetLngNameByActivitySid(self._sid)
    GF.OpenWnd("UIBzTips",{title= title,text = self._helpTipsContent2})
end

function UISubFreeEnjoyFund:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...) self:OnActivityPageResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)self:OnActivityListResp(pb)  end)
end

function UISubFreeEnjoyFund:RefreshUI()
	self:InitTipTxt()
	self:RefreshCenter()
end

--#####################################################################################################################
--## Center ###########################################################################################################
--#####################################################################################################################
function UISubFreeEnjoyFund:RefreshCenter()
	self:InitPayBtn()
	self:RefreshScrollView()
end

function UISubFreeEnjoyFund:GetActivityListCanGetIndex()
	if not self._activityEntryList then
		return self._curClickPos
	end

	local maxDay = #self._activityEntryList
	for k,v in ipairs(self._activityEntryList) do
		local status = v.status
		if status == 1 or k == self._openDay or k == maxDay then
			return k
		end
	end

	return self._curClickPos
end

function UISubFreeEnjoyFund:OnClickGet(itempos)
	self._curClickPos = itempos
	if not self._isBuy then return end
	if not self._activityEntryList then return end

	local list = {}
	for k,v in ipairs(self._activityEntryList) do
		if v.status == 1 then
			local data = { sid = self._sid,pageId = v.pageId,entryId = v.entryId}
			table.insert(list, data)
		end
	end

	gModelActivity:OnActivityReceiveGoalListReq(list)
end

function UISubFreeEnjoyFund:OnTimer(key)
	if key == self._endTimeKey then
		self:SetEndTimer()
	end
end

--#####################################################################################################################
--## Top ##############################################################################################################
--#####################################################################################################################
function UISubFreeEnjoyFund:SetTop()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

	local moreInfo = activityData.moreInfo
	local activityMoreInfo = JSON.decode(moreInfo)

	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end

	local data = webData.config
	self._webCfg = data

	--顶部背景图
	local path = data.image
	if LxUiHelper.IsImgPathValid(path) then
		--self:SetWndEasyImage(self.mUPImage, path, nil, true)
		self:SetWndEasyImage(self.mUPImage, path, nil, false)
	end

	--顶部标题描述
	path = data.descIcon
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTopTextImage, path, nil, true)
		CS.ShowObject(self.mTopTextImage, true)
	end

	--帮助按钮
	local isShow = data.helpTips == 1
	CS.ShowObject(self.mHelpBtn, isShow)
	if isShow then
		self._helpTipsTitle   = gModelActivity:GetLngNameByActivitySid(self._sid)
		self._helpTipsContent = data.helpTipsContent
	end

    --local text = ccClientText(156)
    --if not string.isempty(text) then
    --    self._helpTipsContent2 = text
    --    self:SetWndText(self.mBuyTipsText, text)
    --    CS.ShowObject(self.mBuyTipsText, true)
        --CS.ShowObject(self.mBuyTipsBtn, true)
    --end

    --时间
	isShow = data.endTime > 0 and data.openDay
	CS.ShowObject(self.mTime, isShow)
	if isShow then
		-- local endTime = tonumber(activityMoreInfo.endTime or 0)
		self._endTimes = activityData.endTime --endTime/1000
		self:TimerStart(self._endTimeKey, 1, false, -1)
		self:SetEndTimer()
	end

	--激活特效
	self._iconEffectName = data.iconEffect or data.itemIconEffect

	--礼包购买的后端数据
	local setTypeList = {}
	local typeList = activityMoreInfo.type
	for i, v in ipairs(typeList) do
		table.insert(setTypeList, v)
	end

	self._buyList = {}
	self._buyNumList = {}
	self._payDay = {}
	for k, v in ipairs(setTypeList) do
		local tempStr1 = self._constBuyStr .. v
		local tempStr2 = self._constBuyNumStr .. v
		local tempStr3 = self._constPayDay .. v
		local buy, buyNum = activityMoreInfo[tempStr1], activityMoreInfo[tempStr2]
		local day = activityMoreInfo[tempStr3]
		self._buyList[v] = buy
		self._buyNumList[v] = buyNum
		self._payDay[v] = day
	end

	local buy   = self._buyList[1]
	self._isBuy = buy ~= 0
	self._openDay = tonumber(activityMoreInfo.openDay or 0)
end

function UISubFreeEnjoyFund:RefreshForeign()
	if self._isVie then
		self:SetAnchorPos(self.mTopTextImage,Vector2.New(280,-69))
		self:SetAnchorPos(self.mTopText,Vector2.New(-65,-5))
	end
end

function UISubFreeEnjoyFund:OnClickBuy()
	if self._isBuy then return end
	if not self._activityEntryList then return end

	local buyRewards = self._buyDataList[1].rewards
	local rewards = {}
	for k,v in ipairs(self._activityEntryList) do
		local index = v.entryId
		local rewardList = v.rewards
		if index <= self._openDay then --已激活的奖励
			if not rewards[1] then
				rewards[1] = {}
				table.insert(rewards[1], buyRewards)	--添加即得奖励
			end

			table.insert(rewards[1], rewardList)
		else							--可后续领取的奖励
			if not rewards[2] then
				rewards[2] = {}
			end
			table.insert(rewards[2], rewardList)
		end
	end

	local moneyStr = self._moneyStr
	local entry = self._buyDataList[1]
	local buyIcon = self._webCfg.buyIcon
	local titleName = self._webCfg.name

	GF.OpenWnd("UIPkBuyPopBig",
			{sid = self._sid,entry = entry, rewards = rewards,buyBtnStr = moneyStr,
			 modelActivityType = ModelActivity.FREE_ENJOY_FUND, heroImgPath = buyIcon, titleName = titleName})
end



------------------------------------------------------------------
return UISubFreeEnjoyFund


