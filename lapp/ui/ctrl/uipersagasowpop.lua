---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPerSagaSowPop:LWnd
local UIPerSagaSowPop = LxWndClass("UIPerSagaSowPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPerSagaSowPop:UIPerSagaSowPop()
	---@type table<number, CommonIcon>
	self._uiHeroIconClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPerSagaSowPop:OnWndClose()
	self:ClearCommonIconList(self._uiHeroIconClsList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPerSagaSowPop:OnCreate()
	LWnd.OnCreate(self)

	self._isMe=true --是否自己
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPerSagaSowPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self._currPlayerId=self:GetWndArg("playerId")
	self:OnClickShowReq()
end

function UIPerSagaSowPop:InitCommand()
	self:SetWndText(self.mNameXUITextObj,ccClientText(11512))
	local list= self.combatHeroData._heros
	local grids=self.combatHeroData._grids
	for i = 1, #list do
		list[i].sort=grids[i]
	end
	table.sort(list,function (a,b)
		return a.sort <b.sort
	end)
	local len=5-#list
	for i = 1, len do
		table.insert(list,{})
	end
	if(self._uiHeroIconList)then
		self._uiHeroIconList:RefreshList(list)
	else
		self._uiHeroIconList = self:GetUIScroll("_uiHeroIconList")
		self._uiHeroIconList:Create(self.mXUIScrollRectObj,list,function (...) self:SetHeroIconListItem(...) end)
	end
end

function UIPerSagaSowPop:SetHeroIconListItem(list,item, itemdata, itempos)
	local heroTrans = CS.FindTrans(item,"HeroIcon")
	local nameText=CS.FindTrans(item,"NameXUIText")
	local addTrans = CS.FindTrans(item,"BtnAdd")

	CS.ShowObject(addTrans,self._isMe)
	if(self._isMe)then
		self:SetWndClick(item, function (...)
			GF.OpenWnd("UIPerSagaSetPop",{
				combatHeroData=self.combatHeroData,
				callFun=function(...)
					self:OnClickShowReq()
				end
			})
		end)
	end
	if(not itemdata.id)then
		CS.ShowObject(heroTrans,false)
		CS.ShowObject(nameText,false)
		return
	end
	CS.ShowObject(heroTrans,true)
	CS.ShowObject(nameText,true)
	local heroData={
		index=itemdata.index,
		id=itemdata.id,
		refId=itemdata.refId,
		star=itemdata.star,
		level=itemdata.lv,
	}
	local color = gModelHero:GetHeroNameColorTableByRefId(heroData.refId)
	local name = gModelHero:GetHeroNameByRefId(heroData.refId,heroData.star)
	if not string.isempty(name) then
		if color then
			local uiText = LxUiHelper.FindXTextCtrl(nameText)
			self:SetXUITextColor(uiText,color)
		end
		self:SetWndText(nameText,name)
	end

	local InstanceID = item:GetInstanceID()
	local uiHeroIconClsList = self._uiHeroIconClsList
	local baseClass = uiHeroIconClsList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiHeroIconClsList[InstanceID] = baseClass
		baseClass:Create(heroTrans)
	end
	baseClass:SetHeroDataSet(heroData)
	baseClass:DoApply()
end

function UIPerSagaSowPop:InitEvent()
	self:SetWndClick(self.mBgImageObj, function (...) self:WndClose() end)
	self:SetWndClick(self.mCloseBtnObj, function (...) self:WndClose() end)
end

function UIPerSagaSowPop:OnGetFormationShowResp(pb)
	local playerId=pb.playerId
	local targetId=pb.targetId
	local heroData=gModelGeneral:SetCombatHeroData(pb.heroData)
	local bMe=playerId==targetId
	self._isMe=bMe
	self.combatHeroData=heroData
	self:InitCommand()
end

function UIPerSagaSowPop:InitMessage()--接协议
	self:WndNetMsgRecv(LProtoIds.GetFormationShowResp,function (...)
		self:OnGetFormationShowResp(...)
	end)
end

function UIPerSagaSowPop:OnClickShowReq()
	local pb = LProtoHelper.CreateProto(LProtoIds.GetFormationShowReq)
	pb.formationType=6
	pb.playerId=gModelPlayer:GetPlayerId()
	pb.targetId=self._currPlayerId
	SendMessage(pb,LProtoIds.GetFormationShowReq)
end

------------------------------------------------------------------
return UIPerSagaSowPop


