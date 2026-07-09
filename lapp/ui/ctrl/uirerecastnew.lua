---
--- Created by LCM.
--- DateTime: 2024/3/5 14:47:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReRecastNew:LWnd
local UIReRecastNew = LxWndClass("UIReRecastNew", LWnd)

local UIBtnTabList = LXImport('LApp.UI.Common.UIBtnTabList')

UIReRecastNew.CHOOSE_ITEM = 0
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReRecastNew:UIReRecastNew()
    ---@type UIBtnTabList
    self._uiBtnTabList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReRecastNew:OnWndClose()
    if self._uiBtnTabList then
        self._uiBtnTabList:Destroy()
        self._uiBtnTabList = nil
    end
    if self._skillIconList then
        LUtil.ClearHashTable(self._skillIconList)
        self._skillIconList = nil
    end
    FireEvent(EventNames.REFRESH_OUTFITOPT_BAG)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReRecastNew:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    self._skillIconList = {}
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReRecastNew:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    if self._isEnus then
        self:InitTextSizeWithLanguage(self.mHideSkillRecastDesc, -1.5)
    end
    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    --self:InitTabBtnList()
    self:InitUITabList()
    self:ChangePageFunc(self._page, true)
    self:InitHandler()
end

function UIReRecastNew:OnRuneRecastAttrResp(pb)
    local serverData = self._runeData
    if not serverData then
        return
    end
    if pb.runeId ~= serverData.id then
        return
    end
    self:UpDateRuneServerData()
end

function UIReRecastNew:RefreshViewFunc()
    --self._payRecastItem = nil
    local isNeedClear = true
    if (self._payRecastItem and self._luckItemId and self._payRecastItem.itemId == self._luckItemId and ModelRune.TYPE_SKILLRECAST == self._page) then
        local haveNum = gModelItem:GetNumByRefId(self._luckItemId)
        isNeedClear = haveNum <= 0
    end

    if isNeedClear then
        self._payRecastItem = nil
    end

    self:InitNeedList()
    local func = self._pageRefreshViewList[self._page]
    if func then
        func()
    end
end

function UIReRecastNew:RefreshQuenchingPayList()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local refId = serverData.refId
    local isQuenching = gModelRune:IsCanQuenchingByRefId(refId)
    local descStr
    local isMaxClass = gModelRune:IsMaxClass(serverData)
    if isMaxClass or not isQuenching then
        descStr = ccClientText(24930)
    end
    self:SetWndText(self.mQuenchingNoPayDesc, descStr)
    self:InitQuenchingPayList()
end

function UIReRecastNew:OnRuneRecastResp(pb)
    local serverData = self._runeData
    if not serverData then
        return
    end
    if pb.runeId ~= serverData.id then
        return
    end
    self:UpDateRuneServerData()
end

function UIReRecastNew:OnDrawBotPageBtnCell(list, item, itemdata, itempos)
    local BtnTab2 = self:FindWndTrans(item, "BtnTab2")
    local pageIndex = itemdata.pageIndex
    local isSel = pageIndex == self._page
    self:SetWndTabText(BtnTab2, itemdata.btnName, -6, -40)
    local isOpen = self:CheckIsRuneMechanismOpen(pageIndex, true)
    local status = not isOpen and LWnd.StateGray or (isSel and LWnd.StateOn or LWnd.StateOff)
    self:SetWndTabStatus(BtnTab2, status)
    self:SetWndClick(BtnTab2, function()
        self:ChangePageFunc(pageIndex)
    end)
end

function UIReRecastNew:OnDrawNeedItemCell(list, item, itemdata, itempos)
    local IconTrans = self:FindWndTrans(item, "Icon")
    local NumTrans = self:FindWndTrans(item, "Num")
    local AddBtnTrans = self:FindWndTrans(item, "BtnDiv/AddBtn")
    local refId = itemdata.itemId
    if IconTrans then
        local icon = gModelItem:GetItemIconByRefId(refId)
        self:SetWndEasyImage(IconTrans, icon)
    end
    if NumTrans then
        local haveNum = gModelItem:GetNumByRefId(refId)
        haveNum = LUtil.NumberCoversion(haveNum)
        self:SetWndText(NumTrans, haveNum)
    end
    if AddBtnTrans then
        self:SetWndClick(AddBtnTrans, function()
            self:AddItemEvent(refId)
        end)
    end
end

function UIReRecastNew:OnClickAttrRecastHelpBtnFunc()
    self:OpenHelpWndByHelpId(123)
end

function UIReRecastNew:OnDrawQuenchingPayCell(list, item, itemdata, itempos)
    local ItemIconRoot = self:FindWndTrans(item, "ItemIconRoot")
    local CommonUI = self:FindWndTrans(ItemIconRoot, "CommonUI")
    local Icon = self:FindWndTrans(CommonUI, "Icon")
    local PayDiv = self:FindWndTrans(item, "GameObject/PayDiv")
    local ItemName = self:FindWndTrans(PayDiv, "ItemName")
    local ItemNum = self:FindWndTrans(PayDiv, "ItemNum")
    CS.ShowObject(CommonUI, true)
    local itemType, itemId, itemNum = itemdata.itemType, itemdata.itemId, itemdata.itemNum
    self:CreateCommonItem(ItemIconRoot, itemdata)

    local nameStr, numStr
    local haveNum
    if itemType == LItemTypeConst.TYPE_RUNE then
        nameStr = gModelRune:GetRuneNameByRefIdNew(itemId)
        local selRuneIdList = self._selRuneIdList
        if not selRuneIdList then
            selRuneIdList = {}
            self._selRuneIdList = selRuneIdList
        end
        --self._selUseRuneItemList = {}
        local selUseRuneItemList = self._selUseRuneItemList
        if not selUseRuneItemList then
            selUseRuneItemList = {}
            self._selUseRuneItemList = selUseRuneItemList
        end
        haveNum = #selRuneIdList + #selUseRuneItemList
        self:SetWndClick(Icon, function()
            GF.OpenWnd("UIReSelMals", {
                openType = 1,
                needRuneRefId = itemId,
                needRuneNum = itemNum,
                selRuneList = self._selRuneIdList,
                selRuneItemList = self._selUseRuneItemList,
                selRuneData = self._runeData,
                openPage = self._page,
                callFunc = function(selList, selRuneItemList)
                    if not self:IsWndValid() then
                        return
                    end
                    selList = selList or {}
                    self._selRuneIdList = {}
                    for i, v in ipairs(selList) do
                        table.insert(self._selRuneIdList, v)
                    end
                    selRuneItemList = selRuneItemList or {}
                    self._selUseRuneItemList = {}
                    for k, v in pairs(selRuneItemList) do
                        table.insert(self._selUseRuneItemList, v)
                    end
                    self:RefreshQuenchingPayList()
                    local isOpen = self:CheckIsRuneMechanismOpen(self._page, true)
                    if not isOpen then
                        self:AutoSelPage()
                    end
                    self:RefreshTabBtnList()
                end,
            })
        end)
    else
        nameStr = gModelItem:GetNameByRefId(itemId)
        haveNum = gModelItem:GetNumByRefId(itemId)
        self:SetWndClick(Icon, function()
            --gModelGeneral:ShowCommonItemTipWnd(itemdata)

            self:OpenGetWayWnd(itemId)
            --gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
        end)
    end
    local isEnough = haveNum >= itemNum
    local color = isEnough and "lightGreen" or "lightRed"
    local haveNumStr = LUtil.FormatColorStr(LUtil.NumberCoversion(haveNum), color)
    local itemNumStr = LUtil.NumberCoversion(itemNum)
    numStr = string.format("%s/%s", haveNumStr, itemNumStr)

    self:SetWndText(ItemName, nameStr)
    self:SetWndText(ItemNum, numStr)
    self:InitTextSizeWithLanguage(ItemNum, -4)
end

function UIReRecastNew:RefreshRuneSkillDiv()
    local serverData = self._runeData
    if not serverData then
        return
    end

    local skillId = serverData.skillId
    local skillList = {}
    for i, v in ipairs(skillId) do
        table.insert(skillList, {
            runeSkillRefId = v,
        })
    end
    self:CreateSkillDiv(self.mBeforeSkillDiv, { skillList = skillList }, 24904)

    local refId = serverData.refId
    local showSkillNum = gModelRune:GetShowSkillNumByRefId(refId)
    local nextSkillId = serverData.nextSkillId
    local nextSkillList = {}
    for i = 1, showSkillNum do
        table.insert(nextSkillList, {
            runeSkillRefId = nextSkillId[i],
        })
    end
    self:CreateSkillDiv(self.mLaterSkillDiv, { skillList = nextSkillList }, 24905)
end

function UIReRecastNew:OnDrawQuenchingStarCell(list, item, itemdata, itempos)
    local Star = self:FindWndTrans(item, "Star")
    CS.ShowObject(Star, itemdata.show)
end

function UIReRecastNew:OnDrawQuenchingAttrCell(list, item, itemdata, itempos)
    local ClassDiv = self:FindWndTrans(item, "ClassDiv")
    local LvDiv = self:FindWndTrans(item, "LvDiv")
    local AttrDiv = self:FindWndTrans(item, "AttrDiv")
    local showStatus = itemdata.showStatus
    local showClassDiv, showLvDiv, showAttrDiv = showStatus == 1, showStatus == 2, showStatus == 3
    CS.ShowObject(ClassDiv, showClassDiv)
    CS.ShowObject(LvDiv, showLvDiv)
    CS.ShowObject(AttrDiv, showAttrDiv)
    if showClassDiv then
        self:CreateClassDiv(ClassDiv, itemdata)
    elseif showLvDiv then
        self:CreateLvDiv(LvDiv, itemdata)
    elseif showAttrDiv then
        self:CreateQuenchingAttrDiv(AttrDiv, itemdata)
    end
end

function UIReRecastNew:OnDrawAttrCell(list, item, itemdata, itempos)
    local NoAttrDiv = self:FindWndTrans(item, "NoAttrDiv")
    local AttrDiv = self:FindWndTrans(item, "AttrDiv")
    local attrRefRefId = itemdata
    local isNoAttrRefId = attrRefRefId == 0
    CS.ShowObject(NoAttrDiv, isNoAttrRefId)
    CS.ShowObject(AttrDiv, not isNoAttrRefId)
    if isNoAttrRefId then
        local AttrName = self:FindWndTrans(NoAttrDiv, "AttrName")
        self:SetWndText(AttrName, ccClientText(24840))
    else
        local runeAttrRef = gModelRune:GetAttrInfoByRefId(attrRefRefId)
        if runeAttrRef then
            local attr = runeAttrRef.attr
            local first = attr[1]
            if first then
                local AttrIcon = self:FindWndTrans(AttrDiv, "AttrIcon")
                local AttrName = self:FindWndTrans(AttrDiv, "AttrName")
                local AttrNum = self:FindWndTrans(AttrDiv, "AttrNum")
                local attrRefId, attrType, attrVal = first.attrRefId, first.attrType, first.attrVal
                local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
                self:SetWndEasyImage(AttrIcon, attrIcon)
                local attrName = gModelHero:GetAttributeNameById(attrRefId)
                self:SetWndText(AttrName, attrName)
                local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, attrType, attrVal)
                self:SetWndText(AttrNum, value)
            end
        end
    end
end

function UIReRecastNew:OnClickAttrRecastBtnFunc(haveResult)
    local serverData = self._runeData
    if not serverData then
        return
    end
    local runeId = serverData.id
    local payList, itemType = self:GetAttrRecastItemList()
    local noEnoughItem = nil
    for i, v in ipairs(payList) do
        local itemId = v.itemId
        if itemId ~= UIReRecastNew.CHOOSE_ITEM then
            local haveNum = gModelItem:GetNumByRefId(itemId)
            if haveNum < v.itemNum then
                noEnoughItem = itemId
                break
            end
        end
    end
    if noEnoughItem then
        self:OpenGetWayWnd(noEnoughItem)
        --gModelGeneral:OpenGetWayWnd({itemId = noEnoughItem,srcWnd = self:GetWndName()})
        return
    end
    local func = function()
        if not self:IsWndValid() then
            return
        end
        gModelRune:OnRuneRecastAttrReq(runeId, itemType)
    end
    if haveResult then
        self:OnRecastTipsFunc(func)
    else
        func()
    end
end

function UIReRecastNew:GetSkillRecastItemList()
    local list = {}
    local serverData = self._runeData
    if not serverData then
        return list
    end
    local refId = serverData.refId
    local showSkillNum = gModelRune:GetShowSkillNumByRefId(refId)
    local isNotSkill = showSkillNum <= 0
    if isNotSkill then
        return list
    end
    local recastNeedItem, recastReplaceItem = gModelRune:GetRuneSkillRecastItemListByRefId(refId)
    if not recastNeedItem or not recastReplaceItem then
        return list
    end
    local isRecastPayFull = true
    local recastNeedItemList = {}
    recastNeedItemList.itemType = 1
    local nItemList = {}
    recastNeedItemList.itemList = nItemList
    for i, v in ipairs(recastNeedItem) do
        table.insert(nItemList, { itemType = v.itemType, itemId = v.itemId, itemNum = v.itemNum, })
    end

    local recastReplaceItemList = {}
    recastReplaceItemList.itemType = 2
    local rItemList = {}
    recastReplaceItemList.itemList = rItemList
    for i, v in ipairs(recastReplaceItem) do
        table.insert(rItemList, { itemType = v.itemType, itemId = v.itemId, itemNum = v.itemNum, })
    end

    local skillFirstChoose = self._skillFirstChoose
    local firstChooseList = skillFirstChoose and recastReplaceItemList.itemList or recastNeedItemList.itemList
    local firstChooseType = skillFirstChoose and recastReplaceItemList.itemType or recastNeedItemList.itemType
    local otherChooseList = (not skillFirstChoose) and recastReplaceItemList.itemList or recastNeedItemList.itemList
    local otherChooseType = (not skillFirstChoose) and recastReplaceItemList.itemType or recastNeedItemList.itemType
    local haveNum
    for i, v in ipairs(firstChooseList) do
        if not isRecastPayFull then
            break
        end
        local itemId, itemNum = v.itemId, v.itemNum
        haveNum = gModelItem:GetNumByRefId(itemId)
        isRecastPayFull = haveNum >= itemNum
    end
    --- 重铸石优先被勾选，先判断 recastReplaceItem 是否满足，满足的话使用 recastReplaceItem
    --- 如果 recastReplaceItem 不满足，判断 recastNeedItem 是否满足，如果满足用 recastNeedItem ，不满足则使用 recastReplaceItem
    local itemType = 1
    if isRecastPayFull then
        list = firstChooseList
        itemType = firstChooseType
    else
        isRecastPayFull = true
        for i, v in ipairs(otherChooseList) do
            if not isRecastPayFull then
                break
            end
            local itemId, itemNum = v.itemId, v.itemNum
            haveNum = gModelItem:GetNumByRefId(itemId)
            isRecastPayFull = haveNum >= itemNum
        end
        if isRecastPayFull then
            list = otherChooseList
            itemType = otherChooseType
        else
            list = firstChooseList
            itemType = firstChooseType
        end
    end
    --[[	local useRecastReplaceItem = itemType == 2 								-- 使用是替换道具
        if skillFirstChoose and useRecastReplaceItem then
        end]]
    -- local luckItem,godItem = gModelRune:GetLucItemAndGodItemId(refId)
    -- if luckItem or godItem then
    -- 	local tRecastNum,subNum,recastNum = self:GetRecastNum()
    -- 	local isEnd = subNum <= 0
    -- 	if isEnd and recastNum ~= 0 then
    -- 		self._payRecastItem = nil
    -- 	else
    -- 		local payRecastItem = self._payRecastItem
    -- 		if payRecastItem then
    -- 			table.insert(list,{itemType = payRecastItem.itemType,itemId = payRecastItem.itemId,itemNum = payRecastItem.itemNum,openSelWnd = true})
    -- 		else
    -- 			table.insert(list,{itemType = LItemTypeConst.TYPE_ITEM,itemId = UIReRecastNew.CHOOSE_ITEM,itemNum = 0,})
    -- 		end
    -- 	end
    -- end
    return list, itemType
end
----------------------------------------------- RefreshSkillRecastView -----------------------------------------------

----------------------------------------------- RefreshAttrRecastView -----------------------------------------------
function UIReRecastNew:InitAttrList(trans, list)
    local key = trans:GetInstanceID()
    local uiAttrList = self:FindUIScroll(key)
    if uiAttrList then
        uiAttrList:RefreshList(list)
    else
        uiAttrList = self:GetUIScroll(key)
        uiAttrList:Create(trans, list, function(...)
            self:OnDrawAttrCell(...)
        end)
    end
    local isEnAble = #list > 4
    uiAttrList:EnableScroll(isEnAble)
end

function UIReRecastNew:RefresrhNotQuenching()
    local serverData = self._runeData
    if not serverData then
        return
    end
    self:RefreshQuenchingTop()
    self:RefreshQuenchingPayList()
    self:InitQuenchingDescList()
end

function UIReRecastNew:OnClickSkillRecastSaveBtnFunc()
    --[[	local serverData = self._runeData
        if not serverData then return end
        local runeId = serverData.id
        gModelRune:OnRuneRecastSaveReq(runeId,ModelRune.RECAST_SKILL)]]
    self:OnClickOptBtnFunc(ModelRune.RECAST_SKILL)
end

function UIReRecastNew:OnClickQuenchingBtnFunc()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local runeRefId = serverData.refId
    local isQuenching = gModelRune:IsCanQuenchingByRefId(runeRefId)
    if not isQuenching then
        GF.ShowMessage(ccClientText(24922))
        return
    end
    local nextSkillIdLen = #serverData.nextSkillId
    local nextAttrIdLen = #serverData.nextAttrId
    if nextSkillIdLen > 0 or nextAttrIdLen > 0 then
        GF.ShowMessage(ccClientText(24921))
        return
    end
    local isMaxClass = gModelRune:IsMaxQuenching(serverData.clazzRefId)
    if isMaxClass then
        GF.ShowMessage(ccClientText(24931))
        return
    end

    -- self:OnRuneQuenchingReq()
    self:OnRuneQuenchingClazzReq()
end

function UIReRecastNew:RefreshBotRuneAttrView()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local nextAttrId = serverData.nextAttrId
    local nextAttrIdLen = #nextAttrId
    local showResultDiv = nextAttrIdLen > 0
    CS.ShowObject(self.mAttrRecastBtn, not showResultDiv)
    CS.ShowObject(self.mAttrRecastResultDiv, showResultDiv)
end

function UIReRecastNew:CreateCommonItem(trans, itemdata)
    local InstanceID = trans:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    local iconTrans = self:FindWndTrans(trans, "CommonUI/Icon")
    baseClass:Create(iconTrans)
    self:SetIconClickScale(iconTrans, true)
    local itype, refId, count = itemdata.itemType, itemdata.itemId, itemdata.itemNum
    baseClass:SetCommonReward(itype, refId, count)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()
end

function UIReRecastNew:InitUITabList()
    local dataList = {}
    for k, v in pairs(self._pageViewList) do
        table.insert(dataList, v)
    end
    table.sort(dataList, function(a, b)
        return a.btnType > b.btnType
    end)

    ---@type UIBtnTabList
    local uiBtnTabList = UIBtnTabList:New()
    self._uiBtnTabList = uiBtnTabList
    uiBtnTabList:SetCheckLockFunc(function(itemdata, itempos)
        return self:CheckIsRuneMechanismOpen(itemdata.btnType, true)
    end)
    if self._isVie then
        uiBtnTabList:SetData(self, self.mTabScroll, dataList, self._page, nil, function(textTran)
            self:InitTextLineWithLanguage(textTran, -10)
            self:InitTextSizeWithLanguage(textTran, -3)
            self:SetAnchorPos(textTran, Vector2.New(0, -20))
            LxUiHelper.SetSizeWithCurAnchor(textTran, 0, 120)
        end)
    else
        uiBtnTabList:SetData(self, self.mTabScroll, dataList, self._page)
    end
end

function UIReRecastNew:RefreshAttrRecastView()
    self:RefreshAttrRecastGouStatus()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local root = self.mAttrRecastRuneRoot
    self:CreateRuneIcon(root, serverData, true)
    self:RefreshRuneAttrDiv()
    self:RefreshBotRuneAttrView()
    self:RefreshAttrRecastPayList()

    local refId = serverData.refId
    local recastNeedItem1, recastReplaceItem1 = gModelRune:GetRuneAttrRecastItemListByRefId(refId)
    local itemName = gModelItem:GetNameByRefId(recastReplaceItem1[1].itemId)
    self:SetWndText(self.mAttrRecastGouTxt, itemName)
end

function UIReRecastNew:InitQuenchingAttrList(trans, list)
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...)
            self:OnDrawQuenchingAttrCell(...)
        end)
    end
end
----------------------------------------------- CommonFunc -----------------------------------------------
function UIReRecastNew:CreateRuneIcon(trans, itemdata, onClickFunc)
    local InstanceID = trans:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    local iconTrans = self:FindWndTrans(trans, "CommonUI/Icon")
    baseClass:Create(iconTrans)
    self:SetIconClickScale(iconTrans, true)
    baseClass:SetRuneData(itemdata)
    baseClass:DoApply()
    if onClickFunc then
        self:SetWndClick(iconTrans, function()
            self:OpenRuneTips(itemdata)
        end)
    end
end

function UIReRecastNew:OnRuneQuenchingResp(pb)
    local serverData = self._runeData
    if not serverData then
        return
    end
    if pb.runeId ~= serverData.id then
        return
    end
    self:UpDateRuneServerData()
end

function UIReRecastNew:OpenHelpWndByHelpId(helpId)
    GF.OpenWnd("UIBzTips", { refId = helpId })
end

function UIReRecastNew:OnItemChange()
    self:RefreshViewFunc()
end

function UIReRecastNew:RefreshSkillRecastJD()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local refId = serverData.refId
    local ref = gModelRune:GetRuneInfoByRefId(refId)
    if not ref then
        return
    end
    local recast = serverData.recast
    local recastNum, subNum = self:GetRecastNum()
    if not recastNum or not subNum then
        return
    end
    local percentage = recast / recastNum
    LxUiHelper.SetProgress(self.mSkillRecastBar, percentage)
    local numStr = string.format("%s/%s", recast, recastNum)
    self:SetWndText(self.mSkillRecastNum, numStr)
    local str = ""
    local isEndShow = subNum <= 0

    -- local uiHyperText = UIHyperText:New()
    -- uiHyperText:Create(self.mHideSkillRecastClickDesc)
    -- local skillTitle =  ccClientText(13217)
    -- skillTitle = uiHyperText:AddHyper(skillTitle,{func = function()
    -- 	GF.OpenWnd("UIReJNPreView",{page = 3})
    -- end})
    -- self:SetWndText(self.mHideSkillRecastClickDesc,LUtil.FormatColorStr(skillTitle,"darkYellow"))
    -- CS.ShowObject(self.mHideSkillRecastClickDesc,true)

    if isEndShow then
        str = ccClientText(24951)
        --str =  ccClientText(24843)
    else
        str = ccClientText(24906, subNum, "")
    end
    self:SetWndText(self.mHideSkillRecastDesc, str)


end

function UIReRecastNew:RefreshAttrRecastGouStatus()
    CS.ShowObject(self.mAttrRecastGou, self._attrFirstChoose)
end

function UIReRecastNew:OpenGetWayWnd(refId)
    local wndInst = GF.FindFirstWndByName("UIGeay")
    if wndInst then
        return
    end
    gModelGeneral:OpenGetWayWnd({ itemId = refId, srcWnd = self:GetWndName() })
end

function UIReRecastNew:RefreshFunc()
    for k, v in pairs(self._pageViewList) do
        local isSel = v.pageIndex == self._page
        CS.ShowObject(v.viewTrans, isSel)
        CS.ShowObject(v.botViewTrans, isSel)
        CS.ShowObject(v.botOptViewTrans, isSel)
    end
    self:RefreshViewFunc()
    self:RefreshTabBtnList()
end

function UIReRecastNew:AutoSelPage()
    local runeData = self._runeData
    if not runeData then
        return
    end
    local refId = runeData.refId
    local isOpen = gModelRune:CheckIsMechanismOpen(refId, self._page)
    if not isOpen then
        local mechanism = gModelRune:GetMechanismListByRefId(refId)
        for i, v in ipairs(mechanism) do
            if v == 1 then
                self._page = i
                break
            end
        end
        self:RefreshFunc()
    end
end

function UIReRecastNew:CreateSkillDiv(trans, itemdata, textId)
    local LightLine = self:FindWndTrans(trans, "LightLine")
    self:SetTextTile(LightLine, ccClientText(textId))
    local SkillList = self:FindWndTrans(trans, "SkillList")
    self:InitSkillList(SkillList, itemdata.skillList)
end

function UIReRecastNew:InitQuenchingPayList()
    local serverData = self._runeData
    local list = serverData and gModelRune:GetQuenchingPayList(serverData) or {}
    local uiQuenchingPayList = self._uiQuenchingPayList
    if uiQuenchingPayList then
        uiQuenchingPayList:RefreshList(list)
    else
        uiQuenchingPayList = self:GetUIScroll("uiQuenchingPayList")
        self._uiQuenchingPayList = uiQuenchingPayList
        uiQuenchingPayList:Create(self.mQuenchingPayList, list, function(...)
            self:OnDrawQuenchingPayCell(...)
        end)
    end
end

function UIReRecastNew:OnClickSkillRecastHelpBtnFunc()
    self:OpenHelpWndByHelpId(122)
end

function UIReRecastNew:OpenSkillSelWnd()
    GF.OpenWnd("UIReRecastJNSel", { runeData = self._runeData })

    if true then
        return
    end

    local serverData = self._runeData
    if not serverData then
        return
    end
    local refId = serverData.refId
    local ref = gModelRune:GetRuneInfoByRefId(refId)
    if not ref then
        return
    end
    local accumulateFixedSkill = ref.accumulateFixedSkill
    local payList, itemType = self:GetSkillRecastItemList()
    if not itemType then
        if LOG_INFO_ENABLED then
            printInfoNR("没有配置的技能选择类型")
        end
        return
    end
    GF.OpenWnd("UIReJNSel", { runeId = serverData.id, selectType = ModelRune.RECASTTYPE_4, skillList = accumulateFixedSkill, useItemType = itemType })
end

function UIReRecastNew:GetRecastNum()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local refId = serverData.refId
    local ref = gModelRune:GetRuneInfoByRefId(refId)
    if not ref then
        return
    end
    local recastNum = ref.recastNum
    local tRecastNum = recastNum - 1
    local recast = serverData.recast
    local subNum = tRecastNum - recast
    return tRecastNum, subNum, recastNum
end

function UIReRecastNew:InitHandler()
    self:SetWndClick(self.mBtnShowSkill, function()
        self:OpenSkillSelWnd()
    end)
end

function UIReRecastNew:OnClickSkillRecastGouBgBtnFunc()
    self._skillFirstChoose = not self._skillFirstChoose
    LPlayerPrefs.SetRuneSkillFirstChoose(tostring(self._skillFirstChoose))
    self:RefreshSkillRecastGouStatus()
    self:RefreshSkillRecastPayList()
end

function UIReRecastNew:OnDrawQuenchingDescCell(list, item, itemdata, itempos)
    local StarDiv = self:FindWndTrans(item, "StarDiv")
    local NoActImg = self:FindWndTrans(StarDiv, "NoActImg")
    local ActImg = self:FindWndTrans(StarDiv, "ActImg")
    local act = itemdata.act
    CS.ShowObject(ActImg, act)
    CS.ShowObject(NoActImg, not act)
    self:SetTextTile(item, itemdata.desc)
end

function UIReRecastNew:RefreshSkillRecastPayList()
    local payList = self:GetSkillRecastItemList()
    local isEmpty = #payList < 1
    local desc = isEmpty and ccClientText(24933) or ""
    local uiPayList = self.mSkillRecastPayList
    self:SetTextTile(uiPayList, desc)
    self:CreatePayList(uiPayList, payList)
end

function UIReRecastNew:InitText()
    self:SetWndText(self.mSkillPreBtnName, ccClientText(13205))
    self:SetTextTile(self.mSkillRecastTxt, ccClientText(24908))
    self:SetTextTile(self.mAttrRecastTxt, ccClientText(24908))
    self:SetTextTile(self.mQuenchingTxt, ccClientText(24919))
    self:SetTextTile(self.mChangeRuneBtn, ccClientText(24903))

    self:SetWndText(self.mSkillRecastDesc, string.replace(ccClientText(24911), ccClientText(13217)))

    self:SetWndText(self.mTxtClose, ccClientText(30205))
    self:SetWndButtonText(self.mSkillRecastBtn, ccClientText(24909))
    self:SetWndButtonText(self.mSkillRecastNewBtn, ccClientText(24909))
    self:SetWndButtonText(self.mSkillRecastSaveBtn, ccClientText(24847))
    self:SetWndButtonText(self.mAttrRecastBtn, ccClientText(24909))
    self:SetWndButtonText(self.mAttrRecastNewBtn, ccClientText(24909))
    self:SetWndButtonText(self.mAttrRecastSaveBtn, ccClientText(24847))
    self:InitAttrRecastDescList()


end

function UIReRecastNew:GetAttrRecastItemList()
    local list = {}
    local serverData = self._runeData
    if not serverData then
        return list
    end
    local refId = serverData.refId
    local runeRef = gModelRune:GetRuneInfoByRefId(refId)
    if not runeRef then
        return
    end
    local attrGroupId = runeRef.attrGroupId
    local isNotAttr = string.isempty(attrGroupId)
    if isNotAttr then
        return list
    end
    local recastNeedItem1, recastReplaceItem1 = gModelRune:GetRuneAttrRecastItemListByRefId(refId)
    if not recastNeedItem1 or not recastReplaceItem1 then
        return list
    end
    local isRecastPayFull = true
    local recastNeedItem1List = {}
    recastNeedItem1List.itemType = 1
    local nItemList = {}
    recastNeedItem1List.itemList = nItemList
    for i, v in ipairs(recastNeedItem1) do
        table.insert(nItemList, { itemType = v.itemType, itemId = v.itemId, itemNum = v.itemNum, })
    end

    local recastReplaceItem1List = {}
    recastReplaceItem1List.itemType = 2
    local rItemList = {}
    recastReplaceItem1List.itemList = rItemList
    for i, v in ipairs(recastReplaceItem1) do
        table.insert(rItemList, { itemType = v.itemType, itemId = v.itemId, itemNum = v.itemNum, })
    end

    local attrFirstChoose = self._attrFirstChoose
    local firstChooseList = attrFirstChoose and recastReplaceItem1List.itemList or recastNeedItem1List.itemList
    local firstChooseType = attrFirstChoose and recastReplaceItem1List.itemType or recastNeedItem1List.itemType
    local otherChooseList = (not attrFirstChoose) and recastReplaceItem1List.itemList or recastNeedItem1List.itemList
    local otherChooseType = (not attrFirstChoose) and recastReplaceItem1List.itemType or recastNeedItem1List.itemType
    local haveNum
    for i, v in ipairs(firstChooseList) do
        if not isRecastPayFull then
            break
        end
        local itemId, itemNum = v.itemId, v.itemNum
        haveNum = gModelItem:GetNumByRefId(itemId)
        isRecastPayFull = haveNum >= itemNum
    end
    --- 重铸石优先被勾选，先判断 recastReplaceItem 是否满足，满足的话使用 recastReplaceItem
    --- 如果 recastReplaceItem 不满足，判断 recastNeedItem 是否满足，如果满足用 recastNeedItem ，不满足则使用 recastReplaceItem
    local itemType = 1
    if isRecastPayFull then
        list = firstChooseList
        itemType = firstChooseType
    else
        isRecastPayFull = true
        for i, v in ipairs(otherChooseList) do
            if not isRecastPayFull then
                break
            end
            local itemId, itemNum = v.itemId, v.itemNum
            haveNum = gModelItem:GetNumByRefId(itemId)
            isRecastPayFull = haveNum >= itemNum
        end
        if isRecastPayFull then
            list = otherChooseList
            itemType = otherChooseType
        else
            list = firstChooseList
            itemType = firstChooseType
        end
    end
    return list, itemType
end

function UIReRecastNew:OnClickAttrRecastBgBtnFunc()
    self._attrFirstChoose = not self._attrFirstChoose
    LPlayerPrefs.SetRuneAttrFirstChoose(tostring(self._attrFirstChoose))
    self:RefreshAttrRecastGouStatus()
    self:RefreshAttrRecastPayList()
end

function UIReRecastNew:CreateClassDiv(trans, itemdata)
    local AttrNameTrans = self:FindWndTrans(trans, "AttrName")
    local BeforeStarListTrans = self:FindWndTrans(trans, "BeforeStarList")
    local BNoStarTxtTrans = self:FindWndTrans(BeforeStarListTrans, "NoStarTxt")
    local ArrowTrans = self:FindWndTrans(trans, "Arrow")
    local LaterStarListTrans = self:FindWndTrans(trans, "LaterStarList")
    local LNoStarTxtTrans = self:FindWndTrans(LaterStarListTrans, "NoStarTxt")
    self:SetWndText(AttrNameTrans, ccClientText(24833))
    self:SetWndText(BNoStarTxtTrans, ccClientText(24923))
    self:SetWndText(LNoStarTxtTrans, ccClientText(24923))
    local curStarNum = itemdata.curStarNum
    local nextStarNum = itemdata.nextStarNum
    local showBStarTxt = curStarNum <= 0
    local showLStarTxt = nextStarNum <= 0
    local isMax = nextStarNum == -1
    CS.ShowObject(BNoStarTxtTrans, showBStarTxt)
    local showArrow = not isMax
    local showNext = false
    if isMax then
        showNext = false
    else
        showNext = showLStarTxt
    end
    CS.ShowObject(ArrowTrans, showArrow)
    CS.ShowObject(LNoStarTxtTrans, showNext)

    --[[	CS.ShowObject(BNoStarTxtTrans,showBStarTxt)
        CS.ShowObject(LNoStarTxtTrans,nextStarNum > 0 and curStarNum ~= nextStarNum)
        CS.ShowObject(ArrowTrans,nextStarNum > 0)]]
    self:CreateQuenchingStarList(BeforeStarListTrans, curStarNum)
    self:CreateQuenchingStarList(LaterStarListTrans, nextStarNum)
end

function UIReRecastNew:UpDateRuneServerData(runeId, onlyUpData)
    local runeData
    if runeId then
        runeData = gModelRune:GetServerDataById(runeId)
    else
        local serverData = self._runeData
        if serverData then
            runeData = gModelRune:GetServerDataById(serverData.id)
        end
    end
    if not runeData then
        return
    end
    self._runeData = runeData
    if onlyUpData then
        return
    end
    self:RefreshViewFunc()
end

function UIReRecastNew:OpenRuneSpecialWnd()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local refId = serverData.refId
    GF.OpenWnd("UIReSpRecast", { runeRefId = refId, selItemData = self._payRecastItem,
                                         func = function(selItemData)
                                             if not self:IsWndValid() then
                                                 return
                                             end
                                             self._payRecastItem = selItemData
                                             self:RefreshSkillRecastPayList()
                                         end }
    )
end

function UIReRecastNew:CreateQuenchingAttrDiv(trans, itemdata)
    local AttrIconTrans = self:FindWndTrans(trans, "AttrIcon")
    local AttrNameTrans = self:FindWndTrans(trans, "AttrName")
    local AttrNumBTrans = self:FindWndTrans(trans, "AttrNumB")
    local ArrowTrans = self:FindWndTrans(trans, "Arrow")
    local AttrNumLTrans = self:FindWndTrans(trans, "AttrNumL")
    local attrRefId = itemdata.attrRefId
    local attrType = itemdata.attrType
    local beforeAttrVal = itemdata.beforeAttrVal
    local laterAttrVal = itemdata.laterAttrVal
    local isShowNext = laterAttrVal ~= nil and laterAttrVal >= beforeAttrVal
    local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
    self:SetWndEasyImage(AttrIconTrans, attrIcon)
    local attrName = gModelHero:GetAttributeNameById(attrRefId)
    self:SetWndText(AttrNameTrans, attrName)
    local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, attrType, beforeAttrVal)
    self:SetWndText(AttrNumBTrans, value)
    CS.ShowObject(ArrowTrans, isShowNext)
    CS.ShowObject(AttrNumLTrans, isShowNext)
    if isShowNext then
        local nextValue = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, attrType, laterAttrVal)
        self:SetWndText(AttrNumLTrans, nextValue)
    end
end

function UIReRecastNew:OnClickQuenchingHelpBtnFunc()
    --[[	local preRune = {
            id = "9002605000000019540",
            playerId = "9002601000000011002",
            refId = 206401,
            heroId = "0",
            skillId = {1142,1162},
            attrId = {4002,4003},
            recast = 0,
            score = 24737.294921875,
            state = 0,
            levelRefId = 1011,
            clazzRefId = 1,
        }
        local newRune = {
            id = "9002605000000019540",
            playerId = "9002601000000011002",
            refId = 206401,
            heroId = "0",
            skillId = {1143,1163},
            attrId = {5002,5004},
            recast = 0,
            score = 24790.009765625,
            state = 0,
            levelRefId = 1011,
            clazzRefId = 2,
        }
        GF.OpenWnd("UIReUpClass",{
            preRune = preRune,
            newRune = newRune,
        })]]
    self:OpenHelpWndByHelpId(124)
end

function UIReRecastNew:OnDrawPayItemCell(list, item, itemdata, itempos)
    local ItemIconRoot = self:FindWndTrans(item, "ItemIconRoot")
    local CommonUI = self:FindWndTrans(ItemIconRoot, "CommonUI")
    local Icon = self:FindWndTrans(CommonUI, "Icon")
    local SelRuneImg = self:FindWndTrans(ItemIconRoot, "SelRuneImg")
    local PayDiv = self:FindWndTrans(item, "GameObject/PayDiv")
    local ItemName = self:FindWndTrans(PayDiv, "ItemName")
    local ItemNum = self:FindWndTrans(PayDiv, "ItemNum")
    local itemType, itemId, itemNum = itemdata.itemType, itemdata.itemId, itemdata.itemNum
    local showCommonIcon = itemId ~= UIReRecastNew.CHOOSE_ITEM
    CS.ShowObject(CommonUI, showCommonIcon)
    CS.ShowObject(SelRuneImg, not showCommonIcon)
    local showItemName, showItemNum = "", ""
    if showCommonIcon then
        self:CreateCommonItem(ItemIconRoot, itemdata)
        local haveNum = gModelItem:GetNumByRefId(itemId)
        local isEnough = haveNum >= itemNum
        local color = isEnough and "lightGreen" or "lightRed"
        local haveNumStr = LUtil.FormatColorStr(LUtil.NumberCoversion(haveNum), color)
        showItemName = gModelItem:GetNameByRefId(itemId)
        local itemNumStr = LUtil.NumberCoversion(itemNum)
        showItemNum = string.format("%s/%s", haveNumStr, itemNumStr)
        self:SetWndClick(Icon, function()
            if itemdata.openSelWnd then
                self:OpenRuneSpecialWnd()
            else
                --gModelGeneral:ShowCommonItemTipWnd(itemdata)
                --gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
                self:OpenGetWayWnd(itemId)
            end
        end)
    else
        self:SetWndClick(SelRuneImg, function()
            self:OpenRuneSpecialWnd()
        end)
    end
    self:SetWndText(ItemName, showItemName)
    self:SetWndText(ItemNum, showItemNum)
end

function UIReRecastNew:OnClickAttrRecastSaveBtnFunc()
    --[[	local serverData = self._runeData
        if not serverData then return end
        local runeId = serverData.id
        gModelRune:OnRuneRecastSaveReq(runeId,ModelRune.RECAST_ATTR)]]
    self:OnClickOptBtnFunc(ModelRune.RECAST_ATTR)
end

function UIReRecastNew:OnRuneQuenchingReq()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local list = serverData and gModelRune:GetQuenchingPayList(serverData) or {}
    local noEnoughItem
    for i, v in ipairs(list) do
        local itemId, itemNum = v.itemId, v.itemNum
        local haveNum = gModelItem:GetNumByRefId(itemId)
        if haveNum < itemNum then
            noEnoughItem = itemId
            break
        end
    end
    if noEnoughItem then
        self:OpenGetWayWnd(noEnoughItem)
        --gModelGeneral:OpenGetWayWnd({itemId = noEnoughItem,srcWnd = self:GetWndName()})
        return
    end
    gModelHero:SetNeedHeroPowerTips(true, self._heroId)
    local runeId = serverData.id
    gModelRune:OnRuneQuenchingReq(runeId)
end
----------------------------------------------- RefreshAttrRecastView -----------------------------------------------

----------------------------------------------- RefreshQuenchingView -----------------------------------------------

function UIReRecastNew:RefreshQuenchingRuneIcon()
    local serverData = self._runeData
    if not serverData then
        return
    end
    self:CreateRuneIcon(self.mQuenchingBRuneRoot, serverData)
    local curRefId = serverData.refId
    local isQuenching = gModelRune:IsCanQuenchingByRefId(curRefId)
    local isMaxClass = gModelRune:IsMaxClass(serverData)
    local showNextTrans = isQuenching and not isMaxClass or false
    local nextRuneRoot = self.mQuenchingLRuneRoot
    local quenchingArrowDiv = self.mQuenchingArrowDiv
    CS.ShowObject(nextRuneRoot, showNextTrans)
    CS.ShowObject(quenchingArrowDiv, showNextTrans)
    if showNextTrans then
        local newServerData = table.clone(serverData)
        -- local isUpClass = gModelRune:CheckIsUpClass(serverData)
        -- if isUpClass then
        -- local clazzRefId = newServerData.clazzRefId
        local classRef = gModelRune:GetInitRuneQuenchingClassRefByRefId(serverData.clazzRefId)
        -- clazzRefId = classRef and classRef.nextClass or clazzRefId
        -- local refId = classRef and classRef.upQuality or newServerData.refId
        newServerData.clazzRefId = serverData.clazzRefId + 1
        newServerData.refId = classRef and classRef.upQuality
        -- else
        -- 	local levelRefId = newServerData.levelRefId
        -- 	local levelRef = gModelRune:GetRuneQuenchingRefByRefId(levelRefId)
        -- 	if levelRef then
        -- 		local nextLevel = levelRef.nextLevel
        -- 		if nextLevel ~= -1 then
        -- 			newServerData.levelRefId = nextLevel
        -- 		end
        -- 	end
        -- end
        self:CreateRuneIcon(nextRuneRoot, newServerData)
    end
end

function UIReRecastNew:OnRuneRecastSaveResp(pb)
    local serverData = self._runeData
    if not serverData then
        return
    end
    if pb.runeId ~= serverData.id then
        return
    end
    self:UpDateRuneServerData()
end

function UIReRecastNew:CreateAttrDiv(trans, itemdata, textId)
    local LightLine = self:FindWndTrans(trans, "LightLine")
    self:SetTextTile(LightLine, ccClientText(textId))
    local AttrList = self:FindWndTrans(trans, "AttrList")
    self:InitAttrList(AttrList, itemdata.attrList)
end

function UIReRecastNew:CreateLvDiv(trans, itemdata)
    local AttrNameTrans = self:FindWndTrans(trans, "AttrName")
    local AttrNumBTrans = self:FindWndTrans(trans, "AttrNumB")
    local ArrowTrans = self:FindWndTrans(trans, "Arrow")
    local AttrNumLTrans = self:FindWndTrans(trans, "AttrNumL")
    self:SetWndText(AttrNameTrans, ccClientText(24834))
    local curLevelNum = itemdata.curLevelNum
    self:SetWndText(AttrNumBTrans, curLevelNum)
    local nextLevelNum = itemdata.nextLevelNum
    local showNextLevel = nextLevelNum ~= nil and nextLevelNum ~= 0
    CS.ShowObject(ArrowTrans, showNextLevel)
    CS.ShowObject(AttrNumLTrans, showNextLevel)
    if showNextLevel then
        self:SetWndText(AttrNumLTrans, nextLevelNum)
    end
end

function UIReRecastNew:OnClickChangeRuneBtnFunc()
    GF.OpenWnd("UIReSelMals", {
        openType = 2,
        selRuneData = self._runeData,
        openPage = self._page,
        callFunc = function(selRuneData)
            if not self:IsWndValid() then
                return
            end
            if not selRuneData then
                return
            end
            local id = selRuneData.id
            self:UpDateRuneServerData(id)
            local isOpen = self:CheckIsRuneMechanismOpen(self._page, true)
            if not isOpen then
                self:AutoSelPage()
            end
            self:RefreshTabBtnList()
        end,
    })
end

function UIReRecastNew:CreatePayList(trans, list)
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...)
            self:OnDrawPayItemCell(...)
        end)
    end
end

function UIReRecastNew:RefresrhQuenching()
    self._selRuneIdList = {}
    self._selUseRuneItemList = {}
    local serverData = self._runeData
    if not serverData then
        return
    end
    self:RefreshQuenchingTop()
    self:RefreshQuenchingPayList()
    self:InitQuenchingDescList()
end

function UIReRecastNew:OpenRuneTips(serverData)
    local data = {
        runeData = serverData,
    }
    gModelGeneral:OpenRuneInfoTip(data)
end

function UIReRecastNew:CheckIsRuneMechanismOpen(page, notShowTip)
    local runeData = self._runeData
    if not runeData then
        return false
    end
    local refId = runeData.refId
    local str = ""
    local isOpen = gModelRune:CheckIsMechanismOpen(refId, page)
    if not isOpen then
        if page == ModelRune.TYPE_SKILLRECAST then
            str = ccClientText(24933)
        elseif page == ModelRune.TYPE_ATTRRECAST then
            str = ccClientText(24934)
        elseif page == ModelRune.TYPE_QUENCHING then
            str = ccClientText(24935)
        end
        if not notShowTip and not string.isempty(str) then
            GF.ShowMessage(str)
        end
    end
    return isOpen, nil, str
end

function UIReRecastNew:InitData()
    local runeData = self:GetWndArg("runeData")
    self._runeData = runeData

    local luckItem, godItem = runeData and gModelRune:GetLucItemAndGodItemId(runeData.refId)
    self._luckItemId = luckItem

    local page = self:GetWndArg("page")
    if not page then
        page = ModelRune.TYPE_SKILLRECAST
    end
    self._page = page

    self._heroId = self:GetWndArg("heroId")

    self._skillFirstChoose = toboolean(LPlayerPrefs.runeSkillFirstChoose)            -- 技能重铸优先选择重铸石
    self._attrFirstChoose = toboolean(LPlayerPrefs.runeAttrFirstChoose)            -- 属性重铸优先选择重铸石

    self._payRecastItem = nil                -- 重铸石道具
    self._skillRecastId = nil                -- 选择的技能id
    self._selRuneIdList = {}                -- 淬炼进阶选择的符文id
    self._selUseRuneItemList = {}            -- 淬炼进阶选择的符文道具

    self._pageViewList = {
        [ModelRune.TYPE_SKILLRECAST] = {
            pageIndex = ModelRune.TYPE_SKILLRECAST,
            btnType = ModelRune.TYPE_SKILLRECAST,
            viewTrans = self.mSkillRecastView,
            botViewTrans = self.mSkillRecastBotView,
            botOptViewTrans = self.mBotSkillRecastOptView,
            btnName = ccClientText(24900),
            offIcon = "rune_tab1",
            onIcon = "rune_tab1",
            clickFunc = function(itemdata)
                return self:ChangePageFunc(itemdata.pageIndex, true)
            end,
        },
        [ModelRune.TYPE_ATTRRECAST] = {
            pageIndex = ModelRune.TYPE_ATTRRECAST,
            btnType = ModelRune.TYPE_ATTRRECAST,
            viewTrans = self.mAttrRecastView,
            botViewTrans = self.mAttrRecastBotView,
            botOptViewTrans = self.mBotAttrRecastOptView,
            btnName = ccClientText(24901),
            offIcon = "rune_tab2",
            onIcon = "rune_tab2",
            clickFunc = function(itemdata)
                return self:ChangePageFunc(itemdata.pageIndex, true)
            end,
        },
        [ModelRune.TYPE_QUENCHING] = {
            pageIndex = ModelRune.TYPE_QUENCHING,
            btnType = ModelRune.TYPE_QUENCHING,
            viewTrans = self.mQuenchingView,
            botViewTrans = self.mQuenchingBotView,
            botOptViewTrans = self.mBotQuenchingOptView,
            btnName = ccClientText(24902),
            offIcon = "rune_tab3",
            onIcon = "rune_tab3",
            clickFunc = function(itemdata)
                return self:ChangePageFunc(itemdata.pageIndex, true)
            end,
        },
    }
    self._pageRefreshViewList = {
        [ModelRune.TYPE_SKILLRECAST] = function()
            self:RefreshSkillRecastView()
        end,
        [ModelRune.TYPE_ATTRRECAST] = function()
            self:RefreshAttrRecastView()
        end,
        [ModelRune.TYPE_QUENCHING] = function()
            self:RefreshQuenchingView()
        end,
    }
    self._pageNeedItemList = {
        [ModelRune.TYPE_SKILLRECAST] = gModelRune:GetSkillRecastShowItemList(),
        [ModelRune.TYPE_ATTRRECAST] = gModelRune:GetAttrRecastShowItemList(),
        [ModelRune.TYPE_QUENCHING] = gModelRune:GetQuenchingItemList(),
    }
end

function UIReRecastNew:InitQuenchingDescList()
    local list, index = self:GetQuenchingDescList()
    local refresh = not index and true or false
    local uiQuenchingDescList = self._uiQuenchingDescList
    if uiQuenchingDescList then
        uiQuenchingDescList:RefreshData(list, refresh)
    else
        uiQuenchingDescList = self:GetUIScroll("uiQuenchingDescList")
        self._uiQuenchingDescList = uiQuenchingDescList
        uiQuenchingDescList:Create(self.mQuenchingList, list, function(...)
            self:OnDrawQuenchingDescCell(...)
        end, UIItemList.WRAP, refresh)
    end
    local uiList = uiQuenchingDescList:GetList()
    if index then
        uiList:RefreshList(UIListWrap.RefreshMode.Custom, index)
    else
        uiList:RefreshList(UIListWrap.RefreshMode.Solid)
    end
end

function UIReRecastNew:ChangePageFunc(pageIndex, init)
    if not init then
        if self._page == pageIndex then
            return
        end
    end
    local isOpen = self:CheckIsRuneMechanismOpen(pageIndex, init)
    if not isOpen then
        self:AutoSelPage()
        return
    end
    self._page = pageIndex
    self:RefreshFunc()
    return true
end
----------------------------------------------- CommonFunc -----------------------------------------------

----------------------------------------------- RefreshSkillRecastView -----------------------------------------------
function UIReRecastNew:InitSkillList(trans, list)
    local key = trans:GetInstanceID()
    local uiSkillList = self:FindUIScroll(key)
    if uiSkillList then
        uiSkillList:RefreshList(list)
    else
        uiSkillList = self:GetUIScroll(key)
        uiSkillList:Create(trans, list, function(...)
            self:OnDrawSkillCell(...)
        end)
    end
    local isEnable = #list > 2
    uiSkillList:EnableScroll(isEnable)
end

function UIReRecastNew:OnClickOptBtnFunc(saveType)
    local serverData = self._runeData
    if not serverData then
        return
    end
    local runeId = serverData.id
    local heroId = self._heroId
    local saveFunc = function()
        gModelHero:SetNeedHeroPowerTips(true, heroId)
        gModelRune:OnRuneRecastSaveReq(runeId, saveType, ModelRune.OPT_TYPE_SAVE)
    end
    local cancelFunc = function()
        gModelRune:OnRuneRecastSaveReq(runeId, saveType, ModelRune.OPT_TYPE_CANCAL)
    end
    gModelGeneral:OpenUIOrdinTips({ refId = 52407, func = saveFunc, leftFunc = cancelFunc })
end

function UIReRecastNew:InitMsg()
    self:WndNetMsgRecv(LProtoIds.RuneRecastResp, function(pb)
        self:OnRuneRecastResp(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.RuneRecastAttrResp, function(pb)
        self:OnRuneRecastAttrResp(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.RuneRecastSaveResp, function(pb)
        self:OnRuneRecastSaveResp(pb)
    end)
    --self:WndNetMsgRecv(LProtoIds.RuneQuenchingResp,function(pb) self:OnRuneQuenchingResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.RuneQuenchingClazzResp, function(pb)
        self:OnRuneQuenchingClazzResp(pb)
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:OnItemChange()
    end)
end

function UIReRecastNew:RefreshSkillRecastView()
    self:RefreshSkillRecastGouStatus()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local root = self.mSkillRecastRuneRoot
    self:CreateRuneIcon(root, serverData, true)
    self:RefreshRuneSkillDiv()
    self:RefreshBotSkillRecastView()
    self:RefreshSkillRecastPayList()

    local refId = serverData.refId
    local recastNeedItem1, recastReplaceItem1 = gModelRune:GetRuneAttrRecastItemListByRefId(refId)
    local itemName = gModelItem:GetNameByRefId(recastReplaceItem1[1].itemId)
    self:SetWndText(self.mSkillRecastGouTxt, itemName)
end

function UIReRecastNew:OnRuneQuenchingClazzResp(pb)
    local serverData = self._runeData
    if not serverData then
        return
    end
    if pb.runeId ~= serverData.id then
        return
    end
    self:UpDateRuneServerData()
end

function UIReRecastNew:OnDrawSkillCell(list, item, itemdata, itempos)
    local SkillBg = self:FindWndTrans(item, "SkillBg")
    local SkillRoot = self:FindWndTrans(SkillBg, "SkillRoot")
    local SkillIconTrans = self:FindWndTrans(SkillRoot, "SkillIcon")
    local SkillName = self:FindWndTrans(SkillBg, "SkillName")

    local skillIconList = self._skillIconList
    if not skillIconList then
        skillIconList = {}
        self._skillIconList = skillIconList
    end

    local runeSkillRefId = itemdata.runeSkillRefId
    local isHaveSkill = runeSkillRefId ~= nil
    local skillData
    if isHaveSkill then
        skillData = gModelRune:GetSkillInfoByRefId(runeSkillRefId)
    end
    local skillRefId = skillData and skillData.SkillId

    local InstanceID = item:GetInstanceID()
    local baseClass = skillIconList[InstanceID]
    if not baseClass then
        baseClass = SkillIcon:New(self)
    end
    baseClass:ShowWenHao(not isHaveSkill)
    baseClass:Create(SkillIconTrans, skillRefId, function()
        if not skillData then
            return
        end
        local skillType = skillData.skillType
        gModelRune:OpenNewRuneSkillWnd(runeSkillRefId, skillType)
    end)
    local color
    local skillNameStr
    if skillRefId then
        local skillRef = gModelHero:GetSkillByStarId(skillRefId)
        if skillRef then
            skillNameStr = ccLngText(skillRef.name)
            local quality = skillData.quality + 2
            color = gModelItem:GetColorByQualityId(quality)
        end
    else
        skillNameStr = ccClientText(24839)
        color = LUtil.GetColorByKey("black")
    end
    if color then
        --printInfoNR("color = " .. color)
        self:SetXUITextTransColor(SkillName, color)
    end
    self:SetWndText(SkillName, skillNameStr)
    CS.ShowObject(SkillName, true)
end

function UIReRecastNew:RefreshAttrRecastPayList()
    local payList = self:GetAttrRecastItemList()
    local isEmpty = #payList < 1
    local desc = isEmpty and ccClientText(24934) or ""
    local uiPayList = self.mAttrRecastPayList
    self:SetTextTile(uiPayList, desc)
    self:CreatePayList(uiPayList, payList)
end

function UIReRecastNew:RefreshBotSkillRecastView()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local refId = serverData.refId
    local recastTypeList = gModelRune:GetRuneRecastTypeListByRefId(refId) or {}
    local totalNum = recastTypeList[ModelRune.RECASTTYPE_4] or 0
    local isHaveTotal = totalNum == 1
    CS.ShowObject(self.mHideSkillRecastDiv, isHaveTotal)
    CS.ShowObject(self.mSkillRecastDiv, not isHaveTotal)
    if isHaveTotal then
        self:RefreshSkillRecastJD()
    end
    local nextSkillId = serverData.nextSkillId
    local isHaveNextSkillId = #nextSkillId > 0
    CS.ShowObject(self.mSkillRecastResultDiv, isHaveNextSkillId)
    CS.ShowObject(self.mSkillRecastBtn, not isHaveNextSkillId)
end

function UIReRecastNew:OnClickSkillRecastBtnFunc(haveResult)
    local serverData = self._runeData
    if not serverData then
        return
    end
    local refId = serverData.refId
    local isCanSkillRecast = gModelRune:IsHaveSkillNumByRefId(refId)
    if not isCanSkillRecast then
        GF.ShowMessage(ccClientText(24933))
        return
    end
    local runeId = serverData.id
    local payList, itemType = self:GetSkillRecastItemList()
    if not itemType then
        if LOG_INFO_ENABLED then
            printInfoNR("没有配置的技能选择类型")
        end
        return
    end
    local noEnoughItem = nil
    for i, v in ipairs(payList) do
        local itemId = v.itemId
        if itemId ~= UIReRecastNew.CHOOSE_ITEM then
            local haveNum = gModelItem:GetNumByRefId(itemId)
            if haveNum < v.itemNum then
                noEnoughItem = itemId
                break
            end
        end
    end
    if noEnoughItem then
        self:OpenGetWayWnd(noEnoughItem)
        --gModelGeneral:OpenGetWayWnd({itemId = noEnoughItem,srcWnd = self:GetWndName()})
        return
    end
    local tRecastNum, subNum, recastNum = self:GetRecastNum()
    local isEnd = subNum <= 0
    local recastType
    if isEnd and recastNum ~= 0 then
        recastType = ModelRune.RECASTTYPE_4
    else
        local payRecastItem = self._payRecastItem
        if payRecastItem then
            local itemId = payRecastItem.itemId
            recastType = gModelRune:CheckItemIsLuckOrGod(serverData.refId, itemId)
        else
            recastType = ModelRune.RECASTTYPE_1
        end
    end

    recastType = ModelRune.RECASTTYPE_1
    local recast = serverData.recast
    if recastType == ModelRune.RECASTTYPE_4 and not self._skillRecastId then
        self:OpenSkillSelWnd()

    else
        local func = function()
            if not self:IsWndValid() then
                return
            end
            gModelRune:OnRuneRecastReq(runeId, recastType, self._skillRecastId, itemType)
        end
        if haveResult then
            self:OnRecastTipsFunc(func)
        else
            func()
        end
    end
end

function UIReRecastNew:OnDrawAttrRecastDescCell(list, item, itemdata, itempos)
    local UIText = self:FindWndTrans(item, "UIText")
    local str = ""
    local textId = itemdata.textId
    local hyperTextId = itemdata.hyperTextId
    if hyperTextId then
        local uiHyperText = UIHyperText:New()
        uiHyperText:Create(UIText)
        local skillTitle = ccClientText(hyperTextId)
        skillTitle = uiHyperText:AddHyper(skillTitle, { func = function()
            -- 属性预览
            GF.OpenWnd("UIReAttrSow")
        end })
        str = string.replace(ccClientText(textId), LUtil.FormatColorStr(skillTitle, "darkYellow"))
    else
        str = ccClientText(textId)
    end
    self:SetWndText(UIText, str)
end

function UIReRecastNew:OnRuneQuenchingClazzReq()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local selRuneIdList = self._selRuneIdList
    if not selRuneIdList then
        selRuneIdList = {}
        self._selRuneIdList = selRuneIdList
    end
    local selUseRuneItemList = self._selUseRuneItemList
    if not selUseRuneItemList then
        selUseRuneItemList = {}
        self._selUseRuneItemList = selUseRuneItemList
    end
    local selRuneIdNum = #selRuneIdList + #selUseRuneItemList
    local isSelRuneEnough = true
    local noEnoughItem = nil
    local list = gModelRune:GetQuenchingPayList(serverData)
    for i, v in ipairs(list) do
        local itemType = v.itemType
        if itemType == LItemTypeConst.TYPE_RUNE then
            isSelRuneEnough = selRuneIdNum >= v.itemNum
        else
            local itemId = v.itemId
            local haveNum = gModelItem:GetNumByRefId(itemId)
            if haveNum < v.itemNum then
                noEnoughItem = itemId
                break
            end
        end
    end
    if not isSelRuneEnough then
        -- 选择的符文不够
        GF.ShowMessage(ccClientText(24927))
        return
    end
    if noEnoughItem then
        self:OpenGetWayWnd(noEnoughItem)
        --gModelGeneral:OpenGetWayWnd({itemId = noEnoughItem,srcWnd = self:GetWndName()})
        return
    end

    GF.OpenWnd("UIReUpPre", {
        runeData = serverData,
        selRuneIdList = self._selRuneIdList,
        selUseRuneItemList = self._selUseRuneItemList,
        exitWndFunc = function(selRuneIdList, selRuneItemList)
            selRuneIdList = selRuneIdList or {}
            self._selRuneIdList = {}
            for i, v in ipairs(selRuneIdList) do
                table.insert(self._selRuneIdList, v)
            end
            selRuneItemList = selRuneItemList or {}
            self._selUseRuneItemList = {}
            for i, v in ipairs(selRuneItemList) do
                table.insert(self._selUseRuneItemList, v)
            end
            self:InitQuenchingPayList()
        end
    })
    local runeId = serverData.id
    -- gModelRune:OnRuneQuenchingClazzReq(runeId,  selRuneIdList, selUseRuneItemList)
end

function UIReRecastNew:GetNeedList()
    local list = self._pageNeedItemList[self._page]
    return list
end

function UIReRecastNew:OnClickSkillPreBtnFunc()
    GF.OpenWndTop("UIReJNPreView")
end

function UIReRecastNew:CreateQuenchingStarList(trans, starNum)
    local list = {}
    for i = 1, starNum do
        table.insert(list, {
            show = true
        })
    end
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...)
            self:OnDrawQuenchingStarCell(...)
        end)
    end
end

function UIReRecastNew:RefreshRuneAttrDiv()
    local serverData = self._runeData
    if not serverData then
        return
    end
    local attrId = serverData.attrId
    self:CreateAttrDiv(self.mBeforeAttrDiv, { attrList = attrId }, 24904)

    local nextAttrList = {}
    local attrIdLen = #attrId
    local nextAttrId = serverData.nextAttrId
    for i = 1, attrIdLen do
        table.insert(nextAttrList, nextAttrId[i] or 0)
    end
    self:CreateAttrDiv(self.mLaterAttrDiv, { attrList = nextAttrList }, 24905)
end

function UIReRecastNew:InitNeedList()
    local list = self:GetNeedList()
    local uiNeedList = self._uiNeedList
    if uiNeedList then
        uiNeedList:RefreshData(list)
    else
        uiNeedList = self:GetUIScroll("uiNeedList")
        self._uiNeedList = uiNeedList
        uiNeedList:Create(self.mNeedItemList, list, function(...)
            self:OnDrawNeedItemCell(...)
        end)
    end
end
----------------------------------------------- RefreshQuenchingView -----------------------------------------------
function UIReRecastNew:OnTcpReconnect()
    local runeData = self._runeData
    if not runeData then
        if LOG_INFO_ENABLED then
            LogError("断线重连符文数据丢失，强制关闭界面")
        end
        self:WndClose()
        return
    end
    self:UpDateRuneServerData(nil, true)
    self:RefreshFunc()
end

function UIReRecastNew:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mSkillRecastBtn, function()
        self:OnClickSkillRecastBtnFunc()
    end)
    self:SetWndClick(self.mSkillRecastNewBtn, function()
        self:OnClickSkillRecastBtnFunc(true)
    end)
    self:SetWndClick(self.mSkillRecastSaveBtn, function()
        self:OnClickSkillRecastSaveBtnFunc()
    end)
    self:SetWndClick(self.mAttrRecastBtn, function()
        self:OnClickAttrRecastBtnFunc()
    end)
    self:SetWndClick(self.mAttrRecastNewBtn, function()
        self:OnClickAttrRecastBtnFunc(true)
    end)
    self:SetWndClick(self.mAttrRecastSaveBtn, function()
        self:OnClickAttrRecastSaveBtnFunc()
    end)
    self:SetWndClick(self.mQuenchingBtn, function()
        self:OnClickQuenchingBtnFunc()
    end)
    self:SetWndClick(self.mSkillPreBtn, function()
        self:OnClickSkillPreBtnFunc()
    end)
    self:SetWndClick(self.mSkillRecastGouBgBtn, function()
        self:OnClickSkillRecastGouBgBtnFunc()
    end)
    self:SetWndClick(self.mAttrRecastGouBgBtn, function()
        self:OnClickAttrRecastBgBtnFunc()
    end)
    self:SetWndClick(self.mSkillRecastHelpBtn, function()
        self:OnClickSkillRecastHelpBtnFunc()
    end)
    self:SetWndClick(self.mAttrRecastHelpBtn, function()
        self:OnClickAttrRecastHelpBtnFunc()
    end)
    self:SetWndClick(self.mQuenchingHelpBtn, function()
        self:OnClickQuenchingHelpBtnFunc()
    end)
    self:SetWndClick(self.mChangeRuneBtn, function()
        self:OnClickChangeRuneBtnFunc()
    end)
end

function UIReRecastNew:RefreshSkillRecastGouStatus()
    CS.ShowObject(self.mSkillRecastGou, self._skillFirstChoose)
end

function UIReRecastNew:RefreshTabBtnList()
    if self._uiBtnTabList then
        self._uiBtnTabList:RefreshTabScroll()
    end
    --[[	local uiBotPageList = self._uiBotPageList
        if uiBotPageList then
            local uiList = uiBotPageList:GetList()
            uiList:RefreshList()
        end]]
end

function UIReRecastNew:RefreshQuenchingView()
    self._selRuneIdList = {}
    self._selUseRuneItemList = {}
    local serverData = self._runeData
    if not serverData then
        return
    end
    self:RefresrhQuenching()
    --[[	local refId = serverData.refId
        local isQuenching = gModelRune:IsCanQuenchingByRefId(refId)
        if isQuenching then
            self:RefresrhQuenching()
        else
            self:RefresrhNotQuenching()
        end]]
end

function UIReRecastNew:InitTabBtnList()
    local list = self._pageViewList
    local uiBotPageList = self._uiBotPageList
    if uiBotPageList then
        uiBotPageList:RefreshList(list)
    else
        uiBotPageList = self:GetUIScroll("uiBotPageList")
        self._uiBotPageList = uiBotPageList
        uiBotPageList:Create(self.mBotPageList, list, function(...)
            self:OnDrawBotPageBtnCell(...)
        end)
    end
end

function UIReRecastNew:AddItemEvent(refId)
    self:OpenGetWayWnd(refId)
end

function UIReRecastNew:InitAttrRecastDescList()
    local list = self:GetAttrRecastDescList()
    local uiAttrRecastDescList = self._uiAttrRecastDescList
    if uiAttrRecastDescList then
        uiAttrRecastDescList:RefreshList(list)
    else
        uiAttrRecastDescList = self:GetUIScroll("uiAttrRecastDescList")
        self._uiAttrRecastDescList = uiAttrRecastDescList
        uiAttrRecastDescList:Create(self.mAttrRecastDescList, list, function(...)
            self:OnDrawAttrRecastDescCell(...)
        end)
        uiAttrRecastDescList:EnableScroll(true, false)
    end
end

function UIReRecastNew:GetAttrRecastDescList()
    local list = {
        {
            textId = 24912,
        },
        {
            textId = 24913,
            hyperTextId = 24915,
        },
        {
            textId = 24914,
        },
    }
    return list
end

function UIReRecastNew:OnRecastTipsFunc(func)
    gModelGeneral:OpenUIOrdinTips({ refId = 52408, func = func })
end

function UIReRecastNew:GetQuenchingDescList()
    local list = {}
    local runeQuenchingClassRef = GameTable.MagicRuneQuenchingClassRef
    local serverData = self._runeData
    local runeClassSer = 0
    if serverData then
        --[[		local levelRefId = serverData.levelRefId
                runeClassSer = gModelRune:GetCurLevelNeedClassByLevelRefId(levelRefId)]]
        --local clazzRefId = serverData.clazzRefId
        --runeClassSer = gModelRune:GetRuneClassByClassRefId(clazzRefId)
        --local quenchingClassRef = gModelRune:GetInitRuneQuenchingClassRefByRefId(clazzRefId)
        --if quenchingClassRef then
        --end
        runeClassSer = serverData.refId
    end
    local successStr = ccClientText(24928)
    for k, v in pairs(runeQuenchingClassRef) do
        local desc = ccLngText(v.desc)
        if not string.isempty(desc) then
            local upQuality = v.upQuality
            local act = runeClassSer >= upQuality
            if act then
                desc = desc .. successStr
            end
            table.insert(list, {
                act = act,
                desc = desc,
                runeClass = v.runeClass,
                upQuality = v.upQuality,
            })
        end
    end
    table.sort(list, function(a, b)
        return a.runeClass < b.runeClass
    end)
    local index
    for i, v in ipairs(list) do
        if runeClassSer == v.upQuality then
            index = i - 1
        end
    end
    return list, index
end

function UIReRecastNew:RefreshQuenchingAttrInfo()
    local serverData = self._runeData
    if not serverData then
        return
    end
    -- local list = gModelRune:GetAttrList(serverData)

    local canQuenching = gModelRune:IsCanQuenchingByRefId(serverData.refId)
    local isMaxQuenching = gModelRune:IsMaxQuenching(serverData.clazzRefId)
    local list = gModelRune:GetRuneUpAttrList(serverData.attrId, isMaxQuenching)
    local isGrayBtn = false
    local btnTextId = 24852
    if isMaxQuenching then
        isGrayBtn = true
        btnTextId = 24931
    end
    self:SetWndButtonGray(self.mQuenchingBtn, isGrayBtn)
    self:SetWndButtonText(self.mQuenchingBtn, ccClientText(btnTextId))
    CS.ShowObject(self.mQuenchingBtn, canQuenching)

    local trans = self.mQuenchingTopDiv
    local LightLineTrans = self:FindWndTrans(trans, "LightLine")
    self:SetTextTile(LightLineTrans, ccClientText(24818))
    local QuenchingAttrListTrans = self:FindWndTrans(trans, "QuenchingAttrList")
    self:InitQuenchingAttrList(QuenchingAttrListTrans, list)
end

function UIReRecastNew:RefreshQuenchingTop()
    local serverData = self._runeData
    if not serverData then
        return
    end
    self:RefreshQuenchingRuneIcon()
    self:RefreshQuenchingAttrInfo()
end
------------------------------------------------------------------
return UIReRecastNew