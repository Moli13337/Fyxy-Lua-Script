---
--- Created by LCM.
--- DateTime: 2022/11/1 10:11:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemUpLv:LWnd
local UIGolemUpLv = LxWndClass("UIGolemUpLv", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemUpLv:UIGolemUpLv()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemUpLv:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemUpLv:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemUpLv:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
    self:RefreshView()
end

function UIGolemUpLv:RefreshView()
    local beforeGolem = self._beforeGolem
    local laterGolem = self._laterGolem
    if not beforeGolem or not laterGolem then return end
    local beforeLv = gModelGolem:GetGolemLvlByGolemInfo(beforeGolem)
    local afterLv = gModelGolem:GetGolemLvlByGolemInfo(laterGolem)

    local str = string.replace(ccClientText(14701),beforeLv)
    self:SetWndText(self.mGolemCurLv,str)

    str = string.replace(ccClientText(14701),afterLv)
    self:SetWndText(self.mGolemNextLv,str)

    self:InitShowAttrList()
end

function UIGolemUpLv:OnDrawShowAttrCell(list,item,itemdata,itempos)
    local AttrIconTrans = self:FindWndTrans(item,"AttrIcon")
    local AttrNameTrans = self:FindWndTrans(item,"AttrName")
    local BeforeAttrValueTrans = self:FindWndTrans(item,"BeforeAttrValue")
    local LastAttrValueTrans = self:FindWndTrans(item,"LastAttrValue")

    local attrRefId = itemdata.attrRefId
    local attrType = itemdata.attrType

    local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
    self:SetWndEasyImage(AttrIconTrans,attrIcon)
    local attrName = gModelHero:GetAttributeNameById(attrRefId)
    self:SetWndText(AttrNameTrans,attrName)

    local beforeValue = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,itemdata.beforeValue)
    beforeValue = string.replace(ccClientText(33246),beforeValue)
    self:SetWndText(BeforeAttrValueTrans,beforeValue)

    local attrShowType = itemdata.attrShowType
    local laterValue = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,itemdata.laterValue)
    if attrShowType == ModelGolem.GOLEM_DIV_ATTR_PRIME then
        laterValue = string.replace(ccClientText(33248),laterValue)
    elseif attrShowType == ModelGolem.GOLEM_DIV_ATTR_DEPUTY then
        laterValue = string.replace(ccClientText(33247),laterValue)
    end
    self:SetWndText(LastAttrValueTrans,laterValue)
end

function UIGolemUpLv:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

------------------------- List -------------------------
function UIGolemUpLv:GetShowAttrList()
    local beforeGolem = self._beforeGolem
    local laterGolem = self._laterGolem
    if not beforeGolem or not laterGolem then return {} end
    local beforeMainAttr = gModelGolem:GetGolemMainAttrListByGolemInfo(beforeGolem)
    local beforeViceAttr = gModelGolem:GetGolemViceAttrListByGolemInfo(beforeGolem)

    local laterMainAttr = gModelGolem:GetGolemMainAttrListByGolemInfo(laterGolem)
    local laterViceAttr = gModelGolem:GetGolemViceAttrListByGolemInfo(laterGolem)

    local mainAttrSortList = gModelGolem:GetTwoAttrContrastList(beforeMainAttr,laterMainAttr)
    local viceAttrSortList = gModelGolem:GetTwoAttrContrastList(beforeViceAttr,laterViceAttr)

    local list = {}
    for i,v in ipairs(mainAttrSortList) do
        table.insert(list,{
            attrRefId = v.attrRefId,
            attrType = v.attrType,
            beforeValue = v.beforeValue,
            laterValue = v.laterValue,
            attrShowType = ModelGolem.GOLEM_DIV_ATTR_PRIME,
        })
    end
    for i,v in ipairs(viceAttrSortList) do
        table.insert(list,{
            attrRefId = v.attrRefId,
            attrType = v.attrType,
            beforeValue = v.beforeValue,
            laterValue = v.laterValue,
            attrShowType = ModelGolem.GOLEM_DIV_ATTR_DEPUTY,
        })
    end

    return list
end


function UIGolemUpLv:InitMsg()

	-- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIGolemUpLv:InitText()
    self:SetTextTile(self.mUpLvTitle,ccClientText(33241))
    self:SetWndText(self.mGolemDesc,ccClientText(33242))
end

function UIGolemUpLv:InitShowAttrList()
    local list = self:GetShowAttrList()
    local uiShowAttrList = self._uiShowAttrList
    if uiShowAttrList then
        uiShowAttrList:RefreshList(list)
    else
        uiShowAttrList = self:GetUIScroll("uiShowAttrList")
        self._uiShowAttrList = uiShowAttrList
        uiShowAttrList:Create(self.mShowAttrList,list,function(...) self:OnDrawShowAttrCell(...) end)
    end
end

function UIGolemUpLv:InitData()
    self._beforeGolem = self:GetWndArg("beforeGolem")
    self._laterGolem = self:GetWndArg("laterGolem")
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIGolemUpLv



