---
--- Created by LCM.
--- DateTime: 2024/3/1 17:53:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeForkroad:LWnd
local UIHopeForkroad = LxWndClass("UIHopeForkroad", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeForkroad:UIHopeForkroad()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeForkroad:OnWndClose()
    --FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
    FireEvent(EventNames.ON_FDT_EVENT_CLOSEUI)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeForkroad:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeForkroad:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:SetWndButtonText(self.mGoToBtn,ccClientText(30111))
    self:SetTextTile(self.mDescTxt,ccClientText(41417))
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:RefreshView()
    self:InitChoiceList()
end

function UIHopeForkroad:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mGoToBtn,function() self:OnClickGoToBtnFunc() end)
end

------------------------- List -------------------------


function UIHopeForkroad:GetChoiceList()
    local list = {}
    ---@type StructDreamTripEventInfo
    local serverData = self._eventInfo
    if serverData then
        local eventRefId = serverData.eventRefId
        local parameterList = gModelFastDreamTrip:GetForkroadParameter(eventRefId)
        if parameterList then
            local mapGameId = gModelFastDreamTrip:GetDreamTripMapGameId()
            local curIndex = gModelFastDreamTrip:GetDreamTripIndex()
            local curPos = gModelFastDreamTrip:GetMapDreamTripGridPos(mapGameId,curIndex)
            local gridStartIndex
            for i,v in ipairs(parameterList) do
                gridStartIndex = v.gridStartIndex
                local pos = gModelFastDreamTrip:GetMapDreamTripGridPos(mapGameId,gridStartIndex)
                if pos then
                    local isLeft,isDown = false,false
                    local topX = pos.x - curPos.x
                    local topY = pos.y - curPos.y
                    if topY ~= 0 then
                        isDown = topY < 0
                    end
                    if topX ~= 0 then
                        isLeft = topX < 0
                    end
                    local dire
                    if isDown then
                        dire = isLeft and ModelFastDreamTrip.TYPE_BOT_LEFT or ModelFastDreamTrip.TYPE_BOT_RIGHT
                    else
                        dire = isLeft and ModelFastDreamTrip.TYPE_TOP_LEFT or ModelFastDreamTrip.TYPE_TOP_RIGHT
                    end
                    table.insert(list,{
                        dire = dire,
                        btnName = self._direNameList[dire],
                        direType = v.direType,
                    })
                end
            end
        end
    end
    return list
end

function UIHopeForkroad:OnClickChoiceFunc(itemdata)
    local direType = itemdata.direType
    if self._direType == direType then return end
    self._direType = direType
    self:InitChoiceList()
end

function UIHopeForkroad:InitData()
    ---@type StructDreamTripEventInfo
    local eventInfo = self:GetWndArg("eventInfo")
    self._eventInfo = eventInfo

    self._eventId = eventInfo.eventId
    self._index = eventInfo.index
    self._eventRefId = eventInfo.eventRefId
    self._eventType = eventInfo.eventType


    self._direNameList = {
        [ModelFastDreamTrip.TYPE_TOP_LEFT] = ccClientText(30104),
        [ModelFastDreamTrip.TYPE_TOP_RIGHT] = ccClientText(30105),
        [ModelFastDreamTrip.TYPE_BOT_LEFT] = ccClientText(30106),
        [ModelFastDreamTrip.TYPE_BOT_RIGHT] = ccClientText(30107),
    }


    self._direType = nil
end

function UIHopeForkroad:OnFDTEventFinish(recordFinishMap,pb)
    if not recordFinishMap[self._eventId] then return end
    self:WndClose()
end

function UIHopeForkroad:OnClickGoToBtnFunc()
    if not self._direType then return end
    gModelFastDreamTrip:OnDreamTripStartEventReq(self._eventId,{tostring(self._direType)})
end

function UIHopeForkroad:InitMsg()
    self:WndEventRecv(EventNames.ON_FDT_EVENT_FINISH,function(...) self:OnFDTEventFinish(...) end)

    --- 7.20新增活动梦境之旅
    --self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret) self:OnDreamTripStartEventResp(pb) end)
    -- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end


function UIHopeForkroad:OnDreamTripStartEventResp(pb)
    if pb.eventId ~= self._eventId then return end
    local endInfo = pb.endInfo
    if not endInfo then return end
    if endInfo.state == StructDreamTripGrid.FINISH then
        self:WndClose()
    end
end

function UIHopeForkroad:OnDrawChoiceCell(list,item,itemdata,itempos)
    local BgTrans = self:FindWndTrans(item,"Bg")
    local SelImgTrans = self:FindWndTrans(item,"SelImg")
    local TopRightTrans = self:FindWndTrans(item,"TopRight")
    local TopLeftTrans = self:FindWndTrans(item,"TopLeft")
    local BotRightTrans = self:FindWndTrans(item,"BotRight")
    local BotLeftTrans = self:FindWndTrans(item,"BotLeft")
    local NameTrans = self:FindWndTrans(item,"Name")
    local BtnTrans = self:FindWndTrans(item,"Btn")


    local direType = itemdata.direType
    local isSel = self._direType and self._direType == direType or false
    CS.ShowObject(SelImgTrans,isSel)

    local dire = itemdata.dire
    CS.ShowObject(TopRightTrans,dire == ModelFastDreamTrip.TYPE_TOP_RIGHT)
    CS.ShowObject(TopLeftTrans,dire == ModelFastDreamTrip.TYPE_TOP_LEFT)

    CS.ShowObject(BotLeftTrans,dire == ModelFastDreamTrip.TYPE_BOT_LEFT)
    CS.ShowObject(BotRightTrans,dire == ModelFastDreamTrip.TYPE_BOT_RIGHT)

    self:SetWndText(NameTrans,itemdata.btnName)

    self:SetWndClick(BtnTrans,function()
        self:OnClickChoiceFunc(itemdata)
    end)

end

function UIHopeForkroad:InitChoiceList()
    local list = self:GetChoiceList()
    local uiChoiceList = self._uiChoiceList
    if uiChoiceList then
        uiChoiceList:RefreshList(list)
    else
        uiChoiceList = self:GetUIScroll("uiChoiceList")
        self._uiChoiceList = uiChoiceList
        uiChoiceList:Create(self.mChoiceList,list,function(...) self:OnDrawChoiceCell(...) end)
    end
end

function UIHopeForkroad:RefreshView()
    local eventRefId = self._eventRefId
    local eventRef = gModelFastDreamTrip:GetDreamTripEventRefByRefId(eventRefId)
    if not eventRef then return end

    local name = ccLngText(eventRef.name)
    self:SetWndText(self.mLblBiaoti,name)

    local choose = tonumber(eventRef.choose)
    local textRef = gModelFastDreamTrip:GetDreamTripTextRefByRefId(choose)
    local dec = ""
    if textRef then
        dec = ccLngText(textRef.dec)
    end
    self:SetWndText(self.mEventDesc,dec)

    local prefabSize = gModelFastDreamTrip:GetDreamTripEventPrefabSizeByRefId(self._eventRefId)
    local resType = eventRef.resType
    if resType == 1 then
        local res = eventRef.res
        self:SetWndEasyImage(self.mEventIcon,res,function()
            CS.ShowObject(self.mEventIcon,true)
            self.mEventIcon.localScale = Vector3(prefabSize,prefabSize,prefabSize)
        end)
    elseif resType == 2 then
        local prefab = eventRef.prefab
        self:CreateWndSpine(self.mEventSpinePos,prefab,prefab,false,function(dpSpine)
            dpSpine:SetScale(prefabSize or 1)
            CS.ShowObject(self.mEventSpinePos,true)
        end)
    end
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeForkroad



