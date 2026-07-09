---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBags:LWnd
local UIBags = LxWndClass("UIBags", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBags:UIBags()

    self._itemEffectList = {} -- k=itemInstanceId, v={}
    self._waitLoadEffList = {} -- itemInstanceId

    self:SetHideHurdle()

    self._showDivType = nil
    self._selAttrInfoMap = {}

    ---@type number 页签选择
    self._tabEnum = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBags:OnWndClose()
    self._refreshByOutfitOpt = false

    self._itemEffectList = {}
    self._waitLoadEffList = {}

    gModelHero:SelItemUpHeroIdList()

    gModelItem:ClearNewItemList()

    if self._uiAllList then
        self._uiAllList:OnWndClose()
    end

    --gModelGeneral:OpenPopWnd()

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBags:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBags:OnStart()
    LWnd.OnStart(self)

    self:InitUI()


    self.jpj = gLGameLanguage:IsJapanVersion()
    self:SetStaticContent()
    self:CreateEmptyShow()
    self:InitData()
    self:InitEvent()
    self:InitMsg()
    self:InitCommonListRect()

    self:InitSortSelGolemDiv()
    self:InitAttrSelGolemDiv()
    self:InitStatusSelGolemDiv()

    self:InitBtnList()
    self:InitEffectTimer()
end

function UIBags:OnClickCommonBtnFunc(itemdata)
    local refreshStatus = false
    local showType = itemdata.showType
    if showType == ModelGolem.GOLEM_DIV_SORT then
        refreshStatus = self:OnClickCommonSortDivFunc(itemdata)
    elseif showType == ModelGolem.GOLEM_DIV_STATUS then
        refreshStatus = self:OnClickCommonStatusDivFunc(itemdata)
        --self:ClearSuitSort()
    end
    if refreshStatus then
        GF.ShowMessage(ccClientText(33298))
    end
    self:OnClickClickMaskFunc()
end

--------- 刷新背包装备品质选中图
function UIBags:RefreshSelBagHeroZSImg()
    local bagHeroZSType = self._bagHeroZSType
    local trans = self._bagHeroZSKeyTransList[bagHeroZSType]
    if trans then
        CS.SetParentTrans(self.mQualitySelImg, trans)
    end
end

function UIBags:GetAllStatus(refId)
    return self:GetItemStatus(refId)
end

--------- 刷新背包部位选中图
function UIBags:RefreshSelBagPartImg()
    local bagSelPartType = self._bagSelPartType
    local trans = self._bagPartKeyTransList[bagSelPartType]
    if trans then
        CS.SetParentTrans(self.mPartSelImg, trans)
    end
end
-- 修改底部按钮选中状态时的图片
function UIBags:ChangeBtnImage(index, SelImg, BtnName, init)
    local btnList = self._btnList
    if index then
        local btn = btnList[index]
        local show = i == self._lastbtn and 0 or 1
        self:SetWndTabStatus(btn, show)
    else
        for i = 1, #btnList do
            local btn = btnList[i]

            local show = i == self._lastbtn and 0 or 1
            self:SetWndTabStatus(btn, show)

            local redPointTrans = CS.FindTrans(btn, "redPoint")
            if redPointTrans then
                local refId = self._btnIdList[i].refId
                local temp = self._tabRedPointList[refId]
                if temp then
                    local status = temp.func(refId)
                    CS.ShowObject(redPointTrans, status)
                else
                    CS.ShowObject(redPointTrans, false)
                end
            end
        end
    end
end

function UIBags:OnGolemBagResp()
    self:RefreshListTransFunc()
end

function UIBags:RefreshListTransFunc()
    local btnRefId = self._btnRefId
    local listTransList = self._listTransList or {}
    local btnInfo = listTransList[btnRefId]
    if btnInfo then
        local func = btnInfo.func
        if func then
            func(true)
        end
    end
end

function UIBags:GetKeyMap(info)
    return info.keyMap
end

function UIBags:GetSelInfoKeyMapByShowType(showType)
    --- 属性除外 ， 属性有主副之分
    local selTypeInfo = self:GetSelInfoByShowType(showType)
    if not selTypeInfo then
        return
    end
    return self:GetKeyMap(selTypeInfo)
end
-- 页签按钮处理
function UIBags:OnDrawBtn(list, item, itemdata, itempos)
    local btnTrans = CS.FindTrans(item, "BtnTab1")
    if not btnTrans then
        return
    end
    local ref = itemdata.ref
    local index = itemdata.index
    local refId = itemdata.refId
    local name = ccLngText(ref.name)
    local btnList = self._btnList
    local curBtn = btnList[index]
    if not curBtn then
        curBtn = btnTrans
        btnList[index] = curBtn
    end
    self:SetWndClick(curBtn, function()
        LxUiHelper.FilterScrollItem(self.mTypeBtnList, itempos - 1)
        self:BtnEvent(refId, index)
    end, LSoundConst.CLICK_PAGE_COMMON)
    self:SetWndTabText(btnTrans, name)

    local show = index == self._lastbtn and 0 or 1
    self:SetWndTabStatus(btnTrans, show)

    local redPointTrans = CS.FindTrans(btnTrans, "redPoint")
    if redPointTrans then
        local temp = self._tabRedPointList[refId]
        if temp then
            local status = temp.func()
            CS.ShowObject(redPointTrans, status)
        else
            CS.ShowObject(redPointTrans, false)
        end
    end
end

function UIBags:OutfitOptResp()
    if self._lastbtn == 4 then
        self:RefreshAllGrid(LItemTypeConst.TYPE_OUTFIT, true)
    elseif self._lastbtn == 1 then
        self:RefreshAllGrid(0, true)
    end
end

-- 页签按钮事件
function UIBags:BtnEvent(refId, index, refresh, init)
    if self._btnRefId == refId and (not refresh) then
        return
    end
    --printInfoN("---- refId,index = ",refId,index)
    self._btnRefId = refId
    -- 按钮背景换颜色
    self._lastbtn = index
    self:CheckCutTabBtnGolemNeedInit()
    self:OnClickClickMaskFunc()
    self:RefreshFunc(refId, refresh)
end

function UIBags:InitSelAttrInfo(list)
    local selAttrInfoMap = self._selAttrInfoMap
    local selAttrInfoNumMap = {}
    self._selAttrInfoNumMap = selAttrInfoNumMap
    list = list or {}
    --    local showType = ModelGolem.GOLEM_DIV_ATTR
    local attrRefId
    local status, selAttrType
    for i, v in ipairs(list) do
        selAttrType = v.selAttrType
        local selAttrTypeInfo = selAttrInfoMap[selAttrType]
        if not selAttrTypeInfo then
            selAttrTypeInfo = {}
            selAttrInfoMap[selAttrType] = selAttrTypeInfo
        end
        local selNum = 0
        for idx, val in ipairs(v.attrList) do
            attrRefId = val.attrRefId
            --status = self:CheckIsSel(showType, {
            --    selAttrType = selAttrType,
            --    refId = attrRefId,
            --})
            if status then
                selNum = selNum + 1
            end
            --selAttrTypeInfo[attrRefId] = {
            --    status = status,
            --    showType = showType,
            --    selAttrType = val.selAttrType
            --}
        end
        selAttrInfoNumMap[selAttrType] = selNum
    end
end

function UIBags:GetItemName(itype, refId, itemdata)
    local name = gModelGeneral:GetItemName(itype, refId, 1, nil, itemdata)
    return name
end

function UIBags:OnDrawAttrSelGolemCell(list, item, itemdata, itempos)
    local TitleTrans = self:FindWndTrans(item, "TitleDiv/Title")
    local AttrListTrans = self:FindWndTrans(item, "AttrList")
    self:SetWndText(TitleTrans, itemdata.str)

    self:InitAttrList(AttrListTrans, itemdata.attrList)
end

function UIBags:OnClickAttrBtnFunc(itemdata)
    local showType = itemdata.showType
    local attrRefId = itemdata.attrRefId
    local selAttrType = itemdata.selAttrType
    local status = false
    local selAttrInfoMap = self._selAttrInfoMap
    local selAttrInfoNumMap = self._selAttrInfoNumMap
    local selNum = selAttrInfoNumMap[selAttrType] or 0
    local isSel = self:CheckAttrSelStatus(selAttrType, attrRefId)
    if isSel then
        local selAttrTypeInfo = selAttrInfoMap[selAttrType]
        if selAttrTypeInfo[attrRefId] then
            selAttrTypeInfo[attrRefId].status = false
            selAttrInfoNumMap[selAttrType] = selNum - 1
            status = true
        end
    else
        local configAttrTypeInfo = self:GetConfigNumByShowType(showType)
        local configNum = configAttrTypeInfo[selAttrType]
        local selAttrTypeInfo = selAttrInfoMap[selAttrType]
        if not selAttrTypeInfo then
            selAttrTypeInfo = {}
            selAttrInfoMap[selAttrType] = selAttrTypeInfo
        end
        if selNum < configNum then
            selAttrInfoNumMap[selAttrType] = selNum + 1
            selAttrTypeInfo[attrRefId] = {
                status = true,
                showType = showType,
            }
            status = true
        else
            --if selAttrType == ModelGolem.GOLEM_DIV_ATTR_PRIME then
            --    if configNum == 1 then
            --        for k, v in pairs(selAttrTypeInfo) do
            --            v.status = false
            --        end
            --        selAttrTypeInfo[attrRefId] = {
            --            status = true,
            --            showType = showType,
            --        }
            --        status = true
            --    else
            --        --- 多选的情况不管，等策划决定
            --    end
            --elseif selAttrType == ModelGolem.GOLEM_DIV_ATTR_DEPUTY then
            --    GF.ShowMessage(ccClientText(33299))
            --end
        end
    end
    if not status then
        return
    end
    local listKey = itemdata.listKey
    local uiAttrList = self:FindUIScroll(listKey)
    if not uiAttrList then
        return
    end
    self._selAttrInfoMap = selAttrInfoMap
    local uiList = uiAttrList:GetList()
    uiList:RefreshList()
end

function UIBags:OnClickChangePartBtnFunc(show)
    CS.ShowObject(self.mChangePartBtn, not show)
    self:ChangeCommonListPos()
end

function UIBags:GetShowRedPointStatus(refId, itype, trans, id, showNew, extra)
    if itype == LItemTypeConst.TYPE_ITEM then
        local showRedPoint = false
        if ModelItem.ITEM_OLDEQUIPITEMLIST[refId] then
            showRedPoint = true
        elseif gModelItem:GetIsShowRedPointByRefId(refId) then
            showRedPoint = true
        else
            if refId == 204420 then
                printInfoN2("--", "--")
            end

            local needNum = gModelItem:GetSuiPianNeedNumByRefId(refId)
            if needNum ~= nil then
                local num = gModelItem:GetNumByRefId(refId)
                showRedPoint = needNum <= num
            end
        end
        local isLeiDeng = gModelItem:GetLeiDengItemByRefId(refId)
        if isLeiDeng and id then
            local status = gModelItem:CheckLeiDengIsGet(refId, id)
            showRedPoint = status
        end
        local isWishingMatch = gModelWishingMatch:IsWishingMatchItem(refId)
        if (isWishingMatch) then
            local allNum = extra.allNum
            local dayNum = extra.dayNum
            local endTime = extra.endTime
            showRedPoint = gModelWishingMatch:CheckCanDraw(refId, dayNum, allNum, endTime)
        end
        -- 新的显示比红点高
        if showNew then
            showRedPoint = false
        end
        CS.ShowObject(trans, showRedPoint)
    elseif itype == LItemTypeConst.TYPE_EQUIP then
        local isNew = gModelEquip:IsNewEquip(refId)
        CS.ShowObject(trans, isNew)
    else
        CS.ShowObject(trans, false)
    end
end

function UIBags:OnDrawAttrCell(list, item, itemdata, itempos)
    local NoSelBgTrans = self:FindWndTrans(item, "NoSelBg")
    local SelBgTrans = self:FindWndTrans(item, "SelBg")
    local AttrIconTrans = self:FindWndTrans(item, "AttrIcon")
    local BtnTrans = self:FindWndTrans(item, "Btn")
    local attrRefId = itemdata.attrRefId
    local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
    self:SetWndEasyImage(AttrIconTrans, attrIcon)
    local show = self:CheckAttrSelStatus(itemdata.selAttrType, attrRefId)
    local attrName = gModelHero:GetAttributeNameById(attrRefId)
    self:SetTextTile(NoSelBgTrans, attrName)
    self:SetTextTile(SelBgTrans, attrName)

    if self.jpj then
        local noselText  = CS.FindTrans(NoSelBgTrans,"UIText")
        local selText  = CS.FindTrans(SelBgTrans,"UIText")
        self:InitTextLineWithLanguage(noselText,-20)
        self:InitTextLineWithLanguage(selText,-20)
        self:InitTextSizeWithLanguage(noselText,-4)
        self:InitTextSizeWithLanguage(selText,-4)
        LxUiHelper.SetSizeWithCurAnchor(noselText,0,100)
        LxUiHelper.SetSizeWithCurAnchor(selText,0,100)
    end

    CS.ShowObject(NoSelBgTrans, not show)
    CS.ShowObject(SelBgTrans, show)

    self:SetWndClick(BtnTrans, function()
        self:OnClickAttrBtnFunc(itemdata)
    end)
end

function UIBags:GetSelGolemDivInfo(trans, showDivType, initTxt)
    local DivBgTrans = self:FindWndTrans(trans, "DivBg")
    local DivNameTrans = self:FindWndTrans(DivBgTrans, "DivName")
    local BtnTrans = self:FindWndTrans(DivBgTrans, "Btn")
    local SelListTrans = self:FindWndTrans(DivBgTrans, "SelList")

    local showDivListTransList = self._showDivListTransList
    if not showDivListTransList then
        showDivListTransList = {}
        self._showDivListTransList = showDivListTransList
    end
    showDivListTransList[showDivType] = SelListTrans

    local showDivNameTransList = self._showDivNameTransList
    if not showDivNameTransList then
        showDivNameTransList = {}
        self._showDivNameTransList = showDivNameTransList
    end
    showDivNameTransList[showDivType] = {
        nameTrans = DivNameTrans,
        initTxt = initTxt,
    }

    self:SetWndText(DivNameTrans, initTxt)
    if self.jpj then
        self:InitTextSizeWithLanguage(DivNameTrans,-4)
        self:SetAnchorPos(DivNameTrans,Vector2.New(-10,0))
    end
    return {
        DivBgTrans = DivBgTrans,
        DivNameTrans = DivNameTrans,
        BtnTrans = BtnTrans,
        SelListTrans = SelListTrans,
    }
end

function UIBags:OnDrawAllItemCell(list, item, itemdata, itempos, fromHeadTail)
    local aniNode = CS.FindTrans(item, "AniRoot")
    local _item = item
    item = aniNode
    local uiIconRoot = CS.FindTrans(item, "IconRoot")
    local refId = itemdata.refId or itemdata:GetRefId()
    local itype = itemdata.itype or itemdata:GetType()

    local newImg = CS.FindTrans(item, "NewImg")
    local key = refId

    --local shardIconRoot = self:FindWndTrans(aniNode,"ShardIconRoot")
    --CS.ShowObject(shardIconRoot,itype == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD)
    --CS.ShowObject(uiIconRoot,itype ~= LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD)

    if itype == LItemTypeConst.TYPE_RUNE then
        key = itemdata.id or itemdata:GetRuneId()
    elseif itype == LItemTypeConst.TYPE_OUTFIT then
        key = refId .. itemdata.heroRefId .. itemdata.star .. itemdata.starExp
        -- 【G公共支持】删除伙伴晶石功能相关数据
        -- elseif itype == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD then
        -- 	key = refId..itemdata.cells
        -- elseif itype == LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING then
        -- 	key = refId
    end

    local showNew = self._allStateList[key] or false
    if newImg then
        self:SetWndEasyImage(newImg, "public_txt_10", nil, true)
        CS.ShowObject(newImg, showNew)
    end

    local redPointTrans = CS.FindTrans(item, "redPoint")
    if redPointTrans then
        self:GetShowRedPointStatus(refId, itype, redPointTrans, itemdata.id, nil, itemdata.extra)
    end

    local OutfitFull = self:FindWndTrans(aniNode, "OutfitFull")
    local isShowOutfitFull = false

    local FullStatus = self:FindWndTrans(aniNode, "FullStatus")
    local showFullStatus = false
    if uiIconRoot then
        local instanceID = item:GetInstanceID()
        local baseClass, isNew = self:GetCommonIcon(instanceID)
        if isNew then
            baseClass:Create(self:FindWndTrans(uiIconRoot, "Icon"))
            baseClass:EnableSupportMulti(true) --格子支持多类型重用
        end

        self:CheckDrawItemEffect(item, instanceID, itype, refId, itempos) --物品格子光效创建检测

        if itype == LItemTypeConst.TYPE_RUNE then
            baseClass:EnableShowNum(true)
            baseClass:SetRuneData(itemdata:GetServerData())
            -- 【G公共支持】删除伙伴晶石功能相关数据
            -- elseif itype == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD or itype == LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING then
            -- 	local itemData = table.light_copy(itemdata)
            -- 	itemData.showNum = itemData.num>0
            -- 	baseClass:SetRewardDetailItem(itemData)
        elseif itype == LItemTypeConst.TYPE_EQUIP then
            local equipnum = itemdata:GetNum()
            baseClass:SetEquipIcon(refId, equipnum)
            baseClass:EnableShowNum(true)
        else
            baseClass:EnableShowNum(false)
            baseClass:SetCommonReward(itype, refId, itemdata.num)
            baseClass:RefreshActiveShow()
        end

        self:SetWndClick(uiIconRoot, function()
            if itype == LItemTypeConst.TYPE_EQUIP then
                gModelEquip:SetNewStatusEquip(refId, false)
                CS.ShowObject(redPointTrans, false)
            end

            local quality = gModelEquip:GetEquipQualityByRefId(refId)
            if quality and quality >= 7 then
                --判断是否为金装
                --gModelGeneral:RunOriginConfigCode(1008, {
                --    refId=refId,
                --    id=itemdata._id,
                --    equip=itemdata,
                --})

                gModelGeneral:OpenEquipInfoTip(refId, nil, 1, false, nil, nil, nil, nil, true, itemdata)
            else
                self:OpenTips({ itype = itype, refId = refId, itemdata = itemdata, redPoint = redPointTrans, newTrans = newImg })
            end

        end)

        baseClass:DoApply()

        if itype == LItemTypeConst.TYPE_EQUIP then
            local quality = gModelEquip:GetEquipQualityByRefId(refId)
            if quality and quality >= 7 then
                local level = itemdata:GetLevel()
                baseClass:SetEquipExtension(level)
            end
        end
        if itype == LItemTypeConst.TYPE_GOLEM then
            baseClass:SetLvTxt(itemdata.lvl)
        end
    end
    CS.ShowObject(OutfitFull, isShowOutfitFull)

    CS.ShowObject(FullStatus, showFullStatus)

    local itemNameTrans = CS.FindTrans(item, "ItemName")
    if itemNameTrans then
        local name = self:GetItemName(itype, refId, itemdata)
        self:SetWndText(itemNameTrans, name)
        --self:InitTextShowWithLanguage(itemNameTrans)
    end

    if not self._itemRefIdToTran then
        self._itemRefIdToTran = {}
    end

    self._itemRefIdToTran[refId] = uiIconRoot
end

function UIBags:OnClickCommonDivFunc(transInfo, showType)
    local listTrans = transInfo.SelListTrans
    local btnTrans = transInfo.BtnTrans
    local _showDivType = self._showDivType
    if _showDivType and _showDivType == showType then
        CS.ShowObject(self.mClickMask, false)
        CS.ShowObject(listTrans, false)
        self._showDivType = nil
        btnTrans.localScale = Vector3.New(1, 1, 1)
        return false
    end
    CS.ShowObject(self.mClickMask, true)
    CS.ShowObject(listTrans, true)
    self._showDivType = showType
    self:RefreshSelGolemDivStatus()
    btnTrans.localScale = Vector3.New(1, -1, 1)
    return true
end

function UIBags:OnClickAttrSelGolemDivFunc(transInfo, showType)
    local listTrans = transInfo.SelListTrans
    local bool = self:OnClickCommonDivFunc(transInfo, showType)
    if not bool then
        return
    end

    self:InitAttrSelGolemList(listTrans)
end

function UIBags:InitData()
    self._btnIdList = {}
    self._btnSortList = {}
    self._lastbtn = nil
    self._btnList = {}

    self._listTransList = {
        [101] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(0, refresh)
        end, index = 1 },
        [201] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(LItemTypeConst.TYPE_ITEM, refresh)
        end, index = 1, showAutoCompBtn = true },
        [202] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(LItemTypeConst.TYPE_ITEM, refresh)
        end, index = 2 },
        [203] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(LItemTypeConst.TYPE_EQUIP, refresh)
        end, index = 1 },
        --[204] = { trans = self.mCommonList, func = function(refresh)
        --    self:RefreshAllGrid(LItemTypeConst.TYPE_ITEM, refresh)
        --end, index = 3 },
        [205] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(LItemTypeConst.TYPE_ITEM, refresh)
        end, index = 4 },
        [204] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(LItemTypeConst.TYPE_RUNE, refresh)
        end, index = 1 },
        [206] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(LItemTypeConst.TYPE_ITEM, refresh)
        end, index = 2 },
        [207] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(LItemTypeConst.TYPE_ITEM, refresh)
        end, index = 2 },
        [208] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(LItemTypeConst.TYPE_GOLEM, refresh)
        end, index = 5 },
        [210] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(LItemTypeConst.TYPE_ITEM, refresh)
        end, index = 6 },
        [211] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(LItemTypeConst.TYPE_GOLEM, refresh)
        end, index = 1 },
        -- 【G公共支持】删除伙伴晶石功能相关数据
        -- [212] = {trans = self.mCommonList,func = function(refresh) self:RefreshAllGrid(LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD,refresh) end,index = 1},
        [209] = { trans = self.mCommonList, func = function(refresh)
            self:RefreshAllGrid(LItemTypeConst.TYPE_ITEM, refresh)
        end, index = 7 },
    }

    self._allStateList = {}
    local t = {}
    local listTransList = self._listTransList
    for k, v in pairs(listTransList) do
        local data = table.light_copy(v)
        data.key = k
        table.insert(t, data)
    end
    table.sort(t, function(a, b)
        return a.key < b.key
    end)
    self._listSortTransList = t

    self._diRectTransList = {
        [0] = {

        }
    }

    self._tabRedPointList = {
        [101] = { func = function(typei)
            return self:GetAllStatus(101)
        end },
        [201] = { func = function(typei)
            return self:GetItemStatus(typei or 201)
        end },
        [202] = { func = function(typei)
            return self:GetItemStatus(typei or 202)
        end },
        [204] = { func = function(typei)
            return self:GetItemStatus(typei or 204)
        end },
    }

    local btnRefId = self:GetWndArg("subPage") or 101
    self._btnRefId = btnRefId

    if LOG_INFO_ENABLED then
        printInfoNR("from UIBags | btnRefId = " .. btnRefId)
    end

    self:InitSelBtnList()

    self._showDivListTransList = {}

    self._showDivNameTransList = {}

    self:InitShowSelDivInfoList()
end

function UIBags:OnClickCommonStatusDivFunc(itemdata)
    local showType = itemdata.showType
    local value = itemdata.refId

    local isSel = self:CheckIsSel(showType, {
        refId = value,
    })
    local selTypeInfo = self:GetSelInfoByShowType(showType)
    local selTypeKeyInfo = self:GetSelInfoKeyMapByShowType(showType)
    if isSel then
        selTypeKeyInfo[value] = nil
        local selTypeNumInfo = self:GetSelInfoSelNumByShowType(showType)
        selTypeInfo.selNum = selTypeNumInfo - 1
        return true
    else
        local configNum = self:GetConfigNumByShowType(showType)
        local selTypeNumInfo = self:GetSelInfoSelNumByShowType(showType)
        if selTypeNumInfo < configNum then
            selTypeKeyInfo[value] = value
            selTypeInfo.selNum = selTypeNumInfo + 1
            return true
        else
            if configNum == 1 then
                --- 如果是只能选择单个的情况
                selTypeInfo.keyMap = {}
                selTypeInfo.keyMap[value] = value
                return true
            else
                --- 多选的情况不管，等策划决定
            end
        end
    end
    return false
end

--function UIBags:GetTabTypeByIType(iType)
--	if(iType == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD)then
--		return 212
--	end
--end
--function UIBags:GetOrderByITypeAndRefId(iType,refId)
--	if(iType == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD)then
--		return refId
--	end
--end

function UIBags:ClearAllItemEffect()
    for k, v in pairs(self._itemEffectList) do
        self._itemEffectList[k] = nil
        self:DestroyWndEffectByKey(k)
    end
    self._itemEffectList = {}
    self._waitLoadEffList = {}
end

function UIBags:OpenTips(data)
    local isRefresh = false
    local itype, refId, itemdata = data.itype, data.refId, data.itemdata
    local dataStateList = {}
    if itype == LItemTypeConst.TYPE_ITEM then
        if itemdata._state == ModelItem.ITEM_NEW_STATUS then
            isRefresh = true
            if self._allStateList then
                self._allStateList[refId] = false
            end
            table.insert(dataStateList, { type = itype, refId = refId, state = 0 })
        end
        local itemRef = gModelItem:GetRefByRefId(refId)
        local itemType = itemRef.type
        if itemType == ModelItem.Item_LEIDENGITEM or itemType == ModelItem.Item_DENGJILJITEM then
            gModelGeneral:OpenItemInfoTip(refId, nil, nil, nil, nil, nil, nil, nil, itemdata.id)
        --elseif itemType == ModelItem.Item_MainCitySkin then
        --    GF.OpenWnd("UIMCitySnItemPop", { refId = refId })
        elseif itemType == ModelItem.Item_Summon then
            local itemdata = data.itemdata
            gModelGeneral:OpenItemInfoTip(refId, nil, nil, nil, nil, nil, nil, nil, itemdata.id)
        elseif itemType == ModelItem.ITEM_WISH_MATCH then
            gModelGeneral:OpenItemInfoTip(refId, 1, nil, nil, nil, nil, nil, nil, itemdata.id, nil, nil, nil, nil, itemdata)
        elseif itemType == ModelItem.ITEM_THOUSAND then
            gModelGeneral:OpenItemInfoPara(itemdata)
        elseif itemType == ModelItem.TTEM_TYPE_HALIDOMITEM then
            gModelGeneral:OpenItemInfoPara({
                refId = itemdata:GetRefId(),
                formBag = true,
            })
        elseif itemType == gModelItem.TTEM_TYPE_DRACONIC_ITEM or itemType == gModelItem.TTEM_TYPE_DRACONIC or
                itemType == gModelItem.TTEM_TYPE_PET or itemType == gModelItem.TTEM_TYPE_DIVINE or itemType == ModelItem.Item_MainCitySkin then
            GF.OpenWndUp("UIInip", { refId = refId, formBag = true,showBtn = itemType == ModelItem.Item_MainCitySkin })
        else
            gModelGeneral:OpenItemInfoTip(refId)
        end
    elseif itype == LItemTypeConst.TYPE_EQUIP then
        gModelGeneral:OpenEquipInfoTip(refId, nil, 1)
    elseif itype == LItemTypeConst.TYPE_RUNE then
        isRefresh = true
        local runeData = itemdata:GetServerData()
        local _data = { openWay = 1, runeData = runeData, }
        gModelGeneral:OpenRuneInfoTip(_data)
        local id = runeData.id
        table.insert(dataStateList, { type = itype, refId = refId, id = id, state = 0 })
        if self._allStateList then
            self._allStateList[id] = false
        end
    elseif itype == LItemTypeConst.TYPE_GOLEM then
        --- 魔偶属性详情界面
        gModelGolem:OpenGolemInfoTip({
            viewType = 3,
            golemData = itemdata,
        })
        -- 【G公共支持】删除伙伴晶石功能相关数据
        -- elseif itype == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD then
        -- 	local shardData = table.clone(itemdata)
        -- 	shardData.showWear = true
        -- 	gModelGeneral:ShowRewardDetailTip(shardData)
        -- elseif itype == LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING then
        -- 	local shardData = table.clone(itemdata)
        -- 	shardData.showWear = true
        -- 	gModelGeneral:ShowRewardDetailTip(shardData)
    end
    if #dataStateList > 0 then
        gModelItem:OnDataStateChangeReq(dataStateList)
    end
    if isRefresh then
        local redPointTrans = data.redPoint
        local newTrans = data.newTrans
        if newTrans and redPointTrans then
            CS.ShowObject(newTrans, false)
            self:GetShowRedPointStatus(refId, itype, redPointTrans, itemdata.id, false, itemdata.extra)
        end
    end
end

function UIBags:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndCloseAndBack()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:WndEventRecv(gModelEquip.EventArgs.StrengthChange, function(data)
        --self._equip = data.equip
        local isRefresh_1 = self._nowShowItemType == 0
        local isRefresh_2 = self._nowShowItemType == LItemTypeConst.TYPE_EQUIP
        if isRefresh_1 or isRefresh_2 then
            self:RefreshAllGrid(self._nowShowItemType, true)

        end
    end)


    --self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)
    self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mAutoCompItemBtn, function()
        if self._btnRefId==201 then
            self:OnOneKeyUseItem()
            return
        end
        gModelItem:BagAutoCompFunc(self:GetWndName())
    end)

    self:SetWndClick(self.mAllPartBtn, function()
        self:ChangeBagPartSel(0)
    end)
    -- for i, v in ipairs(self._bagPartList) do
    --     self:SetWndClick(v.trans, function()
    --         self:ChangeBagPartSel(v.partType)
    --     end)
    -- end
    self:SetWndClick(self.mAllQualityBtn, function()
        self:ChangeHeroZSSel(0)
    end)
    for i, v in ipairs(self._bagHeroZSList) do
        self:SetWndClick(v.trans, function()
            self:ChangeHeroZSSel(v.zsType)
        end)
    end
    self:SetWndClick(self.mHeroAllRaceBtn, function()
        self:ChangeHeroRaceSel(0)
    end)
    for i, v in ipairs(self._heroRaceList) do
        self:SetWndClick(v.trans, function()
            self:ChangeHeroRaceSel(v.raceType)
        end)
    end
    self:SetWndClick(self.mChangePartBtn, function()
        self:OnClickChangePartBtnFunc(true)
    end)
    self:SetWndClick(self.mHideMoreBg, function()
        self:OnClickChangePartBtnFunc(false)
    end)
    self:SetWndClick(self.mGolemAutoResolveBtn, function()
        gModelGolem:OpenGolemResolve()
    end)
    self:SetWndClick(self.mClickMask, function()
        self:OnClickClickMaskFunc(true)
    end)
end

function UIBags:RefreshGolemInfo()
    CS.ShowObject(self.mClickMask, false)
    local refId = self._btnRefId
    local isGolem = refId == 208
    CS.ShowObject(self.mSelGolemDiv, isGolem)
end

function UIBags:OnTcpReconnect()
    self:RefreshFunc()
end

--------- 修改背包装备品质状态
function UIBags:ChangeHeroZSSel(zsType)
    if self._bagHeroZSType == zsType then
        return
    end
    self._bagHeroZSType = zsType
    self:RefreshSelBagHeroZSImg()
    self:RefreshAllGrid(LItemTypeConst.TYPE_OUTFIT)
end

function UIBags:GetTransByRefId(refId)
    if self._itemRefIdToTran then
        return self._itemRefIdToTran[refId]
    end
end

function UIBags:InitShowSelDivInfoList()
    self._showSelDivInfoList = {
        --- 配置数据，可选择的数据
        config = {
            [ModelGolem.GOLEM_DIV_SORT] = ModelGolem.GOLEM_DIV_SORT_NUM,
            [ModelGolem.GOLEM_DIV_ATTR] = {
                [ModelGolem.GOLEM_DIV_ATTR_PRIME] = ModelGolem.GOLEM_DIV_ATTR_PRIME_NUM,
                [ModelGolem.GOLEM_DIV_ATTR_DEPUTY] = ModelGolem.GOLEM_DIV_ATTR_DEPUTY_NUM,
            },
            [ModelGolem.GOLEM_DIV_STATUS] = ModelGolem.GOLEM_DIV_STATUS_NUM,
        },
        --- 玩家选择的数据
        selInfo = {
            [ModelGolem.GOLEM_DIV_SORT] = {
                selNum = 0,
                keyMap = {},
            },
            [ModelGolem.GOLEM_DIV_ATTR] = {
                [ModelGolem.GOLEM_DIV_ATTR_PRIME] = {
                    selNum = 0,
                    keyMap = {},
                },
                [ModelGolem.GOLEM_DIV_ATTR_DEPUTY] = {
                    selNum = 0,
                    keyMap = {},
                },
            },
            [ModelGolem.GOLEM_DIV_STATUS] = {
                selNum = 0,
                keyMap = {},
            },

        },
    }
end

function UIBags:GetStatusSelGolemList(key, listTrans, showType)
    local list = {}
    table.insert(list, {
        showType = showType,
        refId = ModelGolem.GOLEM_SORT_LVL,
        showStr = ccClientText(33211),
        listKey = key,
        listTrans = listTrans,
    })
    table.insert(list, {
        showType = showType,
        refId = ModelGolem.GOLEM_SORT_GETTIME,
        showStr = ccClientText(33212),
        listKey = key,
        listTrans = listTrans,
    })
    table.insert(list, {
        showType = showType,
        refId = ModelGolem.GOLEM_SORT_ATTRTYPE,
        showStr = ccClientText(33213),
        listKey = key,
        listTrans = listTrans,
    })
    return list
end

function UIBags:GetEquipList(bSort)
    local list = gModelEquip:GetEquipList()
    local t = {}
    for _, v in pairs(list) do
        if v:GetNum() > 0 then
            table.insert(t, v)
        end
    end
    if bSort then
        table.sort(t, function(item1, item2)
            --local refId1 = item1.refId or item1:GetRefId()
            --local refId2 = item2.refId or item2:GetRefId()
            --
            --local type1 = item1.itype or item1:GetType()
            --local type2 = item2.itype or item2:GetType()
            --local ref1, ref2 = self:GetTypeRef(type1, refId1), self:GetTypeRef(type2, refId2)
            --if ref1 and ref2 then
            --    local sort1, sort2 = ref1.order, ref2.order
            --    return sort1 < sort2
            --end
            local sort1, sort2 = item1:GetOrder(), item2:GetOrder()
            return sort1 > sort2
        end)
    end
    return t
end

function UIBags:InitMsg()
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        self:RefreshListTransFunc()
    end)

    self:WndNetMsgRecv(LProtoIds.ItemListResp, function()
        if self._lastbtn ~= 4 and self._lastbtn ~= 1 then
            self:RefreshAllGrid(LItemTypeConst.TYPE_ITEM, true)
        end
    end)

    self:WndNetMsgRecv(LProtoIds.ItemChangeResp, function()
        self:RefreshAllGrid(self._nowShowItemType, true)
        self:BtnEvent(self._btnRefId, self._lastbtn, true)
    end)
    self:WndNetMsgRecv(LProtoIds.ChangeRuneResp, function()
        if self._lastbtn == 6 then
            self:RefreshAllGrid(LItemTypeConst.TYPE_RUNE, true)
        elseif self._lastbtn == 1 then
            self:RefreshAllGrid(0, true)
        end
    end)
    self:WndNetMsgRecv(LProtoIds.GolemBagResp, function()
        self:OnGolemBagResp()
    end)
    self:WndEventRecv(EventNames.REFRESH_OUTFITOPT_BAG, function()
        if self._refreshByOutfitOpt then
            self:OutfitOptResp()
        end
        self._refreshByOutfitOpt = false
    end)
    self:WndEventRecv(EventNames.On_Equip_Change, function()
        self:RefreshAllGrid(self._nowShowItemType, true)
        self:BtnEvent(self._btnRefId, self._lastbtn, true)
    end)
end

function UIBags:CheckIsSel(showType, info)
    if showType == ModelGolem.GOLEM_DIV_SORT then
        local selTypeKeyInfo = self:GetSelInfoKeyMapByShowType(showType)
        return selTypeKeyInfo[info.refId] ~= nil or false
    elseif showType == ModelGolem.GOLEM_DIV_ATTR then
        local selAttrType = info.selAttrType
        if not selAttrType then
            return false
        end

        local selTypeInfo = self:GetSelInfoByShowType(showType)
        local selTypeKeyTypeInfo = selTypeInfo[selAttrType]
        if not selTypeKeyTypeInfo then
            return false
        end

        local keyMap = self:GetKeyMap(selTypeKeyTypeInfo)
        return keyMap[info.refId] ~= nil or false
    elseif showType == ModelGolem.GOLEM_DIV_STATUS then
        local selTypeKeyInfo = self:GetSelInfoKeyMapByShowType(showType)
        return selTypeKeyInfo[info.refId] ~= nil or false
    end
end

function UIBags:GetSortSelGolemList(key, listTrans, showType)
    local list = {}
    local suitTypeList = gModelGolem:GetGolemSuitList()
    for i, v in ipairs(suitTypeList) do
        table.insert(list, {
            showType = showType,
            refId = v.refId,
            showStr = v.name,
            type = v.type,
            listKey = key,
            listTrans = listTrans,
        })
    end
    return list
end

--------- 刷新背包装备专属英雄种族选中图
function UIBags:RefreshSelHeroRaceImg()
    local heroRaceType = self._heroRaceType
    local trans = self._heroRaceKeyTransList[heroRaceType]
    if trans then
        CS.SetParentTrans(self.mHeroRaceSelImg, trans)
    end
end

function UIBags:InitAttrList(trans, list)
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...)
            self:OnDrawAttrCell(...)
        end)
    end
end

function UIBags:GetSelInfoSelNumByShowType(showType)
    --- 属性除外 ， 属性有主副之分
    local selTypeInfo = self:GetSelInfoByShowType(showType)
    if not selTypeInfo then
        return
    end
    return self:GetSelNum(selTypeInfo)
end

function UIBags:InitAttrSelGolemDiv()
    local showDivType = ModelGolem.GOLEM_DIV_ATTR
    local trans = self.mAttrSelGolemDiv
    local transInfo = self:GetSelGolemDivInfo(trans, showDivType, ccClientText(33250))
    self:SetWndClick(transInfo.DivBgTrans, function()
        self:OnClickAttrSelGolemDivFunc(transInfo, showDivType)
    end)
end

function UIBags:GetItemStatus(tabType, isAuto)
    local list = self:GetItemList(nil, tabType)
    for k, v in pairs(list) do
        local refId = v.refId or v:GetRefId()
        if gModelItem:GetIsShowRedPointByRefId(refId) then
            return true
        end

        local isCheckSuiPina = false
        if isAuto then
            local itype = gModelItem:GetType(refId)
            isCheckSuiPina = not (itype == ModelItem.TTEM_TYPE_EQUIP_STRENGTH_3)
        else
            isCheckSuiPina = true
        end

        if isCheckSuiPina then
            local suipian = gModelItem:GetSuiPianNeedNumByRefId(refId)
            if suipian then
                local num = tonumber(v:GetNum())
                if num >= suipian then
                    return true
                end
            end
        end

        if tabType == 101 then
            local status = gModelItem:CheckAllLeiDengStatus()
            if status then
                return status
            end
        end
    end
    return false
end

function UIBags:InitAttrSelGolemList(listTrans, refreshData)
    local BgTrans = self:FindWndTrans(listTrans, "Bg")
    CS.ShowObject(BgTrans, true)

    local BtnDivTrans = self:FindWndTrans(listTrans, "BtnDiv")
    local BtnYellow3Trans = self:FindWndTrans(BtnDivTrans, "BtnYellow3")
    self:SetWndButtonText(BtnYellow3Trans, ccClientText(45422))
    self:SetWndClick(BtnYellow3Trans, function()

        self:OnClickAttrEnterBtnFunc()
    end)
    CS.ShowObject(BtnDivTrans, true)

    local key = listTrans:GetInstanceID()
    local list = self:GetAttrSelGolemList(key)
    self:InitSelAttrInfo(list)

    local uiList = self:FindUIScroll(key)
    if uiList then
        if refreshData then
            uiList:RefreshData(list)
        else
            uiList:RefreshList(list)
        end
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(listTrans, list, function(...)
            self:OnDrawAttrSelGolemCell(...)
        end)
    end
end

function UIBags:RefreshAllGrid(itemType, isRefresh)
    self._nowShowItemType = itemType or 0
    local allListData = nil
    local isEquipType = itemType == LItemTypeConst.TYPE_EQUIP
    local isGolem = itemType == LItemTypeConst.TYPE_GOLEM
    self:InitBtnTabList()
    if itemType == LItemTypeConst.TYPE_ITEM then
        allListData = self:GetItemList(true)
    elseif itemType == LItemTypeConst.TYPE_RUNE then
        allListData = self:GetRuneList(true)
        -- 【G公共支持】删除伙伴晶石功能相关数据
        -- elseif itemType == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD or itemType == LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING then
        -- 	allListData = self:GetShardList()
    elseif isGolem then
        allListData = self:GetGolemBagList(true)
    elseif isEquipType then
        allListData = self:GetEquipList(true)
    else
        allListData = self:GetAllItemList()
    end

    local showGolemAutoBtn = isGolem
    -- if showGolemAutoBtn then
    --     local guideGolemList = {
    --         16201,
    --     }
    --     local status = false
    --     for i, v in ipairs(guideGolemList) do
    --         status = gModelGuide:IsGuideFinished(v)
    --         if LOG_INFO_ENABLED then
    --             if status then
    --                 printInfoNR("打印而已，莫慌   ===== 已完成指引id：" .. v)
    --             else
    --                 printInfoNR("打印而已，莫慌   ===== 未完成指引id：" .. v)
    --             end
    --         end
    --         if status then
    --             break
    --         end
    --     end
    --     showGolemAutoBtn = status
    -- end
    CS.ShowObject(self.mGolemAutoResolveBtn, showGolemAutoBtn)

    self._allStateList = {}
    for i, v in ipairs(allListData) do
        local setState = false
        local refId = v.refId or v:GetRefId()
        local itype = v.itype or v:GetType()
        if itemType == 0 then
            setState = true
        elseif itype == itemType then
            setState = true
        end
        if setState then
            local state
            if itype == LItemTypeConst.TYPE_EQUIP then
                state = gModelEquip:IsNewEquip(v:GetRefId())
            else
                state = v.state or v:GetState()
            end
            local isShowNew = state == ModelItem.ITEM_NEW_STATUS
            local key = refId
            if itype == LItemTypeConst.TYPE_RUNE then
                key = v.id or v:GetRuneId()
            elseif itype == LItemTypeConst.TYPE_OUTFIT then
                key = refId .. v.heroRefId .. v.star .. v.starExp
            end
            self._allStateList[key] = isShowNew
        end
    end

    CS.ShowObject(self.mNoRecord, false)
    CS.ShowObject(self.mNoOutfitRecord, false)

    local noRecordTrans = isEquipType and self.mNoOutfitRecord or self.mNoRecord
    if (#allListData == 0) then
        CS.ShowObject(noRecordTrans, true)
        CS.ShowObject(self.mCommonList, false)
        return
    end

    CS.ShowObject(noRecordTrans, false)
    CS.ShowObject(self.mCommonList, true)

    local uiList = self._uiAllList
    if not uiList then
        uiList = self:GetUIScroll("key_uiAllList")
        self._uiAllList = uiList
        uiList:Create(self.mCommonList, allListData, function(...)
            self:OnDrawAllItemCell(...)
        end, UIItemList.SUPER_GRID, false)
        local superList = uiList:GetList()
        superList:EnableLoadAnimation(true)
        superList:SetLoadAnimationScale(0.2, 0.15)
        superList:RefreshList(isRefresh)
    else
        uiList:RefreshList(allListData)

        local superList = uiList:GetList()
        if isRefresh then
            superList:DrawAllItems(false)
        else
            superList:MoveToPos(1, 0)
            superList:DrawAllItems(true)
        end
    end

end

function UIBags:RefreshSelGolemDivStatus()
    local showDivListTransList = self._showDivListTransList
    if not showDivListTransList then
        return
    end
    local showDivType = self._showDivType
    local show
    for showType, showDivListTrans in pairs(showDivListTransList) do
        show = showType == showDivType or false
        CS.ShowObject(showDivListTrans, show)
    end
    local info = self:GetSelInfo()
    local showDivNameTransList = self._showDivNameTransList
    for showType, divNameTransInfo in pairs(showDivNameTransList) do
        if showType == ModelGolem.GOLEM_DIV_ATTR then
            self:SetWndText(divNameTransInfo.nameTrans, divNameTransInfo.initTxt)
        else
            local selInfo = info[showType]
            local selNum = selInfo.selNum
            if selNum > 0 then
                local keyMap = selInfo.keyMap
                if showType == ModelGolem.GOLEM_DIV_SORT then
                    local suitTypeSort = gModelGolem:GetWarehouseSuitTypeStatus()
                    for k, v in pairs(keyMap) do
                        local name
                        if suitTypeSort == 0 then
                            name = gModelGolem:GetGolemSuitTypeNameByType(k)
                        elseif suitTypeSort == 1 then
                            name = gModelGolem:GetGolemSuitNameByRefId(k)
                        end
                        self:SetWndText(divNameTransInfo.nameTrans, name)
                    end
                elseif showType == ModelGolem.GOLEM_DIV_STATUS then
                    for k, v in pairs(keyMap) do
                        if k == ModelGolem.GOLEM_SORT_LVL then
                            self:SetWndText(divNameTransInfo.nameTrans, ccClientText(33211))
                        elseif k == ModelGolem.GOLEM_SORT_GETTIME then
                            self:SetWndText(divNameTransInfo.nameTrans, ccClientText(33212))
                        elseif k == ModelGolem.GOLEM_SORT_ATTRTYPE then
                            self:SetWndText(divNameTransInfo.nameTrans, ccClientText(33213))
                        end
                    end
                end
            else
                self:SetWndText(divNameTransInfo.nameTrans, divNameTransInfo.initTxt)
            end
        end
    end
end

function UIBags:GetConfig()
    local showSelDivInfoList = self._showSelDivInfoList
    if not showSelDivInfoList then
        return nil
    end
    return showSelDivInfoList.config
end

function UIBags:GetTypeRef(iType, refId)
    local ref
    if iType == LItemTypeConst.TYPE_ITEM then
        ref = gModelItem:GetRefByRefId(refId)
    elseif iType == LItemTypeConst.TYPE_EQUIP then
        ref = gModelEquip:GetEquipRefByRefId(refId)
    elseif iType == LItemTypeConst.TYPE_RUNE then
        ref = gModelRune:GetRuneInfoByRefId(refId)
        --【G公共支持】删除伙伴晶石功能相关数据
        -- elseif iType == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD then
        -- 	local cfg = gModelCrystalShard:GetCrystalCfgByType(ModelCrystalShard.CrystalTypeRef)
        -- 	ref = cfg[refId]
        -- elseif iType == LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING then
        -- 	local cfg = gModelCrystalShard:GetCrystalCfgByType(ModelCrystalShard.CrystalDrawingRef)
        -- 	ref = cfg[refId]
    end
    if not ref then
        -- 接入其他模块的表格查找
        if LOG_INFO_ENABLED then
            printInfoN("手动接入其他的模块的Ref", iType, refId)
        end
    end
    return ref
end

function UIBags:OnFrameLoadEffect()
    if not self._waitLoadEffList then
        return
    end
    if #self._waitLoadEffList <= 0 then
        return
    end
    if not self:IsWndVisible() then
        return
    end
    local instanceId = table.remove(self._waitLoadEffList, 1)
    local effData = self._itemEffectList[instanceId]
    if not effData then
        return
    end
    local effPath = effData.effPath
    self:CreateWndEffect(effData.root, effPath, effData.effKey, 100, false, false)

end

function UIBags:GetRuneList(sort)
    local runeList = gModelRune:GetNotWearRuneList(true) or {}
    return runeList
end

function UIBags:GetAllItemList()
    local allList = {}
    local list = {
        self:GetItemList(),
        self:GetEquipList(),
        self:GetRuneList(),
        -- self:GetGolemBagList(nil, true),
        --self:GetShardList()
    }
    for i, v in ipairs(list) do
        for index, data in pairs(v) do
            table.insert(allList, data)
        end
    end
    local btnSortList = self._btnSortList
    local sortAllListFunc = function(item1, item2)
        local refId1 = item1.refId or item1:GetRefId()
        local refId2 = item2.refId or item2:GetRefId()

        local type1 = item1.itype or item1:GetType()
        local type2 = item2.itype or item2:GetType()
        local ref1, ref2 = self:GetTypeRef(type1, refId1), self:GetTypeRef(type2, refId2)
        if ref1 and ref2 then
            --local isCrystalType1 = type1 == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD or type1 == LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING
            --local isCrystalType2 = type2 == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD or type1 == LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING
            --local tabType1 = isCrystalType1 and self:GetTabTypeByIType(type1) or ref1.tabType
            --local tabType2 = isCrystalType2 and self:GetTabTypeByIType(type2) or ref2.tabType
            local tabType1 = ref1.tabType
            local tabType2 = ref2.tabType
            if tabType1 == tabType2 then
                -- 【G公共支持】删除伙伴晶石功能相关数据
                -- if(type1 == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD or type1 ==LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING)then
                -- 	if(item1.type ~= item2.type)then
                -- 		return item1.type > item2.type
                -- 	end
                -- 	return item1.quality > item2.quality
                -- else
                local sort1, sort2 = ref1.order, ref2.order
                if nil == sort1 or nil == sort2 then
                    printInfoN2("----------------------refId1--" .. refId1 .. "---------------refId2--" .. refId2)
                    return false
                else
                    --装备内部的排序
                    if sort1 == sort2 and type1 == LItemTypeConst.TYPE_EQUIP then
                        sort1, sort2 = item1:GetOrder(), item2:GetOrder()
                        return sort1 > sort2
                    end

                    return sort1 < sort2

                end
                -- end
            else
                local allSort1 = btnSortList[tabType1] or 0
                local allSort2 = btnSortList[tabType2] or 0
                return allSort1 < allSort2
            end
        end
        return false
    end
    table.sort(allList, sortAllListFunc)

    --【G公共支持】删除伙伴晶石功能相关数据
    -- local shardList = self:GetShardList()
    -- if shardList then
    -- 	for index,data in pairs(shardList) do
    -- 		table.insert(allList,data)
    -- 	end
    -- end

    return allList
end

function UIBags:GetConfigNumByShowType(showType)
    local config = self:GetConfig()
    if not config then
        return
    end
    return config[showType]
end

function UIBags:InitStatusSelGolemDiv()
    local showDivType = ModelGolem.GOLEM_DIV_STATUS
    local trans = self.mStatusSelGolemDiv
    local transInfo = self:GetSelGolemDivInfo(trans, showDivType, ccClientText(33251))
    self:SetWndClick(transInfo.DivBgTrans, function()
        self:OnClickStatusSelGolemDivFunc(transInfo, showDivType)
    end)
end

function UIBags:GetOutfitList(sort)
    -- local list = gModelOutfit:GetBagSortOutfitList(sort, {
    --     outfitType = self._bagSelPartType,
    --     heroQuality = self._bagHeroZSType,
    --     heroRace = self._heroRaceType,
    -- })

    -- return list
end

--【G公共支持】删除伙伴晶石功能相关数据
-- function UIBags:GetShardList()
-- 	local shardList = gModelCrystalShard:GetUIBagsShowCrystalList(true,false)
-- 	if(not shardList)then
-- 		return {}
-- 	end
-- 	return shardList
-- end

function UIBags:GetGolemBagList(sort, isAll)
    local useWarhouse = true
    if isAll then
        local allGolemIsShowWarhouse = gModelGolem:GetGolemConfigRefByKey("allGolemIsShowWarhouse")
        if not allGolemIsShowWarhouse then
            allGolemIsShowWarhouse = 1
            if LOG_INFO_ENABLED then
                printInfoNR("GolemConfigRef 表 allGolemIsShowWarhouse 字段控制当前页签是全部时，是否按照仓库逻辑来显示，默认 1 为仓库逻辑")
            end
        end
        useWarhouse = allGolemIsShowWarhouse == 1
    end
    local golemBagList = {}
    if useWarhouse then
        golemBagList = gModelGolem:GetGolemWarehouseList(self:GetSelInfo(), {})
    else
        golemBagList = gModelGolem:GetGolemBagList()
        table.sort(golemBagList, function(a, b)
            local refIdA = a.refId
            local refIdB = b.refId
            local orderA = gModelGolem:GetGolemElementConfigOrderByRefId(refIdA)
            local orderB = gModelGolem:GetGolemElementConfigOrderByRefId(refIdB)
            if orderA ~= orderB then
                return orderA < orderB
            end
        end)
    end
    return golemBagList
end

function UIBags:InitCommonListRect()
    local raceMax = self.mCommonList.offsetMax
    local raceMin = self.mCommonList.offsetMin
    self._commonPosList = {
        topPosX = raceMax.x,
        topPosY = raceMax.y,
        botPosX = raceMin.x,
        botPosY = raceMin.y,
    }
    if LOG_INFO_ENABLED then
        printInfoNR("from UIBags | ===================")
    end
end

function UIBags:GetAttrSelGolemList(listKey)
    local list = {}
    local attrList = {}
    local showType = ModelGolem.GOLEM_DIV_ATTR
    local attr = gModelGolem:GetGolemConfigRefByKey("attr")
    for i, v in ipairs(attr) do
        v = tonumber(v)
        table.insert(attrList, {
            attrRefId = v,
            selAttrType = ModelGolem.GOLEM_DIV_ATTR_PRIME,
            showType = showType,
            listKey = listKey,
        })
    end
    table.insert(list, {
        selAttrType = ModelGolem.GOLEM_DIV_ATTR_PRIME,
        showType = showType,
        attrList = attrList,
        str = ccClientText(33218),
        listKey = listKey,
    })

    local attrDeputyList = {}
    local attrDeputy = gModelGolem:GetGolemConfigRefByKey("attrDeputy")
    for i, v in ipairs(attrDeputy) do
        v = tonumber(v)
        table.insert(attrDeputyList, {
            attrRefId = v,
            selAttrType = ModelGolem.GOLEM_DIV_ATTR_DEPUTY,
            showType = showType,
            listKey = listKey,
        })
    end
    table.insert(list, {
        selAttrType = ModelGolem.GOLEM_DIV_ATTR_DEPUTY,
        showType = showType,
        attrList = attrDeputyList,
        str = ccClientText(33219),
        listKey = listKey,
    })

    return list
end

function UIBags:RefreshFunc(refId, refresh)
    refId = refId or self._btnRefId
    self:ClearAllItemEffect()
    self:DestroyWndEffectAll()
    self:ChangeBtnImage(nil, nil, nil, true)
    for i, v in ipairs(self._listSortTransList) do
        local k = v.key
        local show = k == refId
        if show then
            if v.func then
                v.func(refresh)
            end
            break
        end
    end
    self:RefreshGolemInfo()
    self:ChangeCommonListPos()
end

function UIBags:CheckAttrSelStatus(selAttrType, attrRefId)
    local selAttrInfoMap = self._selAttrInfoMap
    if not selAttrInfoMap then
        return false
    end
    local selInfo = selAttrInfoMap[selAttrType]
    if not selInfo then
        return false
    end
    local selAttrInfo = selInfo[attrRefId]
    if not selAttrInfo then
        return false
    else
        return selAttrInfo.status or false
    end
end

function UIBags:GetSelInfoByShowType(showType)
    local selInfo = self:GetSelInfo()
    if not selInfo then
        return
    end
    return selInfo[showType]
end

function UIBags:InitEffectTimer()
    self._itemEffectTimerKey = "item_effect_create"
    self:TimerStart(self._itemEffectTimerKey, 0.1, false, -1)
end

function UIBags:OnOneKeyUseItem()
    local info = {}
    local superList = self._uiAllList:GetList()
    local count = superList:GetDataSize()
    local list = {}
    for indx = 1, count do
        local itemdata = superList:GetDataByIndex(indx)
        local type = gModelItem:GetType(itemdata._refId)
        if type ==ModelItem.Item_GIFT or type == ModelItem.Item_DROP then
            table.insert(info,{refId = itemdata._refId,num = tonumber(itemdata:GetNum())}) --向服务器发送物品使用请求
            table.insert(list,{itemId = itemdata._refId,type = itemdata:GetType(),count = tonumber(itemdata:GetNum())})
        end
    end
    if #list>0 then
        gModelGeneral:OpenUIOrdinTips({refId = 10047,itemList = list,func = function()
            gModelItem:OnItemUseReq(info)
        end})
    else
        GF.ShowMessage(ccClientText(10260))
    end
end

function UIBags:ChangeCommonListPos()
    local commonPosList = self._commonPosList
    if not commonPosList then
        self:InitCommonListRect()
        commonPosList = self._commonPosList
    end
    local btnRefId = self._btnRefId
    local topPosX, botPosX = commonPosList.topPosX, commonPosList.botPosX
    local topPosY, botPosY
    --local isSuiPian = btnRefId == 201
    local isSuiPian = btnRefId == 202
    local isGolem = btnRefId == 208
    local isItem = btnRefId == 201
    local isBadge = btnRefId == 209
    local isDefault = false
    if isSuiPian or isItem then
        topPosY, botPosY = commonPosList.topPosY, 332.3792
    elseif isBadge then
        topPosY, botPosY = commonPosList.topPosY, 340
    else
        topPosY, botPosY = commonPosList.topPosY, commonPosList.botPosY
        isDefault = true
    end
    if isGolem then
        isDefault = false
        topPosY, botPosY = commonPosList.topPosY, 338
        local golemBagList = gModelGolem:GetGolemBagList()
        local golemBagNum = #golemBagList
        local allNum = gModelGolem:GetBagSaveNum()
        local isFull = golemBagNum >= allNum
        local textId = isFull and 34846 or 34847
        local str = string.replace(ccClientText(textId),golemBagNum,allNum)
        self:SetTextTile(self.mGolemNum,str)
    end
    local btnName = isSuiPian and ccClientText(10243) or ccClientText(45960)
    self:RefreshAutoCompItemBtn(isSuiPian)
    CS.ShowObject(self.mDi, isDefault)
    CS.ShowObject(self.mDi2, isSuiPian or isItem)

    CS.ShowObject(self.mDi6, isGolem or isBadge)
    CS.ShowObject(self.mGolemNum, isGolem)

    CS.ShowObject(self.mAutoCompItemBtn, isSuiPian or isItem)
    self:SetWndButtonText(self.mAutoCompItemBtn,btnName)
    if isItem then CS.ShowObject(self.mAutoCompItemRedPoint, self:GetItemStatus(201, true)) end


    self.mCommonList.offsetMax = Vector2(topPosX, topPosY)
    self.mCommonList.offsetMin = Vector2(botPosX, botPosY)
end

function UIBags:OnClickClickMaskFunc(notRefresh)
    CS.ShowObject(self.mClickMask, false)
    self._showDivType = nil
    self:RefreshSelGolemDivStatus()
    if notRefresh then
        return
    end
    ----- 逻辑处理
    self:RefreshFunc()
end

function UIBags:OnClickSortSelGolemDivFunc(transInfo, showType)
    local listTrans = transInfo.SelListTrans
    local bool = self:OnClickCommonDivFunc(transInfo, showType)
    if not bool then
        return
    end

    local key = listTrans:GetInstanceID()
    local list = self:GetSortSelGolemList(key, listTrans, showType)

    local selNum = self:GetSelInfoSelNumByShowType(showType)
    local configNum = self:GetConfigNumByShowType(showType)
    local index
    if selNum >= configNum then
        local value
        for i, v in ipairs(list) do
            value = gModelGolem:GetWarehouseSuitTypeKey(v)
            if self:CheckIsSel(showType, { refId = value }) then
                index = i + 1
                break
            end
        end
    end
    self:InitCommonSelList(key, listTrans, list, nil, showType, index)
end

function UIBags:InitSelBtnList()
    ---------------------------- 装备部位列表 ----------------------------
    -- local bagPartList = {}
    -- table.insert(bagPartList, {
    --     partType = 0,
    --     trans = self.mAllPartBtn,
    -- })
    -- local outfitPartList = {}
    -- for k, v in pairs(GameTable.OutfitPartRef) do
    --     table.insert(outfitPartList, { partType = v.type, img = v.selectIcon })
    -- end
    -- table.sort(outfitPartList, function(a, b)
    --     return a.partType < b.partType
    -- end)
    -- local partTransList = { self.mOutfit1Btn, self.mOutfit2Btn, self.mOutfit3Btn, self.mOutfit4Btn, }
    -- for i, v in ipairs(outfitPartList) do
    --     local trans = partTransList[i]
    --     if trans then
    --         self:SetWndEasyImage(trans, v.img)
    --         table.insert(bagPartList, {
    --             partType = v.partType,
    --             trans = trans
    --         })
    --     end
    -- end
    -- self._bagPartList = bagPartList
    -- local bagPartKeyTransList = {}
    -- for i, v in ipairs(bagPartList) do
    --     bagPartKeyTransList[v.partType] = v.trans
    -- end
    -- self._bagPartKeyTransList = bagPartKeyTransList
    -- self._bagSelPartType = bagPartList[1].partType

    ---------------------------- 装备专属英雄品质列表 ----------------------------
    local bagHeroZSList = {}
    table.insert(bagHeroZSList, {
        zsType = 0,
        trans = self.mAllQualityBtn
    })
    local qualityList = {}
    local getQualityRefList = { 6, 7 }
    for i, v in ipairs(getQualityRefList) do
        local qualityRef = gModelItem:GetQualityRef(v)
        if qualityRef then
            table.insert(qualityList, {
                zsType = v,
                img = qualityRef.selectIcon
            })
        end
    end
    local qualityTransList = { self.mQuality1Btn, self.mQuality2Btn }
    for i, v in ipairs(qualityList) do
        local trans = qualityTransList[i]
        if trans then
            self:SetWndEasyImage(trans, v.img)
            table.insert(bagHeroZSList, {
                zsType = v.zsType,
                trans = trans
            })
        end
    end
    self._bagHeroZSList = bagHeroZSList
    local bagHeroZSKeyTransList = {}
    for i, v in ipairs(bagHeroZSList) do
        bagHeroZSKeyTransList[v.zsType] = v.trans
    end
    self._bagHeroZSKeyTransList = bagHeroZSKeyTransList
    self._bagHeroZSType = bagHeroZSList[1].zsType

    ---------------------------- 装备专属英雄种族列表 ----------------------------
    local heroRaceList = {}
    table.insert(heroRaceList, {
        raceType = 0,
        trans = self.mHeroAllRaceBtn
    })
    local raceList = {}
    for k, v in pairs(GameTable.CharacterRaceRef) do
        table.insert(raceList, {
            raceType = v.refId,
            img = v.icon
        })
    end
    table.sort(raceList, function(a, b)
        return a.raceType < b.raceType
    end)
    local raceTransList = { self.mHeroRace1Btn, self.mHeroRace2Btn, self.mHeroRace3Btn, self.mHeroRace4Btn, self.mHeroRace5Btn }
    for i, v in ipairs(raceList) do
        local trans = raceTransList[i]
        if trans then
            self:SetWndEasyImage(trans, v.img)
            table.insert(heroRaceList, {
                raceType = v.raceType,
                trans = trans
            })
        end
    end
    self._heroRaceList = heroRaceList
    local heroRaceKeyTransList = {}
    for i, v in ipairs(heroRaceList) do
        heroRaceKeyTransList[v.raceType] = v.trans
    end
    self._heroRaceKeyTransList = heroRaceKeyTransList
    self._heroRaceType = heroRaceList[1].raceType
end

function UIBags:OnClickAttrEnterBtnFunc()
    local selAttrInfoMap = self._selAttrInfoMap
    local showSelDivInfoList = self._showSelDivInfoList
    local selInfo = showSelDivInfoList.selInfo
    --local arrSelInfo = selInfo[ModelGolem.GOLEM_DIV_ATTR]
    local selAttrType
    local selAttrTypeNumList = {}
    for i, v in pairs(selAttrInfoMap) do
        selAttrType = i
        selAttrTypeNumList[selAttrType] = 0
        for j, k in pairs(v) do
            if k.status then
                --  arrSelInfo[i].keyMap[j] = j
                local selAttrTypeNum = selAttrTypeNumList[selAttrType] or 0
                selAttrTypeNumList[selAttrType] = selAttrTypeNum + 1
            else
                --   arrSelInfo[i].keyMap[j] = nil
            end
        end
    end
    for tSelAttrType, tSelAttrNum in pairs(selAttrTypeNumList) do
        --   arrSelInfo[tSelAttrType].selNum = tSelAttrNum
    end
    self._showSelDivInfoList = showSelDivInfoList
    self:OnClickClickMaskFunc()
end

function UIBags:InitCommonSelList(key, trans, list, refreshData, showType, index)
    local uiList = self:FindUIScroll(key)
    if uiList then
        if refreshData then
            uiList:RefreshData(list)
        else
            uiList:RefreshList(list)
        end
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...)
            self:OnDrawCommonSelList(...)
        end)
        uiList:EnableScroll(#list > 8)
    end
    if index then
        local tList = uiList:GetList()
        tList:RefreshList()
        tList:DelayScrollTo(index - 1, 2)
    end
end

function UIBags:OnDrawCommonSelList(list, item, itemdata, itempos)
    local NoSelTxtTrans = self:FindWndTrans(item, "NoSelTxt")
    local SelImgTrans = self:FindWndTrans(item, "SelImg")
    local SelTxtTrans = self:FindWndTrans(SelImgTrans, "SelTxt")
    local BtnTrans = self:FindWndTrans(item, "Btn")
    local TuiJianTrans = self:FindWndTrans(item, "TuiJian")

    self:SetWndText(NoSelTxtTrans, itemdata.showStr)

    local value
    local showType = itemdata.showType
    if showType == ModelGolem.GOLEM_DIV_SORT then
        value = gModelGolem:GetWarehouseSuitTypeKey(itemdata)
    elseif showType == ModelGolem.GOLEM_DIV_STATUS then
        value = itemdata.refId
    end
    local show = self:CheckIsSel(showType, {
        refId = value
    })
    if show then
        self:SetWndText(SelTxtTrans, itemdata.showStr)
    end
    CS.ShowObject(SelImgTrans, show)

    CS.ShowObject(TuiJianTrans, false)

    self:SetWndClick(BtnTrans, function()
        self:OnClickCommonBtnFunc(itemdata)
    end)
end

function UIBags:OnClickAttrSelGolemDivFunc(transInfo, showType)
    local listTrans = transInfo.SelListTrans
    local bool = self:OnClickCommonDivFunc(transInfo, showType)
    if not bool then
        return
    end

    self:InitAttrSelGolemList(listTrans)
end

function UIBags:GetSelInfo()
    local showSelDivInfoList = self._showSelDivInfoList
    if not showSelDivInfoList then
        return nil
    end
    return showSelDivInfoList.selInfo
end

function UIBags:OnClickStatusSelGolemDivFunc(transInfo, showType)
    local listTrans = transInfo.SelListTrans
    local bool = self:OnClickCommonDivFunc(transInfo, showType)
    if not bool then
        return
    end

    local key = listTrans:GetInstanceID()
    local list = self:GetStatusSelGolemList(key, listTrans, showType)
    self:InitCommonSelList(key, listTrans, list, nil, showType)
end

function UIBags:OnTimer(key)
    if key == self._itemEffectTimerKey then
        self:OnFrameLoadEffect()
    end
end

function UIBags:GetItemList(sort, tabelType)
    local allBtnType = self._btnIdList[1].refId
    local btnRefId = tabelType or self._btnRefId
    local tabEnum = self._tabEnum
    local list = {}
    local itemList = gModelItem:GetItemList() or {}
    for k, v in pairs(itemList) do
        local refId = v:GetRefId()
        local display = gModelItem:GetDisplayByRefId(refId)
        if display then
            local ins = false
            local tabType = gModelItem:GetTabTypeByRefId(refId)

            if tabType and tabType == btnRefId then
                ins = self:CheckIsIntoTabEnum(btnRefId,refId,tabEnum)
            elseif btnRefId == allBtnType then
                ins = true
            end
            if ins then
                local isLeiDeng = gModelItem:GetLeiDengItemByRefId(refId)
                if isLeiDeng then
                    local LeiDengList = gModelItem:GetLeiDengServerDataById(refId)
                    for id, info in pairs(LeiDengList) do
                        table.insert(list, {
                            refId = refId,
                            itype = 1,
                            id = id,
                            num = 1,
                            state = v:GetState()
                        })
                    end
                else
                    local type = gModelItem:GetType(refId)
                    if ModelItem.UNIQUE_ITEM_TYPE[type] then
                        --if type == ModelItem.Item_Summon or type == ModelItem.ITEM_WISH_MATCH then
                        local _itemExtras = v._itemExtras
                        local _num = v._num
                        if not string.isempty(_num) then
                            _num = tonumber(_num)
                            for j = 1, _num do
                                local _itemExtra = _itemExtras[j]
                                local data = {
                                    refId = refId,
                                    itype = 1,
                                    id = _itemExtra.id,
                                    num = 1,
                                    state = v:GetState(),
                                    extra = JSON.decode(_itemExtra.extra)
                                }
                                --if(type == ModelItem.ITEM_WISH_MATCH)then
                                --	data.extra = JSON.decode(_itemExtra.extra)
                                --end
                                table.insert(list, data)
                            end
                        end
                    else
                        table.insert(list, v)
                    end

                end
            end
        end
    end

    if not sort then
        return list
    end
    if not table.isempty(list) then
        local sortItemFunc = function(item1, item2)
            local refId1, refId2 = item1.refId or item1:GetRefId(), item2.refId or item2:GetRefId()
            local ref1, ref2 = gModelItem:GetRefByRefId(refId1), gModelItem:GetRefByRefId(refId2)
            local tabType1, tabType2 = ref1.tabType, ref2.tabType
            if tabType1 == tabType2 then
                local sort1, sort2 = ref1.order, ref2.order
                return sort1 < sort2
            else
                local allSort1, allSort2 = gModelItem:GetItemBagAllSortByRefId(tabType1) or 0, gModelItem:GetItemBagAllSortByRefId(tabType2) or 0
                local id1, id2 = item1.id, item2.id
                if id1 ~= nil and id2 ~= nil then
                    return tonumber(id1) < tonumber(id2)
                else
                    return allSort1 < allSort2
                end
            end
        end
        table.sort(list, sortItemFunc)
    end
    return list
end

-- 页签按钮列表
function UIBags:InitBtnList()
    local uiBtnList = self._uiBtnList
    if not uiBtnList then
        uiBtnList = UIListEasy:New()
        uiBtnList:Create(self, self.mTypeBtnList)
        uiBtnList:EnableScroll(true, true)
        uiBtnList:SetFuncOnItemDraw(function(...)
            self:OnDrawBtn(...)
        end)
        self._uiBtnList = uiBtnList
    end

    local btnList = self._btnIdList
    local btnSortList = self._btnSortList
    if table.isempty(btnList) then
        local ref = gModelItem:GetBagItemType()
        for k, v in pairs(ref) do
            table.insert(btnList, v)
            local allSort = v.allSort
            if allSort ~= 0 then
                btnSortList[v.refId] = allSort
            end
        end
        self._btnIdList = btnList
    end

    table.sort(btnList, function(btn1, btn2)
        return btn1.sort < btn2.sort
    end)

    local btnRefId = self._btnRefId
    local tIndex

    for i, v in ipairs(btnList) do
        local refId = v.refId
        if refId == btnRefId then
            tIndex = i
        end
        uiBtnList:AddData(refId, { index = i, refId = refId, ref = v })
    end

    self._lastbtn = tIndex
    self._btnRefId = nil
    self:BtnEvent(btnRefId, tIndex, nil, true)

    uiBtnList:RefreshList()

    if tIndex then
        uiBtnList:DelayScrollTo(tIndex - 1)
    end
end

function UIBags:SetStaticContent()
    self:SetXUITextText(self.mLblBiaoti, ccClientText(10200))
    self:SetWndButtonText(self.mAutoCompItemBtn, ccClientText(10243))
    self:SetWndButtonText(self.mGolemAutoResolveBtn, ccClientText(33230))
end

function UIBags:InitSortSelGolemDiv()
    local showDivType = ModelGolem.GOLEM_DIV_SORT
    local trans = self.mSortSelGolemDiv
    local transInfo = self:GetSelGolemDivInfo(trans, showDivType, ccClientText(33249))
    self:SetWndClick(transInfo.DivBgTrans, function()
        self:OnClickSortSelGolemDivFunc(transInfo, showDivType)
    end)
end

function UIBags:CheckDrawItemEffect(item, instanceID, itemType, refId, itempos)
    local effRoot = CS.FindTrans(item, "Eff")
    if not effRoot then
        return
    end
    local effData = self._itemEffectList[instanceID]
    local loadEff = nil
    if itemType == LItemTypeConst.TYPE_ITEM then
        local itemRef = gModelItem:GetRefByRefId(refId)
        loadEff = itemRef and itemRef.bgEff or nil
    end
    local bClearOldEff = true
    local bNew = false
    if not string.isempty(loadEff) then
        bNew = true
        if not effData then
            bClearOldEff = false
        elseif effData.effPath == loadEff then
            bClearOldEff = false
            bNew = false
        end
    end

    if bClearOldEff and effData then
        self:DestroyWndEffectByKey(effData.effKey)
        self._itemEffectList[instanceID] = nil
        table.removeidata(self._waitLoadEffList, instanceID)
    end

    if bNew then
        if not effData then
            effData = { root = effRoot, instanceID = instanceID, item = item, itempos = itempos }
        end
        effData.effPath = loadEff
        effData.effKey = instanceID .. loadEff
        self._itemEffectList[instanceID] = effData
        table.insert(self._waitLoadEffList, instanceID)
    end
end

--------- 修改背包装备专属英雄种族
function UIBags:ChangeHeroRaceSel(raceType)
    if self._heroRaceType == raceType then
        return
    end
    self._heroRaceType = raceType
    self:RefreshSelHeroRaceImg()
    self:RefreshAllGrid(LItemTypeConst.TYPE_OUTFIT)
end

function UIBags:CheckCutTabBtnGolemNeedInit()
    --local cutBagTabBtnNeedChange = gModelGolem:GetGolemConfigRefByKey("cutBagTabBtnNeedChange")
    local cutBagTabBtnNeedChange = nil
    if not cutBagTabBtnNeedChange then
        cutBagTabBtnNeedChange = 0
        if LOG_INFO_ENABLED then
            printInfoNR("cutBagTabBtnNeedChange 表格 cutBagTabBtnNeedChange 字段表示背包切换按钮需要重置筛选条件，默认是 0 ，不重置，配置为 1 表示需要重置")
        end
    end
    local isNeedReset = cutBagTabBtnNeedChange == 1
    if not isNeedReset then
        return
    end
    self:InitShowSelDivInfoList()
end

function UIBags:OnAwake()
    LWnd.OnAwake(self)
    self:DelaySendFinish(0.5)
end

function UIBags:GetSelNum(info)
    return info.selNum
end

---- 套装类型选择器
function UIBags:OnClickCommonSortDivFunc(itemdata)
    local showType = itemdata.showType
    local value = gModelGolem:GetWarehouseSuitTypeKey(itemdata)

    local isSel = self:CheckIsSel(showType, {
        refId = value,
    })
    local selTypeInfo = self:GetSelInfoByShowType(showType)
    local selTypeKeyInfo = self:GetSelInfoKeyMapByShowType(showType)
    if isSel then
        selTypeKeyInfo[value] = nil
        local selTypeNumInfo = self:GetSelInfoSelNumByShowType(showType)
        selTypeInfo.selNum = selTypeNumInfo - 1
        return true
    else
        local configNum = self:GetConfigNumByShowType(showType)
        local selTypeNumInfo = self:GetSelInfoSelNumByShowType(showType)
        if selTypeNumInfo < configNum then
            selTypeKeyInfo[value] = value
            selTypeInfo.selNum = selTypeNumInfo + 1
            return true
        else
            if configNum == 1 then
                --- 如果是只能选择单个的情况
                selTypeInfo.keyMap = {}
                selTypeInfo.keyMap[value] = value
                return true
            else
                --- 多选的情况不管，等策划决定
            end
        end
    end
    return false
end

function UIBags:CreateEmptyShow()
    local data = {
        refId = 3001,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
    local text = self:FindWndTrans(self.mOutfitEmptyBtn, "Light/Text")
    local data1 = {
        refId = 100,
        IntroTran = self.mOutfitEmptyText,
        TextBgTran = self.mOutfitEmptyTextBg,
        IconTran = self.mOutfitEmptyIcon,
        GetBtn = self.mOutfitEmptyBtn,
        GetBtnText = text,
    }
    local emptyList1 = self:GetCommonEmptyList("_empty1")
    emptyList1:RefreshUI(data1)
end

function UIBags:RefreshAutoCompItemBtn(isShow)
    CS.ShowObject(self.mAutoCompItemBtn, isShow)
    if not isShow then
        return
    end

    --local refId = 201
    local refId = 202
    --local temp = self._tabRedPointList[refId]

    local temp = {}
    temp.func = function(isAuto)
        return self:GetItemStatus(202, isAuto)
    end
    local showRed = false
    if temp then
        showRed = temp.func(true)
    end

    CS.ShowObject(self.mAutoCompItemRedPoint, showRed)

    --if gLGameLanguage:IsJapanRegion() then
    --    self:SetWndButtonGray(self.mAutoCompItemBtn, not showRed)
    --end
end

--------- 修改背包部位选中状态
function UIBags:ChangeBagPartSel(partType)
    if self._bagSelPartType == partType then
        return
    end
    self._bagSelPartType = partType
    self:RefreshSelBagPartImg()
    self:RefreshAllGrid(LItemTypeConst.TYPE_OUTFIT)
end

function UIBags:CheckIsIntoTabEnum(btnRefId,refId,tabEnum)
    if not tabEnum then return true end
    local ref = gModelItem:GetRefByRefId(refId)
    if not ref then return end

    if btnRefId == 209 then
        if tabEnum == 0 then return true end

        local typeData = checknumber(ref.typeDate)
        if typeData and typeData > 0 then
            local badgeRef = GameTable.BadgeRef[typeData]
            if badgeRef and badgeRef.skillType == tabEnum then
                return true
            end
        end

        return false
    end
    return true
end


function UIBags:GetBtnTabList()
    local list = {}
    local btnRefId = self._btnRefId
    if btnRefId and btnRefId > 0 then
        if btnRefId == 209 then
            list = {
                {tabEnum = 0,icon = "public_race_0"},
                {tabEnum = 1,icon = "jewelry_job_2"},
                {tabEnum = 2,icon = "jewelry_job_1"},
                {tabEnum = 3,icon = "jewelry_job_3"},
            }
        end
    end
    return list
end

function UIBags:InitBtnTabList()
    local list = self:GetBtnTabList()
    local hasBtnTab = #list > 0
    CS.ShowObject(self.mBtnTabList,hasBtnTab)
    if not hasBtnTab then return end


    if not self._tabEnum then
        self._tabEnum = list[1].tabEnum
    end

    ---@type UIItemList
    local uiTabScroll = self._uiTabScroll
    if uiTabScroll then
        uiTabScroll:RefreshList(list)
    else
        uiTabScroll = self:GetUIScroll("uiTabScroll")
        self._uiTabScroll = uiTabScroll
        uiTabScroll:Create(self.mTabScroll, list, function(...) self:OnDrawTabCell(...) end)
    end
end

function UIBags:OnDrawTabCell(list, item, itemdata, itempos)

    local isSel = self:CheckIsSelTab(itemdata)
    self:SetWndTabStatus(item,isSel and LWnd.StateOn or LWnd.StateOff)

    local icon = itemdata.icon
    self:SetWndTabIcon(item,icon,icon)

    self:SetWndClick(item,function()
        self:OnClickTabFunc(itemdata)
    end)
end

function UIBags:CheckIsSelTab(itemdata)
    return itemdata.tabEnum == self._tabEnum
end

function UIBags:OnClickTabFunc(itemdata)
    if self:CheckIsSelTab(itemdata) then return end
    self._tabEnum = itemdata.tabEnum
    self:RefreshAllGrid(self._nowShowItemType)
end
------------------------------------------------------------------
return UIBags