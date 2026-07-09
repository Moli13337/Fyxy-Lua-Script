---
--- Created by Administrator.
--- DateTime: 2023/10/23 19:52:12
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UIHeartYell:LChildWnd
local UIHeartYell = LxWndClass("UIHeartYell", LChildWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHeartYell:UIHeartYell()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHeartYell:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHeartYell:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHeartYell:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mHeroChangBtnTxt,ccClientText(11675))
	self:SetWndText(self.mHeartShopBtnTxt,ccClientText(11676))
	self:SetWndText(self.mLogBtnTxt,ccClientText(11677))


	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:CreateAni()

	self:CreateWndEffect(self.mOneCallBtn,"fx_ui_XLZH_anniu","fx_ui_XLZH_anniu" .. 1,100,false,false)
	self:CreateWndEffect(self.mTenCallBtn,"fx_ui_XLZH_anniu","fx_ui_XLZH_anniu" .. 10,100,false,false)

	self:SetWndText(self.mOneCallBtnName,ccClientText(11607))
	self:SetWndText(self.mTenCallBtnName,ccClientText(11608))

	gModelCallHero:CallOpt(self._page)
end

function UIHeartYell:OneCall()
	--printInfoNR("======== ",self._onePayRefId,self._onePayNum,self._subPage)
	if self._subPage == -1 then
		GF.ShowMessage(ccClientText(11631))
		return
	end
	if not self._rewardList then return end
	local rewardData = self._rewardList[self._subPage]
	if not rewardData then return end
	local refId = rewardData.refId
	local refData = self._refData[refId]

	local wndId = 50501
	local func = function()
		self:IsOpenGetWay(self._onePayRefId,self._onePayNum,function()
			self:SendMsg(refId,self._onePayNum, self._onePayRefId)
		end)
	end
	local fixName = gModelItem:GetNameByRefId(self._onePayRefId)
	local payName = ccLngText(refData.typeName)
	local para =
	{
		refId = wndId,
		func = func,
		para = {fixName,self._onePayNum,1,payName}
	}
	--local openFunc = function()
	--	local fixName = gModelItem:GetNameByRefId(self._onePayRefId)
	--	local payName = ccLngText(refData.typeName)
	--	GF.OpenWnd("UIOrdinTip",{refId = wndId,func = func,para = {fixName,self._onePayNum,1,payName}})
	--end
	self:IsOpenGetWay(self._onePayRefId,self._onePayNum,function()
		--gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
		gModelGeneral:OpenUIOrdinTips(para)
	end)
end

function UIHeartYell:OnDrawItem(list,item, itemdata, itempos)
	local bgTrans = self:FindWndTrans(item,"Bg")
	if bgTrans then
		local refId = itemdata.refId
		local IconTrans = self:FindWndTrans(bgTrans,"Icon")
		local BtnTrans = self:FindWndTrans(bgTrans,"Btn")
		local NumTrans = self:FindWndTrans(bgTrans,"Num")
		if IconTrans then
			local icon = gModelItem:GetItemIconByRefId(refId)
			self:SetWndEasyImage(IconTrans, icon)
		end
		if BtnTrans then
			self:SetWndClick(BtnTrans,function()
				gModelGeneral:OpenGetWayWnd({itemId = refId})
			end)
		end
		if NumTrans then
			local haveNum = gModelItem:GetNumStrByRefId(refId)
			self:SetWndText(NumTrans, haveNum)
		end
	end
end

function UIHeartYell:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeartResp, function()
		local rewardList = {}
		local serverData = gModelCallHero:GetHeartData()
		for k,v in pairs(serverData) do
			table.insert(rewardList,v)
		end
		table.sort(rewardList,function(data1,data2)
			local sort1,sort2 = self._refData[data1.refId].srot,self._refData[data2.refId].srot
			return sort1 < sort2
		end)
		self._rewardList = rewardList
		self:InitView(self._subPage == -1)
	end)
	self:WndNetMsgRecv(LProtoIds.CallHeroResp, function()
--[[		local effectName = self._callEffectList[self._subPage]
		if effectName then
			self:CreateWndEffect(self.mBigShiTou,effectName,effectName,100,false,false)
		end]]
		gModelCallHero:CallOpt(self._page)
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:InitView(self._subPage == -1)
	end)
end

function UIHeartYell:SendMsg(refId,times, consumeRefId)
	gModelCallHero:OnCallHeroReq(refId,times, consumeRefId)
end

function UIHeartYell:InitEvent()
	self:SetWndClick(self.mOneCallBtn,function()
		self:CreateWndEffect(self.mOneCallBtn,"fx_ui_XLZH_dianji","fx_ui_XLZH_dianji" .. 1,100,false,false)
		--self:OneCall()
		self:SendHearCall(1)
	end)
	self:SetWndClick(self.mTenCallBtn,function()
		self:CreateWndEffect(self.mTenCallBtn,"fx_ui_XLZH_dianji","fx_ui_XLZH_dianji" .. 10,100,false,false)
		--self:TenCall()
		self:SendHearCall(2)
	end)
	self:SetWndClick(self.mTipsBtn,function()
		GF.OpenWnd("UIBzTips",{refId = 49})
	end)
	self:SetWndClick(self.mRuleBtn,function()
		GF.OpenWnd("UIYellHRu",{extractType = self._page})
	end)
	self:SetWndClick(self.mHeroChangBtn,function()
		local callChangeJump = GameTable.SummonConfigRef["callChangeJump"]
		gModelFunctionOpen:Jump(callChangeJump,"WndCall")
	end)
	self:SetWndClick(self.mHeartShopBtn,function()
		local heartShopJumpId = GameTable.SummonConfigRef["heartShopJumpId"]
		gModelFunctionOpen:Jump(heartShopJumpId,"WndCall")
	end)
	self:SetWndClick(self.mLogBtn,function()
		GF.OpenWnd("UIYellLog",{callType = self._page})
	end)

	for i,v in ipairs(self._shiTouList) do
		self:SetWndClick(v,function()
			self:ShiTouEvent(i)
		end)
	end
end

function UIHeartYell:CreateAni()
	local seqTween
	self:TweenSeqKill(self._playKey)
	if not seqTween then
		self._playShiTou = true
		local moveUpTime = 0.5
		local moveDownTime = 1
		local up,down = 5,-5
		seqTween = self:TweenSeqCreate(self._playKey,function(seq)
			local moveUp = self.mBigShiTou:DOLocalMoveY(self.mBigShiTou.localPosition.y + up,moveUpTime)
			seq:Append(moveUp)
			local moveDown = self.mBigShiTou:DOLocalMoveY(self.mBigShiTou.localPosition.y + down,moveDownTime)
			seq:Append(moveDown)
			local moveReCover = self.mBigShiTou:DOLocalMoveY(self.mBigShiTou.localPosition.y,moveUpTime)
			seq:Append(moveReCover)
			return seq
		end)
	end
	seqTween:SetLoops(-1,DG.Tweening.LoopType.Restart)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._playKey)
	end)
end

function UIHeartYell:ShiTouEvent(index)
	if self._subPage == index then return end
	self._subPage = index
	if self._lastEffectKey then
		self:DestroyWndEffectByKey(self._lastEffectKey)
	end
	for i,v in ipairs(self._shiTouBotList) do
		local img = "callhero_icon_ui_5"
		if i == self._subPage then
			img = "callhero_icon_ui_6"
			local effName = self._shitouEffectList[i]
			self._lastEffectKey = effName
			self:CreateWndEffect(v,effName,effName,100,false,false)
			self:SetWndEasyImage(self.mShiTouHun,self._shiTouUIList[i])
			CS.ShowObject(self.mShiTouHun,true)
		end
		self:SetWndEasyImage(v,img)
	end
	if self._playShiTou then
		self:CreateWndEffect(self.mBigShiTouEff,"fx_ui_XLZH_dashuijing","fx_ui_XLZH_dashuijing",100,false,false)
	end
end

function UIHeartYell:SendHearCall(type)
	local refId = ModelCallHero.HEART_CALL_MAP[self._subPage]
	local wndName = self:GetParentWndName()
	gModelCallHero:SendHeartCall(refId,type,wndName)
end


function UIHeartYell:ChangePayBtn(expend, iconTrans, numTrans,payTimes)
	expend = string.split(expend, "|")
	local payRefId, payNum,haveNum
	if #expend == 1 then
		local data = string.split(expend[1], "=")
		payRefId, payNum = tonumber(data[2]), tonumber(data[3])
		haveNum = gModelItem:GetNumByRefId(payRefId)
	else
		for i, v in ipairs(expend) do
			local data = string.split(v, "=")
			local refId, num = tonumber(data[2]), tonumber(data[3])
			haveNum = gModelItem:GetNumByRefId(refId)
			if i == 1 and haveNum >= num then
				payRefId,payNum = refId,num
				break
			else
				payRefId,payNum = refId,num
			end
		end
	end
	if payTimes == 1 then
		self._onePayRefId,self._onePayNum = payRefId,payNum
	elseif payTimes == 10 then
		self._tenPayRefId,self._tenPayNum = payRefId,payNum
	end
	self:SetWndText(numTrans, payNum)

	local icon = gModelItem:GetItemIconByRefId(payRefId)
	self:SetWndEasyImage(iconTrans, icon)
end

function UIHeartYell:InitItemList(dataList)
	if(self._uiList)then
		self._uiList:RefreshList(dataList)
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mItemList,dataList,function (...) self:OnDrawItem(...) end)
	end
end

function UIHeartYell:IsOpenGetWay(refId,num,func)
	local haveNum = gModelItem:GetNumByRefId(refId)
	if haveNum < num then
		gModelGeneral:OpenGetWayWnd({itemId = refId,srcWnd = self:GetWndName()})
	else
		if func then func() end
	end
end

function UIHeartYell:InitData()
	self._page = self:GetWndArg("page") or 1
	self._subPage = -1

	self._shiTouBotList = {
		self.mShiTouDi1,
		self.mShiTouDi2,
		self.mShiTouDi3,
		self.mShiTouDi4,
	}

	self._shitouEffectList = {
		"fx_ui_XLZH_huo",
		"fx_ui_XLZH_shui",
		"fx_ui_XLZH_feng",
		"fx_ui_XLZH_guangan",
	}

	self._shiTouList = {
		self.mShiTou1,
		self.mShiTou2,
		self.mShiTou3,
		self.mShiTou4,
	}

	self._shiTouUIList = {
		"callhero_icon_ui_1",
		"callhero_icon_ui_2",
		"callhero_icon_ui_3",
		"callhero_icon_ui_4",
	}

	self._callEffectList = {
		"fx_ui_XLZH_zhaohuan_huo",
		"fx_ui_XLZH_zhaohuan_shui",
		"fx_ui_XLZH_zhaohuan_feng",
		"fx_ui_XLZH_zhaohuan_guangan",
	}

	self._lastEffectKey = nil
	self._playShiTou = false
	self._playKey = "moveShiTou"
	self._recoverShiTouPos = self.mBigShiTou.localPosition

	self._refData = gModelCallHero:GetTypeData(self._page)

end

function UIHeartYell:InitView(init)
	if not self._rewardList then return end
	local oneExpend,tenExpend,showItem
	local allCallNum = 0
	if init then
		local serverData = self._rewardList[1]
		allCallNum = serverData.callNum
		local refId = serverData.refId
		local refData = self._refData[refId]
		local showStar = refData.showStar
		showStar = string.split(showStar,",")
		local str = string.replace(ccClientText(11629),showStar[1],showStar[2])
		self:SetWndText(self.mDescTxt,str)

		oneExpend,tenExpend = refData.oneExpend,refData.tenExpend
		showItem = refData.showItem
	else
		local serverData = self._rewardList[self._subPage]
		allCallNum = serverData.callNum
		local refId = serverData.refId
		local refData = self._refData[refId]
		oneExpend,tenExpend = refData.oneExpend,refData.tenExpend
		showItem = refData.showItem
	end
	local heartCallNumMax = GameTable.SummonConfigRef["heartCallNumMax"]
	local limitStr = string.replace(ccClientText(11630),allCallNum,heartCallNumMax)
	self:SetWndText(self.mChouquTxt,limitStr)

	self:ChangePayBtn(oneExpend,self.mOnePayIcon,self.mOnePayNum,1)
	self:ChangePayBtn(tenExpend,self.mTenPayIcon,self.mTenPayNum,10)


	showItem = string.split(showItem,"|")
	local itemList = {}
	for i,v in ipairs(showItem) do
		v = string.split(v,"=")
		table.insert(itemList,{refId = tonumber(v[2])})
	end
	self:InitItemList(itemList)
end

function UIHeartYell:TenCall()
	--printInfoNR("======== ",self._tenPayRefId,self._tenPayNum,self._subPage)
	if self._subPage == -1 then
		GF.ShowMessage(ccClientText(11631))
		return
	end
	if not self._rewardList then return end
	local rewardData = self._rewardList[self._subPage]
	if not rewardData then return end
	local refId = rewardData.refId
	local refData = self._refData[refId]

	local wndId = 50501
	local func = function()
		self:IsOpenGetWay(self._tenPayRefId,self._tenPayNum,function()
			self:SendMsg(refId,self._tenPayNum, self._tenPayRefId)
		end)
	end
	local fixName = gModelItem:GetNameByRefId(self._tenPayRefId)
	local payName = ccLngText(refData.typeName)
	local para =
	{
		refId = wndId,
		func = func,
		para = {fixName,self._tenPayNum,10,payName}
	}

	--local openFunc = function()
	--	local fixName = gModelItem:GetNameByRefId(self._tenPayRefId)
	--	local payName = ccLngText(refData.typeName)
	--	GF.OpenWnd("UIOrdinTip",{refId = wndId,func = func,para = {fixName,self._tenPayNum,10,payName}})
	--end
	self:IsOpenGetWay(self._tenPayRefId,self._tenPayNum,function()
		--gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
		gModelGeneral:OpenUIOrdinTips(para)

	end)
end

------------------------------------------------------------------
return UIHeartYell


