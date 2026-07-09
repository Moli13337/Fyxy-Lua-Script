---
--- Created by Administrator.
--- DateTime: 2024/5/23 10:37:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMotifActEntrance_6:LWnd
local UIMotifActEntrance_6 = LxWndClass("UIMotifActEntrance_6", LWnd)

UIMotifActEntrance_6.ACTIVITY_TYPE_SECTION = 1                --时间区间
UIMotifActEntrance_6.ACTIVITY_TYPE_SERVICE = 2                --开服时间
UIMotifActEntrance_6.ACTIVITY_TYPE_REGISTER = 3                --注册时间
UIMotifActEntrance_6.ACTIVITY_TYPE_FOREVER = 4                --永久有效
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMotifActEntrance_6:UIMotifActEntrance_6()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMotifActEntrance_6:OnWndClose()

    if self._feedOpen then
        GF.OpenWnd("UIMinEntranceList")
        FireEvent(EventNames.ON_CHECK_SUBSCRIBE_FEED_CLEANTAR)
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMotifActEntrance_6:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMotifActEntrance_6:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitData()
    self:InitPara()
    self:InitEvent()

    --界面打开时的数据请求
    self:ReqOnStart()
end

--region 初始化数据 --------------------------------------------------------------------------------
function UIMotifActEntrance_6:InitData()
    self._anchors = {
        [1] = Vector2(0, 1),
        [2] = Vector2(0.5, 1),
        [3] = Vector2(1, 1),
        [4] = Vector2(0, 0.5),
        [5] = Vector2(0.5, 0.5),
        [6] = Vector2(1, 0.5),
        [7] = Vector2(0, 0),
        [8] = Vector2(0.5, 0),
        [9] = Vector2(1, 0),
    }

    self._timeKey = "UIMotifActEntrance_timeKey"
end

function UIMotifActEntrance_6:InitPara()
    local feedOpen = self:GetWndArg("feedOpen")
    self._feedOpen = feedOpen
    if feedOpen then
        LogWarn("正在直流")
    else
        LogWarn("bu 在直流")
    end
    local _sid = self:GetWndArg("sid")
    if not _sid then
        local uniqueJump = self:GetWndArg("subPage")
        _sid = gModelActivity:GetSidByUniqueJump(uniqueJump)
    end
    if not _sid then
        local dataList = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_ACTIVITY_TYPE_85)
        if dataList[1] then
            _sid = dataList[1].sid
        end
    end
    if not _sid then
        self:WndClose()
        return
    end

    self._sid = _sid

    self._title = gModelActivity:GetLngNameByActivitySid(_sid)
    --这个面板默认是6的类型
    self._themeType = 6
end

--设置列表的位置和显示的大小
function UIMotifActEntrance_6:SetListPos()
    local themelistPos = self._pageConfig.themelistPos
    local themelistScope = self._pageConfig.themelistScope
    local mEntryList = self.mShowList
    if not string.isempty(themelistPos) then
        local pos = LxDataHelper.ParseVector2NotEmpty3(themelistPos)
        self:SetAnchorPos(mEntryList, pos)
    end

    if not string.isempty(themelistScope) then
        local arr = string.split(themelistScope, ";")
        local a1, a2 = tonumber(arr[1]), tonumber(arr[2])

        mEntryList.sizeDelta = Vector2.New(a1, a2)
    end
    --
    --UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(mEntryList)
end

function UIMotifActEntrance_6:InitEvent()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
        if sid ~= self._sid then
            return
        end
        self:OnActivityConfigData()
        --self:RefreshTime()
    end)

    --补上活动的数据
    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        local sid = pb.sid
        if self._sid ~= sid then
            return
        end
        self:ResetData(pb)
    end)

    --活动的红点检查
    self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshCellRP() end)


    self:WndEventRecv(EventNames.ON_ACT_PAGE_RED_CHANGE, function()
        self:RefreshCellRP()
    end)



    self:SetWndClick(self.mBtnClose, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mBtnClose2, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mBtnHelp, function(...)
        self:OnClickHelp()
    end, LSoundConst.CLICK_ERROR_COMMON)

    self:WndEventRecv(EventNames.ON_INVASION_OPEN,function()
        self:WndClose()
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:RefreshCellRP()
    end)
end

function UIMotifActEntrance_6:OnClickHelp()
    local content = self._pageConfig.signHelpTips or ""
    local title = self._title or ""
    GF.OpenWnd("UIBzTips", { title = title, text = content })
end

function UIMotifActEntrance_6:RefreshData()
    local _themeType = self._themeType
    local _pages = self._pages
    local _sid = self._sid
    if not _pages or not _themeType then
        return
    end
    local activityData = gModelActivity:GetActivityBySid(_sid)
    if not activityData then
        self:WndClose()
        return
    end
    local moreInfo = JSON.decode(activityData.moreInfo)
    local openList = moreInfo.openList or {}
    local _openList = {}
    for i, v in ipairs(openList) do
        local templateId = tonumber(v[1])
        _openList[templateId] = v
    end
    self._openList = _openList

    local pageData = _pages[1]
    if not pageData then
        self:WndClose()
        return
    end

    local entry = pageData.entry
    local list = {}
    for i, v in ipairs(entry) do
        local entryCfg = gModelActivity:GetWebActivityEntryData(_sid, v.pageId, v.entryId)
        v.entryCfg = entryCfg
        table.insert(list, v)
    end
    self._enterWebInfo = list

    self:CreateShowList()
end
--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
function UIMotifActEntrance_6:OnActivityConfigData()
    local _sid = self._sid
    local activityData = gModelActivity:GetWebActivityDataById(_sid)
    if not activityData then
        return
    end
    self._pageConfig = activityData.config
    self:CreateShowListData()
    self:SetListPos()

    self:SetCloseBtnState()
    self:SetSignImage()
    self:SetHeadLine()
    self:SetHelpTips()
    self:SetTime()
    self:SetBottomImage()
    self:SetListBg()
    self:SetSpine()
    --设置完 请求界面的服务器数据
    gModelActivity:OnActivityPageReq(_sid)
end

function UIMotifActEntrance_6:SetItemTime()
    local _timeList = self._timeList or {}
    local curTime = GetTimestamp()
    for i, v in pairs(_timeList) do
        local endTime = v.endTime
        local timeText = v.timeText

        local timespan = endTime - curTime
        local timeStr = LUtil.FormatTimespanCn(timespan)
        timeStr = string.replace(ccClientText(29205), timeStr)

        self:SetWndText(timeText, timeStr)
    end
end

function UIMotifActEntrance_6:ReqOnStart()
    gModelActivity:ReqActivityConfigData(self._sid)
end

--设置标题头部
function UIMotifActEntrance_6:SetHeadLine()
    local headline = self._pageConfig.headline
    local headlinePos = self._pageConfig.headlinePos

    if LxUiHelper.IsImgPathValid(headline) then
        local trans = self.mTitleImg
        CS.ShowObject(trans, true)
        self:SetWndEasyImage(trans, headline, nil, true)
        if not string.isempty(headlinePos) then
            local pos = LxDataHelper.ParseVector2NotEmpty3(headlinePos)
            self:SetAnchorPos(trans, pos)
        end
    end
end

--设置时间部分
function UIMotifActEntrance_6:SetTime()
    local timePos = self._pageConfig.timePos

    if not string.isempty(timePos) then
        local pos = LxDataHelper.ParseVector2NotEmpty3(timePos)
        self:SetAnchorPos(self.mTimeBg, pos)
    end

    local _timeKey = self._timeKey
    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        return
    end
    local endTime = activityData.endTime
    if endTime <= 0 then
        self:TimerStop(_timeKey)
        self:SetWndText(self.mTimeText, ccClientText(18404))
        if self.jpj then
            self:InitTextSizeWithLanguage(self.mTimeText,-2)
        end
        CS.ShowObject(self.mTimeBg, true)
        return
    end
    local time = GetTimestamp()
    local timespan = endTime - time
    local timeStr = ""
    if (timespan < 0) then
        timeStr = ccClientText(14301)
        self:TimerStop(_timeKey)
    else
        local _enterTime = self._enterTime
        local timeF = _enterTime and _enterTime or ccClientText(18400)
        timeStr = LUtil.FormatTimespanCn(timespan)
        timeStr = string.replace(timeF, timeStr)
    end
    self:SetWndText(self.mTimeText, timeStr)
    if self.jpj then
        self:InitTextSizeWithLanguage(self.mTimeText,-2)
    end
    CS.ShowObject(self.mTimeBg, true)
end

function UIMotifActEntrance_6:RefreshCellRP()
    local sid = self._sid
    local redTrList = self._cellRedPointTran or {}
    for i, v in pairs(redTrList) do
        local resData = self._cellRedPointInfo[i]
        local isRed = gModelRedPoint:GetActivityRedPointPageEntry(sid,resData.pageId,resData.enterId)
        CS.ShowObject(v, isRed)
    end
end

--标题旁边的？部分
function UIMotifActEntrance_6:SetHelpTips()
    local signHelpTips = self._pageConfig.signHelpTips
    local signHelpTipsPos = self._pageConfig.signHelpTipsPos

    if not string.isempty(signHelpTips) then
        local trans = self.mBtnHelp
        CS.ShowObject(trans, true)
        if not string.isempty(signHelpTipsPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty3(signHelpTipsPos)
            self:SetAnchorPos(trans, pos)
        end
    end
end

--设置背景的大图
function UIMotifActEntrance_6:SetSignImage()
    local signImage = self._pageConfig.signImage
    local bgAdjustPara = self._pageConfig.bgAdjustPara
    local bgAnchorType = self._pageConfig.bgAnchorType
    if not string.isempty(signImage) then
        local paint = self.mBgImage
        CS.ShowObject(paint, true)
        local isNativeSize = false
        if themeType == 1 and not string.isempty(bgAdjustPara) then
            isNativeSize = true
            local arr = string.split(bgAdjustPara, "=")
            paint.localScale = Vector2.New(tonumber(arr[1]), tonumber(arr[1]))
            local pos = LxDataHelper.ParseVector2NotEmpty3(arr[2])
            self:SetAnchorPos(paint, pos)
            self:SetWndEasyImage(paint, signImage, nil, isNativeSize)
        else
            self:SetWndEasyImage(paint, signImage)
        end
        if not string.isempty(bgAnchorType) then
            local anchorType = tonumber(bgAnchorType)
            if anchorType >= 1 and anchorType <= 9 then
                local anchorV = self._anchors[anchorType]
                self:SetTrAnchors(paint, anchorV)
            end
        end

    end
end

function UIMotifActEntrance_6:OpenAwakeSkill(para)
    local numList = LxDataHelper.ParseNumber_Sign(para, ',')

    gModelHeroExtra:OpenHeroTreeSkillPreviewWnd({ heroTreePointLvList = numList, })
end

function UIMotifActEntrance_6:CreateSmallCell(item, itemdata)
    --找到small的节点
    local Template_2 = CS.FindTrans(item, "Template_2")
    local root_1 = CS.FindTrans(Template_2, "Con_1/Bg")
    local root_2 = CS.FindTrans(Template_2, "Con_2/Bg")
    local sizeX = 2 * root_1.sizeDelta.x
    local sizeY = root_1.sizeDelta.y
    local size = Vector2.New(sizeX, sizeY)

    item.sizeDelta = size

    --设置节点内容 -- 传入节点和相关的参数
    self:SetCellInfo(root_1, itemdata[1], item)
    self:SetCellInfo(root_2, itemdata[2], item)
end

function UIMotifActEntrance_6:SetCellInfo(root, itemdata, item)
    local Name = CS.FindTrans(root, "Name")
    local redPoint = self:FindWndTrans(root, "redPoint")
    local TimeIcon = CS.FindTrans(root, "TimeIcon")
    local timeText = self:FindWndTrans(root, "TimeText")

    CS.ShowObject(TimeIcon, false)


    -- 入口配置
    local enterId = itemdata.refId
    local infoData = self._enterWebInfo[enterId]
    local entryCfg = infoData.entryCfg
    local pageId = infoData.pageId

    local eModel = entryCfg.eModel or 0
    local templateId = entryCfg.templateId
    local _openList = self._openList or {}
    local _openData = _openList[templateId]
    local isOpenActivity = false
    local activityData = nil
    local templateState = entryCfg.templateState
    --if itemdata.refId ==5 then
    --    printInfoN2("--","--")
    --end

    if eModel > 0 then
        local list = gModelActivity:GetActivityDataByModelId(eModel)
        local len = #list
        if len > 0 then
            for i, v in ipairs(list) do
                local moreInfo = JSON.decode(v.moreInfo)
                if moreInfo and templateId == moreInfo.templateId then
                    isOpenActivity = true
                    activityData = v
                    break
                end
            end
        end
    else
        isOpenActivity = true
    end


    local activityStatus = activityData and activityData.status or ModelActivity.STATUS_NO_SHOW

    --背景名称
    self:SetWndEasyImage(root, entryCfg.templateIcon)
    self:SetWndText(Name, entryCfg.templateName)

    --拿到点击参数
    local clickArgs = self:GetClickArgs(entryCfg)
    clickArgs.enterId=enterId
    clickArgs.pageId=pageId
    self:SetItemClick(root, clickArgs)

    --红点部分 红点节点的持有
    if not self._cellRedPointTran then
        self._cellRedPointTran = {}
    end
    self._cellRedPointTran[enterId] = redPoint

    --红点的检查信息的持有
    if not self._cellRedPointInfo then
        self._cellRedPointInfo = {}
    end

    local redpointData = { sid = self._sid, pageId = pageId, enterId = enterId }
    self._cellRedPointInfo[enterId] = redpointData

    local isRed = gModelRedPoint:GetActivityRedPointPageEntry(self._sid, pageId, enterId)
    CS.ShowObject(redPoint, isRed)

    --时间
    --设置时间


    local timeStr = ""
    if _openData then
        timeStr = ccClientText(29200)
        local curTime = GetTimestamp()
        local endTime = _openData[4] and tonumber(_openData[4]) or 0
        local type = tonumber(_openData[2])

        if not self._timeList then
            self._timeList = {}
        end
        --记录时间信息
        local timeData = {}
        timeData.endTime = endTime
        timeData.timeText = timeText

        --if activityStatus ~= ModelActivity.STATUS_INVALID then
        if type == UIMotifActEntrance_6.ACTIVITY_TYPE_FOREVER then
            timeStr = ccClientText(29206)
        elseif activityStatus == ModelActivity.STATUS_VALID then
            local timespan = endTime - curTime
            timeStr = LUtil.FormatTimespanCn(timespan)
            timeStr = string.replace(ccClientText(29205), timeStr)
            local data = {
                endTime = endTime,
                timeText = timeText
            }

            if not self._timeList then
                self._timeList = {}
            end

            self._timeList[enterId] = data

            CS.ShowObject(TimeIcon, true)
        elseif endTime > 0 and endTime < curTime then

        else
            timeStr = templateState
        end
        --end
        CS.ShowObject(TimeIcon, true)
    else
        timeStr=ccClientText(14301)
        CS.ShowObject(TimeIcon, true)
    end
    self:SetWndText(timeText, timeStr)
    if self.jpj then
        self:InitTextSizeWithLanguage(timeText,-4)
    end
end
--endregion --------------------------------------------------------------------------------------

--region 界面数据 --------------------------------------------------------------------------------
function UIMotifActEntrance_6:CreateShowListData()
    local tempData_1 = string.split(self._pageConfig.cellType, "|")

    local showList = {}
    for k, v in ipairs(tempData_1) do
        local tempData_2 = string.split(v, "=")

        local data = {}
        data.refId = tonumber(tempData_2[1])
        data.row = tonumber(tempData_2[2])
        data.cellType = tonumber(tempData_2[3])

        if not showList[data.row] then
            showList[data.row] = {}
        end
        table.insert(showList[data.row], data)
    end

    self._showList = showList
end

--获取点击的参数 -- 兼容太多的地方了
function UIMotifActEntrance_6:GetClickArgs(entryCfg)
    local clickArgs = {}
    local _openList = self._openList or {}
    local templateId = entryCfg.templateId

    clickArgs.eModel = entryCfg.eModel or 0
    clickArgs. isOpenActivity = false
    clickArgs. activityData = nil
    clickArgs. templateId = entryCfg.templateId
    clickArgs. templateMoreInfo = entryCfg.moreInfo
    clickArgs. _openList = self._openList or {}
    clickArgs. _openData = _openList[templateId]
    clickArgs. _sid = self._sid
    clickArgs. templateTitle = entryCfg.templateTitle
    clickArgs. jumpId = entryCfg.jumpId or 0
    clickArgs.entryCfg = entryCfg

    if clickArgs.eModel > 0 then
        local list = gModelActivity:GetActivityDataByModelId(clickArgs.eModel)
        local len = #list
        if len > 0 then
            for i, v in ipairs(list) do
                local moreInfo = JSON.decode(v.moreInfo)
                if moreInfo and templateId == moreInfo.templateId then
                    clickArgs.isOpenActivity = true
                    clickArgs.activityData = v
                    break
                end
            end
        end
    else
        clickArgs.isOpenActivity = true
    end

    clickArgs.openHeroType, clickArgs.para = 0, 0
    if not string.isempty(clickArgs.templateMoreInfo) then
        local heroArr = string.split(clickArgs.templateMoreInfo, "=")
        clickArgs.openHeroType = tonumber(heroArr[1])
        clickArgs.para = heroArr[2]
    end

    return clickArgs
end

--endregion --------------------------------------------------------------------------------------

--region 界面表现 --------------------------------------------------------------------------------
--创建中间内容列表
function UIMotifActEntrance_6:CreateShowList()
    local _uiList = self._uiShowList

    --红点持有的引用
    self._redTran = {}

    if _uiList then
        _uiList:RefreshList(self._showList)
        _uiList:DrawAllItems()
    else
        _uiList = self:GetUIScroll("sift1List")
        _uiList:Create(self.mShowList, self._showList, function(...)
            self:CreateShowListItem(...)
        end, UIItemList.SUPER)
        self._uiShowList = _uiList
    end

end
--endregion --------------------------------------------------------------------------------------

--region 计时器部分 --------------------------------------------------------------------------------
function UIMotifActEntrance_6:OnTimer(key)
    if (key == self._timeKey) then
        self:SetTime()
        self:SetItemTime()
    end
end

--设置列表的背景
function UIMotifActEntrance_6:SetListBg()
    local themelistBg = self._pageConfig.themelistBg

    if not string.isempty(themelistBg) then
        CS.ShowObject(self.mListBg, true)
        self:SetWndEasyImage(self.mListBg, themelistBg, nil, true)
    end

    local themelistBgPos =self._pageConfig.themelistBgPos

    local pos = LxDataHelper.ParseVector2NotEmpty3(themelistBgPos)
    self:SetAnchorPos(self.mListBg, pos)
end

function UIMotifActEntrance_6:CreateShowListItem(list, item, itemdata, itempos)
    --取 1 的 type  判断是那种类型的
    local itemCellTypeType = itemdata[1].cellType

    --控制好显隐
    local Template_1 = CS.FindTrans(item, "Template_1")
    local Template_2 = CS.FindTrans(item, "Template_2")

    CS.ShowObject(Template_1, itemCellTypeType == 1)
    CS.ShowObject(Template_2, itemCellTypeType == 2)
    if itemCellTypeType == 1 then
        self:CreateBigCell(item, itemdata)
    else
        self:CreateSmallCell(item, itemdata)
    end

end

function UIMotifActEntrance_6:SetSpineShow(root,LHRes,LHOverturn,LHPos)
    local emptyRes = string.isempty(LHRes)
    if emptyRes then
        CS.ShowObject(root, false)
        return
    end

    CS.ShowObject(root, true)
    local spinekey = root:GetInstanceID()
    local spine = self:FindWndSpineByKey(spinekey)
    if not spine then
        self:CreateWndSpine(root, LHRes, spinekey, false, function(dpSpine)
            --dpSpine:PlayAnimationSolid("animation", true)
        end)
    end

    local x_OverTurn = LHOverturn and -1 or 1
    root.localScale = Vector2(x_OverTurn, 1)

    LHPos = LHPos or "0,0"
    local pos = string.split(LHPos, ",")
    root.localPosition = Vector2.New(checknumber(pos[1]), checknumber(pos[2]))
end

function UIMotifActEntrance_6:CreateBigCell(item, itemdata)
    -- 找到big的节点
    local Template_1 = CS.FindTrans(item, "Template_1")
    local root = CS.FindTrans(Template_1, "Bg")

    --设置大小
    local size = root.sizeDelta
    item.sizeDelta = size

    -- 入口配置
    local enterId = itemdata[1].refId
    local infoData = self._enterWebInfo[enterId]
    local entryCfg = infoData.entryCfg

    self:SetCellInfo(root, itemdata[1], item)
end

function UIMotifActEntrance_6:ResetData(pb)
    local _pages = self._pages or {}
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        _pages[page.pageId] = page
    end
    self._pages = _pages

    self:RefreshData()
end

--设置立绘
function UIMotifActEntrance_6:SetSpine()
    local pageConfig = self._pageConfig
    if not pageConfig then return end

    self:SetSpineShow(self.mLiHui_1,pageConfig.LH,pageConfig.LHOverturn == 1,pageConfig.LHPos)
    self:SetSpineShow(self.mLiHui_2,pageConfig.LH2,pageConfig.LHOverturn2 == 1,pageConfig.LHPos2)
end

function UIMotifActEntrance_6:SetBottomImage()
    local bottomImg = self._pageConfig.bottomImg

    local arr = string.split(bottomImg, "=")
    if LxUiHelper.IsImgPathValid(arr[1]) then
        local img = self.mBottomImg
        self:SetWndEasyImage(img, arr[1], function()
            CS.ShowObject(img, true)
            if not string.isempty(arr[2]) then
                local sizeV2 = LxDataHelper.ParseVector2NotEmpty(arr[2])
                img.sizeDelta = sizeV2
            end
            if not string.isempty(arr[3]) then
                local pos = LxDataHelper.ParseVector2NotEmpty(arr[3])
                self:SetAnchorPos(img, pos)
            end
            local anchorType = arr[4] and tonumber(arr[4]) or 0
            if anchorType >= 1 and anchorType <= 9 then
                local anchorV = self._anchors[anchorType]
                self:SetTrAnchors(img, anchorV)
            end
        end)
    end
end


--设置退出按钮的样式和位置
function UIMotifActEntrance_6:SetCloseBtnState()

    local closeBtn = self._pageConfig.closeBtn
    if not string.isempty(closeBtn) then
        local paint
        local arr = string.split(closeBtn, "=")
        local anchorType = tonumber(arr[1]) or 0
        local imgStr = arr[2]
        local posStr = arr[3]
        if not posStr then
            posStr = arr[2]
            imgStr = arr[1]
            anchorType = 5
        end
        if LxUiHelper.IsImgPathValid(imgStr) then
            paint = self.mBtnClose
            self:SetWndEasyImage(paint, imgStr, function()
                CS.ShowObject(paint, true)
            end, true)
        end
        if anchorType >= 1 and anchorType <= 9 and paint then
            local anchorV = self._anchors[anchorType]
            self:SetTrAnchors(paint, anchorV)
        end
        if not string.isempty(posStr) and paint then
            local pos = LxDataHelper.ParseVector2NotEmpty3(posStr)
            self:SetAnchorPos(paint, pos)
        end
    else
        CS.ShowObject(self.mBtnClose, true)
    end

    local closeText = self._pageConfig.closeText
    if not string.isempty(closeText) then
        local paint = self.mCloseText
        local arr = string.split(closeText, "=")
        local text = arr[1]
        local posStr = arr[2]
        self:SetWndText(paint, text)
        CS.ShowObject(paint, true)
        if not string.isempty(posStr) then
            local pos = LxDataHelper.ParseVector2NotEmpty3(posStr)
            self:SetAnchorPos(paint, pos)
        end
    end
end

--给节点设置点击的方法
function UIMotifActEntrance_6:SetItemClick(item, clickArgs)
    local eModel = clickArgs.eModel or 0
    local isOpenActivity = clickArgs.isOpenActivity
    local activityData = clickArgs.activityData
    local templateId = clickArgs.templateId
    local templateMoreInfo = clickArgs.templateMoreInfo
    local _openList = clickArgs._openList
    local _openData = clickArgs._openData
    local _sid = clickArgs._sid
    local templateTitle = clickArgs.templateTitle
    local jumpId = clickArgs.jumpId or 0
    local openHeroType, para = clickArgs.openHeroType, clickArgs.para
    local entryCfg = clickArgs.entryCfg

    self:SetWndClick(item, function()
        if openHeroType ~= 0 then
            if openHeroType == 1 then
                gModelGeneral:OpenHeroSkin({ skinRefId = tonumber(para), preview = true })
            elseif openHeroType == 2 then
                gModelGeneral:OpenHeroSimpleTip(tonumber(para), true)
            elseif openHeroType == 3 then
                gModelBattle:OnClickShamBattle(tonumber(para))
            elseif openHeroType == 4 then
                self:OpenAwakeSkill(para)
            end
            return
        end
        if not isOpenActivity then
            if not _openData then
                GF.ShowMessage(ccClientText(29201))
                return
            end
            local activityDatas = gModelActivity:GetActivityBySid(_sid)
            local sTime = _openData[3] or "-1"
            local eTime = _openData[4] or "-1"
            local endTime = tonumber(eTime)
            local curTime = GetTimestamp()
            if tonumber(sTime) > activityDatas.endTime or activityDatas.startTime > endTime then
                GF.ShowMessage(entryCfg.templateTips)
                return
            elseif endTime > 0 and endTime < curTime then
                GF.ShowMessage(ccClientText(29201))
                return
            end
            local para = {
                templateName = templateTitle,
                reward = entryCfg.templateAward,
                openData = _openData,
                templateText = entryCfg.templateText
            }
            GF.OpenWnd("UIMotifActPreview", para)
            return
        end
        if activityData and activityData.status == ModelActivity.STATUS_INVALID then
            GF.ShowMessage(ccClientText(29201))
            return
        end
        if jumpId > 0 then
            local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId, true)
            if not isOpen then
                return
            end
            gModelFunctionOpen:Jump(jumpId, self:GetWndName())
            --self:WndClose()
            return
        end
        local func = gModelActivity:GetShowActivityFun(activityData.model)
        if func then

            --这里顺便进行红点是否点击取消的发送
            gModelActivity:OnActivitySpecialOpReq(activityData.sid,clickArgs.pageId, clickArgs.enterId, nil, "1",26)
            func(activityData, _sid)
        end
    end)
end
function UIMotifActEntrance_6:OnTryTcpReconnect()
    if self._sid then
        self:ReqOnStart()
    end
end
--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIMotifActEntrance_6