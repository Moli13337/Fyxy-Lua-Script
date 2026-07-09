---@class LWonderEventObj
local LWonderEventObj = LxClass("LWonderEventObj",nil)
local typeLineRenderCtrl = typeof(CS.LineRenderCtrl)
local typeofBtObjectView = typeof(CardEHT.BtObjectView)


function LWonderEventObj:LWonderEventObj(mgr)
    ---@type LWonderManager
    self._mgr = mgr

    self._seqCom = SequenceCom:New()
end


function LWonderEventObj:Create(objectData)

    self._data = objectData

    local eventId = objectData.eventId
    local gridKey = objectData.gridKey
    local list = self._dynamicObjList
    local resType = objectData.resType
    local sorting = objectData.sorting
    local res = objectData.res
    local status = objectData.status
    local eventType = objectData.eventType

    local layerIndex = objectData.layerIndex
    if layerIndex then
        sorting = LGamePlayType.WONDER_SORTING_EVENT + 21 - layerIndex
    else
        sorting = sorting or LGamePlayType.WONDER_SORTING_EVENT
    end

    self._eventType = eventType

    local pos = objectData.position
    if eventType == ModelWonderland.EVENT_OCTOPUS and status == StructWonderlandGrid.PLAYER then
        pos = pos + Vector3.New(0,-0.4,0)
    end

    if not list then
        list = {}
        self._dynamicObjList = list
    end

    local eventRecord = nil

    if resType == 1 then
        local iconKey = string.format("icon_%s#%s",gridKey,eventId)
        local data =
        {
            key =iconKey,
            resName = res,
            pos = pos,
            scale = objectData.scale,
            sorting = sorting,
        }
        self:GetIconCtrl():MakeObject(data)
        eventRecord = {type = 1,key =iconKey }

    elseif resType == 2 then
        local spineKey = string.format("spine_%s#%s",gridKey,eventId)
        local spineData =
        {
            key = spineKey,
            resName = res,
            pos = pos,
            angle = objectData.angle,
            scale = objectData.scale,
            sorting = sorting,
            endFunc = function()
                self:StartAniTimer()

                local data = self._moveData
                self._moveData = nil
                if data then
                    self:MoveTo(data.targetPos,data.endCalls)
                end

                self:OnLoaded()
            end

        }

        self:GetObjCtrl():MakeObject(spineData)

        eventRecord = {type = 2,key =spineKey }
    elseif resType == 3 then

        local effectKey = string.format("effect_%s#%s",gridKey,eventId)

        local effData =
        {
            key = effectKey,
            resName = res,
            pos = pos,
            scale = objectData.scale
        }

        self:GetEffCtrl():MakeObject(effData)
        eventRecord = {type = 3,key =effectKey }
    end


    self:AddRecord(eventRecord)

    self:RefreshRelativeEff()
end

function LWonderEventObj:AddRecord(record)
    if not  self._eventRecordList then
        self._eventRecordList= {}
        self._effKeyMap = {}
    end

    table.insert(self._eventRecordList,record)
    self._effKeyMap[record.key] = record
end

function LWonderEventObj:RemoveEff(key)
    if not self._effKeyMap then
        return
    end

    local record = self._effKeyMap[key]
    if record then
        return
    end

    table.removeidata(self._eventRecordList,record)
    self:DestroyEventObj(record)
end

function LWonderEventObj:IsEffExist(key)
    return self._effKeyMap and self._effKeyMap[key]
end

function LWonderEventObj:RefreshRelativeEff()
    local eventId = self._data.eventId
    --local eventCfg = gModelWonderland:GetEventConfig(eventId)
    local eventType = self._eventType
    local isSpecial = gModelWonderland:IsSpecialEvent(eventType)
    local gridKey = self._data.gridKey
    if isSpecial then
        local addEff = "fx_qjtx_tishi"
        local effectKey = string.format("addEff_%s#%s",gridKey,eventId)
        local effData =
        {
            key = effectKey,
            resName = addEff,
            pos = self._data.position,
            scale = self._data.scale,
        }
        self:GetEffCtrl():MakeObject(effData)
        local eventRecord = {type = 3,key =effectKey }
        self:AddRecord(eventRecord)
    end
    local linedata =nil
    if eventType == ModelWonderland.EVENT_BEAN_VINE then

        local dstInfo = LxDataHelper.ParseNumber_Sign(self._data.eventdata.moreInfo,"|")
        if #dstInfo>=2 then
            local dstLayer =dstInfo[1]
            local dstGrid =dstInfo[2]
            local dstGridKey = gModelWonderland:FormatGridKey(dstLayer,dstGrid)
            if dstGridKey > gridKey then

                linedata =
                {
                    eventId = eventId,
                    dstGridKey = dstGridKey,
                }

                self._lineData = linedata
            else
                self._lineData =
                {
                    eventId = eventId,
                    dstGridKey = dstGridKey,
                }
            end
        end

        if linedata then
            local lineKey =string.format("lineEff_%s_%s",self._gridKey,linedata.eventId)

            local effName = "fx_ui_qjmx_line"

            local item = self:GetMgr():GetMapItem(gridKey).item
            local dstGridData =self:GetMgr():GetMapItem(linedata.dstGridKey)
            local dstItem = dstGridData.item

            local startPos =item.position + Vector3.New(0,0.6,0)
            local endPos = dstItem.position + Vector3.New(0,0.5,0)
            local dis = Vector3.Distance(startPos, endPos)
            local topPos = Mathf.Lerp(startPos,endPos,0.5) + Vector3.New(0,dis,0)*0.4
            local endFunc  = function(effect)
                local trans = effect:GetDisplayTrans()
                if not CS.IsValidObject(trans) then
                    return
                end

                local lineCtrl = trans.gameObject:GetComponent(typeLineRenderCtrl)
                if not lineCtrl then
                    lineCtrl = trans.gameObject:AddComponent(typeLineRenderCtrl)
                end

                lineCtrl:SetPos(startPos,endPos,topPos,trans)

            end

            local effData =
            {
                position = Vector3.zero,
                resName = effName,
                key = lineKey,
                endFunc =endFunc,
                scale = 1
            }
            local eventRecord = {type = 3,key =lineKey }
            self:AddRecord(eventRecord)
            self:GetEffCtrl():MakeObject(effData)
        end
    else
        self._lineData = nil
    end

    if eventType == ModelWonderland.EVENT_CLIP then
        local addEff = "ui_fx_xianjingjiazi"
        local effectKey = string.format("clipEff_%s#%s",gridKey,eventId)
        local effData =
        {
            key = effectKey,
            resName = addEff,
            pos = self._data.position + Vector3.New(-0.032,0.311,0),
            scale = self._data.scale,
        }
        self:GetEffCtrl():MakeObject(effData)
        local eventRecord = {type = 3,key =effectKey }
        self:AddRecord(eventRecord)
    end

end

function LWonderEventObj:Delete()

    if self._isDelayDestroy then
        return
    end

    local eventId = self._data.eventId

    local eventCfg = gModelWonderland:GetEventConfig(eventId)
    local eventType = self._eventType -- eventCfg.type
    if eventType == ModelWonderland.EVENT_SNOW then
        local res = eventCfg.res
        local strs = string.split(res,',')
        if #strs>1 then
            res = strs[2]
        end
        local effectKey = string.format("effect_%s#%s",self._data.gridKey,eventId)
        self:GetEffCtrl():DestroyByKey(effectKey)
        local data =
        {
            position = self._data.position,
            resName = res,
            key = effectKey,
            scale = self._data.scale
        }
        self:GetEffCtrl():MakeObject(data)

        self._isDelayDestroy = true

        local seq = self._seqCom:CreateSeq("DelayDestroy")
        seq:AppendInterval(3)
        seq:OnComplete(function ()
            self._seqCom:DeleteSeq("DelayDestroy")
            self:Destroy()
        end)
        seq:PlayForward()
    elseif eventType == ModelWonderland.EVENT_POD or eventType == ModelWonderland.EVENT_CLIP or eventType == ModelWonderland.EVENT_BEAN_VINE then
        --delay


        local gridData = gModelWonderland:GetGridDataByGridKey(self._data.gridKey)
        local state = gridData:GetStatus()
        printInfoN("wondereventobj state "..state)
        if state == StructWonderlandGrid.PASSED or state == StructWonderlandGrid.PLAYER then
            return
        end

        self:Destroy()
    else
        self:Destroy()
    end
end

function LWonderEventObj:GetMgr()
    return self._mgr
end

function LWonderEventObj:GetEffCtrl()
    return self._mgr:GetEffCtrl()
end

function LWonderEventObj:GetIconCtrl()
    return self._mgr:GetIconCtrl()
end
function LWonderEventObj:GetObjCtrl()
    return self._mgr:GetObjCtrl()
end

function LWonderEventObj:Destroy()
    if self._isDestoy then
        return
    end

    self._isDestoy = true

    if self._eventRecordList then
        for k,v in pairs(self._eventRecordList) do
            self:DestroyEventObj(v)
        end
        self._eventRecordList = nil
        self._effKeyMap = nil
    end

    if self._seqCom then
        self._seqCom:Destroy()
        self._seqCom = nil
    end
    self:ClearTimer()
end

function LWonderEventObj:ClearTimer()
    if self._timer then
        self._timer:Destroy()
        self._timer = nil
    end
end

function LWonderEventObj:StartAniTimer()
    if self._timer then
        self._timer:TimerRemoveByKey("loopAni")
    end


    local eventId = self._data.eventId
    local eventCfg = gModelWonderland:GetEventConfig(eventId)
    local eventType = eventCfg.type

    if eventType ~= ModelWonderland.EVENT_ARROW_TOWER and
            eventType ~= ModelWonderland.EVENT_POISON then
        return
    end
    --local curBout = gModelWonderland:GetBout()
    --local isBoutOdd = curBout %2 == 1
    local gridData  = gModelWonderland:GetGridDataByGridKey(self._data.gridKey)
    local status = gridData:GetStatus()

    if status== StructWonderlandGrid.DISAPPEAR then
        return
    end

    local para = eventCfg.parameter
    local strs = string.split(para,'=')
    local playBout = tonumber(strs[1])%2
    self._playBout = playBout


    if self._playBout then
        if not self._timer then
            self._timer = LxTimer:New()
        end

        self._timer:TimerCreate("loopAni",function () self:DoAttack() end,2,false,-1)
    end

    if eventType == ModelWonderland.EVENT_POISON then
        local gridKey = self._data.gridKey
        local effectKey = string.format("poisonIdle_%s#%s",gridKey,eventId)
        if self._playBout then
            if not self:IsEffExist(effectKey) then
                local addEff = "ui_fx_duqixianjing"
                local effData =
                {
                    key = effectKey,
                    resName = addEff,
                    pos = self._data.position + Vector3.New(0,0.47,0),
                    scale = self._data.scale,
                }
                self:GetEffCtrl():MakeObject(effData)
                local eventRecord = {type = 3,key =effectKey }
                self:AddRecord(eventRecord)
            end
        else
            self:RemoveEff(effectKey)
        end
    end


end



function LWonderEventObj:DoAttack()
    local curBout = gModelWonderland:GetBout()
    local isBoutOdd = curBout %2
    if isBoutOdd ~= self._playBout then
        return
    end


    local key = "attack"
    local seq = self._seqCom:CreateSeq(key)

    seq:AppendCallback(function ()
        self:PlayOnceAni("attack")
    end)

    local eventId = self._data.eventId
    local gridKey = self._data.gridKey
    local playBehit = gModelWonderland:IsInScopes(gridKey,eventId)

    seq:AppendInterval(0.7)
    if playBehit then
        seq:InsertCallback(0.2,function () self:GetMgr():PlayBehit(eventId) end)
    end
    seq:OnComplete(function ()
        self._seqCom:DeleteSeq(key)
    end)
    seq:PlayForward()
end

function LWonderEventObj:PlayOnceAni(aniName)
    local spineKey = string.format("spine_%s#%s",self._data.gridKey,self._data.eventId)
    local spine = self:GetObjCtrl():FindObjByKey(spineKey)
    if spine and spine:IsDpValid() then
        spine:SetAnimationCompleteFunc(function (ani)
            spine:SetAnimationCompleteFunc(nil)
            if ani ~= "idle" then
                spine:PlayAnimation(0,"idle",true)
            end
        end)
        spine:PlayAnimation(0,aniName,false)
    end
end

function LWonderEventObj:OnReach()
    printInfoN("onreach")

    local key = "attack"
    local seq = self._seqCom:CreateSeq(key)

    seq:AppendCallback(function ()
        self:PlayOnceAni("attack")
    end)

    local eventId = self._data.eventId
    seq:AppendInterval(0.7)
    seq:InsertCallback(0.2,function () self:GetMgr():PlayBehit(eventId) end)
    seq:OnComplete(function ()
        self._seqCom:DeleteSeq(key)
        self:Destroy()
    end)
    seq:PlayForward()
end

function LWonderEventObj:OnToOther(endCall)
    printInfoN("OnToOther")
    if self._isDestoy then
        if endCall then
            endCall(ModelWonderland.EVENT_POD)
        end
        return
    end

    local key = "attack"
    local seq = self._seqCom:CreateSeq(key)

    seq:AppendCallback(function ()
        self:PlayOnceAni("attack")
    end)

    local eventId = self._data.eventId
    seq:AppendInterval(0.7)
    seq:InsertCallback(0.2,function () self:GetMgr():PlayBehit(eventId) end)
    seq:OnComplete(function ()
        self._seqCom:DeleteSeq(key)
        self:Destroy()
        if endCall then
            endCall(ModelWonderland.EVENT_POD)
        end
    end)
    seq:PlayForward()

end

function LWonderEventObj:RefreshBeanVine()
    if self._eventType ~= ModelWonderland.EVENT_BEAN_VINE then
        return
    end

    local mgr = self:GetMgr()
    local lineData = self._lineData
    if lineData then
        local desGrid = mgr:GetGridByKey(lineData.dstGridKey)
        desGrid:RefreshGridByData()
    end

    local gridKey = self._data.gridKey
    local eventGrid = mgr:GetGridByKey(gridKey)
    eventGrid:RefreshGridByData()
end

function LWonderEventObj:IsDestroyed()
    return self._isDestoy
end


function LWonderEventObj:DestroyEventObj(objData)
    if objData.type == 1 then
        self:GetIconCtrl():DestroyByKey(objData.key)
    elseif objData.type == 2 then
        self:GetObjCtrl():DestroyByKey(objData.key)
    elseif objData.type == 3 then
        self:GetEffCtrl():DestroyByKey(objData.key)
    end
end

function LWonderEventObj:Refresh(eventData,status)
    local eventId = eventData.eventId
    local eventCfg = gModelWonderland:GetEventConfig(eventId)
    local eventType = eventCfg.type
    if eventType == ModelWonderland.EVENT_FOAM then
        local oldMoreinfo = self._data.eventdata.moreInfo
        local newMoreinfo = eventData.moreInfo
        if oldMoreinfo~= newMoreinfo then
            local type = tonumber(newMoreinfo)
            local index = 1
            if type == 1 then
                index = 2
            end
            local resList = string.split(eventCfg.res,",")
            local res = resList[index]

            if self._eventRecordList then
                for k,v in pairs(self._eventRecordList) do
                    self:DestroyEventObj(v)
                end

            end
            self._eventRecordList = {}
            self._effKeyMap = {}

            local gridKey = self._data.gridKey
            local effectKey = string.format("effect_%s#%s",gridKey,eventId)
            local pos = self._data.position
            if index == 2 then
                pos = Vector3.New(0,pos.y,0)
            end
            local effData =
            {
                key = effectKey,
                resName = res,
                pos = pos,
                scale = self._data.scale
            }

            self:GetEffCtrl():MakeObject(effData)
            local eventRecord = {type = 3,key =effectKey }
            --table.insert(self._eventRecordList,eventRecord)
            self:AddRecord(eventRecord)
        end
    elseif eventType == ModelWonderland.EVENT_BEAST then

        local resOffset = self:GetMgr():GetTranPosition(eventCfg.resSite)/100
        local layerIndex = eventData.layerIndex
        local posY = layerIndex*0.8 -2
        local pos = Vector3.New(0,posY,0) + resOffset
        local endFunc = function()
            local isMeet = eventData.isMeet
            if isMeet then
                eventData.beastState = 1
                --GF.OpenWnd("UIEdenMonsterPop",{data= eventData,eventType = ModelWonderland.EVENT_BEAST,wndType = 7,isFirst = true})

                self:OpenBeastWnd(eventData)
            end
        end

        self:RefreshBeastAni()

        self:MoveTo(pos,endFunc)

    elseif eventType == ModelWonderland.EVENT_OCTOPUS then
        print("refresh event")
        local spine = self:GetSpineObject()
        if not spine or not spine:IsDpValid() then
            return
        end
        local dpTrans = spine:GetSpineTrans()

        local pos = self._data.position
        if status == StructWonderlandGrid.PLAYER then
             pos = pos + Vector3.New(0,-0.4,0)
        end
        dpTrans.position = pos
    end
end

function LWonderEventObj:OpenBeastWnd(eventData)

    if gModelGameHelperAlleviation:CheckWonderlandIsAutoRun() then
        return
    end

    GF.OpenWnd("UIEdenMonsterPop",{data= eventData,eventType = ModelWonderland.EVENT_BEAST,wndType = 7,isFirst = true})
end

function LWonderEventObj:OnLoaded()
    local eventId = self._data.eventId
    local eventCfg = gModelWonderland:GetEventConfig(eventId)
    local type = eventCfg.type
    if type ~= ModelWonderland.EVENT_BEAST then
        return
    end

    self:RefreshBeastAni()

    if self._data.onLoaded then
        self._data.onLoaded()
    end
end

function LWonderEventObj:RefreshBeastAni()
    local sleepBout = gModelWonderland:GetBeastSleep()
    local ani = "idle"
    if sleepBout > 0 then
        ani = "sleep"
    end
    local spine = self:GetSpineObject()
    if spine and spine:IsDpValid() then
        spine:PlayAnimation(0,ani,true)
    end
end

function LWonderEventObj:MoveTo(targetPos,endCall)
    local btObjectView = self:GetBtObjectView()
    if not btObjectView then
        self._moveData =
        {
            targetPos = targetPos,
            endCall = endCall,
        }
        return
    end



    local obj = self:GetSpineObject()
    local curPos = obj:GetDisplayTrans().position
    local dis = Mathf.Abs(curPos.y - targetPos.y)
    if dis<0.01 then
        return
    end
    local speed = 1
    local time = dis/speed
    --time = Mathf.Clamp(time,0.1,0.8)
    obj:PlayAnimation(0,"run",true)
    btObjectView:StartMove(targetPos,time)

    local seq = self._seqCom:CreateSeq("moveDelay")
    seq:AppendInterval(time)
    seq:OnComplete(function ()
        self._seqCom:DeleteSeq("moveDelay")
        if endCall then
            endCall()
        end
        local sleepBout = gModelWonderland:GetBeastSleep()
        local ani = "idle"
        if sleepBout >0 then
            ani = "sleep"
        end
        obj:PlayAnimation(0,ani,true)
    end)
    seq:PlayForward()
end

function LWonderEventObj:GetSpineObject()
    local gridKey = self._data.gridKey
    local eventId = self._data.eventId
    local spineKey = string.format("spine_%s#%s",gridKey,eventId)
    local spine = self:GetObjCtrl():FindObjByKey(spineKey)
    return spine
end

function LWonderEventObj:GetBtObjectView()
    if self._btObjectView then
        return self._btObjectView
    end
    local spine = self:GetSpineObject()
    if not spine or not spine:IsDpValid() then
        return
    end
    local dpTrans = spine:GetSpineTrans()
    local dpGo = dpTrans.gameObject
    local comp = dpGo:GetComponent(typeofBtObjectView)
    if(not comp) then
        comp = dpGo:AddComponent(typeofBtObjectView)
    end
    self._btObjectView = comp
    return comp
end



return LWonderEventObj
