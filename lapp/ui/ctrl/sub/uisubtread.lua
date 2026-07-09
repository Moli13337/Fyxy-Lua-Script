---
--- Created by Administrator.
--- DateTime: 2023/10/14 11:16:34
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubTread:LChildWnd
local UISubTread = LxWndClass("UISubTread", LChildWnd)
local Tweening = DG.Tweening
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubTread:UISubTread()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubTread:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubTread:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubTread:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:InitNetEvent()
	self:InitUIEvent()
	self:RefreshUI()

	self:CheckGiftBtnIsShow()

	self:RefreshActShow()
end


function UISubTread:InitData()
	self._countDownTimer = "_countDownTimer"
	self._autoMoveKey = "automove"
end

function UISubTread:FindTreasure(type)
	local wndName = self:GetParentWndName()
	gModelTreaFind:SendFindReq(type,wndName)

    --if type == 1 then
     --   --local data = gModelTreaFind:GetTreaFindInfo()
     --   local freeCnt = gModelTreaFind:GetFreeFindCnt()
     --   if freeCnt>0 then
     --       gModelTreaFind:OnFindTreasureReq(type)
     --       return
     --   end
    --end
    --
    --
	--local cost = gModelTreaFind:GetFindCost(type)
	--local itemId = cost.itemId
	--local own = gModelItem:GetNumByRefId(itemId)
	--if own>=cost.itemNum then
	--	gModelTreaFind:ShowItemCostTipWnd(type)
	--	return
	--end
    --
	--local diaCost = gModelTreaFind:GetFindDiaCost(type)
	--own = gModelItem:GetNumByRefId(diaCost.itemId)
	--if own >= diaCost.itemNum then
	--	gModelTreaFind:ShowDiaTipWnd(type)
	--	return
	--end
	--local parentWnd = self:GetParentWnd()
	--local wndName = parentWnd:GetWndName()
	--gModelGeneral:OpenGetWayWnd({itemId = diaCost.itemId,srcWnd = wndName})
	--GF.OpenWnd("UITreadBuy")

end

function UISubTread:SetStaticContent()
	local str =ccClientText(19414) -- "神迹探宝"
	self:SetWndText(self.mTitle,str)

	str =ccClientText(19413) --"掉落概率"
	self:SetWndText(self.mHelpText,str)

	local effect = "fx_xunbao_zhuanpan"
	self:CreateWndEffect(self.mCenter,effect,effect,100)

	local text = self:FindWndTrans(self.mLogBtn,"Text")
	str =ccClientText(19435) -- "日志"
	self:SetWndText(text,str)

	text = self:FindWndTrans(self.mShop,"Text")
	str =ccClientText(10362) -- "日志"
	self:SetWndText(text,str)

	text = self:FindWndTrans(self.mGiftBtn,"Text")
	str =ccClientText(27751) -- "礼物"
	self:SetWndText(text,str)
end

--function UISubTread:OnDrawStar(list,item,itemdata,itempos)
--	local Image = self:FindWndTrans(item,"Image")
--	local select = self:FindWndTrans(item,"select")
--
--	local isSelect = self._select == itempos
--	CS.ShowObject(select,isSelect)
--	self:SetWndClick(item,function () self:SelectTrea(itempos,itemdata) end)
--
--	self._starItemList[itempos] = item
--end

--function UISubTread:SelectTrea(itempos,itemdata)
--
--	local index = self._select
--	local item= self._starItemList[index]
--	if item then
--		local select = self:FindWndTrans(item,"select")
--		CS.ShowObject(select,false)
--	end
--
--	item = self._starItemList[itempos]
--	if item then
--		local select = self:FindWndTrans(item,"select")
--		CS.ShowObject(select,true)
--	end
--
--	self._select = itempos
--
--	self:ShowHotTrea(itemdata)
--end

--function UISubTread:ShowHotTrea(itemdata)
--	local itemId = itemdata.itemId
--	local treaId = gModelTreaFind:GetTreaIdByItemId(itemId)
--	if treaId< 0 then
--		return
--	end
--
--	local objRef = gModelTreasure:GetTreasureObjectRefByRefId(treaId)
--	local name = ccLngText(objRef.name)
--	self:SetWndText(self.mHotName,name)
--
--
--	local spineName = objRef.spine
--	local aniname = objRef.idle
--	local spineKey = "hotTrea"
--	self:DestroyWndSpineByKey(spineKey)
--	if not string.isempty(spineName) then
--		self:CreateWndSpine(self.mHotTrea,spineName,spineKey,false,function (spine)
--			local scale = gModelTreaFind:GetPara("objectScaleOther")
--			spine:SetRaycastTarget(false)
--			spine:SetScale(scale)
--			if not string.isempty(aniname) then
--				spine:PlayAnimationSolid(aniname)
--			end
--		end)
--	end
--
--
--
--end



function UISubTread:OnTimer(key)
	if key == self._countDownTimer then
		self:SetCountDown()
	elseif self._autoMoveKey == key then
		self:MoveHotTrea(true)
	end
end

function UISubTread:RefreshNumInfo()
    local numLimit = gModelTreaFind:GetPara("dayExtractNumMax")
    local callNum = gModelTreaFind:GetTodayCallNum()

    local str = string.replace(ccClientText(11630),callNum,numLimit)
    self:SetWndText(self.mNumInfo,str)
end

function UISubTread:InitNetEvent()
	self:WndNetMsgRecv(LProtoIds.FindTreasureInfoResp,function ()
		self:RefreshUI()

		self:RefreshBubble()
		self:CheckGiftBtnRedPoint()
	end)
	self:WndNetMsgRecv(LProtoIds.TreasureDropGiftResp,function ()
		self:CheckGiftBtnIsShow()
	end)

	self:WndEventRecv(EventNames.ON_ACTIVITY_LIST_CHANGE,function () self:RefreshTreaHot() end)
	--self:WndEventRecv(EventNames.ON_ACTIVITY_CHANGE,function () self:RefreshTreaHot() end)

	self:WndEventRecv(EventNames.On_Item_Change,function () self:OnItemChange() end)

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid == self._sid then
			self:ShowActContent()
		elseif sid == self._actBuffSid then
			self:ShowActAdd(data)
		end

	end)
end

function UISubTread:OnClickShop()
	local jumpId = gModelTreaFind:GetPara("shopJumpId")
	local parent = self:GetParentWnd()
	local wndName = parent:GetWndName()
	gModelFunctionOpen:Jump(jumpId,wndName)
end

function UISubTread:InitUIEvent()
	local btn1 = self:FindWndTrans(self.mBtn1,"Btn")
	self:SetWndClick(btn1,function ()
		self:FindTreasure(1)
	end)

	local btn2 = self:FindWndTrans(self.mBtn2,"Btn")
	self:SetWndClick(btn2,function ()
		self:FindTreasure(2)
	end)
	self:CreateWndEffect(btn1,"fx_ui_XLZH_anniu","btn1",100,false,false,2)
	self:CreateWndEffect(btn2,"fx_ui_XLZH_anniu","btn2",100,false,false,2)

	self:SetWndClick(self.mHelp,function () self:OnClickHelpStr() end)
	self:SetWndClick(self.mBoxIcon,function ()
		self:OpenBox()
	end)
	self:SetWndClick(self.mOpenBtn,function () self:ChangeTreaOpen() end)
	self:SetWndClick(self.mShop,function () self:OnClickShop() end)
	self:SetWndClick(self.mLogBtn,function () self:OnClickLog() end)
	self:SetWndClick(self.mLookBtn,function () self:OnClickHelpStr() end)

	self:SetWndClick(self.mTip,function ()
		CS.ShowObject(self.mTip,false)
	end)

	self:SetWndClick(self.mGiftBtn,function()
		self:OnClickGiftBtn()
	end)
end

function UISubTread:ShowActContent()

	local data = gModelActivity:GetWebActivityDataById(self._sid)
	if not data then
		return
	end
	local infoData =data.config

	local activityData = gModelActivity:GetActivityBySid(self._sid)
	local title = activityData and activityData.title or ""

	--local helpTipsId = infoData.helpTipsId
	self:SetWndClick(self.mHotHelp,function ()
		GF.OpenWndUp("UIBzTips",{title = title, text = infoData.helpTipsContent1})
	end,LSoundConst.CLICK_ERROR_COMMON)

	local rewards =LxDataHelper.ParseItem(infoData.rewards1)
	self._rewards = rewards

	local itemdata = rewards[1]
	if not itemdata then
		return
	end

	--local showData = gModelGeneral:GetCommonItemShowInfo(itemdata)
    --
	--self:SetWndEasyImage(self.mItemIcon,showData.icon)

	--local instanceId = self.mItemRoot:GetInstanceID()
	--local commonitem = self:GetCommonIcon(instanceId)
	--commonitem:Create(self.mItemRoot)
	--commonitem:SetCommonRewardByStr()
	--commonitem:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)


	--self:SetWndClick(self.mItemRoot,function()
	--	gModelGeneral:ShowCommonItemTipWnd(itemdata)
	--end)

	self:CreateCommonIconImpl(self.mItemicon,itemdata,{showNum = false})

	--commonitem:DoApply()


	local cfgNum = infoData.specialRewardNum
	local text1 = infoData.bubbleTxt1
	local text2 = infoData.bubbleTxt2

	self._actCfgNum = cfgNum
	self:SetWndClick(self.mBubble,function ()
		self:ShowActTip(cfgNum,text1,text2)
	end)

	local itemName = gModelItem:GetItemNameRichText(itemdata.itemId)
	self:SetWndText(self.mItemName,itemName)
	self:InitTextLineWithLanguage(self.mItemName, -30)

	self._hasAct = true
	self:RefreshBubble()

end

function UISubTread:OnClickHelpStr()
	GF.OpenWnd("UITreadRule")
end

function UISubTread:OnClickGiftBtn()
	--GF.OpenWnd("WndTreasureGiftBuy",{giftType = 2})
end
function UISubTread:OnItemChange()
	for k,v in pairs(self._uiCurrencyItem) do
		local refId = k
		local item = v
		local count = gModelItem:GetNumByRefId(refId)
		count = LUtil.NumberCoversion(count)
		local num = self:FindWndTrans(item,"Bg/num")
		self:SetWndText(num,count)
	end

    self:RefreshBoxInfo()
	self:SetFindBtn(1,self.mBtn1)
	self:SetFindBtn(2,self.mBtn2)
end

function UISubTread:CheckGiftBtnIsShow()
	--local status = gModelTreasure:CheckFindGiftStatus()
	local status =false
	CS.ShowObject(self.mGiftBtn,status)
	if status then
		self:CheckGiftBtnRedPoint()
	end
end

function UISubTread:OnClickLog()
	GF.OpenWnd("UITreadRecord")
end

function UISubTread:RefreshBoxInfo()

    local boxCfg = gModelTreaFind:GetBoxRewardConfig()
    if boxCfg then
        local need = boxCfg.need
        local item = LxDataHelper.ParseItem_3(need)
        local own = gModelItem:GetNumByRefId(item.itemId)
        local showStr = string.format("%s/%s",own,item.itemNum)
		local progress = own/item.itemNum
		progress = Mathf.Clamp(progress,0,1)
		LxUiHelper.SetProgress(self.mProgress,progress)
        self:SetWndText(self.mBoxNum,showStr)

		local effectKey = "fx_baoxiang_paiweisai01"
		if own >= item.itemNum then
			self:CreateWndEffect(self.mBoxIcon,effectKey,effectKey,100,false,false,2)
		else
			self:DestroyWndEffectByKey(effectKey)
		end
    end
end

function UISubTread:OnDrawCurrency(list,item,itemdata,itempos)
	local Bg = self:FindWndTrans(item,"Bg")
	local BgIcon = self:FindWndTrans(Bg,"icon")
	local BgAdd = self:FindWndTrans(Bg,"add")
	local BgNum = self:FindWndTrans(Bg,"num")

	local iconPath,iconBgPath = gModelItem:GetItemImgByRefId(itemdata)
	self:SetWndEasyImage(BgIcon,iconPath)
	self:SetWndClick(BgAdd,function () self:OnClickAdd(itemdata) end)
	local count = gModelItem:GetNumByRefId(itemdata)
	count = LUtil.NumberCoversion(count)

	self:SetWndText(BgNum,count)

	self._uiCurrencyItem[itemdata]= item
end

function UISubTread:FormatTimeSpan(timeSpan)
	local time = math.floor(timeSpan)
	local day =math.floor(time/86400)
	local str = ""
	if day>0 then
		str = day..ccClientText(10304)
	end
	local leftTime = time%86400
	str = str..LUtil.FormatTimespanNumber(leftTime)
	return str
end

function UISubTread:ChangeTreaOpen()
	printInfoN("----UISubTread:ChangeTreaOpen() "..tostring(GetTimestamp()))
	local isOpen = gModelTreaFind:GetTreaHotOpen()
	local newValue = not isOpen

	if newValue then
		local value = gModelTreaFind:SetTreaHotOpen(newValue)
		if value then
			local str =ccClientText(19425) -- "成功开启热点，热点宝物100%出"
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

function UISubTread:RefreshActShow()
	CS.ShowObject(self.mActUp,false)
	local actBuffData = gModelActivity:GetActivityExtraData(ModelActivity.COMMONRANK,{"treasureFree"})
	if not actBuffData or not actBuffData.sid then
		return
	end

	self._actBuffSid = actBuffData.sid
	gModelActivity:ReqActivityConfigData(actBuffData.sid)
end

function UISubTread:SetFindBtn(type,item)
	local btn = self:FindWndTrans(item,"Btn/spBtn")

	local isFree = false
	local showStr = nil
    local freeCnt = gModelTreaFind:GetFreeFindCnt()
	if type ==1 then
		if freeCnt> 0 then
			showStr =ccClientText(19426) -- "免费%s次"
			isFree = true
		else
			showStr =ccClientText(19427)
		end
	else
		showStr =ccClientText(19428)
	end
	self:SetWndButtonText(btn,showStr)


	local findCost = gModelTreaFind:GetFindCost(type)
	local itemId = findCost.itemId
	local itemNum = findCost.itemNum
	local own = gModelItem:GetNumByRefId(findCost.itemId)
	if own< findCost.itemNum then
		local diaCost = gModelTreaFind:GetFindDiaCost(type)
		itemId = diaCost.itemId
		itemNum = diaCost.itemNum
	end


	local cost = self:FindWndTrans(item,"cost")
	local costIcon = self:FindWndTrans(cost,"icon")
	local costNum = self:FindWndTrans(cost,"num")
	local intro = self:FindWndTrans(item,"intro")
	local introText = self:FindWndTrans(intro,"text")
	local iconPath = gModelItem:GetItemImgByRefId(itemId)
	self:SetWndEasyImage(costIcon,iconPath)
	self:SetWndText(costNum,itemNum)

	CS.ShowObject(cost,not isFree)

	if type == 2 then
		local str =ccClientText(19418) -- "必得<#9624ab>紫色</color>或<#d2730f>橙色</color>或<#817900>金色</color>宝物"
		self:SetWndText(introText,str)
	end

	CS.ShowObject(intro,type == 2)
end

function UISubTread:RefreshUI()
	self:SetFindBtn(1,self.mBtn1)
	self:SetFindBtn(2,self.mBtn2)

	local str =ccClientText(19432) -- "<#d2730f>橙色</color>宝物最多还需要<#feeba7>%s</color>次"
	local para = gModelTreaFind:GetPara("objectForeshow1")
	local leftTimes = gModelTreaFind:GetLeftTimes({para})
	local showStr = string.replace(str,leftTimes)
	self:SetWndText(self.mIntroText,showStr)
	self:InitTextLineWithLanguage(self.mIntroText,-30)

	self:RefreshBoxInfo()
	local findCost = gModelTreaFind:GetFindCost(1)
	local itemId = findCost.itemId
	local dataList = {itemId,102001}

	self._uiCurrencyItem ={}
	local uilist = self:GetUIScroll("currencyList")
	uilist:Create(self.mPayItemList,dataList,function (...) self:OnDrawCurrency(...) end)

	self:RefreshTreaHot()

	self:RefreshNumInfo()
end


function UISubTread:RefreshTreaHot()

	local isOpen = gModelTreaFind:GetTreaHotOpen()
	local state = 0
	if isOpen then
		state = 1
	end

	local effect = "fx_xunbao_redian"
	if isOpen then
		self:CreateWndEffect(self.mHotEff,effect,effect,100,false,false,2)
	else
		self:DestroyWndEffectByKey(effect)
	end

	-- local activityList = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_TREASURE_HOT,ModelActivity.STATUS_VALID)
	local activityList = {}
	local activity = activityList[1]
	local showOpenBtn = true
	if not activity then
		showOpenBtn = false
	end
	CS.ShowObject(self.mOpenBtn,showOpenBtn)

	local imgPath = "treasure1_txt_1"
	if state == 1 then
		imgPath = "treasure1_txt_2"
	end
	self:SetWndEasyImage(self.mOpenTrea,imgPath)
	CS.ShowObject(self.mTreaHot,isOpen)
	if not isOpen then
		return
	end


	self._sid = activity.sid
	self:SetCountDown()
	self:TimerStop(self._countDownTimer)
	self:TimerStart(self._countDownTimer,1,false,-1)

	--local infoData =JSON.decode(activity.moreInfo)
    --
	--local helpTipsId = infoData.helpTipsId
	--self:SetWndClick(self.mHotHelp,function ()
	--	GF.OpenWndUp("UIBzTips",{refId = helpTipsId})
	--end,LSoundConst.CLICK_ERROR_COMMON)
    --
	--local rewards =LxDataHelper.ParseItem(infoData.rewards)
	--self._rewards = rewards
	--local cnt = #rewards
	--if cnt<=0 then
	--	return
	--end
	--self._select = -1;
	--local list = self:GetUIScroll("starList")
	--self._starItemList = {}
	--list:Create(self.mStarList,rewards,function (...) self:OnDrawStar(...) end)
    --
	--self:SelectTrea(1,rewards[1])
    --
	----CS.SetOnBeginDrag(self.mHotTrea.gameObject,function (...) self:OnBeginDrag(...) end)
	----CS.SetOnEndDrag(self.mHotTrea.gameObject,function (...) self:OnEndDrag(...) end)
	----self:SetWndClick(self.mHotTrea,function () self:OnClickHot() end)
    --
	--self:ShowTreasureList()
	--self:StartAutoMove()

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UISubTread:ShowActTip(cfgNum,text1,text2)
	local actCnt = gModelTreaFind:GetActivityCnt()
	if not text1 or not text2 then
		return
	end
	local leftNum = cfgNum- actCnt
	local str = nil
	if leftNum> 0 then
		str = string.replace(text1,leftNum)
	else
		str = text2
	end
	self:SetWndText(self.mTipText,str)
	CS.ShowObject(self.mTip,true)
end

function UISubTread:ShowActAdd(data)
	local num,text =data.config.treasureFree,data.config.treasureFreeName
	if not num or not text then
		return
	end
	local str = string.replace(text,num)
	self:SetWndText(self.mActNum,str)
	CS.ShowObject(self.mActUp,true)
end

function UISubTread:CheckGiftBtnRedPoint()
	--local status = gModelTreasure:CheckFindGiftRedPoint()
	local status =false
	local redPointTrans = self:FindWndTrans(self.mGiftBtn,"redPoint")
	CS.ShowObject(redPointTrans,status)
end

function UISubTread:RefreshBubble()
	local seqCom = self:GetSeqCom()
	if not self._hasAct then
		seqCom:DeleteSeq("floatTween")
		return
	end

	local cfgNum = self._actCfgNum
	local text = self:FindWndTrans(self.mBubble,"UIText")
	local actCnt = gModelTreaFind:GetActivityCnt()
	local leftNum = cfgNum- actCnt
	local str = nil
	if leftNum>0 then
		str = tostring(leftNum)
	else
		str = "UP"
	end
	self:SetWndText(text,str)


	self.mBubble.localPosition = Vector3.New(52,4,0)
	local seq = seqCom:CreateSeq("floatTween")
	local tween = self.mBubble:DOLocalMoveY(12,1):SetRelative(true)
	seq:Append(tween)
	seq:SetLoops(-1,Tweening.LoopType.Yoyo)
	seq:PlayForward()
end

function UISubTread:SetCountDown()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local endTime = activityData.endTime
	local str = nil
	if endTime == 0 then
		str=ccClientText(14300) --"永久"
		self:TimerStop(self._countDownTimer)
	else
		local timeSpan = endTime- GetTimestamp()
		if timeSpan <= 0 then
			str =ccClientText(14301) --"活动已结束"
			self._isEnd = true
			self:TimerStop(self._countDownTimer)
		else
			str = self:FormatTimeSpan(timeSpan)
		end
	end

	self:SetWndText(self.mActTime,str)
end

function UISubTread:OnClickAdd(itemId)
	local parentWnd = self:GetParentWnd()
	local wndName = parentWnd:GetWndName()
	gModelGeneral:OpenGetWayWnd({itemId=itemId,srcWnd = wndName})
end

function UISubTread:OpenBox()
	local boxCfg = gModelTreaFind:GetBoxRewardConfig()
	if not boxCfg then
		return
	end
	local need = boxCfg.need
	local item = LxDataHelper.ParseItem_3(need)
	local own = gModelItem:GetNumByRefId(item.itemId)
	if own>= item.itemNum then
		gModelTreaFind:OnFindTreasureRewardReq()
	else
		--todo
		GF.OpenWnd("UITreadBoxInfo")
	end

end

--function UISubTread:MoveHotTrea(isLeft)
--	local list = self:GetUIScroll("treasureList")
--	local uiList = list:GetList()
--	if uiList then
--		uiList:MoveOneStep(isLeft)
--	end
--end

--function UISubTread:StartAutoMove()
--	local interval = gModelTreaFind:GetPara("shopHotspotShow")
--	self:TimerStop(self._autoMoveKey)
--	self:TimerStart(self._autoMoveKey,interval,true,-1)
--end

--function UISubTread:OnBeginDrag(go,eventData)
--	self._beginX = eventData.position.x
--	--printInfoN("beginx .."..self._beginX)
--end
--function UISubTread:OnEndDrag(go,eventData)
--	local endX = eventData.position.x
--	if not self._beginX then
--		return
--	end
--	--printInfoN("endX .."..endX)
--	local dis = endX- self._beginX
--	if dis>30 then
--		self:MoveHotTrea(true)
--		self:StartAutoMove()
--	elseif dis<-30 then
--		self:MoveHotTrea(false)
--		self:StartAutoMove()
--	end
--end

--function UISubTread:OnClickHot()
--	if not self._rewards then
--		return
--	end
--	local itemdata = self._rewards[self._select]
--	gModelGeneral:ShowCommonItemTipWnd(itemdata)
--end


--function UISubTread:ShowTreasureList()
--	local para =
--	{
--		root = self.mItemList,
--		dataList= self._rewards,
--		setFunc = function (...) self:OnDrawTrea(...) end,
--		type = UIItemList.CIRCLE,
--		onCenterFunc= function (...) self:OnTreaCenter(...) end,
--		centerPos = 0,
--	}
--
--	local uiList = self:GetUIScroll("treasureList")
--	uiList:InitListData(para)
--
--end

--function UISubTread:OnDrawTrea(list,item,itemdata,itempos)
--	local bg = self:FindWndTrans(item,"bg")
--	local root = self:FindWndTrans(item,"root")
--	local nameBg = self:FindWndTrans(item,"nameBg")
--	local nameBgName = self:FindWndTrans(nameBg,"name")
--
--	local itemId = itemdata.itemId
--	local treaId = gModelTreaFind:GetTreaIdByItemId(itemId)
--	if treaId< 0 then
--		return
--	end
--
--	local objRef = gModelTreasure:GetTreasureObjectRefByRefId(treaId)
--	local name = ccLngText(objRef.name)
--	self:SetWndText(nameBgName,name)
--	--local iconPath = objRef.icon
--	local type = objRef.type
--	local treaRef = gModelTreasure:GetTreasureRefByRefId(type)
--	local iconBgPath = treaRef.iconBgDrop
--
--	local spineName = objRef.spine
--	local aniname = objRef.idle
--	local spineKey = "hotTrea"..itempos
--	self:DestroyWndSpineByKey(spineKey)
--	if not string.isempty(spineName) then
--		self:CreateWndSpine(root,spineName,spineKey,false,function (spine)
--			local scale = gModelTreaFind:GetPara("objectScaleOther")
--			spine:SetRaycastTarget(false)
--			spine:SetScale(scale)
--			if not string.isempty(aniname) then
--				spine:PlayAnimationSolid(aniname)
--			end
--		end)
--	end
--
--	self:SetWndEasyImage(bg,iconBgPath)
--
--	self:SetWndClick(item,function ()
--		gModelGeneral:ShowCommonItemTipWnd(itemdata)
--	end)
--
--	self:InitTextModeWithLanguage(nameBgName)
--end

--function UISubTread:OnTreaCenter(item,itemdata,itempos)
--	self:SelectTrea(itempos)
--end


------------------------------------------------------------------
return UISubTread


