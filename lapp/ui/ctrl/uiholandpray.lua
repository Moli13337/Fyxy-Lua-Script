---
--- Created by Administrator.
--- DateTime: 2024/3/28 21:36:50
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHoLandPray:LWnd
local UIHoLandPray = LxWndClass("UIHoLandPray", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHoLandPray:UIHoLandPray()
    self._useItemNum = 0
    self._haveNum = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHoLandPray:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHoLandPray:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHoLandPray:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isVie = gLGameLanguage:IsVieVersion()

    self:AddEventMsg()
    self:OnUpdatePanel()

    self:RefreshForeignShow()
end

function UIHoLandPray:OnDrawAttrCell(list, item, itemdata, itempos)
    local AttrIcon = self:FindWndTrans(item, "AttrIcon")
    local AttrName = self:FindWndTrans(item, "AttrName")
    local AttrValue = self:FindWndTrans(item, "AttrValue")
    local numType, refId, value = itemdata.type, itemdata.refId, itemdata.value
    if AttrIcon then
        local icon = gModelHero:GetAttributeIconById(refId)
        self:SetWndEasyImage(AttrIcon, icon)
    end

    if AttrName then
        local name = gModelHero:GetAttributeNameById(refId)
        self:SetWndText(AttrName, name)
    end

    if AttrValue then
        local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, numType, value)
        valueStr = "+" .. valueStr
        self:SetWndText(AttrValue, valueStr)
    end
end
function UIHoLandPray:OnUpdateRedPoint(isShow)
    local RedPoint = self:FindWndTrans(self.mUpLvBtn, "redPoint")
    CS.ShowObject(RedPoint, isShow)
end
function UIHoLandPray:AddEvent()
    local useNum = self._useItemNum
    if useNum < self:GetUseMaxNum() then
        self._useItemNum = self._useItemNum + 1
        self.isupdate = true
        self:SetWndText(self.mTxtValue, self._useItemNum .. "")
        self:UpdateSliderValue()
    else
        -- GF.ShowMessage(ccClientText(40508))
    end
end
--刷新Slider
function UIHoLandPray:UpdateSliderValue()
    self.mSliderUse.value = (self._useItemNum / math.max(self:GetUseMaxNum(), 1))
end

function UIHoLandPray:SubEvent()
    local curNum = self._useItemNum - 1
    if curNum > 0 then
        self._useItemNum = curNum
        self.isupdate = true
        self:SetWndText(self.mTxtValue, self._useItemNum .. "")
        self:UpdateSliderValue()
    end
end

function UIHoLandPray:OnUpdatePanel()
    self:UpdateAttrs()
    local ref = GameTable.HolyLandLvRef[gModelHolyLand.holyLandInfo.level]
    local maxCount = ref and ref.useLimit or 0
    local residueNum = maxCount - gModelHolyLand.holyLandInfo.flowerUseCnt
    self.mSlider.value = residueNum / maxCount
    self:SetWndText(self.mTxtPress, residueNum .. "/" .. maxCount)
    local itemRef = GameTable.PlayerItemRef[tonumber(GameTable.HolyLandConfigRef.useItem)]
    self:SetWndText(self.mTxtDesc, ccClientText(40512))

    local baseClass = self._commonIconItem
    if not baseClass then
        baseClass = CommonIcon:New()
        self._commonIconItem = baseClass
        baseClass:Create(self.mCommonUI)
    end
    baseClass:SetCommonReward(1, itemRef.refId, 1)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    local haveNum = gModelItem:GetNumByRefId(itemRef.refId)
    self._haveNum = haveNum
    -- local color = haveNum>0 and "#139057" or "#FB1E12"
    -- color = string.format("<color=%s>%s</color>",color,haveNum)
    local str = string.replace(ccClientText(24822), LUtil.NumberCoversion(haveNum))
    self:SetWndText(self.mItemValue, str)
    self._useItemNum = self:GetUseMaxNum()
    self:SetWndText(self.mTxtValue, self._useItemNum .. "")
    self:UpdateSliderValue()
    local ref = GameTable.HolyLandLvRef[gModelHolyLand.holyLandInfo.level]
    if ref and ref.lvNext <= 0 and gModelHolyLand.holyLandInfo.flowerUseCnt <= 0 then
        self:SetWndButtonGray(self.mUpLvBtn, true)
        self:SetWndButtonText(self.mUpLvBtn, ccClientText(40511))
    end

    self:SetWndClick(self.mCommonUI, function()
        local data = { itemId = itemRef.refId, itemType = 1, itemNum = haveNum }
        gModelGeneral:ShowCommonItemTipWnd(data)
    end)
end
function UIHoLandPray:AddEventMsg()
    if PRODUCT_G_VER ~= 0 then
        -- 提审
        self:SetWndEasyImage(self.mImageIcon, "holyhand_bg_21", nil, nil, true)
    end
    self:WndEventRecv(EventNames.HOLYLAND_UPDATE, function()
        self:OnUpdatePanel()
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:OnUpdatePanel()
    end)
    self:SetWndText(self.mTxtTitle, ccClientText(40505))
    self:SetWndButtonText(self.mUpLvBtn, ccClientText(40503))
    self:SetWndText(self.mTxtAttrTitle, ccClientText(40504))
    self:SetWndClick(self.mCloseBtn, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mFullBg, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mAddBtn, function()
        self:AddEvent()
    end)
    self:SetWndClick(self.mSubBtn, function()
        self:SubEvent()
    end)
    self:SetWndClick(self.mMaxBtn, function()
        if self:GetUseMaxNum() <= 0 then
            return
        end
        self._useItemNum = self:GetUseMaxNum()
        self:SetWndText(self.mTxtValue, self._useItemNum .. "")
        self:UpdateSliderValue()
    end)
    LxUiHelper.SetProgress_ValueChanged(self.mSliderUse.transform, function()
        local value = self.mSliderUse.value
        if self.isupdate then
            self.isupdate = false
            return
        end
        self:UpdatePropValue(value)
    end)
    self:SetWndClick(self.mUpLvBtn, function()
        if self._useItemNum > self._haveNum or (gModelHolyLand.holyLandInfo.flowerUseCnt > 0 and self._haveNum == 0) then
            gModelGeneral:OpenGetWayWnd({ itemId = tonumber(GameTable.HolyLandConfigRef.useItem) })
            GF.ShowMessage(ccClientText(18342))
            return
        end
        if gModelHolyLand.holyLandInfo.flowerUseCnt <= 0 then
            local ref = GameTable.HolyLandLvRef[gModelHolyLand.holyLandInfo.level]
            if ref and ref.lvNext <= 0 then
                GF.ShowMessage(ccClientText(40513))
            else
                GF.ShowMessage(ccClientText(40508))
            end
        elseif self._useItemNum > 0 then
            local data = { refId = tonumber(GameTable.HolyLandConfigRef.useItem), num = self._useItemNum }
            gModelItem:OnItemUseReq({ data })
        elseif self._useItemNum == 0 then
            -- GF.ShowMessage("請選擇祈願次數")
        end
    end)

    self:RegisterRedPointFunc(ModelRedPoint.HOLY_LAND_PRAY_USEBTN, function(isShow)
        self:OnUpdateRedPoint(isShow)
    end)
end

function UIHoLandPray:GetUseMaxNum()
    return math.min(gModelHolyLand.holyLandInfo.flowerUseCnt, self._haveNum)
end

function UIHoLandPray:RefreshForeignShow()
    if self._isVie then
        LxUiHelper.SetSizeWithCurAnchor(self.mLeft, 0,380)
        LxUiHelper.SetSizeWithCurAnchor(self.mRight, 0,380)
    end
end
function UIHoLandPray:UpdateAttrs()
    local list = self:GetAttrList() or {}
    local uiAttrList = self._uiAttrList
    if not uiAttrList then
        uiAttrList = self:GetUIScroll("HolyLandPrayList")
        self._uiAttrList = uiAttrList
        uiAttrList:Create(self.mListAttrs, list, function(...)
            self:OnDrawAttrCell(...)
        end)
    else
        self._uiAttrList:RefreshList(list)
    end
end
function UIHoLandPray:UpdatePropValue(sliderValue)
    if not sliderValue then
        return
    end
    local max = self:GetUseMaxNum()
    local val = math.ceil(sliderValue * max)
    self._useItemNum = (val == 0 and gModelHolyLand.holyLandInfo.flowerUseCnt > 0) and 1 or val
    self:SetWndText(self.mTxtValue, self._useItemNum)
end
function UIHoLandPray:GetAttrList()
    local useCount = gModelHolyLand.holyLandInfo.flowerUseCnt
    local itemRef = GameTable.PlayerItemRef[tonumber(GameTable.HolyLandConfigRef.useItem)]
    local ref = GameTable.HolyLandLvRef[gModelHolyLand.holyLandInfo.level]
    local maxCount = ref and ref.useLimit or 0
    useCount = maxCount - useCount
    local list = LxDataHelper.ParseAttrList(itemRef.typeDate)
    for _, value in ipairs(list) do
        value.value = value.value * useCount
    end
    return list
end

------------------------------------------------------------------
return UIHoLandPray