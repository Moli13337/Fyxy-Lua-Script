---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOrdinTip:LWnd
local UIOrdinTip = LxWndClass("UIOrdinTip", LWnd)
local typeUIToggle = typeof(UnityEngine.UI.Toggle)

UIOrdinTip.STYLE_1 = 1
UIOrdinTip.STYLE_2 = 2
UIOrdinTip.STYLE_3 = 3
UIOrdinTip.STYLE_4 = 4
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOrdinTip:UIOrdinTip()
    ---@type table<number,CommonIcon>
    self._uicommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOrdinTip:OnWndClose()
    if self._uicommonList then
        local list = self._uicommonList
        for k, v in pairs(list) do
            v:Destroy()
            list[k] = nil
        end
        self._uicommonList = nil
    end

    gLGameUI:CloseLoadMask()

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOrdinTip:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndMode(LWnd.WND_MODE_NONE)

    gLGameUI:OpenLoadMask()

    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOrdinTip:OnStart()
    LWnd.OnStart(self)

    gLGameUI:CloseLoadMask()

    self:InitUI()

    self._isSEA = gLGameLanguage:IsSEALngRegion()
    self._isEnus = gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVieVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:SetWndText(self.mDayNotShowTxt, ccClientText(10155))
    self:InitData()
    self:ShowTypeWndByData()
    self:InitEvent()
    self:RefreshPrivilegeRoot()
end

function UIOrdinTip:SetTitle3()
    local titleSize = GameTable.UIWindowRef.titleSize or 26
    local defaultSize = GameTable.UIWindowRef.defaultSize or 20
    self:DisposeXUIText(self.mTitle3, self._title, titleSize)
    self:DisposeXUIText(self.mContent3, self._text, defaultSize)
    if not self._isEnus then
        self:InitTextLineWithLanguage(self.mContent3, -30)
    end
end

function UIOrdinTip:ShowTypeTwelve()
    local styleIndex = UIOrdinTip.STYLE_3
    self:SetWndStyleStateByIndex(styleIndex)
    self:SetTitle3()
    self:SetBtnByStyleIndex(styleIndex)
    self:SetDayNoShow3()
    self:SetOtherTip()
end
-------------------------------------UIListEasy-------------------------------------
function UIOrdinTip:DisposeXUIText(trans, msg, size, color)
    local xuiTextTrans = self:FindWndText(trans)
    self:SetXUITextText(xuiTextTrans, msg)
    if size then
        self:SetXUITextFontSize(xuiTextTrans, size)
    end
    if color then
        self:SetXUITextColor(xuiTextTrans, color)
    end
end

function UIOrdinTip:IsAutoLangFont()
    --local refId = self:GetWndArg("refId")
    --if refId == 40019 then
    --	return false
    --end

    return true
end

function UIOrdinTip:ShowTypeWndByData()
    local wndRefId = self._wndRefId
    --wndRefId = 50201
    --LogError("wndRefId=  "..wndRefId)
    local wndData = GameTable.UIWindowAttRef[wndRefId]

    if not wndData then
        LogError("默认窗口类型为10001，没有配置该窗口的类型的数据:" .. wndRefId)
        wndData = GameTable.UIWindowAttRef[10001]
    end
    self._wndData = wndData

    local wndType = tonumber(wndData.windowType)
    -- wndType = 2
    self._wndType = wndType


    if PRODUCT_G_VER ~= 0 then
        -- 提审
        if self._isSEA then
            CS.ShowObject(self.mRoleIcon, false)
        end
        if gLGameLanguage:IsKoreaRegion() then
            if wndType == 12 then
                CS.ShowObject(self.mRoleIcon, false)
            end
        end
    end

    local showCloseBtn = tonumber(wndData.closeBtn)
    local closeBtn
    if wndType == 13 then
        closeBtn = self.mCloseBtn4
    elseif wndType % 2 == 1 then
        closeBtn = self.mCloseBtn1
    else
        closeBtn = self.mCloseBtn2
    end
    self._showCloseBtn = showCloseBtn == 1
    CS.ShowObject(closeBtn, self._showCloseBtn)




    -- 点击空白处是否退出
    local touchAnyClose = wndData.touchAnyClose
    self._touchClose = tonumber(touchAnyClose)

    -- 今日不再提醒块是否显示
    local todayTipStr = string.split(wndData.todayTip, "=")
    local todayTip = tonumber(todayTipStr[1])
    -- todayTip = 1
    local title = ccLngText(wndData.title)

    local btnText = ccLngText(wndData.btnTxt)
    local strs = string.split(btnText, "|")

    local btnPng = wndData.btnPng
    local pngStr = string.split(btnPng, "|")

    --是否在按钮上方显示道具消耗
    local showRes = wndData.showRes
    local showResData
    if not string.isempty(showRes) and showRes ~= 0 and showRes ~= "0" then
        local showResList = string.split(showRes, '|')
        local showResId = tonumber(showResList[1])
        showResData = gModelGeneral:GetCommonTipsConsumeItemListByShowResId(showResId, self._consumeItemData)
    end

    local startCountDowns = LxDataHelper.ParseNumber_Sign(self._wndData.startCountDown, "|")
    local countDowns = LxDataHelper.ParseNumber_Sign(self._wndData.countdown, '|')

    self._countDownDataList = {}

    local bNeedTimer = false
    for k = 1, 2 do
        local buttonCd = startCountDowns[k] or 0
        local tipsCd = countDowns[k] or 0
        if buttonCd > 0 then
            self._btnClickList[k] = false
        end
        if buttonCd > 0 or tipsCd > 0 then
            self._countDownDataList[k] = { buttonCd = buttonCd, buttonTime = buttonCd, isButtonOk = buttonCd <= 0, tipsCd = tipsCd, tipsTime = tipsCd }
            bNeedTimer = true
        end
    end

    self._todayTip = todayTip
    self._todayDefaultSel = tonumber(todayTipStr[2]) == 1
    if self._todayDefaultSel then
        local csToggle = self.mToggle:GetComponent(typeUIToggle)
        if csToggle then
            csToggle.isOn = self._todayDefaultSel
            self._isNotAlert = self._todayDefaultSel
        end
    end

    self._title = title

    self._btnStrs = strs
    self._btnImgPaths = pngStr
    self._showResData = showResData
    self._countDowns = countDowns

    local otherTipStr = string.split(wndData.otherTip, "=")
    --self._otherTip = self._wndData.otherTip==1
    self._otherTip = tonumber(otherTipStr[1]) == 1
    self._otherDefaultSel = tonumber(otherTipStr[2]) == 1
    self._otherTipText = ccLngText(self._wndData.otherTipTxt)

    local text = ccLngText(wndData.text)
    local para = self._contentPara
    if self._otherTip and self._extraChoice then
        if self._useOther then
            para = self._extraChoice.para
        end
    end
    if para then
        text = string.replace(text, unpack(para))
    end
    self._text = text
    self._text2 = ccLngText(wndData.text2)

    local setFunc = self._typeSetFunc[wndType]
    if setFunc then
        setFunc()
    end

    if bNeedTimer then
        self:TimerStart(self._countDownKey, 1, false, -1)
    end

    if self._isCountDownPara then
        self:TimerStart(self._countDownKey3, 1, false, -1)
    end
end

-------------------------------------UIListEasy-------------------------------------
function UIOrdinTip:InitScrollView()
    local uiList = self._uiList
    if not uiList then
        local isEnable = false
        local list
        if self._rewardNum < 5 then
            isEnable = false
            list = self.mLimitList
        else
            isEnable = true
            list = self.mRewardList
        end
        uiList = UIListEasy:New()
        uiList:Create(self, list)
        uiList:EnableScroll(isEnable, true)
        uiList:SetFuncOnItemDraw(function(...)
            self:uilist_OnDrad(...)
        end)
        self._uiList = uiList
    end
    uiList:RemoveAll()
    local rewardList = self._listData or {}
    for k, v in ipairs(rewardList) do
        uiList:AddData(k, v)
    end
    uiList:RefreshList()
end

function UIOrdinTip:OnTimer(key)
    if key == self._countDownKey then
        self:SetCountDown()
    elseif key == self._countDownKey2 then
        self:SetCountDown2()
    elseif key == self._showCDKey then
        self:ShowCDDiv()
    elseif key == self._countDownKey3 then
        local para = tonumber(self._contentPara[1])
        para = para - 1
        if para < 0 then
            para = 0
            self:TimerStop(self._countDownKey3)
        end
        self._contentPara[1] = para
        self:RefreshText()
    end
end

function UIOrdinTip:SetDayNoShow2()
    if self._todayTip ~= 0 then
        CS.ShowObject(self.mDayNotShow, true)
        self.mDayNotShow.localPosition = Vector3(0, -130, 0)
    else
        CS.ShowObject(self.mDayNotShow, false)
    end
end

function UIOrdinTip:OnClickToggleFunc(btnClick)
    local csToggle = self.mToggle:GetComponent(typeUIToggle)
    if (csToggle) then
        local isOn = csToggle.isOn
        if btnClick then
            isOn = not isOn
            csToggle.isOn = isOn
        end
        self._isNotAlert = isOn
    end
end

function UIOrdinTip:SetWndStyleStateByIndex(styleIndex)
    CS.ShowObject(self.mWndStyle1, styleIndex == UIOrdinTip.STYLE_1)
    CS.ShowObject(self.mWndStyle2, styleIndex == UIOrdinTip.STYLE_2)
    CS.ShowObject(self.mWndStyle3, styleIndex == UIOrdinTip.STYLE_3)
    CS.ShowObject(self.mWndStyle4, styleIndex == UIOrdinTip.STYLE_4)
end

function UIOrdinTip:SetWndRefId(wndRefId)
    self._wndRefId = wndRefId
end

function UIOrdinTip:OnClickCloseButton()
    if self._closeFunc then
        self._closeFunc()
    end
    self:WndClose()
end

function UIOrdinTip:OnClickButton(index, isNeedCheckShift)
    local countDownData = self._countDownDataList[index]
    if countDownData and not countDownData.isButtonOk and not self._btnClickList[index] then
        local time = countDownData.buttonTime
        if time > 0 then
            local str = string.replace(ccClientText(10114), time)
            GF.ShowMessage(str)
            return
        end
    end

    --- 2024/7/3：防止点击过快
    if self._clickDelayTime and Time.time - self._clickDelayTime < 1 then
        return
    end

    self._clickDelayTime = Time.time

    local isConfirm = false
    local wndType = self._wndType
    if wndType == 1 or wndType == 2 or wndType == 12 or wndType == 13 then
        if index == 2 then
            isConfirm = true
        end

        if self._wndRefId == 170031 then
            isConfirm = true
        end
    elseif wndType == 3 or wndType == 4 then
        isConfirm = true
        if self._wndRefId == 100027 and index == 1 then
            isConfirm = false
        end
    end
    local func = self._leftFunc
    if isConfirm then
        func = self._confirmFunc
        if self._otherTip and self._extraChoice then
            if self._useOther then
                func = self._extraChoice.func
            end
        end

        if self._isNotAlert then
            local refId = self._wndRefId
            local sid = self._sid
            local alertId
            if self._todayTip and self._todayTip == 2 then
                --todayTip为2， 同refId，不同sid, 今日不再提示不共用
                if not sid then
                    LogError("sid is a nil")
                    return
                end
                alertId = tonumber(refId .. sid)
            else
                --todayTip为1， 同refId，今日不再提示共用
                alertId = tonumber(refId)
            end

            if gLGameLanguage:IsJapanRegion() and self._isDiamond then
                --日本，召唤用到钻石时，同一个弹窗id，再弹出1次，直到再次被勾选
                alertId = tonumber(alertId .. ModelItem.ITEM_DIAMOND)
            end

            gModelGeneral:SetAlertId(alertId)
        end
    end

    local closeFunc = self._closeFunc

    if index == 1 then
        if closeFunc and func ~= closeFunc then
            ---防止重复调用
            closeFunc()
        end
    end

    if func then

        if isNeedCheckShift then
            self:ShowCheckMasonryNumTips(func, closeFunc)
            return
        end

        func()
    end

    --if not self._notClose then
    self:WndClose()
    --end

    --FireEvent(EventNames.ON_COMMON_TIP_OVER)
end

function UIOrdinTip:SetBtns(root)
    local haveStartNum = false

    local btnTransList = {}
    self._btnTransList = btnTransList
    local btnAutoTextTransList = {}
    self._btnAutoTextTransList = btnAutoTextTransList

    local childCount = root.childCount
    for idx = 1, childCount do
        local btnItem = root:GetChild(idx - 1)
        CS.ShowObject(btnItem, false)
    end

    local addLine
    for i = 1, 2 do
        --local btnText= (i==2 and self._surBtnFreeStr) or self._btnStrs[i]
        local btnText = self._btnStrs[i]
        local btnImg = self._btnImgPaths[i]
        local active = false

        if not string.isempty(btnImg) then
            local btn = self:FindWndTrans(root, btnImg)
            if btn then
                CS.ShowObject(btn, true)
                -- 调整按钮位置
                btn:SetSiblingIndex(i)
                btnTransList[i] = btn
                local autoTextTrans = self:FindWndTrans(btn, "AutoText")
                btnAutoTextTransList[i] = autoTextTrans

                haveStartNum = false
                if btnText then
                    active = true
                    local countDownData = self._countDownDataList[i]
                    local text = btnText
                    if countDownData and countDownData.buttonCd > 0 then
                        self:SetWndButtonGray(btn, true)
                        text = string.format("%s(%ss)", btnText, countDownData.buttonCd)
                        self._btnClickList[i] = false
                        haveStartNum = true
                    end

                    --显示道具消耗
                    local consumeText = self:FindWndTrans(btn, "ConsumeText")
                    local isNeedCheckShift = false
                    if (self._surBtnFreeStr) then
                        local consumeItemIcon = self:FindWndTrans(consumeText, 'ConsumeItemIcon')
                        self:SetAnchorPos(consumeText, Vector2.New(0, 45.5))
                        self:SetWndText(consumeText, self._surBtnFreeStr)
                        CS.ShowObject(consumeItemIcon, false)
                    elseif self._showResData ~= nil then
                        local consumeItemId = self._showResData.consumeItemId
                        local consumeItemNum = self._showResData.consumeItemNum or 0
                        if consumeText then
                            local consumeItemIcon = self:FindWndTrans(consumeText, 'ConsumeItemIcon')

                            local haveItemNum = gModelItem:GetNumByRefId(consumeItemId)
                            local numStrColor = haveItemNum >= consumeItemNum and "green" or "red"
                            --local numStrColor	  = haveItemNum >= consumeItemNum and "red" or "green"
                            local haveItemNumStr = LUtil.NumberCoversion(haveItemNum)
                            local consumeItemNumStr = LUtil.NumberCoversion(consumeItemNum)
                            local consumeStr = LUtil.FormatColorStr(haveItemNumStr, numStrColor)
                            consumeStr = string.format("%s/%s", consumeStr, consumeItemNumStr)
                            self:SetWndText(consumeText, consumeStr)

                            local itemIcon = gModelItem:GetItemImgByRefId(consumeItemId)
                            if LxUiHelper.IsImgPathValid(itemIcon) then
                                self:SetWndEasyImage(consumeItemIcon, itemIcon)
                                CS.ShowObject(consumeItemIcon, true)
                            end
                        end

                        if consumeItemId == ModelItem.ITEM_DIAMOND
                                and gLGameLanguage:IsJapanRegion() then
                            --local haveItemNumTruth = gModelItem:GetNumByRefId(consumeItemId, true)
                            --isNeedCheckShift = haveItemNumTruth < consumeItemNum
                            isNeedCheckShift=false
                        end
                    end

                    self:SetWndButtonText(btn, text)
                    local index = i
                    self:SetWndClick(btn, function()
                        self:OnClickButton(index, isNeedCheckShift)
                    end)
                    if countDownData and countDownData.tipsCd > 0 then
                        CS.ShowObject(autoTextTrans, not haveStartNum)
                        local text = string.replace(ccClientText(10115), countDownData.tipsCd, btnText)
                        local str = string.gsub(text, " ", "")
                        self:SetWndText(autoTextTrans, str)
                    end
                end
            end
        end

    end
end

function UIOrdinTip:SetCountDown()
    local btnTransList = self._btnTransList
    local btnAutoTextTransList = self._btnAutoTextTransList

    local btnStrs = self._btnStrs

    local countDownDataList = self._countDownDataList
    local bStop = true
    for i = 1, 2 do
        local btnText = btnStrs[i]
        local countDownData = countDownDataList[i]
        if countDownData and not countDownData.isAllOk and btnText then
            local btn = btnTransList[i]
            local autoTextTrans = btnAutoTextTransList[i]

            bStop = false

            if not countDownData.isButtonOk then
                local text
                local timeLeft = countDownData.buttonTime - 1
                countDownData.buttonTime = timeLeft
                if timeLeft > 0 then
                    text = string.format("%s(%ss)", btnText, timeLeft)
                else
                    text = btnText

                    self._btnClickList[i] = true
                    self:SetWndButtonGray(btn, false)
                    countDownData.isButtonOk = true
                    if countDownData.tipsTime > 0 then
                        CS.ShowObject(autoTextTrans, true)
                    else
                        countDownData.isAllOk = true
                    end
                end
                self:SetWndButtonText(btn, text)
            else
                local timeLeft = countDownData.tipsTime - 1
                countDownData.tipsTime = timeLeft
                if timeLeft > 0 then
                    local autoText = string.replace(ccClientText(10115), timeLeft, btnText)
                    local str = string.gsub(autoText, " ", "")
                    self:SetWndText(autoTextTrans, str)
                else
                    -----引导监听
                    --local btnPath = LxUiHelper.GetRelativePath(self:GetWndName(),btn)
                    --FireEvent(EventNames.AUTO_CLICK_EVENT,btnPath)
                    CS.ShowObject(autoTextTrans, false)
                    countDownData.isAllOk = true
                    self:OnClickButton(i)
                end
            end
        end
    end

    if bStop then
        self:TimerStop(self._countDownKey)
    end
end

function UIOrdinTip:SetBtnByStyleIndex(styleIndex)
    local btnLayout
    local btnItemLayout
    local descLayout
    if styleIndex == UIOrdinTip.STYLE_1 then
        btnLayout = self.mBtnLayout_1
        btnItemLayout = self.mBtnLayout_1_item
        descLayout = self.mDescLayout_1
    elseif styleIndex == UIOrdinTip.STYLE_2 then
        btnLayout = self.mBtnLayout_2
        btnItemLayout = self.mBtnLayout_2_item
    elseif styleIndex == UIOrdinTip.STYLE_3 then
        btnLayout = self.mBtnLayout_3
    else
        btnLayout = self.mBtnLayout_4
        descLayout = self.mDescLayout_4
    end

    local isShowDescLayout = not self:IsCountDownTimeEnd()
    local isShowItemConsume = self._showResData ~= nil and btnItemLayout ~= nil and not isShowDescLayout
    isShowItemConsume = self._surBtnFreeStr and true or isShowItemConsume
    local isShowBtn = not isShowItemConsume and not isShowDescLayout
    if btnLayout then
        CS.ShowObject(btnLayout, isShowBtn)
    end

    if btnItemLayout then
        CS.ShowObject(btnItemLayout, isShowItemConsume)
    end

    if descLayout then
        CS.ShowObject(descLayout, isShowDescLayout)
    end

    if isShowDescLayout then
        self:RefreshDescLayout(descLayout)
    elseif isShowBtn then
        self:SetBtns(btnLayout)
    else
        self:SetBtns(btnItemLayout)
    end
end

function UIOrdinTip:IsCountDownTimeEnd()
    local countDownTimeValue = self._countDownTimeValue
    if not countDownTimeValue then
        return true
    end

    local nextValue = countDownTimeValue - GetTimestamp()
    return nextValue <= 0
end

function UIOrdinTip:uilist_OnDrad(list, item, itemdata, itempos)
    local itype = itemdata.itype or itemdata.type
    if itype == nil then
        itype = itemdata.itemType
    end

    local refId = itemdata.heroId or tonumber(itemdata.itemId or itemdata.refId)
    local num = itemdata.count or itemdata.itemNum

    local instanceId = item:GetInstanceID()
    local iconRootTrans = CS.FindTrans(item, "CommonUI/IconRoot")
    local uicommonlist = self._uicommonList
    local baseClass = uicommonlist[instanceId]
    if not baseClass then
        baseClass = CommonIcon:New()
        uicommonlist[instanceId] = baseClass
        baseClass:Create(CS.FindTrans(iconRootTrans, "Icon"))
    end
    if itype == LItemTypeConst.TYPE_HERO and itemdata.heroId then
        baseClass:SetHeroPlayer(itemdata.heroId)
    elseif itype == LItemTypeConst.TYPE_HERO and itemdata.heroData then
        baseClass:SetHeroDataSet(itemdata.heroData)
    elseif itype == LItemTypeConst.TYPE_PET then
        baseClass:SetPetDataSet(refId)
    else
        baseClass:SetCommonReward(itype, refId, num)
    end
    if itemdata.hideNum then
        baseClass:EnableShowNum(false)
    else
        baseClass:EnableShowNum(true)
    end

    baseClass:DoApply()

    self:SetWndClick(iconRootTrans, function()
        if itype == LItemTypeConst.TYPE_ITEM then
            gModelGeneral:OpenItemInfoTip(refId, num)

        elseif itype == LItemTypeConst.TYPE_HERO then
            local heroData = itemdata.heroData
            if itemdata.heroId then
                local heroRefId = gModelHero:GetRefIdById(itemdata.heroId)
                gModelGeneral:OpenHeroSimpleTip(heroRefId)
            elseif heroData then
                local id = heroData.id
                local lv = heroData.level
                local serverData = gModelHero:GetHeroServerDataById(id)
                if serverData then
                    lv = serverData.lv
                end
                local data = {
                    id = id,
                    refId = heroData.refId,
                    level = lv,
                    star = heroData.star,
                    grade = heroData.grade,
                    fightPower = heroData.fightPower,
                    isResonance = heroData.isResonance,
                    skin = heroData.skin,
                }
                gModelHero:ReqShowHeroTip("", data)
            end
        elseif itype == LItemTypeConst.TYPE_EQUIP then
            gModelGeneral:OpenEquipInfoTip(refId, nil, 1, true)
        elseif itype == LItemTypeConst.TYPE_PET then
            GF.OpenWnd("UIPeView", { refId = refId, playerId = gModelPlayer:GetPlayerId() })

        elseif itype == LItemTypeConst.TYPE_RUNE then
            local runeId = itemdata.id
            local serverData = gModelRune:GetServerDataById(runeId)
            if serverData then
                local data = { runeData = serverData }
                gModelGeneral:OpenRuneInfoTip(data)
            end
        end
    end)
    self:SetIconClickScale(iconRootTrans, true)

    local uiNameTrans = CS.FindTrans(iconRootTrans, "UIName")
    local uiNameText = uiNameTrans and self:FindWndText(uiNameTrans) or nil
    if uiNameText then
        local itemname, itemcolor = baseClass:GetName()
        self:SetXUITextText(uiNameText, itemname or "")
        if itemcolor then
            self:SetXUITextColor(uiNameText, itemcolor)
        end
        --self:InitTextModeWithLanguage(uiNameTrans)

        self:InitTextShowWithLanguage(uiNameText)
    end
end

function UIOrdinTip:SetDayNoShow1()
    if self._todayTip ~= 0 then
        CS.ShowObject(self.mDayNotShow, true)
        self.mDayNotShow.localPosition = Vector3(0, -22, 0)
        self.mContent1.localPosition = Vector3(0, -141, 0)
    else
        CS.ShowObject(self.mDayNotShow, false)
        self.mContent1.localPosition = Vector3(0, -153, 0)
    end
end

function UIOrdinTip:SetCountDown2()
    local countDownTimeValue = self._countDownTimeValue
    local nextValue = countDownTimeValue - GetTimestamp()
    if nextValue <= 0 then
        self:TimerStop(self._countDownKey2)
        local setFunc = self._typeSetFunc[self._wndType]
        if setFunc then
            setFunc()
        end

        if self._countDownFunc then
            self._countDownFunc()
        end

        return
    end

    local contentStr = self._text2
    if not string.isempty(contentStr) then
        local timeStr = LUtil.FormatInTheDayTime2(nextValue)
        timeStr = string.replace(contentStr, timeStr)
        if CS.IsValidObject(self._descContentTrans) then
            self:SetWndText(self._descContentTrans, timeStr)
        end
    end
end

function UIOrdinTip:SetDayNoShow3()
    if self._todayTip ~= 0 then
        CS.ShowObject(self.mDayNotShow, true)
        self.mDayNotShow.localPosition = Vector3(0, -232, 0)
        self.mContent3.localPosition = Vector3(9, 36, 0)
    else
        CS.ShowObject(self.mDayNotShow, false)
        self.mContent3.localPosition = Vector3(9, 18, 0)
    end
end

function UIOrdinTip:ShowCDDiv()
    local showCDTime = self._showCDTime
    local showRoot = showCDTime and showCDTime > 0
    CS.ShowObject(self.mShowCDDiv,showRoot)
    if not showRoot then
        self:TimerStop(self._showCDKey)
        return
    end

    local curTime = GetTimestamp()
    local timeLeft = showCDTime - curTime
    local inCD = timeLeft > 0
    if inCD then
        local timeStr = string.replace(ccClientText(11637),LUtil.GetFormatCDTime(timeLeft))
        self:SetWndText(self.mShowCDTime,timeStr)
    end
end

function UIOrdinTip:SetListData(data)
    data = data or {}
    self._listData = data
    self._rewardNum = #data
end

function UIOrdinTip:ShowTypeOne()
    local styleIndex = UIOrdinTip.STYLE_1
    self:SetWndStyleStateByIndex(styleIndex)
    self:SetTitle1()
    self:SetBtnByStyleIndex(styleIndex)

    self:SetDayNoShow1()
    self:SetOtherTip()
end

function UIOrdinTip:SetTitle1()
    local titleSize = GameTable.UIWindowRef.titleSize or 30
    local defaultSize = GameTable.UIWindowRef.defaultSize or 24
    self:DisposeXUIText(self.mTitle1, self._title, titleSize)
    self:DisposeXUIText(self.mContent1, self._text, defaultSize)
    self:InitTextLineWithLanguage(self.mTitle1, -30)
    if not self._isEnus then
        self:InitTextLineWithLanguage(self.mContent1, -30)
    end
    if self._isVie then
        self:InitTextLineWithLanguage(self.mContent1, 0)
    end
end

function UIOrdinTip:SetDayNoShow4()
    CS.ShowObject(self.mDayNotShow, false)
end

function UIOrdinTip:RefreshPrivilegeRoot()
    local privilegeStatus = self:GetWndArg("privilegeStatus") or 0
    local isPrivilegeShow = privilegeStatus == 1
    if isPrivilegeShow and gModelNormalActivity:CheckHasAdPrivilegeActive() then
        isPrivilegeShow = false
    end
    CS.ShowObject(self.mPrivilegeRoot,isPrivilegeShow)
    CS.ShowObject(self.mPrivilegeDiv,isPrivilegeShow)
    if not isPrivilegeShow then return end

    local jumpCB = self:GetWndArg("jumpCB")

    self:SetWndButtonText(self.mBtnGotoBuy,ccClientText(47102))
    self:SetWndClick(self.mBtnGotoBuy,function()
        gModelFunctionOpen:Jump(10401101)
        if jumpCB then
            jumpCB()
        end
        self:WndClose()
    end)
end

function UIOrdinTip:InitEvent()
    if self._touchClose == 1 then
        self:SetWndClick(self.mMaskCell, function()
            self:OnClickCloseButton()
        end)
    end
    LxUiHelper.SetToggle_ValueChanged(self.mToggle, function()
        self:OnClickToggleFunc()
    end)
    self:SetWndClick(self.mCloseBtn1, function()
        self:OnClickCloseButton()
    end)
    self:SetWndClick(self.mCloseBtn2, function()
        self:OnClickCloseButton()
    end)
    self:SetWndClick(self.mCloseBtn4, function()
        self:OnClickCloseButton()
    end)
    self:SetWndClick(self.mToggleBtn, function()
        self:OnClickToggleFunc(true)
    end)
end

function UIOrdinTip:ShowTypeThirteen()
    local styleIndex = UIOrdinTip.STYLE_4
    self:SetWndStyleStateByIndex(styleIndex)
    self:SetTitle4()
    self:SetBtnByStyleIndex(styleIndex)
    self:SetDayNoShow1()
    self:SetOtherTip()
end

function UIOrdinTip:RefreshDescLayout(descLayoutTrans)
    if self._countDownTimeValue then
        self._descContentTrans = self:FindWndTrans(descLayoutTrans, "descContent")
        self:SetCountDown2()
        self:TimerStart(self._countDownKey2, 1, false, -1)
    end
end

function UIOrdinTip:ShowTypeFour()
    local styleIndex = UIOrdinTip.STYLE_2
    self:SetWndStyleStateByIndex(styleIndex)
    self:SetTitle2()
    self:SetDayNoShow2()
    self:SetBtnByStyleIndex(styleIndex)

    local num = self._rewardNum
    local list
    if num < 5 then
        list = self.mLimitList
    else
        list = self.mRewardList
    end
    CS.ShowObject(list, true)
    self:InitScrollView()
    self:SetOtherTip()
end

function UIOrdinTip:SetWndCallBack(func)
    self._wndCallBack = func
end

function UIOrdinTip:RefreshText()
    local wndData = self._wndData
    local text = ccLngText(wndData.text)
    local para = self._contentPara
    if self._otherTip and self._extraChoice then
        if self._useOther then
            para = self._extraChoice.para
        end
    end
    if para then
        text = string.replace(text, unpack(para))
    end
    self._text = text

    if self._wndType == 1 or self._wndType == 3 then
        self:SetTitle1()
    elseif self._wndType == 2 or self._wndType == 4 then
        self:SetTitle2()

    end
end

function UIOrdinTip:ExecuteBackPress()
    if self._showCloseBtn then
        self:WndClose()
    end
end

function UIOrdinTip:ShowCheckMasonryNumTips(func, closeFunc)
    local consumeItemNum = self._showResData.consumeItemNum or 0

    self:WndClose()
    gModelGeneral:ShowCheckMasonryNumTips(consumeItemNum, func, closeFunc)
end

function UIOrdinTip:SetTitle4()
    local titleSize = GameTable.UIWindowRef.titleSize or 30
    local defaultSize = GameTable.UIWindowRef.defaultSize or 24
    self:DisposeXUIText(self.mTitle4, self._title, titleSize)
    self:DisposeXUIText(self.mContent4, self._text, defaultSize)
end

function UIOrdinTip:InitEmptyList()
    local emptyId = self:GetWndArg("emptyId")
    if emptyId and emptyId > 0 then
        local emptyList = self:GetCommonEmptyList("_empty")
        local data = {
            refId = emptyId,
            IntroTran = self.mEmptyText,
            IconTran = self.mEmptyIcon,
            TextBgTran = self.mEmptyTextBg,
        }
        emptyList:RefreshUI(data)
        CS.ShowObject(self.mNoRecord2, true)
    end
end

function UIOrdinTip:SetOtherTip()
    CS.ShowObject(self.mOtherTip, self._otherTip)
    if self._otherTip then
        local toggle = self:FindWndTrans(self.mOtherTip, "Toggle")
        local text = self:FindWndTrans(toggle, "text")
        self:SetWndText(text, self._otherTipText)
        LxUiHelper.SetToggle_ValueChanged(toggle, function(value)
            self._useOther = value
            self:RefreshText()
        end)
        if self._otherDefaultSel then
            local csToggle = toggle:GetComponent(typeUIToggle)
            if csToggle then
                csToggle.isOn = self._otherDefaultSel
                self._useOther = self._otherDefaultSel
                self:RefreshText()
            end
        end
        self:SetWndClick(self.mOtherToggleBtn, function()
            local csToggle = toggle:GetComponent(typeUIToggle)
            if (csToggle) then
                local isOn = csToggle.isOn
                isOn = not isOn
                csToggle.isOn = isOn
                self._useOther = isOn
                self:RefreshText()
            end
        end)
    end
end

function UIOrdinTip:SetTitle2()
    local titleSize = GameTable.UIWindowRef.titleSize or 30
    local defaultSize = GameTable.UIWindowRef.defaultSize or 24
    self:DisposeXUIText(self.mTitle2, self._title, titleSize)
    self:DisposeXUIText(self.mContent2, self._text, defaultSize)
    if not self._isEnus then
        self:InitTextLineWithLanguage(self.mContent2, -20)
    end
end

function UIOrdinTip:ShowTypeTwo()
    local styleIndex = UIOrdinTip.STYLE_2
    self:SetWndStyleStateByIndex(styleIndex)
    self:SetTitle2()
    self:SetDayNoShow2()
    self:SetBtnByStyleIndex(styleIndex)

    local num = self._rewardNum
    local list
    if num < 5 then
        list = self.mLimitList
    else
        list = self.mRewardList
    end
    local isEmpty = num < 1
    if isEmpty then
        self:InitEmptyList()
    end
    CS.ShowObject(list, true)
    self:InitScrollView()
    self:SetOtherTip()
end

function UIOrdinTip:ShowTypeThree()
    local styleIndex = UIOrdinTip.STYLE_1
    self:SetWndStyleStateByIndex(styleIndex)
    self:SetTitle1()
    self:SetBtnByStyleIndex(styleIndex)
    CS.ShowObject(self.mCancelBtn1, false)
    self:SetDayNoShow1()
    self:SetOtherTip()
end

function UIOrdinTip:InitData()
    self._wndRefId = self:GetWndArg("refId")            -- 窗口的RefId
    if self._wndRefId then
        self._wndRefId = tonumber(self._wndRefId)
    end
    if LOG_INFO_ENABLED then
        printInfoN(string.format("wndcommontip refId %s", tostring(self._wndRefId)))
    end
    self._sid = self:GetWndArg("sid")                -- 活动的sid

    local itemList = self:GetWndArg("itemList") or {}                    -- 要展示的道具

    --要展示的消耗道具 格式：= {消耗数量,道具id} 或者 = 消耗数量(默认读取showRes上的道具id)
    self._consumeItemData = self:GetWndArg("consume")

    self._confirmFunc = self:GetWndArg("func")            -- 回调函数
    self._leftFunc = self:GetWndArg("leftFunc")
    self._contentPara = self:GetWndArg("para")

    self._extraChoice = self:GetWndArg("extraChoice")
    self._surBtnFreeStr = self:GetWndArg("surBtnFreeStr")

    --self._notClose = self:GetWndArg("notClose")			-- 不自动关闭窗口
    self._closeFunc = self:GetWndArg("closeFunc")        -- 关闭按钮的回调
    local countDownTimeValue = self:GetWndArg("countDownTimeValue")
    if countDownTimeValue then
        self._countDownTimeValue = GetTimestamp() + countDownTimeValue
    end
    self._countDownFunc = self:GetWndArg("countDownFunc")
    self._isDiamond = self:GetWndArg("isDiamond")
    self._isCountDownPara = self:GetWndArg("isCountDownPara")

    self._wndData = nil
    self._wndType = 1

    self._countDownKey = "_countDownKey"
    self._countDownKey2 = "_countDownKey2"
    self._countDownKey3 = "_countDownKey3"
    self._showCDKey = "showCDKey"

    --11637
    local showCDTime = self:GetWndArg("showCDTime")
    if showCDTime and showCDTime > 0 then
        self._showCDTime = showCDTime
        self:ShowCDDiv()
        self:TimerStart(self._showCDKey, 1, false, -1)
    end

    self:SetListData(itemList)

    self._typeSetFunc = {
        [1] = function()
            self:ShowTypeOne()
        end,
        [2] = function()
            self:ShowTypeTwo()
        end,
        [3] = function()
            self:ShowTypeThree()
        end,
        [4] = function()
            self:ShowTypeFour()
        end,
        [12] = function()
            self:ShowTypeTwelve()
        end,
        [13] = function()
            self:ShowTypeThirteen()
        end,
    }

    self._btnClickList = {
        [1] = true,
        [2] = true,
    }

    local itemFunc = function(refId, num)
        gModelGeneral:OpenItemInfoTip(refId, num)
    end
    local heroFunc = function(refId)
        gModelGeneral:OpenHeroSimpleTip(refId)
    end
    local equipFunc = function(refId)
        gModelGeneral:OpenEquipInfoTip(refId, nil, 1, true)
    end
    local runeFunc = function(id)
        local serverData = gModelRune:GetServerDataById(id)
        if serverData then
            local data = { runeData = serverData }
            gModelGeneral:OpenRuneInfoTip(data)
        end
    end
    self._funcList = {
        itemFunc,
        heroFunc,
        equipFunc,
        runeFunc,
    }

end

------------------------------------------------------------------
return UIOrdinTip


