---
--- Created by Administrator.
--- DateTime: 2021/1/11 15:04:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFairylandMain:LWnd
local UIFairylandMain = LxWndClass("UIFairylandMain", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")

UIFairylandMain.HAVE_GIFT_NO_SEL = 0
UIFairylandMain.HAVE_CELL_AND_GIFT = 1
UIFairylandMain.HAVE_SEL_NO_GIFT = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFairylandMain:UIFairylandMain()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFairylandMain:OnWndClose()
	self._activeIconList = nil

	if self._func then self._func() end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFairylandMain:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFairylandMain:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	--self:DoWndStartScale(0,self.mTopView)
	self:InitEvent()
	self:InitMsg()
	self:InitPara()
end

function UIFairylandMain:CheckFairylandGiftRed()
	if table.isempty(self._activityPageData) then
		return false
	end


	local pageData
	local isShow = self._callGiftOptional ~= self.HAVE_GIFT_NO_SEL
	if isShow then
		pageData = self._activityPageData[ModelActivity.FAIRYLAND_GIFT_CUSTOM]
		if pageData then
			for k,v in ipairs(pageData.entry) do
				local marketData = v.MarketData
				if marketData.expendType == 0 then --免费
					local personal 		= marketData.personal; -- 已使用个人限购次数
					local personalGoal	= marketData.personalGoal; -- 个人可购买次数
					local haveCount		= personalGoal - personal
					if haveCount > 0 then
						return true
					end
				end
			end
		end
	end

	isShow = self._callGiftOptional ~= self.HAVE_SEL_NO_GIFT
	if isShow then
		pageData = self._activityPageData[ModelActivity.FAIRYLAND_GIFT]
		if pageData then
			local expend2List
			local expendId
			local haveCount
			for k,v in ipairs(pageData.entry) do
				local marketData = v.MarketData
				expend2List = string.split(marketData.expend2 or "" , "=")
				if #expend2List <= 1 then
					expendId = tonumber(expend2List[1])
					if expendId <= 0 then
						local personal = tonumber(marketData.personal)  -- 已使用个人限购次数
						local personalGoal = tonumber(marketData.personalGoal)  -- 个人可购买次数
						haveCount = personalGoal - personal
						if haveCount > 0 then
							return true
						end
					end
				end
			end
		end
	end

	return false
end


--#####################################################################################################################
--## Top ##############################################################################################################
--#####################################################################################################################
function UIFairylandMain:SetTop()
	local data	   = self._cfgDataMoreInfo
	self:SetWndEasyImage(self.mView,data.image)
	self:SetWndEasyImage(self.mTitleImg,data.titleIcon,nil,true)
	self:SetAnchorPos(self.mView, LxDataHelper.ParseVector2NotEmpty(data.imagePos))
	self:SetAnchorPos(self.mTitleImg, LxDataHelper.ParseVector2NotEmpty(data.titleIconPos))
	self:SetAnchorPos(self.mTimeBgImg, LxDataHelper.ParseVector2NotEmpty(data.timePos))

	local discountEntryDes = data.discountEntryDes
	local popDesc = string.gsub(discountEntryDes,"\\n","\n")
	self:SetWndText(self.mDescPopText, popDesc)

	self:RefreshShowTime()
	self:InitHeroPb()

    local effects = data.effects
    if not string.isempty(effects) then
        self:CreateWndEffect(self.mEffectRoot,effects,effects,100,false,false)
    end
end


--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIFairylandMain:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end
	self:ResetActivePageData(pb)
	self:RefreshActiveList()
end

function UIFairylandMain:OnActiveIconCell(iconIndex)
	local itemdata = self._activeDataList[iconIndex]
	local item	   = self._activeIconList[iconIndex]

	if not (item and itemdata) then return end

	--local nameTrans = CS.FindTrans(item, "Name")
	local iconTrans = self:FindWndTrans(item, "Icon")
	local nameImgTrans = CS.FindTrans(item, "NameImg")
	local redPoint =  CS.FindTrans(nameImgTrans, "redPoint")
	local data		= itemdata
	local jumpFunc  = itemdata.jumpFunc
	local jumpNoClose = itemdata.jumpNoClose
	local redCheckFunc = itemdata.redCheckFunc
	local iconPath  = data.icon

	if LxUiHelper.IsImgPathValid(iconPath) then
		self:SetWndEasyImage(item,iconPath,nil,true)
		self:SetWndEasyImage(iconTrans,iconPath,nil,true)
		CS.ShowObject(iconTrans, true)
	end

	self:SetWndEasyImage(nameImgTrans,data.name,nil,true)
	self:SetAnchorPos(item, LxDataHelper.ParseVector2NotEmpty(data.iconPos))
	CS.ShowObject(item, true)
	--self:SetWndText(nameTrans,data.name)

	self:SetWndClick(item,function()
		if not jumpNoClose then
			self:WndClose()
		end

		if jumpFunc then
			jumpFunc()
		end
	end)

	local showRedPoint = false
	if redCheckFunc then
		showRedPoint = redCheckFunc()
	end
	CS.ShowObject(redPoint, showRedPoint or false)
end

function UIFairylandMain:InitPara()
	self._func = self:GetWndArg("func")
	self._sid = self:GetWndArg("sid")
	local page = self:GetWndArg("page")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	self._page = page or 1
	self._subPage = 1

	self._showTimeKey = "_showTimeKey"
	self._ewUIHeroObj = nil
	self._activePath  = "Active"

	gModelActivity:ReqActivityConfigData(self._sid)
end

--#####################################################################################################################
--## Hero #############################################################################################################
--#####################################################################################################################
function UIFairylandMain:InitHeroPb()
	local moreInfo = self._cfgDataMoreInfo
	local pbName = moreInfo.heroLH

	if string.isempty(pbName) then
		return
	end


	if not self._ewUIHeroObj then
		self._ewUIHeroObj = LUIHeroObject:New(self)
		self._ewUIHeroObj:Create(self.mHeroObj,pbName,pbName)
		self._ewUIHeroObj:SetScale(moreInfo.heroLHSize)
		self._ewUIHeroObj:ShowHero(true)
		self._ewUIHeroObj:StartLoad()
		self:SetAnchorPos(self.mHeroObj, LxDataHelper.ParseVector2NotEmpty(moreInfo.heroLHPos))
	else
		self._ewUIHeroObj:ShowHero(true)
	end
end

function UIFairylandMain:RefreshActiveList()
	local uiList = self._activeIconList
	if not uiList then
		self:InitActiveIconList()
		uiList = self._activeIconList
	end

	CS.ShowObject(self.mActiveList, true)
	for k,v in ipairs(uiList) do
		self:OnActiveIconCell(k)
	end
end

function UIFairylandMain:ResetActivePageData(pb)
	self._activityPageData = {}
	for i, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		if page then
			self._activityPageData[v.pageId]=page
		end
	end
end


--#####################################################################################################################
--## RedPoint #########################################################################################################
--#####################################################################################################################
function UIFairylandMain:CheckFairylandTaskRed()
	local taskPageId 		= ModelActivity.FAIRYLAND_TASK
	local taskPageData 	 	= self._activityPageData[taskPageId]

	if taskPageData then
		for k,v in ipairs(taskPageData.entry) do
			local goalData 		= v.goalData
			local status   		= goalData.status
			if status == 1 then	--可领取
				return true
			end
		end
	end

	--是否隐藏累计充值
	local isHideAccumulate = self._cfgDataMoreInfo.accumulateRecharge == 0
	if isHideAccumulate then
		return false
	end

	local accumulatePageId 	= ModelActivity.FAIRYLAND_ACCUMULATE
	local accumulatePageData = self._activityPageData[accumulatePageId]
	if accumulatePageData then
		for k,v in ipairs(accumulatePageData.entry) do
			local goalData = v.goalData
			local status   = goalData.status
			if status == 1 then	--可领取
				return true
			end
		end
	end

	return false
end

function UIFairylandMain:CheckFairylandWatchesFellRed()
	if not self._cfgDataMoreInfo then return false end

	local itemId = self._cfgDataMoreInfo.itemId
	if gModelItem:GetNumByRefId(itemId) < 10 then
		return false
	end

	return not gModelActivity:IsClickActivityRed(self._sid)
end

function UIFairylandMain:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)

	self:SetTextTile(self.mCloseBtn,ccClientText(19233))
end

function UIFairylandMain:ShowTimerFunc()
	local now = GetTimestamp()
	local timeDif = os.difftime(self._endTime,now)
	if timeDif <= 0 then
		self:StopShowTimer()
		return
	end

	local timeStr  = LUtil.FormatTimeToCn3(timeDif)
	timeStr		   = string.replace(ccClientText(18701), timeStr)
	self:SetWndText(self.mTime,timeStr)
end

--#####################################################################################################################
--## time #############################################################################################################
--#####################################################################################################################
function UIFairylandMain:RefreshShowTime()
	local timeValue = self._activityData.endTime or 0
	self._endTime   = timeValue
	local showTime = self._endTime > 0
	CS.ShowObject(self.mTimeBgImg, showTime)
	if not showTime then return end

	local now = GetTimestamp()
	local timeDif = os.difftime(self._endTime,now)
	if timeDif <= 0 then
		return
	end

	self:ShowTimerFunc()
	self:TimerStart(self._showTimeKey,1,false,-1)
end

function UIFairylandMain:OnTimer(key)
	if key == self._showTimeKey then
		self:ShowTimerFunc()
	end
end

function UIFairylandMain:InitData()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	self._activityData 		= gModelActivity:GetActivityBySid(self._sid)
	self._cfgDataMoreInfo 	= webData.config
	local config 			= self._cfgDataMoreInfo
	self._cfgShowTime 		= config.showTime
	local startDay		   	= self._activityData.startTime
	local addTime		   	= GetTimestamp() - startDay
	self._activityOpenDay  	= math.ceil((addTime) / 86400)
	local taskEntryIcon = string.split(config.taskEntryIcon, '=')
	local flopEntryIcon = string.split(config.flopEntryIcon, '=')
	local giftEntryIcon = string.split(config.giftEntryIcon, '=')
	local challengeEntryIcon = string.split(config.challengeEntryIcon, '=')
	local dropEntryIcon = string.split(config.dropEntryIcon, '=')
	local discountEntryIcon = string.split(config.discountEntryIcon, '=')
	local discountJump	= config.discountJump
	self._activeDataList = {
		[1] = { --秘境任务
			name = taskEntryIcon[1],
			icon = taskEntryIcon[2],
			iconPos = config.taskEntryIconPos,
			jumpFunc = function()
				GF.OpenWndBottom("UIFairylandTask",{
					sid = self._sid,
					--data = config,
					--mainData = self._activityData,
				})
			end,
			redCheckFunc = function() return self:CheckFairylandTaskRed() end,
		},
		[2] = { --翻牌
			name = flopEntryIcon[1],
			icon = flopEntryIcon[2],
			iconPos = config.flopEntryIconPos,
			jumpFunc = function()
				GF.OpenWndBottom("UIFlandDraw",{
					sid = self._sid,
					--data = config,
					--mainData = self._activityData,
				})
			end,
			redCheckFunc = function() return self:CheckFairylandDrawRed() end,
		},
		[3] = { --礼包
			name = giftEntryIcon[1],
			icon = giftEntryIcon[2],
			iconPos = config.giftEntryIconPos,
			jumpFunc = function()
				GF.OpenWndBottom("UIFairylandGift",{
					sid = self._sid,
					--data = config,
					--mainData = self._activityData,
				})
			end,
			redCheckFunc = function() return self:CheckFairylandGiftRed() end,
		},
		[4] = { --挑战
			name = challengeEntryIcon[1],
			icon = challengeEntryIcon[2],
			iconPos = config.challengeEntryIconPos,
			jumpFunc = function()
				local isFightType = gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_FAIRYLAND_BOSS)
				if isFightType then
					--优先进入当前的战斗中
					gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_FAIRYLAND_BOSS,{})
					return
				end

				GF.OpenWndBottom("UIFlandBoss",{
					sid = self._sid,
					--data = config,
					--mainData = self._activityData,
				})
			end,
			redCheckFunc = function() return self:CheckFairylandBossRed() end,
		},
		[5] = { --掉落+兑换
			name = dropEntryIcon[1],
			icon = dropEntryIcon[2],
			iconPos = config.dropEntryIconPos,
			jumpFunc = function()
				GF.OpenWnd("UIFairylandWatchesFell",{
					sid = self._sid,
					--data = config,
					--mainData = self._activityData,
				})
			end,
			jumpNoClose = true,
			redCheckFunc = function() return self:CheckFairylandWatchesFellRed() end,
		},
		[6] = { --每日特惠
			name = discountEntryIcon[1],
			icon = discountEntryIcon[2],
			iconPos = config.discountEntryIconPos,
			jumpFunc = function()
				if not gModelFunctionOpen:CheckIsOpened(discountJump,true) then
					return
				end
				gModelFunctionOpen:Jump(discountJump,self:GetWndName())
			end,
			redCheckFunc = function() return false end,
		},
	}

	self._callGiftOptional = config.callGiftOptional or config.giftOptional
end

function UIFairylandMain:CheckFairylandBossRed()
	--检测是否有当日未挑战的boss
	local bossPageId 		= ModelActivity.FAIRYLAND_BOSS
	local bossPageData 	 	= self._activityPageData[bossPageId]
	if bossPageData then
		for k,v in ipairs(bossPageData.entry) do
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
			if not entryCfg then
				return
			end

			local cfgMoreInfoData = string.split(entryCfg.moreInfo, '=')
			local openTimes = string.split(cfgMoreInfoData[1], ',')
			local starDay   = tonumber(openTimes[1])
			local endDay    = tonumber(openTimes[2])
			local isOpen	= self._activityOpenDay >= starDay and self._activityOpenDay <= endDay
			if isOpen then
				local moreInfo = JSON.decode(v.moreInfo)
				local challengeBossTime = tonumber(moreInfo.challengeBossTime)
				if challengeBossTime == 0 then
					--有未挑战
					return true
				end
			end
		end
	end

	--检测是否有可领取的任务奖励
	local bossTaskPageId = ModelActivity.FAIRYLAND_BOSS_TASK --仙境迷踪_BOSS挑战任务
	local bossTaskPageData 	= self._activityPageData[bossTaskPageId]
	if bossTaskPageData then
		for k,v in ipairs(bossTaskPageData.entry) do
			local status  = v.goalData.status
			if status == 1 then
				--有奖励可领取
				return true
			end
		end
	end

	return false
end

function UIFairylandMain:InitActiveIconList()
	self._activeIconList = {}
	local path
	for k,v in ipairs(self._activeDataList) do
		path = self._activePath..k
		local trans = CS.FindTrans(self.mActiveList, path)
		table.insert(self._activeIconList, trans)
	end
end

function UIFairylandMain:StopShowTimer()
	self:TimerStop(self._showTimeKey)
	self:WndClose()
end

function UIFairylandMain:InitMsg()

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb) self:OnActivityPageResp(pb) end)
end

function UIFairylandMain:CheckFairylandDrawRed()
	if not self._cfgDataMoreInfo then
		return false
	end

	local flopNeedItem 	= self._cfgDataMoreInfo.flopNeedItem
	local consumeData  	= string.split(flopNeedItem, '=')
	local refId 		= tonumber(consumeData[2])
	local itemNum 		= tonumber(consumeData[3])
	local haveNum 		= gModelItem:GetNumByRefId(refId)
	return haveNum >= itemNum
end

function UIFairylandMain:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitData()
	self:SetTop()
	gModelActivity:OnActivityPageReq(self._sid)
end




------------------------------------------------------------------
return UIFairylandMain


