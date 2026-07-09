---
--- Created by Administrator.
--- DateTime: 2024/7/11 21:11:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEqSpInfo:LWnd
local UIEqSpInfo = LxWndClass("UIEqSpInfo", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEqSpInfo:UIEqSpInfo()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEqSpInfo:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEqSpInfo:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEqSpInfo:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitText()
    self:InitPara()
    self:InitData()

    self:SetPanel()
end

function UIEqSpInfo:InitText()
    --self:SetWndText(self.mTitleText, ccClientText(44507)) --[44507] [裝備精煉]
    --self:SetWndText(self.mTZAttrTxt_1, ccClientText(44509)) --[44509] [精煉結果]
    --self:SetWndText(self.mTZAttrTxt_2, ccClientText(44510)) --[44510] [精煉材料]
    --
    --self:SetWndText(self:GetBtnTextTran(self.mRefineBtn), ccClientText(44508))  --[44508] [精 煉]
end


--region 页面初始化 --------------------------------------------------------------------------------
function UIEqSpInfo:InitEvent()
    --uiclick
    self:SetWndClick(self.mBg, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mBtn1, function()
        self:OptLeftBtn()
    end)
    self:SetWndClick(self.mBtn2, function()
        self:OptMidBtn()
    end)
    self:SetWndClick(self.mBtn3, function()
        self:OptRightBtn()
    end)

end
--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIEqSpInfo:SetPanel()
    if not self._ref then
        return
    end
    local heroId = self._heroId
    local showTZList = true

    --按钮显示部分
    local btnStr1, btnStr2, btnStr3
    if heroId then

        --【卸下】【强化】【替换】
        btnStr1, btnStr2, btnStr3 = ccClientText(11302), ccClientText(44500), ccClientText(11310)--[11302]	[卸  下]   [44500] [强 化]    [11310]	[替  換]
    else
        --【分解】【强化】【穿戴】
        btnStr1, btnStr2, btnStr3 = ccClientText(43704), ccClientText(44500), ccClientText(11300) --[43704] [分 解]   [44500] [强 化]  [11300]	[裝  備]
    end
    if showTZList then
        self:SetXUITextText(self.mBtnName1, btnStr1)
        self:SetXUITextText(self.mBtnName2, btnStr2)
        self:SetXUITextText(self.mBtnName3, btnStr3)

    end

    --红点部分
    if self._showRedImg then
        local equipType = self._ref.type
        local eqStruct = gModelEquip:GetEquipRefByRefId(self._ref)
        local good = gModelEquip:GetStrongerEquipByPart(eqStruct, equipType)
        local trans
        trans = self.mRedPoint
        CS.ShowObject(trans, good ~= 0 and good ~= self._refId)
    end

    --装备部分
    local trans = CS.FindTrans(self.mEquipInfo, "Icon")

    if trans then
        local typeConst = LItemTypeConst.TYPE_PET_EQUIP == self._typeConst and LItemTypeConst.TYPE_PET_EQUIP or LItemTypeConst.TYPE_EQUIP
        local baseClass = CommonIcon:New(self)
        baseClass:Create(trans)
        baseClass:SetCommonReward(typeConst, self._refId, 0, nil, true)
        baseClass:EnableShowNum(false)
        baseClass:DoApply()
        self._equipIcon = baseClass
    end
    local grade = 0
    if self._equip then
        local level = self._equip:GetLevel()
        self._equipIcon:SetEquipExtension(level)
        grade = self._equip:GetGrade()
    end

    local tempTrans = self.mBaseAttrTxt
    local baseTxt = ccClientText(11307)

    self:SetWndText(tempTrans, baseTxt)

    tempTrans = self.mTZAttrTxt
    baseTxt = ccClientText(11308)
    self:SetWndText(tempTrans, baseTxt)

    tempTrans = self.mSSkillText
    baseTxt = ccClientText(44517)
    self:SetWndText(tempTrans, baseTxt)

    baseTxt = ccClientText(11313)
    self:SetWndText(self.mTZUpTxt, baseTxt)

    baseTxt = ccClientText(44519)
    self:SetWndText(self.mGradeAttrTxt, baseTxt)

    local quaId = self._ref.quality

    local heroMessage = gModelItem:GetHeroMessQualityById(quaId)
    local headTrans = self.mHeadImg1
    self:SetWndEasyImage(headTrans, heroMessage)

    -- 装备名字
    tempTrans = self.mNameTxt2
    local equipName = ccLngText(self._ref.name)
    if showTZList then
        tempTrans = self.mNameTxt
    end
    if grade > 0 then
        equipName = string.format("%s +%s", equipName, grade)
    end

    self:SetXUITextText(tempTrans, equipName)

    -- 名字设置颜色
    local color = gModelItem:GetColorByQualityId(quaId)
    self:SetXUITextColor(tempTrans, color)

    -- 基础属性
    local equipAttr = self._ref.attr
    local attrList = string.split(equipAttr, ",")
    for i, v in ipairs(attrList) do
        local temp = string.split(v, "=")
        local attrType, nType, num = tonumber(temp[1]), tonumber(temp[2]), tonumber(temp[3])
        local tempNum = i
        if not showTZList then
            tempNum = i + 2
        end
        self:ChangeAttrTrans(tempNum, attrType, nType, num)
    end

    --类型
    local equipType = self._ref.type
    local typeName = gModelEquip:GetEquipPartRefByPart(equipType).typeName

    local str = ccClientText(11305)
    str = string.replace(str, ccLngText(typeName))
    tempTrans = self.mTypeTxt
    self:SetXUITextText(tempTrans, str)
    self:SetXUITextColor(tempTrans, color)

    -- 装备成绩

    local scoreNum = self._equip and self._equip:GetScore() or gModelEquip:GetEquipRefByRefId(self._refId).score
    local score = math.floor(scoreNum + 0.5)
    local str = ccClientText(11306)
    str = string.replace(str, score)
    tempTrans = self.mScoreTxt
    self:SetXUITextText(tempTrans, str)
    self:SetXUITextColor(tempTrans, color)

    --铸魂部分
    local classlv = self._equip:GetGrade()
    self._equipClassRef = ModelEquip:GetUpGradeRef(self._ref.type, classlv)
    local addAtr = (self._equipClassRef.selfAddAttr * 100) .. "%"

    local gradeTran = self.mGrade_Attr1
    local name = CS.FindTrans(gradeTran, "AttrName")
    local value = CS.FindTrans(gradeTran, "AttrValue")

    CS.ShowObject(gradeTran, true)
    local AttrIcon_Lock = CS.FindTrans(gradeTran, "AttrIcon_Lock")

    --获取下当前的星星
    local curStar = tonumber(self._equipRef.star)
    local needStar = tonumber(self._equipClassRef.upNeedStar)
    local isShowAttr = self._equipClassRef.selfAddAttr > 0
    if not isShowAttr then
        --如果为0 判断下是否足够
        isShowAttr = curStar >= needStar
    end

    if isShowAttr then
        self:SetWndText(name, ccClientText(44514)) --[44514] [裝備全屬性加成：]
        self:SetWndText(value, addAtr)
        CS.ShowObject(AttrIcon_Lock, false)
    else
        local star = self._equipClassRef.upNeedStar
        local str = string.replace(ccClientText(44526), star)
        self:SetWndText(name, str)
        CS.ShowObject(AttrIcon_Lock, true)
    end

    -- 装备描述
    local des = self._ref.des and ccLngText(self._ref.des) or ""
    tempTrans = self.mEquipDescTxt
    self:SetWndText(tempTrans, des)
    CS.ShowObject(self.mEquipDesc, not string.isempty(des))

    if self._heroId then
        self:WearSuitCount()
    else
        self:BagSuitCount()
    end

    self:OptBtn()
end

function UIEqSpInfo:ChangeAttrTrans(index, attrType, nType, num)
    local attrList = self._attrList
    local trans = attrList[index]
    if not trans then
        return
    end
    CS.ShowObject(trans, true)
    local iconTrans = CS.FindTrans(trans, "AttrIcon")
    if iconTrans then
        self:SetAttrIcon(iconTrans, attrType)
    end
    local AttrNameTrans = CS.FindTrans(trans, "AttrName")
    local AttrValueTrans = CS.FindTrans(trans, "AttrValue")
    if AttrNameTrans and AttrValueTrans then
        if self._equipStrengthRef then
            local attrInfo = gModelEquip:ParseEquipAttrInfo(self._equipStrengthRef.attrAdd)

            if attrInfo.refId == attrType and attrInfo.type == nType then
                num = num + attrInfo.value
            end

        end
        local refineId = self._equip:GetRefineRefId()
        if refineId > 0 then
            local refineRef = gModelEquip:GetRefineLevelRef(refineId)

            if refineRef then
                local attrInfo = gModelEquip:ParseEquipAttrInfo(refineRef.attrAdd1)

                if attrInfo.refId == attrType and attrInfo.type == nType then
                    num = num + attrInfo.value
                end
            end
        end

        self:SetAttrInfo(AttrNameTrans, AttrValueTrans, attrType, nType, num)
    end
end

--function UIEqSpInfo:ShowSkillInfo(state)
--	CS.ShowObject(self.mSuitSkillObj, state)
--end

function UIEqSpInfo:OnClickShare()
    if self._shareFunc then
        self._shareFunc()
    end
    self:WndClose()
end

function UIEqSpInfo:InitPara()
    self._refId = self:GetWndArg("refId")--装备refId
    self._heroId = self:GetWndArg("heroId")--装备对象
    self._openWay = self:GetWndArg("OpenWay") -- 1:背包 2:英雄界面,3:替换界面
    self._noShowBtn = self:GetWndArg("noShowBtn") -- 隐藏所有的按钮
    self._showRedImg = self:GetWndArg("showRedImg") -- 显示红点
    self._share = self:GetWndArg("share")
    self._shareFunc = self:GetWndArg("shareFunc")
    self._typeConst = self:GetWndArg("typeConst") or LItemTypeConst.TYPE_EQUIP
    self._equip = self:GetWndArg("equip")
    self._equipRef = gModelEquip:GetEquipRefByRefId(self._refId)
    self._strengthType = gModelEquip:GetEquipStrengthType(self._equipRef)
    self._equipStrengthRef = gModelEquip:GetEquipStrengthRef(self._strengthType, self._equip:GetLevel())

    if tonumber(self._heroId) == 0 then
        self._heroId = nil
    end  -- 0的英雄id 抛弃掉
end

function UIEqSpInfo:InitData()
    self._ref = gModelEquip:GetEquipRefByRefId(self._refId)

    self._refId = self._equip:GetRefId()
    self._id = self._equip:GetId()
    self._attrList = {
        self.mAttr1,
        self.mAttr2,
    }

    self._gradeList = {
        self.mGrade_Attr1,
        self.mGrade_Attr2,
    }

    self._suitList = {
        self.mSuit1,
        self.mSuit2,
        self.mSuit3,
    }

    self._skillList = {
        self.mSkillInfo_1,
        self.mSkillInfo_2,
    }
    self._skillRootList = {
        self.mSuitSkillObj_1,
        self.mSuitSkillObj_2,
    }
end

function UIEqSpInfo:ChangeSkillTrans(skillCount, skillActivation, skillId, activeNum)
    -- 节点
    local tran = self._skillList[skillCount]

    if not tran then
        printInfoNR2("UIEqSpInfo--配置了超过技能的限制", "skillCount--" .. skillCount)
        return
    end

    local skillIconRoot = CS.FindTrans(tran, "SkillIcon")
    local iconBg = CS.FindTrans(skillIconRoot, "IconBg")
    local icon = CS.FindTrans(iconBg, "Icon")

    local SkillName = CS.FindTrans(tran, "SkillName")
    local AcitveText = CS.FindTrans(tran, "AcitveText")
    local SkillText = CS.FindTrans(tran, "SkillText")

    local activeStr = string.replace(ccClientText(44518), activeNum)

    self:SetWndText(AcitveText, activeStr)

    local color = "768ba4FF"
    if skillActivation then
        color = "0fb93fFF"
    end
    color = LUtil.ColorByHex(color)
    local skillActiveText = self:FindWndText(AcitveText)
    self:SetXUITextColor(skillActiveText, color)

    local skillRef = gModelSkill:GetSkillRef(skillId)

    if not skillRef then
        printInfoNR2("UIEqSpInfo--无技能配置", "skillId--" .. skillId)
        return
    end

    CS.ShowObject(self._skillRootList[skillCount], true)

    --description  icon iconBg name
    self:SetWndText(SkillName, ccLngText(skillRef.name))
    self:SetWndText(SkillText, ccLngText(skillRef.description))

    if string.isempty(skillRef.iconBg) then
        self:SetWndEasyImage(iconBg, skillRef.iconBg)
    end

    self:SetWndEasyImage(icon, skillRef.icon)
    CS.ShowObject(icon, true)
end

function UIEqSpInfo:GetBtnTextTran(tran)
    local textTran = CS.FindTrans(tran, "UIText")
    return textTran
end

function UIEqSpInfo:BagSuitCount()
    -- 套装属性
    -- 获取已装备的列表
    if not self._ref then
        return
    end
    local curSuit = self._ref.suitList
    local SuitRef = gModelEquip:GetSuitListBySuit(curSuit)
    if not table.isempty(SuitRef) then
        table.sort(SuitRef, function(suit1, suit2)
            local suitSort1, suitSort2 = suit1.suitLv, suit2.suitLv
            return suitSort1 < suitSort2
        end)
        local changeName = false

        local skillCount = 0
        for i, v in ipairs(SuitRef) do
            if not changeName then
                if not self._heroId then
                    local baseTxt = ccLngText(v.suitName)
                    self:SetWndText(self.mTZAttrTxt, baseTxt)
                end
                changeName = true
            end
            local activation = false
            local activationList = v.activationNum
            local list = string.split(activationList, ",")
            local quality, starNum, activationNum = tonumber(list[1]), tonumber(list[2]), tonumber(list[3])
            local activationAttrList = v.activationAttr
            self:ChangeSuitTrans(i, activation, activationAttrList, activationNum, quality, starNum)

            local skillActivation = false
            activationList = v.skillNum
            local temp = string.split(activationList, ",")
            quality, starNum, activationNum = tonumber(temp[1]), tonumber(temp[2]), tonumber(temp[3])
            --拿下技能数据
            local skillId = v.skill

            if skillId > 0 then
                skillCount = skillCount + 1
                --计数
                self:ChangeSkillTrans(skillCount, skillActivation, skillId, activationNum)
            end

        end
    else
        CS.ShowObject(self.mTZUpTxt, false)
    end
end
--endregion --------------------------------------------------------------------------------------

--region 事件部分 --------------------------------------------------------------------------------

--uiClick
function UIEqSpInfo:OptLeftBtn()
    if self._heroId then
        self:WndClose()
        gModelEquip:OnEquipUnloadReq(self._heroId, { self._refId })                                            -- 卸下

    else
        -- 出售
        --GF.ShowMessage("敬请期待")
        gModelGeneral:RunOriginConfigCode(1008, {
            refId = self._refId,
            id = self._id,
            equip = self._equip,
        })
        --gModelGeneral:RunOriginConfigCode(1008, { refId = self._refId, itype = 3 })
        self:WndClose()
    end
end

function UIEqSpInfo:WearSuitCount()
    local curSuit = self._ref.suitList
    local heroAttrList, equipList = gModelHero:GetHeroAttrAndEquipInfoById(self._heroId)
    if table.isempty(equipList) then
        equipList = {}
    end
    local suitList, equipState = {}, {}
    -- 统计套装类型
    for k, v in pairs(equipList) do
        local wearEquipRef = gModelEquip:GetEquipRefByRefId(v:GetRefId())
        local tempSuit = wearEquipRef.suitList
        -- 套装效果统计
        if tempSuit ~= 0 then
            local temp = tempSuit
            local tempInfo = suitList[temp]
            if not tempInfo then
                suitList[temp] = 1
            else
                suitList[temp] = tempInfo + 1
            end
        end

        local quality = wearEquipRef.quality
        local star = wearEquipRef.star
        for i = quality, 1, -1 do
            if equipState[i] == nil then
                equipState[i] = {}
            end
            if quality > i then
                --当品质>填入品质的时候 忽视掉星星
                star = 5
            end

            for k = star, 1, -1 do
                if equipState[i][k] == nil then
                    equipState[i][k] = 0
                end
                equipState[i][k] = equipState[i][k] + 1
            end
        end
    end
    -- 套装效果 	套装级别-套装类型
    local addSuitList = {
        [2] = 0,
        [3] = 0,
        [4] = 0,
    }
    for k, v in pairs(suitList) do
        local _suit = k
        for _k, _v in pairs(suitList) do
            if tonumber(_k) > _suit then
                suitList[k] = v + _v
            end
        end
        for i = 4, 2, -1 do
            local temp = i
            if suitList[k] >= i and _suit > addSuitList[temp] then
                addSuitList[temp] = _suit
            end
        end
    end
    -- local addCurSuitList = {}
    for k, v in pairs(addSuitList) do
        if v == 0 then
            -- addCurSuitList[k] = true
            addSuitList[k] = curSuit
        end
    end

    local list = gModelHero:GetHeroSuitAttrState(self._heroId, self._refId)
    for i, v in ipairs(list) do
        local activationList = v.activationNum
        local temp = string.split(activationList, ",")
        local quality, starNum, activationNum = tonumber(temp[1]), tonumber(temp[2]), tonumber(temp[3])
        local activationAttrList = v.activationAttr

        local activation = false
        if equipState[quality] then
            if equipState[quality][starNum] and equipState[quality][starNum] >= activationNum then
                activation = true
            end
        end

        --

        self:ChangeSuitTrans(i, activation, activationAttrList, activationNum, quality, starNum)
    end

    local tempsuitList = gModelEquip:GetSuitListBySuitList(curSuit)
    local skillCount = 0
    for i, v in ipairs(tempsuitList) do
        --技能部分
        local skillActivation = false
        local activationList = v.skillNum
        local temp = string.split(activationList, ",")

        equipState = gModelHero:GetHeroSuitState(self._heroId, self._refId)
        local quality, starNum, activationNum = tonumber(temp[1]), tonumber(temp[2]), tonumber(temp[3])
        if equipState[quality] then
            if equipState[quality][starNum] and equipState[quality][starNum] >= activationNum then
                skillActivation = true
            end
        end

        --拿下技能数据
        local skillId = v.skill

        if skillId > 0 then
            skillCount = skillCount + 1
            --计数
            self:ChangeSkillTrans(skillCount, skillActivation, skillId, activationNum)
        end
    end

end

function UIEqSpInfo:ChangeSuitTrans(index, activation, activationAttrList, activationNum, quality, starNum)
    local suitList = self._suitList
    local trans = suitList[index]
    if not trans then
        return
    end
    CS.ShowObject(trans, true)
    local color = "768ba4FF"
    if activation then
        color = "0fb93fFF"
    end
    color = LUtil.ColorByHex(color)
    local list = string.split(activationAttrList, ",")
    for i, v in ipairs(list) do
        local temp = string.split(v, "=")
        local attr, nType, num = tonumber(temp[1]), tonumber(temp[2]), tonumber(temp[3])
        local iconTrans = CS.FindTrans(trans, "Icon")
        if iconTrans then
            self:SetAttrIcon(iconTrans, attr)
        end
        local addAttrNameTrans = CS.FindTrans(trans, "AddAttrName")
        local addAttrTrans = CS.FindTrans(trans, "AddAttr")
        if addAttrNameTrans and addAttrTrans then
            --num的值要+上剩星部分

            self:SetAttrInfo(addAttrNameTrans, addAttrTrans, attr, nType, num)


        end
        local suitAttrTrans = CS.FindTrans(trans, "SuitAttr")
        if suitAttrTrans then
            local str = ccClientText(11309)
            local quaRef = gModelItem:GetQualityRef(quality)
            if quaRef then
                local quaName = ccLngText(quaRef.name)
                str = string.replace(str, activationNum, quaName, starNum)
            end
            local xuiText = self:FindWndText(suitAttrTrans)
            if xuiText then
                self:SetXUITextText(xuiText, str)
                self:SetXUITextColor(xuiText, color)
            end
        end
    end
end

function UIEqSpInfo:SetAttrInfo(trans1, trans2, attr, nType, num, color)
    local attrName = gModelHero:GetAttributeNameById(attr)
    if attrName then
        local str = "#a1#:"
        local xuiText = self:FindWndText(trans1)
        if xuiText then
            str = string.replace(str, attrName)
            self:SetXUITextText(xuiText, str)
            if color then
                self:SetXUITextColor(xuiText, color)
            end
        end
        str = "#a1#"
        if nType == 2 then
            num = (num * 100) .. "%"
        end
        str = string.replace(str, num)
        xuiText = self:FindWndText(trans2)
        if xuiText then
            self:SetXUITextText(xuiText, str)
            if color then
                self:SetXUITextColor(xuiText, color)
            end
        end
    end
end

function UIEqSpInfo:OptBtn()
    if self._openWay == 3 then
        CS.ShowObject(self.mOptBtnList1, false)
        CS.ShowObject(self.mOptBtnList2, true)
    else
        CS.ShowObject(self.mOptBtnList1, true)
        CS.ShowObject(self.mOptBtnList2, false)

        --设置红点
        local btnRedpoint_2 = CS.FindTrans(self.mBtn2, "redPoint")

        local isShow = gModelEquip:GetEquipCanExtensionRedpoint(self._equip)
        CS.ShowObject(btnRedpoint_2, isShow)
    end
end

function UIEqSpInfo:SetAttrIcon(trans, attr)
    local icon = gModelHero:GetAttributeIconById(attr)
    if icon then
        self:SetWndEasyImage(trans, icon)
    end
end

function UIEqSpInfo:OptMidBtn()
    self:WndClose()

    --强化
    GF.OpenWndBottom("UIEqExtension", { tabIndex = 3, refId = self._refId, id = self._id, equip = self._equip })
end

function UIEqSpInfo:OptRightBtn()
    if self._heroId then
        --替换
        self:WndClose()
        GF.OpenWndUp("UIEqWear", { refId = self._refId, heroId = self._heroId, part = self._ref.type, equip = self._equip })    -- 替换

    else
        FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.HERO)
        self:WndClose()
    end
end


--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIEqSpInfo