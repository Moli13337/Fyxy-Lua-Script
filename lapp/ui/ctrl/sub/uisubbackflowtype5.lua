---
--- Created by BY.
--- DateTime: 2023/10/15 11:27:00
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubBackflowType5:LChildWnd
local UISubBackflowType5 = LxWndClass("UISubBackflowType5", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubBackflowType5:UISubBackflowType5()
	self._timeKey = "_timeKey"
	self._timeMonsterKey = "_timeMonsterKey"
	--self._statusList = {}
	self._uiEasyList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubBackflowType5:OnWndClose()
	self:ClearCommonIconList(self._uiEasyList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubBackflowType5:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubBackflowType5:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISubBackflowType5:InitCommand()
	self:SetWndText(self.mAwardText,ccClientText(23507))
	local refId = self:GetWndArg("refId")
	local ref = gModelBackflow:RegressionBackflowRefByRefId(refId)
	self._ref = ref

	CS.ShowObject(self.mBtnHelp,ref.helpId > 0)
	local showIcon,showIconPos,showTitle,showTitlePos = ref.showIcon,ref.showIconPos,ref.showTitle,ref.showTitlePos
	if LxUiHelper.IsImgPathValid(showIcon) then
		CS.ShowObject(self.mIconImg,true)
		self:SetWndEasyImage(self.mIconImg,showIcon,nil,true)
		local showIconPosArr = string.split(showIconPos,"|")
		self.mIconImg.anchoredPosition = Vector2(tonumber(showIconPosArr[1]),tonumber(showIconPosArr[2]))
	end
	if LxUiHelper.IsImgPathValid(showTitle) then
		CS.ShowObject(self.mTextImg,true)
		self:SetWndEasyImage(self.mTextImg,showTitle,nil,true)
		local showTitlePosArr = string.split(showTitlePos,"|")
		self.mTextImg.anchoredPosition = Vector2(tonumber(showTitlePosArr[1]),tonumber(showTitlePosArr[2]))
	end

	local time = gModelBackflow:GetResidueTime()
	CS.ShowObject(self.mTimeText,time > 0)
	if(time > 0)then
		self:SetTime()
		self:TimerStop(self._timeKey)
		self:TimerStart(self._timeKey,1,false,-1)
	end
	gModelBackflow:RegressionMonsterReq()
end
function UISubBackflowType5:InitMessage()
	self:WndNetMsgRecv(LProtoIds.RegressionMonsterResp,function (pb)
		self:RefreshData()
	end)
end

function UISubBackflowType5:SetSpine(ref,spineName)
	--local paintFlip=ref.paintFlip2==1
	local heroSize = ref.heroSize
	local heroPos = string.split(ref.heroPos,"|")
	local _oldKey = self._oldKey
	if _oldKey then
		if _oldKey == spineName then
			return
		else
			self:DestroyWndSpineByKey(_oldKey)
		end
	end
	self:CreateWndSpine(self.mHeroRoot,spineName,spineName,false,function(dpSpine)
		dpSpine:SetScale(heroSize)
		--dpSpine:SetFlipX(paintFlip)
		local dpTrans =dpSpine:GetDisplayTrans()
		dpTrans.anchorMin = Vector2.New(0.5,0.5)
		dpTrans.anchorMax = Vector2.New(0.5,0.5)
		self._oldKey = spineName
	end)
	self.mHeroRoot.localPosition = Vector2.New(tonumber(heroPos[1]),tonumber(heroPos[2]))
end
function UISubBackflowType5:OnClickHero(refId)
	--local _statusList = self._statusList
	--for i, v in pairs(_statusList) do
	--	CS.ShowObject(v,false)
	--end
	--CS.ShowObject(_statusList[refId],true)
	self._heroRefId = refId
	if self._uiHeroSuper then
		self._uiHeroSuper:DrawAllItems()
	end
	self:RefreshHeroData()
end
function UISubBackflowType5:SetChallengeTime()--设置时间
	local time = self._endTime
	if(time <= 0)then
		self:TimerStop(self._timeMonsterKey)
		CS.ShowObject(self.mChallengeTimeText,false)
		return
	end
	local timeStr = LUtil.FormatTimespanCn(time)
	self:SetWndText(self.mChallengeTimeText,string.replace(ccClientText(23500),timeStr))
end
------------------------------------------------time--------------------------------------------------------------------
function UISubBackflowType5:OnTimer(key)
	if(self._timeKey == key)then
		self:SetTime()
	elseif(self._timeMonsterKey == key)then
		self:SetChallengeTime()
	end
end

function UISubBackflowType5:RefreshData()
	local monsters,endTime = gModelBackflow:GetMonsterInfo()
	self._endTime = endTime
	local list = {}
	local curIndex = 999
	for i, v in ipairs(monsters) do
		if v.kill == 0 and i < curIndex then
			curIndex = i
		end
		table.insert(list,v)
	end
	if #list <= 0 then
		LogError("今天没有英雄可挑战，请检查配置RegressionMonsterResp")
		return
	end
	local _uiHeroSuper = self._uiHeroSuper
	if _uiHeroSuper then
		_uiHeroSuper:RefreshList(list)
	else
		_uiHeroSuper = self:GetUIScroll("mHeroSuper")
		_uiHeroSuper:Create(self.mHeroSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
		_uiHeroSuper:EnableScroll(true,false)
		self._uiHeroSuper = _uiHeroSuper
	end
	_uiHeroSuper:DrawAllItems()
	if not self._heroRefId then
		if curIndex > #list then
			curIndex = 1
		end
		self:OnClickHero(list[curIndex].refId)
	end
end

function UISubBackflowType5:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = self._ref.helpId})
end

function UISubBackflowType5:RefreshHeroData()
	local refId = self._heroRefId
	if not refId then
		return
	end
	local ref = gModelBackflow:RegressionChallengeRefByRefId(refId)
	if ref.showHero <= 0 then
		return
	end
	local monsters,endTime = gModelBackflow:GetMonsterInfo()
	local heroEffectRef = gModelHero:GetShowEffectById(ref.showHero)
	self:SetSpine(ref,heroEffectRef.heroDrawing)

	local power = LUtil.FormatPowerShowStr(tonumber(ref.combat)) --LUtil.FormatCoversionHurtNumSpriteText(tonumber(ref.combat),false,nil,16)
	self:SetWndText(self.mPowerText,power)
	CS.ShowObject(self.mHeroBg,true)
	self:SetWndEasyImage(self.mHeroBg,ref.bg)
	CS.ShowObject(self.mDesBg,true)
	self:SetWndText(self.mDesText,ccLngText(ref.desc))
	local itemList = LxDataHelper.ParseItem(ref.reward)
	self:InitItemList("heroAward",self.mAwardRoot,itemList)

	local isKill = false
	for i, v in ipairs(monsters) do
		if v.refId == refId then
			isKill = v.kill == 1
		end
	end

	self:SetWndButtonGray(self.mBtnChallenge,isKill)
	self:SetWndButtonText(self.mBtnChallenge,not isKill and ccClientText(23508) or ccClientText(23514))

	self:TimerStop(self._timeMonsterKey)
	CS.ShowObject(self.mChallengeTimeText,not isKill)
	if not isKill then
		self:SetChallengeTime()
		self:TimerStart(self._timeMonsterKey,1,false,-1)
	end
end

function UISubBackflowType5:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local heroIcon = self:FindWndTrans(root,"HeroIcon")
	local status_Sel = self:FindWndTrans(root,"Status_Sel")
	local mask = self:FindWndTrans(root,"Mask")

	local kill = itemdata.kill
	local refId = itemdata.refId
	local _heroRefId = self._heroRefId
	CS.ShowObject(mask,kill > 0)
	CS.ShowObject(status_Sel,_heroRefId == refId)
	local ref = gModelBackflow:RegressionChallengeRefByRefId(refId)
	local heroEffectRef = gModelHero:GetShowEffectById(ref.showHero)

	self:SetWndEasyImage(heroIcon,heroEffectRef.icon)
	self:SetWndClick(root,function ()
		self:OnClickHero(refId)
	end)
end

function UISubBackflowType5:InitItemList(key,awardRoot,itemList)
	local uiIconEasyList = self._uiEasyList[key]
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiEasyList[key] = uiIconEasyList
		uiIconEasyList:Create(self, awardRoot)
		--uiIconEasyList:SetIconParentPath("itemRoot")
	end
	uiIconEasyList:RefreshList(itemList)
end

function UISubBackflowType5:InitEvent()
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end)
	self:SetWndClick(self.mBtnChallenge,function (...) self:OnClickChallenge() end)
end
function UISubBackflowType5:OnClickChallenge()
	local refId = self._heroRefId
	if not refId then
		return
	end
	local monsters,endTime = gModelBackflow:GetMonsterInfo()
	for i, v in ipairs(monsters) do
		if v.refId == refId and v.kill == 1 then
			GF.ShowMessage(ccClientText(23514))
			return
		end
	end
	local ref = gModelBackflow:RegressionChallengeRefByRefId(refId)

	local combatType = LCombatTypeConst.COMBAT_TYPE_23
	local extraData = {
		monster = ref.monster,
		reliefTroopId = ref.ReliefTroopId,
		method = ccLngText(ref.Introduction),
		dungeonId = refId
	}
	gLFightManager:PrepareGoToBattle(combatType,extraData)
end
function UISubBackflowType5:SetTime()--设置时间
	local time = gModelBackflow:GetResidueTime()
	if(time <= 0)then
		self:TimerStop(self._timeKey)
		CS.ShowObject(self.mTimeText,false)
		return
	end
	local timeStr = LUtil.FormatTimespanCn(time)
	self:SetWndText(self.mTimeText,string.replace(ccClientText(23500),timeStr))
end
------------------------------------------------------------------
return UISubBackflowType5

