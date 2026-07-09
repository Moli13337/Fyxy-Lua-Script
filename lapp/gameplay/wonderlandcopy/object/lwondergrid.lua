local LWonderBase = LXImport("..Base.LWonderBase")
---@class LWonderGrid
local LWonderGrid = LxClass("LWonderGrid",LWonderBase)
local typeBuildClick = typeof(CS.BuildingClick)
local typeLineRenderCtrl = typeof(CS.LineRenderCtrl)
local LWonderEventObj = LXImport(".LWonderEventObj")

LWonderGrid.STATE_BIRTH = 0
LWonderGrid.STATE_READY = 1

function LWonderGrid:LWonderGrid(manager)

    self._monsterTagPath = {
        [0] = "wonderland_txt_4",
        [1] = "wonderland_txt_2",
        [2] = "wonderland_txt_3",
        [3] = "wonderland_txt_3",

    }

    ---@type LWonderManager
    self._manager = manager
    self._seqCom = SequenceCom:New()
    self._state = LWonderGrid.STATE_BIRTH
    self._dynamicObjList={}
end

function LWonderGrid:Create(item,itemdata,interval)
    self._item = item
    self._gridKey = itemdata:GetGridKey()
    self:ShowGridIcon(item,itemdata)


    interval = interval or 0
    if interval >0 then
        local seq = self._seqCom:CreateSeq("birthTween")
        local root = CS.FindTrans(item,"Root")
        local tween = self:FormatGridTween(root)
        --printInfoN("interval "..interval)
        seq:AppendInterval(interval)
        seq:Append(tween)
        seq:OnComplete(function ()
            self._seqCom:DeleteSeq("birthTween")
            self:OnBirthEnd(item,itemdata)
        end)
        seq:PlayForward()
    else
        self:OnBirthEnd(item,itemdata)
    end

end

function LWonderGrid:OnBirthEnd(item,itemdata)
    self._state = LWonderGrid.STATE_READY
    self:ShowGridIcon(item,itemdata)
    self:ShowGridEvent(item,itemdata)
    local root = CS.FindTrans(item,"Root")
    root.transform.localScale = Vector3.New(1,1,1)
    local curLayer = gModelWonderland:GetCurLayer()
    local curGrid = gModelWonderland:GetCurGrid()
    local gridKey = gModelWonderland:FormatGridKey(curLayer,curGrid)
    if gridKey == self._gridKey then
        self._manager:CreateMainRole()
    end
end

function LWonderGrid:FormatGridTween(item)
    item.transform.localScale = Vector3.New(0,0,0)
    local tweener = item.transform:DOScale(Vector3.New(1,1,1),0.2)
    return tweener
end

function LWonderGrid:ShowGridIcon(item,itemdata)
    local gridIcon = CS.FindTrans(item,"Root/GridIcon")

    local layerIndex = itemdata:GetLayerIndex()
    local gridIndex= itemdata:GetGridIndex()
    local gridKey = itemdata:GetGridKey()
    self._gridKey = gridKey

    local data = gModelWonderland:GetGridDataByGridKey(gridKey)
    if not data then
        return
    end

    local stateRecord = gModelWonderland:GetGridOldState()
    local state = stateRecord[gridKey]

    --local state = data:GetStatus()
    if state == StructWonderlandGrid.DISAPPEAR then
        CS.ShowObject(item,false)
        return
    end
    CS.ShowObject(item,true)
    CS.ShowObject(gridIcon,true)
    self:SetClick(item,function ()
        self:OnClickGrid(layerIndex,gridIndex)
    end)

    local pathData = self:GetGridIconByState(state)
    local gridIconPath = nil
    if pathData then
        gridIconPath = pathData.iconPath
    end

    local isInfluenced = data:GetInfluenced()

    if isInfluenced==1 then --结冰方块
        printInfoN("influence grid")
        local eventId = 20021
        local cfg = gModelWonderland:GetEventConfig(eventId)
        gridIconPath = cfg.res

    end

    if LxUiHelper.IsImgPathValid(gridIconPath) then
        self:SetSprite(item,gridIcon,gridIconPath)
    end
end

function LWonderGrid:ShowGridEvent(item,itemdata,isDestroy)
    local gridTag = CS.FindTrans(item,"Root/GridTag")
    local layerIndex = itemdata:GetLayerIndex()
    local gridIndex= itemdata:GetGridIndex()
    local gridKey = gModelWonderland:FormatGridKey(layerIndex,gridIndex)
    --printInfoN("gridKey "..gridKey)
    local data = gModelWonderland:GetGridDataByGridKey(gridKey)
    if not data then
        return
    end
    --local stateRecord = gModelWonderland:GetGridOldState()
    --local state = stateRecord[gridKey]
    --if state == StructWonderlandGrid.DISAPPEAR then
    --    return
    --end

    local eventList = data:GetEventList()

    local monsterType = nil

    local showEventIdList = {}
    for k,v in pairs(eventList) do
        local eventId = v.eventId
        local cfg = gModelWonderland:GetEventConfig(eventId)
        if cfg then
            local showEvent = gModelWonderland:IsEventShow(layerIndex,gridIndex,eventId)
            if showEvent then
                showEventIdList[eventId] = v
                if not monsterType then
                    monsterType = gModelWonderland:GetEventMonsterType(eventId)
                end
            end
        else
            LogError("no event cfg eventid "..(eventId or "nil"))
        end

    end

    if monsterType then
        local iconPath = self._monsterTagPath[monsterType]
        self:SetSprite(item,gridTag,iconPath)
    end

    local showTag = monsterType~=nil

    CS.ShowObject(gridTag,showTag)




    local affectList = gModelWonderland:GetAffectByGrid(gridKey)
    if affectList then
        for k,v in ipairs(affectList) do
            local eventId = v
            local cfg = gModelWonderland:GetEventConfig(eventId)
            local eventType = cfg.type
            local needShow = self:CheckAffectEventShow(gridKey,eventType)

            if needShow then
                showEventIdList[v] = {eventId = eventId}
            end

        end
    end

    --事件显示刷新
    local destroyList = {}
    local addList = {}

    local curEventShowList = self._eventList or {}
    for k,v in pairs(curEventShowList) do

        if not showEventIdList[k] then
            table.insert(destroyList,k)
        end
    end

    local status = data:GetStatus()

    for k,v in pairs(showEventIdList) do
        local eventObj = curEventShowList[k]
        if not eventObj or eventObj:IsDestroyed() then
            table.insert(addList,v)
        else
            eventObj:Refresh(v,status)
        end
    end

    for k,v in ipairs(destroyList) do
        --printInfoN("destroy eventid "..v)
        if isDestroy then
            self:DestroyEventObjByEventId(v)
        else
            self:ClearEventObjByEventId(v)
        end
    end

    for k,v in ipairs(addList) do
        local eventCfg = gModelWonderland:GetEventConfig(v.eventId)
        local type = eventCfg.type
        local position = item.position
        if type == ModelWonderland.EVENT_SNOW then
            position = Vector3.New(0,position.y,0)
        elseif type == ModelWonderland.EVENT_FOAM and v.moreInfo == "1" then
            position = Vector3.New(0,position.y,0)
        end
        self:ShowEvent(position,v,gridKey,status,layerIndex)
    end


end

function LWonderGrid:RefreshGrid(item,itemdata)
    if self._state~= LWonderGrid.STATE_READY then
        return
    end
    self:ShowGridIcon(item,itemdata)
    self:ShowGridEvent(item,itemdata)
end

function LWonderGrid:RefreshGridByData()
    if self._state~= LWonderGrid.STATE_READY then
        return
    end

    local gridKey = self._gridKey
    local gridData = gModelWonderland:GetGridDataByGridKey(gridKey)
    self:ShowGridEvent(self._item,gridData,true)
end

function LWonderGrid:GetGridIconByState(state)
    local themeId = gModelWonderland:GetThemeId()
    local iconPath = gModelWonderland:GetGridIconPath(themeId,state)
    return {iconPath = iconPath}
end

function LWonderGrid:ShowEvent(position,eventdata,gridKey,status,layerIndex)
    local eventId = eventdata.eventId
    local eventCfg = gModelWonderland:GetEventConfig(eventId)
    local resSize = eventCfg.resSize
    local resType = eventCfg.resType
    local res = eventCfg.res
    local resOffset = self:GetTranPosition(eventCfg.resSite)/100
    local pos = position + resOffset

    local eventType = eventCfg.type
    local angle = Vector3.zero
    if eventType == ModelWonderland.EVENT_SNOW then
        local tempStrs = string.split(res,",")
        if #tempStrs>1 then
            res = tempStrs[1]
        end
    elseif eventType == ModelWonderland.EVENT_ARROW_TOWER then
        local gridData = gModelWonderland:GetGridDataByGridKey(gridKey)
        angle = self:GetAngle(eventdata,gridData:GetLayerIndex(),gridData:GetGridIndex())
    elseif eventType == ModelWonderland.EVENT_FOAM then
        local moreInfo = eventdata.moreInfo
        local index = 1
        if tonumber(moreInfo) == 1 then
            index = 2
        end
        local temp= string.split(res,",")
        res = temp[index]
    elseif eventType == ModelWonderland.EVENT_BEAST then
        --local _,layerIndex = gModelWonderland:GetBeastEventInfo()
        --local posY = layerIndex*0.8 -2
        --pos = Vector3.New(0,posY,0)
        return
    end


    local objData =
    {
        position = pos,
        eventId = eventId,
        eventdata = eventdata,
        gridKey = gridKey,
        scale = resSize,
        resType = resType,
        res = res,
        angle = angle,
        status = status,
        eventType = eventType,
        layerIndex = layerIndex,
    }

    self:CreateEventObj(objData)


end


function LWonderGrid:CreateEventObj(objectData)
    local eventObj = LWonderEventObj:New(self._manager)
    eventObj:Create(objectData)

    local eventList= self._eventList
    if not self._eventList then
        eventList = {}
        self._eventList = eventList
    end

    eventList[objectData.eventId] = eventObj
end

function LWonderGrid:ClearEventObj()
    if not self._eventList then
        return
    end
    for k,v in pairs(self._eventList) do
        v:Destroy()
    end
    self._eventList = nil

end

function LWonderGrid:ClearEventObjByEventId(eventId)
    if not self._eventList then
        return
    end

    local eventObj = self._eventList[eventId]
    if not eventObj then
        return
    end

    eventObj:Delete()
    --self._eventList[eventId]= nil
end

function LWonderGrid:DestroyEventObjByEventId(eventId)
    if not self._eventList then
        return
    end

    local eventObj = self._eventList[eventId]
    if not eventObj then
        return
    end
    self._eventList[eventId] = nil
    eventObj:Destroy()
end



function LWonderGrid:SetClick(trans,func)
    local comp = CS.BuildingClick.Get(trans.gameObject)
    local mapName = self._manager:GetMapName()

    local path = LxUiHelper.GetRelativePath(mapName,trans)
    local modifyFun = function()
        printInfoN(string.format("path %s",path))
        if func then
            func()
        end
    end
    comp.ClickDelegate = modifyFun
end

function LWonderGrid:CheckAffectEventShow(gridKey,eventType)
    local gridData = gModelWonderland:GetGridDataByGridKey(gridKey)
    local state = gridData:GetStatus()
    if eventType == ModelWonderland.EVENT_GRANDMA then
        if state == StructWonderlandGrid.PASSED or state == StructWonderlandGrid.DISAPPEAR then
            return false
        else
            return true
        end
    end
end


function LWonderGrid:IsPassed(layerIndex,gridIndex)
    local gridData = gModelWonderland:GetGridData(layerIndex,gridIndex)
    local state = gridData:GetStatus()
    if state == StructWonderlandGrid.PASSED then
        return true
    end
    return false
end

function LWonderGrid:GetAngle(eventData,layerIndex,gridIndex)
    local scopes = eventData.scopes
    local curCnt = gModelWonderland:GetLayerGridCnt(layerIndex)
    local lastLayerIndex = layerIndex-1
    local lastGridIndex = nil
    local lastCnt = gModelWonderland:GetLayerGridCnt(lastLayerIndex)
    if lastCnt>curCnt then
        lastGridIndex = gridIndex
    else
        lastGridIndex = gridIndex - 1
    end

    local isLeft = false
    for k,v in ipairs(scopes) do
        if v.tierIndex == lastLayerIndex and lastGridIndex == v.gridIndex then
            isLeft = true
        end
    end

    local angle = isLeft and Vector3.New(0,180,0) or Vector3.zero
    return angle
end

function LWonderGrid:GetTranPosition(str)
    local tempStr = string.split(str,";")
    local x = tonumber(tempStr[1] or 0)
    local y = tonumber(tempStr[2] or 0)

    return Vector3.New(x,y,0)

end

function LWonderGrid:OnClickGrid(layerIndex,gridIndex)
    if self._state ~= LWonderGrid.STATE_READY then
        return
    end
    printInfoN("OnClickGrid")

    FireEvent(EventNames.ON_WONDER_GRID_CLICK,layerIndex,gridIndex)
end

function LWonderGrid:Destroy()
    if self._seqCom then
        self._seqCom:Destroy()
        self._seqCom = nil
    end

    self:ClearEventObj()


    LWonderBase.Destroy(self)
end

function LWonderGrid:ChangeState(oldState,newState)
    local item = self._item
    if not CS.IsValidObject(item) then
        return
    end
    local resName,type = gModelWonderland:GetPlatformEffectName(oldState,newState)
    local itemdata = gModelWonderland:GetGridDataByGridKey(self._gridKey)
    if not resName or not type then
        self:ShowGridIcon(item,itemdata)
        return
    end
    local key = "platfromEff"..self._gridKey
    self._manager:GetEffCtrl():DestroyByKey(key)
    self._manager:GetObjCtrl():DestroyByKey(key)

    local offset  = Vector3.zero
    local delay = 0.02
    if type == 0 then
        offset = Vector3.New(0,-0.13,0)
        delay = 0.733
        local data =
        {
            key = key,
            resName = resName,
            pos = item.transform.position+ offset,
            scale = 1.1,
            sorting = LGamePlayType.WONDER_SORTING_STATE_RES,
            endFunc = function(spine)
                spine:PlayAnimation(0,"animation",false)
            end
        }

        self._manager:GetObjCtrl():MakeObject(data)
    elseif type == 1 then
        local data =
        {
            key = key,
            resName = resName,
            pos = item.transform.position,
            scale = 1,
        }

        self._manager:GetEffCtrl():MakeObject(data)
    end

    local grid = CS.FindTrans(item,"Root/GridIcon")
    CS.ShowObject(grid,false)
    local seq= self._seqCom:CreateSeq(key)

    seq:AppendInterval(delay)
    seq:AppendCallback(function ()
        CS.ShowObject(grid,true)
        self:ShowGridIcon(item,itemdata)
    end)
    seq:OnComplete(function()
        self._seqCom:DeleteSeq(key)
    end	)
    seq:PlayForward()


end

function LWonderGrid:OnReach()
    if not self._eventList then
        return
    end
    for k,v in pairs(self._eventList) do
        local eventId = k
        local eventCfg = gModelWonderland:GetEventConfig(eventId)
        local eventType =eventCfg.type
        if eventType ==ModelWonderland.EVENT_CLIP then
            v:OnReach()
        end
    end
end

function LWonderGrid:OnToOther(endCall)
    local isFind = false
    local addEventType= nil
    if self._eventList then
        for k,v in pairs(self._eventList) do
            local eventId = k
            local eventCfg = gModelWonderland:GetEventConfig(eventId)
            local eventType =eventCfg.type
            if eventType ==ModelWonderland.EVENT_POD then
                v:OnToOther(endCall)
                isFind = true
            elseif eventType == ModelWonderland.EVENT_BEAN_VINE then
                addEventType = eventType
            end

        end
    end

    if not isFind then
        if endCall then
            endCall(addEventType)
        end
    end
end

function LWonderGrid:RefreshBeanVine()
    if not self._eventList then
        return
    end
    for k,v in pairs(self._eventList) do
        local eventId = k
        local eventCfg = gModelWonderland:GetEventConfig(eventId)
        local eventType =eventCfg.type
        if eventType ==ModelWonderland.EVENT_BEAN_VINE then
            v:RefreshBeanVine()
        end
    end
end


return LWonderGrid