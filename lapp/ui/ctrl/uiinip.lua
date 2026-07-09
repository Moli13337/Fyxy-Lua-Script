---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInip:LWnd
local UIInip = LxWndClass("UIInip", LWnd)

UIInip.REFRESH_TYPE_NETWORK = 1
UIInip.REFRESH_TYPE_CLICK = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInip:UIInip()
    ---@type CommonIconUIInip
    self._itemIconCls = nil
    ---@type table<number, CommonIcon>
    self._rewardIconList = {}
    self._uiCommonList = {}
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInip:OnWndClose()
    if self._itemIconCls then
        self._itemIconCls:Destroy()
        self._itemIconCls = nil
    end

    if self._rewardIconList then
        local iconList = self._rewardIconList
        for k, v in pairs(iconList) do
            v:Destroy()
            iconList[k] = nil
        end
        self._rewardIconList = nil
    end
    self:ClearCommonIconList(self._uiCommonList)
    if self._callFunc then
        self._callFunc()
    end
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInip:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndMode(LWnd.WND_MODE_NONE)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInip:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    local timePara = {
        key = 1,
        loopcnt = -1,
        interval = 1,
        timescale = false,
        callOnStart = true,
        func = function()
            self:Update()
        end
    }
    self:TimerStartImpl(timePara)

    self:SetWndText(self.mTitle1, ccClientText(10213))
    self:SetWndText(self.mXuqiuTxt, ccClientText(10175))
    self:SetWndText(self.mMiniGuaranteeDescTxt, ccClientText(10248))
    self:SetWndText(self.mHeroListTitleText, ccClientText(31503))
    self:SetTextTile(self.mDraconicStarMax, ccClientText(41064))

    self:InitEvent()
    self:InitData()
    self:InitMsg()
    local isLD = self._type == ModelItem.Item_LEIDENGITEM
    local textId = isLD and 10238 or 10174
    self:SetWndText(self.mDaySignInTxt, ccClientText(textId))

    self:RefreshShowRewardDiv()
    local showBtnList = self:RefreshBtnList()

    if self._type == ModelItem.ITEM_WISH_MATCH then
        return
    end

    self:ShowHeroListDiv()
    if showBtnList ~= nil and not showBtnList then
        CS.ShowObject(self.mBtnBg, false)

        CS.ShowObject(self.mTipBg3, true)
        --CS.ShowObject(self.mNoBtnBg, true)
        CS.ShowObject(self.mNoBtnLayout, true)
    end
    if self._type == ModelItem.Item_Summon then
        return
    end

    local showExtra, extraStr = self:GetExtraInfo(self._refId)
    CS.ShowObject(self.mExtraInfo, showExtra)

    self:SetWndText(self.mExtraInfo, extraStr)
    local ref = gModelItem:GetRefByRefId(self._refId)
    if ref then
        local quaId = ref.quality
        local color = gModelItem:GetColorByQualityId(quaId)
        if color then
            self:SetXUITextColor(self.mExtraInfo, color)
        end
    end
    self:ShowBadgeSkillList()
    --- 龙语相关
    self:RefreshStar()
    self:Update()
    self:RefreshShowSlider()

    CS.ShowObject(self.mCandleDiv, false)
    if self._type == ModelItem.TTEM_TYPE_CANDLE then
        -- 增加蜡烛的显示
        self:SetCandleInfo()
    end
end

function UIInip:OnDrawDaySignInRewardCell(list, item, itemdata, itempos)
    local Root = self:FindWndTrans(item, "Root")
    local itype, refId, num = itemdata.itemType, itemdata.itemId, itemdata.itemNum
    local instanceId = item:GetInstanceID()
    local baseClass = self._rewardIconList[instanceId]
    if not baseClass then
        baseClass = CommonIcon:New()
        self._rewardIconList[instanceId] = baseClass
        baseClass:Create(Root)
    end
    baseClass:SetCommonReward(itype, refId, num)
    --LItemTypeConst.TYPE_PET
    baseClass:DoApply()
    self:SetWndClick(Root, function()
        self:ClickRewardItem(itemdata, itype, refId)
    end)
end

function UIInip:RefreshStar()
    local starMax = 0
    local starNum, refId
    local type = self._type

    if type == gModelItem.TTEM_TYPE_DRACONIC_ITEM then
        starNum = gModelDraconic:GetSpeechStar(self._refId)
        refId = self._refId
    elseif type == gModelItem.TTEM_TYPE_DRACONIC then
        starNum, refId = gModelDraconic:GetSpeechStarByItemId(self._refId)
    elseif type == gModelItem.TTEM_TYPE_HALIDOMITEM then
        local halidomRefId = gModelItem:GetItem2HalidomRefId(self._refId)
        if halidomRefId and halidomRefId > 0 then
            local isActHalidom = gModelHalidom:CheckIsHalidomObjAct(halidomRefId)
            if isActHalidom then
                --- 未激活不显示星星图标
                starNum = gModelHalidom:GetHalidomObjStarLvByRefId(halidomRefId)
                --[[			else
                                --- 2024/5/28：原本是要显示置灰星星，因与文档不符，直接注释，反馈单已删除
                                starNum = 0]]
            end
            starMax = gModelHalidom:GetHalidomStarByRefId(halidomRefId)
        end
    elseif type == gModelItem.TTEM_TYPE_PET then
        local petId = tonumber(self._ref.typeDate)
        local pet = gModelPet:GetPetById(petId)
        starMax = pet:GetMaxStar()
        starNum = pet._star
        CS.ShowObject(self.mHalidomStarRoot1, pet.isActive)
        CS.ShowObject(self.mStarRoot, pet.isActive)
    elseif type == gModelItem.TTEM_TYPE_DIVINE then
        local id = tonumber(self._ref.typeDate)
        local info = gModelDivineWeapon:GetDivineWeaponByRefId(id)
        starMax = gModelDivineWeapon:GetMaxStar(id)
        starNum = info and info.star or 0
        CS.ShowObject(self.mHalidomStarRoot1, not not info)
        CS.ShowObject(self.mStarRoot, not not info)
    end

    if not starNum or starNum == -1 then
        return
    end

    local trans = self.mStarRoot
    if type == gModelItem.TTEM_TYPE_DRACONIC_ITEM or type == gModelItem.TTEM_TYPE_DRACONIC then
        starMax = gModelDraconic:GetStarMax(refId)
    else
        trans = self.mHalidomStarRoot1
    end
    self:SetStarRootInfo(trans, starNum, starMax)
end

function UIInip:InitJumpList(list)
    local uiJumpList = self._uiJumpList
    if uiJumpList then
        uiJumpList:RefreshList(list)
    else
        uiJumpList = self:GetUIScroll("uiJumpList")
        self._uiJumpList = uiJumpList
        uiJumpList:Create(self.mJumpList, list, function(...)
            self:OnDrawJumpCell(...)
        end)
    end
end

function UIInip:GetPlayerLvRewardList(clickDay, clickStatus)
    local list = {}
    local LeiDengInfo = gModelItem:GetLeiDengItemByRefId(self._refId)
    local LeiDengServerData = self._id and gModelItem:GetLeiDengServerDataById(self._refId, self._id)
    local playerLv = gModelPlayer:GetPlayerLv()
    local isHave = LeiDengServerData ~= nil

    local rewardDays = isHave and LeiDengServerData.rewardDays or {}
    local isFirst = isHave and #rewardDays == 0 or false
    local rewardDaysKey = isHave and LeiDengServerData.rewardDaysKey or {}
    local isFirstOpen = false
    local showNext = 0
    for i, v in ipairs(LeiDengInfo) do
        local day = v.day
        local rewardList = v.rewardList
        local isShowRedPoint = false
        local isOpen = false
        local isNotGet = false
        local isCurDay = false
        if isHave then
            isNotGet = rewardDaysKey[day] == nil -- 未领取
            isCurDay = playerLv == day
            isShowRedPoint = isNotGet and isCurDay
            if not isFirstOpen and clickDay == nil then
                -- 第n天
                isFirstOpen = isShowRedPoint
                isOpen = isShowRedPoint
            elseif not isFirstOpen and clickDay == day then
                -- 展开某一天
                isFirstOpen = true
                isOpen = clickStatus
            end

            -- 多日未领取时
            if isNotGet and not isFirstOpen and clickDay == nil and playerLv > day then
                isFirstOpen = true
                isOpen = true
            end

            -- 首次登陆标记
            if isFirst and not isFirstOpen and clickDay == nil then
                isFirstOpen = true
                isOpen = isFirst
            end

            -- 领取完当日的展示下一天
            if showNext == 1 and clickDay == nil then
                isOpen = true
                isFirstOpen = true
                showNext = showNext + 1
            end
            if isCurDay and not isNotGet then
                showNext = 1
            end
        else
            isNotGet = true
            if not isFirstOpen and clickDay == nil then
                -- 第n天
                isFirstOpen = isShowRedPoint
                isOpen = isShowRedPoint
            elseif not isFirstOpen and clickDay == day then
                -- 展开某一天
                isFirstOpen = true
                isOpen = clickStatus
            end
        end
        table.insert(list, {
            day = day,
            rewardList = rewardList,
            isShowRedPoint = isShowRedPoint,
            isHave = isHave,
            isOpen = isOpen,
            isGet = not isNotGet,
            isCurDay = isCurDay,
        })
    end
    if not isFirstOpen then
        for i, v in ipairs(list) do
            if not v.isOpen and not v.isGet then
                list[i].isOpen = true
                break
            end
        end
    end
    return list
end

function UIInip:SetStarRootInfo(trans, starNum, starMax)
    for i = 1, 10 do
        if i > starMax then
            CS.ShowObject(CS.FindTrans(trans, "star" .. i), false)
        else
            CS.ShowObject(CS.FindTrans(trans, "star" .. i), true)
            CS.ShowObject(CS.FindTrans(trans, "star" .. i .. "/gray"), i > starNum)
        end
    end
end

function UIInip:OnDrawSelCell(list, item, itemdata, itempos)
    local UIText = self:FindWndTrans(item, "UIText")
    self:SetWndText(UIText, itemdata)
end

function UIInip:InitBtnList()
    CS.ShowObject(self.mBtnBg, true)

    CS.ShowObject(self.mTipBg3, false)
    --CS.ShowObject(self.mNoBtnBg,false)
    CS.ShowObject(self.mNoBtnLayout, false)
    local refId = self._refId
    local typeList
    if self._share then
        typeList = {
            [1] = { btnId = 3333, name = ccClientText(12116), icon = "public_btn_1_2" }
        }
    elseif self._appointBtnCode ~= nil then
        typeList = gModelItem:GetAppointCode(self._appointBtnCode)
    else
        if self._type == ModelItem.TTEM_TYPE_HALIDOMITEM then
            typeList = {}

            --- 2024/5/28：只要是预览按钮，统统都是无操作按钮
            --[[			if self._formBag then
                            table.insert(typeList,{
                                code = ModelItem.BTNCODE_HALIDOM_PRE,name = ccClientText(41542),icon = "public_btn_1_1"
                            })
                        else
                            table.insert(typeList,{
                                code = ModelItem.BTNCODE_HALIDOM_PRENOTOPT,name = ccClientText(41542),icon = "public_btn_1_1"
                            })
                        end]]
            table.insert(typeList, {
                code = ModelItem.BTNCODE_HALIDOM_PRENOTOPT, name = ccClientText(41542), icon = "public_btn_1_1"
            })

            --table.insert(typeList,{
            --	code = ModelItem.BTNCODE_HALIDOM_PRENOTOPT,name = ccClientText(41542),icon = "public_btn_1_1"
            --})
            if self._formBag then
                --- 从背包打开
                local halidomRefId = gModelItem:GetItem2HalidomRefId(refId)
                if halidomRefId and halidomRefId > 0 then
                    if gModelHalidom:CheckIsHalidomObjAct(halidomRefId) then
                        table.insert(typeList, {
                            code = ModelItem.BTNCODE_HALIDOM_USE, name = ccClientText(41544), icon = "public_btn_1_2"
                        })
                    else
                        table.insert(typeList, {
                            code = ModelItem.BTNCODE_HALIDOM_COMPOUND, name = ccClientText(41543), icon = "public_btn_1_2"
                        })
                    end
                end
            end
        elseif self._type == ModelItem.Item_MainCitySkin then
            local ref = self._ref
            if ref then
                local mainCitySkinId = checknumber(ref.typeDate)
                if mainCitySkinId and mainCitySkinId > 0 then
                    local isAct = gModelPlayerSpace:GetMainCitySkinByRefId(mainCitySkinId)
                    if isAct then
                        --- 出售
                        typeList = {
                            [1] = {
                                code = ModelItem.BTNCODE_MAINCITY_SELL,name = ccClientText(30312),icon = "public_btn_1_3"
                            }
                        }
                    else
                        --- 使用
                        typeList = {
                            [1] = {
                                code = ModelItem.BTNCODE_MAINCITY_USE,name = ccClientText(30313),icon = "public_btn_1_2"
                            }
                        }
                    end
                end
            end
        else
            typeList = gModelItem:GetBtnType(refId, self._extra, self._formBag)
        end
    end
    local itemNum = table.keysize(typeList)
    local uiList = self._uiList
    if not uiList then
        uiList = UIListEasy:New()
        local trans, noSelTrans
        if itemNum <= 2 then
            trans = self.mBtnList1
            noSelTrans = self.mBtnList
        else
            trans = self.mBtnList
            noSelTrans = self.mBtnList1
        end
        CS.ShowObject(noSelTrans, false)
        uiList:Create(self, trans)
        uiList:EnableScroll(false, true)
        uiList:SetFuncOnItemDraw(function(...)
            self:btnListOnDraw(...)
        end)
        self._uiList = uiList
    end
    local itemCnt = self._showBtnNum and self._showBtnNum or #typeList

    for i = 1, itemCnt do
        local data = typeList[i]
        if itemCnt == 1 and self._type == ModelItem.TTEM_TYPE_EQUIP_STRENGTH_3 then
            data = typeList[2]
        end

        uiList:AddData(i, data)
    end
    uiList:RefreshList()
end

function UIInip:CreateRewardList(trans, list, isMax)
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if not uiList then
        uiList = self:GetUIScroll(key)
    end
    local uiListType
    if isMax then
        uiListType = UIItemList.WRAP
    end
    uiList:Create(trans, list, function(...)
        self:OnDrawDaySignInRewardCell(...)
    end, uiListType)
end

function UIInip:InitDaySignInList(refreshType, clickDay, clickStatus)
    local itype = self._type
    local list = {}
    if itype == ModelItem.Item_LEIDENGITEM then
        list = self:GetDaySignInRewardList(clickDay, clickStatus)
    elseif itype == ModelItem.Item_DENGJILJITEM then
        list = self:GetPlayerLvRewardList(clickDay, clickStatus)
    end
    local jumpIndx = 0
    if clickDay then
        for i, v in ipairs(list) do
            if v.day == clickDay then
                jumpIndx = i
            end
        end
    end
    local uiDaySignInList = self._uiDaySignInList
    if uiDaySignInList then
        uiDaySignInList:RefreshList(list)
        if clickDay then
            uiDaySignInList:MoveToPos(jumpIndx)
        else
            uiDaySignInList:DrawAllItems()
        end
    else
        uiDaySignInList = self:GetUIScroll("uiDaySignInList")
        self._uiDaySignInList = uiDaySignInList
        uiDaySignInList:Create(self.mDaySignInList, list, function(...)
            self:OnDrawDaySignInCell(...)
        end,
                UIItemList.SUPER)
    end
    if clickDay == nil then
        local index = 0
        for i, v in ipairs(list) do
            if v.isOpen then
                index = i
                break
            end
        end
        if index ~= 0 then
            uiDaySignInList:MoveToPos(index)
        end
    end
end

function UIInip:GetBtnOutLine(icon)
    local nameOutlines = {
        ["public_btn_1_1"] = "SourceHanSerifCN_132262_2",
        ["public_btn_1_2"] = "SourceHanSerifCN_442a00_2",
        ["public_btn_1_3"] = "SourceHanSerifCN_550b00_2",
        ["public_btn_ash_1"] = "SourceHanSerifCN_000000_2"
    }
    return nameOutlines[icon]
end

function UIInip:ShowItemToGolemInfo()
    local ref = self._ref
    if not ref then
        return
    end
    local golemRefId = tonumber(ref.typeDate)
    if not golemRefId then
        return
    end

    self:SetTextTile(self.mGolemSuitEffTitle, ccClientText(33259))

    local suit = gModelGolem:GetGolemElementSuitByRefId(golemRefId)

    local suitName = gModelGolem:GetGolemSuitNameByRefId(suit)
    self:SetWndText(self.mGolemSuitEffTxt, suitName)

    local icon = gModelGolem:GetGolemSuitIconByRefId(suit)
    self:SetWndEasyImage(self.mGolemSuitEffIcon, icon)

    local suitText, suitText1 = gModelGolem:GetGolemSuitSuitTextAndSuitText1ByRefId(suit)
    local twoEffDesc = string.replace(ccClientText(33258), ModelGolem.SUIT_WEAR_1)
    local twoEffTxt = string.replace(ccClientText(33257), twoEffDesc, suitText)

    local fourEffDesc = string.replace(ccClientText(33258), ModelGolem.SUIT_WEAR_2)
    local fourEffTxt = string.replace(ccClientText(33257), fourEffDesc, suitText1)

    local suitEffDesc = string.replace(ccClientText(33253), twoEffTxt, fourEffTxt)
    self:SetWndText(self.mGolemSuitEffDesc, suitEffDesc)

    local jumpDataList = gModelItem:ParseJump(ref.jump)
    if #jumpDataList < 1 then
        CS.ShowObject(self.mDaoJuJumpDiv, false)
        return
    end
    self:SetTextTile(self.mDaoJuJumpTitle, ccClientText(33224))

    local list = {}
    for i, v in ipairs(jumpDataList) do
        local jumpCfg = gModelGeneral:GetJumpConfig(v.jumpId)
        if jumpCfg then
            local data = {}
            data.name = ccLngText(jumpCfg.name)
            data.btnTxt = ccClientText(33269)
            data.functionId = jumpCfg.functionId
            data.isOpen = gModelFunctionOpen:CheckIsOpened(data.functionId)
            table.insert(list, data)
        end
    end
    self:InitJumpList(list)

    CS.ShowObject(self.mDaoJuGolemDiv, true)
end

function UIInip:OnDrawJumpCell(list, item, itemdata, itempos)
    local JumpNameTrans = self:FindWndTrans(item, "JumpName")
    local JumpTxtTrans = self:FindWndTrans(item, "JumpTxt")
    self:SetWndText(JumpNameTrans, itemdata.name)

    local hyper = self:GetUIHyperText(JumpTxtTrans)
    local str = hyper:AddHyper(itemdata.btnTxt, { func = function()
        self:OnClickJumpFunc(itemdata)
    end })
    self:SetWndText(JumpTxtTrans, str)
end

function UIInip:GetDaySignInRewardList(clickDay, clickStatus)
    local list = {}
    local LeiDengInfo = gModelItem:GetLeiDengItemByRefId(self._refId)
    local LeiDengServerData = self._id and gModelItem:GetLeiDengServerDataById(self._refId, self._id)
    local isHave = LeiDengServerData ~= nil
    local createTime = isHave and LeiDengServerData.createTime / 1000 or 0
    local createZeroTime = LUtil.GetNextDayTimes(createTime)
    local curTime = GetTimestamp()
    local zeroTime = LUtil.GetNextDayTimes(curTime, 1)
    local lostDay = zeroTime - createZeroTime
    local changeDay = LUtil.GetCurTimeDayNum(lostDay)

    local rewardDays = isHave and LeiDengServerData.rewardDays or {}
    local isFirst = isHave and #rewardDays == 0 or false
    local rewardDaysKey = isHave and LeiDengServerData.rewardDaysKey or {}
    local isFirstOpen = false
    local showNext = 0
    for i, v in ipairs(LeiDengInfo) do
        local day = v.day
        local rewardList = v.rewardList
        local isShowRedPoint = false
        local isOpen = false
        local isNotGet = false
        local isCurDay = false
        if isHave then
            isNotGet = rewardDaysKey[day] == nil -- 未领取
            isCurDay = changeDay == day
            isShowRedPoint = isNotGet and isCurDay
            if not isFirstOpen and clickDay == nil then
                -- 第n天
                isFirstOpen = isShowRedPoint
                isOpen = isShowRedPoint
            elseif not isFirstOpen and clickDay == day then
                -- 展开某一天
                isFirstOpen = true
                isOpen = clickStatus
            end

            -- 多日未领取时
            if isNotGet and not isFirstOpen and clickDay == nil and changeDay > day then
                isFirstOpen = true
                isOpen = true
            end

            -- 首次登陆标记
            if isFirst and not isFirstOpen and clickDay == nil then
                isFirstOpen = true
                isOpen = isFirst
            end

            -- 领取完当日的展示下一天
            if showNext == 1 and clickDay == nil then
                isOpen = true
                isFirstOpen = true
                showNext = showNext + 1
            end
            if isCurDay and not isNotGet then
                showNext = 1
            end
        end
        table.insert(list, {
            day = day,
            rewardList = rewardList,
            isShowRedPoint = isShowRedPoint,
            isHave = isHave,
            isOpen = isOpen,
            isGet = not isNotGet,
            isCurDay = isCurDay,
        })
    end
    if not isFirstOpen then
        for i, v in ipairs(list) do
            if not v.isOpen and not v.isGet then
                list[i].isOpen = true
                break
            end
        end
    end
    return list
end

function UIInip:CandleListItem(list, item, itemdata, itempos)
    local MagicIcon = CS.FindTrans(item, "MagicIcon")
    local MagicName = CS.FindTrans(item, "MagicName")
    local MagicName_Jump = CS.FindTrans(item, "MagicName_Jump")
    local NeedTag = CS.FindTrans(item, "NeedTag")
    local NeedTagText = CS.FindTrans(NeedTag, "UIText")

    if self._isEnus then
        self:SetAnchorPos(NeedTag, Vector2.New(30, 0))
    elseif self._isVie then
        self:SetAnchorPos(NeedTag, Vector2.New(45, 0))
    end

    --取下阵法的配置
    local magicCfg = gModelMagic:GetMagicCircleRef(itemdata)
    local typeRefId = magicCfg.type
    local typeCfg = gModelMagic:GetMagicTypeRef(typeRefId)
    local Icon = typeCfg.icon
    self:SetWndEasyImage(MagicIcon, Icon)

    self:SetWndText(NeedTagText, ccClientText(45727))

    local nameStr = ccLngText(magicCfg.name)
    --拼接一次进度
    local circleData = gModelMagic:GetCircleData(itemdata)
    local candleCount, _ = gModelMagic:ParseCandleCell(magicCfg.cell)
    local schedule = "（%s/%s）"
    if circleData then
        local seat = circleData:GetSeat()
        schedule = string.format(schedule, #seat, candleCount)
    else
        schedule = string.format(schedule, 0, candleCount)
    end
    nameStr = nameStr .. schedule

    self:SetWndText(MagicName, nameStr)
    self:SetWndText(MagicName_Jump, nameStr)

    --判断下情况吧 系列的解锁情况
    local isOpen = gModelMagic:CheckMagicTypeIsOpen(typeRefId)

    local isShopJump = false
    local canLight, pos
    if isOpen then
        --该阵法还需不需要这个蜡烛 是第几个位置
        canLight, pos = gModelMagic:GetCandleCanLightMagicCircle(self._refId, magicCfg.refId)

        isShopJump = canLight
    else

        isShopJump = false

    end

    CS.ShowObject(MagicName, not isShopJump)
    CS.ShowObject(MagicName_Jump, isShopJump)
    CS.ShowObject(NeedTag, isShopJump)

    local count, positionData = gModelMagic:ParseCandleCell(magicCfg.cell)

    local data = positionData[pos]

    self:SetWndClick(item, function()
        if not isOpen then
            GF.ShowMessage(ccLngText(typeCfg.desc))
            return
        end
        self:WndClose()

        --跳转到点亮部分
        GF.OpenWnd("UIMicLightCandle", {
            itemdata = data,
            isLight = not isShopJump,
            circleCfg = magicCfg,
            seat = pos,
        })

    end)

end

-- 星级列表 item
function UIInip:OnDrawStarListItem(list, item, itemdata, itempos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache         = {}
        itemCache.txtDesc = CS.FindTrans(item, "TxtDesc")
        itemCache.comStar = CS.FindTrans(item, "ComStar")
        self:SetComponentCache(instanceID, itemCache)
    end

    local gray = false--self._starNum < itemdata.rankNow
    self:SetComStar(itemCache.comStar, 1)
    local starStar = itempos==1 and ccClientText(46547) or string.replace(ccClientText(47548),itemdata.star)
    local skillRef = GameTable.SnakeSkillRef[itemdata.skill]
    local strDesc = ccLngText(skillRef.description)

    self:SetWndText(itemCache.txtDesc, starStar..strDesc)

    local itemSize = item.sizeDelta
    local textD = itemCache.txtDesc:GetComponent("YXUIText")
    itemSize.y = textD.preferredHeight
    item.sizeDelta = itemSize
end

function UIInip:OnDrawDaySignInCell(list, item, itemdata, itempos)
    local isShowRedPoint = itemdata.isShowRedPoint
    local rewardList = itemdata.rewardList
    local day = itemdata.day
    local isHave = itemdata.isHave
    local isOpen = itemdata.isOpen
    local isGet = itemdata.isGet
    local isCurDay = itemdata.isCurDay

    local isLDItem = self._type == ModelItem.Item_LEIDENGITEM

    local TopDiv = self:FindWndTrans(item, "TopDiv")
    local RewardDiv = self:FindWndTrans(item, "RewardDiv")
    if TopDiv then
        --local jumpPos = self._type == ModelItem.Item_LEIDENGITEM and day or itempos
        local jumpPos = day
        local NoSelImg = self:FindWndTrans(TopDiv, "NoSelImg")
        local SelImg = self:FindWndTrans(TopDiv, "SelImg")
        self:SetWndClick(NoSelImg, function()
            self:ClickCellEvent(jumpPos, isOpen, isCurDay, isShowRedPoint, true)
        end)
        self:SetWndClick(SelImg, function()
            self:ClickCellEvent(jumpPos, isOpen, isCurDay, isShowRedPoint, false)
        end)
        CS.ShowObject(NoSelImg, not isOpen)
        CS.ShowObject(SelImg, isOpen)

        local NoSelTitle = self:FindWndTrans(TopDiv, "NoSelTitle")
        local SelTitle = self:FindWndTrans(TopDiv, "SelTitle")
        local textId = isLDItem and 10235 or 10173
        local str = string.replace(ccClientText(textId), day)
        self:SetWndText(NoSelTitle, str)
        self:SetWndText(SelTitle, str)
        CS.ShowObject(NoSelTitle, not isOpen)
        CS.ShowObject(SelTitle, isOpen)

        local NoSelTxt = self:FindWndTrans(TopDiv, "NoSelTxt")
        local SelTxt = self:FindWndTrans(TopDiv, "SelTxt")
        local rewardStr = self:GetRewardStr(rewardList)
        self:SetWndText(NoSelTxt, rewardStr)
        self:SetWndText(SelTxt, rewardStr)
        CS.ShowObject(NoSelTxt, not isOpen)
        CS.ShowObject(SelTxt, isOpen)

        local NoShowBtn = self:FindWndTrans(TopDiv, "NoShowBtn")
        local ShowBtn = self:FindWndTrans(TopDiv, "ShowBtn")
        local GetImg = self:FindWndTrans(TopDiv, "GetImg")
        self:SetWndClick(NoShowBtn, function()
            self:ClickCellEvent(jumpPos, isOpen, isCurDay, isShowRedPoint, true)
        end)
        self:SetWndClick(ShowBtn, function()
            self:ClickCellEvent(jumpPos, isOpen, isCurDay, isShowRedPoint, false)
        end)
        if isGet then
            CS.ShowObject(NoShowBtn, false)
            CS.ShowObject(ShowBtn, false)
        else
            CS.ShowObject(NoShowBtn, not isOpen)
            CS.ShowObject(ShowBtn, isOpen)
        end
        CS.ShowObject(GetImg, isGet)
    end
    local showRewardDiv = false
    if RewardDiv then
        local MinList = self:FindWndTrans(RewardDiv, "MinList")
        local MaxList = self:FindWndTrans(RewardDiv, "MaxList")
        local len = #rewardList
        local isSelMax = len > 4
        local showMax = isOpen and isSelMax
        local showMin = isOpen and not isSelMax
        CS.ShowObject(MinList, showMin)
        CS.ShowObject(MaxList, showMax)
        if showMin then
            self:CreateRewardList(MinList, rewardList, false)
            showRewardDiv = true
        end
        if showMax then
            self:CreateRewardList(MaxList, rewardList, true)
            showRewardDiv = true
        end
    end
    CS.ShowObject(RewardDiv, showRewardDiv)
    local width = TopDiv.sizeDelta.x
    local height = TopDiv.sizeDelta.y + 10
    if showRewardDiv then
        height = height + RewardDiv.sizeDelta.y
    end
    LxUiHelper.SetSizeWithCurAnchor(item, 0, width)
    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
end

function UIInip:InitEvent()
    self:SetWndClick(self.mBg, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIInip:ShowLeiDengRewardDiv()
    local ref = self._ref
    local showDescDiv = ref ~= nil
    local description = showDescDiv and ref.description
    local titleId = 10240
    self:SetDescTxt(showDescDiv, ccLngText(description), titleId)
    CS.ShowObject(self.mDaySignInDiv, true)
    self:InitDaySignInList()
end

function UIInip:InitMsg()
    self:WndNetMsgRecv(LProtoIds.ItemUseResp, function()
        if self._id then
            local isEnd = gModelItem:GetLeiDengServerDataById(self._refId, self._id)
            if not isEnd then
                self:WndClose()
                return
            end
            if self._uiList then
                self._uiList:RefreshList()
            end
            self:InitDaySignInList()
        else
            self:WndClose()
        end
    end)
    self:WndNetMsgRecv(LProtoIds.SellGoodsResp, function()
        GF.ShowMessage(ccClientText(10225))
        self:WndClose()
    end)
    self:WndNetMsgRecv(LProtoIds.ItemDropReplaceInfoResp, function(pb, ret)
        local dropInfo = pb.dropInfo
        if not dropInfo then
            return
        end
        local refId = dropInfo.refId
        if self._refId ~= refId then
            return
        end
        self:RefreshDropDesc(dropInfo)
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        if not self._id then
            return
        end
        local isEnd = gModelItem:GetLeiDengServerDataById(self._refId, self._id)
        if not isEnd then
            self:WndClose()
            return
        end
        self:InitDaySignInList()
        if self._uiList then
            self._uiList:RefreshList()
        end
    end)
end

function UIInip:RefreshShowRewardDiv()
    local isLeiDeng = gModelItem:GetLeiDengItemByRefId(self._refId)
    if isLeiDeng then
        self:ShowLeiDengRewardDiv()
    else
        local itemType = gModelItem:GetType(self._refId)
        if itemType and itemType == ModelItem.Item_RUNESEL then
            self:ShowRuneSelTypeInfo()
        elseif itemType and itemType == ModelItem.ITEM_CUSTOM_ITEMTOGOLEM then
            --道具魔偶
            self:ShowItemToGolemInfo()
        else
            self:ShowTypeRewardList()
        end
    end
end

function UIInip:InitData()
    self._refId = self:GetWndArg("refId")
    self._showNum = self:GetWndArg("showNum")
    self._showBagNum = self:GetWndArg("showBagNum")
    self._hideNum = self:GetWndArg("hide")
    self._hideOwnText = self:GetWndArg("hideOwnText")
    self._share = self:GetWndArg("share")
    self._shareFunc = self:GetWndArg("shareFunc")
    self._callFunc = self:GetWndArg("callFunc")
    self._appointBtnCode = self:GetWndArg("appointBtnCode")
    self._showBtn = self:GetWndArg("showBtn")
    self._chatType = self:GetWndArg("chatType")
    self._id = self:GetWndArg("id")
    self._forceNoShowBtn = self:GetWndArg("forceNoShowBtn")
    self._showBtnNum = self:GetWndArg("showBtnNum") --需要显示的按钮的数量
    self._formBag = self:GetWndArg("formBag") or false

    local refId = self._refId
    if not refId then
        return
    end
    self._type = gModelItem:GetType(refId)
    self._TextShow = gModelItem:GetTextShow(refId) or 0
    local serverData = gModelItem:GetItemServerDataByRefId(refId)
    local num
    if serverData then
        num = serverData:GetNum()
    else
        num = 0
    end
    local ref = gModelItem:GetRefByRefId(refId)
    local color
    if ref then
        self._ref = ref

        ----应策划要求，去除道具作用，改为只使用道具描述
        ---将道具描述改为道具背景
        --【D道具系统】删除2个字段（客户端）
        -- local setting = ccLngText(ref.setting)
        -- local show = not string.isempty(setting)
        CS.ShowObject(self.mDaoJuZuoYongDiv, false)
        -- if show then
        -- 	self:SetWndText(self.mTitleTxt,setting)
        -- end
        --

        --[[
        local itemUseDesc = ccLngText(ref.itemUseDec)
        if string.isempty(itemUseDesc) then
            itemUseDesc = ccClientText(10208)
        end
        local str = ccClientText(10206)
        str = string.replace(str,itemUseDesc)
        self:SetWndText(self.mTitleTxt,itemUseDesc)
        ]]
        --

        local quaId = ref.quality
        local heroMessage = gModelItem:GetHeroMessQualityById(quaId)
        if heroMessage then
            self:SetWndEasyImage(self.mHeadImg, heroMessage)
        end
        color = gModelItem:GetColorByQualityId(quaId)
        if color then
            self:SetXUITextColor(self.mNameTxt, color)
        end
        local name = gModelItem:GetNameByRefId(refId)
        self:SetXUITextText(self.mNameTxt, name)
        --self:InitTextModeWithLanguage(self.mNameTxt)
    end
    --[[		local str = ccClientText(10234)
            -- 显示的数量和是否显示背包数量
            if self._showNum  and not self._showBagNum then
                num = self._showNum
                str = ccClientText(10211)
            end
            str = string.replace(str,num)
            self:SetXUITextText(self.mNumTxt,str)
            if self._hideOwnText ~=nil  then
                CS.ShowObject(self.mNumTxt,not self._hideOwnText)
            end

            if self._showNum then
                local tnum = tonumber(self._showNum)
                if tnum < 0 then
                    CS.ShowObject(self.mNumTxt,false)
                end
            end]]

    local showNum = num
    if self._id then
        showNum = 1
    end
    local str = ccClientText(10234)
    -- str = string.replace(str,LUtil.NumberCoversion(showNum))
    self:SetXUITextText(self.mHaveNumTxt, str .. LUtil.NumberCoversion(showNum))
    if color then
        self:SetXUITextColor(self.mHaveNumTxt, color)
    end
    if self._type == ModelItem.Item_Summon or self._type == ModelItem.ITEM_WISH_MATCH then
        local itemdata = gModelItem:GetItemServerDataByRefId(refId)
        if itemdata then
            local _itemExtras = itemdata._itemExtras
            local _extra = nil
            if self._id then
                for i, v in ipairs(_itemExtras) do
                    if v.id == self._id then
                        _extra = v.extra
                        break
                    end
                end
            end
            if _extra then
                local extra = JSON.decode(_extra)
                self._extra = extra
                local callNum = extra.callNum
                local typeDate = string.split(ref.typeDate, "=")
                local allCallNum = tonumber(typeDate[2])
                if allCallNum and allCallNum > 0 then
                    local str = ccClientText(10710) .. (allCallNum - callNum)
                    CS.ShowObject(self.mExtraInfo, true)
                    self:SetWndText(self.mExtraInfo, str)
                else
                    CS.ShowObject(self.mExtraInfo, false)
                end
            end
        end
    end

    local showHalidomNum = false
    local showNumTxt = false
    local isHalidom = self._type == ModelItem.TTEM_TYPE_HALIDOMITEM or self._type == gModelItem.TTEM_TYPE_DRACONIC_ITEM or self._type == gModelItem.TTEM_TYPE_DRACONIC
    isHalidom = isHalidom or self._type == ModelItem.TTEM_TYPE_PET or self._type == ModelItem.TTEM_TYPE_DIVINE
    if isHalidom then
        if self._type == ModelItem.TTEM_TYPE_HALIDOMITEM then
            local halidomRefId = gModelItem:GetItem2HalidomRefId(refId)
            if halidomRefId and halidomRefId > 0 then
                if gModelHalidom:CheckHalidomObjIsMaxStarLv(halidomRefId) then
                    showHalidomNum = true
                end
            end
        elseif self._type == ModelItem.TTEM_TYPE_PET then
            local petId = tonumber(self._ref.typeDate)
            local pet = gModelPet:GetPetById(petId)
            local starCfg = pet:GetPetStarCfg()
            if starCfg.rankNext <= 0 then
                showHalidomNum = true
            end
        elseif self._type == ModelItem.TTEM_TYPE_DIVINE then
            local id = tonumber(self._ref.typeDate)
            local cost = gModelDivineWeapon:GetUpStarCost(id)
            if not cost then
                showHalidomNum = true
            end
        else
            local starNum, draconicRefId = gModelDraconic:GetSpeechStarByItemId(refId)
            local costItem = gModelDraconic:GetUpStarCostRef(draconicRefId, starNum)
            showHalidomNum = costItem == nil
        end
    else
        if self._showNum and not self._showBagNum then
            showNumTxt = true
            local tStr = ccClientText(10211)
            local tNum = tonumber(self._showNum)
            showNum = tNum
            if tNum == -2 then
                tStr = string.replace(tStr, ccClientText(44241))
            else
                tStr = string.replace(tStr, tNum)
            end

            self:SetXUITextText(self.mNumTxt, tStr)
        end
    end
    if color then
        self:SetXUITextColor(self.mNumTxt, color)
    end
    CS.ShowObject(self.mNumTxt, showNumTxt)

    if self._hideOwnText ~= nil then
        CS.ShowObject(self.mNumTxt, not self._hideOwnText)
    end

    if self._chatType then
        CS.ShowObject(self.mHaveNumTxt, false)
    elseif isHalidom then
        CS.ShowObject(self.mHaveNumTxt, showHalidomNum)
    elseif self._ref then
        local haveNum = self._ref.haveNum or 0
        CS.ShowObject(self.mHaveNumTxt, haveNum == 1)
    end

    local commonTrans = CS.FindTrans(self.mItemInfo, "ItemIcon")
    if commonTrans then
        local itemIconCls = self._itemIconCls
        if not itemIconCls then
            itemIconCls = CommonIcon:New()
            self._itemIconCls = itemIconCls
            itemIconCls:Create(commonTrans)
        end
        itemIconCls:SetCommonReward(LItemTypeConst.TYPE_ITEM, refId, showNum, nil, true)
        local showNumStatus = not self._hideNum
        if tonumber(showNum) < 1 then
            showNumStatus = false
        end

        itemIconCls:EnableShowNum(false)
        itemIconCls:EnableShowBg(false)
        itemIconCls:DoApply()

    end
end

function UIInip:OnDrawRewardItem(list, item, itemdata, itempos)
    local uiCommonTrans = self:FindWndTrans(item, "CommonUI")
    if not uiCommonTrans then
        return
    end

    local Icon = self:FindWndTrans(uiCommonTrans, "Icon")
    local UIName = self:FindWndTrans(uiCommonTrans, "UIName")
    local GLName = self:FindWndTrans(uiCommonTrans, "GLName")
    local gradeBg = self:FindWndTrans(uiCommonTrans, "gradeBg")
    local gradeBgGradeLv = self:FindWndTrans(gradeBg, "gradeLv")
    local Special = self:FindWndTrans(uiCommonTrans, "Special")
    local specialLeft = self:FindWndTrans(uiCommonTrans, "SpecialLeft")
    local topTxt = self:FindWndTrans(specialLeft, "TopTxt")

    local NeedTag = self:FindWndTrans(uiCommonTrans, "NeedTag")
    local NeedTagText = CS.FindTrans(NeedTag, "UIText")

    if self._type == 102 or self._type == 103 or self._type == 104 then
        self:SetWndText(NeedTagText, ccClientText(45727))
        local candleRefId = itemdata.refId
        local isShow = gModelMagic:CheckCandleIdCanLightMagicCircle(candleRefId)
        CS.ShowObject(NeedTag, isShow)
    else
        CS.ShowObject(NeedTag, false)
    end

    local isZX = itemdata.isZX or false
    CS.ShowObject(Special, isZX)
    if isZX then
        self:SetWndEasyImage(Special, "public_txt_zx_1", nil, true)
    end

    --local iconTrans = CS.FindTrans(uiCommonTrans, "Icon")
    local itype, refId, num = itemdata.itype, itemdata.refId, itemdata.num
    local isTryHero = itemdata.isTryHero

    local instanceId = item:GetInstanceID()
    local baseClass = self._rewardIconList[instanceId]
    if not baseClass then
        baseClass = CommonIcon:New()
        self._rewardIconList[instanceId] = baseClass
        baseClass:Create(Icon)
    end
    baseClass:SetCommonReward(itype, refId, num)
    baseClass:SetShowStarList(not isTryHero)
    baseClass:SetNoShowLv(isTryHero)

    baseClass:DoApply()

    --local uiNameTrans = CS.FindTrans(uiCommonTrans, "UIName")
    local uiNameText = UIName and self:FindWndText(UIName) or nil
    if uiNameText then
        local itemname, itemcolor = baseClass:GetName()
        self:SetXUITextText(uiNameText, itemname or "")
        if itemcolor then
            self:SetXUITextColor(uiNameText, itemcolor)
        end
    end
    if self._TextShow == 1 then
        if self._type == 104 or self._type == 107 or self.getItemType == 122 then
            CS.ShowObject(GLName,true)
            CS.ShowObject(uiNameText,false)
            self:SetWndText(GLName,itemdata.probability )
        end
    end
    self:SetWndClick(uiCommonTrans, function()
        self:ClickRewardItem(itemdata, itype, refId)
    end)

    local ref = self._ref
    if (ref) then
        local getType = ref.type
        if (getType == ModelItem.ITEM_WISH_MATCH) then
            if (uiNameText) then
                CS.ShowObject(uiNameText, false)
                local wishData = itemdata.wishData
                if (wishData and wishData.type == 1) then
                    CS.ShowObject(specialLeft, true)
                    CS.ShowObject(topTxt, true)
                    --local topStr = string.format("X%s",wishData.guaranteeTime)
                    local topStr = string.replace(ccClientText(10255), wishData.guaranteeTime)
                    self:SetWndText(topTxt, topStr)
                end
            end
        end
    end
end

function UIInip:SetCandleInfo()
    -- 增加蜡烛的显示
    local Title = CS.FindTrans(self.mCandleDesc, "UIText")
    self:SetWndText(Title, ccClientText(45726))

    local showData = gModelMagic:GetMagicByCandleRefId(self._refId)

    if showData and #showData > 4 then
        for i = 1, 4 do
            local tranKey = string.replace("Candle_#a1#", i)
            local candleTran = CS.FindTrans(self.mCandleDiv, tranKey)
            CS.ShowObject(candleTran, false)
        end

        CS.ShowObject(self.mMagicCandleScroll, true)
        CS.ShowObject(self.mCandleDiv, true)

        local uiList = self._candleUiList
        if uiList then
            uiList:RefreshList(showData)
        else
            uiList = self:GetUIScroll("mHeroListScroll_UIInip_")
            self._heroUiList = uiList
            uiList:Create(self.mMagicCandleScroll, showData, function(...)
                self:CandleListItem(...)
            end, UIItemList.SUPER)
        end
        self._candleUiList = uiList


    elseif showData and #showData <= 4 then
        CS.ShowObject(self.mMagicCandleScroll, false)
        CS.ShowObject(self.mCandleDiv, true)

        for i = 1, 4 do
            local tranKey = string.replace("Candle_#a1#", i)
            local candleTran = CS.FindTrans(self.mCandleDiv, tranKey)
            CS.ShowObject(candleTran, false)
        end

        local count = #showData
        for i = 1, count do
            local tranKey = string.replace("Candle_#a1#", i)
            local candleTran = CS.FindTrans(self.mCandleDiv, tranKey)
            CS.ShowObject(candleTran, true)
            self:CandleListItem(nil, candleTran, showData[i], i)
        end
    end
end

function UIInip:ShowInDataTxt(txtStr)
    if (txtStr) then
        CS.ShowObject(self.mInDataTxt, true)
        self:SetWndText(self.mInDataTxt, txtStr)
    end
end

function UIInip:GetBtnColor(icon)
    local nameOutlines = {
        ["public_btn_1_1"] = "5C6D9A",
        ["public_btn_2_1"] = "5C6D9A",
        ["public_btn_3_1"] = "5C6D9A",
    }
    return nameOutlines[icon] or "FFFFFF"
end

function UIInip:OnClickJumpFunc(itemdata)
    local functionId = itemdata.functionId
    if not functionId then
        return
    end
    if not gModelFunctionOpen:CheckIsOpened(functionId, true) then
        return
    end
    gModelFunctionOpen:Jump(functionId, self:GetWndName())
end


function UIInip:ShowBadgeSkillList()
    if self._type ~= ModelItem.TTEM_TYPE_BADGE then return end
    CS.ShowObject(self.mBadgeDiv, true)
    self:SetTextTile(self.mBadgeTitle,ccClientText(40911))
    self:RefreshStarList()
end

function UIInip:GetRewardStr(list)
    local str
    for i, v in ipairs(list) do
        local name = gModelGeneral:GetCommonItemName(v)
        local infoStr = string.format("%s*%s", name, v.itemNum)
        if str == nil then
            str = infoStr
        else
            str = str .. "," .. infoStr
        end
    end
    str = string.replace(ccClientText(10236), str)
    return str or ""
end

function UIInip:InitRuneSelList(list)
    list = list or {}
    local uiSelList = self._uiSelList
    if uiSelList then
        uiSelList:RefreshList(list)
    else
        uiSelList = self:GetUIScroll("uiSelList")
        self._uiSelList = uiSelList
        uiSelList:Create(self.mSelList, list, function(...)
            self:OnDrawSelCell(...)
        end)
    end
end

function UIInip:RefreshBtnList()
    local showBtnList
    if self._type == ModelItem.TTEM_TYPE_HALIDOMITEM then
        local halidomRefId = gModelItem:GetItem2HalidomRefId(self._refId)
        if halidomRefId and gModelHalidom:CheckHalidomObjIsMaxStarLv(halidomRefId) then
            CS.ShowObject(self.mBtnBg, false)
            CS.ShowObject(self.mBtnHalidom, true)
        else
            self:InitBtnList()
        end
    elseif self._type == gModelItem.TTEM_TYPE_PET then
        if self._formBag then
            local ref = self._ref
            if ref and string.isempty(ref.btn) or (self._forceNoShowBtn or self._showBtn == false) then
                CS.ShowObject(self.mBtnBg, false)
                local bShowDesc = self.mDaoJuMiaoShuDiv.gameObject.activeSelf
                CS.ShowObject(self.mTipBg3, bShowDesc)
                CS.ShowObject(self.mNoBtnLayout, bShowDesc)
            else
                self:InitBtnList()
            end
        else
            self._appointBtnCode = { 1033 }
            self:InitBtnList()
        end
    elseif self._type == ModelItem.TTEM_TYPE_BADGE and not self._formBag and not self._share then
        showBtnList =false
    elseif not self._formBag and self._type == gModelItem.TTEM_TYPE_DIVINE then
        CS.ShowObject(self.mBtnBg, false)
        local bShowDesc = self.mDaoJuMiaoShuDiv.gameObject.activeSelf
        CS.ShowObject(self.mTipBg3, bShowDesc)
        CS.ShowObject(self.mNoBtnLayout, bShowDesc)
    else
        if self._showNum ~= nil then
            CS.ShowObject(self.mBtnBg, false)
            local bShowDesc = self.mDaoJuMiaoShuDiv.gameObject.activeSelf
            CS.ShowObject(self.mTipBg3, bShowDesc)
            --CS.ShowObject(self.mNoBtnBg, bShowDesc)
            CS.ShowObject(self.mNoBtnLayout, bShowDesc)
        else
            local ref = self._ref
            if ref and string.isempty(ref.btn) then
                if self._showBtn and self._type == gModelItem.Item_MainCitySkin then
                    showBtnList = true
                    self:InitBtnList()
                else
                    CS.ShowObject(self.mBtnBg, false)
                    local bShowDesc = self.mDaoJuMiaoShuDiv.gameObject.activeSelf

                    CS.ShowObject(self.mTipBg3, bShowDesc)
                    --CS.ShowObject(self.mNoBtnBg, bShowDesc)
                    CS.ShowObject(self.mNoBtnLayout, bShowDesc)
                end
            else
                showBtnList = self._showBtn == nil or not self._showBtn
                if showBtnList then
                    local haveNum = gModelItem:GetNumByRefId(self._refId)
                    showBtnList = haveNum > 0 or self._showBtnNum ~= nil
                    if showBtnList and self._forceNoShowBtn then
                        showBtnList = false
                    end
                end
                if showBtnList or self._type == gModelItem.TTEM_TYPE_DRACONIC_ITEM or self._type == gModelItem.TTEM_TYPE_DRACONIC then
                    self._forceNoShowBtn = false
                    showBtnList = true
                    self:InitBtnList()
                end
            end
        end
        if self._appointBtnCode ~= nil or self._type == gModelItem.TTEM_TYPE_DRACONIC_ITEM or self._type == gModelItem.TTEM_TYPE_DRACONIC then
            -- 通过指定按钮code来显示按钮
            self:InitBtnList()
        end
    end
    return showBtnList
end

function UIInip:ShowTypeRewardList()
    local refId = self._refId
    local ref = self._ref
    if ref then
        local showItemList = true
        local showTime, timeStr = false, ""
        local descTitleId = 10240
        local rewardTitleId
        local descTxtStr
        local description = ccLngText(ref.description)
        local getType = ref.type
        self.getItemType = getType
        local typeDate = ref.typeDate
        local itemList = {}
        if getType == ModelItem.Item_GIFT or getType == ModelItem.Item_CHOOSE then
            if getType == ModelItem.Item_GIFT then
                rewardTitleId = 10214
            else
                rewardTitleId = 10215
            end
            typeDate = string.split(typeDate, ",")
            for i, v in ipairs(typeDate) do
                v = string.split(v, "=")
                table.insert(itemList, { itype = tonumber(v[1]), refId = tonumber(v[2]), num = tonumber(v[3]) })
            end
            if #itemList == 0 then
                printInfoNR("not peizhi")
            end
            -- elseif getType == ModelItem.Item_OUTFIT then
            -- 	rewardTitleId = 10214
            -- 	typeDate = string.split(typeDate,",")
            -- 	for i,v in ipairs(typeDate) do
            -- 		v = string.split(v,"=")
            -- 		local outfitRefId = tonumber(v[1])
            -- 		local outfitHeroRefId = tonumber(v[3])
            -- 		if outfitHeroRefId <= 0 then
            -- 			outfitHeroRefId = 0
            -- 		end
            -- 		table.insert(itemList,{
            -- 			itype = LItemTypeConst.TYPE_OUTFIT,
            -- 			refId = outfitRefId,
            -- 			star = tonumber(v[2]),
            -- 			starExp = 0,
            -- 			score = gModelOutfit:GetOutfitBaseScoreByRefId(outfitRefId),
            -- 			nextHeroRefId = 0,
            -- 			heroId = "0",
            -- 			heroRefId = outfitHeroRefId
            -- 		})
            -- 	end
        elseif getType == ModelItem.Item_DROP then
            rewardTitleId = 10214
            local rewardShow = ref.rewardShow
            rewardShow = string.split(rewardShow, "|")
            for i, v in ipairs(rewardShow) do
                local rewardRefId = tonumber(v)
                local rewardList = gModelItem:GetItemRewardData(rewardRefId)
                for idx, val in ipairs(rewardList) do
                    table.insert(itemList, val)
                end
            end
            --itemList = gModelItem:GetGroupRewardListByGroup(tonumber(typeDate))
        elseif getType == ModelItem.Item_DROPITEMTYPE then
            gModelItem:OnItemDropReplaceInfoReq(refId)
            typeDate = string.split(typeDate, ",")
            showItemList = true
            rewardTitleId = 10214
            local rewardShow = string.split(ref.rewardShow, "|")
            for i, v in ipairs(rewardShow) do
                local rewardRefId = tonumber(v)
                local rewardList = gModelItem:GetItemRewardData(rewardRefId)
                local isZX = i == 1
                for idx, val in ipairs(rewardList) do
                    table.insert(itemList, {
                        itype = val.itype,
                        refId = val.refId,
                        num = val.num,
                        probability = val.probability,
                        isZX = isZX,
                    })
                end
            end
        elseif getType == ModelItem.Item_STARPASS or getType == ModelItem.Item_LVPASS then
            rewardTitleId = 10216
            local selHeroList = {}
            typeDate = string.split(typeDate, ",")
            local val1, val2, val3 = tonumber(typeDate[1]), tonumber(typeDate[2]), tonumber(typeDate[3])
            if val1 == 1 then
                if getType == getType == ModelItem.Item_STARPASS then
                    selHeroList = gModelHero:SelRaceHeroList(val2, val3)
                else
                    selHeroList = gModelHero:SelRaceHeroList(val2, nil, val3)
                end
            else
                if getType == getType == ModelItem.Item_STARPASS then
                    selHeroList = gModelHero:SelRefIdHeroList(val2, val3)
                else
                    selHeroList = gModelHero:SelRefIdHeroList(val2, nil, val3)
                end
            end
            for k, v in pairs(selHeroList) do
                table.insert(itemList, { itype = 2, refId = v.id, num = 1, bagHero = true })
            end
        elseif getType == ModelItem.Item_DEBRIS then
            rewardTitleId = 10217
            typeDate = string.split(typeDate, "=")
            local val1, val2, val3 = tonumber(typeDate[1]), tonumber(typeDate[2]), tonumber(typeDate[3])
            if val1 == 1 then
                local itype = LItemTypeConst.TYPE_HERO
                table.insert(itemList, { itype = itype, refId = val2, num = 1 })
            else
                local rewardShow = ref.rewardShow
                rewardShow = string.split(rewardShow, "|")
                for i, v in ipairs(rewardShow) do
                    local rewardRefId = tonumber(v)
                    local rewardList = gModelItem:GetItemRewardData(rewardRefId)
                    if rewardList then
                        for idx, val in ipairs(rewardList) do
                            table.insert(itemList, val)
                        end
                    else
                        printInfoNR("配置表ItemRewardShowRef， 缺失配置 id = " .. rewardRefId)
                    end
                end
            end
        elseif getType == ModelItem.DEBRIS_COMPOUND then
            rewardTitleId = 10214
            local rewardShow = ref.rewardShow
            rewardShow = string.split(rewardShow, "|")
            for i, v in ipairs(rewardShow) do
                local rewardRefId = tonumber(v)
                local rewardList = gModelItem:GetItemRewardData(rewardRefId)
                if rewardList then
                    for idx, val in ipairs(rewardList) do
                        table.insert(itemList, val)
                    end
                else
                    printInfoNR("配置表ItemRewardShowRef， 缺失配置 id = " .. rewardRefId)
                end
            end
            showItemList = rewardShow and #rewardShow > 0
        elseif getType == ModelItem.Item_SKINITEM then
            -- or getType == 108 去除108类型的显示，已调整到详细描述中
            showTime = true
            showItemList = false
            --14300,10220
            local times
            typeDate = string.split(typeDate, "=")
            times = tonumber(typeDate[2])
            --if getType == 108 then
            --	times = tonumber(typeDate[4])
            --end
            if times == -1 or times == 0 then
                timeStr = ccClientText(14300)
            else
                timeStr = LUtil.FormatTimeToMin(times)
            end
        elseif getType == ModelItem.ITEM_TREASURE_ART then
            --descTitleId = 10239
            showItemList = false
        elseif getType == ModelItem.Item_GENERAL then
            typeDate = string.split(typeDate, "=")
            local typeDateLen = #typeDate
            local firstData = tonumber(typeDate[1])
            if typeDateLen == 1 and firstData and firstData == 1 then
                self:ShowHeroNeedRuneList()
            end
            showItemList = false
        elseif getType == ModelItem.Item_SELECT_TRY_HERO then
            --试用英雄自选道具类型
            rewardTitleId = 10215
            local typeDateList = string.split(typeDate, "|")
            for i, v in ipairs(typeDateList) do
                local data = string.split(v, "=")
                table.insert(itemList, {
                    itype = LItemTypeConst.TYPE_HERO,
                    refId = tonumber(data[1]),
                    num = 1,
                    isTryHero = true,
                })
            end
            if #itemList == 0 then
                printInfoNR("not peizhi")
            end
        elseif getType == ModelItem.Item_COIN_CERTIFICATE then
            --商品兑换券
            local welfareId = tonumber(ref.typeDate)
            local str = gModelPay:GetShowByWelfareId(welfareId)
            descTxtStr = string.replace(description, str)
            showItemList = false
        elseif getType == ModelItem.Item_Summon then
            --商品兑换券
            local extra = self._extra
            if extra then
                local endTime = extra.endTime
                if not string.isempty(endTime) then
                    local timeStr = LUtil.FormatTimeStr(endTime)
                    descTxtStr = string.replace(description, timeStr)
                else
                    descTxtStr = description
                end
            else
                descTxtStr = ccClientText(10252)
            end
            showItemList = false
        elseif (getType == ModelItem.ITEM_WISH_MATCH) then
            rewardTitleId = 10253
            local wishDropList = gModelWishingMatch:GetItemDropList(refId)
            for i, v in pairs(wishDropList) do
                local itemArr = string.split(v.reward, '=')
                local wishItemData = {
                    itype = tonumber(itemArr[1]),
                    refId = tonumber(itemArr[2]),
                    num = tonumber(itemArr[3]),
                    isShowEff = itemArr[4] == "1",
                    wishData = v
                }
                table.insert(itemList, wishItemData)
            end
            local inDataTimeStr, showInDataStrPre
            if (self._id) then
                local extra = self._extra
                local strIndex = (extra and extra.endTime / 1000 > GetTimestamp()) and 37817 or 37816
                inDataTimeStr = string.format("<color=#c81212>%s</color>", ccClientText(strIndex))
                showInDataStrPre = 37819
            else
                inDataTimeStr = gModelWishingMatch:GetItemInDataTimeStr(self._refId)
                inDataTimeStr = string.format("<color=#139057>%s</color>", inDataTimeStr)
                showInDataStrPre = 37818
            end
            local showInDataStr = string.replace(ccClientText(showInDataStrPre), inDataTimeStr)
            self:ShowInDataTxt(showInDataStr)
            CS.ShowObject(self.mHaveNumTxt, false)
        elseif getType == ModelItem.TTEM_TYPE_EQUIP_STRENGTH_3 then
            rewardTitleId = 10258
            -- = ref.type
            local rewardShow = ref.rewardShow
            if string.isempty(rewardShow) then
                showItemList = false
            else
                rewardShow = string.split(rewardShow, "|")
                for i, v in ipairs(rewardShow) do
                    local rewardRefId = tonumber(v)
                    local rewardList = gModelItem:GetItemRewardData(rewardRefId)
                    for idx, val in ipairs(rewardList) do
                        table.insert(itemList, val)
                    end
                end
            end
        else
            showItemList = false
        end
        self:SetTimeTxt(showTime, timeStr)
        descTxtStr = descTxtStr or description
        self:SetDescTxt(descTitleId ~= nil, descTxtStr, descTitleId)
        CS.ShowObject(self.mRewardDiv, showItemList)
        if showItemList then
            self:InitRewardList(itemList, rewardTitleId)
        end
    end
end

function UIInip:BtnEvent(code, itemdata)
    local closeStatus = false
    --[[	if self._refId == 1301002 then
            local info = {}
            table.insert(info,{refId = self._refId,num = 1})
            gModelItem:OnItemUseReq(info)
            code = nil
            closeStatus = true
        end]]
    if code then
        local itype = self._type
        local data = {}
        if itype == ModelItem.Item_LEIDENGITEM or itype == ModelItem.Item_DENGJILJITEM then
            data.id = self._id
        end
        local itemdata = self:GetWndArgList()
        closeStatus = gModelItem:GetWndNameByType(itype, self._refId, code, data, self._id, itemdata)
    else
        closeStatus = true
        if self._shareFunc then
            self._shareFunc()
        end

        if itemdata.func then
            closeStatus = itemdata.func()
        end
    end
    if closeStatus then
        self:WndClose()
    end
end

function UIInip:GetExtraInfo(itemId)
    local ref = gModelItem:GetRefByRefId(itemId)
    if not ref then
        return false
    end

    local type = ref.type
    -- if type == ModelItem.ITEM_TREASURE_ART then
    -- 	local artId = tonumber(ref.typeDate)
    -- 	if not artId then return false end

    -- 	local state,status,itemNum = gModelTreasure:GetArticleUpgradeInfo(artId,itemId)
    -- 	local color = status  and 'green' or 'red'
    -- 	local format = ""
    -- 	if state == 1 then
    -- 		format = ccClientText(21221)
    -- 	else
    -- 		format = ccClientText(21222)
    -- 	end
    -- 	local str = string.replace(format,LUtil.FormatColorStr(itemNum,color))
    -- 	return true,str
    -- elseif type == ModelItem.Item_TREASURESKIN then
    -- 	local treasureSkinRefId = tonumber(ref.typeDate)
    -- 	if not treasureSkinRefId then return false end
    -- 	local str
    -- 	if gModelTreasure:CheckItemTreasureSkinRefIdIsAct(treasureSkinRefId) then
    -- 		str = ccClientText(21233)
    -- 	else
    -- 		str = ccClientText(21232)
    -- 	end
    -- 	return true,str
    if type == ModelItem.Item_GENERAL then
        --local isActive = gModelHero:IsSourceItemActive(itemId)
        --if isActive then
        --	return true, "<#feeba7>(源珠已激活)</color>"
        --end
    end
    return false
end

function UIInip:ShowHeroListDiv()
    local _type = self._type
    if _type ~= ModelItem.Item_Summon then
        return
    end
    local heroList = {}
    local isSummon = false
    local extra = self._extra
    if not extra then
        return
    end
    local rankValue = extra.rankValue
    if not string.isempty(rankValue) and rankValue > 0 then
        isSummon = true
        heroList = LxDataHelper.ParseItem_3List(extra.reward)
    end
    CS.ShowObject(self.mHeroListDiv, isSummon)
    if not isSummon then
        return
    end

    local uiList = self._heroUiList
    if uiList then
        uiList:RefreshList(heroList)
    else
        uiList = self:GetUIScroll("mHeroListScroll_UIInip_")
        self._heroUiList = uiList
        uiList:Create(self.mHeroListScroll, heroList, function(...)
            self:HeroListItem(...)
        end)
    end
end

function UIInip:ClickRewardItem(itemdata, itype, refId)
    if itype == LItemTypeConst.TYPE_ITEM then
        local ref = gModelItem:GetRefByRefId(refId)
        local curType = ref and ref.type
        local oldRefId = self._refId
        local oldNum = self._showNum
        local chatType = self._chatType
        local id = self._id
        local showBagNum, hide, hideOwnText, showBtn
        local oldForceNoShowBtn = self._forceNoShowBtn
        if oldNum == -1 then
            showBagNum, hide, hideOwnText, showBtn = false, true, true, true
        end
        local share = self._share
        local shareFunc = self._shareFunc
        -- if curType == ModelItem.Item_OUTFIT then
        -- 	local showNum = self._showNum
        -- 	local typeDate = string.split(ref.typeDate,",")
        -- 	for i,v in ipairs(typeDate) do
        -- 		v = string.split(v,"=")
        -- 		local outfitRefId = tonumber(v[1])
        -- 		local outfitHeroRefId = tonumber(v[3])
        -- 		if outfitHeroRefId <= 0 then
        -- 			outfitHeroRefId = 0
        -- 		end
        -- 		local outfitData = {itype = LItemTypeConst.TYPE_OUTFIT, refId = outfitRefId, star = tonumber(v[2]), starExp = 0,
        -- 							score = gModelOutfit:GetOutfitBaseScoreByRefId(outfitRefId), nextHeroRefId = 0, heroId = "0", heroRefId = outfitHeroRefId
        -- 		}
        -- 		local callFunc = self._callFunc
        -- 		self._callFunc = nil
        -- 		local data = {
        -- 			curSerData = outfitData,
        -- 			outfitType = 2,
        -- 			func = function()
        -- 				local layer = self:GetWndSortLayer()
        -- 				if layer == LGameUI.UI_SORTLAYER_UITOP then
        -- 					GF.OpenWndTop("UIInip",{refId = oldRefId,showNum = showNum,chatType = chatType,id = id,forceNoShowBtn = oldForceNoShowBtn,
        -- 												share = share,shareFunc = shareFunc,callFunc = callFunc})
        -- 				else
        -- 					GF.OpenWndUp("UIInip",{refId = oldRefId,showNum = showNum,chatType = chatType,id = id,forceNoShowBtn = oldForceNoShowBtn,
        -- 											   share = share,shareFunc = shareFunc,callFunc = callFunc})
        -- 				end

        -- 			end,
        -- 		}
        -- 		gModelGeneral:OpenOutfitInfoTip(data,true)
        -- 	end
        -- 	self:WndClose()
        -- else
        showBagNum, hide, hideOwnText, showBtn = self._showBagNum, self._hide, self._hideOwnText, self._showBtn
        self:WndClose()
        local layer = self:GetWndSortLayer()
        if layer == LGameUI.UI_SORTLAYER_UITOP then
            --[[				GF.OpenWndTop("UIInip",{refId = refId,hide = true,hideOwnText = true,showBtn = true,chatType = chatType,showNum = oldNum,callFunc = function()
                                    gModelGeneral:OpenItemInfoTipTop(oldRefId,oldNum,showBagNum,hide,hideOwnText,chatType,id,showBtn)
                                end})]]
            gModelGeneral:OpenItemInfoTipTop(refId, oldNum, showBagNum, hide, hideOwnText, chatType, id, showBtn,
                    function()
                        gModelGeneral:OpenItemInfoTipTop(oldRefId, oldNum, showBagNum, hide, hideOwnText, chatType, id,
                                showBtn, nil, oldForceNoShowBtn)
                    end, true)
        else
            --[[				GF.OpenWndUp("UIInip",{refId = refId,hide = true,hideOwnText = true,showBtn = true,chatType = chatType,showNum = oldNum,callFunc = function()
                                    gModelGeneral:OpenItemInfoTip(oldRefId,oldNum,showBagNum,hide,hideOwnText,nil,nil,chatType,id,showBtn)
                                end})]]

            local itemData = gModelItem:GetRefByRefId(refId)

            if itemData.type == ModelItem.TTEM_TYPE_EQUIP_STRENGTH_3 then

                gModelGeneral:OpenItemInfoTip(refId, oldNum, nil, true, true, share, shareFunc, chatType, nil, nil,
                        function()
                            gModelGeneral:OpenItemInfoTip(oldRefId, oldNum, showBagNum, hide, hideOwnText, share, shareFunc,
                                    chatType, id, showBtn, nil, oldForceNoShowBtn)
                        end, isNotShowBtn, 1)

            else


                gModelGeneral:OpenItemInfoTip(refId, oldNum, nil, true, true, share, shareFunc, chatType, nil, nil,
                        function()
                            gModelGeneral:OpenItemInfoTip(oldRefId, oldNum, showBagNum, hide, hideOwnText, share, shareFunc,
                                    chatType, id, showBtn, nil, oldForceNoShowBtn)
                        end, true)
            end


        end
        -- end
    elseif itype == LItemTypeConst.TYPE_HERO then
        local bagHero = itemdata.bagHero
        if bagHero then
            local serverData = gModelHero:GetHeroServerDataById(refId)
            local data = {
                id = refId,
                refId = serverData.refId,
                level = serverData.lv,
                star = serverData.star,
                grade = serverData.grade,
                fightPower = serverData.fightPower,
                isResonance = serverData.isResonance,
            }
            gModelHero:ReqShowHeroTip("", data)
        else
            gModelGeneral:OpenHeroSimpleTip(refId, true)
        end
    elseif itype == LItemTypeConst.TYPE_EQUIP then

        local quality = gModelEquip:GetEquipQualityByRefId(refId)
        if quality >= 7 then
            local itemdata = gModelEquip:GetEquipStructByRefId(refId)
            gModelGeneral:OpenEquipInfoTip(refId, nil, 3, false, nil, nil, nil, nil, true, itemdata)
        else
            gModelGeneral:OpenEquipInfoTip(refId, nil, 1, true)
        end
    elseif itype == LItemTypeConst.TYPE_GOLEM then
        gModelGeneral:ShowCommonItemTipWnd(itemdata)

        -- 【C宠物系统】删掉宠物系统相关
        -- elseif itype == LItemTypeConst.TYPE_PET then
        -- 	GF.OpenWnd("WndPetReviewPop",{refId = refId})
    elseif itype == LItemTypeConst.TYPE_PET_EQUIP then
        gModelGeneral:OpenEquipInfoTip(refId, nil, nil, true, nil, nil, nil, itype)
    end
end

function UIInip:ShowRuneSelTypeInfo()
    local ref = self._ref
    if not ref then
        return
    end
    local refId = self._refId
    local typeDataInfo = gModelItem:GetRuneSelTypeDataByRefId(refId)
    if not typeDataInfo then
        return
    end
    local descTitleId = 10240
    self:SetDescTxt(descTitleId ~= nil, ccLngText(ref.description), descTitleId)
    CS.ShowObject(self.mRuneSelDiv, true)
    local attrGroup = typeDataInfo.attrGroup
    local skillGroup = typeDataInfo.skillGroup
    self:SetTextTile(self.mSelDesc, ccClientText(24806))
    local attrLen = #attrGroup
    local attrStr = string.replace(ccClientText(24807), attrLen)
    local skillStr
    local textId
    local skillGroupRef
    for i, skillRefId in ipairs(skillGroup) do
        --textId = gModelRune:GetQualityTextIdByQuality(quality)
        skillGroupRef = gModelRune:RuneSkillGroupRefByRefId(skillRefId)
        if skillGroupRef then
            if skillStr then
                --skillStr = string.replace(ccClientText(24804),skillStr,ccClientText(textId))
                skillStr = string.replace(ccClientText(24804), skillStr, ccLngText(skillGroupRef.skillGroupName))
            else
                skillStr = ccLngText(skillGroupRef.skillGroupName)
            end
        end
    end
    skillStr = string.replace(ccClientText(24808), skillStr)
    local strList = { attrStr, skillStr }
    self:InitRuneSelList(strList)
end

function UIInip:ClickCell(day, status, redPointStatus)
    self:InitDaySignInList(nil, day, status)
end

function UIInip:OnDrawXuQiuCell(list, item, itemdata, itempos)
    local CommonUI = self:FindWndTrans(item, "CommonUI")
    local Icon = self:FindWndTrans(CommonUI, "Icon")

    local instanceId = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(Icon)
    local itype = itemdata.itype
    if itype == LItemTypeConst.TYPE_HERO then
        baseClass:SetHeroDataSet(itemdata.heroData)
    end
    baseClass:DoApply()
end

function UIInip:RefreshShowSlider()
    local showSlider = false
    local progress = 0
    local curNum = 0
    local maxNum = 0
    if self._type == gModelItem.TTEM_TYPE_HALIDOMITEM then
        local refId = self._refId
        local halidomRefId = gModelItem:GetItem2HalidomRefId(refId)
        if halidomRefId and halidomRefId > 0 then
            if not gModelHalidom:CheckHalidomObjIsMaxStarLv(halidomRefId) then
                curNum = gModelItem:GetNumByRefId(refId)
                local success = false
                if gModelHalidom:CheckIsHalidomObjAct(halidomRefId) then
                    local halidomObj = gModelHalidom:GetHalidomObjByRefId(halidomRefId)
                    if halidomObj then
                        local nextNum = gModelHalidom:GetSplitHalidomStarNextNumByRefId(halidomObj.starRefId)
                        if nextNum then
                            maxNum = nextNum.itemNum
                            progress = curNum / maxNum
                            showSlider = true
                            success = true
                        end
                    end
                end
                if not success then
                    local compoundNum = gModelItem:GetItem2HalidomCompoundNum(refId)
                    if compoundNum and compoundNum > 0 then
                        maxNum = compoundNum
                        progress = curNum / maxNum
                        showSlider = true
                    end
                end
            end
        end
    elseif self._type == gModelItem.TTEM_TYPE_DRACONIC_ITEM or self._type == gModelItem.TTEM_TYPE_DRACONIC then
        local starNum, draconicRefId = gModelDraconic:GetSpeechStarByItemId(self._refId)
        local costItem = gModelDraconic:GetUpStarCostRef(draconicRefId, starNum)
        if costItem then
            curNum = gModelItem:GetNumByRefId(self._refId)
            maxNum = costItem.count
            progress = curNum / maxNum
            showSlider = true
        end
    elseif self._type == gModelItem.TTEM_TYPE_PET then
        local petId = tonumber(self._ref.typeDate)
        local pet = gModelPet:GetPetById(petId)
        local starCfg = pet:GetPetStarCfg()
        local upNeed = (pet.isActive and starCfg.rankNext > 0) and GameTable.MagicPetStarRef[starCfg.rankNext].upNeed or starCfg.upNeed
        if not string.isempty(upNeed) and starCfg.rankNext > 0 then
            local cost = LUtil.GetRefItemData(upNeed)
            curNum = gModelItem:GetNumByRefId(cost.itemId)
            maxNum = cost.itemNum
            progress = curNum / maxNum
            showSlider = true
        end
    elseif self._type == gModelItem.TTEM_TYPE_DIVINE then
        local Id = tonumber(self._ref.typeDate)
        local cost = gModelDivineWeapon:GetUpStarCost(Id)
        if cost then
            curNum = gModelItem:GetNumByRefId(cost.itemId)
            maxNum = cost.itemNum
            progress = curNum / maxNum
            showSlider = true
        end
    end
    if showSlider then
        self:SetWndText(self.mShowSliderNum, string.replace(ccClientText(41518), curNum, maxNum))
        LxUiHelper.SetProgress(self.mShowSlider, progress)
    end
    CS.ShowObject(self.mShowSlider, showSlider)
end

function UIInip:btnListOnDraw(list, item, itemdata, itempos)
    local btnTrans = CS.FindTrans(item, "Btn")
    local code = itemdata.code

    local refId = self._refId
    local isLeiDeng = gModelItem:GetLeiDengItemByRefId(refId)
    local canGet = false
    local id = self._id
    if refId and id then
        canGet = gModelItem:CheckLeiDengIsGet(refId, id)
    end
    if btnTrans then
        self:SetWndClick(btnTrans, function()
            self:BtnEvent(code, itemdata)
        end)

        local isJump = code == 1014

        local isGray = false
        if isJump then
            local ref = gModelItem:GetRefByRefId(refId)
            local isOpen = gModelFunctionOpen:CheckIsOpened(ref.useJump)
            isGray = not isOpen
        end

        local icon = itemdata.icon
        self:SetWndButtonImg(btnTrans, icon)

        if isLeiDeng then
            local tShow = false
            if not self._share then
                tShow = not canGet
            end
            isGray = isGray or tShow
        end

        self:SetWndButtonGray(btnTrans, isGray)

        --local outLineRes = self:GetBtnOutLine(icon)
        --if outLineRes then
        --	self:SetWndButtonTextMat(btnTrans,outLineRes)
        --end
        local colorStr = self:GetBtnColor(icon)
        local color = LUtil.ColorByHex_6(colorStr)
        self:SetWndButtonTextColor(btnTrans, color)
        self:SetWndButtonText(btnTrans, itemdata.name)
    end

    local redPointTrans = CS.FindTrans(item, "redPoint")
    if redPointTrans then
        local show = ModelItem.ITEM_OLDEQUIPITEMLIST[self._refId] or false
        if isLeiDeng then
            show = canGet
        end
        CS.ShowObject(redPointTrans, show)
    end
end

function UIInip:ClickCellEvent(day, isOpen, isCurDay, isShowRedPoint, show)
    local status = isOpen
    if isCurDay then
        status = not isOpen
    else
        status = show
    end
    self:ClickCell(day, status, isShowRedPoint)
end

function UIInip:HeroListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local commonUI = self:FindWndTrans(root, "CommonUI/Icon")
    local name = self:FindWndTrans(root, "Name")

    local instanceID = item:GetInstanceID()
    local itemType = itemdata.itemType
    local itemId = itemdata.itemId
    local itemNum = itemdata.itemNum

    local uicommonlist = self._uiCommonList
    local baseClass = uicommonlist[instanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        uicommonlist[instanceID] = baseClass
        baseClass:Create(commonUI)
    end
    baseClass:SetCommonReward(itemType, itemId, itemNum)

    baseClass:DoApply()
    local itemName = gModelGeneral:GetCommonItemName({ itemType = itemType, itemId = itemId })
    self:SetWndText(name, itemName)
    self:InitTextShowWithLanguage(name)
    self:SetWndClick(item, function()
        if itemType == LItemTypeConst.TYPE_HERO then
            gModelGeneral:OpenHeroSimpleTip(itemId, true)
        else
            gModelGeneral:OpenItemInfoTip(itemId, itemNum)
        end
    end)
end

function UIInip:SetRefId(refId)
    self._refId = refId
end

function UIInip:RefreshDropDesc(dropInfo)
    local refId = self._refId
    local ref = gModelItem:GetRefByRefId(refId)
    if not ref then
        return
    end
    local itype = ref.type
    if itype ~= ModelItem.Item_DROPITEMTYPE then
        return
    end
    local group = dropInfo.group
    local typeDate = string.split(ref.typeDate, "|")
    local refGroup = tonumber(typeDate[1])
    if group ~= refGroup then
        return
    end
    local description = ccLngText(ref.description)
    description = string.replace(description, dropInfo.num)
    self:SetWndText(self.mDescTxt, description)
    self:RefreshDropShow(dropInfo, typeDate)
end

function UIInip:SetDescTxt(showDescDiv, description, titleId)
    CS.ShowObject(self.mDaoJuMiaoShuDiv, showDescDiv)
    if not showDescDiv then
        return
    end
    self:SetWndText(self.mTitle2, ccClientText(titleId))
    self:SetWndText(self.mDescTxt, description)
end

function UIInip:RefreshDropShow(dropInfo, typeData)
    CS.ShowObject(self.mMiniGuaranteeDiv, true)
    local allNum = tonumber(typeData[2]) + 1
    local num = dropInfo.num
    local showNum = allNum - num
    local str = string.replace(ccClientText(10249), showNum, allNum)
    self:SetWndText(self.mMiniGuaranteeTxt, str)
    local percentage = showNum / allNum
    LxUiHelper.SetProgress(self.mMiniGuaranteeBar, percentage)
end

function UIInip:InitNeedHeroUIList(list)
    local len = #list
    CS.ShowObject(self.mDaoJuXuQiuDiv, len > 0)
    local showMax = len > 4
    local showTrans = showMax and self.mXuQiuList or self.mXuQiuMinList
    local uiNeedHeroList = self._uiNeedHeroList
    if uiNeedHeroList then
        uiNeedHeroList:RefreshList(list)
    else
        uiNeedHeroList = self:GetUIScroll("uiNeedHeroList")
        self._uiNeedHeroList = uiNeedHeroList
        if showMax then
            uiNeedHeroList:Create(showTrans, list, function(...)
                self:OnDrawXuQiuCell(...)
            end, UIItemList.WRAP)
        else
            uiNeedHeroList:Create(showTrans, list, function(...)
                self:OnDrawXuQiuCell(...)
            end)
        end
    end
end

function UIInip:SetTimeTxt(showTime, titleTxt)
    CS.ShowObject(self.mDaoJuShiJianDiv, showTime)
    if not showTime then
        return
    end
    self:SetWndText(self.mTitle4, ccClientText(10219))
    self:SetWndText(self.mTimeTxt, titleTxt)
end

function UIInip:Update()
    if self._type == gModelItem.TTEM_TYPE_FISH_ROD then
        local num = gModelItem:GetNumByRefId(self._refId)
        if num > 0 then
            local strNum = ""
            local data = gModelFish:GetFishItemAttr(self._refId)
            if data.time <= 0 then
                -- 无期限
                strNum = ccClientText(44293)
            else
                local serData = gModelItem:GetItemServerDataByRefId(self._refId)
                local curTime = GetTimestamp()
                local createTime = serData:GetCreateTime() * 0.001 -- 其实是结束时间
                local leftTime = createTime - curTime
                if leftTime <= 0 then
                    -- 过期
                    strNum = ccClientText(44295)
                else
                    strNum = LUtil.FormatTimespanCn(math.ceil(leftTime))
                end
            end
            self:SetTextTile(self.mImgTime, strNum)
            CS.ShowObject(self.mImgTime, true)
            return
        end
    end

    CS.ShowObject(self.mImgTime, false)
    self:TimerStop(1)
end

function UIInip:InitRewardList(itemList, rewardTitleId)
    rewardTitleId = rewardTitleId or 10214
    self:SetWndText(self.mTitle3, ccClientText(rewardTitleId))
    local list = self:GetUIScroll("reward")
    list:Create(self.mRewardList, itemList, function(...)
        self:OnDrawRewardItem(...)
    end, UIItemList.WRAP, false)
    local uiList = list:GetList()
    uiList:EnableLoadAnimation(true, 0, 4)
    uiList:RefreshList(UIListWrap.RefreshMode.Solid)
end

-- 刷新灵魂星级列表
function UIInip:RefreshStarList()
    if not self.badgeSkillList then
        local uiList = self:GetUIScroll("mBadgeSkillList")
        self.badgeSkillList = uiList
        local badgeRefId = tonumber(self._ref.typeDate)
        local list = gModelBadge:GetBadgeStarRef(badgeRefId)
        uiList:Create(self.mBadgeSkillList, list, function(...)
            self:OnDrawStarListItem(...)
        end, UIItemList.SUPER, true)
    else
        self.badgeSkillList:DrawAllItems()
    end
end

function UIInip:ShowHeroNeedRuneList()
    local refId = self._refId
    if not refId then
        return
    end
    local heroList = {}
    local showNeedHeroType = gModelRune:GetConfig("showNeedHeroType")
    if showNeedHeroType == nil then
        showNeedHeroType = 1
    end
    local runeSkillList = gModelRune:GetRuneUpItemInfoByItemRefId(refId)
    if showNeedHeroType == 1 then
        local saveHeroList = {}

        for k, v in pairs(runeSkillList) do
            local heroServerDataList = gModelHero:GetNeedRuneListByRuneSkillRefId(nil, v, refId)
            for idx, heroServerData in ipairs(heroServerDataList) do
                if not saveHeroList[idx] then
                    saveHeroList[idx] = heroServerData
                end
            end
        end

        for k, v in pairs(saveHeroList) do
            table.insert(heroList, v)
        end
    elseif showNeedHeroType == 2 then
        for k, v in pairs(runeSkillList) do
            local tHeroList = gModelHero:GetRecommendRuneHeroInfoByRuneSkillRefId(v)
            for hRefId, val in pairs(tHeroList) do
                local heroServerDataList = gModelHero:GetNeedRuneListByRuneSkillRefId(hRefId, v, refId)
                for idx, heroServerData in ipairs(heroServerDataList) do
                    table.insert(heroList, heroServerData)
                end
            end
        end
    end
    self:InitNeedHeroUIList(heroList)
end

------------------------------------------------------------------
return UIInip