---
--- Created by LCM.
--- DateTime: 2024/3/17 20:03:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITmHourGlass:LWnd
local UITmHourGlass = LxWndClass("UITmHourGlass", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITmHourGlass:UITmHourGlass()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITmHourGlass:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITmHourGlass:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITmHourGlass:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEmptyList()
	self:InitText()
	self:InitRaceDataList()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshItemFunc()
    self:RefreshRaceSel()
	self:RefreshSelHeroId()
end
------------------------- CommonFunc -------------------------

------------------------- List -------------------------
function UITmHourGlass:GetNeedItemList()
    local list = {}
    local itemId = self._itemId
    if itemId then
        table.insert(list,{
            itemType = LItemTypeConst.TYPE_ITEM,
            itemId = itemId,
            itemNum = gModelItem:GetNumByRefId(itemId),
        })
    end
    return list
end

function UITmHourGlass:OnClickRaceBtnFunc(race)
    if self._selRace == race then return end
    self._selRace = race
    self:RefreshRaceSel()
    self:InitHeroList()
end

function UITmHourGlass:RefreshRaceSel()
    local btnTrans
    local selRace = self._selRace
    if selRace == 0 then
        btnTrans = self.mAllRaceBtn
    else
        local raceBtnTransList = self._raceBtnTransList or {}
        local btnInfo = raceBtnTransList and raceBtnTransList[selRace]
        btnTrans = btnInfo and btnInfo.btnTrans
    end
    if not btnTrans then return end
    CS.SetParentTrans(self.mRaceSelImg,btnTrans)
end

function UITmHourGlass:GetHeroRewardItemList()
    local list = {}
    local selHeroId = self._selHeroId
    if selHeroId then
        local serverData = gModelHero:GetHeroServerDataById(selHeroId)
        if serverData then
            --local refId = serverData.refId
            local star = serverData.star
            local returnStar = self._returnToStar or star
            local returnStarRef = gModelHero:GetStarRefById(selHeroId,returnStar)
            local returnLevel = returnStarRef and returnStarRef.maxLevel or 1
            if returnLevel > serverData.lv then
                returnLevel = serverData.lv
            end
            local returnHeroData = {
                id = selHeroId,
                refId = serverData.refId,
                star = returnStar,
                level = returnLevel,
                skin = serverData.skin,
                isResonance = serverData.isResonance,
                itemType = serverData.itype
            }
            table.insert(list,returnHeroData)
            local returnItemList = gModelHeroSpirit:UseItemReturnHeroRewardList(self._itemId,serverData)
            for i,v in ipairs(returnItemList) do
                table.insert(list,v)
            end
        end
    end
    return list
end

function UITmHourGlass:InitNeedItemList()
    local list = self:GetNeedItemList()
    local uiNeedItemList = self._uiNeedItemList
    if uiNeedItemList then
        uiNeedItemList:RefreshList(list)
    else
        uiNeedItemList = self:GetUIScroll("uiNeedItemList")
        self._uiNeedItemList = uiNeedItemList
        uiNeedItemList:Create(self.mNeedItemList,list,function(...) self:OnDrawNeedItemCell(...) end)
    end
end

function UITmHourGlass:InitRaceDataList()
    self._raceBtnTransList = {
        {
            btnTrans = self.mRace1Btn,
            race = 1,
        },
        {
            btnTrans = self.mRace2Btn,
            race = 2,
        },
        {
            btnTrans = self.mRace3Btn,
            race = 3,
        },
        {
            btnTrans = self.mRace4Btn,
            race = 4,
        },
        {
            btnTrans = self.mRace5Btn,
            race = 5,
        },
    }
end


function UITmHourGlass:GetHeroList()
    local list = {}
    if self._heroStar then
        list = gModelHero:GetStarHeroList(self._heroStar,self._selRace)
        table.sort(list,function(a,b)
            local statusA,statusB = a.status,b.status
            if statusA ~= statusB then
                return statusA < statusB
            end
            if statusA == statusB and statusA == 0 then
                local isCombatA,isCombatB = a.isCombat,b.isCombat
                if isCombatA ~= isCombatB then
                    return isCombatA > isCombatB
                end
                local lockA,lockB = a.lock,b.lock
                if lockA ~= lockB then
                    return lockA > lockB
                end
                local isResonanceA,isResonanceB = a.isResonance,b.isResonance
                if isResonanceA ~= isResonanceB then
                    return isResonanceA > isResonanceB
                end
            end
            local refIdA,refIdB = a.refId,b.refId
            local qualityA = gModelHero:GetHeroInitQualityByRefId(refIdA)
            local qualityB = gModelHero:GetHeroInitQualityByRefId(refIdB)
            if qualityA ~= qualityB then
                return qualityA > qualityB
            end
            local raceTypeA,raceTypeB = gModelHero:GetHeroType(refIdA),gModelHero:GetHeroType(refIdB)
            if raceTypeA ~= raceTypeB then
                return raceTypeA > raceTypeB
            end
            return a.id < b.id
        end)
    end
    return list
end

function UITmHourGlass:InitText()
    self:SetWndText(self.mLblBiaoti,ccClientText(26307))
    self:SetWndText(self.mTitleText,ccClientText(26303))
    self:SetWndButtonText(self.mEnterBtn,ccClientText(26306))
    self:SetWndText(self.mPayDescTxt,ccClientText(26304))
end

function UITmHourGlass:InitHeroList(click)
    local list = self:GetHeroList()
    local uiHeroList = self._uiHeroList
    if uiHeroList then
        if click then
            uiHeroList:RefreshData(list)
        else
            uiHeroList:RefreshList(list)
        end
    else
        uiHeroList = self:GetUIScroll("uiHeroList")
        self._uiHeroList = uiHeroList
        uiHeroList:Create(self.mHeroList,list,function(...) self:OnDrawHeroCell(...) end,UIItemList.WRAP)
    end
    local isEmpty = #list < 1
    CS.ShowObject(self.mNoRecord2,isEmpty)
end
------------------------- CommonFunc -------------------------
function UITmHourGlass:GetCommonIconTrans(trans)
    return self:FindWndTrans(trans,"CommonUI/Icon")
end

function UITmHourGlass:OnDrawNeedItemCell(list,item,itemdata,itempos)
    local IconTrans = self:FindWndTrans(item,"Icon")
    local NumTrans = self:FindWndTrans(item,"Num")
    local BtnDivTrans = self:FindWndTrans(item,"BtnDiv")
    local AddBtnTrans = self:FindWndTrans(BtnDivTrans,"AddBtn")

    local itemId = itemdata.itemId
    local icon = gModelItem:GetItemIconByRefId(itemId)
    self:SetWndEasyImage(IconTrans,icon)

    local itemNum = itemdata.itemNum
    self:SetWndText(NumTrans,itemNum)

    self:SetWndClick(AddBtnTrans,function()
        self:OnClickAddBtnFunc(itemId)
    end)
end

function UITmHourGlass:InitEvent()
    for i,v in ipairs(self._raceBtnTransList) do
        self:SetWndClick(v.btnTrans,function()
            self:OnClickRaceBtnFunc(v.race)
        end)
    end
    self:SetWndClick(self.mAllRaceBtn,function() self:OnClickRaceBtnFunc(0) end)
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)
end

function UITmHourGlass:OnClickHeroFunc(itemdata)
    local id = itemdata.id
    local status = itemdata.status
    if status == 1 then
        if itemdata.isCombat == 1 then
            local noOpenSelWndList = {}
            local wndInst = GF.FindFirstWndByName("UISagaSpirit")
            if wndInst then
                noOpenSelWndList["UISagaSelect"] = "UISagaSelect"
            end
            gModelFormation:OnHeroRemoveFormationReq(id,2,LGameUI.UI_SORTLAYER_UIBOTTOM,true,noOpenSelWndList)
        elseif itemdata.lock == 1 then
            gModelHeroSpirit:HeroUnLockOpt({heroId = id})
        elseif itemdata.isResonance == 1 then
            gModelHeroSpirit:HeroUnResonanceOpt({heroId = id})
        end
        return
    end
    if self._selHeroId == id then return end
    self._selHeroId = id
    self:RefreshSelHeroId(true)
end

function UITmHourGlass:OnClickHeroRewardItemFunc(itemdata)
    gModelGeneral:ShowCommonItemTipWnd(itemdata)
end

function UITmHourGlass:CreateHeroRoot()
    local selHeroId = self._selHeroId
    local isSel = selHeroId ~= nil
    CS.ShowObject(self.mHeroIconRoot,isSel)
    CS.ShowObject(self.mNoSelHeroImg,not isSel)
    if not isSel then return end
    local trans = self.mHeroIconRoot
    local heroData = gModelHero:GetHeroServerDataById(selHeroId)
    self:CreateCommonIcon(trans,heroData,true)
    local IconTrans = self:GetCommonIconTrans(trans)
    self:SetWndClick(IconTrans,function()
        local serverData = gModelHero:GetHeroServerDataById(selHeroId)
        if serverData then
            gModelHero:ReqShowHeroTip("",serverData)
        end
    end)
end

function UITmHourGlass:RefreshHeroData()
    self:InitHeroList(true)
end

function UITmHourGlass:InitMinRewardItemList(list)
    local uiMinRewardItemList = self._uiMinRewardItemList
    if uiMinRewardItemList then
        uiMinRewardItemList:RefreshList(list)
    else
        uiMinRewardItemList = self:GetUIScroll("uiMinRewardItemList")
        self._uiMinRewardItemList = uiMinRewardItemList
        uiMinRewardItemList:Create(self.mMinRewardItemList,list,function(...) self:OnDrawHeroRewardItemCell(...) end)
    end
end

function UITmHourGlass:OnDrawHeroCell(list,item,itemdata,itempos)
    self:CreateCommonIcon(item,itemdata)

    local IconTrans = self:GetCommonIconTrans(item)
    self:SetWndClick(IconTrans,function()
        self:OnClickHeroFunc(itemdata)
    end)
end

function UITmHourGlass:OnDrawHeroRewardItemCell(list,item,itemdata,itempos)
    self:CreateCommonIcon(item,itemdata,true)

    local IconTrans = self:GetCommonIconTrans(item)
    self:SetWndClick(IconTrans,function()
        self:OnClickHeroRewardItemFunc(itemdata)
    end)
end

function UITmHourGlass:InitData()
    self._itemId = self:GetWndArg("itemId")

    self._selHeroId = nil

    self._selRace = 0

    local itemInfo = gModelItem:GetTimeHourGlassInfoByRefId(self._itemId)
    if itemInfo then
        local heroStar = itemInfo.heroStar
        local returnToStar = itemInfo.returnToStar
        local str = string.replace(ccClientText(26301),heroStar,returnToStar)
        self:SetWndText(self.mReturnTxt,str)

        self._heroStar = heroStar
        self._returnToStar = returnToStar
    end
end

function UITmHourGlass:InitMsg()
    self:WndNetMsgRecv(LProtoIds.HeroReturn2Resp,function(pb) self:OnHeroReturn2Resp(pb) end)
    self:WndNetMsgRecv(LProtoIds.HeroLockResp,function() self:RefreshHeroData() end)
    self:WndNetMsgRecv(LProtoIds.HeroRemoveFormationResp,function() self:RefreshHeroData() end)
    self:WndNetMsgRecv(LProtoIds.ResonanceHeroResp,function() self:RefreshHeroData() end)


	 self:WndEventRecv(EventNames.On_Item_Change,function() self:RefreshItemFunc() end)
end

function UITmHourGlass:OnClickEnterBtnFunc()
    local selHeroId = self._selHeroId
    if not selHeroId then
        GF.ShowMessage(ccClientText(26300))
        return
    end
    local needRefId,needNum = gModelHeroSpirit:GetReturnItemInfo(self._itemId,selHeroId)
    if not needRefId or not needNum then return end
    local haveNum = gModelItem:GetNumByRefId(needRefId)
    if haveNum < needNum then
        gModelGeneral:OpenGetWayWnd({itemId = needRefId,srcWnd = self:GetWndName()})
        GF.ShowMessage(ccClientText(26302))
        return
    end
    local list = self:GetHeroRewardItemList()
    GF.OpenWnd("UITmHourGlassTips",{
        selHeroId = selHeroId,
        itemId = self._itemId,
        returnRewardList = list,
    })
end

function UITmHourGlass:InitEmptyList()
    local data = {
        refId = 1004,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UITmHourGlass:RefreshHeroRewardItemList()
    local list = self:GetHeroRewardItemList()
    local len = #list
    local minListTrans = self.mMinRewardItemList
    local moreListTrans = self.mRewardItemList
    local showMin = len <= 2
    local showMore = not showMin
    local isEmpty = len < 1
    if isEmpty then
        showMin = false
        showMore = false
    end
    CS.ShowObject(minListTrans,showMin)
    CS.ShowObject(moreListTrans,showMore)
    CS.ShowObject(self.mReturnTxt,isEmpty)
    if isEmpty then return end

    if showMin then
        self:InitMinRewardItemList(list)
    else
        self:InitRewardItemList(list)
    end
end

function UITmHourGlass:OnHeroReturn2Resp(pb)
    self._selHeroId = nil
    self:RefreshSelHeroId()
end

function UITmHourGlass:OnClickAddBtnFunc(itemId)
    gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
end

function UITmHourGlass:InitRewardItemList(list)
    local uiRewardItemList = self._uiRewardItemList
    if uiRewardItemList then
        uiRewardItemList:RefreshList(list)
    else
        uiRewardItemList = self:GetUIScroll("uiRewardItemList")
        self._uiRewardItemList = uiRewardItemList
        uiRewardItemList:Create(self.mRewardItemList,list,function(...) self:OnDrawHeroRewardItemCell(...) end,UIItemList.WRAP)
    end
    local uiList = uiRewardItemList:GetList()
    uiList:RefreshList(UIListWrap.RefreshMode.Solid)
end

function UITmHourGlass:RefreshSelHeroId(click)
    self:CreateHeroRoot()
    local showPayDiv = self:RefreshPayItem()
    CS.ShowObject(self.mPayDiv,showPayDiv or false)
    self:RefreshHeroRewardItemList()
    self:InitHeroList(click)
end

function UITmHourGlass:RefreshPayItem()
    local selHeroId = self._selHeroId
    local needRefId,needNum = gModelHeroSpirit:GetReturnItemInfo(self._itemId,selHeroId)
    if not needRefId or not needNum then return end
    local icon = gModelItem:GetItemIconByRefId(needRefId)
    self:SetWndEasyImage(self.mPayItemIcon,icon)
    local str = string.replace(ccClientText(26305),needNum)
    self:SetWndText(self.mPayNumTxt,str)
    return true
end

function UITmHourGlass:RefreshItemFunc()
    self:InitNeedItemList()
end

function UITmHourGlass:CreateCommonIcon(trans,itemdata,notShow)
    local IconTrans = self:GetCommonIconTrans(trans)

    local InstanceID = trans:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(IconTrans)
    local itemType = itemdata.itemType or itemdata.itype
    local itemId = itemdata.itemId or itemdata.refId
    local itemNum = itemdata.itemNum
    if itemType == LItemTypeConst.TYPE_ITEM then
        baseClass:SetCommonReward(itemType, itemId, itemNum)
    elseif itemType == LItemTypeConst.TYPE_HERO then
        local id = itemdata.id
        if id then
            local isSelect = id == self._selHeroId and not notShow
            local heroData = {
                id = id,
                refId = itemdata.refId,
                star = itemdata.star,
                level = itemdata.level,
                skin = itemdata.skin,
                isResonance = itemdata.isResonance,
                selected = isSelect,
            }
            baseClass:SetHeroDataSet(heroData)
            baseClass:ShowStatusImg(true,false)
        else
            baseClass:SetCommonReward(itemType, itemId, itemNum)
        end
    end
    baseClass:DoApply()
end

------------------------- List -------------------------

------------------------------------------------------------------
return UITmHourGlass



