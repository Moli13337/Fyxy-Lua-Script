---
--- Created by BY.
--- DateTime: 2023/10/22 21:29:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFightSowWin:LWnd
local UIFightSowWin = LxWndClass("UIFightSowWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFightSowWin:UIFightSowWin()
	self:SetHideHurdle()
	self:SetHideTop()
	self:SetHideBottom()
	FireEvent(EventNames.ON_CHAT_SHOW,false)
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFightSowWin:OnWndClose()
	FireEvent(EventNames.ON_CHAT_SHOW,true)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFightSowWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFightSowWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIFightSowWin:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GetFormationListResp,function (pb)
		FireEvent(EventNames.REFRESH_BATTLE_TEAM_SHOW)
	end)
	self:SetWndToggleDelegate(self.mSkipToggle,function (value)
		self._skipToggle = value
	end)
end

function UIFightSowWin:GetCombatTypeData75(combatType,para)
	local title = gModelTower:GetTowerCurrNameByType(ModelTower.RACE_TYPE_99)
	local towerType = gModelTower:GetTowerTypeByCombatTyep(combatType)
	local _callFunc = function () GF.OpenWndBottom("UITaWin",{towerType = towerType}) end
	local desList = string.split(ccClientText(22314),"|")
	local monsterArr = gModelTower:GetTowerLayerMonstorLen(ModelTower.RACE_TYPE_99)
	local data = {
		title = title,
		callFunc = _callFunc,
		desList = desList,
		formationLen = #monsterArr
	}
	return data
end

function UIFightSowWin:InitEvent()
	self._getDataByCombatTypeFunc = {
		[LCombatTypeConst.COMBAT_TYPE_75] = function (...) return self:GetCombatTypeData75(...) end,
	}

	self:SetWndClick(self.mReturnBtn,function() self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnChallenge,function () self:OnClickChallenge() end)
end

function UIFightSowWin:OnClickClose()
	local _callFunc = self._callFunc
	if _callFunc then
		_callFunc()
	else
		GF.ChangeMap("LCityMap")
	end
	self:WndClose()
end

function UIFightSowWin:OnClickChallenge()
	local combatType = self._combatType
	local _skipToggle = self._skipToggle
	local func = function(index)
		gLFightManager:PrepareGoToBattle(combatType, {curTeam = index})	--切换到布阵界面
		gModelBattle:SetIsSkipBattlePrepare(combatType,_skipToggle)
	end
	if not _skipToggle then
		if func then func() end
		return
	end
	local battleFunc = function()
		local combatData =
		{
			combatType = combatType,
		}
		gModelBattle:StartAfterSetFormation(combatData)
		gModelBattle:SetIsSkipBattlePrepare(combatType,_skipToggle)
	end
	local type,index = gModelTower:GetIsTowerBattle(combatType,5)
	if type > 0 then
		if type == 1 then
			gModelGeneral:OpenUIOrdinTips({refId = 80017,func = function ()
				if func then func() end
			end})
		elseif type == 2 or type == 3 then
			local posList = index or {}
			local strList = {}
			for k,v in ipairs(posList) do
				local str = string.replace(ccClientText(21817),v+1)
				table.insert(strList,str)
			end
			local paraStr = table.concat(strList,",")
			local para = nil
			if type == 2 then
				para =
				{
					refId = 80016,
					para = {paraStr},
					func = function()
						func(posList[1])
					end,
					leftFunc = battleFunc
				}
			else
				para =
				{
					refId = 80015,
					para = {paraStr},
					func = function()
						func(posList[1])
					end
				}
			end


			gModelGeneral:OpenUIOrdinTips(para)
		end
		return
	end
	if battleFunc then battleFunc() end
end

function UIFightSowWin:InitCommand()
	local combatType = self:GetWndArg("combatType")
	local para = self:GetWndArg("extraData")
	local title,_callFunc,desList,formationLen
	local func = self._getDataByCombatTypeFunc[combatType]
	if func then
		local _data = func(combatType,para)
		if _data then
			title,_callFunc,desList,formationLen = _data.title,_data.callFunc,_data.desList,_data.formationLen
		end
	end
	self._skipToggle = gModelBattle:GetIsSkipBattlePrepare(combatType)
	self._combatType = combatType
	self._callFunc = _callFunc
	self._formationLen = formationLen
	local combatData={}
	combatData.combatType=combatType
	title = gModelBattle:GetOtherName(combatData)
	self:SetWndText(self.mTitleText,title)
	self:SetWndText(self.mToggleText,ccClientText(10364))
	self:SetWndButtonText(self.mBtnChallenge,ccClientText(22310))
	self:SetWndToggleValue(self.mSkipToggle,self._skipToggle)
	local uiList = self:GetUIScroll("desSuper")
	local list = desList or {}
	self._desLen = #list or 0
	uiList:Create(self.mDesSuper,list,function (...) self:ListItem(...) end, UIItemList.SUPER)

	gModelFormation:OnGetFormationListReq({combatType})

	self:SetWndText(self.mTxtReturn,ccClientText(41102))
end

function UIFightSowWin:ListItem(list, item, itemdata, itempos)
	local desText = self:FindWndTrans(item,"DesText")

	self:SetWndText(desText,itemdata or "")
	local uiText = LxUiHelper.FindXTextCtrl(desText)
	local height = uiText.preferredHeight
	LxUiHelper.SetSizeWithCurAnchor(item,1,height)

end

function UIFightSowWin:OnTryTcpReconnect()
	gModelFormation:OnGetFormationListReq({self._combatType})
end
------------------------------------------------------------------
return UIFightSowWin


