---
--- Created by Administrator.
--- DateTime: 2024/9/19 16:41:25
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMicCollectSow:LWnd
local UIMicCollectSow = LxWndClass("UIMicCollectSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMicCollectSow:UIMicCollectSow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMicCollectSow:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMicCollectSow:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMicCollectSow:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitMsg()
    self:InitText()
    self:InitPara()
end

function UIMicCollectSow:InitText()
    self:SetTranUIText(self.mBg_1, ccClientText(45702))
    self:SetWndTabText(self.mBtnTab_1, ccClientText(45703))
    self:SetWndTabText(self.mBtnTab_2, ccClientText(45704))
    self:SetWndText(self.mSubTitle, ccClientText(45708))  --[45708] [屬性加成]
    self:SetWndText(self.mCloseTip, ccClientText(10103))

    self:SetWndText(self.mSubTitle_2, ccClientText(45712))  --[45712] [全體少女加成]
    self:SetWndText(self.mSubTitle_3, ccClientText(45713))  --[45713] [魔法陣增益]

end

--region 界面初始化 --------------------------------------------------------------------------------
function UIMicCollectSow:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mBtnTab_1, function()
        self:OnTabClick(1)
    end)

    self:SetWndClick(self.mBtnTab_2, function()
        self:OnTabClick(2)
    end)
end

function UIMicCollectSow:InitPara()
    local tabIndex = self:SetWndArg("tabIndex") or 1
    self._index = 0
    self:OnTabClick(tabIndex)
end
--endregion --------------------------------------------------------------------------------------

--region clickEvent --------------------------------------------------------------------------------
function UIMicCollectSow:OnTabClick(index)
    if self._index == index then
        return
    end
    self._index = index
    CS.ShowObject(self.mCenter_1, index == 1)
    CS.ShowObject(self.mCenter_2, index == 2)
    self:SetWndTabStatus(self.mBtnTab_1, index == 1 and 0 or 1)
    self:SetWndTabStatus(self.mBtnTab_2, index == 2 and 0 or 1)

    if index == 1 then
        self:SetContent_1()

    elseif index == 2 then
        self:SetContent_2()
    end
end

function UIMicCollectSow:InitMsg()
    self:WndEventRecv(gModelMagic.EventArgs.CollectionActive, function()
        if self._index == 1 then
            self:SetContent_1()
        end
    end)
end

function UIMicCollectSow:OnDrawBuff(list, item, itemdata, index)
    local Info = CS.FindTrans(item, "Info")
    local SkillIcon_Bg = CS.FindTrans(Info, "SkillIcon_Bg")
    local SkillIcon = CS.FindTrans(SkillIcon_Bg, "SkillIcon")
    local SkillLv = CS.FindTrans(SkillIcon_Bg, "SkillLv")
    local SkillName = CS.FindTrans(Info, "SkillName")
    local AttrDiv = CS.FindTrans(Info, "AllHeroAttrDiv")

    local magicCircleRef = gModelMagic:GetMagicCircleRef(itemdata.magicRefId)

    self:SetWndEasyImage(SkillIcon, magicCircleRef.buffIcon)
    self:SetWndText(SkillName, ccLngText(magicCircleRef.buffName))
    self:SetWndText(SkillLv, "Lv." .. itemdata.level)

    if itemdata.level == 0 then
        CS.ShowObject(SkillLv, false)
    end

    --设置对应的属性
    local AllHeroAttrList = CS.FindTrans(Info, "AllHeroAttrList")

    local buffCfg = gModelMagic:GetBuffCfgByOriginIdAndLv(magicCircleRef.buff, itemdata.level)
    local count, attrList = gModelMagic:ParseAttr(buffCfg.attr)
    self:SetAttrList(attrList, AllHeroAttrList, index, false)

    if count >= 3 then
        self:SetAttrList(attrList, AllHeroAttrList, index, false)
        CS.ShowObject(AllHeroAttrList, true)
        CS.ShowObject(AttrDiv, false)
    else
        CS.ShowObject(AllHeroAttrList, false)
        CS.ShowObject(AttrDiv, true)

        for i = 1, count do
            local attrTranKey = "Attr_" .. i
            local attrTran = CS.FindTrans(AttrDiv, attrTranKey)
            self:OnDrawAttr(nil, attrTran, attrList[i], i)
            CS.ShowObject(attrTran, true)
        end

    end


end

function UIMicCollectSow:OnDrawCollect(list, item, itemdata, index)
    local Title = CS.FindTrans(item, "Title")
    local BuffDes_1 = CS.FindTrans(item, "BuffDesDiv/BuffDes_1")
    local BuffDes_2 = CS.FindTrans(item, "BuffDesDiv/BuffDes_2")
    local UseBtn = CS.FindTrans(item, "UseBtn")
    local UseTag = CS.FindTrans(item, "UseTag")

    self:SetWndText(Title, ccLngText(itemdata.desc))

    CS.ShowObject(BuffDes_1, false)
    CS.ShowObject(BuffDes_2, false)
    CS.ShowObject(UseBtn, false)
    CS.ShowObject(UseTag, false)
    --设置属性
    local count, attrList = gModelMagic:ParseAttr(itemdata.attr)

    for i = 1, count do
        local tran = i == 1 and BuffDes_1 or BuffDes_2
        CS.ShowObject(tran, true)
        local str = string.replace(ccClientText(45706), attrList[i].attrName, attrList[i].attrStr)  --[45706] [全體少女：#a1#]
        self:SetWndText(tran, str)
    end


    --按钮的状态设置
    local code, collectRefId = gModelMagic:GetCollectSchedule()
    local isNext = collectRefId + 1 == itemdata.refId

    local instanceID = UseBtn:GetInstanceID()
    self:DestroyWndEffectByKey(instanceID)
    if collectRefId >= itemdata.refId then
        CS.ShowObject(UseTag, true)
    else
        CS.ShowObject(UseBtn, true)

        if code >= itemdata.collectionDegree and isNext then
            self:SetWndButtonGray(UseBtn, false)
            self:CreateWndEffect(UseBtn, "fx_anniu_03", instanceID, 100)
        else
            self:SetWndButtonGray(UseBtn, true)
        end

        self:SetWndButtonText(UseBtn, ccClientText(45709))  --[45709] [啓 用]
    end

    self:SetWndClick(UseBtn, function()
        --激活
        if code >= itemdata.collectionDegree then
            if isNext then
                gModelMagic:SendMagicCollectionActiveReq(itemdata.refId)
            else
                GF.ShowMessage(ccClientText(45711))
            end
        else
            GF.ShowMessage(string.replace(ccClientText(45710), itemdata.collectionDegree)) --[45710] [收集度未達到：#a1#]
        end
    end)
end

function UIMicCollectSow:SetCandleAttrList(attrList, tran)
    local showData = attrList
    self._attrScrollList = self._attrScrollList or {}
    local uiList = self._attrScrollList[tran.name]

    if not uiList then
        uiList = self:GetUIScroll("UIMicCollectSow" .. tran.name)

        uiList:Create(tran, showData or {}, function(...)
            self:OnDrawCandleAttr(...)
        end, UIItemList.SUPER_GRID)
    else
        uiList:RefreshList(showData)
        uiList:DrawAllItems()
    end
    self._attrScrollList[tran.name] = uiList
end

function UIMicCollectSow:SetContent_1()
    local code, collectRefId = gModelMagic:GetCollectSchedule()
    --当前的收集度
    self:SetWndText(self.mCurCollect, string.replace(ccClientText(45707), code))
    self:SetCollectList()

    --总的加成部分
    self:SetAllAttrBenefit(collectRefId)
end

function UIMicCollectSow:OnDrawCandleAttr(list, item, itemdata, index)
    local AttrIcon = CS.FindTrans(item, "AttrIcon")
    local AttrName = CS.FindTrans(item, "AttrName")
    local AttrValue_1 = CS.FindTrans(item, "AttrValue_1")
    local AttrValue_2 = CS.FindTrans(item, "AttrValue_2")

    local icon = gModelHero:GetAttributeIconById(itemdata.attrRefId)
    self:SetWndEasyImage(AttrIcon, icon)

    self:SetWndText(AttrName, itemdata.attrName)
    self:SetWndText(AttrValue_1, itemdata.attrStr)

    if self._isVie then
        local uiText = LxUiHelper.FindXTextCtrl(AttrName)
        local desW = uiText.preferredWidth

        if checknumber(desW) > 40 then
            self:SetAnchorPos(AttrValue_1, Vector2.New(80, 0))
        else
            self:SetAnchorPos(AttrValue_1, Vector2.New(40, 0))
        end
    end

end


--设置内容2的页签
function UIMicCollectSow:SetContent_2()
    --设置蜡烛的属性
    self:SetAllCandleBenefit()

    --设置阵法的增益
    self:SetAllMagicBenefit()
end

function UIMicCollectSow:SetMagicBenefitList(magicBenefit, tran)
    local showData = magicBenefit
    self._attrScrollList = self._attrScrollList or {}
    local uiList = self._attrScrollList[tran.name]

    if not uiList then
        uiList = self:GetUIScroll("UIMicCollectSow" .. tran.name)

        uiList:Create(tran, showData or {}, function(...)
            self:OnDrawBuff(...)
        end, UIItemList.SUPER)
    else
        uiList:RefreshList(showData)
        uiList:DrawAllItems()
    end

    self._attrScrollList[tran.name] = uiList
end

function UIMicCollectSow:OnDrawAttr(list, item, itemdata, index)
    local Des = CS.FindTrans(item, "Des")
    local str = string.replace(ccClientText(45706), itemdata.attrName, itemdata.attrStr)  --[45706] [全體少女：#a1#]
    self:SetWndText(Des, str)
end

function UIMicCollectSow:SetAllCandleBenefit()
    CS.ShowObject(self.mNoDes_2, false)

    --获取数据
    local count, candleDataAttr = gModelMagic:GetAllCandleAttr()
    --不显示
    if not count then
        CS.ShowObject(self.mNoDes_2, true)
        self:SetWndText(self.mNoDes_2, ccLngText(GameTable.EmptyTipsRef[41002].text))
    else

        self:SetCandleAttrList(candleDataAttr, self.mCandleAttrList)
    end
end

--center_1的数据设置
function UIMicCollectSow:SetCollectList()
    local showData = gModelMagic:GetMagicCollectionRef()
    local uiList = self._collectList

    table.sort(showData, function(a, b)

        --排序 可激活的放前面
        local aSortCode = 10000 - a.refId

        local bSortCode = 10000 - b.refId
        local code, collectRefId = gModelMagic:GetCollectSchedule()

        if collectRefId >= a.refId then
            --已经激活过了  - 1000
            aSortCode = aSortCode - 1000
        else
            --可以激活
            local isNext = collectRefId + 1 == a.refId

            if code >= a.collectionDegree and isNext then
                aSortCode = aSortCode * 1000
            end
        end

        if collectRefId >= b.refId then
            bSortCode = bSortCode - 1000
        else
            local isNext = collectRefId + 1 == b.refId

            if code >= b.collectionDegree and isNext then
                bSortCode = bSortCode * 1000
            end
        end

        return aSortCode > bSortCode
    end)

    if not uiList then
        uiList = self:GetUIScroll("UIMicCollectSowCollectList")
        uiList:Create(self.mCollectList, showData or {}, function(...)
            self:OnDrawCollect(...)
        end, UIItemList.SUPER)
    else
        uiList:RefreshList(showData)
        uiList:DrawAllItems()
    end
    self._collectList = uiList
end

--endregion --------------------------------------------------------------------------------------

--region 界面方法 --------------------------------------------------------------------------------
--找到一个tran下的uitext 并设置文本
function UIMicCollectSow:SetTranUIText(tran, str)
    local text = CS.FindTrans(tran, "UIText")
    self:SetWndText(text, str)
end

function UIMicCollectSow:SetAllMagicBenefit()
    CS.ShowObject(self.mNoDes_3, false)

    --获取数据
    local count, magicBenefit = gModelMagic:GetAllMagicBenefitInfo()
    --不显示
    if not count or count == 0 then
        CS.ShowObject(self.mNoDes_3, true)
        local emptyCfg = GameTable.EmptyTipsRef[41000]


        --icon  textbg  text
        self:SetWndEasyImage(self.mEmptyIcon, emptyCfg.icon)
        self:SetWndEasyImage(self.mEmptyTextBg, emptyCfg.textBg)
        self:SetWndText(self.mEmptyText, ccLngText(emptyCfg.text))
    else
        self:SetMagicBenefitList(magicBenefit, self.mBuffList)
    end
end

function UIMicCollectSow:SetAllAttrBenefit(collectRefId)
    local count, attrList = gModelMagic:GetAttrBenifitByRefId(collectRefId)
    CS.ShowObject(self.mNoDes, false)
    if count == 0 or not count then
        --不显示
        CS.ShowObject(self.mNoDes, true)
        self:SetWndText(self.mNoDes, ccLngText(GameTable.EmptyTipsRef[41001].text))
    else

        local count = #attrList

        if count >= 3 then
            self:SetAttrList(attrList, self.mAttrList)
            CS.ShowObject(self.mAttrList, true)
            CS.ShowObject(self.mAttrDiv, false)
        else
            CS.ShowObject(self.mAttrList, false)
            CS.ShowObject(self.mAttrDiv, true)
            for i = 1, count do
                local attrTranKey = "Attr_" .. i
                local attrTran = CS.FindTrans(self.mAttrDiv, attrTranKey)
                self:OnDrawAttr(nil, attrTran, attrList[i], i)
                CS.ShowObject(attrTran, true)
            end

        end
    end
end

function UIMicCollectSow:SetAttrList(attrList, tran, otherKey, CanScroll)
    local showData = attrList
    self._attrScrollList = self._attrScrollList or {}

    local tranKey = otherKey and string.format("%s_%s", tran.name, otherKey) or tran.name
    local uiList = self._attrScrollList[tranKey]

    if not uiList then
        uiList = self:GetUIScroll("UIMicCollectSow" .. tranKey)

        uiList:Create(tran, showData or {}, function(...)
            self:OnDrawAttr(...)
        end, UIItemList.SUPER)
    else
        uiList:RefreshList(showData)
        uiList:DrawAllItems()
    end

    if not CanScroll then
        uiList:EnableScroll(false, false)
    end

    self._attrScrollList[tranKey] = uiList
end
--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIMicCollectSow