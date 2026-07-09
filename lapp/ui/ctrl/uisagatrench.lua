---
--- Created by LCM.
--- DateTime: 2024/3/7 18:02:51
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaTrench:LWnd
local UISagaTrench = LxWndClass("UISagaTrench", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaTrench:UISagaTrench()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaTrench:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaTrench:OnCreate()
	LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaTrench:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitWayList()
end

function UISagaTrench:InitWayList()
    local list = self:GetWayList()
    local uiWayList = self._uiWayList
    if uiWayList then
        uiWayList:RefreshList(list)
    else
        uiWayList = self:GetUIScroll("uiWayList")
        self._uiWayList = uiWayList
        uiWayList:Create(self.mWayList,list,function(...) self:OnDrawWayCell(...) end)
    end
    local enable = #list >= 4
    uiWayList:EnableScroll(enable)
end


function UISagaTrench:InitMsg()

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end
------------------------- List -------------------------


function UISagaTrench:GetWayList()
    local list = {}
    local heroSetOrigin = self._heroSetOrigin
    if heroSetOrigin then
        local jumpId
        for i,v in ipairs(heroSetOrigin) do
            jumpId = v.jumpId
            local jumpCfg = gModelGeneral:GetJumpConfig(jumpId)
            if jumpCfg then
                local data = {}
                data.jumpId = jumpId
                data.name = ccLngText(jumpCfg.name)
                data.functionId = jumpCfg.functionId
                data.isOpen = gModelFunctionOpen:CheckIsOpened(data.functionId)
                data.textId = v.textId
                data.text = ccLngText(jumpCfg.text)
                data.index = i
                data.icons = string.split(jumpCfg.icon,'|')
                table.insert(list,data)
            end
        end
        table.sort(list,function (a,b)
            local aOpen = a.isOpen and 0 or 1
            local bOpen = b.isOpen and 0 or 1
            if aOpen ~= bOpen then
                return aOpen< bOpen
            end

            return a.index < b.index
        end)
    end
    return list
end

function UISagaTrench:OnClickGoBtnFunc(itemdata)
    local functionId = itemdata.functionId
    local isOpen = gModelFunctionOpen:CheckIsOpened(functionId,true)
    if not isOpen then
        return
    end
    local srcWnd = self._srcWnd
    local jumpId = itemdata.jumpId
    self:WndClose()
    gModelGeneral:OriginJump({
        functionId = functionId,
        originRefId = jumpId,
        srcWnd = srcWnd,
    })
end

function UISagaTrench:OnDrawWayCell(list,item,itemdata,itempos)
    local introTrans = self:FindWndTrans(item,"intro")
    local descTrans = self:FindWndTrans(item,"desc")
    local gotoBtnTrans = self:FindWndTrans(item,"gotoBtn")
    local TextTrans = self:FindWndTrans(gotoBtnTrans,"Text")

    local name = itemdata.name
    self:SetWndText(introTrans,name)

    local str = gModelItem:GetItemJumpDesc(itemdata.textId)
    self:SetWndText(descTrans,str)

    self:SetWndText(TextTrans,itemdata.text)

    local isOpen = itemdata.isOpen
    local imagePath = isOpen and itemdata.icons[1] or itemdata.icons[2]
    self:SetBtnImageAndMat(gotoBtnTrans,imagePath,TextTrans,true)

    self:SetWndClick(gotoBtnTrans,function() self:OnClickGoBtnFunc(itemdata) end)
end

function UISagaTrench:InitText()
    self:SetWndText(self.mLblBiaoti,ccClientText(10091))
    self:SetWndText(self.mTrenchDesc,ccClientText(10092))
    self:InitTextLineWithLanguage(self.mTrenchDesc, -30)
end

function UISagaTrench:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISagaTrench:InitData()
    self._srcWnd = self:GetWndArg("srcWnd")

    local heroSetOrigin = gModelHero:GeConfigByKey("heroSetOrigin")
    heroSetOrigin = string.split(heroSetOrigin,"|")

    local list = {}
    for i,v in ipairs(heroSetOrigin) do
        v = string.split(v,"=")
        table.insert(list,{
            jumpId = tonumber(v[1]),
            textId = tonumber(v[2]),
        })
    end
    self._heroSetOrigin = list
end

------------------------- List -------------------------

------------------------------------------------------------------
return UISagaTrench


