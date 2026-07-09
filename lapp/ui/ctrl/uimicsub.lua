---
--- Created by Administrator.
--- DateTime: 2024/9/18 20:36:50
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMicSub:LWnd
local UIMicSub = LxWndClass("UIMicSub", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMicSub:UIMicSub()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMicSub:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMicSub:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMicSub:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    
    self:InitEvent()
    self:InitMsg()
    self:InitPara()
    self:InitText()
    self:InitCommon()

end

function UIMicSub:OnDrawAttr(list, item, itemdata, index)
    local AttrIcon = CS.FindTrans(item, "AttrIcon")
    local AttrValue = CS.FindTrans(item, "AttrValue")

    local icon = gModelHero:GetAttributeIconById(itemdata.attrRefId)
    self:SetWndEasyImage(AttrIcon, icon)
    local attrStr = gModelHero:GetAttributeValueNoNameByIdAndVal(itemdata.attrRefId, itemdata.attrType, itemdata.attrValue)
    self:SetWndText(AttrValue, attrStr)
end

function UIMicSub:SetMagicEffect(isLight)
    if not self._magicIconEffect then
        self._magicIconEffect = self:CreateWndEffect(self.mMagicIconEffect, self._magicCircleCfg.eff, self._magicCircleCfg.eff, 100, nil, nil, nil, nil, nil, true)
    end

    self._magicIconEffect:SetVisible(isLight)
end

--通过index 1~40 找到对应的控件
function UIMicSub:GetGridTranByIndex(index)
    local tranIndex = self._magicIndex[index]
    if nil == tranIndex then
        printInfoN2("--", "--not--tranIndex--index--" .. index)
        return
    end

    local tranKey = "grid_" .. tranIndex

    local tran = CS.FindTrans(self.mItemRoot, tranKey)
    return tran
end

function UIMicSub:SetMagicBuff()
    --判断有无属性
    local circleData = gModelMagic:GetCircleData(self._magicCircleCfg.refId)
    local isActive = false

    local lightCount = 0
    if circleData then
        isActive = circleData:GetActive()

        local seat = circleData:GetSeat()
        lightCount = #seat
    end

    --取对应buff
    local buffRefId = self._magicCircleCfg.buff
    local buffCfg = gModelMagic:GetBuffCfgByOriginIdAndLv(buffRefId, isActive and circleData:GetLevel() or 0)

    self:SetWndEasyImage(self.mSkillIcon, self._magicCircleCfg.buffIcon)

    self:SetWndText(self.mSkillName, ccLngText(self._magicCircleCfg.buffName))
    self:SetWndText(self.mSkillLv, "Lv." .. buffCfg.lv)

    if buffCfg.lv == 0 then
        CS.ShowObject(self.mSkillLv, false)
    else
        CS.ShowObject(self.mSkillLv, true)
    end

    CS.ShowObject(self.mBuffDes, not isActive)
    CS.ShowObject(self.mSkillLock, not isActive)
    --状态位设置
    self._isActive = isActive
    self._haveNext = false
    self._nextCfg = nil
    local isCanActive = lightCount >= self._cellCount

    local instanceID = self.mBtnUpLev:GetInstanceID()
    self:DestroyWndEffectByKey(instanceID)

    CS.ShowObject(self.mFull, false)

    CS.ShowObject(self.mBtnActive, false)
    CS.ShowObject(self.mBtnUpLev, false)
    local btnTran


    --设置阵法的特效
    self:SetMagicEffect(false)
    self:SetMagicEffect(isActive)
    if not isActive then
        btnTran = self.mBtnActive
        CS.ShowObject(btnTran, true)

        self:SetWndButtonGray(btnTran, not isCanActive)
        self:SetWndButtonText(btnTran, ccClientText(45720))

        if isCanActive then
            self:CreateWndEffect(btnTran, "fx_anniu_03", instanceID, 100)
        end
    else
        self:SetWndButtonText(self.mBtnUpLev, ccClientText(10000))
        CS.ShowObject(self.mBtnUpLev, true)
        local isOpen = gModelFunctionOpen:CheckIsShow(21008001)

        if isOpen then
            --开启了切激活了就要显示下一级
            local nextRefId = buffCfg.next

            if nextRefId == -1 then
                self._haveNext = false
                CS.ShowObject(self.mBtnUpLev, false)
                CS.ShowObject(self.mFull, true)
            else
                CS.ShowObject(self.mBtnUpLev, true)
                CS.ShowObject(self.mFull, false)

                self._haveNext = true
                local nextLv = buffCfg.lv + 1
                self._nextCfg = gModelMagic:GetBuffCfgByOriginIdAndLv(buffRefId, nextLv)
            end

            if gModelMagic:CheckCanUpBuff(buffCfg.refId) then
                self:SetWndButtonGray(self.mBtnUpLev, false)
                self:CreateWndEffect(self.mBtnUpLev, "fx_anniu_03", instanceID, 100)
            end
        else
            self:SetWndButtonGray(self.mBtnUpLev, true)
            CS.ShowObject(self.mBtnUpLev, false)
        end

    end

    self._isCanActive = isCanActive

    --拿到对应的属性
    local count, attrList = gModelMagic:ParseAttr(buffCfg.attr)

    local uiList = self._allHeroAttr

    if not uiList then
        uiList = self:GetUIScroll("UIMicSubAllHeroAttr")

        uiList:Create(self.mAllHeroAttrList, attrList or {}, function(...)
            self:OnDrawAllHeroAttr(...)
        end, UIItemList.SUPER)
    else
        uiList:RefreshList(attrList)
        uiList:DrawAllItems()
    end
    self._allHeroAttr = uiList


end

function UIMicSub:InitText()
    self:SetWndText(self.mTxtReturn, ccClientText(41102))

    local bagText = CS.FindTrans(self.mBagBtn, "Text")
    self:SetWndText(bagText, ccClientText(24811))

    local shopText = CS.FindTrans(self.mShopBtn, "Text")
    self:SetWndText(shopText, ccClientText(45804))

    local giftText = CS.FindTrans(self.mGiftBtn, "Text")
    self:SetWndText(giftText, ccClientText(45805))

    local title_1 = CS.FindTrans(self.mTitle_1, "UIText")
    self:SetWndText(title_1, ccClientText(45712))

    local title_2 = CS.FindTrans(self.mTitle_2, "UIText")
    self:SetWndText(title_2, ccClientText(45713))

    self:SetWndText(self.mBuffDes, ccClientText(45714))

    if self._isEnus then
        self:SetAnchorPos(self.mBuffDes, Vector2.New(-209, -60))
        self:InitTextLineWithLanguage(self.mBuffDes, -10)
    end
end

function UIMicSub:SetCandleAddAttr()
    local resultAttr = {}
    local showAttrData = {}


    --没有的时候要展示所有属性的0  没办法直接获取 这里先缓存一遍 需要展示的属性
    for k, v in pairs(self._cellInfo) do
        local candleRefId = v.itemId

        local count, attrs = gModelMagic:GetCandleAttr(candleRefId, 1, true)

        for i, attr in ipairs(attrs) do
            local attrKey = attr.attrRefId * 10 + attr.attrType

            resultAttr[attrKey] = attr
            resultAttr[attrKey].attrValue = 0
        end
    end


    --计算会增加的值
    local circleData = gModelMagic:GetCircleData(self._magicCircleCfg.refId)

    if circleData then
        local seat = circleData:GetSeat()
        for index, pos in ipairs(seat) do
            local itemInfo = self._cellInfo[pos]
            --获取对应的数值

            if itemInfo then
                local count, attrs = gModelMagic:GetCandleAttr(itemInfo.itemId, itemInfo.itemNum, true)

                for k = 1, count do
                    local attr = attrs[k]
                    local attrKey = attr.attrRefId * 10 + attr.attrType

                    resultAttr[attrKey].attrValue = resultAttr[attrKey].attrValue + attr.attrValue
                end
            else
                printInfoN2("--位置不对--取不到数据", "--pos--server--" .. pos .. "not cell info ")
            end

        end
    end

    --设置属性列表
    for k, v in pairs(resultAttr) do
        table.insert(showAttrData, v)

    end

    table.sort(showAttrData, function(a, b)
        return a.attrRefId < b.attrRefId
    end)

    --创建列表
    local uiList = self._AttrUiList
    if not uiList then
        uiList = self:GetUIScroll("UIMicSubAttrList")

        uiList:Create(self.mAttrList, showAttrData or {}, function(...)
            self:OnDrawAttr(...)
        end, UIItemList.SUPER)
    else
        uiList:RefreshList(showAttrData)
        uiList:DrawAllItems()
    end

    self._AttrUiList = uiList

    uiList:EnableScroll(false, true)
end

--endregion --------------------------------------------------------------------------------------

--region 界面方法 --------------------------------------------------------------------------------
function UIMicSub:CreateGrid()
    local uiList = self._gridList

    local showData = {}
    for i = 1, 49 do
        table.insert(showData, i)
    end

    self._magicIndex = {}

    if not uiList then
        uiList = self:GetUIScroll("WndMagicEntranceList")
        uiList:Create(self.mMagicSubGrid, showData or {}, function(...)
            self:OnDrawGrid(...)
        end, UIItemList.SUPER_GRID)
    else
        uiList:RefreshList(showData)
        uiList:DrawAllItems()
    end
    uiList:EnableScroll(false, false)
    self._gridList = uiList

end

--region 界面初始化 --------------------------------------------------------------------------------
function UIMicSub:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mBtnUpLev, function()
        self:OnBtnUpLevClick()
    end)

    self:SetWndClick(self.mBtnActive, function()
        self:OnBtnUpLevClick()
    end)

    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { refId = 179 })
    end)

    self:SetWndClick(self.mBagBtn, function()
        GF.OpenWnd("UIBags", { subPage = 206 })
    end)

    self:SetWndClick(self.mShopBtn, function()
        GF.OpenWnd("UIDian", { shopId = 2014 })
    end)

    self:SetWndClick(self.mGiftBtn, function()
        GF.OpenWnd("UIMicPotGift")
    end)
end

function UIMicSub:SetMagicGridState()
    self._cellCount, self._cellInfo = gModelMagic:ParseCandleCell(self._magicCircleCfg.cell)

    for k, v in pairs(self._cellInfo) do
        --k 为格子的位置 取到对应的格子
        local gridIndex = self._magicIndex[k]

        if not gridIndex then
            printInfoN2("-----------", "-no grid index--" .. k)
        else
            local gridRootTran = self:GetGridTranByIndex(k)

            --图标设置
            local gridTran = CS.FindTrans(gridRootTran, "Grid")

            local candleIcon = CS.FindTrans(gridTran, "Candle")
            local candleIcon_Gray = CS.FindTrans(gridTran, "Candle_Gray")
            local redPoint = CS.FindTrans(gridTran, "redPoint")
            local tips = CS.FindTrans(gridTran, "Tips")
            local candleEffect = CS.FindTrans(gridTran, "CandleEffect")
            local itemdata = v

            local instanceId = candleEffect:GetInstanceID()
            --
            if not self._candleLightEffect then
                self._candleLightEffect = {}
            end

            --蜡烛的引用
            local candleCfg = gModelMagic:GetMagicRef(itemdata.itemId)

            local circleData = gModelMagic:GetCircleData(self._magicCircleCfg.refId)

            local effectName = candleCfg.eff

            if not self._candleLightEffect[instanceId] then
                self._candleLightEffect[instanceId] = self:CreateWndEffect(candleEffect, effectName, effectName .. instanceId, 100, nil, nil, nil, nil, nil, true)
                self._candleLightEffect[instanceId]:SetVisible(false)
            end


            --图标
            self:SetWndEasyImage(candleIcon, candleCfg.icon)
            self:SetWndEasyImage(candleIcon_Gray, candleCfg.icon)
            local tipsPath = gModelMagic:GetCandleQualityTipsImgPath(candleCfg.quality, candleCfg.num)
            self:SetWndEasyImage(tips, tipsPath, nil, true)

            local isLight = false

            if circleData then
                local seat = circleData:GetSeat()

                for index, pos in ipairs(seat) do
                    if pos == k then
                        isLight = true
                    end
                end
            end

            self:SetWndClick(gridRootTran, function()
                GF.OpenWnd("UIMicLightCandle", {
                    itemdata = itemdata,
                    isLight = isLight,
                    circleCfg = self._magicCircleCfg,
                    seat = k,
                })
            end)

            CS.ShowObject(candleIcon_Gray, not isLight)
            CS.ShowObject(candleIcon, isLight)
            CS.ShowObject(tips, true)

            self._candleLightEffect[instanceId]:SetVisible(isLight)

            local have = gModelItem:GetNumByRefId(itemdata.itemId)
            local isShowRed = have >= itemdata.itemNum
            CS.ShowObject(redPoint, isShowRed and not isLight)

        end
    end
end

function UIMicSub:InitMsg()
    self:WndEventRecv(gModelMagic.EventArgs.LightCandle, function()
        self:SetMagicInfo()
    end)

    self:WndEventRecv(gModelMagic.EventArgs.UpLightCandle, function()
        self:SetMagicInfo()
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:SetMagicInfo()
    end)
end

--endregion --------------------------------------------------------------------------------------

--region event --------------------------------------------------------------------------------
function UIMicSub:OnBtnUpLevClick()


    if self._isActive then
        --打开升级页面
        GF.OpenWnd("UIMicUpCandleLv", {
            magicRefId = self._magicRefId,

        })
    else
        if self._isCanActive then
            --可以激活
            gModelMagic:SendMagicUpLevelReq(self._magicRefId, 0)
        else
            GF.ShowMessage(ccClientText(45721))
        end
    end
end

--设置魔法阵相关
function UIMicSub:SetMagicInfo()
    --标题
    self:SetWndText(self.mMagicName, ccLngText(self._magicCircleCfg.name))

    --设置格子的状态
    self:SetMagicGridState()

    --当前阵法的蜡烛信息
    self:SetCandleAddAttr()

    --设置下方buff的信息若是没有激活则取第一个
    self:SetMagicBuff()


end

function UIMicSub:OnDrawAllHeroAttr(list, item, itemdata, index)
    local Des = CS.FindTrans(item, "Des")
    local str = string.replace(ccClientText(45706), itemdata.attrName, itemdata.attrStr)  --[45706] [全體少女：#a1#]
    if self._haveNext and self._nextCfg then
        local count, attrList = gModelMagic:ParseAttr(self._nextCfg .attr)
        local nextStr = ccClientText(45729)
        for k, v in ipairs(attrList) do
            if v.attrRefId == itemdata.attrRefId and v.attrType == itemdata.attrType then


                local nextValue = v.attrValue - itemdata.attrValue

                if nextValue > 0 then
                    local attrStr = gModelHero:GetAttributeValueNoNameByIdAndVal(v.attrRefId, v.attrType, nextValue)

                    nextStr = string.replace(nextStr, attrStr)
                else
                    nextStr = ""
                end
                break
            end
        end
        str = str .. nextStr
    end

    self:SetWndText(Des, str)
end

function UIMicSub:OnDrawGrid(list, item, itemdata, index)
    item.name = "grid_" .. index
    local grid = CS.FindTrans(item, "Grid")

    if self._abandanIndex[index] then
        CS.ShowObject(grid, false)
    else
        table.insert(self._magicIndex, index)
    end

    if index == self._midIndex then
        CS.ShowObject(self.mMagicIcon, true)
        self:SetWndEasyImage(self.mMagicIcon, self._magicCircleCfg.icon, nil, false)

        self._midTrans = grid
    end

    if index == 49 then
        --最后一个时候 设置魔法阵的坐标
        local pos = Vector3.New(self._midTrans.position.x, self._midTrans.position.y, self._midTrans.position.z)
        self.mMagicIcon.position = pos

        self:SetMagicInfo()
    end
end

function UIMicSub:InitPara()
    self._magicRefId = self:GetWndArg("magicRefId")
    self._magicCircleCfg = gModelMagic:GetMagicCircleRef(self._magicRefId)


    --舍弃的itemPos
    self._abandanIndex = {
        [17] = true,
        [18] = true,
        [19] = true,
        [24] = true,
        [25] = true,
        [26] = true,
        [31] = true,
        [32] = true,
        [33] = true,
    }

    --中间的itempos
    self._midIndex = 25

end

function UIMicSub:InitCommon()
    self:CreateGrid()

end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIMicSub