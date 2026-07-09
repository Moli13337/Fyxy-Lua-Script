---
--- Created by BY.
--- DateTime: 2023/10/9 15:24:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISpreadCombatPop:LWnd
local UISpreadCombatPop = LxWndClass("UISpreadCombatPop", LWnd)

UISpreadCombatPop.TYPE_WND_3 = 3            --- 直接传入数据

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISpreadCombatPop:UISpreadCombatPop()
    self._commonIconList = {}
    self._timeKey = "_timeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISpreadCombatPop:OnWndClose()
    self:ClearCommonIconList(self._commonIconList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISpreadCombatPop:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISpreadCombatPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
end

function UISpreadCombatPop:OnClickPk()
    if not self._reportTable then
        return
    end

    local bool = gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_PK)
    if bool then
        GF.ShowMessage(ccClientText(23409))
        return
    end
    --gModelChat:OnShareFormationPKReq(self._fileUrl)
    local prepareData = self:GetBattlePrepareData()
    local func = function()
        local combatExtraData = {
            otherName = self._playerName,
            url = self._fileUrl,
            prepareData = prepareData,
        }
        gModelGeneral:RecordGameState()
        gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_PK, combatExtraData)
        self:WndClose()
    end
    GF.OpenWnd("UIOrdinTip", { refId = 51502, func = func, para = { self._playerName } })
end

function UISpreadCombatPop:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end)
    --self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
    self:SetWndClick(self.mBtnShare, function(...)
        self:OnClickShare()
    end)
    self:SetWndClick(self.mBtnRedact, function(...)
        self:OnClickRedact()
    end)
    self:SetWndClick(self.mBtnPk, function(...)
        self:OnClickPk()
    end)
end

function UISpreadCombatPop:OnClickRedact()
    local combatType = self._combatType

    local para = {
        setTargetType = combatType,
        returnFunc = function()
            gModelGeneral:RecoverGameState()
        end
    }
    gModelGeneral:RecordGameState()
    gModelFormation:OpenSetFormationWnd(para)
    self:WndClose()
end

function UISpreadCombatPop:InitCommand()
    --self:SetWndText(self.mLblBiaoti,ccClientText(23400))
    self:SetWndText(self.mTitle1Text, ccClientText(23401))
    self:SetWndText(self.mTitle2Text, ccClientText(23402))
    self:SetWndText(self.mTitle3Text, ccClientText(38703))
    --self:SetWndText(self.mSkillText,ccClientText(23407))
    self:SetWndText(self.mCloseTip, ccClientText(17003))
    self:SetWndButtonText(self.mBtnRedact, ccClientText(23403))
    self:SetWndButtonText(self.mBtnShare, ccClientText(23404))
    self:SetWndButtonText(self.mBtnPk, ccClientText(23405))

    local wndType = self:GetWndArg("wndType") or 1
    self._callFunc = self:GetWndArg("func")    --回调方法
    self._uiCommonList = {}

    CS.ShowObject(self.mBtnRedact, wndType == 1)
    CS.ShowObject(self.mBtnShare, wndType == 1)
    CS.ShowObject(self.mBtnPk, wndType == 2)
    if wndType == 1 then
        local _combatType = self:GetWndArg("combatType")--combatType	结构
        local _channel = self:GetWndArg("channel")--channel 频道
        self._atPlayerId = self:GetWndArg("atPlayerId")--私聊时传目标
        self._channel = _channel
        self._combatType = _combatType
        local playerId = gModelPlayer:GetPlayerId()
        gModelPlayer:OnGetFormationShowReq(playerId, _combatType)
    elseif wndType == UISpreadCombatPop.TYPE_WND_3 then
        self:RefreshWndType3()
    else
        local reportInfo = self:GetWndArg("reportInfo")--战报
        local reportId = reportInfo.reportId
        local playerId = reportInfo.playerId
        self:SetWndVisible(false)
        local reqInfo = {
            reportId = reportId,
            serverId = reportInfo.serverId,
            callback = function(reportTable)
                if self:IsWndClosed() then
                    return
                end
                self:SetWndVisible(true)

                self:MagShaderData(reportTable, reportId,playerId)
            end,
            failCall = function()
                GF.CloseWndByName("UISpreadCombatPop")
            end
        }
        self:GetReportTable(reqInfo)
    end
end

function UISpreadCombatPop:GetBattlePrepareData()
    local heroData = {}
    heroData.power = tonumber(self._reportTable.power)
    local formationRefId = tonumber(self._reportTable.formation.formationRefId)
    heroData.matrixRefId = formationRefId
    heroData.combatTreasures = self._draconicList
    heroData.playerInfo = { _grade = 200 }
    local prefabNameList = {}
    for k, v in ipairs(self._heroList) do
        local grid = v.grid
        local refId = v.refId
        if refId then
            local pos = gModelFormation:GetIndexByPos(formationRefId, grid)
            local star = v.star
            local skin = v.skin
            local prefabName, needFlip = gModelHero:GetHeroDisplay(refId, star, skin, true, v.form)

            --if skin and skin > 0 then
            --	local effRef = gModelHero:GetShowEffectById(skin)
            --	prefabName = effRef.prefabName
            --else
            --	prefabName = gModelHero:GetHeroPrefabNameByRefId(refId, star)
            --end
            local bottomImg = gModelHero:GetHeroBottomImgByRefId(refId)
            local race = gModelHero:GetHeroRace(refId)
            local data = {
                prefabName = prefabName,
                bottomImg = bottomImg,
                refId = refId,
                lv = v.lv,
                pos = pos,
                race = race,
                isResonance = v.isResonance,
                skin = v.skin,
                needFlip = needFlip,
            }
            prefabNameList[pos] = data
        end
    end
    heroData.prefabNameList = prefabNameList
    return heroData
end

function UISpreadCombatPop:InitMessage()
    self:WndNetMsgRecv(LProtoIds.GetFormationShowResp, function(...)
        self:OnGetFormationShowResp(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ChatShareResp, function(...)
        self:OnClickWndClose()
    end)
end

function UISpreadCombatPop:OnClickShare()
    local list = self._heroList or {}
    if #list <= 0 then
        GF.ShowMessage(ccClientText(23408))
        return
    end
    --阵容类型|阵容下标
    local combatType = self._combatType
    local combatName = ccLngText(GameTable.BattleGameRef[combatType].name)
    local _shareData = combatType .. ";" .. combatType .. "|" .. 0
    gModelChat:OnChatShareReq(self._channel, ModelChat.CHATSHARE_23, _shareData, self._atPlayerId)
end

function UISpreadCombatPop:InitSkillList(list, onDrawFunc)
    local skillList = self._skillUIList
    if (skillList) then
        skillList:RefreshList(list)
    else
        skillList = self:GetUIScroll("skillList")
        skillList:Create(self.mSkillScroll, list, function(...)
            onDrawFunc(...)
        end)
        self._skillUIList = skillList
    end
end

function UISpreadCombatPop:MagShaderData(reportTable, reportId,playerId)
    local formation = reportTable.formation
    local grids = formation.grids
    local playerId = formation.playerId or playerId
    local serverId = tonumber(reportTable.serverId)
    local url = gModelChat:GetReportUrl(serverId, reportId)
    local heros = reportTable.heros
    local _grids = {}
    for i, v in ipairs(grids) do
        _grids[tonumber(v.index)] = v.id
    end
    local _heroList = {}
    for i = 1, LCombatFormationConst.GRID_MAX do
        local hero = {}
        local key = _grids[i]
        if key then
            local heroData = heros[key]
            hero = {
                id = heroData.id,
                refId = tonumber(heroData.refId),
                star = tonumber(heroData.star),
                lv = tonumber(heroData.level),
                skin = tonumber(heroData.skinId),
                grade = tonumber(heroData.grade),
                fightPower = tonumber(heroData.power),
                isResonance = heroData.resonance == "true" and 1 or 0,
                playerId = playerId,
                serverId = serverId,
                url = url,
                heroType = 5
            }
        end
        hero.grid = i
        table.insert(_heroList, hero)
    end

    local _skillList = {}
    local skillRefIds = formation.skillRefIds
    if skillRefIds then
        local combatTreasureInfo = reportTable.combatTreasureInfo or {}
        local treasureInfos = combatTreasureInfo.draconicInfos or {}
        local _skillKs = {}
        for i, v in ipairs(skillRefIds) do
            _skillKs[v] = i
        end

        for i, v in ipairs(treasureInfos) do
            local skillRefId = tonumber(v.treasureSuitRefId)
            local index = _skillKs[skillRefId]
            if index and skillRefId > 0 then
                local data = {}
                data.index = index
                local ref = GameTable.TreasureSuitRankRef[skillRefId]
                data.skillRefId = ref.skillId
                local exhibitionInfo = v.exhibitionInfo
                if exhibitionInfo then
                    local articles = {}
                    for i, v in ipairs(exhibitionInfo.articles) do
                        table.insert(articles, {
                            rankRefId = tonumber(v.rankRefId),
                            refId = tonumber(v.refId),
                            strengRefId = tonumber(v.strengRefId),
                        })
                    end
                    local info = {
                        articles = articles,
                        refId = tonumber(exhibitionInfo.refId),
                        skillRefId = tonumber(exhibitionInfo.skillRefId)
                    }
                    data.info = info
                    table.insert(_skillList, data)
                end
            end
        end
        if #_skillList > 1 then
            table.sort(_skillList, function(a, b)
                return a.index < b.index
            end)
        end
    end

    local _playerName = reportTable.formationName
    self._heroList = _heroList
    local _skillListK = {}
    for i, v in ipairs(_skillList) do
        _skillListK[v.index] = v
    end
    local nilList = {
        index = 1,
        info = {
            articles = {},
            refId = 0,
            skillRefId = 0,
        },
        skillRefId = 0
    }
    local _skillListI = {}
    for i = 1, 4 do
        local skillData = _skillListK[i]
        local data = skillData
        if not skillData then
            local nilData = table.clone(nilList)
            nilData.index = i
            data = nilData
        end
        table.insert(_skillListI, data)
    end

    self._skillList = _skillListI
    self._fileUrl = url
    self._playerName = _playerName
    self._reportTable = reportTable


    -- 龙纹技能
    local map = {}
    local combatTreasureInfo = reportTable.combatTreasureInfo or {}
    local draconicInfos = combatTreasureInfo.draconicInfos or {}
    for i, v in ipairs(draconicInfos) do
        map[tonumber(v.slot)] = v
    end

    local list = {}
    for i = 1, 4 do
        local tab = {}
        if map[i] then
            tab.draconicRefId = tonumber(map[i].draconicRefId)
            tab.draconicSuitRefId = tonumber(map[i].draconicSuitRefId)
            tab.skillRefId = tonumber(map[i].skillRefId)
            tab.slot = tonumber(map[i].slot)
        end
        list[i] = tab
    end
    self._draconicList = list


    -- 【C宠物系统】删掉宠物系统相关
    -- self._pets = reportTable.pets
    -- self._petDetailInfoList = self:GetPetDetailInfoList(reportTable.petDetailInfoList)
    self:RefreshData()
end

function UISpreadCombatPop:OnGetFormationShowResp(pb)
    local heroData = pb.heroData
    local combatData = gModelGeneral:SetCombatHeroData(heroData)
    local _heros = combatData._heros
    local _grids = combatData._grids
    local _heroKs = {}
    for i, v in ipairs(_grids) do
        _heroKs[v] = _heros[i]
    end
    local _heroList = {}
    --for i = 1, 9 do
    --	local hero = _heroKs[i] or {}
    --	hero.grid = i
    --	table.insert(_heroList,hero)
    --end

    for i = 1, LCombatFormationConst.GRID_MAX do
        local hero = _heroKs[i] or {}
        hero.grid = i
        table.insert(_heroList, hero)
    end

    local _skillInfo = combatData._skillInfo

    self._heroList = _heroList
    self._skillList = _skillInfo
    self._draconicList = combatData._draconicList
    --self._petFights = combatData:GetPetFights()
    --self._petHelps = combatData:GetPetHelps()
    -- self._petFights = gModelPetSpace:GetStructPetDetailInfoList(pb.petFights)
    -- self._petHelps = gModelPetSpace:GetStructPetDetailInfoList(pb.petHelps)
    self:RefreshData()
end

-- function UISpreadCombatPop:OnDrawFairHeroCell(list,item,itemdata,itempos)
-- 	local heroTrans = self:FindWndTrans(item,"Image")
-- 	local hasId = itemdata.hasId
-- 	if not hasId then return end

-- 	local id = itemdata.id
-- 	local refId = tonumber(id)
-- 	local ref = gModelFairCompete:GetFairCompeteHeroRefByRefId(refId)
-- 	if not ref then return end

-- 	local InstanceID = item:GetInstanceID()
-- 	local baseClass = self:GetCommonIcon(InstanceID)
-- 	baseClass:Create(heroTrans)
-- 	baseClass:SetHeroIcon(ref.type)
-- 	baseClass:SetNoShowLv(true)
-- 	baseClass:DoApply()
-- end

function UISpreadCombatPop:OnDrawFairSkillCell(list, item, itemdata, itempos)
    -- local root = self:FindWndTrans(item,"Root")
    -- local Icon = self:FindWndTrans(root,"Icon")
    -- local isEmpty = itemdata.isEmpty
    -- if isEmpty then
    -- 	CS.ShowObject(Icon,false)
    -- 	return
    -- end

    -- local skillRefId = itemdata.skillRefId
    -- local ref = gModelTreasure:GetTreasureSuitRankRefByRefId(skillRefId)
    -- local iconPath = gModelTreasure:GetTreasureIconByRefId(ref.type,skillRefId)
    -- self:SetWndEasyImage(Icon, iconPath,function()
    -- 	CS.ShowObject(Icon,true)
    -- end)
    local skillRefId = itemdata.skillRefId
    --local ref = gModelTreasure:GetTreasureSuitRankRefByRefId(skillRefId)
    --local iconPath = gModelTreasure:GetTreasureIconByRefId(ref.type,skillRefId)
    --self:SetWndEasyImage(Icon, iconPath,function()
    --	CS.ShowObject(Icon,true)
    --end)
end

function UISpreadCombatPop:InitItemList()
    local heroListA = self._heroList or {}
    local gridMax = LCombatFormationConst.GRID_MAX
    for i = 1, gridMax do
        local obj1 = LxUnity.InstantObject(self.mItemTemplate.gameObject)
        obj1:SetActive(true)
        local trans1 = obj1.transform
        trans1:SetParent(self["mLeftPos" .. i], false)
        self:HeroListItem(nil, trans1, heroListA[i] or {})
    end
end

function UISpreadCombatPop:SkillListItem(list, item, itemdata, itempos)
    if not next(itemdata) then
        return
    end

    local root = self:FindWndTrans(item, "Root")
    local Icon = self:FindWndTrans(root, "Icon")
    local refId = itemdata.draconicSuitRefId
    local ref = GameTable.DraconicRef[refId]

    if refId == 0 then
        return
    end

    local dragonRef = GameTable.DraconicSuitRankRef[refId]

    if nil == ref then


        if nil == dragonRef then
            return
        end
        ref = GameTable.DraconicRef[dragonRef.type]
    end

    self:SetWndEasyImage(Icon, ref.skillIcon, function()
        CS.ShowObject(Icon, true)
    end)

    self:SetWndClick(Icon, function()
        if itemdata.skillRefId == 0 or nil == itemdata.skillRefId then
            return
        end

        local ref, upRef = gModelDraconic:GetDraconicRefBySkillId(itemdata.skillRefId)

        GF.OpenWnd("UIDraconicUpStar", { refId = upRef.type, starNum = upRef.rankNow, tips = true })
    end)
end

function UISpreadCombatPop:InitHeroList(list, onDrawFunc)
    local heroList = self._heroUIList
    if (heroList) then
        heroList:RefreshList(list)
    else
        heroList = self:GetUIScroll("heroList")
        heroList:Create(self.mHeroScroll, list, function(...)
            onDrawFunc(...)
        end)
        self._heroUIList = heroList
    end
end

function UISpreadCombatPop:RefreshWndType3()
    local reportInfo = self:GetWndArg("reportInfo")
    if not reportInfo then
        return
    end
    local grids = JSON.decode(reportInfo.grids)

    local heroMap = {}
    for i, v in ipairs(grids) do
        heroMap[v.grid] = {
            id = v.id,
            hasId = true,
        }
    end
    local heroList = {}
    for i = 1, 9 do
        local hero = heroMap[i] or {}
        hero.grid = i
        table.insert(heroList, hero)
    end
    -- self:InitHeroList(heroList,function(...)
    -- 	self:OnDrawFairHeroCell(...)
    -- end)


    local showTreasureDiv = true
    -- local combatType = tonumber(reportInfo.formationType) or tonumber(reportInfo.combatType)
    -- if combatType and combatType == LCombatTypeConst.COMBAT_TYPE_33 then
    -- 	showTreasureDiv = not gModelFormation:CheckTreasureNotUse(combatType)
    -- end
    CS.ShowObject(self.mTreasureDiv, showTreasureDiv)
    if not showTreasureDiv then
        return
    end
    local treasureIdList = JSON.decode(reportInfo.treasureIdList)
    local skillList = {}
    for i = 1, 4 do
        local isEmpty = false
        local skillRefId = treasureIdList[i]
        if not skillRefId or skillRefId <= 0 then
            isEmpty = true
        end
        table.insert(skillList, {
            skillRefId = skillRefId,
            isEmpty = isEmpty,
        })
    end
    self:InitSkillList(skillList, function(...)
        --self:SkillListItem(...)
        self:OnDrawFairSkillCell(...)
    end)
end

function UISpreadCombatPop:OnClickWndClose()
    local func = self._callFunc
    if func then
        func()
    end
    self:WndClose()
end

function UISpreadCombatPop:HeroListItem(list, item, itemdata, itempos)
    local id = itemdata.id
    if (not id) then
        return
    end
    local heroTrans = self:FindWndTrans(item, "Image")
    local herodata = {
        id = itemdata.id,
        refId = itemdata.refId,
        star = itemdata.star,
        level = itemdata.lv,
        skin = itemdata.skin,
        grade = itemdata.grade,
        fightPower = itemdata.fightPower,
        isResonance = itemdata.isResonance,
        other = itemdata.url,
        heroType = itemdata.heroType or 1,
        form = itemdata.form,
    }
    local InstanceID = item:GetInstanceID()
    local baseClass = self._commonIconList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        self._commonIconList[InstanceID] = baseClass
        baseClass:Create(heroTrans)
    end
    baseClass:SetHeroDataSet(herodata)
    baseClass:DoApply()

    self:SetWndClick(heroTrans, function()
        gModelHero:ReqShowHeroTip(itemdata.playerId, herodata, nil, nil, nil, itemdata.serverId)
    end)
end

function UISpreadCombatPop:RefreshData()
    -- local heroList = self._heroList or {}
    -- self:InitHeroList(heroList,function(...)
    -- 	self:HeroListItem(...)
    -- end)
    self:InitItemList()

    local skillList = self._draconicList or {}
    local showList = {}

    local skillListTable = false

    if #skillList > 0 then
        local itemData = skillList[1]

        local itemType = type(itemData)
        if "table" == itemType then
            skillListTable = true
        end
    end

    if skillListTable then
        self:InitSkillList(skillList, function(...)
            self:SkillListItem(...)
        end)

    else

        for k, v in ipairs(skillList) do


            local itemdata = {}
            itemdata.draconicSuitRefId = v
            if v == 0 then
            else
                local dragonRef = GameTable.DraconicSuitRankRef[v]
                itemdata.skillRefId = dragonRef.skillId
                itemdata.draconicRefId = dragonRef.type
            end
            table.insert(showList, itemdata)
        end
        self:InitSkillList(showList, function(...)
            self:SkillListItem(...)
        end)

        --
    end

    --【C宠物系统】删掉宠物系统相关
    -- self:SetPetDiv()
end
-----------------
---    -- 【C宠物系统】删掉宠物系统相关
-- function UISpreadCombatPop:IsPetPartOpen()
-- 	local isOpen = gModelFunctionOpen:CheckIsShow(36003000)
-- 	return isOpen
-- end
-- function UISpreadCombatPop:SetPetDiv()
-- 	--local isOpenPet = self:IsPetPartOpen()
-- 	--CS.ShowObject(self.mPetDiv,isOpenPet)
-- 	--if(not isOpenPet)then
-- 	--	return
-- 	--end
-- 	CS.ShowObject(self.mPetDiv,true)
-- 	self:InitPetList()
-- end

-- function UISpreadCombatPop:InitPetList()
-- 	local _petDetailInfoList = self._petDetailInfoList
-- 	local petFights = self._petFights or {}
-- 	local petHelps = self._petHelps or {}
-- 	local petUIList = self._petUIList
-- 	local list = {}
-- 	for i = 1, 4 do
-- 		local petList
-- 		local index
-- 		local petDetailInfo
-- 		if(_petDetailInfoList and #_petDetailInfoList>0)then
-- 			petList = _petDetailInfoList
-- 			index = i
-- 			petDetailInfo = petList[index] or nil
-- 		else
-- 			petList = i<3 and petFights or petHelps
-- 			index = i<3 and i or i-2
-- 			petDetailInfo = petList[index] or nil
-- 		end
-- 		local data = petDetailInfo and {petDetailInfo = petDetailInfo} or {isEmpty = true}
-- 		table.insert(list,data)
-- 	end
-- 	if(petUIList)then
-- 		petUIList:RefreshList(list)
-- 	else
-- 		petUIList = self:GetUIScroll("petList")
-- 		petUIList:Create(self.mPetScroll,list,function (...)
-- 			self:OnDrawPetList(...)
-- 		end)
-- 		self._petUIList = petUIList
-- 	end
-- end
-- function UISpreadCombatPop:OnDrawPetList(list, item, itemdata, itempos)
-- 	local root = self:FindWndTrans(item,"Root")
-- 	local emptyIcon = self:FindWndTrans(root,"EmptyIcon")
-- 	local iconRoot = self:FindWndTrans(root,"IconRoot")
-- 	local isEmpty = itemdata.isEmpty
-- 	local bgPath
-- 	CS.ShowObject(emptyIcon,isEmpty)
-- 	CS.ShowObject(iconRoot,not isEmpty)
-- 	if isEmpty then
-- 		bgPath = "public_item_bg_lock"
-- 		self:SetWndEasyImage(emptyIcon,bgPath)
-- 		return
-- 	end
-- 	local petData = itemdata.petDetailInfo
-- 	if(petData)then
-- 		local InstanceID = iconRoot:GetInstanceID()
-- 		local baseClass = self._uiCommonList[InstanceID]
-- 		if not baseClass then
-- 			baseClass = CommonIcon:New()
-- 			self._uiCommonList[InstanceID] = baseClass
-- 			baseClass:Create(iconRoot)
-- 		end
-- 		baseClass:SetRewardDetailItem(petData)
-- 		baseClass:SetShowDissimilation(petData.changeStatus~=0)
-- 		baseClass:SetMainFormationStatus(false)
-- 		baseClass:SetShowSelectImg(false)
-- 		baseClass:DoApply()
-- 		self:SetWndClick(iconRoot, function()
-- 			local shareData = not petData.id and petData or nil
-- 			local refId = not petData.id and petData.refId or nil
-- 			GF.OpenWnd("WndPetSharePop",{id = petData.id,refId = refId,shareData = shareData,isChatWnd = true})
-- 		end)
-- 	end
-- end
-- function UISpreadCombatPop:GetPetDetailInfoList(petDetailInfoList)
-- 	if(not petDetailInfoList)then
-- 		return
-- 	end
-- 	local list = {}
-- 	for i, v in ipairs(petDetailInfoList) do
-- 		local petDetailInfo = gModelPetSpace:GetPetDetailInfo(v)
-- 		petDetailInfo.id = nil
-- 		table.insert(list,petDetailInfo)
-- 	end
-- 	return list
-- end
-------------------------------
------------------------------------------------------------------
return UISpreadCombatPop