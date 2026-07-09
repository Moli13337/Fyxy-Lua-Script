---
--- Created by LCM.
--- DateTime: 2024/3/2 17:56:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaPotency:LWnd
local UISagaPotency = LxWndClass("UISagaPotency", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaPotency:UISagaPotency()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaPotency:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaPotency:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaPotency:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitPotencyList()
end

function UISagaPotency:InitPotencyList()
    local list = self:GetPotencyList()
    local uiPotencyList = self._uiPotencyList
    if uiPotencyList then
        uiPotencyList:RefreshList(list)
    else
        uiPotencyList = self:GetUIScroll("uiPotencyList")
        self._uiPotencyList = uiPotencyList
        uiPotencyList:Create(self.mPotencyList,list,function(...) self:OnDrawPotencyCell(...) end)
        uiPotencyList:EnableScroll(true)
    end
end


function UISagaPotency:InitMsg()
	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UISagaPotency:InitData()

    self:SetWndText(    self.mTitle,ccClientText(26638))
end

function UISagaPotency:InitDescList(trans,list)
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans,list,function(...) self:OnDrawDescCell(...) end)
        uiList:EnableScroll(true)
    end
end

function UISagaPotency:OnDrawDescCell(list,item,itemdata,itempos)
    self:SetTextTile(item,itemdata.desc)
end

function UISagaPotency:OnDrawPotencyCell(list,item,itemdata,itempos)
    local TitleBgTrans = self:FindWndTrans(item,"TitleBg")
    local NameTxtTrans = self:FindWndTrans(TitleBgTrans,"NameTxt")
    local OpenTxtTrans = self:FindWndTrans(TitleBgTrans,"OpenTxt")

    local ContentBgTrans = self:FindWndTrans(item,"ContentBg")
    local IconTrans = self:FindWndTrans(ContentBgTrans,"Icon")

    local DescListTrans = self:FindWndTrans(ContentBgTrans,"DescList")

    self:SetWndText(NameTxtTrans,itemdata.name)
    self:SetWndText(OpenTxtTrans,itemdata.unlock)
    self:SetWndEasyImage(IconTrans,itemdata.icon,function()
        CS.ShowObject(IconTrans,true)
    end)
    self:InitDescList(DescListTrans,itemdata.text)
end



function UISagaPotency:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end
------------------------- List -------------------------


function UISagaPotency:GetPotencyList()
    local list = {}
    return list
end
------------------------- List -------------------------

------------------------------------------------------------------
return UISagaPotency



