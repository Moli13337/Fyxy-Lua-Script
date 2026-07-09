---
--- Created by Administrator.
--- DateTime: 2024/6/11 15:05:17
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPeWishLandYell:LChildWnd
local UISubPeWishLandYell = LxWndClass("UISubPeWishLandYell", LChildWnd)
------------------------------------------------------------------


UISubPeWishLandYell.SLIDER_N = 0
UISubPeWishLandYell.SLIDER_H = 1
UISubPeWishLandYell.SLIDER_C = 2
UISubPeWishLandYell.SLIDER_L = 3


UISubPeWishLandYell.TYPE_REWARD_NORMAL = 0
UISubPeWishLandYell.TYPE_REWARD_CANGET = 1
UISubPeWishLandYell.TYPE_REWARD_ALREADY = 2

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPeWishLandYell:UISubPeWishLandYell()
	self._oneTimerKey = "oneTimerKey"
	self._tenTimerKey = "tenTimerKey"

	self._doAniKey = "doAniKey"

	---@type Transform 单次召唤时间
	self._timeTxt1Trans = nil

	---@type Transform 多次召唤时间
	self._timeTxt2Trans = nil

	---@type UIObjPool
	self._rewardPool = nil

	---@type boolean 是否拥有免费
	self._hasFreeNum = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPeWishLandYell:OnWndClose()
	if self._rewardPool then
		self._rewardPool:DestroyAllObj()
		self._rewardPool = nil
	end
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPeWishLandYell:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPeWishLandYell:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	---@type UIObjPool
	local pool = UIObjPool:New()
	pool:Create(self.mRewardRoot,self.mRewardTemplate)
	self._rewardPool = pool



	self.jpj = gLGameLanguage:IsJapanVersion()
	if self.jpj then
		self:SetAnchorPos(self.mJumpAniBtn,Vector2.New(220,140))
	end
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:OnWndRefresh()
end

function UISubPeWishLandYell:CreateTimer(key,time,loopCnt)
	time = time or 1
	loopCnt = loopCnt or -1
	self:TimerStop(key)
	self:TimerStart(key,time,false,loopCnt)
end




function UISubPeWishLandYell:GetLuckList()
	local list = {}
	local refs = gModelPetDreanLand:GetPetDreamlandLuckyRefByLottery(self._lotteryType)
	if refs and #refs > 0 then
		for i,v in ipairs(refs) do
			local sliderType = UISubPeWishLandYell.SLIDER_N
			table.insert(list,{
				refId = v.refId,
				type = v.type,
				grad = v.grad,
				gradReward = v.gradReward,
				beforeGrad = v.beforeGrad,
				sliderType = sliderType,
			})
		end
	end
	return list
end

function UISubPeWishLandYell:GetPayTransInfo(trans)
	local key = trans:GetInstanceID()
	if not self._payTransInfos then
		self._payTransInfos = {}
	end
	local payTransInfo = self._payTransInfos[key]
	if not payTransInfo then
		local PayDiv = self:FindWndTrans(trans,"PayDiv")
		payTransInfo = {
			effRootTrans = self:FindWndTrans(trans,"EffRoot"),
			btnNameTrans = self:FindWndTrans(trans,"BtnName"),
			timeTxtTrans = self:FindWndTrans(trans,"TimeTxt"),
			payDivTrans = PayDiv,
			iconImgTrans = self:FindWndTrans(PayDiv,"IconImg"),
			numTxtTrans = self:FindWndTrans(PayDiv,"NumTxt"),
			freeTxtTrans = self:FindWndTrans(trans,"FreeTxt"),
			redPointTrans = self:FindWndTrans(trans,"redPoint"),
		}
		self._payTransInfos[key] = payTransInfo
	end
	return payTransInfo
end

function UISubPeWishLandYell:OnPetDreamLandLotterytResp(pb)
	local func = function()
		gModelPetDreanLand:CommonDisposeRewardCall(pb)
		self:RefreshView()
	end

	local soundId = self._lotteryType == ModelPetDreanLand.TYPE_LOTTERY_0 and 38 or 37
	local audioName = LxResPathUtil.GetAudioSoundName(nil, soundId)
	if audioName then
		gLGameAudio:PlaySound(audioName)
	end

	if gModelPetDreanLand:GetDreamLandCallJumpAniState() then
		func()
	else
		self:DoLotterytAni(func)
	end
end

function UISubPeWishLandYell:InitShow()
	CS.ShowObject(self.mEffRoot,false)

	local lotteryType = self._lotteryType
	local spineName,effName
	if lotteryType == ModelPetDreanLand.TYPE_LOTTERY_0 then
		spineName = "fx_ui_yindanzhaohuan"
		effName = "fx_ui_yindanzhaohuan_eff"
	elseif lotteryType == ModelPetDreanLand.TYPE_LOTTERY_1 then
		spineName = "fx_ui_jindanzhaohuan"
		effName = "fx_ui_jindanzhaohuan_eff"
	end

	if self._recordEffRes and self._recordEffRes ~= effName then
		self:DestroyWndEffectByKey(self._recordEffRes)
	end
	self:CreateWndEffect(self.mEffRoot,effName,effName,100,false,false)
	self._recordEffRes = effName

	if self._recordSpineRes and self._recordSpineRes ~= spineName then
		self:DestroyWndSpineByKey(self._recordSpineRes)
	end
	self._spine = self:CreateWndSpine(self.mSpineRoot,spineName,spineName,false)
	self._recordSpineRes = spineName
end

function UISubPeWishLandYell:OnEventXXXXX()
end

function UISubPeWishLandYell:OnTimer(key)
	if key == self._oneTimerKey then
		self:SetCountDownTime(self._timeTxt1Trans)
	end
end



function UISubPeWishLandYell:IsLuckState(itemdata)
	---@type StructPetDreamLandLotteryData
	local lotteryData = gModelPetDreanLand:GetTypeLotteryInfo(self._lotteryType)
	if not lotteryData then
		return UISubPeWishLandYell.TYPE_REWARD_NORMAL
	end

	local refId = itemdata.refId
	if lotteryData:IsGetRewardId(refId) then
		return UISubPeWishLandYell.TYPE_REWARD_ALREADY
	end

	local grad = itemdata.grad
	local curGrad = lotteryData:GetCurGrad()
	if curGrad >= grad then
		return UISubPeWishLandYell.TYPE_REWARD_CANGET
	end
	return UISubPeWishLandYell.TYPE_REWARD_NORMAL
end

function UISubPeWishLandYell:RefreshPayTimer()
	self:CreateTimer(self._oneTimerKey)
end

function UISubPeWishLandYell:OnItemChange()
	self:RefreshView()
end

function UISubPeWishLandYell:OnDrawLuckCell(list, item, itemdata, itempos)
	local Root = self:FindWndTrans(item,"Root")
	local CommonUI = self:FindWndTrans(Root,"CommonUI")
	local Icon = self:FindWndTrans(CommonUI,"Icon")
	local AlreadyRec = self:FindWndTrans(CommonUI,"AlreadyRec")
	local CanGet = self:FindWndTrans(CommonUI,"CanGet")

	local NumTxt = self:FindWndTrans(Root,"NumTxt")

	local HSlider = self:FindWndTrans(item,"HSlider")
	local CSlider = self:FindWndTrans(item,"CSlider")
	local LSlider = self:FindWndTrans(item,"LSlider")

	local gradReward = itemdata.gradReward
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(gradReward.itemType, gradReward.itemId, gradReward.itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()
	self:SetIconClickScale(Icon, true)

	local grad = itemdata.grad
	self:SetWndText(NumTxt,grad)

	local state = self:IsLuckState(itemdata)
	local showCanGet = state == UISubPeWishLandYell.TYPE_REWARD_CANGET
	CS.ShowObject(AlreadyRec,state == UISubPeWishLandYell.TYPE_REWARD_ALREADY)
	CS.ShowObject(CanGet,showCanGet)

	self:SetWndClick(Icon,function()
		if showCanGet then
			gModelPetDreanLand:OnPetDreamLandLotterytReceiveReq(self._lotteryType)
		else
			gModelGeneral:ShowCommonItemTipWnd(gradReward)
		end
	end)

	local sliderType = itemdata.sliderType
	local showHSlider = sliderType == UISubPeWishLandYell.SLIDER_H
	local showCSlider = sliderType == UISubPeWishLandYell.SLIDER_C
	local showLSlider = sliderType == UISubPeWishLandYell.SLIDER_L

	local sliderTrans = nil
	if showHSlider then
		sliderTrans = HSlider
	elseif showLSlider then
		sliderTrans = LSlider
	else
		sliderTrans = CSlider
	end

	local progress = 0
	---@type StructPetDreamLandLotteryData
	local lotteryData = gModelPetDreanLand:GetTypeLotteryInfo(self._lotteryType)
	if lotteryData then
		local curNum = lotteryData:GetCurGrad()
		if curNum >= grad then
			progress = 1
		else
			local beforeGrad = itemdata.beforeGrad
			local enoughNum = curNum - beforeGrad
			local progressNum = grad - beforeGrad
			progress = enoughNum / progressNum
		end
	end
	LxUiHelper.SetProgress(sliderTrans, progress)


	CS.ShowObject(HSlider,showHSlider)
	CS.ShowObject(CSlider,showCSlider)
	CS.ShowObject(LSlider,showLSlider)


	LxUiHelper.SetSizeWithCurAnchor(item,0,self._itemHorLen)
end

function UISubPeWishLandYell:OnWndRefresh()
	if self._rewardPool then
		self._rewardPool:ReturnAllObj()
	end
	local bgName = self:GetWndArg("BgName")
	if not string.isempty(bgName) then self:SetWndEasyImage(self.mBg,bgName) end
	self:InitData()
	self:InitShow()
	self:RefreshJumpStatus()
	self:RefreshView()
end

function UISubPeWishLandYell:OnDrawNeedAddItemCell(list, item, itemdata, itempos)
	local IconTrans = self:FindWndTrans(item,"IconDiv/Icon")
	local NumTrans = self:FindWndTrans(item,"Num")
	local BtnDivTrans = self:FindWndTrans(item,"BtnDiv")
	local AddBtnTrans = self:FindWndTrans(BtnDivTrans,"AddBtn")

	local itemId = itemdata.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(IconTrans,icon)

	local haveNum = gModelItem:GetNumStrByRefId(itemId)
	self:SetWndText(NumTrans,haveNum)

	---@type V_ItemRef
	local ref = gModelItem:GetRefByRefId(itemId)
	local showBtnDiv = ref and not string.isempty(ref.jump)
	CS.ShowObject(BtnDivTrans,showBtnDiv)

	self:SetWndClick(item,function()
		self:OnClickAddBtnFunc(itemdata)
	end)

	self:SetWndClick(AddBtnTrans,function()
		self:OnClickAddBtnFunc(itemdata)
	end)
end

function UISubPeWishLandYell:DoLotterytAni(func)
	if gModelPetDreanLand:CheckHasRewardUI() then
		if func then func() end
		return
	end
	local showDivList = self._showDivList
	if not showDivList then
		showDivList = {self.mTop,self.mBot,self.mRewardRoot,}
		self._showDivList = showDivList
	end

	for i,v in ipairs(showDivList) do
		CS.ShowObject(v,false)
	end

	CS.ShowObject(self.mShowEffMask,true)
	FireEvent(EventNames.REFRESH_CALL_STATE,{show = false})
	self:TweenSeqKill(self._doAniKey)
	local seqTween = self:TweenSeqCreate(self._doAniKey,function(seq)
		if self._spine then
			self._spine:PlayAnimationSolid("start",false)
		end
		CS.ShowObject(self.mEffRoot,true)
		seq:AppendInterval(2)
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		if self._spine then
			self._spine:PlayAnimationSolid("idle",true)
		end

		CS.ShowObject(self.mEffRoot,false)
		CS.ShowObject(self.mShowEffMask,false)

		for i,v in ipairs(showDivList) do
			CS.ShowObject(v,true)
		end

		FireEvent(EventNames.REFRESH_CALL_STATE,{show = true})
		self:TweenSeqKill(self._doAniKey)
		if func then func() end
	end)
end

function UISubPeWishLandYell:_OpenJackpotRule()
	gModelPetDreanLand:OpenCallJackpotRule(self._lotteryType)
end

function UISubPeWishLandYell:OnRefreshPDLInfo()
	self:RefreshView()
end

function UISubPeWishLandYell:InitData()
	local lotteryType = self:GetWndArg("lotteryType")
	self._lotteryType = lotteryType
	local hasFreeNum = false
	if lotteryType == ModelPetDreanLand.TYPE_LOTTERY_0 then
		local petDreamlandFreeNum = gModelPetDreanLand:GetPetDreamlandConfigRefByKey("petDreamlandFreeNum")
		hasFreeNum = petDreamlandFreeNum and petDreamlandFreeNum > 0 or false
	elseif lotteryType == ModelPetDreanLand.TYPE_LOTTERY_1 then
		local petDreamlandHighFreeNum = gModelPetDreanLand:GetPetDreamlandConfigRefByKey("petDreamlandHighFreeNum")
		hasFreeNum = petDreamlandHighFreeNum and petDreamlandHighFreeNum > 0 or false
	end
	self._hasFreeNum = hasFreeNum
end

function UISubPeWishLandYell:GetNeedAddItemList()
	local list = {}
	local item = gModelPetDreanLand:GetPetDreamlandNeedItemList(self._lotteryType)
	table.insert(list,item)
	return list
end

function UISubPeWishLandYell:RefreshView()
	local num = 0
	local lotteryData = gModelPetDreanLand:GetTypeLotteryInfo(self._lotteryType)
	if lotteryData then
		num = lotteryData:GetCurGrad()
	end
	self:SetWndText(self.mLuckNumTxt,num)

	self:InitNeedAddItemList()
	self:InitLuckList()
	self:RefreshPayInfo()
	self:CreateRewards()
	self:RefreshPayTimer()
end

function UISubPeWishLandYell:InitNeedAddItemList()
	local list = self:GetNeedAddItemList()
	local uiList = self:FindUIScroll("mNeedAddItemList")
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mNeedAddItemList")
		uiList:Create(self.mNeedAddItemList, list, function(...) self:OnDrawNeedAddItemCell(...) end)
	end
end

function UISubPeWishLandYell:OnClickOneCallBtn()
	gModelPetDreanLand:DisposePetDreamLandLotteryReq(self._lotteryType,1)
end

function UISubPeWishLandYell:OnClickBtnDetail()
	self:_OpenJackpotRule()
end

function UISubPeWishLandYell:OnClickTenCallBtn()
	gModelPetDreanLand:DisposePetDreamLandLotteryReq(self._lotteryType,10)
end

function UISubPeWishLandYell:OnClickBtnHelp()
	self:_OpenJackpotRule()
end

function UISubPeWishLandYell:CreateRewards()
	local rewardShows = gModelPetDreanLand:GetPetDreamLandRate(self._lotteryType)
	if not rewardShows or #rewardShows < 1 then return end
	self._rewardPool:ReturnAllObj()
	for i,v in ipairs(rewardShows) do
		local showInfo = v.showInfo
		local showReward = v.showReward
		if showReward and showInfo then
			self:CreateReward(showReward,showInfo)
		end
	end
end

function UISubPeWishLandYell:InitText()
	self:SetTextTile(self.mBtnDetail,ccClientText(43345))
	self:SetTextTile(self.mBtnLucky,ccClientText(41501))
	self:SetWndText(self.mJumpAniBgTxt, ccClientText(14617)) --[14617]	[跳過動畫]
end

function UISubPeWishLandYell:RefreshJumpStatus()
	local state = gModelPetDreanLand:GetDreamLandCallJumpAniState()
	CS.ShowObject(self.mJumpAniBgGou,state)
end

function UISubPeWishLandYell:_SetPayInfo(trans,payInfo,serData)
	local payTransInfo = self:GetPayTransInfo(trans)
	local timeTxtTrans = payTransInfo.timeTxtTrans
	local needCD = serData.needCD
	local hasFreeNum = serData.hasFreeNum
	local showFreeRP = hasFreeNum
	local timeTxtStr = ""
	if showFreeRP then
		timeTxtStr = string.replace(ccClientText(43373),serData.freeLeft)
	else
		local itemId = payInfo.itemId
		local icon = gModelItem:GetItemIconByRefId(itemId)
		local iconImgTrans = payTransInfo.iconImgTrans
		self:SetWndEasyImage(iconImgTrans,icon,function()
			CS.ShowObject(iconImgTrans,true)
		end,true)

		local numStr = LUtil.NumberCoversion(payInfo.itemNum)
		self:SetWndText(payTransInfo.numTxtTrans,numStr)
	end
	self:SetWndText(timeTxtTrans,timeTxtStr)

	self:SetWndText(payTransInfo.btnNameTrans,serData.btnName)

	CS.ShowObject(payTransInfo.payDivTrans,not showFreeRP)
	CS.ShowObject(payTransInfo.redPointTrans,showFreeRP)

	return payTransInfo
end

function UISubPeWishLandYell:OnClickJumpAniBtn()
	local status = gModelPetDreanLand:GetDreamLandCallJumpAniState()
	gModelPetDreanLand:SetDreamLandCallJumpAniState(not status)
	self:RefreshJumpStatus()
end

function UISubPeWishLandYell:OnClickReward(showReward)
	gModelGeneral:ShowCommonItemTipWnd(showReward)
end

function UISubPeWishLandYell:OnClickAddBtnFunc(itemdata)
	gModelGeneral:OpenGetWayWnd({itemId = itemdata.itemId,srcWnd = self:GetWndName()})
end

function UISubPeWishLandYell:InitLuckList()
	local list = self:GetLuckList()

	if not self._uiLuckListWidth then
		self._uiLuckListWidth = self.mLuckList.sizeDelta.x
	end
	local len = #list
	self._itemHorLen = self._uiLuckListWidth / len

	local uiList = self:FindUIScroll("mLuckList")
	if uiList then
		uiList:RefreshList(list)
		uiList:DrawAllItems(false)
	else
		uiList = self:GetUIScroll("mLuckList")
		uiList:Create(self.mLuckList, list, function(...)
			self:OnDrawLuckCell(...)
		end,UIItemList.SUPER)
	end
	uiList:EnableScroll(false)

	local percent = 0
	---@type StructPetDreamLandLotteryData
	local lotteryData = gModelPetDreanLand:GetTypeLotteryInfo(self._lotteryType)
	if lotteryData then
		local curNum = lotteryData:GetCurGrad()
		local dataList = {}
		for i,v in ipairs(list) do
			table.insert(dataList,v.grad)
		end
		percent = LUtil.GetCurPercent(dataList,curNum)
	end
	LxUiHelper.SetProgress(self.mLuckySlider, percent)
	CS.ShowObject(self.mLuckySlider,true)
end

function UISubPeWishLandYell:OnClickBtnLucky()
end

function UISubPeWishLandYell:InitEvent()
	--- 返回按钮必备
	-- self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnHelp,function() self:OnClickBtnHelp() end)
	self:SetWndClick(self.mBtnLucky,function() self:OnClickBtnLucky() end)
	self:SetWndClick(self.mBtnDetail,function() self:OnClickBtnDetail() end)
	self:SetWndClick(self.mOneCallBtn,function() self:OnClickOneCallBtn() end)
	self:SetWndClick(self.mTenCallBtn,function() self:OnClickTenCallBtn() end)
	self:SetWndClick(self.mJumpAniBtn,function() self:OnClickJumpAniBtn() end)
end


function UISubPeWishLandYell:RefreshPayInfo()
	local lotteryType = self._lotteryType

	local lotteryData = gModelPetDreanLand:GetTypeLotteryInfo(lotteryType)
	if not lotteryData then return end

	local oneCallNum = 1
	local payInfo1 = gModelPetDreanLand:GetDreamlandCallByType(lotteryType,oneCallNum)
	local freeNum = lotteryData.freeNum
	local totalFreeNum = lotteryData.totalFreeNum
	local freeLeft = totalFreeNum - freeNum
	local hasFreeNum = freeLeft > 0
	local singleCall = {
		freeLeft = freeLeft,
		hasFreeNum = hasFreeNum,
		needCD = lotteryData.needCD,
		btnName = hasFreeNum and ccClientText(43391) or ccClientText(43346)
	}
	local payTransInfo1 = self:_SetPayInfo(self.mOneCallBtn,payInfo1,singleCall)

	local oneRP = gModelPetDreanLand:CheckLotteryItemTimesEnoughByLotteryType(lotteryType,oneCallNum)
	CS.ShowObject(payTransInfo1.redPointTrans,oneRP)

	self._timeTxt1Trans = payTransInfo1.timeTxtTrans

	local tenCallNum = 10
	local payInfo2 = gModelPetDreanLand:GetDreamlandCallByType(lotteryType,tenCallNum)
	local moreCall = {
		freeLeft = 0,
		hasFreeNum = false,
		needCD = false,
		btnName = ccClientText(43365)
	}
	local payTransInfo2 = self:_SetPayInfo(self.mTenCallBtn,payInfo2,moreCall)

	local tenRP = gModelPetDreanLand:CheckLotteryItemTimesEnoughByLotteryType(lotteryType,tenCallNum)
	CS.ShowObject(payTransInfo2.redPointTrans,tenRP)

	self._timeTxt2Trans = payTransInfo2.timeTxtTrans
end

function UISubPeWishLandYell:SetCountDownTime(timeTxtTrans)
	if not timeTxtTrans then
		self:TimerStop(self._oneTimerKey)
		return
	end

	local lotteryData = gModelPetDreanLand:GetTypeLotteryInfo(self._lotteryType)
	if not lotteryData then
		self:TimerStop(self._oneTimerKey)
		return
	end

	local nextRefreshTimeOfFreeNum = lotteryData.nextRefreshTimeOfFreeNum
	if nextRefreshTimeOfFreeNum < 0 then
		self:TimerStop(self._oneTimerKey)
		return
	end

	local nowTime = GetTimestamp()
	local timeLeft = nextRefreshTimeOfFreeNum - nowTime
	local timeStr = ""
	if timeLeft > 0 and self._hasFreeNum then
		timeStr = string.replace(ccClientText(43374),LUtil.FormatTimespanNumber(timeLeft))
	else
		self:TimerStop(self._oneTimerKey)
	end
	self:SetWndText(timeTxtTrans,timeStr)
end

function UISubPeWishLandYell:OnPetDreamLandLotterytReceiveResp(pb)
	self:InitLuckList()
end

function UISubPeWishLandYell:CreateReward(showReward,showInfo)
	---@type Transform
	local item = self._rewardPool:GetObj()
	if not item then return end

	local QualityBg = self:FindWndTrans(item,"QualityBg")
	local ItemIcon = self:FindWndTrans(item,"ItemIcon")
	local ItemNum = self:FindWndTrans(item,"ItemNum")

	local itemId = showReward.itemId
	local icon = gModelGeneral:GetCommonItemImgRef(showReward)
	self:SetWndEasyImage(ItemIcon,icon,function()
		CS.ShowObject(ItemIcon,true)
	end,true)

	self:SetWndText(ItemNum,LUtil.NumberCoversion(showReward.itemNum))

	local quality = gModelGeneral:GetCommonItemQualityRef(showReward)
	if quality and quality > 0 then
		local qualityRef = gModelItem:GetQualityRef(quality)
		if qualityRef and not string.isempty(qualityRef.itemFrame2) then
			local itemFrame2 = qualityRef.itemFrame2
			self:SetWndEasyImage(QualityBg,itemFrame2,function()
				CS.ShowObject(QualityBg,true)
			end,true)
		end
	end

	item.transform:SetParent(self.mRewardRoot.transform)

	local scale = showInfo.scale
	item.localScale = Vector3(scale,scale,scale)

	local showPos = showInfo.showPos
	item.localPosition = Vector3(showPos.x,showPos.y,0)

	self:SetWndClick(item,function() self:OnClickReward(showReward) end)

	CS.ShowObject(item,true)
end

function UISubPeWishLandYell:InitMsg()
	self:WndEventRecv(EventNames.On_Item_Change,function (...) self:OnItemChange() end)
	self:WndEventRecv(EventNames.REFRESH_PDL_INFO,function (...) self:OnRefreshPDLInfo() end)
	self:WndNetMsgRecv(LProtoIds.PetDreamLandLotterytResp,function(...) self:OnPetDreamLandLotterytResp(...) end)
	self:WndNetMsgRecv(LProtoIds.PetDreamLandLotterytReceiveResp,function(...) self:OnPetDreamLandLotterytReceiveResp(...) end)
end




------------------------------------------------------------------
return UISubPeWishLandYell