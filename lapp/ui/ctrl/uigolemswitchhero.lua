---
--- Created by LCM.
--- DateTime: 2022/10/28 11:50:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemSwitchHero:LWnd
local UIGolemSwitchHero = LxWndClass("UIGolemSwitchHero", LWnd)
UIGolemSwitchHero.TYPE_NORMAL = 1
UIGolemSwitchHero.TYPE_ACTIVITY = 2
UIGolemSwitchHero.TYPE_GOLEM_RECAST = 3
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemSwitchHero:UIGolemSwitchHero()
    self._raceType = UIHeroRaceList.ALL_RACE_REFID
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemSwitchHero:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemSwitchHero:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemSwitchHero:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitHeroList()
end

function UIGolemSwitchHero:CheckHeroRefIdIsSel(heroRefId)
     return self._selHeroId == heroRefId
end

function UIGolemSwitchHero:OnClickNormalEnterBtnFunc()
    if self._selHeroId then
        local func = self._func
        if func then
            func(self._selHeroId)
        end
        self._func = nil
    end
    self:WndClose()
end

function UIGolemSwitchHero:InitData()
    self._curSelHeroId = self:GetWndArg("curSelHeroId")
    self._selHeroId =  self._curSelHeroId

    self._func = self:GetWndArg("func")

    local wndType = self:GetWndArg("wndType") or UIGolemSwitchHero.TYPE_NORMAL
    self._wndType = wndType

    self._sid = self:GetWndArg("sid")
    self._actType = self:GetWndArg("actType")
end

function UIGolemSwitchHero:OnDrawActivityHeroCell(list,item,itemdata,itempos)
    local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
    local HeroNameTrans = self:FindWndTrans(item,"HeroName")
    local heroRefId = itemdata.itemId
    local instanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemdata.itemType,heroRefId,itemdata.itemNum)

    local isSel = self:CheckHeroRefIdIsSel(heroRefId)
    baseClass:SetShowGouImg(isSel)

    baseClass:DoApply()

    local heroName = gModelHero:GetHeroNameByRefId(heroRefId)
    self:SetWndText(HeroNameTrans,heroName)


    self:SetWndClick(IconTrans,function()
        self:OnClickActivityHeroFunc(itemdata)
    end)
end

function UIGolemSwitchHero:GetActivityHeroList()
    local actHeroList = self:GetWndArg("actHeroList")
    return actHeroList
end

function UIGolemSwitchHero:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)
end

function UIGolemSwitchHero:OnDrawNormalHeroCell(list,item,itemdata,itempos)
    local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
    local HeroNameTrans = self:FindWndTrans(item,"HeroName")

    local id,refId,star,level = itemdata.id,itemdata.refId,itemdata.star,itemdata.lv
    local isSelect = self:CheckHeroIdIsSel(id)
    local instanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    local herodata = {
        trans = IconTrans,
        id = id,
        refId = refId,
        star = star,
        level = level,
        skin = itemdata.skin,
        selected = isSelect,
        treeInfo = itemdata.treeInfo
    }
    baseClass:SetHeroDataSet(herodata)
    baseClass:DoApply()

    local heroName = gModelHero:GetHeroNameByRefId(refId, star)
    self:SetWndText(HeroNameTrans,heroName)

    self:SetWndClick(IconTrans,function()
        self:OnClickNormalHeroFunc(itemdata)
    end)
end

function UIGolemSwitchHero:OnClickActivityHeroFunc(itemdata)
    local heroRefId = itemdata.itemId
    local isSel = self:CheckHeroRefIdIsSel(heroRefId)
    if isSel then
        self._selHeroId = nil
    else
        self._selHeroId = heroRefId
    end
    self:RefreshHeroList()
end

function UIGolemSwitchHero:InitHeroList()
    local list = self:GetHeroList()

    local onDrawHeroCellFunc
    local wndType = self._wndType
    if wndType == UIGolemSwitchHero.TYPE_NORMAL or wndType == UIGolemSwitchHero.TYPE_GOLEM_RECAST then
        onDrawHeroCellFunc = function(...)
            self:OnDrawNormalHeroCell(...)
        end
    elseif wndType == UIGolemSwitchHero.TYPE_ACTIVITY then
        onDrawHeroCellFunc = function(...)
            self:OnDrawActivityHeroCell(...)
        end
    end



    local uiHeroList = self._uiHeroList
    if uiHeroList then
        uiHeroList:RefreshList(list)
    else
        uiHeroList = self:GetUIScroll("uiHeroList")
        self._uiHeroList = uiHeroList
        uiHeroList:Create(self.mHeroList,list,function(...)
            if onDrawHeroCellFunc then
                onDrawHeroCellFunc(...)
            end
        end,UIItemList.WRAP)
        uiHeroList:EnableScroll(true,false)
    end
end

function UIGolemSwitchHero:OnClickEnterBtnFunc()
    local wndType = self._wndType
    if wndType == UIGolemSwitchHero.TYPE_NORMAL or wndType == UIGolemSwitchHero.TYPE_GOLEM_RECAST then
        self:OnClickNormalEnterBtnFunc()
    elseif wndType == UIGolemSwitchHero.TYPE_ACTIVITY then
        self:OnClickActivityEnterBtnFunc()
    end
end
------------------------- List -------------------------
function UIGolemSwitchHero:GetNormalHeroList()
    return gModelGolem:GetCutGolemWearHeroList(self._raceType)
end

function UIGolemSwitchHero:OnClickNormalHeroFunc(itemdata)
    local id = itemdata.id
    local isSel = self:CheckHeroIdIsSel(id)
    if isSel then
        self._selHeroId = nil
    else
        self._selHeroId = id
    end
    self:RefreshHeroList()
end

function UIGolemSwitchHero:InitText()
    self:SetWndText(self.mLblBiaoti,ccClientText(33245))
    self:SetWndButtonText(self.mEnterBtn,ccClientText(10102))
end

function UIGolemSwitchHero:OnClickActivityEnterBtnFunc()
    if self._selHeroId then
        if not self._actType then return end
        gModelActivity:OnActivitySpecialOpReq(self._sid,nil,nil,nil,tostring(self._selHeroId),self._actType)
    else
        self:WndClose()
    end
end

function UIGolemSwitchHero:InitMsg()
     self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function(pb) self:OnActivitySpecialOpResp(pb) end)

	-- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIGolemSwitchHero:OnActivitySpecialOpResp(pb)
    if not self._sid then return end
    local wndType = self._wndType
    if wndType == UIGolemSwitchHero.TYPE_NORMAL then return end
    if pb.sid ~= self._sid then return end
    local opType = pb.opType
    if opType == ModelActivity.SELECT_HERO_COMBAT or opType == ModelActivity.SELECT_HERO_UP_STAR then
        self:WndClose()
    end
end

function UIGolemSwitchHero:CheckHeroIdIsSel(id)
    return id == self._selHeroId
end

function UIGolemSwitchHero:RefreshHeroList()
    local uiHeroList = self._uiHeroList
    if uiHeroList then
        local uiList = uiHeroList:GetList()
        uiList:RefreshList()
    end
end

function UIGolemSwitchHero:GetHeroList()
    local wndType = self._wndType
    if wndType == UIGolemSwitchHero.TYPE_NORMAL then
        return self:GetNormalHeroList()
    elseif wndType == UIGolemSwitchHero.TYPE_ACTIVITY then
        return self:GetActivityHeroList()
    elseif wndType == UIGolemSwitchHero.TYPE_GOLEM_RECAST then
        local list = {}
        local wearMap,wearList,golemStar
        local golemStars = gModelGolem:GetGolemStars()
        local heroList = self:GetNormalHeroList()
        for i,v in ipairs(heroList) do
            wearMap,wearList = gModelGolem:GetHeroWearGolemListByHeroId(v.id)
            if wearList and #wearList > 0 then
                for idx,wearInfo in ipairs(wearList) do
                    golemStar = gModelGolem:GetGolemElementStarByGolemInfo(wearInfo.golemInfo)
                    if golemStar >= golemStars then
                        table.insert(list,v)
                        break
                    end
                end
            end
        end
        return list
    end
    return {}
end
------------------------- List -------------------------

------------------------------------------------------------------
return UIGolemSwitchHero



