---
--- Created by Administrator.
--- DateTime: 2024/5/21 17:09:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISdOpt:LWnd
local UISdOpt = LxWndClass("UISdOpt", LWnd)
------------------------------------------------------------------

--- 激活
UISdOpt.TYPE_OPT_ACT = 1

--- 升星
UISdOpt.TYPE_OPT_UPSTAR = 2

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISdOpt:UISdOpt()
    --- 加载完成特效数量
    self._finishEffectNum = 0

    --- 需要加载特效数量
    self._loadEffectNum = 0

    --- 显示动画的节点
    self._aniTransList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISdOpt:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISdOpt:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISdOpt:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_UPGRADE_COMMON)
    self:InitData()
    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:RefreshView()
end

function UISdOpt:RefreshView()
    self._loadEffectNum = 0
    self:SetHalidomIcon()

    local optType = self._optType
    local showActView = optType == UISdOpt.TYPE_OPT_ACT
    local showUpStarView = optType == UISdOpt.TYPE_OPT_UPSTAR
    if showActView then
        self:RefreshActView()
    elseif showUpStarView then
        self._loadEffectNum = self._loadEffectNum + 1
        self:CreateEffect(self.mEffRoot, "fx_ui_shengxing_1")
        self:RefreshUpStarView()
    end

    self:RefreshCommonShow()
    CS.ShowObject(self.mUpStarArrow, showUpStarView)

    CS.ShowObject(self.mHalidomActView, showActView)
    CS.ShowObject(self.mHalidomUpStarView, showUpStarView)
end

function UISdOpt:GetHalidomActAttrList()
    local newHalidom = self._newHalidom
    if not newHalidom then
        return {}
    end

    return gModelHalidom:GetHalidomStarAttrListByRefId(newHalidom.starRefId)
end

function UISdOpt:StartPlayAni()
    ---@type SequenceCom
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq("startPlayAni")
    local playTime = 0
    local intervalTime = 0.1
    seq:AppendCallback(function()
        CS.ShowObject(self.mEffRoot, true)
    end)
    seq:AppendInterval(playTime)
    playTime = playTime + intervalTime

    seq:AppendCallback(function()
        CS.ShowObject(self.mHalidomInfoDiv, true)
    end)
    seq:AppendInterval(playTime)
    playTime = playTime + intervalTime

    --- 加载
    for i, v in ipairs(self._aniTransList) do
        seq:AppendCallback(function()
            CS.ShowObject(v, true)
        end)
        seq:AppendInterval(playTime)
        playTime = playTime + intervalTime
    end

    seq:AppendCallback(function()
        CS.ShowObject(self.mNextActDiv, true)
    end)
    seq:AppendInterval(playTime)

    seq:OnComplete(function()
        seqCom:DeleteSeq("startPlayAni")
    end)
    seq:PlayForward()
end

---------------- RefreshActView start

function UISdOpt:RefreshActView()
    self:InitHalidomActAttrList()
end

function UISdOpt:RefreshCommonShow()
    local newHalidom = self._newHalidom
    if not newHalidom then
        return
    end

    self:SetWndText(self.mHalidomName, gModelHalidom:GetHalidomNameByRefId(newHalidom.refId))
    self:SetWndText(self.mNextActDesc, gModelHalidom:GetHalidomStarDescByRefId(newHalidom.starRefId))
end

function UISdOpt:InitHalidomActAttrList()
    local list = self:GetHalidomActAttrList()
    self._loadEffectNum = self._loadEffectNum + #list
    local uiList = self:FindUIScroll("mHalidomActAttrList")
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("mHalidomActAttrList")
        uiList:Create(self.mHalidomActAttrList, list, function(...)
            self:OnDrawHalidomActAttrCell(...)
        end)
    end
end

function UISdOpt:OnDrawHalidomActAttrCell(list, item, itemdata, itempos)
    CS.ShowObject(item, false)

    local EffRoot = self:FindWndTrans(item, "EffRoot")
    local AttrName = self:FindWndTrans(item, "AttrName")
    local AttrIcon = self:FindWndTrans(AttrName, "AttrIcon")
    local ActNum = self:FindWndTrans(item, "ActNum")

    self:CreateEffect(EffRoot, "fx_ui_shengxing_3")
    table.insert(self._aniTransList, item)

    self:SetAttrIcon(AttrIcon, itemdata)
    self:SetAttrName(AttrName, itemdata)
    self:SetAttrNum(ActNum, itemdata, itemdata.attrNum)
end

function UISdOpt:InitStarList(trans, star)
    local list = self:GetStarList(star)
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...)
            self:OnDrawStarCell(...)
        end)
    end
end

function UISdOpt:SetAttrNum(numTrans, attr, attrVal)
    local valStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attr.attrRefId, attr.attrType, attrVal)
    self:SetWndText(numTrans, valStr)
end

function UISdOpt:InitHalidomUpStarAttrList()
    local list = self:GetHalidomUpStarAttrList()
    self._loadEffectNum = self._loadEffectNum + #list
    local uiList = self:FindUIScroll("mHalidomUpStarAttrList")
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("mHalidomUpStarAttrList")
        uiList:Create(self.mHalidomUpStarAttrList, list, function(...)
            self:OnDrawalidomUpStarAttrCell(...)
        end)
    end
end

function UISdOpt:OnDrawalidomUpStarAttrCell(list, item, itemdata, itempos)
    CS.ShowObject(item, false)

    local EffRoot = self:FindWndTrans(item, "EffRoot")
    local AttrIcon = self:FindWndTrans(item, "AttrIcon")
    local AttrName = self:FindWndTrans(item, "AttrName")
    local AttrNum = self:FindWndTrans(item, "AttrNum")
    local AttrNextNum = self:FindWndTrans(item, "AttrNextNum")

    self:CreateEffect(EffRoot, "fx_ui_shengxing_3")
    table.insert(self._aniTransList, item)

    self:SetAttrIcon(AttrIcon, itemdata)
    self:SetAttrName(AttrName, itemdata)
    self:SetAttrNum(AttrNum, itemdata, itemdata.bAttrValue)
    self:SetAttrNum(AttrNextNum, itemdata, itemdata.nAttrValue)
end






---------------- RefreshUpStarView end

function UISdOpt:SetAttrIcon(iconTrans, attr)
    local attrIcon = gModelHero:GetAttributeIconById(attr.attrRefId)
    self:SetWndEasyImage(iconTrans, attrIcon)
end

function UISdOpt:CreateEffect(trans, effName)
    CS.ShowObject(self.mEffRoot, false)
    local key = trans:GetInstanceID()
    self:CreateWndEffect(trans, effName, key, 100, false, false,
            nil, nil, nil, nil, nil, function()
                self:CheckIsLoadFinish()
            end)
end

function UISdOpt:InitData()
    self._optType = self:GetWndArg("optType")

    ---@type StructHalidomObjInfo
    self._oldHalidom = self:GetWndArg("oldHalidom")

    ---@type StructHalidomObjInfo
    self._newHalidom = self:GetWndArg("newHalidom")
end

function UISdOpt:CheckIsLoadFinish()
    self._finishEffectNum = self._finishEffectNum + 1
    if self._finishEffectNum >= self._loadEffectNum then
        self:StartPlayAni()
    end
end

function UISdOpt:GetStarList(star)
    local list = {}
    local img, temp, index = LUtil.GetHeroStarImg(star)
    for i = 1, temp do
        table.insert(list, { img = img, })
    end
    return list
end

function UISdOpt:SetHalidomIcon()
    local trans = self.mHalidomIcon
    local Icon = self:FindWndTrans(trans, "Icon")
    local key = trans:GetInstanceID()
    local baseIcon = self:GetCommonIcon(key)
    baseIcon:Create(Icon)
    if self._newHalidom then
        baseIcon:SetHalidomObj(self._newHalidom)
    else
        baseIcon:SetHalidomRefId(self._refId)
    end
    baseIcon:DoApply()

    self:CreateEffect(self.mHalidomIconEff, "fx_ui_shengxing_2")
end

function UISdOpt:RefreshStarDiv()
    local oldHalidom = self._oldHalidom
    local newHalidom = self._newHalidom
    if not oldHalidom or not newHalidom then
        return
    end

    self._loadEffectNum = self._loadEffectNum + 1
    local effRoot = self:FindWndTrans(self.mStarDiv, "EffRoot")
    self:CreateEffect(effRoot, "fx_ui_shengxing_3")

    self:InitStarList(self.mOldStarList, oldHalidom.starLv)

    local isMaxStar = gModelHalidom:CheckHalidomIsMaxStarLv(newHalidom.refId, newHalidom.starLv)
    CS.ShowObject(self.mMaxStarImg, isMaxStar)
    if not isMaxStar then
        self:InitStarList(self.mNewStarList, newHalidom.starLv)
    end
end

function UISdOpt:GetHalidomUpStarAttrList()
    return gModelHalidom:GetHalidomUpStarAttrList(self._oldHalidom, self._newHalidom)
end

function UISdOpt:OnDrawStarCell(list, item, itemdata, itempos)
    local StarImg = self:FindWndTrans(item, "StarImg")
    self:SetWndEasyImage(StarImg, itemdata.img, function()
        CS.ShowObject(StarImg, true)
    end, true)
end

function UISdOpt:InitEvent()
    --- 返回按钮必备
    self:SetWndClick(self.mMaskBg, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UISdOpt:SetAttrName(nameTrans, attr)
    local name = gModelHero:GetAttributeNameById(attr.attrRefId)
    self:SetWndText(nameTrans, name)
end


---------------- RefreshActView end



---------------- RefreshUpStarView start


function UISdOpt:RefreshUpStarView()
    self:RefreshStarDiv()
    self:InitHalidomUpStarAttrList()
end

function UISdOpt:InitText()
    self:SetWndText(self.mCloseTip, ccClientText(41037))

    --图片字
    self:SetWndEasyImage(self.mImage_Act, "halidom_txt_2", function()
        CS.ShowObject(self.mImage_Act, true)
    end)
    self:SetWndEasyImage(self.mImage_UpStar, "draconic_txt_2", function()
        CS.ShowObject(self.mImage_UpStar, true)
    end)
end

function UISdOpt:InitMsg()
end

------------------------------------------------------------------
return UISdOpt