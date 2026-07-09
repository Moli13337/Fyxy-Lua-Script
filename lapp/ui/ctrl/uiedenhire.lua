---
--- Created by Administrator.
--- DateTime: 2023/10/27 21:59:57
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenHire:LWnd
local UIEdenHire = LxWndClass("UIEdenHire", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenHire:UIEdenHire()
	---@type table<number, CommonIcon>
	self._uiIconClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenHire:OnWndClose()
	self:ClearCommonIconList(self._uiIconClsList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenHire:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenHire:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self:SetStaticContent()

	self:InitData()
	self:WndNetMsgRecv(LProtoIds.WonderlandHeroHireResp,function (...) self:OnWonderlandHeroHireResp(...) end)
	self:RefreshUI()
	self:InitUIEvent()

	--self:DoWndStartScale(0,self.mRoot)
end

function UIEdenHire:OnClickConfirm()

	if not self._canSelect then
		local str = ccClientText(16715)
		GF.ShowMessage(str)--"您还没有抵达雇佣兵团,不能雇佣英雄!")
		return
	end

	if not self._select then
		local str = ccClientText(16716)
		GF.ShowMessage(str)--"请先选择1名要雇佣的英雄")
		return
	end

	local state = self._data.state
	local gridIndex = self._data.gridIndex
	if state == StructWonderlandGrid.ALLOW then
		gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
	end

	local strId = tostring(self._select)
	gModelWonderland:WonderlandHeroHireReq(1,strId)
	self:WndClose()
end
function UIEdenHire:SetEventTitle(eventId)
	local eventCfg = gModelWonderland:GetEventConfig(eventId)
	local name = ccLngText(eventCfg.name)
	self:SetWndText(self.mMainTitle,name)
end

function UIEdenHire:RefreshUI()
	local data = self:GetWndArg("data")
	self._data = data
	self._canSelect = data.canSelect

	local moreInfo = data.moreInfo

	local btnType = "blue_1"
	if self._canSelect then
		btnType = "yellow_1"
	end
	self:SetColorBtnImg(self.mButton,btnType)
	--self:SetWndImageGray(self.mButton,not self._canSelect)
	gModelWonderland:WonderlandHeroHireReq(0,moreInfo)

	local eventId = data.eventId
	local eventcfg = gModelWonderland:GetEventConfig(eventId)

	self:SetEventTitle(eventId)
	local textId = gModelWonderland:GetEventTextId(eventId)
	if textId then
		local textCfg = gModelWonderland:GetEventTextConfig(textId)
		local post = ccLngText(textCfg.dec)
		self:SetWndText(self.mPost,post)
	end






	local spineKey = eventcfg.prefab
	if string.isempty(spineKey) then
		return
	end
	local prefabSize = eventcfg.prefabSize or 1
	self:CreateWndSpine(self.mRole,spineKey,spineKey,false,function (spine)
		spine:SetScale(prefabSize)
		spine:PlayAnimation(0,"idle",true)
	end)
end


function UIEdenHire:OnDrawHero(list, item,itemdata,itempos)

	local powerBg = self:FindWndTrans(item,"powerBg")
	local powerBgIcon = self:FindWndTrans(powerBg,"icon")
	local powerBgUIText = self:FindWndTrans(powerBg,"UIText")
	local help = self:FindWndTrans(item,"help")

	local heroTrans = self:FindWndTrans(item,"HeroIcon")

	local id,refId,star,level,grade,fightPower = itemdata.id,itemdata.refId,itemdata.star,itemdata.lvl,itemdata.grade,itemdata.power
	local herodata = {
		id = id,
		refId = refId,
		star = star,
		level = level,
		skin = itemdata.skin
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
		self:OnSelectHero(id)
	end)

	self:SetWndText(powerBgUIText,LUtil.PowerNumberCoversion(fightPower))

	self:SetWndClick(help,function ()
		local data = {
			id = id,
			refId = refId,
			level = level,
			star = star,
			grade = grade,
			fightPower = fightPower,
			--isWonderHero = true,
			heroType = 2,
			isResonance = itemdata.isResonance,
			skin = itemdata.skin,
		}
		gModelHero:ReqShowHeroTip("",data)
	end)

	self._heroItemList[id] = baseClass
end

function UIEdenHire:InitUIEvent()
	self:SetWndClick(self.mButton,function () self:OnClickConfirm() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIEdenHire:SetStaticContent()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	local str =ccClientText(16775) --"选择佣兵"
	self:SetWndText(self.mTitle,str)

	str = ccClientText(16799)
	local text =self:FindWndTrans(self.mButton,"Text")
	self:SetWndText(text,str)
end

function UIEdenHire:InitData()
	self._heroItemList = {}
end

function UIEdenHire:OnSelectHero(id)
	if self._select == id then
		return
	end
	local old = self._select
	local heroIcon = nil
	if old then
		heroIcon = self._heroItemList[old]
		if heroIcon then
			heroIcon:ShowGouImg(false)
		end
	end

	self._select = id
	heroIcon = self._heroItemList[id]
	if heroIcon then
		heroIcon:ShowGouImg(true)
	end

end

function UIEdenHire:OnWonderlandHeroHireResp(pb)
	local heroList = pb.info

	local list = self:GetUIScroll("heroList")
	list:Create(self.mHeroList,heroList,function (...) self:OnDrawHero(...) end)
end


------------------------------------------------------------------
return UIEdenHire


