---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEqInfo:LWnd
local UIEqInfo = LxWndClass("UIEqInfo", LWnd)
------------------------------------------------------------------
--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEqInfo:UIEqInfo()
    self._equipIcon = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEqInfo:OnWndClose()
    if self._equipIcon then
        self._equipIcon:Destroy()
    end
    self._equipIcon = nil
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEqInfo:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEqInfo:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitData()
    if not self._openWay then
        CS.ShowObject(self.mOptBtnList1, false)
        --CS.ShowObject(self.mBtn1,false)
        --CS.ShowObject(self.mBtn2,false)
    end
    if self._noShowBtn then
        --[[		CS.ShowObject(self.mBtn1,false)
                CS.ShowObject(self.mBtn2,false)
                CS.ShowObject(self.mBtn3,false)
                CS.ShowObject(self.mBtn4,false)]]
        CS.ShowObject(self.mOptBtnList1, false)
        CS.ShowObject(self.mOptBtnList2, false)
        -- CS.ShowObject(self.mTipBg3,true)
    end
    self:InitEvent()
    self:InitMsg()
    if self._showTZList then
        CS.ShowObject(self.mInfoBg1, true)
        CS.ShowObject(self.mInfoBg2, false)
    else
        CS.ShowObject(self.mInfoBg2, true)
        CS.ShowObject(self.mInfoBg1, false)
    end
    self:Refresh()
end

function UIEqInfo:WearSuitCount()
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

        --if curSuit > tempSuit then
        --    curSuit = tempSuit
        --end
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
            local tempStar = i >= quality and star or 5

            for k = tempStar, 1, -1 do
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
    --local list = gModelEquip:FindSuitList(addSuitList)
    for i, v in ipairs(list) do
        local activationList = v.activationNum
        local temp = string.split(activationList, ",")
        local quality, starNum, activationNum = tonumber(temp[1]), tonumber(temp[2]), tonumber(temp[3])
        local activationAttrList = v.activationAttr
        -- local activation = true
        -- local toStringActNum = activationNum

        local activation = false
        if equipState[quality] then
            if equipState[quality][starNum] and equipState[quality][starNum] >= activationNum then
                activation = true
            end
        end
        -- if addCurSuitList[toStringActNum] then
        -- 	activation = false
        -- end
        self:ChangeSuitTrans(i, activation, activationAttrList, activationNum, quality, starNum)
    end

    -- local selfActive, skillId = false, 0
    -- local selfSuit = gModelEquip:GetEquipRefByRefId(self._refId).suitList
    -- local suitCfg = gModelEquip:GetEquipSuitRefById(selfSuit)
    -- if suitCfg and suitCfg.skillNum and suitCfg.skill then
    -- 	local temp = string.split(suitCfg.skillNum, ",")
    -- 	local quality, starNum, activationNum = tonumber(temp[1]), tonumber(temp[2]), tonumber(temp[3])
    -- 	if equipState[quality] then
    -- 		if equipState[quality][starNum] and equipState[quality][starNum] >= activationNum then
    -- 			selfActive = true
    -- 		end
    -- 	end
    -- 	skillId = suitCfg.skill
    -- end
    -- self:ShowSkillInfo(selfActive, skillId)
end

function UIEqInfo:InitMsg()
    self:WndNetMsgRecv(LProtoIds.EquipWearResp, function()
        self:WndClose()
    end)
    self:WndNetMsgRecv(LProtoIds.EquipUnloadResp, function()
        self:WndClose()
    end)
    self:WndNetMsgRecv(LProtoIds.PetEquipWearResp, function()
        self:WndClose()
    end)
    self:WndNetMsgRecv(LProtoIds.PetEquipUnloadResp, function()
        self:WndClose()
    end)
end

-- function UIEqInfo:ShowSkillInfo(state)
-- 	CS.ShowObject(self.mSuitSkillObj, state)
-- end

function UIEqInfo:OnClickShare()
    if self._shareFunc then
        self._shareFunc()
    end
    self:WndClose()
end

function UIEqInfo:OptLeftBtn()
    if self._heroId then
        if self._typeConst == LItemTypeConst.TYPE_PET_EQUIP then
            local petId = self._heroId
            gModelPet:OnPetEquipUnloadReq(petId, { self._refId })
        else
            gModelEquip:OnEquipUnloadReq(self._heroId, { self._refId })                                            -- 卸下
        end
    else
        --  跳转合成
        --GF.ShowMessage("敬请期待")
        GF.OpenWnd("UIMid")

        self:WndClose()
    end
end

function UIEqInfo:ChangeSuitTrans(index, activation, activationAttrList, activationNum, quality, starNum)
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

function UIEqInfo:SetAttrInfo(trans1, trans2, attr, nType, num, color)
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

function UIEqInfo:ChangeAttrTrans(index, attrType, nType, num)
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
        self:SetAttrInfo(AttrNameTrans, AttrValueTrans, attrType, nType, num)
    end
end

function UIEqInfo:BagSuitCount()
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
        end
    else
        CS.ShowObject(self.mTZUpTxt, false)
    end
end

function UIEqInfo:OptRightBtn()
    if self._heroId then
        self:WndClose()
        if self._typeConst == LItemTypeConst.TYPE_PET_EQUIP then
            local petId = self._heroId
            GF.OpenWndUp("UIPeEqWear", { petRefId = petId, part = self._ref.type, refId = self._refId })
        else
            GF.OpenWndUp("UIEqWear", { refId = self._refId, heroId = self._heroId, part = self._ref.type })    -- 替换
        end
    else
        if self._typeConst == LItemTypeConst.TYPE_PET_EQUIP then
            --装扮
            -- gModelGeneral:RunOriginConfigCode(1029)
        else
            -- 穿戴
            FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.HERO)
        end

        self:WndClose()

    end
end

function UIEqInfo:SetAttrIcon(trans, attr)
    local icon = gModelHero:GetAttributeIconById(attr)
    if icon then
        self:SetWndEasyImage(trans, icon)
    end
end

function UIEqInfo:InitData()
    self._refId = self:GetWndArg("refId")--装备refId
    self._heroId = self:GetWndArg("heroId")--装备对象
    self._openWay = self:GetWndArg("OpenWay") -- 1:背包 2:英雄界面
    self._noShowBtn = self:GetWndArg("noShowBtn") -- 隐藏所有的按钮
    self._showRedImg = self:GetWndArg("showRedImg") -- 显示红点
    self._share = self:GetWndArg("share")
    self._shareFunc = self:GetWndArg("shareFunc")
    self._typeConst = self:GetWndArg("typeConst") or LItemTypeConst.TYPE_EQUIP
    self._ref = self._typeConst == LItemTypeConst.TYPE_PET_EQUIP and gModelPet:GetPetEquipRef(self._refId) or gModelEquip:GetEquipRefByRefId(self._refId)
    self._attrList = {
        self.mAttr1,
        self.mAttr2,
        self.mAttr3,
        self.mAttr4,
    }
    self._suitList = {
        self.mSuit1,
        self.mSuit2,
        self.mSuit3,
    }
    self._showTZList = true
    local curSuit = self._ref.suitList
    if not curSuit or curSuit == 0 then
        self._showTZList = false
    end
    CS.ShowObject(self.mShareBtn1, self._share == true)
    CS.ShowObject(self.mShareBtn2, self._share == true)
end

function UIEqInfo:InitEvent()
    if self._openWay then
        if self._showTZList then
            self:SetWndClick(self.mBtn1, function()
                self:OptLeftBtn()
            end)
            self:SetWndClick(self.mBtn2, function()
                self:OptRightBtn()
            end)
        else
            self:SetWndClick(self.mBtn3, function()
                self:OptLeftBtn()
            end)
            self:SetWndClick(self.mBtn4, function()
                self:OptRightBtn()
            end)
        end
    end
    self:SetWndClick(self.mBg, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mICloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn1, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mShareBtn1, function()
        self:OnClickShare()
    end)
    self:SetWndClick(self.mShareBtn2, function()
        self:OnClickShare()
    end)
end

function UIEqInfo:Refresh()
    if not self._ref then
        return
    end
    local heroId = self._heroId
    local showTZList = self._showTZList
    local btnStr1, btnStr2
    if heroId then
        btnStr1, btnStr2 = ccClientText(11302), ccClientText(11310)
    else

        local strId = LItemTypeConst.TYPE_PET_EQUIP == self._typeConst and 11312 or 41541
        btnStr1, btnStr2 = ccClientText(strId), ccClientText(11300)
    end
    if showTZList then
        self:SetXUITextText(self.mBtnName1, btnStr1)
        self:SetXUITextText(self.mBtnName2, btnStr2)
    else
        self:SetXUITextText(self.mBtnName3, btnStr1)
        self:SetXUITextText(self.mBtnName4, btnStr2)
    end

    if self._showRedImg then
        local equipType = self._ref.type
        local eqStruct = gModelEquip:GetEquipRefByRefId(self._ref)
        local good = gModelEquip:GetStrongerEquipByPart(eqStruct, equipType)
        local trans
        if showTZList then
            trans = self.mRedPoint
        else
            trans = self.mRedPoint1
        end
        CS.ShowObject(trans, good ~= 0 and good ~= self._refId)
    end

    local trans = CS.FindTrans(self.mEquipInfo2, "Icon")
    if showTZList then
        trans = CS.FindTrans(self.mEquipInfo, "Icon")
    end
    if trans then
        local typeConst = LItemTypeConst.TYPE_PET_EQUIP == self._typeConst and LItemTypeConst.TYPE_PET_EQUIP or LItemTypeConst.TYPE_EQUIP
        local baseClass = CommonIcon:New(self)
        baseClass:Create(trans)
        baseClass:SetCommonReward(typeConst, self._refId, 0, nil, true)
        baseClass:EnableShowNum(false)
        baseClass:DoApply()
        self._equipIcon = baseClass
    end

    local tempTrans = self.mBaseAttrTxt2
    local baseTxt = ccClientText(11307)
    if showTZList then
        tempTrans = self.mBaseAttrTxt
    end
    self:SetWndText(tempTrans, baseTxt)

    tempTrans = self.mTZAttrTxt
    baseTxt = ccClientText(11308)
    if showTZList then
        self:SetWndText(tempTrans, baseTxt)
    end

    -- if heroId then
    baseTxt = ccClientText(11313)
    -- else
    -- baseTxt = ccClientText(11314)
    -- end
    if showTZList then
        self:SetWndText(self.mTZUpTxt, baseTxt)
    end

    local quaId = self._ref.quality
    local heroMessage = gModelItem:GetHeroMessQualityById(quaId)
    if heroMessage then
        local headTrans = self.mHeadImg2
        if showTZList then
            headTrans = self.mHeadImg1
        end
        self:SetWndEasyImage(headTrans, heroMessage)
    end

    -- 装备名字
    tempTrans = self.mNameTxt2
    local equipName = ccLngText(self._ref.name)
    if showTZList then
        tempTrans = self.mNameTxt
    end
    self:SetXUITextText(tempTrans, equipName)

    -- 名字设置颜色
    local color = gModelItem:GetColorByQualityId(quaId)
    self:SetXUITextColor(tempTrans, color)


    -- 装备类型
    local equipType = self._ref.type
    local typeName = self._typeConst == LItemTypeConst.TYPE_PET_EQUIP and ccLngText(gModelPet:GetPetEquipPartRef(equipType).name) or gModelEquip:GetEquipPartRefByPart(equipType).typeName
    if typeName then
        local str = ccClientText(11305)
        str = string.replace(str, ccLngText(typeName))
        tempTrans = self.mTypeTxt2
        if showTZList then
            tempTrans = self.mTypeTxt
        end
        self:SetXUITextText(tempTrans, str)
        self:SetXUITextColor(tempTrans, color)
    end

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

    -- 装备成绩
    local scoreNum = self._typeConst == LItemTypeConst.TYPE_PET_EQUIP and gModelPet:GetPetEquipRef(self._refId).score or gModelEquip:GetEquipRefByRefId(self._refId).score
    local score = math.floor(scoreNum + 0.5)
    local str = ccClientText(11306)
    str = string.replace(str, score)
    tempTrans = self.mScoreTxt2
    if showTZList then
        tempTrans = self.mScoreTxt
    end
    self:SetXUITextText(tempTrans, str)
    self:SetXUITextColor(tempTrans, color)

    -- 装备描述
    local des = self._ref.des and ccLngText(self._ref.des) or ""
    tempTrans = self.mEquipDescTxt2
    if showTZList then
        tempTrans = self.mEquipDescTxt
    end
    self:SetWndText(tempTrans, des)
    CS.ShowObject(self.mEquipDesc, not string.isempty(des))
    if showTZList then
        if self._heroId then
            self:WearSuitCount()
        else
            self:BagSuitCount()
        end
    end
end

------------------------------------------------------------------
return UIEqInfo



