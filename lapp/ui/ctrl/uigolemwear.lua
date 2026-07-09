---
--- Created by LCM.
--- DateTime: 2022/11/2 11:43:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemWear:LWnd
local UIGolemWear = LxWndClass("UIGolemWear", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemWear:UIGolemWear()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemWear:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemWear:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemWear:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()

	--self:InitGolemWearList()
    self:TryGetRecommendData()
end

function UIGolemWear:OnGolemWearResp(pb)
    if pb.opsType == ModelGolem.OPSTYPE_TYPE_WEAR then
        self:WndClose()
    end
end

function UIGolemWear:CheckIsSelSuit(itemdata)
    if not self._selSuitInfo then return false end
    local selRefId = self._selSuitInfo.refId
    local refId = itemdata.refId
    return refId == selRefId
end

function UIGolemWear:TryGetRecommendData()
    local refId = self._heroServerData and self._heroServerData.refId
    self._curHeroReid = refId
    self._hotDataMap = {}
    if refId then
        local heroRef = gModelHero:GetHeroRef(refId)
        if heroRef and heroRef.quality >= 6 then -- 传说已经神话才需要显示热门数据
            local hotData = gModelGeneral:OnGetHeroRecommendData(2, refId)
            if not hotData then
                gModelGeneral:OnHeroRecommendDataReq(2, refId)
                return
            end
            self._hotDataMap = hotData
        end
    end
    self:InitGolemWearList()
end

function UIGolemWear:OnClickGolemWearFunc(itemdata,  itempos)
    local isSel = self:CheckIsSelSuit(itemdata)
    if isSel then return end
    self._selSuitInfo = itemdata
    local uiGolemWearList = self._uiGolemWearList
    if uiGolemWearList then
        uiGolemWearList:DrawItemByIndex(self._selItemPos)
        uiGolemWearList:DrawItemByIndex(itempos)
        --uiGolemWearList:DrawAllItems()
    end
    self._selItemPos = itempos
end

function UIGolemWear:OnDrawGolemWearCell(list,item,itemdata,itempos)
    local IconTrans = self:FindWndTrans(item,"Icon")
    local NameTrans = self:FindWndTrans(item,"Name")
    local NoFullImgTrans = self:FindWndTrans(item,"NoFullImg")
    local FullImgTrans = self:FindWndTrans(item,"FullImg")
    local NoFullTextTrans = self:FindWndTrans(item,"NoFullImgText")
    local FullTextTrans = self:FindWndTrans(item,"FullImgText")
    local RecommendImgTrans = self:FindWndTrans(item,"RecommendImg")
    local SelImgTrans = self:FindWndTrans(item,"SelImg")
    local EffRootTrans = self:FindWndTrans(item,"EffRoot")
    local BtnTrans = self:FindWndTrans(item,"Btn")
    local HotNodeTrans = self:FindWndTrans(item,"HotNode")
    local hotTextTrans = self:FindWndTrans(HotNodeTrans, "HotText")
    local HotImgTrans = self:FindWndTrans(item, "HotImg")

    IconTrans.localScale = Vector2(0.8, 0.8)
    self:SetWndEasyImage(IconTrans,itemdata.icon,function()
        CS.ShowObject(IconTrans,true)
    end,true)

    self:SetWndText(NameTrans,itemdata.name)

    local isFull = itemdata.isFull
    if isFull then
        local str = string.replace(ccClientText(33227),ModelGolem.SUIT_WEAR_2)
        self:SetTextTile(FullImgTrans,str)
        self:SetWndText(FullTextTrans, str)
    else
        local str = string.replace(ccClientText(33227),ModelGolem.SUIT_WEAR_2)
        self:SetTextTile(NoFullImgTrans, str)
        self:SetWndText(NoFullTextTrans, str)
    end

    local isForeign =false-- gLGameLanguage:IsForeignRegion()
    CS.ShowObject(FullImgTrans,isFull and not isForeign)
    CS.ShowObject(NoFullImgTrans,not isFull and not isForeign)
    CS.ShowObject(FullTextTrans,isFull and isForeign)
    CS.ShowObject(NoFullTextTrans,not isFull and isForeign)

    local isRecommend = itemdata.isRecommend
    if isRecommend then
        local key = EffRootTrans:GetInstanceID()
        self:CreateWndEffect(EffRootTrans,"ui_fx_golem_item_recommend_01",key,100)
    end
    CS.ShowObject(RecommendImgTrans,itemdata.recommendStatus == 1)
    CS.ShowObject(EffRootTrans,isRecommend)

    local isSel = self:CheckIsSelSuit(itemdata)
    CS.ShowObject(SelImgTrans,isSel)

    self:SetWndClick(BtnTrans,function()
        self:OnClickGolemWearFunc(itemdata, itempos)
    end)

    self:SetWndLongClick(BtnTrans,function()
        self:OnLongClickGolemWearFunc(itemdata)
    end,0.8,false)

    if itemdata.recommendStatus == 2 then
        CS.ShowObject(HotImgTrans, true)
        CS.ShowObject(HotNodeTrans, true)
        self:SetWndText(hotTextTrans, string.replace(self._recommendShowFmtStr, tostring(itemdata.hot or "0")))
    else
        CS.ShowObject(HotImgTrans, false)
        CS.ShowObject(HotNodeTrans,false)
    end
end

function UIGolemWear:InitGolemWearList()
    local list = self:GetGolemWearList()
    if not self._selSuitInfo then
        self._selSuitInfo = list[1]
        self._selItemPos = 1
    end
    local uiGolemWearList = self._uiGolemWearList
    if uiGolemWearList then
        uiGolemWearList:RefreshList(list)
        list:DrawAllItems()
    else
        uiGolemWearList = self:GetUIScroll("uiGolemWearList")
        self._uiGolemWearList = uiGolemWearList
        uiGolemWearList:Create(self.mGolemWearList,list,function(...) self:OnDrawGolemWearCell(...) end,UIItemList.SUPER_GRID)
    end
end

function UIGolemWear:OnClickWearBtnFunc()
--[[    local wearList = self._wearList or {}
    local wearNum = 0
    for k,v in pairs(wearList) do
        wearNum = wearNum + 1
    end
    if wearNum > 0 then
        --- 当前身上有穿戴
        gModelGeneral:OpenUIOrdinTips({refId = 310006,func = function()
            self:OnAutoSelWearGolemList()
        end})
    else
        self:OnAutoSelWearGolemList()
    end]]


    ---- jh  是后面优化了，加了11，12的判断；优先级12＞11＞6，每次只显示一个
    self:OnAutoSelWearGolemList()
end

function UIGolemWear:InitData()
    self._heroServerData = self:GetWndArg("heroServerData")
    self._wearList = self:GetWndArg("wearList")

    self._recommendShowFmtStr =  ccClientText(26692) or ""
end

function UIGolemWear:OnClickBtnHelpFunc()
    GF.OpenWnd("UIBzTips",{refId = 503})
end

function UIGolemWear:OnLongClickGolemWearFunc(itemdata)
    gModelGolem:OpenGolemRecommend({
        suitId = itemdata.refId
    })
end

function UIGolemWear:OnWearGolemFunc(wearPosKeyList)
    local heroServerData = self._heroServerData
    if not heroServerData then return end

    local wearGolemIdList = {}
    for k,v in pairs(wearPosKeyList) do
        table.insert(wearGolemIdList,v.id)
    end
    gModelGolem:OnGolemWearReq(ModelGolem.OPSTYPE_TYPE_WEAR,heroServerData.id,wearGolemIdList)
end

function UIGolemWear:InitText()
    self:SetWndText(self.mLblBiaoti,ccClientText(34858))
    self:SetWndButtonText(self.mWearBtn,ccClientText(33217))
    self:SetTextTile(self.mTextTitle3,ccClientText(34807))
end

function UIGolemWear:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mWearBtn,function() self:OnClickWearBtnFunc() end)
    self:SetWndClick(self.mBtnHelp,function() self:OnClickBtnHelpFunc() end)
end

function UIGolemWear:OnHeroRecommendDataResp(pb)
    if self._curHeroReid ~= pb.heroRefId  then return end
    if pb.type ~= 2 then return end
    self._hotDataMap = gModelGeneral:OnGetHeroRecommendData(2, self._curHeroReid)
    self:InitGolemWearList()
end

function UIGolemWear:OnAutoSelWearGolemList()
    local selSuitInfo = self._selSuitInfo
    if not selSuitInfo then return end

    local wearPosKeyList = {}
    local locationKeyList = selSuitInfo.locationKeyList
    local sortGolemFunc = function(a,b)
        return a.score > b.score
    end

    local wearLowPowerGolem = false                 --- 是否穿戴了评分低的魔偶
    local isAllSuitWear = false

    local wearList = self._wearList or {}
    local wearNum = 0
    for k,v in pairs(wearList) do
        wearNum = wearNum + 1
    end


    if locationKeyList then
        local selSuitRefId = selSuitInfo.refId
        local heroRecommendMap = self._heroRecommendMap or {}
        local curSelIsHeroRecommend = heroRecommendMap[selSuitRefId] ~= nil


        local wearPosNum = 0
        local notWearPosKey = {}
        local suitId,golemRefId
        for posRefId,locationList in pairs(locationKeyList) do
            if #locationList > 0 then
                suitId,golemRefId = nil,nil

                local locationInfoList = {}
                for i,v in ipairs(locationList) do
                    if not gModelGolem:GetGolemIsLockByGolemInfo(v) then
                        golemRefId = gModelGolem:GetGolemRefIdByGolemInfo(v)
                        suitId = gModelGolem:GetGolemElementSuitByRefId(golemRefId)
                        table.insert(locationInfoList,{
                            refId = golemRefId,
                            suitId = suitId,
                            score = gModelGolem:GetGolemScoreByGolemInfo(v),
                            id = gModelGolem:GetGolemIdByGolemInfo(v),
                        })
                    end
                end
                table.sort(locationInfoList,sortGolemFunc)

                local first = locationInfoList[1]
                local wearGolem = wearList[posRefId]
                if wearGolem then
                    local firstSuitId = first.suitId
                    local wearGolemSuit = gModelGolem:GetGolemElementSuitByGolemInfo(wearGolem)
                    local wearGolemScore = gModelGolem:GetGolemScoreByGolemInfo(wearGolem)
                    local changeHeroWearGolem = false           --- 是否使用身上穿戴的
                    local firstScore = first.score
                    if curSelIsHeroRecommend then
                        --- 当前为英雄推荐的，且推荐英雄的魔偶存在
                        if wearGolemSuit == firstSuitId then
                            if wearGolemScore >= firstScore then
                                changeHeroWearGolem = true
                                first = wearGolem
                            end
                        end
                    end

                    if wearGolemScore > firstScore and not changeHeroWearGolem then
                        wearLowPowerGolem = true
                    end
                end
                wearPosKeyList[posRefId] = first
                wearPosNum = wearPosNum + 1
            else
                local wearGolem = wearList[posRefId]
                if wearGolem then
                    wearPosKeyList[posRefId] = wearGolem
                    wearPosNum = wearPosNum + 1
                else
                    table.insert(notWearPosKey,posRefId)
                end
            end
        end

        if wearPosNum >= ModelGolem.SHOW_GOLEM_NUM then
            isAllSuitWear = true
        end

        if wearPosNum < ModelGolem.SHOW_GOLEM_NUM then
            --- 若选中的魔偶不足四件套时，则优先穿戴该套装评分最高的套件，剩余没有该套装的位置则穿戴当前位置可穿戴评分最高魔偶
            local golemDrawingList
            for i,posRefId in ipairs(notWearPosKey) do
                golemDrawingList = gModelGolem:GetAutoWearGolemBagList({
                    needGolemDrawing = posRefId,
                })
                if #golemDrawingList > 0 then
                    local locationInfoList = {}
                    for idx,val in ipairs(golemDrawingList) do
                        if not gModelGolem:GetGolemIsLockByGolemInfo(val) then
                            table.insert(locationInfoList,{
                                refId = gModelGolem:GetGolemRefIdByGolemInfo(val),
                                score = gModelGolem:GetGolemScoreByGolemInfo(val),
                                id = gModelGolem:GetGolemIdByGolemInfo(val),
                            })
                        end
                    end
                    table.sort(locationInfoList,sortGolemFunc)
                    local first = locationInfoList[1]
                    local wearGolem = wearList[posRefId]
                    if wearGolem then
                        local changeHeroWearGolem = false           --- 是否使用身上穿戴的
                        local wearGolemScore = gModelGolem:GetGolemScoreByGolemInfo(wearGolem)
                        local firstScore = first.score
                        if wearGolemScore >= firstScore then
                            changeHeroWearGolem = true
                            first = wearGolem
                        end

                        if wearGolemScore > firstScore and not changeHeroWearGolem then
                            wearLowPowerGolem = true
                        end
                    end
                    wearPosKeyList[posRefId] = first
                end
            end
        end
    else
        local tPosGolemInfo
        local firstScore,wearGolem,wearGolemScore
        local autoSelGolemList = gModelGolem:GetAutoSelWearGolemList(sortGolemFunc)
        for pos,posGolemInfo in pairs(autoSelGolemList) do
            wearGolem = wearList[pos]
            if wearGolem then
                local changeHeroWearGolem = false           --- 是否使用身上穿戴的
                wearGolemScore = gModelGolem:GetGolemScoreByGolemInfo(wearGolem)
                firstScore = posGolemInfo.score
                if wearGolemScore >= firstScore then
                    changeHeroWearGolem = true
                    tPosGolemInfo = wearGolem
                else
                    tPosGolemInfo = posGolemInfo
                end

                if wearGolemScore > firstScore and not changeHeroWearGolem then
                    wearLowPowerGolem = true
                end
            else
                tPosGolemInfo = posGolemInfo
            end

            wearPosKeyList[pos] = tPosGolemInfo
        end
    end

    local num = 0
    for k,v in pairs(wearPosKeyList) do
        num = num + 1
    end
    if num < 1 then
        gModelGeneral:OpenUIOrdinTips({refId = 310008,func = function()
            gModelGolem:JumpDreamKillWnd(self:GetWndName())
        end})
        return
    end

    local func = function()
        if not self:IsWndValid() then return end
        self:OnWearGolemFunc(wearPosKeyList)
    end

    if wearLowPowerGolem then
        gModelGeneral:OpenUIOrdinTips({refId = 310012,func = func})
        return
    end

    if isAllSuitWear then
        if wearNum > 0 then
            --- 当前身上有穿戴
            gModelGeneral:OpenUIOrdinTips({refId = 310006,func = func})
        else
            func()
        end
    else
        gModelGeneral:OpenUIOrdinTips({refId = 310011,func = func})
    end

end
------------------------- List -------------------------


function UIGolemWear:GetGolemWearList()
    local wearSuitList = {}

    local wearList = self._wearList or {}
    for k,v in pairs(wearList) do
        local suitId = gModelGolem:GetGolemElementSuitByGolemInfo(v)
        wearSuitList[suitId] = v
    end

    local hotDataMap = self._hotDataMap or {}
    local heroServerData = self._heroServerData
    local golemSkill = gModelGolem:GetHeroGolemSkillByHeroServerData(heroServerData) or {}
    local initGolemSuitRefList = gModelGolem:GetInitGolemSuitRefList()
    local heroRecommendMap = {}
    local list = {}
    local refId

    for k,v in pairs(initGolemSuitRefList) do
        refId = v.refId
        local isRecommend = gModelGolem:CheckSuitIsHaveHeroRecommend(golemSkill,refId)
        local isFull,locationKeyList = gModelGolem:GetGolemListBySuitId(refId)
        --if not isFull then
        --    if wearSuitList[refId] then
        --        isFull = true
        --    end
        --end
        local hotData = hotDataMap[refId]
        local recommendStatus = 0
        local hotNum = 0
        if hotData then
            recommendStatus = 2
            hotNum = hotData
        elseif isRecommend then
            recommendStatus = 1
        end


        local data = {
            refId = refId,
            type = v.type,
            name = v.name,
            sort = v.sort,
            icon = v.icon,
            recommendStatus = recommendStatus,
            hot = hotNum,
            isFull = isFull,
            locationKeyList = locationKeyList,
        }
        table.insert(list,data)
        if isRecommend then
            heroRecommendMap[refId] = data
        end
    end
    self._heroRecommendMap = heroRecommendMap
    table.sort(list,function(a,b)
        local recommendStatusA = a.recommendStatus
        local recommendStatusB = b.recommendStatus
        if recommendStatusA ~= recommendStatusB then
            return recommendStatusA > recommendStatusB
        end
        if recommendStatusA == 2 and a.hot ~= b.hot then
            return a.hot > b.hot
        end
        return a.sort < b.sort
    end)
    return list
end

function UIGolemWear:InitMsg()
    self:WndNetMsgRecv(LProtoIds.GolemWearResp,function(pb) self:OnGolemWearResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.HeroRecommendDataResp, function(pb)
        self:OnHeroRecommendDataResp(pb)
    end)
	-- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end
------------------------- List -------------------------

------------------------------------------------------------------
return UIGolemWear



