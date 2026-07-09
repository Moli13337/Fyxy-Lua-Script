---
--- Created by Administrator.
--- DateTime: 2024/5/21 15:16:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISdAward:LWnd
local UISdAward = LxWndClass("UISdAward", LWnd)
------------------------------------------------------------------

--- 0：左边为单次召唤按钮
--- 1：左边为确定按钮
UISdAward.SHOW_TYPE = 1


--- 圣物
UISdAward.TYPE_HALIDOM = 1

--- 萌宠幻境
UISdAward.TYPE_PETDLCALL = 2


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISdAward:UISdAward()
	self._iconPlayTime = 0.1
	self._cancelItemTween = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISdAward:OnWndClose()
	local way = self._way
	if way and way == ModelHalidom.WAY_REWARD_DRAW then
		FireEvent(EventNames.CLOSE_HALIDOM_REWARD)
		FireEvent(EventNames.CLOSE_HALIDOM_BIGREWARD)
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISdAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISdAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:CreateWndEffect(self.mEffRoot,"fx_ui_gongxihuode","fx_ui_gongxihuode",100,false)
	self:InitData()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	CS.ShowObject(self.mPayBtnList,self._way == ModelHalidom.WAY_REWARD_DRAW)
	CS.ShowObject(self.mCloseTip,self._way == ModelHalidom.WAY_REWARD_PROGRESS)
	self:RefreshView()
end

function UISdAward:OnHalidomDrawResp(pb)
	self._rewardList = gModelHalidom:GetRewardListByPb(pb,self._way)
	if #self._rewardList < 1 then return end
	self._luckyItem = pb.luckyItem
	CS.ShowObject(self.mEffRoot,false)
	self:RefreshView()
end

function UISdAward:OnStartDrag()
	self._cancelItemTween = true

	---@type SequenceCom
	local seqCom = self:GetSeqCom()
	seqCom:DeleteAllSeq()

--[[	local uiList = self._uiRewardList
	local list = uiList:GetList()
	local seq = seqCom:CreateSeq("moveContent")
	local duration = 0.2
	local curPos = list:GetContentPosition()
	local endPos = Vector2.zero
	local tween = YXTween.TweenFloat(0, 1, duration, function(t)
		local pos = Vector2.Lerp(curPos, endPos, t)
		list:SetContentPosition(pos)
	end)

	seq:Append(tween)
	seq:PlayForward()]]
end



function UISdAward:GetRewardList()
	return self._rewardList
end

function UISdAward:MoveContent()
	if self._cancelItemTween then return end

	local uiList = self._uiRewardList:GetList()
	if not uiList then return end

	local viewSize = self.mRewardList.rect.size
	local contentSize = uiList:GetContentSize()
	local itemSize = Vector2.New(140, 100)

	local moveLen = contentSize.y - viewSize.y
	if moveLen <= 0 then return end

	local disY = -itemSize.y / moveLen
	local dis = Vector2.New(0, disY)
	local duration = 0.4
	local seq = self._seqCom:CreateSeq("moveContent")
	local curPos = uiList:GetContentPosition()
	local endPos = curPos + dis
	endPos.y = math.max(0, endPos.y)
	local tween = YXTween.TweenFloat(0, 1, duration, function(t)
		local pos = Vector2.Lerp(curPos, endPos, t)
		uiList:SetContentPosition(pos)
	end)
	seq:Append(tween)
	seq:PlayForward()
end

function UISdAward:InitEvent()

	if UISdAward.SHOW_TYPE == 0 then
		--- 返回按钮必备
		self:SetWndClick(self.mMaskBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	elseif self._way == ModelHalidom.WAY_REWARD_PROGRESS then
		self:SetWndClick(self.mMaskBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	end

	self:SetWndClick(self.mBtnPay1,function()
		if UISdAward.SHOW_TYPE == 0 then
			self:OnClickBtnPay1Func()
		else
			self:WndClose()
		end
	end)

	self:SetWndClick(self.mBtnPay2,function() self:OnClickBtnPay2Func() end)
end

function UISdAward:RefreshCallPayPetDreamLandInfo1()
	local lotteryType = self._lotteryType
	---@return StructPetDreamLandLotteryData
	local lotteryData = gModelPetDreanLand:GetTypeLotteryInfo(lotteryType)
	if not lotteryData then return end

	local freeNum = lotteryData.freeNum
	local totalFreeNum = lotteryData.totalFreeNum
	local freeLeft = totalFreeNum - freeNum
	local hasFree = freeLeft > 0
	local payInfo1 = gModelPetDreanLand:GetDreamlandCallByType(lotteryType,1)
	self:SetCallPayInfo(payInfo1,{
		payIconTrans = self.mBtnPay2Icon,
		payTxtTrans = self.mBtnPay2Num,
		hasFree = hasFree,
		freeDrawCnt = freeLeft,
	})

	local btnOneName = hasFree and ccClientText(43391) or ccClientText(43346)
	self:SetWndButtonText(self.mBtnPay2,btnOneName)
end

function UISdAward:OnPetDreamLandLotterytResp(pb)
	self._rewardList = gModelPetDreanLand:CommonDisposeRewards(pb.itemList)
	if #self._rewardList < 1 then return end
	self._luckyItem = pb.extraItem
	CS.ShowObject(self.mEffRoot,false)
	self:RefreshView()
end

function UISdAward:RefreshCallPayMoreBtn()
	if self._wndType == UISdAward.TYPE_HALIDOM then
		self:RefreshCallPayHalidomMoreBtn()
	else
		self:RefreshCallPayPetDreamLandMoreBtn()
	end
end

function UISdAward:OnClickBtnPay1Func()
	local wndType = self._wndType
	if wndType == UISdAward.TYPE_HALIDOM then
		gModelHalidom:DisposeHalidomDrawReq(ModelHalidom.TYPE_DRAW_ONCE)
	else
		gModelPetDreanLand:DisposePetDreamLandLotteryReq(self._lotteryType,1)
	end
end

function UISdAward:RefreshCallPetDreamLand0()
	local lotteryType = self._lotteryType
	---@return StructPetDreamLandLotteryData
	local lotteryData = gModelPetDreanLand:GetTypeLotteryInfo(lotteryType)
	if not lotteryData then return end

	local freeNum = lotteryData.freeNum
	local totalFreeNum = lotteryData.totalFreeNum
	local freeLeft = totalFreeNum - freeNum
	local hasFree = freeLeft > 0
	local payInfo1 = gModelPetDreanLand:GetDreamlandCallByType(lotteryType,1)
	self:SetCallPayInfo(payInfo1,{
		payIconTrans = self.mBtnPay1Icon,
		payTxtTrans = self.mBtnPay1Num,
		hasFree = hasFree,
		freeDrawCnt = freeLeft,
	})

	local btnOneName = hasFree and ccClientText(43391) or ccClientText(43346)
	self:SetWndButtonText(self.mBtnPay1,btnOneName)

	self:RefreshCallPayMoreBtn()
end

function UISdAward:CreateMinRewardList(list)
	CS.ShowObject(self.mMinRewardList,true)
	CS.ShowObject(self.mRewardList,false)

	local uiList = self._uiMinRewardList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mMinRewardList")
		self._uiMinRewardList = uiList
		uiList:Create(self.mMinRewardList, list, function(...)
			self:OnDrawRewardCell(...)
		end)
	end
	uiList:EnableScroll(true)
	local tUIList = uiList:GetList()
	tUIList:RefreshList()
end

function UISdAward:RefreshDesc()
	local desc = ""
	if self._luckyItem and #self._luckyItem > 0 then
		local itemList = LUtil.GetSortItemAllAddNumList(self._luckyItem)
		local itemStrs = {}
		for i,v in ipairs(itemList) do
			table.insert(itemStrs,string.replace(ccClientText(41549),
					gModelItem:GetNameByRefId(v.itemId),LUtil.NumberCoversion(v.itemNum)))
		end
		local itemStr = ""
		if #itemStrs > 1 then
			local str = ccClientText(41550)
			itemStr = table.concat(itemStrs,str)
		else
			itemStr = itemStrs[1]
		end
		desc = string.replace(ccClientText(41531),itemStr)
	end
	self:SetWndText(self.mDesc,desc)
end

function UISdAward:OnClickBtnPay2Func()
	local wndType = self._wndType
	if UISdAward.SHOW_TYPE == 0 then
		if wndType == UISdAward.TYPE_HALIDOM then
			gModelHalidom:DisposeHalidomDrawReq(ModelHalidom.TYPE_DRAW_MORE)
		else
			gModelPetDreanLand:DisposePetDreamLandLotteryReq(self._lotteryType,10)
		end
	else
		if self:CheckIsMore() then
			if wndType == UISdAward.TYPE_HALIDOM then
				gModelHalidom:DisposeHalidomDrawReq(ModelHalidom.TYPE_DRAW_MORE)
			else
				gModelPetDreanLand:DisposePetDreamLandLotteryReq(self._lotteryType,10)
			end
		else
			if wndType == UISdAward.TYPE_HALIDOM then
				gModelHalidom:DisposeHalidomDrawReq(ModelHalidom.TYPE_DRAW_ONCE)
			else
				gModelPetDreanLand:DisposePetDreamLandLotteryReq(self._lotteryType,1)
			end
		end
	end
end

function UISdAward:InitData()
	self._wndType = self:GetWndArg("wndType") or UISdAward.TYPE_HALIDOM
	self._rewardList = self:GetWndArg("rewardList") or {}
	self._luckyItem = self:GetWndArg("luckyItem")
	self._way = self:GetWndArg("way")


	--- 萌宠幻境才有的数据
	local lotteryType = self:GetWndArg("lotteryType")
	self._lotteryType = lotteryType
end

function UISdAward:RefreshCallPayInfo1()
	CS.ShowObject(self.mPayItemDiv1,false)
	self:SetWndButtonText(self.mBtnPay1,ccClientText(10102))

	if self:CheckIsMore() then
		self:RefreshCallPayMoreBtn()
	else
		local wndType = self._wndType
		if wndType == UISdAward.TYPE_HALIDOM then
			self:RefreshCallPayHalidomInfo1()
		else
			self:RefreshCallPayPetDreamLandInfo1()
		end
	end
end

function UISdAward:RefreshView()
	LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_EQUIP_COMMON)

	---@type SequenceCom
	local seqCom = self:GetSeqCom()
	seqCom:DeleteAllSeq()

	self:RefreshDesc()
	self:RefreshCallPayInfo()
	self:InitRewardList()
	CS.ShowObject(self.mEffRoot,true)
end

function UISdAward:RefreshCallPayHalidomInfo1()
	local hasFree = gModelHalidom:CheckRPHasFreeNum()
	local halidomExpend = gModelHalidom:GetHalidomExpend()
	self:SetCallPayInfo(halidomExpend,{
		payIconTrans = self.mBtnPay2Icon,
		payTxtTrans = self.mBtnPay2Num,
		hasFree = hasFree,
		freeDrawCnt = gModelHalidom:GetHalidomFreeDrawCnt()
	})
	local btnOneName = hasFree and ccClientText(41547) or ccClientText(41507)
	self:SetWndButtonText(self.mBtnPay2,btnOneName)
end

function UISdAward:OnRewardItemReturn(list, item, itemdata, itempos)
	local instanceId = item:GetInstanceID()
	---@type SequenceCom
	local seqCom = self:GetSeqCom()
	seqCom:DeleteSeq(instanceId)
end

function UISdAward:OnDrawRewardCell(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item,"CommonUI/Icon")

	local reward = itemdata.reward
	local instanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(reward.itemType,reward.itemId,reward.itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	self:TweenItemScale(Icon,itempos)

	self:SetWndClick(Icon,function()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end)
end

function UISdAward:InitMsg()
	 self:WndEventRecv(EventNames.On_Item_Change,function (...) self:OnItemChange() end)
	 self:WndNetMsgRecv(LProtoIds.HalidomDrawResp,function(...) self:OnHalidomDrawResp(...) end)
	 self:WndNetMsgRecv(LProtoIds.PetDreamLandLotterytResp,function(...) self:OnPetDreamLandLotterytResp(...) end)
end

function UISdAward:RefreshCallPayPetDreamLandMoreBtn()
	local lotteryType = self._lotteryType
	---@return StructPetDreamLandLotteryData
	local lotteryData = gModelPetDreanLand:GetTypeLotteryInfo(lotteryType)
	if not lotteryData then return end

	local payInfo2 = gModelPetDreanLand:GetDreamlandCallByType(lotteryType,10)
	self:SetCallPayInfo(payInfo2,{
		payIconTrans = self.mBtnPay2Icon,
		payTxtTrans = self.mBtnPay2Num,
		hasFree = false,
		freeDrawCnt = -1
	})
	CS.ShowObject(self.mPayItemDiv2,true)
	self:SetWndButtonText(self.mBtnPay2,ccClientText(43365))
end

function UISdAward:RefreshCallPayHalidom0()
	local hasFree = gModelHalidom:CheckRPHasFreeNum()
	local halidomExpend = gModelHalidom:GetHalidomExpend()
	self:SetCallPayInfo(halidomExpend,{
		payIconTrans = self.mBtnPay1Icon,
		payTxtTrans = self.mBtnPay1Num,
		hasFree = hasFree,
		freeDrawCnt = gModelHalidom:GetHalidomFreeDrawCnt()
	})

	local btnOneName = hasFree and ccClientText(41547) or ccClientText(41507)
	self:SetWndButtonText(self.mBtnPay1,btnOneName)
	--CS.ShowObject(self.mPayItemDiv1,not hasFree)

	self:RefreshCallPayMoreBtn()
end

function UISdAward:RefreshCallPayHalidomMoreBtn()
	local halidomMoreExpend = gModelHalidom:GetHalidomMoreExpend()
	self:SetCallPayInfo(halidomMoreExpend,{
		payIconTrans = self.mBtnPay2Icon,
		payTxtTrans = self.mBtnPay2Num,
		hasFree = false,
		freeDrawCnt = -1
	})
	CS.ShowObject(self.mPayItemDiv2,true)
	self:SetWndButtonText(self.mBtnPay2,ccClientText(41508))
end

function UISdAward:SetCallPayInfo(payInfo,data)
	local hasFree = data.hasFree
	local freeDrawCnt = data.freeDrawCnt

	--免费的次数用白色文本，d2efff
	--道具足够是用绿色文本，68e6ac
	--不够是红色文本，ff7676

	local payIconTrans = data.payIconTrans
	local numStr = ""
	local showIconParent = false
	if hasFree and freeDrawCnt > 0 then
		CS.ShowObject(payIconTrans,false)
		numStr = string.replace(ccClientText(41548),freeDrawCnt)
		numStr = string.replace("<color=#d2efff>#a1#</color>",numStr)
	else
		showIconParent = true
		local itemId = payInfo.itemId
		local iconPath = gModelItem:GetItemIconByRefId(itemId)
		self:SetWndEasyImage(payIconTrans,iconPath,function()
			CS.ShowObject(payIconTrans,true)
		end)
		local hasNum = gModelItem:GetNumByRefId(itemId)
		local itemNum = payInfo.itemNum
		local isEnough = hasNum >= itemNum
		local color = isEnough and "#68e6ac" or "#ff7676"
		numStr = string.replace("<color=#a1#>#a2#/#a3#</color>",color,LUtil.NumberCoversion(hasNum),
				LUtil.NumberCoversion(itemNum))
	end
	CS.ShowObject(payIconTrans.parent,showIconParent)

	--local showStr = isEnough and ccClientText(41509) or ccClientText(41510)
	--showStr = string.replace(showStr,LUtil.NumberCoversion(hasNum),LUtil.NumberCoversion(itemNum))
	self:SetWndText(data.payTxtTrans,numStr)
end

function UISdAward:RefreshCallPayInfo()
	if UISdAward.SHOW_TYPE == 0 then
		self:RefreshCallPayInfo0()
	else
		self:RefreshCallPayInfo1()
	end
end

function UISdAward:RefreshCallPayInfo0()
	if self._wndType == UISdAward.TYPE_HALIDOM then
		self:RefreshCallPayHalidom0()
	else
		self:RefreshCallPetDreamLand0()
	end
end

function UISdAward:TweenItemScale(item,itempos)
	local nowTime = Time.time
	local timePast = nowTime - self._startTime
	local delay = itempos * self._iconPlayTime
	if timePast > delay or self._cancelItemTween then
		item.transform.localScale = Vector3.one
		print("======= timePast > delay or self._cancelItemTween ")
		return
	end

	local curDelay = delay - timePast
	local instanceId = item:GetInstanceID()
	item.transform.localScale = Vector3.zero
	---@type SequenceCom
	local seqCom = self:GetSeqCom()
	if seqCom:FindSeq(instanceId) then
		seqCom:DeleteSeq(instanceId)
	end
	local seq = seqCom:CreateSeq(instanceId)
	seq:AppendInterval(curDelay)
	seq:Append(item:DOScale(Vector3.one, self._iconPlayTime))
	print("播放动画")
	if itempos > 8 and itempos % 4 == 1 then
		seq:AppendCallback(function()
			self:MoveContent()
		end)
	end
	seq:OnKill(function()
		item.transform.localScale = Vector3.one
	end)
	seq:OnComplete(function()
		seqCom:DeleteSeq(instanceId)
	end)
	seq:PlayForward()
end

function UISdAward:InitRewardList()
	self._cancelItemTween = false
	self._startTime = Time.time

	local list = self:GetRewardList()
	local isMore = #list > 4

	if isMore then
		self:CreateRewardList(list)
	else
		self:CreateMinRewardList(list)
	end
end

function UISdAward:OnItemChange()
	self:RefreshCallPayInfo()
end

function UISdAward:InitText()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
end

function UISdAward:CheckIsMore()
	return #self._rewardList > 1
end

function UISdAward:CreateRewardList(list)
	CS.ShowObject(self.mRewardList,true)
	CS.ShowObject(self.mMinRewardList,false)

	local uiList = self._uiRewardList
	if uiList then
		uiList:RefreshList(list)
		uiList:DrawAllItems(true)
	else
		uiList = self:GetUIScroll("mRewardList")
		self._uiRewardList = uiList
		uiList:Create(self.mRewardList, list, function(...)
			self:OnDrawRewardCell(...)
		end, UIItemList.SUPER_GRID, false)

		local uiScrollList = uiList:GetList()
		uiScrollList:SetFuncOnItemReturn(function(...)
			self:OnRewardItemReturn(...)
		end)
		uiScrollList:SetOnStartDrag(function()
			self:OnStartDrag()
		end)
	end
	local tList = uiList:GetList()
	tList:RefreshList()
end

------------------------------------------------------------------
return UISdAward