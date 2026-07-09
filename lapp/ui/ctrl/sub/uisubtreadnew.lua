---
--- Created by LCM.
--- DateTime: 2024/3/6 10:55:43
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubTreadNew:LChildWnd
local UISubTreadNew = LxWndClass("UISubTreadNew", LChildWnd)

local Tweening = DG.Tweening

--- 1：使用箱子特效
UISubTreadNew.USE_BOX_TYPE = 2

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubTreadNew:UISubTreadNew()
	self._countDownTimer = "_countDownTimer"
	self._treasureAniKey = "treasureAniKey"

	self._spineBoxKey = "spineBoxKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubTreadNew:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubTreadNew:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubTreadNew:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:CreateWndSpine(self.mSpRoot,"Lingwuzhaohuan",self._treasureAniKey,false,function()
		self:RefreshTreaHot()
	end)

	if UISubTreadNew.USE_BOX_TYPE ~= 1 then
		local curPos = self.mBoxEffect.localPosition
		self.mBoxEffect.localPosition = Vector3(curPos.x,curPos.y + 37,curPos.z)
		self:CreateWndSpine(self.mBoxEffect,"Shiguangbaozanxiangzi_huang",self._spineBoxKey,false,function()
			self:RefreshBoxInfo()
		end)
	end

	self:InitCallBtnInfo()
	self:InitText()
	self:CheckGiftBtnIsShow()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshUI()
	self:RefreshActShow()
	gModelTreaFind:ReqData()
end

function UISubTreadNew:OnClickMinCallBtnFunc()
	self:OnClickCallBtnFunc(ModelTreaFind.FINDTREA_TYPE_1)
end

function UISubTreadNew:OnClickCallBtnFunc(callType)
	local wndName = self:GetParentWndName()
	gModelTreaFind:SendFindReq(callType,wndName)
end

function UISubTreadNew:SetFindBtn(info)
	local btnType = info.btnType

	local isFree = false
	local btnImg
	local btnTextId
	local limitStr = ""
	local showLimitStr = false
	if btnType == ModelTreaFind.FINDTREA_TYPE_1 then
		local freeCnt = gModelTreaFind:GetFreeFindCnt()
		isFree = freeCnt > 0
		btnImg = isFree and "treasure1_txt_7" or "treasure1_txt_5"
		btnTextId = isFree and 19426 or 19427
	elseif btnType == ModelTreaFind.FINDTREA_TYPE_2 then
		btnImg = "treasure1_txt_6"
		btnTextId = 19428

		limitStr = ccClientText(19418)
		showLimitStr = true
	end
	local isForeign = gLGameLanguage:IsForeignRegion()
	if isForeign then
		self:SetWndText(info.BtnNameTrans, ccClientText(btnTextId))
		self:InitTextLineWithLanguage(info.BtnNameTrans, -30)
		if gLGameLanguage:IsJapanRegion() then
			self:InitTextSizeWithLanguage(info.BtnNameTrans, -6)
		end
	else
		self:SetWndEasyImage(info.BtnImgTrans,btnImg)
	end
	CS.ShowObject(info.BtnImgTrans, not isForeign)
	CS.ShowObject(info.BtnNameTrans,  isForeign)


	CS.ShowObject(info.RedPointTrans,isFree)

	local LimitTxtTrans = info.LimitTxtTrans
	self:SetWndText(LimitTxtTrans,limitStr)
	self:InitTextLineWithLanguage(LimitTxtTrans, -30)
	CS.ShowObject(LimitTxtTrans,showLimitStr)

	local isPay = not isFree
	if isPay then
		local findCost = gModelTreaFind:GetFindCost(btnType)
		local itemId = findCost.itemId
		local itemNum = findCost.itemNum
		local own = gModelItem:GetNumByRefId(findCost.itemId)
		if own < findCost.itemNum then
			local diaCost = gModelTreaFind:GetFindDiaCost(btnType)
			itemId = diaCost.itemId
			itemNum = diaCost.itemNum
		end
		local iconPath = gModelItem:GetItemImgByRefId(itemId)
		self:SetWndEasyImage(info.IconImgTrans,iconPath)

		local itemNumStr = LUtil.NumberCoversion(itemNum)
		self:SetWndText(info.NumTxtTrans,itemNumStr)
	end
	CS.ShowObject(info.PayDivTrans,isPay)
end

function UISubTreadNew:OnFindTreasureInfoResp()
	self:RefreshUI()
	self:RefreshBubble()
	self:CheckGiftBtnRedPoint()
end

function UISubTreadNew:InitText()
	self:SetTextTile(self.mDetailsBtn,ccClientText(26008))
	self:SetTextTile(self.mLogBtn,ccClientText(19435))
	self:SetTextTile(self.mShopBtn,ccClientText(10362))
	self:SetTextTile(self.mGiftBtn,ccClientText(27751))
	self:SetWndText(self.mHotTxt,ccClientText(27805))
end

function UISubTreadNew:ShowActContent()
	local data = gModelActivity:GetWebActivityDataById(self._sid)
	if not data then return end
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local infoData = data.config
	local title = activityData.title or ""
	self:SetWndClick(self.mHotHelpBtn,function ()
		GF.OpenWndUp("UIBzTips",{title = title, text = infoData.helpTipsContent1})
	end,LSoundConst.CLICK_ERROR_COMMON)


	local rewards = LxDataHelper.ParseItem(infoData.rewards1)
	local itemdata = rewards[1]
	if not itemdata then return end

	self:CreateCommonIconImpl(self.mItemicon,itemdata,{showNum = false})

	local itemName = gModelItem:GetItemNameRichText(itemdata.itemId)
	self:SetWndText(self.mItemName,itemName)
	self:InitTextLineWithLanguage(self.mItemName, -30)

	local cfgNum = infoData.specialRewardNum
	local text1 = infoData.bubbleTxt1
	local text2 = infoData.bubbleTxt2

	self._actCfgNum = cfgNum

	self:SetWndClick(self.mBubble,function ()
		self:ShowActTip(cfgNum,text1,text2)
	end)

	self._hasAct = true
	self:RefreshBubble()
end

function UISubTreadNew:InitMsg()
	self:WndNetMsgRecv(LProtoIds.FindTreasureInfoResp,function ()
		self:OnFindTreasureInfoResp()
	end)
	self:WndNetMsgRecv(LProtoIds.TreasureDropGiftResp,function ()
		self:OnTreasureDropGiftResp()
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_LIST_CHANGE,function ()
		self:RefreshTreaHot()
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function ()
		self:RefreshFindCallBtn()
		self:RefreshBoxInfo()
		self:InitNeedAddItemList()
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		self:OnActivityConfigData(data,sid)
	end)
end

function UISubTreadNew:SetCountDown()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local endTime = activityData.endTime
	local str = ""
	if endTime == 0 then
		str = ccClientText(14300) --"永久"
		self:TimerStop(self._countDownTimer)
	else
		local timeSpan = endTime - GetTimestamp()
		if timeSpan <= 0 then
			str = ccClientText(14301) --"活动已结束"
			self:TimerStop(self._countDownTimer)
		else
			str = self:FormatTimeSpan(timeSpan)
		end
	end
	self:SetWndText(self.mHotTimeTxt,str)
end

function UISubTreadNew:RefreshUI()
	self:RefreshFindCallBtn()
	self:RefreshLimitTxt()
	self:RefreshBoxInfo()
	self:RefreshNumInfo()
	self:RefreshTreaHot()
	self:InitNeedAddItemList()
end

function UISubTreadNew:RefreshBubble()
	local seqCom = self:GetSeqCom()
	local aniKey = "floatTween"
	if not self._hasAct then
		seqCom:DeleteSeq(aniKey)
		return
	end

	local cfgNum = self._actCfgNum
	local text = self:FindWndTrans(self.mBubble,"UIText")
	local actCnt = gModelTreaFind:GetActivityCnt()
	if not actCnt then return end
	local leftNum = cfgNum - actCnt
	local str = ""
	if leftNum > 0 then
		str = tostring(leftNum)
	else
		str = "UP"
	end
	self:SetWndText(text,str)


	self.mBubble.localPosition = Vector3.New(54,40,0)
	local seq = seqCom:CreateSeq(aniKey)
	local tween = self.mBubble:DOLocalMoveY(10,1):SetRelative(true)
	seq:Append(tween)
	seq:SetLoops(-1,Tweening.LoopType.Yoyo)
	seq:PlayForward()
end

function UISubTreadNew:OnClickBoxBtnFunc()
	local boxCfg = gModelTreaFind:GetBoxRewardConfig()
	if not boxCfg then return end
	local need = boxCfg.need
	local item = LxDataHelper.ParseItem_3(need)
	local own = gModelItem:GetNumByRefId(item.itemId)
	if own >= item.itemNum then
		gModelTreaFind:OnFindTreasureRewardReq()
	else
		GF.OpenWnd("UITreadBoxInfo")
	end
end

function UISubTreadNew:ShowActAdd(data)
	local num,text =data.config.treasureFree,data.config.treasureFreeName
	if not num or not text then
		return
	end
	local str = string.replace(text,num)
	self:SetWndText(self.mActNum,str)
	CS.ShowObject(self.mActUp,true)
end

function UISubTreadNew:OnActivityConfigData(data,sid)
	if sid == self._actBuffSid then
		self:ShowActAdd(data)
	elseif sid == self._sid then
		self:ShowActContent()
	end
end

function UISubTreadNew:OnClickCloseHotBtnFunc()
	local isOpen = gModelTreaFind:GetTreaHotOpen()
	local newValue = not isOpen
	if newValue then
		local value = gModelTreaFind:SetTreaHotOpen(newValue)
		if value then
			local str = ccClientText(19425) -- "成功开启热点，热点宝物100%出"
			GF.ShowMessage(str)
			self:RefreshTreaHot()
		end
	else
		local para =
		{
			refId = 52401,
			func = function()
				local str =ccClientText(19431) -- "成功关闭热点"
				GF.ShowMessage(str)
				gModelTreaFind:SetTreaHotOpen(newValue)
				if not self:IsWndClosed() then
					self:RefreshTreaHot()
				end
			end
		}

		gModelGeneral:OpenUIOrdinTips(para)
	end
end

function UISubTreadNew:OnClickLogBtnFunc()
	GF.OpenWnd("UITreadRecord")
end

function UISubTreadNew:RefreshShow(actOpen)
	actOpen = actOpen and true or false
	local showBg = actOpen and "treasure1_bg_big_4" or "treasure1_bg_big_3"
	self:SetWndEasyImage(self.mBg,showBg)

	local showPanBg = actOpen and "treasure1_frame_4_2" or "treasure1_frame_4_1"
	self:SetWndEasyImage(self.mPanImg,showPanBg)

	local showStarBg = actOpen and "treasure1_star_ui_2" or "treasure1_star_ui_1"
	self:SetWndEasyImage(self.mStarImg,showStarBg)

	local idleName = actOpen and "huang_loop" or "lan_loop"
	local spine = self:FindWndSpineByKey(self._treasureAniKey)
	if spine then
		spine:PlayAnimationSolid(idleName,true)
	end

	CS.ShowObject(self.mNormalImg,not actOpen)
end

function UISubTreadNew:CheckGiftBtnIsShow()
	--local status = gModelTreasure:CheckFindGiftStatus()
	local status =false
	CS.ShowObject(self.mGiftBtn,status)
	if status then
		self:CheckGiftBtnRedPoint()
	end
end

function UISubTreadNew:RefreshActShow()
	CS.ShowObject(self.mActUp,false)
	local actBuffData = gModelActivity:GetActivityExtraData(ModelActivity.COMMONRANK,{"treasureFree"})
	if not actBuffData or not actBuffData.sid then
		return
	end

	self._actBuffSid = actBuffData.sid
	gModelActivity:ReqActivityConfigData(actBuffData.sid)
end

function UISubTreadNew:OnClickMaxCallBtnFunc()
	self:OnClickCallBtnFunc(ModelTreaFind.FINDTREA_TYPE_2)
end

function UISubTreadNew:RefreshFindCallBtn()
	if not self._callBtnInfoList then
		self:InitCallBtnInfo()
	end
	local callBtnInfoList = self._callBtnInfoList
	for i,v in ipairs(callBtnInfoList) do
		self:SetFindBtn(v)
	end
end

function UISubTreadNew:CheckGiftBtnRedPoint()
	--local status = gModelTreasure:CheckFindGiftRedPoint()
	local status =false
	local redPointTrans = self:FindWndTrans(self.mGiftBtn,"redPoint")
	CS.ShowObject(redPointTrans,status)
end

function UISubTreadNew:InitNeedAddItemList()
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

function UISubTreadNew:OnClickAddBtnFunc(itemdata)
	gModelGeneral:OpenGetWayWnd({itemId = itemdata.itemId,srcWnd = self:GetParentWndName()})
end

function UISubTreadNew:OnClickTipFunc(show)
	CS.ShowObject(self.mTip,show)
end

function UISubTreadNew:InitEvent()
    self:SetWndClick(self.mCloseHotBtn,function() self:OnClickCloseHotBtnFunc() end)
    self:SetWndClick(self.mDetailsBtn,function() self:OnClickDetailsBtnFunc() end)
    self:SetWndClick(self.mLogBtn,function() self:OnClickLogBtnFunc() end)
    self:SetWndClick(self.mShopBtn,function() self:OnClickShopBtnFunc() end)
    self:SetWndClick(self.mMinCallBtn,function() self:OnClickMinCallBtnFunc() end)
    self:SetWndClick(self.mMaxCallBtn,function() self:OnClickMaxCallBtnFunc() end)
    self:SetWndClick(self.mBoxBtn,function() self:OnClickBoxBtnFunc() end)
	self:SetWndClick(self.mTip,function () self:OnClickTipFunc(false) end)
	self:SetWndClick(self.mGiftBtn,function () self:OnClickGiftBtn() end)
end

function UISubTreadNew:OnClickDetailsBtnFunc()
	--GF.OpenWnd("UITreadRule")
	GF.OpenWnd("UIYellHRew",{viewType = 4})
end

function UISubTreadNew:InitCallBtnInfo()
	local callBtnList = {
		{
			trans = self.mMinCallBtn,
			btnType = ModelTreaFind.FINDTREA_TYPE_1,
			effName = "fx_ui_putongzhaohuan_04",
		},
		{
			trans = self.mMaxCallBtn,
			btnType = ModelTreaFind.FINDTREA_TYPE_2,
			effName = "fx_ui_putongzhaohuan_05",
		},
	}

	local callBtnInfoList = {}
	for i,v in ipairs(callBtnList) do
		local callBtnInfo = self:GetCallBtnInfo(v)
		table.insert(callBtnInfoList,callBtnInfo)
	end
	self._callBtnInfoList = callBtnInfoList
end

function UISubTreadNew:InitData()
end

function UISubTreadNew:RefreshTreaHot()
	local isOpen = gModelTreaFind:GetTreaHotOpen()
	local state = isOpen and 1 or 0

	self:RefreshShow(isOpen)

	local effect = "fx_xunbao_redian"
	if isOpen then
		self:CreateWndEffect(self.mHotTreaEffRoot,effect,effect,100,false,false,2)
	end
	CS.ShowObject(self.mHotTreaEffRoot,isOpen)

	-- local activityList = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_TREASURE_HOT,ModelActivity.STATUS_VALID)
	local activityList = {}
	local activity = activityList[1]
	local showOpenBtn = true
	if not activity then
		showOpenBtn = false
	end
	CS.ShowObject(self.mCloseHotBtn,showOpenBtn)

	local openHotStatus = state == 1

	local btImgPath = openHotStatus and "treasure1_bg_big_4" or "treasure1_bg_big_3"
	self:SetWndEasyImage(self.mBg,btImgPath)

	local imgPath = openHotStatus and "treasure1_txt_2" or "treasure1_txt_1"
	self:SetWndEasyImage(self.mOpenHotTreaImg,imgPath)

	CS.ShowObject(self.mHotTreaArea,isOpen)
	if not isOpen then return end

	self._sid = activity.sid
	self:SetCountDown()
	self:TimerStop(self._countDownTimer)
	self:TimerStart(self._countDownTimer,1,false,-1)

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UISubTreadNew:OnClickShopBtnFunc()
	local jumpId = gModelTreaFind:GetPara("shopJumpId")
	local parent = self:GetParentWnd()
	local wndName = parent:GetWndName()
	gModelFunctionOpen:Jump(jumpId,wndName)
end

function UISubTreadNew:ShowActTip(cfgNum,text1,text2)
	local actCnt = gModelTreaFind:GetActivityCnt()
	if not text1 or not text2 then
		return
	end
	local leftNum = cfgNum - actCnt
	local str = ""
	if leftNum > 0 then
		str = string.replace(text1,leftNum)
	else
		str = text2
	end
	self:SetWndText(self.mTipText,str)
	self:OnClickTipFunc(true)
end

function UISubTreadNew:RefreshLimitTxt()
	local str = ccClientText(19432) -- "<#d2730f>橙色</color>宝物最多还需要<#feeba7>%s</color>次"
	local para = gModelTreaFind:GetPara("objectForeshow1")
	local leftTimes = gModelTreaFind:GetLeftTimes({para})
	local showStr = string.replace(str,leftTimes)
	local isShow = not (gLGameLanguage:IsUSARegion() or gLGameLanguage:IsKoreaRegion())
	CS.ShowObject(self.mDescTxt, isShow)
	if not isShow then return end
	self:SetWndText(self.mDescTxt,showStr)
	self:InitTextLineWithLanguage(self.mDescTxt,-30)
end

function UISubTreadNew:OnTimer(key)
	if key == self._countDownTimer then
		self:SetCountDown()
	end
end

function UISubTreadNew:OnClickGiftBtn()
	--GF.OpenWnd("WndTreasureGiftBuy",{giftType = 2})
end

function UISubTreadNew:CreateBtnEff(trans,effName)
	local key = trans:GetInstanceID()
	self:CreateWndEffect(trans,effName,key,100,false,false)
end

function UISubTreadNew:OnTreasureDropGiftResp()
	self:CheckGiftBtnIsShow()
end

function UISubTreadNew:RefreshBoxInfo()
	local boxCfg = gModelTreaFind:GetBoxRewardConfig()
	if not boxCfg then return end
	local item = LxDataHelper.ParseItem_3(boxCfg.need)
	local own = gModelItem:GetNumByRefId(item.itemId)
	local itemNum = item.itemNum
	local progress = own / itemNum
	progress = Mathf.Clamp(progress,0,1)
	LxUiHelper.SetProgress(self.mJinDuTiao,progress)

	local showStr = string.format("%s/%s",own,itemNum)
	self:SetWndText(self.mJinDuTxt,showStr)


	local showEff = own >= itemNum
	local showEffRoot = false
	local showImg = false
	if UISubTreadNew.USE_BOX_TYPE == 1 then
		if showEff then
			local effectKey = "fx_baoxiang_paiweisai01"
			self:CreateWndEffect(self.mBoxEffect,effectKey,effectKey,100,false,false,2)
		end
		showEffRoot = showEff
		showImg = not showEff
	else
		local dpSpine = self:FindWndSpineByKey(self._spineBoxKey)
		if dpSpine:IsDpValid() then
			local aniName = showEff and "doudong" or "jingtai"
			dpSpine:PlayAnimationSolid(aniName,true)
		end
		showEffRoot = true
	end
	CS.ShowObject(self.mBoxImg,showImg)
	CS.ShowObject(self.mBoxEffect,showEffRoot)
	CS.ShowObject(self.mBoxGetRedPoint,showEff)
end

function UISubTreadNew:FormatTimeSpan(timeSpan)
	local time = math.floor(timeSpan)
	local day =math.floor(time / 86400)
	local str = ""
	if day > 0 then
		str = day .. ccClientText(10304)
	end
	local leftTime = time % 86400
	str = str .. LUtil.FormatTimespanNumber(leftTime)
	return str
end

function UISubTreadNew:GetCallBtnInfo(info)
	local trans = info.trans
	local EffRootTrans = self:FindWndTrans(trans,"EffRoot")
	local BtnNameTrans = self:FindWndTrans(trans,"BtnName")
	local BtnImgTrans = self:FindWndTrans(trans,"BtnImg")
	local TimeTxtTrans = self:FindWndTrans(trans,"TimeTxt")
	local PayDivTrans = self:FindWndTrans(trans,"PayDiv")
	local IconImgTrans = self:FindWndTrans(PayDivTrans,"IconImg")
	local NumTxtTrans = self:FindWndTrans(PayDivTrans,"NumTxt")
	local FreeTxtTrans = self:FindWndTrans(trans,"FreeTxt")
	local LimitTxtTrans = self:FindWndTrans(trans,"LimitTxt")
	local RedPointTrans = self:FindWndTrans(trans,"redPoint")

	self:CreateBtnEff(EffRootTrans,info.effName)

	return {
		BtnNameTrans = BtnNameTrans,
		BtnImgTrans = BtnImgTrans,
		TimeTxtTrans = TimeTxtTrans,
		PayDivTrans = PayDivTrans,
		IconImgTrans = IconImgTrans,
		NumTxtTrans = NumTxtTrans,
		FreeTxtTrans = FreeTxtTrans,
		LimitTxtTrans = LimitTxtTrans,
		RedPointTrans = RedPointTrans,
		btnType = info.btnType,
	}
end
------------------------- List -------------------------

function UISubTreadNew:GetNeedAddItemList()
	local findCost = gModelTreaFind:GetFindCost(1)
	local itemId = findCost.itemId
	local list = {
		{
			itemId = itemId,
		},
		{
			itemId = 102001,
		}
	}
	return list
end

function UISubTreadNew:OnDrawNeedAddItemCell(list,item,itemdata,itempos)
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

function UISubTreadNew:RefreshNumInfo()
	local numLimit = gModelTreaFind:GetPara("dayExtractNumMax")
	local callNum = gModelTreaFind:GetTodayCallNum()
	local str = string.replace(ccClientText(11630),callNum,numLimit)
	self:SetTextTile(self.mCallLimitTxt,str)
end

------------------------- List -------------------------

------------------------------------------------------------------
return UISubTreadNew



