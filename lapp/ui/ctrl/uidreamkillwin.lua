---
--- Created by Administrator.
--- DateTime: 2024/12/16 17:23:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDreamKillWin:LWnd
local UIDreamKillWin = LxWndClass("UIDreamKillWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDreamKillWin:UIDreamKillWin()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDreamKillWin:OnWndClose()

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDreamKillWin:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDreamKillWin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitStaticText()
    self:InitEvent()
    self:InitMessage()
    self:InitData()
end

function UIDreamKillWin:BossListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local img = self:FindWndTrans(root, "Img")
    local mask = self:FindWndTrans(root, "Mask")
    local sel = self:FindWndTrans(root, "Sel")
    local nameText = self:FindWndTrans(root, "NameText")
    local timeText = self:FindWndTrans(root, "TimeText")
    if not self._bossSelList then
        self._bossSelList = {}
    end
    self._bossSelList[itemdata.refId] = sel
    --页签
    self:SetWndEasyImage(img, itemdata.icon, nil, true)
    --时间
    --local openDay = string.split(itemdata.openDay, ";")
    local timeStr = ""
    local openDayStr = ""
    --for i, v in ipairs(openDay) do
    --    local dayStr = v
    --
    --    if not string.isempty(timeStr) then
    --        timeStr = timeStr .. "/" .. dayStr
    --    else
    --        timeStr = dayStr
    --    end
    --end
    openDayStr = string.replace(ccClientText(12150),gModelCrusadeAgainst:GetOpenDayStr(itemdata.openDay))
    --timeStr = string.format(ccClientText(32321), openDayStr)

    self:SetWndText(timeText, openDayStr)

    --选中框
    CS.ShowObject(sel, self._initBossIRefId == itemdata.refId)

    --遮罩
    local isOpent = gModelCrusadeAgainst:CheckIsOpen(itemdata.openDay)
    CS.ShowObject(mask, not isOpent)

    --点击方法
    self:SetWndClick(root, function()
        if not isOpent then
            local openDayStr = string.replace(ccClientText(12159),gModelCrusadeAgainst:GetOpenDayStr(itemdata.openDay),ccLngText(itemdata.name))
            GF.ShowMessage(openDayStr)
        end
        local movePos = itempos - 1
        movePos = movePos == 0 and 1 or movePos
        self._bossList:MoveToPos(movePos)
        self:OnClickBoss(itemdata.refId)

    end)
end

function UIDreamKillWin:OnClickCur()
    local bossRefId = self._bossRefId
    GF.OpenWnd("UIDreamCrusadeAgainstNodePop", { bossRefId = bossRefId })
end
function UIDreamKillWin:OnClickHarvest()
    GF.OpenWnd("UIHarvestPop")
end

function UIDreamKillWin:OnClickBoss(refId)
    local bossSelList = self._bossSelList or {}
    local bossRefId = self._bossRefId
    if bossRefId then
        CS.ShowObject(bossSelList[bossRefId], false)
    end
    CS.ShowObject(bossSelList[refId], true)
    self._bossRefId = refId
    self._difficulty = nil
    self:RefreshData()
end
--endregion --------------------------------------------------------------------------------------

--region check方法 --------------------------------------------------------------------------------
function UIDreamKillWin:IsSweep()
    local bossRefId = self._bossRefId
    local nodeId = self._nodeId
    local bossInfo = gModelCrusadeAgainst:GetCrusadeAgainstInfosByBossRefId(bossRefId)
    if bossInfo.nodeId >= nodeId then
        return true
    end
end

function UIDreamKillWin:InitMessage()
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function(index)
        self:OnClickClose()
    end)

    self:WndEventRecv(EventNames.ON_JUMP_DIFFICULTY, function(difficulty)
        self._difficulty = difficulty
        self:RefreshData()
    end)

    self:WndNetMsgRecv(LProtoIds.CrusadeAgainstInfoResp, function(pb)
        self:RefreshPhysical()
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.CrusadeAgainstSweepResp, function(pb)
        self:RefreshPhysical()
        self:RefreshData()
    end)
end

function UIDreamKillWin:AwardListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local itemRoot = self:FindWndTrans(root, "Icon")

    self:CreateCommonIconImpl(itemRoot, itemdata, { showNum = itemdata.type == 2 })
end

function UIDreamKillWin:InitEvent()
    self:SetWndClick(self.mBtnClose, function()
        self:OnClickClose()
    end)

    self:SetWndClick(self.mBtnCur, function()
        self:OnClickCur()
    end)

    self:SetWndClick(self.mBtnChallenge, function()
        self:OnClickChallenge()
    end)

    self:SetWndClick(self.mBtnHelp, function()
        self:OnClickHelp()
    end)

    self:SetWndClick(self.mBtnPass, function()
        self:OnClickPass()
    end)
end

function UIDreamKillWin:InitCommand(bossRefId, boosI, list)

    self:CreateBossScroll(list)

    --请求数据
    local bool = gModelFunctionOpen:CheckIsOpened(31000001, true)
    if not bool and false then
        return
    end
    gModelCrusadeAgainst:OnCrusadeAgainstInfoReq()

    if bossRefId then
        self:OnClickBoss(bossRefId)
    else
        self:OnClickBoss(list[boosI].refId)
    end
end

function UIDreamKillWin:OnClickChallenge()
    local bossRefId = self._bossRefId
    local nodeId = self._nodeId
    local bossRef = gModelCrusadeAgainst:GetDreamCrusadeDifficultyRefByRefId(bossRefId)
    local isOpent = gModelCrusadeAgainst:CheckIsOpen(bossRef.openDay)
    if not isOpent then
        GF.ShowMessage(ccClientText(32338))
        return
    end

    local physical = gModelCrusadeAgainst:GetPhysical()
    local singleEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("singleEnergy")--梦境讨伐单次消耗体力
    local lackPhysic = physical < singleEnergy

    if self:IsSweep() then
        if lackPhysic then
            local buyCount, buyLimit = gModelCrusadeAgainst:GetBuyInfo()
            local canBuy = buyLimit > buyCount
            local buyEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("buyEnergy")
            local buyEnergyItem = LxDataHelper.ParseItem_4(buyEnergy)
            local num = gModelItem:GetNumByRefId(buyEnergyItem.itemId)--拥有体力药数量
            local hasPhysicItem = num > 0

            if canBuy then
                GF.OpenWnd("UIDreamCrusadeAgainstVimPop")
            else
                if hasPhysicItem then
                    GF.OpenWnd("UICrusadeAgainstSweepPop", { nodeId = nodeId })
                else
                    GF.OpenWnd("UIDreamCrusadeAgainstVimPop")
                end
            end
        else
            GF.OpenWnd("UICrusadeAgainstSweepPop", { nodeId = nodeId })
        end
        return
    end

    if lackPhysic then
        GF.OpenWnd("UIDreamCrusadeAgainstVimPop")
        return
    end

    local bossInfo = gModelCrusadeAgainst:GetCrusadeAgainstInfosByBossRefId(bossRefId)
    local callBackFunc = function()
        if not self:IsWndValid() then
            return
        end
        local residueNum = bossRef.clearLimit - bossInfo.passCount
        if residueNum <= 0 then
            local nodeRef = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(nodeId)
            local difficulty = nodeRef.difficulty - 1
            local nodeList = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefBoosTypeAndDifficulty(bossRefId, difficulty)
            local para1 = string.format("%s-%s", difficulty, #nodeList)
            gModelGeneral:OpenUIOrdinTips({ refId = 310101, para = { para1, ccLngText(bossRef.name) }, func = function(...)
                self._difficulty = difficulty
                self:RefreshData()
            end })
            return
        end
        gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_CRUSADE_AGAINST, { bossRefId = bossRefId, targetId = nodeId })
    end

    callBackFunc()
end
function UIDreamKillWin:OnClickPass()
    GF.OpenWnd("UITaVdoPop", { openType = 4, refId = self._nodeId })
end

--刷新体力
function UIDreamKillWin:RefreshPhysical()
    local item = self.mPhysicalTemplate
    local root = self:FindWndTrans(item, "Root")
    local itemText = self:FindWndTrans(root, "ItemBg/ItemText")
    local itemIcon = self:FindWndTrans(root, "ItemBg/ItemIcon")
    local icon = gModelItem:GetItemIconByRefId(270001)
    self:SetWndEasyImage(itemIcon, icon)

    local vipLv = gModelPlayer:GetVipLevel()
    local vipRef = gModelVip:GetRefByVipLv(vipLv)
    local physical = gModelCrusadeAgainst:GetPhysical()
    local energyLimit = vipRef.energyLimit

    self:SetWndText(itemText, string.format("%s/%s", physical, energyLimit))
    self:SetWndClick(root, function()
        self:OnClickPhysical()
    end)
end

--奖励部分
function UIDreamKillWin:SetAwardItem(item, awardStr, type)
    local titleText = self:FindWndTrans(item, "TitleText")
    local awardRoot = self:FindWndTrans(item, "AwardRoot")
    local awardRoot2 = self:FindWndTrans(item, "AwardRoot2")

    self:SetWndText(titleText, type == 1 and ccClientText(32301) or ccClientText(32302))
    local list = {}
    if not string.isempty(awardStr) then
        list = LxDataHelper.ParseItem(awardStr)
    end
    for i, v in ipairs(list) do
        v.type = type
    end
    CS.ShowObject(awardRoot, #list >= 3)
    CS.ShowObject(awardRoot2, #list < 3)
    if #list >= 3 then
        local uiList = self:GetUIScroll("awardRoot" .. type)
        if uiList:GetList() then
            uiList:RefreshList(list)
        else
            uiList:Create(awardRoot, list, function(...)
                self:AwardListItem(...)
            end)
        end

        uiList:EnableScroll(#list >= 3, true)
    else
        local uiList2 = self:GetUIScroll("awardRoot2" .. type)
        if uiList2:GetList() then
            uiList2:RefreshList(list)
        else
            uiList2:Create(awardRoot2, list, function(...)
                self:AwardListItem(...)
            end)
        end

        uiList2:EnableScroll(#list >= 3, true)
    end
end

function UIDreamKillWin:OnClickPhysical()
    GF.OpenWnd("UIDreamCrusadeAgainstVimPop")
end

--endregion --------------------------------------------------------------------------------------

--region 界面事件 --------------------------------------------------------------------------------
---ui event
function UIDreamKillWin:OnClickHelp()
    GF.OpenWnd("UIBzTips", { refId = 502 })
end


---msg

--endregion --------------------------------------------------------------------------------------

--region 界面的数据处理 --------------------------------------------------------------------------------
--刷新数据
function UIDreamKillWin:RefreshData()
    local _difficulty = self._difficulty
    local bossRefId = self._bossRefId
    local bossInfo = gModelCrusadeAgainst:GetCrusadeAgainstInfosByBossRefId(bossRefId)
    if not bossInfo then
        return
    end
    local singleEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("singleEnergy")--梦境讨伐单次消耗体力

    --设置背景
    local bossRef = gModelCrusadeAgainst:GetDreamCrusadeDifficultyRefByRefId(bossRefId)
    local bg = bossRef.bg
    if LxUiHelper.IsImgPathValid(bg) then
        CS.ShowObject(self.mBgImage, true)
        self:SetWndEasyImage(self.mBgImage, bg)
    end

    --boss立绘
    local exhibition, exhibitionPos = bossRef.exhibition, bossRef.exhibitionPos
    if not string.isempty(exhibition) then
        local posParent = self.mBossSpine
        if self._oldSpineName and self._oldSpineName ~= exhibition then
            self:DestroyWndSpineByKey("mBossSpine")
        end
        self:CreateWndSpine(posParent, exhibition, "mBossSpine", false)
        self._oldSpineName = exhibition
        CS.ShowObject(posParent, true)
        if not string.isempty(exhibitionPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty2(exhibitionPos)
            self:SetAnchorPos(posParent, pos)
        end
    end

    --进度部分
    local nodeRef, curLevelNum = self:GetNodeRef()
    if nodeRef.nextRefid == -1 then
        curLevelNum = 11
    elseif curLevelNum < 10 then
        curLevelNum = nodeRef.levelNum - 1
    end
    if bossInfo.nodeId == 0 then
        curLevelNum = 0
    end
    self._curLevelNum = curLevelNum

    --记录节点id
    self._nodeId = nodeRef.refId

    self.mPassValueBar.maxValue = 100
    local barValue = 0
    if curLevelNum <= 3 then
        barValue = 8.5 * curLevelNum
    elseif curLevelNum <= 7 then
        barValue = 9 * curLevelNum
    elseif curLevelNum < 10 then
        barValue = 9 * curLevelNum + (curLevelNum - 7)
    else
        barValue = 100
    end
    self.mPassValueBar.value = barValue

    self:CreateStarList()

    --刷新难度显示
    local difficulty = nodeRef.difficulty
    local curStr = string.replace(ccClientText(46503), difficulty)
    self:SetWndText(self.mCurText, curStr)

    --boss name
    self:SetWndText(self.mBossName, curStr .. "·" .. ccLngText(bossRef.name))
    if gLGameLanguage:IsVieVersion() or gLGameLanguage:IsEnglishVersion()  then
        LxUiHelper.SetSizeWithCurAnchor(self.mBossBg,0,380)
        self:InitTextSizeWithLanguage(self.mChallengeNumText,-8)
    end

    --次数
    local clearLimit = bossRef.clearLimit
    self:SetWndText(self.mChallengeNumText, string.replace(ccClientText(46500), clearLimit - bossInfo.passCount))

    --设置自身的消耗
    self:SetWndText(self.mCostNumText, singleEnergy)
    local icon = gModelItem:GetItemIconByRefId(270001)
    self:SetWndEasyImage(self.mCostIcon, icon)
    --设置战斗
    local openDay = bossRef.openDay
    local isOpent = gModelCrusadeAgainst:CheckIsOpen(openDay)
    self._isOpent = isOpent
    CS.ShowObject(self.mBtnChallenge, true)
    self:SetWndButtonGray(self.mBtnChallenge, not isOpent)
    local challengeStr = ccClientText(17210)
    if bossInfo.nodeId >= nodeRef.refId then
        challengeStr = ccClientText(12106)
    end
    self:SetWndButtonText(self.mBtnChallenge, challengeStr)

    --奖励部分
    local isAward1 = nodeRef.refId > bossInfo.nodeId
    local isAward2 = not string.isempty(nodeRef.rewardChallengeShow)
    CS.ShowObject(self.mAwardBg1, isAward1)
    if isAward1 then
        self:SetAwardItem(self.mAwardBg1, nodeRef.rewardFirstShow, 1)
    end
    CS.ShowObject(self.mAwardBg2, isAward2)
    if isAward2 then
        self:SetAwardItem(self.mAwardBg2, nodeRef.rewardChallengeShow, 2)
    end

end

function UIDreamKillWin:StarListItem(list, item, itemdata, itempos)
    local image = self:FindWndTrans(item, "Image")
    local icon = self:FindWndTrans(item, "Icon")
    local text = self:FindWndTrans(item, "Text")
    local eff = self:FindWndTrans(item, "Eff")
    if itempos == self._starLen then
        self:SetWndEasyImage(image, "golem_boss_2")
        self:SetWndEasyImage(icon, "golem_boss_1")
    end
    local _curLevelNum = self._curLevelNum == 11 and 10 or self._curLevelNum

    CS.ShowObject(icon, _curLevelNum >= itempos)
    self:SetWndText(text, itempos)


end

function UIDreamKillWin:OnClickClose()
    GF.OpenWndBottom("UIOutts")
    local ref = GameTable.DailyGamePlayRef[112]
    local group = ref and ref.group
    if group and group > 0 then
        GF.OpenWnd("UIOuttsList", { listRefId = group })
    end
    self:WndClose()
end
--endregion --------------------------------------------------------------------------------------

--region 界面设置 --------------------------------------------------------------------------------
--设置boss的列表
function UIDreamKillWin:CreateBossScroll(list)
    local uiList = self._bossList

    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("mDreamBossScroll")
        uiList:Create(self.mBossScroll, list, function(...)
            self:BossListItem(...)
        end, UIItemList.SUPER)
        uiList:EnableScroll(true, true)
        self._bossList = uiList
    end

    self._bossList:MoveToPos(self._initMovePos)
end
function UIDreamKillWin:OnClickStrategy()
    local bossRefId = self._bossRefId
    GF.OpenWnd("UIBossStrategyPop", { bossRefId = bossRefId })
end

function UIDreamKillWin:InitData()
    local bossRefId = self:GetWndArg("bossRefId")

    local list = gModelCrusadeAgainst:GetDreamCrusadeDifficultyRef()
    local boosI = 1
    for i, v in ipairs(list) do
        local isOpent = gModelCrusadeAgainst:CheckIsOpen(v.openDay)
        if isOpent then
            boosI = i
            break
        end
    end
    self._initBossIRefId = list[boosI].refId
    local movePos = boosI - 1
    movePos = movePos == 0 and 1 or movePos
    self._initMovePos = movePos
    self:InitCommand(bossRefId, boosI, list)
end

--当前节点信息 --感觉是不应该出现在这里的
function UIDreamKillWin:GetNodeRef()
    local _difficulty = self._difficulty
    local bossRefId = self._bossRefId
    local bossInfo = gModelCrusadeAgainst:GetCrusadeAgainstInfosByBossRefId(bossRefId)
    if not bossInfo then
        return
    end
    local curLevelNum = 0
    local nodeRef = nil
    if not _difficulty then
        if bossInfo.nodeId == 0 then
            local nodeList = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefBoosTypeAndDifficulty(bossRefId, 1)
            nodeRef = nodeList[1]
        else
            local tasRef = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(bossInfo.nodeId)
            if tasRef.nextRefid > 0 then
                nodeRef = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(tasRef.nextRefid)
            else
                nodeRef = tasRef
            end
        end
    else
        if bossInfo.nodeId ~= 0 then
            local tasRef = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(bossInfo.nodeId)
            local nexRef = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(tasRef.nextRefid)
            if not nexRef or nexRef.difficulty > _difficulty then
                local nodeList = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefBoosTypeAndDifficulty(bossRefId, _difficulty)
                nodeRef = nodeList[#nodeList]
                curLevelNum = 10
            else
                if tasRef.nextRefid > 0 then
                    nodeRef = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(tasRef.nextRefid)
                else
                    nodeRef = tasRef
                end
            end
        else
            local nodeList = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefBoosTypeAndDifficulty(bossRefId, 1)
            nodeRef = nodeList[1]
        end
    end
    return nodeRef, curLevelNum
end

--region 初始化 --------------------------------------------------------------------------------
function UIDreamKillWin:InitStaticText()
    self:SetWndText(self.mCostText, ccClientText(46505))
    self:SetWndText(self.mPassValueText, ccClientText(32303))
    self:SetWndText(self.mPassText, ccClientText(32307))
end

--进度条的形象
function UIDreamKillWin:CreateStarList()
    --进度条的星星
    local starList = {}
    for i = 1, 10 do
        table.insert(starList, i)
    end
    self._starLen = #starList
    local uiStarList = self._uiStarList
    if uiStarList then
        uiStarList:RefreshList(starList)
    else
        uiStarList = self:GetUIScroll("mStarList")
        uiStarList:Create(self.mStarList, starList, function(...)
            self:StarListItem(...)
        end)
    end
end


--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIDreamKillWin