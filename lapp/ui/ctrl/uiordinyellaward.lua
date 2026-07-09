---
--- Created by Administrator.
--- DateTime: 2023/10/15 16:08:02
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOrdinYellAward:LWnd
local UIOrdinYellAward = LxWndClass("UIOrdinYellAward", LWnd)

UIOrdinYellAward.TYPE_ACTIVITY = 1                -- 活动格式
UIOrdinYellAward.TYPE_DEFAULT = 2                -- 设置格式

UIOrdinYellAward.TYPE_PAY_DIAMOND = 1                    -- 钻石
UIOrdinYellAward.TYPE_PAY_ITEM = 2                        -- 道具
UIOrdinYellAward.TYPE_PAY_FREE = 3                        -- 免费

UIOrdinYellAward.CALL_NUM_ONE = 1
UIOrdinYellAward.CALL_NUM_TEN = 10

UIOrdinYellAward.MIN_HREO_NUM = 5
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOrdinYellAward:UIOrdinYellAward()
    self._runAniKey = "runAniKey"
    self._aniRunTime = 2.5
    self._modelPageId2List = {
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = ModelActivity.SWEET_COUNTRY_7,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_96] = ModelActivity.MOTIF_ACTIVITY_LOTTERY_1,
    }
    self._modelLotteryList = {
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = ModelActivity.SWEETS_COUNTRY_LOTTERY,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_96] = ModelActivity.DROP_REWARD_LOTTERY,
    }
    self._modelPageIdList = {
        -- [ModelActivity.BAND_THEME] = ModelActivity.BAND_THEME_TURN_TABLE,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_57] = ModelActivity.NEWYEAR2022_ITEM_4,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_66] = ModelActivity.MAGIC_ACADEMY4,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_67] = ModelActivity.HAPPY_COUNTRY_7,
        [ModelActivity.MODEL_ACTIVITY_TYPE_68] = ModelActivity.KING_STREET_3,
        -- [ModelActivity.SUMMER_DAY] = ModelActivity.BAND_THEME_TURN_TABLE,

    }

    ---@type StructActLotteryInfo
    self._actLotteryInfo = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOrdinYellAward:OnWndClose()
    local closeWndFunc = self:GetWndArg("closeWndFunc")
    if closeWndFunc then
        closeWndFunc()
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOrdinYellAward:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOrdinYellAward:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:SetWndButtonText(self.mEnterBtn, ccClientText(10102))

    self:InitEvent()
    self:InitMsg()
    self:InitData()

    self:OnWndRefresh()
end

function UIOrdinYellAward:RefreshDesc()
    local fixedData = self._fixedReward
    if fixedData then
        local itemId = checknumber(fixedData.refId or fixedData.itemId)
        local itemNum = checknumber(fixedData.num or fixedData.itemNum)
        local fixName, fixNum = gModelItem:GetNameByRefId(itemId),itemNum
        local str = string.replace(ccClientText(11619), fixName, fixNum)
        self:SetWndText(self.mDescTxt, str)
    end
end

function UIOrdinYellAward:PlayUpHeroWndList()
    self:ShowHeroUpStar()
end

function UIOrdinYellAward:OnCommonActClick()
    local _actModel = self._actModel
    local _sid = self._sid
    local _callNum = self._callNum or 0
    local pageId = self._modelPageId2List[_actModel]
    local activityCfg = gModelActivity:GetWebActivityDataById(_sid)
    if not activityCfg then return end
    if pageId then
        local _lotteryEnum = self._modelLotteryList[_actModel]
        gModelActivity:SendActivityCallReq2(_sid, pageId, _callNum == 1 and 1 or 2, self:GetWndName(), _lotteryEnum)
        return
    end
    pageId = self._modelPageIdList[_actModel]
    gModelActivity:GetCallDataBySid(_sid, pageId, _callNum == 1 and 1 or 2, self:GetWndName())
end

function UIOrdinYellAward:InitEvent()
    self:SetWndClick(self.mEnterBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mAgainBtn, function()
        self:OnClickAgainFunc()
    end)
    self:SetWndClick(self.mEffectBg, function()
        CS.ShowObject(self.mEffectBg, false)
        self:OnClickEffectBg()
    end)
end

--function UIOrdinYellAward:RefreshDefaultView()
--
--end
function UIOrdinYellAward:OnTcpReconnect()
    self:WndClose()
end

function UIOrdinYellAward:InitMsg()
    self:WndNetMsgRecv(LProtoIds.HeroSacrificeResp, function(pb, ret)
        self._canGo = false
    end)
    self:WndEventRecv(EventNames.ON_JUMP, function(...)
        self:WndClose()
    end)
    self:WndEventRecv(EventNames.ON_ACTLOTTERYINFO, function(...) self:OnActLotteryInfo(...) end)
end

function UIOrdinYellAward:IsEnough()
    local enough = false
    local payItemRefId = self._payItemRefId
    local payItemNum = self._payItemNum
    if payItemRefId and payItemNum then
        local haveNum = gModelItem:GetNumByRefId(payItemRefId)
        enough = haveNum >= payItemNum
    end
    if not enough then
        GF.OpenWndTop("UIGeay", { itemId = payItemRefId, srcWnd = self:GetWndName() })
    end
    return enough
end

function UIOrdinYellAward:InitPayItemList(list)
    list = list or {}
    local uiPayItemList = self._uiPayItemList
    if uiPayItemList then
        uiPayItemList:RefreshList(list)
    else
        uiPayItemList = self:GetUIScroll("uiPayItemList")
        self._uiPayItemList = uiPayItemList
        uiPayItemList:Create(self.mPayItemList, list, function(...)
            self:OnDrawPayItemCell(...)
        end)
    end
end

function UIOrdinYellAward:OnTimer(key)
    if key == self._runAniKey then
        self:PlayUpHeroWndList()
    end
end

function UIOrdinYellAward:OnTryTcpReconnect()
    self:WndClose()
end
function UIOrdinYellAward:OnWndRefresh()
    self:InitWndPara()
    self:RefreshView()
end

function UIOrdinYellAward:OnClickEffectBg()
    self:TimerStop(self._runAniKey)
    if self._aniFunc then
        self._aniFunc()
    end
end

function UIOrdinYellAward:InitData()
    --local showType = self:GetWndArg("showType")
    --if showType == nil then
    --	showType = UIOrdinYellAward.TYPE_ACTIVITY
    --end
    --self._showType = showType

    self._payItemRefId = nil
    self._payItemNum = nil
    self._payTpye = nil
    self._lastGoldCallTimes = nil

    self._aniFunc = function()
        self:PlayUpHeroWndList()
    end

    self._heroEffectList = {
        [4] = "fx_ui_yingxiong_purple",
        [5] = "fx_ui_yingxiong_yellow",
    }

    --self._canGo = gModelHero:GetAutoSacrificeStatus()
end

function UIOrdinYellAward:InitWndPara()
    self._itemList = self:GetWndArg("itemList") or {}
    self._sid = self:GetWndArg("sid")
    self._callNum = self:GetWndArg("callNum")
    self._fixedReward = self:GetWndArg("fixedReward")
    self._jumpAni = self:GetWndArg("jumpAni")
end

function UIOrdinYellAward:OnClickActivityCall()
    local _actModel = self._actModel
    if _actModel == ModelActivity.MODEL_ACTIVITY_TYPE_166 then
        self:OnAct166Click()
    else
        self:OnCommonActClick()
    end
end

function UIOrdinYellAward:RefreshActivityView()
    --local sid = self:GetWndArg("sid")
    local sid = self._sid --self._sid = sid
    --local callNum = self:GetWndArg("callNum")
    --local callNum = self._callNum --= callNum

    local webData = gModelActivity:GetWebActivityDataById(sid)
    if not webData then
        return
    end
    local activityData = gModelActivity:GetActivityBySid(sid)
    if not activityData then
        return
    end

    local model = activityData.model
    self._actModel = model

    local config = webData.config

    self._btnTextList = {}
    local btnText = string.split(config.callAgainBtnTxt or config.btnText, "=")
    for i, v in ipairs(btnText) do
        table.insert(self._btnTextList, v)
    end

    if model == ModelActivity.MODEL_ACTIVITY_TYPE_166 then
        gModelActivity:OnActLotteryInfoReq(sid,ModelActivity.PAGE_ACTIVITY_166_CALL)

        self:RefreshAct166View(webData,activityData)
    else
        local moreInfo = JSON.decode(activityData.moreInfo)
        self:DisposeActivityMoreInfo(moreInfo)

        self._goldConfigTimes = config.goldTimes
        self._goldCallTimes = moreInfo.callNum
        local last
        if moreInfo.remainBuyNum then
            last = moreInfo.remainBuyNum
        else
            local alreadyCallNum = moreInfo.callNum or 0
            local goldTimes = moreInfo.goldTimes or 0
            last = goldTimes - alreadyCallNum
        end
        self._lastGoldCallTimes = last

        local desTips = config.callDiamondTips or ccClientText(20809)
        local str = string.replace(desTips, last)
        self:SetWndText(self.mCallNumDescTxt, str)

        local viewInfo = {
            showBg = moreInfo.showBg,
            effectBg = moreInfo.effectBg,
            --effectName = moreInfo.effectName or "fx_xyzh_zhaohuan",
            effectName = moreInfo.effectName or "fx_ui_xinyuanzhaohuan_120",
            titleImg = moreInfo.titleImg,
            titleEffectName = moreInfo.titleEffectName or "fx_ui_gongxihuode",
            --soundEffect = moreInfo.soundEffect or LSoundConst.TRIGGER_CALL_MIRROR
            soundEffect = moreInfo.soundEffect or LSoundConst.TRIGGER_CALL_MIRROR
        }

        --龙珠的召唤特效
        local templateType =self:GetWndArg("templateType")

        if templateType == 1 then
            viewInfo.effectName= "fx_ui_h120_aichongzhaohuan"
        end

        if templateType == 2 then
            viewInfo.effectName= "fx_yu_h120_longwenzhaohuan"
        end

        --
        local config = self:GetWndArg("config")
        if config.callBg1 then
            viewInfo.showBg=config.callBg1
            viewInfo.effectBg=config.callBg1

            self:SetWndEasyImage(self.EffectBg_2,config.callBg1,function()
                CS.ShowObject(self.EffectBg_2,true)
            end)
        end

        self:SetViewShow(viewInfo)
        if not self._jumpAni then
            self._aniRunTime = moreInfo.aniRunTime or self._aniRunTime
        else
            self._aniRunTime = 0
        end

        self._tipRefId = config.tipRefId
        self._goodsData = {
            config.goodsOne, -- --抽1次购买的道具和数量
            config.goodsTen, -- --抽10次购买的道具和数量
        }

        --重新设置抽取的道具部分

        if model == ModelActivity.MODEL_ACTIVITY_TYPE_120 then
            local callInfo
            if self._callNum == UIOrdinYellAward.CALL_NUM_ONE then
                callInfo = self._callInfo[1]
            else
                callInfo = self._callInfo[2]
            end


            --120活动的抽取需要额外的特殊显示
            local leftTime = self._lastGoldCallTimes or moreInfo.goldTimes

            local payItemRefId
            local payItemNum

            local itemId = callInfo[1].itemId
            local itemNum = callInfo[1].itemNum

            local diamond = callInfo[2].itemId
            local diamondCallNum = callInfo[2].itemNum

            local haveNum = gModelItem:GetNumByRefId(itemId)

            if haveNum >= itemNum then
                --有道具优先道具
                payItemRefId = itemId
                payItemNum = itemNum
            elseif leftTime >= self._callNum then
                --剩余钻石次数是不是大于 显示钻石
                payItemRefId = diamond
                payItemNum = diamondCallNum
            else
                payItemRefId = itemId
                payItemNum = itemNum
            end
            local initPayItemList = {}

            table.insert(initPayItemList, {
                itemId = payItemRefId,
                itemNum = payItemNum
            })

            self:InitPayItemList(initPayItemList)
        end
    end
end

function UIOrdinYellAward:OnDrawPayItemCell(list, item, itemdata, itempos)
    local Icon = self:FindWndTrans(item, "Icon")
    local UIText = self:FindWndTrans(item, "UIText")

    local itemId = itemdata.itemId
    local itemNum = itemdata.itemNum

    --local haveNum = gModelItem:GetNumByRefId(itemId)
    --local haveEnought = haveNum >= itemNum
    --
    --if not haveEnought then
    --
    --    itemId = self._callInfo[2][2].itemId
    --    itemNum = self._callInfo[2][2].itemNum
    --end
    --

    local haveNum = gModelItem:GetNumByRefId(itemId)
    local color = haveNum >= itemNum and "lightGreen_new" or "red"

    local img = gModelItem:GetItemIconByRefId(itemId)
    self:SetWndEasyImage(Icon, img)


    -- if self._payTpye == UIOrdinYellAward.TYPE_PAY_ITEM and self._actModel == ModelActivity.MODEL_ACTIVITY_TYPE_72 then
    -- 	color = haveNum >= 1 and "green" or "red"
    -- 	itemNum = haveNum
    -- end

    local str = LUtil.FormatColorStr(haveNum, color)
    local newStr = string.format("%s/%s", str, itemNum)
    self:SetWndText(UIText, newStr)
end

function UIOrdinYellAward:RefreshView()
    self:RefreshActivityView()

    self:RefreshBtnTxt()
    self:RefreshDesc()
    self:RunAni()
end

function UIOrdinYellAward:RunAni()
    if not self._jumpAni then
        gLGameAudio:PlaySound("SoundS_27")

        self:ResetView(not self._jumpAni)
    end

    self:TimerStop(self._runAniKey)
    self:TimerStart(self._runAniKey, self._aniRunTime, true, 1)
end

function UIOrdinYellAward:RefreshAct166View(webData,actData)
    if not webData or not actData then return end


    local diamondCount = self:GetWndArg("diamondCount")
    local config = webData.config
    self:DisposeActivityMoreInfo(config,{
        freeNum = self:GetWndArg("freeCount"),
        diamondCount = diamondCount,
    })

    local callInfo
    if self._callNum == UIOrdinYellAward.CALL_NUM_ONE then
        callInfo = self._callInfo[1]
    else
        callInfo = self._callInfo[2]
    end

    local desTips = config.callDiamondTips or ccClientText(20809)
    local str = string.replace(desTips, diamondCount)
    self:SetWndText(self.mCallNumDescTxt, str)

    self._aniRunTime = 0

    local lotteryType = self:GetWndArg("lotteryType")
    if lotteryType and lotteryType ~= 3 then
        self._fixedReward = self:GetWndArg("fixedReward")
    end
    self._lotteryType = lotteryType


    --local tolCount = self:GetWndArg("tolCount")
end

function UIOrdinYellAward:OnActLotteryInfo(data,sid)
    if sid ~= self._sid then return end

    ---@type StructActLotteryInfo
    self._actLotteryInfo = data
end

function UIOrdinYellAward:DisposeActivityMoreInfo(moreInfo,extra)
    if not moreInfo then
        return
    end
    extra = extra or {}
    local callNum = self._callNum
    local freeNum = extra.freeNum or moreInfo.freeNum
    self._freeNum = freeNum

    local callInfo = {}
    --if callNum == UIOrdinYellAward.CALL_NUM_ONE then
    -- 单次召唤
    local single = {}
    local oneExpend
    if moreInfo.oneExpend then
        oneExpend = string.split(moreInfo.oneExpend, "|")
    else
        oneExpend = {
            moreInfo.costOne2, --道具
            moreInfo.costOne1, --钻石
        }
    end

    for i, v in ipairs(oneExpend) do
        v = string.split(v, "=")
        table.insert(single, {
            itemType = tonumber(v[1]),
            itemId = tonumber(v[2]),
            itemNum = tonumber(v[3]),
        })
    end
    --else
    -- 10次召唤
    local multi = {}
    local tenExpend
    if moreInfo.tenExpend then
        tenExpend = string.split(moreInfo.tenExpend, "|")
    else
        tenExpend = {
            moreInfo.costTen2, --道具
            moreInfo.costTen1, --钻石
        }
    end

    for i, v in ipairs(tenExpend) do
        v = string.split(v, "=")
        table.insert(multi, {
            itemType = tonumber(v[1]),
            itemId = tonumber(v[2]),
            itemNum = tonumber(v[3]),
        })
    end
    --end
    if callNum == UIOrdinYellAward.CALL_NUM_ONE then
        callInfo = single
    else
        callInfo = multi
    end


    local showCost = false
    local payItemRefId, payItemNum

    local initPayItemList = {}
    local payType = UIOrdinYellAward.TYPE_PAY_ITEM
    if freeNum > 0 and callNum == UIOrdinYellAward.CALL_NUM_ONE then
        payType = UIOrdinYellAward.TYPE_PAY_FREE
    else
        local model = self._actModel
        if model == ModelActivity.MODEL_ACTIVITY_TYPE_166 then
            local diamondCount = extra.diamondCount or 0
            local hasDiamond = diamondCount >= callNum

            local itemId,itemNum
            for i, v in ipairs(callInfo) do
                itemId = v.itemId
                itemNum = v.itemNum
                local haveNum = gModelItem:GetNumByRefId(itemId)
                if itemId ~= ModelItem.ITEM_DIAMOND then
                    if haveNum and haveNum >= itemNum then
                        payItemRefId, payItemNum = itemId, itemNum
                        showCost = true
                        break
                    end
                else
                    if hasDiamond then
                        payItemRefId, payItemNum = itemId, itemNum
                        showCost = true
                        break
                    end
                end
            end

            if not payItemRefId and not showCost then
                local payItem = callInfo[1]
                payItemRefId, payItemNum = payItem.itemId, payItem.itemNum
            end
        else
            local len = #callInfo
            local lastCallInfo = callInfo[len]

            for i, v in ipairs(callInfo) do
                local itemId = v.itemId
                local haveNum = gModelItem:GetNumByRefId(itemId)
                -- if (self._actModel == ModelActivity.MODEL_ACTIVITY_TYPE_72 and haveNum >= 1) or (haveNum >= itemNum) then
                -- 	payItemRefId,payItemNum = itemId,itemNum
                -- 	break
                -- end

                if itemId ~= ModelItem.ITEM_DIAMOND then
                    if haveNum then
                        payItemRefId, payItemNum = itemId, v.itemNum
                        showCost = true
                    end
                end
            end

            if not payItemRefId and lastCallInfo and not (showCost) then
                payItemRefId, payItemNum = lastCallInfo.itemId, lastCallInfo.itemNum
            end
        end
    end

    if payItemRefId and payItemNum then
        payType = payItemRefId == ModelItem.ITEM_DIAMOND and UIOrdinYellAward.TYPE_PAY_DIAMOND or UIOrdinYellAward.TYPE_PAY_ITEM
        table.insert(initPayItemList, {
            itemId = payItemRefId,
            itemNum = payItemNum
        })
        self._payItemRefId = payItemRefId
        self._payItemNum = payItemNum

    end

    self._callInfo = {}
    self._callInfo[1] = single
    self._callInfo[2] = multi

    self._payTpye = payType
    self:InitPayItemList(initPayItemList)
end

function UIOrdinYellAward:ResetView(show)
    if show == nil then
        show = true
    end
    CS.ShowObject(self.mEffectBg, show)
    CS.ShowObject(self.mTitleRoot, not show)
    --CS.ShowObject(self.mTitleImg,not show and self._haveTitleImage)
    CS.ShowObject(self.mInfoWnd, not show)
end

function UIOrdinYellAward:OnAct166Click()
    if not self._actLotteryInfo then return end

    local sid = self._sid
    local webData = gModelActivity:GetWebActivityDataById(sid)
    if not webData then return end

    local config = webData.config

    local actLotteryInfo = self._actLotteryInfo
    --- 钻石,道具
    local cost1,cost2
    local callNum = self._callNum
    if callNum == UIOrdinYellAward.CALL_NUM_ONE then
        if actLotteryInfo:CheckHasFree() then
            gModelActivity:OnActLotteryReq(sid,ModelActivity.PAGE_ACTIVITY_166_CALL,actLotteryInfo.round,1,3)
            return
        end
        cost1 = LxDataHelper.ParseItem_3(config.costOne1)
        cost2 = LxDataHelper.ParseItem_3(config.costOne2)
    else
        cost1 = LxDataHelper.ParseItem_3(config.costTen1)
        cost2 = LxDataHelper.ParseItem_3(config.costTen2)
    end
    if not cost1 or not cost2 then return end

    local diamondCount = self:GetWndArg("diamondCount") or 0
    local hasDiamond = diamondCount >= callNum

    local lotteryType = 2
    local cost = cost2
    if not gModelGeneral:CheckItemEnough(cost2.itemId,cost2.itemNum) then
        if hasDiamond then
            if gModelGeneral:CheckItemEnough(cost1.itemId,cost1.itemNum) then
                cost = cost1
                lotteryType = 1
            end
        end
    end
    if not gModelGeneral:CheckItemEnough(cost.itemId,cost.itemNum,true,self:GetWndName()) then
        return
    end
    gModelActivity:OnActLotteryReq(sid,ModelActivity.PAGE_ACTIVITY_166_CALL,actLotteryInfo.round,callNum,lotteryType)
end

function UIOrdinYellAward:ShowReward()

    self:ResetView(false)
    self:InitHeroList()
end

function UIOrdinYellAward:OnClickAgainFunc()
    local isAct = gModelActivity:GetActivityBySid(self._sid)
    if not isAct then
        return
    end
    --if self._canGo then return end
    --local showType = self._showType
    --if showType == UIOrdinYellAward.TYPE_ACTIVITY then
    self:OnClickActivityCall()
    --elseif showType == UIOrdinYellAward.TYPE_DEFAULT then
    --end
end

function UIOrdinYellAward:ShowHeroUpStar()
    local list = self._itemList or {}
    local upHeroList = {}
    for i, v in ipairs(list) do
        local itype = v.itype
        if itype == LItemTypeConst.TYPE_HERO then
            local heroRefId = v.refId
            local initStar = gModelHero:GetHeroInitStarByRefId(heroRefId)
            if initStar > 4 then
                table.insert(upHeroList, { refId = heroRefId })
            end
        end
    end
    local len = #upHeroList

    --遍历下龙纹的部分
    local upDragonList = {}
    for k, v in ipairs(list) do
        local itemRef = gModelItem:GetRefByRefId(v.refId)
        if itemRef then
            if itemRef.type == ModelItem.TTEM_TYPE_DRACONIC_ITEM then
                table.insert(upDragonList, v.refId)
            elseif itemRef.type == ModelItem.TTEM_TYPE_DRACONIC then
                local dragonRefId = checknumber(itemRef.typeDate)
                local costItem = gModelDraconic:GetUpStarCostRef(dragonRefId, -1)
                local max = costItem.count
                --check一遍数量
                if checknumber(v.num) >= max then
                    table.insert(upDragonList,dragonRefId)
                end
            end


        end
    end
    local dragonLen = #upDragonList

    if len > 0 then
        local func = function()
            self:ShowReward()
        end

        gModelGeneral:ShowUpHero(upHeroList, func)
    elseif dragonLen > 0 then
        local func = function()
            self:ShowReward()
        end
        GF.OpenWnd("UIDraconicGet", { refIdList = upDragonList, callback = func })
    else
        self:ShowReward()
    end


end

function UIOrdinYellAward:SetViewShow(info)
    local showBg = info.showBg
    if showBg then
        self:SetWndEasyImage(self.mShowBg, showBg)
    end
    local effectBg = info.effectBg
    if effectBg then
        self:SetWndEasyImage(self.mEffectBg, effectBg)
    end
    local effectName = info.effectName
    if effectName then
        self:CreateWndEffect(self.mEffectRoot, effectName, effectName, 100, false, false)
    end
    local titleEffectName = info.titleEffectName
    --self:CreateWndEffect(self.mTitleRoot,titleEffectName,titleEffectName,100,false,false)
    local titleImg = info.titleImg
    self._haveTitleImage = LxUiHelper.IsImgPathValid(titleImg)
    if self._haveTitleImage then
        self:SetWndEasyImage(self.mTitleImg, titleImg)
    end

    self._soundEffect = info.soundEffect
end

function UIOrdinYellAward:InitHeroList()
    CS.ShowObject(self.mAniRoot, true)
    local list = self._itemList or {}
    local len = #list
    self._len = len
    local isMore = len > UIOrdinYellAward.MIN_HREO_NUM
    CS.ShowObject(self.mHeroList, isMore)
    CS.ShowObject(self.mMinHeroList, not isMore)
    if isMore then
        local uiHeroList = self._uiMoreHeroList
        if uiHeroList then
            uiHeroList:RefreshList(list)
        else
            uiHeroList = self:GetUIScroll("uiHeroList_isMore")
            self._uiMoreHeroList = uiHeroList
            if CS.IsValidObject(self.mHeroList) then
                uiHeroList:Create(self.mHeroList, list, function(...)
                    self:OnDrawHeroCell(...)
                end, UIItemList.WRAP)
            end
        end
    else
        local uiHeroList = self._uiHeroList
        if uiHeroList then
            uiHeroList:RefreshList(list)
        else
            uiHeroList = self:GetUIScroll("uiHeroList")
            self._uiHeroList = uiHeroList
            if CS.IsValidObject(self.mMinHeroList) then
                uiHeroList:Create(self.mMinHeroList, list, function(...)
                    self:OnDrawHeroCell(...)
                end)
            end
        end
    end
end

function UIOrdinYellAward:RefreshBtnTxt()
    local callNum = self._callNum
    local oneCall = callNum == UIOrdinYellAward.CALL_NUM_ONE
    local textStr = oneCall and ccClientText(20800) or ccClientText(20801)
    local btnTextList = self._btnTextList
    if btnTextList and #btnTextList > 0 then
        if self._payTpye then
            if self._payTpye == UIOrdinYellAward.TYPE_PAY_FREE and btnTextList[1] then
                textStr = btnTextList[1]
            else
                if oneCall and btnTextList[2] then
                    textStr = btnTextList[2]
                elseif btnTextList[3] then
                    textStr = btnTextList[3]
                end
            end
        end
    end
    self:SetWndButtonText(self.mAgainBtn, textStr)
end

function UIOrdinYellAward:OnDrawHeroCell(list, item, itemdata, itempos)
    local CommonTrans = self:FindWndTrans(item, "Common")
    local iconTrans = self:FindWndTrans(CommonTrans, "Icon")
    local instanceId = item:GetInstanceID()
    local refId = itemdata.refId
    local itype = itemdata.itype
    --local count = itemdata.count
    --local formatData =
    --{
    --	itemId = refId,
    --	itemType = itype,
    --	itemNum = count,
    --}

    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(iconTrans)
    local actModel = self._actModel
    if actModel == ModelActivity.MODEL_ACTIVITY_TYPE_166 then
        baseClass:SetCommonReward(itype, refId, itemdata.count)
    else
        baseClass:SetRewardDetailItem(itemdata)
    end

    --baseClass:SetCommonReward(itype, refId, count)
    baseClass:EnableShowNum(itype ~= LItemTypeConst.TYPE_OUTFIT)

    baseClass:DoApply()

    self:DestroyWndEffectByKey(instanceId)
    if itype == LItemTypeConst.TYPE_HERO then
        local initStar = gModelHero:GetHeroInitStarByRefId(refId)
        if initStar < 4 then
            LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_HERO_NORMAL)
        end
        local heroEffectList = self._heroEffectList
        local eff = heroEffectList and heroEffectList[initStar]
        if eff then
            self:CreateWndEffect(CommonTrans, eff, instanceId, 100, false, false)
        end
    end

    self:SetIconClickScale(iconTrans, true)
    self:SetWndClick(iconTrans, function()
        --if itype == LItemTypeConst.TYPE_ITEM then
        --	gModelGeneral:OpenItemInfoTipTop(refId,count)
        --elseif itype == LItemTypeConst.TYPE_HERO then
        --	gModelGeneral:OpenHeroSimpleTip(refId,true)
        --elseif itype == LItemTypeConst.TYPE_EQUIP then
        --	gModelGeneral:OpenEquipInfoTip(refId,nil,count,true, nil, nil, true)
        --elseif itype == LItemTypeConst.TYPE_OUTFIT then
        --	gModelGeneral:ShowCommonItemTipWnd(formatData)
        --end
        gModelGeneral:ShowRewardDetailTip(itemdata)
    end)

    if self._len > UIOrdinYellAward.MIN_HREO_NUM then
        item.localScale = Vector3.one * 0.8
    else
        item.localScale = Vector3.one
    end
end

------------------------------------------------------------------
return UIOrdinYellAward


