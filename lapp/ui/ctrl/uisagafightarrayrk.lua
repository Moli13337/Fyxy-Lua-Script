---
--- Created by LCM.
--- DateTime: 2024/3/5 13:00:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaFightArrayRk:LWnd
local UISagaFightArrayRk = LxWndClass("UISagaFightArrayRk", LWnd)

---- 每页的数量
UISagaFightArrayRk.INIT_PAGE_SIZE = 25

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaFightArrayRk:UISagaFightArrayRk()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaFightArrayRk:OnWndClose()
    GF.CloseWndByName("UIOrdinBulletSay")
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaFightArrayRk:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaFightArrayRk:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:InitEmptyList()
    self:InitBotBtnList()


end

function UISagaFightArrayRk:InitFunctionOpenIdList()
    local campRefIdOpenMap = {}
    local functionOpenList = {}
    local funcId, campRefId
    local isOpen
    local rankCamp = gModelRank:GetRankingConfigRefByKey("rankCamp")
    local rankCampMap = string.split(rankCamp, ";")
    for i, v in ipairs(rankCampMap) do
        v = string.split(v, "=")
        funcId = tonumber(v[2])
        campRefId = tonumber(v[1])
        isOpen = gModelFunctionOpen:CheckIsOpened(funcId)
        local data
        if isOpen then
            data = {
                funcId = funcId,
                name = gModelFunctionOpen:GetFunctionName(funcId),
                isOpen = isOpen,
                isLock = false,
                campRefId = campRefId,
            }
        else
            local isShow = gModelFunctionOpen:CheckIsShow(funcId)
            if isShow then
                data = {
                    funcId = funcId,
                    name = gModelFunctionOpen:GetFunctionName(funcId),
                    isOpen = isOpen,
                    isLock = true,
                    campRefId = campRefId,
                }
            end
        end
        if data then
            table.insert(functionOpenList, data)

            campRefIdOpenMap[campRefId] = data
        end
    end
    self._campRefIdOpenMap = campRefIdOpenMap
    self._functionOpenList = functionOpenList
end

function UISagaFightArrayRk:InitBotBtnList()
    local list = self:GetBotBtnList()

    if not self._campRefId then
        local first = list[1]
        if first then
            self._campRefId = first.campRefId
            self:ReqPage(self._page)
        end
    end

    local uiBotBtnList = self._uiBotBtnList
    if uiBotBtnList then
        uiBotBtnList:RefreshList(list)
    else
        uiBotBtnList = self:GetUIScroll("uiBotBtnList")
        self._uiBotBtnList = uiBotBtnList
        uiBotBtnList:Create(self.mBotBtnList, list, function(...)
            self:OnDrawBotBtnCell(...)
        end)
    end
    local enable = #list > 4
    uiBotBtnList:EnableScroll(enable, true)
end

function UISagaFightArrayRk:InitMsg()

    self:WndNetMsgRecv(LProtoIds.RankFormationHeroResp, function(pb)
        self:OnRankFormationHeroResp(pb)
    end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
    self:WndNetMsgRecv(LProtoIds.GetFormationResp, function(pb)
        self:UpdateMyFormation()
    end)
end

function UISagaFightArrayRk:ReqNextPage()
    local page = self._page + 1
    self:ReqPage(page)
end

function UISagaFightArrayRk:InitRankCampRefData()
    local typeCampList = {}
    local heroRefId = self._heroRefId
    if heroRefId then
        local ref = gModelRank:GetRankCampRefByRefId(heroRefId)
        if ref then
            local campRefIdOpenMap = self._campRefIdOpenMap or {}
            local campInfo
            local typeCamp = string.split(ref.typeCamp, ";")
            for i, campRefId in ipairs(typeCamp) do
                campRefId = tonumber(campRefId)
                campInfo = campRefIdOpenMap[campRefId]
                if campInfo then
                    table.insert(typeCampList, campInfo)
                end
            end
        end
    end
    self._typeCampList = typeCampList
end

function UISagaFightArrayRk:InitData()
    self._heroRefId = self:GetWndArg("heroRefId")

    self._heroName = gModelHero:GetHeroNameByRefId(self._heroRefId)

    self:InitText()

    self._campRefId = nil

    local heroBAPageSize = gModelRank:GetRankingConfigRefByKey("heroBAPageSize")
    if not heroBAPageSize then
        if LOG_INFO_ENABLED then
            printInfoNR("RankingConfigRef表 heroBAPageSize 字段表示每一页获取的数据量，目前暂无配置，默认是：" .. UISagaFightArrayRk.INIT_PAGE_SIZE)
        end
        heroBAPageSize = UISagaFightArrayRk.INIT_PAGE_SIZE
    end
    self._heroBAPageSize = heroBAPageSize

    self._rankIconPathList = {
        "public_num_1",
        "public_num_2",
        "public_num_3",
    }

    self._rankFormationHeroMap = {}
    self._recordRankFormationTypeMap = {}

    self._isOpenDanmu = gModelHeroBook:GetBarrageStatus()

    if self._isOpenDanmu then
        FireEvent(EventNames.CHANGE_COMMON_BARRAGE_INFO, {
            heroRefId = self._heroRefId,
            barrageType = ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT
        })
    else
        FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS, false)
    end

    self:InitFunctionOpenIdList()
    self:InitPageData()
    self:InitRankCampRefData()
end

function UISagaFightArrayRk:InitText()
    local heroName = self._heroName
    if not heroName then
        return
    end

    local isRankName = gModelRank:GetRankingConfigRefByKey("isRankName") or 1
    local str = ccClientText(35000)
    if isRankName == 1 then
        str = heroName .. str
    end
    self:SetWndText(self.mLblBiaoti, str)
end

function UISagaFightArrayRk:ReqPage(page)
    if not self._campRefId then
        return
    end
    if not self._heroRefId then
        return
    end
    gModelRank:OnRankFormationHeroReq(self._campRefId, self._heroRefId, page, self._heroBAPageSize)
end

function UISagaFightArrayRk:OnRankFormationHeroResp(pb)
    local heroRefId = pb.heroRefId
    if self._heroRefId ~= heroRefId then
        return
    end
    self._page = pb.page
    local type = pb.type
    self._myInfo = pb.myInfo
    local rankFormationHeroMap = self._rankFormationHeroMap
    if not rankFormationHeroMap then
        rankFormationHeroMap = {}
        self._rankFormationHeroMap = rankFormationHeroMap
    end
    local rankFormationHeroInfo = rankFormationHeroMap[type]
    if not rankFormationHeroInfo then
        rankFormationHeroInfo = {}
        rankFormationHeroMap[type] = rankFormationHeroInfo
    end

    local recordRankFormationTypeMap = self._recordRankFormationTypeMap
    if not recordRankFormationTypeMap then
        recordRankFormationTypeMap = {}
        self._recordRankFormationTypeMap = recordRankFormationTypeMap
    end
    local recordRankFormationTypeInfo = recordRankFormationTypeMap[type]
    if not recordRankFormationTypeInfo then
        recordRankFormationTypeInfo = {}
        recordRankFormationTypeMap[type] = recordRankFormationTypeInfo
    end

    local rankFormationInfo
    local playerId
    for i, v in ipairs(pb.info) do
        playerId = v.playerId
        if not recordRankFormationTypeInfo[playerId] then
            recordRankFormationTypeInfo[playerId] = true
            rankFormationInfo = gModelRank:GetStructRankFormationInfo(v)
            table.insert(rankFormationHeroInfo, rankFormationInfo)
        end
    end
    self:InitRankHeroList()
    self:SetMyHeroRankInfo()
end

function UISagaFightArrayRk:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UISagaFightArrayRk:OnClickHeroIconFunc(itemdata)
    local heroServer = itemdata.heroServer

    if not heroServer then
        local playerId = gModelPlayer:GetPlayerId()
        local serverId = gModelPlayer:GetServerId()
        --GF.ShowMessage(ccClientText(42017))
        gModelHero:ReqShowHeroTip(playerId, self._selfHeroData, nil, nil, nil, serverId)

        return
    end

    local heroData = {
        index = heroServer.index,
        id = heroServer.id,
        refId = heroServer.refId,
        star = heroServer.star,
        level = heroServer.level,
        grade = heroServer.grade,
        fightPower = heroServer.power,
        isResonance = heroServer.resonance,
        skin = heroServer.skin,
        treeInfo = heroServer.treeInfo,
    }
    gModelHero:ReqShowHeroTip(itemdata.playerId, heroData, nil, nil, nil, itemdata.serverId)
end

function UISagaFightArrayRk:SetMyFormationPower(formationReq)
    local TopDivTrans = self:FindWndTrans(self.mMyRank, "TopDiv")
    local PowerDivTrans = self:FindWndTrans(TopDivTrans, "PowerDiv");
    local PowerTextTrans = self:FindWndTrans(PowerDivTrans, "PowerText")

    local combatType = self._campRefId
    local heroRefId = self._heroRefId
    local myInfo = self._myInfo
    local showFormationPower = false
    local formationPower = 0
    if myInfo and myInfo.rank > 0 then
        showFormationPower = true
        formationPower = myInfo.power
    else
        local heroUp = false
        local totalPower = 0
        --local formationData = gModelFormation:GetFormation(combatType)
        local formationList = gModelFormation:GetFormationList(combatType)
        if formationReq then
            if not formationList then
                gModelFormation:OnGetFormationReq(combatType)
                return
            end
        end
        if formationList then
            local teamIndex = -1
            local teamPower = {}
            for k, v1 in pairs(formationList) do
                local formationData = v1
                local tempTotalPower = 0
                for i, v in pairs(formationData.grids) do

                    local heroId = v.id
                    local heroInfo = gModelHero:GetHeroById(heroId)
                    if heroInfo then
                        local refId = heroInfo:GetRefId()
                        local power = heroInfo:GetPower()
                        tempTotalPower = tempTotalPower + power

                        if refId == heroRefId then
                            heroUp = true
                            teamIndex = k
                        end
                    end
                end
                teamPower[k] = tempTotalPower
            end
            if teamIndex ~= -1 then
                totalPower = teamPower[teamIndex]
            end
        end
        if heroUp then
            showFormationPower = true
            formationPower = totalPower
        end
    end
    if formationPower ~= 0 then
        self:SetWndText(PowerTextTrans, LUtil.PowerNumberCoversion(formationPower))
    end
    CS.ShowObject(PowerDivTrans, showFormationPower)
end

function UISagaFightArrayRk:InitEmptyList()
    local heroRefId = self._heroRefId
    local nameStr = heroRefId and gModelHero:GetHeroNameByRefId(heroRefId) or ""
    local data = {
        refId = 30001,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
        para = { nameStr },
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UISagaFightArrayRk:OnDrawHeroCell(list, item, itemdata, itempos)
    local IconTrans = self:FindWndTrans(item, "CommonUI/Icon")
    local InstanceID = item:GetInstanceID()

    local heroServer = itemdata.heroServer

    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(IconTrans)
    local herodata = {
        id = heroServer.id,
        refId = heroServer.refId,
        star = heroServer.star,
        level = heroServer.level,
        skin = heroServer.skin,
        isResonance = heroServer.resonance,
        grade = heroServer.grade,
        treeInfo = heroServer.treeInfo,
        endTime = heroServer.endTime,
        isTry = heroServer.isTry,
    }
    baseClass:SetHeroDataSet(herodata)
    baseClass:DoApply()

    if heroServer.refId == self._heroRefId then
        baseClass:SetShowLightImg(true)
    else
        baseClass:SetShowLightImg(false)
    end

    self:SetWndClick(IconTrans, function()
        self:OnClickHeroIconFunc(itemdata)
    end)
end

function UISagaFightArrayRk:InitHeroList(uiListTrans, list)
    local key = uiListTrans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(uiListTrans, list, function(...)
            self:OnDrawHeroCell(...)
        end)
    end
end

function UISagaFightArrayRk:DisposeHeroList(itemdata)
    local heroInfo = itemdata.heroInfo
    local playerId = itemdata.playerId
    local serverId = itemdata.serverId
    local heroList = {}
    for i, v in ipairs(heroInfo) do
        table.insert(heroList, {
            heroServer = v,
            playerId = playerId,
            serverId = serverId,
        })
    end
    return heroList
end

function UISagaFightArrayRk:InitPageData()
    self._page = 1
end

function UISagaFightArrayRk:RefreshBotBtnList()
    local uiBotBtnList = self._uiBotBtnList
    if not uiBotBtnList then
        return
    end
    local uiList = uiBotBtnList:GetList()
    uiList:RefreshList()
end

function UISagaFightArrayRk:OnClickBotBtnFunc(itemdata)
    local campRefId = itemdata.campRefId
    if self._campRefId == campRefId then
        return
    end
    self._campRefId = campRefId
    self:RefreshBotBtnList()
    self:InitPageData()
    self:ReqPage(self._page)
end

function UISagaFightArrayRk:SetMyHeroRankInfo()
    local TopDivTrans = self:FindWndTrans(self.mMyRank, "TopDiv")
    local RankDivTrans = self:FindWndTrans(TopDivTrans, "RankDiv")
    local RankImgRootTrans = self:FindWndTrans(RankDivTrans, "RankImgRoot")
    local RankImgTrans = self:FindWndTrans(RankImgRootTrans, "RankImg")

    local RankTxtRootTrans = self:FindWndTrans(RankDivTrans, "RankTxtRoot")
    local RankTxtTrans = self:FindWndTrans(RankTxtRootTrans, "RankTxt")

    --local PowerDivTrans = self:FindWndTrans(TopDivTrans, "PowerDiv");
    --local PowerTextTrans = self:FindWndTrans(PowerDivTrans, "PowerText")

    local PlayerNameTrans = self:FindWndTrans(TopDivTrans, "PlayerName")
    local HeroPowerTrans = self:FindWndTrans(TopDivTrans, "PlayerServerName")

    local RankBgTrans = self:FindWndTrans(TopDivTrans, "RankBg")
    local RankBgTipTrans = self:FindWndTrans(RankBgTrans, "MyRankTip")

    local HeroIconTrans = self:FindWndTrans(TopDivTrans, "CommonUI/Icon")
    local SelfTag = self:FindWndTrans(TopDivTrans, "SelfTag")
    local SelfTagText = self:FindWndTrans(TopDivTrans, "SelfTag/SelfTagText")



    local DanMu = self:FindWndTrans(TopDivTrans, "DanMu")
    local DanmuOpen = self:FindWndTrans(DanMu, "Open")
    local DanmuOpenText = self:FindWndTrans(DanMu, "Open/OpenText")
    local DanmuClose = self:FindWndTrans(DanMu, "Close")
    local DanmuCloseText = self:FindWndTrans(DanMu, "Close/CloseText")

    local playerName = gModelPlayer:GetPlayerName()
    self:SetWndText(PlayerNameTrans, playerName)
    self:SetWndText(RankBgTipTrans, ccClientText(10339))
    self:SetWndText(SelfTagText, ccClientText(34304))  --[34304]	[我的少女]
    self:SetWndText(DanmuOpenText, ccClientText(34305))  --[34305]	[弹]
    self:SetWndText(DanmuCloseText, ccClientText(34305))  --[34305]	[弹]

    CS.ShowObject(DanmuOpen, self._isOpenDanmu)
    CS.ShowObject(DanmuClose, not self._isOpenDanmu)

    if self._isVie then
        local text = self:FindWndText(SelfTagText)
        local width =text.preferredWidth
        LxUiHelper.SetSizeWithCurAnchor(SelfTag,0,110+width/2)
        self:SetAnchorPos(SelfTagText,Vector2.New(-20,0))
    end

    local myInfo = self._myInfo
    local myRank = -1
    local heroServer
    --local showPower = false
    if myInfo and myInfo.rank > 0 then
        myRank = myInfo.rank
        for i, v in pairs(myInfo.heroInfo) do
            if v.refId == self._heroRefId then
                heroServer = v
                break
            end
        end
    end

    --if showPower then
    --    self:SetWndText(PowerTextTrans, LUtil.PowerNumberCoversion(myInfo.power))
    --
    --end
    --CS.ShowObject(PowerDivTrans, showPower)

    local rankIconPathList = self._rankIconPathList
    local rankIcon = rankIconPathList[myRank]
    local showRankImg = rankIcon ~= nil
    if showRankImg then
        CS.ShowObject(RankTxtTrans, false)

        self:SetWndEasyImage(RankImgTrans, rankIcon, function()
            CS.ShowObject(RankImgTrans, true)
        end, true)
    else
        CS.ShowObject(RankImgTrans, false)
        if myRank ~= -1 then
            self:SetWndText(RankTxtTrans, string.replace(ccClientText(35001), myRank))
        else
            self:SetWndText(RankTxtTrans, ccClientText(19526))
        end

        CS.ShowObject(RankTxtTrans, true)
    end
    CS.ShowObject(RankImgRootTrans, showRankImg)
    CS.ShowObject(RankTxtRootTrans, not showRankImg)

    local RankHeroRootTrans = self:FindWndTrans(TopDivTrans, "RankHeroRoot")
    local IconTrans = self:FindWndTrans(RankHeroRootTrans, "CommonUI/Icon")
    local HeadIconTrans = self:FindWndTrans(IconTrans, "HeadIcon")
    local InstanceID = self.mMyRank:GetInstanceID()

    --local headData = {
    --    trans = HeadIconTrans,
    --    icon = gModelPlayer:GetPlayerHead(),
    --    headFrame = gModelPlayer:GetPlayerHeadFrame(),
    --    name = playerName,
    --    level = gModelPlayer:GetPlayerLv(),
    --}
    --local baseClass = self:GetHeadIcon(InstanceID)
    --baseClass:SetHeadData(headData)

    local playerId = gModelPlayer:GetPlayerId()
    self:SetWndClick(HeadIconTrans, function()
        gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
    end)

    local power

    local herodata
    if heroServer then
        power = heroServer.power

        herodata = {
            id = heroServer.id,
            refId = heroServer.refId,
            star = heroServer.star,
            level = heroServer.level,
            skin = heroServer.skin,
            isResonance = heroServer.resonance,
            grade = heroServer.grade,
            treeInfo = heroServer.treeInfo,
            endTime = heroServer.endTime,
            isTry = heroServer.isTry,
        }
    else
        local heroId = gModelHero:GetMaxPowerHeroByRefId(self._heroRefId)
        local herotempdata = gModelHero:GetHeroById(heroId)

        herodata = {
            id = herotempdata._id,
            refId = herotempdata._refId,
            star = herotempdata._star,
            level = herotempdata._level,
            skin = herotempdata._skin,
            isResonance = false,
            grade = herotempdata._grade,
            treeInfo = herotempdata._treeInfo,
            endTime = herotempdata._endTime,
            isTry = false,
            fightPower= herotempdata:GetPower(),
        }

        power = herotempdata:GetPower()
    end

    if self._InitSelfHeroIcon then
    else
        self._InitSelfHeroIcon= true

        local baseClass = self:GetCommonIcon(InstanceID)
        baseClass:Create(HeroIconTrans)
        baseClass:SetHeroDataSet(herodata)
        baseClass:DoApply()

    end
    self._selfHeroData = herodata

    --if heroServer.refId == self._heroRefId then
    --    baseClass:SetShowLightImg(true)
    --else
    --    baseClass:SetShowLightImg(false)
    --end

    local itemdata = {}
    itemdata.heroServer = heroServer
    self:SetWndClick(HeroIconTrans, function()

        self:OnClickHeroIconFunc(itemdata)
    end)

    self:SetWndText(HeroPowerTrans, string.replace(ccClientText(34303), self._heroName, LUtil.PowerNumberCoversion(power)))
    --self:SetMyFormationPower(true)



    local cd = gModelChat:GetChatConfigRefByKey("textShowSpeed")
    local colorList = gModelHero:GetBarrageColorList()
    gModelHeroBook:OpenCommonBarrage({
        cd = cd,
        colorList = colorList,
        barrageType = ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT,
        heroRefId = self._heroRefId,
        autoRun = true,
    })


    if self._isOpenDanmu then
        FireEvent(EventNames.CHANGE_COMMON_BARRAGE_INFO, {
            heroRefId = self._heroRefId,
            barrageType = ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT
        })
    else
        FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS, false)
    end

    self:SetWndClick(DanMu, function()
        self._isOpenDanmu = not self._isOpenDanmu

        gModelHeroBook:SetBarrageStatus(self._isOpenDanmu)
        CS.ShowObject(DanmuOpen, self._isOpenDanmu)
        CS.ShowObject(DanmuClose, not self._isOpenDanmu)

        if self._isOpenDanmu then
            FireEvent(EventNames.CHANGE_COMMON_BARRAGE_INFO, {
                heroRefId = self._heroRefId,
                barrageType = ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT
            })
        else
            FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS, false)
        end
    end)



end

function UISagaFightArrayRk:UpdateMyFormation()
    self:SetMyFormationPower(false)
end

function UISagaFightArrayRk:OnDrawBotBtnCell(list, item, itemdata, itempos)
    local BtnTab1Trans = self:FindWndTrans(item, "BtnTab1")


    if self._isEnus then
        self:SetWndTabText(BtnTab1Trans, itemdata.name,-6)
    else
        self:SetWndTabText(BtnTab1Trans, itemdata.name)
    end

    local tabStatus
    local isOpen = itemdata.isOpen
    if isOpen then
        local isSel = itemdata.campRefId == self._campRefId
        tabStatus = isSel and LWnd.StateOn or LWnd.StateOff
    else
        tabStatus = LWnd.StateGray
    end
    self:SetWndTabStatus(BtnTab1Trans, tabStatus)

    self:SetWndClick(BtnTab1Trans, function()
        self:OnClickBotBtnFunc(itemdata)
    end)
end
------------------------- List -------------------------

function UISagaFightArrayRk:GetRankHeroList()
    local campRefId = self._campRefId
    if not campRefId then
        return {}
    end
    local rankFormationHeroMap = self._rankFormationHeroMap
    if not rankFormationHeroMap then
        return {}
    end
    local rankFormationHeroInfo = rankFormationHeroMap[campRefId]
    return rankFormationHeroInfo or {}
end

function UISagaFightArrayRk:IsGetNextPageData(itempos)
    if itempos < 1 then
        return false
    end
    local canGetNext = itempos % self._heroBAPageSize == 0
    if canGetNext then
        local tempPage = itempos / self._heroBAPageSize
        if tempPage < self._page then
            return true
        end
    end
    return false
end

function UISagaFightArrayRk:InitRankHeroList()
    local list = self:GetRankHeroList()
    local uiRankHeroList = self._uiRankHeroList
    if uiRankHeroList then
        uiRankHeroList:RefreshList(list)
    else
        uiRankHeroList = self:GetUIScroll("uiRankHeroList")
        self._uiRankHeroList = uiRankHeroList
        uiRankHeroList:Create(self.mRankHeroList, list, function(...)
            self:OnDrawRankHeroCell(...)
        end, UIItemList.SUPER)
    end
    uiRankHeroList:DrawAllItems()
    local isEmpty = #list < 1
    CS.ShowObject(self.mNoRecord2, isEmpty)
end

function UISagaFightArrayRk:GetBotBtnList()
    return self._typeCampList
end

function UISagaFightArrayRk:OnDrawRankHeroCell(list, item, itemdata, itempos)
    local TopDivTrans = self:FindWndTrans(item, "TopDiv")
    local RankDivTrans = self:FindWndTrans(TopDivTrans, "RankDiv")
    local RankImgRootTrans = self:FindWndTrans(RankDivTrans, "RankImgRoot")
    local RankImgTrans = self:FindWndTrans(RankImgRootTrans, "RankImg")

    local RankTxtRootTrans = self:FindWndTrans(RankDivTrans, "RankTxtRoot")
    local RankTxtTrans = self:FindWndTrans(RankTxtRootTrans, "RankTxt")

    --- 头像
    local RankHeroRootTrans = self:FindWndTrans(TopDivTrans, "RankHeroRoot")
    local IconTrans = self:FindWndTrans(RankHeroRootTrans, "CommonUI/Icon")
    local HeadIconTrans = self:FindWndTrans(IconTrans, "HeadIcon")

    local PlayerNameTrans = self:FindWndTrans(TopDivTrans, "PlayerName")

    local PlayerServerNameTrans = self:FindWndTrans(TopDivTrans, "PlayerServerName")

    local PowerDivTrans = self:FindWndTrans(TopDivTrans, "PowerDiv")
    local PowerTextTrans = self:FindWndTrans(PowerDivTrans, "PowerText")

    local BotDivTrans = self:FindWndTrans(item, "BotDiv")
    local HeroListTrans = self:FindWndTrans(BotDivTrans, "HeroList")

    local rank = itemdata.rank
    local rankIconPathList = self._rankIconPathList
    local rankIcon = rankIconPathList[rank]
    local showRankImg = rankIcon ~= nil
    if showRankImg then
        CS.ShowObject(RankTxtTrans, false)

        self:SetWndEasyImage(RankImgTrans, rankIcon, function()
            CS.ShowObject(RankImgTrans, true)
        end, true)
    else
        CS.ShowObject(RankImgTrans, false)

        self:SetWndText(RankTxtTrans, string.replace(ccClientText(35001), rank))
        CS.ShowObject(RankTxtTrans, true)
    end
    CS.ShowObject(RankImgRootTrans, showRankImg)
    CS.ShowObject(RankTxtRootTrans, not showRankImg)

    local name = itemdata.name

    local InstanceID = item:GetInstanceID()
    local headData = {
        trans = HeadIconTrans,
        icon = itemdata.head,
        headFrame = itemdata.headFrame,
        name = name,
        level = itemdata.grade,
    }
    local baseClass = self:GetHeadIcon(InstanceID)
    baseClass:SetHeadData(headData)

    self:SetWndClick(HeadIconTrans, function()
        gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
    end)

    local heroRefId = self._heroRefId
    self:SetWndText(PlayerNameTrans, name)
    local heroName = gModelHero:GetHeroNameByRefId(heroRefId)
    local curHeroInfo
    for i, v in pairs(itemdata.heroInfo) do
        if v.refId == heroRefId then
            curHeroInfo = v
            break
        end
    end
    self:SetWndText(PlayerServerNameTrans, string.replace(ccClientText(34303), heroName, LUtil.PowerNumberCoversion(curHeroInfo.power)))

    self:SetWndText(PowerTextTrans, LUtil.PowerNumberCoversion(itemdata.power))

    local heroList = self:DisposeHeroList(itemdata)
    self:InitHeroList(HeroListTrans, heroList)

    --[[    if self:IsGetNextPageData(itempos) then
            self:ReqNextPage()
        end]]
end

------------------------- List -------------------------

------------------------------------------------------------------
return UISagaFightArrayRk



