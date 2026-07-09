---
--- Created by BY.
--- DateTime: 2023/10/6 21:23:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UICareColleWin:LWnd
local UICareColleWin = LxWndClass("UICareColleWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UICareColleWin:UICareColleWin()
    self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UICareColleWin:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UICareColleWin:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UICareColleWin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
end

function UICareColleWin:InitMessage()
    self:WndNetMsgRecv(LProtoIds.CombatResultSureResp, function(pb)
        self:RefreshData()
    end)
end

function UICareColleWin:OnClickCell(ref)
    if self._battleRefId[ref.functionId] then
        --ref.combatType
        gLFightManager:PrepareGoToBattle(ref.combatType, { targetId = self._battleRefId[ref.functionId] })
    else
        gModelFunctionOpen:Jump(ref.functionId, self:GetWndName())
    end
end

function UICareColleWin:RefreshData()
    local list = gModelCareSchool:GetCollegeFunctionListRef()
    local _uiList = self._uiList
    if not _uiList then
        _uiList = self:GetUIScroll("cell")
        _uiList:Create(self.mCellSuper, list, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER)
        _uiList:EnableScroll(true, false)
        self._uiList = _uiList
    else
        _uiList:RefreshList(list)
    end
    _uiList:MoveToPos()
end

function UICareColleWin:ListItem(list, item, itemdata, itempos)
    local InstanceID = item:GetInstanceID()
    local bg = CS.FindTrans(item, "Image")
    local nameText = CS.FindTrans(item, "TitleBg/NameText")
    local mask = CS.FindTrans(item, "Mask")
    local lockText = CS.FindTrans(item, "Mask/LockText")
    local desText = CS.FindTrans(item, "Image_1/DesText")
    local maskEff = CS.FindTrans(item, "MaskEff")

    local image_1 = CS.FindTrans(item, "Image_1")
    local image_2 = CS.FindTrans(item, "Image_2")
    local des_1 = CS.FindTrans(image_2, "DesText_1")
    local des_2 = CS.FindTrans(image_2, "DesText_2")
    CS.ShowObject(image_1, true)
    CS.ShowObject(image_2, false)

    local titleIcon = CS.FindTrans(item, "TitleBg/Icon")

    local isOpened = gModelFunctionOpen:CheckIsOpened(itemdata.functionId)
    local openTips = gModelFunctionOpen:GetOpenTips(itemdata.functionId)
    self:SetWndEasyImage(bg, itemdata.bg)
    self:SetWndText(nameText, ccLngText(itemdata.name))
    self:SetWndText(desText, ccLngText(itemdata.desc))

    self:SetWndEasyImage(titleIcon, itemdata.titleIcon, nil, true)


    if self._isEnus then
        self:InitTextSizeWithLanguage(nameText, -6)
    else
        self:InitTextSizeWithLanguage(nameText, -4)
    end

    local addLine = -60
    if gLGameLanguage:IsJapanRegion() then
        addLine = -70
    end

    if self._isVie then
        addLine = -20
    end

    self:InitTextLineWithLanguage(nameText, addLine)

    self:InitTextSizeWithLanguage(desText, -4)
    CS.ShowObject(mask, not isOpened)
    self:SetWndText(lockText, openTips)

    local inFight = gLFightManager:IsCombatTypeInFight(itemdata.combatType)
    CS.ShowObject(maskEff, inFight)

    local fightEffect  =  CS.FindTrans(maskEff, "FightEffect")
    if inFight then

        local isForeign = gLGameLanguage:IsForeignRegion()

        --local combatSpint = CS.FindTrans(maskEff, "MaskText/CombatSpint")
        --local textEff = CS.FindTrans(maskEff, "MaskText/TextEff")
        --local textTransList = {}
        --for i = 1, 6 do
        --    local image = self:FindWndTrans(textEff, "Image" .. i)
        --    table.insert(textTransList, image)
        --
        --    if isForeign then
        --        self:SetWndEasyImage(image, "trialcopy_ui_1", nil, true)
        --    end
        --
        --    if i > 3 then
        --        CS.ShowObject(image, not isForeign)
        --    end
        --end
        --self:SetSpine(combatSpint, InstanceID, "jian", 1)
        --self:SetTextEff(textTransList, InstanceID)
        --


        self:CreateWndEffect(fightEffect, "jian", "chapter" .. itempos, 100, false, false, nil, nil, nil, nil, nil, nil, 10)
    else
        --self:SetTextEff(nil, InstanceID)

    end

    CS.ShowObject(fightEffect, inFight)

    self:SetWndClick(item, function()
        if inFight then
            gLFightManager:PrepareGoToBattle(itemdata.combatType, {})
        else
            if isOpened then
                self:OnClickCell(itemdata)
            else
                GF.ShowMessage(openTips)
            end
        end
    end)

    --获取对应battleId

    local otherRefId = self._battleOtherRefId[itemdata.functionId]
    if otherRefId then
        local list = gModelCareSchool:GetSimulationHurtList()

        local battleRefId = self._battleRefId[itemdata.functionId]
        local str_1
        local str_2
        if battleRefId then
            local battleRef = gModelCareSchool:GetCollegeSimulationRefByRefId(battleRefId)
            --设置第一个
            local recordNum_1 = list[battleRef.refId] or 0
            str_1 = string.replace(ccClientText(44902), recordNum_1)

        end

        local otherBattleRef = gModelCareSchool:GetCollegeSimulationRefByRefId(otherRefId)
        local recordNum_2 = list[otherBattleRef.refId] or 0
        str_2 = string.replace(ccClientText(44903), recordNum_2)

        CS.ShowObject(image_1, false)
        CS.ShowObject(image_2, true)
        self:SetWndText(des_1, str_1)
        self:SetWndText(des_2, str_2)
    end
end

function UICareColleWin:InitCommand()
    self._battleRefId = {
        [19103000] = 3,
        [19102000] = 1,
    }
    self._battleOtherRefId = {
        [19102000] = 2,
    }

    gModelCareSchool:OnCollegeInfoReq()
    self:SetWndText(self.mTitle, ccClientText(20900))
    --self:SetWndText(self.mTitleText, ccClientText(20900))
    self:SetWndText(self.mRecordUIText, ccClientText(42011))--[42011]  [戰報]
    self:SetWndText(self.mRankUIText, ccClientText(36305))  --[36305]	[排行榜]
    --printInfoN2("----------cjh ---------redpoint--19100000", gModelRedPoint:CheckShowRedPoint(19100000))
    --printInfoN2("----------cjh ---------redpoint--19101000", gModelRedPoint:CheckShowRedPoint(19101000))
    self:RefreshData()
end

function UICareColleWin:SetSpine(paintTans, key, name, scale)
    --设置Spine
    local spine = self:FindWndSpineByKey(key)
    if (spine) then
        self:DestroyWndSpineByKey(key)
    end
    self:CreateWndSpine(paintTans, name, key, false, function(dpSpine)
        dpSpine:SetScale(scale)
    end)
end

function UICareColleWin:SetTextEff(transs, key)
    local seqTween
    self:TweenSeqKill(key)
    if (not transs or #transs < 1) then
        return
    end
    if not seqTween then
        seqTween = self:TweenSeqCreate(key, function(seq)
            local moveTime = 0.2
            local moveH = 10
            for i, v in ipairs(transs) do
                local pos = Vector2.New(v.localPosition.x, v.localPosition.y + moveH)
                local moveTween = v:DOLocalMove(pos, moveTime)
                seq:Append(moveTween)
            end
            for i, v in ipairs(transs) do
                local pos = Vector2.New(v.localPosition.x, v.localPosition.y)
                local moveTween = v:DOLocalMove(pos, moveTime)
                seq:Append(moveTween)
            end
            seq:SetLoops(-1)
            seq:Play()
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(key)

    end)
end

function UICareColleWin:InitEvent()
    self:SetWndClick(self.mBtnClose, function()
        GF.OpenWndBottom("UIOutts")
        self:WndClose()
    end)

    self:SetWndClick(self.mRecord, function()
        GF.OpenWnd("UICareColleReportPop")
    end)

    self:SetWndClick(self.mRank, function()
        GF.OpenWndBottom("UIRkPop", { refId = ModelRank.RANK_1600 })
    end)
end
------------------------------------------------------------------
return UICareColleWin


