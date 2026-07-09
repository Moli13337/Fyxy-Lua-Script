---
--- Created by BY.
--- DateTime: 2023/10/7 11:50:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITaRacePop:LWnd
local UITaRacePop = LxWndClass("UITaRacePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaRacePop:UITaRacePop()
	self._raceList = {}
	self._receRedList = {}
	self._rotateKey = "rotateKey"
	self._playKey = "playKey"
	self._refId = 0
	self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaRacePop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaRacePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaRacePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	--gModelBackflow:SetPrivileBtn(self.mBtnPrivile,7,self)

	-- local priviCom = self:GetPrivilegeCom()
	-- priviCom:Create(self.mBtnPrivile,7,self)
end

function UITaRacePop:InitMessage()
	self:WndEventRecv(EventNames.BATTLE_BACK_END,function () self:RefreshRaceTower() end)
	self:WndNetMsgRecv(LProtoIds.TowerInfoListResp,function (...)
		self:RefreshRaceTower()
		self:OnClickRace(self._refId)
	end)
end

function UITaRacePop:SetSpine(paintTans,key,name,scale)--设置Spine
	local spine = self:FindWndSpineByKey(key)
	if(spine)then
		self:DestroyWndSpineByKey(key)
	end
	self:CreateWndSpine(paintTans,name,key,false,function(dpSpine)
		dpSpine:SetScale(scale)
	end)
end

function UITaRacePop:RefreshData()
	local _refId = self._refId
	local info = gModelTower:GetTowerInfoByTowerType(_refId)
	local floor = info and info.floor + 1 or 1
	local ref = gModelTower:GetTowerPatternRefByRefId(_refId)
	local openDayStr = ""
	if ref.refId == ModelTower.RACE_COM then
		openDayStr = ccClientText(12152)
	else
		openDayStr = string.replace(ccClientText(12150),gModelTower:GetOpenDayStr(ref.openDay))
	end
	local layerStr = string.replace(ccClientText(12151),floor)
	local list = gModelTower:GetTowerLayerDataList(_refId)
	local len = #list
	if info.floor >= len then
		layerStr = ccClientText(12161)
	end
	self:SetWndText(self.mLayerText,layerStr)
	self:SetWndText(self.mOpenText,openDayStr)
	self:SetWndText(self.mDesText,ccLngText(ref.description))
	self:SetWndEasyImage(self.mTowerIcon,ref.bg)
	self:SetWndEasyImage(self.mRaceImg,ref.nameIcon,nil,true)

	local isOpent = gModelTower:GetIsOpentByTowerType(_refId)
	local isShow = isOpent and info.maxChallengesNum ~= -1
	CS.ShowObject(self.mChallengeText,isShow)
	if isShow then
		local num = info.maxChallengesNum - info.battleNum
		local color = "green"
		if num <= 0 then
			num = 0
			color = "red"
		end
		local numStr = LUtil.FormatColorStr(num,color)
		self:SetWndText(self.mChallengeText,string.replace(ccClientText(12149),numStr))
	end
end

function UITaRacePop:InitEvent()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	--self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end)
	self:SetWndClick(self.mGoToBtn, function(...) self:OnClickGoTo() end)
	self:SetWndClick(self.mTipsBtnObj, function(...) self:OnClickTips() end)
end

function UITaRacePop:SetReceInfo(trans,ref)
	local icon = CS.FindTrans(trans,"Icon")
	local numText = CS.FindTrans(trans,"NumBg/NumText")
	local openText = CS.FindTrans(trans,"OpenText")
	local mask = CS.FindTrans(trans,"Mask")
	local maskImg = CS.FindTrans(trans,"Mask/Image")
	local maskText = CS.FindTrans(trans,"Mask/Image/MaskText")
	local eff = CS.FindTrans(trans,"Eff")
	local spine = CS.FindTrans(trans,"Spine")
	local info = gModelTower:GetTowerInfoByTowerType(ref.refId)
	CS.ShowObject(eff,false)
	if not info then
		gModelTower:OnTowerInfoListReq(true)
		return
	end
	local isOpent = gModelTower:GetIsOpentByTowerType(ref.refId)
	local ref = gModelTower:GetTowerPatternRefByRefId(ref.refId)
	local isFight= gLFightManager:IsCombatTypeInFight(ref.combatTyep)
	local InstanceID = trans:GetInstanceID()
	local bool = false
	CS.ShowObject(numText,not bool)
	CS.ShowObject(openText,not bool)
	CS.ShowObject(mask,not isOpent or isFight)
	CS.ShowObject(spine,isFight)
	CS.ShowObject(maskImg,not isFight)
	self:SetWndText(maskText,ccClientText(12163))
	self:InitTextSizeWithLanguage(maskText,-4)
	self:SetWndEasyImage(icon,ref.icon)
	if isFight then
		self:SetSpine(spine,InstanceID,"jian",1)
	end
	local openDayStr = ""
	if ref.refId == ModelTower.RACE_COM then
		openDayStr = ccClientText(12152)
	else
		openDayStr = gModelTower:GetOpenDayStr(ref.openDay)
	end
	local numStr
	if info.floor < ref.floor then
		numStr = info.floor + 1
	else
		numStr = info.floor
	end
	if isOpent then
		numStr = LUtil.FormatColorStr(numStr,"yellow_2")
		openDayStr = LUtil.FormatColorStr(openDayStr,"yellow_2")
		if info.maxChallengesNum > 0 then
			--CS.ShowObject(eff,true)
			self:CreateWndEffect(trans,"fx_slzt_xuanze","fx_slzt_xuanze"..ref.refId,100,false,false)
		end
		if info.maxChallengesNum - info.battleNum > 0 then
			CS.ShowObject(eff,true)
			self._raceEffList[ref.refId] = eff
			self:CreateWndEffect(eff,"fx_slzt_weixuanzhong","fx_slzt_weixuanzhong"..ref.refId,100,false,false)
		end
	end

	self:SetWndText(openText,openDayStr)
	self:InitTextLineWithLanguage(openText, -30)
	self:SetWndText(numText,numStr)
	self:SetWndClick(trans,function ()
		self:OnClickRace(ref.refId)
	end)
end

function UITaRacePop:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(12100))
	CS.ShowObject(self.mTitleText,true)
	self:SetWndButtonText(self.mGoToBtn,ccClientText(12158))
	for i = 1, 5 do
		local race = CS.FindTrans(self.mRaceMag,"Race"..i)
		table.insert(self._raceList,race)
		local red = CS.FindTrans(self.mRaceRedMag,"Race"..i)
		table.insert(self._receRedList,red)
	end
	self:RefreshRaceTower()
	local towerRace = tonumber(LPlayerPrefs.towerRace)
	if towerRace == ModelTower.RACE_TYPE_99 then
		towerRace = ModelTower.RACE_COM
	end
	local isOpent = gModelTower:GetIsOpentByTowerType(towerRace)
	if not isOpent then
		towerRace = ModelTower.RACE_COM
	end
	self:OnClickRace(towerRace,true)
	self:CreateWndEffect(self.mRaceOnEff,"fx_slzt_zhongzukuang","fx_slzt_zhongzukuang",100)
	self:PlayYuanAni()
end

function UITaRacePop:PlayYuanAni()
	local seqTween
	self:TweenSeqKill(self._playKey)
	if not seqTween then
		local showTime = 18
		seqTween = self:TweenSeqCreate(self._playKey,function(seq)
			local moveZ = self.mYuanImg.transform:DORotate(Vector3.New(0,0,180),showTime)
			seq:Append(moveZ)
			return seq
		end)
	end
	seqTween:SetLoops(-1,DG.Tweening.LoopType.Restart)
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._playKey)
	end)
	seqTween:PlayForward()
end

function UITaRacePop:OnClickGoTower(_refId)
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

function UITaRacePop:PlayRotateAni(rotateZ,isOne)
	local seqTween
	self:TweenSeqKill(self._rotateKey)
	if not seqTween then
		local showTime = isOne and 0 or 0.2
		local _oldrotateZ = self._oldrotateZ
		if _oldrotateZ then
			local isRate = math.abs(_oldrotateZ - rotateZ ) > 72
			if isRate and (_oldrotateZ == 0 or rotateZ == 0)then
				local newRoteZ = rotateZ
				if _oldrotateZ == 0 then
					_oldrotateZ = 360
				elseif newRoteZ == 0 then
					newRoteZ = 360
				end
				isRate = math.abs(_oldrotateZ - newRoteZ ) > 72
			end
			if isRate then
				showTime = showTime * 2
			end
		end
		self._oldrotateZ = rotateZ

		seqTween = self:TweenSeqCreate(self._rotateKey,function(seq)
			local moveZ = self.mRaceMag.transform:DORotate(Vector3.New(0,0,rotateZ),showTime)
			seq:Append(moveZ)
			local redRotate = self.mRaceRedMag.transform:DORotate(Vector3.New(0,0,rotateZ),showTime)
			seq:Join(redRotate)
			for i, v in ipairs(self._raceList) do
				local raceZ = v.transform:DOLocalRotate(Vector3.New(0,0,-rotateZ),showTime)
				seq:Join(raceZ)
			end
			for i, v in ipairs(self._receRedList) do
				local raceZ = v.transform:DOLocalRotate(Vector3.New(0,0,-rotateZ),showTime)
				seq:Join(raceZ)
			end
			return seq
		end)
	end
	--seqTween:SetLoops(-1,DG.Tweening.LoopType.Restart)
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._rotateKey)
		if not isOne then
			self:CreateWndEffect(self.mRaceOnEff,"fx_slzt_xuanze","fx_slzt_xuanze",100)
		end
	end)

	seqTween:PlayForward()
end

function UITaRacePop:RefreshRaceTower()
	self._raceEffList = {}
	local refList = gModelTower:GetTowerPatternRef()
	for i, v in ipairs(self._raceList) do
		self:SetReceInfo(v,refList[i])
	end
end

function UITaRacePop:OnClickRace(refId,isOne)
	if self._refId >0 then
		--if self._refId == refId then
		--	return
		--end
		local trans = self._raceList[self._refId]
		self:ChangeRace(trans,false,self._refId)
	end
	local trans = self._raceList[refId]
	self:ChangeRace(trans,trans,refId,isOne)
	local _raceEffList = self._raceEffList
	for i, v in pairs(_raceEffList) do
		CS.ShowObject(v,true)
	end
	local eff = _raceEffList[refId]
	if eff then
		CS.ShowObject(eff,false)
	end
end

function UITaRacePop:ChangeRace(trans,bool,refId,isOne)
	local onImg = CS.FindTrans(trans,"OnImg")
	local mask = CS.FindTrans(trans,"Mask")
	local numBg = CS.FindTrans(trans,"NumBg")
	local openText = CS.FindTrans(trans,"OpenText")
	local spine = CS.FindTrans(trans,"Spine")
	local isOpent = gModelTower:GetIsOpentByTowerType(refId)
	local ref = gModelTower:GetTowerPatternRefByRefId(refId)
	local isFight= gLFightManager:IsCombatTypeInFight(ref.combatTyep)
	CS.ShowObject(onImg,bool)
	CS.ShowObject(mask,(not isOpent) or isFight)
	CS.ShowObject(numBg,not bool)
	CS.ShowObject(openText,not bool)
	CS.ShowObject(spine,isFight)
	if not bool then
		return
	end
	self._refId = refId

	self:PlayRotateAni(360/5 * (refId - 1),isOne)
	self:RefreshData()
end

function UITaRacePop:OnClickTips()
	local value1 = gModelTower:GetTowerConfigRefByKey("freeTimes")
	local value2 = gModelTower:GetTowerConfigRefByKey("quickChallenge")
	GF.OpenWnd("UIBzTips",{refId=5,para={value1,value2}})
end

function UITaRacePop:OnClickGoTo()
	local _refId = self._refId
	if _refId == ModelTower.RACE_COM then
		local towerDifficulty = LPlayerPrefs.towerDifficulty
		if towerDifficulty == "true" then
			_refId = ModelTower.RACE_TYPE_99
		end
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
------------------------------------------------------------------
return UITaRacePop


