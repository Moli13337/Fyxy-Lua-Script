---
--- Created by Administrator.
--- DateTime: 2023/10/27 17:39:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISnTip:LWnd
local UISnTip = LxWndClass("UISnTip", LWnd)
local Time = Time
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISkillCtrl = LxRequire("LApp.UI.Display.LUISkillCtrl")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISnTip:UISnTip()
    ---@type CommonIcon
    self._itemIconCls = nil

    ---@type table<string,LUIHeroObject>
    self._uiHeroObjList = nil            -- spine列表
    ---@type LUIHeroObject
    self._curUIHeroObj = nil            -- 当前spine
    ---@type LUISkillCtrl
    self._uiSkillCtrl = nil

    self._loopHeroObjTimerKey = 1119
    self._heroSize = 1.6
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISnTip:OnWndClose()
    LUtil.ClearHashTable(self._uiHeroObjList)
    self._uiHeroObjList = nil

    if self._uiSkillCtrl then
        self._uiSkillCtrl:Destroy()
        self._uiSkillCtrl = nil
    end

    if self._itemIconCls then
        self._itemIconCls:Destroy()
        self._itemIconCls = nil
    end

    if self._callFunc then
        self._callFunc()
    end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISnTip:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISnTip:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:CreateWndEffect(self.mEffRoot, "fx_shouchong_guanghuan_01", "fx_shouchong_guanghuan_01", 150, false, false, 4, nil, 150)
    self:CreateWndEffect(self.mGuangRoot, "fx_shouchong_guanghuan_01_up", "fx_shouchong_guanghuan_01_up", 150, false, false, 8, nil, 150)
    self:InitEvent()
    self:InitMsg()
    self:InitData()
end

--设置形象
function UISnTip:SetSpine(paintTans, ref, key)
    --local paintFlip=ref.paintFlip2==1
    --local paintMultiple=ref.paintMultiple2
    self:CreateWndSpine(paintTans, ref.spine, key, false, function(dpSpine)
        dpSpine:SetScale(1.5)
        --dpSpine:SetFlipX(paintFlip)
        --local dpTrans =dpSpine:GetDisplayTrans()
        --dpTrans.anchorMin = Vector2.New(0.5,0.5)
        --dpTrans.anchorMax = Vector2.New(0.5,0.5)
    end)
end

-- 创建spine
function UISnTip:CreateHeroSpine(prefabName, heroRefId, star, heroEffId)
    local uiHeroObjList = self._uiHeroObjList
    if not uiHeroObjList then
        uiHeroObjList = {}
        self._uiHeroObjList = uiHeroObjList
    end

    local refId = self._refId

    if self._uiSkillCtrl then
        self._uiSkillCtrl:Destroy()
        self._uiSkillCtrl = nil
    end

    local newUIHeroObj = uiHeroObjList[prefabName]
    local oldUIHeroObj = self._curUIHeroObj
    if oldUIHeroObj and newUIHeroObj ~= oldUIHeroObj then
        oldUIHeroObj:ShowHero(false)
    end
    if not newUIHeroObj then
        newUIHeroObj = LUIHeroObject:New(self)
        uiHeroObjList[prefabName] = newUIHeroObj
        self._curUIHeroObj = newUIHeroObj
        newUIHeroObj:Create(self.mSpineRoot, prefabName, prefabName)
        newUIHeroObj:SetScale(self._heroSize)
        -- newUIHeroObj:SetClickFunc(function(...)
        --     self:OnClickHeroSpine(...)
        -- end)
        newUIHeroObj:SetHeroData(nil, heroRefId, star, heroEffId, true)
        -- newUIHeroObj:SetLoadedFunction(function(...)
        --     self:OnClickHeroSpine(...)
        -- end)
        newUIHeroObj:ShowHero(true)
        newUIHeroObj:StartLoad()
    else
        self._curUIHeroObj = newUIHeroObj
        newUIHeroObj:SetHeroData(nil, heroRefId, star, heroEffId, true)
        newUIHeroObj:ShowHero(true)
    end

    self:StartHeroObjRunTimer()
end

function UISnTip:GetBtnOutLine(icon)
    local nameOutlines = {
        ["public_btn_1_1"] = "SourceHanSerifCN_132262_2",
        ["public_btn_1_2"] = "SourceHanSerifCN_442a00_2",
        ["public_btn_1_3"] = "SourceHanSerifCN_550b00_2",
        ["public_btn_ash_1"] = "SourceHanSerifCN_000000_2"
    }
    return nameOutlines[icon]
end

function UISnTip:OnShowLiHui()

    if self._heroRefId then
        GF.OpenWndUp("UISagaLiHuiSow", { selSkinRefId = self._heroRefId })

    end
end

function UISnTip:InitData()
    self._refId = self:GetWndArg("refId")
    self._showNum = self:GetWndArg("showNum")
    self._showBagNum = self:GetWndArg("showBagNum")
    self._hideNum = self:GetWndArg("hide")
    self._hideOwnText = self:GetWndArg("hideOwnText")
    self._share = self:GetWndArg("share")
    self._shareFunc = self:GetWndArg("shareFunc")
    self._callFunc = self:GetWndArg("callFunc")
    self._appointBtnCode = self:GetWndArg("appointBtnCode")
    self._forceNoShowBtn = self:GetWndArg("forceNoShowBtn")

    local refId = self._refId
    self._type = gModelItem:GetType(refId)
    if refId then
        local serverData = gModelItem:GetItemServerDataByRefId(refId)
        local num
        if serverData then
            num = serverData:GetNum()
        else
            num = 0
        end
        local ref = gModelItem:GetRefByRefId(refId)
        if not ref then
            return
        end
        self._ref = ref
        local quaId = ref.quality
        local heroMessage = gModelItem:GetHeroMessQualityById(quaId)
        if heroMessage then
            self:SetWndEasyImage(self.mHeadImg, heroMessage)
        end
        local color = gModelItem:GetColorByQualityId(quaId)
        if color then
            self:SetXUITextColor(self.mNameTxt, color)
        end
        local name = ccLngText(ref.name)
        self:SetXUITextText(self.mNameTxt, name)

        local str = ccClientText(10257)
        -- 显示的数量和是否显示背包数量
        if self._showNum and not self._showBagNum then
            num = self._showNum
            str = ccClientText(10211)
            str = string.replace(str, num)
        else
            str = str .. num
        end
        self:SetXUITextText(self.mNumTxt, str)
        if color then
            self:SetXUITextColor(self.mNumTxt, color)
        end
        if self._hideOwnText ~= nil then
            CS.ShowObject(self.mNumTxt, not self._hideOwnText)
        end
        local isCharacterSet = false
        local typeDate = string.split(ref.typeDate, "=")
        if ref.type == ModelItem.Item_CHARACTERSET and typeDate[1] and typeDate[1] == "4" then
            isCharacterSet = true
        end
        if isCharacterSet then
            local roleRefId = tonumber(typeDate[2])
            local roleRef = gModelPlayer:GetRoleAdventureImageRefByRefId(roleRefId)
            local attr = roleRef.attributes
            self:CreateAttrList(attr)
            self:SetSpine(self.mSpineRoot, roleRef, roleRef.spine)
            local timeStr = ""
            local times = tonumber(typeDate[4])
            if times == -1 or times == 0 then
                timeStr = ccClientText(14300)
            else
                timeStr = LUtil.FormatTimeToMin(times)
            end
            -- local fTimeStr = string.replace(ccClientText(17412),timeStr)
            self:SetWndText(self.mTimeTxt, ccClientText(17428) .. timeStr)
            if color then
                self:SetXUITextColor(self.mTimeTxt, color)
            end
        else
            local timeStr, heroEffId, heroRefId
            local typeDate = string.split(ref.typeDate, "=")
            local times = tonumber(typeDate[2])
            if times == -1 or times == 0 then
                timeStr = ccClientText(14300)
            else
                timeStr = LUtil.FormatTimeToMin(times)
            end
            heroEffId = tonumber(typeDate[1])
            heroRefId = tonumber(typeDate[3])
            --timeStr = ccClientText(17412) .. ":" .. timeStr
            -- local fTimeStr = string.replace(ccClientText(17412),timeStr)
            self:SetWndText(self.mTimeTxt, ccClientText(17428) .. timeStr)

            local star = gModelHero:GetHeroInitStarByRefId(heroRefId)
            if color then
                self:SetXUITextColor(self.mTimeTxt, color)
            end
            if heroEffId and star then
                local heroEffRef = gModelHero:GetShowEffectById(heroEffId)
                if heroEffRef then
                    local attr = heroEffRef.attr
                    self:CreateAttrList(attr)

                    --这里加入全属性的计算就可以了
                    local allAttr = heroEffRef.attrAll
                    self:CreateAttrList(allAttr, true)
                    local prefabName = heroEffRef.prefabName
                    self:CreateHeroSpine(prefabName, heroRefId, star, heroEffId)

                    self._heroRefId = heroRefId
                end
            end
        end
        self:SetWndText(self.mTitle_Quan, ccClientText(17431))
        self:SetWndText(self.mTitle1, ccClientText(17413))
        self:SetWndText(self.mTitle2, ccClientText(17414))

        local description = ccLngText(ref.description)
        self:SetWndText(self.mDescTxt, description)

        local commonTrans = CS.FindTrans(self.mItemInfo, "ItemIcon")
        if commonTrans then
            local itemIconCls = self._itemIconCls
            if not itemIconCls then
                itemIconCls = CommonIcon:New()
                self._itemIconCls = itemIconCls
                itemIconCls:Create(commonTrans)
            end
            itemIconCls:SetCommonReward(LItemTypeConst.TYPE_ITEM, refId, num)
            itemIconCls:EnableShowNum(not self._hideNum)
            itemIconCls:DoApply()
        end

        if self._showNum ~= nil then
            local showMax = true
            if self._appointBtnCode ~= nil then
                self:InitBtnList()
            else
                showMax = false
                CS.ShowObject(self.mBtnBg, false)
            end
            --CS.ShowObject(self.mTipBg2,showMax)
            --CS.ShowObject(self.mTipBg3,not showMax)
        else
            local showMax = true
            if self._appointBtnCode ~= nil then
                -- 通过指定按钮code来显示按钮
                self:InitBtnList()
            else
                local btn = ref.btn
                local isNoShowBtnList = string.isempty(btn)
                if self._forceNoShowBtn then
                    isNoShowBtnList = true
                end
                if isNoShowBtnList then
                    showMax = false
                    CS.ShowObject(self.mBtnBg, false)
                else
                    self:InitBtnList()
                end
            end
            --CS.ShowObject(self.mTipBg2,showMax)
            --CS.ShowObject(self.mTipBg3,not showMax)
        end
    end
end

function UISnTip:OnDrawAttrCell(list, item, itemdata, itempos)
    local AttrIconTrans = self:FindWndTrans(item, "AttrIcon")
    local AttrNameTrans = self:FindWndTrans(item, "AttrName")
    local AttrValueTrans = self:FindWndTrans(item, "AttrValue")
    local attrType, attrRefId, attrValue = itemdata.attrType, itemdata.attrRefId, itemdata.attrValue
    if AttrIconTrans then
        local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
        self:SetWndEasyImage(AttrIconTrans, attrIcon, function()
            CS.ShowObject(AttrIconTrans, true)
        end)
    end
    if AttrNameTrans then
        local attrName = gModelHero:GetAttributeNameById(attrRefId)
        self:SetWndText(AttrNameTrans, attrName)
    end
    if AttrValueTrans then
        local attrStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, attrType, attrValue)
        self:SetWndText(AttrValueTrans, attrStr)
    end
end

function UISnTip:btnListOnDraw(list, item, itemdata, itempos)
    local btnTrans = CS.FindTrans(item, "Btn")
    local btnNameTrans = CS.FindTrans(btnTrans, "BtnName")
    if btnTrans then
        self:SetWndClick(btnTrans, function()
            local code = itemdata.code
            self:BtnEvent(code)
        end)
        local icon = itemdata.icon
        self:SetWndEasyImage(btnTrans, icon)

        -- local outLineRes = self:GetBtnOutLine(icon)
        -- if outLineRes then
        -- 	self:SetWndTextMat(btnNameTrans,outLineRes)
        -- end
    end
    if btnNameTrans then
        local name = itemdata.name
        self:SetWndText(btnNameTrans, name)
    end
end

function UISnTip:InitBtnList()
    CS.ShowObject(self.mBtnBg, true)
    local refId = self._refId
    local typeList
    if self._share then
        typeList = {
            [1] = { btnId = 3333, name = ccClientText(12116), icon = "public_btn_1_1" }
        }
    elseif self._appointBtnCode ~= nil then
        typeList = gModelItem:GetAppointCode(self._appointBtnCode)
    else
        typeList = gModelItem:GetBtnType(refId)
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
    for i = 1, #typeList do
        local data = typeList[i]
        uiList:AddData(i, data)
    end
    uiList:RefreshList()
end

function UISnTip:StartHeroObjRunTimer()
    if self:IsTimerExist(self._loopHeroObjTimerKey) then
        return
    end
    self:TimerStart(self._loopHeroObjTimerKey, 0, false, -1)
end

function UISnTip:OnClickHeroSpine(heroObj)
    if self._curUIHeroObj == nil then
        return
    end
    if self._curUIHeroObj ~= heroObj then
        return
    end
    local spine = self._curUIHeroObj:GetDpObject()
    if not spine then
        return
    end
    local nowPlayAniName = spine:GetCurTrackEntryName()
    if nowPlayAniName == nil or nowPlayAniName == "idle" then
        local panelPlayEff = heroObj:RandomOneSkill()
        if not panelPlayEff then
            heroObj:PlayAttackAni()
            return
        end

        local skillCtr = self._uiSkillCtrl
        if skillCtr then
            skillCtr:Destroy()
            skillCtr = nil
        end

        skillCtr = LUISkillCtrl:New(self)
        self._uiSkillCtrl = skillCtr

        skillCtr:InitData(heroObj, panelPlayEff, self.mHeroEffRoot, 6, 6, self._heroSize * 100)
        skillCtr:PreLoadPlaySkill()
    end
end

function UISnTip:InitMsg()
    self:WndNetMsgRecv(LProtoIds.ItemUseResp, function()
        if self._useSkin then
            self._callFunc = nil
        end
        self:WndClose()
    end)
    self:WndNetMsgRecv(LProtoIds.SellGoodsResp, function()
        GF.ShowMessage(ccClientText(10225))
        self:WndClose()
    end)
end

function UISnTip:InitEvent()
    self:SetWndClick(self.mBg, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mShowLiHui, function()
        self:OnShowLiHui()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UISnTip:OnTimer(key)
    if key == self._loopHeroObjTimerKey then
        local time = Time.unscaledTime
        if self._curUIHeroObj then
            self._curUIHeroObj:OnRun(time)
        end
        if self._uiSkillCtrl then
            self._uiSkillCtrl:OnRun(time)
        end
    end
end

function UISnTip:BtnEvent(code)
    local closeStatus = false
    if code then
        local itype = self._type
        closeStatus = gModelItem:GetWndNameByType(itype, self._refId, code)
    else
        closeStatus = true
        if self._shareFunc then
            self._shareFunc()
        end
    end
    if closeStatus then
        if code == 1016 then
            self._callFunc = nil
        end
        self:WndClose()
    else
        if code == 1015 then
            self._useSkin = true
        end
    end
end

function UISnTip:CreateAttrList(attrList, isall)
    if string.isempty(attrList) then
        if isall then
            CS.ShowObject(self.mDaoJuQuanZuoYongDiv, false)
        end
        return
    end
    if isall then
        CS.ShowObject(self.mDaoJuQuanZuoYongDiv, true)
    end
    attrList = string.split(attrList, ",")

    local dataList = {}
    for i, v in ipairs(attrList) do
        v = string.split(v, "=")
        table.insert(dataList, {
            attrType = tonumber(v[2]),
            attrRefId = tonumber(v[1]),
            attrValue = tonumber(v[3]),
        })
    end

    local listTrans = isall and self.mQuanAttrList or self.mAttrList
    local key = isall and "attrListAll" or "attrList"

    local uiList = self:GetUIScroll(key)
    uiList:Create(listTrans, dataList, function(...)
        self:OnDrawAttrCell(...)
    end, UIItemList.NORMAL)
    uiList:EnableScroll(false)
end
------------------------------------------------------------------
return UISnTip


