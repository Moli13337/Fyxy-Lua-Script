---
--- Created by BY.
--- DateTime: 2023/10/12 16:00:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWishPrigeBuyPop:LWnd
local UIWishPrigeBuyPop = LxWndClass("UIWishPrigeBuyPop", LWnd)
local Tweening = DG.Tweening

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWishPrigeBuyPop:UIWishPrigeBuyPop()
	self._uiCommonList = {}
	self._timeTextList = {}
	self._timeKey = "timeKey"

	self._timeLimitKey = "timeLimitKey"
	self._timeLimitTextList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWishPrigeBuyPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self:ClearCommonIconList(self._hyperList)

	local callfunc = self:GetWndArg("callfunc")
	if callfunc then
		callfunc()
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWishPrigeBuyPop:OnCreate()
	LWnd.OnCreate(self)

	self._hyperList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWishPrigeBuyPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTabImg()

	self:InitMessage()
	self:InitCommand()

	self:InitEvent()

	self:RefreshExtraContent()
end

--【T特权商城】删掉无用的参数和特权
--function UIWishPrigeBuyPop:IsHuaweiTarget()
--	return gModelNormalActivity:IsHuaweiTarget(self._ref.refId)
--end

function UIWishPrigeBuyPop:OnClickPrivacyBtn()
	gLSdkImpl:CallMethod(LSdkMethod.OpenPrivacyPolicy)
end

function UIWishPrigeBuyPop:OnClickBuyFreeGift(ref)
	gModelNormalActivity:BuyFreePrivi(ref.refId)
end

function UIWishPrigeBuyPop:CheckPopMergeTip()
	if not self._ref then
		return
	end

	--local privilegeId = gModelTowerDefence:GetPrivilegeId()
	--if privilegeId ~= self._ref.refId then
	--	return
	--end
	--
	--gModelTowerDefence:CheckShowAutoMergeTip()
end

function UIWishPrigeBuyPop:OnClickChargeBtn()
	gLSdkImpl:CallMethod(LSdkMethod.OpenServiceTerm)
end

function UIWishPrigeBuyPop:RewardListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"CommonUI/Icon")
	local itemTab = self:FindWndTrans(item,"CommonUI/ItemTab")
	local descript = itemdata.descript
	local isShowTab = descript ~= 0-- and LGameLanguage:GetLanguageFlag() == "zhcn"
	CS.ShowObject(itemTab,isShowTab)
	if isShowTab then
		local tabImg = self._tabImgList[descript] or self._tabImgList[3]
		self:SetWndEasyImage(itemTab,tabImg)
	end
	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId,itemdata.itemNum)
	baseClass:DoApply()
	CS.ShowObject(root, true)
	self:SetIconClickScale(root, true)
	self:SetWndClick(root, function() gModelGeneral:ShowCommonItemTipWnd(itemdata) end)
end

function UIWishPrigeBuyPop:InitCommand()
	self._freePrivilegeIdList = gModelNormalActivity:GetFreePrivilegeIdList() or {}

	local ref = self:GetWndArg("ref")
	if not ref then
		local refId = self:GetWndArg("extra")
		ref = gModelNormalActivity:GetBIActivityPrivilegeGiftRefByRefId(refId)
		self._ref = ref
		gModelNormalActivity:OnPrivilegeGiftReq()
	else
		self._ref = ref
		self:RefreshData()
	end

	--self:SetWndEasyImage(self.mTitleImg,ref.namePng,nil,true)
	self:SetWndText(self.mTitleText, ccLngText(ref.name))


	self:SetWndText(self.mIntroText,string.replace(ccClientText(14210),ccLngText(ref.description2)))
	self:InitTextLineWithLanguage(self.mIntroText, -30)
	self:SetWndText(self.mPreviewText,ccClientText(14209))


	local itemList = gModelNormalActivity:GetAllRewardShow(ref.refId) or {}
	local cnt = #itemList
	local showMore  = cnt > 1
	local size = showMore and 652 or 510
	LxUiHelper.SetSizeWithCurAnchor(self.mBg,1,size)
	CS.ShowObject(self.mReward2,showMore)

	--local uiList = self:GetUIScroll("rewardCell")
	--uiList:Create(self.mRewardList1,itemList,function (...) self:RewardListItem(...) end)

	local item1List = itemList[1] or {}
	local rewardList1 = self:CreateUIScrollImpl(nil,self.mRewardList1,item1List,function (...)
		self:RewardListItem(...)
	end,UIItemList.SUPER_GRID)

	local isReward1Enable = item1List and #item1List > 5
	rewardList1:EnableScroll(isReward1Enable , true)

	if showMore then
		local item2List = itemList[2] or {}
		local rewardList2 = self:CreateUIScrollImpl(nil,self.mRewardList2,item2List,function (...)
			self:RewardListItem(...)
		end,UIItemList.SUPER_GRID)
		isReward1Enable = item2List and #item2List > 5
		rewardList2:EnableScroll(isReward1Enable , true)
	end

	local list = {}
	if gModelNormalActivity:IsHuaweiChanel() then
		local desc = ccLngText(ref.channelText)
		local temps = string.split(desc,"|")
		for k,v in ipairs(temps) do
			table.insert(list,v)
		end
	end
	--local configList = gModelNormalActivity:GetPriviRewardRef(ref.refId)
	--if configList and #configList >0 then
		local desc = gModelNormalActivity:GetPriviRewardDesc(ref.refId)
		--local desc = ccLngText(configList[1].description1)
		local temps = string.split(desc,"|")
		for k,v in ipairs(temps) do
			table.insert(list,v)
		end


	--end


	local _uiList = self:GetUIScroll("descriptionCell")
	_uiList:Create(self.mCellScroll,list,function (...) self:DesListItem(...) end,UIItemList.SUPER)
	_uiList:EnableScroll(true,false)



end

function UIWishPrigeBuyPop:InitTabImg()
	self._tabImgList = gModelNormalActivity:GetPrivilegeTabImgList()
end

function UIWishPrigeBuyPop:RefreshExtraContent()
	local subscribeTips = gModelNormalActivity:GetBIActivityConfigRefByKey("subscribeTips")

	local bValidPackage = false
	if gLGameLanguage:IsForeignVietnamOrAmericaRegion() then
		bValidPackage = CS.IsOSIos() and self:IsUsaRegionShowLink()
	else
		--【T特权商城】删掉无用的参数和特权
		--bValidPackage = self:IsIosTarget() or self:IsHuaweiTarget()
	end

	local showExtra = subscribeTips == 1 and bValidPackage

	CS.ShowObject(self.mExtra,showExtra)

	if not showExtra then
		return
	end

	self:SetWndText(self.mIntroTitle,ccClientText(24300))

	--【T特权商城】删掉无用的参数和特权
	--if self:IsHuaweiTarget() then
	--	self:SetWndText(self.mIntroCon,ccClientText(24302))
	--else
		self:SetWndText(self.mIntroCon,ccClientText(24301))
	--end

end

function UIWishPrigeBuyPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.PrivilegeGiftResp, function(...)
		self:RefreshData()

		self:CheckPopMergeTip()
	end)
	self:WndNetMsgRecv(LProtoIds.BuyPrivilegeGiftResp, function(...)
		self:RefreshData()

		self:CheckPopMergeTip()
	end)
end

function UIWishPrigeBuyPop:InitGiftInfo(item,data,giftRef,showBubble)
	local SubscriptionText = self:FindWndTrans(item,"SubscriptionText")
	local BtnItemBuy = self:FindWndTrans(item,"BtnItemBuy")
	local BtnItemBuyText = self:FindWndTrans(BtnItemBuy,"Text")
	local BtnSubscription = self:FindWndTrans(item,"BtnSubscription")
	local ref = data.ref

	CS.ShowObject(item,true)
	self:SetWndText(SubscriptionText,ccLngText(ref.moreText))

	local refId = ref.refId
	local isFree = self._freePrivilegeIdList[refId] or false

	local isUseItemBuy = not isFree and string.find(ref.expend,"=")
	CS.ShowObject(BtnItemBuy,isUseItemBuy)
	CS.ShowObject(BtnSubscription,not isUseItemBuy )
	if isFree then
		self:SetWndButtonText(BtnSubscription,ccClientText(11932))
		self:SetWndClick(BtnSubscription,function ()
			self:OnClickBuyFreeGift(ref)
		end)
	elseif isUseItemBuy then
		local expendInfo = string.split(ref.expend,"=")
		local itemId = tonumber(expendInfo[2])
		local icon = gModelItem:GetItemIconByRefId(itemId)
		local itemNum = expendInfo[3] or ""
		if icon then
			local ItemIconTrans = self:FindWndTrans(BtnItemBuyText,"ItemIcon")
			self:SetWndEasyImage(ItemIconTrans,icon)
		end
		self:SetWndText(BtnItemBuyText,itemNum)
		self:SetWndClick(BtnItemBuy,function ()
			self:OnClickBuyGift(ref,ccLngText(giftRef.name))
		end)
	else
		local expendId = tonumber(ref.expend)
		local valueShow = gModelPay:GetShowByWelfareId(expendId)

		self:SetWndButtonText(BtnSubscription,valueShow)
		self:SetWndClick(BtnSubscription,function ()
			self:OnClickBuyGift(ref,ccLngText(giftRef.name))
		end)
	end

	--【T特权商城】删掉无用的参数和特权
	--if showBubble then
	--	local btnStr = ccLngText(gModelNormalActivity:GetBIActivityConfigRefByKey("returnBtnText"))
	--	self:SetWndButtonText(BtnSubscription,btnStr)
	--end



	local instanceId = item:GetInstanceID()
	self._timeLimitTextList[instanceId] = nil
	local TimeLimit = self:FindWndTrans(item,"TimeLimit")
	if TimeLimit then
		CS.ShowObject(TimeLimit, false)
		local giftRefId = giftRef and giftRef.refId
		if giftRefId and giftRefId > 0 then
			if gModelNormalActivity:CheckInCreateRoleTime(giftRefId) == 0 then
				local Desc = self:FindWndTrans(TimeLimit,"Desc")
				self:SetWndText(Desc,ccClientText(14220))

				local TimeTxt = self:FindWndTrans(TimeLimit,"TimeTxt")
				local endTime = gModelNormalActivity:GetPrivilegeGiftExtraEndTime(giftRefId)
				local tempData = {
					endTime = endTime,
					timeTxt = TimeTxt,
					root = TimeLimit,
					endCDFunc = function()
						if not self:IsWndValid() then return end
						self:RefreshData()
					end
				}
				self._timeLimitTextList[instanceId] = tempData
				self:SetTimeLimitTxtCD(tempData)

				if not self:IsTimerExist(self._timeLimitKey) then
					self:TimerStart(self._timeLimitKey, 1, false, -1)
				end
			end
		end
	end
end

function UIWishPrigeBuyPop:DesListItem(list, item, itemdata, itempos)
	local _Text = CS.FindTrans(item,"UIText")
	self:SetWndText(_Text,itemdata)
	local uiText = LxUiHelper.FindXTextCtrl(_Text)
	local height = uiText.preferredHeight
	LxUiHelper.SetSizeWithCurAnchor(item,1,height)
end

function UIWishPrigeBuyPop:SetTime()
	local time = GetTimestamp()
	for i, v in pairs(self._timeTextList) do
		local info = gModelNormalActivity:GetPrivilegeGiftListByRefId(i)
		local endTime = info.endTime
		local timespan = endTime - time
		if(timespan > 0)then
			local timeStr = LUtil.FormatTimespanCn(timespan)
			self:SetWndText(v,string.replace(ccClientText(17241),timeStr))
		end
	end

	for k,v in pairs(self._timeLimitTextList) do
		self:SetTimeLimitTxtCD(v)
	end
end

function UIWishPrigeBuyPop:OnTimer(key)
	self:SetTime()
end

function UIWishPrigeBuyPop:SetTimeLimitTxtCD(tempData)
	local endTime,timeTxt,root = tempData.endTime,tempData.timeTxt,tempData.root
	local time = GetTimestamp()
	local timespan = endTime - time
	local showRoot = timespan > 0
	local timeStr = ""
	if showRoot then
		timeStr = LUtil.GetFormatCDTime(timespan)
	else
		local endCDFunc = tempData.endCDFunc
		if endCDFunc then
			endCDFunc()
		end
	end
	self:SetWndText(timeTxt,timeStr)
	CS.ShowObject(root,showRoot)
end

function UIWishPrigeBuyPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndCloseAndBack() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndCloseAndBack() end)
	self:SetWndClick(self.mPrivacyBtn, function(...) self:OnClickPrivacyBtn() end)
	self:SetWndClick(self.mChargeBtn, function(...) self:OnClickChargeBtn() end)

	self:InitLinkContent()

end

function UIWishPrigeBuyPop:OnClickBuyGift(ref,giftName)
	gModelNormalActivity:BuyPrivi(ref.refId)
end

--【T特权商城】删掉无用的参数和特权
--function UIWishPrigeBuyPop:IsIosTarget()
--	return gModelNormalActivity:IsIosTarget(self._ref.refId)
--end

function UIWishPrigeBuyPop:IsUsaRegionShowLink()
	return gModelNormalActivity:IsUSARegionAutoGift(self._ref.refId)
end

function UIWishPrigeBuyPop:RefreshData()
	local itemdata = self._ref
	local infos = gModelNormalActivity:GetPrivilegeGiftList()
	local gifts = {}
	local isActive = false
	local activeInfo = nil
	for i, v in ipairs(infos) do
		local ref = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(v.refId)
		if ref and ref.type == itemdata.refId then
			local giftData = {ref = ref,info = v}
			table.insert(gifts,giftData)
			if not isActive then
				isActive = gModelNormalActivity:IsPrivilegeActive(v.refId)
				activeInfo = giftData
			end
		end
	end

	local notActive = not isActive

	CS.ShowObject(self.mBtn1,notActive)
	CS.ShowObject(self.mBtn2,notActive)
	CS.ShowObject(self.mTag,isActive)

	local bubbleRoot = self.mBubbleRoot
	local timeText = self.mTimeText

	local showBubble = false

	if notActive then
		local btnList =
		{
			[1] = self.mBtn1,
			[2] = self.mBtn2,
		}

		for k,v in ipairs(btnList) do
			CS.ShowObject(v,false)
		end


		local showPos = 1
		local cnt = #gifts

		for k,v in ipairs(gifts) do

			--【T特权商城】删掉无用的参数和特权
			--local curShowBubble = gModelNormalActivity:CheckShowIosBubble(itemdata.refId,v.ref.refId)
			--if curShowBubble then
			--	showBubble = true
			--	showPos = k
			--end
			--self:InitGiftInfo(btnList[k],v,itemdata,curShowBubble)
			self:InitGiftInfo(btnList[k],v,itemdata,false)


		end


		--[[【T特权商城】删掉无用的参数和特权
		if showBubble then
			local anchorPos = nil
			if cnt == 1 then
				anchorPos = Vector2.New(0,-302)
			elseif cnt == 2 then
				if showPos == 1 then
					anchorPos = Vector2.New(-128,-302)
				else
					anchorPos = Vector2.New(122,-302)
				end
			end

			bubbleRoot.anchoredPosition = anchorPos
		end
		]]
	else
		local endTime = activeInfo.info.endTime
		if endTime == -1 then
			self:SetWndText(timeText,ccLngText(activeInfo.ref.moreText))
		else
			self._timeTextList[activeInfo.info.refId] = timeText
			if not self:IsTimerExist(self._timeKey)then
				self:SetTime()
				self:TimerStart(self._timeKey,1,false,-1)
			end
		end
	end

	local str = gifts[1] and ccLngText(gifts[1].ref.moreText)
	self:SetWndText(self.mIntro1,str)
	str = gifts[2] and ccLngText(gifts[2].ref.moreText)
	self:SetWndText(self.mIntro2,str)

	local instanceId = bubbleRoot:GetInstanceID()
	local seqCom = self:GetSeqCom()
	seqCom:DeleteSeq(instanceId)

	CS.ShowObject(bubbleRoot,showBubble)
	--[[【T特权商城】删掉无用的参数和特权
	if showBubble then
		local bubbleStr = ccLngText(gModelNormalActivity:GetBIActivityConfigRefByKey("returnBubbleText"))
		self:SetTextTile(bubbleRoot,bubbleStr)

		local seq = seqCom:CreateSeq(instanceId)
		bubbleRoot.localScale = Vector3.New(1,1,1)
		local tween = bubbleRoot:DOScale(Vector3.New(0.9,0.9,0.9),1)
		seq:Append(tween)
		seq:SetLoops(-1,Tweening.LoopType.Yoyo)
		seq:PlayForward()
	end
	]]--
end

function UIWishPrigeBuyPop:InitLinkContent()
	local showLink = false
    local showRestore = false
	local showBtnDiv = false
	local link1 = nil
	local link2 = nil

	if gLGameLanguage:IsForeignVietnamOrAmericaRegion() then
		if self:IsUsaRegionShowLink() then
			--删除欧美特权的
			--link1 = gModelNormalActivity:GetBIActivityConfigRefByKey("link3")
			--link2 = gModelNormalActivity:GetBIActivityConfigRefByKey("subscribeLink")
			--showLink = false
			--showBtnDiv = true
		end
	else
		--[[【T特权商城】删掉无用的参数和特权
		if self:IsIosTarget() then
			link1 = gModelNormalActivity:GetBIActivityConfigRefByKey("link1")
			link2 = gModelNormalActivity:GetBIActivityConfigRefByKey("link2")
			showLink = true
			showRestore = PRODUCT_G_VER == 1
		elseif self:IsHuaweiTarget() then
			link1 = gModelNormalActivity:GetBIActivityConfigRefByKey("huaweiLink1")
			link2 = gModelNormalActivity:GetBIActivityConfigRefByKey("huaweiLink2")
			showLink = true
		end
		]]--
	end

	if showBtnDiv then --海外全球显示这个
		self:SetWndButtonText(self.mPrivacyBtn, ccClientText(14219))
		self:SetWndButtonText(self.mChargeBtn, ccClientText(14220))
	end

	CS.ShowObject(self.mCharge,showLink)
	CS.ShowObject(self.mPrivacy,showLink)
	CS.ShowObject(self.mBtnContent, showBtnDiv)
    CS.ShowObject(self.mRestore,showRestore)
    if showRestore then
        local hyper = self:GetUIHyperText(self.mRestore)
        local str = hyper:AddHyper(ccClientText(14217),{func = function ()
            gLSdkImpl:CallMethod(LSdkMethod.CallSdkRestorePurchase)
        end})

        self:SetWndText(self.mRestore,str)
    end

	local isShowMgr = gModelNormalActivity:IsUSARegionShowAutoGiftMgr()
	CS.ShowObject(self.mManagerText, isShowMgr)
	if isShowMgr then
		local UIText = self.mManagerText
		local uiHyperText = self:GetUIHyperText(UIText)
		local str = ccClientText(14218)
		str = uiHyperText:AddHyper(str,{func = function()
			gLSdkImpl:CallMethod(LSdkMethod.DoSubDetails)
		end})
		self:SetWndText(UIText,str)
	end

	if not showLink then
		return
	end

	local hyperCreateFun = function(tran)
		if not CS.IsValidObject(tran) then
			return
		end
		return self:GetUIHyperText(tran)
	end

	local text = string.replace(link1, ccClientText(14211))
	local UIText = self.mPrivacy
	local wndName = self:GetWndName()
	local content = LUtil.CreateHyperWithValue(UIText,text,hyperCreateFun,function (data)
		--苹果订阅需要用sdk的内嵌浏览器打开
		if CS.IsOSIos() then
			gLSdkImpl:CallMethod(LSdkMethod.CallSdkOpenWebViewWithURLString,tostring(data.msg), text)
		else
			gModelChat:ClickHyper(data,wndName)
		end

	end)

	self:SetWndText(UIText,content)

	local textCharge = string.replace(link2, ccClientText(14212))
	UIText = self.mCharge
	content = LUtil.CreateHyperWithValue(UIText,textCharge,hyperCreateFun,function (data)
		if CS.IsOSIos() then
			gLSdkImpl:CallMethod(LSdkMethod.CallSdkOpenWebViewWithURLString,tostring(data.msg), textCharge)
		else
			gModelChat:ClickHyper(data,wndName)
		end
	end)
	self:SetWndText(UIText,content)
end

------------------------------------------------------------------
return UIWishPrigeBuyPop