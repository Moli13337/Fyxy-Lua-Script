---
--- Created by Administrator.
--- DateTime: 2023/10/13 17:40:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaPowerTips:LWnd
local UISagaPowerTips = LxWndClass("UISagaPowerTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaPowerTips:UISagaPowerTips()
    self._showUpPowerAniKey = "_showUpPowerAniKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaPowerTips:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaPowerTips:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaPowerTips:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitShowPowerTrans()
    self:InitData()
    self:InitCommon()
    self:SetUpPowerTxt()
end

function UISagaPowerTips:InitShowPowerInfo()
    for i, v in ipairs(self._aniTransList or {}) do
        CS.ShowObject(v, false)
    end
    self.mShowUpPowerImg.localPosition = Vector3.zero
    for i, v in ipairs(self._aniAttrTransList or {}) do
        v.localPosition = Vector3.zero
    end
end

function UISagaPowerTips:SetUpPowerTxt()
    local AttrName, AttrAddNum
    local dataList = self._dataList or {}
    local data, showTrans
    local attrName
    local showTransList = {}
    for i, v in ipairs(self._aniAttrTransList) do
        data = dataList[i]
        showTrans = data ~= nil
        if data then
            AttrName = self:FindWndTrans(v, "AttrName")
            AttrAddNum = self:FindWndTrans(v, "AttrAddNum")
            local refId = data.refId
            attrName = gModelHero:GetAttributeNameById(refId)
            self:SetWndText(AttrName, attrName)

            local showType = gModelHero:GetAttrShowType(refId)
            if data.type == 2 then
                showType = 2
            end
            local addNum = data.addNum
            local tAddNum = addNum
            if showType == 2 then
                tAddNum = string.format("%0.4f", tAddNum)
                tAddNum = tonumber(tAddNum)
            else
                tAddNum = math.floor(tAddNum)
            end
            local addNumStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, showType, math.abs(tAddNum))
            addNumStr = addNum >= 0 and "+" .. addNumStr or "-" .. addNumStr
            self:SetWndText(AttrAddNum, addNumStr)

            table.insert(showTransList, v)
        end
        CS.ShowObject(v, showTrans)
    end
    self:RunShowUpPowerAni(showTransList)
end

function UISagaPowerTips:InitShowPowerTrans()
    CS.ShowObject(self.mShowUpPowerDiv, false)

    local aniTransList = {
        self.mShowUpPowerImgDiv, self.mShowAttrDiv1, self.mShowAttrDiv2, self.mShowAttrDiv3, self.mShowAttrDiv4, self.mShowAttrDiv5, self.mShowAttrDiv6,
        self.mShowAttrDiv7, self.mShowAttrDiv8, self.mShowAttrDiv9, self.mShowAttrDiv10
    }
    self._aniTransList = aniTransList

    local aniAttrPTrans = {
        self.mShowAttrDiv1, self.mShowAttrDiv2, self.mShowAttrDiv3, self.mShowAttrDiv4, self.mShowAttrDiv5,
        self.mShowAttrDiv6, self.mShowAttrDiv7, self.mShowAttrDiv8, self.mShowAttrDiv9, self.mShowAttrDiv10
    }
    self._aniAttrPTrans = aniAttrPTrans

    local aniAttrTransList = {
        self.mShowAniRoot1, self.mShowAniRoot2, self.mShowAniRoot3, self.mShowAniRoot4, self.mShowAniRoot5,
        self.mShowAniRoot6, self.mShowAniRoot7, self.mShowAniRoot8, self.mShowAniRoot9, self.mShowAniRoot10
    }
    self._aniAttrTransList = aniAttrTransList

    self:InitShowPowerInfo()
end

function UISagaPowerTips:InitCommon()
    if not string.isempty(self._powerPre) then

        self:SetWndText(self.mPowerYSZTxt, LUtil.PowerNumberCoversion(math.floor(self._powerPre)))
        self:InitTextSizeWithLanguage(self.mPowerYSZTxt, 2)
    end

    if not string.isempty(self._subValue) then
        self:SetWndText(self.mShowAddTxt, string.format("+%s", math.floor(self._subValue)))
    end
end

function UISagaPowerTips:InitData()
    self._dataList = self:GetWndArg("dataList")
    self._powerPre = self:GetWndArg("powerPre") or ""
    self._subValue = self:GetWndArg("subValue") or ""
end

function UISagaPowerTips:RunShowUpPowerAni(transList)
    self:InitShowPowerInfo()

    local showTransList = {}
    if not string.isempty(self._powerPre) then
        table.insert(showTransList, {
            transP = self.mShowUpPowerImgDiv,
            trans = self.mShowUpPowerImg,
        })
    end

    local aniAttrPTrans = self._aniAttrPTrans
    local transP, transInfo
    for i, v in ipairs(transList) do
        transP = aniAttrPTrans[i]
        CS.ShowObject(transP, false)
        v.localPosition = Vector3.zero
        transInfo = {
            transP = transP,
            trans = v,
        }
        table.insert(showTransList, transInfo)
    end

    local info = {
        initPos = Vector3.zero,
        showTime = 0.4,
        waitTime = 1,
        noShowTime = 0.1,
    }

    CS.ShowObject(self.mShowUpPowerDiv, true)
    CS.ShowObject(CS.FindTrans(self.mShowUpPowerDiv, "PowerDiv/Image"), true)
    self:TweenSeq_MoveFadeInStaysAwayList(self._showUpPowerAniKey, showTransList, info, function()
        self:WndClose()
    end)
end
------------------------------------------------------------------
return UISagaPowerTips


