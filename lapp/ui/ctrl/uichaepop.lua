---
--- Created by BY.
--- DateTime: 2023/10/27 21:16:25
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIChaePop:LWnd
local UIChaePop = LxWndClass("UIChaePop", LWnd)
local typeof = typeof
local UnityEngine = UnityEngine
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIChaePop:UIChaePop()
    self._tabList = {}
    self._tabRedList = {}
    self._typeList = {}
    self._typeRedList = {}
    self._timeKey = "timeKey"
    self._activateList = {}
    self._useIdList = {}                --使用中数据
    self._currIdList = {}                --当前选择数据
    --self._redTabTypeKey = {}
    self._infoMarList = {
        [ModelPlayerSpace.ROLE_HEAD] = true,
        [ModelPlayerSpace.ROLE_HEADFRAME] = true,
        [ModelPlayerSpace.ROLE_TITLE] = true,
        [ModelPlayerSpace.ROLE_FIGURE] = true,
        -- [ModelPlayerSpace.ROLE_MEDAL] = true,
        [ModelPlayerSpace.BACKGROUND] = true,
        [ModelPlayerSpace.BUBBLE] = true
    }
    self._tagMarList = {
        --[ModelPlayerSpace.ROLE_TAG] = true
        [ModelPlayerSpace.ROLE_TAG] = false
    }
    self._tabType = nil                            --选择的类型
    self._type = nil                            --选择的小类型
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIChaePop:OnWndClose()
    -- self:CleanDragList()
    --self:OnReqRed()
    self:OnReqTypeRed({ self._tabType .. "-" .. self._type })
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIChaePop:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIChaePop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isForeignVersion = gLGameLanguage:IsForeignVersion()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    
    if self._isEnus then 
        self:SetAnchorPos(self.mTimeText,Vector2.New(205.8,-85))
        self:SetAnchorPos(self.mArrtText,Vector2.New(-64,-105))
    end

    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    self:RefreshTabRed()
    -- self:InitDragList()
    if gLGameLanguage:IsJapanRegion() then
        if PRODUCT_G_VER~=0 then
            CS.ShowObject(self.mChatBg,false)
            CS.ShowObject(self.mTitleImg,false)
        end
    end
end
function UIChaePop:OnClickTab(tabType, itempos)
    local _tabList = self._tabList
    local _tabType = self._tabType
    if _tabType then
        if _tabType == tabType then
            return
        end
        self._oldTabType = _tabType
        self:SetWndTabStatus(_tabList[_tabType], 1)
    end
    self._tabType = tabType
    self:SetWndTabStatus(_tabList[tabType], 0)

    self:RefreshTabType()
    self:RefreshData()
    self:RefreshTypeRed()

    if itempos then
        local wndPara = {
            wndName = self:GetWndName(),
            para1 = itempos,
            para2 = 1,
        }

        FireEvent(EventNames.ON_WND_OPEN_TRIGGER, wndPara) --指引触发条件
    end
end
--点击有红点的小标签
function UIChaePop:OnClickRedPoint(type, refId)
    local _redPointList = self:GetRedPointListByType(type)
    _redPointList[refId] = false
    self._redPointList[type] = _redPointList
    self:RefreshTabRed()
end
function UIChaePop:OnClickHeroIcon(refId, type)
    self._currIdList[type] = refId
    self:RefreshData()
end
--数据变更时刷新 使用列表 当前选择列表 数据
function UIChaePop:RefreshUseList()
    self._useIdList = {
        [ModelPlayerSpace.ROLE_HEAD] = gModelPlayer:GetPlayerHead(),
        [ModelPlayerSpace.ROLE_HEADFRAME] = gModelPlayer:GetPlayerHeadFrame(),
        [ModelPlayerSpace.ROLE_TITLE] = gModelPlayer:GetPlayerTitle(),
        -- [ModelPlayerSpace.ROLE_MEDAL] = gModelPlayer:GetBadge(),
        --[ModelPlayerSpace.ROLE_TAG] = gModelPlayer:GetPlayerTags(),
        [ModelPlayerSpace.BACKGROUND] = gModelPlayer:GetBackGround(),
        [ModelPlayerSpace.BUBBLE] = gModelPlayer:GetBubble(),
    }
    self._currIdList = table.clone(self._useIdList)
end
--点击大标签时发送取消大标签红点请求
function UIChaePop:OnReqTypeRed(keys)
    local list = {}
    for i, v in pairs(keys) do
        table.insert(list, v)
    end
    if #list > 0 then
        gModelPlayerSpace:OnPersonaliseClickInfoReq(list)
    end
end
---------------------------------------获取数据-------------------------------------------
---------------------------------------点击---------------------------------------------
function UIChaePop:OnClickClose()
    local list = self:GetSaveData()
    local isSave = false
    for i, v in pairs(list) do
        if v ~= nil then
            isSave = true
            break
        end
    end
    if not isSave then
        self:WndClose()
        return
    end
    gModelGeneral:OpenUIOrdinTips({ refId = 50008, func = function()
        self:OnClickSave(true)
        self:WndClose()
    end, leftFunc = function()
        self:WndClose()
    end })
end
function UIChaePop:HeadListItem(list, item, itemdata, itempos)
    if not itemdata then
        return
    end
    local root = CS.FindTrans(item, "HeadUI")
    local headImage = CS.FindTrans(root, "HeadBg/HeadImage")
    local mask = CS.FindTrans(root, "Mask")
    local isTrue = CS.FindTrans(root, "IsTrue")
    local isSel = CS.FindTrans(root, "IsSel")
    local isUse = CS.FindTrans(root, "IsUse")
    local noUse = CS.FindTrans(root, "NoUse")
    local redPoint = CS.FindTrans(item, "redPoint")

    local refId = itemdata.refId
    local type = itemdata.type
    local useId = self._useIdList[self._tabType]
    local _currSelId = self._currSelId
    local activateLis = self._activateList[self._tabType] or {}
    local isActivate = activateLis[refId] and activateLis[refId].state == 0
    local isRed = self:GetRedPoint(type, refId)
    local isCurrSel = refId == _currSelId
    self:SetWndEasyImage(headImage, itemdata.icon)
    CS.ShowObject(mask, not isActivate)
    CS.ShowObject(noUse, not isActivate)
    -- self:SetImageAlpha(headImage, isActivate and 1 or 0.3)
    --CS.ShowObject(isTrue,itemdata.refId == _currSelId)
    CS.ShowObject(isUse, useId == refId)
    CS.ShowObject(isSel, isCurrSel)
    CS.ShowObject(redPoint, isRed and not isCurrSel)
    if isRed and isCurrSel then
        self:OnClickRedPoint(type, refId)
    end

    self:SetWndClick(root, function()
        self:OnClickHeroIcon(itemdata.refId, itemdata.type)
        local bubbleId = self._currIdList[ModelPlayerSpace.BUBBLE]
        local bubbleRef = gModelPlayer:GetRolePlayerHeadRefByRefId(bubbleId)
        self:SetBubbleImg(self.mChatBg, bubbleRef, ccClientText(21185))
    end)
    if self._tabType == ModelPlayerSpace.ROLE_TITLE then
        self:SetWndLongClick(root, function()
            local playerName
            if isActivate then
                playerName = gModelPlayer:GetPlayerName()
            end
            GF.OpenWnd("UIPerSpreadPop", { StructPersonaliseInfo = { refId = refId, playerName = playerName } })
        end, 0.8, false)
    end
end
---------------------------------------个性标签-------------------------------------------
---------------------------------------个性背景-------------------------------------------
function UIChaePop:RefreshBackGroundList()
    local _tabType = self._tabType
    local _roleTypes = self._roleTypes
    local _type = self._type
    if _tabType ~= ModelPlayerSpace.BACKGROUND then
        return
    end
    local list = {}
    local refs = gModelPlayer:GetRolePlayerHeadListByType(_tabType)
    for i, v in pairs(refs) do
        if _type == v.subType then
            table.insert(list, v)
        end
    end
    table.sort(list, function(a, b)
        return a.refId < b.refId
    end)
    for i, v in pairs(_roleTypes) do
        CS.ShowObject(v, false)
    end
    local uiListTrans = _roleTypes[_tabType]
    if uiListTrans then
        CS.ShowObject(uiListTrans, true)
        local _uiList = self:GetUIScroll(_tabType)
        local _uiListSuper = _uiList:GetList()
        if _uiListSuper then
            _uiList:RefreshList(list)
            _uiListSuper:DrawAllItems()
        else
            _uiList:Create(uiListTrans, list, function(...)
                self:BackGroundListItem(...)
            end, UIItemList.SUPER_GRID)
            _uiList:EnableScroll(true, false)
        end
    end
end
function UIChaePop:RefreshTagList()
    local _tabType = self._tabType
    local _roleTypes = self._roleTypes
    local _type = self._type
    if _tabType ~= ModelPlayerSpace.ROLE_TAG then
        return
    else
        return
    end
    local list = {}
    local refs = gModelPlayer:GetRolePlayerHeadListByType(_tabType)
    for i, v in pairs(refs) do
        if _type == v.subType then
            table.insert(list, v)
        end
    end
    table.sort(list, function(a, b)
        return a.refId < b.refId
    end)
    for i, v in pairs(_roleTypes) do
        CS.ShowObject(v, false)
    end
    local uiListTrans = _roleTypes[_tabType]
    if uiListTrans then
        CS.ShowObject(uiListTrans, true)
        local _uiList = self:GetUIScroll(_tabType)
        local _uiListSuper = _uiList:GetList()
        if _uiListSuper then
            _uiList:RefreshList(list)
            _uiListSuper:DrawAllItems()
        else
            _uiList:Create(uiListTrans, list, function(...)
                self:TagListItem(...)
            end, UIItemList.SUPER_GRID)
            _uiList:EnableScroll(true, false)
        end
    end
end
function UIChaePop:OnClickBubble(refId, type)
    self._currIdList[type] = refId
    self:RefreshData()
end
function UIChaePop:OnClickShare()
    if not gModelFunctionOpen:CheckIsOpened(11700000, true) then
        return
    end
    local _tabType = self._tabType
    local _currId, shareType
    if _tabType == ModelPlayerSpace.ROLE_TITLE then
        _currId = self._currIdList[_tabType]
        shareType = ModelChat.CHATSHARE_TITLE
    -- elseif _tabType == ModelPlayerSpace.ROLE_MEDAL then
    --     _currId = self._currBadgeId
    --     shareType = ModelChat.CHATSHARE_BADGE
    end

    local _activateList = self._activateList[self._tabType]
    if not _activateList[_currId] or _activateList[_currId].state ~= 0 then
        return
    end
    local jsonStr = JSON.encode(_activateList[_currId])
    local data = {
        root = self.mBtnShare,
        shareType = shareType,
        shareData = jsonStr
    }
    gModelGeneral:OpenShareTip(data)
end
---------------------------------------个性背景-------------------------------------------
---------------------------------------聊天气泡-------------------------------------------
function UIChaePop:RefreshBubbleList()
    local _tabType = self._tabType
    local _roleTypes = self._roleTypes
    local _type = self._type
    if _tabType ~= ModelPlayerSpace.BUBBLE then
        return
    end
    local fList, lList, list = {}, {}, {}
    local refs = gModelPlayer:GetRolePlayerHeadListByType(_tabType)
    for i, v in pairs(refs) do
        if _type == v.subType then
            table.insert(list, v)
        end
    end
    local activateLis = self._activateList[_tabType] or {}
    for _, v in ipairs(list) do
        if activateLis[v.refId] and activateLis[v.refId].state == 0 then
            table.insert(fList, v)
        else
            table.insert(lList, v)
        end
    end
    table.sort(fList, function(a, b)
        return a.refId < b.refId
    end)
    table.sort(lList, function(a, b)
        return a.refId < b.refId
    end)
    list = {}
    for _, v in ipairs(fList) do
        table.insert(list, v)
    end
    for _, v in ipairs(lList) do
        table.insert(list, v)
    end
    for i, v in pairs(_roleTypes) do
        CS.ShowObject(v, false)
    end
    local uiListTrans = _roleTypes[_tabType]
    if uiListTrans then
        CS.ShowObject(uiListTrans, true)
        local _uiList = self:GetUIScroll(_tabType)
        local _uiListSuper = _uiList:GetList()
        if _uiListSuper then
            _uiList:RefreshList(list)
            _uiListSuper:DrawAllItems()
        else
            _uiList:Create(uiListTrans, list, function(...)
                self:BubbleListItem(...)
            end, UIItemList.SUPER_GRID)
            _uiList:EnableScroll(true, false)
        end
    end
end
function UIChaePop:OnClickType(type)
    local _type = self._type
    local _typeList = self._typeList
    if _type then
        self:SetWndTabStatus(_typeList[_type], 1)
    end
    self._type = type
    self:SetWndTabStatus(_typeList[type], 0)
    --local key = self._tabType.."-"..self._type
    --self._redTabTypeKey[key] = true
    self._isOnTypeTab = true
    local _tabType = self._tabType
    if not _tabType then
        return
    end
    self:OnReqTypeRed({ _tabType .. "-" .. type })
end
--获取小标签红点
function UIChaePop:GetRedPoint(type, refId)
    local _redPointList = self:GetRedPointListByType(type)
    return _redPointList[refId]
end
function UIChaePop:OnClickTag(itemdata, isDown)
    local setTagNum = gModelPlayer:GetRoleConfigRefByKey("setTagNum")
    local type = itemdata.type
    local refId = itemdata.refId
    local list = self._currIdList[type] or {}
    local isUpList = false
    for i = 1, setTagNum do
        local id = list[i] or 0
        if isDown then
            if id == refId then
                list[i] = 0
                break
            end
        else
            if id == 0 then
                list[i] = refId
                isUpList = true
                break
            end
        end
    end
    if not isUpList and not isDown then
        GF.ShowMessage(ccClientText(21172))
        self:RefreshData()
        return
    end
    self._currIdList[type] = list
    self:RefreshData()
end
---------------------------------------点击---------------------------------------------
---------------------------------------计时器-------------------------------------------
function UIChaePop:OnTimer(key)
    self:SetTime()
end
function UIChaePop:InitMessage()
    self:WndNetMsgRecv(LProtoIds.PersonaliseChangeResp, function(pb)
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.PersonaliseNewInfoResp, function(pb)
        self:RefreshData()
        self:RefreshTabRed()
    end)
    self:WndNetMsgRecv(LProtoIds.PersonaliseInfoResp, function(pb)
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.PersonaliseChangeTotalResp, function(pb)
        self._isOne = true
        local head = pb.head
        local headFrame = pb.headFrame
        local title = pb.title
        local backGround = pb.backGround
        local bubble = pb.bubble
        local badge = 0
        if pb.badge then
            for i, v in ipairs(pb.badge) do
                badge = 1
            end
        end
        local tag = 0
        if pb.tag then
            for i, v in ipairs(pb.tag) do
                tag = 1
            end
        end
        local list = {
            [1] = head,
            [2] = headFrame,
            [3] = title,
            [5] = badge,
            [6] = tag,
            [7] = backGround,
            [8] = bubble,
        }
        local tipsStr = ""
        local j = 0
        for i, v in pairs(list) do
            if v > 0 then
                if j ~= 0 then
                    tipsStr = tipsStr .. ","
                end
                local name = ""
                local typeRef = gModelPlayerSpace:GetRolePlayerHeadTypeRefByType(i)
                if typeRef then
                    name = ccLngText(typeRef.title)
                end
                tipsStr = tipsStr .. name
                j = j + 1
            end
        end
        local tips = ccClientText(21152)
        GF.ShowMessage(string.replace(tips, tipsStr))
        --self:WndClose()
        self:RefreshUseList()
        self:RefreshData()
    end)

    self:WndNetMsgRecv(LProtoIds.PersonaliseClickInfoResp, function(...)
        local _redPointList = gModelPlayerSpace:GetRedPointList()
        self._redPointList = table.clone(_redPointList)
        self:RefreshTabRed(...)
    end)
end
function UIChaePop:BubbleListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "HeadUI")
    local chatBg = self:FindWndTrans(root, "HeadBg/ChatBg")
    local isSel = self:FindWndTrans(root, "IsSel")
    local isUse = self:FindWndTrans(root, "IsUse")
    local mask = self:FindWndTrans(root, "Mask")
    local noUse = self:FindWndTrans(root, "NoUse")

    self:SetBubbleImg(chatBg, itemdata)
    local refId = itemdata.refId
    local _tabType = self._tabType
    local useId = self._useIdList[_tabType]
    local _currSelId = self._currIdList[_tabType]
    local isCurrSel = refId == _currSelId
    local activateLis = self._activateList[_tabType] or {}
    local isActivate = activateLis[refId] and activateLis[refId].state == 0

    local canvasGroup = chatBg:GetComponent(typeofCanvasGroup)
    canvasGroup.alpha = isActivate and 1 or 0.3

    CS.ShowObject(isUse, useId == refId)
    CS.ShowObject(isSel, isCurrSel)
    CS.ShowObject(mask, not isActivate)
    CS.ShowObject(noUse, not isActivate)
    self:SetWndClick(root, function()
        self:OnClickBubble(itemdata.refId, itemdata.type)
        self:SetBubbleImg(self.mChatBg, itemdata)
    end)
end
function UIChaePop:TagListItem(list, item, itemdata, itempos)
    if not itemdata then
        return
    end

    local root = self:FindWndTrans(item, "HeadUI")
    local tagBg = self:FindWndTrans(root, "TagBg")
    local tagText = self:FindWndTrans(root, "TagBg/TagText")
    local isTrue = self:FindWndTrans(root, "IsTrueBg/IsTrue")

    --local currList = self._currIdList[ModelPlayerSpace.ROLE_TAG]
    local currList = {}
    local _isUse = false
    for i, v in pairs(currList) do
        if v == itemdata.refId then
            _isUse = true
            break
        end
    end

    local tagBgPath = itemdata.tagBg
    local tagTextStr = LUtil.FormatColorStr(ccLngText(itemdata.name), "#" .. itemdata.tagColour)
    self:SetWndEasyImage(tagBg, tagBgPath)
    self:SetWndText(tagText, tagTextStr)

    CS.ShowObject(isTrue, _isUse)
    self:SetWndClick(root, function()
        self:OnClickTag(itemdata, _isUse)
    end)
end
function UIChaePop:InitCommand()
    local page = self:GetWndArg("page")
    local startType = self:GetWndArg("startType") or ModelPlayerSpace.ROLE_HEAD
    local selectRefId = self:GetWndArg("refId")

    self._isForeignFr = gLGameLanguage:IsFrenchVersion()

    self:SetWndText(self.mLblBiaoti, ccClientText(13102))
    local _redPointList = gModelPlayerSpace:GetRedPointList()
    self._redPointList = table.clone(_redPointList)

    local list = gModelPlayerSpace:GetRolePlayerHeadTypeRef()
    if page then
        local item = list[page]
        if item then
            startType = item.type
        end
    end
    if selectRefId then
        self._currIdList[startType] = selectRefId
    end
    local _uiList = self:GetUIScroll("setTab")
    _uiList:Create(self.mTabScroll, list, function(...)
        self:TabListItem(...)
    end)
    if #list > 4 then
        _uiList:EnableScroll(true, true)
    end
    self:OnClickTab(startType)
end
---------------------------------------刷数据---------------------------------------------
---------------------------------------大标签---------------------------------------------
function UIChaePop:TabListItem(list, item, itemdata, itempos)
    local BtnTab1 = CS.FindTrans(item, "BtnTab1")
    local redPoint = CS.FindTrans(item, "redPoint")
    self._tabList[itemdata.type] = BtnTab1
    self._tabRedList[itemdata.type] = redPoint

    local addFontLine = -30
    if gLGameLanguage:IsFrenchVersion() then
        addFontLine = -60
    end

    self:SetWndTabText(BtnTab1, ccLngText(itemdata.title), -4, addFontLine)
    self:SetWndTabStatus(BtnTab1, 1)
    self:SetWndClick(item, function()
        local _activateHeadList = gModelPlayer:GetPersonaliseInfo(ModelPlayerSpace.ROLE_HEAD)
        local _activateHeadFrameList = gModelPlayer:GetPersonaliseInfo(ModelPlayerSpace.ROLE_HEADFRAME)
        local _activateTitleList = gModelPlayer:GetPersonaliseInfo(ModelPlayerSpace.ROLE_TITLE)

        if _activateHeadList then
            local head = self._currIdList[ModelPlayerSpace.ROLE_HEAD]
            if not head or not _activateHeadList[head] then
                self._currIdList[ModelPlayerSpace.ROLE_HEAD] = self._useIdList[ModelPlayerSpace.ROLE_HEAD]
            end
        end
        if _activateHeadFrameList then
            local headFrame = self._currIdList[ModelPlayerSpace.ROLE_HEADFRAME]
            if not headFrame or not _activateHeadFrameList[headFrame] then
                self._currIdList[ModelPlayerSpace.ROLE_HEADFRAME] = self._useIdList[ModelPlayerSpace.ROLE_HEADFRAME]
            end
        end
        if _activateTitleList then
            local title = self._currIdList[ModelPlayerSpace.ROLE_TITLE]
            if not title or not _activateTitleList[title] then
                self._currIdList[ModelPlayerSpace.ROLE_TITLE] = self._useIdList[ModelPlayerSpace.ROLE_TITLE]
            end
        end
        LxUiHelper.FilterScrollItem(self.mTabScroll, itempos - 1)
        self:OnClickTab(itemdata.type, itempos)
    end)
end
function UIChaePop:SetTagItemList(item, itemdata, itempos)
    CS.ShowObject(item, true)
    local posRef = gModelPlayerSpace:GetRoleTagPosByRefId(itempos)
    local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(itemdata)
    local btnAdd = self:FindWndTrans(item, "BtnAdd")
    local numText = self:FindWndTrans(item, "BtnAdd/NumText")
    local tagItem = self:FindWndTrans(item, "TagItem")
    local tagText = self:FindWndTrans(item, "TagItem/TagText")
    local btnDel = self:FindWndTrans(item, "TagItem/BtnDel")

    CS.ShowObject(btnAdd, false)
    CS.ShowObject(tagItem, false)
    self:SetWndText(numText, itempos)
    local size = posRef.setTagSize
    if LGameLanguage:IsForeignVersion() then
        size = 1
        self:InitTextSizeWithLanguage(tagText, -10)
        self:InitTextLineWithLanguage(tagText, -30)
    end

    item.localScale = Vector2.New(size, size)
    if not ref then
        CS.ShowObject(btnAdd, true)
        return
    end
    CS.ShowObject(tagItem, true)

    self:SetWndEasyImage(tagItem, ref.tagBg)
    self:SetWndText(tagText, LUtil.FormatColorStr(ccLngText(ref.name), "#" .. ref.tagColour))
    self:SetWndClick(tagItem, function()
        self:OnClickTag(ref, true)
    end)
end
---------------------------------------刷数据---------------------------------------------
function UIChaePop:RefreshData()
    local _tabType = self._tabType
    local _activateList = gModelPlayer:GetPersonaliseInfo(_tabType)
    self._activateList[_tabType] = _activateList
    if (not _activateList) then
        gModelPlayer:OnPersonaliseInfoReq(_tabType)
        return
    end
    CS.ShowObject(self.mInfoMar, self._infoMarList[_tabType])
    CS.ShowObject(self.mTagMar, self._tagMarList[_tabType])
    -- self:RefreshBadgeList()
    self:RefreshCellList()
    self:RefreshTagList()
    self:RefreshBackGroundList()
    self:RefreshBubbleList()
    self:RefreshShowInfo()
    self:RefreshTagInfo()
end
--设置徽章
function UIChaePop:SetMedalIcon(root, medalId)
    local medalBg = CS.FindTrans(root, "Root/MedalBg")
    local medalImg = CS.FindTrans(root, "Root/MedalImg")
    CS.ShowObject(medalBg, medalId == 0)
    CS.ShowObject(medalImg, medalId ~= 0)
    if medalId ~= 0 then
        local UIText = self:FindWndTrans(medalImg, "UIText")

        local rankStr = ""
        local medalRef = gModelPlayer:GetRolePlayerHeadRefByRefId(medalId)
        if medalRef then
            self:SetWndEasyImage(medalImg, medalRef.icon)

            local type = medalRef.type
            local refId = medalRef.refId
            if type == 5 then
                local isType5Rank = gModelPlayer:IsRoleCrossGradingRankType(refId)
                if isType5Rank then
                    rankStr = gModelPlayer:GetRankSeasonStr(refId)
                end
            end

            local badgeInsideSize = medalRef.badgeInsideSize
            if badgeInsideSize == 0 then
                badgeInsideSize = 80
                printInfoNR(refId .. "配置 badgeInsideSize = 0，默认" .. badgeInsideSize)
            end
            badgeInsideSize = badgeInsideSize / 100
            printInfoNR("badgeInsideSize = " .. badgeInsideSize)
            medalImg.localScale = Vector3(badgeInsideSize, badgeInsideSize, badgeInsideSize)
        end
        self:SetWndText(UIText, rankStr)
    end
end
--刷新大标签红点
function UIChaePop:RefreshTabRed()
    if not self._tabRedList then
        return
    end
    for i, v in pairs(self._tabRedList) do
        local bool = self:GetIsRedByType(i)
        CS.ShowObject(v, bool)
    end
    self:RefreshTypeRed()
end
--获取大标签红点
function UIChaePop:GetIsRedByType(type)
    local list = self:GetRedPointListByType(type)
    for i, v in pairs(list) do
        if v then
            return true
        end
    end
    return false
end
function UIChaePop:InitEvent()
    self._isForeign = gLGameLanguage:IsForeignRegion()
    self._isUSARegion = gLGameLanguage:IsUSARegion()
    self:SetWndClick(self.mBg, function()
        self:OnClickClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose, function()
        self:OnClickClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnYellow2, function()
        self:OnClickSave()
    end)
    self:SetWndClick(self.mBtnShare, function()
        self:OnClickShare()
    end)
    --self:SetWndClick(self.mBtnBackGround,function () self:OnClickBtnBackGround() end)

    self._roleTypes = {
        [ModelPlayerSpace.ROLE_HEAD] = self.mHeadSuper,
        [ModelPlayerSpace.ROLE_HEADFRAME] = self.mHeadFrameSuper,
        [ModelPlayerSpace.ROLE_TITLE] = self.mTitleSuper,
        -- [ModelPlayerSpace.ROLE_MEDAL] = self.mBadgeSuper,
        --[ModelPlayerSpace.ROLE_TAG] = self._isUSARegion and self.mTagSuperEn or self.mTagSuper,
        [ModelPlayerSpace.BACKGROUND] = self.mBackGroundSuper,
        [ModelPlayerSpace.BUBBLE] = self.mBubbleSuper,
    }
    -- self._medalList = {
    --     [1] = self.mMedalIcon1,
    --     [2] = self.mMedalIcon2,
    --     [3] = self.mMedalIcon3,
    -- }
    local _tagList = {}
    local setTagNum = gModelPlayer:GetRoleConfigRefByKey("setTagNum")
    for i = 1, setTagNum do
        local item = self:FindWndTrans(self.mTagItemRoot, "TagItem" .. i)
        local posRef = gModelPlayerSpace:GetRoleTagPosByRefId(i)

        if posRef then
            local posArr = string.split(posRef.setTagPos, "|")

            item.localPosition = Vector2.New(tonumber(posArr[1]), tonumber(posArr[2]))

        end
        _tagList[i] = item
    end
    self._tagList = _tagList
    -- local isMedalShow = gModelFunctionOpen:CheckIsShow(17601010)
    -- for i, v in pairs(self._medalList) do
    --     self:SetWndClick(v, function()
    --         self:OnClickMedalList(i)
    --     end)
    --     CS.ShowObject(v, isMedalShow)
    -- end
    self:RefreshUseList()
end
--设置头像
function UIChaePop:SetHeadIcon(playerInfo)
    local baseClass = self._headBaseClass
    if baseClass then
        baseClass:SetHeadData(playerInfo)
        baseClass:RefreshUI()
    else
        baseClass = HeadIcon:New(self)
        baseClass:SetHeadData(playerInfo)
        baseClass:RefreshUI()
        self._headBaseClass = baseClass
    end
end
---------------------------------------红点操作-------------------------------------------
---------------------------------------获取数据-------------------------------------------
--获取界面保存的数据
function UIChaePop:GetSaveData()
    local _useIdList = self._useIdList
    local _currIdList = self._currIdList
    local _activateList = self._activateList
    local _usehead = _useIdList[ModelPlayerSpace.ROLE_HEAD]
    local _useFrameId = _useIdList[ModelPlayerSpace.ROLE_HEADFRAME]
    local _useTitle = _useIdList[ModelPlayerSpace.ROLE_TITLE]
    local _useBackGround = _useIdList[ModelPlayerSpace.BACKGROUND]
    local _useBubble = _useIdList[ModelPlayerSpace.BUBBLE]
    -- local _useBadges = _useIdList[ModelPlayerSpace.ROLE_MEDAL] or {}
    --local _useTags = _useIdList[ModelPlayerSpace.ROLE_TAG] or {}
    local _useTags = {}
    local headId = _currIdList[ModelPlayerSpace.ROLE_HEAD]
    local headFrameId = _currIdList[ModelPlayerSpace.ROLE_HEADFRAME]
    local titleId = _currIdList[ModelPlayerSpace.ROLE_TITLE]
    local backGroundId = _currIdList[ModelPlayerSpace.BACKGROUND]
    local backBubbleId = _currIdList[ModelPlayerSpace.BUBBLE]
    if headId then
        local _activateList = _activateList[ModelPlayerSpace.ROLE_HEAD] or {}
        headId = _activateList[headId] and _activateList[headId].state == 0 and headId or nil
    end
    if headFrameId then
        local _activateList = _activateList[ModelPlayerSpace.ROLE_HEADFRAME] or {}
        headFrameId = _activateList[headFrameId] and _activateList[headFrameId].state == 0 and headFrameId or nil
    end
    if titleId then
        local _activateList = _activateList[ModelPlayerSpace.ROLE_TITLE] or {}
        titleId = _activateList[titleId] and _activateList[titleId].state == 0 and titleId or nil
    end
    if backGroundId then
        local _activateList = _activateList[ModelPlayerSpace.BACKGROUND] or {}
        backGroundId = _activateList[backGroundId] and _activateList[backGroundId].state == 0 and backGroundId or nil
    end
    if backBubbleId then
        local _activateList = _activateList[ModelPlayerSpace.BUBBLE] or {}
        backBubbleId = _activateList[backBubbleId] and _activateList[backBubbleId].state == 0 and backBubbleId or nil
    end
    -- local badgeList = _currIdList[ModelPlayerSpace.ROLE_MEDAL]
    local head = _usehead ~= headId and headId or nil
    local headFrame = _useFrameId ~= headFrameId and headFrameId or nil
    local title = _useTitle ~= titleId and titleId or nil
    local backGround = _useBackGround ~= backGroundId and backGroundId or nil
    local bubble = _useBubble ~= backBubbleId and backBubbleId or nil
    -- local badges = {}
    -- local isBadge = false
    -- for i, v in pairs(badgeList) do
    --     if (not _useBadges[i] and v ~= 0) or (_useBadges[i] and _useBadges[i] ~= v) then
    --         isBadge = true
    --     end
    --     if v ~= 0 then
    --         table.insert(badges, v .. "=" .. i)
    --     else
    --         table.insert(badges, "0=" .. i)
    --     end
    -- end
    -- badges = isBadge and badges or nil
    --local tagList = _currIdList[ModelPlayerSpace.ROLE_TAG]
    local tagList = {}
    local setTagNum = gModelPlayer:GetRoleConfigRefByKey("setTagNum")
    local tags = {}
    local isTag = false
    for i = 1, setTagNum do
        local useId = _useTags[i]
        local id = tagList[i]
        tags[i] = id and id .. "=" .. i or "0=" .. i
        if useId ~= id then
            isTag = true
        end
    end
    if not isTag then
        tags = nil
    end

    local data = {
        [ModelPlayerSpace.ROLE_HEAD] = head,
        [ModelPlayerSpace.ROLE_HEADFRAME] = headFrame,
        [ModelPlayerSpace.ROLE_TITLE] = title,
        -- [ModelPlayerSpace.ROLE_MEDAL] = badges,
        [ModelPlayerSpace.ROLE_TAG] = tags,
        [ModelPlayerSpace.BACKGROUND] = backGround,
        [ModelPlayerSpace.BUBBLE] = bubble,
    }
    return data
end
---------------------------------------大标签---------------------------------------------
---------------------------------------小标签---------------------------------------------
function UIChaePop:RefreshTabType()
    local tabType = self._tabType
    local list = gModelPlayer:GetRoleAdventureImageTypeRef(tabType)
    self._typeRedList = {}
    local _uiList = self._uiTypeList
    if _uiList then
        _uiList:RefreshList(list)
    else
        _uiList = self:GetUIScroll("setType")
        _uiList:Create(self.mTypeScroll, list, function(...)
            self:TypeListItem(...)
        end)
    end
    local _redPointList = self._redPointList
    local types = {}
    local redList = _redPointList[tabType]
    if redList then
        for i, v in pairs(redList) do
            if v then
                local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(i)
                if not types[ref.subType] then
                    types[ref.subType] = v
                end
            end
        end
        local redIs = {}
        for i, v in pairs(types) do
            table.insert(redIs, i)
        end
        if #redIs > 0 then
            table.sort(redIs, function(a, b)
                return a < b
            end)
            self:OnClickType(redIs[1])
            return
        end
    else
        local _useIdList = self._useIdList
        local refs = gModelPlayer:GetRolePlayerHeadListByType(tabType)
        local id = _useIdList[tabType]
        local info = refs[id]
        if info then
            local subType = info.subType
            self:OnClickType(subType)
            return
        end
    end
    self:OnClickType(list[1].type)
end
--点击有红点的大标签
function UIChaePop:OnClickRedPointByType(type, refIds)
    local _redPointList = self:GetRedPointListByType(type)
    for i, v in ipairs(refIds) do
        _redPointList[v] = false
    end
    self._redPointList[type] = _redPointList
    self:RefreshTabRed()
end
--刷新小标签红点
function UIChaePop:RefreshTypeRed()
    if not self._typeRedList then
        return
    end
    local types = {}
    local len = 0
    for i, v in pairs(self._typeRedList) do
        types[i] = false
        len = len + 1
    end
    local list = self:GetRedPointListByType(self._tabType)
    for i, v in pairs(list) do
        local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(i)
        if not types[ref.subType] then
            types[ref.subType] = v
        end
    end
    for i, v in pairs(self._typeRedList) do
        CS.ShowObject(v, types[i])
    end
end
function UIChaePop:RefreshShowInfo()
    local _tabType = self._tabType
    if _tabType == ModelPlayerSpace.ROLE_TAG then
        return
    end
    local _currIdList = self._currIdList
    local roleIds = self._useIdList
    CS.ShowObject(self.mBtnShare, false)
    self:SetHeadIcon({
        trans = self.mHeadIcon,
        icon = _currIdList[1] or roleIds[1],
        headFrame = _currIdList[2] or roleIds[2],
    })
    local titleId = _currIdList[3] or roleIds[3]
    local titleStr = "role_titile_0"
    if titleId and titleId > 0 then
        local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(titleId)
        titleStr = ref.icon
    end
    self:SetWndEasyImage(self.mTitleImg, titleStr, nil, true)
    -- CS.ShowObject(self.mTitleImg, _tabType ~= ModelPlayerSpace.BUBBLE)
    -- CS.ShowObject(self.mChatBg, _tabType == ModelPlayerSpace.BUBBLE)
    -- if _tabType == ModelPlayerSpace.BUBBLE then
        local bubbleId = _currIdList[ModelPlayerSpace.BUBBLE] or roleIds[ModelPlayerSpace.BUBBLE]
        local bubbleRef = gModelPlayer:GetRolePlayerHeadRefByRefId(bubbleId)
            -- self:SetWndText(chatText, ccClientText(21185))
        self:SetBubbleImg(self.mChatBg, bubbleRef, ccClientText(21184))
    -- end
    -- local badgeList = _currIdList[ModelPlayerSpace.ROLE_MEDAL]
    -- if badgeList then
    --     for i, v in pairs(badgeList) do
    --         local root = self._medalList[i]
    --         self:SetMedalIcon(root, v)
    --     end
    -- end

    local saveText
    local refId = _currIdList[_tabType]
    local _activateList = self._activateList[_tabType]
    -- if _tabType == ModelPlayerSpace.ROLE_MEDAL then
    --     refId = self._currBadgeId
    -- end

    local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(refId)
    if not ref then
        return
    end

    if PRODUCT_G_VER == 1 then
        --ios 屏蔽
        CS.ShowObject(self.mBtnYellow2, false)
    end

    local isGray = false
    if not refId then
        refId = self._useIdList[_tabType]
    else
        local activityData = _activateList[refId]
        if activityData and activityData.state == 0 then
            saveText = ccClientText(21113)

            if PRODUCT_G_VER == 1 then
                --ios 屏蔽
                CS.ShowObject(self.mBtnYellow2, true)
            end

        else
            saveText = ccClientText(21116)
            isGray = true
        end
        self:SetWndButtonText(self.mBtnYellow2, saveText)
    end

    if gLGameLanguage:IsJapanRegion() then
        --日本地区，不能激活的，显示灰色按钮
        if isGray then
            local jump = ref.jump
            isGray = jump == 0 or not gModelFunctionOpen:CheckIsOpened(jump, false)
        end
        self:SetWndButtonGray(self.mBtnYellow2, isGray)
    end

    self:SetWndText(self.mNameText, ccLngText(ref.name))
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.mNameText)

    local arrtStr = ""
    local arrtlist = LUtil.GetRefAttrData(ref.attributes)
    for i, v in ipairs(arrtlist) do
        local name = gModelHero:GetAttributeNameById(v.refId)
        local value = gModelHero:GetAttributeValueNoNameByIdAndVal(v.refId, v.numType, v.value)
        arrtStr = arrtStr .. name .. LUtil.FormatColorStr("+" .. value, "lightGreen") .. "  "
    end
    if arrtStr == "" then
        arrtStr = ccLngText(ref.description)
    else
        arrtStr = arrtStr .. "\n" .. ccLngText(ref.description)
    end

    self:SetWndText(self.mArrtText, arrtStr)
    self:InitTextLineWithLanguage(self.mArrtText, -5)
    self:InitTextSizeWithLanguage(self.mArrtText, -2)
    local activityData = _activateList[refId]
    if not activityData then
        self:SetWndText(self.mTimeText, ccClientText(21156))
        self:TimerStop(self._timeKey)
        return
    elseif activityData.state == 2 then
        local y, m, d = LUtil.GetYmdByTimestamp(tonumber(activityData.createTime) / 1000)
        self:SetWndText(self.mTimeText, string.replace(ccClientText(21155), y .. "." .. m .. "." .. d))
        return
    end
    if _tabType == ModelPlayerSpace.ROLE_TITLE then
        CS.ShowObject(self.mBtnShare, false)
    end
    local expireTime = tonumber(activityData.expireTime)
    if expireTime <= 0 then
        self:SetWndText(self.mTimeText, ccClientText(21123))
        self:TimerStop(self._timeKey)
        return
    end

    local time = GetTimestamp()
    local endTime = expireTime + activityData.createTime
    local timespan = endTime / 1000 - time
    if timespan <= 0 then
        self:TimerStop(self._timeKey)
        return
    end
    self._expireTime = endTime
    self:TimerStart(self._timeKey, 1, false, -1)
    self:SetTime()
end
function UIChaePop:SetBubbleImg(chatBg, itemdata, str)
    local arrows = self:FindWndTrans(chatBg, "Arrows")
    local isForeignVersion = self._isForeignVersion
    local chatText = self:FindWndTrans(chatBg, "ChatText")
    local chatText_out = self:FindWndTrans(chatBg, "ChatText_out")

    local useChatTxt = isForeignVersion and chatText_out or chatText
    local hideChatTxt = isForeignVersion and chatText or chatText_out
    CS.ShowObject(useChatTxt,true)
    CS.ShowObject(hideChatTxt,false)

    local pendantList = {}
    for i = 1, 4 do
        local pendant = self:FindWndTrans(chatBg, "Pendant" .. i)
        pendantList[i] = pendant
    end

    local iconArr = string.split(itemdata.icon, "|")
    self:SetWndEasyImage(chatBg, iconArr[1])
    self:SetWndEasyImage(arrows, iconArr[2])
    for i, v in ipairs(pendantList) do
        local iconStr = iconArr[i + 2] or "0"
        CS.ShowObject(v, iconStr ~= "0")
        if iconStr ~= "0" then
            self:SetWndEasyImage(v, iconStr, nil, true)
        end
    end
    local name = ccLngText(itemdata.name)
    local tagColour = itemdata.tagColour or "734f22"
    if string.isempty(tagColour) then
        return
    end
    local s = str or LUtil.FormatColorStr(name, "#" .. tagColour)
    self:SetWndText(useChatTxt, s)

    if self.jpj then
        self:InitTextSizeWithLanguage(useChatTxt,-4)
    end

    arrows.anchoredPosition = Vector2.New(arrows.anchoredPosition.x, itemdata.arrowPointY)
end
---------------------------------------个性设置-------------------------------------------
---------------------------------------个性徽章-------------------------------------------
-- function UIChaePop:RefreshBadgeList()
--     local _tabType = self._tabType
--     local _roleTypes = self._roleTypes
--     if _tabType ~= ModelPlayerSpace.ROLE_MEDAL and self._currIdList[ModelPlayerSpace.ROLE_MEDAL] then
--         return
--     end
--     local badgePosList = self._currIdList[ModelPlayerSpace.ROLE_MEDAL] or {}
--     local badgeUseList = self._useIdList[ModelPlayerSpace.ROLE_MEDAL] or {}
--     local useB = badgeUseList
--     for i = 1, 3 do
--         local id = badgePosList[i]
--         local useId = useB[i]
--         if not id then
--             if useId then
--                 badgePosList[i] = useId
--             else
--                 badgePosList[i] = 0
--             end
--         end
--     end
--     self._currIdList[ModelPlayerSpace.ROLE_MEDAL] = badgePosList

--     if _tabType ~= ModelPlayerSpace.ROLE_MEDAL then
--         return
--     end
--     for i, v in pairs(_roleTypes) do
--         CS.ShowObject(v, false)
--     end
--     local uiListTrans = _roleTypes[_tabType]
--     local list = {}
--     local refs = gModelPlayer:GetRolePlayerHeadListByType(_tabType)
--     for i, v in pairs(refs) do
--         table.insert(list, v)
--     end
--     self._badgeActivateList = self._activateList[_tabType]
--     table.sort(list, function(a, b)
--         local _badgeActivateList = self._badgeActivateList or {}
--         local aAct = _badgeActivateList[a.refId]
--         local bAct = _badgeActivateList[b.refId]
--         local aA = (aAct and aAct.state == 0) and 1 or 2
--         local bA = (bAct and bAct.state == 0) and 1 or 2
--         if aA ~= bA then
--             return aA < bA
--         end
--         return a.sort < b.sort
--     end)
--     if uiListTrans then
--         CS.ShowObject(uiListTrans, true)
--         local _uiList = self:GetUIScroll(_tabType)
--         local _uiListSuper = _uiList:GetList()
--         if _uiListSuper then
--             _uiList:RefreshList(list)
--             _uiListSuper:DrawAllItems()
--         else
--             _uiList:Create(uiListTrans, list, function(...)
--                 self:BadgeListItem(...)
--             end, UIItemList.SUPER_GRID)
--             _uiList:EnableScroll(true, false)
--         end
--         if not self._currBadgeId then
--             self._currBadgeId = list[1].refId
--         end
--     end
-- end
-- function UIChaePop:BadgeListItem(list, item, itemdata, itempos)
--     if not itemdata then
--         return
--     end
--     local root = CS.FindTrans(item, "HeadUI")
--     local headImage = CS.FindTrans(root, "HeadBg/HeadImage")
--     local mask = CS.FindTrans(root, "Mask")
--     local isSel = CS.FindTrans(root, "IsSel")
--     local isUse = CS.FindTrans(root, "IsUse")
--     local UIText = CS.FindTrans(root, "UIText")
--     local redPoint = CS.FindTrans(item, "redPoint")

--     local refId = itemdata.refId
--     local type = itemdata.type
--     local currList = self._currIdList[ModelPlayerSpace.ROLE_MEDAL]
--     local _isUse = false
--     for i, v in pairs(currList) do
--         if v == itemdata.refId then
--             _isUse = true
--             break
--         end
--     end

--     local rankStr = ""
--     if type == 5 then
--         local isType5Rank = gModelPlayer:IsRoleCrossGradingRankType(refId)
--         if isType5Rank then
--             rankStr = gModelPlayer:GetRankSeasonStr(refId)
--         end
--     end
--     self:SetWndText(UIText, rankStr)

--     local _redPointList = self:GetRedPointListByType(type)
--     local _badgeActivateList = self._badgeActivateList
--     local isActivate = _badgeActivateList[refId] and _badgeActivateList[refId].state == 0
--     local isRed = _redPointList[refId]
--     local isCurrSel = refId == self._currBadgeId
--     CS.ShowObject(mask, not isActivate)
--     self:SetWndEasyImage(headImage, itemdata.icon, function()
--         self:SetImageAlpha(headImage, isActivate and 1 or 0.3)
--     end)
--     CS.ShowObject(UIText, isActivate)
--     CS.ShowObject(isUse, _isUse)
--     CS.ShowObject(isSel, self._currBadgeId == refId)
--     CS.ShowObject(redPoint, isRed and not isCurrSel)
--     if isRed and isCurrSel then
--         self:OnClickRedPoint(type, refId)
--     end
--     self:SetWndClick(root, function()
--         if isActivate then
--             self:OnClickBadge(refId, itemdata.type, _isUse)
--         else
--             self._currBadgeId = refId
--             self:RefreshData()
--         end
--     end)
--     self:SetWndLongClick(root, function()
--         local playerName, createTime
--         if isActivate then
--             playerName = gModelPlayer:GetPlayerName()
--             local item = _badgeActivateList[refId]
--             createTime = item.createTime
--         end
--         GF.OpenWnd("UIPerSpreadPop", { StructPersonaliseInfo = { refId = refId, createTime = createTime, playerName = playerName } })
--     end, 0.8, false)
-- end
-- function UIChaePop:OnClickBadge(refId, type, isDown)
--     local badgeMaxNum = gModelPlayer:GetRoleConfigRefByKey("badgeMaxNum")
--     local list = self._currIdList[type] or {}
--     local isUpList = false
--     for i = 1, badgeMaxNum do
--         local id = list[i]
--         if isDown then
--             if id == refId then
--                 list[i] = 0
--                 break
--             end
--         else
--             if id == 0 then
--                 list[i] = refId
--                 isUpList = true
--                 break
--             end
--         end
--     end
--     self._currBadgeId = refId

--     if not isUpList and not isDown then
--         GF.ShowMessage(ccClientText(21141))
--         self:RefreshData()
--         return
--     end

--     self._currIdList[type] = list
--     self:RefreshData()
-- end
---------------------------------------个性徽章-------------------------------------------
---------------------------------------个性标签-------------------------------------------
function UIChaePop:RefreshTagInfo()
    local _tabType = self._tabType
    -- if _tabType ~= ModelPlayerSpace.ROLE_TAG then
        -- return
    -- else
        -- return
    -- end
    local _currIdList = self._currIdList
    local tags = _currIdList[_tabType]
    -- self:SetWndButtonText(self.mBtnYellow2, ccClientText(21113))
    local setTagNum = gModelPlayer:GetRoleConfigRefByKey("setTagNum")
    local num = 0
    for i = 1, setTagNum do
        local item = self._tagList[i]
        local refId = tags[i] or 0
        self:SetTagItemList(item, refId, i)
        if refId > 0 then
            num = num + 1
        end
    end
    self:SetWndText(self.mTagNumText, LUtil.FormatColorStr(num .. "/" .. setTagNum, num >= setTagNum and "lightRed" or "lightGreen"))
end
function UIChaePop:BackGroundListItem(list, item, itemdata, itempos)
    local root = CS.FindTrans(item, "HeadUI")
    local headImage = CS.FindTrans(root, "HeadBg/HeadImage")
    local isSel = CS.FindTrans(root, "IsSel")
    local isUse = CS.FindTrans(root, "IsUse")

    local refId = itemdata.refId
    local _tabType = self._tabType
    local useId = self._useIdList[_tabType]
    local _currSelId = self._currIdList[_tabType]
    local isCurrSel = refId == _currSelId
    local activateLis = self._activateList[_tabType] or {}
    local isActivate = activateLis[refId] and activateLis[refId].state == 0

    self:SetWndEasyImage(headImage, itemdata.icon)
    self:SetImageAlpha(headImage, isActivate and 1 or 0.3)
    CS.ShowObject(isUse, useId == refId)
    CS.ShowObject(isSel, isCurrSel)
    self:SetWndClick(root, function()
        if isCurrSel then
            self:OnClickBtnBackGround(itemdata.refId)
        else
            self:OnClickBackGround(itemdata.refId, itemdata.type)
        end
        local bubbleId = self._currIdList[ModelPlayerSpace.BUBBLE]
        local bubbleRef = gModelPlayer:GetRolePlayerHeadRefByRefId(bubbleId)
        self:SetBubbleImg(self.mChatBg, bubbleRef, ccClientText(21185))
    end)
end
--获取头像，头像框，称号列表
function UIChaePop:GetTypeList(type)
    local _useId = self._useIdList[type]
    local currId = self._currIdList[type]
    local _activateList = self._activateList[type]
    local refs = gModelPlayer:GetRolePlayerHeadListByType(type)
    local list = {}
    local headType = ModelPlayerSpace.ROLE_HEAD
    local curTime = GetTimestamp()
    for i, v in pairs(refs) do
        local _ac = _activateList[v.refId]
        local isOpen = true
        if headType == type and not string.isempty(v.activation) then
            if not gModelPlayer:CheckRolePlayerHeadIsOpen(v.activation,curTime) then
                isOpen = false
            end
        end
        if v.subType == self._type and (not _ac or _ac.state ~= 1) and isOpen then
            table.insert(list, v)
        end
    end
    -- if type == ModelPlayerSpace.ROLE_MEDAL then
    --     local list = {}
    --     for i, v in ipairs(_useId) do
    --         list[v] = true
    --     end
    --     _useId = list
    -- end

    table.sort(list, function(a, b)
        local ais, bis
        --local _activateList = self._activateList[type]
        -- if type == ModelPlayerSpace.ROLE_MEDAL then
        --     ais = _useId[a.refId] and 0 or 1
        --     bis = _useId[b.refId] and 0 or 1
        -- else
            ais = a.refId == _useId and 0 or 1
            bis = b.refId == _useId and 0 or 1
        -- end
        if not self._isOne and ais ~= bis then
            return ais < bis
        end
        ais = (_activateList[a.refId] and _activateList[a.refId].state == 0) and 0 or 1
        bis = (_activateList[b.refId] and _activateList[b.refId].state == 0) and 0 or 1
        if ais ~= bis then
            return ais < bis
        end
        return a.sort < b.sort
    end)
    if not currId then
        currId = list[1].refId
    end
    self._currSelId = currId
    self._useId = _useId
    return list
end
---------------------------------------聊天气泡-------------------------------------------
---------------------------------------红点操作-------------------------------------------
--获取大标签的小标签红点列表
function UIChaePop:GetRedPointListByType(type)
    return self._redPointList[type] or {}
end
function UIChaePop:SetTime()
    local time = GetTimestamp()
    local endTime = self._expireTime
    local timespan = endTime / 1000 - time
    if (timespan <= 0) then
        self:TimerStop(self._timeKey)
        self:RefreshShowInfo()
        return
    end
    self:SetWndText(self.mTimeText, LUtil.FormatTimespanCn(timespan))
end
function UIChaePop:TypeListItem(list, item, itemdata, itempos)
    local BtnTab1 = CS.FindTrans(item, "BtnTab7")
    local redPoint = CS.FindTrans(item, "redPoint")
    self._typeList[itemdata.type] = BtnTab1
    self._typeRedList[itemdata.type] = redPoint

    local addFontLine
    if self._isForeignFr then
        addFontLine = -40
    end

    self:SetWndTabText(BtnTab1, ccLngText(itemdata.name), -4, addFontLine)
    self:SetWndTabStatus(BtnTab1, 1)
    self:SetWndClick(item, function()
        self._oldTabType = self._tabType
        self:OnClickType(itemdata.type)
        self:RefreshData()
        local bubbleId = self._currIdList[ModelPlayerSpace.BUBBLE]
        local bubbleRef = gModelPlayer:GetRolePlayerHeadRefByRefId(bubbleId)
        self:SetBubbleImg(self.mChatBg, bubbleRef, ccClientText(21185))
    end)
end
function UIChaePop:OnClickSave(isOnClickSave)
    local _tabType = self._tabType
    local _currId
    -- if _tabType == ModelPlayerSpace.ROLE_MEDAL then
    --     _currId = self._currBadgeId
    -- else
        _currId = self._currIdList[_tabType]
    -- end

    local _activateList = self._activateList[_tabType]
    local list = self:GetSaveData()
    local isSave = false
    for i, v in pairs(list) do
        if v ~= nil then
            isSave = true
            break
        end
    end
    --	if isOnClickSave or _tabType == ModelPlayerSpace.ROLE_TAG or(_activateList[_currId] and _activateList[_currId].state == 0) then
    if isOnClickSave or (_activateList[_currId] and _activateList[_currId].state == 0) then
        if not isSave then
            GF.ShowMessage(ccClientText(21153))
            return
        end
        self._isOne = true
        gModelPlayerSpace:OnPersonaliseChangeTotalReq(list[1], list[2], list[3], nil, list[5], list[6], list[7], list[8])
    else
        local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(_currId)
        if ref.jump == 0 then
            GF.ShowMessage(ccLngText(ref.description))
            return
        end
        if not gModelFunctionOpen:CheckIsOpened(ref.jump, true) then
            return
        end
        gModelFunctionOpen:Jump(ref.jump, self:GetWndName())
        self:WndClose()
        GF.CloseWndByName("UIPersonAreaWin")
    end
end
---------------------------------------小标签---------------------------------------------
---------------------------------------个性设置-------------------------------------------
function UIChaePop:RefreshCellList()
    local _currIdList = self._currIdList
    local _roleTypes = self._roleTypes
    local _tabType = self._tabType
    if ModelPlayerSpace.ROLE_FIGURE <= _tabType then
        return
    end
    local list = self:GetTypeList(_tabType)
    for i, v in pairs(_roleTypes) do
        CS.ShowObject(v, false)
    end
    if not _currIdList[_tabType] or _currIdList[_tabType] == 0 then
        self._currSelId = list[1].refId
    end
    local uiListTrans = _roleTypes[_tabType]
    if uiListTrans then
        local _oldList = self._oldList
        if _oldList then
            local isChange = false
            for i, v in ipairs(list) do
                local item = _oldList[i]
                if item and v.refId ~= item.refId then
                    isChange = true
                    break
                end
            end
            if isChange then
                local type = _oldList[1].type
                local refIds = {}
                for i, v in ipairs(_oldList) do
                    table.insert(refIds, v.refId)
                end
                self:OnClickRedPointByType(type, refIds)
            end
        end
        CS.ShowObject(uiListTrans, true)
        local _uiList = self:GetUIScroll(_tabType)
        local _uiListSuper = _uiList:GetList()
        if _uiListSuper then
            _uiList:RefreshList(list)
            _uiListSuper:DrawAllItems()
        else
            _uiList:Create(uiListTrans, list, function(...)
                self:HeadListItem(...)
            end, UIItemList.SUPER_GRID)
            _uiList:EnableScroll(true, false)
        end
        if #list > 0 and (not _currIdList[_tabType] or _currIdList[_tabType] == 0) then
            _currIdList[_tabType] = list[1].refId
        end
        self._oldList = list

        if self._isOnTypeTab then
            self._isOnTypeTab = false
            local isSortOpen = gModelPlayerSpace:GetRoleAdventureImageTypeRefIsSortOpen(_tabType, self._type)
            if isSortOpen == 1 then
                local activateLis = self._activateList[_tabType] or {}
                local maxI = 0
                local moveToI = 1
                for i, v in ipairs(list) do
                    local refId = v.refId
                    local sort = v.sort
                    local isActivate = activateLis[refId] and activateLis[refId].state == 0
                    if isActivate and sort > maxI then
                        maxI = sort
                        moveToI = i
                    end
                end
                _uiList:MoveToPos(moveToI)
            else
                _uiList:MoveToPos(1)
            end
        end
    end
    self._currIdList = _currIdList
end
function UIChaePop:OnClickBackGround(refId, type)
    self._currIdList[type] = refId
    self:RefreshData()
end
-- function UIChaePop:OnClickMedalList(index)
--     local badgeList = self._currIdList[ModelPlayerSpace.ROLE_MEDAL]
--     badgeList[index] = 0
--     self._currIdList[ModelPlayerSpace.ROLE_MEDAL] = badgeList
--     self:RefreshData()
-- end
function UIChaePop:OnClickBtnBackGround(backGroundId)
    local list = self:GetSaveData()
    local playerInfo = {
        _head = list[1] and list[1] or gModelPlayer:GetPlayerHead(),
        _headFrame = list[2] and list[2] or gModelPlayer:GetPlayerHeadFrame(),
        _grade = gModelPlayer:GetPlayerLv(),
        _vipLevel = gModelPlayer:GetVipLevel(),
        _name = gModelPlayer:GetPlayerName(),
        sex = gModelPlayer:GetPlayerSex(),
        _serverId = gModelPlayer:GetServerId(),
        _guildId = gModelPlayer:GetGuildId(),
        _serverName = "",
        _playerId = gModelPlayer:GetPlayerId(),
        _guildName = gModelPlayer:GetGuildName(),
        signature = gModelPlayer:GetPlayerSignature(),
        disallowTalk = 0,
        title = list[3] and list[3] or gModelPlayer:GetPlayerTitle(),
        badge = list[5] and list[5] or gModelPlayer:GetBadge(),
        tag = list[6] and list[6] or gModelPlayer:GetPlayerTags(),
        backGround = backGroundId,
        _power = gModelPlayer:GetPlayerFightPower()
    }

    GF.OpenWnd("UIPerInfoPop", { openType = 3, playerInfo = playerInfo })
end
---------------------------------------计时器-------------------------------------------
---------------------------------------初始化徽章拖动-----------------------------------
-- function UIChaePop:InitDragList()
--     -- self._dragItemList = { self.mMedalIcon1, self.mMedalIcon2, self.mMedalIcon3 }
--     self._dragItemDataList = {}
--     self._dragOriginPos = {}
--     self._dragIndexList = {}
--     -- for k, v in ipairs(self._dragItemList) do
--     --     table.insert(self._dragIndexList, k)

--     --     local dragKey = "_dragItem_" .. k

--     --     local vector3List = v:GetLocalCorners()
--     --     local vecMin = vector3List[0]
--     --     local vecMax = vector3List[2]

--     --     local minX = vecMin.x
--     --     local minY = vecMin.y
--     --     local maxX = vecMax.x
--     --     local maxY = vecMax.y
--     --     local centerX = (vecMax.x + vecMin.x) / 2
--     --     local centerY = (vecMax.y + vecMin.y) / 2

--     --     local width = vecMax.x - vecMin.x
--     --     local height = vecMax.y - vecMin.y
--     --     local midW = width / 2
--     --     local midH = height / 2

--     --     self._dragItemDataList[dragKey] = {
--     --         key = dragKey,
--     --         keyIndex = k,
--     --         index = k,
--     --         item = v,
--     --         minX = minX,
--     --         minY = minY,
--     --         maxX = maxX,
--     --         maxY = maxY,
--     --         centerX = centerX,
--     --         centerY = centerY,
--     --         width = width,
--     --         height = height,
--     --         midW = midW,
--     --         midH = midH,
--     --     }
--     --     table.insert(self._dragOriginPos, v.localPosition)
--     --     self:InternalUIDragSetItem(dragKey, v, CS.YXUIDrag.DragMode.DragNothing)
--     -- end

--     local sdMar = self.mTagMar.sizeDelta
--     self._dragTagDataList = {}
--     for i, v in pairs(self._tagList) do
--         local dragKey = "_dragTag_" .. i
--         local localPos = v.localPosition
--         local posRef = gModelPlayerSpace:GetRoleTagPosByRefId(i)
--         local btnAdd = self:FindWndTrans(v, "BtnAdd")
--         local tagItem = self:FindWndTrans(v, "TagItem")
--         local sdTagItem = tagItem.sizeDelta
--         local sdBtnAdd = btnAdd.sizeDelta
--         --local sdTagWidth = (sdTagItem.x * posRef.setTagSize) / 2
--         local sdTagWidth = sdTagItem.x
--         --local sdTagWidth = (sdBtnAdd.x)/2
--         local minX = -sdMar.x / 2 + sdTagWidth
--         local maxX = sdMar.x / 2 - sdTagWidth
--        -- local sdTagHeight = (sdTagItem.y * posRef.setTagSize) / 2
--         local sdTagHeight = sdTagItem.y
--         --local sdTagHeight = (sdBtnAdd.y)/2
--         local minY = -sdMar.y / 2 + sdTagHeight
--         local maxY = sdMar.y / 2 - sdTagHeight
--         self._dragTagDataList[dragKey] = {
--             key = dragKey,
--             item = v,
--             localPos = localPos,
--             minX = minX,
--             minY = minY,
--             maxX = maxX,
--             maxY = maxY,
--             width = sdTagItem.x,
--             height = sdBtnAdd.y,
--             index = i
--         }
--         self:InternalUIDragSetItem(dragKey, v, CS.YXUIDrag.DragMode.DragNothing)
--     end

--     local len = #self._dragOriginPos
--     local top = self._dragOriginPos[1]
--     local bottom = self._dragOriginPos[len]
--     local itemTopData = self._dragItemDataList["_dragItem_1"]
--     local itemBottomData = self._dragItemDataList["_dragItem_" .. len]

--     self._dragOriginLimitMinX = top.x + itemTopData.minX
--     self._dragOriginLimitMaxX = bottom.x + itemBottomData.maxX

-- end
--开始拖动
-- function UIChaePop:UIDragOnBegin(dragKey, eventData)
--     local isTag = string.find(dragKey, "_dragTag_")
--     if isTag then
--         self._dragTagData = nil
--         local itemData = self._dragTagDataList[dragKey]
--         local item = itemData.item
--         self._dragTagData = itemData
--         item:SetAsLastSibling()
--         local camera = eventData.pressEventCamera
--         local pos = camera:ScreenToWorldPoint(eventData.position)
--         pos = item.parent:InverseTransformPoint(pos)
--         self._dragOffsetPosX = item.localPosition.x - pos.x
--         self._dragOffsetPosY = item.localPosition.y - pos.y
--     else
--         self._dragItemData = nil
--         local itemData = self._dragItemDataList[dragKey]
--         local item = itemData.item
--         self._dragItemData = itemData
--         item:SetAsLastSibling()
--         local camera = eventData.pressEventCamera
--         local pos = camera:ScreenToWorldPoint(eventData.position)
--         pos = item.parent:InverseTransformPoint(pos)
--         self._dragOffsetPosX = item.localPosition.x - pos.x
--     end
-- end
--结束拖动
-- function UIChaePop:UIDragOnEnd(dragKey, eventData)
--     local isTag = string.find(dragKey, "_dragTag_")
--     if isTag then
--         local _dragTagData = self._dragTagData
--         local currLocalPoint = _dragTagData.item.localPosition
--         --local currIndex = _dragTagData.index
--         for i, v in pairs(self._dragTagDataList) do
--             if i ~= dragKey then
--                 local _localPos = v.localPos
--                 local height = v.height
--                 local width = v.width
--                 --local _index = v.index
--                 local isX = (currLocalPoint.x <= _localPos.x + width / 2) and (_localPos.x - width / 2 <= currLocalPoint.x)
--                 local isY = (currLocalPoint.y <= _localPos.y + height / 2) and (_localPos.y - height / 2 <= currLocalPoint.y)
--                 if isX and isY then
--                     self:OnSwopTag(dragKey, i)
--                     return
--                 end
--             end
--         end
--         self:OnSwopTag(dragKey, "0")
--     -- else
--     --     if self._dragItemData and self._dragItemData.key == dragKey then
--     --         local dragItemData = self._dragItemData
--     --         local item = dragItemData.item
--     --         local tween = dragItemData.tween
--     --         if tween then
--     --             tween:Kill(false)
--     --         end
--     --         local originPos = self._dragOriginPos[dragItemData.index]
--     --         tween = item:DOLocalMoveX(originPos.x, 0.15)
--     --         tween:OnComplete(function()
--     --             local dragItemData = self._dragItemDataList[dragKey]
--     --             if dragItemData then
--     --                 dragItemData.tween = nil
--     --             end
--     --         end)
--     --         dragItemData.tween = tween
--     --         tween:PlayForward()
--     --     end
--     --     self._dragItemData = nil
--     end
-- end
--拖动中
-- function UIChaePop:UIDragOnDrag(dragKey, eventData)
--     local isTag = string.find(dragKey, "_dragTag_")
--     if isTag then
--         local _dragTagData = self._dragTagData
--         local trans = _dragTagData.item
--         local camera = eventData.pressEventCamera
--         local pos = camera:ScreenToWorldPoint(eventData.position)
--         pos = trans.parent:InverseTransformPoint(pos)
--         pos.x = pos.x + self._dragOffsetPosX
--         pos.y = pos.y + self._dragOffsetPosY
--         if pos.x < _dragTagData.minX then
--             pos.x = _dragTagData.minX
--         elseif pos.x > _dragTagData.maxX then
--             pos.x = _dragTagData.maxX
--         end
--         if pos.y < _dragTagData.minY then
--             pos.y = _dragTagData.minY
--         elseif pos.y > _dragTagData.maxY then
--             pos.y = _dragTagData.maxY
--         end
--         local transPos = trans.localPosition
--         local curPos = Vector3.New(pos.x, pos.y, transPos.z)
--         trans.localPosition = curPos
--     -- else
--         -- if self._dragItemData and self._dragItemData.key == dragKey then
--         --     local trans = self._dragItemData.item
--         --     local camera = eventData.pressEventCamera
--         --     local pos = camera:ScreenToWorldPoint(eventData.position)
--         --     pos = trans.parent:InverseTransformPoint(pos)
--         --     pos.x = pos.x + self._dragOffsetPosX

--         --     local min = pos.x + self._dragItemData.minX
--         --     local max = self._dragItemData.maxX + pos.x

--         --     if min < self._dragOriginLimitMinX then
--         --         pos.x = self._dragOriginLimitMinX - self._dragItemData.minX
--         --     elseif max > self._dragOriginLimitMaxX then
--         --         pos.x = self._dragOriginLimitMaxX - self._dragItemData.maxX
--         --     end

--         --     local transPos = trans.localPosition
--         --     local curPos = Vector3.New(pos.x, transPos.y, transPos.z)
--         --     trans.localPosition = curPos
--         --     self:CheckDragItemSwap(self._dragItemData, curPos)
--         -- end
--     end
-- end
-- function UIChaePop:CleanDragList()
--     for k, v in pairs(self._dragItemDataList or {}) do
--         v.item = nil
--         if v.tween then
--             v.tween:Kill(false)
--             v.tween = nil
--         end
--     end
--     for k, v in pairs(self._dragTagDataList or {}) do
--         v.item = nil
--         if v.tween then
--             v.tween:Kill(false)
--             v.tween = nil
--         end
--     end
-- end
-- function UIChaePop:CheckDragItemSwap(curData, curPos)
--     if false then
--         return
--     end
--     local curIndexPos = self._dragOriginPos[curData.index]
--     local curOriginPosX = curIndexPos.x + curData.centerX
--     local centerX = curData.centerX + curPos.x
--     local swapIndex = nil
--     local bMoveUp = true
--     for k, v in pairs(self._dragIndexList) do
--         if k ~= curData.index then
--             local originPos = self._dragOriginPos[k]
--             local dragKey = "_dragItem_" .. v
--             local dragItemData = self._dragItemDataList[dragKey]
--             local itemcenterX = dragItemData.centerX + originPos.x
--             local itemmidW = dragItemData.midW
--             local odis = centerX - itemcenterX
--             local dis = odis
--             if dis < 0 then
--                 dis = -dis
--             end
--             if dis < itemmidW then
--                 bMoveUp = curOriginPosX < itemcenterX
--                 swapIndex = k
--                 break
--             end
--         end
--     end
--     if not swapIndex then
--         return
--     end

--     local min = bMoveUp and (curData.index + 1) or (curData.index - 1)
--     local max = bMoveUp and swapIndex or swapIndex

--     local delta = bMoveUp and -1 or 1

--     for k = min, max, -delta do
--         local keyIndex = self._dragIndexList[k]
--         local dragKey = "_dragItem_" .. keyIndex
--         local dragItemData = self._dragItemDataList[dragKey]
--         local newIndex = k + delta
--         local oldIndex = dragItemData.index
--         dragItemData.index = newIndex
--         local item = dragItemData.item
--         local tween = dragItemData.tween
--         if tween then
--             tween:Kill(false)
--         end
--         local originPos = self._dragOriginPos[newIndex]
--         tween = item:DOLocalMoveX(originPos.x, 0.2)
--         tween:OnComplete(function()
--             local dragItemData = self._dragItemDataList[dragKey]
--             if dragItemData then
--                 dragItemData.tween = nil
--             end
--         end)
--         dragItemData.tween = tween
--         tween:PlayForward()
--         self:OnSwap(oldIndex, newIndex)
--     end
--     table.remove(self._dragIndexList, curData.index)
--     curData.index = swapIndex
--     table.insert(self._dragIndexList, swapIndex, curData.keyIndex)
-- end
-- function UIChaePop:OnSwap(oldIndex, newIndex)
    -- local _medalList = self._medalList
    -- local oldItem = _medalList[oldIndex]
    -- local newItem = _medalList[newIndex]
    -- _medalList[oldIndex] = newItem
    -- _medalList[newIndex] = oldItem
    -- self._medalList = _medalList

    -- local badgeList = self._currIdList[ModelPlayerSpace.ROLE_MEDAL]
    -- local oldHero = badgeList[oldIndex]
    -- local newHero = badgeList[newIndex]
    -- badgeList[oldIndex] = newHero
    -- badgeList[newIndex] = oldHero
    -- self._currIdList[ModelPlayerSpace.ROLE_MEDAL] = badgeList
    -- for i, v in pairs(self._medalList) do
    --     self:SetWndClick(v, function()
    --         self:OnClickMedalList(i)
    --     end)
    -- end
-- end
-- function UIChaePop:OnSwopTag(oldKey, nexKey)
--     local _dragTagDataList = self._dragTagDataList
--     if nexKey == "0" then
--         local dragItemData = _dragTagDataList[oldKey]
--         local originPos = dragItemData.localPos
--         self:OnTweenTag(oldKey, originPos)
--     else
--         local oldDragItemData = _dragTagDataList[oldKey]
--         local oldOriginPos = oldDragItemData.localPos
--         local oldIndex = oldDragItemData.index
--         local currPos = oldDragItemData.item.localPosition
--         local newDragItemData = _dragTagDataList[nexKey]
--         local newOriginPos = newDragItemData.localPos
--         local newIndex = newDragItemData.index
--         self:OnTweenTag(oldKey, oldOriginPos)
--         self:OnTweenTag(nexKey, newOriginPos, currPos)

--         --local tags = self._currIdList[ModelPlayerSpace.ROLE_TAG]
--         local tags = {}
--         local oldData = tags[oldIndex]
--         local newData = tags[newIndex]
--         tags[oldIndex] = newData
--         tags[newIndex] = oldData
--         --self._currIdList[ModelPlayerSpace.ROLE_TAG] = tags
--         self:RefreshTagInfo()
--     end
-- end
-- function UIChaePop:OnTweenTag(_dragTag_, originPos, initPos)
--     local _dragTagDataList = self._dragTagDataList
--     local dragItemData = _dragTagDataList[_dragTag_]
--     local item = dragItemData.item
--     local tween = dragItemData.tween
--     if tween then
--         tween:Kill(false)
--     end
--     if initPos then
--         item.localPosition = initPos
--     end
--     tween = item:DOLocalMove(originPos, 0.2)
--     tween:OnComplete(function()
--         local dragItemData = _dragTagDataList[_dragTag_]
--         if dragItemData then
--             dragItemData.tween = nil
--         end
--     end)
--     dragItemData.tween = tween
--     tween:PlayForward()
-- end
---------------------------------------初始化徽章拖动-------------------------------------------
return UIChaePop


