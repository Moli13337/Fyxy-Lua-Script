---
--- Created by BY.
--- DateTime: 2023/10/26 16:48:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFightSowMonsterPop:LWnd
local UIFightSowMonsterPop = LxWndClass("UIFightSowMonsterPop", LWnd)

UIFightSowMonsterPop.TYPE_MONSTER = 1
UIFightSowMonsterPop.TYPE_PLAYER = 2


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFightSowMonsterPop:UIFightSowMonsterPop()
    self._commonIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFightSowMonsterPop:OnWndClose()
    self:ClearCommonIconList(self._commonIconList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFightSowMonsterPop:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFightSowMonsterPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:SetWndText(self.mCloseTip, ccClientText(17003))
    self:InitEvent()
    self:InitMessage()
    local wndType = self:GetWndArg("wndType") or UIFightSowMonsterPop.TYPE_MONSTER
    if wndType == UIFightSowMonsterPop.TYPE_MONSTER then
        self:ShowTypeMonster()
    else
        self:ShowTypePlayer()
    end
end

function UIFightSowMonsterPop:HeroListItemHero(list, item, itemdata, itempos)
    local id = itemdata.id
    if (not id) then
        return
    end
    local heroTrans = self:FindWndTrans(item, "Image/Root")
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
    }
    self:CreateHeroIconImpl(heroTrans, herodata)

    self:SetWndClick(heroTrans, function()
        gModelHero:ReqShowHeroTip(itemdata.playerId, herodata, nil, nil, nil, itemdata.serverId)
    end)
end

function UIFightSowMonsterPop:OnGetFormationShowResp(pb)
    printInfoN(string.format("playerId %s %s, teamindex %s %s", pb.targetId, self._playerId, pb.teamIndex, self._teamIndex))
    if pb.targetId ~= self._playerId or pb.teamIndex ~= self._teamIndex then
        return
    end

    local power = pb.heroData.power or 0
    power = tonumber(power)
    local powerNum = LUtil.FormatCoversionHurtNumSpriteText(power, nil, nil, 20)
    self:SetWndText(self.mPowerText, powerNum)

    local heroData = pb.heroData
    local combatData = gModelGeneral:SetCombatHeroData(heroData)
    local _heros = combatData._heros
    local _grids = combatData._grids
    local _heroKs = {}
    for i, v in ipairs(_grids) do
        _heroKs[v] = _heros[i]
    end
    local _heroList = {}
    for i = 1, 9 do
        local hero = _heroKs[i] or {}
        hero.grid = i
        table.insert(_heroList, hero)
    end

    local _skillInfo = combatData._skillInfo

    self:CreateUIScrollImpl("heroList", self.mHeroScroll, _heroList, function(...)
        self:HeroListItemHero(...)
    end)

    for i = 1, 4 do
        local item = self:FindWndTrans(self.mSkillScroll, "Root/ItemTemplate" .. i)
        local itemdata = _skillInfo[i] or {}
        self:SkillListItemHero(item, itemdata)
    end


end

--设置技能

function UIFightSowMonsterPop:SetSpine(spineName)
    self:CreateWndSpine(self.mHeroSpine, spineName, spineName, false, function(dpSpine)
        --dpSpine:SetFlipX(-1)
        local dpTrans = dpSpine:GetDisplayTrans()
        dpTrans.anchorMin = Vector2.New(0.5, 0.5)
        dpTrans.anchorMax = Vector2.New(0.5, 0.5)
    end)
end
function UIFightSowMonsterPop:SetHeroShow(heroList)
    for k, itemdata in ipairs(heroList) do
        local tranKey = "Hero_" .. k

        local refId = itemdata.refId
        if (refId > 0) then

            local item = CS.FindTrans(self.mHeroDiv, tranKey)
            local monsterAtrRef = GameTable.MonsterAttrRef[refId]
            local heroTrans = self:FindWndTrans(item, "Root")
            local herodata = {
                isMon = true,
                refId = refId,
                star = monsterAtrRef.starLv,
                level = monsterAtrRef.lv,
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
                GF.ShowMessage(ccClientText(16905))
            end)

            item.localScale = Vector3.one * 0.8
        end
    end
end

function UIFightSowMonsterPop:ShowTypePlayer()
    local data = self:GetWndArg("teamData")
    local teamIndex = data.teamIndex
    local playerId = data.playerId
    local formationType = data.formationType

    self._teamIndex = teamIndex
    self._playerId = playerId
    self._formationType = formationType

    gModelPlayer:OnGetFormationShowReq(playerId, formationType, teamIndex)

    local herodata = self:GetWndArg("herodata")
    local spineName = gModelHero:GetHeroDisplay(herodata.refId, herodata.star, herodata.skin)
    self:SetSpine(spineName)
end

function UIFightSowMonsterPop:ShowTypeMonster()
    --self:SetWndText(self.mNameText,ccClientText(22312))

    local monsterFormationId = self:GetWndArg("monsterFormationId")
    gModelFormation:OnMonsterPowerReq({ monsterFormationId }, nil, nil, ModelFormation.REQ_INDEX_TYPE_2)
    local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(monsterFormationId)
    local showHeroId = 0
    local monsterIndex = 0
    local list = {}
    local gridMax = LCombatFormationConst.GRID_MAX
    for i = 1, gridMax do
        local monsterId = monsterFormationRef["monster" .. i]
        table.insert(list, { refId = monsterId })
        if monsterId > 0 then
            monsterIndex = monsterIndex + 1
            if monsterIndex <= 3 then
                showHeroId = monsterId
            end
        end
    end

    --这里解析了 那么就在这里处理英雄显示吧


    self:SetHeroShow(list)

    --local heroList = self._heroUIList
    --if(heroList)then
    --	heroList:RefreshList(list)
    --else
    --	heroList = self:GetUIScroll("heroList")
    --	heroList:Create(self.mHeroScroll,list,function (...) self:HeroListItem(...) end)
    --	self._heroUIList = heroList
    --end


    local dicInfo = string.split(monsterFormationRef.draconicList, "|")
    local dicList = { }
    for _, v in ipairs(dicInfo or {}) do
        --local s = string.split(v, "=")
        --dicList[tonumber(s[1])] = tonumber(s[2])

        table.insert(dicList, checknumber(v))
    end

    --设置龙纹技能
    local DraconicSuitRankRef = GameTable.DraconicSuitRankRef
    local DraconicRef = GameTable.DraconicRef
    for i = 1, 4 do
        local data = { ref = nil, upRef = nil }
        if dicList[i] and dicList[i] > 0 then
            local upRef = DraconicSuitRankRef[dicList[i]]
            local ref = DraconicRef[upRef.type]

            data = { ref = ref, upRef = upRef }
        end

        local root = self:FindWndTrans(self.mSkillDiv, "Skill_" .. i)
        self:SetDicIcon(root, data)
    end

    if showHeroId <= 0 then
        return
    end

    local showMaxPower = self:GetWndArg("showMaxPower")
    local monsterAtrRef = nil
    if showMaxPower then
        monsterAtrRef = gModelHero:GetMaxPowerMonsterAttrRef(monsterFormationId)
    else
        monsterAtrRef = GameTable.MonsterAttrRef[showHeroId]
    end

    local heroEffectRef = GameTable.CharacterEffectRef[monsterAtrRef.effectId]
    self:SetSpine(heroEffectRef.prefabName)
end

function UIFightSowMonsterPop:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end)
end

function UIFightSowMonsterPop:HeroListItem(list, item, itemdata, itempos)
    local refId = itemdata.refId
    if (refId <= 0) then
        return
    end
    local monsterAtrRef = GameTable.MonsterAttrRef[refId]
    local heroTrans = self:FindWndTrans(item, "Image/Root")
    local herodata = {
        isMon = true,
        refId = refId,
        star = monsterAtrRef.starLv,
        level = monsterAtrRef.lv,
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
        GF.ShowMessage(ccClientText(16905))
    end)
end

function UIFightSowMonsterPop:InitMessage()
    self:WndNetMsgRecv(LProtoIds.MonsterPowerResp, function(pb)
        local reqIndex = pb.reqIndex
        if reqIndex ~= ModelFormation.REQ_INDEX_TYPE_2 then
            return
        end
        local powerData = pb.powerData
        local data = powerData[1]
        --local powerNum = LUtil.FormatCoversionHurtNumSpriteText(data.power, nil, nil, 20)

        local powerNum = LUtil.PowerNumberCoversion(data.power)
        --self:SetWndText(self.mPowerText,powerNum)
        self:SetWndText(self.mPowerNum, powerNum)
    end)

    self:WndNetMsgRecv(LProtoIds.GetFormationShowResp, function(...)
        self:OnGetFormationShowResp(...)
    end)
end

function UIFightSowMonsterPop:SetDicIcon(root, data)
    if data == nil then
        return
    end

    local itemdata = data
    if itemdata.ref == nil then
        return
    end

    local icon = self:FindWndTrans(root, "Icon")
    CS.ShowObject(icon, itemdata.ref ~= nil)
    self:SetWndEasyImage(icon, itemdata.ref.skillIcon)
    self:SetWndClick(root, function()
        if itemdata.ref then
            GF.OpenWnd("UIDraconicUpStar", { refId = itemdata.ref.refId, starNum = itemdata.upRef.rankNow, tips = true })
        end
    end)


end

function UIFightSowMonsterPop:SkillListItem(item, itemdata)
    if not itemdata then
        return
    end
    local skillId = itemdata.skillId
    if not skillId or skillId <= 0 then
        return
    end
    local root = self:FindWndTrans(item, "Root")
    local Icon = self:FindWndTrans(root, "Icon")
    -- local info = gModelTreasure:GetSkillInfo(skillId)
    -- if info then
    -- 	local iconPath = gModelTreasure:GetTreasureIconByRefId(info.refId, itemdata.exhibitionInfo and itemdata.exhibitionInfo.skin or nil)
    -- 	self:SetWndEasyImage(Icon,iconPath,function ()
    -- 		CS.ShowObject(Icon,true)
    -- 	end)
    -- end
    self:SetWndClick(Icon, function()
        GF.ShowMessage(ccClientText(16905))
    end)
end

function UIFightSowMonsterPop:SkillListItemHero(item, itemdata, itempos)
    if not itemdata.info then
        return
    end
    local root = self:FindWndTrans(item, "Root")
    local Icon = self:FindWndTrans(root, "Icon")
    local refId = itemdata.info.refId
    local ref = GameTable.TreasureRef[refId]
    if ref then
        self:SetWndEasyImage(Icon, ref.icon, function()
            CS.ShowObject(Icon, true)
        end)
    end
    self:SetWndClick(Icon, function()

        gModelGeneral:ShowTacticTips(refId)
        --gModelGeneral:OpenOnlyTreasureTip({treasureData = itemdata.info})
    end)
end

------------------------------------------------------------------
return UIFightSowMonsterPop


