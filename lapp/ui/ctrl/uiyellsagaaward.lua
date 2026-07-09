---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIYellSagaAward:LWnd
local UIYellSagaAward = LxWndClass("UIYellSagaAward", LWnd)

UIYellSagaAward.TYPE_NORMAL = 1
UIYellSagaAward.TYPE_ACTIVITY = 2



------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIYellSagaAward:UIYellSagaAward()
	---@type table<number,CommonIcon>
	self._uiCommonIconList = {}
	self._seqList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIYellSagaAward:OnWndClose()
	self:ClearTimer()

	if self._seqList then
		local seqList = self._seqList
		for k,v in pairs(self._seqList) do
			v:Kill(false)
			seqList[k] = nil
		end
	end
	if self._uiCommonIconList then
		self:ClearCommonIconList(self._uiCommonIconList)
		self._uiCommonIconList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIYellSagaAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIYellSagaAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitEvent()
	self:InitMsg()

	self:SetStaticContent()

	self:OnWndRefresh()
end

function UIYellSagaAward:InitEvent()
	self:SetWndClick(self.mAgainBtn,function() self:SendMsg() end)
	self:SetWndClick(self.mEnterBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mView,function()
		if not self._showList then
			printInfoNR("================================== 列表还没有显示")
			self._clickView = false
		end
		if self._clickView then return end
		self._clickView = true
		self:DestroyWndSpineByKey(self._zhaohuanKey)
		self:DestroyWndEffectByKey(self._fxuiZHKey)
		self:ClearTimer()
		self:ShowReward()
	end)
	self:SetWndClick(self.mView2,function()
		if not self._showList then
			printInfoNR("================================== 列表还没有显示")
			self._clickView = false
		end
		if self._clickView then return end
		self._clickView = true
		CS.ShowObject(self.mView2,false)
		CS.ShowObject(self.mView,true)
		self:DestroyWndEffectByKey(self._heartKey)
		self:ClearTimer()
		self:ShowReward()
	end)
	self:SetWndClick(self.mFenxiangBtn,function()
		self:OnClickShare()
	end)
	self:SetWndClick(self.mShareMask,function()
		CS.ShowObject(self.mShareMask,false)
	end)
end

function UIYellSagaAward:InitWndPara()
	self._itemList = self:GetWndArg("itemList")
	self._refId = self:GetWndArg("refId")
	self._haveUpStar = self:GetWndArg("haveUpStar") or true
	self._playTimes = self:GetWndArg("callNum")
	self._rankValue = self:GetWndArg("rankValue")
	self._callLogId = self:GetWndArg("callLogId")
	self._rank = self:GetWndArg("rank") or 0
	local sid = self:GetWndArg("sid")
	self._fixedReward = self:GetWndArg("fixedReward")

	self._wndType = self:GetWndArg("wndType") or UIYellSagaAward.TYPE_NORMAL

	self._sid = sid
	self._extractType = gModelCallHero:GetExtractType(self._refId)
	self._tipRefId = 110008
	if not sid then return end
	local activityDataS = gModelActivity:GetActivityBySid(sid)
	local activityDataW = gModelActivity:GetWebActivityDataById(sid)
	if not activityDataS or not activityDataW then return end
	local model = activityDataS.model
	local moreInfo = JSON.decode(activityDataS.moreInfo)
	local dataW = activityDataW.config
	local showBg = dataW.showBg
	self._tipRefId = dataW.tipRefId
	if LxUiHelper.IsImgPathValid(showBg) then
		self:SetWndEasyImage(self.mView,showBg)
	end
	local noEffModelList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_67] = true,
		[ModelActivity.MODEL_ACTIVITY_TYPE_68] = true
	}
	if noEffModelList[model] then
		self._first = false
	end
	local last
	if moreInfo.remainBuyNum then
		last = moreInfo.remainBuyNum
	else
		local alreadyCallNum = moreInfo.callNum or 0
		local goldTimes = moreInfo.goldTimes or 0
		last = goldTimes - alreadyCallNum
	end
	local desTips = dataW.diaCallLimitTips or ccClientText(20809)
	local str = string.replace(desTips,last)
	self:SetWndText(self.mCallDiamondTips,str)
end

function UIYellSagaAward:RefreshCostItemShow()
	local payNum = self._payNum
	if not payNum then
		return
	end
	local itemId = self._payRefId
	local haveNum = gModelItem:GetNumByRefId(itemId)

	local str = "<color=%s>%s/%s</color>"
	local color = "#ffffff"
	if haveNum < payNum then
		color = "#ff5151"
	end
	local haveNumStr = LUtil.NumberCoversion(haveNum)
	local needNumStr = LUtil.NumberCoversion(payNum)
	str = string.replace(str,color,haveNumStr,needNumStr)
	self:SetWndText(self.mPayNum,str)
end

function UIYellSagaAward:SendMsg()
	if self._canGo then return end
	if self._net then return end
	local playTime = self._playTimes

	local enterfunc = function()
		gModelHero:BuyHeroBag(self:GetWndName())
	end
	local leftFunc = function()
		FireEvent(EventNames.ON_MOJING_MAIN)
		GF.OpenWndBottom("UISagaSpirit",{page = 1})
		self:WndClose()
	end
	local isFull = gModelGeneral:IsFullHeroBag(playTime,leftFunc,enterfunc,nil,nil,self:GetWndName())
	if isFull then return end
	local _sid = self._sid
	if _sid then
		local isZS = false
		local callType = self._playTimes == 1 and 1 or 2
		if self._payRefId == 102001 then
			isZS = true
		end
		local func = function()
			if self._extractType == 1 and self._sendSacrifice then
				self._net = true
			end
			--gModelActivity:OnActivityDropGiftReq(_sid,self._activePageId,self._playTimes,callType)
			gModelActivity:GetCallDataBySid(_sid,self._activePageId,callType,self:GetWndName(),self._playTimes)
		end
		--if isZS then
		--	local activityCfg = gModelActivity:GetWebActivityDataById(_sid)
		--	if not activityCfg then return end
		--	local data = activityCfg.config
		--	local payNum,payName,payRefId
		--	local cost = playTime == 1 and data.costOne1 or data.costTen1
		--	local itemOneCost = data.goodsOne -- --抽1次购买的道具和数量
		--	local itemTenCost = data.goodsTen -- --抽10次购买的道具和数量
		--	local itemOneCostData = string.split(itemOneCost, '=')
		--	local itemTenCostData = string.split(itemTenCost, '=')
		--	if cost then
		--		local costList = string.split(cost,"=")
		--		if #costList > 0 then
		--			payNum = tonumber(costList[3])
		--			payNum = payNum .. gModelItem:GetNameByRefId(tonumber(costList[2]))
		--		end
		--		if playTime == 1 then
		--			payRefId = tonumber(itemOneCostData[2])
		--			payName = itemOneCostData[3]
		--		else
		--			payRefId = tonumber(itemTenCostData[2])
		--			payName = itemTenCostData[3]
		--		end
		--	end
		--	if not payNum then
		--		if func then func() end
		--		return
		--	end
        --
		--	payName = payName .. gModelItem:GetNameByRefId(payRefId)
		--	local tipRefId = self._tipRefId or 110008
		--	local tipPara = {refId = tipRefId,func = func,para = {payNum,payName,playTime},sid = _sid,consume=payNum}
		--	gModelGeneral:OpenUIOrdinTips(tipPara,true)
		--else
			if func then func() end
		--end
	else
		local type = 1
		if playTime == 10 then
			type = 2
		end
		local wndName = self:GetWndName()

		local refId = self._refId
		if refId ~= 0 then
			local refData = gModelCallHero:GetCallRefByRefId(refId)
			if not refData then
				printErrorN(string.format("no callRef refId",refId))

				return
			end
			if refData.extractType == 1 then
				gModelCallHero:SendCallHeroReq(refId,type,wndName,true)
			elseif refData.extractType == 2 then
				gModelCallHero:SendHeartCall(refId,type,wndName,true)
			else
				printErrorN(string.format("call type unknown type ",refData.type))
			end
		else
			gModelCallHero:SendIntegralCallHeroReq(refId,type,self._payRefId, wndName,true)
		end
	end
end


function UIYellSagaAward:ClearTimer()
	local timer = self._timer
	if timer then
		LxTimer.LoopTimeStop(timer)
		self._timer = nil
	end
end

function UIYellSagaAward:RefreshView()
	gModelCallHero:AutoSacrificeFunc()

	self:RefreshCanGoStatus()
	self:PlayYuanAni()
	local data =
	{
		trans = self.mGongxihuodeRoot,
		effName = "fx_ui_gongxihuode",
		effKey = "fx_ui_gongxihuode",
		bDefaultSorting = true,
		sortOrder = 1,
		endFunc = function()
			CS.ShowObject(self.mGongxihuodeRoot,true)
		end,
	}
	self:CreateWndEffect_Ex(data)
	CS.ShowObject(self.mAgainBtn,true)
	CS.ShowObject(self.mEnterBtn,true)
	CS.ShowObject(self.mBlockLine1,true)
	CS.ShowObject(self.mBlockLine2,true)
	local data = self._refData
    if data == nil then
		-- 积分召唤
        CS.ShowObject(self.mMinList,true)
        CS.ShowObject(self.mPropIcon,false)
		local integralNeedItem = GameTable.SummonConfigRef["integralNeedItem"]
		local strList = string.split(integralNeedItem,"=")
		local refId = tonumber(strList[2])
		local num = tonumber(strList[3])
		local haveNum = gModelItem:GetNumByRefId(refId)
		local str = "<color=%s>%s/%s</color>"
		local color = "#0fb93f"
		if haveNum < num then
			color = "#ff5151"
		end
		local haveNumStr = LUtil.NumberCoversion(haveNum)
		local needNumStr = LUtil.NumberCoversion(num)
		str = string.replace(str,color,haveNumStr,needNumStr)
		self:SetXUITextText(self.mPayNum,str)
        CS.ShowObject(self.mPayNum,true)
        self:SetXUITextText(self.mAgainBtnName,ccClientText(11617))
        self:InitMinScrollRect()
        return
    end
	local itemList = self._itemList
	local num = 0
	for k,v in pairs(itemList) do
		if v.itype == 2 then
			num = num + 1
		end
	end
	local showMin
	if self._extractType == 1 then
		showMin = num == 1
		CS.ShowObject(self.mMinList,showMin)
		CS.ShowObject(self.mMaxList,not showMin)

		local ouqi = self._rankValue and self._rankValue > 0 or false
		CS.ShowObject(self.mOuQiDiv,ouqi)
		if ouqi then
			self:SetWndText(self.mOuQiZhiTxt,self._rankValue)
			self:SetWndText(self.mOuQiZhiImgText, ccClientText(11681))
		end
		CS.ShowObject(self.mSurpassText,self._rank > 0)
		if self._rank > 0 then
			local value = string.format("%.1f",self._rank * 100)
			local txt = ccClientText(11651)
			self:SetWndText(self.mSurpassText,string.replace(txt,value.."%"))
		end
	else
		local number = table.keysize(itemList)
		showMin = number <= 4
		CS.ShowObject(self.mMinList,showMin)
		CS.ShowObject(self.mMaxList,not showMin)
		CS.ShowObject(self.mOuQiDiv,false)
	end
	local expend
	local callBtnTxt = {}
	local callAgainBtnTxt = data.callAgainBtnTxt
	if not string.isempty(callAgainBtnTxt) then
		callBtnTxt = string.split(callAgainBtnTxt,"=")
	end
	if showMin then
		self:SetXUITextText(self.mAgainBtnName,callBtnTxt[2] or ccClientText(11617))
		expend = data.oneExpend
	else
		self:SetXUITextText(self.mAgainBtnName,callBtnTxt[3] or ccClientText(11618))
		expend = data.tenExpend
	end

	local temp = string.split(expend, "|")
	local payRefId, payNum,haveNum
	if #temp == 1 then
		local tempdata = string.split(temp[1], "=")
		payRefId, payNum = tonumber(tempdata[2]), tonumber(tempdata[3])
		haveNum = gModelItem:GetNumByRefId(payRefId)
	else
		for i, v in ipairs(temp) do
			local tempdata = string.split(v, "=")
			local needRefId, needNum = tonumber(tempdata[2]), tonumber(tempdata[3])
			haveNum = gModelItem:GetNumByRefId(needRefId)
			if i == 1 and haveNum >= needNum then
				payRefId,payNum = needRefId,needNum
				break
			else
				payRefId,payNum = needRefId,needNum
			end
		end
	end

	local fixedReward = self._fixedReward
	local str = ""
	if fixedReward then
		local fixName = gModelItem:GetNameByRefId(fixedReward.itemId)
		str = string.replace(ccClientText(11619),fixName,fixedReward.itemNum)
	end


	self:SetXUITextText(self.mRewardTitle,str)
	CS.ShowObject(self.mRewardTitle,true)

	str = "<color=%s>%s/%s</color>"
	local color = "#ffffff"
	if haveNum < payNum then
		color = "#ff5151"
	end
	local haveNumStr = LUtil.NumberCoversion(haveNum)
	local needNumStr = LUtil.NumberCoversion(payNum)
	str = string.replace(str,color,haveNumStr,needNumStr)
	self:SetXUITextText(self.mPayNum,str)

	self._payRefId = payRefId
	self._payNum = payNum
	local icon = gModelItem:GetItemIconByRefId(payRefId)
	CS.ShowObject(self.mPropIcon,true)
	self:SetWndEasyImage(self.mPropIcon, icon)
	self:RefreshNumShow()
	if showMin then
		self:InitMinScrollRect()
	else
		self:InitList()
	end
end

function UIYellSagaAward:Run()
	CS.ShowObject(self.mAgainBtn,false)
	CS.ShowObject(self.mEnterBtn,false)
	if self._extractType ~= nil then
		if self._extractType == 1 then
			self:StarAni()
		else
			self:ClearTimer()
			self._timer = LxTimer.LoopTimeCall(function()
				CS.ShowObject(self.mShowView,true)
				CS.ShowObject(self.mView2,false)
				CS.ShowObject(self.mView,true)
				self:DestroyWndEffectByKey(self._heartKey)
				self:ClearTimer()
				self:ShowReward()
			end, 4, false, 1)
		end
	else
		self:StarAni()
	end
end

function UIYellSagaAward:InitList()
	local list = self._itemList or {}

	local uiList = self._uiList
	if not uiList then
		uiList = self:GetUIScroll("_uiRewardList")
		self._uiList = uiList
		uiList:Create(self.mMaxList, list, function(...)
			self:OnDrawRewardItem(...)
		end)
		uiList:EnableScroll(true)
	else
		uiList:RefreshList(list)
		local tuiList = uiList:GetList()
		tuiList:SetItemRootPosition(nil,0)
	end

	if not self._showList then
		self._showList = true
	end
end

function UIYellSagaAward:RefreshCanGoStatus()
	local len = gModelCallHero:GetHeroSacrificeNumAndList()
	self._sendSacrifice = len > 0
	if self._extractType == 1 and len > 0 then
		self._canGo = gModelHero:GetAutoSacrificeStatus()
	else
		self._canGo = false
	end
end

function UIYellSagaAward:SetItemList(itemList)
	self._itemList = itemList
end

function UIYellSagaAward:RefreshType1View()
	CS.ShowObject(self.mYuan,false)
	CS.ShowObject(self.mActivityImg,false)
	CS.ShowObject(self.mCallIcon,false)
	CS.ShowObject(self.mGongxihuodeRoot,false)
	CS.ShowObject(self.mBlockLine1,false)
	CS.ShowObject(self.mTitle,false)
	CS.ShowObject(self.mMinList,false)
	CS.ShowObject(self.mMaxList,false)
	CS.ShowObject(self.mBlockLine2,false)
	CS.ShowObject(self.mAgainBtn,false)
	CS.ShowObject(self.mEnterBtn,false)
end

function UIYellSagaAward:RefreshData()
	-- 本地表格数据
	if self._refId and self._refId ~= 0 then
		self._refData = gModelCallHero:GetCallRefByRefId(self._refId)
		self._extractType = self._refData.extractType
		if self._extractType == 2 then
			CS.ShowObject(self.mView2,true)
			CS.ShowObject(self.mView,false)
			if self._refData then
				local effectName = self._callEffectList[self._refData.srot]
				self._heartKey = effectName
				self:CreateWndEffect(self.mHeartEffRoot,effectName,effectName,100,false,false)
			end
		end
	end
	local soundId
	-- 活动数据
	local _sid = self._sid
	if _sid then
		local activityCfg = gModelActivity:GetWebActivityDataById(_sid)
		local moreInfo = activityCfg.config
		if not string.isempty(moreInfo.costOneSound) and not string.isempty(moreInfo.costTenSound)then
			soundId = self._playTimes == 1 and moreInfo.costOneSound or moreInfo.costTenSound
		end
		if moreInfo.oneExpend ~= nil then
			--活动召唤
			self._activePageId = 1
			self._refData = {
				oneExpend = moreInfo.oneExpend,
				tenExpend = moreInfo.tenExpend,
				getBackground = moreInfo.getBackground,
				backgroundIcon = "callhero5_bg_2",
			}
		-- elseif moreInfo.eModel == ModelActivity.MODEL_NEWYEAR then
		-- 	--新春召唤
		-- 	self._activePageId = 7
		-- 	self._refData = {
		-- 		oneExpend = moreInfo.costOne2.."|"..moreInfo.costOne1,
		-- 		tenExpend = moreInfo.costTen2.."|"..moreInfo.costTen1,
		-- 		backgroundIcon = moreInfo.callMirror,
		-- 	}
		-- elseif moreInfo.eModel == ModelActivity.MODEL_ACTIVITY_TYPE_67 then
		-- 	--快乐国
		-- 	self._activePageId = ModelActivity.HAPPY_COUNTRY_7
		-- 	self._refData = {
		-- 		oneExpend = moreInfo.costOne2.."|"..moreInfo.costOne1,
		-- 		tenExpend = moreInfo.costTen2.."|"..moreInfo.costTen1,
		-- 		callAgainBtnTxt = moreInfo.callAgainBtnTxt,
		-- 	}
		elseif moreInfo.eModel == ModelActivity.MODEL_ACTIVITY_TYPE_68 then
			--国王大街
			self._activePageId = ModelActivity.KING_STREET_3
			self._refData = {
				oneExpend = moreInfo.costOne2.."|"..moreInfo.costOne1,
				tenExpend = moreInfo.costTen2.."|"..moreInfo.costTen1,
				callAgainBtnTxt = moreInfo.callAgainBtnTxt,
			}
		else
			return
		end
	end


	if self._extractType == 1 then
		soundId = LSoundConst.TRIGGER_CALL_MIRROR
	elseif self._extractType == 2 then
		soundId = LSoundConst.TRIGGER_CALL_MIRROR
	end
	if soundId then
		LxUiHelper.PlayAudioSoundName(soundId)
	end
end

function UIYellSagaAward:InitData()


	self._activePageId = nil
	self._first = true
	self._callEffectList = {
		"fx_ui_XLZH_zhaohuan_huo",
		"fx_ui_XLZH_zhaohuan_shui",
		"fx_ui_XLZH_zhaohuan_feng",
		"fx_ui_XLZH_zhaohuan_guangan",
	}

	self._clickView = false
	self._showList = false

	self._playAni = true
	self._showFenXiang = false

	self._fxuiZHKey = "fx_ui_ZH"
	self._zhaohuanKey = "zhaohuan"

	--self:RefreshData()


	self._playKey = "moveYuan"
	self._heroEffectList = {
		[4] = "fx_ui_ZHJS_yingxiong_zise",
		[5] = "fx_ui_ZHJS_yingxiong_chengse",
	}
	self._net = false
	self._isUSARegion = gLGameLanguage:IsUSARegion()
	self:RefreshCanGoStatus()
end

function UIYellSagaAward:ShowReward()
	local wndName = self:GetWndName()
	self:SendGuideReadyEvent(wndName)
	--self._delayFinishEvent = true
	CS.ShowObject(self.mStartView,false)
	CS.ShowObject(self.mShowView,true)
	if self._haveUpStar then
		self:ShowUpHeroList()
	else
		self._clickView = true
		self:RefreshView()
	end
	self:CreateWndEffect(self.mTopView,"fx_ui_ZHJS_lanse_xingdian","fx_ui_ZHJS_lanse_xingdian",100,false,false)
	self:CreateWndEffect(self.mView,"fx_ui_ZHJS_lanse_BJxingguang","fx_ui_ZHJS_lanse_BJxingguang",100,false,false)
	self:ClearTimer()
end

function UIYellSagaAward:OnAwake()
	LWnd.OnAwake(self)
	self._delayFinishEvent = true
end

function UIYellSagaAward:StarAni()
	self:ClearTimer()
	if self._first then
		CS.ShowObject(self.mStartView,true)
		local data = self._refData
		if data ~= nil then
			local bg = data.getBackground
			if bg and not string.isempty(bg) then
				self:SetWndEasyImage(self.mView,bg)
			end
			local backgroundIcon = data.backgroundIcon
			if not string.isempty(backgroundIcon) then
				self:SetWndEasyImage(self.mCallIcon,backgroundIcon,function()
					CS.ShowObject(self.mCallIcon,true)
				end,true)
				CS.ShowObject(self.mActivityImg,self._sid ~= nil)
			end
		else
			CS.ShowObject(self.mCallIcon,true)
		end
		self:CreateWndEffect(self.mEffectRoot,self._fxuiZHKey,self._fxuiZHKey,100,false,false)
		self:CreateWndSpine(self.mBoLiRoot,self._zhaohuanKey,self._zhaohuanKey,false,function(dpSpine)
			dpSpine:PlayAnimation(0,"attack1",false)
		end)
		self._first = false

		self._timer = LxTimer.LoopTimeCall(function()
			self:ShowReward()
		end, 4, false, 1)
	else
		self:ShowReward()
	end
end

function UIYellSagaAward:OnClickShare()
	local data = {
		root = self.mFenxiangBtn,
		shareType = ModelChat.CHATSHARE_CALL,
		shareData = tostring(self._callLogId)
	}
	gModelGeneral:OpenShareTip(data)
end

function UIYellSagaAward:ShowUpHeroList()
	local upHeroList = {}
	for i,v in ipairs(self._itemList) do
		local itype = v.itype
		if itype == 2 then
			local heroRefId = nil
			if self._wndType == UIYellSagaAward.TYPE_ACTIVITY then
				heroRefId = v.refId
			else
				heroRefId = v.itemId
			end
			local initStar = gModelHero:GetHeroInitStarByRefId(heroRefId)
			if self._extractType == 2 then
				if initStar > 4 then
					table.insert(upHeroList,{refId = heroRefId})
				end
			else
				if initStar >= 4 then
					table.insert(upHeroList,{refId = heroRefId})
				end
			end
		end
	end
	local len = #upHeroList
	self._upHeroList = upHeroList
	local func = function()
		self._clickView = true
		self:RefreshView()
	end

	if len > 0 then
		gModelGeneral:ShowUpHero(self._upHeroList, func)
	else
		func()
	end
end

function UIYellSagaAward:RefreshNumShow()
	local refId = self._refId
	CS.ShowObject(self.mPropMag,true)
	self:SetWndText(self.mFreeNum,"")
	if refId then
		local _callHeroData = gModelCallHero:GetCallHeroData()
		local callHero = _callHeroData[refId]
		if callHero and callHero.freeNum >= self._playTimes then
			CS.ShowObject(self.mPropMag,false)
			local freeNumStr = gModelActivity:GetPrivilegeFreeNumStr()
			local time = gModelBackflow:GetResidueTime()
			local isModelOpen = time > 0
			if isModelOpen then
				freeNumStr = ccClientText(23517)
			end
			self:SetWndText(self.mFreeNum,string.replace(freeNumStr,callHero.freeNum))
		end
	end
end

function UIYellSagaAward:OnDrawActItem(list,item,itemdata,itempos)
	local aniTrans = CS.FindTrans(item, "CommonUI")
	local iconTrans = CS.FindTrans(aniTrans, "Icon")

	local InstanceID = item:GetInstanceID()
	local baseClass =self:GetCommonIcon(InstanceID) --self._uiCommonIconList[InstanceID]
	baseClass:Create(iconTrans)
	baseClass:SetRewardDetailItem(itemdata)
	baseClass:EnableShowNum(true)
	baseClass:ShowSacrificeImg()
	baseClass:DoApply()
	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		gModelGeneral:ShowRewardDetailTip(itemdata)
	end)
end

function UIYellSagaAward:SetStaticContent()
	self:SetXUITextText(self.mEnterBtnName,ccClientText(10102))

end

function UIYellSagaAward:PlayAni(item, itemData, itemPos)
	local itype = itemData.itype
	local refId = nil
	if self._wndType == UIYellSagaAward.TYPE_ACTIVITY then
		refId = itemData.refId
	else
		refId = itemData.itemId
	end
	local instanceId = item:GetInstanceID()
	local seq = self._seqList[instanceId]
	if seq then
		seq:Kill(false)
		self._seqList[instanceId] = nil
	end

	local aniTrans = CS.FindTrans(item, "CommonUI")

	if not self._playAni or itemData.isPlayAni then
		aniTrans.localScale = Vector3.one
		return
	end

	itemData.isPlayAni = true

	aniTrans.localScale = Vector3.zero
	local dtSequence = YXTween.TweenSequenceIns()
	self._seqList[instanceId] = dtSequence

	local playTime = 0.2
	local startT = itemPos * playTime
	local ani1 = aniTrans:DOScale(1, playTime)

	dtSequence:AppendInterval(startT)
	dtSequence:Append(ani1)

	dtSequence:OnComplete(function()
		self._seqList[instanceId] = nil
		local effScaleSize = 100
		if itype == LItemTypeConst.TYPE_HERO then
			local eff
			--[[            if gModelHero:CheckIsShowHeroQualityForeign() then
                        else
                            local initStar = gModelHero:GetHeroInitStarByRefId(refId)
                            if initStar >= 4 then
                                LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_HERO_NORMAL)
                            end
                            eff = self._heroEffectList[initStar]
                        end]]
			local heroRef  = gModelHero:GetHeroRef(refId)
			if heroRef then
				local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
				if qualityRef then
					local heroCallFxList = string.split(qualityRef.heroCallFx, '=')
					eff = heroCallFxList[1]
					local fxEffSize = heroCallFxList[2]
					if not string.isempty(fxEffSize) then
						effScaleSize = tonumber(fxEffSize) * 100
					end
				end
			end
			local initStar = gModelHero:GetHeroInitStarByRefId(refId)
			if initStar >= 4 then
				LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_HERO_NORMAL)
			end
			if not eff then
				eff = self._heroEffectList[initStar]
			end

			if item then
				local uicommonTrans = CS.FindTrans(item,"effectRoot")
				if eff and uicommonTrans then
					self:CreateWndEffect(uicommonTrans,eff,instanceId,effScaleSize,false,false)
				end
			end
		end
	end)

	dtSequence:PlayForward()
end

function UIYellSagaAward:OnWndRefresh()
	self:InitWndPara()
	self:ReSetView()
	self:RefreshData()
	self:Run()
end

function UIYellSagaAward:PlayYuanAni()
	CS.ShowObject(self.mYuan,true)
	local seqTween
	self:TweenSeqKill(self._playKey)
	if not seqTween then
		local showTime = 18
		seqTween = self:TweenSeqCreate(self._playKey,function(seq)
			local moveZ = self.mYuan.transform:DORotate(Vector3.New(0,0,180),showTime)
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

function UIYellSagaAward:OnDrawRewardItem(list, item, itemdata, itempos, fromHeadTail)
	if self._wndType == UIYellSagaAward.TYPE_ACTIVITY then
		self:OnDrawActItem(list,item,itemdata,itempos)
	else
		self:OnSetItem(list, item, itemdata, itempos)
	end

	local instanceId = item:GetInstanceID()
	self:DestroyWndEffectByKey(instanceId)
	self:PlayAni(item, itemdata, itempos)
end

function UIYellSagaAward:InitMsg()
	self:WndNetMsgRecv(LProtoIds.MagicResp,function(pb,ret)
		self._net = false
		self:RefreshNumShow()
	end)
	self:WndNetMsgRecv(LProtoIds.HeroSacrificeResp,function(pb,ret)
		self._canGo = false
	end)

	self:WndEventRecv(EventNames.On_Item_Change,function ()
		self:RefreshCostItemShow()
	end)
end

function UIYellSagaAward:ReSetView()
	self:DestroyWndEffectAll()
	self._clickView = false
	self._showList = false
	self._playAni = true
	self._showFenXiang = false

	if self._extractType then
		if self._extractType == 1 then
			self:RefreshType1View()
		elseif self._extractType == 2 then
			self:RefreshType2View()
		end
	else
		self:RefreshType1View()
	end
	CS.ShowObject(self.mOuQiDiv,false)
	CS.ShowObject(self.mShareMask,false)
	CS.ShowObject(self.mRewardTitle,false)
end

function UIYellSagaAward:InitMinScrollRect()
	local itemRoot = self.mItemRoot
	local itemTransList = {}
	self._itemTransList = itemTransList
	local itemData = self._itemList
	if not self._showList then
		self._showList = true
	end
	for i = 1,#itemData do
		local item = CS.FindTrans(itemRoot,"Item"..i)
		if item then
			local instanceId = item:GetInstanceID()
			self:DestroyWndEffectByKey(instanceId)
			itemTransList[i] = item
			CS.ShowObject(item,true)
			local data = itemData[i]
			if self._wndType == UIYellSagaAward.TYPE_ACTIVITY then
				self:OnDrawActItem(nil,item,data,i)
			else
				self:OnSetItem(nil, item, data, i)

			end
			self:PlayAni(item, data, i)
		end
	end
end

function UIYellSagaAward:RefreshType2View()
	CS.ShowObject(self.mView2,false)
end

function UIYellSagaAward:OnSetItem(list, item, itemData, itemPos)
	local refId = itemData.itemId
	local itype = itemData.itype
	local count = itemData.count
	local aniTrans = CS.FindTrans(item, "CommonUI")
	local iconTrans = CS.FindTrans(aniTrans, "Icon")

	local InstanceID = item:GetInstanceID()
	local baseClass =self:GetCommonIcon(InstanceID) --self._uiCommonIconList[InstanceID]
	baseClass:Create(iconTrans)
	baseClass:SetCommonReward(itype, refId, count)
	baseClass:EnableShowNum(true)
	baseClass:ShowSacrificeImg()
	baseClass:DoApply()
	local formatData =
	{
		itemId = refId,
		itemType = itype,
		itemNum = count,
	}

	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		if itype == LItemTypeConst.TYPE_ITEM then
			gModelGeneral:OpenItemInfoTipTop(refId,count)
		elseif itype == LItemTypeConst.TYPE_HERO then
			gModelGeneral:OpenHeroSimpleTip(refId,true)
		elseif itype == LItemTypeConst.TYPE_EQUIP then
			gModelGeneral:OpenEquipInfoTip(refId,nil,count,true, nil, nil, true)
		elseif itype == LItemTypeConst.TYPE_OUTFIT then
			gModelGeneral:ShowCommonItemTipWnd(formatData)
		end
	end)
end
------------------------------------------------------------------
return UIYellSagaAward



