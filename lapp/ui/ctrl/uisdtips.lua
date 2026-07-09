---
--- Created by Administrator.
--- DateTime: 2024/5/22 21:21:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISdTips:LWnd
local UISdTips = LxWndClass("UISdTips", LWnd)
------------------------------------------------------------------
local typeof_LayoutElement = typeof(UnityEngine.UI.LayoutElement)

--- 操作按钮状态
UISdTips.BTN_OPT_NORMAL = 0
UISdTips.BTN_OPT_ACT = 1
UISdTips.BTN_OPT_UPSTAR = 2

--- 正常
UISdTips.TYPE_WND_NORMAL = 0
--- 满星预览
UISdTips.TYPE_WND_FULLMAX = 1
--- 操作弹窗
UISdTips.TYPE_WND_OPT = 2
--- 满星预览 无按钮状态
UISdTips.TYPE_WND_NOTOPTFULLMAX = 3

UISdTips.SHOW_MAXPRE = {
    [UISdTips.TYPE_WND_FULLMAX] = true,
    [UISdTips.TYPE_WND_NOTOPTFULLMAX] = true,
}

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISdTips:UISdTips()
    self._typeWnd = UISdTips.TYPE_WND_NORMAL
    self._optState = UISdTips.BTN_OPT_NORMAL

    --- 道具数据结构
    self._nextNumItem = nil

    ---@type StructHalidomObjInfo
    self._halidomObj = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISdTips:OnWndClose()
    FireEvent(EventNames.REFRESH_BOOK_VIEW)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISdTips:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISdTips:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    CS.ShowObject(self.mTakeEffectDesc_Spacing_enus, self._isEnus)

    if self._isEnus then
        self.mTakeEffectDiv_enus.localPosition = self.mTakeEffectDiv_enus.localPosition + Vector3.New(-17, 0, 0)
    end

    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:RefreshView()
    self:RefreshForeign()
end

function UISdTips:InitTakeEffectAttrList(list)
    local uiList = self:FindUIScroll("mTakeEffectAttrList")
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("mTakeEffectAttrList")
        uiList:Create(self.mTakeEffectAttrList, list, function(...)
            self:OnDrawTakeEffectAttrCell(...)
        end)
    end
end

function UISdTips:OnDrawTakeEffectAttrCell(list, item, itemdata, itempos)
    local AttrIcon = self:FindWndTrans(item, "AttrIconDiv/AttrIcon")
    local AttrInfo = self:FindWndTrans(item, "AttrInfo")

    local attrRefId = itemdata.attrRefId
    local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
    self:SetWndEasyImage(AttrIcon, attrIcon, function()
        CS.ShowObject(AttrIcon, true)
    end)

    local name = gModelHero:GetAttributeNameById(attrRefId)
    local valStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, itemdata.attrType, itemdata.attrNum)
    local infoStr = string.replace(ccClientText(41536), name, valStr)
    self:SetWndText(AttrInfo, infoStr)
end

function UISdTips:SetHalidomIcon()
    local trans = self.mHalidomIcon
    local Icon = self:FindWndTrans(trans, "Icon")
    local key = trans:GetInstanceID()
    local baseIcon = self:GetCommonIcon(key)
    baseIcon:Create(Icon)
    if self._halidomObj then
        baseIcon:SetHalidomObj(self._halidomObj)
    else
        baseIcon:SetHalidomRefId(self._refId)
        local bMaxLv = UISdTips.SHOW_MAXPRE[self._typeWnd]
        baseIcon:SetHalidomShowMaxStarImg(bMaxLv)
    end
    baseIcon:DoApply()
    baseIcon:ChangeHalidomToTipsState()
end

function UISdTips:GetBaseAttrList()
    local list = {}
    local typeWnd = self._typeWnd
    if UISdTips.SHOW_MAXPRE[typeWnd] then
        --- 显示满星的基础属性加成
        local lastRef = gModelHalidom:GetInitLastHalidomStarRef(self._refId)
        if lastRef then
            list = gModelHalidom:GetLastHalidomStarAttrList(lastRef.refId)
        end
    elseif typeWnd == UISdTips.TYPE_WND_OPT then
        local halidomObj = self._halidomObj
        if halidomObj then
            list = gModelHalidom:GetHalidomObjStarAttrListByObj(halidomObj)
        end
    end
    table.sort(list, function(a, b)
        local sortA, sortB = gModelHero:GetAttributeSortById(a.attrRefId), gModelHero:GetAttributeSortById(b.attrRefId)
        return sortA < sortB
    end)
    return list
end

function UISdTips:InitText()
    self:SetWndText(self.mTakeEffectDesc, ccClientText(41539))
    self:SetTextTile(self.mMaxPreDiv, ccClientText(41526))
    self:SetTextTile(self.mBaseAttrTitle, ccClientText(41523))
    self:SetTextTile(self.mPassivitySkillTitle, ccClientText(41524))
end

function UISdTips:InitPassivitySkillDescList()
    local list = self:GetPassivitySkillDescList()
    local listLen = #list
    local isEnabled = false
    local height = 0
    local csLayoutElement = self.mPassivitySkillDescList:GetComponent(typeof_LayoutElement)
    if listLen > 2 then
        height = 320
        if csLayoutElement then
            isEnabled = true
            csLayoutElement.preferredHeight = height
        end
    end
    csLayoutElement.enabled = isEnabled

    local uiList = self:FindUIScroll("mPassivitySkillDescList")
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("mPassivitySkillDescList")
        uiList:Create(self.mPassivitySkillDescList, list, function(...)
            self:OnDrawPassivitySkillDescCell(...)
        end)
    end
    uiList:EnableScroll(true)
end

function UISdTips:GetPassivitySkillDescList()
    local list = {}
    local typeWnd = self._typeWnd
    if UISdTips.SHOW_MAXPRE[typeWnd] then
        --- 读取所有的描述
        local refs = gModelHalidom:GetInitHalidomStarRefs(self._refId)
        if refs and #refs > 0 then
            for i, v in ipairs(refs) do
                table.insert(list, {
                    desc = ccLngText(v.desc),
                    lockDesc = "",
                    showLock = false,
                })
            end
        end
    elseif typeWnd == UISdTips.TYPE_WND_OPT then
        --- 满星则隐藏下星增益描述
        local halidomObj = self._halidomObj
        if halidomObj then
            local halidomRefId = halidomObj.refId
            local starLv = halidomObj.starLv
            local curStarRefId = gModelHalidom:GetHalidomStarRefId(halidomRefId, starLv)
            local curDesc = gModelHalidom:GetHalidomStarDescByRefId(curStarRefId)
            if not string.isempty(curDesc) then
                table.insert(list, {
                    desc = curDesc,
                    lockDesc = "",
                    showLock = false,
                })
            end

            local nextStarLv = starLv + 1
            local nextStarRefId = gModelHalidom:GetHalidomStarRefId(halidomRefId, nextStarLv)
            if nextStarRefId and nextStarRefId > 0 then
                table.insert(list, {
                    desc = gModelHalidom:GetHalidomStarDescByRefId(nextStarRefId),
                    lockDesc = string.replace(ccClientText(41530), nextStarLv),
                    showLock = true,
                })
            end
        end
    end
    return list
end

function UISdTips:OnDrawPassivitySkillDescCell(list, item, itemdata, itempos)
    local Desc = self:FindWndTrans(item, "Desc")
    local LockDesc = self:FindWndTrans(item, "LockDesc")
    self:SetWndText(Desc, itemdata.desc)
    local showLock = itemdata.showLock
    if showLock then
        self:SetWndText(LockDesc, itemdata.lockDesc)
    end
    CS.ShowObject(LockDesc, showLock)
end

function UISdTips:RefreshForeign()
    if self._isVie then
        local textTran = CS.FindTrans(self.mMaxPreDiv, "UIText")
        self:SetAnchorPos(textTran, Vector2.New(3, 0))
    end
end

function UISdTips:RefreshCommon()
    if not self._refId then
        return
    end

    self:SetHalidomIcon()

    local refId = self._refId
    self:SetWndText(self.mHalidomName, gModelHalidom:GetHalidomNameByRefId(refId))

    local type = gModelHalidom:GetHalidomTypeByRefId(refId)
    local typeStr = string.replace(ccClientText(41527), gModelHalidom:GetHalidomTypeNameByRefId(type))
    self:SetWndText(self.mHalidomTypeName, typeStr)

    self:SetWndText(self.mStoryDesc, gModelHalidom:GetHalidomDescByRefId(refId))
end

function UISdTips:OnClickBtnOptFunc()
    if not self._refId then
        return
    end
    if not self._nextNumItem then
        return
    end

    local nextNumItem = self._nextNumItem
    if not gModelGeneral:CheckItemEnough(nextNumItem.itemId, nextNumItem.itemNum, true, self:GetWndName(), nil, nil, function()
        local jumpBackCB = self:GetWndArg("jumpBackCB")
        if jumpBackCB then
            jumpBackCB()
        end
        GF.CloseWndByName("UISdTips")
    end) then
        return
    end

    if self._optState == UISdTips.BTN_OPT_ACT then
        gModelHalidom:OnHalidomStarUpReq(self._refId)
    elseif self._optState == UISdTips.BTN_OPT_UPSTAR then
        gModelHalidom:OnHalidomStarUpReq(self._refId)
    end
end

function UISdTips:RefreshBotDiv()
    local btnName = ""
    local showBot = false
    local showFullStar = false
    local nextNumItem = nil
    local typeWnd = self._typeWnd
    local optState = UISdTips.BTN_OPT_NORMAL
    if typeWnd == UISdTips.TYPE_WND_FULLMAX then
        local numItem = gModelHalidom:GetSplitHalidomNumItemByRefId(self._refId)
        if numItem then
            nextNumItem = numItem

            btnName = ccClientText(41541)

            optState = UISdTips.BTN_OPT_ACT

            showBot = true
        end
    elseif typeWnd == UISdTips.TYPE_WND_OPT then
        local halidomObj = self._halidomObj
        if halidomObj then
            local starRefId = halidomObj.starRefId
            nextNumItem = gModelHalidom:GetSplitHalidomStarNextNumByRefId(starRefId)
            showFullStar = gModelHalidom:CheckHalidomStarIsMax(starRefId)

            btnName = ccClientText(41540)

            optState = UISdTips.BTN_OPT_UPSTAR

            showBot = true
        end
    end
    self._optState = optState

    self._nextNumItem = nextNumItem

    local progress = 0
    local optStr = ""
    local showItem = false
    if nextNumItem then
        local hasNum = gModelItem:GetNumByRefId(nextNumItem.itemId)
        local itemNum = nextNumItem.itemNum
        optStr = string.replace(ccClientText(41518), hasNum, itemNum)
        progress = hasNum / itemNum
        showItem = true
    end

    local slider = self:UIProgressFind(self.mOptSlider, "mOptSlider", progress)
    slider:SetUIProgress(progress)

    self:SetWndText(self.mOptNum, optStr)
    self:SetWndButtonText(self.mBtnOpt, btnName)

    CS.ShowObject(self.mOptDiv, showItem)
    CS.ShowObject(self.mFullStarDiv, showFullStar)
    CS.ShowObject(self.mBotDiv, showBot)
    CS.ShowObject(self.mTipBg2, showBot)

    local showHideDiv = not showBot
    CS.ShowObject(self.mHideDiv, showHideDiv)
    CS.ShowObject(self.mTipBg3, showHideDiv)
end

function UISdTips:InitBaseAttrList()
    local list = self:GetBaseAttrList()
    local uiList = self:FindUIScroll("mBaseAttrList")
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("mBaseAttrList")
        uiList:Create(self.mBaseAttrList, list, function(...)
            self:OnDrawBaseAttrCell(...)
        end)
    end
    CS.ShowObject(self.mBaseAttrDiv, #list > 0)
end

function UISdTips:OnHalidomStarUpResp(pb)
    --- 满星预览无操作，直接返回
    if self._typeWnd == UISdTips.TYPE_WND_NOTOPTFULLMAX then
        return
    end

    if self._typeWnd == UISdTips.TYPE_WND_FULLMAX then
        -- 合成操作
        local obj = pb.obj
        if obj and obj.refId == self._refId then
            ---@type StructHalidomObjInfo
            local halidomObj = gModelHalidom:GetHalidomObjByRefId(self._refId)
            if halidomObj then
                self._halidomObj = halidomObj
                self._typeWnd = UISdTips.TYPE_WND_OPT
            end
        end
    end

    self:RefreshView()
end

function UISdTips:RefreshTakeEffectDiv()
    local showTakeEffect = false
    local starRefId, taskFinishCnt
    local topNum = 0
    local typeWnd = self._typeWnd
    if typeWnd == UISdTips.TYPE_WND_FULLMAX then
        --- 满星显示上线次数和累计加成最大值
        local lastRef = gModelHalidom:GetInitLastHalidomStarRef(self._refId)
        if lastRef then
            starRefId = lastRef.refId
            topNum = gModelHalidom:GetHalidomStarTopNumByRefId(starRefId)
            taskFinishCnt = topNum
        end
    elseif typeWnd == UISdTips.TYPE_WND_OPT then
        local halidomObj = self._halidomObj
        if halidomObj then
            starRefId = halidomObj.starRefId
            topNum = gModelHalidom:GetHalidomStarTopNumByRefId(starRefId)
            taskFinishCnt = halidomObj.taskFinishCnt
        end
    end
    starRefId = starRefId or 0
    topNum = topNum or 0
    if starRefId > 0 and topNum > 0 then

        self:SetWndText(self.mTakeEffectNum, string.replace(ccClientText(41538), taskFinishCnt, topNum))

        --- 每完成1次任务的属性增加
        local attrList = gModelHalidom:GetHalidomStarAddAttrListByRefId(starRefId)
        local list = {}
        for i, v in ipairs(attrList) do
            table.insert(list, {
                attrRefId = v.attrRefId,
                attrType = v.attrType,
                attrNum = v.attrNum * taskFinishCnt,
            })
        end
        self:InitTakeEffectAttrList(list)
        showTakeEffect = true
    end
    CS.ShowObject(self.mTakeEffectDiv, showTakeEffect)
end
function UISdTips:InitData()
    self._typeWnd = self:GetWndArg("typeWnd")

    local refId = self:GetWndArg("refId")

    local halidomObj = self:GetWndArg("halidomObj")
    if halidomObj then
        refId = halidomObj.refId
    end
    self._halidomObj = halidomObj

    self._refId = refId
end

function UISdTips:InitMsg()
    self:WndEventRecv(EventNames.On_Item_Change, function(...)
        self:OnItemChange()
    end)
    self:WndNetMsgRecv(LProtoIds.HalidomStarUpResp, function(...)
        self:OnHalidomStarUpResp(...)
    end)
end

function UISdTips:RefreshView()

    CS.ShowObject(self.mMaxPreDiv, UISdTips.SHOW_MAXPRE[self._typeWnd])
    self:RefreshCommon()

    self:InitBaseAttrList()
    self:InitPassivitySkillDescList()
    self:RefreshTakeEffectDiv()
    self:RefreshBotDiv()
end

function UISdTips:OnDrawBaseAttrCell(list, item, itemdata, itempos)
    local AttrIcon = self:FindWndTrans(item, "AttrIconDiv/AttrIcon")
    local AttrInfo = self:FindWndTrans(item, "AttrInfo")

    local attrRefId = itemdata.attrRefId
    local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
    self:SetWndEasyImage(AttrIcon, attrIcon, function()
        CS.ShowObject(AttrIcon, true)
    end)

    local name = gModelHero:GetAttributeNameById(attrRefId)
    local valStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, itemdata.attrType, itemdata.attrNum)
    --local infoStr = string.replace(ccClientText(41536),name,valStr)
    local infoStr = "+" .. valStr
    local nextAttrNum = itemdata.nextAttrNum
    if nextAttrNum and nextAttrNum > 0 then
        local nextValStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, itemdata.attrType, nextAttrNum)
        local nextAddStr = string.replace(ccClientText(41529), nextValStr)
        infoStr = infoStr .. nextAddStr
    end
    self:SetWndText(AttrInfo, infoStr)
end

function UISdTips:OnItemChange()
    self:RefreshBotDiv()
end

function UISdTips:InitEvent()
    --- 返回按钮必备
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mMaskBg, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnOpt, function()
        self:OnClickBtnOptFunc()
    end)
end

------------------------------------------------------------------
return UISdTips