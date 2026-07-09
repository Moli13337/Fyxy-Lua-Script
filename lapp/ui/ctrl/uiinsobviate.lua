---
--- Created by Administrator.
--- DateTime: 2024/7/30 15:23:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInsObviate:LWnd
local UIInsObviate = LxWndClass("UIInsObviate", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInsObviate:UIInsObviate()
	self.timeKey = "SameRemove"
	self.endTime = 0
	self.useTime = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInsObviate:OnWndClose()
	LWnd.OnWndClose(self)
	self:TimerStop(self.timeKey)
	if self._showTween then self._showTween:Kill() end
	if self.loveInfo then gModelHeroExtra:OnHeroGiveGiftResp(self.loveInfo) end
	-- gModelHeroExtra:OnHeroInteractQuestReq()--互动任务信息
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInsObviate:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInsObviate:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mTxtDesc,ccClientText(41660))
	self._heroEffectRef = self:GetWndArg("heroEffectRef")
	local eventId = self:GetWndArg("eventId")
	self.eventRef = GameTable.GardenEventRef[eventId]
	self:SetWndText(self.mTxtName,ccLngText(self.eventRef.name))
	self:SetWndButtonText(self.mBtnComfirm,ccClientText(32807))
	if self._heroEffectRef then
		local spineName = self._heroEffectRef.heroDrawing
		self:CreateWndSpine(self.mRoleRoot,spineName,"anwserSpine",nil,function(spine)
			spine:PlayAnimationSolid("idle",true)
		end)
	end
	self:OnAddEevetMsg()
	self:OnUpatePanel()
end

function UIInsObviate:CreateCardList()
	CS.ShowObject(self.mListHeahCard,true)
	self.score = 0
	local headRef = GameTable.SnakeRolePlayerHeadRef
	local headList = {}
	local listLeng = 0
	local curTime = GetTimestamp()
	local headType = ModelPlayerSpace.ROLE_HEAD
	local activationType,activationHero
	for _, value in pairs(headRef) do
		if value.type == headType and not string.isempty(value.activation) then
			if gModelPlayer:CheckRolePlayerHeadIsOpen(value.activation,curTime) then
				table.insert(headList,value.refId)
				listLeng = listLeng + 1
			end
		end
	end
	local list = {}
	local indexMap  = {}
	local lenght = 0
	local last = nil
	local count = 0
	while listLeng>0 and lenght<16 and count < 3000 do
		local index = nil
		if not last then
			index = math.random(1,listLeng)
		else
			index = math.random(listLeng+1,listLeng+10000)
		end
		if not indexMap[index] then
			indexMap[index] = index
			lenght = lenght+1
			if last then
				list[index] = last
				last = nil
			else
				list[index] = headList[index]
				last = headList[index]
			end
		end
		count = count+1
	end
	headList = {}
	listLeng = 0
	for _, value in pairs(list) do
		table.insert(headList,value)
		listLeng = listLeng+1
	end
	self.headListLeng = listLeng

	if self.rwdList then
		local uiList = self.rwdList:GetList()
		uiList:RemoveAll()
		self.rwdList:RefreshList(headList)
	else
		local uilist = self:CreateUIScrollImpl("CardScroll",self.mListHeahCard,headList,function (...)
			self:OnDrawCardItem(...)
		end)
		self.rwdList = uilist
	end

end
function UIInsObviate:OnDrawRewardItem(list, item, itemData, index)
	local CommonUIIcon = self:FindWndTrans(item,"CommonUI/Icon")
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(CommonUIIcon)

	baseClass:SetCommonReward(itemData.itemType, itemData.itemId, itemData.itemNum)
	baseClass:DoApply()
	self:SetWndClick(CommonUIIcon,function()
        gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)
end

function UIInsObviate:OnResult()
	self:TimerStop(self.timeKey)
	if self._showTween then
		self._showTween:Kill()
		self.doTweening = false
	end
	self.isStart = false
	CS.ShowObject(self.mBtnComfirm,true)
	CS.ShowObject(self.mImgResult,true)
	CS.ShowObject(self.mTitleText,self.isWin)
	CS.ShowObject(self.mImgResult,not self.isWin)
	CS.ShowObject(self.mImgResultWin, self.isWin)
	self:SetWndButtonText(self.mBtnComfirm,self.isWin and ccClientText(42044) or ccClientText(41661))
	self:SetWndText(self.mTxtTime,ccClientText(41663))
	self:SetTextTile(self.mTitleText,ccClientText(41655))
	local pos = self.mImgResult.anchoredPosition
	pos.y = self.isWin and 120 or 45
	self.mImgResult.anchoredPosition = pos
	local effKey = self.isWin and "fx_ui_garden_wancheng" or "fx_ui_garden_shibai"
	local effTran = self.isWin and self.mImgResultWin or self.mImgResult
	self:CreateEffect(effTran,effKey)
	if self.isWin then
		CS.ShowObject(self.mTxtTimeTitle,true)
		CS.ShowObject(self.mListHeahCard,false)
		self:SetWndText(self.mTxtTimeTitle,ccClientText(41664))
		local timeStr = LUtil.FormatTimeToCn3(self.useTime)
		self:SetWndText(self.mTxtTime,timeStr)
		self:SetTimePos(0,31)
		self:CreateRwdList()
	end
end

function UIInsObviate:OnUpatePanel()
	self:SetTimePos(-241,201)
	CS.ShowObject(self.mTitleText,false)
	CS.ShowObject(self.mTxtTimeTitle,false)
	CS.ShowObject(self.mImgResult,false)
	CS.ShowObject(self.mBtnComfirm,not self.isStart)
	self:SetWndText(self.mTxtTime,ccClientText(41662))
	if self.isStart then
		self.endTime = GetTimestamp() + GameTable.GardenConfigRef.gardenRightTouchTimeMax
		self:TimerStart(self.timeKey, 1, false, -1)
		self:SetTimeTxt()
	else
		self:CreateCardList()
	end

end
function UIInsObviate:OnTimer(key)
	if key == self.timeKey then
		self:SetTimeTxt()
	end
end

function UIInsObviate:SetTimeTxt()
	local nowTime = GetTimestamp()
	local timeDif = os.difftime(self.endTime, nowTime)
	if timeDif <= 0 then
		self.isWin = false
		self:OnResult()
		return
	end
	local timeStr = LUtil.FormatTimeToCn3(timeDif)
	self:SetWndText(self.mTxtTime,timeStr)
end

function UIInsObviate:OnPlayToWeen(commonIcon,effTran,itemdata,start,rotation,endFunc)
	self.doTweening = true
	local tweenSeq = YXTween.TweenSequenceIns()
	local moveFunc = function(value)
		local euler = Quaternion.Euler(0,value,0)
		commonIcon.transform.localRotation = euler
	end

	local moveTween = YXTween.TweenFloat(start, rotation, 0.3, moveFunc):SetEase(DG.Tweening.Ease.Linear)
    tweenSeq:Append(moveTween)
    tweenSeq:AppendCallback(function()
		local headRef = GameTable.SnakeRolePlayerHeadRef[itemdata]
		self:SetWndEasyImage(commonIcon,headRef.icon)
		commonIcon.sizeDelta = Vector2.New(85, 85)
    end)
	local moveTween = YXTween.TweenFloat(rotation, start, 0.3, moveFunc):SetEase(DG.Tweening.Ease.Linear)
    tweenSeq:Append(moveTween)
	if self.selData then
		if itemdata == self.selData then
			tweenSeq:AppendInterval(0.4)
			tweenSeq:AppendCallback(function()
				local effName = "fx_ui_garden_kapaifanzhuan"
				local eff = self:FindWndEffectByKey("fx_ui_garden_kapaifanzhuan1")
				if eff then
					local dpTrans = eff:GetDisplayTrans()
					eff:SetVisible(false)
					dpTrans:SetParent(effTran,false)
					eff:SetVisible(true)
				else
					self:CreateEffect(effTran,effName,"fx_ui_garden_kapaifanzhuan1",nil)
				end
				local eff = self:FindWndEffectByKey("fx_ui_garden_kapaifanzhuan2")
				if eff then
					local dpTrans = eff:GetDisplayTrans()
					eff:SetVisible(false)
					dpTrans:SetParent(self.effTran,false)
					eff:SetVisible(true)
				else
					self:CreateEffect(self.effTran,effName,"fx_ui_garden_kapaifanzhuan2",nil)
				end
			end)
			tweenSeq:AppendInterval(0.2)
			tweenSeq:AppendCallback(function()
				local effName = "fx_ui_garden_kapaixiaochu"
				local eff = self:FindWndEffectByKey("fx_ui_garden_kapaixiaochu1")
				if eff then
					local dpTrans = eff:GetDisplayTrans()
					eff:SetVisible(false)
					dpTrans:SetParent(effTran,false)
					eff:SetVisible(true)
				else
					self:CreateEffect(effTran,effName,"fx_ui_garden_kapaixiaochu1",nil)
				end
				local eff = self:FindWndEffectByKey("fx_ui_garden_kapaixiaochu2")
				if eff then
					local dpTrans = eff:GetDisplayTrans()
					eff:SetVisible(false)
					dpTrans:SetParent(self.effTran,false)
					eff:SetVisible(true)
				else
					self:CreateEffect(self.effTran,effName,"fx_ui_garden_kapaixiaochu2",nil)
				end
				LxUiHelper.PlayAudioSoundName(LSoundConst.INTERACT_OBVIATE_RIGHT)
			end)
			tweenSeq:AppendInterval(0.1)
			tweenSeq:AppendCallback(function()
				CS.ShowObject(commonIcon,false)
				CS.ShowObject(self.selCommonIcon,false)
				commonIcon.sizeDelta = Vector2.New(93, 93)
				self.selCommonIcon.sizeDelta = Vector2.New(93, 93)
				self.score = self.score+1
				if self.score>= self.headListLeng/2 then
					self:TimerStop(self.timeKey)
					self.isWin = true
					self:OnResult()
					self.useTime = GameTable.GardenConfigRef.gardenRightTouchTimeMax - (self.endTime - GetTimestamp())
					gModelHeroExtra:OnHeroInteractGameOpsReq(1,self.useTime<= GameTable.GardenConfigRef.gardenRightTouchTime and 1 or 2,"")
				end
			end)
		else
			tweenSeq:AppendInterval(0.3)
			tweenSeq:AppendCallback(function()
				commonIcon.sizeDelta = Vector2.New(93, 93)
				self.selCommonIcon.sizeDelta = Vector2.New(93, 93)
				self:SetWndEasyImage(commonIcon,"garden_bg_5")
				self:SetWndEasyImage(self.selCommonIcon,"garden_bg_5")
				LxUiHelper.PlayAudioSoundName(LSoundConst.INTERACT_OBVIATE_ERROR)
			end)
		end
	end
	tweenSeq:OnComplete(function()
		tweenSeq:Kill()
		self.doTweening = false
		if endFunc then endFunc() end
	end)
    self._showTween = tweenSeq
    tweenSeq:PlayForward()
end
function UIInsObviate:CreateEffect(trans,effectName,effectKey,effectSize,func,sortLayer)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans,effectName,effectKey,effectSize,false,false,nil,nil,nil,nil,sortLayer,func)
end

function UIInsObviate:SetTimePos(x,y)
	local pos = self.mImgTime.anchoredPosition
	pos.x = x or pos.x
	pos.y = y or pos.y
	self.mImgTime.anchoredPosition = pos
end
function UIInsObviate:OnAddEevetMsg()
	self:SetWndClick(self.mBtnComfirm,function()
		if self.isWin then
			self:WndClose()
			return
		end
		if not self.isStart  then
			self.isStart = true
			self:CreateCardList()
			self:OnUpatePanel()
		end
	end)
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.HeroInteractGameOpsResp,function(pb)
		if pb.rewardInfo then
			local thingsDetail = gModelGeneral:GetThingsDetailInfoByPb(pb.rewardInfo)
			if thingsDetail.rewardNum>0 then
				self:OnResult()
			end
		end
		if pb.gift.addLoveValue>0 then
			self.loveInfo = pb.gift
		end
	end)
end


function UIInsObviate:CreateRwdList()
	if not self.eventRef then return end
	local list = {}
	local reward = self.useTime<= GameTable.GardenConfigRef.gardenRightTouchTime and self.eventRef.reward1 or self.eventRef.reward2
	list = LxDataHelper.ParseItem(reward)
    local list = self:CreateUIScrollImpl("rwdScroll",self.mListRwdScroll,list,function (...)
        self:OnDrawRewardItem(...)
    end)
    self.rwdList = list
end
function UIInsObviate:OnDrawCardItem(list, item, itemData, index)
	local CommonUIIcon = self:FindWndTrans(item,"CommonUI/Icon")
	local EffectTran = self:FindWndTrans(item,"CommonUI/Effect")
	CS.ShowObject(EffectTran,false)
	local euler = Quaternion.Euler(0,0,0)
	CommonUIIcon.transform.localRotation = euler
	self:SetWndEasyImage(CommonUIIcon,"garden_bg_5",function()
		CS.ShowObject(CommonUIIcon,true)
	end)
	self:SetWndClick(CommonUIIcon,function()
		if not self.isStart then
			GF.ShowMessage(ccClientText(41665))
			return
		end
		if self.doTweening or self.selCommonIcon==CommonUIIcon then return end
		CS.ShowObject(EffectTran,true)
		self:OnPlayToWeen(CommonUIIcon,EffectTran,itemData,0,90,function()
			if not self.selData then
				self.selData = itemData
				self.selCommonIcon = CommonUIIcon
				self.effTran = EffectTran
			else
				self.selData = nil
				self.selCommonIcon = nil
				self.effTran = nil
			end
		end)

	end)
end
------------------------------------------------------------------
return UIInsObviate