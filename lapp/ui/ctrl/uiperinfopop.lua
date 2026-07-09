---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPerInfoPop:LWnd
local UIPerInfoPop = LxWndClass("UIPerInfoPop", LWnd)

UIPerInfoPop.TYPE_NORMAL = 1            -- 正常打开
UIPerInfoPop.TYPE_BOSSTOWER = 2            -- 爬塔打开
UIPerInfoPop.TYPE_PREVIEW = 3            -- 预览打开
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPerInfoPop:UIPerInfoPop()
    ---@type table<number,CommonIcon>
    self._uiHeroIconClsList = {}
    self._playerPopOnlineKey = "_playerPopOnlineKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPerInfoPop:OnWndClose()
    self:ClearCommonIconList(self._uiHeroIconClsList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPerInfoPop:OnCreate()
    LWnd.OnCreate(self)

    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPerInfoPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()
    local openType = self:GetWndArg("openType") or UIPerInfoPop.TYPE_NORMAL
    self._openType = openType
    self._isForeign = gLGameLanguage:IsForeignVersion()
    self:InitText()
    self:InitEvent()
    self:InitMessage()
    self:InitCommonData()

    if openType == UIPerInfoPop.TYPE_NORMAL then
        self:InitCommand()
        -- elseif openType == UIPerInfoPop.TYPE_BOSSTOWER then
        -- 	self:InitBossTowerData()
    elseif openType == UIPerInfoPop.TYPE_PREVIEW then
        self:InitPreviewData()
    end
    self:InitEmptyList()

    self:RefreshForeign()
end

function UIPerInfoPop:InitTabBtnList()
    local list = self._tabBtnList
    local uiList = self._uiTabBtnList
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("uiTabBtnList")
        self._uiTabBtnList = uiList
        uiList:Create(self.mTabList, list, function(...)
            self:OnDrawTabBtnCell(...)
        end)
    end
end

function UIPerInfoPop:OnTreasureCell(list, item, itemdata, itempos)
    local DraconicSkill = self:FindWndTrans(item, "DraconicSkill")
    local typeRoot = self:FindWndTrans(item, "DraconicSkill/typeRoot")

    local param = {
        showName = true,
        showType = true,
        showStar = true,
        upRefId = itemdata.upRef.refId,
    }
    gModelDraconic:DrawSkillItem(self, DraconicSkill, param)

    if gLGameLanguage:IsJapanVersion() then
        CS.ShowObject(typeRoot,false)
    end

    self:SetWndClick(item, function()
        GF.OpenWnd("UIDraconicUpStar", { refId = itemdata.ref.refId, starNum = itemdata.upRef.rankNow, tips = true })
    end)
end

function UIPerInfoPop:InitCommonData()
    self._medalList = {
        [1] = self.mMedalIcon1,
        [2] = self.mMedalIcon2,
        [3] = self.mMedalIcon3
    }
end

function UIPerInfoPop:GetBossTowerPower()
    -- local power = self._pageIdx == 1 and self._maxHeroPower or self._lastHeroPower
    -- return tonumber(power)
end
-- 点击@
function UIPerInfoPop:OnClickaTa()
    --local _cellFun = self._cellFun
    --if _cellFun ~= nil then
    local data = {
        playerId = self._playerInfo._playerId,
        playerName = self._playerInfo._name,
        serverId = self._playerInfo._serverId,
        headFrame = self._playerInfo._headFrame,
    }
    FireEvent(EventNames.CHAT_AT_OTHER, data)
    --_cellFun(data)
    --end
    self:WndClose()
end

function UIPerInfoPop:RefreshForeign()
    CS.ShowObject(self.mBtnReportJa, false)
    if gLGameLanguage:IsJapanRegion() then
        if PRODUCT_G_VER ~= 0 then
            local isIos = CS.IsOSIos()
            if isIos then
                CS.ShowObject(self.mBtnReportJa, true)
            end
        end
    end
end
-- 点击拉黑
function UIPerInfoPop:OnClickBlacklist()
    if (not gModelFriend:GetBlackBAdd()) then
        GF.ShowMessage(ccClientText(12028))
        return
    end
    if (not gModelFriend:GetBAddHei(self._playerId)) then
        GF.OpenWnd("UIOrdinTip", { refId = 50002, func = function(...)
            gModelFriend:OnRelationProcessReq(3, gModelPlayer:GetPlayerId(), self._playerId, 1)
        end })
    else
        gModelFriend:OnRelationProcessReq(3, gModelPlayer:GetPlayerId(), self._playerId, 2)
    end
end

function UIPerInfoPop:RefreshHeroView()
    local combatHeroData = self._combatHeroData
    if not combatHeroData then
        return
    end
    local playerInfo = self._playerInfo

    local list = combatHeroData._heros or {}
    local grids = combatHeroData._grids
    for i = 1, #list do
        list[i].sort = grids[i]
    end
    table.sort(list, function(a, b)
        return a.sort < b.sort
    end)
    local uiList = self._uiHeroList
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("heroList")
        uiList:Create(self.mHeroListScroll, list, function(...)
            self:SetHeroIconListItem(...)
        end)
        self._uiHeroList = uiList
    end

    local playerData = {
        trans = self.mHeadIcon,
        playerId = playerInfo._playerId,
        name = playerInfo._name,
        icon = playerInfo._head,
        iconBg = playerInfo._headFrame,
        headFrame = playerInfo._headFrame,
        level = playerInfo._grade,
        serverId = playerInfo._serverId
    }
    local baseClass = HeadIcon:New(self)
    baseClass:SetHeadData(playerData)
    baseClass:RefreshUI()
    self:SetPowerStr(playerInfo._power)
end

function UIPerInfoPop:InitCommand()
    local playerInfo = self:GetWndArg("playerInfo")
    local combatHeroData = self:GetWndArg("combatHeroData")
    self._systemType = self:GetWndArg("systemType")
    --self._cellFun = self:GetWndArg("cellFun")
    self._channelId = self:GetWndArg("channelId")
    self._channelIndex = self:GetWndArg("channelIndex")
    self._treasures = self:GetWndArg("treasures")
    self._draconic = self:GetWndArg("draconic")
    self._playerInfo = playerInfo
    self._heroList = combatHeroData._heros
    self._combatHeroData = combatHeroData
    self._pageIdx = 1
    self._playerId = playerInfo._playerId
    self._spaceName = playerInfo._spaceName

    if LPlayerShowConst.HERO_DISCUSS == self._systemType then
        CS.ShowObject(self.mBtnCombat, false)
    end

    self:InitPlayerInfo(playerInfo)
    self:InitBtnSet()

    self._tabBtnList = {
        [1] = { btnName = ccClientText(19053), func = function()
            self:RefreshHeroView()
        end, idx = 1, viewRoot = self.mMaoxianView },
        [2] = { btnName = ccClientText(19054), func = function()
            self:RefreshBaoWuView()
        end, idx = 2, viewRoot = self.mBaowuView },
    }
    self:InitTabBtnList()
    self:RefreshBlackText()
    gModelChat:PlayerOnlineReq({ playerInfo._playerId }, "2")
    local _playerPopOnlineKey = self._playerPopOnlineKey
    --if not isOnline then
    --	self:TimerStop(_playerPopOnlineKey)
    --	return
    --end
    if not self:IsTimerExist(_playerPopOnlineKey) then
        self:TimerStart(_playerPopOnlineKey, 60, false, -1)
    end
    --local isBadgeShow = gModelFunctionOpen:CheckIsShow(17601020)
    --isBadgeShow = false
    local isBadgeShow = false
    CS.ShowObject(self.mBadgeMag, isBadgeShow)
    local isTagShow = gModelFunctionOpen:CheckIsShow(17602000)
    isTagShow = false
    CS.ShowObject(self.mTagItemRoot, isTagShow)
    CS.ShowObject(self.mBtnMar, self._systemType ~= LPlayerShowConst.BLACKLISET)

    self:TabBtnEvent(self._pageIdx, true)
end

function UIPerInfoPop:RefreshBossTowerHeroView()
    -- local list = self:GetBossTowerHeroList()
    -- local power = self:GetBossTowerPower()
    -- self:SetPowerStr(power)

    -- local uiList = self:GetUIScroll("heroList")
    -- uiList:Create(self.mHeroListScroll,list,function (...) self:SetBossTowerHeroListItem(...) end)
end
function UIPerInfoPop:BossTowerCombat()
    -- local playerInfo = self._playerInfo
    -- if not playerInfo then
    -- 	return
    -- end
    -- local enemyList,formationKeyList,formationRefId = self:GetBossTowerHeroList()
    -- local prefabNameList = {}
    -- for i,v in ipairs(enemyList) do
    -- 	local refId = v.refId
    -- 	local bossTowerRef = gModelBossTower:GetBossTowerHeroRefByRefId(refId)
    -- 	local monsterRefId = bossTowerRef and bossTowerRef.attr
    -- 	local prefabName,scale,needFlip = gModelHero:GetMonsterPbNameByRefId(monsterRefId)
    -- 	local heroType = gModelBossTower:GetBossTowerHeroTypeByRefId(refId)
    -- 	table.insert(prefabNameList,{
    -- 		refId = heroType,
    -- 		monsterRefId = refId,
    -- 		lv = v.breakLv,
    -- 		pos = i,
    -- 		bottomImg = gModelHero:GetHeroBottomImgByRefId(heroType),
    -- 		prefabName = prefabName,
    -- 		scale = scale,
    -- 		isResonance = 0,
    -- 		race = gModelHero:GetHeroRace(heroType),
    -- 		needFlip = needFlip,
    -- 	})
    -- end
    -- local prepareData = {
    -- 	prefabNameList = prefabNameList,
    -- 	playerInfo = playerInfo,
    -- 	matrixRefId = formationRefId,
    -- 	combatTreasures = {},
    -- }
    -- local combatType = gModelBossTower:GetBossTowerConfigRefByKey("compareFightType")
    -- local combatExtraData = {
    -- 	sid = self._sid,
    -- 	playerId = playerInfo._playerId,
    -- 	otherLevel = playerInfo._grade,
    -- 	otherName = playerInfo._name,
    -- 	otherPlayerHead = playerInfo._head,
    -- 	serverId = playerInfo._serverId,
    -- 	power = self:GetBossTowerPower(),
    -- 	enemyList = enemyList,
    -- 	prepareData = prepareData,
    -- 	bossTowerPkType = self._pageIdx,
    -- 	targetId = playerInfo._playerId,
    -- }
    -- gModelGeneral:RecordGameState()
    -- gLFightManager:PrepareGoToBattle(combatType,combatExtraData)
end

--设置头像
function UIPerInfoPop:SetHeadIcon(playerInfo)
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
-- 点击称号
function UIPerInfoPop:OnClickTitle()
    local _playerInfo = self._playerInfo
    local title = _playerInfo.title
    if title and title > 0 then
        local titleRef = gModelPlayer:GetRolePlayerHeadRefByRefId(title)
        if not titleRef then
            GF.ShowMessage(ccClientText(21148))
            return
        end
        GF.OpenWnd("UIPerSpreadPop", { StructPersonaliseInfo = { refId = title, playerName = _playerInfo._name } })
        --gModelPlayerSpace:OnPersonaliseOtherInfoReq(_playerInfo._name,_playerInfo._playerId,title)
    else
        GF.ShowMessage(ccClientText(21148))
    end
end

function UIPerInfoPop:RefreshBlackText()
    local str = ""
    if (not gModelFriend:GetBAddHei(self._playerId)) then
        str = ccClientText(21118)
    else
        str = ccClientText(21154)
    end
    self:SetWndText(self.mBtnBlacklistText, str)
end

function UIPerInfoPop:PlayerOnlineResp(pb)
    local playerIdList = pb.playerIdList
    local moreInfo = pb.moreInfo
    if moreInfo ~= "2" then
        return
    end
    local isOnline = false
    for i, v in ipairs(playerIdList) do
        isOnline = true
    end
    local effName = isOnline and "fx_liaotian_zaixianlvdian" or "fx_liaotian_lixianhuidian"
    self:DestroyWndEffectByKey("UIPerInfoPop")
    self:CreateWndEffect(self.mOnStatus, effName, "UIPerInfoPop", 80)
end

function UIPerInfoPop:OnClickBadge(index)
    local _playerInfo = self._playerInfo
    local badges = _playerInfo.badge
    local badge = badges[index]
    if badge and badge > 0 then
        gModelPlayerSpace:OnPersonaliseOtherInfoReq(_playerInfo._name, _playerInfo._playerId, badge)
    else
        GF.ShowMessage(ccClientText(21149))
    end
end

function UIPerInfoPop:OnDrawTabBtnCell(list, item, itemdata, itempos)
    local BtnTab2 = self:FindWndTrans(item, "BtnTab2")
    if BtnTab2 then
        local idx = itemdata.idx
        local sel = idx == self._pageIdx
        local isNoBtn = itemdata.isNoBtn
        self:SetWndTabText(BtnTab2, itemdata.btnName)
        self:SetWndTabStatus(BtnTab2, sel and 0 or 1)
        if not isNoBtn then
            self:SetWndClick(BtnTab2, function()
                if UIPerInfoPop.TYPE_PREVIEW == self._openType then
                    GF.ShowMessage(ccClientText(19097))
                else
                    self:TabBtnEvent(idx)
                end
            end)
        end

        if self._isVie then
            local textTran = CS.FindTrans(BtnTab2, "On/Text")
            self:InitTextLineWithLanguage(textTran, -30)
            textTran = CS.FindTrans(BtnTab2, "Off/Text")
            self:InitTextLineWithLanguage(textTran, -30)
        end

    end
end

function UIPerInfoPop:InitPreviewData()
    local playerInfo = self:GetWndArg("playerInfo")
    self._playerInfo = playerInfo
    self._pageIdx = 1
    self:InitPlayerInfo(playerInfo)
    self._tabBtnList = {
        [1] = { btnName = ccClientText(19053), idx = 1 },
        [2] = { btnName = ccClientText(19054), idx = 2 },
    }
    self:InitTabBtnList()
    --local isBadgeShow = gModelFunctionOpen:CheckIsShow(17601020)
    --isBadgeShow = false
    local isBadgeShow = false
    CS.ShowObject(self.mBadgeMag, isBadgeShow)
    local isTagShow = gModelFunctionOpen:CheckIsShow(17602000)
    isTagShow = false
    CS.ShowObject(self.mTagItemRoot, isTagShow)
    CS.ShowObject(self.mBtnMar, false)
    CS.ShowObject(self.mMaoxianView, true)
    self:SetPowerStr(playerInfo._power)
    CS.ShowObject(self.mPreviewText, true)
end

function UIPerInfoPop:SetPowerStr(power)
    --local defaultFontSize = 20
    --if self._isForeign then
    --	defaultFontSize   = 20
    --end
    local playerPower = tonumber(power or 0)
    --self:SetXUITextFontSize(self.mPowerText,defaultFontSize)
    --local playerPowerStr = LUtil.FormatCoversionHurtNumSpriteText(playerPower, nil, nil, defaultFontSize)
    --self:SetXUITextText(self.mPowerText,playerPowerStr)

    --local powerStr = LUtil.FormatPowerShowStr(playerPower,150)
    local powerStr = LUtil.PowerNumberCoversion(playerPower)
    self:SetWndText(self.mPowerText, powerStr)
end

function UIPerInfoPop:OnWndRefresh()
    local _openType = self._openType
    if _openType == UIPerInfoPop.TYPE_NORMAL then
        self:InitCommand()
        -- elseif _openType == UIPerInfoPop.TYPE_BOSSTOWER then
        -- 	self:InitBossTowerData()
    elseif _openType == UIPerInfoPop.TYPE_PREVIEW then
        self:InitPreviewData()
    end
end

function UIPerInfoPop:SetHeroIconListItem(list, item, itemdata, itempos)
    local heroTrans = CS.FindTrans(item, "Root/HeroIcon")
    local nameText = CS.FindTrans(item, "NameText")
    local heroData = {
        index = itemdata.index,
        id = itemdata.id,
        refId = itemdata.refId,
        star = itemdata.star,
        level = itemdata.lv,
        grade = itemdata.grade,
        fightPower = itemdata.fightPower,
        isResonance = itemdata.isResonance,
        skin = itemdata.skin,
        treeInfo = itemdata.treeInfo,
        -- crystalSheet = itemdata.crystalSheet,【G公共支持】删除伙伴晶石功能相关数据
        form = itemdata.form,
    }

    local InstanceID = item:GetInstanceID()
    local heroIconClsList = self._uiHeroIconClsList
    local baseClass = heroIconClsList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        heroIconClsList[InstanceID] = baseClass
        baseClass:Create(heroTrans)
        self:SetIconClickScale(heroTrans, true)
    end
    baseClass:SetHeroDataSet(heroData)
    baseClass:DoApply()

    local ref = gModelHero:GetHeroShowRefByRefId(itemdata.refId, itemdata.star)
    self:SetWndText(nameText, ccLngText(ref.name))
    self:SetWndClick(heroTrans, function()
        gModelHero:ReqShowHeroTip(self._playerInfo._playerId, heroData, nil, nil, nil, self._playerInfo._serverId)
    end)
end

function UIPerInfoPop:InitText()
    local isEnglish = gLGameLanguage:IsEnglishVersion()
    local addLineValue = 0
    local addSizeValue = -2
    if isEnglish then
        addLineValue = 20
    elseif gLGameLanguage:IsJapanRegion() then
        addSizeValue = -4
    end

    self:SetWndText(self.mCloseTip, ccClientText(17003))
    self:SetWndText(self.mTagTipsText, ccClientText(13121))
    self:SetWndText(self.mTitleText, ccClientText(11518))
    self:SetWndText(self.mBtnReportText, ccClientText(21117))
    self:SetWndText(self.mBtnChatText, ccClientText(21119))
    self:SetWndText(self.mBtnFriendText, ccClientText(21120))
    self:InitTextLineWithLanguage(self.mBtnFriendText, addLineValue)
    self:InitTextSizeWithLanguage(self.mBtnFriendText, addSizeValue)
    self:SetWndText(self.mBtnTatText, ccClientText(21175))
    self:SetWndText(self.mBtnCombatText, ccClientText(21121))
    self:SetWndText(self.mPreviewText, ccClientText(19097))
    self:SetWndText(self.mPowerName, ccClientText(12623) .. ":")
    self:SetWndText(self.mBtnReportText, ccClientText(12623) .. ":")
    local isEnableWrapping = self._isForeign
    self.mBtnBlacklistText_1.enableWordWrapping = isEnableWrapping
    self.mBtnReportText_1.enableWordWrapping = isEnableWrapping
    self.mBtnChatText_1.enableWordWrapping = isEnableWrapping
    self.mBtnTatText_1.enableWordWrapping = isEnableWrapping
    self.mBtnCombatText_1.enableWordWrapping = isEnableWrapping
    self:SetWndText(CS.FindTrans(self.mBtnReportJa, "BtnReportJaText"), ccClientText(21117))
end

function UIPerInfoPop:GetBossTowerHeroList()
    local list = {}
    -- local heroInfoList = {}
    -- local formationList = {}
    local formationKeyList = {}
    -- if self._pageIdx == 1 then
    -- 	formationList = self._maxHeroF
    -- 	heroInfoList = self._maxHeroKey
    -- elseif self._pageIdx == 2 then
    -- 	formationList = self._lastHeroF
    -- 	heroInfoList = self._lastHeroKey
    -- end
    local formationRefId = nil
    -- if formationList then
    -- 	local grids = formationList.grids or {}
    -- 	for i,v in ipairs(grids) do
    -- 		if v.id then
    -- 			local id = tonumber(v.id)
    -- 			table.insert(list,heroInfoList[id])
    -- 			formationKeyList[id] = v.grid
    -- 		end
    -- 	end
    -- end
    return list, formationKeyList, formationRefId
end

function UIPerInfoPop:RefreshBaoWuView()
    local list = {}
    for k, v in ipairs(self._draconic or {}) do
        list[k] = v.starRefId
    end
    local dataList = {}
    local DraconicSuitRankRef = GameTable.DraconicSuitRankRef
    local DraconicRef = GameTable.DraconicRef
    for k, v in ipairs(list) do
        local upRef = DraconicSuitRankRef[v]
        local ref = DraconicRef[upRef.type]
        dataList[k] = { ref = ref, upRef = upRef }
    end
    table.sort(dataList, gModelDraconic.SortDraconicList)

    local uiTreasureList = self._uiTreasureList
    if uiTreasureList then
        uiTreasureList:RefreshList(dataList)
    else
        uiTreasureList = self:GetUIScroll("uiTreasureList")
        self._uiTreasureList = uiTreasureList
        uiTreasureList:Create(self.mBaowuListScroll, dataList, function(...)
            self:OnTreasureCell(...)
        end, UIItemList.WRAP)
    end
end
function UIPerInfoPop:NormalCombat()
    local _playerInfo = self._playerInfo
    if not _playerInfo then
        return
    end
    local playerLv = _playerInfo._grade
    local needLv = gModelFunctionOpen:GetLevelLimit(12900000)
    local isOpen = gModelFunctionOpen:CheckIsOpened(12900000, true)
    local curBattle = gLFightManager:GetCurBattleUnit()
    if curBattle then
        local battle = gLFightManager:GetBattleByType(LCombatTypeConst.COMBAT_PK)
        if battle then
            local combatExtraData = battle:GetCombatExtraData()
            if combatExtraData.playerId ~= self._playerId then
                GF.ShowMessage(string.replace(ccClientText(16404)))
                return
            end
        else
            GF.ShowMessage(string.replace(ccClientText(16405)))
            return
        end
    end
    if not self._heroList or #self._heroList == 0 then
        GF.ShowMessage(string.replace(ccClientText(16403)))
        return
    end
    if isOpen then
        if playerLv >= needLv then
            local func = function()
                local combatExtraData = {
                    playerId = _playerInfo._playerId,
                    otherLevel = _playerInfo._grade,
                    otherName = _playerInfo._name,
                    otherPlayerHead = _playerInfo._head,
                    serverId = _playerInfo._serverId,
                }
                gModelGeneral:RecordGameState()
                gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_PK, combatExtraData)
                --self:WndClose()
            end
            GF.OpenWnd("UIOrdinTip", { refId = 51502, func = func, para = { _playerInfo._name } })
        else
            GF.ShowMessage(string.replace(ccClientText(16402), needLv))
        end
    else
        --GF.ShowMessage(string.replace(ccClientText(16401),needLv))
    end
end
-- 点击私聊
function UIPerInfoPop:OnClickChat()
    if (not gModelFunctionOpen:CheckIsOpened(11706000, true)) then
        return
    end

    local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
    if not sensitive then
        GF.ShowMessage(ccClientText(30800))
        return
    end

    local playerInfo = {
        playerId = self._playerInfo._playerId,
        name = self._playerInfo._name,
        icon = self._playerInfo._head,
        headFrame = self._playerInfo._headFrame,
        serverId = self._playerInfo._serverId
    }
    if gModelChat:OnClickOpenChat({ channel = ModelChat.CHANNEL_PRIVATE, playerInfo = playerInfo }) then
        FireEvent(EventNames.ON_CHAT_SKIP_PRIVATE, { channel = ModelChat.CHANNEL_PRIVATE, playerInfo = playerInfo })
        self:WndClose()
    end
end
--------------------------------------------------------------------------------------------------------------------
-- 点击切磋
function UIPerInfoPop:OnClickCombat()
    local openType = self._openType
    if openType == UIPerInfoPop.TYPE_NORMAL then
        self:NormalCombat()
    else
        -- self:BossTowerCombat()
    end
end
-----------------------------------------------------------------------------------------------------------------
function UIPerInfoPop:OnTimer(key)
    if (self._playerPopOnlineKey == key) then
        gModelChat:PlayerOnlineReq({ self._playerId }, "2")
    end
end

function UIPerInfoPop:InitBossTowerData()
    -- local sid = self:GetWndArg("sid")
    -- local playerInfo = self:GetWndArg("playerInfo")
    -- local maxHero = self:GetWndArg("maxHero")
    -- local maxHeroKey = self:GetWndArg("maxHeroKey")
    -- local maxHeroF = self:GetWndArg("maxHeroF")
    -- local maxHeroPower = self:GetWndArg("maxHeroPower")
    -- local lastHero = self:GetWndArg("lastHero")
    -- local lastHeroKey = self:GetWndArg("lastHeroKey")
    -- local lastHeroF = self:GetWndArg("lastHeroF")
    -- local lastHeroPower = self:GetWndArg("lastHeroPower")

    -- self._sid = sid
    -- self._playerInfo = playerInfo
    -- self._maxHero = maxHero
    -- self._maxHeroKey = maxHeroKey
    -- self._maxHeroF = maxHeroF
    -- self._maxHeroPower = maxHeroPower

    -- self._lastHero = lastHero
    -- self._lastHeroKey = lastHeroKey
    -- self._lastHeroF = lastHeroF
    -- self._lastHeroPower = lastHeroPower

    -- self._pageIdx = 1
    -- self:InitPlayerInfo(playerInfo)
    -- self:SetBossTowerBtn()
    -- self._tabBtnList = {
    -- 	[1] = {btnName = ccClientText(23768),func = function()
    -- 		self:RefreshBossTowerHeroView()
    -- 	end,idx = 1,viewRoot = self.mMaoxianView},
    -- 	[2] = {btnName = ccClientText(23769),func = function()
    -- 		self:RefreshBossTowerHeroView()
    -- 	end,idx = 2,viewRoot = self.mMaoxianView},
    -- }
    -- self:InitTabBtnList()


    -- self:TabBtnEvent(self._pageIdx,true)
end

function UIPerInfoPop:SetBossTowerHeroListItem(list, item, itemdata, itempos)
    -- local heroTrans = CS.FindTrans(item,"Root/HeroIcon")
    -- local nameText = CS.FindTrans(item,"Root/NameText")
    -- local InstanceID = item:GetInstanceID()
    -- local baseClass = self:GetCommonIcon(InstanceID)
    -- baseClass:Create(heroTrans)
    -- self:SetIconClickScale(heroTrans, true)
    -- local refId = itemdata.refId
    -- local heroType = gModelBossTower:GetBossTowerHeroTypeByRefId(refId)
    -- local star = gModelBossTower:GetHeroStarByRefId(refId)
    -- local heroData = {
    -- 	refId = heroType,
    -- 	star = star,
    -- 	level = itemdata.breakLv,
    -- }
    -- baseClass:SetHeroDataSet(heroData)
    -- baseClass:DoApply()

    -- local ref = gModelHero:GetHeroShowRefByRefId(heroType,star)
    -- self:SetWndText(nameText,ccLngText(ref.name))

    -- self:SetWndClick(heroTrans,function ()
    -- 	--GF.OpenWnd("UISagaSpreadNew",{refId = refId,bossTowerHeroRefId = refId,sid = self._sid,wndType = 3,bossTowerServerData = itemdata,playerId = self._playerInfo._playerId})
    -- 	gModelGeneral:OpenHeroShareWnd({refId = refId,bossTowerHeroRefId = refId,sid = self._sid,wndType = 3,bossTowerServerData = itemdata,playerId = self._playerInfo._playerId})
    -- end)
end

function UIPerInfoPop:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnReport, function(...)
        self:OnClickInform()
    end)
    self:SetWndClick(self.mBtnBlacklist, function(...)
        self:OnClickBlacklist()
    end)
    self:SetWndClick(self.mBtnChat, function(...)
        self:OnClickChat()
    end)
    self:SetWndClick(self.mBtnAddFriend, function(...)
        self:OnClickAddFriends()
    end)
    self:SetWndClick(self.mBtnTa, function(...)
        self:OnClickaTa()
    end)
    self:SetWndClick(self.mBtnCombat, function(...)
        self:OnClickCombat()
    end)
    self:SetWndClick(self.mTitleImg, function()
        self:OnClickTitle()
    end)
    self:SetWndClick(self.mMedalIcon1, function()
        self:OnClickBadge(1)
    end)
    self:SetWndClick(self.mMedalIcon2, function()
        self:OnClickBadge(2)
    end)
    self:SetWndClick(self.mMedalIcon3, function()
        self:OnClickBadge(3)
    end)

    self:SetWndClick(self.mBtnReportJa, function()
        gModelGeneral:OpenUIOrdinTips({ refId = 50010 })
    end)
end

function UIPerInfoPop:InitMessage()
    if self._openType ~= UIPerInfoPop.TYPE_NORMAL then
        return
    end

    self:WndNetMsgRecv(LProtoIds.RelationProcessResp, function(...)
        self:RefreshBlackText(...)
        self:InitBtnSet()
    end)
    self:WndNetMsgRecv(LProtoIds.RelationIdResp, function(...)
        self:InitBtnSet()
    end)
    self:WndEventRecv(EventNames.FRIEND_WIN_UPDATE_END, function(...)
        self:InitBtnSet()
    end)
    --self:WndNetMsgRecv(LProtoIds.PlayerSpaceResp,function (...)
    --	self:WndClose()
    --end)
    self:WndNetMsgRecv(LProtoIds.PlayerOnlineResp, function(...)
        self:PlayerOnlineResp(...)
    end)
end

function UIPerInfoPop:SetBossTowerBtn()
    CS.ShowObject(self.mBtnBlacklist, false)
    CS.ShowObject(self.mBtnReport, false)
    CS.ShowObject(self.mBtnChat, false)
    CS.ShowObject(self.mBtnTa, false)
    CS.ShowObject(self.mBtnAddFriend, false)
end

function UIPerInfoPop:InitBtnSet()
    local isFriend = gModelFriend:GetBFriend(self._playerId)
    CS.ShowObject(self.mBtnChat, isFriend)
    CS.ShowObject(self.mBtnAddFriend, not isFriend)
    --CS.ShowObject(self.mBtnReport, self._systemType == LPlayerShowConst.CHAT_SYSTEM)
    CS.ShowObject(self.mBtnReport, false)
    CS.ShowObject(self.mBtnTa, self._systemType == LPlayerShowConst.CHAT_SYSTEM)

    if self._systemType == LPlayerShowConst.STORY_WRITER then
        CS.ShowObject(self.mBtnBlacklist, false)
        CS.ShowObject(self.mBtnChat, false)
        CS.ShowObject(self.mBtnTa, false)
        CS.ShowObject(self.mBtnAddFriend, false)
        CS.ShowObject(self.mBtnCombat, false)
    end
end

function UIPerInfoPop:InitEmptyList()
    local data = {
        refId = 18001,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UIPerInfoPop:InitPlayerInfo(playerInfo)
    local _head = playerInfo._head
    local _headFrame = playerInfo._headFrame
    local _grade = playerInfo._grade
    local _vipLevel = playerInfo._vipLevel
    local _name = playerInfo._name
    local sex = playerInfo.sex
    local _serverId = playerInfo._serverId
    local _guildId = playerInfo._guildId
    local _serverName = playerInfo._serverName
    local _playerId = playerInfo._playerId
    local _guildName = playerInfo._guildName
    local signature = playerInfo.signature
    local disallowTalk = playerInfo.disallowTalk
    local title = playerInfo.title
    local badge = playerInfo.badge
    local tag = playerInfo.tag
    local backGround = playerInfo.backGround
    local age = playerInfo.age or 1
    local ipCountry = playerInfo.ipCountry
    local ipProvince = playerInfo.ipProvince
    local shieldInfo = playerInfo.shieldInfo or "0|0"
    local figure = playerInfo._figure
    local grade = playerInfo._grade
    if not backGround or backGround == 0 then
        backGround = gModelPlayer:GetRoleConfigRefByKey("initPersonalBg")
    end

    self:SetWndText(self.mLvlText, grade)

    if GameTable.SnakeRoleAdventureImageRef[figure] then
        local heroEffId = GameTable.SnakeRoleAdventureImageRef[figure].hero
        local iconBig = GameTable.CharacterEffectRef[heroEffId].iconBig
        self:SetWndEasyImage(self.mRoleSp, iconBig)
    end

    self:SetHeadIcon({
        trans = self.mHeadIcon,
        icon = _head,
        headFrame = _headFrame,
        level = _grade,
    })

    CS.ShowObject(self.mVipBg, false)
    CS.ShowObject(self.mVipTitle, false)
    if _vipLevel >= 0 then
        local vipLvRef = gModelVip:GetRefByVipLv(_vipLevel)
        if vipLvRef then
            local shieldInfoList = string.split(shieldInfo, "|")
            local isShowVip = shieldInfoList[1] and shieldInfoList[1] == "0"
            local showVipStr = ""
            if isShowVip then
                showVipStr = tostring(_vipLevel)
            end
            self:SetWndText(self.mVipText,string.replace(ccClientText(11942),showVipStr))
            CS.ShowObject(self.mVipBg, isShowVip)
            --if not string.isempty(typeface) then
            --	local arr = string.split(typeface,"|")
            --	local topColor = LUtil.ColorByHex_6(arr[1])
            --	local bottomColor = LUtil.ColorByHex_6(arr[2])
            --	LxUiHelper.SetTextColorGradient(self.mVipText,topColor,topColor,bottomColor,bottomColor)
            --	if not string.isempty(arr[3]) then
            --		local pos = LxDataHelper.ParseVector2NotEmpty3(arr[3])
            --		self:SetAnchorPos(self.mVipText, pos)
            --	end
            --end
        end
    end
    --self:SetWndText(self.mVipText,LUtil.FormatHurtNumSpriteText(_vipLevel))
    self:SetWndText(self.mNameText, _name)
    --local sexIcon = sex == 1 and "role_zone_ui_man" or "role_zone_ui_woman"
    local sexIcon = gModelPlayer:GetDefaultIcon()

    self:SetWndEasyImage(self.mSexImg, sexIcon)
    CS.ShowObject(self.mSexImg, false)
    local ageStr = age > 1 and age - 1 or ccClientText(21108)
    self:SetWndText(self.mAgeText, string.replace(ccClientText(21176), ageStr))
    local serverId = gModelPlayer:GetServerId()
    local guildId = gModelPlayer:GetGuildId()
    if guildId ~= 0 then
        guildId = tonumber(guildId)
    end

    local sevenName = gModelFriend:GetSevenName(_serverId)
    local isSeven = serverId == _serverId
    if _serverName ~= "" then
        sevenName = _serverName
    end
    -- self:SetWndText(self.mSevenText,string.replace(ccClientText(21138),sevenName))
    local str = ""
    local func = nil
    if (_guildId == 0) then
        str = ccClientText(11550)
        if isSeven and guildId > 0 then
            str = str .. string.replace(ccClientText(11551), ccClientText(11552))
            func = function()
                --邀请加入
                gModelGuild:OnGuildInviteReq(_playerId)
                self:OnClickChat()
            end
        end
    else
        str = _guildName
        --if isSeven and guildId == 0 then
        str = string.replace(ccClientText(11551), str)
        func = function()

            --check 公会的开启
            local isopen = gModelFunctionOpen:CheckIsOpened(12100000, true)
            if isopen then
                gModelGuild:OnGuildMemberListReq(_guildId, _serverId)
            end
        end
        --end
    end
    self:SetWndClick(self.mBtnGuild, function()
        if func then
            func()
        end
    end)
    local guildStr = string.replace(ccClientText(21139), str)
    self:SetWndText(self.mGuildText, guildStr)
    local signatureStr = (signature == "" or disallowTalk == 1) and ccClientText(21109) or signature
    self:SetWndText(self.mSignatureText, signatureStr)
    local isForeignEn = gLGameLanguage:IsOtherLngRegion()
    if not isForeignEn then
        local ipStr = gModelPlayer:GetIpShowText(ipCountry, ipProvince)
        ipStr = string.replace(ccClientText(15045), ipStr)
        self:SetWndText(self.mIpText, ipStr)
    end

    local titleR = title or 0
    CS.ShowObject(self.mTitleImg, true)
    local titleRef = gModelPlayer:GetRolePlayerHeadRefByRefId(titleR)
    if titleRef then
        self:SetWndEasyImage(self.mTitleImg, titleRef.icon, nil, true)
    else
        CS.ShowObject(self.mTitleImg, false)
        self:SetWndEasyImage(self.mTitleImg, "role_titile_0", nil, true)
    end
    local _badge = badge
    for i, v in pairs(_badge) do
        local root = self._medalList[i]
        self:SetMedalIcon(root, v)
    end
    local isTabTips = true
    local _tagIds = {}
    for i, v in pairs(tag) do
        table.insert(_tagIds, v)
    end
    local setTagNum = gModelPlayer:GetRoleConfigRefByKey("popTagNum")
    for i = 1, setTagNum do
        local item = self:FindWndTrans(self.mTagItemRoot, "TagItem" .. i)
        local refId = _tagIds[i] or 0
        if refId > 0 then
            isTabTips = false
        end
        self:SetTagItemList(item, refId, i)
    end
    CS.ShowObject(self.mTagTipsText, isTabTips)

    local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(backGround)
    if not ref then
        return
    end
    local icon = ref.icon
    local titleColor = ref.titleColor
    -- local titleIcon = ref.titleIcon

    -- self:SetWndEasyImage(self.mTitleStar1,titleIcon)
    -- self:SetWndEasyImage(self.mTitleStar2,titleIcon)
    if CS.IsWebGL() then
        self:SetWndEasyImage(self.mCommonBg, icon, nil, false)
    else
        self:SetWndEasyImage(self.mCommonBg, icon, nil, true)

    end

    if ref.effect then
        self:CreateWndEffect(self.mCommonBg, ref.effect, ref.effect, 100, false, false)
    end
    LxUiHelper.SetTextColorGradientStr(self.mTitleText, titleColor)
    printInfoNR(titleColor)
end

function UIPerInfoPop:SetMedalIcon(root, medalId)
    local medalBg = CS.FindTrans(root, "MedalBg")
    local medalImg = CS.FindTrans(root, "MedalImg")

    CS.ShowObject(medalBg, not medalId)
    CS.ShowObject(medalImg, medalId)
    if medalId then
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

            local badgeOutsideSize = medalRef.badgeOutsideSize
            if badgeOutsideSize == 0 then
                badgeOutsideSize = 60
                printInfoNR(refId .. "配置 badgeOutsideSize = 0，默认" .. badgeOutsideSize)
            end
            badgeOutsideSize = badgeOutsideSize / 100
            printInfoNR("badgeOutsideSize = " .. badgeOutsideSize)
            medalImg.localScale = Vector3(badgeOutsideSize, badgeOutsideSize, badgeOutsideSize)
        end
        self:SetWndText(UIText, rankStr)
    end
end

function UIPerInfoPop:TabBtnEvent(idx, init)
    if not init then
        if self._pageIdx == idx then
            return
        end
    end
    self._pageIdx = idx
    if self._tabBtnList then
        local uiList = self._uiTabBtnList:GetList()
        if uiList then
            uiList:RefreshList()
        end

        local _tabBtnList = self._tabBtnList or {}
        if self._openType == UIPerInfoPop.TYPE_BOSSTOWER then
            -- CS.ShowObject(self.mMaoxianView,true)
            -- CS.ShowObject(self.mBaowuView,false)
        else
            for i, v in ipairs(_tabBtnList) do
                local viewRoot = v.viewRoot
                CS.ShowObject(viewRoot, i == idx)
            end
        end
        local func = _tabBtnList[idx].func
        if func then
            func()
        end
    end
end

-- 点击举报
function UIPerInfoPop:OnClickInform()
    if (gModelFunctionOpen:CheckIsOpened(11799000, true)) then
        GF.OpenWnd("UIRepin", { channelId = self._channelId, channelIndex = self._channelIndex, playerInfo = self._playerInfo })
    end
end

function UIPerInfoPop:SetTagItemList(item, itemdata, itempos)
    CS.ShowObject(item, true)
    local posRef = gModelPlayerSpace:GetRoleTagPosByRefId(itempos)
    local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(itemdata)
    local btnAdd = self:FindWndTrans(item, "BtnAdd")
    local numText = self:FindWndTrans(item, "BtnAdd/NumText")
    local tagItem = self:FindWndTrans(item, "TagItem")
    local tagText = self:FindWndTrans(item, "TagItem/TagText")

    CS.ShowObject(btnAdd, false)
    CS.ShowObject(tagItem, false)
    self:SetWndText(numText, itempos)
    local posArr = string.split(posRef.popTagPos, "|")
    item.localPosition = Vector2.New(tonumber(posArr[1]), tonumber(posArr[2]))
    if not ref then
        return
    end
    CS.ShowObject(tagItem, true)
    local size = posRef.popTagSize
    item.localScale = Vector2.New(size, size)
    self:SetWndEasyImage(tagItem, ref.tagBg)
    self:SetWndText(tagText, LUtil.FormatColorStr(ccLngText(ref.name), "#" .. ref.tagColour))
end
-- 点击加好友
function UIPerInfoPop:OnClickAddFriends()
    gModelFriend:OnRelationProcessReq(1, gModelPlayer:GetPlayerId(), self._playerInfo._playerId, 1)
end
------------------------------------------------------------------
return UIPerInfoPop