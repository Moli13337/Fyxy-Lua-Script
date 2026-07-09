---
--- Created by Administrator.
--- DateTime: 2024/3/27 17:32:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITaRacePopNew:LWnd
local UITaRacePopNew = LxWndClass("UITaRacePopNew", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaRacePopNew:UITaRacePopNew()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaRacePopNew:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaRacePopNew:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaRacePopNew:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie =gLGameLanguage:IsVieVersion()
	self._isEnus = gLGameLanguage:IsEnglishVersion()
	if self._isEnus then 
		self:SetAnchorPos(self.mTipsBtn,Vector2.New(120,0))
	end
	if self._isVie then
		self:SetAnchorPos(self.mTipsBtn,Vector2.New(130,0))
	end
	self:InitMessage()
	self:CreateRaceList()
	self:SetWndText(self.mTitleText,ccClientText(12100))
	self:SetHideTop(true)
end
function UITaRacePopNew:CreateItem(list,item,itemdata,itemPos)
	local Bg = self:FindWndTrans(item,"Bg")
	local TxtName = self:FindWndTrans(Bg,"TxtName")
	local TxtResidue = self:FindWndTrans(Bg,"ImTxtBg/TxtResidue")
	local TxtOpenTime = self:FindWndTrans(Bg,"TxtOpenTime")
	local TxtCurlevel = self:FindWndTrans(Bg,"ImTxtBg/TxtCurlevel")
	local TxtDescTips = self:FindWndTrans(Bg,"TxtDescTips")
	local ImgLock = self:FindWndTrans(Bg,"ImgMask")
	local ImTxtBg = self:FindWndTrans(Bg,"ImTxtBg")
	local ImgRed = self:FindWndTrans(Bg,"ImgRed")
	self:SetWndClick(Bg,function()
		self:OnClickGoTo(itemdata.refId)
	end)

	self:SetWndText(TxtName,ccLngText(itemdata.name))
	local info = gModelTower:GetTowerInfoByTowerType(itemdata.refId)
	local isOpent = gModelTower:GetIsOpentByTowerType(itemdata.refId)
	local openDayStr = ""
	if itemdata.refId == ModelTower.RACE_COM or itemdata.refId == ModelTower.RACE_TYPE_99  then
		openDayStr = ccClientText(12152)
	else
		openDayStr = string.replace(ccClientText(12150),gModelTower:GetOpenDayStr(itemdata.openDay))
	end


	self:SetWndText(TxtOpenTime,openDayStr)
	self:SetWndText(TxtDescTips,ccLngText(itemdata.description))
	self:SetWndEasyImage(Bg,itemdata.icon)
	self:SetWndEasyImage(ImTxtBg,itemdata.nameIcon)
	CS.ShowObject(ImgLock,not isOpent)

	if not info then
		gModelTower:OnTowerInfoListReq(true)
		self:SetWndText(TxtResidue,string.replace(ccClientText(12149),ccClientText(12820)))
		self:SetWndText(TxtCurlevel,string.replace(ccClientText(12183),ccClientText(12820)))
		return
	end
	CS.ShowObject(TxtResidue,info.maxChallengesNum ~= -1)
	local num = info.maxChallengesNum - info.battleNum
	-- local isShow = isOpent and info.maxChallengesNum ~= -1
	-- local color = "green"
	-- if num <= 0 then
	-- 	num = 0
	-- 	color = "red"
	-- end
	-- local numStr = LUtil.FormatColorStr(num,color)
	self:SetWndText(TxtResidue,string.replace(ccClientText(12149),num))

	local numStr
	if info.floor < itemdata.floor then
		numStr = info.floor + 1
	else
		numStr = info.floor
	end
	self:SetWndText(TxtCurlevel,string.replace(ccClientText(12183),numStr))

	local typeInfo = gModelTower:GetTowerInfoByTowerType(itemdata.refId)
	local num = gModelTower:GetCurrNum(itemdata.refId)
	local redType = gModelTower:GetBehindPhaseArwardRedByType(itemdata.refId)
	CS.ShowObject(ImgRed,(redType>0 or (num>0 and (typeInfo and typeInfo.historyMaxFloor>0))) and isOpent)
	-- if isOpent and info.maxChallengesNum - info.battleNum > 0 then
	-- 	CS.ShowObject(eff,true)
	-- 	self._raceEffList[ref.refId] = eff
	-- 	self:CreateWndEffect(eff,"fx_slzt_weixuanzhong","fx_slzt_weixuanzhong"..ref.refId,100,false,false)
	-- end
end

function UITaRacePopNew:CreateRaceList()
	local raceRef = gModelTower:GetTowerPatternList()
	if not self.list then
		self.list = self:GetUIScroll("TowerRaceList")
		self.list:Create(self.mListRaceType,raceRef,function(...)
			self:CreateItem(...)
		end)
	else
		self.list:RefreshList(raceRef)
	end

end

function UITaRacePopNew:OnClickGoTower(_refId)
	local ref = gModelTower:GetTowerPatternRefByRefId(_refId)
	local isFight= gLFightManager:IsCombatTypeInFight(ref.combatTyep)
	if isFight then
		gLFightManager:PrepareGoToBattle(ref.combatTyep,{})
	else
		GF.OpenWndBottom("UITaWin",{towerType = _refId})
		if _refId == ModelTower.RACE_TYPE_99 then
			_refId = ModelTower.RACE_COM
		end
		LPlayerPrefs.SetTowerRace(_refId)
	end
	self:WndClose()
end

function UITaRacePopNew:OnClickGoTo(_refId)
	if _refId == ModelTower.RACE_COM then
		local towerDifficulty = LPlayerPrefs.towerDifficulty
		--if towerDifficulty == "true" then
		--	_refId = ModelTower.RACE_TYPE_99
		--end
	end
	local ref = gModelTower:GetTowerPatternRefByRefId(_refId)
	local isOpent = gModelTower:GetIsOpentByTowerType(_refId)
	if not isOpent then
		local openDayStr = string.replace(ccClientText(12159),gModelTower:GetOpenDayStr(ref.openDay),ccLngText(ref.name))
		GF.ShowMessage(openDayStr)
		return
	end
	local ref = gModelTower:GetTowerPatternRefByRefId(_refId)
	local refList = gModelTower:GetTowerPatternRef()
	for i, v in pairs(refList) do
		if v.combatTyep ~= ref.combatTyep then
			local isFight= gLFightManager:IsCombatTypeInFight(v.combatTyep)
			if isFight then
				GF.ShowMessage(string.replace(ccClientText(12164),ccLngText(v.name)))
				return
			end
		end
	end
	local cutToEff
	if _refId == ModelTower.RACE_TYPE_99 then
		cutToEff = "fx_slzt_zhuanchang_02"
	end
	GF.OpenWndTop("UITaCutToEff",{cutToEff = cutToEff,callfunc1 = function ()
		self:OnClickGoTower(_refId)
	end})
end

function UITaRacePopNew:InitMessage()
	self:SetWndClick(self.mCloseBtn, function(...)
		if not self:WndCloseAndBack() then
			GF.OpenWndBottom("UIOutts",{ childIndex = 1 })
		end
	end)
	self:SetWndClick(self.mTipsBtn, function(...) GF.OpenWnd("UIBzTips",{refId = 5}) end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:WndEventRecv(EventNames.BATTLE_BACK_END,function () self:CreateRaceList() end)
	self:WndNetMsgRecv(LProtoIds.TowerInfoListResp,function (...)
		self:CreateRaceList()
	end)
end
------------------------------------------------------------------
return UITaRacePopNew