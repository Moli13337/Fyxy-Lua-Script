---
--- Created by Administrator.
--- DateTime: 2023/10/2 17:35:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenSagaBag:LWnd
local UIEdenSagaBag = LxWndClass("UIEdenSagaBag", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenSagaBag:UIEdenSagaBag()
	---@type table<number, CommonIcon>
	self._uiIconClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenSagaBag:OnWndClose()
	self:ClearCommonIconList(self._uiIconClsList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenSagaBag:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenSagaBag:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitUIEvent()
	self:InitEvent()
	self:RefreshUI()

end

function UIEdenSagaBag:InitEvent()
	self:WndNetMsgRecv(LProtoIds.WonderlandScenePageResp,function () self:ShowItemInfo() end)
	self:WndEventRecv(EventNames.On_Item_Change,function () self:ShowItemInfo() end)
	self:WndNetMsgRecv(LProtoIds.WonderlandHeroOpsResp,function () self:ShowHeroList() end)
end

function UIEdenSagaBag:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnOk,function () self:OnClickOk() end)
	self:SetWndClick(self.mAddBtn,function () self:OnClickAdd() end)
end

function UIEdenSagaBag:ShowHeroList()
	local heroList =gModelWonderland:GetHeroListInReborn()

	if self._effRecord then
		for k,v in ipairs(self._effRecord) do
			self:DestroyWndEffectByKey(k)
		end
		self._effRecord = {}
	end


	local list = self:GetUIScroll("heroList")
	list:Create(self.mHeroList,heroList,function (...) self:OnDrawHero(...) end,UIItemList.WRAP,false)

	local uiList = list:GetList()
	uiList:EnableLoadAnimation(true, 0, 4)
	uiList:RefreshList()
end

function UIEdenSagaBag:OnClickOk()
	local isMapEnd = gModelWonderland:IsMapEnd()
	if isMapEnd then
		local str =ccClientText(16769) --"地图已通关，无需重生"
		GF.ShowMessage(str)
		return
	end
	local freeCnt = gModelWonderland:GetFreeRebornCnt()
	local isFree = freeCnt> 0
	if  isFree then
		gModelWonderland:WonderlandHeroOpsReq(1)
		return
	end
	local rebornItem = gModelWonderland:GetWonderlandPara("rebornFire")
	rebornItem = LxDataHelper.ParseItem_3(rebornItem)

	local own = gModelItem:GetNumByRefId(rebornItem.itemId)

	if own >= rebornItem.itemNum then
		gModelWonderland:WonderlandHeroOpsReq(1)
	else
		gModelGeneral:OpenGetWayWnd({itemId = rebornItem.itemId,srcWnd = self:GetWndName()})
	end
end

function UIEdenSagaBag:RefreshUI()
	local str =ccClientText(16713) --"英雄状况"
	self:SetWndText(self.mTitle,str)
	str =ccClientText(16714) -- "雇佣的英雄只可在奇景探险中被使用,重置后将清空所有雇佣英雄"
	self:SetWndText(self.mIntro,str)

	str =ccClientText(16758) -- "复活所有阵亡英雄,并恢复所有英雄生命<#0fb93f>下一场战斗所有英雄攻击+30%</color>"
	self:SetWndText(self.mItemInfo,str)

	self:SetWndButtonText(self.mBtnOk,ccClientText(16774))

	self:ShowItemInfo()

	local rebornItem = gModelWonderland:GetWonderlandPara("rebornFire")
	rebornItem = LxDataHelper.ParseItem_3(rebornItem)
	local own = gModelItem:GetNumByRefId(rebornItem.itemId)

	local itemdata = {
		itemId = rebornItem.itemId,
		itemType = 1,
		itemNum = own,
	}

	self:CreateCommonIconImpl(self.mIconRoot,itemdata)

	gModelWonderland:ClearHpChange()
	self:ShowHeroList()
end


function UIEdenSagaBag:OnClickAdd()
	local rebornItem = gModelWonderland:GetWonderlandPara("rebornFire")
	rebornItem = LxDataHelper.ParseItem_3(rebornItem)
	local wndName = self:GetWndName()
	gModelGeneral:OpenGetWayWnd({itemId =rebornItem.itemId,srcWnd = wndName })
end

function UIEdenSagaBag:OnDrawHero(list, item,itemdata,itempos)
	local blood = self:FindWndTrans(item,"blood")
	--local bloodBackground = self:FindWndTrans(blood,"Background")
	local deadTag = self:FindWndTrans(item,"deadTag")
	--local deadTagMask = self:FindWndTrans(deadTag,"mask")
	--local deadTagDeadText = self:FindWndTrans(deadTag,"deadText")
	local hireTag = self:FindWndTrans(item,"hireTag")

	local heroTrans = self:FindWndTrans(item,"HeroIcon")

	local value =0
	if itemdata.maxHp>0 then
		value =itemdata.curHp/itemdata.maxHp
	end
	LxUiHelper.SetProgress(blood,value)

	local isHire = itemdata.heroType == ModelWonderland.HIRE_HERO
	local heroType= isHire and 2 or 1

	local id,refId,star,level,grade,fightPower = itemdata.id,itemdata.refId,itemdata.star,itemdata.lvl,itemdata.grade,itemdata.power
	local herodata = {
		id = id,
		refId = refId,
		star = star,
		level = level,
		skin = itemdata.skin,
		isResonance = itemdata.resonance,
		form = itemdata.form or 0,
	}

	local instanceId = item:GetInstanceID()
	local baseClass = self._uiIconClsList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiIconClsList[instanceId] = baseClass
		baseClass:Create(heroTrans)
		self:SetIconClickScale(heroTrans, true)
	end

	baseClass:SetHeroDataSet(herodata)
	baseClass:DoApply()

	self:SetWndClick(heroTrans, function()
		local data = {
			id = id,
			refId = refId,
			level = level,
			star = star,
			grade = grade,
			fightPower = fightPower,
			--isWonderHero = isHire,
			heroType = heroType,
			isResonance = itemdata.resonance,
			skin = itemdata.skin,
		}
		gModelHero:ReqShowHeroTip("",data)
	end)

	local isDead = itemdata.curHp<= 0
	CS.ShowObject(deadTag,isDead)

	CS.ShowObject(hireTag,isHire)

	local instanceid = item:GetInstanceID()
	local isChange =  gModelWonderland:IsHpChangeHero(id)
	local key = "relive"..tostring(instanceid)
	if isChange then
		if not self._effRecord then
			self._effRecord = {}
		end
		self._effRecord[key] = true
		table.insert(self._effRecord,key)
		self:CreateWndEffect(heroTrans,"fx_qjtx_wupinshuaxin",key,100)
	else
		if self._effRecord then
			self._effRecord[key] = nil
		end
		self:DestroyWndEffectByKey(key)
	end
end

function UIEdenSagaBag:ShowItemInfo()

	local freeCnt = gModelWonderland:GetFreeRebornCnt()
	local showFree = freeCnt> 0
	CS.ShowObject(self.mIcon,not showFree)
	CS.ShowObject(self.mNum,not showFree)
	if showFree then
		self:SetWndText(self.mCostText,ccClientText(10771))
		return
	end

	local rebornItem = gModelWonderland:GetWonderlandPara("rebornFire")
	rebornItem = LxDataHelper.ParseItem_3(rebornItem)
	local iconPath = gModelItem:GetItemImgByRefId(rebornItem.itemId)
	self:SetWndEasyImage(self.mIcon,iconPath)
	local own = gModelItem:GetNumByRefId(rebornItem.itemId)
	local color = "red"
	if own >= rebornItem.itemNum then
		color = "green"
	end
	local ownStr = LUtil.FormatColorStr(own,color)
	local str = string.format("%s/%s",ownStr,rebornItem.itemNum)
	self:SetWndText(self.mNum,str)
	self:SetWndText(self.mCostText,ccClientText(16722))

end

------------------------------------------------------------------
return UIEdenSagaBag


