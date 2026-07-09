---
--- Created by LCM.
--- DateTime: 2024/3/26 17:07:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActUpSagaGift:LWnd
local UIActUpSagaGift = LxWndClass("UIActUpSagaGift", LWnd)

UIActUpSagaGift.UPSTAR_REWARD = 1
UIActUpSagaGift.UPSTAR_GIFT = 2


UIActUpSagaGift.TYPE_BUY_FREE = 0		--免费购买
UIActUpSagaGift.TYPE_BUY_ITEM = 1		--道具购买
UIActUpSagaGift.TYPE_BUY_RMB = 2		--充值购买

UIActUpSagaGift.GET_REWARD_EFFNAME = "fx_ui_qiandao_lingqutishi"			-- 可领取特效
--UIActUpSagaGift.GET_REWARD_EFFNAME = "fx_daoju_orange"			-- 可领取特效
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActUpSagaGift:UIActUpSagaGift()
    self._timeKey = "_timeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActUpSagaGift:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActUpSagaGift:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActUpSagaGift:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
    gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActUpSagaGift:GetActivityList()
    local activityDataList = self._activityDataList
    if not activityDataList then return {} end

    local sid = self._sid
    local entryCfg

    local page1ActList = {}
    local page1List = activityDataList[UIActUpSagaGift.UPSTAR_REWARD] or {}
    local entry1List = page1List.entry or {}
    for i,v in ipairs(entry1List) do
        entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,v.entryId)
        if entryCfg then
            table.insert(page1ActList,self:GetCommonPageData(v,entryCfg))
        end
    end

    local page2ActList = {}
    local page2List = activityDataList[UIActUpSagaGift.UPSTAR_GIFT] or {}
    local entry2List = page2List.entry or {}
    for i,v in ipairs(entry2List) do
        entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,v.entryId)
        if entryCfg then
            table.insert(page2ActList,self:GetCommonPageData(v,entryCfg))
        end
    end

    local sortFunc = function(a,b)
        return a.sort < b.sort
    end
    table.sort(page1ActList,sortFunc)
    table.sort(page2ActList,sortFunc)


    local bigRewardList = {}
    local bigRewardMap = {}

    local recordBigRewardMap = {}
    local recordBigRewardDataMap = {}
    local recordBigRewardIndex = 1
    local actDataList = {}
    local entry2Data
    local data
    for i,v in ipairs(page1ActList) do
        entry2Data = page2ActList[i]
        if entry2Data then
            data = self:GetCommonActData(v,entry2Data)
            table.insert(actDataList,data)

            if data.showBigReward then
                recordBigRewardMap[recordBigRewardIndex] = i
                recordBigRewardDataMap[i] = data
                recordBigRewardIndex = recordBigRewardIndex + 1

                table.insert(bigRewardList,{
                    index = i,
                    bigRewardData = data,
                })

                bigRewardMap[i] = data
            end
        end
    end
    self._bigRewardList = bigRewardList
    self._bigRewardMap = bigRewardMap
    self._recordBigRewardDataMap = recordBigRewardDataMap

    local showNextBigRewardList = {}
    local showBigReward = #bigRewardList > 0
    if showBigReward then
        local curIndex = 2
        local showIndex
        for i,v in ipairs(actDataList) do
            showIndex = recordBigRewardMap[curIndex]
            if showIndex < i then
                local record = curIndex
                curIndex = curIndex + 1
                showIndex = recordBigRewardMap[curIndex]
                if not showIndex then
                    showIndex = recordBigRewardMap[record]
                    curIndex = record
                end
                showNextBigRewardList[i] = showIndex
            else
                showNextBigRewardList[i] = showIndex
            end
        end
    end
    self._showNextBigRewardList = showNextBigRewardList
    CS.ShowObject(self.mBigRewardDiv,showBigReward)

    return actDataList
end

function UIActUpSagaGift:InitActivitySuperList()
    local list = self:GetActivityList()
    self._allLen = #list

    local index
    for i,v in ipairs(list) do
        if v.status1 == ModelActivity.REWARD_STATUE_CAN_GET then
            if not index then
                index = i
            elseif i < index then
                index = i
            end
        end
    end
    if not index then
        index = 0
    end
    self._curIndex = index

    local uiActivityList = self._uiActivityList
    if uiActivityList then
        uiActivityList:RefreshList(list)
    else
        uiActivityList = self:GetUIScroll("mActivityWrapList")
        self._uiActivityList = uiActivityList
        uiActivityList:Create(self.mActivitySuperList,list,function(...) self:OnDrawActivityCell(...) end,UIItemList.SUPER)
    end
    uiActivityList:DrawAllItems()
    uiActivityList:MoveToPos(index)
end

function UIActUpSagaGift:RefreshEndTime()
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

function UIActUpSagaGift:GetCommonActData(entry1Data,entry2Data)
    local entryCfg1 = entry1Data.entryCfg
    local entryCfg2 = entry2Data.entryCfg

    local entry1MoreInfo = tonumber(entryCfg1.moreInfo) or 0
    local showBigReward = entry1MoreInfo == 1

    local goalData1 = entry1Data.goalData
    local goalData2 = entry2Data.goalData

    local MarketData1 = entry1Data.MarketData
    local MarketData2 = entry2Data.MarketData

    return {
        pageId1 = entry1Data.pageId,
        entryId1 = entry1Data.entryId,
        leftReward = self:GetRewardList(entryCfg1.reward),
        goalData1 = goalData1,
        status1 = goalData1.status,

        MarketData1 = MarketData1,
        personalGoal1 = MarketData1.personalGoal,
        personal1 = MarketData1.personal,
        name = entryCfg1.name,

        pageId2 = entry2Data.pageId,
        entryId2 = entry2Data.entryId,
        rightReward = self:GetRewardList(entryCfg2.reward),
        goalData2 = goalData2,
        status2 = goalData2.status,

        MarketData2 = MarketData2,
        personalGoal2 = MarketData2.personalGoal,
        personal2 = MarketData2.personal,
        name2 = entryCfg2.name,

        showBigReward = showBigReward
    }
end

function UIActUpSagaGift:InitActivityWrapList()
    local list = self:GetActivityList()
    self._allLen = #list

    local index = 0
    for i,v in ipairs(list) do
        if v.status1 == ModelActivity.REWARD_STATUE_CAN_GET or v.status2 == ModelActivity.REWARD_STATUE_CAN_GET then
            if i > index then
                index = i
            end
        end
    end
    self._curIndex = index

    local uiActivityList = self._uiActivityList
    if uiActivityList then
        uiActivityList:RefreshList(list)
    else
        uiActivityList = self:GetUIScroll("mActivityWrapList")
        self._uiActivityList = uiActivityList
        uiActivityList:Create(self.mActivityWrapList,list,function(...) self:OnDrawActivityCell(...) end,UIItemList.WRAP,false)
    end
    local uiList = uiActivityList:GetList()
    if uiList then
        index = index - 4
        if index < 1 then
            index = 0
        end
        uiList:RefreshList(UIListWrap.RefreshMode.Custom,index)
    end
end

function UIActUpSagaGift:InitMsg()

    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
    self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp,function(pb) self:OnActivityListResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb) self:OnActivityPageResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.ActivityABCDRewardResp,function (pb) self:OnActivityABCDRewardResp(pb) end)

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIActUpSagaGift:OnActivityListResp(pb)
    local sid = self._sid
    local activities = pb.activities
    for i, v in ipairs(activities) do
        if v.sid == sid then
            gModelActivity:ReqActivityConfigData(sid)
            break
        end
    end
end

function UIActUpSagaGift:GetRecordBigRewardData(index)
    local recordBigRewardDataMap = self._recordBigRewardDataMap
    if not recordBigRewardDataMap then return end
    return recordBigRewardDataMap[index]
end

function UIActUpSagaGift:InitEvent()
    self:SetWndClick(self.mSelAddBtn,function() self:OnClickSelAddBtnFunc() end)
    self:SetWndClick(self.mSelBtn,function() self:OnClickSelBtnFunc() end)
    self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtnFunc() end)
    self:SetWndClick(self.mBuyBtn,function() self:OnClickBuyBtnFunc() end)
    self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIActUpSagaGift:SetActivityCell(item,itemdata,itempos)
    local CenterDivTrans = self:FindWndTrans(item,"CenterDiv")

    local SelImgTrans = self:FindWndTrans(CenterDivTrans,"SelImg")

    local LeftRewradListTrans = self:FindWndTrans(CenterDivTrans,"LeftRewradList")
    local LeftRewradMoreListTrans = self:FindWndTrans(CenterDivTrans,"LeftRewradMoreList")
    local RightRewradListTrans = self:FindWndTrans(CenterDivTrans,"RightRewradList")
    local RightRewradMoreListTrans = self:FindWndTrans(CenterDivTrans,"RightRewradMoreList")

    local TopBgTrans = self:FindWndTrans(CenterDivTrans,"TopBg")
    local TopShowBgTrans = self:FindWndTrans(TopBgTrans,"TopShowBg")

    local BotBgTrans = self:FindWndTrans(CenterDivTrans,"BotBg")
    local BotShowBgTrans = self:FindWndTrans(BotBgTrans,"BotShowBg")

    local NameBgTrans = self:FindWndTrans(CenterDivTrans,"NameBg")
    local SelNameBgTrans = self:FindWndTrans(NameBgTrans,"SelNameBg")
    local NameTrans = self:FindWndTrans(NameBgTrans,"Name")

    local BtnRootTrans = self:FindWndTrans(CenterDivTrans,"BtnRoot")
    local BtnYellow3Trans = self:FindWndTrans(BtnRootTrans,"BtnYellow3")

    local ShowEndImgTrans = self:FindWndTrans(CenterDivTrans,"ShowEndImg")

    local status1 = itemdata.status1
    local status2 = itemdata.status2
    local showSel = status1 == ModelActivity.REWARD_STATUE_CAN_GET or status2 == ModelActivity.REWARD_STATUE_CAN_GET
    CS.ShowObject(SelImgTrans,showSel)
    CS.ShowObject(SelNameBgTrans,showSel)

    self:SetWndText(NameTrans,itemdata.name)

    local leftReward = self:DisposeRewardList(itemdata.leftReward,{
        pageId = itemdata.pageId1,
        entryId = itemdata.entryId1,
        status = status1,
        target = 1,
    })
    local leftLen = #leftReward
    local leftMoreStatus = leftLen > 1
    local leftShowTrans = leftMoreStatus and LeftRewradMoreListTrans or LeftRewradListTrans
    local leftHideTrans = leftMoreStatus and LeftRewradListTrans or LeftRewradMoreListTrans
    CS.ShowObject(leftShowTrans,true)
    CS.ShowObject(leftHideTrans,false)
    self:InitRewardList(leftShowTrans,leftReward)

    local personalGoal2 = itemdata.personalGoal2
    local personal2 = itemdata.personal2
    local last = personalGoal2 - personal2
    local showEndImg = last < 1


    local rightStatus = ModelActivity.REWARD_STATUE_COMMON
    if status1 == ModelActivity.REWARD_STATUE_CAN_GET or status1 == ModelActivity.REWARD_STATUE_HAD_GET then
        if showEndImg then
            rightStatus = ModelActivity.REWARD_STATUE_HAD_GET
        else
            rightStatus = 4
        end
    end
    local rightReward = self:DisposeRewardList(itemdata.rightReward,{
        pageId = itemdata.pageId2,
        entryId = itemdata.entryId2,
        status = rightStatus,
        target = 2,
    })
    local rightLen = #rightReward
    local rightMoreStatus = rightLen > 3
    local rightShowTrans = rightMoreStatus and RightRewradMoreListTrans or RightRewradListTrans
    local rightHideTrans = rightMoreStatus and RightRewradListTrans or RightRewradMoreListTrans
    CS.ShowObject(rightShowTrans,true)
    CS.ShowObject(rightHideTrans,false)
    self:InitRewardList(rightShowTrans,rightReward)

    local curIndex = self._curIndex or 0
    local showTop = itempos and itempos > 1 or false
    if showTop then
        local showTopShow = itempos <= curIndex
        CS.ShowObject(TopShowBgTrans,showTopShow)
    end
    CS.ShowObject(TopBgTrans,showTop)

    local showBot = itempos and itempos < self._allLen or false
    if showBot then
        local showBotShow = itempos <= curIndex
        CS.ShowObject(BotShowBgTrans,showBotShow)
    end
    CS.ShowObject(BotBgTrans,showBot)

    CS.ShowObject(ShowEndImgTrans,showEndImg)

    local showBtnStatus = not showEndImg
    if showBtnStatus then
        local MarketData2 = itemdata.MarketData2
        local expend2 = tonumber(MarketData2.expend2)
        local str = gModelPay:GetShowByWelfareId(expend2)
        self:SetWndButtonText(BtnYellow3Trans,str)
        self:SetWndClick(BtnYellow3Trans,function()
            self:OnClickBtnYellow3Func(itemdata)
        end)
        local isGray = status1 == ModelActivity.REWARD_STATUE_COMMON
        self:SetWndButtonGray(BtnYellow3Trans,isGray)
    end
    CS.ShowObject(BtnRootTrans,showBtnStatus)

    if self._cellBg and LxUiHelper.IsImgPathValid(self._cellBg) then
        local CenterBgTrans = self:FindWndTrans(CenterDivTrans,"Bg")
        self:SetWndEasyImage(CenterBgTrans,self._cellBg)
    end
end

function UIActUpSagaGift:InitData()
    local sid = self:GetWndArg("sid")
    local subPage = self:GetWndArg("subPage")
    if subPage then
        sid = gModelActivity:GetSidByUniqueJump(subPage)
    end
    self._sid = sid
end

function UIActUpSagaGift:OnDrawRewardCell(list,item,itemdata,itempos)
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

    local status = itemdata.status
    local target = itemdata.target

    local showLock = status == 0
    local showSel = status == 1
    local showGou = status == 2
    local showOnlyMask = status == 4
    --优化需求 #11761
    --【后台活动】模板4103升星弹框显示优化
    local maskImgCom = self:GetCanvasGroup(MaskBgTrans)
    if(maskImgCom)then
        maskImgCom.alpha = 1
    end
    if(status == 0 and target == 1)then
        showLock = false
    elseif(status == 0 and target == 2)then
        showOnlyMask = true
        showLock = false
        if(maskImgCom)then
            maskImgCom.alpha = 0.5
        end
    elseif(status == 4 and target == 2)then
        showOnlyMask = false
    end
    -------------------------------------
    CS.ShowObject(SelImgTrans,showSel)
    CS.ShowObject(GouTrans,showGou)
    CS.ShowObject(LockTrans,showLock)

    local showRedPointStatus = false
    if self._showRedPoint then
        showRedPointStatus = showSel
    end
    CS.ShowObject(redPointTrans,showRedPointStatus)

    local showEffStatus = showSel
    if self._showEff and showEffStatus then
        local effName = self._getRewardEffName or UIActUpSagaGift.GET_REWARD_EFFNAME
        local effKey = EffRootTrans:GetInstanceID()
        self:CreateWndEffect(EffRootTrans,effName,effKey,100)
        CS.ShowObject(SelImgTrans,false)
    end
    CS.ShowObject(EffRootTrans,showEffStatus)

    local showMask = showLock or showGou or showOnlyMask
    CS.ShowObject(MaskBgTrans,showMask)


    self:SetWndClick(BtnTrans,function()
        self:OnClickRewardItemFunc(itemdata)
    end)
end

function UIActUpSagaGift:ShowBigReward(index)
    local data = self:GetRecordBigRewardData(index)
    if not data then return end
    self:SetActivityCell(self.mBigRewardDiv,data)
end

function UIActUpSagaGift:OnDrawActivityCell(list,item,itemdata,itempos)
    self:SetActivityCell(item,itemdata,itempos)
    local showNextBigRewardList = self._showNextBigRewardList
    if not showNextBigRewardList then return end
    local index = showNextBigRewardList[itempos]
    if not index then return end
    if index == self._showIndex then
        self:ShowBigReward(index)
        return
    end
    local data = self:GetRecordBigRewardData(index)
    if not data then return end
    self._showIndex = index
    self:ShowBigReward(index)
end
function UIActUpSagaGift:OnActivityConfigData(data,sid)
    if sid ~= self._sid then return end

    self:TimerStop(self._timeKey)

	local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityWebData then return end
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

    self._endTime = tonumber(activityData.endTime)


    local moreInfo = JSON.decode(activityData.moreInfo)

    local buyPassNumList = {}
    local buyPassNum = string.split(moreInfo.buyPassNum,",")
    for i,v in ipairs(buyPassNum) do
        v = tonumber(v)
        table.insert(buyPassNumList,{
            buyPass = v,
        })
    end
    self._buyPassNumList = buyPassNumList

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
        getRewardEffName = UIActUpSagaGift.GET_REWARD_EFFNAME
        if LOG_INFO_ENABLED then
            printInfoNR("特效名字，配置 getRewardEffName 字段，默认 getRewardEffName = " .. UIActUpSagaGift.GET_REWARD_EFFNAME)
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

    local upStarImage = config.upStarImage
    if LxUiHelper.IsImgPathValid(upStarImage) then
        self:SetWndEasyImage(self.mTopImg,upStarImage,function()
            CS.ShowObject(self.mTopImg,true)
        end,true)
    end

    local upStarTitle = config.upStarTitle
    if LxUiHelper.IsImgPathValid(upStarTitle) then
        self:SetWndEasyImage(self.mActTxtImg,upStarTitle,function()
            CS.ShowObject(self.mActTxtImg,true)
        end,true)
    end
    self:SetAnchorPos(self.mActTxtImg, LxDataHelper.ParseVector2NotEmpty(config.upStarTitlePos))

    self._helpTipsTitle = activityData.title
    self._upStarHelpDes = config.upStarHelpDes

    local helpTips = tonumber(config.helpTips) or 0
    local showHelpTips = helpTips == 1
    if showHelpTips then
        self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(config.upStarHelpPos))
    end
    CS.ShowObject(self.mHelpBtn,showHelpTips)

    self:SetAnchorPos(self.mTimeBg, LxDataHelper.ParseVector2NotEmpty(config.upStarTimePos))

    self._upStarBtnJump = config.upStarBtnJump

    local upStarDes = config.upStarDes
    self:SetWndText(self.mActDesc,upStarDes)
    self:SetAnchorPos(self.mActDesc, LxDataHelper.ParseVector2NotEmpty(config.showItemDescPosition))


    local jumpIcon = config.jumpIcon
    if not string.isempty(jumpIcon) then
        self:SetWndButtonImg(self.mBuyBtn,jumpIcon)

        local mat = LUtil.GetOutlineMatByImg(jumpIcon)
        self:SetWndButtonTextMat(self.mBuyBtn,mat)
    end

    self:SetWndButtonText(self.mBuyBtn,config.upStarBtnText)
    self:SetAnchorPos(self.mBtnShowDiv, LxDataHelper.ParseVector2NotEmpty(config.upStarBtn))



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

    local selectOpen = tonumber(config.selectOpen) or 0
    local isSelectOpen = selectOpen == 1
    local isAppointHero = selectOpen == 2
    local selectHeroList = {}
    local selectChangeHeroItemList = {}
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
            self._select = tonumber(config.appointHero)
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
    CS.ShowObject(self.mCanSelHeroDiv,isSelectOpen)

    local imageHeroPos = config.imageHeroPos
    self:SetAnchorPos(self.mActPersonImg, LxDataHelper.ParseVector2NotEmpty(imageHeroPos))
    self:SetAnchorPos(self.mHerpSp, LxDataHelper.ParseVector2NotEmpty(imageHeroPos))


    self._selectOpen = selectOpen
    self._isSelectOpen = isSelectOpen
    self._selectHeroList = selectHeroList
    self._selectChangeHeroItemList = selectChangeHeroItemList

    local bg = config.bg
    if LxUiHelper.IsImgPathValid(bg) then
        self:SetWndEasyImage(self.mActBg,bg,function()
        end,true)
    end
    local titleBg = config.titleBg
    if LxUiHelper.IsImgPathValid(titleBg) then
        self:SetWndEasyImage(self.mListTipBg,titleBg,function()
        end,true)
    end
    local cellListBg = config.cellListBg
    if LxUiHelper.IsImgPathValid(cellListBg) then
        self:SetWndEasyImage(self.mCellBg,cellListBg,function()
            self:ChangeImgEnable(self.mCellBg,true)
        end,true)
    else
        self:ChangeImgEnable(self.mCellBg,false)
    end
    local line = config.line
    if LxUiHelper.IsImgPathValid(line) then
        self:SetWndEasyImage(self.mLine,line,function()
        end)
    end
    local noSelHeroImgPath = config.silhouette
    local noSelHeroImgPos = config.silhouettePos
    if LxUiHelper.IsImgPathValid(noSelHeroImgPath) then
        self:SetWndEasyImage(self.mNoSelHeroImg,noSelHeroImgPath,function()
        end,true)
    end
    self:SetAnchorPos(self.mHerpSp, LxDataHelper.ParseVector2NotEmpty(noSelHeroImgPos))
    self._cellBg = config.cellBg

    --self._cellTextBg = config.cellTextBg

    self:RefreshSelectHero()

    gModelActivity:OnActivityPageReq(sid)
end
function UIActUpSagaGift:ChangeImgEnable(trans,enabled)
    local uiImage = self:GetUIImage(trans)
    if not uiImage then return end
    uiImage.enabled = enabled
end

function UIActUpSagaGift:OnActivityABCDRewardResp(pb)
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

function UIActUpSagaGift:OnClickHelpBtnFunc()
    if not self._helpTipsTitle or not self._upStarHelpDes then return end
    GF.OpenWnd("UIBzTips",{title= self._helpTipsTitle,text = self._upStarHelpDes})
end

function UIActUpSagaGift:RefreshSelectHero()
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
------------------------- List -------------------------

function UIActUpSagaGift:GetCommonPageData(serverData,cfgData)
    return {
        entryCfg = cfgData,
        goalData = serverData.goalData,
        MarketData = serverData.MarketData,
        pageId = serverData.pageId,
        entryId = serverData.entryId,
        sort = cfgData.sort,
        entry = serverData
    }
end

function UIActUpSagaGift:OnActivityPageResp(pb)
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
    self:InitActivitySuperList()
end

function UIActUpSagaGift:OnClickBtnYellow3Func(itemdata)
    if itemdata.status1 == ModelActivity.REWARD_STATUE_COMMON then
        return
    end
    local personalGoal2 = itemdata.personalGoal2
    local personal2 = itemdata.personal2
    local last = personalGoal2 - personal2
    if last < 1 then return end
    local MarketData2 = itemdata.MarketData2
    local expend2 = MarketData2.expend2
    local expend2Info = string.split(expend2,"=")
    local expendType
    if expend2 == "" then
        expendType = UIActUpSagaGift.TYPE_BUY_FREE
    else
        local len = #expend2Info
        local isFree = expend2Info[1] and expend2Info[1] == "-1" or false
        if isFree then
            expendType = UIActUpSagaGift.TYPE_BUY_FREE
        else
            if len > 1 then
                expendType = UIActUpSagaGift.TYPE_BUY_ITEM

            else
                expendType = UIActUpSagaGift.TYPE_BUY_RMB
            end
        end
    end
    local pageId2 = itemdata.pageId2
    local entryId2 = itemdata.entryId2
    local callFunc
    local setTextStr
    local itemId
    local isFreeBuy = false
    if expendType == UIActUpSagaGift.TYPE_BUY_FREE then
        isFreeBuy = true
        setTextStr = ccClientText(11913)
        callFunc = function()
            gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId2,entryId2)
        end
    elseif expendType == UIActUpSagaGift.TYPE_BUY_ITEM then
        itemId = tonumber(expend2Info[2])
        setTextStr = tonumber(expend2Info[3])
        callFunc = function()
            local dia = gModelItem:GetNumByRefId(itemId)
            local itemName = gModelItem:GetNameByRefId(itemId)
            local value = tonumber(expend2Info[3])
            -- 钻石购买
            local func = function()
                if dia >= value then
                    gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId2,entryId2)
                else
                    gModelGeneral:OpenGetWayWnd({itemId = itemId})
                end
            end
            GF.OpenWnd("UIOrdinTip",{refId = 110005,func = func,para = {value .. itemName},consume = {value, itemId}})
        end
    elseif expendType == UIActUpSagaGift.TYPE_BUY_RMB then
        expend2 = tonumber(expend2)
        setTextStr = gModelPay:GetShowByWelfareId(expend2)
        callFunc = function()
            gModelPay:GiftPayCtrl(entryId2,expend2,ModelPay.PAY_TYPE_ACTIVITY,nil,self._sid,pageId2)
        end
    end

    local itemList = gModelActivity:GetSelectOpenCommonReward(self._sid,itemdata.rightReward)

    local buyCountText = string.replace(ccClientText(23202), last)
    GF.OpenWnd("UIGiftBuyPop", {
        title = itemdata.name2,
        desc = buyCountText,
        payStr = setTextStr,
        payItemId = not isFreeBuy and itemId or nil,
        payFunc = callFunc,
        itemList = itemList,
        sid = self._sid
    })

end

function UIActUpSagaGift:OnClickSelBtnFunc()
    if not self._isSelectOpen then return end
    --gModelGolem:OpenGolemSwitchHero({
    --    wndType = 2,
    --    actHeroList = self._selectHeroList,
    --    sid = self._sid,
    --    actType = ModelActivity.SELECT_HERO_UP_STAR,
    --})
end

function UIActUpSagaGift:OnActivityResp(pb)
	if self._sid ~= pb.sid then return end
    gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActUpSagaGift:OnClickSelAddBtnFunc()
end

function UIActUpSagaGift:InitRewardList(trans,list)
    local key = trans:GetInstanceID()
    local uiRewardList = self:FindUIScroll(key)
    if uiRewardList then
        uiRewardList:RefreshList(list)
    else
        uiRewardList = self:GetUIScroll(key)
        uiRewardList:Create(trans,list,function(...) self:OnDrawRewardCell(...) end)
    end
end

function UIActUpSagaGift:DisposeRewardList(rewardList,info)
    rewardList = rewardList or {}
    local pageId = info.pageId
    local entryId = info.entryId
    local status = info.status
    local target = info.target
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
        })
    end
    return list
end

function UIActUpSagaGift:OnClickBuyBtnFunc()
    local upStarBtnJump = self._upStarBtnJump
    if not upStarBtnJump then
        if LOG_INFO_ENABLED then
            printInfoNR("upStarBtnJump 字段为空")
        end
        return
    end
    if gModelFunctionOpen:CheckIsOpened(upStarBtnJump,true) then
        gModelFunctionOpen:Jump(upStarBtnJump,self:GetWndName())
    end
end

function UIActUpSagaGift:GetRewardList(reward)
    if self._selectOpen and self._selectOpen == ModelActivity.TYPE_SELECTOPEN_1 and self._isSelectHero then
        local selectChangeHeroItemList = self._selectChangeHeroItemList or {}
        local select = self._select
        local changeHeroItem = selectChangeHeroItemList[select]
        if not changeHeroItem then
            if LOG_INFO_ENABLED then
                printInfoNR("找不到英雄对应配置的道具 select = " .. select)
            end
        end
        local rewardList = LxDataHelper.ParseItem(reward) or {}
        local list = {}
        local transitionItem = self._transitionItem
        if not transitionItem then
            if LOG_INFO_ENABLED then
                printInfoNR("找不到对应配置的道具 transitionItem 字段")
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
        return LxDataHelper.ParseItem(reward) or {}
    end
end

function UIActUpSagaGift:OnClickRewardItemFunc(itemdata)
    if self._isSelectOpen and not self._isSelectHero then
        GF.ShowMessage(ccClientText(36102))
        return
    end
    local status = itemdata.status
    local showSel = status == 1
    if showSel then
        gModelActivity:OnActivityReceiveGoalReq(self._sid,itemdata.pageId,itemdata.entryId)
    else
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIActUpSagaGift



