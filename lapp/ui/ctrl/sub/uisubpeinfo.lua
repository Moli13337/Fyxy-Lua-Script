---
--- Created by Administrator.
--- DateTime: 2024/6/14 19:01:27
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPeInfo:LChildWnd
local UISubPeInfo = LxWndClass("UISubPeInfo", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPeInfo:WndChildPetBase()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPeInfo:OnWndClose()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPeInfo:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPeInfo:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self._isJapaness  =gLGameLanguage:IsJapanVersion()
    if self._isJapaness then 
        self:SetAnchorPos(self.mTxtName,Vector2.New(10,-36))
    end 
    self:OnAddClick()
    self.argList = self:GetWndArgList()
    self.listLeng = self.argList.allPet and #self.argList.allPet or 0
    self:OnUpdatePet()
end
function UISubPeInfo:OnRightClick()
    self.argList.index = self.argList.index + 1
    self.argList.refId = self.argList.allPet[self.argList.index].refId
    self:OnUpdatePet()
    FireEvent(EventNames.PET_INFO_CHANGE)
end
function UISubPeInfo:OnUpdateLevel()
    local pet = gModelPet:GetPetById(self.argList.refId)
    self:SetWndText(self.mTxtLevel, string.replace(ccClientText(43766), pet._level, pet.maxLevel))
end
function UISubPeInfo:OnLeftClick()
    self.argList.index = self.argList.index - 1
    self.argList.refId = self.argList.allPet[self.argList.index].refId
    self:OnUpdatePet()
    FireEvent(EventNames.PET_INFO_CHANGE)
end
function UISubPeInfo:OnUpdateRed()
    local red = self:FindWndTrans(self.mBtnCommon, "redPoint")
    ---@type StructPet
    local pet = gModelPet:GetPetById(self.argList.refId)
    local isShow = false
    if pet.isActive then
        isShow = pet:IsCanUpLevel()
    else
        isShow = pet:GetPetState() == 2
    end
    CS.ShowObject(red, isShow)
end
function UISubPeInfo:OnAddClick()
    self:SetWndClick(self.mBtnLeft, function()
        self:OnLeftClick()
    end)

    self:SetWndClick(self.mBtnRight, function()
        self:OnRightClick()
    end)

    self:SetWndClick(self.mBtnShare, function()
        self:OnShare()
    end)

    self:SetWndClick(self.mBtnCommon, function()
        self:OnUpStarLv()
    end)
    self:SetWndClick(self.mBtnAttrHelp, function()
        GF.OpenWnd("UIPeLinkJN", { refId = self.argList.refId })
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:UpdateCost()
        self:OnUpdateRed()
    end)
    self:WndEventRecv(EventNames.PET_CHANGE_LEVEL, function()
        self:OnUpdateAttr()
        self:OnUpdateLevel()
        self:OnUpdateRed()
        self:UpdateCost()
    end)
    self:WndEventRecv(EventNames.PET_CHANGE_STAR, function()
        self:UpdateCost()
        self:OnSkillDesc()
        self:OnUpdateAttr()
        self:OnUpdateStar()
        self:OnUpdateLevel()
        self:OnUpdateRed()
    end)

end

function UISubPeInfo:OnShare()
    local data = {
        root = self.mBtnShare,
        shareType = ModelChat.CHAT_SHARE_41,
        shareData = tostring(self.argList.refId),
    }
    gModelGeneral:OpenShareTip(data)
end

function UISubPeInfo:OnUpdateAttr()
    ---@type StructPet
    local pet = gModelPet:GetPetById(self.argList.refId)
    local attrs = nil
    local attrItems = LUtil.ConvertCommonAttrStrToList(pet:GetTotalAttrStr())
    local totalAttrStr = LUtil.GetCommonAttrKeyList(attrItems)
    attrs = LUtil.MapAttrToListAttr(totalAttrStr)
    local lvCfg = pet:GetLvCfg()
    self.nextLvAttr = {}
    self.curLvAttr = {}
    if pet.isActive and lvCfg.lvNext > 0 then
        local nexAttr = GameTable.MagicPetLvRef[lvCfg.lvNext]
        self.curLvAttr = LUtil.ConvertCommonAttrStrToMap(lvCfg.attr) or {}
        self.nextLvAttr = nexAttr and LUtil.ConvertCommonAttrStrToMap(nexAttr.attr) or {}
    end
    local uiAttrList = self._uiAttrList
    self.curAttrAdd = gModelPet:GetTotalAttrAdd()
    if uiAttrList then
        uiAttrList:RefreshList(attrs)
    else
        uiAttrList = self:GetUIScroll("favorAttrList")
        self._uiAttrList = uiAttrList
        uiAttrList:Create(self.mListAttrs, attrs, function(...)
            self:OnDrawAttrCell(...)
        end)
    end
end
function UISubPeInfo:OnUpdateArrow()
    CS.ShowObject(self.mBtnLeft, self.argList.index > 1)
    CS.ShowObject(self.mBtnRight, self.argList.index < self.listLeng)
end

function UISubPeInfo:UpdateCost()
    ---@type StructPet
    local pet = gModelPet:GetPetById(self.argList.refId)
    local ref = pet:GetLvCfg()
    CS.ShowObject(self.mSellItemList, pet.isActive)
    CS.ShowObject(self.mSlider.transform, not pet.isActive)
    self:SetWndButtonGray(self.mBtnCommon, ref and ref.lvNext <= 0)
    if pet.isActive then
        self:SetWndButtonText(self.mBtnCommon, (ref and ref.lvNext <= 0) and ccClientText(12611) or ccClientText(40501))
        local list = ref and LxDataHelper.ParseItem(ref.upNeed) or {}
        local uiList = self:FindUIScroll("PetInfoCost")
        if uiList then
            uiList:RefreshList(list)
            uiList:DrawAllItems()
        else
            uiList = self:GetUIScroll("PetInfoCost")
            uiList:Create(self.mSellItemList, list, function(...)
                self:OnDrawCostItem(...)
            end)
        end
    else
        self:OnUpdateActiveCost()
    end
end

function UISubPeInfo:OnUpdateStar()
    gModelPet:SetStar(self.mImgStar, self.argList.refId, nil, function(starPath)
        self:SetWndEasyImage(self.mImgStar, starPath)
    end)
end

function UISubPeInfo:OnSkillDesc()
    ---@type StructPet
    local pet = gModelPet:GetPetById(self.argList.refId)
    local desc, conditionDesc, isCondition = pet:GetLinkSkillDesc()
    self:SetWndText(self.mTxtLinkDesc, desc or "")
    self:SetWndText(self.mTxtLinkCond, conditionDesc or "")
    CS.ShowObject(self.mTxtLinkCond, isCondition)

    local petStarCfg = pet:GetPetStarCfg(0)
    local attrAdd = petStarCfg.attrChangeAdd
    local attrStar = pet._star
    while ((pet._star > petStarCfg.rankNow and petStarCfg.rankNext > 0) or attrAdd <= 0) do
        petStarCfg = GameTable.MagicPetStarRef[petStarCfg.rankNext]
        attrAdd = petStarCfg.attrChangeAdd > 0 and petStarCfg.attrChangeAdd or attrAdd
        attrStar = petStarCfg.rankNow
    end
    local nexStarCfg = pet:GetPetStarCfg(pet._star + 1)
    local nexAttrAdd
    if nexStarCfg and nexStarCfg.attrChangeAdd > 0 and pet._star >= attrStar then
        nexAttrAdd = " <color=#139057>(+" .. (nexStarCfg.attrChangeAdd - attrAdd) .. "%)</color>"
    end
    local color = (pet._star >= attrStar and pet.isActive) and "#D2730F" or "#C81212"
    self:SetWndText(self.mTxtWholeAttr, string.replace(ccClientText(43714), color, nexAttrAdd and attrAdd .. "%" .. nexAttrAdd or attrAdd .. "%"))
    self:SetWndText(self.mTxtWholeCond, string.replace(ccClientText(43713), attrStar))
    CS.ShowObject(self.mTxtWholeCond, pet._star ~= attrStar or not pet.isActive)
end
function UISubPeInfo:OnUpdateActiveCost()
    local petInfo = gModelPet:GetPetById(self.argList.refId)
    local starCfg = petInfo:GetPetStarCfg()
    CS.ShowObject(self.mSlider.transform, starCfg.rankNext > 0 and true or false)
    CS.ShowObject(self.mBtnCommon, starCfg.rankNext > 0 and true or false)
    CS.ShowObject(self.mTxtFull, starCfg.rankNext < 0 and true or false)
    self:SetWndButtonText(self.mBtnCommon, petInfo.isActive and ccClientText(43736) or ccClientText(43737))
    if starCfg.rankNext < 0 then
        self:SetWndText(self.mTxtFull, ccClientText(43738))

        return
    end
    local cost = starCfg.upNeed--petInfo.isActive and GameTable.MagicPetStarRef[starCfg.rankNext].upNeed or
    local costItem = LxDataHelper.ParseItem_4(cost)
    local hasNum = gModelItem:GetNumByRefId(costItem.itemId)
    self.mSlider.value = hasNum / costItem.itemNum
    self:SetWndText(self.mTxtProBar, LUtil.NumberCoversion(hasNum) .. "/" .. costItem.itemNum)
end
function UISubPeInfo:OnWndRefresh()
    LChildWnd.OnWndRefresh(self)
    self:OnUpdatePet()
end
function UISubPeInfo:OnDrawAttrCell(list, item, itemdata, itempos)
    local AttrIcon = self:FindWndTrans(item, "AttrIcon")
    local AttrName = self:FindWndTrans(item, "AttrName")
    local AttrValue = self:FindWndTrans(item, "AttrValue")
    local AttrAdd = self:FindWndTrans(item, "AttrAdd")
    local numType, refId, value = itemdata.attrType, itemdata.attrRefId, itemdata.attrNum
    if AttrIcon then
        local icon = gModelHero:GetAttributeIconById(refId)
        self:SetWndEasyImage(AttrIcon, icon)
    end

    if AttrName then
        local name = gModelHero:GetAttributeNameById(refId)
        self:SetWndText(AttrName, name)
    end

    if AttrValue then
        local addVal = math.floor(value * self.curAttrAdd * 0.01)
        local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, numType, value + addVal)
        self:SetWndText(AttrValue, "+" .. valueStr)
    end
    local pos = AttrValue.anchoredPosition
    self:SetWndText(AttrAdd, "")
    if AttrAdd and self.nextLvAttr[refId] and self.nextLvAttr[refId][numType] then
        local curLvAttrVal = self.curLvAttr[refId] and self.curLvAttr[refId][numType] or 0
        local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, numType, self.nextLvAttr[refId][numType] - curLvAttrVal)
        self:SetWndText(AttrAdd, "+" .. valueStr)
        pos.x = 115
    else
        pos.x = 135
    end
    if self._isVie then
        pos.x = pos.x + 30
    end

    AttrValue.anchoredPosition = pos
end
function UISubPeInfo:OnUpdatePet()
    local petCfg = GameTable.MagicPetRef[self.argList.refId]
    local pet = gModelPet:GetPetById(self.argList.refId)

    if self._isEnus then
        LxUiHelper.SetSizeWithCurAnchor(self.mBgImage1, 0, 300)
        self:SetWndText(self.mTxtName_Enus, ccLngText(petCfg.name))
    else
        self:SetWndText(self.mTxtName, ccLngText(petCfg.name))
    end

    self:SetWndText(self.mTxtTitleLink, ccClientText(43715))
    self:SetWndText(self.mTxtTitleAttr, ccClientText(43716))
    local qualityIcon = GameTable.RarityRef[petCfg.quality]

    CS.ShowObject(self.mBtnShare, pet.isActive)
    self:SetWndEasyImage(self.mImgType, qualityIcon.qualityText, function()
        CS.ShowObject(self.mImgType, true)
    end)
    if petCfg and string.isempty(petCfg.spine) then
        self:SetWndEasyImage(self.mImgSpine, petCfg.icon, function()
            CS.ShowObject(self.mImgSpine, true)
            local img = self:FindWndImage(self.mImgSpine)
            img:SetNativeSize()
        end)
        CS.ShowObject(self.mPetSpine, false)
    else
        CS.ShowObject(self.mPetSpine, true)
        CS.ShowObject(self.mImgSpine, false)
        self:DestroyWndSpineByKey("PetDrawing")
        local dpSpine = self:CreateWndSpine(self.mPetSpine, petCfg.spine, "PetDrawing", true, function(dpLoaded)
            dpLoaded:PlayAnimation(0, "idle", true)
        end, true)
        dpSpine:StartLoad()
    end

    self:OnUpdateArrow()
    self:OnUpdateStar()
    self:OnSkillDesc()
    self:OnUpdateAttr()
    self:UpdateCost()
    self:OnUpdateRed()
    self:OnUpdateLevel()
end
function UISubPeInfo:OnUpStarLv()
    ---@type StructPet
    local pet = gModelPet:GetPetById(self.argList.refId)

    if pet.isActive then
        if not pet:IsCanUpLevel(true) then
            return
        end
        gModelPet:OnPetUpLevelReq(self.argList.refId, 1)
    else
        if not pet:IsCanUpStar(true) then
            return
        end
        gModelPet:OnPetUpSatrReq(self.argList.refId)
    end
end

function UISubPeInfo:OnDrawCostItem(list, item, itemdata, itempos)
    local SellIconTrans = self:FindWndTrans(item, "SellIcon")
    if SellIconTrans then
        local iconImg = gModelItem:GetItemIconByRefId(itemdata.itemId)
        self:SetWndEasyImage(SellIconTrans, iconImg, function()
            CS.ShowObject(SellIconTrans, true)
        end)
    end
    local SellValueTrans = self:FindWndTrans(item, "SellValue")
    if SellValueTrans then
        local haveCount = gModelItem:GetNumByRefId(itemdata.itemId)
        local color = haveCount >= itemdata.itemNum and "#139057" or "#FB1E12"
        local str = string.format("<color=%s>%s</color>/%s", color, LUtil.NumberCoversion(haveCount), LUtil.NumberCoversion(itemdata.itemNum))
        self:SetWndText(SellValueTrans, str)
    end
end

------------------------------------------------------------------
return UISubPeInfo