---
--- 活动80 周年签到
--- Created by Ease.
--- DateTime: 2023/10/4 18:01:11
---
---活动80--签到界面调整
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAnnSign:LWnd
local UIAnnSign = LxWndClass("UIAnnSign", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAnnSign:UIAnnSign()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAnnSign:OnWndClose()
    if (self._loginRewardList) then
        self._loginRewardList:OnWndClose()
    end
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAnnSign:OnCreate()

    local sid = self:GetWndArg("sid")
    gModelGuide:SetActivityGuildData(sid)
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAnnSign:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()    --初始化预设引用

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    
    if self._isEnus then 
        LxUiHelper.SetSizeWithCurAnchor(self.mTimeBg,0,300)
    end 
    
    self:InitStaticContent()
    self:InitEvent() --初始化事件
    self:InitBtnEvent()
    self:InitMessage()   --初始化协议
    self:InitData()  --初始化数据
end
function UIAnnSign:SetTransPos(imgTrans, offset)
    if (offset and not string.isempty(offset)) then
        local pos = LxDataHelper.ParseVector2NotEmpty2(offset)
        self:SetAnchorPos(imgTrans, pos)
    end
end
function UIAnnSign:SetBgImgAndPos(imgTrans, imgPath, offset, isNativeSize)
    if (imgPath) then
        if (imgPath == "") then
            CS.ShowObject(imgTrans, false, nil, isNativeSize)
            return
        end
        self:SetWndEasyImage(imgTrans, imgPath, nil, isNativeSize)
        self:SetTransPos(imgTrans, offset)
    end
    CS.ShowObject(imgTrans, imgPath ~= nil)
end

function UIAnnSign:CreateEffect(trans, effectName, effectKey, effectSize)
    effectKey = effectKey or trans:GetInstanceID()
    effectSize = effectSize or 100
    self:CreateWndEffect(trans, effectName, effectKey, effectSize, false, false)
end
function UIAnnSign:RefreshUI()
    self:InitLoginList()
    self:RefreshShowTime()
end
function UIAnnSign:SetData()
    local cfgData = self._cfgData --配置表f
    local activityData = gModelActivity:GetActivityBySid(self._sid)--activity pb
    if (not cfgData or not activityData) then
        return
    end
    local cfg = cfgData.config
    self._signHelpTips = cfg.signHelpTips or ""        --帮助窗口描述
    self._signHelpTitle = gModelActivity:GetLngNameByActivitySid(self._sid) or ""     --帮助窗口标题
    self._signHelpTipsPos = cfg.signHelpTipsPos     --帮助窗口标题

    self._signImageName = cfg.signImage --背景图
    self._headLine = cfg.headline    --艺术字标题
    self._signHeroImage = cfg.signImageHero

    self._signImageNamePos = cfg.signImagePos --背景图偏移 x|y
    self._headLinePos = cfg.headlinePos --偏移 x|y
    self._signHeroImagePos = cfg.signImageHeroPos --偏移 x|y

    self._endActivityTime = activityData.endTime --活动结束事件

    --9.2新增字段
    self._uiPrefab = cfg.uiPrefab
    self._timeColor = cfg.timeTxtColor --剩余时间颜色
    self._timePos = cfg.timePos
    self._availableImage = cfg.availableImage --道具底图
    self._unavailableImage = cfg.unavailableImage --道具底图
    self._availableDaysColor = cfg.availableDaysColor
    self._unavailableDaysColor = cfg.unavailableDaysColor
    self._availableItemColor = cfg.availableItemColor
    self._unavailableItemColor = cfg.unavailableItemColor
    self._lockImage = cfg.lockImage
    self._maskImage = cfg.maskImage
    --self._availableEffectShow = cfg.availableEffectShow --显示页签按钮
    self._btnIconShow = cfg.btnIconShow --显示页签按钮
    self._btnIcon = cfg.btnIcon --显示页签按钮
    --self._availableEffect = cfg.availableEffect --显示道具特效

    --24.5.27新增字段
    self._isNew = cfg.isNew or 0
    printErrorN("size " .. cfg.availableEffectSize)
    if not string.isempty(cfg.availableEffect) then
        local strs = string.split(cfg.availableEffect, "=")
        local effPara = {
            resType = tonumber(strs[1]),
            resName = strs[2]
        }

        self._availableEffect = effPara
        self._availableEffectSize = cfg.availableEffectSize
    end
    self._privilegeHeroTurn = cfg.privilegeHeroTurn --显示道具特效
    self:SetUI()
end
function UIAnnSign:InitLoginList()

    local loginRewardListTrans

    --这里插入第三个页签
    if self._isNew == 1 then
        CS.ShowObject(self.mLoginRewardList2, false)
        CS.ShowObject(self.mLoginRewardList, false)
        CS.ShowObject(self.mLoginRewardList3, true)

        loginRewardListTrans = self.mLoginRewardList3
    else
        loginRewardListTrans = self._uiPrefab == 1 and self.mLoginRewardList2 or self.mLoginRewardList
        CS.ShowObject(self.mLoginRewardList2, self._uiPrefab == 1)
        CS.ShowObject(self.mLoginRewardList, self._uiPrefab ~= 1)
        CS.ShowObject(self.mLoginRewardList3, false)
    end

    local list = self._entry

    if (self._loginRewardList) then
        self._loginRewardList:RefreshList(list)
    else
        self._loginRewardList = self:GetUIScroll("mRewardList")
        if self._isNew == 1 then
            self._loginRewardList:Create(loginRewardListTrans, list, function(...)
                self:OnDrawItemCell_New(...)
            end, UIItemList.SUPER_GRID)
        else
            self._loginRewardList:Create(loginRewardListTrans, list, function(...)
                self:OnDrawItemCell(...)
            end, UIItemList.SUPER_GRID)
        end

    end
    local curIndex = self:GetActivityListCanGetIndex()
    self._loginRewardList:DrawAllItems()
    if curIndex and curIndex > 4 then
        self._loginRewardList:MoveToPos(curIndex)
    end

    --if(self._uiPrefab ==1)then
    --	local typeofLoopGridView = typeof(SuperScrollView.LoopGridView)
    --	if not typeofLoopGridView then
    --		return
    --	end
    --	local gridView = self.mLoginRewardList:GetComponent(typeofLoopGridView)
    --	if not CS.IsValidObject(gridView) then
    --		return
    --	end
    --	gridView.ItemPadding = Vector2.New(15,35)
    --end
end
function UIAnnSign:OnClickGet(itempos)
    if not self._entry then
        return
    end
    local list = {}
    for k, v in ipairs(self._entry) do
        if v.status == 1 then
            local data = { sid = self._sid, pageId = v.webData.pageId, entryId = v.webData.entryId }
            table.insert(list, data)
        end
    end
    gModelActivity:OnActivityReceiveGoalListReq(list)
end
function UIAnnSign:OnActivityPageResp(pb, ret)
    local sid = pb.sid
    if sid ~= self._sid then
        return
    end
    local page = pb.pages[1]
    local pageId = page.pageId
    local pageData = gModelActivity:GenerateActivePageDataFromPb(page)
    local entry = {}
    for i, v in ipairs(pageData.entry) do
        local entryCfg = gModelActivity:GetWebActivityEntryData(sid, pageId, v.entryId)
        local data = {}
        data.webData = v
        data.title = entryCfg.name
        data.desc = entryCfg.description
        data.moreInfo = entryCfg.moreInfo
        data.status = v.status or v.goalData.status
        data.rewards = LxDataHelper.ParseItem(entryCfg.reward)
        data.isNewCondition_Copletion = tonumber(pageData.moreInfo) == 1
        table.insert(entry, data)
    end    --后端已经排序
    self._page = pageData
    self._entry = entry
    self:RefreshUI()
end
function UIAnnSign:InitMessage()
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:OnActivityPageResp(pb)
    end)
end
function UIAnnSign:InitEvent()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        gModelActivity:OnActivityPageReq(self._sid)
    end)
end

function UIAnnSign:InitStaticContent()
    self:SetWndText(self.mTxtClose, ccClientText(30205))
end
function UIAnnSign:SetTransColor(trans, color)
    if (color) then
        local txtCmp = trans:GetComponent("YXUIText")
        local txtCmpColorHex = LUtil.ColorByHex_6(tostring(color))
        if txtCmpColorHex then
            txtCmp.color = txtCmpColorHex
        end
    end
end

function UIAnnSign:OnDrawItemCell_New(list, item, itemdata, itempos)
    --节点
    local Icon = self:FindWndTrans(item, "Icon")
    local Mask = self:FindWndTrans(item, "Mask")
    local CanGet = self:FindWndTrans(item, "CanGet")
    local Day = self:FindWndTrans(item, "Day")
    local EffRoot = self:FindWndTrans(item, "EffRoot")



    --信息
    local reward = itemdata.rewards[1]
    local status = itemdata.status

    --道具
    local instanceID = Icon:GetInstanceID()

    if not self._uiCommonList then
        self._uiCommonList = {}
    end

    local baseClass = self._uiCommonList[instanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        self._uiCommonList[instanceID] = baseClass
        baseClass:Create(Icon)
    end
    baseClass:SetCommonReward(reward.itemType, reward.itemId, reward.itemNum)
    baseClass:DoApply()

    -----设置icon sacle position----
    local entryData = self._cfgData.chunk[1].entries[itempos]
    local chunkMoreInfo = entryData.moreInfo
    local itemMoreInfoArr = string.split(chunkMoreInfo, "|")
    if (itemMoreInfoArr) then
        local itemScale = itemMoreInfoArr[1]
        if (itemScale) then
            Icon.localScale = Vector3.New(itemScale, itemScale, 1)
        end
        if (itemMoreInfoArr[2]) then
            local itemPos = LxDataHelper.ParseVector2NotEmpty(itemMoreInfoArr[2])
            self:SetAnchorPos(Icon, itemPos)
            self:SetAnchorPos(Mask, itemPos)
            self:SetAnchorPos(CanGet, itemPos)
        end
    end

    --天数
    local dayStr = string.replace(ccClientText(15706), itempos)
    self:SetWndText(Day, dayStr)

    local color = status ~= 0 and self._availableDaysColor or self._unavailableDaysColor
    if not string.isempty(color) then
        self:SetTransColor(Day, color)
    end

    --状态   0 的lock 状态不试用  canget的设置
    local showAviEffect = self._availableEffect ~= nil
    local showOnSel = status == 1

    CS.ShowObject(CanGet, showOnSel and showAviEffect)

    if showAviEffect then
        local resType = self._availableEffect.resType  --1=特效，2=动效，3=图片资源
        local resName = self._availableEffect.resName
        local itemInstanceID = EffRoot:GetInstanceID()
        if resType == 1 then
            if status == 1 then
                self:CreateWndEffect(EffRoot, resName, itemInstanceID, 100)
            else
                self:DestroyWndEffectByKey(itemInstanceID)
            end
        elseif (resType == 2) then
            if status == 1 then
                self:CreateWndSpine(EffRoot, resName, itemInstanceID, nil, nil, nil, true)
            else
                self:DestroyWndSpineByKey(itemInstanceID)
            end
        elseif (resType == 3) then
            self:SetWndEasyImage(CanGet, resName)
            local size = string.split(self._availableEffectSize, ",")
            if (size and #size > 0) then
                CanGet.sizeDelta = Vector2.New(size[1], size[2])
            end
        end
    end

    CS.ShowObject(Mask, status == 2)

    --点击
    --item点击事件
    self:SetWndClick(item, function()
        self:ClickLoginCell(itempos, itemdata)
    end)
end
--loginRewardedItem点击事件
function UIAnnSign:ClickLoginCell(itempos, itemdata)
    local status = itemdata.status or itemdata.goalData.status
    local reward = itemdata.rewards[1]
    if (status == 1) then
        if self._isLimit == 1 then
            if not itemdata.isNewCondition_Copletion then
                GF.ShowMessage(self._conTxt)
                return
            end
        end

        self:OnClickGet(itempos)
    else
        gModelGeneral:ShowCommonItemTipWnd(reward)
    end
end
function UIAnnSign:OnDrawItemCell(list, item, itemdata, itempos)
    local itemTrans1 = self:FindWndTrans(item, "Template1")
    local itemTrans2 = self:FindWndTrans(item, "Template2")
    CS.ShowObject(itemTrans1, false)
    CS.ShowObject(itemTrans2, false)

    local useTemp2 = self._uiPrefab == 1
    local itemTrans = useTemp2 and itemTrans2 or itemTrans1

    CS.ShowObject(itemTrans, true)
    local NoSelImg = self:FindWndTrans(itemTrans, "NoSelImg")
    local SelImg = self:FindWndTrans(itemTrans, "SelImg")
    local Icon = self:FindWndTrans(itemTrans, "Icon")

    -----设置icon sacle position----
    local entryData = self._cfgData.chunk[1].entries[itempos]
    local chunkMoreInfo = entryData.moreInfo
    local itemMoreInfoArr = string.split(chunkMoreInfo, "|")
    if (itemMoreInfoArr) then
        local itemScale = itemMoreInfoArr[1]
        if (itemScale) then
            Icon.localScale = Vector3.New(itemScale, itemScale, 1)
        end
        if (itemMoreInfoArr[2]) then
            local itemPos = LxDataHelper.ParseVector2NotEmpty(itemMoreInfoArr[2])
            self:SetAnchorPos(Icon, itemPos)
        end
    end
    -------------------------------------

    local ItemName = self:FindWndTrans(itemTrans, "ItemName")
    local DayTxt = self:FindWndTrans(itemTrans, "DayTxt")
    local StatesImg = self:FindWndTrans(itemTrans, "StatesImg")
    local OnSelImg = self:FindWndTrans(itemTrans, "OnSelImg")
    local RedPointImg = self:FindWndTrans(itemTrans, "redPoint")    --红点
    local canGetImg = self:FindWndTrans(itemTrans, "CanGetImg")    --红点
    local rewardList = itemdata.rewards
    local reward = rewardList[1]
    local itemId = reward.itemId
    local status = itemdata.status
    local curIndex = self:GetActivityListCanGetIndex()
    local iconPath = gModelGeneral:GetCommonItemImgRef(reward)    --道具图标
    local iconName = gModelGeneral:GetCommonItemName(reward)
    local itemCntStr = tostring(itemdata.webData.items[1].count)
    --local iconCnt = self._uiPrefab == 1 and "" or LUtil.FormatColorStr(" X" .. tostring(itemdata.webData.items[1].count), "blue")
    --iconName = iconName .. iconCnt

    if self._uiPrefab == 0 then
        iconName = ""
    end

    self:SetWndEasyImage(Icon, iconPath, nil, true)
    self:SetWndText(ItemName, iconName)
    --LStringUtil.NumberToCN(itempos)
    local dayStr = string.replace(ccClientText(15706), itempos)
    self:SetWndText(DayTxt, dayStr)
    --self:SetWndEasyImage(StatesImg, "public_txt_13_1", nil, true)
    CS.ShowObject(StatesImg, status == 2)
    CS.ShowObject(NoSelImg, status == 0)
    CS.ShowObject(SelImg, status ~= 0)
    local canGet = status == 1
    CS.ShowObject(RedPointImg, false)

    local showAviEffect = self._availableEffect ~= nil and useTemp2
    local showOnSel = self._uiPrefab == 0 and canGet
    CS.ShowObject(OnSelImg, showOnSel)
    --CS.ShowObject(OnSelImg, status ~= 0 and itemdata.webData.sort == curIndex and self._uiPrefab ~= 1)
    CS.ShowObject(canGetImg, canGet and showAviEffect)
    if showAviEffect then
        local EffRoot = self:FindWndTrans(itemTrans, "EffRoot")
        local itemInstanceID = EffRoot:GetInstanceID()
        CS.ShowObject(EffRoot, status == 1)
        local resType = self._availableEffect.resType
        local resName = self._availableEffect.resName
        if resType == 2 then
            if status == 1 then
                self:CreateWndSpine(EffRoot, resName, itemInstanceID, nil, nil, nil, true)
            else
                self:DestroyWndSpineByKey(itemInstanceID)
            end
        elseif (resType == 3) then
            self:SetWndEasyImage(canGetImg, resName)
            local size = string.split(self._availableEffectSize, ",")
            if (size and #size > 0) then
                canGetImg.sizeDelta = Vector2.New(size[1], size[2])
            end
        else
            if status == 1 then
                self:CreateWndEffect(EffRoot, resName, itemInstanceID, 100)
            else
                self:DestroyWndEffectByKey(itemInstanceID)
            end
        end
        if (resType ~= 3) then
            CS.ShowObject(canGetImg, false)
        end
    end
    --item点击事件
    self:SetWndClick(itemTrans, function()
        self:ClickLoginCell(itempos, itemdata)
    end)
    self:SetTransImg(NoSelImg, self._unavailableImage)
    self:SetTransImg(SelImg, self._availableImage)
    self:SetTransImg(StatesImg, self._maskImage)
    if (self._lockImage) then
        local lockTrans = self:FindWndTrans(NoSelImg, "Image")
        self:SetTransImg(lockTrans, self._lockImage)
    end
    local itemCntTxt = self:FindWndTrans(itemTrans, "ItemCntTxt")
    if (itemCntTxt) then
        self:SetWndText(itemCntTxt, itemCntStr)
    end
    local color = status ~= 0 and self._availableDaysColor or self._unavailableDaysColor
    if not string.isempty(color) then
        self:SetTransColor(DayTxt, color)
    end
    color = status ~= 0 and self._availableItemColor or self._unavailableItemColor
    if not string.isempty(color) then
        self:SetTransColor(ItemName, color)
    end
end
--窗口背景以及艺术字标题
function UIAnnSign:SetUI()
    self:SetTransPos(self.mTimeBg, self._timePos)
    CS.ShowObject(self.mTimeBg, true)
    self:SetTransColor(self.mTimeTxt, self._timeColor)
    self:SetBgImgAndPos(self.mBgImg, self._signImageName, self._signImageNamePos)
    self:SetBgImgAndPos(self.mTxtImage, self._headLine, self._headLinePos, true)
    if (not string.isempty(self._signHelpTipsPos)) then
        self:SetTransPos(self.mHelpBtn, self._signHelpTipsPos)
    end
    self:SetHeroGroup()
    --self:SetBgImgAndPos(self.mHeroImage, self._signHeroImage, self._signHeroImagePos)
end
function UIAnnSign:SetPageBtn()
    local btnCfg = self._btnIcon
    if (not btnCfg) then
        return
    end
    local cfgArr = string.split(btnCfg, "=")
    local btnTxtTrans = self:FindWndTrans(self.mPageBtn, "NameText")
    local btnTrans = self:FindWndTrans(self.mPageBtn, "Icon")
    self:SetWndText(btnTxtTrans, cfgArr[4])
    self:SetBgImgAndPos(btnTrans, cfgArr[3])
end
--倒计时
function UIAnnSign:ShowTimerFunc()
    local nowTime = GetTimestamp()
    local timeDif = os.difftime(self._endTime, nowTime)
    if timeDif <= 0 then
        self:StopShowTimer()
        return
    end
    local timeStr = LUtil.FormatTimespanCn(timeDif)
    timeStr = string.replace(ccClientText(11637), timeStr)--11637 剩余时间
    self:SetWndText(self.mTimeTxt, timeStr)
end
function UIAnnSign:OnTryTcpReconnect()
    gModelActivity:ReqActivityConfigData(self._sid)
end
function UIAnnSign:InitBtnEvent()
    self:SetWndClick(self.mHelpBtn, function()
        local title = self._signHelpTitle
        local helpTips = self._signHelpTips
        local helpData = { title = title, text = helpTips }
        GF.OpenWnd("UIBzTips", helpData)
    end)
    self:SetWndClick(self.mCloseBtn, function()
        if (self._enterSid) then
            local activityData = gModelActivity:GetActivityBySid(self._enterSid)
            local func = gModelActivity:GetShowActivityFun(activityData.model)
            if func then
                func(activityData)
            end
        end
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end
function UIAnnSign:RefreshShowTime()
    local timeValue = self._endActivityTime or 0
    self._endTime = timeValue
    local showTime = self._endTime > 0
    CS.ShowObject(self.mTimeBg, showTime)
    if not showTime then
        return
    end
    self:ShowTimerFunc()
    self:TimerStart(self._showTimeKey, 1, false, -1)
end
function UIAnnSign:StopShowTimer()
    self:TimerStop(self._showTimeKey)
    --self:WndClose()
end
function UIAnnSign:OnTimer(key)
    if key == self._showTimeKey then
        self:ShowTimerFunc()
    end
end
function UIAnnSign:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end
    self._cfgData = data

    self._isLimit = self._cfgData.config.isLimit
    self._conTxt = self._cfgData.config.conTxt

    self:SetData()
    if (self._btnIconShow and self._btnIconShow == 1) then
        self:SetPageBtn()
    end
    CS.ShowObject(self.mPageBtn, self._btnIconShow and self._btnIconShow == 1)
    gModelActivity:OnActivityPageReq(self._sid)
end
--设置伙伴立绘/spine
function UIAnnSign:SetHeroGroup()
    local heroCfgArr = string.split(self._signHeroImage, "=")
    CS.ShowObject(self.mHeroImage, heroCfgArr[1] == "1")
    CS.ShowObject(self.mShowSpine, heroCfgArr[1] == "2")
    local assetName = heroCfgArr[2]
    if (heroCfgArr[1] == "1") then
        self:SetBgImgAndPos(self.mHeroImage, assetName, self._signHeroImagePos)
    elseif (heroCfgArr[1] == "2") then
        self:CreateSpine("TopSpine", self.mShowSpine, assetName, self._signHeroImagePos, self._privilegeHeroTurn)
    else
        self:SetBgImgAndPos(self.mHeroImage, self._signHeroImage, self._signHeroImagePos)
    end
end
------------------------------------------------------------------
-----初始化数据
function UIAnnSign:InitData()
    self._sid = self:GetWndArg("sid")
    local subpage = self:GetWndArg("subPage") --支持跳转
    if subpage then
        self._sid = gModelActivity:GetSidByUniqueJump(subpage)
    end
    self._showTimeKey = "_endTimeKey"
    self._enterSid = self:GetWndArg("enterSid")
    CS.ShowObject(self.mTopGroup, true)
    CS.ShowObject(self.mMaskBg, true)

    --gModelGuide:SetActivityGuildData(self._sid)

    gModelActivity:ReqActivityConfigData(self._sid)
end
function UIAnnSign:GetActivityListCanGetIndex()
    local index
    if not self._entry then
        return index
    end
    for k, v in ipairs(self._entry) do
        local status = v.status
        if status == 1 then
            index = k
        end
    end
    if (index) then
        return index
    end
    for k, v in ipairs(self._entry) do
        local status = v.status
        if status == 2 then
            index = k
        end
    end
    index = index or 1
    return index
end

function UIAnnSign:SetTransImg(imgTrans, path, isNativeSize)
    if (imgTrans and path) then
        self:SetWndEasyImage(imgTrans, path, nil, isNativeSize)
    end
end
function UIAnnSign:CreateSpine(key, spineRoot, spineName, pos, isTurn)
    self:DestroyWndSpineByKey(spineName)
    self:CreateWndSpine(spineRoot, spineName, key, false, function(dpSpine)
        dpSpine:SetIgnoreTimeScale(true)
    end)
    local scaleX = (isTurn and isTurn == 1) and -1 or 1
    if (pos) then
        self:SetAnchorPos(spineRoot, LxDataHelper.ParseVector2NotEmpty2(pos))
    end
    spineRoot.localScale = Vector3.New(scaleX, 1, 1)
end
return UIAnnSign