---
--- Created by LCM.
--- DateTime: 2022/10/28 10:18:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemResolve:LWnd
local UIGolemResolve = LxWndClass("UIGolemResolve", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemResolve:UIGolemResolve()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemResolve:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemResolve:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemResolve:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
    gModelGolem:OnGolemSmartDissolveReq(ModelGolem.GOLEM_SMART_DISSOLVE_SEE_TYPE)
end

function UIGolemResolve:OnClickGolemTypeFunc(itemdata)
    local serverChooseStatusMap = self._serverChooseStatusMap
    if not serverChooseStatusMap then
        serverChooseStatusMap = {}
        self._serverChooseStatusMap = serverChooseStatusMap
    end
    local dissolveType = itemdata.dissolveType
    local isSel = self:CheckSelGolemTypeIsSel(dissolveType)
    local status = isSel and ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CANCEL or ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_ENTER
    serverChooseStatusMap[dissolveType] = status

    local uiSelGolemTypeList = self._uiSelGolemTypeList
    if uiSelGolemTypeList then
        local uiList = uiSelGolemTypeList:GetList()
        uiList:RefreshList()
    end
end

function UIGolemResolve:InitText()
    self:SetWndText(self.mLblBiaoti,ccClientText(33222))
    self:SetWndText(self.mGolemDesc,ccClientText(33234))
    self:SetWndButtonText(self.mSaveBtn,ccClientText(33216))
end

function UIGolemResolve:InitMsg()

	 self:WndNetMsgRecv(LProtoIds.GolemSmartDissolveResp,function(pb) self:OnGolemSmartDissolveResp(pb) end)


	-- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIGolemResolve:OnClickSaveBtnFunc()
    local serverChooseStatusMap = self._serverChooseStatusMap
    if not serverChooseStatusMap then return end
    local choose1 = serverChooseStatusMap[ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CHOOSE1] or ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CANCEL
    local choose2 = serverChooseStatusMap[ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CHOOSE2] or ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CANCEL
    gModelGolem:OnGolemSmartDissolveReq(ModelGolem.GOLEM_SMART_DISSOLVE_SET_TYPE,choose1,choose2)
end

function UIGolemResolve:CheckSelGolemTypeIsSel(dissolveType)
    local serverChooseStatusMap = self._serverChooseStatusMap
    if not serverChooseStatusMap then return false end
    local chooseStatus = serverChooseStatusMap[dissolveType] or ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CANCEL
    return chooseStatus == ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_ENTER
end

------------------------- List -------------------------

function UIGolemResolve:InitSelGolemTypeList(list)
    list = list or {}
    local uiSelGolemTypeList = self._uiSelGolemTypeList
    if uiSelGolemTypeList then
        uiSelGolemTypeList:RefreshList(list)
    else
        uiSelGolemTypeList = self:GetUIScroll("uiSelGolemTypeList")
        self._uiSelGolemTypeList = uiSelGolemTypeList
        uiSelGolemTypeList:Create(self.mSelGolemTypeList,list,function(...) self:OnDrawSelGolemTypeCell(...) end)
    end
end

function UIGolemResolve:OnDrawSelGolemTypeCell(list,item,itemdata,itempos)
    local GouTrans = self:FindWndTrans(item,"GouDiv/GouBg/Gou")
    local TitleTrans = self:FindWndTrans(item,"TitleDiv/Title")
    local BtnTrans = self:FindWndTrans(item,"Btn")
    local isSel = self:CheckSelGolemTypeIsSel(itemdata.dissolveType)
    CS.ShowObject(GouTrans,isSel)
    self:SetWndText(TitleTrans,itemdata.dissolveStr)
    self:SetWndClick(BtnTrans,function()
        self:OnClickGolemTypeFunc(itemdata)
    end)
end

function UIGolemResolve:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mSaveBtn,function() self:OnClickSaveBtnFunc() end)
end

function UIGolemResolve:OnGolemSmartDissolveResp(pb)
    if pb.type == ModelGolem.GOLEM_SMART_DISSOLVE_SET_TYPE then
        self:WndClose()
        return
    end
    local choose1 = pb.choose1
    local choose2 = pb.choose2

    local chooseMap = {
        [ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CHOOSE1] = choose1,
        [ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CHOOSE2] = choose2,
    }

    local serverChooseStatusMap = {}

    local list = {}
    local chooseStatus              --- 分解状态，没有的话，默认是取消分解
    local dissolveType
    local smartDissolveList = gModelGolem:GetGolemSmartDissolveList()
    for i,v in ipairs(smartDissolveList) do
        dissolveType = v.dissolveType
        chooseStatus = chooseMap[dissolveType] or ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CANCEL

        serverChooseStatusMap[dissolveType] = chooseStatus

        table.insert(list,{
            dissolveType = dissolveType,
            dissolveStr = v.dissolveStr,
        })
    end
    self._serverChooseStatusMap = serverChooseStatusMap

    self:InitSelGolemTypeList(list)
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIGolemResolve



