---
--- Created by Administrator.
--- DateTime: 2023/10/11 16:27:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITaltUp:LWnd
local UITaltUp = LxWndClass("UITaltUp", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaltUp:UITaltUp()
    ---@type table<number,CommonIcon>
    self._uiItemIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaltUp:OnWndClose()
    self:ClearCommonIconList(self._uiItemIconList)
    self._uiItemIconList = nil
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaltUp:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaltUp:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:SetWndText(self.mTitle, ccClientText(13235))
    local str = ccClientText(10016)
    self:SetWndText(self.mUpTxt, str)
    self:SetWndText(self.mUpTxt_1, ccClientText(18223))

    self:SetWndButtonText(self.mForgetBtn, ccClientText(13237))
    self:SetWndButtonText(self.mUpBtn, ccClientText(10000))
    self:SetWndText(self.mText, ccClientText(13238))

    self:InitData()
    self:InitEvent()
    self:InitMsg()
    self:Refresh()
end

function UITaltUp:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mForgetBtn, function()
        local func = function()
            gModelRune:OnRuneResetTalentReq(self._heroId, self._pos)
        end
        if self._talentId then
            local ref = self._ref
            local forgetNeed = ref.forgetNeed
            forgetNeed = string.split(forgetNeed, "=")
            local forgetName = gModelItem:GetNameByRefId(tonumber(forgetNeed[2]))
            forgetName = forgetNeed[3] .. forgetName

            --[[			local forgetGet = ref.forgetGet
                        forgetGet = string.split(forgetGet,"=")
                        local getName = gModelItem:GetNameByRefId(tonumber(forgetGet[2]))
                        getName = forgetGet[3] .. getName


                        local wndId = 50802
                        local openFunc = function()
                            GF.OpenWnd("UIOrdinTip",{refId = wndId,para = {forgetName,getName},func = func})
                        end
                        gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)]]
            local forgetList = {}
            local forgetGet = ref.forgetGet
            forgetGet = string.split(forgetGet, ",")
            for i, v in ipairs(forgetGet) do
                v = string.split(v, "=")
                table.insert(forgetList, { itype = tonumber(v[1]), refId = tonumber(v[2]), count = tonumber(v[3]) })
            end
            local wndId = 50802
            gModelGeneral:OpenUIOrdinTips({ refId = wndId, para = { forgetName }, itemList = forgetList, func = func })
            --local openFunc = function()
            --	GF.OpenWnd("UIOrdinTip",{refId = wndId,para = {forgetName},itemList = forgetList,func = func})
            --end
            --gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
        end
    end)
    self:SetWndClick(self.mUpBtn, function()
        local nextRef = self._nextRef
        if nextRef then
            local isUp, lostRefId = true, 0
            local upItem = nextRef.upItem
            upItem = string.split(upItem, ",")
            for i, v in ipairs(upItem) do
                local temp = string.split(v, "=")
                local itemRefId, itemNum = tonumber(temp[2]), tonumber(temp[3])
                local haveNum = gModelItem:GetNumByRefId(itemRefId)
                if haveNum < itemNum then
                    isUp, lostRefId = false, itemRefId
                    break
                end
            end
            if isUp then
                gModelRune:OnRuneUpTalentSkillReq(self._heroId, self._nextId, self._pos)
            else
                --GF.ShowMessage(ccClientText(10411))
                gModelGeneral:OpenGetWayWnd({ itemId = lostRefId })
            end
        end
    end)
end

function UITaltUp:InitMsg()
    self:WndNetMsgRecv(LProtoIds.RuneUpTalentSkillResp, function()
        self:WndClose()
    end)
    self:WndNetMsgRecv(LProtoIds.RuneResetTalentResp, function()
        self:WndClose()
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:Refresh()
    end)

end

-----------------------------------------------------------------
function UITaltUp:SetItemIcon(iconTrans, itemType, itemId, itemNum)
    local instanceId = iconTrans:GetInstanceID()
    local uiItemIconList = self._uiItemIconList
    local baseClass = uiItemIconList[instanceId]
    if not baseClass then
        baseClass = CommonIcon:New()
        uiItemIconList[instanceId] = baseClass
        baseClass:Create(iconTrans)
    end
    baseClass:SetCommonReward(itemType, itemId, itemNum or 0)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    self:SetIconClickScale(iconTrans, true)
    self:SetWndClick(iconTrans, function()
        --[[		local data =
                {
                    itemId = itemId,
                    itemType = itemType,
                    itemNum = itemNum,
                }
                gModelGeneral:ShowCommonItemTipWnd(data)]]

        gModelGeneral:OpenGetWayWnd({ itemId = itemId, srcWnd = self:GetWndName() })
    end)
end
-----------------------------------------------------------------

function UITaltUp:Refresh()
    local curRef = self._ref
    local nextId = curRef.nextId
    local skillLevel = curRef.skillLevel
    local skillName, skillDesc
    local curSkillId = tonumber(curRef.SkillId)
    local skillRef = gModelHero:GetSkillByStarId(curSkillId)
    if skillRef then
        skillName = ccLngText(skillRef.name)
        skillDesc = ccLngText(curRef.skillDesc)
    end
    local curBaseClass = SkillIcon:New(self)
    curBaseClass:Create(self.mSkillIcon, curSkillId)
    self:SetWndText(self.mSkillName, skillName)
    self:SetWndText(self.mSkillDesc, skillDesc)
    for i, v in ipairs(self._curStarList) do
        local show = true
        if i > skillLevel then
            show = false
        end
        CS.ShowObject(v, show)
    end

    local haveNext = nextId ~= -1
    CS.ShowObject(self.mNoRecord, not haveNext)
    CS.ShowObject(self.mUpDiv, haveNext)

    if haveNext then
        local nextRef = gModelRune:GetSkillInfoByRefId(nextId)
        self._nextRef = nextRef
        skillLevel = nextRef.skillLevel
        for i, v in ipairs(self._newStarList) do
            local show = true
            if i > skillLevel then
                show = false
            end
            CS.ShowObject(v, show)
        end
        self._nextId = nextId
        local nextSkillId = nextRef.SkillId
        local nextSkillRef = gModelHero:GetSkillByStarId(nextSkillId)
        skillName = ccLngText(nextSkillRef.name)
        skillDesc = ccLngText(nextRef.skillDesc)
        local newBaseClass = SkillIcon:New(self)
        newBaseClass:Create(self.mSkillIconNew, nextSkillId)

        self:SetWndText(self.mSkillNameNew, skillName)
        self:SetWndText(self.mSkillDescNew, skillDesc)
        self._payRefIdList = {}
        local upItem = nextRef.upItem
        upItem = string.split(upItem, ",")
        for i, v in ipairs(upItem) do
            local iconTrans, nameTrans, valueTrans = self._itemTransList[i], self._itemNameTransList[i], self._itemValueTransList[i]
            local temp = string.split(v, "=")
            local itemRefId, itemNum = tonumber(temp[2]), tonumber(temp[3])
            local itemType = tonumber(temp[1])

            table.insert(self._payRefIdList, {
                refId = itemRefId,
                count = itemNum
            })

            self:SetItemIcon(iconTrans, itemType, itemRefId, itemNum)

            local name = gModelItem:GetNameByRefId(itemRefId)
            self:SetWndText(nameTrans, name)
            local fcolor = gModelItem:GetItemNameColor(itemRefId)
            self:SetXUITextTransColor(nameTrans, fcolor)

            local haveNum = gModelItem:GetNumByRefId(itemRefId)
            local color = "139057ff"
            if haveNum < itemNum then
                color = "c81212ff"
            end
            haveNum = LUtil.NumberCoversion(haveNum)
            local tempNum = LUtil.NumberCoversion(itemNum)
            local str = string.replace(ccClientText(13236), color, haveNum, tempNum)
            self:SetWndText(valueTrans, str)
        end

        self:SetTalentAttr( self._talentId,nextId,haveNext)
    else
        CS.ShowObject(self.mUpBtn, false)
        local y = self.mForgetBtn.localPosition.y
        self.mForgetBtn.localPosition = Vector2(0, y)
        self._nextId = self._talentId
        local nextRef = gModelRune:GetSkillInfoByRefId(self._talentId)
        self._nextRef = nextRef
    end
end

function UITaltUp:InitData()
    self._heroId = self:GetWndArg("HeroId")
    self._talentId = self:GetWndArg("TalentId")
    self._pos = self:GetWndArg("pos")
    local ref = gModelRune:GetSkillInfoByRefId(self._talentId)
    self._ref = ref
    self._nextId = nil
    self._nextRef = nil
    self._itemTransList = {
        self.mItemIcon1,
        self.mItemIcon2
    }
    self._itemNameTransList = {
        self.mItemName1,
        self.mItemName2
    }
    self._itemValueTransList = {
        self.mItemValue1,
        self.mItemValue2
    }
    self._curStarList = {
        self.mStar1,
        self.mStar2,
        self.mStar3,
    }
    self._newStarList = {
        self.mStarNew1,
        self.mStarNew2,
        self.mStarNew3,
    }
    self._payRefIdList = {}
end

--region 获取属性相关的配置 --------------------------------------------------------------------------------
function UITaltUp:SetTalentAttr(refId, nextRefId, havenext)
    local attrTrans = {}
    attrTrans[1]={}
    attrTrans[2]={}
    --获下trans
    attrTrans[1].attrIcon = self:FindWndTrans(self.mAttr_1, "Image_Icon")
    attrTrans[1].attrName = self:FindWndTrans(self.mAttr_1, "Attr_Name")
    attrTrans[1].attrOld = self:FindWndTrans(self.mAttr_1, "Attr_Old")
    attrTrans[1].attrNew = self:FindWndTrans(self.mAttr_1, "Attr_New")
    attrTrans[1].attrArrow = self:FindWndTrans(self.mAttr_1, "AllowImg")

    attrTrans[2].attrIcon = self:FindWndTrans(self.mAttr_2, "Image_Icon")
    attrTrans[2].attrName = self:FindWndTrans(self.mAttr_2, "Attr_Name")
    attrTrans[2].attrOld = self:FindWndTrans(self.mAttr_2, "Attr_Old")
    attrTrans[2].attrNew = self:FindWndTrans(self.mAttr_2, "Attr_New")
    attrTrans[2].attrArrow = self:FindWndTrans(self.mAttr_2, "AllowImg")

    local attrlist = gModelRune:GetSkillAttrInfoByRefId(refId)

    if havenext then
        for k, attr in ipairs(attrlist) do
            if k <= #attrTrans then
                local attrConf = GameTable.RoleAttrRef[attr.refId]
                self:SetWndEasyImage(attrTrans[k].attrIcon, attrConf.icon)
                local attrNameStr=ccLngText(attrConf.name)
                self:SetWndText(attrTrans[k].attrName,attrNameStr)
                local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attr.refId,attr.numType,attr.value)
                self:SetWndText(attrTrans[k].attrOld,value)
            end
        end

        attrlist = gModelRune:GetSkillAttrInfoByRefId(nextRefId)

        for k, attr in ipairs(attrlist) do
            if k <= #attrTrans then
                local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attr.refId,attr.numType,attr.value)
                self:SetWndText(attrTrans[k].attrNew,value)
            end
        end

    end
end

--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UITaltUp


