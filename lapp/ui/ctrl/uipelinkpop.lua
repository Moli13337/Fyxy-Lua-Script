---
--- Created by Administrator.
--- DateTime: 2024/6/13 15:21:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeLinkPop:LWnd
local UIPeLinkPop = LxWndClass("UIPeLinkPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeLinkPop:UIPeLinkPop()
    self._careerType = 0
    self._raceType = 0
    self._heroItem = {}
    self.curLinkIndxToHeroId = {}--当前位置链接的英雄
    self.curHeroIdToLinkIndx = {}--当前英雄链接的位置
    self.curRemoveLinkPet = {}--被替换连接的宠物
    self._commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeLinkPop:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeLinkPop:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeLinkPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    self.refId = self:GetWndArg("refId")--宠物refId
    self.selLinkIndx = 1--当前选中链接的位置
    self:SetWndText(self.mLblBiaoti, ccClientText(43730))
    self:SetWndText(self.mTxtTitle, string.replace(ccClientText(43731), GameTable.MagicPetConfigRef.petHeroStar))

    if self._isEnus then
        self:InitTextSizeWithLanguage(self.mTxtTitle, -2)
    end

    self:SetWndText(self.mTxtDesc, ccClientText(43732))
    self:SetWndButtonText(self.mBtnSave, ccClientText(43733))
    self:OnAddEvent()
    self:SetStaticContent()
    self:InitRaceTypeList()
    self:InitCareerTypeList()
    self:InitSelectData()
    self:OnUpateLinkList()
    self:GenerateUIHeroList()
end
function UIPeLinkPop:OnAddEvent()
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mUnfoldBtn, function()
        -- 展开按钮
        if not self._showRaceBtnList then
            self._showRaceBtnList = true
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mPackBtn, function()
        -- 收起按钮
        if self._showRaceBtnList then
            self._showRaceBtnList = false
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mShowAllBtn, function()
        -- 收起按钮
        if self._showRaceBtnList then
            self._showRaceBtnList = false
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mBtnSave, function()
        gModelPet:OnPetLinkReq(self.refId, self.curLinkIndxToHeroId, self.curRemoveLinkPet)
        self:WndClose()
    end)
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
end

function UIPeLinkPop:InitRaceTypeList()
    local data = {
        wndClass = self,
        listTrans = self.mHeroRaceList,
        showType = UIHeroRaceList.TYPE_NORMAL,
        callbackFunc = function(raceType)
            if not self:IsWndValid() then
                return
            end
            if raceType == self._raceType then
                return
            end
            self._raceType = raceType
            self:GenerateUIHeroList()
        end,
        checkSelFunc = function(raceType)
            if not self:IsWndValid() then
                return
            end
            return self._raceType == raceType
        end,
    }
    self:GetUIHeroRaceList(data)
end

function UIPeLinkPop:OnUpateLinkList()
    self:CreateUIScrollImpl(nil, self.mListHeroSel, self.selectData, function(...)
        self:OnLinkHeroCell(...)
    end)
end

function UIPeLinkPop:PlayRaceBtnAni()
    local isShow = self._showRaceBtnList
    CS.ShowObject(self.mLine1, not isShow)
    CS.ShowObject(self.mLine2, isShow)
    CS.ShowObject(self.mUnfoldBtn, not isShow)
    local sizeY = isShow and -60 or 0
    local size = Vector2.New(self.mHeroList.sizeDelta.x, sizeY)
    self.mHeroList.sizeDelta = size
end

function UIPeLinkPop:OnDrawHeroShenCell(list, item, itemdata, itempos)
    CS.ShowObject(item, true)
    local iconTrans = CS.FindTrans(item, "CommonUI/Icon")
    local PetMaks = CS.FindTrans(item, "PetMaks")
    local ImgSelect = CS.FindTrans(item, "ImgSelect")
    local selHId = itemdata:GetId()
    local instanceId = item:GetInstanceID()
    local commonUIList = self._commonUIList
    local uiIconClass = commonUIList[instanceId]
    if not uiIconClass then
        uiIconClass = CommonIcon:New()
        commonUIList[instanceId] = uiIconClass
        uiIconClass:Create(iconTrans)
        self:SetIconClickScale(iconTrans, true)
    end
    uiIconClass:SetHeroPlayer(selHId)
    uiIconClass:SetNoShowLv(false)
    uiIconClass:SetShowGouImg(false)
    uiIconClass:DoApply()

    local linkNum = #itemdata.petIds --gModelPet:GetLinkPetNum(selHId)
    local isFull = self.curMaxLinkNum <= linkNum
    if isFull and not self.curHeroIdToLinkIndx[selHId] and gModelPet:GetHeroLinkPet(selHId, self.refId) then
        --宠物连接-临时断开情况
        isFull = false
    end
    CS.ShowObject(PetMaks, isFull and not self.curHeroIdToLinkIndx[selHId])
    CS.ShowObject(ImgSelect, not not self.curHeroIdToLinkIndx[selHId])

    if isFull then
        self:SetTextTile(PetMaks, ccClientText(40511))
    end
    self:SetWndLongClick(iconTrans, function()
        gModelHero:ReqShowHeroTip("", itemdata:GetServerData())
    end)

    self:SetWndClick(iconTrans, function()
        local selHIdIndx = self.curHeroIdToLinkIndx[selHId]--已装备
        if selHIdIndx then
            --已连接--取消
            if self.curRemoveLinkPet[selHId] then
                self.curRemoveLinkPet[selHId] = nil
            end
            self.curHeroIdToLinkIndx[selHId] = nil
            if self.curLinkIndxToHeroId[selHIdIndx] then
                self.curLinkIndxToHeroId[selHIdIndx] = nil
            end
            self:OnUpateLinkList()
            self:GenerateUIHeroList()
            return
        elseif isFull then
            --已满--替换--连接
            local func = function(petId)
                self.curRemoveLinkPet[selHId] = petId
                local oldHId = self.curLinkIndxToHeroId[self.selLinkIndx]
                if oldHId then
                    self.curHeroIdToLinkIndx[oldHId] = nil
                end
                self.curLinkIndxToHeroId[self.selLinkIndx] = selHId
                self.curHeroIdToLinkIndx[selHId] = self.selLinkIndx
                self:OnUpateLinkList()
                self:GenerateUIHeroList()
            end
            local selHeroData = gModelHero:GetHeroById(selHId)
            GF.OpenWnd("UIPeLinkReplace", { func = func, itemList = selHeroData:GetPetIds() })
            return
        else
            --没连接--连接
            local oldLinkHId = self.curLinkIndxToHeroId[self.selLinkIndx]
            if oldLinkHId then
                self.curHeroIdToLinkIndx[oldLinkHId] = nil
                if self.curRemoveLinkPet[oldLinkHId] then
                    self.curRemoveLinkPet[oldLinkHId] = nil
                end
            end
            self.curLinkIndxToHeroId[self.selLinkIndx] = selHId
            self.curHeroIdToLinkIndx[selHId] = self.selLinkIndx
            self:OnUpateLinkList()
            self:GenerateUIHeroList()
            return
        end
    end)
end

function UIPeLinkPop:OnLinkHeroCell(list, item, itemdata, itempos)
    local ImgSelect = self:FindWndTrans(item, "CommonUI/ImgSelect")
    local IconBg = self:FindWndTrans(item, "CommonUI/IconBg")
    local Icon = self:FindWndTrans(item, "CommonUI/Icon")
    local ImgMask = self:FindWndTrans(item, "ImgMask")
    local TxtMask = self:FindWndTrans(item, "ImgMask/TxtMask")
    ---@type StructPet
    local pet = gModelPet:GetPetById(itemdata.type)
    local heroId = self.curLinkIndxToHeroId[itemdata.link]
    CS.ShowObject(IconBg, false)
    CS.ShowObject(Icon, false)
    CS.ShowObject(ImgMask, false)
    CS.ShowObject(ImgSelect, itempos == self.selLinkIndx)
    if not string.isempty(heroId) then
        --链接英雄
        CS.ShowObject(Icon, true)
        local instanceId = item:GetInstanceID()
        local commonUIList = self._commonUIList
        local uiIconClass = commonUIList[instanceId]
        if not uiIconClass then
            uiIconClass = CommonIcon:New()
            commonUIList[instanceId] = uiIconClass
            uiIconClass:Create(Icon)
            self:SetIconClickScale(Icon, true)
        end
        uiIconClass:SetHeroPlayer(heroId)
        uiIconClass:SetNoShowLv(false)
        uiIconClass:SetShowGouImg(false)
        uiIconClass:DoApply()
    else
        if pet.isActive and pet._star >= itemdata.rankNow then
            --可连接
            self:SetWndEasyImage(IconBg, "public_item_bg_add")
            CS.ShowObject(IconBg, true)
        else
            self:SetWndEasyImage(IconBg, "public_item_bg_1")
            CS.ShowObject(IconBg, true)
            CS.ShowObject(ImgMask, true)
            local str = itemdata.rankNow == 0 and ccClientText(43729) or string.replace(ccClientText(43728), itemdata.rankNow)
            self:SetWndText(TxtMask, str)
        end
    end
    self._heroItem[itempos] = item
    self:SetWndClick(item, function()
        if not pet.isActive then
            return
        end
        if self.selLinkIndx == itempos then
            return
        end
        if pet._star < itemdata.rankNow then
            return
        end
        local oldItem = self._heroItem[self.selLinkIndx]
        if oldItem then
            local oldSele = self:FindWndTrans(oldItem, "CommonUI/ImgSelect")
            CS.ShowObject(oldSele, false)
        end
        self.selLinkIndx = itempos
        CS.ShowObject(ImgSelect, true)
    end)
end
function UIPeLinkPop:OnClickCareerTypeFunc(refId)
    if self._careerType == refId then
        return
    end
    self._careerType = refId
    self:GenerateUIHeroList()

    local uiCareerTypeList = self._uiCareerTypeList
    if not uiCareerTypeList then
        return
    end
    local uiList = uiCareerTypeList:GetList()
    uiList:RefreshList()
end

function UIPeLinkPop:InitSelectData()
    local heros = {}
    local petStarCfgs = gModelPet.petStarCfg[self.refId]
    ---@type StructPet
    local pet = gModelPet:GetPetById(self.refId)

    if CS.IsWebGL() then
        local index = 0
        for _, value in pairs(petStarCfgs or {}) do
            if value.link > 0 then
                index = index + 1
                table.insert(heros, value)
            end
        end

        table.sort(heros, function(a, b)
            return a.link < b.link
        end)

        for _, value in pairs(heros) do
            --index = index + 1
            index = value.link
            local hId = pet:GetPetLinkHeroId(value.link)
            self.curLinkIndxToHeroId[index] = hId
            if hId then
                self.curHeroIdToLinkIndx[hId] = index
            end
        end
    else
        local index = 0
        for _, value in pairs(petStarCfgs or {}) do
            if value.link>0 then
                index = index+1
                table.insert(heros,value)
                local hId = pet:GetPetLinkHeroId(value.link)
                self.curLinkIndxToHeroId[index] = hId
                if hId then self.curHeroIdToLinkIndx[hId] = index end
            end
        end
    end

    self.selectData = heros

end
function UIPeLinkPop:GetCareerTypeList()
    local list = {}
    table.insert(list, {
        refId = UIHeroRaceList.ALL_RACE_REFID,
        icon = "public_race_0",
    })
    for k, v in pairs(GameTable.CharacterCareerRef) do
        table.insert(list, {
            refId = k,
            icon = v.jobIcon
        })
    end
    table.sort(list, function(a, b)
        return a.refId < b.refId
    end)
    local listLen = #list
    local allRaceNum = gModelHero:GetAllRaceNum()
    local loseNum = allRaceNum - listLen
    if loseNum > 0 then
        for i = 1, loseNum do
            table.insert(list, {
                show = false,
            })
        end
    end

    return list
end

function UIPeLinkPop:GenerateUIHeroList()
    local dataList = gModelHero:GetHeroList()
    local starNeed = GameTable.MagicPetConfigRef.petHeroStar
    local heroList = {}
    for _, value in pairs(dataList) do
        if value:GetStar() >= starNeed then
            local heroCfg = GameTable.CharacterRef[value:GetRefId()]
            if (self._raceType == 0 or heroCfg.raceType == self._raceType) and (self._careerType == 0 or heroCfg.careerType == self._careerType) then
                table.insert(heroList, value)
            end
        end
    end
    table.sort(heroList, function(a, b)
        return a:GetPower() > b:GetPower()
    end)
    CS.ShowObject(self.mNoRecord, not heroList[1])
    self.curMaxLinkNum = gModelPet:GetHeroMaxLinkNum()
    local uiHeroShenList = self._uiHeroScrollList
    if not uiHeroShenList then
        uiHeroShenList = self:GetUIScroll("uiLinkHeroList")
        self._uiHeroScrollList = uiHeroShenList
        uiHeroShenList:Create(self.mHeroList, heroList, function(...)
            self:OnDrawHeroShenCell(...)
        end, UIItemList.SUPER_GRID, false)
        local superList = uiHeroShenList:GetList()
        superList:EnableLoadAnimation(true)
        superList:SetLoadAnimationScale(0.2, 0.15)
        superList:RefreshList()
    else
        uiHeroShenList:RefreshList(heroList)
        local superList = uiHeroShenList:GetList()
        superList:DrawAllItems(true)
    end
end

function UIPeLinkPop:SetStaticContent()
    local emptyList = self:GetCommonEmptyList("_empty")
    local data = {
        refId = 36005,
        IntroTran = self:FindWndTrans(self.mNoRecord, "text"),
    }
    emptyList:RefreshUI(data)
end
function UIPeLinkPop:OnDrawCareerTypeCell(list, item, itemdata, itempos)
    local RaceIconTrans = self:FindWndTrans(item, "RaceIcon")
    local SelImgTrans = self:FindWndTrans(item, "SelImg")
    local icon = itemdata.icon
    local refId = itemdata.refId
    local show = icon ~= nil
    local isSel = false
    if show then
        isSel = self._careerType == refId
        self:SetWndEasyImage(RaceIconTrans, icon)
    end
    CS.ShowObject(RaceIconTrans, show)
    CS.ShowObject(SelImgTrans, isSel)
    self:SetWndClick(RaceIconTrans, function()
        self:OnClickCareerTypeFunc(refId)
    end, LSoundConst.CLICK_PAGE_COMMON)
end
function UIPeLinkPop:InitCareerTypeList()
    local list = self:GetCareerTypeList()
    local uiCareerTypeList = self._uiCareerTypeList
    if uiCareerTypeList then
        uiCareerTypeList:RefreshList(list)
    else
        uiCareerTypeList = self:GetUIScroll("PetCareerList")
        self._uiCareerTypeList = uiCareerTypeList
        uiCareerTypeList:Create(self.mCareerTypeList, list, function(...)
            self:OnDrawCareerTypeCell(...)
        end)
    end
end

------------------------------------------------------------------
return UIPeLinkPop