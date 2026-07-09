---
--- Created by Administrator.
--- DateTime: 2023/10/6 20:13:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAct:LWnd
local UIAct = LxWndClass("UIAct", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAct:UIAct()
    self:SetHideHurdle()
    self._timeKey = "UIAct_timeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAct:OnWndClose()
    self:TimerStop(self._timeKey)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAct:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

    self._ignoreRedId =
    {
        [ModelRedPoint.ACTIVITY_ACTIVITY] = true,
        [ModelRedPoint.ACTIVITY_WELFARE] = true,
        [ModelRedPoint.ACTIVITY_TIME] = true,
        [ModelRedPoint.ACTIVITY_FIVE] = true,
    }

    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAct:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
	
    self:WndEventRecv(EventNames.ON_ACTIVITY_LIST_CHANGE,function () self:OnActivityChange() end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_SHOW_END,function () self:OnActivityChange() end)

    self:InitData()
	self:InitView()
    self:OnWndRefresh()

    self:SendTaInfo()
    self:TimerStart(self._timeKey,0.5,false,-1)
end

function UIAct:OpenPassD(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubPkD",{sid = sid})
end

function UIAct:GetRedIsShow(itemdata)
    local id = itemdata.id
    local showRed = gModelRedPoint:CheckActivityShowRed(id)
    if showRed then
        return true
    else
        local isNewActivity = false
        local isNet = itemdata.isNet
        isNewActivity = gModelActivity:IsActivityNew(id,isNet)
        if not isNet then
            local actRef = gModelActivity:GetActivityFunsById(id)
            if actRef then
                local eModel = actRef.eModel
                --if eModel == ModelActivity.ATTENTION_WECHAT then
                --    isNewActivity = false
                --end
            end
        end
        if isNewActivity then
            return true
        end
    end
    return false
end

function UIAct:OpenFreeEnjoyFund(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubFreeEnjoyFund",{sid = sid})
end

function UIAct:OpenRoundsTheTask(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubRoundsTheTk",{sid = sid})
end

function UIAct:OnClickActivityType(refId)
    if self._curSelectType == refId then
        return
    end
	gLxTKData:OnUIBtnClick("UIAct", refId)

    local old = self._curSelectType
    self._curSelectType = refId


    local uiList = self:GetUIScroll("activityUIList")
    uiList:DrawAllItems()


    self:ReleaseRedFunc(old) --注销旧的红点方法
    self._curSelectFunc = nil
    self:CloseAllChild()

    local activityfuncData = self:GetSelectFunc(refId)
    if activityfuncData then
        self._curSelectFunc = activityfuncData.id
        self:InitActiviFuncList(refId)
        self:OpenActivityChildWnd(activityfuncData)
    end



end


function UIAct:CancleRedPoint(itemdata)
    if not itemdata then return end

    local id = itemdata.id
    local isNet = itemdata.isNet
    if not isNet then
        local actRef = gModelActivity:GetActivityFunsById(id)
        if actRef then
            local eModel = actRef.eModel
            --if eModel == ModelActivity.ATTENTION_WECHAT then
            --    gModelRedPoint:SetMultiIdRedClicked(ModelRedPoint.ACTIVITY_WELFARE,id)
            --end
        end
    else
        local activityData = gModelActivity:GetActivityBySid(id)
        if activityData then

            -- if activityData.model == ModelActivity.ADD_GROUP_ACT then
            --     gModelRedPoint:SetMultiIdRedClicked(ModelRedPoint.ACTIVITY_WELFARE,id)
            if activityData.model == ModelActivity.Mirage_Challenge then
                --gModelActivity:OnActivitySpecialOpReq(id,nil,nil,ModelActivity.CANCEL_RED_POINT, "1|noPageRedPoint1")
            end
        end
    end
end

function UIAct:OpenExchange(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubExcGje",{sid = sid})
end

function UIAct:OpenAttentWeChat(sid)
    self:CreateChildWnd(self.mChildRoot,"WndChildAttentWeChat",{sid = sid})
end

-- function UIAct:OpenDailyGiftB(sid)
--     self:CreateChildWnd(self.mChildRoot,"UIActGiftB",{sid = sid})
-- end

function UIAct:OpenGrowthCapital(sid)
    self:CreateChildWnd(self.mChildRoot,"WndGrowthCapital",{sid = sid})
end
function UIAct:GetFirstOpenedActivity(refId)
    local dataList = gModelActivity:GetActivityIdByType(refId)
    if not dataList then
        return
    end
    for k,v in ipairs(dataList) do
        local isNet = v.isNet
        if not isNet then
            local isOpen = gModelActivity:IsBuiltInActOpen(v.id)
            if isOpen then
                return v
            end
        else
            return v
        end
    end
end

function UIAct:InitView()
	self:SetWndText(self:FindWndTrans(self.mRetrunBtn, "UIText"), ccClientText(30205))
	self:SetWndClick(self.mRetrunBtn,function() self:WndCloseAndBack() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIAct:GetSelectActivity(uniqueJump)
    local typeList =gModelActivity:GetActivityTypes()
    local curType = nil
    local curAct = nil
    local defaultType = nil
    local defaultAct = nil
    for k,v in ipairs(typeList) do
        local actType = v.refId
        local functionId = tonumber(v.functionOpenRefId)
        local isOpen = gModelFunctionOpen:CheckIsOpened(functionId)

        local activityList = gModelActivity:GetActivityIdByType(actType)
        if #activityList>0 and isOpen then
            for k1,v1 in ipairs(activityList) do
                local id = v1.id
                if uniqueJump then
                    if uniqueJump == v1.uniqueJump then
                        curType = actType
                        curAct = v1
                        break
                    end
                else
                    if gModelRedPoint:CheckActivityShowRed(id) or gModelActivity:IsActivityNew(id,v1.isNet) then
                        curType = actType
                        curAct = v1
                        break
                    end
                end
            end

            if not defaultType then
                defaultType = actType
                defaultAct = activityList[1]
            end
        end

        if curType then
            break
        end
    end

    local retType = curType or defaultType
    local retAct = curAct or defaultAct

    return retType,retAct

end

-- function UIAct:OpenDailySignIn(sid)
--     self:CreateChildWnd(self.mChildRoot,"WndDailySignIn",{sid = sid})
-- end

function UIAct:OpenPrivilegeShop(sid)
    local extraPara = self:GetWndArg("extra")
    local index = extraPara or 1

    self:CreateChildWnd(self.mChildRoot,"UISubWishPrige",{index = index})
end

function UIAct:OpenMonthSignIn(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubMonthSignIn",{sid = sid})
end

-- function UIAct:OpenSpecialFund(sid)
--     self:CreateChildWnd(self.mChildRoot,"WndSpecialFunds",{sid = sid})
-- end

function UIAct:OpenMirageChallenge(sid)

    local isFight = gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_ACTIVITY)
    if isFight then
        if gLGameUI then
            gLGameUI:CloseAllBySwitchTypeButExcept(LWnd.SWITCH_TYPE_CHANGE_BTN,nil)
        end
        gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_ACTIVITY,{})
        FireEvent(EventNames.ON_MAIN_CITY_BTN_CHANGE)
    else
        --- 服务端处理，客户端直接消失
        --gModelActivity:OnActivitySpecialOpReq(sid,nil,nil,ModelActivity.CANCEL_RED_POINT, "1|noPageRedPoint1")
        gModelRedPoint:SetActivityRedClicked(sid)
        self:CreateChildWnd(self.mChildRoot,"UIMirageChall",{sid = sid})
    end
end

function UIAct:GetHistory()
    local list = LWnd.GetHistory(self)
    local wndArgList = list.wndArgList
    wndArgList.page = self._page
    wndArgList.subPage = self._activityJump
    return list
end


function UIAct:InitActiviFuncList(type)
    local dataList = gModelActivity:GetActivityIdByType(type)

    if not dataList then
        dataList ={}
    end
    self._dataList = dataList

    self._actvFuncList ={}
    if(self._uiTabList)then
        self._uiTabList:RefreshList(dataList)
    else
        self._uiTabList =self:GetUIScroll("activityFuncUIList")
        self._uiTabList:Create(self.mBtnList,dataList,function (...) self:OnDrawActivityFunc(...) end)
    end
    local index = 1
    for i, v in ipairs(dataList) do
        if(self._curSelectFunc==v.id)then
            index = i
            break
        end
    end

    local uiList = self._uiTabList:GetList()
    if uiList then
        uiList:EnableScroll(true,true)
        uiList:DelayScrollTo(index,UIListEasy.SCROLL_CENTER)
    end

    LxUiHelper.StopFilterMove(self.mBtnList)

    self:RegisterRedFunc(self._curSelectType)
end

-- function UIAct:OpenAdvertising(sid)
--     self:CreateChildWnd(self.mChildRoot,"WndChildActivityAdvertising",{sid = sid})
-- end

-- function UIAct:OpenWxInviteWin(sid)
--     self:CreateChildWnd(self.mChildRoot, "WndChildWxInvite", {sid = sid})
-- end

-- function UIAct:OpenWxCollectionWin(sid)
--     self:CreateChildWnd(self.mChildRoot, "WndChildWxCollection", {sid = sid})
-- end

function UIAct:OpenActivity169(sid)
    self:CreateChildWnd(self.mChildRoot, "UISubActivity169", {sid = sid})
end

function UIAct:SetPara()
    local page = self:GetWndArg("page")
    local subPage = self:GetWndArg("subPage")

    page = page

    self._page = page
    self._activityJump = subPage
end

function UIAct:OpenCommonTarget(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubOrdinTarget",{sid = sid})
end

-- function UIAct:OpenWeeksCard(sid)
--     self:CreateChildWnd(self.mChildRoot,"WndChildWeeksCard",{sid = sid})
-- end

-- function UIAct:OpenAddUpPay(sid)
--     self:CreateChildWnd(self.mChildRoot,"WndChildAddUpPay",{sid = sid})
-- end

function UIAct:OpenExchangeItem(sid)
    self:CreateChildWnd(self.mChildRoot,"UIOrdinRecovery",{sid = sid})
end

function UIAct:GetSelectFunc(actType,uniqueJump)
    local selectList = gModelActivity:GetActivityIdByType(actType)

    local activityfuncData = nil

    for k,v in ipairs(selectList) do
        local jumpId = v.uniqueJump
        if uniqueJump then
            if jumpId == uniqueJump then
                activityfuncData = v
                break
            end
        else
            local showRed = gModelRedPoint:CheckActivityShowRed(v.id) or gModelActivity:IsActivityNew(v.id,v.isNet)
            if showRed then
                activityfuncData = v
                break
            end
        end
    end

    if not activityfuncData then
        activityfuncData = self:GetFirstOpenedActivity(actType)
    end

    return activityfuncData
end

function UIAct:OpenEnjoyMonthCard(sid)
    self:CreateChildWnd(self.mChildRoot,"WndChildEnjoyMonthCard",{sid = sid})
end

function UIAct:ReleaseRedFunc(type)
    local refId = self._typeToRedType[type]
    if self._redRefreshFunc then
        self:ReleaseRedPointSingleFunc(refId,self._redRefreshFunc)
    end
end

function UIAct:RefreshNewTag()
    local id = self._curSelectFunc
    local item = self._actvFuncList[id].item
    local tag = self:FindWndTrans(item,"tag")
    CS.ShowObject(tag,false)
end

function UIAct:OnTimer(key)
    if key == self._timeKey then
        self:SetTime()
    end
end

-- function UIAct:OpenAddGroup(sid)
--     self:CreateChildWnd(self.mChildRoot,"WndChildAddGroup",{sid = sid})
-- end

function UIAct:OpenDreamSecret(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubSecret")
end

--[[
itemdata=
{
	id --sid or refid
	sort --
	isNet --后端
}
]]

function UIAct:OnClickActivFunc(itemdata)
    local id = itemdata.id
    if self._curSelectFunc == id then
        return
    end

    local isNet = itemdata.isNet
    if not isNet then
        local isOpen = gModelActivity:IsBuiltInActOpen(id,true)
        if not isOpen then
            return
        end
    end

    self:CancleRedPoint(itemdata)

    local old = self._curSelectFunc
    self._curSelectFunc = id
    local uiData = self._actvFuncList[old]
    local item = uiData.item
    local data =uiData.itemdata

    local select = self:FindWndTrans(item,"select")
    CS.ShowObject(select, false)

    local UIText = self:FindWndTrans(item,"UIText")
    --self:SetWndText(UIText,LUtil.FormatColorStr(data.name,"grey_2"))
    self:SetWndText(UIText,data.name)
    uiData = self._actvFuncList[id]
    item = uiData.item
    data =uiData.itemdata
    select = self:FindWndTrans(item,"select")
    UIText = self:FindWndTrans(item,"UIText")

    CS.ShowObject(select, true)
    self:SetWndText(UIText,data.name)

    self:CloseAllChild()

    self:OpenActivityChildWnd(itemdata)
end

function UIAct:OpenPassC(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubPkC",{sid = sid})
end

function UIAct:SendTaInfo()
    if not self._curSelectFunc then
        return
    end
    local itemdata = self._actvFuncList and self._actvFuncList[self._curSelectFunc]
    if not itemdata then
        return
    end
    local actData = itemdata.itemdata
    if actData.isNet then
        local activityData = gModelActivity:GetActivityBySid(actData.id)
        if activityData then
            gLxTKData:OnWebActivityClick(activityData)
        end
    else
        local cfg = gModelActivity:GetActivityFunsById(actData.id)
        if cfg then
            gLxTKData:OnFuncActivityClick(cfg)
        end
    end
end

function UIAct:OpenDailyGiftA(sid)
    self:CreateChildWnd(self.mChildRoot,"UIActGiftA",{sid = sid})
end

function UIAct:OpenTimeWardrobe()
    --gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_SKIN,"open",2)
    self:CreateChildWnd(self.mChildRoot,"UILimitWardrobe")
end

function UIAct:ShowContent()

    self:CloseAllChild()

    local typeList =gModelActivity:GetActivityTypes()

    local showTypeList ={}
    for k,v in ipairs(typeList) do
        local refId = v.refId
        local functionId = tonumber(v.functionOpenRefId)
        local isShow = gModelFunctionOpen:CheckIsShow(functionId)
        local activityList = gModelActivity:GetActivityIdByType(refId)
        local data = {}
        data.refId = refId
        data.show = #activityList>0 and isShow
        data.icon = v.icon
        data.name = ccLngText(v.name)
        table.insert(showTypeList,data)
    end

    local curType,curAct = self:GetSelectActivity(self._activityJump)
    if not curType then
        return
    end

    self._curSelectType = curType
    self:InitActivityTypeList(showTypeList)
    self._curSelectFunc =curAct.id
    self:InitActiviFuncList(self._curSelectType)
    self:OpenActivityChildWnd(curAct)
    self:CancleRedPoint(curAct)

	gLxTKData:OnUIBtnClick("UIAct", self._curSelectType)
end


function UIAct:OnActivityChange()
    local typeList =gModelActivity:GetActivityTypes()

    local oldType = self._curSelectType
    local oldSubtype  = self._curSelectFunc

    local curType = self._curSelectType
    local showTypeList ={}
    local selectList = nil
    local existType = nil
    for k,v in ipairs(typeList) do
        local refId = v.refId
        local activityList = gModelActivity:GetActivityIdByType(refId)
        local data = {}
        data.refId = refId
        data.show = #activityList>0
        data.icon = v.icon
        data.name = ccLngText(v.name)
        if #activityList>0 then
            if refId == curType then
                selectList = activityList
            end
            if not existType then
                existType = refId
            end
        end

        table.insert(showTypeList,data)
    end

    if not selectList then
        curType = existType
    end
    self._curSelectType = curType

    self:InitActivityTypeList(showTypeList)

    selectList = gModelActivity:GetActivityIdByType(curType)

    local activityfuncData = nil

    local id = self._curSelectFunc
    if id then
        for k,v in pairs(selectList) do
            local tempid = v.id
            if tempid == id then
                activityfuncData = v
                break
            end
        end
    end

    if not activityfuncData then
        activityfuncData = self:GetFirstOpenedActivity(curType)
    end

    if not activityfuncData then
        return
    end

    self._curSelectFunc =activityfuncData.id
    self:InitActiviFuncList(self._curSelectType)

    local needClose = true
    if oldType == curType and oldSubtype == self._curSelectFunc then
        needClose = false
    end
    if needClose then
        self:CloseAllChild()
    end
    self:OpenActivityChildWnd(activityfuncData)
end

--function UIAct:OpenGiftCode(sid)
--    self:CreateChildWnd(self.mChildRoot,"WndGiftCode",{sid = sid})
--end

function UIAct:OpenDailyGift(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubDTDGift",{sid = sid})
end

function UIAct:InitData()


    self._actvTypeList ={}
    self._actvFuncList = {}

    self._modelOpenFunc =
    {
        [ModelActivity.PRIVILEGE_SHOP] = function(...) self:OpenPrivilegeShop(...) end,
        --[ModelActivity.GIFT_CODE] = function(...) self:OpenGiftCode(...) end,
        [ModelActivity.COMMON_TARGET] = function(...) self:OpenCommonTarget(...) end,
        -- [ModelActivity.DAILY_SIGN_IN] = function(...) self:OpenDailySignIn(...) end,
        [ModelActivity.MODEL_DAILYGIFTBAG] = function(...) self:OpenDailyGift(...) end,
        [ModelActivity.DAILY_GIFT_A] = function(...) self:OpenDailyGiftA(...) end,
        -- [ModelActivity.DAILY_GIFT_B] = function(...) self:OpenDailyGiftB(...) end,
        [ModelActivity.Mirage_Challenge] = function(...) self:OpenMirageChallenge(...) end,
        -- [ModelActivity.Growth_Capital] = function(...) self:OpenGrowthCapital(...) end,
        [ModelActivity.Growth_Capital_2] = function(...) self:OpenGrowthCapital2(...) end,

        -- [ModelActivity.Special_Fund] = function(...) self:OpenSpecialFund(...) end,
        [ModelActivity.MODEL_PASSA] = function(...) self:OpenPassA(...) end,
        [ModelActivity.MODEL_PASSB] = function(...) self:OpenPassB(...) end,
        [ModelActivity.MODEL_ACCUMULATEDAY] = function(...) self:OpenAccumulateDay(...) end,
        [ModelActivity.MONTH_CARD] = function(...) self:OpenMonthCard(...) end,
        [ModelActivity.EXCHANGE] = function(...) self:OpenExchange(...) end,
        [ModelActivity.COMMONRANK] = function(...) self:OpenCommonRank(...) end,
        --[ModelActivity.REAL_NAME] = function(...) self:OpenRealNameVerify(...) end,
        [ModelActivity.ACCOUNT_BIND] = function(...) self:OpenAccountBind(...) end,
        [ModelActivity.TIME_WARDROBE] = function(...) self:OpenTimeWardrobe(...) end,
        [ModelActivity.ACTIVITY_WEEKEND] = function(...) self:OpenWeekend(...) end,
        -- [ModelActivity.ACTIVITY_WEEKSCARD] = function(...) self:OpenWeeksCard(...) end,
        -- [ModelActivity.ACTIVITY_ADDUPPAY] = function(...) self:OpenAddUpPay(...) end,
        [ModelActivity.ACTIVITY_CUSTOMGIFT] = function(...) self:OpenCustomGift(...) end,
        -- [ModelActivity.DAILY_GIFT_C] = function(...) self:OpenDailyGiftC(...) end,
        -- [ModelActivity.ACTIVITY_EXCHANGEITEM] = function(...) self:OpenExchangeItem(...) end,
        --[ModelActivity.MODEL_TREASURE_HOT] = function(...) self:OpenTreaHot(...) end,
        [ModelActivity.MODEL_PASSC] = function(...) self:OpenPassB(...) end,
        [ModelActivity.DREAM_SECRET] = function(...) self:OpenDreamSecret(...) end,
        [ModelActivity.MODEL_PASSD] = function(...) self:OpenPassD(...) end,
        [ModelActivity.FREE_ENJOY_FUND] = function(...) self:OpenFreeEnjoyFund(...) end,
        --[ModelActivity.ATTENTION_WECHAT] = function(...) self:OpenAttentWeChat(...) end,
        [ModelActivity.INVITE_ACTIVITY] = function(...) self:OpenInviteAct(...) end,
        -- [ModelActivity.ADD_GROUP_ACT] = function(...) self:OpenAddGroup(...) end,
        [ModelActivity.ROUNDS_THE_TASK] = function(...) self:OpenRoundsTheTask(...) end,
        [ModelActivity.MODEL_ACTIVITY_TYPE_56] = function(...) self:OpenMonthSignIn(...) end,
        [ModelActivity.MODEL_ACTIVITY_TYPE_77] = function(...) self:OpenUpgradeGift(...) end,
        [ModelActivity.MODEL_ACTIVITY_TYPE_78] = function(...) self:OpenOverflowPrivilege(...) end,
        -- [ModelActivity.MODEL_ACTIVITY_ADVERTISING] = function(...) self:OpenAdvertising(...) end,
        -- [ModelActivity.MONTH_ACTIVITY_ENJOY_CARD] = function(...) self:OpenEnjoyMonthCard(...) end,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_4112] = function(...) self:OpenWxInviteWin(...) end,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_4101] = function(...) self:OpenWxCollectionWin(...) end,
        [ModelActivity.MODEL_ACTIVITY_TYPE_169] = function(...) self:OpenActivity169(...) end,
    }

    self._typeToRedType=
    {
        [1] = ModelRedPoint.ACTIVITY_WELFARE,
        [2] = ModelRedPoint.ACTIVITY_ACTIVITY,
        [3] = ModelRedPoint.ACTIVITY_TIME,
        [5] = ModelRedPoint.ACTIVITY_FIVE,
    }

    self._redRefreshFunc = function ()
        self:RefreshRed()
    end
end

function UIAct:RefreshRed()
    for k,v in pairs(self._actvFuncList) do
        local item = v.item
        if CS.IsValidObject(item) then
            local redPoint = self:FindWndTrans(item,"redPoint")
            local showRed = gModelRedPoint:CheckActivityShowRed(k)

            CS.ShowObject(redPoint,showRed)
            local tagShow = gModelActivity:IsActivityNew(v.itemdata.id,v.itemdata.isNet)
            local tag = self:FindWndTrans(item,"tag")
            CS.ShowObject(tag,tagShow and not showRed)

        end
    end

    for k,v in pairs(self._actvTypeList) do
        if CS.IsValidObject(v) then
            local redPoint = self:FindWndTrans(v,"redPoint")
            local redType = gModelRedPoint:GetAcvityRedTypeByType(k)
            local showRed = gModelRedPoint:CheckShowRedPoint(redType)
            CS.ShowObject(redPoint,showRed)
        end
    end
end

-- function UIAct:OpenDailyGiftC(sid)
--     self:CreateChildWnd(self.mChildRoot,"UIActGiftC",{sid = sid})
-- end

function UIAct:OpenAccumulateDay(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubAccumulateDay",{sid = sid})
end

function UIAct:OpenPassA(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubPkA",{sid = sid})
end
function UIAct:OpenGrowthCapital2(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubGwthCapital2",{sid = sid})
end
function UIAct:OpenOverflowPrivilege(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubOverflowPrige",{sid = sid})
end

function UIAct:OnWndRefresh()
    self:SetPara()
    self:ShowContent()

    self:RefreshRed()
end

function UIAct:OpenInviteAct(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubInviteAct",{sid = sid,isShareJump = self:GetWndArg("isShareJump")})
end

function UIAct:OpenMonthCard(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubMonthCard",{sid = sid})
end

function UIAct:OpenPassB(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubPkB",{sid = sid})
end

function UIAct:RegisterRedFunc(type)


    local refId = self._typeToRedType[type]
    if refId then
        self:RegisterRedPointFunc(refId,self._redRefreshFunc)
    end
end

--[[function UIAct:OpenRealNameVerify()
    self:CreateChildWnd(self.mChildRoot,"UISubExchange",{wndType = 1})
end]]

function UIAct:OpenAccountBind()
    FireEvent(EventNames.CLICK_BIND_BUTTON)
    self:CreateChildWnd(self.mChildRoot,"UISubExchange",{authType = ModelPlayer.AUTH_ACCOUNT_BIND})
end

---打开活动子界面
function UIAct:OpenActivityChildWnd(itemdata)

    local curTime = GetTimestamp()
    gModelActivity:AddRecord(itemdata.id,curTime,itemdata.isNet)
    self:RefreshNewTag()

    local model = nil
    local sid = itemdata.id
    if itemdata.isNet then
        local activityData = gModelActivity:GetActivityBySid(sid)
        if not activityData then
            return
        end
        model = activityData.model
    else
        local sid = itemdata.id
        local cfg = gModelActivity:GetActivityFunsById(sid)
        if not cfg then
            return
        end
        model = cfg.eModel
    end


    local openFunc = self._modelOpenFunc[model]
    if openFunc then
        openFunc(sid)
    end

end

function UIAct:OnDrawActivityFunc(list, item,itemdata,itempos)
    local select = self:FindWndTrans(item,"select")
    local icon = self:FindWndTrans(item,"icon")
    local UIText = self:FindWndTrans(item,"UIText")
    local tag = self:FindWndTrans(item,"tag")
    local redPoint =self:FindWndTrans(item,"redPoint")

    local isNewActivity = false
    local id = itemdata.id
    local isNet = itemdata.isNet
    local iconPath= nil
    if isNet then
        local activityData = gModelActivity:GetActivityBySid(itemdata.id)
        if activityData then
            iconPath = activityData.icon
        end
    else
        local cfg  = gModelActivity:GetActivityFunsById(id)
        iconPath = cfg.icon
    end
    if iconPath then
        self:SetWndEasyImage(icon,iconPath)

    end
    isNewActivity = gModelActivity:IsActivityNew(id,isNet)

    local isSelect = self._curSelectFunc == id

    local color = "grey_2"
    if isSelect then
        color = "white"
    end
    --self:SetWndText(UIText,LUtil.FormatColorStr(itemdata.name,color))
    self:SetWndText(UIText,itemdata.name)

    self:InitTextSizeWithLanguage(UIText,-4)
    self:InitTextLineWithLanguage(UIText,-25)

    local showRed = gModelRedPoint:CheckActivityShowRed(id)
    if not isNet then
        local actRef = gModelActivity:GetActivityFunsById(id)
        if actRef then
            local eModel = actRef.eModel
            --if eModel == ModelActivity.ATTENTION_WECHAT then
            --    isNewActivity = false
            --end
        end
    end
    CS.ShowObject(redPoint,showRed)
    CS.ShowObject(tag,isNewActivity)

    CS.ShowObject(select,isSelect)
    self:SetWndClick(item,function ()
        LxUiHelper.FilterScrollItem(self.mBtnList,itempos-1)
        self:OnClickActivFunc(itemdata)
        self:SendTaInfo()
    end,LSoundConst.CLICK_PAGE_COMMON)


    self._actvFuncList[id] = {item = item,itemdata = itemdata}
end

function UIAct:OpenWeekend(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubWeekend",{sid = sid})
end

function UIAct:GetActivityModel(itemdata)
    local model = nil
    local sid = itemdata.id
    if itemdata.isNet then
        local activityData = gModelActivity:GetActivityBySid(sid)
        model = activityData.model
    else
        local sid = itemdata.id
        local cfg = gModelActivity:GetActivityFunsById(sid)
        model = cfg.eModel
    end
    return model
end
function UIAct:OpenUpgradeGift(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubActUpdeGift",{sid = sid})
end

function UIAct:OpenCommonRank(sid)
    self:CreateChildWnd(self.mChildRoot,"UIOrdinRank",{sid = sid})
end

function UIAct:OpenCustomGift(sid)
    self:CreateChildWnd(self.mChildRoot,"UISubCumGift",{sid = sid})
end

function UIAct:InitActivityTypeList(typelist)
    local uiList = self:GetUIScroll("activityUIList")
    local isForeign = gLGameLanguage:IsUSARegion()
    local root = self.mBtnRoot
    --if isForeign then
    --    root = self.mEnBtnRoot
    --end
    uiList:Create(root,typelist,function (...) self:OnDrawActivityType(...) end)
end

function UIAct:SetTime()
    CS.ShowObject(self.mRedTips,false)
    CS.ShowObject(self.mRedTipsLeft,false)
    local dataList = self._dataList or {}
    local len = #dataList
    if len <= 5 then return end
    local _uiTabList = self._uiTabList
    if not _uiTabList then return end
    local uiList = _uiTabList:GetList()
    if not uiList then return end
    local v2 = uiList:GetContentPosition()
    if not v2 then return end

    local x = v2.x
    x = x <= 0 and 0 or x
    x = x >= 1 and 1 or x
    local dX = 1/(len - 5)
    local num = math.floor(x/dX + 0.5) + 1

    if len - num >= 5 then
        local isShow = false
        local sIndex = (num + 5)
        for i = sIndex, len do
            isShow = self:GetRedIsShow(dataList[i])
            if isShow then
                break
            end
        end
        CS.ShowObject(self.mRedTips,isShow)
    end

    if num > 1 then
        local isShowLeft = false
        local jIndex = num - 1
        for i = 1, jIndex do
            isShowLeft = self:GetRedIsShow(dataList[i])
            if isShowLeft then
                break
            end
        end
        CS.ShowObject(self.mRedTipsLeft,isShowLeft)
    end
end

function UIAct:OnDrawActivityType(list, item,itemdata,itempos)
    local icon = self:FindWndTrans(item,"icon")
    local nameBg = self:FindWndTrans(item,"nameBg")
    local nameBgName = self:FindWndTrans(nameBg,"name")
    local select = self:FindWndTrans(item,"select")
    --local redPoint = self:FindWndTrans(item,"redPoint")


    CS.ShowObject(item,itemdata.show)
    if not itemdata.show then
        return
    end
    local refId = itemdata.refId
    local iconpath = itemdata.icon
    if iconpath then
        self:SetWndEasyImage(icon,iconpath)
    end

    local isSelect = refId == self._curSelectType

    --欧美+韩+日，由于动态描述，图片与文本分离
    --local isShowNameBg = gLGameLanguage:IsForeignRegion()
    local isShowNameBg = false
    if isShowNameBg then
        local color = "lightBlue"
        if isSelect then
            color = "yellow_2"
        end
        local name = LUtil.FormatColorStr(itemdata.name,color)
        self:SetWndText(nameBgName,name)
        self:InitTextSizeWithLanguage(nameBgName,-2)
    end
    CS.ShowObject(nameBg, isShowNameBg)

    CS.ShowObject(select,isSelect)

    self:SetWndClick(item,function () self:OnClickActivityType(refId) end,LSoundConst.CLICK_PAGE_COMMON)

    self._actvTypeList[refId] = item
end
------------------------------------------------------------------
return UIAct


