---
--- Created by Administrator.
--- DateTime: 2023/10/7 16:31:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActPkE:LWnd
local UIActPkE = LxWndClass("UIActPkE", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")

UIActPkE.PAGE_BUY = 1			--档位购买
UIActPkE.PAGE_ELITE = 2			--普通版
UIActPkE.PAGE_ADVANCE = 3		--进阶版
UIActPkE.PAGE_SUPER = 4     	--豪华版
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActPkE:UIActPkE()
	self._passKey = "_endTimeKey"
	self._descFormat = "%s<br><color=#30E055><u>%s</u></color>"

	self._itemGetEff = "fx_baowu_kejihuo"

	---@type table<number,CommonIcon>
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActPkE:OnWndClose()
	if self._curUIHeroObj then
		self._curUIHeroObj:Destroy()
		self._curUIHeroObj = nil
	end

	self:ClearCommonIconList(self._uiCommonList)


	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActPkE:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActPkE:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIActPkE:InitEvent()
	self:SetWndClick(self.mHelpBtn, function(...) self:OnClickHelp() end)
	self:SetWndClick(self.mHeroNameBg, function(...) self:OnClickHeroName() end)
	self:SetWndClick(self.mHeroNameBgEn, function(...) self:OnClickHeroName() end)
	self:SetWndClick(self.mDesText, function(...) self:OnClickGoOn() end)
	self:SetWndClick(self.mText1, function(...) self:OnClickBuyAdvance(UIActPkE.PAGE_ADVANCE) end)
	self:SetWndClick(self.mText2, function(...) self:OnClickBuyAdvance(UIActPkE.PAGE_SUPER) end)
	self:SetWndClick(self.mDiscountBg1, function(...) self:OnClickBuyAdvance(UIActPkE.PAGE_ADVANCE) end)
	self:SetWndClick(self.mDiscountBg2, function(...) self:OnClickBuyAdvance(UIActPkE.PAGE_SUPER) end)
	self:SetWndClick(self.mQuickIcon, function(...) self:OnClickShowQuickPop() end)
	self:SetWndClick(self.mPassGetBtn, function(...) self:OnClickGetBtn() end)
	self:SetWndClick(self.mBackBtn, function(...) self:WndClose() end)
end

function UIActPkE:SetTime()--设置时间
	local time = GetTimestamp()
	local timespan = self._endTime - time
	if(timespan <= 0)then
		self:TimerStop(self._passKey)
		self:SetWndText(self.mEndTimeText,"")
		return
	end

	local timeStr
	if timespan> 86400 then
		timeStr = LUtil.FormatTimespanCn(timespan)
	else
		timeStr = LUtil.FormatTimespanCn(timespan)
	end

	local str = ""
	local _timeDes = self._timeDes
	if not string.isempty(_timeDes) then
		str = string.replace(_timeDes,timeStr)
	end
	self:SetWndText(self.mEndTimeText,str)
end

function UIActPkE:RefreshGetBtn()
	local canGet = self._canGet
	local str
	if canGet then
		str = ccClientText(38800)
	elseif not (self._advanceBuy and self._superBuy) then
		str = ccClientText(38801)
	elseif self._needQuick then
		str = ccClientText(38806)
	else
		str = ccClientText(38802)
	end

	self:SetWndButtonText(self.mPassGetBtn, str)
	CS.ShowObject(self.mBtnRedPoint, canGet)
end

function UIActPkE:OnClickBuyAdvance(buyPage)
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local curPage = self._pages[UIActPkE.PAGE_BUY]
	if not curPage then
		return
	end

	local bGuys = {
		self._advanceBuy and "1" or "0",
		self._superBuy and "1" or "0",
	}
	local entry = curPage.entry
	local index = buyPage == UIActPkE.PAGE_ADVANCE and 1 or 2
	GF.OpenWnd("UIPkBuyPopBig",
			{sid = self._sid,entry = entry, grade = 2, index = index, bGuys = bGuys,
			 modelActivityType = ModelActivity.MODEL_PASSE})
end

--领取奖励后，弹奖励获得弹窗
function UIActPkE:OnActivityABCDRewardResp(pb)
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

    local isShowPassReward = not table.isempty(self._passRewardItemList)
    if isShowPassReward then
        local boxType = self._passRewardItemType
        GF.OpenWnd("UIPkAward",{
            itemList = itemList,
            passItemList = self._passRewardItemList,
            passDesc = ccClientText(20706),
            btnTextList = {ccClientText(10102), ccClientText(20707)},
            func = function() self:ShowGiftPop(boxType) end,
        })
    else
        gModelWndPop:TryOpenPopWnd("UIAward", {itemList = itemList})
    end
end

function UIActPkE:InitCommand()
	self._sid = self:GetWndArg("sid")
	local _sid = self._sid

	self._boxEnum = {
		COMMON = 1,
		ADVANCE = 2,
		SUPER = 3,
	}

	self._pages = {}
	gModelActivity:ReqActivityConfigData(_sid)
end

function UIActPkE:CreateHeroSpine(prefabName)
	if self._curUIHeroObj then return end
	local newUIHeroObj = LUIHeroObject:New(self)
	newUIHeroObj:Create(self.mHeroSpine,prefabName,prefabName)
	newUIHeroObj:SetScale(1)
	--newUIHeroObj:SetClickFunc(function(...) self:OnClickHeroSpine(...) end)
	newUIHeroObj:ShowHero(true)
	newUIHeroObj:StartLoad()

	self._curUIHeroObj = newUIHeroObj
end

function UIActPkE:RefreshData()
	if table.isempty(self._pages) then return end
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	local config = JSON.decode(activityData.moreInfo)
	self._activityData = activityData
	self._endTime = (config.playerEndTime and tonumber(config.playerEndTime) / 1000) or tonumber(activityData.endTime)
	self:SetTime()
	if not self:IsTimerExist(self._passKey) then
		self:TimerStart(self._passKey,1,false,-1)
	end
	local buyPage = self._pages[UIActPkE.PAGE_BUY]
	if not buyPage then return end
	local entry = buyPage.entry[1]
	self._advanceBuy 		= entry.MarketData.personal > 0
	entry 		= buyPage.entry[2]
	self._superBuy 			= entry.MarketData.personal > 0

	self:RefreshCellScroll()
	local schedule = self._schedule
	local str = ""
	local text = self._showItemDesc
	if not string.isempty(text) then
		str = string.replace(text,schedule)
	end

	str = string.replace(self._descFormat, str, self._taskDesc)
	self:SetWndText(self.mDesText, str)
	CS.ShowObject(self.mDesText,true)

	self:RefreshDiscountPrice()
	self:RefreshGetBtn()
end

--#####################################################################################################################
--## Centre ###########################################################################################################
--#####################################################################################################################
function UIActPkE:RefreshCellScroll()
	local eliteList = self._pages[UIActPkE.PAGE_ELITE].entry
	local advanceList = self._pages[UIActPkE.PAGE_ADVANCE].entry
	local superList = self._pages[UIActPkE.PAGE_SUPER].entry

	local schedule = 0
	local canGet = false
	self._completeIndex = 0
	for i, v in ipairs(eliteList) do
		local data = advanceList[i]
		v.goalData2 = data.goalData
		v.pageId2 = data.pageId
		v.entryId2 = data.entryId

		local data3 = superList[i]
		v.goalData3 = data3.goalData
		v.pageId3 = data3.pageId
		v.entryId3 = data3.entryId
		local status = v.goalData.status
		if(status ~= 0)then
			self._completeIndex = i
			if status == 1 or (v.goalData2.status == 1 and self._advanceBuy) or (v.goalData3.status == 1 and self._superBuy) then
				canGet = true
			end
		end
		local scdle = tonumber(v.goalData.schedules[1].schedule)
		if(scdle > 0 and schedule<scdle)then
			schedule = scdle
		end
	end

	self._schedule = schedule
	self._canGet = canGet
	self._maxItemNum = #eliteList

	if(self._uiList)then
		self._uiList:RefreshData(eliteList)
	else
		self._uiList = self:GetUIScroll("cell")
		self._uiList:Create(self.mCellScroll,eliteList,function (...) self:ListItem(...) end, UIItemList.WRAP,false)
	end

	local list= self._uiList:GetList()
	local index = self._completeIndex - 1
	if(index < 4)then
		index = 0
	else
		index = index - 2
	end
	list:RefreshList(UIListWrap.RefreshMode.Custom,index)
end

function UIActPkE:RefreshDiscountPrice()
	local data = self._activityCfg
	if not data then return end

	if not self._advanceBuy then
		local str = self:GetPriceStr(UIActPkE.PAGE_ADVANCE)
		self:SetWndText(self.mDiscountText1, str)
	end
	CS.ShowObject(self.mDiscountBg1, not self._advanceBuy)

	if not self._superBuy then
		local str = self:GetPriceStr(UIActPkE.PAGE_SUPER)
		self:SetWndText(self.mDiscountText2, str)
	end
	CS.ShowObject(self.mDiscountBg2, not self._superBuy)

	self._needQuick = self:CheckNeedQuick()
	CS.ShowObject(self.mQuickIcon, self._needQuick)

	self:RefreshQuickRed()
end

function UIActPkE:RefreshQuickRed()
	if not self._needQuick then
		return
	end

	local passEQuickRedSid = tonumber(LPlayerPrefs.passEQuickRedSid)
	CS.ShowObject(self.mQuickRedPoint, passEQuickRedSid ~= self._sid)
end


function UIActPkE:OnClickHeroName()
	if not self._heroRefId then return end

	local refId = self._heroRefId
	if refId > 9999 then
		gModelGeneral:OpenHeroSkin({skinRefId = refId})
	else
		gModelGeneral:OpenHeroSkin({ refId = refId})
	end
end

function UIActPkE:OnClickShowQuickPop()
	LPlayerPrefs.SetPassEQuickRedSid(self._sid)
	self:RefreshQuickRed()

	local bGuys = {
		self._advanceBuy and "1" or "0",
		self._superBuy and "1" or "0",
	}
	GF.OpenWnd("UIPkQukBuyPop",{sid = self._sid, bGuys = bGuys, titleStr = ccClientText(38805),
	modelActivityType = ModelActivity.MODEL_PASSE})
end

function UIActPkE:OnClickGetBtn()--一键领取
	if table.isempty(self._pages) then return end

	if self._canGet then
		local list ={}
		local getEntryIdList = {}

		for i, v in ipairs(self._pages[UIActPkE.PAGE_ELITE].entry) do
			local status = v.goalData.status
			if(status >= 1)then
				local data1 = { sid = self._sid,pageId = v.pageId,entryId = v.entryId}
				getEntryIdList[v.entryId] = true

				if status == 1 then
					table.insert(list,data1)
				end
			end
		end

		if(self._advanceBuy)then
			for i, v in ipairs(self._pages[UIActPkE.PAGE_ADVANCE].entry) do
				if(v.goalData.status==1)then
					local data2 = { sid = self._sid,pageId = v.pageId,entryId = v.entryId}
					table.insert(list,data2)
				end
			end
		end

		if self._superBuy then
			for i, v in ipairs(self._pages[UIActPkE.PAGE_SUPER].entry) do
				if(v.goalData.status==1)then
					local data3 = { sid = self._sid,pageId = v.pageId,entryId = v.entryId}
					table.insert(list,data3)
				end
			end
		end

		if table.isempty(list) then
			GF.ShowMessage(ccClientText(38803))
			return
		end

		--检测是否显示战令奖励弹窗
		self._passRewardItemList, self._passRewardItemType = self:GetShowPassRewardList(getEntryIdList)
		--self._haveNoGet = self:CheckHaveNoGet()
		gModelActivity:OnActivityReceiveGoalListReq(list)
	elseif not self._advanceBuy then
        self:OnClickBuyAdvance(UIActPkE.PAGE_ADVANCE)
    elseif not self._superBuy then
        self:OnClickBuyAdvance(UIActPkE.PAGE_SUPER)
	else
		self:OnClickGoOn()
	end
end

--######################################################################################################################
--## Server ############################################################################################################
--######################################################################################################################
function UIActPkE:ResetData(pb)
	local sid=pb.sid
	if(self._sid~=sid)then
		return
	end
	for i, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		self._pages[v.pageId]=page
	end
	self:RefreshData()
end

function UIActPkE:OnTargetWndClose(wndName)
    if wndName == "UIAward" and not table.isempty(self._passRewardItemList) then
        --重新开启滑动
        self:ShowGiftPop(self._passRewardItemType)
    end
end

function UIActPkE:ListItem(list,item, itemdata, itempos)
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local entryCfg2 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId2,itemdata.entryId2)
	local entryCfg3 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId3,itemdata.entryId3)
	if not (entryCfg1 and entryCfg2 and entryCfg3) then
		return
	end

	local wire1 = CS.FindTrans(item,"Wire1")
	local wire2 = CS.FindTrans(item,"Wire2")
	local line1 = CS.FindTrans(wire1,"Line1")
	local line2 = CS.FindTrans(wire2,"Line2")
	local numText = CS.FindTrans(item,"NumBg/NumText")
	local rewardList1 = CS.FindTrans(item,"RewardList1")
	local rewardList2 = CS.FindTrans(item,"RewardList2")
	local rewardList3 = CS.FindTrans(item,"RewardList3")

	CS.ShowObject(wire1,itempos ~= 1)
	CS.ShowObject(wire2,itempos ~= self._maxItemNum)

	local curValue = tonumber(entryCfg1.name)
	self:SetWndText(numText, curValue)

	local status1 = itemdata.goalData.status
	local status2 = itemdata.goalData2.status
	local status3 = itemdata.goalData3.status
	local reward1List = LxDataHelper.ParseItem(entryCfg1.reward) or {}
	local InstanceID = item:GetInstanceID()
	for i, v in ipairs(reward1List) do
		v.index = self._boxEnum.COMMON
		v.status = status1
		v.rewardData = itemdata
	end

	local completeIndex = self._completeIndex or 0
	CS.ShowObject(line1, status1 >= 1)

	local isShowLine2 = itempos <= completeIndex
	if itempos == completeIndex then
		isShowLine2 = self._schedule - curValue > 30
	end
	CS.ShowObject(line2, isShowLine2)

	local uiList1 = self:GetUIScroll(InstanceID.."A")
	if(uiList1:GetList())then
		uiList1:RefreshList(reward1List)
	else
		uiList1:Create(rewardList1,reward1List,function (...) self:PassRewardListItem(...) end)
	end

	local reward2List = LxDataHelper.ParseItem(entryCfg2.reward) or {}
	for i, v in ipairs(reward2List) do
		v.index = self._boxEnum.ADVANCE
		v.status = status2
		v.rewardData = itemdata
	end
	local uiList2 = self:GetUIScroll(InstanceID.."B")
	if(uiList2:GetList())then
		uiList2:RefreshList(reward2List)
	else
		uiList2:Create(rewardList2,reward2List,function (...) self:PassRewardListItem(...) end)
	end

	local reward3List = LxDataHelper.ParseItem(entryCfg3.reward) or {}
	for i, v in ipairs(reward3List) do
		v.index = self._boxEnum.SUPER
		v.status = status3
		v.rewardData = itemdata
	end
	local uiList3 = self:GetUIScroll(InstanceID.."C")
	if(uiList3:GetList())then
		uiList3:RefreshList(reward3List)
	else
		uiList3:Create(rewardList3,reward3List,function (...) self:PassRewardListItem(...) end)
	end
end

function UIActPkE:PassRewardListItem(list, item, itemdata, itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local root = self:FindWndTrans(item,"itemRoot/Icon")
	local mask = self:FindWndTrans(item,"Mask")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local EffTrans = self:FindWndTrans(item,"Eff")

	local showEff = true
	local status  = itemdata.status
	local showCanGetEff = status == 1
	local showGou  = status == 2
	local rewardIndex = itemdata.index
	local showMask = false
	if rewardIndex == self._boxEnum.ADVANCE then
		showMask = not self._advanceBuy
		showCanGetEff = showCanGetEff and self._advanceBuy
	elseif rewardIndex == self._boxEnum.SUPER then
		showMask = not self._superBuy
		showCanGetEff = showCanGetEff and self._superBuy
	end
	CS.ShowObject(mask,showMask)

	if EffTrans then
		local show = false
		local instanceId = item:GetInstanceID()
		if itemdata.itemType == LItemTypeConst.TYPE_ITEM and showEff then
			local itemRef = gModelItem:GetRefByRefId(itemdata.itemId)
			local bgEff = itemRef and itemRef.bgEff or nil
			if not string.isempty(bgEff) then
				show = true
				self:CreateWndEffect(EffTrans,bgEff,instanceId,80,false,false)
			end
		end

		local effKey = self._itemGetEff..instanceId
		if showCanGetEff then
			show = true
			self:DestroyWndEffectByKey(effKey)
			self:CreateWndEffect(EffTrans,self._itemGetEff,effKey,60,false,false)
		else
			self:DestroyWndEffectByKey(effKey)
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
	baseClass:SetShowGouImg(showGou)
	baseClass:DoApply()
	self:SetWndText(itemNum,LUtil.NumberCoversion(itemdata.itemNum))
	self:SetIconClickScale(root, true)
	self:SetWndClick(root, function()
		self:OnClickPassGetItem(itemdata)
	end)
	self:SetWndLongClick(root,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end,0.2,true)
end

function UIActPkE:GetPriceStr(pageType)
	local data = self._activityCfg
	if not data then
		return ""
	end

	local str, id
	if pageType == UIActPkE.PAGE_ADVANCE then
		str = data.buttonprice1
		id = 1
	else
		str = data.buttonprice2
		id = 2
	end

	if string.isempty(str) then
		local entry = self._pages[UIActPkE.PAGE_BUY].entry[id]
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,entry.pageId,entry.entryId)
		local expend2 = tonumber(entryCfg.expend2)
		str = gModelPay:GetShowByWelfareId(expend2)
	end

	return str
end

function UIActPkE:CheckNeedQuick()
	if not self._quickBuyDay then
		return false
	end
	local time = GetTimestamp()
	local timespan = (self._endTime - time) / 86400
	local isOpen =  timespan <= self._quickBuyDay
	if not isOpen then
		return false
	end

	return self:CheckHaveNoGet()
end


function UIActPkE:GetShowPassRewardList(getEntryIdList) --检测是否显示特殊获得奖励弹窗
    --礼包已购买
    local buyType
    local buyIndex
    if not self._advanceBuy then
        buyType = UIActPkE.PAGE_ADVANCE
        buyIndex = 1
    elseif not self._superBuy then
        buyType = UIActPkE.PAGE_SUPER
        buyIndex = 2
    else
        return nil, nil
    end

    local list = {}
    --可以领取的进阶版奖励
    for i, v in ipairs(self._pages[buyType].entry) do
        local entryId = v.entryId
        if getEntryIdList[entryId] then
            local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,entryId)
            local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
            for p,q in ipairs(itemList) do
                local itemId = q.itemId
                if list[itemId] then
                    local oldItemNum = list[itemId].itemNum
                    list[itemId].itemNum = oldItemNum + q.itemNum
                else
                    list[itemId] = q
                end
            end
        end
    end


    --直购奖励
    local data = self._pages[UIActPkE.PAGE_BUY].entry[buyIndex]
    local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,data.pageId,data.entryId)
    local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
    for p,q in ipairs(itemList) do
        local itemId = q.itemId
        if list[itemId] then
            local oldItemNum = list[itemId].itemNum
            list[itemId].itemNum = oldItemNum + q.itemNum
        else
            list[itemId] = q
        end
    end

    local resultList = {}
    for k,v in pairs(list) do
        table.insert(resultList, v)
    end

    return resultList, buyIndex
end


function UIActPkE:OnTimer(key)
	if key == self._passKey then
		self:SetTime()
	end
end

function UIActPkE:CheckHaveNoGet()
	if not self._pages then
		return true
	end
	local eliteList = self._pages[UIActPkE.PAGE_ELITE].entry
	local haveNoGet = false
	for i, v in ipairs(eliteList) do
		local goalData	  	= v.goalData
		if(goalData.status == 0)then
			haveNoGet = true
			break
		end
	end

	return haveNoGet
end

function UIActPkE:OnClickGoOn()--前往
	if not self._jump then return end
	gModelFunctionOpen:Jump(self._jump,self:GetWndName())
end




--######################################################################################################################
--## Common ############################################################################################################
--######################################################################################################################
function UIActPkE:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config
	self._activityCfg = data


	self:InitTop()
	self:InitCentreTop()

	self._showItemDesc = data.showItemDesc
	self._taskDesc = data.taskDesc
	self._timeDes = data.timeDes
	self._jump = data.jump
	self._quickBuyDay = data.quickBuyDay

	gModelActivity:OnActivityPageReq(self._sid)
end

--######################################################################################################################
--## Pop ###############################################################################################################
--######################################################################################################################
function UIActPkE:ShowGiftPop(boxType) --显示礼包购买弹窗界面
	local buyPage = boxType == 1 and UIActPkE.PAGE_ADVANCE or UIActPkE.PAGE_SUPER

	self:OnClickBuyAdvance(buyPage)
end

function UIActPkE:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then
			return
		end
		self:OnActivityConfigData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			local sid = v.sid
			if sid == self._sid then
				self:RefreshData()
				return
			end
		end
	end)

	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (...) self:OnTargetWndClose(...) end)

	self:WndNetMsgRecv(LProtoIds.ActivityABCDRewardResp,function (pb)
		self:OnActivityABCDRewardResp(pb)
	end)
end

function UIActPkE:OnClickPassGetItem(itemData)
	gModelGeneral:ShowCommonItemTipWnd(itemData)
end

--#####################################################################################################################
--## Top ##############################################################################################################
--#####################################################################################################################
function UIActPkE:InitTop()
	local data = self._activityCfg
	if not data then return end

	local showHelp = data.helpTips == 1
	local pos = data.helpTipsPosition
	CS.ShowObject(self.mHelpBtn,showHelp)
	if showHelp and pos then
		self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty3(pos))
	end

	local path = data.image
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mBg,path,nil)
	end
	CS.ShowObject(self.mBg, true)

	local str
	local callHero			= data.callHero
	if callHero then
		local callHeroData 	= string.split(callHero, '=')
		local showType		= tonumber(callHeroData[1])
		local isShowHeroImg = showType == 1
		local showData = callHeroData[2]
		CS.ShowObject(self.mHeroImage, isShowHeroImg)
		CS.ShowObject(self.mHeroSpine, not isShowHeroImg)
		if isShowHeroImg then
			self:SetWndEasyImage(self.mHeroSpine, showData, nil, true)
		else
			self:CreateHeroSpine(showData)
		end

		local heroRefId = data.callHeroId
		self._heroRefId = heroRefId

		pos = data.callHeroPos
		if not string.isempty(pos) then
			self:SetAnchorPos(self.mHeroSpine, LxDataHelper.ParseVector2NotEmpty(pos))
		end

		local heroNameBgTrans = gLGameLanguage:IsForeignVersion() and self.mHeroNameBgEn or self.mHeroNameBg
		path = data.callHeroNameIcon
		if LxUiHelper.IsImgPathValid(path) then
			local heroNameImg = self:FindWndTrans(heroNameBgTrans, "Bg")
			self:SetWndEasyImage(heroNameImg, path)
		end
		CS.ShowObject(heroNameBgTrans, true)

		pos = data.callHeroNamePos
		if not string.isempty(pos) then
			self:SetAnchorPos(heroNameBgTrans, LxDataHelper.ParseVector2NotEmpty(pos))
		end

		local effectRef = gModelHero:GetShowEffectById(heroRefId)
		str = ""
		if effectRef then
			if heroRefId < 9999 then
				str = ccLngText(effectRef.name)
			else
				str = ccLngText(effectRef.skinName)
			end
		end

		local heroNameText = gLGameLanguage:IsForeignVersion() and self.mHeroNameTextEn or self.mHeroNameText
		self:SetWndText(heroNameText, str)
	end
end

function UIActPkE:OnClickHelp()--点击帮助
	local _sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	if not activityData then
		return
	end
	local data = activityData.config
	local title = gModelActivity:GetLngNameByActivitySid(_sid)
	local content = data.helpTipsContent
	GF.OpenWnd("UIBzTips",{title= title,text = content})
end

--#####################################################################################################################
--## CentreTop ########################################################################################################
--#####################################################################################################################
function UIActPkE:InitCentreTop()
	local data = self._activityCfg
	if not data then return end

	local str = data.listDesc
	self:SetWndText(self.mText0, str)

	str = data.buttonDesc1
	self:SetWndText(self.mText1, str)

	str = data.buttonDesc2
	self:SetWndText(self.mText2, str)
end

------------------------------------------------------------------
return UIActPkE


