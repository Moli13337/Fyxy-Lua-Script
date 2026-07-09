---
--- Created by Administrator.
--- DateTime: 2023/10/16 10:05:36
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenLord:LWnd
local UIEdenLord = LxWndClass("UIEdenLord", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenLord:UIEdenLord()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenLord:OnWndClose()
    if self._rewardListCls then
        self._rewardListCls:Destroy()
        self._rewardListCls = nil
    end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenLord:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenLord:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

    self:SetStaticContent()
    self:InitWndPara()
    self:InitUIEvent()
    self:InitEvent()
    self:SetEventShow()

    local layerIndex = self._data.layerIndex
    local gridIndex = self._data.gridIndex
    gModelWonderland:WonderlandHeroMonsterReq(1,layerIndex,gridIndex)

end

function UIEdenLord:InitEvent()
    self:WndNetMsgRecv(LProtoIds.WonderlandHeroMonsterResp,function(...) self:OnWonderlandHeroMonsterResp(...) end)
    self:WndNetMsgRecv(LProtoIds.WonderlandScenePageResp,function (...) self:ShowBuffList() end)
end

function UIEdenLord:ShowRewardList()
    local data = self._data
    local layerIndex = data.layerIndex
    --local eventCfg = self._eventCfg
    local rewardId = gModelWonderland:GetEventRewardId(self._data.eventId)
    local reward = gModelWonderland:GetEventReward(rewardId,layerIndex)


    local rewardList = self._rewardListCls
    if not rewardList then
        rewardList = UIIconEasyList:New()
        self._rewardListCls = rewardList
        rewardList:Create(self, self.mItemList)
    end
    rewardList:RefreshList(reward)
end

function UIEdenLord:ShowMonsterList()
    local monsterList = self._monsterList
    local bossList = self._battleData.bossList

    if not monsterList then
        monsterList =self:GetUIScroll("monsterList")
        self._monsterList = monsterList
        monsterList:Create(self.mHeroList,bossList,function (...) self:OnDrawHero(...) end)
    else
        monsterList:RefreshList(bossList)
    end
end

function UIEdenLord:ShowBuffList()
    local layerIndex = self._data.layerIndex
    local gridIndex = self._data.gridIndex
    local eventId = self._data.eventId
    local eventData = gModelWonderland:GetEventData(layerIndex,gridIndex,eventId)

    local treasures = eventData.fixedTreasure or ""
    local dataList = LxDataHelper.ParseNumber_Sign(treasures,"|")

    local buffList = self._buffList
    if not buffList then
        buffList = self:GetUIScroll("buffList")
        self._buffList = buffList
        buffList:Create(self.mBuffList,dataList,function (...) self:OnDrawBuff(...) end)
    else
        buffList:RefreshList(dataList)
    end


end

function UIEdenLord:InitUIEvent()
    self:SetWndClick(self.mMask,function ()
        self:WndClose()
    end)

    self:SetWndClick(self.mGoBtn,function ()
        self:OnClickBattle()
    end)

    self:SetWndClick(self.mCancelBtn,function ()
        self:OnClickCancel()
    end)

    local isSkip = gModelWonderland:GetSkipPrepare()
    self:SetWndToggleValue(self.mSkipPrepare,isSkip)
    self:SetWndToggleDelegate(self.mSkipPrepare,function (value)
        local isSuc = gModelWonderland:SetSkipPrepare(value)
        if not isSuc then
            self:SetWndToggleValue(self.mSkipPrepare,not value)
        end
    end)

    self:SetWndClick(self.mRefreshBtn,function ()
        self:OnClickRefresh()
    end)

end

function UIEdenLord:SetEventShow()
	local eventCfg = self._eventCfg
	local name = ccLngText(eventCfg.name)
    self._name = name
	self:SetWndText(self.mMainTitle,name)

	local spineKey = eventCfg.prefab
    local prefabSize = eventCfg.prefabSize or 1
	if string.isempty(spineKey) then
		return
	end
	self:CreateWndSpine(self.mRole,spineKey,spineKey,false,function (spine)
		spine:SetScale(prefabSize)
		spine:PlayAnimation(0,"idle",true)
	end)
    local eventId = self._data.eventId
	local textId = gModelWonderland:GetEventTextId(eventId)
	local textCfg = gModelWonderland:GetEventTextConfig(textId)
	local post = ccLngText(textCfg.dec)
	self:SetWndText(self.mPost,post)

    --self:ShowBuffList()
    self:ShowRewardList()

    printInfoN(string.format("canselect %s",self._canSelect))
    self:SetWndButtonGray(self.mGoBtn,not self._canSelect)
    self:SetWndButtonGray(self.mCancelBtn,not self._canSelect)

    local pattern = gModelWonderland:GetCurPattern()
    local canGiveUp = self._eventCfg.waive == 1
    local isToughMode = pattern == ModelWonderland.TOUGH
    local showCancel = canGiveUp and isToughMode
    CS.ShowObject(self.mCancelBtn,showCancel)

    self:ShowRefreshPart()
end


function UIEdenLord:ShowRefreshPart()
    local pattern = gModelWonderland:GetCurPattern()
    local isToughMode = pattern == ModelWonderland.TOUGH
    CS.ShowObject(self.mRefreshPart,isToughMode)

    local layerIndex = self._data.layerIndex
    local gridIndex = self._data.gridIndex
    local eventId = self._data.eventId
    local eventData = gModelWonderland:GetEventData(layerIndex,gridIndex,eventId)

    local refreshCnt = eventData.refreshCount

    local str = ""
    if isToughMode then
        local refreshMax = gModelWonderland:GetWonderlandPara("refreshNum")
        str = ccClientText(16783)
        str = string.replace(str,refreshCnt,refreshMax)
    end
    self:SetWndText(self.mRefreshTxt,str)
end

function UIEdenLord:SetStaticContent()
	local str =ccClientText(16780) --"魔 卡"
	self:SetWndText(self.mTitle1,str)
	str =ccClientText(10361) --"奖励"
	self:SetWndText(self.mTitle,str)
	local text = self:FindWndTrans(self.mSkipPrepare,"Label")
	local str=ccClientText( 10341)--"跳过战前布阵"
	self:SetWndText(text,str)

	str =ccClientText(16781) --"挑 战"
	self:SetWndButtonText(self.mGoBtn,str)
	str =ccClientText(16782) --"放 弃"
	self:SetWndButtonText(self.mCancelBtn,str)

	self:SetWndText(self.mCloseTip,ccClientText(10103))
end

function UIEdenLord:OnDrawBuff(list,item,itemdata,itempos)
    local bg = self:FindWndTrans(item,"bg")
    local icon = self:FindWndTrans(item,"icon")
    local level = self:FindWndTrans(item,"level")
    local name = self:FindWndTrans(item,"name")


    local cfg = gModelWonderland:GetTreasureConfig(itemdata)
    if not cfg then
        return
    end
    local iconPath = cfg.resId
    self:SetWndEasyImage(icon,iconPath)
    self:SetWndEasyImage(bg,cfg.frameMin)

    self:SetWndText(name,ccLngText(cfg.name))
    local str = string.replace(ccClientText(10067),cfg.lv)
    self:SetWndText(level,str)

    self:SetWndClick(icon,function ()
        GF.OpenWnd("UIWonderBfTip",{refId = itemdata})
    end)

    local instanceId = bg:GetInstanceID()
    self:CreateWndEffect(bg,"ui_fx_mokashaoguang",instanceId,100)
end

function UIEdenLord:OnClickBattle()
    if self:IsWndClosed() then
        return
    end

    if not  self._canSelect then
        local str = ccClientText(16717)
        GF.ShowMessage(str)--"不可前往")
        return
    end

    if not self._battleData then
        return
    end

    local state = self._data.state
    local gridIndex = self._data.gridIndex
    local layerIndex = self._data.layerIndex
    if state == StructWonderlandGrid.ALLOW then
        gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
    end

    local battleData = self._battleData
    local eventId = self._data.eventId
    local event = gModelWonderland:GetEventData(layerIndex,gridIndex,eventId)

    if not event then
        return
    end

    local wndName = self:GetWndName()
    gModelWonderland:EnterBattle(battleData,wndName)
end

function UIEdenLord:OnClickCancel()

    if not self._canSelect then
        local str =ccClientText(16779) --"您还没有靠近%s"
        str = string.replace(str,self._name)
        GF.ShowMessage(str)
        return
    end

    local data = self._data
    local layerIndex = data.layerIndex
    local gridIndex = data.gridIndex

    local state = data.state


    local moreInfo = string.format("%s|%s",layerIndex,gridIndex)

    local para =
    {
        refId = 70015,
        func = function()
            if state == StructWonderlandGrid.ALLOW then
                gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
            end
            gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_GIVE_UP,moreInfo)
            GF.CloseWndByName("UIEdenLord")
        end
    }

    gModelGeneral:OpenUIOrdinTips(para)
    --gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_GIVE_UP,moreInfo)

    --self:WndClose()
end

function UIEdenLord:InitWndPara()
	local data = self:GetWndArg("data")
	self._eventType = data.eventType
	self._data = data
    self._canSelect = data.canSelect

    local eventId = data.eventId
    self._eventCfg = gModelWonderland:GetEventConfig(eventId)

end

function UIEdenLord:OnClickRefresh()

    if not  self._canSelect then
        local str =ccClientText(16779) --"您还没有靠近%s"
        str = string.replace(str,self._name)
        GF.ShowMessage(str)

        return
    end

    gModelWonderland:RefreshFormation(self._data)
end

function UIEdenLord:OnWonderlandHeroMonsterResp(pb)

    local eventCfg = self._eventCfg
    local eventName =ccLngText(eventCfg.name)

    self._battleData = gModelWonderland:FormatBattleData(pb,eventName)

    self:ShowMonsterList()
    self:ShowBuffList()

    self:ShowRefreshPart()
end

function UIEdenLord:OnDrawHero(list, item,itemdata,itempos)
    local blood = self:FindWndTrans(item,"blood")

    local value =0
    if itemdata.maxHp>0 then
        value =itemdata.curHp/itemdata.maxHp
    end
    LxUiHelper.SetProgress(blood,value)

    local id,refId,star,level,grade,fightPower = itemdata.id,itemdata.refId,itemdata.star,itemdata.lvl,itemdata.grade,itemdata.power
    local herodata = {}
    herodata.id = id
    herodata.refId = refId
    herodata.star = star
    herodata.level = level
    herodata.isMon = itemdata.heroType == ModelWonderland.ENEMY_MONSTER
    herodata.monsterAddCost = itemdata.monsterAddCost
    herodata.skin = itemdata.skin

    local heroTrans = self:FindWndTrans(item,"HeroIcon")

    local instanceId = item:GetInstanceID()
    local heroIconCls = self:GetCommonIcon(instanceId)
    heroIconCls:Create(heroTrans)
    heroIconCls:SetHeroDataSet(herodata)
    heroIconCls:DoApply()

    self:SetWndClick(heroTrans,function ()
        local str = ccClientText(16905)
        GF.ShowMessage(str)
    end)

    local deadTag = self:FindWndTrans(item,"deadTag")
    local hireTag = self:FindWndTrans(item,"hireTag")
    local isDead = itemdata.curHp<= 0
    CS.ShowObject(deadTag,isDead)
    local isHire = itemdata.heroType ==ModelWonderland.HIRE_HERO
    CS.ShowObject(hireTag,isHire)
end

------------------------------------------------------------------
return UIEdenLord


