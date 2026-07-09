---
--- Created by BY.
--- DateTime: 2023/10/17 14:08:22
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubMonthSignIn:LChildWnd
local UISubMonthSignIn = LxWndClass("UISubMonthSignIn", LChildWnd)

UISubMonthSignIn.PAGE_ID_1 = 1        --月签奖励表
UISubMonthSignIn.PAGE_ID_2 = 2        --月签累签奖励表
UISubMonthSignIn.PAGE_ID_3 = 3        --月签付费奖励表
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubMonthSignIn:UISubMonthSignIn()
    self._commonIconList = {}
    self._boxItemList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubMonthSignIn:OnWndClose()
    self:ClearCommonIconList(self._commonIconList)
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubMonthSignIn:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubMonthSignIn:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
end

function UISubMonthSignIn:OnActivityConfigData()
    local activityData = gModelActivity:GetWebActivityDataById(self._sid)
    local data = activityData.config
    local descIcon, descIconPosition, helpTips, TraceSignCost, image, helpTipsPosition, boxIcon = data.descIcon, data.descIconPosition, data.helpTips, data.TraceSignCost, data.image, data.helpTipsPosition, data.boxIcon
    local boxEff, itemEff, specialEff = data.boxEff, data.itemEff, data.specialEff

    local boxSwitch = data.boxSwitch
    if not boxSwitch then
        boxSwitch = 1
    end
    self._boxSwitch = tonumber(boxSwitch)

    local extraSwitch = data.extraSwitch
    if not extraSwitch then
        extraSwitch = 1
    end
    self._extraSwitch = tonumber(extraSwitch)

    self._helpTipsContent = data.helpTipsContent
    self._specialBox = data.specialBox
    if not string.isempty(boxEff) then
        self._boxEff = boxEff
    end
    if not string.isempty(itemEff) then
        self._itemEff = itemEff
    end
    if not string.isempty(specialEff) then
        self._specialEff = specialEff
    end
    if not string.isempty(TraceSignCost) then
        self._traceSignCost = LxDataHelper.ParseItem_3List(TraceSignCost)
    end
    if not string.isempty(boxIcon) then
        self._boxIcon = string.split(boxIcon, "|")
    end

    if LxUiHelper.IsImgPathValid(image) then
        --self:SetWndEasyImage(self.mTopImg, image, nil, true)
        self:SetWndEasyImage(self.mTopImg, image, nil, false)
    end
    if LxUiHelper.IsImgPathValid(descIcon) then
        CS.ShowObject(self.mTxtImg, true)
        self:SetWndEasyImage(self.mTxtImg, descIcon, nil, true)
        if not string.isempty(descIconPosition) then
            local pos = LxDataHelper.ParseVector2NotEmpty(descIconPosition)
            self:SetAnchorPos(self.mTxtImg, pos)
        end
    end
    CS.ShowObject(self.mBtnHelp, helpTips == 1)
    if not string.isempty(helpTipsPosition) then
        local pos = LxDataHelper.ParseVector2NotEmpty(helpTipsPosition)
        self:SetAnchorPos(self.mBtnHelp, pos)
    end

    gModelActivity:OnActivityPageReq(self._sid)
end

function UISubMonthSignIn:OnClickBox(itemdata)
    local status = itemdata.goalData.status
    if status == 1 then
        --领取
        self:OnClickGet(itemdata)
        return
    end
    local rewards = LxDataHelper.SevenParseItems(itemdata.items)
    if rewards then
        local root = self._boxItemList[itemdata.entryId]
        GF.OpenWnd("UIringBoxDetail", { root, rewards })
    end
end

function UISubMonthSignIn:OnClickHelp()
    local _sid = self._sid
    local title = gModelActivity:GetLngNameByActivitySid(_sid)
    local content = self._helpTipsContent
    GF.OpenWnd("UIBzTips", { title = title, text = content })
end

function UISubMonthSignIn:RefreshData()
    local _pages = self._pages
    if not _pages then
        return
    end
    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        return
    end
    local signInData = JSON.decode(activityData.moreInfo)
    local repairTime = signInData.repairTime                        --补签次数
    local day = signInData.day                                        --当前天
    self._repairTime = repairTime
    local repair = tonumber(signInData.repair) or 0
    self._isCanRepair = repair == 1
    self._day = day

    local signInPage = _pages[UISubMonthSignIn.PAGE_ID_1]        --月签奖励表
    local addUpPage = _pages[UISubMonthSignIn.PAGE_ID_2]        --月签累签奖励表
    local againPage = _pages[UISubMonthSignIn.PAGE_ID_3]        --月签付费奖励表

    local signInList = signInPage and signInPage.entry or {}
    local addUpList = addUpPage and addUpPage.entry or {}
    local againList = againPage and againPage.entry or {}
    self._signInList = signInList

    local signInNum = 0
    local signInIndex = day
    for i, v in ipairs(signInList) do
        local status = v.goalData.status
        if status ~= 0 then
            signInNum = signInNum + 1
        end
        if signInIndex ~= day and status == 1 then
            signInIndex = v.entryId
        end
    end
    self:SetWndText(self.mNumText, signInNum)

    local againStatusList = {}
    for i, v in ipairs(againList) do
        againStatusList[v.entryId] = v
    end
    self._againStatusList = againStatusList

    local _cellSuper = self._uiCellSuper
    if _cellSuper then
        _cellSuper:RefreshList(signInList)
    else
        _cellSuper = self:GetUIScroll("MonthSignInCellSuper")
        _cellSuper:Create(self.mCellSuper, signInList, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER_GRID)
        _cellSuper:EnableScroll(true, false)
        self._uiCellSuper = _cellSuper
    end
    _cellSuper:DrawAllItems()
    if not self._one then
        _cellSuper:MoveToPos(signInIndex)
        self._one = true
    end

    local len = #addUpList
    CS.ShowObject(self.mBarMag, len > 0)
    if len <= 0 then
        return
    end
    local dataList = {}
    for k, v in ipairs(addUpList) do
        local goal = v.goalData.schedules[1].goal
        table.insert(dataList, goal)
    end
    local percent = LUtil.GetCurPercent(dataList, signInNum)
    LxUiHelper.SetProgress(self.mActiveBar, percent)
    local boxUIList = self._boxUIList

    if self._boxSwitch == 0 then
        CS.ShowObject(self.mBarMag, false)
    else
        CS.ShowObject(self.mBarMag, true)
        if boxUIList then
            boxUIList:RefreshList(addUpList)
        else
            boxUIList = self:GetUIScroll("MonthSignInBoxList")
            boxUIList:Create(self.mBoxList, addUpList, function(...)
                self:BoxListItem(...)
            end)
            self._boxUIList = boxUIList
        end

    end
end

function UISubMonthSignIn:ResetData(pb)
    local sid = pb.sid
    if (self._sid ~= sid) then
        return
    end
    local _pages = self._pages or {}
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        _pages[v.pageId] = page
    end
    self._pages = _pages
    self:RefreshData()
end

function UISubMonthSignIn:OnClickOneKeyGet()
    local _signInList = self._signInList            --月签奖励表
    local list = {}
    for i, v in ipairs(_signInList) do
        if (v.goalData.status == 1) then
            local data1 = { sid = self._sid, pageId = v.pageId, entryId = v.entryId }
            table.insert(list, data1)
        end
    end
    gModelActivity:OnActivityReceiveGoalListReq(list)
end

function UISubMonthSignIn:ListItem(list, item, itemdata, itempos)
    local _sid = self._sid
    local entryCfg = gModelActivity:GetWebActivityEntryData(_sid, itemdata.pageId, itemdata.entryId)
    local itemRoot = self:FindWndTrans(item, "ItemRoot")
    local mendImg = self:FindWndTrans(item, "MendImg")
    local getMask = self:FindWndTrans(item, "GetMask")
    local titleBg = self:FindWndTrans(item, "TitleBg")
    local titleText = self:FindWndTrans(titleBg, "TitleText")
    local btnMag = self:FindWndTrans(item, "BtnMag")
    local btnAgain = self:FindWndTrans(btnMag, "BtnAgain")
    local btnGet = self:FindWndTrans(btnMag, "BtnGet")
    local btnMend = self:FindWndTrans(btnMag, "BtnMend")
    local mendText = self:FindWndTrans(btnMag, "BtnMend/MendText")
    local mendIcon = self:FindWndTrans(btnMag, "BtnMend/MendText/MendIcon")
    local mask = self:FindWndTrans(item, "Mask")
    local eff = self:FindWndTrans(item, "Eff")
    local eff2 = self:FindWndTrans(item, "Eff2")

    local InstanceID = item:GetInstanceID()
    local status = itemdata.goalData.status                                                    --领取状态
    local _day = self._day                                                                    --当前天数
    local entryId = itemdata.entryId                                                        --目标天数值
    local _againStatusList = self._againStatusList or {}                                    --月签付费奖励领取状态表
    local againItemdata = _day == entryId and _againStatusList[entryId] or false            --月签付费奖励数据
    local againItemdata2 = _day >= entryId and _againStatusList[entryId] or false            --月签付费奖励数据
    local isAgainGet = againItemdata and againItemdata.goalData.status == 0 or false        --月签付费奖励是否可领取--需要充钱
    local isAgainGet2 = againItemdata2 and againItemdata2.goalData.status == 1 or false    --月签付费奖励是否可领取--已经充钱
    local isAgain = isAgainGet and status == 2                                                --是否再领取一次--需要充钱
    local isAgain2 = isAgainGet2 and status == 2                                            --是否再领取一次--已经充钱


    isAgain = isAgain and self._extraSwitch == 1
    isAgain2 = isAgain2 and self._extraSwitch == 1
    local pageId = itemdata.pageId
    local isMend = false                                                                    --是否可补签
    if pageId == 1 then
        isMend = self._isCanRepair and entryId < _day and status == 0
    else
        isMend = entryId < _day and status == 0
    end
    local isShowBtnMag = status == 1 or isMend or isAgain or isAgain2                        --是否显示按钮
    local _repairTime = self._repairTime or 0                                                --补签次数
    local isSpecialBox = entryCfg.moreInfo == 1                                                --特殊奖励框的美术资源
    local isShowEff = status == 1 or (againItemdata2 and againItemdata2.goalData.status == 1)--是否显示特效

    CS.ShowObject(getMask, status == 2)
    CS.ShowObject(mask, (not isAgain and not isAgain2) and status == 2)
    CS.ShowObject(btnMag, isShowBtnMag)
    CS.ShowObject(titleBg, not isShowBtnMag and status == 0)
    CS.ShowObject(mendImg, isMend)
    CS.ShowObject(eff, isShowEff)
    CS.ShowObject(eff2, (isAgain or isAgain2 or status ~= 2) and isSpecialBox)

    self:SetWndText(titleText, entryCfg.name)

    local addLine = -30
    if gLGameLanguage:IsFrenchVersion() then
        addLine = -50
    end

    if isShowBtnMag then
        CS.ShowObject(btnAgain, isAgain)
        CS.ShowObject(btnGet, status == 1 or isAgain2)
        CS.ShowObject(btnMend, isMend)
        if isMend then
            local costItem = self:GetTraceSignCostByIndex(_repairTime + 1)        --补签消耗
            local costNum = costItem.itemNum                                            --补签消耗数量
            local costIcon = gModelItem:GetItemImgByRefId(costItem.itemId)                --补签消耗图标
            self:SetWndText(mendText, costNum)
            self:SetWndEasyImage(mendIcon, costIcon)
        end
        self:SetWndButtonText(btnGet, ccClientText(25602))
        self:SetWndButtonText(btnAgain, ccClientText(25603), nil, nil, addLine)
    end

    local effect1Key = eff:GetInstanceID()
    local _itemEff = self._itemEff
    local _specialEff = self._specialEff
    if isShowEff and _itemEff then
        self:CreateWndEffect(eff, _itemEff, effect1Key, 100)
    else
        self:DestroyWndEffectByKey(effect1Key)
    end

    local effect2Key = eff2:GetInstanceID()
    if isSpecialBox then
        self:CreateWndEffect(eff2, _specialEff, effect2Key, 100)
    else
        self:DestroyWndEffectByKey(effect2Key)
    end

    local rewards = LxDataHelper.SevenParseItems(itemdata.items)
    local reward = rewards[1]
    local func = function()
        if status == 1 then
            --一键领取
            self:OnClickOneKeyGet()
        elseif isMend then
            --补签
            local costItem = self:GetTraceSignCostByIndex(_repairTime + 1)        --补签消耗
            local costItemNum = costItem.itemNum
            local costItemId = costItem.itemId
            gModelGeneral:OpenUIOrdinTips({ refId = 110036, para = { costItemNum }, func = function(...)
                local isEnough = gModelGeneral:CheckItemEnough(costItemId, costItemNum, true)
                if not isEnough then
                    return
                end
                gModelActivity:OnActivitySpecialOpReq(_sid, itemdata.pageId, itemdata.entryId, ModelActivity.SIGN_IN_REPAIR)
            end, consume = { costItemNum, costItemId } })

            --GF.OpenWnd("UIOrdinTip",{refId = 110036,para = {costItem.itemNum},func = function (...)
            --	local isEnough = gModelGeneral:CheckItemEnough(costItem.itemId,costItem.itemNum,true)
            --	if not isEnough then
            --		return
            --	end
            --	gModelActivity:OnActivitySpecialOpReq(_sid,itemdata.pageId,itemdata.entryId,ModelActivity.SIGN_IN_REPAIR)
            --end})
        elseif isAgain then
            --再领取一次
            local againEntryCfg = gModelActivity:GetWebActivityEntryData(_sid, againItemdata.pageId, againItemdata.entryId)
            local jumpId = againEntryCfg.jumpId
            GF.OpenWnd("UIOrdinTip", { refId = 110001, func = function(...)
                local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId, true)
                if isOpen then
                    gModelFunctionOpen:Jump(jumpId, nil, function()
                        gModelActivity:OnActivityPageReq(_sid)
                    end)
                end
            end })
        elseif isAgain2 then
            --再领取一次
            self:OnClickGet(againItemdata2)
        else
            gModelGeneral:ShowCommonItemTipWnd(reward)
            --gModelGeneral:OpenItemInfoTipsFormChat(reward)
        end
    end

    self:SetWndClick(btnMend, function()
        if func then
            func()
        end
    end)
    self:SetWndClick(btnAgain, function()
        if func then
            func()
        end
    end)
    self:SetWndClick(btnGet, function()
        if func then
            func()
        end
    end)
    self:InitCommonIcon(InstanceID, itemRoot, reward, function()
        gModelGeneral:ShowCommonItemTipWnd(reward)
    end, isSpecialBox)
end

function UISubMonthSignIn:InitEvent()
    self:SetWndClick(self.mBtnHelp, function()
        self:OnClickHelp()
    end)
end

function UISubMonthSignIn:InitMessage()
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:ResetData(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        self:RefreshData()
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
        if sid ~= self._sid then
            return
        end
        self:OnActivityConfigData()
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        gModelActivity:OnActivityPageReq(self._sid)
    end)
end

function UISubMonthSignIn:InitCommonIcon(key, root, itemInfo, func, isSpecialBox)
    --local baseClass = self._commonIconList[key]
    --if not baseClass then
    --	baseClass = CommonIcon:New()
    --	self._commonIconList[key] = baseClass
    --	baseClass:Create(root)
    --	self:SetIconClickScale(root, true)
    --end
    --
    --baseClass:SetCommonReward(itemInfo.itemType, itemInfo.itemId, itemInfo.itemNum)
    --baseClass:EnableShowNum(true)
    --baseClass:DoApply()
    self:CreateCommonIconImpl(root, itemInfo)
    local iconBgPath = self._specialBox
    if not isSpecialBox then
        local icon, iconBg = gModelItem:GetItemImgByRefId(itemInfo.itemId)
        iconBgPath = iconBg
    end
    local instanceId = root:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceId)
    if baseClass then
        baseClass:SetQualityBgIcon(iconBgPath)
    end

    self:SetWndClick(root, function()
        if func then
            func()
        end
    end)
end

function UISubMonthSignIn:GetTraceSignCostByIndex(index)
    local _traceSignCost = self._traceSignCost or {}
    local len = #_traceSignCost
    if index > len then
        return _traceSignCost[len]
    end
    return _traceSignCost[index]
end

function UISubMonthSignIn:OnClickGet(itemdata)
    --领取
    local status = itemdata.goalData.status
    if status ~= 1 then
        return
    end
    gModelActivity:OnActivityReceiveGoalReq(self._sid, itemdata.pageId, itemdata.entryId)
end

function UISubMonthSignIn:BoxListItem(list, item, itemdata, itempos)
    local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, itemdata.pageId, itemdata.entryId)
    local icon = self:FindWndTrans(item, "Icon")
    --local mask = self:FindWndTrans(item,"Mask")
    local numText = self:FindWndTrans(item, "NumText")
    local eff = self:FindWndTrans(item, "Icon/Eff")

    local _boxIcon = self._boxIcon or {}
    local status = itemdata.goalData.status
    local boxIcon = _boxIcon[status + 1]
    self._boxItemList[itemdata.entryId] = icon
    self:SetWndEasyImage(icon, boxIcon)
    --self:SetWndEasyImage(mask,boxIcon)
    self:SetWndText(numText, entryCfg.name)
    CS.ShowObject(eff, status == 1)
    if status == 1 and self._boxEff then
        local key = "box" .. itemdata.entryId
        self:CreateWndEffect(eff, self._boxEff, key, 100)
    end
    CS.ShowObject(eff, false)

    self:SetWndClick(icon, function()
        self:OnClickBox(itemdata)
    end)
end

function UISubMonthSignIn:InitCommand()
    self:SetWndText(self.mNameText, ccClientText(25600))
    self._sid = self:GetWndArg("sid")
    local _page = self:GetWndArg("page") --支持跳转
    local _subPage = self:GetWndArg("subPage")
    if _subPage then
        self._sid = gModelActivity:GetSidByUniqueJump(_subPage)
    end
    gModelActivity:ReqActivityConfigData(self._sid)
end
------------------------------------------------------------------
return UISubMonthSignIn


