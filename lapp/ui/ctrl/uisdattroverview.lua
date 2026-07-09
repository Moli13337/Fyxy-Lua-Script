---
--- Created by Administrator.
--- DateTime: 2024/5/21 19:45:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISdAttrOverView:LWnd
local UISdAttrOverView = LxWndClass("UISdAttrOverView", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISdAttrOverView:UISdAttrOverView()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISdAttrOverView:OnWndClose()
    LWnd.OnWndClose(self)

    local func = self:GetWndArg("callFunc")
    if func then
        func()
    end
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISdAttrOverView:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISdAttrOverView:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    self:InitData()
    self:InitEmptyList()
    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:RefreshView()
end

function UISdAttrOverView:GetShowAttrList()
    return self._attrList
end

function UISdAttrOverView:InitEmptyList()
    local data = {
        refId = 23004,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty1")
    emptyList:RefreshUI(data)
end

function UISdAttrOverView:InitText()
    self:SetTextTile(self.mTextTitle5, self._titleTxt)
    self:SetWndText(self.mDesc, ccClientText(41532))
end

function UISdAttrOverView:InitData()
    self._titleTxt = self:GetWndArg("titleTxt") or ccClientText(41519)
    self._attrList = self:GetWndArg("attrList")
end

function UISdAttrOverView:RefreshView()
    self:InitShowAttrList()
end

function UISdAttrOverView:InitMsg()
end

function UISdAttrOverView:InitShowAttrList()
    local list = self:GetShowAttrList()
    local uiList = self:FindUIScroll("mShowAttrList")
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("mShowAttrList")
        uiList:Create(self.mShowAttrList, list, function(...)
            self:OnDrawShowAttrCell(...)
        end)
    end
    uiList:EnableScroll(#list > 10, false)
    CS.ShowObject(self.mNoRecord2, #list < 1)
end

function UISdAttrOverView:OnDrawShowAttrCell(list, item, itemdata, itempos)
    local AttrIcon = self:FindWndTrans(item, "AttrIcon")
    local AttrName = self:FindWndTrans(item, "AttrName")
    local AttrValue = self:FindWndTrans(item, "AttrValue")

    local AttrName_En = self:FindWndTrans(item, "AttrName_En")
    local AttrValue_En = self:FindWndTrans(item, "AttrValue_En")
    AttrName = self._isEnus and AttrName_En or AttrName
    AttrValue = self._isEnus and AttrValue_En or AttrValue

    local attrRefId = itemdata.attrRefId
    local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
    self:SetWndEasyImage(AttrIcon, attrIcon, function()
        CS.ShowObject(AttrIcon, true)
    end)

    local name = gModelHero:GetAttributeNameById(attrRefId)
    self:SetWndText(AttrName, name)

    local valStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, itemdata.attrType, itemdata.attrNum)
    self:SetWndText(AttrValue, tostring(valStr))
end

function UISdAttrOverView:InitEvent()
    --- 返回按钮必备
    self:SetWndClick(self.mMaskBg, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

------------------------------------------------------------------
return UISdAttrOverView