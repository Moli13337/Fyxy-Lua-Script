---
--- Created by LCM.
--- DateTime: 2024/3/7 18:09:25
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubHeartYell:LChildWnd
local UISubHeartYell = LxWndClass("UISubHeartYell", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubHeartYell:UISubHeartYell()
	self._spineKey = "spineKey"


	self._cutHeroTimerKey = "_cutHeroTimerKey"
	self._showAniKey = "showAniKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubHeartYell:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubHeartYell:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubHeartYell:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitText()
	self:InitCallBtnTransInfo()
	self:InitCallTypeBtnInfo()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshSelCallStatus()
	self:RefreshLiHuiShow()

	--local spineName = "Xinlingzhaohuan_xuanzhong"
	--self:CreateWndSpine(self.mEffRoot,spineName,self._spineKey,false,function()
	--	self:RefreshCallView()
	--end)

	gModelCallHero:CallOpt(self._page)
end

function UISubHeartYell:GetCallTypeRef()
	local callRefId = self:GetSelCallRefId()
	return gModelCallHero:GetCallRefByRefId(callRefId)
end

function UISubHeartYell:RefreshLiHuiShow(changeCallType)
	self:TimerStop(self._cutHeroTimerKey)
	local ref = self:GetCallTypeRef()
	if ref then
		self:CreateShowHeroLiHui()
	end
end

function UISubHeartYell:InitNeedAddItemList()
	local list = self:GetNeedAddItemList()
	local uiNeedAddItemList = self._uiNeedAddItemList
	if uiNeedAddItemList then
		uiNeedAddItemList:RefreshList(list)
	else
		uiNeedAddItemList = self:GetUIScroll("uiNeedAddItemList")
		self._uiNeedAddItemList = uiNeedAddItemList
		uiNeedAddItemList:Create(self.mNeedAddItemList,list,function(...) self:OnDrawNeedAddItemCell(...) end)
	end
end

function UISubHeartYell:CreateShowHeroLiHui()
	local spineName = gModelCallHero:GetHeartHeroSpine(self._callRefId)
	if self._recordSpineName and self._recordSpineName ~= spineName then
		---@type LDisplaySpine
		local recordSpine = self:FindWndSpineByKey(self._recordSpineName)
		if recordSpine then
			recordSpine:SetVisible(false)
		end
	end
	self._recordSpineName = spineName
	local newSpine = self:FindWndSpineByKey(spineName)
	if newSpine then
		newSpine:SetVisible(true)
		return
	end
	self:CreateWndSpine(self.mLiHuiPos,spineName,spineName,false)
	if PRODUCT_G_VER ~= 0 then
		CS.ShowObject(self.mLiHuiPos, false)
	end
end

function UISubHeartYell:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeartResp, function()
		self:RefreshServerData()
	end)
	self:WndNetMsgRecv(LProtoIds.CallHeroResp, function()
		gModelCallHero:CallOpt(self._page)
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:RefreshServerData()
	end)
end

function UISubHeartYell:RefreshHeroCVName(heroRefId)
	local cvName = gModelHero:GetHeroCVName(heroRefId)

	cvName =  ""

	local isShow = not string.isempty(cvName)
	CS.ShowObject(self.mCVNameBg, isShow)
	if not isShow then return end

	local cvNameStr = string.replace(ccClientText(19786), cvName)
	self:SetWndText(self.mCVNameTxt, cvNameStr)
end

function UISubHeartYell:GetCallBtnTransInfo(btnTrans)
	local effRootTrans = self:FindWndTrans(btnTrans,"EffRoot")
	local btnNameTrans = self:FindWndTrans(btnTrans,"BtnName")
	local timeTxtTrans = self:FindWndTrans(btnTrans,"TimeTxt")
	local payDivTrans = self:FindWndTrans(btnTrans,"PayDiv")
	local iconImgTrans = self:FindWndTrans(payDivTrans,"IconImg")
	local numTxtTrans = self:FindWndTrans(payDivTrans,"NumTxt")
	local freeTxtTrans = self:FindWndTrans(btnTrans,"FreeTxt")
	return {
		effRootTrans = effRootTrans,
		btnNameTrans = btnNameTrans,
		timeTxtTrans = timeTxtTrans,
		payDivTrans = payDivTrans,
		iconImgTrans = iconImgTrans,
		numTxtTrans = numTxtTrans,
		freeTxtTrans = freeTxtTrans,
	}
end

function UISubHeartYell:GetSelCallRefId()
	local callRefId = self._callRefId
	local refId = callRefId or ModelCallHero.HEART_CALL_1
	return refId
end

function UISubHeartYell:InitCallBtnTransInfo()
	local callBtnTransInfo = {}
	local oneCallBtnTrans = self.mOneCallBtn
	local oneCallTransInfo = self:GetCallBtnTransInfo(oneCallBtnTrans)
	callBtnTransInfo.oneCallTransInfo = oneCallTransInfo
	self:CreateBtnEff(oneCallTransInfo.effRootTrans,"fx_ui_putongzhaohuan_04")


	local tenCallBtnTrans = self.mTenCallBtn
	local tenCallTransInfo = self:GetCallBtnTransInfo(tenCallBtnTrans)
	callBtnTransInfo.tenCallTransInfo = tenCallTransInfo
	self:CreateBtnEff(tenCallTransInfo.effRootTrans,"fx_ui_putongzhaohuan_05")

	self._oneCallTimeTxtTrans = oneCallTransInfo.timeTxtTrans
	self._tenCallTimeTxtTrans = tenCallTransInfo.timeTxtTrans

	self._callBtnTransInfo = callBtnTransInfo
end

--- 获取召唤按钮显示道具信息
function UISubHeartYell:GetCallBtnInfo()
	local ref = self:GetCallTypeRef()
	if not ref then return end
	local oneExpend = LUtil.ConvertCommonItemStrToList(ref.oneExpend,"|")
	local tenExpend = LUtil.ConvertCommonItemStrToList(ref.tenExpend,"|")
	local onePayInfo = self:GetUsePayInfo(oneExpend)
	local tenPayInfo = self:GetUsePayInfo(tenExpend)
	return onePayInfo,tenPayInfo
end

--- 筛选召唤按钮显示道具信息
function UISubHeartYell:GetUsePayInfo(payList)
	payList = payList or {}
	local len = #payList
	local usePayInfo
	if len == 1 then
		usePayInfo = payList[len]
	else
		local itemId,itemNum,haveNum
		for i,v in ipairs(payList) do
			itemId = v.itemId
			itemNum = v.itemNum
			haveNum = gModelItem:GetNumByRefId(itemId)
			if i == 1 and haveNum >= itemNum then
				usePayInfo = v
				break
			end
		end
		if not usePayInfo then
			usePayInfo = payList[len]
		end
	end
	return usePayInfo
end

function UISubHeartYell:CreateTimer(key,time,loopCnt)
	time = time or 1
	loopCnt = loopCnt or -1
	self:TimerStop(key)
	self:TimerStart(key,time,false,loopCnt)
end

function UISubHeartYell:RefreshCallBtn()
	local callBtnTransInfo = self._callBtnTransInfo
	local serverData = self:GetCallHeroServerData()
	if not serverData then return end

	local onePayInfo,tenPayInfo = self:GetCallBtnInfo()
	local freeNum = serverData and serverData.freeNum or 0
	local isHaveFree = freeNum > 0

	local oneCallTransInfo = callBtnTransInfo.oneCallTransInfo
	local btnName = ""
	local freeText = ""
	if isHaveFree then
		btnName = ccClientText(11610)
		--local isNewYear,freeStr,activitys = gModelActivity:GetPrivilegeShow1()
		--if isNewYear then
		--	freeText = string.replace(freeStr,freeNum)
		--else
		if gModelBackflow:GetPrivilegesTypeListByType(9) then
			freeText = string.replace(ccClientText(12141),freeNum)
		end
	else
		btnName = ccClientText(11607)
	end

	local refId = serverData.refId
	local oneCallName = gModelCallHero:GetCallBtnName(refId,ModelCallHero.LEFT,isHaveFree)
	local oneCallInfo = {
		btnName = oneCallName,
		freeText = freeText,
		isHaveFree = isHaveFree,
		itemId = onePayInfo and onePayInfo.itemId,
		itemNum = onePayInfo and onePayInfo.itemNum,
		payType = 1,
	}
	self:SetCallBtn(oneCallTransInfo,oneCallInfo)

	local tenCallName = gModelCallHero:GetCallBtnName(refId,ModelCallHero.RIGHT)
	local tenCallTransInfo = callBtnTransInfo.tenCallTransInfo
	local tenCallInfo = {
		btnName = tenCallName,
		freeText = "",
		isHaveFree = false,
		itemId = tenPayInfo and tenPayInfo.itemId,
		itemNum = tenPayInfo and tenPayInfo.itemNum,
		payType = 10,
	}
	self:SetCallBtn(tenCallTransInfo,tenCallInfo)
end

function UISubHeartYell:InitText()
	self:SetTextTile(self.mDetailsBtn,ccClientText(21813))			-- 详情
	self:SetWndText(self.mLogBtnTxt,ccClientText(11677))
	self:SetWndText(self.mHeartShopBtnTxt,ccClientText(11676))
	self:SetWndText(self.mHeroChangBtnTxt,ccClientText(11675))
end

function UISubHeartYell:InitCallTypeBtnInfo()
	local callTypeInfoList = {
		{
			callBtnTrans = self.mHeart1,
			callEffTrans = self.mHeartEffRoot1,
			linkEffTrans = self.mHeartLinkEffRoot1,
			callRefId = ModelCallHero.HEART_CALL_1,
			effName = "fx_ui_xinlingzhaohuan_xzhuo",
		},
		{
			callBtnTrans = self.mHeart2,
			callEffTrans = self.mHeartEffRoot2,
			linkEffTrans = self.mHeartLinkEffRoot2,
			callRefId = ModelCallHero.HEART_CALL_2,
			effName = "fx_ui_xinlingzhaohuan_xzshui",
		},
		{
			callBtnTrans = self.mHeart3,
			callEffTrans = self.mHeartEffRoot3,
			linkEffTrans = self.mHeartLinkEffRoot3,
			callRefId = ModelCallHero.HEART_CALL_3,
			effName = "fx_ui_xinlingzhaohuan_xzfeng",
		},
		{
			callBtnTrans = self.mHeart4,
			callEffTrans = self.mHeartEffRoot4,
			linkEffTrans = self.mHeartLinkEffRoot4,
			callRefId = ModelCallHero.HEART_CALL_4,
			effName = "fx_ui_xinlingzhaohuan_xzguangan",
		},
	}
	for k,v in pairs(callTypeInfoList) do
		self:CreateWndEffect(v.callEffTrans,v.effName,v.effName,100,false,false,false)
	end
	self._callTypeInfoList = callTypeInfoList
end

function UISubHeartYell:OnClickLogBtnFunc()
	GF.OpenWnd("UIYellLog",{callType = self._page})
end

function UISubHeartYell:CreateBtnEff(trans,effName)
	local key = trans:GetInstanceID()
	self:CreateWndEffect(trans,effName,key,100,false,false)
end

function UISubHeartYell:OnClickDetailsBtnFunc()
	GF.OpenWnd("UIYellHRew",{extractType = 2,viewType = 1})
end

function UISubHeartYell:InitEvent()
	self:SetWndClick(self.mOneCallBtn,function() self:OnClickCallBtnFunc(1) end)
	self:SetWndClick(self.mTenCallBtn,function() self:OnClickCallBtnFunc(2) end)

	for i,v in ipairs(self._callTypeInfoList) do
		self:SetWndClick(v.callBtnTrans,function()
			self:OnClickCallTypeBtnFunc(v.callRefId)
		end)
	end

	self:SetWndClick(self.mDetailsBtn,function() self:OnClickDetailsBtnFunc() end)
	self:SetWndClick(self.mLogBtn,function() self:OnClickLogBtnFunc()	end)
	self:SetWndClick(self.mHeartShopBtn,function() self:OnClickHeartShopBtnFunc()	end)
	self:SetWndClick(self.mHeroChangBtn,function() self:OnClickHeroChangBtnFunc()	end)
end

function UISubHeartYell:OnTimer(key)
	if key == self._cutHeroTimerKey then
		self:TimerStop(self._cutHeroTimerKey)
	end
end

----------------------------- list -----------------------------
function UISubHeartYell:GetNeedAddItemList()
	local list = {}
	local ref = self:GetCallTypeRef()
	if ref then
		list = LUtil.ConvertCommonItemStrToList(ref.showItem,"|")
	end
	return list
end

function UISubHeartYell:SetCallBtn(transInfo,dataInfo)
	local btnNameTrans = transInfo.btnNameTrans
	local payDivTrans = transInfo.payDivTrans
	local iconImgTrans = transInfo.iconImgTrans
	local numTxtTrans = transInfo.numTxtTrans
	local freeTxtTrans = transInfo.freeTxtTrans

	local btnName = dataInfo.btnName
	local freeText = dataInfo.freeText
	self:SetWndText(btnNameTrans,btnName)
	self:SetWndText(freeTxtTrans,freeText)

	local itemId = dataInfo.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(iconImgTrans,icon)

	local itemNum = dataInfo.itemNum
	self:SetWndText(numTxtTrans,itemNum)

	local isHaveFree = dataInfo.isHaveFree
	CS.ShowObject(freeTxtTrans,isHaveFree)
	CS.ShowObject(payDivTrans,not isHaveFree)
end

function UISubHeartYell:OnClickCallTypeBtnFunc(callRefId)
	if self._callRefId == callRefId then return end
	self._callRefId = callRefId
	gModelCallHero:SetHeartCallRefId(self._callRefId)
	self:RefreshSelCallStatus()
	self:RefreshCallView()
	self:RefreshLiHuiShow()
end

function UISubHeartYell:InitData()
	self._page = self:GetWndArg("page")

	local callRefId
	local subPage = self:GetWndArg("subPage")
	if not subPage then
		callRefId = ModelCallHero.HEART_CALL_1
	else
		callRefId = ModelCallHero.HEART_CALL_MAP[subPage]
	end

	local saveCallRefId = gModelCallHero:GetHeartCallRefId()
	if not saveCallRefId then
		callRefId = ModelCallHero.HEART_CALL_1
	else
		callRefId = saveCallRefId
	end
	self._callRefId = callRefId

	self._lihuiInitPos = self.mLiHuiPos.localPosition
end

function UISubHeartYell:RefreshCallView()
	local callRefId = self._callRefId

	local showRandTxt = false
	local showCallLimitTxt = false
	if callRefId then
		local ref = self:GetCallTypeRef()
		local serverData = self:GetCallHeroServerData()
		if ref and serverData then
			showRandTxt = true
			showCallLimitTxt = true

			local showStar = string.split(ref.showStar,",")
			local isSingle = #showStar == 1
			if not isSingle then
				if showStar[1] == showStar[2] then
					isSingle = true
				end
			end
			local showStarStr = ""
			if isSingle then
				showStarStr = string.replace(ccClientText(11682),showStar[1])
			else
				showStarStr = string.replace(ccClientText(11629),showStar[1],showStar[2])
			end
			self:SetWndText(self.mRandomTxt,showStarStr)

			local heartCallNumMax = GameTable.SummonConfigRef["heartCallNumMax"]

			local limitStr = string.replace(ccClientText(11630),serverData.callNum,heartCallNumMax)
			self:SetTextTile(self.mCallLimitTxt,limitStr)

			-- if gLGameLanguage:IsJapanRegion() then
			-- 	local heartDiamondTime = GameTable.SummonConfigRef["heartDiamondTime"]
			-- 	local diamondLimitStr = string.replace(ccClientText(11639),serverData.diamondNum,heartDiamondTime)
			-- 	self:SetWndText(self.mDiamondTipsText,diamondLimitStr)
			-- end
			--

            self:SetWndEasyImage(self.mBg,ref.bg)
		end
	end
	CS.ShowObject(self.mRandomTxt,showRandTxt)
	CS.ShowObject(self.mCallLimitTxt,showCallLimitTxt)

	--if callRefId then
	--	local ani = ModelCallHero.HEART_CALL_EFFNAMELIST[callRefId]
	--	local dpSpine = self:FindWndSpineByKey(self._spineKey)
	--	if dpSpine then
	--		dpSpine:PlayAnimationSolid(ani,true)
	--	end
	--end

	self:RefreshCallBtn()
	self:InitNeedAddItemList()
end

function UISubHeartYell:OnDrawNeedAddItemCell(list,item,itemdata,itempos)
	local IconTrans = self:FindWndTrans(item,"IconDiv/Icon")
	local NumTrans = self:FindWndTrans(item,"Num")
	local AddBtnTrans = self:FindWndTrans(item,"BtnDiv/AddBtn")

	local itemId = itemdata.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(IconTrans,icon)

	local haveNum = gModelItem:GetNumStrByRefId(itemId)
	self:SetWndText(NumTrans,haveNum)

	self:SetWndClick(AddBtnTrans,function()
		self:OnClickAddBtnFunc(itemdata)
	end)
end

function UISubHeartYell:OnTcpReconnect()
	gModelCallHero:CallOpt(self._page)
end

function UISubHeartYell:RefreshServerData()
	self:InitCallServerData()
	self:RefreshCallView()
end

function UISubHeartYell:OnClickHeroChangBtnFunc()
	local callChangeJump = GameTable.SummonConfigRef["callChangeJump"]
	gModelFunctionOpen:Jump(callChangeJump,"WndCall")
end

function UISubHeartYell:OnClickCallBtnFunc(callType)
	local callRefId = self._callRefId
	if not callRefId then
		return
	end
	if gModelGeneral:IsFullHeroBag(1) then
		return 1
	end
	local wndName = self:GetParentWndName()
	gModelCallHero:SendHeartCall(callRefId,callType,wndName)
end

function UISubHeartYell:OnClickAddBtnFunc(itemdata)
	gModelGeneral:OpenGetWayWnd({itemId = itemdata.itemId,srcWnd = self:GetWndName()})
end

function UISubHeartYell:RefreshSelCallStatus()
	local callRefId = self._callRefId
	for i,v in ipairs(self._callTypeInfoList) do
		local show = callRefId and v.callRefId == callRefId or false
		CS.ShowObject(v.callEffTrans,show)
		CS.ShowObject(v.linkEffTrans,show)
	end
end

function UISubHeartYell:OnClickHeartShopBtnFunc()
	local heartShopJumpId = GameTable.SummonConfigRef["heartShopJumpId"]
	gModelFunctionOpen:Jump(heartShopJumpId,"WndCall")
end

function UISubHeartYell:InitCallServerData()
	self._callHeroServerData = gModelCallHero:GetHeartData()
end

function UISubHeartYell:GetCallHeroServerData()
	local callHeroServerData = self._callHeroServerData
	if not callHeroServerData then return end
	local callRefId = self:GetSelCallRefId()
	return callHeroServerData[callRefId]
end

------------------------------------------------------------------
return UISubHeartYell



