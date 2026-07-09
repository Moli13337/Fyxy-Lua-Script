---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRkPop:LWnd
local UIRkPop = LxWndClass("UIRkPop", LWnd)
local typeof_LayoutElement = typeof(UnityEngine.UI.LayoutElement)
UIRkPop.TYPE_RANK_NORNAL = 1
UIRkPop.TYPE_RANK_DREAMTRIP = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRkPop:UIRkPop()
    self:SetHideHurdle()
    ---@type table<number, CommonIcon>
    self._uiItemIconList = {}
    ---@type table<number, CommonIcon>
    self._uiHeroIconClsList = {}

    self._iconEasyListTbl = {}

    self._uiheadList = {}
    self._tabTrans = {}
    self._cellTransList = {}
    self._page = 0
    self._oldPage = 0
    self._pageSize = 25--数据大小25
    self._rankUpdate = "rankUpdate"
    self._rankTime = "rankTime"
    self._rankCellKey = "_rankCellKey"
    self._rankItemDataList = {}
    self._showServerNameRankList = {
        [ModelRank.RANK_TYPE_CROSSSERVER] = true,
        [ModelRank.RANK_MELEE] = true,
        [ModelRank.RANK_INTEGRAL] = true
    }
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRkPop:OnWndClose()
    if self.likeEffTimer then
        for _, v in pairs(self.likeEffTimer) do
            LxTimer.DelayTimeStop(v)
        end
        self.likeEffTimer = nil
    end
    self:ClearCommonIconList(self._uiItemIconList)
    self:ClearCommonIconList(self._uiHeroIconClsList)
    self:ClearCommonIconList(self._uiheadList)
    self:ClearCommonIconList(self._iconEasyListTbl)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRkPop:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRkPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()
    self._isEnus = gLGameLanguage:IsEnglishVersion()  or gLGameLanguage:IsJapanVersion() or gLGameLanguage:IsVieVersion()
    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitEvent()
    self:InitMessage()
    self:InitData()
    self:InitCommand()
    self:InitStaticData()
    local showRankType = self._showRankType
    if showRankType == UIRkPop.TYPE_RANK_NORNAL then
        self:RefreshNornalView()
    end
end
-----------------------------------------------点击---------------------------------------------------------------------
function UIRkPop:OnClickPlayer(playerInfo, isGuildRank)
    local rankRefId = self._refId
    local bossTowerBossRankList = self._bossTowerBossRankList
    local bossTowerRankList = self._bossTowerRankList
    local isBossTowerBossRank = bossTowerBossRankList[rankRefId] ~= nil
    local isBossTowerRank = bossTowerRankList[rankRefId] ~= nil
    local isBossTower = isBossTowerBossRank or isBossTowerRank or false
    if isBossTower and self._activityId then
        -- local combatType = isBossTowerBossRank and gModelBossTower:GetBossTowerConfigRefByKey("towerBossFightType") or gModelBossTower:GetBossTowerConfigRefByKey("towerFightType")
        -- gModelBossTower:OnBossTowerShowReq(self._activityId,playerInfo._playerId,combatType)
    else
        if isGuildRank then
            local isOpen = gModelFunctionOpen:CheckIsOpened(12100000, true)
            if isOpen then
                gModelGuild:OnGuildMemberListReq(playerInfo._guildId, playerInfo._serverId)

            end
        else
            gModelGeneral:PlayerShowReq(playerInfo._playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
        end
    end
end

function UIRkPop:InitRankItem(item, info, isThree)
    --isThree=1前面3，=2列表，=3自
    -- print("3891238920138091283901 === " ..self._refId)

    if self._refId == ModelRank.RANK_2400 or self._refId == ModelRank.RANK_2410 then
        if isThree == 1 then
            self:SetRankItemT2400(item, info)
        else
            self:SetRankItemL2400(item, info, isThree == 3)
        end

        if self._isEnus and info.rank<=3 then
            local rankText = self:FindWndTrans(item, "RankText")
            CS.ShowObject(rankText,false)
        end

        return
    elseif self._refId == ModelRank.RANK_2401 or self._refId == ModelRank.RANK_2411 then
        if isThree == 1 then
            self:SetRankItemT2401(item, info)
        else
            self:SetRankItemL2401(item, info, isThree == 3)
        end

        if self._isEnus and info.rank<=3 then
            local rankText = self:FindWndTrans(item, "RankText")
            CS.ShowObject(rankText,false)
        end
        return
    elseif self._refId == ModelRank.RANK_2600 then
        if isThree == 1 then
            self:SetRankItemT2600(item, info)
        else
            self:SetRankItemL2600(item, info, isThree == 3)
        end

        if self._isEnus and info.rank<=3 then
            local rankText = self:FindWndTrans(item, "RankText")
            CS.ShowObject(rankText,false)
        end
        return
    end

    local image = self:FindWndTrans(item, "Image")
    local bgImage1 = self:FindWndTrans(item, "BgImage1")
    local bgImage2 = self:FindWndTrans(item, "BgImage2")
    local flagBg = self:FindWndTrans(item, "FlagBg")
    local flagIcon = self:FindWndTrans(item, "FlagBg/FlagIcon")
    local guildLvText = self:FindWndTrans(item, "FlagBg/GuildLvBg/GuildLvText")
    local mask = self:FindWndTrans(item, "Mask")
    local iconBg = self:FindWndTrans(item, "IconBg")
    local rankIcon = self:FindWndTrans(item, "RankIcon")
    local group = self:FindWndTrans(item, "Group")
    local groupBg = self:FindWndTrans(group, "GroupBg")
    local bg = self:FindWndTrans(item, "Group/Bg")
    local bg2 = self:FindWndTrans(item, "Group/Bg2")
    local bg3 = self:FindWndTrans(item, "Group/Bg3")
    local bgImg1 = self:FindWndTrans(bg, "BgImg1")
    local bgImg2 = self:FindWndTrans(bg, "BgImg2")
    local serverText = self:FindWndTrans(item, "Group/ServerText")
    local nameText = self:FindWndTrans(item, "Group/NameText")
    local nameTextIcon = self:FindWndTrans(nameText, "Icon")
    local guildNameText = self:FindWndTrans(item, "Group/GuildNameText")
    local guildNameTextIcon = self:FindWndTrans(guildNameText, "Icon")
    local memberText = self:FindWndTrans(item, "Group/MemberText")
    local memberTextIcon = self:FindWndTrans(memberText, "Icon")
    local rankText = self:FindWndTrans(item, "RankText")
    local heroIcon = self:FindWndTrans(item, "Root/HeroIcon")
    local iconImg = self:FindWndTrans(bg, "Icon")
    local desIcon = self:FindWndTrans(bg, "DesIcon")
    local valueText1 = self:FindWndTrans(bg, "valueText1")
    local valueText2 = self:FindWndTrans(bg, "valueText2")
    local valueText3 = self:FindWndTrans(bg, "valueText3")
    local lookBtn = self:FindWndTrans(bg, "LookBtn")
    local likeBG = self:FindWndTrans(item, "Group/LinkBg")
    local like = self:FindWndTrans(likeBG, "like")
    local likeText = self:FindWndTrans(like, "layout/text")
    local likeIcon = self:FindWndTrans(like, "layout/icon")
    local rankImg = self:FindWndTrans(item, "RankImg")
    local homeBtn = self:FindWndTrans(bg3, "HomeBtn")
    local valueHot = self:FindWndTrans(bg3, "valueHot")
    local formationBtn = self:FindWndTrans(bg, "FormationBtn")
    CS.ShowObject(iconImg, false)

    local isShowLike = self:IsShowLike()  --是否显示点赞
    local _rankRefId = self._refId
    local nameEmptyStr = ccClientText(11711)
    if self._refId == ModelRank.RANK_MELEE or
            self._refId == ModelRank.RANK_GUILD_RANK or
            self._refId == ModelRank.RANK_CROSS_GUILD then
        nameEmptyStr = ccClientText(11736)
    end

    if self._refId == ModelRank.RANK_TYPE_603 or self._refId == ModelRank.RANK_TYPE_611 then
        local rankLength = self._rankBaseInfo and #self._rankBaseInfo or 100
        if info and info.index and info.index <= rankLength then
            nameEmptyStr = self._rankBaseInfo[info.index].notEnoughDes
        end

        if string.isempty(nameEmptyStr) then
            nameEmptyStr = ccClientText(11711)
        end

        if self._activityId and not self.activeCfg then
            local webData = gModelActivity:GetWebActivityDataById(self._activityId)
            self.activeCfg = webData and webData.config
        end
        if self.activeCfg and self.activeCfg.itemId then
            local iconPath = gModelItem:GetItemIconByRefId(self.activeCfg.itemId)
            self:SetWndEasyImage(iconImg, iconPath, function()
                if info.info and info.info._playerId ~= 0 then  CS.ShowObject(iconImg, info.rank>0) end
            end)
        end
    end

    self:SetWndText(nameText, nameEmptyStr)
    if self.jpj then
        self:InitTextSizeWithLanguage(nameText,-5)
        self:InitTextCharacterWithLanguage(nameText,-3)
    end
    self:SetWndText(guildNameText, "")
    self:SetWndText(memberText, "")
    CS.ShowObject(guildNameTextIcon, false)
    CS.ShowObject(nameText, true)
    CS.ShowObject(nameTextIcon, false)
    CS.ShowObject(bgImg1, false)
    CS.ShowObject(bgImg2, false)
    CS.ShowObject(desIcon, false)
    CS.ShowObject(serverText, false)
    CS.ShowObject(memberText, false)
    CS.ShowObject(memberTextIcon, false)
    CS.ShowObject(lookBtn, false)
    CS.ShowObject(bg, true)
    CS.ShowObject(heroIcon, false)
    CS.ShowObject(likeBG, false)
    CS.ShowObject(valueText1, true)
    CS.ShowObject(valueText2, false)
    CS.ShowObject(valueText3, false)
    CS.ShowObject(group, true)
    CS.ShowObject(rankIcon, true)
    CS.ShowObject(bg2, false)
    CS.ShowObject(bg3, false)
    CS.ShowObject(rankImg, false)
    CS.ShowObject(formationBtn, false)

    self:SetWndText(valueText1, "")
    if gLGameLanguage:IsJapanRegion() then
        self:InitTextSizeWithLanguage(valueText1, -4)
    end

    local _rankRef = gModelRank:GetRankingRefData(_rankRefId)
    local isGuildRank = _rankRef.showType == 1
    local isServerType = _rankRef.showType == 2
    if isServerType then
        self:InitServerRank(item, info, isThree)
        return
    end

    CS.ShowObject(bgImage1, not isGuildRank)
    CS.ShowObject(bgImage2, isGuildRank)
    CS.ShowObject(flagBg, false)
    CS.ShowObject(mask, not isGuildRank)
    CS.ShowObject(groupBg, not isGuildRank)

    if (isThree ~= 1) then
        local headIcon = self:FindWndTrans(item, "HeadIcon")
        CS.ShowObject(headIcon, not isGuildRank)
        if not isGuildRank then
            self:SetHeadIcon(item, info.info, not info.score)
        end
        local rankStr = ccClientText(11708)
        if (isThree == 2) then
            rankStr = string.replace(ccClientText(11725), info.index)
        end
        self:SetWndText(rankText, rankStr)
    end
    if isThree == 1 then
        self:SetWndText(rankText, info.index)
        CS.ShowObject(rankText, not self._isEnus)
    end


    self:SetWndClick(item, function(...)
    end)
    if image then
        self:SetWndClick(image, function(...)
        end)
    end

    if (not info.score) then
        return
    end
    local playerInfo = info.info
    if (not playerInfo or playerInfo._playerId == 0) then
        return
    end

    local playerId = playerInfo._playerId
    if playerId then
        self._rankItemDataList[playerInfo._playerId] = { item, info, isThree }
    end

    local nameStr = playerInfo._name
    local serverName
    local serverStr = ""

    if self._showServerNameRankList[_rankRef.type] or _rankRef.rankSerNameShow == 1 then
        serverName = gModelFriend:GetSevenName(playerInfo._serverId)
        serverStr = string.replace(ccClientText(11730), serverName)
        serverStr = LUtil.FormatColorStr(serverStr, "green")
        self:SetWndText(serverText, serverStr)
        CS.ShowObject(serverText, true)
    end
    local guildNameStr = playerInfo._guildName
    local meleeInfo = info.guildMeleeRankInfo
    local _descriptionDetail = self._descriptionDetail or ccLngText(_rankRef.descriptionDetail)

    if isGuildRank then
        CS.ShowObject(flagBg, isGuildRank)
        CS.ShowObject(iconBg, false)
        local bgRef = gModelGuild:GetGuildFlagRefByRefId(info.flagBgId)
        local iconRef = gModelGuild:GetGuildFlagRefByRefId(info.flagId)
        if bgRef then
            self:SetWndEasyImage(flagBg, bgRef.res)
        end
        if iconRef then
            self:SetWndEasyImage(flagIcon, iconRef.res)
        end
        self:SetWndText(guildLvText, info.guildLevel)
    end

    local showLink = false
    if self._rankType == ModelRank.RANK_TYPE_SERVERLUCK then
        local callInfo = info.callInfo
        if callInfo.extraReward and #callInfo.extraReward > 0 then
            CS.ShowObject(bgImg2, true)
            self:SetWndText(valueText1, info.score)
            CS.ShowObject(lookBtn, true)
            self:SetWndClick(lookBtn, function()
                self:OnClickLook(playerInfo._name, callInfo)
            end)
        end
    elseif _rankRef.showPower == 1 then
        CS.ShowObject(bgImg1, true)
        CS.ShowObject(iconImg, true)
        self:SetWndText(valueText1, LUtil.PowerNumberCoversion(info.score))
    elseif _rankRefId == ModelRank.RANK_1600 or _rankRefId == ModelRank.RANK_1601 then
        CS.ShowObject(bgImg2, true)
        CS.ShowObject(desIcon, true)
        CS.ShowObject(valueText1, false)
        CS.ShowObject(valueText2, true)
        self:SetWndText(valueText2, LUtil.NumberCoversion(info.score))
        guildNameStr = ""
    elseif self._bossTowerBossRankList[_rankRefId] then
        CS.ShowObject(bgImg1, true)
        CS.ShowObject(iconImg, true)
        self:SetWndText(valueText1, LUtil.PowerNumberCoversion(info.score))
    elseif self._bossTowerRankList[_rankRefId] then
        -- local insRefId = tonumber(info.score)
        -- local isChallenge = insRefId ~= 0
        -- CS.ShowObject(bgImg2,isChallenge)
        -- if isChallenge then
        -- 	local insType = gModelBossTower:GetBossTowerInsTypeByRefId(insRefId)
        -- 	local insName = gModelBossTower:GetBossTowerInsNameByRefId(insRefId)
        -- 	local valueText = valueText1
        -- 	self:SetWndText(valueText,string.format("%s-%s",insType,insName))
        -- end
    elseif _rankRefId == ModelRank.RANK_ONE_NIGHT then
        CS.ShowObject(bg, false)
        CS.ShowObject(bg2, false)
        CS.ShowObject(bg3, true)
        if isThree == 1 then
            CS.ShowObject(bg, true)
            CS.ShowObject(bgImg1, true)
            valueHot = valueText1
            homeBtn = self:FindWndTrans(bg, "HomeBtn")
        end
        self:SetWndText(valueHot, info.score)
        if playerInfo._playerId == gModelPlayer:GetPlayerId() and isThree == 3 then
            CS.ShowObject(homeBtn, false)
        else
            CS.ShowObject(homeBtn, true)
            self:SetWndClick(homeBtn, function()
                GF.OpenWndWait("UIOneNightSpaceOpenEffect", { type = 1, targetId = playerInfo._playerId })
                self:WndClose()
            end)
        end

    elseif _rankRefId == ModelRank.RANK_CROSSGRADING then
        -- 段位赛
        local rank = info.rank
        local score = info.score
        local showIcon = false
        local scoreStr = ""
        local iconImgStr
        local crossGradingRef = gModelCrossGrading:GetCurCrossGradingIntervalRef(score, rank)
        if crossGradingRef then
            scoreStr = score
            showIcon = true
            iconImgStr = crossGradingRef.icon
        end
        local iconImgTrans, valueText1Trans, bgImg2Trans
        if isThree == 1 then
            iconImgTrans = iconImg
            valueText1Trans = valueText1
            bgImg2Trans = bgImg2
        else
            iconImgTrans = self:FindWndTrans(bg2, "Icon")
            valueText1Trans = self:FindWndTrans(bg2, "PowerText")
            bgImg2Trans = bg2

            CS.ShowObject(valueText1Trans, true)

        end
        if iconImgStr then
            self:SetWndEasyImage(iconImgTrans, iconImgStr)
        end
        self:SetWndText(valueText1Trans, scoreStr)
        CS.ShowObject(iconImgTrans, showIcon)
        CS.ShowObject(bgImg2Trans, true)

        self:SetWndText(likeText, LUtil.NumberCoversion(playerInfo._like))
        self:SetWndClick(like, function()
            self:OnClickLike(playerId, like)
        end)
        local isLiked = gModelRank:IsLiked(self._likeType, playerId)
        -- local isSelf = playerId == gModelPlayer:GetPlayerId()
        self:SetWndImageGray(like, isLiked or self._noLikeNum)
        local instanceId = like:GetInstanceID()
        if isLiked or self._noLikeNum or self._noLikeRewardNum then
            self:DestroyWndEffectByKey(instanceId .. "show")
        else
            self:CreateWndEffect(likeIcon, "fx_ui_dianzanchangzhu", instanceId .. "show", 120)
        end
        if likeIcon then
            local res = isLiked and "herobook_icon_3" or "herobook_icon_1"
            self:SetWndEasyImage(likeIcon, res)
        else
            self:SetWndImageGray(like, isLiked or self._noLikeNum)
        end
        showLink = true
    elseif (_rankRefId >= ModelRank.RANK_FAIRYLAND_BOSS_BEGIN and _rankRefId <= ModelRank.RANK_FAIRYLAND_BOSS_END) then
        if not isGuildRank then
            guildNameStr = ""
        end
        CS.ShowObject(bgImg2, true)
        CS.ShowObject(desIcon, true)
        CS.ShowObject(valueText1, false)--isBossRankSelf)
        CS.ShowObject(valueText2, true)--not isBossRankSelf)
        self:SetWndText(valueText2, LUtil.NumberCoversion(math.max(info.score, 0)))
    elseif isShowLike then
        showLink = true
        --显示点赞
        if _rankRefId == ModelRank.RANK_HIGH_LADDER then
            --显示联盟
            if string.isempty(guildNameStr) then
                guildNameStr = ccClientText(11712)
            end
        else
            --显示积分
            guildNameStr = ccClientText(10312) .. info.score
        end

        local valueText = valueText1
        if isThree == 1 then
            CS.ShowObject(bgImg1, true)
            CS.ShowObject(iconImg, true)
        else
            valueText = self:FindWndTrans(bg2, "PowerText")
            CS.ShowObject(bg, false)
            CS.ShowObject(bg2, true)
        end
        local powerNum = playerInfo._power
        -- if _rankRefId == ModelRank.RANK_HIGH_LADDER or _rankRefId == ModelRank.RANK_HIGH_CHAMPION then
        --     powerNum = playerInfo._ladderPower
        -- end
        self:SetWndText(valueText, LUtil.PowerNumberCoversion(powerNum))
        self:SetWndText(likeText, LUtil.NumberCoversion(playerInfo._like))
        self:SetWndClick(like, function()
            self:OnClickLike(playerId, like)
        end)
        local isLiked = gModelRank:IsLiked(self._likeType, playerId)
        -- local isSelf = playerId == gModelPlayer:GetPlayerId()
        local instanceId = like:GetInstanceID()
        if isLiked or self._noLikeNum or self._noLikeRewardNum then
            self:DestroyWndEffectByKey(instanceId .. "show")
        else
            self:CreateWndEffect(likeIcon, "fx_ui_dianzanchangzhu", instanceId .. "show", 120)
        end
        if likeIcon then
            local showGary = isLiked
            local res = showGary and "herobook_icon_3" or "herobook_icon_1"
            self:SetWndEasyImage(likeIcon, res)
        else
            self:SetWndImageGray(like, isLiked or self._noLikeNum)
        end
    elseif _rankRefId == ModelRank.RANK_INVASION then
        CS.ShowObject(bgImg2, true)
        CS.ShowObject(desIcon, true)
        self:SetWndText(valueText2, LUtil.NumberCoversion(info.score))
        CS.ShowObject(valueText1, false)
        CS.ShowObject(valueText2, true)
        guildNameStr = ""
    elseif (_rankRefId == ModelRank.RANK_MELEE or _rankRefId == ModelRank.RANK_INTEGRAL) and meleeInfo then
        local power = ""
        if (self._refId == ModelRank.RANK_MELEE) then
            nameStr = guildNameStr
            guildNameStr = string.replace(_descriptionDetail, meleeInfo.num)
            power = meleeInfo.power
        else
            guildNameStr = string.replace(_descriptionDetail, info.score)
            power = meleeInfo.power --info.info._figure
        end

        CS.ShowObject(bgImg1, true)
        CS.ShowObject(iconImg, true)
        self:SetWndText(valueText1, LUtil.PowerNumberCoversion(power))
    elseif _rankRefId == ModelRank.RANK_1800 or _rankRefId == ModelRank.RANK_1802 then
        CS.ShowObject(bgImg2, true)
        self:SetWndText(valueText3, string.replace(_descriptionDetail, info.score))
        CS.ShowObject(valueText3, true)
    elseif _rankRefId == ModelRank.RANK_2200 then
        CS.ShowObject(bgImg2, true)
        CS.ShowObject(formationBtn, true)
        local towerdefenceMissionCfg = GameTable.TowerDefenceMissionRef[info.score]
        self:SetWndText(valueText1, string.replace(_descriptionDetail, towerdefenceMissionCfg and tostring(towerdefenceMissionCfg.sort) or "0"))
        local selfPlayerId = gModelPlayer:GetPlayerId()
        if selfPlayerId ~= playerInfo._playerId then
            self:SetWndClick(formationBtn, function()
                self:OnClickFormation(playerInfo._playerId)
            end)
        end
    elseif _rankRefId == ModelRank.RANK_511 or _rankRefId == ModelRank.RANK_512 then
        local petDreamlandRankItem = gModelPetDreanLand:GetPetDreamlandConfigRefByKey("petDreamlandRankItem")
        if petDreamlandRankItem and petDreamlandRankItem > 0 then
            local iconPath = gModelItem:GetItemIconByRefId(petDreamlandRankItem)
            if iconPath then
                self:SetWndEasyImage(iconImg, iconPath, function()
                    CS.ShowObject(iconImg, true)
                end)
                CS.ShowObject(bgImg2, true)
                local desStr = LUtil.NumberCoversion(info.score)
                self:SetWndText(valueText1, desStr)
            end
        end
    elseif (info.score > 0) then
        CS.ShowObject(bgImg2, true)
        local desStr = info.score
        if _rankRef.detailsRef ~= "" then
            local ref = GameTable[_rankRef.detailsRef]
            local itemRef = ref[desStr]
            local detailsFields = string.split(_rankRef.detailsFields, "=")
            desStr = itemRef[detailsFields[1]]
            if detailsFields[2] == "1" then
                desStr = ccLngText(desStr)
            end
        else
            desStr = LUtil.NumberCoversion(info.score)
        end

        local valueText = valueText1
        if gLGameLanguage:IsForeignRegion() and _rankRefId == ModelRank.RANK_TYPE_ADVENTURE then
            if isThree == 1 then
                valueText = self:FindWndTrans(item, "Group/EnglishText")
            else
                valueText = self:FindWndTrans(item, "EnglishText")
            end

            CS.ShowObject(bgImg2, false)
            CS.ShowObject(valueText, true)
        end
        local s = ""
        if string.isempty(_descriptionDetail) then
            s = desStr
        elseif _rankRefId == ModelRank.RANK_TYPE_611 then
            local lev = math.floor(info.score / 1000)
            local progress = info.score - lev * 1000
            lev = math.max(lev, 1)
            s = string.replace(_descriptionDetail, lev, progress)
        else
            s = string.replace(_descriptionDetail, desStr)
        end
        self:SetWndText(valueText, s)
    end
    CS.ShowObject(nameText, true)

    if _rankRefId == ModelRank.RANK_ENDLES_COMPLEX then
        local anPos = valueText1.anchoredPosition
        anPos.x = 0
        valueText1.anchoredPosition = anPos
    end

    if _rankRefId == ModelRank.RANK_ARENA_LEADER then
        if isThree == 1 then
            self:SetWndEasyImage(iconImg, "actionarena_icon_1", nil, true)
            self:SetAnchorPos(iconImg, Vector2.New(20, 0))
            self:SetAnchorPos(valueText1, Vector2.New(15, 0))
            iconImg.localScale = Vector2.New(0.4, 0.4)
            self:SetWndText(valueText1, "<color=#139057>" .. info.score .. "</color>")
            CS.ShowObject(iconImg, true)
            CS.ShowObject(bgImg1, false)
        else
            local bg2Back = CS.FindTrans(bg2, "Back")
            local bg2Icon = CS.FindTrans(bg2, "Icon")
            local bg2PowerText = CS.FindTrans(bg2, "PowerText")
            self:SetWndEasyImage(bg2Icon, "actionarena_icon_1", nil, true)
            self:SetAnchorPos(bg2PowerText, Vector2.New(65, 5))
            bg2Icon.localScale = Vector2.New(0.4, 0.4)
            self:SetWndText(bg2PowerText, "<color=#9F835C>" .. info.score .. "</color>")
            CS.ShowObject(guildNameText, false)
            CS.ShowObject(bg2Back, false)
        end
    end

    local nameTextIconPath, memberTextIconPath, guildNameTextPath
    if isGuildRank then
        local str = ""
        if (info.guildLevel > 0) then
            local s = ccClientText(11721)
            str = string.replace(s, info.guildCount, gModelGuild:GetGuildNumByLv(info.guildLevel))
            memberTextIconPath = "guild_icon_11"

            if isThree ~= 1 then
                str = self._spaceStr .. str
            end
        end

        CS.ShowObject(memberText, true)
        if str == "" and guildNameStr ~= "" then
            str = guildNameStr
        end
        if _rankRefId == ModelRank.RANK_MELEE then
            str = guildNameStr
            memberTextIconPath = nil
        elseif _rankRefId == ModelRank.RANK_CROSS_GUILD then
            str = string.replace(ccClientText(11730), serverName)
            memberTextIconPath = nil
        end
        self:SetWndText(memberText, str)

        if isThree ~= 1 then
            self:SetWndText(serverText, guildNameStr)
            if _rankRefId == ModelRank.RANK_MELEE then
                self:SetWndText(serverText, nameStr)
            end

            if serverName then
                if _rankRefId == ModelRank.RANK_CROSS_GUILD or _rankRefId == ModelRank.RANK_GUILD_RANK then
                    nameStr = self._spaceStr .. nameStr
                    guildNameTextPath = "guild_icon_25"
                else
                    CS.ShowObject(serverText, false)
                    nameStr = string.replace(ccClientText(11730), serverName)
                end
            else
                nameStr = self._spaceStr .. nameStr
                guildNameTextPath = "guild_icon_25"
            end
            CS.ShowObject(nameText, false)
            CS.ShowObject(serverText, true)
            guildNameStr = nameStr
        else
            if _rankRefId == ModelRank.RANK_CROSS_GUILD then
                self:SetWndText(serverText, guildNameStr)
                nameTextIconPath = "guild_icon_25"
                nameStr = self._spaceStr2 .. nameStr

                if self._isEnus then
                    nameTextIcon.localPosition = Vector3.New(28, 0, 0)
                end

            elseif _rankRefId == ModelRank.RANK_MELEE then
                nameTextIconPath = "guild_icon_25"
                self:SetWndText(serverText, nameStr)
                CS.ShowObject(nameText, false)
                CS.ShowObject(serverText, true)
                nameStr = string.replace(ccClientText(11730), serverName)
            else
                CS.ShowObject(guildNameText, false)
                self:SetWndText(serverText, guildNameStr)
                nameStr = self._spaceStr2 .. nameStr
                nameTextIconPath = "guild_icon_25"
            end
            CS.ShowObject(serverText, true)
        end
    end

    CS.ShowObject(likeBG, showLink)
    local needServerInNameEnd = showLink and isThree ~= 1 and not isGuildRank
    if needServerInNameEnd then
        nameStr = nameStr .. serverStr
        CS.ShowObject(serverText, false)
    end

    self:SetWndText(nameText, nameStr)
    self:InitTextSizeWithLanguage(nameText, -2)
    self:SetWndText(guildNameText, guildNameStr)
    if LxUiHelper.IsImgPathValid(nameTextIconPath) then
        self:SetWndEasyImage(nameTextIcon, nameTextIconPath, nil, true)
        CS.ShowObject(nameTextIcon, true)

    end

    if LxUiHelper.IsImgPathValid(memberTextIconPath) then
        self:SetWndEasyImage(memberTextIcon, memberTextIconPath, nil)
        CS.ShowObject(memberTextIcon, true)
    end

    if LxUiHelper.IsImgPathValid(guildNameTextPath) then
        self:SetWndEasyImage(guildNameTextIcon, guildNameTextPath, nil, true)
        CS.ShowObject(guildNameTextIcon, true)
    end

    if (isThree == 1) then
        local playIcon = self:FindWndTrans(item, "Mask/PlayIcon")
        if (not self._bMirrorRole) then
            self:SetHeroPaint(playIcon, info.info, 1)
            self:SetWndClick(item, function(...)
                self:OnClickPlayer(playerInfo, isGuildRank)
            end)
        else
            self:SetHeroPaint(playIcon, info.hero, 2)
            local playerBtn = self:FindWndTrans(item, "PlayerBtn")
            CS.ShowObject(playerBtn, false)
            self:SetWndClick(playerBtn, function(...)
                self:OnClickPlayer(playerInfo, isGuildRank)
            end)
            local heroInfo = info.hero
            heroInfo.level = heroInfo.lv
            heroInfo.skin = heroInfo.skin,
            self:SetWndClick(item, function(...)
                gModelHero:ReqShowHeroTip(playerId, heroInfo)
            end)
        end
    else
        local image = self:FindWndTrans(item, "Image")
        self:SetWndClick(image, function(...)
            self:OnClickPlayer(playerInfo, isGuildRank)
        end)
        CS.ShowObject(rankText, true)
        if (info.rank >= 1 and info.rank <= 3) then
            self:SetWndText(rankText, "<#ffffff>" .. info.rank .. "</color>")
            -- CS.ShowObject(rankText,false)
            local rankIcon = ""
            if (info.rank == 1) then
                rankIcon = "public_num_1"
            elseif (info.rank == 2) then
                rankIcon = "public_num_2"
            elseif (info.rank == 3) then
                rankIcon = "public_num_3"
            end
            CS.ShowObject(rankImg, true)
            self:SetWndEasyImage(rankImg, rankIcon)
        elseif info.rank > 3 then

            local coverStr = nil
            if _rankRefId == ModelRank.RANK_1901 then
                coverStr = LUtil.NumberCoversion(tonumber(info.rank))
            elseif self._bossTowerBossRankList[_rankRefId] then
                coverStr = LUtil.NumberCoversion(tonumber(info.rank))
            else
                coverStr = string.replace(ccClientText(11725), info.rank)
            end

            self:SetWndText(rankText, coverStr)
        end

        local heroInfo = info.hero
        if heroInfo and heroInfo.id == "" then
            return
        end
        if heroInfo then
            CS.ShowObject(heroIcon, true)
            self:SetHeroIcon(heroIcon, heroInfo, playerId)
        else
            CS.ShowObject(heroIcon, false)
        end
    end

    if self._isEnus and info.rank<=3 then
        local rankText = self:FindWndTrans(item, "RankText")
        CS.ShowObject(rankText,false)
    end


    if gLGameLanguage:IsJapanVersion() then
        if isThree then
            self:InitTextSizeWithLanguage(nameText, -4)
        end
    end

end

function UIRkPop:IsShowLike()
    --是否为排位赛进入的排行榜（需要显示点赞）
    return self._likeType and self._likeType ~= 0
end

function UIRkPop:ChangeTab(trans, bool)
    local state = bool and 0 or 1
    self:SetWndTabStatus(trans, state)
end

function UIRkPop:SetRankItemT2401(item, itemdata)
    local BgImage1 = self:FindWndTrans(item, "BgImage1")
    local BgImage2 = self:FindWndTrans(item, "BgImage2")
    local BgImage3 = self:FindWndTrans(item, "BgImage3")
    local FlagBg = self:FindWndTrans(item, "FlagBg")
    local FlagBgFlagIcon = self:FindWndTrans(FlagBg, "FlagIcon")
    local FlagBgGuildLvBg = self:FindWndTrans(FlagBg, "GuildLvBg")
    local GuildLvBgGuildLvText = self:FindWndTrans(FlagBgGuildLvBg, "GuildLvText")
    local Mask = self:FindWndTrans(item, "Mask")
    local Group = self:FindWndTrans(item, "Group")
    local GroupGroupBg = self:FindWndTrans(Group, "GroupBg")
    local GroupServerText = self:FindWndTrans(Group, "ServerText")
    local GroupNameText = self:FindWndTrans(Group, "NameText")
    local GroupGuildNameText = self:FindWndTrans(Group, "GuildNameText")
    local GroupMemberText = self:FindWndTrans(Group, "MemberText")
    local GroupBg = self:FindWndTrans(Group, "Bg")
    local BgBgImg1 = self:FindWndTrans(GroupBg, "BgImg1")
    local BgBgImg2 = self:FindWndTrans(GroupBg, "BgImg2")
    local BgIcon = self:FindWndTrans(GroupBg, "Icon")
    local BgValueText1 = self:FindWndTrans(GroupBg, "valueText1")
    local BgValueText2 = self:FindWndTrans(GroupBg, "valueText2")
    local BgDesIcon = self:FindWndTrans(GroupBg, "DesIcon")
    local BgLookBtn = self:FindWndTrans(GroupBg, "LookBtn")
    local BgHomeBtn = self:FindWndTrans(GroupBg, "HomeBtn")
    local BgFormationBtn = self:FindWndTrans(GroupBg, "FormationBtn")
    local GroupEnglishText = self:FindWndTrans(Group, "EnglishText")
    local GroupLinkBg = self:FindWndTrans(Group, "LinkBg")
    local RankIcon = self:FindWndTrans(item, "RankIcon")
    local PlayerBtn = self:FindWndTrans(item, "PlayerBtn")

    CS.ShowObject(Mask, false)
    CS.ShowObject(BgImage1, false)
    CS.ShowObject(BgImage3, false)
    CS.ShowObject(GroupGroupBg, false)
    CS.ShowObject(GroupGuildNameText, false)
    CS.ShowObject(BgBgImg2, false)
    CS.ShowObject(BgIcon, false)
    CS.ShowObject(BgValueText2, false)
    CS.ShowObject(BgDesIcon, false)
    CS.ShowObject(BgLookBtn, false)
    CS.ShowObject(BgHomeBtn, false)
    CS.ShowObject(BgFormationBtn, false)
    CS.ShowObject(GroupEnglishText, false)
    CS.ShowObject(GroupLinkBg, false)
    CS.ShowObject(PlayerBtn, false)

    CS.ShowObject(Group, true)
    CS.ShowObject(BgImage2, true)
    CS.ShowObject(RankIcon, true)
    CS.ShowObject(GroupServerText, true)
    CS.ShowObject(GroupNameText, true)
    CS.ShowObject(GroupMemberText, true)
    CS.ShowObject(GroupBg, true)
    CS.ShowObject(BgBgImg1, true)
    CS.ShowObject(BgValueText1, true)
    CS.ShowObject(FlagBg, true)
    CS.ShowObject(FlagBgFlagIcon, true)
    CS.ShowObject(FlagBgGuildLvBg, true)
    CS.ShowObject(GuildLvBgGuildLvText, true)

    if gLGameLanguage:IsJapanRegion() then
        self:InitTextSizeWithLanguage(BgValueText1, -4)
    end

    local isEmpty = not itemdata.info or itemdata.info._playerId == 0
    CS.ShowObject(FlagBg, not isEmpty)
    CS.ShowObject(GroupBg, not isEmpty)
    self:SetRankIcon(RankIcon, itemdata)
    self:SetWndClick(item, function()
        self:OpenGuildInfo(itemdata)
    end)

    if isEmpty then
        self:SetWndText(GroupNameText, ccClientText(11711))
        return
    end

    self:SetWndText(GroupServerText, itemdata.info._guildName)
    local str = string.replace(ccClientText(11732), itemdata.info._name)
    self:SetWndText(GroupNameText, str)
    str = ""
    local gLv = itemdata.guildLevel
    if gLv > 0 then
        str = string.replace(ccClientText(11721), itemdata.guildCount, gModelGuild:GetGuildNumByLv(gLv))
    end
    self:SetWndText(GroupMemberText, str)
    self:SetWndText(GuildLvBgGuildLvText, gLv)
    local bgRef = gModelGuild:GetGuildFlagRefByRefId(itemdata.flagBgId)
    local iconRef = gModelGuild:GetGuildFlagRefByRefId(itemdata.flagId)
    if bgRef then
        self:SetWndEasyImage(FlagBg, bgRef.res)
    end
    if iconRef then
        self:SetWndEasyImage(FlagBgFlagIcon, iconRef.res)
    end

    self:SetWndText(BgValueText1, itemdata.score)

end
--设置物品
function UIRkPop:SetItemIcon(itemIcon, itemData, InstanceID)
    local uiItemIconList = self._uiItemIconList
    local baseClass = uiItemIconList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New(self)
        uiItemIconList[InstanceID] = baseClass
        baseClass:Create(itemIcon)
    end
    baseClass:SetCommonReward(LItemTypeConst.TYPE_ITEM, itemData.refId, itemData.count or 0)
    baseClass:EnableShowNum(false)
    self:SetWndClick(itemIcon, function()
        gModelGeneral:ShowCommonItemTipWnd(itemData)
    end)
    baseClass:DoApply()
end
--设置立绘
function UIRkPop:SetHeroPaint(paintTans, info, index)
    --index = 1 文件形象， = 2 英雄形象
    if (info and index == 1) then
        local ref = gModelPlayer:GetRoleAdventureImage(info._figure)
        local key = info._playerId
        if (not ref) then
            return
        end
        self:SetSpine(paintTans, ref, key)
    elseif (info and index == 2) then
        local refId = info.refId
        local starLv = info.star
        local key = info.id
        local ref
        if (info.skin > 0) then
            ref = gModelHero:GetShowEffectById(info.skin)
            ref = gModelPlayer:GetRoleAdventureImage(ref.rankingId)
        else
            ref = gModelHero:GetHeroShowRefByRefId(refId, starLv)
            ref = gModelPlayer:GetRoleAdventureImage(ref.rankingId)
        end
        if (not ref) then
            return
        end
        self:SetSpine(paintTans, ref, key)
    end
end

function UIRkPop:SetRankText(tran, itemdata, isSelf, rankIcon)
    local isEmpty = not itemdata.info or itemdata.info._playerId == 0
    local rank = itemdata.rank or itemdata.index
    local str = nil
    if isEmpty then
        if isSelf then
            str = ccClientText(11708)
        else
            str = string.replace(ccClientText(11725), rank)
        end
    else
        if rank >= 1 and rank <= 3 then
            self:SetRankIcon(rankIcon, itemdata)
        else
            if rank < 0 then
                str = ccClientText(11708)
            else
                str = string.replace(ccClientText(11725), rank)
            end
        end
    end

    self:SetWndText(tran, str)
end

function UIRkPop:RefreshAwardPageSelf()
    if not (self._awardPageRewardList and self._selfRank and self._awardPageTypeList[self._oldType]) then
        return
    end

    self._selfRank = self._rankNum or 0
    local selfRank = self._selfRank
    local selfAward = nil
    for i, v in ipairs(self._awardPageRewardList) do
        local rank = v.rank
        local rankArr
        if rank ~= nil then
            if type(rank) == "string" then
                rankArr = string.split(rank, ",")
            elseif type(rank) == "table" then
                rankArr = rank
            end
        else
            rankArr = {}
            table.insert(rankArr, v.rankMax)
            table.insert(rankArr, v.rankMin)
        end
        if (tonumber(rankArr[1]) <= selfRank and (selfRank <= tonumber(rankArr[2]) or tonumber(rankArr[2]) <= 0)) then
            selfAward = v
            break
        end
    end
    --[[
	---- 如果没有奖励的话，直接显示未上榜没有奖励
	if not selfAward then
		local len = #self._awardPageRewardList
		local data = self._awardPageRewardList[len]
		if data then
]]--[[			selfAward = {
				reward = data.reward,
				sort = data.sort,
				rank = self._selfRank.."," .. self._selfRank
			}]]--[[
			local rankList = data.rank
			local rankArr
			if rankList ~= nil then
				if type(rankList) == "string" then
					rankArr = string.split(rankList,",")
				elseif type(rankList) == "table" then
					rankArr = rankList
				end
			else
				rankArr = {}
				table.insert(rankArr,data.rankMax)
				table.insert(rankArr,data.rankMin)
			end
			local rankMax = tonumber(rankArr[2])
			selfAward = data
		end
	end]]
    if (not selfAward) then
        self:SetWndText(self.mRankText, ccClientText(11716))
        self:InitTextSizeWithLanguage(self.mRankText, -4)
        self:SetWndText(self.mDesText, ccClientText(11722))
        self:InitTextSizeWithLanguage(self.mDesText, -4)
        CS.ShowObject(CS.FindTrans(self.mAwardRank, "RankIcon"), false)
        return
    end
    self:SetWndText(self.mRankText, "")
    self:SetWndText(self.mDesText, "")
    self:SetAwardItem(self.mAwardRank, selfAward, 2)
end

function UIRkPop:SetRankItemT2600(item, itemdata)
    local BgImage1 = self:FindWndTrans(item, "BgImage1")
    local BgImage2 = self:FindWndTrans(item, "BgImage2")
    local BgImage3 = self:FindWndTrans(item, "BgImage3")
    --local BgImage3Image = self:FindWndTrans(BgImage3,"Image")
    local FlagBg = self:FindWndTrans(item, "FlagBg")
    --local FlagBgFlagIcon = self:FindWndTrans(FlagBg,"FlagIcon")
    --local FlagBgGuildLvBg = self:FindWndTrans(FlagBg,"GuildLvBg")
    --local GuildLvBgGuildLvText = self:FindWndTrans(FlagBgGuildLvBg,"GuildLvText")
    local Mask = self:FindWndTrans(item, "Mask")
    local MaskPlayIcon = self:FindWndTrans(Mask, "PlayIcon")
    local Group = self:FindWndTrans(item, "Group")
    local GroupGroupBg = self:FindWndTrans(Group, "GroupBg")
    local GroupServerText = self:FindWndTrans(Group, "ServerText")
    local GroupNameText = self:FindWndTrans(Group, "NameText")
    local GroupGuildNameText = self:FindWndTrans(Group, "GuildNameText")
    local GroupMemberText = self:FindWndTrans(Group, "MemberText")
    local GroupBg = self:FindWndTrans(Group, "Bg")
    local BgBgImg1 = self:FindWndTrans(GroupBg, "BgImg1")
    local BgBgImg2 = self:FindWndTrans(GroupBg, "BgImg2")
    local BgIcon = self:FindWndTrans(GroupBg, "Icon")
    local BgValueText1 = self:FindWndTrans(GroupBg, "valueText1")
    local BgValueText2 = self:FindWndTrans(GroupBg, "valueText2")
    local BgDesIcon = self:FindWndTrans(GroupBg, "DesIcon")
    local BgLookBtn = self:FindWndTrans(GroupBg, "LookBtn")
    local BgHomeBtn = self:FindWndTrans(GroupBg, "HomeBtn")
    --local HomeBtnHomeIcon = self:FindWndTrans(BgHomeBtn,"HomeIcon")
    local BgFormationBtn = self:FindWndTrans(GroupBg, "FormationBtn")
    --local FormationBtnImage1 = self:FindWndTrans(BgFormationBtn,"Image1")
    --local FormationBtnImage = self:FindWndTrans(BgFormationBtn,"Image")
    local GroupEnglishText = self:FindWndTrans(Group, "EnglishText")
    local GroupLinkBg = self:FindWndTrans(Group, "LinkBg")
    --local LinkBgLike = self:FindWndTrans(GroupLinkBg,"like")
    --local likeLayout = self:FindWndTrans(LinkBgLike,"layout")
    --local layoutIcon = self:FindWndTrans(likeLayout,"icon")
    --local layoutText = self:FindWndTrans(likeLayout,"text")
    local RankIcon = self:FindWndTrans(item, "RankIcon")
    local PlayerBtn = self:FindWndTrans(item, "PlayerBtn")

    if gLGameLanguage:IsJapanRegion() then
        self:InitTextSizeWithLanguage(BgValueText1, -4)
    end

    CS.ShowObject(BgImage2, false)
    CS.ShowObject(BgImage3, false)
    CS.ShowObject(BgImage3, false)
    CS.ShowObject(FlagBg, false)
    CS.ShowObject(GroupGuildNameText, false)
    CS.ShowObject(GroupMemberText, false)
    CS.ShowObject(BgBgImg2, false)
    CS.ShowObject(BgIcon, false)
    CS.ShowObject(BgValueText2, false)
    CS.ShowObject(BgDesIcon, false)
    CS.ShowObject(BgLookBtn, false)
    CS.ShowObject(BgHomeBtn, false)
    CS.ShowObject(BgFormationBtn, false)
    CS.ShowObject(GroupEnglishText, false)
    CS.ShowObject(GroupLinkBg, false)
    CS.ShowObject(PlayerBtn, false)

    CS.ShowObject(BgImage1, true)
    CS.ShowObject(Mask, true)
    CS.ShowObject(Group, true)
    CS.ShowObject(GroupGroupBg, true)
    CS.ShowObject(GroupServerText, false)
    CS.ShowObject(GroupNameText, true)
    CS.ShowObject(GroupBg, true)
    CS.ShowObject(BgBgImg1, true)
    CS.ShowObject(BgValueText1, true)
    CS.ShowObject(RankIcon, true)

    self:SetRankIcon(RankIcon, itemdata)
    self:SetWndClick(item, function()
        self:OpenPlayerInfo(itemdata)
    end)
    local isEmpty = not itemdata.info or itemdata.info._playerId == 0

    CS.ShowObject(BgBgImg1, not isEmpty)
    if isEmpty then
        self:SetWndText(GroupNameText, ccClientText(11711))
        return
    end

    self:SetPlayerShow(MaskPlayIcon, itemdata)
    --self:ShowServerText(GroupServerText,itemdata)
    self:SetWndText(GroupNameText, itemdata.info._name)
    self:SetWndText(BgValueText1, itemdata.score)
end

function UIRkPop:SetTime()
    local times = self._times
    local timet = GetTimestamp()
    local timespan = times - timet
    if (timespan <= 0) then
        self:TimerStop(self._rankTime)
        self:SetWndText(self.mTimeText, ccClientText(20317))
        return
    end
    local timeStr = LUtil.FormatTimespanThreeCn(timespan)
    self:SetWndText(self.mTimeText, string.replace(ccClientText(11724), timeStr))
end

function UIRkPop:ShowServerText(tran, itemdata)
    local serverStr = string.replace(ccClientText(11730), itemdata.info._serverName)
    serverStr = LUtil.FormatColorStr(serverStr, "green")
    self:SetWndText(tran, serverStr)
end

function UIRkPop:OnClickLook(playerName, callInfo)
    callInfo.playerName = playerName
    GF.OpenWndTop("UIYellSagaSpreadWin", { StructCallShowInfo = callInfo })
end

function UIRkPop:GetTabBtnList()
    local list = {}
    if self._refIds and #self._refIds > 0 then
        for i, v in ipairs(self._refIds) do
            table.insert(list, {
                ref = gModelRank:GetRankingRefData(v)
            })
        end
    end
    return list
end

function UIRkPop:OnClickGetAward(refId)
    gModelRank:OnMileStoneReceiveReq({ refId })
end

function UIRkPop:SetRankItemL2600(item, itemdata, isSelf)
    --local Image = self:FindWndTrans(item,"Image")
    local RankText = self:FindWndTrans(item, "RankText")
    local FlagBg = self:FindWndTrans(item, "FlagBg")
    --local FlagBgFlagIcon = self:FindWndTrans(FlagBg,"FlagIcon")
    --local FlagBgGuildLvBg = self:FindWndTrans(FlagBg,"GuildLvBg")
    --local GuildLvBgGuildLvText = self:FindWndTrans(FlagBgGuildLvBg,"GuildLvText")
    local IconBg = self:FindWndTrans(item, "IconBg")
    --local IconBgIcon = self:FindWndTrans(IconBg,"Icon")
    local ServerIcon = self:FindWndTrans(item, "ServerIcon")
    --local ServerIconImage = self:FindWndTrans(ServerIcon,"Image")
    local Group = self:FindWndTrans(item, "Group")
    local GroupNameText = self:FindWndTrans(Group, "NameText")
    local GroupServerText = self:FindWndTrans(Group, "ServerText")
    local GroupGuildNameText = self:FindWndTrans(Group, "GuildNameText")
    local GroupMemberText = self:FindWndTrans(Group, "MemberText")
    --local GroupBg2 = self:FindWndTrans(Group,"Bg2")
    --local Bg2Back = self:FindWndTrans(GroupBg2,"Back")
    --local Bg2Icon = self:FindWndTrans(GroupBg2,"Icon")
    --local Bg2PowerText = self:FindWndTrans(GroupBg2,"PowerText")
    local GroupBg = self:FindWndTrans(Group, "Bg")
    local BgBgImg1 = self:FindWndTrans(GroupBg, "BgImg1")
    --local BgBgImg2 = self:FindWndTrans(GroupBg,"BgImg2")
    local BgIcon = self:FindWndTrans(GroupBg, "Icon")
    --local BgDesIcon = self:FindWndTrans(GroupBg,"DesIcon")
    local BgValueText1 = self:FindWndTrans(GroupBg, "valueText1")
    --local BgValueText2 = self:FindWndTrans(GroupBg,"valueText2")
    local BgLookBtn = self:FindWndTrans(GroupBg, "LookBtn")
    local BgFormationBtn = self:FindWndTrans(GroupBg, "FormationBtn")
    --local FormationBtnImage1 = self:FindWndTrans(BgFormationBtn,"Image1")
    --local FormationBtnImage = self:FindWndTrans(BgFormationBtn,"Image")
    --local GroupBg3 = self:FindWndTrans(Group,"Bg3")
    --local Bg3BgImg1 = self:FindWndTrans(GroupBg3,"BgImg1")
    --local Bg3ValueHot = self:FindWndTrans(GroupBg3,"valueHot")
    --local Bg3HomeBtn = self:FindWndTrans(GroupBg3,"HomeBtn")
    --local HomeBtnIcon = self:FindWndTrans(Bg3HomeBtn,"Icon")
    --local GroupLinkBg = self:FindWndTrans(Group,"LinkBg")
    --local LinkBgLike = self:FindWndTrans(GroupLinkBg,"like")
    --local likeLayout = self:FindWndTrans(LinkBgLike,"layout")
    --local layoutIcon = self:FindWndTrans(likeLayout,"icon")
    --local layoutText = self:FindWndTrans(likeLayout,"text")
    local BgPower = self:FindWndTrans(item, "BgPower")
    --local BgPowerBack = self:FindWndTrans(BgPower,"Back")
    --local BgPowerIcon = self:FindWndTrans(BgPower,"Icon")
    --local BgPowerPowerText = self:FindWndTrans(BgPower,"PowerText")
    --local Root = self:FindWndTrans(item,"Root")
    --local EnglishText = self:FindWndTrans(item,"EnglishText")

    local headTran = self:FindWndTrans(item, "HeadIcon")

    if gLGameLanguage:IsJapanRegion() then
        self:InitTextSizeWithLanguage(BgValueText1, -4)
    end

    CS.ShowObject(FlagBg, false)
    --CS.ShowObject(IconBg,false)
    CS.ShowObject(ServerIcon, false)
    CS.ShowObject(BgPower, false)
    CS.ShowObject(GroupGuildNameText, false)
    CS.ShowObject(GroupMemberText, false)

    CS.ShowObject(Group, true)
    CS.ShowObject(GroupBg, true)
    CS.ShowObject(BgIcon, false)
    CS.ShowObject(BgLookBtn, false)
    CS.ShowObject(BgFormationBtn, false)
    --CS.ShowObject(headTran,true)

    local isEmpty = not itemdata.info or itemdata.info._playerId == 0
    CS.ShowObject(BgBgImg1, not isEmpty)
    CS.ShowObject(GroupServerText, false)
    local rankIcon = self:FindWndTrans(item, "RankImg")
    self:SetRankText(RankText, itemdata, isSelf, rankIcon)

    CS.ShowObject(headTran, not isEmpty)
    CS.ShowObject(IconBg, isEmpty)
    self:SetWndText(BgValueText1, "")
    if isEmpty then
        self:SetWndText(GroupNameText, ccClientText(11711))
        return
    end

    self:SetWndText(GroupNameText, itemdata.info._name)

    self:SetHeadIconImpl(headTran, itemdata)
    --self:ShowServerText(GroupServerText,itemdata)
    self:SetWndText(BgValueText1, itemdata.score)
end

function UIRkPop:ClearRankScrollList()
    local uiList = self:FindUIScroll(self._rankCellKey)
    if uiList then
        uiList:Clear()
    end
    self._rankList = nil
end

function UIRkPop:InitMessage()
    self:WndEventRecv(EventNames.RANK_UPDATE_END, function(...)
        local data = { ... }
        local type = data[1]
        if type and type ~= self._type then
            return
        end
        self:RefreshRank()
        self:RefreshAwardPageSelf()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildBraveHurtRankResp, function(...)
        self:RefreshRank(...)
        self:RefreshAwardPageSelf()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildDonateRankResp, function(...)
        self:RefreshRank(...)
        self:RefreshAwardPageSelf()
    end)
    self:WndNetMsgRecv(LProtoIds.MilestoneResp, function(...)
        if self._showRankType ~= UIRkPop.TYPE_RANK_NORNAL then
            return
        end
        self:RefreshMilestone(...)
    end)
    self:WndNetMsgRecv(LProtoIds.MilStoneHistoryResp, function(...)
        if self._showRankType ~= UIRkPop.TYPE_RANK_NORNAL then
            return
        end
        GF.OpenWnd("UIRkAwardPop")
    end)
    self:WndNetMsgRecv(LProtoIds.MileStoneReceiveResp, function(...)
        if self._showRankType ~= UIRkPop.TYPE_RANK_NORNAL then
            return
        end
        self:RefreshMilestone(...)
    end)
    self:WndEventRecv(EventNames.ON_LIKE_HISTORY_RET, function()
        if self._showRankType ~= UIRkPop.TYPE_RANK_NORNAL then
            return
        end
        self:RefreshLikeState()
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerLikeResp, function(...)
        if self._showRankType ~= UIRkPop.TYPE_RANK_NORNAL then
            return
        end
        self:RefreshPlayerInfo(...)
    end)
    self:WndNetMsgRecv(LProtoIds.DreamTripRankResp, function(pb, ret)
        if self._showRankType == UIRkPop.TYPE_RANK_NORNAL then
            return
        end
        local list = self:GetDreamTripList(pb)
        self:RefreshDreamTripRank(list)
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
end

function UIRkPop:NewPage()
    local showRankType = self._showRankType
    if showRankType == UIRkPop.TYPE_RANK_NORNAL then
        if (self._refId == ModelRank.RANK_GUILDBBRAVE) then
            gModelGuild:OnGuildBraveHurtRankReq()
        elseif (self._refId == ModelRank.RANK_GUILD_DONATE) then
            gModelGuild:OnGuildDonateRankReq()
        else
            self._page = self._page + 1
            gModelRank:OnRankReq(self._type, self._refId, self._page, self._pageSize, self._activityId)--排行榜请求
        end
    elseif showRankType == UIRkPop.TYPE_RANK_DREAMTRIP then
        gModelDreamTrip:OnDreamTripRankReq()
    end
end

function UIRkPop:InitStaticData()
    self:SetWndText(self.mMeTitleText, ccClientText(11726))
    self:SetWndText(self.mMeTitleText2, ccClientText(11731))
    self:SetWndText(self.mOneKeyMilestoneText, ccClientText(11733))
end

function UIRkPop:ShowInvasionCd()
    local endTime = self._endTime
    local timeLeft = endTime - GetTimestamp()
    local str = nil
    if timeLeft <= 0 then
        self:TimerStop(self._invasionTimer)
        CS.ShowObject(self.mTimeBg, false)
        return false
    else
        str = ccClientText(21062) --"%s后发放奖励"
        str = string.replace(str, LUtil.FormatTimespanCn(timeLeft))
    end

    self:SetWndText(self.mTimeText, str)
    return true
end

function UIRkPop:OnTimer(key)
    if (self._rankTime == key) then
        self:SetTime()
    elseif (self._rankUpdate == key) then
        self._page = self._page - 1
        self:NewPage()
    elseif self._invasionTimer == key then
        self:ShowInvasionCd()
    end
end

function UIRkPop:OnCloseWnd()
    --关闭界面
    local _callFun = self._callFunc
    if _callFun ~= nil then
        _callFun()
    end
    self:WndCloseAndBack()
end

function UIRkPop:RefreshNornalView()
    self._redFun1 = function(pb)
        self:RefreshRed(1)
    end
    self._redFun2 = function(pb)
        self:RefreshRed(2)
    end
    self:RegisterRedPointFunc(ModelRedPoint.RANK_SCHEDULE, self._redFun1)
    self:RegisterRedPointFunc(ModelRedPoint.RANK_HERO, self._redFun2)
end

function UIRkPop:AwardRankListItem(list, item, itemdata, itempos)
    --奖励cell
    self:SetAwardItem(item, itemdata, 1)
end

function UIRkPop:OnClickTab(type, refId)
    if (not table.isempty(self._tabTrans)) then
        if (self._oldType) then
            if (self._oldType == type) then
                return
            end
            local trans = self._tabTrans[self._oldType]
            self:ChangeTab(trans, false)
        end
        local trans = self._tabTrans[type]
        self:ChangeTab(trans, true)
    end
    self._oldType = type
    CS.ShowObject(self.mDi, false)
    CS.ShowObject(self.mDi1, false)
    CS.ShowObject(self.mDi2, false)
    CS.ShowObject(self.mMilestoneRoot, false)
    CS.ShowObject(self.mRankRoot, false)
    CS.ShowObject(self.mAwardPage, false)
    if (type == ModelRank.TYPE_RANK_ROOT) then
        CS.ShowObject(self.mRankRoot, true)
        CS.ShowObject(self.mDi, true)
        if (not self._haveServerData) then
            self:NewPage()
        elseif not self._rankList then
            self:RefreshRank()
            self:RefreshAwardPageSelf()
        end
    elseif (type == ModelRank.TYPE_MILESTONE_ROOT) then
        CS.ShowObject(self.mMilestoneRoot, true)
        CS.ShowObject(self.mDi2, true)
        if (not self._awardList) then
            gModelRank:OnMilestoneReq(self._refId)
        end
    elseif (self._awardPageTypeList[type]) then
        if type == ModelRank.TYPE_REWARD_GUILD_WAR or type == ModelRank.TYPE_REWARD_GUILD_SCORE then
            --修改标题名字
            for k, v in ipairs(self._tabDataList) do
                if v.type == type then
                    self:RefreshTitleText(v.title)
                end
            end
            if not refId then
                refId = type == ModelRank.TYPE_REWARD_GUILD_WAR and ModelRank.RANK_MELEE or ModelRank.RANK_INTEGRAL
            end
            self._refId = refId
            self._page = 0
            self:NewPage()
        end
        CS.ShowObject(self.mAwardPage, true)
        CS.ShowObject(self.mDi1, true)
        self:RefreshAwardPage(type)
    elseif (type == ModelRank.TYPE_RANK_GUILD_WAR or type == ModelRank.TYPE_RANK_GUILD_SCORE) then
        CS.ShowObject(self.mRankRoot, true)
        CS.ShowObject(self.mDi, true)
        if not refId then
            refId = type == ModelRank.TYPE_RANK_GUILD_WAR and ModelRank.RANK_MELEE or ModelRank.RANK_INTEGRAL
        end
        self._refId = refId
        self._page = 0
        self._oldPage = 0
        self:SetCommonData()
        self:DestroyWndSpinetAll()
        self:ClearRankScrollList()
        self:NewPage()
    elseif (type == ModelRank.TYPE_REWARD_RANK_10 or type == ModelRank.TYPE_REWARD_RANK_11) then
        CS.ShowObject(self.mRankRoot, true)
        CS.ShowObject(self.mDi, true)
        if not refId then
            refId = type == ModelRank.TYPE_REWARD_RANK_10 and ModelRank.RANK_1600 or ModelRank.RANK_1601
        end
        self._refId = refId
        self._page = 0
        self._oldPage = 0
        self:SetCommonData()
        self:DestroyWndSpinetAll()
        self:ClearRankScrollList()
        self:NewPage()
    elseif type == ModelRank.TYPE_BOSSTOWER_RANK_SERVER or type == ModelRank.TYPE_BOSSTOWER_RANK_WORLD then
        CS.ShowObject(self.mRankRoot, true)
        CS.ShowObject(self.mDi, true)
        if not refId then
            refId = type == ModelRank.TYPE_BOSSTOWER_RANK_SERVER and ModelRank.RANK_1702 or ModelRank.RANK_1709
        end
        self._refId = refId
        self._page = 0
        self._oldPage = 0
        self:SetCommonData()
        self:DestroyWndSpinetAll()
        self:ClearRankScrollList()
        self:NewPage()
    elseif type == ModelRank.TYPE_DARK_WAR_PERSON or type == ModelRank.TYPE_DARK_WAR_GUILD then
        CS.ShowObject(self.mRankRoot, true)
        CS.ShowObject(self.mDi, true)
        if not refId then
            refId = type == ModelRank.TYPE_DARK_WAR_PERSON and ModelRank.RANK_2410 or ModelRank.RANK_2411
        end
        self._refId = refId
        self._page = 0
        self._oldPage = 0
        self:SetCommonData()
        self:DestroyWndSpinetAll()
        self:ClearRankScrollList()
        self:NewPage()
    end

    self:RefreshTimeBg(type)
end

function UIRkPop:SetAwardItem(trans, data, index)
    --设置排行cell	index:1=其他，2=自己
    local rankIcon = self:FindWndTrans(trans, "RankIcon")
    local rankText = self:FindWndTrans(trans, "RankText")
    local awardScroll = self:FindWndTrans(trans, "AwardScroll")
    local rankList = data.rank
    local rankArr
    if rankList ~= nil then
        if type(rankList) == "string" then
            rankArr = string.split(rankList, ",")
        elseif type(rankList) == "table" then
            rankArr = rankList
        end
    else
        rankArr = {}
        table.insert(rankArr, data.rankMax)
        table.insert(rankArr, data.rankMin)
    end
    local rank = tonumber(rankArr[1])
    local rankMax = tonumber(rankArr[2])
    local rankStr = ""
    if (rankArr[1] == rankArr[2]) then
        rankStr = rankArr[1]
    else
        if tonumber(rankArr[2]) > 0 then
            rankStr = string.replace(ccClientText(11714), rankArr[1], rankArr[2])
        else
            --rankStr = string.replace(ccClientText(11714),rankArr[1],9999)
            rankStr = rankArr[1] .. "+"
        end
    end
    if rank == rankMax and (rank >= 1 and rank <= 3) then
        CS.ShowObject(rankIcon, true)
        CS.ShowObject(rankText, false)
        -- self:SetWndText(rankText, "<#ffffff>" .. rank .. "</color>")
        local iconStr = "public_num_3"
        if (rank == 1) then
            iconStr = "public_num_1"
        elseif (rank == 2) then
            iconStr = "public_num_2"
        end
        self:SetWndEasyImage(rankIcon, iconStr)
    else
        CS.ShowObject(rankIcon, false)
        CS.ShowObject(rankText, true)
        self:SetWndText(rankText, rankStr)
        self:InitTextSizeWithLanguage(rankText, -2)
    end
    local reward1List
    local reward = data.reward
    if type(reward) == "string" then
        reward1List = LxDataHelper.ParseItem(data.reward)
    elseif type(reward) == "table" then
        reward1List = data.reward
        if data.judgeFunc then
            if not data.judgeFunc() then
                reward1List = data.normalReward
            end
        end
    end

    local InstanceID = trans:GetInstanceID()
    local uiList = self._iconEasyListTbl[InstanceID]
    if not uiList then
        uiList = UIIconEasyList:New()
        self._iconEasyListTbl[InstanceID] = uiList
        uiList:Create(self, awardScroll)
        uiList:SetIconParentPath("Root/CommonUI/Icon")
    end
    uiList:RefreshList(reward1List)
end

function UIRkPop:InitRewardList(ref)
    if not ref then
        return
    end

    if not self._rewardList and ref.rankReward == 1 then
        local rateList = {}
        local refId = ref.refId
        --- 萌宠幻境的需要特殊处理，rankRewardType：0=大戰區，1=小戰區
        local isPetDreamLandRank = refId == ModelRank.RANK_511 or refId == ModelRank.RANK_512

        local bigFightId
        if isPetDreamLandRank then
            bigFightId = gModelPetDreanLand:GetDreamLandInfoBigFightId()
            if bigFightId and bigFightId > 0 then
                --- 2024/7/2：直接读表，不需要按照概率来
                --[[				local value = gModelPetDreanLand:GetPetDreamlandRewardValue(bigFightId)
				if value and #value > 0 then
					rateList = value
				end]]
            end
        end

        self._rewardList = {}
        local rankAwardRef = GameTable[ref.rankRewardForm]
        local rankRewardType = ref.rankRewardType

        local useReward1 = false
        local isPetDLMini = refId == ModelRank.RANK_512
        if isPetDLMini then
            --- 小战区人数＜据点占领上限之和*分配系数*校准参数，则这个小战区的人少，奖励发放读取[reward1]字段
            useReward1 = gModelPetDreanLand:IsMiniFight()
        end

        for i, v in pairs(rankAwardRef) do
            local isIns = rankRewardType == 0 or rankRewardType == v.type
            if isPetDreamLandRank then
                if rankRewardType == v.type then
                    isIns = v.subtype == bigFightId
                else
                    isIns = false
                end
            end
            if isIns then
                local rewardData = {
                    refId = v.refId,
                    type = v.type,
                }

                if v.rankMax then
                    rewardData.rankMax = v.rankMax
                    rewardData.rankMin = v.rankMin
                elseif v.rank then
                    local rank = string.split(v.rank, ',')
                    rewardData.rankMax = tonumber(rank[1])
                    rewardData.rankMin = tonumber(rank[2])
                end

                local titleReward = v.titleReward
                local tRewardList = LxDataHelper.ParseItem(titleReward) or {}
                local reward
                if useReward1 and not string.isempty(v.reward1) then
                    reward = LxDataHelper.ParseItem(v.reward1)
                else
                    reward = LxDataHelper.ParseItem(v.reward)
                end
                for p, q in ipairs(reward) do
                    local rate = rateList[p] or 1
                    table.insert(tRewardList, {
                        itemType = q.itemType,
                        itemId = q.itemId,
                        itemNum = math.floor(q.itemNum * rate),
                        isShowEff = q.isShowEff,
                    })
                end

                rewardData.reward = tRewardList
                table.insert(self._rewardList, rewardData)
            end
        end
        table.sort(self._rewardList, function(a, b)
            if a.sort and b.sort then
                return a.sort < b.sort
            else
                return a.refId < b.refId
            end
        end)
    end
end
-------------------------------------------------设置-------------------------------------------------------------------
--设置玩家头像
function UIRkPop:SetHeadIcon(item, info, bool)
    local iconBg = self:FindWndTrans(item, "IconBg")
    local headIcon = self:FindWndTrans(item, "HeadIcon")
    CS.ShowObject(iconBg, true)
    CS.ShowObject(headIcon, false)
    if (not info or bool or (info._playerId and info._playerId == 0)) then
        return
    end
    CS.ShowObject(iconBg, false)
    CS.ShowObject(headIcon, true)
    local InstanceID = item:GetInstanceID()

    local playerInfo = {
        trans = headIcon,
        playerId = info._playerId,
        icon = info._head,
        headFrame = info._headFrame,
        level = info._grade,
    }
    local uiheadlist = self._uiheadList
    local baseClass = uiheadlist[InstanceID]
    if not baseClass then
        baseClass = HeadIcon:New(self)
        uiheadlist[InstanceID] = baseClass
    end
    baseClass:SetHeadData(playerInfo)
    self:SetWndClick(headIcon, function(...)
        self:OnClickPlayer(info)
    end)
end

function UIRkPop:InitCommand()
    self:SetCommonData()
    local ref = self._refData

    self._noLikeNum = false
    self._noLikeRewardNum = false
    self._haveServerData = false

    self:InitRewardList(ref)

    local countDown = gModelRank:GetRankingConfigRefByKey("rankreFreshTime")
    self:TimerStart(self._rankUpdate, countDown, false, -1)

    self:RefreshTimeBg()
    self:InitTabList(ref)
end

function UIRkPop:GetDreamTripList(pb)
    local list = {}
    local infos = pb.infos
    local star = pb.star
    local playerInfo
    for i, v in ipairs(infos) do
        playerInfo = gModelGeneral:SetPlayerInfo(v)
        table.insert(list, {
            info = playerInfo,
            score = star[i] or 0,
            rank = i,
            index = i,
        })
    end
    return list
end

function UIRkPop:ShowInvasionRankTime()
    self._endTime = self:GetWndArg("endTime") or 0
    self._invasionTimer = "_invasionTimer"
    self:TimerStop(self._invasionTimer)

    if self:ShowInvasionCd() then
        self:TimerStart(self._invasionTimer, 1, false, -1)
        CS.ShowObject(self.mTimeBg, true)
    end
end
--#####################################################################################################################
--### RankRoot ########################################################################################################
--#####################################################################################################################
----------------------------------------------排行榜--------------------------------------------------------------------
function UIRkPop:RefreshDreamTripRank(list)
    if not (self._rankRootTypeList[self._oldType]) then
        return
    end
    list = list or {}
    table.sort(list, function(a, b)
        return a.score > b.score
    end)
    local threeList = {}
    local cellList = {}

    local selfInfo
    local selfPlayerId = gModelPlayer:GetPlayerId()
    for i, v in ipairs(list) do
        v.rank = i
        v.index = i
        local playerId = v.info._playerId
        if playerId == selfPlayerId then
            selfInfo = v
        end
        if (i > 3) then
            table.insert(cellList, v)
        else
            table.insert(threeList, v)
        end
    end

    local len = #threeList
    if len < 3 then
        for i = 1, 3 - len do
            table.insert(threeList, { index = i + len })
        end
    end
    self:RefreshThreeRank(threeList)--刷新前3

    len = #cellList
    if len < 7 then
        for i = 1, 7 - len do
            table.insert(cellList, { index = 4 + #cellList })
        end
    end

    local rankList = self._rankList
    if rankList then
        rankList:RefreshData(cellList)
        local uiList = rankList:GetList()
        uiList:EnableLoadAnimation(false)
        uiList:RefreshSilent()
    else
        rankList = self:GetUIScroll(self._rankCellKey)
        self._rankList = rankList
        rankList:Create(self.mCellScroll, cellList, function(...)
            self:ListItem(...)
        end, UIItemList.WRAP, false)
        local uiList = rankList:GetList()
        uiList:EnableLoadAnimation(true, 0.03, 1, 2)
        uiList:SetLoadAnimationScale(nil, 0.03)
        uiList:RefreshSimpleList(UIListWrap.RefreshMode.Top)
    end
    self._rankNum = selfInfo and selfInfo.rank or 0
    if selfInfo then
        self:InitRankItem(self.mMeRankItem, selfInfo, 3)--刷新自己

        if self._refId == ModelRank.RANK_ENDLES_COMPLEX then
            -- local valueText1 = self:FindWndTrans(self.mMeRankItem,"Group/bg/valueText1")
            -- local anPos = valueText1.anchoredPosition
            -- anPos.x = 85
            -- valueText1.anchoredPosition = anPos
        end
    end
end

function UIRkPop:InitTabList(ref)
    local refId = self._refId

    --排行排名
    local list = {}
    if refId == ModelRank.RANK_MELEE or refId == ModelRank.RANK_INTEGRAL then
        --联盟混战的排行，会同时出现多个排行，多个奖励分页
        if table.isempty(self._rewardList) then
            list = {
                { type = ModelRank.TYPE_RANK_GUILD_WAR, title = ccClientText(12590), refId = ModelRank.RANK_MELEE },
                { type = ModelRank.TYPE_RANK_GUILD_SCORE, title = ccClientText(12591), refId = ModelRank.RANK_INTEGRAL },
            }
        end
    elseif refId == ModelRank.RANK_1600 or refId == ModelRank.RANK_1601 then
        --联盟混战的排行，会同时出现多个排行，多个奖励分页
        if table.isempty(self._rewardList) then

            list = {
                { type = ModelRank.TYPE_REWARD_RANK_10, title = ccClientText(20921), refId = ModelRank.RANK_1600 },
                { type = ModelRank.TYPE_REWARD_RANK_11, title = ccClientText(20922), refId = ModelRank.RANK_1601 },
            }
        end
    elseif refId == ModelRank.RANK_1702 or refId == ModelRank.RANK_1709 then
        -- bossTower的排行，会同时出现多个排行，多个奖励分页
        if table.isempty(self._rewardList) then

            list = {
                { type = ModelRank.TYPE_BOSSTOWER_RANK_SERVER, title = ccClientText(23717), refId = ModelRank.RANK_1702 },
                { type = ModelRank.TYPE_BOSSTOWER_RANK_WORLD, title = ccClientText(23737), refId = ModelRank.RANK_1709 },
            }
        end
    elseif refId == ModelRank.RANK_2410 or refId == ModelRank.RANK_2411 then
        list = {
            { type = ModelRank.TYPE_DARK_WAR_GUILD, title = ccClientText(27665), refId = ModelRank.RANK_2411 },
            { type = ModelRank.TYPE_DARK_WAR_PERSON, title = ccClientText(20921), refId = ModelRank.RANK_2410 },
        }
    else
        list = { { type = ModelRank.TYPE_RANK_ROOT, title = ccClientText(11719) } }
    end

    --里程碑奖励
    if (ref and ref.markReward == 1) then
        table.insert(list, { type = ModelRank.TYPE_MILESTONE_ROOT, title = ccClientText(11720) })
    end

    --排行奖励
    if not table.isempty(self._rewardList) then
        if refId == ModelRank.RANK_ARENA_LEADER then
            table.insert(list, { type = ModelRank.TYPE_REWARD_ARENA_DAY, title = ccClientText(11727) })
            table.insert(list, { type = ModelRank.TYPE_REWARD_ARENA_SEASON, title = ccClientText(11728) })
        elseif refId == ModelRank.RANK_MELEE or refId == ModelRank.RANK_INTEGRAL then
            list = {
                { type = ModelRank.TYPE_REWARD_GUILD_WAR, title = ccClientText(17942), refId = ModelRank.RANK_MELEE },
                { type = ModelRank.TYPE_REWARD_GUILD_SCORE, title = ccClientText(17943), refId = ModelRank.RANK_INTEGRAL },
            }
        else
            table.insert(list, { type = ModelRank.TYPE_REWARD, title = ccClientText(11715) })
        end
    end

    if (#list > 1) then
        self._tabList = self:GetUIScroll("tabCell")
        self._tabList:Create(self.mTabScroll, list, function(...)
            self:TabItem(...)
        end)

        CS.ShowObject(self.mTabScroll,true)
    end

    self._tabDataList = list

    local page = self._firstOpenPage
    if page ~= 1 then
        --第一次打开面板，需要请求排行数据
        self:NewPage()
    end
    local len = #list
    if page > len then
        self:OnClickTab(list[len].type)
    else
        self:OnClickTab(list[page].type)
    end
end

function UIRkPop:InitData()
    self._type = 2--排行榜请求类型 1请求排行榜分类展示信息 2请求子排行榜展示信息
    self._callFunc = self:GetWndArg("callFunc")
    self._showRankType = self:GetWndArg("showRankType") or UIRkPop.TYPE_RANK_NORNAL
    self._rankType = self:GetWndArg("type")
    self._refId = self:GetWndArg("refId")
    self._refId2 = self:GetWndArg("refId2") --用于双排行的情况，如联盟混战排行	self._callFun = self:GetWndArg("func")
    self._activityId = self:GetWndArg("sid")
    self._rewardList = self:GetWndArg("rewardList")
    self._rewardList2 = self:GetWndArg("rewardList2")
    self._endTime = self:GetWndArg("endTime")
    self._firstOpenPage = self:GetWndArg("page") or 1

    self._rankBaseInfo = self:GetWndArg("rankBaseInfo") or {}

    self._refIds = self:GetWndArg("refIds")
    if self._refIds and #self._refIds > 0 then
        self._refId = self._refIds[1]
        CS.ShowObject(self.mTabBtnList, true)
        self:InitTabBtnList()
    else
        CS.ShowObject(self.mTabBtnList, false)
    end

    printInfoN(string.format("refId %s ,type %s", self._refId, self._rankType))

    self._rankThree = {
        self.mRank1,
        self.mRank2,
        self.mRank3,
    }

    self._awardPageTypeList = {
        [ModelRank.TYPE_REWARD] = true,
        [ModelRank.TYPE_REWARD_ARENA_DAY] = true,
        [ModelRank.TYPE_REWARD_ARENA_SEASON] = true,
        [ModelRank.TYPE_REWARD_GUILD_WAR] = true,
        [ModelRank.TYPE_REWARD_GUILD_SCORE] = true,
    }

    self._rankRootTypeList = {
        [ModelRank.TYPE_RANK_ROOT] = true,
        [ModelRank.TYPE_RANK_GUILD_WAR] = true,
        [ModelRank.TYPE_RANK_GUILD_SCORE] = true,
        [ModelRank.TYPE_REWARD_RANK_10] = true,
        [ModelRank.TYPE_REWARD_RANK_11] = true,
        [ModelRank.TYPE_BOSSTOWER_RANK_SERVER] = true,
        [ModelRank.TYPE_BOSSTOWER_RANK_WORLD] = true,
        [ModelRank.TYPE_DARK_WAR_PERSON] = true,
        [ModelRank.TYPE_DARK_WAR_GUILD] = true,
    }
    if self._activityId then
        gModelActivity:ReqActivityConfigData(self._activityId)
    end

    self._bossTowerBossRankList = {
        [1700] = true,
        [1701] = true,
        [1703] = true,
        [1704] = true,
        [1705] = true,
        [1706] = true,
        [1707] = true,
        [1708] = true,
        [1710] = true,
        [1711] = true,
    }

    self._bossTowerRankList = {
        [ModelRank.RANK_1702] = true,
        [ModelRank.RANK_1709] = true,
    }

    self._spaceStr = "        "
    if gLGameLanguage:IsJapanRegion() then
        self._spaceStr = "      "
    end

    self._isEnus = gLGameLanguage:IsForeignVersion()


    self._spaceStr2 = "      "
    if self._isEnus then
        self._spaceStr2 = "       "

        self:SetAnchorPos(self.mTimeBg,Vector2.New(40,64))
    end

end

function UIRkPop:SetPlayerShow(tran, itemdata)
    if (not self._bMirrorRole) then
        self:SetHeroPaint(tran, itemdata.info, 1)
    else
        self:SetHeroPaint(tran, itemdata.hero, 2)
    end
end
----------------------------------------------里程碑--------------------------------------------------------------------
function UIRkPop:RefreshMilestone()
    if (self._oldType ~= ModelRank.TYPE_MILESTONE_ROOT) then
        return
    end
    CS.ShowObject(self.mBtnOneKeyMilestone, false)
    local rankingRewardQuick = gModelRank:GetRankingConfigRefByKey("rankingRewardQuick")
    local data = gModelRank:GetMarkRef(self._refId)
    if table.isempty(data) then
        return
    end
    self._milStoneData = data
    self._destStr = data.str
    local list = data.list
    local index
    local getNum = 0
    for i, v in ipairs(list) do
        if not v.bReceive and v.infos then
            if not index then
                index = i
            end
            getNum = getNum + 1
        end
    end
    CS.ShowObject(self.mBtnOneKeyMilestone, getNum > rankingRewardQuick)
    local refreshList = true
    if index then
        refreshList = false
        index = index - 1
        if index < 0 then
            index = 0
        end
    end
    if (self._milestoneList) then
        self._milestoneList:RefreshData(list, not refreshList)
    else
        self._milestoneList = self:GetUIScroll("milestoneCell")
        self._milestoneList:Create(self.mMilestoneScroll, list, function(...)
            self:MilestoneListItem(...)
        end, UIItemList.WRAP, refreshList)
    end
    if index then
        local uiList = self._milestoneList:GetList()
        uiList:RefreshList(UIListWrap.RefreshMode.Custom, index)
    end
end

function UIRkPop:OnClickLike(playerId, trans)
    -- if playerId == gModelPlayer:GetPlayerId() then
    --     GF.ShowMessage(ccClientText(11877))
    --     return
    -- end

    if gModelRank:IsLiked(self._likeType, playerId) then
        GF.ShowMessage(ccClientText(11878))
        return
    end

    if gModelRank:IsLikeLimit(self._likeType, true) then
        return
    end

    gModelRank:OnPlayerLikeReq(playerId, self._likeType)
    local instanceId = trans:GetInstanceID()
    local eff = self:CreateWndEffect(trans, "fx_ui_dianzan", instanceId, 100)
    self.likeEffTimer = self.likeEffTimer ~= nil and self.likeEffTimer or {}
    self.likeEffTimer[instanceId] = LxTimer.DelayTimeCall(function()
        if eff then
            eff:Destroy()
        end
    end, 0.5)
end

function UIRkPop:OnClickHelp()
    if not self._refId then
        return
    end
    local ref = gModelRank:GetRankingRefData(self._refId)
    GF.OpenWnd("UIBzTips", { refId = ref.helpTips })
end

function UIRkPop:RefreshPlayerInfo(pb)
    local likeType = pb.likeType
    if likeType ~= self._likeType then
        return
    end
    local playerId = pb.playerId
    local rankItemData = self._rankItemDataList[playerId]
    if not rankItemData then
        return
    end
    local oldNoLikeNum = self._noLikeNum
    self._noLikeNum = gModelRank:IsLikeLimit(self._likeType)
    rankItemData[2].info._like = rankItemData[2].info._like + 1
    if oldNoLikeNum ~= nil and oldNoLikeNum ~= self._noLikeNum then
        self:RefreshRank()
        return
    end
    local oldNoLikeReward = self._noLikeRewardNum
    self._noLikeRewardNum = gModelRank:IsLikeTimeRewardLimit(self._likeType)
    if oldNoLikeReward ~= nil and oldNoLikeReward ~= self._noLikeRewardNum then
        self:RefreshRank()
        return
    end

    self:InitRankItem(rankItemData[1], rankItemData[2], rankItemData[3])
end

function UIRkPop:SetRankItemL2401(item, itemdata, isSelf)
    local Image = self:FindWndTrans(item, "Image")
    local RankText = self:FindWndTrans(item, "RankText")
    local FlagBg = self:FindWndTrans(item, "FlagBg")
    local FlagBgFlagIcon = self:FindWndTrans(FlagBg, "FlagIcon")
    local FlagBgGuildLvBg = self:FindWndTrans(FlagBg, "GuildLvBg")
    local GuildLvBgGuildLvText = self:FindWndTrans(FlagBgGuildLvBg, "GuildLvText")
    local IconBg = self:FindWndTrans(item, "IconBg")
    local ServerIcon = self:FindWndTrans(item, "ServerIcon")
    local Group = self:FindWndTrans(item, "Group")
    local GroupNameText = self:FindWndTrans(Group, "NameText")
    local GroupServerText = self:FindWndTrans(Group, "ServerText")
    local GroupGuildNameText = self:FindWndTrans(Group, "GuildNameText")
    local GroupMemberText = self:FindWndTrans(Group, "MemberText")
    local GroupBg2 = self:FindWndTrans(Group, "Bg2")

    local GroupBg = self:FindWndTrans(Group, "Bg")
    local BgBgImg1 = self:FindWndTrans(GroupBg, "BgImg1")
    local BgBgImg2 = self:FindWndTrans(GroupBg, "BgImg2")
    local BgIcon = self:FindWndTrans(GroupBg, "Icon")
    local BgDesIcon = self:FindWndTrans(GroupBg, "DesIcon")
    local BgValueText1 = self:FindWndTrans(GroupBg, "valueText1")
    local BgValueText2 = self:FindWndTrans(GroupBg, "valueText2")
    local BgLookBtn = self:FindWndTrans(GroupBg, "LookBtn")
    local BgFormationBtn = self:FindWndTrans(GroupBg, "FormationBtn")
    local GroupBg3 = self:FindWndTrans(Group, "Bg3")
    local GroupLinkBg = self:FindWndTrans(Group, "LinkBg")
    local BgPower = self:FindWndTrans(item, "BgPower")
    local Root = self:FindWndTrans(item, "Root")

    local headIcon = self:FindWndTrans(item, 'HeadIcon')

    if gLGameLanguage:IsJapanRegion() then
        self:InitTextSizeWithLanguage(BgValueText1, -4)
    end

    CS.ShowObject(IconBg, false)
    CS.ShowObject(ServerIcon, false)
    CS.ShowObject(BgPower, false)
    CS.ShowObject(Root, false)
    CS.ShowObject(headIcon, false)
    CS.ShowObject(BgBgImg2, false)
    CS.ShowObject(BgIcon, false)
    CS.ShowObject(BgValueText2, false)
    CS.ShowObject(BgLookBtn, false)
    CS.ShowObject(BgFormationBtn, false)
    CS.ShowObject(GroupBg3, false)
    CS.ShowObject(GroupBg2, false)
    CS.ShowObject(GroupLinkBg, false)
    CS.ShowObject(BgDesIcon, false)
    CS.ShowObject(GroupNameText, false)

    CS.ShowObject(Image, true)
    CS.ShowObject(RankText, true)
    CS.ShowObject(FlagBg, true)
    CS.ShowObject(Group, true)
    --CS.ShowObject(GroupServerText,true)
    CS.ShowObject(GroupGuildNameText, true)
    --CS.ShowObject(GroupMemberText,true)
    CS.ShowObject(GroupBg, true)
    CS.ShowObject(BgBgImg1, true)
    CS.ShowObject(BgValueText1, true)

    local isEmpty = not itemdata.info or itemdata.info._playerId == 0
    CS.ShowObject(FlagBg, not isEmpty)
    CS.ShowObject(GroupBg, not isEmpty)
    CS.ShowObject(GroupServerText, not isEmpty)
    CS.ShowObject(GroupMemberText, not isEmpty)
    local rankIcon = self:FindWndTrans(item, "RankImg")
    self:SetRankText(RankText, itemdata, isSelf, rankIcon)
    self:SetWndClick(Image, function()
        self:OpenGuildInfo(itemdata)
    end)

    if isEmpty then
        self:SetWndText(GroupGuildNameText, ccClientText(11711))
        return
    end

    self:SetWndText(GroupServerText, itemdata.info._guildName)
    local str = string.replace(ccClientText(11732), itemdata.info._name)
    self:SetWndText(GroupGuildNameText, str)
    str = ""
    local gLv = itemdata.guildLevel
    if gLv > 0 then
        str = string.replace(ccClientText(11721), itemdata.guildCount, gModelGuild:GetGuildNumByLv(gLv))
    end
    self:SetWndText(GroupMemberText, str)
    self:SetWndText(GuildLvBgGuildLvText, gLv)
    local bgRef = gModelGuild:GetGuildFlagRefByRefId(itemdata.flagBgId)
    local iconRef = gModelGuild:GetGuildFlagRefByRefId(itemdata.flagId)
    if bgRef then
        self:SetWndEasyImage(FlagBg, bgRef.res)
    end
    if iconRef then
        self:SetWndEasyImage(FlagBgFlagIcon, iconRef.res)
    end

    self:SetWndText(BgValueText1, itemdata.score)


end

function UIRkPop:RefreshTimeBg(pageType)
    local _refId = self._refId
    local _endTime = self._endTime
    local isShowTime = gModelRank:GetIsRankingConfigRefByKey(_refId, "weekReward")
    CS.ShowObject(self.mTimeBg, isShowTime)
    local endTimeData = self:GetWndArg("endTimeData")
    if _refId == ModelRank.RANK_ARENA_LEADER then
        CS.ShowObject(self.mTimeBg, true)
        if not pageType or pageType == ModelRank.TYPE_RANK_ROOT then
            CS.ShowObject(self.mTimeBg, false)
            self:SetWndText(self.mTimeText, string.replace(ccClientText(10324), LUtil.FormatColorStr(128, "green")))
        elseif pageType == ModelRank.TYPE_REWARD_ARENA_DAY then
            local accountTime = gModelArena:GetArenaPara("AccountTime")
            local str = string.gsub(accountTime, "=", ":")
            self:SetWndText(self.mTimeText, string.replace(ccClientText(10352), str))
        elseif pageType == ModelRank.TYPE_REWARD_ARENA_SEASON then
            local seasonEndTime = gModelArena:GetRankSeasonTime()
            local timespan = seasonEndTime - GetTimestamp()
            local timeStr = LUtil.FormatTimespanCn(timespan)
            timeStr = LUtil.FormatColorStr(timeStr, "green")
            self:SetWndText(self.mTimeText, string.replace(ccClientText(10325), timeStr))
        end
    elseif _refId == ModelRank.RANK_ARENA_PEAK then
        if pageType == ModelRank.TYPE_REWARD then
            CS.ShowObject(self.mTimeBg, true)
            self:SetWndText(self.mTimeText, ccClientText(11854))
        end
    elseif _refId == ModelRank.RANK_HIGH_LADDER then
        CS.ShowObject(self.mTimeBg, true)
        if pageType == ModelRank.TYPE_RANK_ROOT then
            self:SetWndText(self.mTimeText, ccClientText(17522))
        else
            self:SetWndText(self.mTimeText, ccClientText(17523))
        end
    elseif _refId == ModelRank.RANK_HIGH_CHAMPION then
        CS.ShowObject(self.mTimeBg, true)
        self:SetWndText(self.mTimeText, ccClientText(17523))
    elseif _refId == ModelRank.RANK_INVASION then
        self:ShowInvasionRankTime()
    elseif _refId == ModelRank.RANK_CROSSGRADING then

        CS.ShowObject(self.mTimeBg, true)
        self.mTimeBg.sizeDelta = Vector2.New(447, 50)
        local xuiTextTrans = self:FindWndText(self.mTimeText)
        self:SetXUITextFontSize(xuiTextTrans, 20)
        self:SetWndText(self.mTimeText, ccClientText(21856))
        local curPos = self.mTimeBg.localPosition
        self.mTimeBg.localPosition = Vector3(curPos.x, curPos.y + 6, curPos.z)
        --self:SetAnchorPos(self.mTimeBg, Vector2.New(0.5,0.5))

    elseif _refId == 2300 then
        local str = self:GetWndArg("rankTips")
        CS.ShowObject(self.mTimeBg, true)
        self:SetWndText(self.mTimeText, str)
    elseif (_refId == ModelRank.RANK_TYPE_604 or gModelRank:CheckIsDayEndRank(_refId)) and endTimeData then
        local times
        local timet = GetTimestamp()
        if (endTimeData) then
            local endTimeDataArr = string.split(endTimeData, ":")
            times = LUtil.GetNextDayTimes(timet, 0, tonumber(endTimeDataArr[1]), tonumber(endTimeDataArr[2]))
        else
            times = self._endTime
        end
        self._times = times
        self:SetTime()
        self:TimerStart(self._rankTime, 1, false, -1)
        CS.ShowObject(self.mTimeBg, true)
    elseif (_refId == 1900) then
        self._times = gModelMagicPot:GetRankTime()
        self:SetTime()
        self:TimerStart(self._rankTime, 1, false, -1)
        CS.ShowObject(self.mTimeBg, true)
    elseif (isShowTime) then
        local timet = GetTimestamp()
        local times = LUtil.GetWeekTWOTimestamp(timet, 1)
        self._times = times
        self:SetTime()
        self:TimerStart(self._rankTime, 1, false, -1)
    elseif _endTime then
        CS.ShowObject(self.mTimeBg, true)
        self._times = _endTime
        local sid = self._activityId
        if (not self._times) then
            local activityDataS = gModelActivity:GetActivityBySid(sid)
            self._times = activityDataS.endTime
        end
        self:SetTime()
        if (self._times) then
            self:TimerStart(self._rankTime, 1, false, -1)
        end
    end
end
--设置英雄头像
function UIRkPop:SetHeroIcon(heroIcon, heroInfo, playerId)
    local heroData = {
        id = heroInfo.id,
        refId = heroInfo.refId,
        star = heroInfo.star,
        level = heroInfo.lv,
        skin = heroInfo.skin,
        isResonance = heroInfo.isResonance,
    }
    local instanceId = heroIcon:GetInstanceID()
    local uicommonlist = self._uiHeroIconClsList
    local baseClass = uicommonlist[instanceId]
    if not baseClass then
        baseClass = CommonIcon:New()
        uicommonlist[heroInfo.id] = baseClass
        baseClass:Create(heroIcon)
        self:SetIconClickScale(heroIcon, true)
    end
    baseClass:SetHeroDataSet(heroData)
    baseClass:DoApply()

    heroInfo.level = heroInfo.lv
    heroInfo.skin = heroInfo.skin,
    self:SetWndClick(heroIcon, function(...)
        gModelHero:ReqShowHeroTip(playerId, heroInfo)
    end)
end

function UIRkPop:SetRankItemL2400(item, itemdata, isSelf)
    --local Image = self:FindWndTrans(item,"Image")
    local RankText = self:FindWndTrans(item, "RankText")
    local FlagBg = self:FindWndTrans(item, "FlagBg")
    --local FlagBgFlagIcon = self:FindWndTrans(FlagBg,"FlagIcon")
    --local FlagBgGuildLvBg = self:FindWndTrans(FlagBg,"GuildLvBg")
    --local GuildLvBgGuildLvText = self:FindWndTrans(FlagBgGuildLvBg,"GuildLvText")
    local IconBg = self:FindWndTrans(item, "IconBg")
    --local IconBgIcon = self:FindWndTrans(IconBg,"Icon")
    local ServerIcon = self:FindWndTrans(item, "ServerIcon")
    --local ServerIconImage = self:FindWndTrans(ServerIcon,"Image")
    local Group = self:FindWndTrans(item, "Group")
    local GroupNameText = self:FindWndTrans(Group, "NameText")
    local GroupServerText = self:FindWndTrans(Group, "ServerText")
    local GroupGuildNameText = self:FindWndTrans(Group, "GuildNameText")
    local GroupMemberText = self:FindWndTrans(Group, "MemberText")
    --local GroupBg2 = self:FindWndTrans(Group,"Bg2")
    --local Bg2Back = self:FindWndTrans(GroupBg2,"Back")
    --local Bg2Icon = self:FindWndTrans(GroupBg2,"Icon")
    --local Bg2PowerText = self:FindWndTrans(GroupBg2,"PowerText")
    local GroupBg = self:FindWndTrans(Group, "Bg")
    local BgBgImg1 = self:FindWndTrans(GroupBg, "BgImg1")
    --local BgBgImg2 = self:FindWndTrans(GroupBg,"BgImg2")
    local BgIcon = self:FindWndTrans(GroupBg, "Icon")
    --local BgDesIcon = self:FindWndTrans(GroupBg,"DesIcon")
    local BgValueText1 = self:FindWndTrans(GroupBg, "valueText1")
    --local BgValueText2 = self:FindWndTrans(GroupBg,"valueText2")
    local BgLookBtn = self:FindWndTrans(GroupBg, "LookBtn")
    local BgFormationBtn = self:FindWndTrans(GroupBg, "FormationBtn")
    --local FormationBtnImage1 = self:FindWndTrans(BgFormationBtn,"Image1")
    --local FormationBtnImage = self:FindWndTrans(BgFormationBtn,"Image")
    --local GroupBg3 = self:FindWndTrans(Group,"Bg3")
    --local Bg3BgImg1 = self:FindWndTrans(GroupBg3,"BgImg1")
    --local Bg3ValueHot = self:FindWndTrans(GroupBg3,"valueHot")
    --local Bg3HomeBtn = self:FindWndTrans(GroupBg3,"HomeBtn")
    --local HomeBtnIcon = self:FindWndTrans(Bg3HomeBtn,"Icon")
    --local GroupLinkBg = self:FindWndTrans(Group,"LinkBg")
    --local LinkBgLike = self:FindWndTrans(GroupLinkBg,"like")
    --local likeLayout = self:FindWndTrans(LinkBgLike,"layout")
    --local layoutIcon = self:FindWndTrans(likeLayout,"icon")
    --local layoutText = self:FindWndTrans(likeLayout,"text")
    local BgPower = self:FindWndTrans(item, "BgPower")
    --local BgPowerBack = self:FindWndTrans(BgPower,"Back")
    --local BgPowerIcon = self:FindWndTrans(BgPower,"Icon")
    --local BgPowerPowerText = self:FindWndTrans(BgPower,"PowerText")
    --local Root = self:FindWndTrans(item,"Root")
    --local EnglishText = self:FindWndTrans(item,"EnglishText")

    local headTran = self:FindWndTrans(item, "HeadIcon")

    if gLGameLanguage:IsJapanRegion() then
        self:InitTextSizeWithLanguage(BgValueText1, -4)
    end

    CS.ShowObject(FlagBg, false)
    --CS.ShowObject(IconBg,false)
    CS.ShowObject(ServerIcon, false)
    CS.ShowObject(BgPower, false)
    CS.ShowObject(GroupGuildNameText, false)
    CS.ShowObject(GroupMemberText, false)

    CS.ShowObject(Group, true)
    CS.ShowObject(GroupBg, true)
    CS.ShowObject(BgIcon, false)
    CS.ShowObject(BgLookBtn, false)
    CS.ShowObject(BgFormationBtn, false)
    --CS.ShowObject(headTran,true)

    local isEmpty = not itemdata.info or itemdata.info._playerId == 0
    CS.ShowObject(BgBgImg1, not isEmpty)
    CS.ShowObject(GroupServerText, not isEmpty)
    local rankIcon = self:FindWndTrans(item, "RankImg")
    self:SetRankText(RankText, itemdata, isSelf, rankIcon)

    CS.ShowObject(headTran, not isEmpty)
    CS.ShowObject(IconBg, isEmpty)
    self:SetWndText(BgValueText1, "")
    if isEmpty then
        self:SetWndText(GroupNameText, ccClientText(11711))
        return
    end

    self:SetWndText(GroupNameText, itemdata.info._name)

    self:SetHeadIconImpl(headTran, itemdata)
    self:ShowServerText(GroupServerText, itemdata)
    self:SetWndText(BgValueText1, itemdata.score)
end

function UIRkPop:RefreshRed(index)
    -- if(index ~= self._rankType)then
    -- 	return
    -- end
    if not self._cellTransList then
        return
    end
    for i, v in pairs(self._cellTransList) do
        local item = v
        local RedPoint = self:FindWndTrans(item, "redPoint")
        local showRed = gModelRedPoint:CheckRankShowRed(i)
        CS.ShowObject(RedPoint, showRed)
    end
end
--设置形象
function UIRkPop:SetSpine(paintTans, ref, key)
    local paintFlip = ref.paintFlip2 == 1
    local paintMultiple = ref.paintMultiple2
    local offset = LxDataHelper.ParseVector2(ref.paintPaint2, ',')
    local spineKye = paintTans:GetInstanceID()
    self:DestroyWndSpineByKey(spineKye)--臨時處理-沒緩存
    self:CreateWndSpine(paintTans, ref.spine, spineKye, false, function(dpSpine)
        dpSpine:SetScale(paintMultiple)
        dpSpine:SetFlipX(paintFlip)
        local dpTrans = dpSpine:GetDisplayTrans()
        if dpTrans then
            dpTrans.anchorMin = Vector2.New(0.5, 0.5)
            dpTrans.anchorMax = Vector2.New(0.5, 0.5)
            dpTrans.localPosition = offset
        end
    end)
end

function UIRkPop:TabItem(list, item, itemdata, itempos)
    local btnTab = self:FindWndTrans(item, "BtnTab3")
    self:SetWndTabText(btnTab, itemdata.title, -4)
    self:SetWndTabStatus(btnTab, 1)
    if (itemdata.type == ModelRank.TYPE_MILESTONE_ROOT) then
        self._cellTransList[self._refId] = item
    end
    self._tabTrans[itemdata.type] = btnTab

    self:SetWndClick(item, function(...)
        self:OnClickTab(itemdata.type, itemdata.refId)
    end, LSoundConst.CLICK_PAGE_COMMON)
end

function UIRkPop:SetHeadIconImpl(tran, itemdata)
    local playerInfo = itemdata.info
    local playerId = playerInfo:GetPlayerId()
    local headData = {
        trans = tran,
        icon = playerInfo:GetHead(),
        headFrame = playerInfo:GetHeadFrame(),
        level = playerInfo:GetGrade(),
        func = function()
            gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.STORY_WRITER)
        end,
    }

    self:CreateHeadIconImpl(headData)
end

function UIRkPop:OnClickFormation(playerId)
    --GF.OpenWnd("WndFairyTaleTDOtherHero",{playerId = playerId})
end

function UIRkPop:OpenGuildInfo(itemdata)
    local playerInfo = itemdata.info
    if not playerInfo then
        return
    end

    gModelGuild:OnGuildMemberListReq(playerInfo._guildId, playerInfo._serverId)
end

function UIRkPop:ListItem(list, item, itemdata, itempos)
    if not itemdata then
        return
    end
    if (itemdata.index >= (self._page * self._pageSize - 3) and self._oldPage ~= self._page) then
        local num = gModelRank:GetRankQuantity(self._refId)
        if (self._page * self._pageSize < num) then
            self._oldPage = self._page
            self:NewPage()
        end
    end

    self:InitRankItem(item, itemdata, 2)
end

function UIRkPop:SetRankIcon(tran, itemdata)
    local rank = itemdata.rank or itemdata.index
    local iconStr = "public_num_3"
    local isIn = true
    if rank == 1 then
        iconStr = "public_num_1"
    elseif rank == 2 then
        iconStr = "public_num_2"
    elseif rank == 3 then
        iconStr = "public_num_3"
    else
        isIn = false
    end
    CS.ShowObject(tran, isIn)
    if not isIn then
        return
    end
    self:SetWndEasyImage(tran, iconStr)

end

function UIRkPop:SetCommonData()
    local _refId = self._refId
    local ref
    if _refId then
        self._bMirrorRole = gModelRank:GetIsRankingConfigRefByKey(_refId, "rankMirrorRole")
        ref = gModelRank:GetRankingRefData(_refId)
        self._likeType = ref.like
        CS.ShowObject(self.mBtnHelp, ref.helpTips > 0)
    end

    self._refData = ref

    local titleStr = ref and ccLngText(ref.nameTitle) or ""

    local webData = gModelActivity:GetWebActivityDataById(self._activityId)
    if webData and webData.config then
        self.activeCfg = webData.config
        local data = webData.config
        if not string.isempty(data.rankTitle) then
            titleStr = data.rankTitle
        end
    end

    self:RefreshTitleText(titleStr)
end

function UIRkPop:InitEvent()
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mCloseBtn, function(...)
        self:OnCloseWnd()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnHelp, function(...)
        self:OnClickHelp()
    end, LSoundConst.CLICK_ERROR_COMMON)
    self:SetWndClick(self.mBtnOneKeyMilestone, function(...)
        self:OnClickOneKeyMilStone()
    end)
end

function UIRkPop:OnActivityConfigData(data, sid)
    local _activityId = self._activityId
    if _activityId ~= sid then
        return
    end
    local webData = gModelActivity:GetWebActivityDataById(sid)
    if not webData then
        return
    end
    local data = webData.config
    if data.descriptionDetail then
        self._descriptionDetail = data.descriptionDetail
        self:RefreshRank()
    end
    if not string.isempty(data.rankTitle) then
        self:RefreshTitleText(data.rankTitle)
    end
end
function UIRkPop:InitServerRank(item, info, isThree)
    --isThree=1前面3，=2列表，=3自
    if isThree == 1 then
        local bgImage1 = self:FindWndTrans(item, "BgImage3")
        local groupBg = self:FindWndTrans(item, "Group/GroupBg")
        local serverText = self:FindWndTrans(item, "Group/ServerText")
        local nameText = self:FindWndTrans(item, "Group/NameText")
        local bgImg1 = self:FindWndTrans(item, "Group/Bg/BgImg1")
        local icon = self:FindWndTrans(item, "Group/Bg/Icon")
        local valueText1 = self:FindWndTrans(item, "Group/Bg/valueText1")

        CS.ShowObject(bgImage1, true)
        CS.ShowObject(groupBg, true)
        CS.ShowObject(serverText, info.serverName)
        CS.ShowObject(nameText, not info.score)
        CS.ShowObject(bgImg1, info.score)
        CS.ShowObject(icon, false)

        if info.score then
            local score = LUtil.NumberCoversion(info.score)
            self:SetWndText(valueText1, score)
            if gLGameLanguage:IsJapanRegion() then
                self:InitTextSizeWithLanguage(valueText1, -4)
            end

            local serverStr = LUtil.FormatColorStr(info.serverName, "lightGreen")
            self:SetWndText(serverText, serverStr)
        end
    else
        local rankText = self:FindWndTrans(item, "RankText")
        local rankImg = self:FindWndTrans(item, "RankImg")
        local serverIcon = self:FindWndTrans(item, "ServerIcon")
        local nameText = self:FindWndTrans(item, "Group/NameText")
        local bgPower = self:FindWndTrans(item, "BgPower")
        local powerText = self:FindWndTrans(item, "BgPower/PowerText")
        local powerIcon = self:FindWndTrans(item, "BgPower/Icon")

        local rankStr = ccClientText(11708)
        if (isThree == 2) then
            local rank = info.rank and info.rank or info.index
            rankStr = string.replace(ccClientText(11725), rank)
        elseif info.rank then
            if (info.rank >= 1 and info.rank <= 3) then
                CS.ShowObject(rankText, false)
                local rankIcon = ""
                if (info.rank == 1) then
                    rankIcon = "public_num_1"
                elseif (info.rank == 2) then
                    rankIcon = "public_num_2"
                elseif (info.rank == 3) then
                    rankIcon = "public_num_3"
                end
                CS.ShowObject(rankImg, true)
                self:SetWndEasyImage(rankImg, rankIcon)
            elseif info.rank > 3 then
                rankStr = string.replace(ccClientText(11725), info.rank)
            end
        end
        CS.ShowObject(serverIcon, info.score)
        CS.ShowObject(bgPower, info.score)
        CS.ShowObject(powerIcon, false)

        self:SetWndText(rankText, rankStr)
        if info.score then
            self:SetWndText(nameText, info.serverName)
            local score = LUtil.NumberCoversion(info.score)
            self:SetWndText(powerText, score)

        end
    end
end

function UIRkPop:SetRankItemT2400(item, itemdata)
    local BgImage1 = self:FindWndTrans(item, "BgImage1")
    local BgImage2 = self:FindWndTrans(item, "BgImage2")
    local BgImage3 = self:FindWndTrans(item, "BgImage3")
    --local BgImage3Image = self:FindWndTrans(BgImage3,"Image")
    local FlagBg = self:FindWndTrans(item, "FlagBg")
    --local FlagBgFlagIcon = self:FindWndTrans(FlagBg,"FlagIcon")
    --local FlagBgGuildLvBg = self:FindWndTrans(FlagBg,"GuildLvBg")
    --local GuildLvBgGuildLvText = self:FindWndTrans(FlagBgGuildLvBg,"GuildLvText")
    local Mask = self:FindWndTrans(item, "Mask")
    local MaskPlayIcon = self:FindWndTrans(Mask, "PlayIcon")
    local Group = self:FindWndTrans(item, "Group")
    local GroupGroupBg = self:FindWndTrans(Group, "GroupBg")
    local GroupServerText = self:FindWndTrans(Group, "ServerText")
    local GroupNameText = self:FindWndTrans(Group, "NameText")
    local GroupGuildNameText = self:FindWndTrans(Group, "GuildNameText")
    local GroupMemberText = self:FindWndTrans(Group, "MemberText")
    local GroupBg = self:FindWndTrans(Group, "Bg")
    local BgBgImg1 = self:FindWndTrans(GroupBg, "BgImg1")
    local BgBgImg2 = self:FindWndTrans(GroupBg, "BgImg2")
    local BgIcon = self:FindWndTrans(GroupBg, "Icon")
    local BgValueText1 = self:FindWndTrans(GroupBg, "valueText1")
    local BgValueText2 = self:FindWndTrans(GroupBg, "valueText2")
    local BgDesIcon = self:FindWndTrans(GroupBg, "DesIcon")
    local BgLookBtn = self:FindWndTrans(GroupBg, "LookBtn")
    local BgHomeBtn = self:FindWndTrans(GroupBg, "HomeBtn")
    --local HomeBtnHomeIcon = self:FindWndTrans(BgHomeBtn,"HomeIcon")
    local BgFormationBtn = self:FindWndTrans(GroupBg, "FormationBtn")
    --local FormationBtnImage1 = self:FindWndTrans(BgFormationBtn,"Image1")
    --local FormationBtnImage = self:FindWndTrans(BgFormationBtn,"Image")
    local GroupEnglishText = self:FindWndTrans(Group, "EnglishText")
    local GroupLinkBg = self:FindWndTrans(Group, "LinkBg")
    --local LinkBgLike = self:FindWndTrans(GroupLinkBg,"like")
    --local likeLayout = self:FindWndTrans(LinkBgLike,"layout")
    --local layoutIcon = self:FindWndTrans(likeLayout,"icon")
    --local layoutText = self:FindWndTrans(likeLayout,"text")
    local RankIcon = self:FindWndTrans(item, "RankIcon")
    local PlayerBtn = self:FindWndTrans(item, "PlayerBtn")

    CS.ShowObject(BgImage2, false)
    CS.ShowObject(BgImage3, false)
    CS.ShowObject(BgImage3, false)
    CS.ShowObject(FlagBg, false)
    CS.ShowObject(GroupGuildNameText, false)
    CS.ShowObject(GroupMemberText, false)
    CS.ShowObject(BgBgImg2, false)
    CS.ShowObject(BgIcon, false)
    CS.ShowObject(BgValueText2, false)
    CS.ShowObject(BgDesIcon, false)
    CS.ShowObject(BgLookBtn, false)
    CS.ShowObject(BgHomeBtn, false)
    CS.ShowObject(BgFormationBtn, false)
    CS.ShowObject(GroupEnglishText, false)
    CS.ShowObject(GroupLinkBg, false)
    CS.ShowObject(PlayerBtn, false)

    CS.ShowObject(BgImage1, true)
    CS.ShowObject(Mask, true)
    CS.ShowObject(Group, true)
    CS.ShowObject(GroupGroupBg, true)
    CS.ShowObject(GroupServerText, true)
    CS.ShowObject(GroupNameText, true)
    CS.ShowObject(GroupBg, true)
    CS.ShowObject(BgBgImg1, true)
    CS.ShowObject(BgValueText1, true)
    CS.ShowObject(RankIcon, true)

    if gLGameLanguage:IsJapanRegion() then
        self:InitTextSizeWithLanguage(BgValueText1, -4)
    end

    self:SetRankIcon(RankIcon, itemdata)
    self:SetWndClick(item, function()
        self:OpenPlayerInfo(itemdata)
    end)
    local isEmpty = not itemdata.info or itemdata.info._playerId == 0

    CS.ShowObject(BgBgImg1, not isEmpty)
    if isEmpty then
        self:SetWndText(GroupNameText, ccClientText(11711))
        return
    end

    self:SetPlayerShow(MaskPlayIcon, itemdata)
    self:ShowServerText(GroupServerText, itemdata)
    self:SetWndText(GroupNameText, itemdata.info._name)
    self:SetWndText(BgValueText1, itemdata.score)
end

function UIRkPop:RefreshLikeState()
    for k, v in pairs(self._rankItemDataList) do
        local isLiked = gModelRank:IsLiked(self._likeType, k)
        local isSelf = k == gModelPlayer:GetPlayerId()
        local item = v[1]
        if CS.IsValidObject(item) then
            local like = self:FindWndTrans(item, "like")
            self:SetWndImageGray(like, isLiked or isSelf)
        end
    end
end

function UIRkPop:OnClickTabBtn(itemdata)
    ---@type V_RankingRef
    local ref = itemdata.ref
    if ref.refId == self._refId then
        return
    end

    self._refId = ref.refId

    local uiTabBtnList = self:FindUIScroll("mTabBtnList")
    if uiTabBtnList then
        local uiList = uiTabBtnList:GetList()
        uiList:RefreshList()
    end

    self._bMirrorRole = gModelRank:GetIsRankingConfigRefByKey(self._refId, "rankMirrorRole")
    self._likeType = ref.like
    CS.ShowObject(self.mBtnHelp, ref.helpTips > 0)

    self._refData = ref

    local titleStr = ref and ccLngText(ref.nameTitle) or ""
    self:RefreshTitleText(titleStr)

    self._rewardList = nil
    self:InitRewardList(ref)
    self._page = 0
    self._haveServerData = false
    local oldType = self._oldType
    self._oldType = nil
    self:OnClickTab(oldType, ref.refId)
end

function UIRkPop:OpenPlayerInfo(itemdata)
    local playerInfo = itemdata.info
    if not playerInfo then
        return
    end

    if playerInfo._playerId == 0 then
        return
    end
    gModelGeneral:PlayerShowReq(playerInfo._playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
end

function UIRkPop:RefreshTitleText(titleStr)
    self:SetWndText(self.mTitleText, titleStr)
    self:InitTextSizeWithLanguage(self.mTitleText, -2)
    if gLGameLanguage:IsVieVersion() then
        self:InitTextLineWithLanguage(self.mTitleText,30)
    end
end

--刷新排行榜列表
function UIRkPop:RefreshRank()
    local ranks
    local selfInfo
    if (self._refId == ModelRank.RANK_GUILDBBRAVE) then
        local guildRankInfo = gModelGuild:GetGuildBraveRankData()
        ranks = guildRankInfo.oherRank
        selfInfo = guildRankInfo.selfRank
    elseif self._refId == ModelRank.RANK_GUILD_DONATE then
        local guildRankInfo = gModelGuild:GetRankDonateData()
        ranks = guildRankInfo.oherRank
        selfInfo = guildRankInfo.selfRank
    else
        ranks = gModelRank:GetRankListInfo(self._type, self._refId)
        selfInfo = gModelRank:GetMeRank()
    end
    if not selfInfo or not ranks then
        return
    end
    self._rankNum = selfInfo.rank
    self._haveServerData = true
    if not ((self._rankRootTypeList[self._oldType])) then
        return
    end

    local cellList = {}
    local threeList = {}

    if self:IsShowLike() then
        self._noLikeNum = gModelRank:IsLikeLimit(self._likeType)
        self._noLikeRewardNum = gModelRank:IsLikeTimeRewardLimit(self._likeType)
    end

    for i, v in ipairs(ranks) do


        v.index = i
        if (v.rank > 3) then
            --这里也判断下自己的rank是否符合当前的位置
            table.insert(cellList, v)
        elseif (v.rank >= 1 and v.rank <= 3) then
            table.insert(threeList, v)
        end
    end

    local len = #threeList

    for k = len + 1, 3 do
        table.insert(threeList, { index = k })
    end

    if self._refId == ModelRank.RANK_TYPE_603 then
        --前三的数据也进行处理
        local temp_threeList = {}

        for k, v in ipairs(threeList) do
            local index = k + 3  -- 当前对应的排名 从4
            -- check 排名是否对应
            if v.rank then
                --如果有排名
                local dataNewKey = v.rank

                v.index = v.rank
                temp_threeList[dataNewKey] = v
            end
        end
        threeList = temp_threeList

        for i = 1, 3 do
            if not threeList[i] then
                threeList[i] = { index = i }
            end
        end
    end

    self:RefreshThreeRank(threeList)--刷新前3

    len = #cellList

    for k = len + 4, 10 do
        table.insert(cellList, { index = k })
    end

    if self._refId == ModelRank.RANK_TYPE_603 then
        local temp_cellList = {}

        for k, v in ipairs(cellList) do
            -- check 排名是否对应
            if v.rank then
                --如果有排名
                local dataNewKey = v.rank - 3

                v.index = v.rank
                temp_cellList[dataNewKey] = v
            end
        end
        cellList = temp_cellList

        for i = 1, 7 do
            if not cellList[i] then
                cellList[i] = { index = i + 3 }
            end
        end
    end

    --table.sort(cellList , function(a , b)
    --	return a.index < b.index
    --end)

    if (self._rankList) then
        local list = self._rankList:GetList()
        self._rankList:RefreshData(cellList)
        list:EnableLoadAnimation(false)
        list:RefreshSilent()
    else
        self._rankList = self:GetUIScroll(self._rankCellKey)
        self._rankList:Create(self.mCellScroll, cellList, function(...)
            self:ListItem(...)
        end, UIItemList.WRAP, false)
        local list = self._rankList:GetList()
        list:EnableLoadAnimation(true, 0.03, 1, 2)
        list:SetLoadAnimationScale(nil, 0.03)
        list:RefreshSimpleList(UIListWrap.RefreshMode.Top)
    end

    --去掉未上榜不显示的限制，排名改为显示服务端发来的值
    --[[local ref = gModelRank:GetRankingRefData(self._refId)
		if selfInfo.rank > ref.quantity then
			selfInfo.rank = 0
		end
	]]--
    self:InitRankItem(self.mMeRankItem, selfInfo, 3)--刷新自己
    if self._refId == ModelRank.RANK_ENDLES_COMPLEX then
        -- local valueText1 = self:FindWndTrans(self.mMeRankItem,"Group/Bg/valueText1")
        -- local anPos = valueText1.anchoredPosition
        -- anPos.x = 85
        -- valueText1.anchoredPosition = anPos
    end
end

function UIRkPop:OnClickLookCell(refId)
    gModelRank:OnMilStoneHistoryReq(refId)
end

function UIRkPop:InitTabBtnList()
    local list = self:GetTabBtnList()
    local uiList = self:FindUIScroll("mTabBtnList")
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("mTabBtnList")
        uiList:Create(self.mTabBtnList, list, function(...)
            self:OnDrawTabBtnCell(...)
        end)
    end

    if self._isVie then
        self:SetAnchorPos(self.mTabBtnList,Vector2.New(80,-168))
    end
end

function UIRkPop:MilestoneListItem(list, item, itemdata, itempos)
    if not itemdata then
        return
    end
    local titleText = self:FindWndTrans(item, "TitleImage/DesText")
    local nameText = self:FindWndTrans(item, "NameText")
    local tipsText = self:FindWndTrans(item, "TipsText")
    local lookBtn = self:FindWndTrans(item, "LookBtn")
    local lookText = self:FindWndTrans(item, "LookBtn/LookText")
    local itemIcon = self:FindWndTrans(item, "Root/ItemIcon")
    local Mask = self:FindWndTrans(item, "Root/Mask")
    local Image = self:FindWndTrans(item, "Root/Image")
    local NumTxt = self:FindWndTrans(item, "Root/NumTxt")

    local playerInfo = itemdata.infos and itemdata.infos.info
    local dataRef = GameTable.LeaderboardMarkRewardRef[itemdata.refId]
    self:SetHeadIcon(item, playerInfo)
    self:SetWndText(titleText, string.replace(self._destStr, dataRef.stage))
    self:InitTextSizeWithLanguage(titleText, -2)
    self:SetWndText(nameText, "")
    self:SetWndText(tipsText, ccClientText(11706))
    self:SetWndText(lookText, ccClientText(11729))
    CS.ShowObject(lookBtn, false)
    CS.ShowObject(Image, false)
    CS.ShowObject(Mask, false)


    if self._isEnus then
        self:SetAnchorPos(titleText,Vector2.New(235.5,-19))
    end

    local itemData = LUtil.GetRefItemData(dataRef.reward)--物品数据
    local InstanceID = item:GetInstanceID()
    self:SetItemIcon(itemIcon, itemData, InstanceID)
    self:SetWndText(NumTxt, itemData.count)

    if (not playerInfo) then
        return
    end
    self:SetWndText(tipsText, "")
    self:SetWndText(nameText, playerInfo._name)
    CS.ShowObject(lookBtn, true)
    CS.ShowObject(Image, true)

    local bReceive = itemdata.bReceive
    local maskIcon = "public_txt_4_3"
    if (bReceive) then
        maskIcon = "public_txt_13_1"
    end
    CS.ShowObject(Mask, bReceive)
    self:SetWndEasyImage(Image, maskIcon, nil, true)
    Image.localScale = Vector3.New(1.1, 1.1, 1)
    self:SetWndClick(lookBtn, function(...)
        self:OnClickLookCell(itemdata.refId)
    end)
    if (not bReceive) then
        self:SetWndClick(itemIcon, function(...)
            self:OnClickGetAward(itemdata.refId)
        end)
    end
end

function UIRkPop:OnDrawTabBtnCell(list, item, itemdata, itempos)
    ---@type V_RankingRef
    local ref = itemdata.ref
    self:SetWndTabText(item, ccLngText(ref.nameTitle))
    local isSel = self._refId == ref.refId
    self:SetWndTabStatus(item, isSel and LWnd.StateOn or LWnd.StateOff)
    self:SetWndClick(item, function()
        self:OnClickTabBtn(itemdata)
    end)

    if self._isVie then
        local csLayoutElement = item:GetComponent(typeof_LayoutElement)
        csLayoutElement.preferredWidth = 220
    end
end

function UIRkPop:RefreshThreeRank(list)
    local rankTrans
    for i = 1, #list do
        rankTrans = self._rankThree[i]
        self:InitRankItem(rankTrans, list[i], 1)
    end
end

function UIRkPop:OnClickOneKeyMilStone()
    local data = self._milStoneData
    local list = data.list
    local refIds = {}
    for i, v in ipairs(list) do
        if not v.bReceive and v.infos then
            table.insert(refIds, v.refId)
        end
    end
    if #refIds <= 0 then
        GF.ShowMessage(ccClientText(11734))
        return
    end
    gModelRank:OnMileStoneReceiveReq(refIds)
end


--#####################################################################################################################
--## AwardPage ########################################################################################################
--#####################################################################################################################
----------------------------------------------奖励排行------------------------------------------------------------------
function UIRkPop:RefreshAwardPage(curRewardType)
    local selfRank = self._rankNum or 0
    curRewardType = curRewardType or ModelRank.TYPE_REWARD
    local list
    if curRewardType == ModelRank.TYPE_REWARD
            or curRewardType == ModelRank.TYPE_REWARD_ARENA_DAY
            or curRewardType == ModelRank.TYPE_REWARD_GUILD_WAR then
        list = self._rewardList
    elseif curRewardType == ModelRank.TYPE_REWARD_ARENA_SEASON
            or curRewardType == ModelRank.TYPE_REWARD_GUILD_SCORE then
        list = self._rewardList2
    end

    self._selfRank = selfRank
    self._awardPageRewardList = list
    if (self._awardUiList) then
        local uiList = self._awardUiList:GetList()
        local beforeNum = uiList:GetDataSize()
        if beforeNum ~= #list then
            self._awardUiList:RefreshList(list)
        else
            self._awardUiList:RefreshData(list)
        end
    else
        self._awardUiList = self:GetUIScroll("_awardUiList")
        self._awardUiList:Create(self.mAwardScroll, list, function(...)
            self:AwardRankListItem(...)
        end)
        self._awardUiList:EnableScroll(true, false)
    end

    self:RefreshAwardPageSelf()
end

------------------------------------------------------------------
return UIRkPop



