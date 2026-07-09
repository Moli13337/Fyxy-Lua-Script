---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaSelect:LWnd
local UISagaSelect = LxWndClass("UISagaSelect", LWnd)

UISagaSelect.IGNORE_RESONANCE = 1            -- 0：启用 				1：忽略

UISagaSelect.TYPE_STAR_UP = 1                -- 英雄升星
UISagaSelect.TYPE_AWAKEN = 2                -- 英雄觉醒
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaSelect:UISagaSelect()
    ---@type table<number,CommonIcon>
    self._commonIconClsTbl = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaSelect:OnWndClose()
    self:ClearCommonIconList(self._commonIconClsTbl)
    self._commonIconClsTbl = nil
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaSelect:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaSelect:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    local isOpenRace6 = gModelSpiritHero:CheckIsOpenSpiritHero() or false
    CS.ShowObject(self.mRaceBtn6, isOpenRace6)
    self:InitData()
    self:InitEmptyList()
    self:InitEvent()
    self:InitMsg()
    self:GetData()
    local dataList = self._dataList
    local itemList = self._itemList
    local haveSelHeroList = table.isempty(dataList)
    local haveSelItemList = table.isempty(itemList)
    local showAuto = (not haveSelHeroList) or (not haveSelItemList)
    if showAuto then
        local hiddenHeroAutomatic = gModelHero:GeConfigByKey("hiddenHeroAutomatic")
        if hiddenHeroAutomatic then
            local star = self._star
            if star >= hiddenHeroAutomatic then
                showAuto = false
                local localPosition = self.mEnterBtn.localPosition
                self.mEnterBtn.localPosition = Vector3(0, localPosition.y, localPosition.z)
            end
        end
        self:InitScrollView()
    else
        CS.ShowObject(self.mSelectHeroList, not haveSelHeroList)
        CS.ShowObject(self.mSelectBg, not haveSelHeroList)
        CS.ShowObject(self.mNoRecord, haveSelHeroList)
        CS.ShowObject(self.mCancelBtn, not haveSelHeroList)
        CS.ShowObject(self.mEnterBtn, not haveSelHeroList)
    end
    self:ShowNumTxt()

    self:SetXUITextText(self.mTitle, ccClientText(10029))
    self:SetXUITextText(self.mDescTxt, ccClientText(10028))
    self:SetXUITextText(self.mSelDescTxt, ccClientText(14707))
    self:SetWndButtonText(self.mEnterBtn, ccClientText(10102))

    if self._selectSameRefId then
        self:SetWndButtonText(self.mCancelBtn, ccClientText(10101))
        CS.ShowObject(self.mCancelBtn, true)
    else
        self:SetWndButtonText(self.mAutoBtn, ccClientText(14405))
        CS.ShowObject(self.mAutoBtn, showAuto)
    end

    CS.ShowObject(self.mRaceDiv, self._showRaceDiv)
end

function UISagaSelect:InitEvent()
    self:SetWndClick(self.mCancelBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBg, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mEnterBtn, function()
        self:EnterBtnFunc()
    end)

    self:SetWndClick(self.mAutoBtn, function()
        self:AutoBtnFunc()
    end)

    self:SetWndClick(self.mGetBtn, function()
        self:GetBtnFunc()
    end)

    local raceBtnList = self._raceBtnList or {}
    for i, v in ipairs(raceBtnList) do
        if i == 6 and gLGameLanguage:IsForeignRegion() then
            --欧美，韩国，日本暂时屏蔽星灵英雄
            CS.ShowObject(v, false)
        end

        self:SetWndClick(v, function()
            self:OnClickRaceType(i)
        end)
    end

    self:SetWndClick(self.mAllRaceBtn, function()
        self:OnClickRaceType(0)
    end)
end

function UISagaSelect:AutoBtnFunc1()
    local isSel = false
    local autoItemList = self._autoItemList
    for i, v in ipairs(autoItemList) do
        if self._selectHeroNum >= self._num then
            break
        end
        local id = v.id
        local refId = v.refId
        if not self._selectItemList[id].sel then
            if not isSel then
                isSel = true
            end
            local selItemNum = self._selItemList[refId]
            if not selItemNum then
                selItemNum = 0
            end
            selItemNum = selItemNum + 1
            self._selItemList[refId] = selItemNum
            self._selectItemList[id].sel = true
            self._selectHeroNum = self._selectHeroNum + 1
        end
    end
    local autoList = self._autoHeroList
    for i, v in ipairs(autoList) do
        if self._selectHeroNum >= self._num then
            break
        end
        local id = v.id
        if not self._selectHeroList[id] and v.status == 0 then
            if not isSel then
                isSel = true
            end
            self._selectHeroList[id] = id
            self._selectHeroNum = self._selectHeroNum + 1
        end
    end
    if isSel then
        local uiList = self._uiList
        if uiList then
            uiList:RefreshList()
            self:ShowNumTxt()
        end
    end
end

function UISagaSelect:SetData(refId, num, star, race, selHeorId, selHeroList)
    printInfoN(refId, num, star, race)
    self._refId = refId
    self._num = num
    self._star = star
    self._race = race
    self._selHeorId = selHeorId
    self._selHeroList = selHeroList
end

function UISagaSelect:OnClickRaceType(raceType)
    self._raceType = raceType
    self:InitScrollView()
end

function UISagaSelect:ShowNumTxt()
    local maxNum = self._num or 0
    local color = "0fb93fff"
    if maxNum > self._selectHeroNum then
        color = "844141ff"
    end
    local str
    if self._selectSameRefId then
        str = ccClientText(10030)
        str = string.replace(str, color, self._selectHeroNum, maxNum)
    else
        str = ccClientText(10073)
        local nameStr = self:GetName()
        str = string.replace(str, color, self._selectHeroNum, maxNum, nameStr)
    end
    self:SetWndText(self.mSelectTxt, str)
end

function UISagaSelect:CheckIsFullSel(opt)
    local num = self._selectHeroNum + opt
    if num > self._num then
        GF.ShowMessage(ccClientText(10031))
        return false
    end
    return true
end

function UISagaSelect:GetName()
    local refId = self._refId
    local race = self._race
    local star = self._star
    local nameStr
    if race == -1 then
        -- 指定英雄
        local name = gModelHero:GetHeroNameByRefId(refId, star)
        --[[		local nameColor = "#" .. gModelHero:GetHeroNameColorByRefId(refId,star)
                nameStr = LUtil.FormatColorStr(name,nameColor)]]
        nameStr = string.replace(ccClientText(10050), star) .. name
    else
        -- 范围英雄
        local ref = gModelHero:GetHeroRaceRefByRefId(race)
        local raceName = ""
        if ref then
            raceName = ccLngText(ref.name)
        end
        nameStr = string.replace(ccClientText(10050), star) .. raceName .. ccClientText(13412)
        --[[		local nameColor = "#" .. gModelItem:GetHeroColorByQuality(star)
                nameStr = LUtil.FormatColorStr(nameStr,nameColor)]]
    end
    return nameStr
end

function UISagaSelect:OnDisposeHero(itemdata,baseClass)
    local id = itemdata.id
    local lock, isCombat = itemdata.lock, itemdata.isCombat
    if isCombat == 1 then
        local noOpenSelWndList = {}
        local wndInst = GF.FindFirstWndByName("UISagaSpirit")
        if wndInst then
            noOpenSelWndList["UISagaSelect"] = "UISagaSelect"
        end
        gModelFormation:OnHeroRemoveFormationReq(id, 2, LGameUI.UI_SORTLAYER_UIBOTTOM, true, noOpenSelWndList)
    elseif lock == 1 then
        gModelHeroSpirit:HeroUnLockOpt({ heroId = id })
    else
        if (not self._selectRefId) and self._selectSameRefId then
            self._selectRefId = gModelHero:GetRefIdById(id)
        end
        local num = 1
        if self._selectHeroList[id] then
            num = -1
            if self._selectSameRefId and self._selectHeroNum - num <= 0 then
                self._selectHeroNum = 0
                self._selectRefId = nil
            end
        end
        if num == 1 then
            if not self:CheckIsFullSel(num) then
                return
            end
            if isAct then
                self._selectHerofunc(id, num, baseClass)
            else
                self._selectHerofunc(id, num, baseClass)
            end
        else
            self._selectHerofunc(id, num, baseClass)
        end
    end
end

function UISagaSelect:CommonDisposeClickIcon(type,itemdata,baseClass)
    if self._isLimitClick then return end

    if type == 2 then
        local treeInfo = itemdata.treeInfo
        local points = treeInfo.points
        if table.isempty(points) then
            self:OnDisposeHero(itemdata,baseClass)
        else
            local dataList = {}
            table.insert(dataList,itemdata)
            local race = gModelHero:GetHeroRace(itemdata.refId)
            local career = gModelHero:GetHeroCareerType(itemdata.refId)
            gModelGeneral:OpenUIOrdinTips({refId = 10048,itemList = dataList,func = function()
                local para = {
                    heroId = itemdata.id,
                    career = career,
                    race = race,
                }
                GF.OpenWnd("UISagaTree", para)
            end})
        end
    else
        self:OnDisposeItem(itemdata,baseClass)
    end
end

function UISagaSelect:OnDrawSelectHeroCell(list, item, itemdata, itempos, fromHeadTail)
    if not self:IsWndValid() then
        return
    end
    local CommonUITrans = CS.FindTrans(item, "CommonUI")

    local itype = itemdata.itype
    local refId = itemdata.refId
    local id = itemdata.id
    local lock, isCombat = itemdata.lock, itemdata.isCombat
    local sel
    local isAct = false

    local iconTrans = CS.FindTrans(CommonUITrans, "Icon")
    local longTrans = iconTrans

    local instanceId = item:GetInstanceID()
    local baseClass = self._commonIconClsTbl[instanceId]
    if not baseClass then
        baseClass = CommonIcon:New()
        self._commonIconClsTbl[instanceId] = baseClass
        baseClass:Create(iconTrans)
    end

    self:SetIconClickScale(iconTrans, true)

    if itype == 2 then
        baseClass:SetHeroPlayer(id)
        if isAct then
            baseClass:SetShowMaskOnly(isAct)
        else
            baseClass:ShowStatusImg(true, UISagaSelect.IGNORE_RESONANCE == 1)
        end
        sel = self._selectHeroList[id] ~= nil
        self:SetWndClick(iconTrans, function()
            self:CommonDisposeClickIcon(itype,itemdata,baseClass)
        end)
    else
        baseClass:SetCommonReward(itype, refId, 1)
        if not self._selectItemList[id] then
            printInfoN2("--------", "-----------")
        else
            sel = self._selectItemList[id].sel
        end

        self:SetWndClick(iconTrans, function()
            self:CommonDisposeClickIcon(itype,itemdata,baseClass)
        end)
    end
    self:SetWndLongClick(longTrans, function()
        if itype == 1 then
            gModelGeneral:OpenItemInfoTip(refId, 1)
        else
            local data = {
                id = id,
                refId = refId,
                level = itemdata.lv,
                star = itemdata.star,
                grade = itemdata.grade,
                fightPower = itemdata.fightPower,
                isResonance = itemdata.isResonance,
                skin = itemdata.skin,
                treeInfo = itemdata.treeInfo,
            }
            gModelHero:ReqShowHeroTip("", data)
        end
    end, 0.8, false)

    baseClass:EnableShowNum(false)
    baseClass:SetShowGouImg(sel)
    baseClass:DoApply()

    local uiNameTrans = CS.FindTrans(CommonUITrans, "UIName")
    local uiNameText = uiNameTrans and self:FindWndText(uiNameTrans) or nil
    if uiNameText then
        local itemname, itemcolor = baseClass:GetName()
        self:SetXUITextText(uiNameText, itemname or "")
    end
end

function UISagaSelect:GetTypeSortNum(data)
    local itype = data.itype
    local sortNum = 1
    if itype == LItemTypeConst.TYPE_ITEM then
        local itemRace = data.itemRace
        if itemRace == 0 then
            sortNum = 5
        elseif itemRace == 4 or itemRace == 5 then
            sortNum = 4
        elseif itemRace > 5 then
            sortNum = 3
        end
    elseif itype == LItemTypeConst.TYPE_HERO then
        local refId = data.refId
        local quality = gModelHero:GetHeroInitQualityByRefId(refId) or 1
        if quality >= 7 then
            sortNum = 7                         -- 神话
        elseif quality == 6 then
            sortNum = 6                         -- 传说
        else
            sortNum = 2
        end
    end
    return sortNum
end

function UISagaSelect:AutoBtnFunc()
    local sortAllData = self._sortAllData or {}
    local isSel = false
    for i, v in ipairs(sortAllData) do
        if self._selectHeroNum >= self._num then
            break
        end
        local itype = v.itype
        if itype == LItemTypeConst.TYPE_ITEM then
            local id = v.id
            local refId = v.refId
            if not self._selectItemList[id].sel then
                if not isSel then
                    isSel = true
                end
                local selItemNum = self._selItemList[refId]
                if not selItemNum then
                    selItemNum = 0
                end
                selItemNum = selItemNum + 1
                self._selItemList[refId] = selItemNum
                self._selectItemList[id].sel = true
                self._selectHeroNum = self._selectHeroNum + 1
            end
        else
            local id = v.id
            if not self._selectHeroList[id] and v.status == 0 then
                if not isSel then
                    isSel = true
                end
                self._selectHeroList[id] = id
                self._selectHeroNum = self._selectHeroNum + 1
            end
        end
    end
    if isSel then
        local uiList = self._uiList
        if uiList then
            uiList:RefreshList()
            self:ShowNumTxt()
        end
    end
end

function UISagaSelect:OnDisposeItem(itemdata,baseClass)
    local id = itemdata.id
    local num = 1
    if self._selectItemList[id] and self._selectItemList[id].sel then
        num = -1
    end
    self._selectItemfunc(id, itemdata.refId, num, baseClass)
end

function UISagaSelect:GetBtnFunc()
    local refId, star, race, selHeroId = self._refId, self._star, self._race, self._selHeorId
    local isSelRace
    if race == -1 then
        isSelRace = nil
    else
        isSelRace = race
    end
    if isSelRace then
        if race == 0 then
            -- 非指定的同系伙伴
            local jumpId = gModelHero:GeConfigByKey("heroGainJump1")
            gModelFunctionOpen:Jump(jumpId, self:GetWndName(), function()
                GF.CloseWndByName("UISagaSelect")
            end)
        else
            -- 星级伙伴
            local heroGainJump2 = gModelHero:GeConfigByKey("heroGainJump2")
            heroGainJump2 = string.split(heroGainJump2, "|")
            for i, v in ipairs(heroGainJump2) do
                v = string.split(v, "=")
                local configRace = tonumber(v[1])
                if configRace == race then
                    gModelGeneral:OpenGetWayWnd({
                        itemId = tonumber(v[2]),
                        srcWnd = self:GetWndName(),
                        jumpCallBackFunc = function()
                            GF.CloseWndByName("UISagaSelect")
                        end
                    })
                    break
                end
            end
        end
    else
        -- 根据英雄refId选择
        gModelGeneral:OpenGetWayWnd({
            itemId = refId,
            refIdType = LItemTypeConst.TYPE_HERO,
            srcWnd = self:GetWndName(),
            heroStar = star,
            jumpCallBackFunc = function()
                GF.CloseWndByName("UISagaSelect")
            end
        })
    end
end

function UISagaSelect:RefreshHeroList()
    local uiList = self._uiList
    if uiList then
        uiList:DrawAllItems()
    end
end

function UISagaSelect:InitEmptyList()
    local emptyId = 2001
    local nameStr
    if not self._selectSameRefId then
        emptyId = 10001
        nameStr = self:GetName()
    end
    local data = {
        refId = emptyId,
        IntroTran = self.mEmptyText,
        IconTran = self.mEmptyIcon,
        TextBgTran = self.mEmptyTextBg,
        GetBtn = self.mGetBtn,
        GetBtnText = self.mGetBtnTxt,
        ButtonRoot = self.mGetBtn,
        para = { nameStr },
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)

    CS.ShowObject(self.mGetBtn, true)
end

function UISagaSelect:ShowGetBtn()
    local activeSelf = self.mGetBtn.gameObject.activeSelf
    if not activeSelf then
        return
    end
    local refId = self._refId
    local ref = godelHero:GetHeroRef(refId)
    if ref then
        local jump = ref.jump
        local isEmpty = string.isempty(jump)
        CS.ShowObject(self.mGetBtn, not isEmpty)
    end
end

function UISagaSelect:OnCancelHeroSel(heroId)
    if not self:IsWndValid() then
        return
    end
    local isRefresh = false
    if self._selectHeroList[heroId] then
        isRefresh = true
        self._selectHeroList[heroId] = nil
        if self._selectHeroNum > 0 then
            self._selectHeroNum = self._selectHeroNum - 1
        end
    end
    self:ShowNumTxt()
    if not isRefresh then
        return
    end
    self:RefreshHeroList()
    --self:InitScrollView()
end

function UISagaSelect:InitMsg()
    self:WndNetMsgRecv(LProtoIds.HeroLockResp, function()
        self:InitScrollView()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroRemoveFormationResp, function()
        self:InitScrollView()
    end)
    self:WndNetMsgRecv(LProtoIds.ResonanceHeroResp, function()
        self:InitScrollView()
    end)
end

function UISagaSelect:EnterAwakenFunc()
    -- 确定按钮事件
    if self._func then
        local selectHeroList = self._selectHeroList        -- 界面选择的英雄
        local enterFunc = function()
            local selHeroList = self._selHeroList or {}                -- 列表传进来已选择的英雄
            for k, v in pairs(selHeroList) do
                local b = gModelHero:IsHeroIdUpLvTreeSel(v)
                if b then
                    gModelHero:SetUpLvTreeSelHeroId(k)
                end
            end
            for k, v in pairs(selectHeroList) do
                local b = gModelHero:IsHeroIdUpLvTreeSel(v)
                if not b then
                    gModelHero:SetUpLvTreeSelHeroId(k)
                end
            end
            if self._func then
                self._func(selectHeroList, self._selItemList)
            end
            self:WndClose()
        end
        local isHave5JH = false
        local have5JHList = {}
        for k, v in pairs(self._selItemList) do
            if v > 0 then
                local itemRefData = gModelItem:GetYingHunRefByRefId(k)
                if itemRefData then
                    local race = itemRefData.race
                    if race == 0 then
                        for i = 1, v do
                            table.insert(have5JHList, { itype = LItemTypeConst.TYPE_ITEM, refId = k, count = 1 })
                        end
                        isHave5JH = true
                    end
                end
            end
        end
        local isHaveHeightQualityHero = false
        for k, v in pairs(selectHeroList) do
            local refId = gModelHero:GetRefIdById(k)
            if refId then
                local quality = gModelHero:GetHeroInitQualityByRefId(refId) or 1
                if quality >= 6 then
                    local heroServerData = gModelHero:GetHeroServerDataById(k)
                    table.insert(have5JHList, { itype = LItemTypeConst.TYPE_HERO, heroData = heroServerData })
                    isHaveHeightQualityHero = true
                    isHave5JH = true
                end
            end
        end
        local tipsId
        if isHave5JH and not isHaveHeightQualityHero then
            tipsId = self._noHeightQualityTipRefId or 10018
        elseif isHave5JH and isHaveHeightQualityHero then
            tipsId = self._heightQualityTipRefId or 10008
        end
        if tipsId then
            local data = { refId = tipsId, func = enterFunc, itemList = have5JHList }
            gModelGeneral:OpenUIOrdinTips(data)
        else
            enterFunc()
        end
    else
        self:WndClose()
    end
end

function UISagaSelect:EnterBtnFunc()
    local selectType = self._selectType
    if selectType == UISagaSelect.TYPE_STAR_UP then
        self:EnterStarUpFunc()
    elseif selectType == UISagaSelect.TYPE_AWAKEN then
        self:EnterAwakenFunc()
    end
end

function UISagaSelect:OnEnterHeroSel(heroId)
    if not self:IsWndValid() then
        return
    end
    local isRefresh = false
    if not self._selectHeroList[heroId] then
        if not self:CheckIsFullSel(1) then
            return
        end
        isRefresh = true
        self._selectHeroList[heroId] = heroId
        self._selectHeroNum = self._selectHeroNum + 1
    end
    if not isRefresh then
        return
    end
    self:ShowNumTxt()
    self:RefreshHeroList()
    --self:InitScrollView()
end

function UISagaSelect:InitScrollView1()
    local uiList = self._uiList
    if not uiList then
        uiList = UIListWrap:New()
        uiList:Create(self, self.mSelectHeroList)
        uiList:SetFuncOnItemDraw(function(...)
            self:OnDrawSelectHeroCell(...)
        end)
        self._uiList = uiList
    end
    uiList:RemoveAll()

    local itemData = {}
    local itemIdx = 1
    local itemList = self._itemList
    for k, v in pairs(itemList) do
        local tempItem = v:GetServerData()
        local key = string.split(k, "_")
        local itemRace, itemIndex = tonumber(key[2]), tonumber(key[3])
        tempItem.id = k
        tempItem.itemRace = itemRace
        tempItem.itemIndex = itemIndex
        tempItem.index = itemIdx
        table.insert(itemData, tempItem)
        itemIdx = itemIdx + 1
    end
    local oldSortItemFunc = function(item1, item2)
        local itemRace1, itemRace2 = item1.itemRace, item2.itemRace
        if itemRace1 ~= itemRace2 then
            return itemRace1 < itemRace2
        else
            local itemIndex1, itemIndex2 = item1.itemIndex, item2.itemIndex
            return itemIndex1 < itemIndex2
        end
    end
    table.sort(itemData, oldSortItemFunc)
    self._autoItemList = {}
    local itemIndex = 0
    for k, v in ipairs(itemData) do
        local id = v.id
        local sel = false
        local refId = v.refId
        local selItemNum = self._selItemList[refId]
        if selItemNum then
            if v.itemIndex <= selItemNum then
                sel = true
                itemIndex = itemIndex + 1
            end
        end
        v.sel = sel
        self._selectItemList[id] = { sel = sel, itemRace = v.itemRace, itemIndex = v.itemIndex }
        table.insert(self._autoItemList, v)
        uiList:AddData(id, v)
    end

    local selectHeroList = self._selectHeroList
    local data = {}
    local _data = self._dataList
    for k, v in pairs(_data) do
        table.insert(data, v)
    end
    -- 通用排序
    local commonSortFunc = function(hero1, hero2)
        local status1, status2 = hero1:GetStatus(), hero2:GetStatus()
        if status1 ~= status2 then
            return status1 < status2
        else
            local star1, star2 = hero1:GetStar(), hero2:GetStar()
            if star1 ~= star2 then
                return star1 < star2
            else
                local lv1, lv2 = hero1:GetLv(), hero2:GetLv()
                if lv1 ~= lv2 then
                    return lv1 < lv2
                else
                    local power1, power2 = hero1:GetPower(), hero2:GetPower()
                    if power1 ~= power2 then
                        return power1 < power2
                    else
                        local refId1, refId2 = hero1:GetRefId(), hero2:GetRefId()
                        if refId1 ~= refId2 then
                            return refId1 < refId2
                        else
                            local id1, id2 = hero1:GetId(), hero2:GetId()
                            return id1 > id2
                        end
                    end
                end
            end
        end
    end

    local cailiaoSortFunc = function(hero1, hero2)
        local status1, status2 = hero1:GetStatus(), hero2:GetStatus()
        if status1 ~= status2 then
            return status1 < status2
        else
            local refId1, refId2 = hero1:GetRefId(), hero2:GetRefId()
            if not self._race then
                -- 本体
                local isSameNum1, isSameNum2 = 0, 0
                if self._refId == refId1 then
                    isSameNum1 = 1
                end
                if self._refId == refId2 then
                    isSameNum2 = 1
                end
                if isSameNum1 ~= isSameNum2 then
                    return isSameNum1 < isSameNum2
                end
            end
            local star1, star2 = hero1:GetStar(), hero2:GetStar()
            if star1 ~= star2 then
                return star1 < star2
            else
                local power1, power2 = hero1:GetPower(), hero2:GetPower()
                if power1 ~= power2 then
                    return power1 < power2
                else
                    if refId1 ~= refId2 then
                        return refId1 > refId2
                    else
                        local id1, id2 = hero1:GetId(), hero2:GetId()
                        return id1 > id2
                    end
                end
            end
        end
    end

    local newSortFunc = function(hero1, hero2)
        local refId1, refId2 = hero1:GetRefId(), hero2:GetRefId()
        local ref1 = gModelHero:GetHeroRef(refId1)
        local ref2 = gModelHero:GetHeroRef(refId2)
        local quality1, quality2 = ref1.quality, ref2.quality
        if quality1 ~= quality2 then
            return quality1 < quality2
        else
            local lv1, lv2 = hero1:GetLv(), hero2:GetLv()
            if lv1 ~= lv2 then
                return lv1 < lv2
            else
                --[[				local power1,power2 = hero1:GetPower(),hero2:GetPower()
                                if power1 ~= power2 then
                                    return power1 < power2
                                else
                                end]]
                if refId1 ~= refId2 then
                    return refId1 > refId2
                else
                    local id1, id2 = hero1:GetId(), hero2:GetId()
                    return id1 < id2
                end
            end
        end
    end

    local func
    if self._selectSameRefId then
        func = commonSortFunc
    else
        --func = cailiaoSortFunc
        func = newSortFunc

    end
    table.sort(data, func)

    self._autoHeroList = {}
    local index = 0
    for k, v in ipairs(data) do
        local hero = v:GetServerData()
        local id = hero.id
        hero.sel = false
        if UISagaSelect.IGNORE_RESONANCE == 1 and hero.isCombat ~= 1 and hero.lock ~= 1 and hero.isResonance == 1 then
            hero.status = 0
        end
        table.insert(self._autoHeroList, hero)
        if selectHeroList[id] then
            if (not self._selectRefId) and self._selectSameRefId then
                self._selectRefId = gModelHero:GetRefIdById(id)
            end
            hero.sel = true
            index = index + 1
        end
        if self._replaceRefId then
            if self._selHeroRefId ~= hero.refId then
                uiList:AddData(id, hero)
            end
        else
            uiList:AddData(id, hero)
        end
    end
    self._selectHeroNum = index + itemIndex
    uiList:RefreshList()
end

function UISagaSelect:SetCallBack(func)
    self._func = func
end

function UISagaSelect:EnterStarUpFunc()
    -- 确定按钮事件
    if self._func then
        local selectHeroList = self._selectHeroList        -- 界面选择的英雄
        local enterFunc = function()
            local selHeroList = self._selHeroList or {}                -- 列表传进来已选择的英雄
            for k, v in pairs(selHeroList) do
                local b = gModelHero:IsHeroIdSel(v)
                if b then
                    gModelHero:SetSelHeroId(k)
                end
            end
            for k, v in pairs(selectHeroList) do
                local b = gModelHero:IsHeroIdSel(v)
                if not b then
                    gModelHero:SetSelHeroId(k)
                end
            end
            if self._func then
                self._func(selectHeroList, self._selItemList)
            end
            self:WndClose()
        end
        local isHave5JH = false
        local have5JHList = {}
        for k, v in pairs(self._selItemList) do
            if v > 0 then
                local itemRefData = gModelItem:GetYingHunRefByRefId(k)
                if itemRefData then
                    local race = itemRefData.race
                    if race == 0 then
                        for i = 1, v do
                            table.insert(have5JHList, { itype = LItemTypeConst.TYPE_ITEM, refId = k, count = 1 })
                        end
                        isHave5JH = true
                    end
                end
            end
        end
        local isHaveHeightQualityHero = false
        for k, v in pairs(selectHeroList) do
            local refId = gModelHero:GetRefIdById(k)
            if refId then
                local quality = gModelHero:GetHeroInitQualityByRefId(refId) or 1
                if quality >= 6 then
                    local heroServerData = gModelHero:GetHeroServerDataById(k)
                    table.insert(have5JHList, { itype = LItemTypeConst.TYPE_HERO, heroData = heroServerData })
                    isHaveHeightQualityHero = true
                    isHave5JH = true
                end
            end
        end
        local tipsId
        if isHave5JH and not isHaveHeightQualityHero then
            tipsId = 10018
        elseif isHave5JH and isHaveHeightQualityHero then
            tipsId = 10008
        end
        if tipsId then
            local data = { refId = tipsId, func = enterFunc, itemList = have5JHList }
            gModelGeneral:OpenUIOrdinTips(data)
        else
            enterFunc()
        end
    else
        self:WndClose()
    end
end

function UISagaSelect:GetData()
    local refId, star, race, selHeroId = self._refId, self._star, self._race, self._selHeorId
    local isSelRace
    if race == -1 then
        isSelRace = nil
    else
        isSelRace = race
    end

    local dataList, itemList
    local selectType = self._selectType
    if selectType == UISagaSelect.TYPE_STAR_UP then
        dataList, itemList = gModelHero:FilterHero(refId, star, isSelRace, selHeroId, self._selHeroList, nil, true, self._selfItemOtherList)
    elseif selectType == UISagaSelect.TYPE_AWAKEN then
        dataList, itemList = gModelHero:AwakenFilterHero(refId, star, isSelRace, selHeroId, self._selHeroList, nil, true)
    end

    self._dataList = dataList
    if self._replaceRefId then
        itemList = {}
    end
    self._itemList = itemList


end

function UISagaSelect:InitData()
    self._isLimitClick = self:GetWndArg("isLimitClick")
    self._refId = self:GetWndArg("refId")
    self._num = self:GetWndArg("num")
    self._star = self:GetWndArg("star")
    self._race = self:GetWndArg("race")
    self._selHeorId = self:GetWndArg("selHeorId")
    self._selHeroList = self:GetWndArg("selHeroList")            -- 已选择的列表
    self._func = self:GetWndArg("func")
    self._selectSameRefId = self:GetWndArg("sameRefId")
    self._replaceRefId = self:GetWndArg("replaceRefId")
    self._selItemList = self:GetWndArg("selItemList") or {}        -- refId:num，道具选择列表

    self._selfItemOtherList = self:GetWndArg("selfItemOtherList") or {}        -- refId:num，道具选择列表

    self._noHeightQualityTipRefId = self:GetWndArg("noHeightQualityTipRefId")
    self._heightQualityTipRefId = self:GetWndArg("heightQualityTipRefId")
    self._selectType = self:GetWndArg("selectType") or UISagaSelect.TYPE_STAR_UP
    self._selHeroRefId = gModelHero:GetRefIdById(self._selHeorId)
    self._showRaceDiv = self:GetWndArg("showRaceDiv") or false -- 是否开启英雄属性素筛选栏
    self._selectRefId = nil
    self._selectHeroList = {}                                            -- 重新选择的列表(英雄)
    self._selectItemList = {}                                            -- 重新选择的列表(道具)
    self._selectHeroNum = 0
    self._autoHeroList = {}
    local selHeroList = self._selHeroList
    if not table.isempty(selHeroList) then
        for k, v in pairs(selHeroList) do
            self._selectHeroList[k] = v
        end
    end

    self._selectHerofunc = function(id, optNum, baseClass)
        local tempRefId = gModelHero:GetRefIdById(id)
        if self._selectSameRefId and self._selectRefId then
            if self._replaceRefId and tempRefId == self._selHeroRefId then
                if self._selectHeroNum == 0 then
                    self._selectRefId = nil
                end
                GF.ShowMessage(ccClientText(14432))            -- 不能置换同名英雄
                return -1
            end
            if tempRefId ~= self._selectRefId then
                GF.ShowMessage(ccClientText(14424))            -- 选择相同名字的英雄
                return -1
            end
        end
        local num = self._selectHeroNum
        local tempNum = num + optNum
        if tempNum > self._num or tempNum < 0 then
            GF.ShowMessage(ccClientText(10031))
            return -2
        end
        local selectHeroList = self._selectHeroList
        local data = selectHeroList[id]
        local status = 0
        local isAdd
        if not data then
            status = 1
            printInfoN("------- 添加了id = ", id)
            self._selectHeroNum = self._selectHeroNum + 1
            data = id
            selectHeroList[id] = data
            isAdd = true
            baseClass:ShowGouImg(true)
        else
            status = 2
            printInfoN("------- 删除了id = ", id)
            self._selectHeroNum = self._selectHeroNum - 1
            data = nil
            selectHeroList[id] = data
            isAdd = false
            baseClass:ShowGouImg(false)
        end
        if self._selectSameRefId and self._selectRefId and self._selectHeroNum == 0 then
            self._selectRefId = nil
        end
        self:ShowNumTxt()
        return status
    end

    self._selectItemfunc = function(id, itemRefId, optNum, baseClass)
        local num = self._selectHeroNum
        local tempNum = num + optNum
        if tempNum > self._num or tempNum < 0 then
            GF.ShowMessage(ccClientText(10031))
            return
        end
        local selectItemList = self._selectItemList
        local data = selectItemList[id]
        local isAdd
        if not data.sel then
            isAdd = true
        else
            isAdd = false
        end
        self._selectItemList[id].sel = isAdd

        baseClass:ShowGouImg(isAdd)

        local selItemNum = self._selItemList[itemRefId]
        if not selItemNum then
            selItemNum = 0
        end
        selItemNum = selItemNum + optNum
        self._selItemList[itemRefId] = selItemNum
        self._selectHeroNum = self._selectHeroNum + optNum
        self:ShowNumTxt()
    end

    self._raceBtnList = {
        self.mRaceBtn1,
        self.mRaceBtn2,
        self.mRaceBtn3,
        self.mRaceBtn4,
        self.mRaceBtn5,
        self.mRaceBtn6,
    }

    self._raceType = 0
end

function UISagaSelect:InitScrollView()
    local uiList = self._uiList
    if not uiList then
        uiList = UIListWrap:New()
        uiList:Create(self, self.mSelectHeroList)
        uiList:SetFuncOnItemDraw(function(...)
            self:OnDrawSelectHeroCell(...)
        end)
        self._uiList = uiList
    end
    uiList:RemoveAll()

    local raceType = self._raceType
    if not raceType then
        return
    end
    local btnTrans
    if raceType == 0 then
        btnTrans = self.mAllRaceBtn
    else
        btnTrans = self._raceBtnList and self._raceBtnList[raceType]
    end
    CS.SetParentTrans(self.mRaceSelImg, btnTrans)

    --------------------- 道具 ---------------------
    local itemData = {}
    local allItemData = {}
    local itemIdx = 1
    local itemList = self._itemList
    for k, v in pairs(itemList) do
        local tempItem = v:GetServerData()
        local key = string.split(k, "_")
        local itemRace, itemIndex = tonumber(key[2]), tonumber(key[3])
        tempItem.id = k
        tempItem.itemRace = itemRace
        tempItem.itemIndex = itemIndex
        tempItem.index = itemIdx
        tempItem.order = gModelItem:GetItemOrderByRefId(tempItem.refId)

        if raceType == 0 or itemRace == raceType then
            table.insert(itemData, tempItem)
        end
        itemIdx = itemIdx + 1
        table.insert(allItemData, tempItem)
    end
    table.sort(itemData, function(a, b)
        return a.order < b.order
    end)
    self._autoItemList = {}
    local itemIndex = 0
    for k, v in ipairs(itemData) do
        table.insert(self._autoItemList, v)
    end
    --------------------- 道具 ---------------------

    --------------------- 英雄 ---------------------
    local heroData = {}
    local selectHeroList = self._selectHeroList
    local data = self._dataList
    self._autoHeroList = {}
    local index = 0
    for k, v in pairs(data) do
        local hero = v:GetServerData()
        local id = hero.id
        hero.sel = false
        if UISagaSelect.IGNORE_RESONANCE == 1 and hero.isCombat ~= 1 and hero.lock ~= 1 and hero.isResonance == 1 then
            hero.status = 0
        end
        if selectHeroList[id] then
            if (not self._selectRefId) and self._selectSameRefId then
                self._selectRefId = gModelHero:GetRefIdById(id)
            end
            hero.sel = true
            index = index + 1
        end
        local heroRefId = hero.refId
        local race = gModelHero:GetHeroRace(heroRefId)
        if raceType == 0 or race == raceType then
            if self._replaceRefId then
                if self._selHeroRefId ~= heroRefId then
                    table.insert(heroData, hero)
                end
            else
                table.insert(heroData, hero)
            end
        end
    end
    --------------------- 英雄 ---------------------

    local allData = {}
    for i, v in ipairs(itemData) do
        table.insert(allData, v)
    end

    table.sort(heroData, function(a, b)
        local refId1, refId2 = a.refId, b.refId
        local ref1 = gModelHero:GetHeroRef(refId1)
        local ref2 = gModelHero:GetHeroRef(refId2)
        local quality1, quality2 = ref1.quality, ref2.quality
        if quality1 ~= quality2 then
            return quality1 < quality2
        else
            local lv1, lv2 = a.lv, b.lv
            if lv1 ~= lv2 then
                return lv1 < lv2
            else
                if refId1 ~= refId2 then
                    return refId1 > refId2
                else
                    local id1, id2 = a.id, b.id
                    return id1 < id2
                end
            end
        end
    end)

    for i, v in ipairs(heroData) do
        table.insert(self._autoHeroList, v)
        table.insert(allData, v)
    end

    local allDataSortFunc = function(a, b)
        local sortNumA = self:GetTypeSortNum(a)
        local sortNumB = self:GetTypeSortNum(b)
        local itypeA, itypeB = a.itype, b.itype
        if sortNumA == sortNumB and itypeA == itypeB and itypeA == LItemTypeConst.TYPE_HERO then
            local refId1, refId2 = a.refId, b.refId
            local ref1 = gModelHero:GetHeroRef(refId1)
            local ref2 = gModelHero:GetHeroRef(refId2)
            local quality1, quality2 = ref1.quality, ref2.quality
            if quality1 ~= quality2 then
                return quality1 < quality2
            else
                local lv1, lv2 = a.lv, b.lv
                if lv1 ~= lv2 then
                    return lv1 < lv2
                else
                    if refId1 ~= refId2 then
                        return refId1 > refId2
                    else
                        local id1, id2 = a.id, b.id
                        return id1 < id2
                    end
                end
            end
        elseif sortNumA == sortNumB and itypeA == itypeB and itypeA == LItemTypeConst.TYPE_ITEM then
            --return a.index < b.index
            return a.order < b.order
        end
        return sortNumA < sortNumB
    end
    table.sort(allData, allDataSortFunc)

    local tTab = {}
    local tItemIndex = 1
    for i, v in ipairs(allItemData) do
        if v.itype == LItemTypeConst.TYPE_ITEM then
            local refId = v.refId
            local newIndex = tTab[refId]
            if not newIndex then
                newIndex = 0
            end
            newIndex = newIndex + 1
            tTab[refId] = newIndex
            v.index = newIndex
            tItemIndex = tItemIndex + 1
        end
    end

    for i, v in ipairs(allItemData) do
        if v.itype == LItemTypeConst.TYPE_ITEM then
            v.id = "itemRace_" .. v.itemRace .. "_" .. v.index
            local sel = false
            local refId = v.refId
            local selItemNum = self._selItemList[refId]

            if selItemNum then
                if v.index <= selItemNum then
                    sel = true
                    itemIndex = itemIndex + 1
                end
            end
            v.sel = sel
            self._selectItemList[v.id] = { sel = v.sel, itemRace = v.itemRace, itemIndex = v.itemIndex }
        end
    end

    self._selectHeroNum = index + itemIndex

    self._sortAllData = allData
    for i, v in ipairs(allData) do
        local id = v.id
        uiList:AddData(id, v)
    end

    uiList:RefreshList()
end

------------------------------------------------------------------
return UISagaSelect


