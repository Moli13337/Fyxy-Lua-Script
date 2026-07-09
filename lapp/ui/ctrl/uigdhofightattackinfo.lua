---
--- Created by Administrator.
--- DateTime: 2024/6/20 18:10:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightAttackInfo:LWnd
local UIGdHoFightAttackInfo = LxWndClass("UIGdHoFightAttackInfo", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightAttackInfo:UIGdHoFightAttackInfo()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightAttackInfo:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightAttackInfo:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightAttackInfo:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._setSelectDivClickTick = 0
    self._curSelectIndex = 0
    self._showHero = true

    self:InitText()
    self:InitEvent()
    self:InitPara()
    self:OnUpdateBtnState()

    self:OpenReq()
end

--选择列表的设置
function UIGdHoFightAttackInfo:SetSelectDiv()
    for i = 1, 3 do
        local tranKey = "Select_" .. i
        local root = CS.FindTrans(self.mSelectDiv, tranKey)

        local sorce = gModelGuildHolyBattle:GetStarIntegral(self._playerShrongholdData.info.refId, i)
        local percent = gModelGuildHolyBattle:GetDifficulty(i)

        local des1 = CS.FindTrans(root, "Des_1")
        local des2 = CS.FindTrans(root, "Des_2")
        local selectTag = CS.FindTrans(root, "SelectTag")

        if not self._SelectDivSelectTag then
            self._SelectDivSelectTag = {}
        end

        self._SelectDivSelectTag[i] = selectTag

        if percent then
            percent = (1 + percent) * 100
        else
            percent = 100
        end

        local str = string.replace(ccClientText(44028), percent)
        self:SetWndText(des1, str)
        str = string.replace(ccClientText(44029), sorce)
        self:SetWndText(des2, str)

        if i==1 then
            self._curSelectIndex=1
            local oldtranKey = "Select_" .. self._curSelectIndex  .. "/SelectTag"
            local oldtran = CS.FindTrans(self.mSelectDiv, oldtranKey)
            CS.ShowObject(oldtran, true)
            self:SelectEffect(root)
        end


        if self._setSelectDivClickTick <= 3 then
            self._setSelectDivClickTick = self._setSelectDivClickTick + 1
            self:SetWndClick(root, function()
                if self._curSelectIndex > 0 then
                    local oldtranKey = "Select_" .. self._curSelectIndex .. "/SelectTag"
                    local oldtran = CS.FindTrans(self.mSelectDiv, oldtranKey)
                    CS.ShowObject(oldtran, false)

                    local root = CS.FindTrans(self.mSelectDiv, "Select_" .. self._curSelectIndex)
                    if self:FindWndEffectByKey(root:GetInstanceID()) then
                        self:DestroyWndEffectByKey(root:GetInstanceID())
                    end
                end

                self._curSelectIndex = i

                local newtran = CS.FindTrans(root, "SelectTag")
                CS.ShowObject(newtran, true)
                self:SelectEffect(root)

                self:OnSelectDivClick(i)
            end)
        end

        --小于当前星星数量的 进行隐藏
        if self._stage == 5 then

        else
            CS.ShowObject(root, i <= self._para.itemData.star)
        end
    end
end

function UIGdHoFightAttackInfo:InitText()
    self:SetWndText(self.mTitle, ccClientText(44022))  --[44022] [敵方防守成員]
    self:SetWndText(self.mRewardTitle, ccClientText(44023))  --[44023] [獎勵預覽]
    -- self:SetWndText(self.mInfo_Title_1, ccClientText(44024))  --[44024] [防守陣容]
    self:SetWndText(self.mInfo_Title_2, ccClientText(44025))  --[44025] [難度選擇]

    self:SetWndText(self.mSweepBtnText, ccClientText(44067))  --[44067] [扫荡]
    self:SetWndTabText(self.mBtnFormation,ccClientText(21810))
    self:SetWndTabText(self.mBtnDraconic,ccClientText(41002))
end

function UIGdHoFightAttackInfo:SetRewardItem()
    local rewardItems = gModelGuildHolyBattle:GetShrongholdReward(self._playerShrongholdData.info.refId)

    local uiList = self._rewardList

    if not uiList then
        uiList = self:GetUIScroll(self.mRewarItemList:GetInstanceID())
        uiList:Create(self.mRewarItemList, rewardItems, function(...)
            self:CreateRewardList(...)
        end, UIItemList.SUPER)

        self._rewardList = uiList
    else
        uiList:RefreshList(rewardItems)
    end
    uiList:EnableScroll(true, true)
end

--设置攻击状态
function UIGdHoFightAttackInfo:SetAttackState()
    --如果是结算阶段
    self.mBG.sizeDelta = Vector2.New(596,815.5)
    CS.ShowObject(self.mInfoDiv,true)
    CS.ShowObject(self.mSweepBtn, false)
    if self._stage == 5 then
        CS.ShowObject(self.mSelectDiv, true)
    else
        local isCanAttack = self._para.itemData.star > 0

        if isCanAttack then
            --判断下其他部分
            isCanAttack = self._stage == 3
        end

        local tempStr = isCanAttack and ccClientText(44030) or ccClientText(44031)

        if not (self._stage == 3) then
            CS.ShowObject(self.mSelectDiv, true)
            CS.ShowObject(self.mSweepBtn, false)
        else
            CS.ShowObject(self.mSelectDiv, isCanAttack)
            CS.ShowObject(self.mInfoDiv, isCanAttack)
            CS.ShowObject(self.mSweepBtn, not isCanAttack)
            if not isCanAttack then
                tempStr = ccClientText(44079)
                self.mBG.sizeDelta = Vector2.New(596,450.5)
            end

        end
        local tempStr_2 = string.replace(ccClientText(44026), tempStr)
        self:SetWndText(self.mAttackState, tempStr_2)

    end
end

function UIGdHoFightAttackInfo:SelectEffect(root)
    local instanceId = root:GetInstanceID()
    self:CreateWndEffect(root,"fx_ui_shengqizhizhan_nandu1",instanceId,100,false,false,nil,nil,nil,nil,nil,nil,1)
end

function UIGdHoFightAttackInfo:OpenReq()
    local playerId = self._para.itemData.playerId
    gModelGuildHolyBattle:SendGuildBattleViewStrongholdReq(playerId)
end

function UIGdHoFightAttackInfo:InitPara()
    self._para = self:GetWndArg("para")

    --获取状态 设置
    self._stage = gModelGuildHolyBattle:GetStage()

    self:SetSpine()
    self:SetAttackState()
end

function UIGdHoFightAttackInfo:OnUpdateBtnState()
    CS.ShowObject(self.mHeroItemList,self._showHero)
    CS.ShowObject(self.mBaowuListScroll,not self._showHero)
    self:SetWndTabStatus(self.mBtnFormation,self._showHero and 0 or 1)
    self:SetWndTabStatus(self.mBtnDraconic,self._showHero and 1 or 0)
end

--设置英雄的列表
function UIGdHoFightAttackInfo:SetHero()
    if not self._showHero then return end
    local heros
    if self._playerShrongholdData.monsterRefId > 0 then
        heros = gModelGuildHolyBattle:GetMonsterList(self._playerShrongholdData.monsterRefId)
    else
        local formation = self._playerShrongholdData.formation
        heros = formation:GetHeros()
    end

    local uiList = self._heroList
    if not uiList then
        uiList = self:GetUIScroll(self.mHeroItemList:GetInstanceID())
        uiList:Create(self.mHeroItemList, heros, function(...)
            self:CreateHeroList(...)
        end, UIItemList.SUPER)

        self._heroList = uiList
    else
        uiList:RefreshList(heros)
    end

    uiList:EnableScroll(true, true)
end

function UIGdHoFightAttackInfo:CreateRewardList(list, item, itemdata, itempos)
    local root = CS.FindTrans(item, "ItemRoot")

    local InstanceID = root:GetInstanceID()

    local uiCommonList = self._uiCommonList
    if not uiCommonList then
        uiCommonList = {}
    end

    local baseClass = uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        uiCommonList[InstanceID] = baseClass
        baseClass:Create(root)
    end

    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    self:SetWndClick(root, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    item.localScale = Vector3.one * 0.8
end

function UIGdHoFightAttackInfo:CreateHeroList(list, item, itemdata, itempos)
    local root = CS.FindTrans(item, "HeroRoot")

    local InstanceID = root:GetInstanceID()

    local uiCommonList = self._uiHeroCommonList
    if not uiCommonList then
        uiCommonList = {}
    end
    --
    local baseClass = uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        uiCommonList[InstanceID] = baseClass
        baseClass:Create(root)
    end
    local heroData = {
        index = itempos,
        id = itemdata.id,
        refId = itemdata.refId,
        star = itemdata.star,
        level = itemdata.level,
        isResonance = itemdata.isResonance,
        skin = itemdata.skin
    }

    baseClass:SetHeroDataSet(heroData)
    baseClass:DoApply()

    local playerInfo = self._para.itemData
    local serverId = self._para.serverId

    self:SetWndClick(item, function()
        gModelHero:ReqShowHeroTip(playerInfo.playerId, itemdata, nil, nil, nil, serverId)
    end)
    item.localScale = Vector3.one * 0.8
end

function UIGdHoFightAttackInfo:SetSuccesssTimes()
    local str = string.replace(ccClientText(44027), self._playerShrongholdData.defence)
    self:SetWndText(self.mSuccessTimes, str)
end

function UIGdHoFightAttackInfo:OnTreasureCell(list,item,itemdata,itempos)
    local DraconicSkill = self:FindWndTrans(item, "DraconicSkill")

    local param = {
        showName = true,
        showType = true,
        showStar = true,
        upRefId = itemdata.upRef.refId,
    }
    gModelDraconic:DrawSkillItem(self, DraconicSkill, param)

    self:SetWndClick(item, function()
        GF.OpenWnd("UIDraconicUpStar", { refId = itemdata.ref.refId, starNum = itemdata.upRef.rankNow, tips = true})
    end)
end

--uiClick
function UIGdHoFightAttackInfo:OnSelectDivClick(index)
    if not (self._stage == 3) then
        GF.ShowMessage(ccClientText(44059))  --[44059] [非戰鬥階段，無法進行戰鬥]
        return
    end


    --次数  优先判断扫荡的
    local leftTime=gModelGuildHolyBattle:GetTotalCount() - gModelGuildHolyBattle:GetChallengeCount()
    if leftTime<= 0 then
        GF.ShowMessage(ccClientText(12554))
        return
    end

    --判断选择的星星是否足够
    if self._para.itemData.star == 0 then

        local selfGuild = gModelPlayer:GetGuildId()
        local guildId = gModelGuildHolyBattle:GetMatchInfo(selfGuild)
        local playerId = self._para.itemData.playerId

        --扫荡
        GF.OpenWnd("UIOrdinTip", { refId = 100201, func = function()
            gModelGuildHolyBattle:SendGuildBattleSweepReq(playerId, guildId)
        end })

        return
    end

    if index > self._para.itemData.star then
        local showStr = string.replace(ccLngText(44057), self._para.itemData.star, index) --[44057] [當前據點剩餘#a1#星，無法進行#a1#星挑戰]
        GF.ShowMessage(showStr)
        --不够星星
        return
    end



    --跳转到站前的准备
    local extraData
    if self._playerShrongholdData.monsterRefId > 0 then
        extraData = {
            meName = gModelPlayer:GetPlayerName(),
            otherName = self._para.itemData.name,
            mapRefId = gModelBattle:GetCombatPlayCampRefByRefId(LCombatTypeConst.COMBAT_TYPE_44),
            targetId = self._para.itemData.playerId,
            battleRefId = index,
            monsterA = self._playerShrongholdData.monsterRefId,
        }
    else
        extraData = {
            meName = gModelPlayer:GetPlayerName(),
            otherName = self._para.itemData.name,
            isUseCombatHeroData = true,
            combatHeroData = self._playerShrongholdData.formation,
            mapRefId = gModelBattle:GetCombatPlayCampRefByRefId(LCombatTypeConst.COMBAT_TYPE_44),
            targetId = self._para.itemData.playerId,
            battleRefId = index,
            isHavePowerData = true,
            powerData = tonumber(self._para.itemData.power),
        }
    end
    GF.OpenWnd("UIOrdinTip", { refId = 100201, func = function()
        gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TYPE_44, extraData)
    end })

end
--龙纹
function UIGdHoFightAttackInfo:SetDraconicList()
    if self._showHero or not self._playerShrongholdData then return end
    local draconics
    if self._playerShrongholdData.monsterRefId > 0 then--怪物不顯示
        draconics = {}
    else
        local formation = self._playerShrongholdData.formation
        draconics =formation:GetDraconics()
    end
    local dataList = {}
    local DraconicSuitRankRef = GameTable.DraconicSuitRankRef
    local DraconicRef = GameTable.DraconicRef
    for k, v in ipairs(draconics) do
        local upRef = DraconicSuitRankRef[v]
        local ref = DraconicRef[upRef.type]
        dataList[k] = {ref = ref, upRef = upRef}
    end
    -- table.sort(dataList, gModelDraconic.SortDraconicList)

    local uiDraconicList = self._uiDraconicList
    if uiDraconicList then
        uiDraconicList:RefreshList(dataList)
    else
        uiDraconicList = self:GetUIScroll("uiTreasureList")
        self._uiDraconicList = uiDraconicList
        uiDraconicList:Create(self.mBaowuListScroll, dataList, function(...)
            self:OnTreasureCell(...)
        end, UIItemList.WRAP)
    end
end

--region 初始化 --------------------------------------------------------------------------------
function UIGdHoFightAttackInfo:InitEvent()
    --event

    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.StrongholdDataChange, function()
        self:OnStrongholdData()
    end)


    --ui
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mClose, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mSweepBtn, function()
        self:OnSelectDivClick(1)
    end)

    self:SetWndClick(self.mBtnFormation,function()
        self._showHero = not self._showHero
        self:OnUpdateBtnState()
        self:SetHero()
    end)
    self:SetWndClick(self.mBtnDraconic,function()
        self._showHero = not self._showHero
        self:OnUpdateBtnState()
        self:SetDraconicList()
    end)
end


--endregion --------------------------------------------------------------------------------------

--region 页面创建 --------------------------------------------------------------------------------
function UIGdHoFightAttackInfo:SetSpine()
    local heroTran = self:FindWndTrans(self.mHeroDetialRoot, "Hero")
    local instanceId = heroTran:GetInstanceID()
    if not self._heroSpine then
        self._heroSpine = LUIHeroObject:New(self)
        self._heroSpine:Create(heroTran, instanceId, self._para.spineName)
        self._heroSpine:SetScale(1.3)
        self._heroSpine:ShowHero(true)
        self._heroSpine:StartLoad()


    else
        self._heroSpine:ShowHero(true)
        self._heroSpine:StartLoad()
    end

    --星星
    for i = 1, 3 do
        local starRoot = self:FindWndTrans(self.mHeroDetialRoot, "StarRoot")

        local starKey = "Star_" .. i

        local star = self:FindWndTrans(starRoot, starKey)

        if i <= self._para.itemData.star then

            self:SetWndEasyImage(star, "hero_icon_star1")
        else

            self:SetWndEasyImage(star, "guildwar1_star -hui")
        end
    end
    local UIText = self:FindWndTrans(self.mHeroDetialRoot, "UIText")
    self:SetWndText(UIText, self._para.itemData.name)

    --战力
    local PowerText = self:FindWndTrans(self.mHeroDetialRoot, "PowerBg/Power")
    self:SetWndText(PowerText, LUtil.NumberCoversion(self._para.itemData.power))

end

--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
function UIGdHoFightAttackInfo:OnStrongholdData()
    self._playerShrongholdData = gModelGuildHolyBattle:GetShrongholdInfo(self._para.itemData.playerId)
    self:SetSuccesssTimes()
    self:SetRewardItem()
    self:SetHero()
    self:SetSelectDiv()
    self:SetDraconicList()
end

--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIGdHoFightAttackInfo