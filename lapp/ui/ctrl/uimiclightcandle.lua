---
--- Created by Administrator.
--- DateTime: 2024/9/19 16:41:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMicLightCandle:LWnd
local UIMicLightCandle = LxWndClass("UIMicLightCandle", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMicLightCandle:UIMicLightCandle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMicLightCandle:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMicLightCandle:OnCreate()
    LWnd.OnCreate(self)
    return true
end

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMicLightCandle:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion() 
    self._isVie = gLGameLanguage:IsVieVersion()
    if self._isEnus then
        CS.ShowObject(self.mAttr_Enus_Spac, self._isEnus)
    end

    self:InitEvent()
    self:InitMsg()
    self:InitPara()
    self:InitText()

    self:RefreshForeign()
end

function UIMicLightCandle:InitPara()
    self._itemdata = self:GetWndArg("itemdata")
    self._isLight = self:GetWndArg("isLight")
    self._magicCircleCfg = self:GetWndArg("circleCfg")
    self._seat = self:GetWndArg("seat")
    self:SetCandleInfo()
end
--endregion --------------------------------------------------------------------------------------

--region event --------------------------------------------------------------------------------
function UIMicLightCandle:OnLightCandleBtnClick()
    local itemdata = self._itemdata
    local haveNum = gModelItem:GetNumByRefId(itemdata.itemId)

    if haveNum < itemdata.itemNum then
        --GF.ShowMessage(ccClientText(45719))
        local needNum  = itemdata.itemNum - haveNum
        needNum = needNum>=0 and needNum  or  0
        GF.OpenWndTop("UIGeay", { itemId = itemdata.itemId, srcWnd = self:GetWndName(),needNum=needNum })
        return
    end
    local magicRefId = self._magicCircleCfg.refId
    gModelMagic:SendMagicLightCandleReq(magicRefId, self._seat)
    --请求后关闭页面
    self:WndClose()
end

--endregion --------------------------------------------------------------------------------------

--region 界面方法 --------------------------------------------------------------------------------
--设置蜡烛的部分
function UIMicLightCandle:SetCandleInfo()
    --蜡烛的引用
    local candleCfg = gModelMagic:GetMagicRef(self._itemdata.itemId)

    --图标
    self:SetWndEasyImage(self.mCandle, candleCfg.icon)
    CS.ShowObject(self.mCandle, true)
    --lv
    local lvPath = gModelMagic:GetCandleQualityTipsImgPath(candleCfg.quality, candleCfg.num)
    self:SetWndEasyImage(self.mCandleLv, lvPath)
    CS.ShowObject(self.mCandleLv, true)

    --蜡烛名
    self:SetWndText(self.mCandleName, ccLngText(candleCfg.name))
    --设置属性
    local count, AttrList = gModelMagic:GetCandleAttr(self._itemdata.itemId, self._itemdata.itemNum)

    --特效
    local effectName = candleCfg.eff

    if not self._candleEffect then
        self._candleEffect = self:CreateWndEffect(self.mCandleEffect, effectName, effectName, 100, nil, nil, nil, nil, nil, true)
        self._candleEffect:SetVisible(false)
    end

    self._candleEffect:SetVisible(self._isLight)
    CS.ShowObject(self.mAttrDiv, false)
    for i = 1, count do
        local tranKey = string.replace("AttrDiv/Attr_#a1#", i)

        local item = CS.FindTrans(self.mBenefitDiv, tranKey)

        local itemdata = AttrList[i]
        if item then
            local AttrIcon = CS.FindTrans(item, "AttrIcon")
            local AttrValue_1 = CS.FindTrans(item, "AttrValue_1")

            local icon = gModelHero:GetAttributeIconById(itemdata.attrRefId)
            self:SetWndEasyImage(AttrIcon, icon)

            local attrStr = gModelHero:GetAttributeValueNoNameByIdAndVal(itemdata.attrRefId, itemdata.attrType, itemdata.attrValue)
            local colorStr = "+<color=#139057>#a1#</color>"

            attrStr = string.replace(colorStr, attrStr)
            attrStr = itemdata.attrName .. attrStr
            self:SetWndText(AttrValue_1, attrStr)
            CS.ShowObject(item, true)
        end
    end

    CS.ShowObject(self.mAttrDiv, true)
    CS.ShowObject(self.mAttrName, true)
    CS.ShowObject(self.mAttr_1, true)

    LayoutRebuilder.ForceRebuildLayoutImmediate(self.mAttr_1)


    --收集度
    local collectStr = string.replace(ccClientText(45718), candleCfg.collectionDegree)
    self:SetWndText(self.mCollect, collectStr)

    CS.ShowObject(self.mBottom_2, self._isLight)
    CS.ShowObject(self.mBottom_1, not self._isLight)
    CS.ShowObject(self.mCostDiv, not self._isLight)


    --消耗道具设置
    if not self._isLight then
        local Icon = self.mItemIcon
        local InstanceID = Icon:GetInstanceID()
        local baseClass = self:GetCommonIcon(InstanceID)
        baseClass:Create(Icon)
        self:SetIconClickScale(Icon, true)
        local itemdata = self._itemdata
        baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
        baseClass:DoApply()

        self:SetWndClick(Icon, function()
            gModelGeneral:ShowCommonItemTipWnd(itemdata)
        end)

        --设置道具名字
        local haveNum = gModelItem:GetNumByRefId(itemdata.itemId)

        local haveStr = LUtil.FormatColorStr(haveNum, haveNum >= itemdata.itemNum and "lightGreen" or "lightRed")

        local nameStr = string.replace("#a1#(#a2#/#a3#)", ccLngText(candleCfg.name), haveStr, itemdata.itemNum)
        self:SetWndText(self.mTips_1, nameStr)

        --Icon.localScale = Vector2(0.65, 0.65)
        local instanceID = self.mLightCandleBtn:GetInstanceID()
        if haveNum >= itemdata.itemNum then
            self:CreateWndEffect(self.mLightCandleBtn, "fx_anniu_03", instanceID, 100)
        else
            self:DestroyWndEffectByKey(instanceID)
        end
    end

end

function UIMicLightCandle:InitMsg()

end

function UIMicLightCandle:OnDrawAttr(list, item, itemdata, index)
    local AttrIcon = CS.FindTrans(item, "AttrIcon")
    local AttrValue = CS.FindTrans(item, "AttrValue")

    local icon = gModelHero:GetAttributeIconById(itemdata.attrRefId)
    self:SetWndEasyImage(AttrIcon, icon)

    self:SetWndText(AttrValue, itemdata.attrValue)
end

function UIMicLightCandle:RefreshForeign()
    if self._isVie then
        LxUiHelper.SetSizeWithCurAnchor(self.mAttr_Enus_Spac,0,25)
        self:InitTextSizeWithLanguage(self.mAttrName,-2)
        CS.ShowObject(self.mAttr_Enus_Spac, self._isVie)

        local text = CS.FindTrans(self.mAttr_1,"AttrValue_1")
        self:InitTextSizeWithLanguage(text,-2)
        text = CS.FindTrans(self.mAttr_2,"AttrValue_1")
        self:InitTextSizeWithLanguage(text,-2)

        local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
        local csLayoutGrid = self.mAttrDiv:GetComponent(typeHorizontalLayoutGroup)
        csLayoutGrid.spacing = 10


    end
end

--region 初始化 --------------------------------------------------------------------------------
function UIMicLightCandle:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mLightCandleBtn, function()
        self:OnLightCandleBtnClick()
    end)

    self:WndNetMsgRecv(LProtoIds.ItemChangeResp, function(pb)
        self:SetCandleInfo()
    end)
end

function UIMicLightCandle:InitText()
    self:SetWndText(self.mTitle, ccClientText(45715))
    self:SetWndText(self.mCloseTip_1, ccClientText(10103))
    self:SetWndText(self.mCloseTip_2, ccClientText(10103))
    self:SetWndText(self.mSubTitle_1, ccClientText(45712))
    self:SetWndText(self.mSubTitle_2, ccClientText(45717))
    self:SetWndButtonText(self.mLightCandleBtn, ccClientText(45716))

    self:SetWndText(self.mAttrName, ccClientText(45712) .. "：")

    self:SetWndText(self.mLightTagText, ccClientText(45731))  --[45731] [已點亮]
end
--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIMicLightCandle