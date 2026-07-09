---
--- Created by Administrator.
--- DateTime: 2023/10/9 16:06:55
---
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaAwakenAttr:LWnd
local UISagaAwakenAttr = LxWndClass("UISagaAwakenAttr", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaAwakenAttr:UISagaAwakenAttr()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaAwakenAttr:OnWndClose()
    if self._delayFrameTimer then
        LxTimer.DelayTimeStop(self._delayFrameTimer)
        self._delayFrameTimer = nil
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaAwakenAttr:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaAwakenAttr:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:CommonData()
    self:InitMsg()
    self:InitEvent()
    self:InitData()
    self:InitUIView()
    self:InitStatic()
end

function UISagaAwakenAttr:InitPreData()
    local preHeroRefId = self:GetWndArg("preHeroRefId")
    if preHeroRefId and preHeroRefId > 0 then
        local heroAwaken = gModelHero:GetHeroAwakenByRefId(preHeroRefId)
        if heroAwaken and heroAwaken > 0 then
            local treePointList = gModelHero:GetHeroTreePointList(heroAwaken)
            if treePointList and #treePointList > 0 then
                local recordMaxAttrTreeId
                local skillList = {}
                local treePointRefId,curPointLvRef,attr,skill,isSkillType
                for k, v in ipairs(treePointList) do
                    treePointRefId = v.refId
                    local typeList = gModelHero:GetHeroTreePointLvList(treePointRefId)
                    local len = #typeList.lvList
                    local lvList = typeList.lvList[len]  -- 预览取最后一级
                    curPointLvRef = gModelHero:GetHeroTreePointLvRef(lvList.refId)
                    attr = curPointLvRef.attr
                    local isAttrType = not string.isempty(attr) and attr ~= "0"
                    if isAttrType then
                        if not recordMaxAttrTreeId then
                            recordMaxAttrTreeId = curPointLvRef.refId
                        elseif recordMaxAttrTreeId < curPointLvRef.refId then
                            recordMaxAttrTreeId = curPointLvRef.refId
                        end
                    end
                    skill = curPointLvRef.skill
                    if skill and skill ~= "" then
                        local tSkill = string.split(skill,"|")
                        for i,skillId in ipairs(tSkill) do
                            skillId = checknumber(skillId)
                            table.insert(skillList, {
                                isActivate = true,
                                treePointRefId = treePointRefId,
                                skill = skillId,
                                skillId = skillId or 0,
                                showLv = curPointLvRef.showLv or 1
                            })
                        end
                    end
                end

                local isAddAttr = recordMaxAttrTreeId ~= nil
                --- 如果没有加成，则取最后一次属性加成的数据
                if not isAddAttr then
                    local treePoint, typeList, lvList
                    local len = #treePointList
                    for i = len, 1, -1 do
                        treePoint = treePointList[i]
                        treePointRefId = treePoint.refId
                        typeList = gModelHero:GetHeroTreePointLvList(treePointRefId)
                        if typeList then
                            local _len = #typeList.lvList
                            lvList = typeList.lvList[_len]  --未激活默认第一级
                            curPointLvRef = gModelHero:GetHeroTreePointLvRef(lvList.refId)
                            attr = curPointLvRef and curPointLvRef.attr
                            if not string.isempty(attr) and attr ~= "0" then
                                recordMaxAttrTreeId = curPointLvRef.refId
                                break
                            end
                        end
                    end
                end

                local maxPointLvRef = gModelHero:GetHeroTreePointLvRef(recordMaxAttrTreeId)
                local resultAttrList = gModelHero:GetAwakenTreePointAttrShiftList(maxPointLvRef.attr)

                self._attrList = resultAttrList
                self._skillList = skillList
            end
        end
    end
end


function UISagaAwakenAttr:InitStatic()
    self:SetWndText(self.mCenterViewTitle, ccClientText(20148))
    self:SetWndText(self.mBotViewTitle, ccClientText(20149))
    self:SetWndText(self.mCloseTip, ccClientText(10103))
    self:SetWndButtonText(self.mBtnRed2, ccClientText(20158), nil, -4)
end

function UISagaAwakenAttr:InitHeroAttrAndSkillList()
    local treeInfoPoints = self._treeInfoPoints

    local num = 0
    local recordActTreeMap = {}
    for k, v in pairs(treeInfoPoints) do
        num = num + 1
    end

    local recordMaxAttrTreeId
    local skillList = {}
    local treePointList = gModelHero:GetHeroTreePointList(self._treeRefId)
    local treePointRefId, infoPoint, isActivate, curPointLvRef, attr, skill, isSkillType
    for k, v in ipairs(treePointList) do
        treePointRefId = v.refId
        infoPoint = treeInfoPoints[treePointRefId]
        isActivate = infoPoint ~= nil
        curPointLvRef = nil
        if isActivate then
            local lvRefId = infoPoint.lvRefId
            curPointLvRef = gModelHero:GetHeroTreePointLvRef(lvRefId)
        else
            local typeList = gModelHero:GetHeroTreePointLvList(treePointRefId)
            local lvList = typeList.lvList[1]  --未激活默认第一级
            curPointLvRef = gModelHero:GetHeroTreePointLvRef(lvList.refId)
        end
        attr = curPointLvRef.attr
        local isAttrType = not string.isempty(attr) and attr ~= "0"
        if isActivate and isAttrType then
            if not recordMaxAttrTreeId then
                recordMaxAttrTreeId = curPointLvRef.refId
            elseif recordMaxAttrTreeId < curPointLvRef.refId then
                recordMaxAttrTreeId = curPointLvRef.refId
            end
        end
        skill = curPointLvRef.skill
        if skill and skill ~= "" then
            local p_ActSkill = isActivate and infoPoint.skillId
            local tSkill = string.split(skill,"|")
            local isMoreSkill = #tSkill
            for i,skillId in ipairs(tSkill) do
                skillId = checknumber(skillId)
                local insData = true
                if isMoreSkill then
                    if p_ActSkill and p_ActSkill > 0 then
                        ---2025/1/6： 2条弹窗太长了，目前显示1条
                        insData = p_ActSkill == skillId
                    end
                end
                if insData then
                    table.insert(skillList, {
                        isActivate = isActivate,
                        treePointRefId = treePointRefId,
                        skill = skillId,
                        skillId = skillId or 0,
                        showLv = curPointLvRef.showLv or 1
                    })
                end
            end
        end
    end

    local isAddAttr = recordMaxAttrTreeId ~= nil
    --- 如果没有加成，则取最后一次属性加成的数据
    if not isAddAttr then
        local treePoint, typeList, lvList
        local len = #treePointList
        for i = len, 1, -1 do
            treePoint = treePointList[i]
            treePointRefId = treePoint.refId
            typeList = gModelHero:GetHeroTreePointLvList(treePointRefId)
            if typeList then
                lvList = typeList.lvList[1]  --未激活默认第一级
                curPointLvRef = gModelHero:GetHeroTreePointLvRef(lvList.refId)
                attr = curPointLvRef and curPointLvRef.attr
                if not string.isempty(attr) and attr ~= "0" then
                    recordMaxAttrTreeId = curPointLvRef.refId
                    break
                end
            end
        end
    end

    local maxPointLvRef = gModelHero:GetHeroTreePointLvRef(recordMaxAttrTreeId)
    local resultAttrList = gModelHero:GetAwakenTreePointAttrShiftList(maxPointLvRef.attr)
    local isNotAct = num < 1
    if isNotAct then
        for i, v in ipairs(resultAttrList) do
            v.value = 0
        end
    end

    self._attrList = resultAttrList
    self._skillList = skillList
end

function UISagaAwakenAttr:OnDrawSkillDescCell(list, item, itemdata, itempos)
    local ActDiv = self:FindWndTrans(item, "ActDiv")
    local LockDiv = self:FindWndTrans(item, "LockDiv")
    local SkillDesc = self:FindWndTrans(item, "SkillDesc")
    local isActivate = itemdata.isActivate
    CS.ShowObject(ActDiv, isActivate)
    CS.ShowObject(LockDiv, not isActivate)
    local skillId = tonumber(itemdata.skillId)
    if not skillId or skillId < 1 then
        skillId = itemdata.skill
    end
    local skillRef = gModelHero:GetSkillByStarId(tonumber(skillId))
    if skillRef then
        local str = string.replace(ccClientText(20184), itemdata.showLv, ccLngText(skillRef.name), ccLngText(skillRef.description))
        self:SetWndText(SkillDesc, str)
    end
end

function UISagaAwakenAttr:OnClickSkillSelect(treePointRefId)
    local serverData = gModelHero:GetHeroServerDataById(self._heroId)
    if not serverData then
        return
    end
    gModelHeroExtra:OpenHeroTreeSkillWnd({
        viewType = 1,
        heroServerData = serverData,
        targetTreePointRefId = treePointRefId,
    })
    --[[	GF.OpenWnd("UISagaAwakenJNSelect",{
            heroId	 = self._heroId,
            pointRefId = treePointRefId,
        })]]
end

function UISagaAwakenAttr:OnClickNormalSkill(skillId, itempos)
    --GF.OpenWnd("UINewJNTip",{curSkillId = skillId,wndType = 2})
    gModelGeneral:OpenSkillWnd({ curSkillId = skillId, wndType = 2 })
end

function UISagaAwakenAttr:RefreshBotView()

    local heroSkillList = self._skillList
    local skillScrollList = self._skillScrollList
    if skillScrollList then
        skillScrollList:RefreshList(heroSkillList)
    else
        local listTrans = self.mSkillDescList
        LxUiHelper.SetCanvasGroupAlpha(listTrans,0)

        ---@type UIItemList
        skillScrollList = self:GetUIScroll("skillDescList")
        self._skillScrollList = skillScrollList
        skillScrollList:Create(listTrans, heroSkillList, function(...)
            self:OnDrawSkillDescCell(...)
        end)
        skillScrollList:EnableScroll(true)


        self._delayFrameTimer = LxTimer.DelayFrameCall(function()
            self._delayFrameTimer = nil
            local listHeight = listTrans.rect.height
            if listHeight > 400 then
                local layout = listTrans:GetComponent(typeLayoutElement)
                layout.preferredHeight = 400
            end
            LxUiHelper.SetCanvasGroupAlpha(listTrans,1)
        end, 1)
    end

end

function UISagaAwakenAttr:OnDrawNormalSkill(list, item, itemdata, itempos)
    local skillIconTrans = CS.FindTrans(item, "CommonUI/Root/SkillIcon")
    local nameText = CS.FindTrans(item, "Name")
    local shiftBtn = self:FindWndTrans(item, "ShiftBtn")
    local coverIcon = self:FindWndTrans(item, "CommonUI/CoverIcon")

    local treePointRefId = itemdata.treePointRefId
    local skillId = itemdata.skillId
    local haveSkill = skillId and skillId > 0
    local isActivate = itemdata.isActivate

    CS.ShowObject(nameText, haveSkill)
    CS.ShowObject(shiftBtn, not self._isTryHero and isActivate)
    CS.ShowObject(coverIcon, not haveSkill)
    local baseClass = SkillIcon:New(self)
    if not haveSkill then
        baseClass:SetShowIcon(false, false)
        baseClass:SetSkillInfo(nil, nil, nil, 1)
        baseClass:ShowLvl(false)
        baseClass:Create(skillIconTrans, 0, function()
            if not isActivate then
                return
            end
            self:OnClickSkillSelect(treePointRefId)
        end)
        baseClass:SetIconAndIconBgGray(false)
    else
        baseClass:SetSkillInfo(nil, false, nil, 1)
        baseClass:ShowLvl(true)
        baseClass:ShowLock(false)
        baseClass:Create(skillIconTrans, skillId, function()
            self:OnClickNormalSkill(skillId, itempos)
        end)
        baseClass:SetIconAndIconBgGray(false)
    end

    self:SetWndClick(shiftBtn, function()
        if not isActivate then
            return
        end
        self:OnClickSkillSelect(treePointRefId)
    end)

    if not haveSkill then
        return
    end

    local skillRef = gModelHero:GetSkillByStarId(skillId)
    if not skillRef then
        return
    end

    if nameText then
        self:SetWndText(nameText, ccLngText(skillRef.name))
        self:InitTextModeWithLanguage(nameText)
    end
end

function UISagaAwakenAttr:OnHeroTreeResetReq()
    local heroId = self._heroId
    self:WndClose()
    gModelHero:OnHeroTreeResetReq(heroId)
end

function UISagaAwakenAttr:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnRed2, function()
        self:OnClickResetAwaken()
    end, LSoundConst.CLICK_BUTTON_COMMON)
end

function UISagaAwakenAttr:InitUIView()
    self:RefreshCenterView()
    self:RefreshBotView()
end

function UISagaAwakenAttr:CommonData()
    self._baseAttrList = {
        LAttrConst.Atk,
        LAttrConst.MaxHP,
        LAttrConst.Def,
        LAttrConst.Speed,
    }
    self._specialAttrList = {
        LAttrConst.Hit, LAttrConst.Dodge, LAttrConst.Crit, LAttrConst.DefCrit,
        LAttrConst.Ctrl, LAttrConst.DefCtrl, LAttrConst.PHurt, LAttrConst.PAvoidHurt,
        LAttrConst.MHurt, LAttrConst.MAvoidHurt, LAttrConst.CritRatio, LAttrConst.CritRatioR,
        LAttrConst.Treat, LAttrConst.BeTreat, LAttrConst.AddHurt, LAttrConst.AvoidHurt,
    }
end

function UISagaAwakenAttr:InitServerData()
    self._heroId = self:GetWndArg("heroId")
    local isMySelf = self:GetWndArg("mySelf")
    if isMySelf == nil then
        isMySelf = true
    end
    CS.ShowObject(self.mReset, isMySelf)

    local treeInfoPoints = {}
    local treeInfo = self:GetWndArg("treeInfo")
    if treeInfo then
        local points = treeInfo.points
        if points then
            treeInfoPoints = {}
            for k, v in ipairs(points) do
                local pointRefId = v.pointRefId
                treeInfoPoints[pointRefId] = v
            end
        else
            treeInfoPoints = {}
        end
    else
        treeInfoPoints = gModelHero:GetHeroServerTreePoints(self._heroId)
    end
    self._treeInfoPoints = treeInfoPoints


    local heroData = self:GetWndArg("heroData")
    local serverData = gModelHero:GetHeroServerDataById(self._heroId)
    if heroData then
        serverData = heroData
    end
    if not serverData then
        printInfoNR("serverData is not find, id = " .. self._heroId)
        return
    end

    self._isTryHero = serverData.isTry

    local refId = serverData.refId
    local heroRef = gModelHero:GetHeroRef(refId)
    if not heroRef then
        printInfoNR("GameTable.CharacterRef[id] is not find, id = " .. refId)
        return
    end

    local heroAwaken = heroRef.heroAwaken
    self._treeRefId = heroAwaken

    self:InitHeroAttrAndSkillList()
end

function UISagaAwakenAttr:OnDrawAttrCell(list, item, itemdata, itempos)
    local AttrIcon = self:FindWndTrans(item, "AttrIcon")
    local AttrName = self:FindWndTrans(item, "AttrName")
    local AttrValue = self:FindWndTrans(item, "AttrValue")
    local refId = itemdata.refId
    local value = itemdata.value
    if AttrIcon then
        local icon = gModelHero:GetAttributeIconById(refId)
        self:SetWndEasyImage(AttrIcon, icon, function()
            CS.ShowObject(AttrIcon, true)
        end)
    end
    if AttrName then
        local name = gModelHero:GetAttributeNameById(refId)
        self:SetWndText(AttrName, name)
    end
    if AttrValue then
        local valuestr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, itemdata.type, value)
        self:SetWndText(AttrValue, valuestr)
    end
end

function UISagaAwakenAttr:InitData()
    local isPre = self:GetWndArg("isPre")
    if isPre then
        CS.ShowObject(self.mReset, false)
        self:InitPreData()
    else
        self:InitServerData()
    end
end

function UISagaAwakenAttr:InitMsg()

end

function UISagaAwakenAttr:GetAttrMapByRefId(refId, defaultAttr)
    local isAddAttr = false
    local tempAttrList = {}
    local maxPointLvRef = gModelHero:GetHeroTreePointLvRef(refId)
    local curAttrList = gModelHero:GetAwakenTreePointAttrShiftList(maxPointLvRef.attr)
    local attrRefId, attrValue, resultAttrData, type, oldTypeData
    for key, attrData in ipairs(curAttrList) do
        attrRefId = attrData.refId
        if defaultAttr then
            tempAttrList[attrRefId] = defaultAttr
        else
            attrValue = attrData.value or 0
            resultAttrData = tempAttrList[attrRefId]
            if not resultAttrData then
                resultAttrData = {}
                tempAttrList[attrRefId] = resultAttrData
                --else
                --	tempAttrList[attrRefId] = resultAttrData + attrValue
            end
            type = attrData.type
            oldTypeData = resultAttrData[type] or 0
            resultAttrData[type] = oldTypeData + attrValue
        end
    end
    isAddAttr = #curAttrList > 0
    return tempAttrList, isAddAttr
end

function UISagaAwakenAttr:OnClickResetAwaken()
    local isZeroLv = true
    local points = gModelHero:GetHeroServerTreePoints(self._heroId, true)

    if points then
        for k, v in ipairs(points) do
            local lvRefId = v.lvRefId
            local ref = gModelHero:GetHeroTreePointLvRef(lvRefId)
            if ref.lv > 0 then
                isZeroLv = false
                break
            end
        end

    end

    if isZeroLv then
        GF.ShowMessage(ccClientText(20159))
        return
    end

    local heroAwakenReset = gModelHero:GeConfigByKey("heroAwakenReset")
    local itemData = LxDataHelper.ParseItem(heroAwakenReset)
    local itemNum = itemData[1].itemNum
    local itemId = itemData[1].itemId

    gModelGeneral:OpenUIOrdinTips({
        refId = 10021,
        func = function()
            local own = gModelItem:GetNumByRefId(itemId)
            if own < itemNum then
                gModelGeneral:OpenGetWayWnd({ itemId = itemId, srcWnd = self:GetWndName() })
                return
            end
            self:OnHeroTreeResetReq()
        end,
        para = { gModelItem:GetNameByRefId(itemId),itemNum }, consume = { itemNum, itemId }
    })
end

function UISagaAwakenAttr:RefreshCenterView()
    local attrList = self._attrList
    local uiAttrList = self._uiAttrList
    if uiAttrList then
        uiAttrList:RefreshList(attrList)
    else
        uiAttrList = self:GetUIScroll("_uiAttrList")
        uiAttrList:Create(self.mAttrList, attrList, function(...)
            self:OnDrawAttrCell(...)
        end)
    end
end

------------------------------------------------------------------
return UISagaAwakenAttr


