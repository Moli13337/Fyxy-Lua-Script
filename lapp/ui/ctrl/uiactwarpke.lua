---
--- Created by LCM.
--- DateTime: 2024/3/20 9:52:04
---
------------------------------------------------------------------
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
local LWnd = LWnd
---@class UIActWarPkE:LWnd
local UIActWarPkE = LxWndClass("UIActWarPkE", LWnd)


local typeof = typeof
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)

UIActWarPkE.TYPE_LEFT = 1			--- 左边
UIActWarPkE.TYPE_RIGHT = 2			--- 右边

UIActWarPkE.STATUS_4 = 4			--- 仅显示遮罩


UIActWarPkE.ACT_PAGE_1 = 1			-- 档位购买
UIActWarPkE.ACT_PAGE_2 = 2			-- 精英版
UIActWarPkE.ACT_PAGE_3 = 3			-- 进阶版

UIActWarPkE.GET_REWARD_EFFNAME = "fx_ui_qiandao_lingqutishi"			-- 可领取特效

UIActWarPkE.SHOWTYPE_ONLYTXT = 0		--- DiscountTxt
UIActWarPkE.SHOWTYPE_IMGTXT = 1			--- DiscountImgShowDiv

UIActWarPkE.SHOWTYPE_DEFAULT = UIActWarPkE.SHOWTYPE_IMGTXT	--- 默认显示

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActWarPkE:UIActWarPkE()
	self._timeKey = "_timeKey"
	self._showType = UIActWarPkE.SHOWTYPE_DEFAULT
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActWarPkE:OnWndClose()
	local buyData,btnName = self:GetBuyData()
	LWnd.OnWndClose(self)
	if self.jumpCallback then self.jumpCallback(self.clickBuy and buyData == nil) end
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActWarPkE:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActWarPkE:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
    gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActWarPkE:OnActivityListResp(pb)
	local sid = self._sid
	local activities = pb.activities
	for i, v in ipairs(activities) do
		if v.sid == sid then
			gModelActivity:ReqActivityConfigData(sid)
			break
		end
	end
end

function UIActWarPkE:GetAllActivityList()
	local activityDataList = self._activityDataList
	if not activityDataList then return {} end

	local sid = self._sid
	local entryCfg
	local pageGrade

	local page2ActList = {}
	local page2List = activityDataList[UIActWarPkE.ACT_PAGE_2] or {}
	local entry2List = page2List.entry or {}
	for i, v in ipairs(entry2List) do
		entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,v.entryId)
		if entryCfg then
			pageGrade = self:GetPageGrade(entryCfg)
			table.insert(page2ActList,{
				pageGrade = pageGrade,
				entryCfg = entryCfg,
				goalData = v.goalData,
				pageId = v.pageId,
				entryId = v.entryId,
			})
		end
	end

	local page3ActList = {}
	local page3List = activityDataList[UIActWarPkE.ACT_PAGE_3] or {}
	local entry3List = page3List.entry or {}
	for i, v in ipairs(entry3List) do
		entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,v.entryId)
		if entryCfg then
			pageGrade = self:GetPageGrade(entryCfg)
			table.insert(page3ActList,{
				pageGrade = pageGrade,
				entryCfg = entryCfg,
				goalData = v.goalData,
				pageId = v.pageId,
				entryId = v.entryId,
			})
		end
	end

	self:CommonSortFunc(page2ActList)
	self:CommonSortFunc(page3ActList)

	local actDataList = {}
	local entry3Data
	for i,v in ipairs(page2ActList) do
		entry3Data = page3ActList[i]
		if entry3Data then
			local data = self:GetCommonActData(v,entry3Data)
			table.insert(actDataList,data)
		end
	end
	return actDataList
end

function UIActWarPkE:InitRewardList(trans,list)
    local key = trans:GetInstanceID()
	local uiRewardList = self:FindUIScroll(key)
	if uiRewardList then
		uiRewardList:RefreshList(list)
	else
		uiRewardList = self:GetUIScroll(key)
		uiRewardList:Create(trans,list,function(...) self:OnDrawRewardCell(...) end)
	end
end

function UIActWarPkE:GetPageGradeStatus(itemdata)
	local buyPassNumList = self._buyPassNumList
	if not buyPassNumList then return false end
	local pageGrade = itemdata.pageGrade
	local passNumInfo = buyPassNumList[pageGrade]
	if not passNumInfo then return false end
	local buyPass = passNumInfo.buyPass or 0
	return buyPass> 0
end

function UIActWarPkE:OnDrawRewardCell(list,item,itemdata,itempos)
	local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
	local SelImgTrans = self:FindWndTrans(item,"SelImg")
	local MaskBgTrans = self:FindWndTrans(item,"MaskBg")
	local GouTrans = self:FindWndTrans(MaskBgTrans,"Gou")
	local LockTrans = self:FindWndTrans(MaskBgTrans,"Lock")
	local redPointTrans = self:FindWndTrans(item,"redPoint")
	local EffRootTrans = self:FindWndTrans(item,"EffRoot")
	local BtnTrans = self:FindWndTrans(item,"Btn")

	local instanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(IconTrans)
	baseClass:SetCommonReward(itemdata.itemType,itemdata.itemId,itemdata.itemNum)
	baseClass:DoApply()

	local target = itemdata.target
	local isRight = target == UIActWarPkE.TYPE_RIGHT

	local status = itemdata.status

	local showLock = false
	local showSel = status == ModelActivity.REWARD_STATUE_CAN_GET
	local showGou = status == ModelActivity.REWARD_STATUE_HAD_GET
	local showOnlyMask = false
	if isRight then
		--[[
                --# 普通版：
                ----# 未达成任务条件时，不显示遮罩和锁
                ----# 可领时显示道具框领取特效

                --# 进阶版：
                ----# 未购买战令时，显示遮罩，遮罩透明度为150
                ----# 已购买未达成时，不显示遮罩和锁
                ----# 可领取时显示道具框领取特效
        ]]
		--showLock = status == 0

		showOnlyMask = status == UIActWarPkE.STATUS_4
	else

	end

	CS.ShowObject(SelImgTrans,showSel)
	CS.ShowObject(GouTrans,showGou)

	if showLock and self._rewardLock and LxUiHelper.IsImgPathValid(self._rewardLock) then
		self:SetWndEasyImage(LockTrans,self._rewardLock)
	end
	CS.ShowObject(LockTrans,showLock)

	local showRedPointStatus = false
	if self._showRedPoint then
		showRedPointStatus = showSel
	end
	CS.ShowObject(redPointTrans,showRedPointStatus)

	local showEffStatus = showSel
	if self._showEff and showEffStatus then
		local effName = self._getRewardEffName or UIActWarPkE.GET_REWARD_EFFNAME
		local effKey = EffRootTrans:GetInstanceID()
		self:CreateWndEffect(EffRootTrans,effName,effKey,100)
	end
	CS.ShowObject(EffRootTrans,showEffStatus)


	local showMask = false
	if isRight then
		local pageGradeStatus = itemdata.pageGradeStatus or false
        if pageGradeStatus then
            showMask = showGou
        else
            showMask = status == ModelActivity.REWARD_STATUE_COMMON or showGou or showOnlyMask
        end
	else
		showMask = showGou
	end
	if showMask and self._rewardMask and LxUiHelper.IsImgPathValid(self._rewardMask) then
		self:SetWndEasyImage(MaskBgTrans,self._rewardMask)
	end
	CS.ShowObject(MaskBgTrans,showMask)


	self:SetWndClick(BtnTrans,function()
		self:OnClickRewardItemFunc(itemdata)
	end)
end

function UIActWarPkE:OnDrawActivityCell(list,item,itemdata,itempos)
	if self._star and LxUiHelper.IsImgPathValid(self._star) then
		local StarImgTrans = self:FindWndTrans(item,"TopDiv/Bg/StarImg")
		self:SetWndEasyImage(StarImgTrans,self._star)
	end

	local BgTrans = self:FindWndTrans(item,"TopDiv/Bg")
	if self._cellTextBg and LxUiHelper.IsImgPathValid(self._cellTextBg) then
		self:SetWndEasyImage(BgTrans,self._cellTextBg,function()
			self:ChangeImgEnable(BgTrans,true)
		end,true)
	else
		self:ChangeImgEnable(BgTrans,false)
	end

    local TitleTrans = self:FindWndTrans(BgTrans,"Title")

    local CenterDivTrans = self:FindWndTrans(item,"CenterDiv")
	if self._cellBg and LxUiHelper.IsImgPathValid(self._cellBg) then
		local CenterBgTrans = self:FindWndTrans(CenterDivTrans,"Bg")
		self:SetWndEasyImage(CenterBgTrans,self._cellBg)
	end
    local LeftRewradListTrans = self:FindWndTrans(CenterDivTrans,"LeftRewradList")
    local LeftRewradMoreListTrans = self:FindWndTrans(CenterDivTrans,"LeftRewradMoreList")
    local RightRewradListTrans = self:FindWndTrans(CenterDivTrans,"RightRewradList")
    local RightRewradMoreListTrans = self:FindWndTrans(CenterDivTrans,"RightRewradMoreList")

	self:SetWndText(TitleTrans,itemdata.name)

	local status1 = itemdata.status1
	local leftReward = self:DisposeRewardList(itemdata.leftReward,{
		pageId = itemdata.pageId1,
		entryId = itemdata.entryId1,
		status = status1,
		target = UIActWarPkE.TYPE_LEFT,
	})
	local leftLen = #leftReward
	local leftMoreStatus = leftLen > 1
	local leftShowTrans = leftMoreStatus and LeftRewradMoreListTrans or LeftRewradListTrans
	local leftHideTrans = leftMoreStatus and LeftRewradListTrans or LeftRewradMoreListTrans
	CS.ShowObject(leftShowTrans,true)
	CS.ShowObject(leftHideTrans,false)
	self:InitRewardList(leftShowTrans,leftReward)


	local rightStatusw = self:GetRightStatus(itemdata)
	local pageGradeStatus = self:GetPageGradeStatus(itemdata)
	local rightReward = self:DisposeRewardList(itemdata.rightReward,{
		pageId = itemdata.pageId2,
		entryId = itemdata.entryId2,
		status = rightStatusw,
		pageGradeStatus = pageGradeStatus,
		target = UIActWarPkE.TYPE_RIGHT,
	})
	local rightLen = #rightReward
	local rightMoreStatus = rightLen > 3
	local rightShowTrans = rightMoreStatus and RightRewradMoreListTrans or RightRewradListTrans
	local rightHideTrans = rightMoreStatus and RightRewradListTrans or RightRewradMoreListTrans
	CS.ShowObject(rightShowTrans,true)
	CS.ShowObject(rightHideTrans,false)
	self:InitRewardList(rightShowTrans,rightReward)
end

function UIActWarPkE:OnClickRewardItemFunc(itemdata)
	local status = itemdata.status
	local showSel = status == 1
	if showSel then
		gModelActivity:OnActivityReceiveGoalReq(self._sid,itemdata.pageId,itemdata.entryId)
	else
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end
end

function UIActWarPkE:InitEvent()
	self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtnFunc() end)
    self:SetWndClick(self.mBuyBtn,function() self:OnClickBuyBtnFunc() end)
    self:SetWndClick(self.mLeftBtn,function() self:OnClickLeftBtnFunc() end)
    self:SetWndClick(self.mRightBtn,function() self:OnClickRightBtnFunc() end)
    self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mSelBtn,function() self:OnClickSelBtnFunc() end)
end

function UIActWarPkE:InitActivityList()
    local list = self:GetActivityList()
    local uiActivityList = self._uiActivityList
    if uiActivityList then
        uiActivityList:RefreshList(list)
    else
        uiActivityList = self:GetUIScroll("uiActivityList")
        self._uiActivityList = uiActivityList
        uiActivityList:Create(self.mActivityList,list,function(...) self:OnDrawActivityCell(...) end,UIItemList.WRAP,false)
    end
	local uiList = uiActivityList:GetList()
	if uiList then
		local index = 0
		for i,v in ipairs(list) do
			if v.status1 == ModelActivity.REWARD_STATUE_CAN_GET then
				index = i
				break
			end
			if self:GetRightStatus(v) == ModelActivity.REWARD_STATUE_CAN_GET then
				index = i
				break
			end
		end
		if index < 4 then
			index = 0
		else
			index = index - 1
		end
		uiList:RefreshList(UIListWrap.RefreshMode.Custom,index)
	end
end

function UIActWarPkE:CommonSortFunc(list)
	table.sort(list,function(a,b)
		local pageGradeA,pageGradeB = a.pageGrade,b.pageGrade
		if pageGradeA ~= pageGradeB then return pageGradeA < pageGradeB end
		local entryCfgA,entryCfgB = a.entryCfg,b.entryCfg
		local sortA,sortB = entryCfgA.sort,entryCfgB.sort
		return sortA < sortB
	end)
end

function UIActWarPkE:OnClickSelBtnFunc()
	if not self._isSelectOpen then return end
	gModelGolem:OpenGolemSwitchHero({
		wndType = 2,
		actHeroList = self._selectHeroList,
		sid = self._sid,
		actType = ModelActivity.SELECT_HERO_COMBAT,
	})
end

function UIActWarPkE:GetPageGrade(entryCfg)
	--礼包档次
	local pageGrade = string.split(entryCfg.moreInfo, '=')[1]
	return tonumber(pageGrade)
end

function UIActWarPkE:GetOrderBuyData()
	local activityDataList = self._activityDataList
	if not activityDataList then
		if LOG_INFO_ENABLED then
			printInfoNR("====== 没有活动数据")
		end
		return
	end

	local page1List = activityDataList[UIActWarPkE.ACT_PAGE_1]
	if not page1List then return end
	local page1EntryList = page1List.entry or {}

	local isNotBuy = true
	local curIndex = 1
	local buyPassNumList = self._buyPassNumList
	for i,v in ipairs(buyPassNumList) do
		if v.buyPass > 0 then
			if isNotBuy then
				isNotBuy = false
			end
			curIndex = curIndex + 1
		end
	end

	if curIndex > #buyPassNumList then
		---- 已购买显示 activateIcon 字段
		return
	end

	if isNotBuy then
		---- 一阶未购买读取文本 buttonDesc
		return page1EntryList[1],self:GetBtnName(),1
	end

	local gradeNum = 0
	local sid = self._sid
	local pageGrade,entryCfg
	local page2GradeList = {}
	local page2List = activityDataList[UIActWarPkE.ACT_PAGE_2] or {}
	local entry2List = page2List.entry or {}
	for i,v in ipairs(entry2List) do
		entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,v.entryId)
		if entryCfg then
			pageGrade = self:GetPageGrade(entryCfg)
			local page2GradeData = page2GradeList[pageGrade]
			if not page2GradeData then
				page2GradeData = {}
				page2GradeList[pageGrade] = page2GradeData
				gradeNum = gradeNum + 1
			end
			table.insert(page2GradeData,{
				status = v.goalData.status,
			})
		end
	end

	if LOG_INFO_ENABLED then
		printInfoNR("精英版 礼包档次数量 gradeNum = " .. gradeNum)
	end

	--- 检测前面的是否已经完成任务了
	local isFinish = true
	local beforeIndex = curIndex - 1
	for pageG,pageGInfoList in pairs(page2GradeList) do
		if not isFinish then break end
		if pageG <= beforeIndex then
			for i,v in ipairs(pageGInfoList) do
				if not isFinish then break end
				isFinish = v.status == ModelActivity.REWARD_STATUE_HAD_GET
			end
		end
	end

	---- 当购买 n-1 阶战令后，并 n-1 阶战令所有任务完成时，则显示第 n 阶购买按钮 buttonDesc .. n-1 字段
	if isFinish then
		return page1EntryList[curIndex],self:GetBtnName(curIndex - 1),curIndex
	--else
	--	return page1EntryList[beforeIndex],self:GetBtnName(beforeIndex)
	end
end

function UIActWarPkE:OnClickRightBtnFunc()
	local actList = self:GetActivityList()
	if #actList < 1 then return end
	local sid = self._sid
	local list = {}
	for i,v in ipairs(actList) do
		if v.status1 == ModelActivity.REWARD_STATUE_CAN_GET then
			table.insert(list,{sid = sid , pageId = v.pageId1,entryId = v.entryId1})
		end
		if self:GetRightStatus(v) == ModelActivity.REWARD_STATUE_CAN_GET then
			table.insert(list,{sid = sid , pageId = v.pageId2,entryId = v.entryId2})
		end
	end
	if #list < 1 then
		if self._noRewardTips then
			GF.ShowMessage(self._noRewardTips)
		end
		return
	end
	gModelActivity:OnActivityReceiveGoalListReq(list)
end

function UIActWarPkE:GetAllBuyData()
	local isAllBuy,curIndex = self:CheckIsAllBuy()
	if isAllBuy then
		if LOG_INFO_ENABLED then
			printInfoNR("====== 全部买完")
		end
		return
	end
	if not curIndex or curIndex < 1 then
		curIndex = 1
	end
	local activityDataList = self._activityDataList
	if not activityDataList then
		if LOG_INFO_ENABLED then
			printInfoNR("====== 没有活动数据")
		end
		return
	end
	local page1List = activityDataList[UIActWarPkE.ACT_PAGE_1]
	if not page1List then
		if LOG_INFO_ENABLED then
			printInfoNR("====== 没有活动页数据")
		end
		return
	end
	local entry1List = page1List.entry or {}
	local indexData = entry1List[curIndex]
	if not indexData then
		if LOG_INFO_ENABLED then
			printInfoNR("====== 没有可购买数据")
		end
	end
	return indexData,indexData.MarketData.expend1
end

function UIActWarPkE:RefreshBuyBtnStatus()
	local buyData,btnName = self:GetBuyData()

	local showBuyEndStatus = buyData == nil
	CS.ShowObject(self.mActBuyStatus,showBuyEndStatus)

	local showBuyBtn = not showBuyEndStatus
	CS.ShowObject(self.mBuyBtn,showBuyBtn)

	local showType = self._showType or UIActWarPkE.SHOWTYPE_DEFAULT

	local showOnlyTxt = showBuyBtn and showType == UIActWarPkE.SHOWTYPE_ONLYTXT
	local showImgTxt = showBuyBtn and showType == UIActWarPkE.SHOWTYPE_IMGTXT
	CS.ShowObject(self.mDiscountTxt,showOnlyTxt)
	CS.ShowObject(self.mDiscountImgShowDiv,showImgTxt)

	self:SetWndButtonText(self.mBuyBtn,btnName)

	local isGray = false
	if self._isSelectOpen then
		if not self._isSelectHero then
			isGray = true
		end
	end

	local webCfg = self._activityDataList[UIActWarPkE.ACT_PAGE_1]
	local isShowDog = false
	if webCfg and #webCfg.entry>0 then
		local moreInfoStr = JSON.decode(webCfg.entry[1].moreInfo).moreInfo
		local moreInfo = string.split(moreInfoStr,"|")
		local DogTxtTip = moreInfo[4]
		if not string.isempty(DogTxtTip) then
			self:SetWndText(self.mTxtDogTxt,DogTxtTip)
			LayoutRebuilder.ForceRebuildLayoutImmediate(self.mImgDogTip)
			isShowDog = true
		end
	end
	CS.ShowObject(self.mImgDogTip,isShowDog)


	self:SetWndButtonGray(self.mBuyBtn,isGray)
	if showBuyEndStatus then
		return
	end
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,buyData.pageId,buyData.entryId)
	if not entryCfg then return end
	local moreInfo = string.split(entryCfg.moreInfo,"|")
	local discountStr = moreInfo[2]

	if showOnlyTxt then
		self:SetWndText(self.mDiscountTxt,discountStr)
	elseif showImgTxt then
		self:SetWndText(self.mDiscountImgTxt,discountStr)
	end
end

function UIActWarPkE:GetCommonActData(entry2Data,entry3Data)
	local cfg1,cfg2 = entry2Data.entryCfg,entry3Data.entryCfg
	local goalData1,goalData2 = entry2Data.goalData,entry3Data.goalData
	return {
		pageGrade = entry2Data.pageGrade,

		pageId1 = entry2Data.pageId,
		entryId1 = entry2Data.entryId,
		leftReward = self:GetRewardList(cfg1.reward),
		goalData1 = goalData1,
		status1 = goalData1.status,

		name = cfg1.name,

		pageId2 = entry3Data.pageId,
		entryId2 = entry3Data.entryId,
		rightReward = self:GetRewardList(cfg2.reward),
		goalData2 = goalData2,
		status2 = goalData2.status,
	}
end

function UIActWarPkE:OnClickLeftBtnFunc()
	self:OnClickJumpFunc()
end

function UIActWarPkE:RefreshEndTime()
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
		timeStr = string.replace(ccClientText(11637), LUtil.FormatTimespanCn(lastTime))
	else
		timeStr = ccClientText(14301)
		self:TimerStop(self._endKey)
	end
	self:SetWndText(self.mTimeText,timeStr)
	CS.ShowObject(self.mTimeBg,true)
end

function UIActWarPkE:GetBtnName(curIndex)
--[[	local config = self._config or {}
	if not curIndex then
		return config.buttonDesc or ""
	end
	local key = "buttonDesc" .. curIndex
	if not config[key] then
		if LOG_INFO_ENABLED then
			printInfoNR("活动配置表 没有找到对应的 key 值" .. key)
		end
	end
	return config[key]
	]]

	if not curIndex then
		curIndex = 0
	end
	curIndex = curIndex + 1
	local activityDataList = self._activityDataList
	if not activityDataList then
		if LOG_INFO_ENABLED then
			printInfoNR("====== 没有活动数据")
		end
		return
	end
	local page1List = activityDataList[UIActWarPkE.ACT_PAGE_1]
	if not page1List then return end
	local page1EntryList = page1List.entry or {}
	local page1Entry = page1EntryList[curIndex]
	if not page1Entry then return end
	local expend2 = page1Entry.MarketData.expend2
	local str = gModelPay:GetShowByWelfareId(tonumber(expend2))
	return str
end

function UIActWarPkE:OnActivityPageResp(pb)
	if self._sid ~= pb.sid then return end
	local activityDataList = self._activityDataList
	if not activityDataList then
		activityDataList = {}
		self._activityDataList = activityDataList
	end
	local pageId,page
	local pages = pb.pages
	for i, v in ipairs(pages) do
		pageId = v.pageId
		page = gModelActivity:GenerateActivePageDataFromPb(v)
		activityDataList[pageId] = page
	end

	self:RefreshBuyBtnStatus()

	self:InitActivityList()
end

function UIActWarPkE:OnClickBuyBtnFunc()
	if self._isSelectOpen and not self._isSelectHero then
		GF.ShowMessage(ccClientText(36102))
		return
	end
	self.clickBuy = true
	local passPurchase = self._passPurchase or ModelActivity.PASSPURCHASE_ORDER
	if passPurchase == ModelActivity.PASSPURCHASE_ALL then
		return self:OnClickAllBuyBtnFunc()
	else
		return self:OnClickOrderBuyBtnFunc()
	end
end

function UIActWarPkE:InitMsg()

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function(pb) self:OnActivityListResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb) self:OnActivityPageResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityABCDRewardResp,function (pb) self:OnActivityABCDRewardResp(pb) end)

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIActWarPkE:GetActivityList()
	local passPurchase = self._passPurchase or ModelActivity.PASSPURCHASE_ORDER
	if passPurchase == ModelActivity.PASSPURCHASE_ALL then
		return self:GetAllActivityList()
	else
		return self:GetOrderActivityList()
	end
end

function UIActWarPkE:GetRightStatus(itemdata)
	local status1 = itemdata.status1
	local status2 = itemdata.status2
	local rightStatusw = ModelActivity.REWARD_STATUE_COMMON
	local pageGrade = itemdata.pageGrade
	if pageGrade then
		if status1 ~= ModelActivity.REWARD_STATUE_COMMON then
			local buyPassNumMap = self._buyPassNumMap or {}
			local buyPassStatus = buyPassNumMap[pageGrade]
			if buyPassStatus then
				if buyPassStatus == 0 then
					rightStatusw = UIActWarPkE.STATUS_4
				else
					rightStatusw = status2
				end
			end
		end
	else
		rightStatusw = status2
	end
	return rightStatusw
end

function UIActWarPkE:GetRewardList(reward)
	local rewardList = LxDataHelper.ParseItem(reward) or {}
	if self._selectOpen and self._selectOpen == ModelActivity.TYPE_SELECTOPEN_1 and self._isSelectHero then
		local selectChangeHeroItemList = self._selectChangeHeroItemList or {}
		local changeHeroItem = selectChangeHeroItemList[self._select]
		if not changeHeroItem then
			if LOG_INFO_ENABLED then
				printInfoNR("找不到对应配置的道具id = "  .. changeHeroItem)
			end
		end
		local list = {}
		local transitionItem = self._transitionItem
		if not transitionItem then
			if LOG_INFO_ENABLED then
				printInfoNR("找不到对应配置的道具 transitionItem = "  .. transitionItem)
			end
		end
		local needChangeId
		for i,v in ipairs(rewardList) do
			if transitionItem and transitionItem == v.itemId then
				needChangeId = changeHeroItem or v.itemId
			else
				needChangeId = v.itemId
			end
			table.insert(list,{
				itemType = v.itemType,
				itemId = needChangeId,
				itemNum = v.itemNum,
				isShowEff = v.isShowEff,
			})
		end
		return list
	else
		return rewardList
	end
end

function UIActWarPkE:DisposeRewardList(rewardList,info)
	rewardList = rewardList or {}
	local pageId = info.pageId
	local entryId = info.entryId
	local status = info.status
	local target = info.target
	local pageGradeStatus = info.pageGradeStatus
	local list = {}
	for i,v in ipairs(rewardList) do
		table.insert(list,{
			pageId = pageId,
			entryId = entryId,
			status = status,
			itemType = v.itemType,
			itemId = v.itemId,
			itemNum = v.itemNum,
			isShowEff = v.isShowEff,
			target = target,
			pageGradeStatus = pageGradeStatus,
		})
	end
	return list
end

function UIActWarPkE:OnActivityConfigData(data,sid)
    if sid ~= self._sid then return end

	self:TimerStop(self._timeKey)

	local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityWebData then return end
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

	self._endTime = tonumber(activityData.endTime)


	local moreInfo = JSON.decode(activityData.moreInfo)

	local buyPassNumList = {}
	local buyPassNumMap = {}
	local buyPassNum = string.split(moreInfo.buyPassNum,",")
	for i,v in ipairs(buyPassNum) do
		v = tonumber(v)
		table.insert(buyPassNumList,{
			buyPass = v,
		})
		buyPassNumMap[i] = v
	end
	self._buyPassNumList = buyPassNumList
	self._buyPassNumMap = buyPassNumMap

	self._select = tonumber(moreInfo.select) or 0

	self:RefreshEndTime()
	local para = {
		key = self._timeKey,
		interval = 1,
		loopcnt = -1,
		timescale = false,
		func = function()
			self:RefreshEndTime()
		end
	}
	self:TimerStartImpl(para)

	local config = activityWebData.config
	self._config = config

	---------------------------------------------------------
	local showType
	local discountShowType = config.discountShowType
	if discountShowType then
		showType = tonumber(discountShowType)
	else
		if LOG_INFO_ENABLED then
			printInfoNR("discountShowType 字段控制显示类型： " .. UIActWarPkE.SHOWTYPE_ONLYTXT .. " = 纯文本显示（discountPosition 字段作用于 DiscountTxt 节点），" ..
				UIActWarPkE.SHOWTYPE_IMGTXT .. " = 折扣图案 + 文本显示（discountPosition 字段作用于 DiscountImgShowDiv 节点），" .. "discountShowType 默认：" .. UIActWarPkE.SHOWTYPE_DEFAULT)
		end
	end
	if not showType then
		showType = UIActWarPkE.SHOWTYPE_DEFAULT
	end
	self._showType = showType

	local discountImgRes = config.discountImgRes
	if discountImgRes then
		self:SetWndEasyImage(self.mDiscountImg,discountImgRes)
	else
		if LOG_INFO_ENABLED then
			printInfoNR("discountImgRes 字段控制显示折扣底图资源，不配置使用默认")
		end
	end

	local discountImgResSize = config.discountImgResSize
	if discountImgResSize then
		discountImgResSize = tonumber(discountImgResSize)
		self.mDiscountImg.localScale = Vector3(discountImgResSize,discountImgResSize,discountImgResSize)
	end

	local discountArrowImgRes = config.discountArrowImgRes
	if discountArrowImgRes then
		self:SetWndEasyImage(self.mDiscountArrowImg,discountArrowImgRes)
	else
		if LOG_INFO_ENABLED then
			printInfoNR("discountArrowImgRes 字段控制显示折扣Up图片资源，不配置使用默认")
		end
	end

	local discountArrowSize = config.discountArrowSize
	if discountArrowSize then
		local discountArrowSizeInfo = string.split(discountArrowSize,";")
		local width = tonumber(discountArrowSizeInfo[1]) or 18
		local height = tonumber(discountArrowSizeInfo[2]) or 22
		local layout = self.mDiscountArrowCon:GetComponent(typeLayoutElement)
		if layout then
			layout.preferredWidth = width
			layout.preferredHeight = height
		end
	else
		if LOG_INFO_ENABLED then
			printInfoNR("discountArrowSize 字段控制显示折扣Up图片资源显示大小（配置格式：width,height），不配置使用默认，若设置了 discountArrowImgRes 字段并且 discountArrowImgRes 的大小不等于默认资源大小（宽：18，高：22），需要启用这个字段，不然会出现文字覆盖up资源问题")
		end
	end
	---------------------------------------------------------


	local showEffStatus = config.showEffStatus
	if not showEffStatus then
		showEffStatus = 1
		if LOG_INFO_ENABLED then
			printInfoNR("是否显示特效，配置 showEffStatus 字段，默认 showEffStatus = 1，显示")
		end
	end
	self._showEff = showEffStatus == 1

	local getRewardEffName = config.getRewardEffName
	if not getRewardEffName then
		getRewardEffName = UIActWarPkE.GET_REWARD_EFFNAME
		if LOG_INFO_ENABLED then
			printInfoNR("特效名字，配置 getRewardEffName 字段，默认 getRewardEffName = " .. UIActWarPkE.GET_REWARD_EFFNAME)
		end
	end
	self._getRewardEffName = config.getRewardEffName

	local showRedPointStatus = config.showRedPointStatus
	if not showRedPointStatus then
		showRedPointStatus = 0
		if LOG_INFO_ENABLED then
			printInfoNR("是否显示红点，配置 showRedPointStatus 字段，默认 showRedPointStatus = 0，不显示")
		end
	end
	self._showRedPoint = showRedPointStatus == 1

	self._transitionItem = tonumber(config.transitionItem) or 0
	if LOG_INFO_ENABLED then
		printInfoNR("transitionItem = " .. self._transitionItem)
	end

	self._passPurchase = tonumber(config.passPurchase) or ModelActivity.PASSPURCHASE_ORDER
	if LOG_INFO_ENABLED then
		printInfoNR("passPurchase = " .. self._passPurchase)
	end

	--------------------------------------------------------------
	local textBg = config.textBg
	if LxUiHelper.IsImgPathValid(textBg) then
		self:SetWndEasyImage(self.mActShowDivBg,textBg,function()
			self:ChangeImgEnable(self.mActShowDivBg,true)
		end,true)
	else
		self:ChangeImgEnable(self.mActShowDivBg,false)
	end

	local bg = config.bg
	if LxUiHelper.IsImgPathValid(bg) then
		self:SetWndEasyImage(self.mActBg,bg,function()
		end,true)
	end

	local titleBg = config.titleBg
	if LxUiHelper.IsImgPathValid(titleBg) then
		self:SetWndEasyImage(self.mListTipBg,titleBg,function()
		end,false)
	end

	local cellListBg = config.cellListBg
	if LxUiHelper.IsImgPathValid(cellListBg) then
		self:SetWndEasyImage(self.mCellBg,cellListBg,function()
			self:ChangeImgEnable(self.mCellBg,true)
		end,true)
	else
		self:ChangeImgEnable(self.mCellBg,false)
	end

	self._star = config.star

	local line = config.line
	if LxUiHelper.IsImgPathValid(line) then
		self:SetWndEasyImage(self.mLine,line,function()
		end)
	end

	self._cellBg = config.cellBg

	self._cellTextBg = config.cellTextBg

	self._noRewardTips = config.noRewardTips

	self._rewardMask = config.rewardMask

	self._rewardLock = config.rewardLock
	--------------------------------------------------------------

	local imageText = config.imageText
	CS.ShowObject(self.mImgPrivilege,not string.isempty(imageText))
	local imgTextPos = config.imageTextPos
	if not string.isempty(imageText) and not string.isempty(imgTextPos) then
		self:SetWndEasyImage(self.mImgPrivilege,imageText,nil,true)
		self:SetAnchorPos(self.mImgPrivilege, LxDataHelper.ParseVector2NotEmpty(imgTextPos))
	end

	local image = config.image
	if LxUiHelper.IsImgPathValid(image) then
		self:SetWndEasyImage(self.mTopImg,image,function()
			CS.ShowObject(self.mTopImg,true)
		end,true)
	end
	self:SetAnchorPos(self.mTopImg, LxDataHelper.ParseVector2NotEmpty(config.imagePos))




	local descIcon = config.descIcon
	if LxUiHelper.IsImgPathValid(descIcon) then
		self:SetWndEasyImage(self.mActTxtImg,descIcon,function()
			CS.ShowObject(self.mActTxtImg,true)
		end,true)
	end
	self:SetAnchorPos(self.mActTxtImg, LxDataHelper.ParseVector2NotEmpty(config.descIconPosition))

	self._helpTipsTitle = activityData.title
	self._helpTipsContent = config.helpTipsContent

	local helpTips = tonumber(config.helpTips) or 0
	local showHelpTips = helpTips == 1
	if showHelpTips then
		self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(config.helpTipsPosition))
	end
	CS.ShowObject(self.mHelpBtn,showHelpTips)

	self:SetAnchorPos(self.mTimeBg, LxDataHelper.ParseVector2NotEmpty(config.timePos))

	self._jump = config.jump

	local taskDesc = config.taskDesc or ""
	local hyper = self:GetUIHyperText(self.mJumpTxt)
	local str = hyper:AddHyper(taskDesc,{func = function() self:OnClickJumpFunc() end})
	self:SetWndText(self.mJumpTxt,str)
	self:SetAnchorPos(self.mJumpTxt, LxDataHelper.ParseVector2NotEmpty(config.taskDescPos))

	local taskBtnShow = tonumber(config.taskBtnShow) or 1
	local showLeftBtn = taskBtnShow == 1
	if taskBtnShow then
		self:SetWndButtonText(self.mLeftBtn,taskDesc)
	end
	CS.ShowObject(self.mLeftBtnDiv,showLeftBtn)

	local showItemDesc = config.showItemDesc
	self:SetWndText(self.mActDesc,showItemDesc)
	self:SetAnchorPos(self.mActDesc, LxDataHelper.ParseVector2NotEmpty(config.showItemDescPosition))

	self:SetAnchorPos(self.mBtnShowDiv, LxDataHelper.ParseVector2NotEmpty(config.buttonPosition))

	if showType == UIActWarPkE.SHOWTYPE_ONLYTXT then
		self:SetAnchorPos(self.mDiscountTxt, LxDataHelper.ParseVector2NotEmpty(config.discountPosition))
	elseif showType == UIActWarPkE.SHOWTYPE_IMGTXT then
		self:SetAnchorPos(self.mDiscountImgShowDiv, LxDataHelper.ParseVector2NotEmpty(config.discountPosition))
	end

	local buttonIcon = config.buttonIcon
	if not string.isempty(buttonIcon) then
		self:SetWndButtonImg(self.mBuyBtn,buttonIcon)

		local mat = LUtil.GetOutlineMatByImg(buttonIcon)
		self:SetWndButtonTextMat(self.mBuyBtn,mat)
	end

	local activateIcon = config.activateIcon
	if not string.isempty(activateIcon) then
		self:SetWndEasyImage(self.mActBuyStatus,activateIcon,nil,true)
	end

	local listDesc = string.split(config.listDesc,"|")
	local txt1 = listDesc[1] or ""
	self:SetWndText(self.mText1,txt1)
	local txt2 = listDesc[2] or ""
	self:SetWndText(self.mText2,txt2)

	self._imageHeroType = config.imageHeroType or 1			--- 资源类型

	self._imageHeroTurn = config.imageHeroTurn or 0			--- 是否水平翻转
	self._isFlipX = self._imageHeroTurn == 1

	self._imageHeroScope = config.imageHeroScope or 1		--- 资源缩放比例

	local selectChangeHeroItemList = {}
	local selectOpen = tonumber(config.selectOpen) or ModelActivity.TYPE_SELECTOPEN_0
	if LOG_INFO_ENABLED then
		printInfoNR("selectOpen = " .. selectOpen)
	end
	local isSelectOpen = selectOpen == ModelActivity.TYPE_SELECTOPEN_1
	local isAppointHero = selectOpen == ModelActivity.TYPE_SELECTOPEN_2
	local selectHeroList = {}
	if isSelectOpen then
		local selectHero = string.split(config.selectHero,"|")
		local heroRefId,heroChangeItemId
		for i,v in ipairs(selectHero) do
			v = string.split(v,"=")
			heroRefId,heroChangeItemId = tonumber(v[1]),tonumber(v[2])
			table.insert(selectHeroList,{
				itemType = LItemTypeConst.TYPE_HERO,
				itemId = heroRefId,
				itemNum = 1
			})

			selectChangeHeroItemList[heroRefId] = heroChangeItemId
		end
	elseif isAppointHero then
		if not config.appointHero then
			if LOG_INFO_ENABLED then
				printInfoNR("打印而已，莫慌    config.appointHero 字段没有配置")
			end
		else
			--- 指定英雄
			isSelectOpen = true
			self._select = tonumber(config.appointHero) or 0
		end
	else
		local imageHero = config.imageHero
		if LxUiHelper.IsImgPathValid(imageHero) then
			self:SetWndEasyImage(self.mActPersonImg,imageHero,function()
				CS.ShowObject(self.mActPersonImg,true)
			end,true)
		end
	end
	self._isSelectHero = self._select > 0
	self._selectChangeHeroItemList = selectChangeHeroItemList

	CS.ShowObject(self.mCanSelHeroDiv,isSelectOpen)

	local imageHeroPos = config.imageHeroPos
	self:SetAnchorPos(self.mActPersonImg, LxDataHelper.ParseVector2NotEmpty(imageHeroPos))
	self:SetAnchorPos(self.mHerpSp, LxDataHelper.ParseVector2NotEmpty(imageHeroPos))


	self._selectOpen = selectOpen
	self._isSelectOpen = isSelectOpen
	self._selectHeroList = selectHeroList

	self:RefreshSelectHero()

	gModelActivity:OnActivityPageReq(sid)
end

function UIActWarPkE:ChangeImgEnable(trans,enabled)
	local uiImage = self:GetUIImage(trans)
	if not uiImage then return end
	uiImage.enabled = enabled
end

function UIActWarPkE:OnClickAllBuyBtnFunc()
	local activityDataList = self._activityDataList
	if not activityDataList then
		if LOG_INFO_ENABLED then
			printInfoNR("====== 没有活动数据")
		end
		return
	end

	local page1List = activityDataList[UIActWarPkE.ACT_PAGE_1]
	if not page1List then return end

	local buyPassNumList = self._buyPassNumList
	if not buyPassNumList then return end

--[[	local curIndex = 1
	for i,v in ipairs(buyPassNumList) do
		if v.buyPass > 0 then
			curIndex = curIndex + 1
		end
	end]]

	local curIndex
	for i,v in ipairs(buyPassNumList) do
		if curIndex then
			if v.buyPass < 1 and curIndex > i then
				curIndex = i
			end
		elseif not curIndex then
			curIndex = i
		end
	end
	if not curIndex then
		curIndex = 1
	end

	---- 显示所有 entry
	local entryList = page1List.entry
	GF.OpenWnd("UIPkBuyPopBig",
			{sid = self._sid,entry = entryList, grade = #buyPassNumList,
			 index = curIndex, modelActivityType = ModelActivity.MODEL_PASSD})
end

function UIActWarPkE:OnActivityABCDRewardResp(pb)
	if pb.sid ~= self._sid then return end
	local reward = pb.itemList
	local itemList = {}
	for k,v in ipairs(reward) do
		local tab = {
			itype = tonumber(v.type),
			itemId = tonumber(v.itemId),
			count = tonumber(v.count),
		}
		table.insert(itemList, tab)
	end
	gModelWndPop:TryOpenPopWnd("UIAward", {itemList = itemList})
end

function UIActWarPkE:InitText()
	self:SetWndButtonText(self.mRightBtn,ccClientText(36101))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
end


------------------------- List -------------------------
function UIActWarPkE:CheckIsAllBuy()
	if not self._buyPassNumList then return false,1 end
	local buyPassNumList = self._buyPassNumList
	local len = #buyPassNumList
	local minNoBuyIndex
	local index
	local buyNum = 0
	for i,v in ipairs(buyPassNumList) do
		if v.buyPass > 0 then
			buyNum = buyNum + 1
			index = i
		else
			if minNoBuyIndex and minNoBuyIndex > i then
				minNoBuyIndex = i
			elseif not minNoBuyIndex then
				minNoBuyIndex = i
			end
		end
	end
	if buyNum >= len then
		return true
	end
	if index then
		index = index + 1
	end
	return false,minNoBuyIndex
end

function UIActWarPkE:InitData()
	local sid = self:GetWndArg("sid")
	local subPage = self:GetWndArg("subPage")
	if subPage then
		sid = gModelActivity:GetSidByUniqueJump(subPage)
	end
    self._sid = sid
	self.jumpCallback = self:GetWndArg("jumpCallback")
end

function UIActWarPkE:OnClickOrderBuyBtnFunc()
	local buyData,btnName,curIndex = self:GetOrderBuyData()
	if not buyData then return end

	if LOG_INFO_ENABLED then
		if curIndex then
			printInfoNR("当前购买下标：curIndex = " .. curIndex)
		else
			printInfoNR("没有下标 ")
		end
	end
	---- 显示当前 entry
	local entryList = {buyData}
	GF.OpenWnd("UIPkBuyPopBig", {sid = self._sid,entry = entryList, grade = 1,
									index = 1,curIndex = curIndex, modelActivityType = ModelActivity.MODEL_PASSD})
end

function UIActWarPkE:OnClickJumpFunc()
	local jump = self._jump
	if not jump then
		if LOG_INFO_ENABLED then
			printInfoNR("jump 字段为空")
		end
		return
	end
	if gModelFunctionOpen:CheckIsOpened(jump,true) then
		gModelFunctionOpen:Jump(jump,self:GetWndName())
	end
end

function UIActWarPkE:OnActivityResp(pb)
	if self._sid ~= pb.sid then return end
	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActWarPkE:OnClickHelpBtnFunc()
	if not self._helpTipsTitle or not self._helpTipsContent then return end
	GF.OpenWnd("UIBzTips",{title= self._helpTipsTitle,text = self._helpTipsContent})
end

function UIActWarPkE:GetOrderActivityList()
	local activityDataList = self._activityDataList
	if not activityDataList then return {} end

	local isAllBuy,curIndex = self:CheckIsAllBuy()
	if not isAllBuy then
		if not curIndex or curIndex < 1 then
			curIndex = 1
		end
	end

	local sid = self._sid
	local entryCfg
	local pageGrade

	local page2ActList = {}
	local page2List = activityDataList[UIActWarPkE.ACT_PAGE_2] or {}
	local entry2List = page2List.entry or {}
	for i, v in ipairs(entry2List) do
		entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,v.entryId)
		if entryCfg then
			pageGrade = self:GetPageGrade(entryCfg)
			local isIns = false
			if isAllBuy then
				isIns = true
			else
				if curIndex >= pageGrade then
					isIns = true
				end
			end
			if isIns then
				table.insert(page2ActList,{
					pageGrade = pageGrade,
					entryCfg = entryCfg,
					goalData = v.goalData,
					pageId = v.pageId,
					entryId = v.entryId,
				})
			end
		end
	end

	local page3ActList = {}
	local page3List = activityDataList[UIActWarPkE.ACT_PAGE_3] or {}
	local entry3List = page3List.entry or {}
	for i, v in ipairs(entry3List) do
		entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,v.entryId)
		if entryCfg then
			pageGrade = self:GetPageGrade(entryCfg)
			local isIns = false
			if isAllBuy then
				isIns = true
			else
				if curIndex >= pageGrade then
					isIns = true
				end
			end
			if isIns then
				table.insert(page3ActList,{
					pageGrade = pageGrade,
					entryCfg = entryCfg,
					goalData = v.goalData,
					pageId = v.pageId,
					entryId = v.entryId,
				})
			end
		end
	end

	self:CommonSortFunc(page2ActList)
	self:CommonSortFunc(page3ActList)

	local actDataList = {}
	local entry3Data
	for i,v in ipairs(page2ActList) do
		entry3Data = page3ActList[i]
		if entry3Data then
			local data = self:GetCommonActData(v,entry3Data)
			table.insert(actDataList,data)
		end
	end
	return actDataList
end

function UIActWarPkE:RefreshSelectHero()
	if not self._isSelectOpen then return end
	local isSelHero = self._isSelectHero
	CS.ShowObject(self.mNoSelHeroImg,not isSelHero)
	CS.ShowObject(self.mSelRoot,not isSelHero)
	if not isSelHero then return end
	local imageHeroType = self._imageHeroType or 1
	local isLiHui = imageHeroType == 1
	local select = self._select or 0
	local imageHeroScope = self._imageHeroScope or 1
	local heroDrawing = gModelHero:GetHeroPrefabNameByRefId(select, nil, isLiHui)
	self:CreateWndSpine(self.mHerpSp,heroDrawing,heroDrawing,false,function(dpSpine)
		dpSpine:SetScale(imageHeroScope)
		CS.ShowObject(self.mHerpSp,true)
	end,nil,nil,self._isFlipX)
end

function UIActWarPkE:GetBuyData()
	local passPurchase = self._passPurchase or ModelActivity.PASSPURCHASE_ORDER
	if passPurchase == ModelActivity.PASSPURCHASE_ALL then
		return self:GetAllBuyData()
	else
		return self:GetOrderBuyData()
	end
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIActWarPkE



