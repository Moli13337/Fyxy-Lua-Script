---
--- Created by Administrator.
--- DateTime: 2023/10/21 16:54:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIVdoCenter:LWnd
local UIVdoCenter = LxWndClass("UIVdoCenter", LWnd)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIVdoCenter:UIVdoCenter()
    ---@type table<number,CommonIcon>
    self._iconHeroClsList = {}

    self._winIconPath = "bestronger_txt_1"
    self._failIconPath = "bestronger_txt_2"
    self._emptySkillBgPath = "public_skill_bg"
    self._defaultFilterType = 1000 --默认不筛选的id
    self._likeRedTransList = {}

    self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIVdoCenter:OnWndClose()
    self._oldTab = nil
    self._curTab = nil
    self._curSelectTypeRefId = nil
    self._tabBtnList = {}
    self._typeBtnList = {}
    self._curVideoDataList = nil
    self._curSelFilterRefId = nil
    self._likeRedTransList = {}

    --if self._uiTypeList then
    --	self._uiTypeList:OnWndClose()
    --end

    if self._uiVideoDataList then
        self._uiVideoDataList:OnWndClose()
    end

    self._uiheadList = {}

    --清楚缓存数据
    gModelVideoCenter:ClearServerInfo()

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIVdoCenter:OnCreate()
    LWnd.OnCreate(self)

    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIVdoCenter:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self.jpj = gLGameLanguage:IsJapanVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:InitTabList()

    self:SetStaticContent()
    self:TryRefreshContent()
    self:RefreshTop()
end

function UIVdoCenter:OnClickVideo(reportTable, videoInfo)
    local reportId = reportTable.id
    local combatType = LCombatTypeConst.COMBAT_BATTLE_VIDEO
    local extraData = {
        combatType = reportTable.combatType,
        videoType = LVideoTypeConst.SIMULATE_FIGHT,
        battleEndfun = function()
            gModelGeneral:RecoverGameState()
        end
    }

    local videoIndex = videoInfo:GetVideoIndex()
    self._videoIdRecord = videoInfo:GetId()
    gModelVideoCenter:OnVideoTAClientEventReq("录像馆_播放", reportId, self._tabPage, self._typeRefId)
    gModelVideoCenter:OnVideoOperaReq(ModelVideoCenter.OperaBackPlay, videoIndex)

    gModelGeneral:RecordGameState()
    gLFightManager:StartBattle(reportId, combatType, extraData, reportTable)
end

function UIVdoCenter:OnClickData(videoInfo)
    local extraData = {}
    local combatType = videoInfo:GetCombatType()
    --local attackPlayer = videoInfo:GetAttackPlayer()
    --local defensePlayer = videoInfo:GetDefensePlayer()
    local reportId = videoInfo:GetReportId()
    local videoIndex = videoInfo:GetVideoIndex()
    local id = videoInfo:GetId()
    local tabPage = self._curTab
    local typeRefId = self._curSelectTypeRefId
    local serverId = videoInfo:GetServerId()
    --local reportUrl = gModelCrossServer:GetServerReportUrl(serverId)

    local isMultiReport = false
    if combatType == LCombatTypeConst.COMBAT_CROSSGRADING_RANK then
        isMultiReport = true
        local otherReport = videoInfo:GetOtherReport()
        if otherReport then
            extraData.reportId = otherReport.reportIdList
            extraData.winnerNumber = otherReport.winnerNumber
        end
    elseif combatType == LCombatTypeConst.COMBAT_TYPE_25 then
        isMultiReport = true

        extraData.reportId = videoInfo.reportList
        extraData.winnerNumber = videoInfo.winnerNumber
        serverId = videoInfo.reportServerId
    end

    extraData.combatType = combatType
    extraData.serverId = serverId

    extraData.videoType = gModelBattle:GetVideoTypeCostByCombatType(combatType)
    extraData.closeAfterVideo = function()
        GF.ChangeMap("LCityMap")
        GF.OpenWndBottom("UIVdoCenter", { tabPage = tabPage, typeRefId = typeRefId, videoId = id })
    end
    extraData.playExtraFun = function()
        gModelVideoCenter:OnVideoTAClientEventReq("录像馆_播放", reportId, tabPage, typeRefId)
        gModelVideoCenter:OnVideoOperaReq(ModelVideoCenter.OperaBackPlay, videoIndex)
    end

    if isMultiReport then
        gLFightManager:ShowCrossGradingBattleDetail(extraData)
    else
        gLFightManager:OnOpenBattleDetails(reportId, extraData, serverId)
    end


end

function UIVdoCenter:SetEmptyContent(item)
    local playNode = self:FindWndTrans(item, "playerNode")
    local emptyTips = self:FindWndTrans(item, "emptyTips")

    CS.ShowObject(playNode, false)

    CS.ShowObject(emptyTips, true)
    self:SetWndText(emptyTips, ccClientText(25308))
end

--itemdata--StructVideoInfo
function UIVdoCenter:SetVideoDataItem(list, item, itemdata, itemPos)
    local ReportTrans = self:FindWndTrans(item, "Report")

    self:CreateReportPart_New(ReportTrans, itemdata, itemPos)
end

function UIVdoCenter:OnClickTag(tagIndex)
    self._curTab = tagIndex
    self._curSelFilterRefId = nil
    self._curSelectTypeRefId = nil
    self:RefreshTagState()
    self:RefreshTypeList()
    self:RefreshTop()
    self:TryRefreshContent()
end

function UIVdoCenter:OnClickType(typeIndex)
    local data = self._typeDataList[typeIndex]
    if not data then
        printInfoNR("self._typeDataList[typeIndex] is not find, typeIndex = " .. typeIndex)
        return
    end

    local refId = data.refId
    local isOpen = gModelVideoCenter:CheckVideoTypeIsOpen(refId, true)
    if not isOpen then
        return
    end

    if refId == self._curSelectTypeRefId then
        return
    end

    local oldRefId = self._curSelectTypeRefId
    local oldTabBtn = self._typeBtnList[oldRefId]
    self:SetWndTabStatus(oldTabBtn, LWnd.StateOff)

    local newRefId = refId
    local newTabBtn = self._typeBtnList[newRefId]
    self:SetWndTabStatus(newTabBtn, LWnd.StateOn)

    self._curSelectTypeRefId = refId
    self._curSelFilterRefId = nil
    self:RefreshFiltrate()
    self:TryRefreshContent()
end

function UIVdoCenter:InitData()
    self._tabPage = self:GetWndArg("tabPage")
    self._typeRefId = self:GetWndArg("typeRefId")
    self._videoId = self:GetWndArg("videoId")

    self._curTab = not self._tabPage and ModelVideoCenter.All or self._tabPage
    self._curSelectTypeRefId = self._typeRefId

    self._oldTab = nil

    self._tabBtnList = {
        [ModelVideoCenter.All] = self.mAllVideoBtn,
        [ModelVideoCenter.SelfRecord] = self.mSelfRecordBtn,
        [ModelVideoCenter.SelfCollect] = self.mSelfCollectBtn,
    }

    self._typeBtnList = {}
    self._curVideoDataList = nil
    self._uiheadList = {}
    self._curSelFilterRefId = nil
    self._sortBtnRot = {
        open = Quaternion.Euler(0, 0, 0),
        close = Quaternion.Euler(0, 0, 180),
    }

    self._isOpenSort = false
    self._isInitPlayerInfo = false
    self._isHaveLikeNum = gModelVideoCenter:CheckHaveLikeNum()
    self._isHaveRewardLikeNum = gModelVideoCenter:CheckHaveRewardLikeNum()
    gModelVideoCenter:OnVideoPlayerInfoReq()
end
--#####################################################################################################################
--## Content ##########################################################################################################
--#####################################################################################################################
function UIVdoCenter:TryRefreshContent()
    local curTab = self._curTab
    local curSelectTypeRefId = self._curSelectTypeRefId

    gModelVideoCenter:OnVideoInfoReq(curTab, curSelectTypeRefId)
end

function UIVdoCenter:GetTypeListByTabIndex(tabIndex)
    local typeList = {}
    if tabIndex == ModelVideoCenter.SelfCollect then
        return typeList
    end

    typeList = gModelVideoCenter:GetVideoTypeList()
    return typeList
end

function UIVdoCenter:RefreshTopText()
    local curTab = self._curTab
    local str
    if curTab == ModelVideoCenter.All then
        local haveLikeNum = gModelVideoCenter:GetHasLikeNum()
        local color = haveLikeNum > 0 and "green" or "red"
        str = LUtil.FormatColorStr(haveLikeNum, color)
        str = string.replace(ccClientText(21502), str)
    elseif curTab == ModelVideoCenter.SelfRecord then
        local videoSelfMax = gModelVideoCenter:GetVideoSelfMax()
        str = string.replace(ccClientText(21503), videoSelfMax)
    elseif curTab == ModelVideoCenter.SelfCollect then
        local curNum = gModelVideoCenter:GetCurCollectNum()
        local videoCollectMax = gModelVideoCenter:GetVideoCollectMax()
        str = curNum .. "/" .. videoCollectMax
        local color = curNum < videoCollectMax and "green" or "red"
        str = LUtil.FormatColorStr(str, color)
        str = string.replace(ccClientText(21504), str)
    end

    self:SetWndText(self.mTopText, str)
    self:InitTextSizeWithLanguage(self.mTopText, -2)
    self:InitTextLineWithLanguage(self.mTopText, -30)
end

function UIVdoCenter:SetTeamContent(item, itemdata)

    local treasure = itemdata:GetTreasureData()
    local skillList = nil
    if treasure then
        local campSkillIdList = treasure.data or {}
        skillList = campSkillIdList.skillList or {}
    end
    skillList = skillList or {}

    self:SetSkillList(item, skillList)

    local heroListRoot = self:FindWndTrans(item, "Team/heroList")
    self:SetTeamFormation(heroListRoot, itemdata)
end

function UIVdoCenter:OnClickSel(filterRefId)
    self._curSelFilterRefId = filterRefId
    self._isOpenSort = false
    self:SetSelSortListState(false)
    self:RefreshSelSortListBtn()
    self:RefreshContent()
end

function UIVdoCenter:SetReportPart(instanceId, itemdata)
    local reportId = itemdata and itemdata.reportId
    local isEmpty = string.isempty(reportId) or string.find(reportId, "EMPTY")
    if isEmpty then
        local list = self:FindUIScroll(instanceId)
        if not list then
            return
        end
        local metaData = list:GetMetaData()
        self:SetEmptyContent(metaData.tran)
        return
    end
    local reqInfo = {
        reportId = itemdata.reportId,
        serverId = itemdata.serverId,
        callback = function(reportTable)
            local list = self:FindUIScroll(instanceId)
            if not list then
                return
            end
            local metaData = list:GetMetaData()
            local curItemdata = metaData.dataList[metaData.curIndex]
            if not curItemdata or curItemdata.reportId ~= itemdata.reportId then
                return
            end
            local tran = metaData.tran
            self:OnDrawReportPart(tran, reportTable, itemdata.serverId, metaData.videoInfo)
        end
    }

    self:GetReportTableCache(reqInfo)
end

function UIVdoCenter:OnClickSortBtn()
    local list = self._filterTypeRefList
    if #list < 1 then
        return
    end

    self._isOpenSort = not self._isOpenSort
    self:SetSelSortListState(self._isOpenSort)
    if self._isOpenSort then
        self:RefreshSelSortList()
    end
end

function UIVdoCenter:SetTypeItem(list, item, itemdata, itempos)
    local BtnTab1 = self:FindWndTrans(item, "BtnTab1")
    local bg = self:FindWndTrans(item, "bg")
    --local redPointTrans = self:FindWndTrans(bg, "redPoint")
    local refId = itemdata.refId
    local name = gModelVideoCenter:GetVideoTypeName(refId)
    local isOpen = gModelVideoCenter:CheckVideoTypeIsOpen(refId, false)

    local isCurSelect = refId == self._curSelectTypeRefId

    local addSize = -6
    local addLine = -30
    if gLGameLanguage:IsThaiVersion() then
        addSize = -6
        addLine = -50
    end

    self:SetWndTabText(BtnTab1, ccLngText(name), -6, addLine)

    local state = isCurSelect and LWnd.StateOn or LWnd.StateOff
    if not isOpen then
        state = LWnd.StateGray
    end
    self:SetWndTabStatus(BtnTab1, state)
    self:SetWndClick(bg, function()
        self:OnClickType(itempos)
    end)
    self._typeBtnList[refId] = BtnTab1
end

function UIVdoCenter:GetTransScreenPos(targetTrans)
    local canvasRect = self._canvasRect
    return YXUIPointUtil.GetScreenPoint(canvasRect, targetTrans)
end

function UIVdoCenter:OnTargetWndClose(wndName)
    if (wndName == "UIBtnLPop") and self._uiVideoDataList then
        self._uiVideoDataList:EnableScroll(true, false)
    end
end

function UIVdoCenter:SetSelSortListState(isOpen)
    CS.ShowObject(self.mSortMaskBg, isOpen)
    CS.ShowObject(self.mSelSortList, isOpen)

    self.mShowSortBtn.localRotation = isOpen and self._sortBtnRot.open or self._sortBtnRot.close
end

function UIVdoCenter:SetTeamFormation(item, itemdata)

    local playerId = itemdata.playerId
    local serverId = itemdata.serverId
    local heroList = {}
    local grids = itemdata.grids
    for i, v in ipairs(grids) do
        local index = v.index
        heroList[index] = v
    end
    local gridMax = LCombatFormationConst.GRID_MAX
    for k = 1, gridMax do
        local rootPath = string.format("pos_%s/root/iconRoot", k)
        local root = self:FindWndTrans(item, rootPath)
        local instanceId = root:GetInstanceID()
        self:DeleteCommonIcon(instanceId)
        local heroData = heroList[k]
        if heroData then
            local heroInfo = {
                id = heroData.id,
                refId = heroData.refId,
                star = heroData.star,
                level = heroData.level,
                skin = heroData.skinId,
                isResonance = heroData.resonance,
                grade = heroData.grade,
                fightPower = heroData.fightPower,
                form = heroData.form,
            }

            local clickFunc = function()
                gModelHero:ReqShowHeroTip(playerId, heroInfo, nil, nil, nil, serverId)
            end

            heroInfo.clickFunc = clickFunc

            self:CreateHeroIconImpl(root, heroInfo)
        end
    end
end

function UIVdoCenter:CreateReportPart_New_2(tran, itemdata, iswin, infoType, otherReport)
    local WinImg = self:FindWndTrans(tran, "WinImg")
    local FailImg = self:FindWndTrans(tran, "FailImg")
    local Score = self:FindWndTrans(tran, "Score")
    local Head = self:FindWndTrans(tran, "Head")
    local HeadIconTrans = self:FindWndTrans(Head, "HeadIcon")
    local leve =self:FindWndTrans(Head, "HeadIcon/lvBg/level")
    local PlayerName = self:FindWndTrans(tran, "PlayerName")
    local Power = self:FindWndTrans(tran, "Power")
    local RankImg = self:FindWndTrans(tran, "RankImg")
    local RankImg_1 = self:FindWndTrans(RankImg, "RankImg_1")
    local ScoreName = self:FindWndTrans(tran, "ScoreName")
    local ServerName = self:FindWndTrans(tran, "ServerName")
    CS.ShowObject(Score, false)
    CS.ShowObject(RankImg, false)
    CS.ShowObject(RankImg_1, false)
    --CS.ShowObject(ScoreName, false)
    CS.ShowObject(ScoreName, true)
    CS.ShowObject(WinImg, iswin)
    CS.ShowObject(FailImg, not iswin)

    if self._isVie then
        self:SetAnchorPos(leve,Vector2.New(0,-8))
    end

    --头像数据
    local headData = {
        trans = HeadIconTrans,
        icon = itemdata:GetPlayerHead(),
        headFrame = itemdata:GetPlayerFrame(),
        name = itemdata:GetPlayerName(),
        level = itemdata:GetPlayerLevel(),
    }

    local InstanceID = tran:GetInstanceID()
    local baseClass = self:GetHeadIcon(InstanceID)
    baseClass:SetHeadData(headData)

    self:SetWndClick(HeadIconTrans, function()
        gModelGeneral:PlayerShowReq(itemdata:GetPlayerId(), LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
    end)

    --name
    local playerName = itemdata:GetPlayerName()
    local serverName = gModelFriend:GetSevenName(itemdata:GetServerId())
    serverName = string.replace(ccClientText(21533), serverName)
    --if infoType == ModelVideoCenter.AttackPlayer then
    --    playerName = playerName .. serverName
    --else
    --    playerName = serverName .. playerName
    --end

    self:SetWndText(ServerName, serverName)
    self:SetWndText(PlayerName, playerName)
    --power
    local power = string.replace(ccClientText(21811), LUtil.PowerNumberCoversion(itemdata:GetPower()))
    self:SetWndText(Power, power)

    -- 公会部分
    local guildName = itemdata:GetGuildName()
    local guildFlagBgId = itemdata:GetGuildFlagBgId()
    local guildFlagId = itemdata:GetGuildFlagId()

    if checknumber(guildFlagBgId) > 0 then
        CS.ShowObject(RankImg, true)
        CS.ShowObject(RankImg_1, true)

        local fragRef = gModelGuild:GetGuildFlagRefByRefId(guildFlagId)
        local fragBgRef = gModelGuild:GetGuildFlagRefByRefId(guildFlagBgId)

        self:SetWndEasyImage(RankImg, fragBgRef.res, nil, false)
        self:SetWndEasyImage(RankImg_1, fragRef.res, nil, false)

        if infoType == ModelVideoCenter.AttackPlayer then

            self:SetAnchorPos(ScoreName, Vector2.New(-41, 29.7))
        else
            self:SetAnchorPos(ScoreName, Vector2.New(19, 29.7))
            if self.jpj then
                self:SetAnchorPos(ScoreName, Vector2.New(30, 29.7))
            end
        end
        self:SetWndText(ScoreName, string.replace(ccClientText(21187), guildName))
    else
        if infoType == ModelVideoCenter.AttackPlayer then

            self:SetAnchorPos(ScoreName, Vector2.New(-90, 29.7))
        else
            self:SetAnchorPos(ScoreName, Vector2.New(67, 29.7))
            if self.jpj then
                self:SetAnchorPos(ScoreName, Vector2.New(30, 29.7))
            end
        end

        self:SetWndText(ScoreName, string.replace(ccClientText(21187), ccClientText(21188)))
    end
    self:SetAnchorPos(RankImg, Vector2.New(RankImg.anchoredPosition.x, 34))
    --如果是类型20就覆盖掉 公会的处理
    if otherReport then
        if otherReport.combatType == LCombatTypeConst.COMBAT_CROSSGRADING_RANK then
            local score = infoType == ModelVideoCenter.AttackPlayer and otherReport.nowScoreA or otherReport.nowScoreB
            local rank = infoType == ModelVideoCenter.AttackPlayer and otherReport.rankA or otherReport.rankB

            local crossGradingRef = gModelCrossGrading:GetCurCrossGradingIntervalRef(score, rank)
            if crossGradingRef then
                CS.ShowObject(RankImg, true)
                CS.ShowObject(RankImg_1, false)

                local icon = crossGradingRef.icon
                self:SetWndEasyImage(RankImg, icon, nil, false)

                local name = ccLngText(crossGradingRef.name)
                self:SetWndText(ScoreName, name)

                self:SetAnchorPos(RankImg, Vector2.New(RankImg.anchoredPosition.x, 29))
            end


        end


    end
end

function UIVdoCenter:ShowAllLikeRed(isShow)
    for k, v in pairs(self._likeRedTransList) do
        CS.ShowObject(v, isShow)
    end
end

function UIVdoCenter:RefreshContent()
    self._isInitPlayerInfo = true
    local videoDataList = self:GetVideoDataList()
    self._curVideoDataList = videoDataList

    local itemNum = #videoDataList
    local isEmpty = itemNum == 0
    CS.ShowObject(self.mEmptyTips, isEmpty)
    CS.ShowObject(self.mVideoContent, not isEmpty)
    if isEmpty then
        return
    end

    printInfoN("cnt %s " .. itemNum)

    local uiVideoDataList = self._uiVideoDataList
    if uiVideoDataList then
        uiVideoDataList:RefreshList(videoDataList)
    else
        uiVideoDataList = self:GetUIScroll("_uiVideoDataList")
        local para = {
            root = self.mVideoContent,
            dataList = videoDataList,
            setFunc = function(...)
                self:SetVideoDataItem(...)
            end,
            type = UIItemList.SUPER,
            onReturnFunc = function(...)
                self:OnVideoItemReturn(...)
            end
        }
        uiVideoDataList:InitListData(para)

        self._uiVideoDataList = uiVideoDataList
    end

    local targetPos
    if self._videoId then
        for k, v in ipairs(videoDataList) do
            if v:GetId() == self._videoId then
                targetPos = k
                break
            end
        end
        self._videoId = nil
    end

    uiVideoDataList:MoveToPos(targetPos or 1)
end

function UIVdoCenter:RefreshItemByPos(itemPos)
    local uiList = self._uiVideoDataList
    if not uiList then
        return
    end

    local itemData = self._curVideoDataList[itemPos]
    local _uiListSuper = uiList:GetList()
    _uiListSuper:SetDataByIndex(itemPos, itemData)
    _uiListSuper:DrawItemByIndex(itemPos)
end

function UIVdoCenter:RefreshFiltrate()
    local curTab = self._curTab
    local filterTypeRefList
    if curTab == ModelVideoCenter.All or curTab == ModelVideoCenter.SelfRecord then
        if not self._curSelectTypeRefId then
            printInfoNR("self._curSelectTypeRefId is a nil")
            return
        end

        local filterType = gModelVideoCenter:GetTypeVideoFilterType(self._curSelectTypeRefId)
        filterTypeRefList = gModelVideoCenter:GetVideoFilterTypeRefList(filterType)
    elseif curTab == ModelVideoCenter.SelfCollect then
        filterTypeRefList = gModelVideoCenter:GetVideoFilterTypeRefList(self._defaultFilterType)
    end

    self._filterTypeRefList = filterTypeRefList
    if not self._curSelFilterRefId and not table.isempty(filterTypeRefList) then
        self._curSelFilterRefId = filterTypeRefList[1].refId
    end

    self:RefreshSelSortListBtn()
    self._isOpenSort = false
    self:SetSelSortListState(false)
end

function UIVdoCenter:OnDrawSelTypeCell(list, item, itemdata, itempos)
    local SelImgTrans = self:FindWndTrans(item, "SelImg")
    local NameTrans = self:FindWndTrans(item, "Name")
    local SelNameTrans = self:FindWndTrans(item, "SelName")

    local refId = itemdata.refId
    local name = ccLngText(itemdata.name)

    local show = refId == self._curSelFilterRefId
    CS.ShowObject(SelImgTrans, show)
    CS.ShowObject(NameTrans, not show)
    CS.ShowObject(SelNameTrans, show)

    local nameText = show and SelNameTrans or NameTrans
    self:SetWndText(nameText, name)
    self:InitTextLineWithLanguage(nameText, -30)
    local addSize = -2
    if gLGameLanguage:IsVietnamVersion() then
        addSize = -1
    end
    self:InitTextSizeWithLanguage(nameText, addSize)

    self:SetWndClick(item, function()
        self:OnClickSel(refId)
    end)
end


--#####################################################################################################################
--## Top ##############################################################################################################
--#####################################################################################################################
function UIVdoCenter:RefreshTop()
    self:RefreshTopText()
    self:RefreshFiltrate()
end

function UIVdoCenter:SetEmptyTeam(item)
    self:SetSkillList(item, {})

    local heroListRoot = self:FindWndTrans(item, "Team/heroList")
    local gridMax = LCombatFormationConst.GRID_MAX
    for k = 1, gridMax do
        local rootPath = string.format("pos_%s/root/iconRoot", k)
        local root = self:FindWndTrans(heroListRoot, rootPath)
        local instanceId = root:GetInstanceID()
        self:DeleteCommonIcon(instanceId)
    end
end

function UIVdoCenter:SetStaticContent()
    self:SetWndText(self.mTitle, ccClientText(21500))
    self:SetWndText(self.mEmptyText, ccClientText(21501))
    self.mShowSortBtn.localRotation = self._sortBtnRot.close
    self._canvasRect = LGameUI.GetUICanvasRoot()
end

function UIVdoCenter:InitEmptyList()
    local data = {
        refId = 23001,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyBg,
        IconTran = self.mEmptyImage,
    }
    local emptyList = self:GetCommonEmptyList("emptyList")
    emptyList:RefreshUI(data)
end

function UIVdoCenter:RefreshSelSortList()
    local list = self._filterTypeRefList
    if #list < 1 then
        return
    end

    CS.ShowObject(self.mSortMaskBg, true)
    CS.ShowObject(self.mSelSortList, true)

    local uiSelSortList = self._uiSelSortList
    if uiSelSortList then
        uiSelSortList:RefreshList(list)
    else
        uiSelSortList = self:GetUIScroll("uiSelSortList")
        self._uiSelSortList = uiSelSortList
        uiSelSortList:Create(self.mSelSortList, list, function(...)
            self:OnDrawSelTypeCell(...)
        end)
    end
end

function UIVdoCenter:GetVideoDataList()
    return gModelVideoCenter:GetFilterVideoInfoList(self._curTab, self._curSelectTypeRefId, self._curSelFilterRefId)
end

function UIVdoCenter:InitMsg()
    self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP, function()
        self:WndClose()
    end)

    self:WndEventRecv(EventNames.ON_VIDEO_CENTER_INFO_CHANGE, function(opera, refId)
        if opera and self._curTab ~= opera then
            return
        end

        if refId and refId ~= 0 and self._curSelectTypeRefId ~= refId then
            return
        end

        self:RefreshContent()
        self:RefreshTopText()
    end)

    self:WndEventRecv(EventNames.ON_VIDEO_CENTER_PLAYER_INFO_CHANGE, function(...)
        self:RefreshTopText()
        if table.isempty(self._curVideoDataList) or self._isInitPlayerInfo then
            return
        end
        self._isHaveLikeNum = gModelVideoCenter:CheckHaveLikeNum()
        self._isHaveRewardLikeNum = gModelVideoCenter:CheckHaveRewardLikeNum()
        self:RefreshContent()
    end)

    self:WndEventRecv(EventNames.ON_WND_CLOSE, function(...)
        self:OnTargetWndClose(...)
    end)


end

function UIVdoCenter:OnClickLike(videoInfo, coverTrans, itemPos)
    --次数达上限
    if not gModelVideoCenter:CheckHaveLikeNum() then
        local timeStr = gModelVideoCenter:GetLikeTime()
        timeStr = string.replace(ccClientText(11879), timeStr)
        GF.ShowMessage(timeStr)
        return
    end

    local id = videoInfo:GetId()
    local isLike = gModelVideoCenter:CheckIsLikeById(id)
    if isLike then
        GF.ShowMessage(ccClientText(11878))
        return
    end

    local curHaveLikeNum = gModelVideoCenter:GetHasLikeNum() - 1
    local curHaveRewardLikeNum = gModelVideoCenter:GetHasRewardLikeNum() - 1
    local videoIndex = videoInfo:GetVideoIndex()
    gModelVideoCenter:OnVideoOperaReq(ModelVideoCenter.OperaLike, videoIndex)

    local reportId = videoInfo:GetReportId()
    gModelVideoCenter:OnVideoTAClientEventReq("录像馆_点赞", reportId, self._curTab, self._curSelectTypeRefId)

    videoInfo:AddLikeNumOnce()
    gModelVideoCenter:SetLikeVideoState(id)
    if not isLike then
        CS.ShowObject(coverTrans, true)

        if not gModelVideoCenter:CheckHaveRewardLikeNum() then
            local timeRewardStr = gModelVideoCenter:GetLikeTimeReward()
            timeRewardStr = string.replace(ccClientText(21538), timeRewardStr)
            GF.ShowMessage(timeRewardStr)
        end
    end

    self._isHaveLikeNum = curHaveLikeNum > 0
    self._isHaveRewardLikeNum = curHaveRewardLikeNum > 0
    if not self._isHaveRewardLikeNum and self._curTab == ModelVideoCenter.All then
        self:ShowAllLikeRed(false)
    end

    self:RefreshItemByPos(itemPos)
end

function UIVdoCenter:RefreshSelSortListBtn()
    local curSelFilterRefId = self._curSelFilterRefId

    local cfg
    for k, v in ipairs(self._filterTypeRefList) do
        if v.refId == curSelFilterRefId then
            cfg = v
            break
        end
    end

    if not cfg then
        printInfoNR("cfg is not find, curSelFilterRefId = " .. curSelFilterRefId)
        return
    end

    self:SetWndText(self.mShowSortName, ccLngText(cfg.name))
    self:InitTextLineWithLanguage(self.mShowSortName, -30)
    local addSize = -2
    if gLGameLanguage:IsVietnamVersion() then
        addSize = -1
    end
    self:InitTextSizeWithLanguage(self.mShowSortName, addSize)
end

function UIVdoCenter:CreateReportPart_New(item, itemdata, itempos)
    --common
    local ScoreBg = self:FindWndTrans(item, "ScoreBg")
    local ScoreTxt = self:FindWndTrans(ScoreBg, "ScoreTxt")
    local DetailsBtn = self:FindWndTrans(item, "DetailsBtn")
    local DetailsBtnName = self:FindWndTrans(DetailsBtn, "DetailsBtnName")
    local InfoNode = self:FindWndTrans(item, "InfoNode")

    --attack
    local AttackDiv = self:FindWndTrans(item, "AttackDiv")

    --defense
    local DefenseDiv = self:FindWndTrans(item, "DefenseDiv")

    --获取对应的div的数据
    local InstanceID = item:GetInstanceID()
    local otherReport = itemdata:GetOtherReport()  --跨服段位赛 才有这个
    local winner = itemdata:GetWinner()

    local attackPlayerData = itemdata:GetAttackPlayer()
    local defensePlayerData = itemdata:GetDefensePlayer()

    self:CreateReportPart_New_2(AttackDiv, attackPlayerData, winner == 1, ModelVideoCenter.AttackPlayer, otherReport)
    self:CreateReportPart_New_2(DefenseDiv, defensePlayerData, winner == 2, ModelVideoCenter.DefensePlayer, otherReport)

    --比分部分
    if ScoreTxt then
        if not otherReport then
            CS.ShowObject(ScoreBg, false)
        else
            CS.ShowObject(ScoreBg, true)

            local winnerNumA = otherReport.winnerNumA
            local winnerNumB = otherReport.winnerNumB

            local colorA, colorB
            if winnerNumA > winnerNumB then
                colorA = "lightGreen"
                colorB = "lightRed"
            elseif winnerNumA < winnerNumB then
                colorA = "lightRed"
                colorB = "lightGreen"
            end
            if colorA then
                winnerNumA = LUtil.FormatColorStr(winnerNumA, colorA)
            end
            if colorB then
                winnerNumB = LUtil.FormatColorStr(winnerNumB, colorB)
            end
            local str = string.replace(ccClientText(21832), winnerNumA, winnerNumB)
            self:SetWndText(ScoreTxt, str)
        end
    end

    --信息栏
    self:CreateInfoNode(InfoNode, itemdata, InstanceID, itempos)
    --按钮部分
    self:SetWndText(DetailsBtnName, ccClientText(21528))
    self:InitTextSizeWithLanguage(DetailsBtnName, -2)

    self:SetWndClick(DetailsBtn, function()
        local combatType = itemdata:GetCombatType()
        local moreTeam = false
        if combatType == LCombatTypeConst.COMBAT_CROSSGRADING_RANK then
            moreTeam = true

            --local info = {
            --    report = otherReport,
            --    crossGradingInfo = itemdata,
            --    viewType = self._btnType,
            --    returnCallFunc = function()
            --        gModelGeneral:RecoverGameState()
            --        --GF.OpenWndBottom("UIVdoCenter",{tabPage = tabPage,typeRefId = typeRefId})
            --    end,
            --}
            --gModelCrossGrading:OpenRecordDetailsByVideoCenter(info)
            --return
        end

        local tabPage = self._curTab
        local typeRefId = self._curSelectTypeRefId
        GF.OpenWnd("UIVdoPop", { videoInfo = itemdata, openEnum = ModelVideoCenter.OpenEnumVideoCenter, tabPage = tabPage, typeRefId = typeRefId, moreTeam = moreTeam })
    end)
end

function UIVdoCenter:OnClickShare(videoInfo, btnTrans, itemPos)
    if self._uiVideoDataList then
        --停止滑动
        self._uiVideoDataList:EnableScroll(false)
    end

    local videoIndex = videoInfo:GetVideoIndex()

    local reportId = videoInfo:GetReportId()

    local sendFunc = function(channel)
        videoInfo:AddShareNumOnce()
        gModelVideoCenter:OnVideoOperaReq(ModelVideoCenter.OperaShare, videoIndex)
        self:RefreshItemByPos(itemPos)

        gModelVideoCenter:OnVideoTAClientEventReq("录像馆_分享", reportId, nil, nil, channel)
    end

    local jsonStr = videoInfo:GetShareJson()

    local data = {
        root = btnTrans,
        shareType = ModelChat.CHATSHARE_VIDEO_CENTER,
        shareData = jsonStr
    }
    gModelGeneral:OpenShareTip(data, sendFunc)
end

function UIVdoCenter:OnDrawMultiReport(item, itemdata, itempos)
    local playNode = self:FindWndTrans(item, "playerNode")
    local player1 = self:FindWndTrans(item, "player1")
    local player2 = self:FindWndTrans(item, "player2")
    local scoreText = self:FindWndTrans(item, "score/text")
    local infoNode = self:FindWndTrans(item, "InfoNode")
    local groupList = self:FindWndTrans(item, "groupRoot/itemList")

    local head1 = self:FindWndTrans(playNode, "Head1")
    local head2 = self:FindWndTrans(playNode, "Head2")

    local winner = itemdata:GetWinner()
    self:SetPlayerContent(player1, head1, itemdata.attack, winner == 1)
    self:SetPlayerContent(player2, head2, itemdata.defense, winner == 2)

    local win, fail = itemdata:GetWinNumberShow()
    local str = string.format("<#30e055>%s</color>:<#ff2929>%s</color>", win, fail)
    self:SetWndText(scoreText, str)

    local instanceId = item:GetInstanceID()
    self:CreateInfoNode(infoNode, itemdata, instanceId, itempos)

    local dataList = {}
    local reportIdList = itemdata.reportList
    for k, v in ipairs(reportIdList) do
        local data = {
            index = k,
            reportId = v,
            serverId = itemdata.reportServerId
        }

        table.insert(dataList, data)
    end
    local uilist = self:FindUIScroll(instanceId)
    if not uilist then
        uilist = self:GetUIScroll(instanceId)
        local para = {
            root = groupList,
            dataList = dataList,
            setFunc = function(...)
                self:OnDrawGroup(...)
            end,
            metaData = { curIndex = 1, tran = item, dataList = dataList, instanceId = instanceId, videoInfo = itemdata }
        }
        uilist:InitListData(para)
    else
        local metaData = uilist:GetMetaData()
        metaData.tran = item
        metaData.dataList = dataList
        metaData.instanceId = instanceId
        metaData.videoInfo = itemdata
        uilist:RefreshList(dataList)
    end

    local metaData = uilist:GetMetaData()
    local index = metaData.curIndex
    local itemdata = dataList[index]
    self:SetReportPart(instanceId, itemdata)

end

function UIVdoCenter:SetPlayerContent(item, headRoot, itemdata, isWin)
    local Info = self:FindWndTrans(item, "Info")
    local InfoLine = self:FindWndTrans(Info, "line")
    local InfoWinIcon = self:FindWndTrans(Info, "winIcon")
    local InfoPower = self:FindWndTrans(Info, "power")
    local powerIcon = self:FindWndTrans(InfoPower, "icon")
    local powerText = self:FindWndTrans(InfoPower, "text")
    local InfoName = self:FindWndTrans(Info, "name")

    local str = string.format("%s[%s]", itemdata.name, itemdata.serverName)
    self:SetWndText(InfoName, str)
    self:SetWndText(powerText, LUtil.FormatColorStr(LUtil.NumberCoversion(itemdata.power)))

    local iconPath = "bestronger_txt_2"
    if isWin then
        iconPath = "bestronger_txt_1"
    end
    self:SetWndEasyImage(InfoWinIcon, iconPath)

    local headTran = self:FindWndTrans(headRoot, "HeadIcon")
    local playerInfo = {
        trans = headTran,
        icon = itemdata.head,
        headFrame = itemdata.headFrame,
        level = itemdata.grade,
        func = function()
            gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
        end,
    }
    self:CreateHeadIconImpl(playerInfo)
end

function UIVdoCenter:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mAllVideoBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mShowListBtn, function()
        self:OnClickSortBtn()
    end)

    self:SetWndClick(self.mSortMaskBg, function()
        self:SetSelSortListState(false)
    end)
end

--#####################################################################################################################
--## Tag ##############################################################################################################
--#####################################################################################################################
function UIVdoCenter:InitTabList()
    self:SetWndTabText(self.mAllVideoBtn, ccClientText(21505))
    self:SetWndTabText(self.mSelfRecordBtn, ccClientText(21506))
    self:SetWndTabText(self.mSelfCollectBtn, ccClientText(21507))

    for k, v in ipairs(self._tabBtnList) do
        self:SetWndClick(v, function()
            self:OnClickTag(k)
        end)
    end

    self:RefreshTagState()
    self:RefreshTypeList()
end

function UIVdoCenter:OnVideoItemReturn(list, item, itemdata, itempos)
    local instanceId = item:GetInstanceID()
    self:WndRemoveScrllByKey(instanceId)
end

function UIVdoCenter:OnDrawGroup(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    local AniRootOff = self:FindWndTrans(AniRoot, "off")
    local AniRootOn = self:FindWndTrans(AniRoot, "on")
    local AniRootUIText = self:FindWndTrans(AniRoot, "UIText")

    local metaData = list:GetMetaData()
    local isSelect = metaData.curIndex == itemdata.index
    CS.ShowObject(AniRootOff, not isSelect)
    CS.ShowObject(AniRootOn, isSelect)

    local color = "yellow_2"
    if isSelect then
        color = "black"
    end

    local teamStr = gModelBattle:GetTeamShowStr(itempos)
    local str = LUtil.FormatColorStr(teamStr, color)
    self:SetWndText(AniRootUIText, str)

    self:SetWndClick(AniRoot, function()
        self:OnClickGroup(list, itemdata)
    end)
end

function UIVdoCenter:RefreshTypeList()
    local curTab = self._curTab
    local typeList = self:GetTypeListByTabIndex(curTab)
    self._typeDataList = typeList
    local typeNum = #typeList
    local isShowTab = typeNum > 0
    CS.ShowObject(self.mTypeList, isShowTab)
    if not isShowTab then
        self:RefreshContent()
        return
    end

    if not (self._curSelectTypeRefId and gModelVideoCenter:CheckVideoTypeIsOpen(self._curSelectTypeRefId, false)) then
        local firstTypeData = typeList[1]
        self._curSelectTypeRefId = firstTypeData.refId
    end

    local uiTypeList = self:FindUIScroll("uiTypeList") -- self._uiTypeList
    if not uiTypeList then
        uiTypeList = self:GetUIScroll("uiTypeList") --UIItemList:New(self)
        uiTypeList:Create(self.mTypeList, typeList, function(...)
            self:SetTypeItem(...)
        end)
        --self._uiTypeList = uiTypeList
    end
    uiTypeList:EnableScroll(typeNum > 4, true)
    uiTypeList:RefreshList(typeList)
end

function UIVdoCenter:RefreshTagState()
    local oldTab = self._oldTab
    local oldBtn = oldTab and self._tabBtnList[oldTab] or nil
    if CS.IsValidObject(oldBtn) then
        self:SetWndTabStatus(oldBtn, LWnd.StateOff)
    end

    local curTab = self._curTab
    local curBtn = self._tabBtnList[curTab]
    if not CS.IsValidObject(curBtn) then
        printInfoNR("self._tabBtnList[curTab] is not find trans, curTab = " .. curTab)
        return
    end

    self._oldTab = curTab
    self:SetWndTabStatus(curBtn, LWnd.StateOn)
end

function UIVdoCenter:CreateInfoNode(infoNode, itemdata, InstanceID, itempos)
    local dateText = self:FindWndTrans(infoNode, "DateText")
    local titleText = self:FindWndTrans(infoNode, "TitleText")
    local infoNumList = self:FindWndTrans(infoNode, "InfoNumList")
    local btnList = self:FindWndTrans(infoNode, "BtnList")
    local playNumText = self:FindWndTrans(infoNumList, "PlayNumIcon/PlayNumText")
    local shareNumText = self:FindWndTrans(infoNumList, "ShareNumIcon/ShareNumText")
    local likeNumText = self:FindWndTrans(infoNumList, "LikeNumIcon/LikeNumText")
    local shareBtn = self:FindWndTrans(btnList, "ShareBtn")
    local shareBtnText = self:FindWndTrans(shareBtn, "Text")
    local dataBtn = self:FindWndTrans(btnList, "DataBtn")
    local dataBtnText = self:FindWndTrans(dataBtn, "Text")
    local likeBtn = self:FindWndTrans(btnList, "LikeBtn")
    local likeCover = self:FindWndTrans(likeBtn, "Cover")
    local likeBtnText = self:FindWndTrans(likeBtn, "Text")
    local likeRedPoint = self:FindWndTrans(likeBtn, "redPoint")
    local collectBtn = self:FindWndTrans(btnList, "CollectBtn")
    local collectCover = self:FindWndTrans(collectBtn, "Cover")
    local collectBtnText = self:FindWndTrans(collectBtn, "Text")

    local createTime = itemdata:GetCrateTime()
    local playBackNum = itemdata:GetPlayBackNum()
    local shareNum = itemdata:GetShareNum()
    local likeNum = itemdata:GetLikeNum()
    self._likeRedTransList[InstanceID] = likeRedPoint

    local id = itemdata:GetId()
    local isLike = gModelVideoCenter:CheckIsLikeById(id)
    local isCollect = gModelVideoCenter:CheckIsCollectById(id)
    local isShowLikeRed = self._isHaveRewardLikeNum and not isLike and self._curTab == ModelVideoCenter.All
    --CS.ShowObject(likeCover, isLike)
    --CS.ShowObject(collectCover, isCollect)
    local likeImg = isLike and "video_btn_icon_5" or "video_btn_icon_6"
    local collectImg = isCollect and "video_btn_icon_3" or "video_btn_icon_4"
    self:SetWndEasyImage(likeBtn, likeImg)
    self:SetWndEasyImage(collectBtn, collectImg)

    CS.ShowObject(likeRedPoint, isShowLikeRed)

    local dateStr = LUtil.FormatYearMonthDay(createTime)
    self:SetWndText(dateText, dateStr)
    if LGameLanguage:IsJapanRegion() then
        self:InitTextSizeWithLanguage(dateText, -2)
    end
    self:SetWndText(playNumText, playBackNum)
    self:SetWndText(shareNumText, shareNum)
    self:SetWndText(likeNumText, likeNum)

    --local combatType = itemdata:GetCombatType()
    --local roundIndex = itemdata:GetRound()
    local titleName = itemdata:GetTitleName()
    self:SetWndText(titleText, titleName)
    self:SetWndText(shareBtnText, ccClientText(21508))
    self:SetWndText(dataBtnText, ccClientText(21509))
    self:SetWndText(likeBtnText, ccClientText(21510))
    self:SetWndText(collectBtnText, ccClientText(21511))
    self:InitTextSizeWithLanguage(collectBtnText, -2)
    self:InitTextSizeWithLanguage(shareBtnText, -2)
    self:InitTextSizeWithLanguage(dataBtnText, -2)
    self:InitTextSizeWithLanguage(likeBtnText, -2)

    self:SetWndClick(shareBtn, function()
        self:OnClickShare(itemdata, shareBtn, itempos)
    end)

    self:SetWndClick(dataBtn, function()
        self:OnClickData(itemdata)
    end)

    self:SetWndClick(likeBtn, function()
        self:OnClickLike(itemdata, likeCover, itempos)
    end)

    self:SetWndClick(collectBtn, function()
        self:OnClickCollect(itemdata, collectBtn)
    end)
end

function UIVdoCenter:GetHistory()
    local list = LWnd.GetHistory(self)
    local wndArgList = list.wndArgList
    wndArgList.tabPage = self._tabPage
    wndArgList.typeRefId = self._typeRefId
    wndArgList.videoId = self._videoIdRecord
    return list
end

function UIVdoCenter:OpenDetail(reportTable, serverId, videoInfo)
    local videoIndex = videoInfo:GetVideoIndex()
    local playExtraFun = function()
        gModelVideoCenter:OnVideoTAClientEventReq("录像馆_播放", reportTable.id, self._tabPage, self._typeRefId)
        gModelVideoCenter:OnVideoOperaReq(ModelVideoCenter.OperaBackPlay, videoIndex)
    end

    local battleInfo = videoInfo:GetSimuBattleInfo()
    GF.OpenWnd("UIFightRecordMulti", { battleInfo = battleInfo, playExtraFun = playExtraFun })
end

function UIVdoCenter:OnClickCollect(videoInfo, coverTrans, itemPos)
    local id = videoInfo:GetId()
    local isCollect = gModelVideoCenter:CheckIsCollectById(id)
    local tabPage = self._curTab
    local typeRefId = self._curSelectTypeRefId
    local videoIndex = videoInfo:GetVideoIndex()
    local reportId = videoInfo:GetReportId()

    local okFunc = function()
        gModelVideoCenter:SetCollectVideoState(id)

        if isCollect then
            gModelVideoCenter:OnVideoTAClientEventReq("录像馆_取消收藏", reportId)
            gModelVideoCenter:OnVideoOperaReq(ModelVideoCenter.OperaCollectCancel, videoIndex)
            if self._curTab == ModelVideoCenter.SelfCollect
                    and gModelVideoCenter:RemoveCollectVideoInfoData(id) then
                self:RefreshContent()
            end
        else
            gModelVideoCenter:OnVideoTAClientEventReq("录像馆_收藏", reportId, tabPage, typeRefId)
            gModelVideoCenter:OnVideoOperaReq(ModelVideoCenter.OperaCollect, videoIndex)
        end
        isCollect = not isCollect
        local collectImg = isCollect and "video_btn_icon_3" or "video_btn_icon_4"
        self:SetWndEasyImage(coverTrans, collectImg)
    end

    if isCollect then
        gModelGeneral:OpenUIOrdinTips({ refId = 52701, func = function()
            okFunc()
        end })
        return
    end

    local curNum = gModelVideoCenter:GetCurCollectNum()
    local maxNum = gModelVideoCenter:GetVideoCollectMax()
    local isMax = curNum >= maxNum
    --达到上限
    if isMax then
        GF.ShowMessage(ccClientText(21512))
        return
    end

    okFunc()
end

function UIVdoCenter:OnClickGroup(list, itemdata)
    local metaData = list:GetMetaData()
    local curIndex = metaData.curIndex
    if curIndex == itemdata.index then
        return
    end

    metaData.curIndex = itemdata.index
    list:DrawAllItems(false)
    self:SetReportPart(metaData.instanceId, itemdata)
end

function UIVdoCenter:OnDrawReportPart(item, reportTable, serverId, videoInfo)
    local playNode = self:FindWndTrans(item, "playerNode")

    local leftTag = self:FindWndTrans(playNode, "team1/power/tag/Image")
    local rightTag = self:FindWndTrans(playNode, "team2/power/tag/Image")
    local team1 = self:FindWndTrans(playNode, "team1")
    local team2 = self:FindWndTrans(playNode, "team2")
    local btnVideo = self:FindWndTrans(playNode, "btnVideo")
    local btnDetail = self:FindWndTrans(playNode, "btnDetail")
    local power1 = self:FindWndTrans(team1, "power/text")
    local power2 = self:FindWndTrans(team2, "power/text")
    local emptyTips = self:FindWndTrans(item, "emptyTips")

    CS.ShowObject(playNode, true)
    CS.ShowObject(emptyTips, false)

    local reportData = LFightReportData:New()
    reportData:CreateNoRound(reportTable)

    local isEmpty = #reportData.formationA.grids == 0 and #reportData.formationB.grids == 0

    if isEmpty then
        self:SetEmptyContent(item)
        return
    end

    local winPath = "trial2_txt_2"
    local failPath = "trial2_txt_1"
    self:SetWndEasyImage(leftTag, reportData.winner == 1 and winPath or failPath)
    self:SetWndEasyImage(rightTag, reportData.winner == 1 and failPath or winPath)

    self:SetTeamContent(team1, reportData.formationA)
    self:SetTeamContent(team2, reportData.formationB)

    self:SetTextTile(btnDetail, ccClientText(21528))
    self:SetTextTile(btnVideo, ccClientText(17001))

    self:SetWndText(power1, LUtil.NumberCoversion(reportData.formationA.power))
    self:SetWndText(power2, LUtil.NumberCoversion(reportData.formationB.power))

    local hasEmpty = #reportData.formationA.grids == 0 or #reportData.formationB.grids == 0

    CS.ShowObject(btnVideo, not hasEmpty)
    CS.ShowObject(btnDetail, not hasEmpty)

    self:SetWndClick(btnVideo, function()
        self:OnClickVideo(reportTable, videoInfo)
    end)

    self:SetWndClick(btnDetail, function()
        self:OpenDetail(reportData, serverId, videoInfo)
    end)

end

------------------------------------------------------------------
return UIVdoCenter


