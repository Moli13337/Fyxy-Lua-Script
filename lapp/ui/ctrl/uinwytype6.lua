---
--- Created by BY.
--- DateTime: 2022/1/6 20:52:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UINwYType6:LWnd
local UINwYType6 = LxWndClass("UINwYType6", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINwYType6:UINwYType6()
	self._blindBoxCount = 0
	self._timeKey = "UINwYType6"
	self._newYearTweenKey = "_newYearTweenKey"
	self._boxTransList = {}
	self._modelEnum = ModelActivity.NEWYEAR2022_ITEM_10
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINwYType6:OnWndClose()
	self:TweenSeqKill(self._newYearTweenKey)
	GF.CloseWndByName("UIBoxff")
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINwYType6:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINwYType6:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UINwYType6:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config

	local mangheEffect = tonumber(data.mangheEffect) or 1
	self._showMangheEffect = mangheEffect == 1

	local bingoImg,bingoTitle,bingoTitlePos,bingoRulesTxt,awardShow,awardShowPos,awardValue,awardName,awardNamePos
	= data.bingoImg,data.bingoTitle,data.bingoTitlePos,data.bingoRulesTxt,data.awardShow,data.awardShowPos,data.awardValue,data.awardName,data.awardNamePos
	local chooseTips,buyCost,buyBtnTxt,chooseTips2 = data.chooseTips,data.buyCost,data.buyBtnTxt,data.chooseTips2
	local awardValuePos = data.awardValuePos
	self._buyCost = buyCost
	self._buyTips = data.buyTips
	self._openTips = data.openTips
	self._heroRefId = data.heroRefId
	self._bingoRulesTxt = bingoRulesTxt
	self._giftType = data.giftType
	self._giftItem = data.giftItem
	self._jumpId = data.jumpId
	self._bingoFx = data.bingoFx or "fx_manghedakai"
	local giftItems = string.split(self._giftItem, '=')
	self._giftItemId = tonumber(giftItems[2])
	self._giftNeedNum = tonumber(giftItems[3])
	local buyReward = data.buyReward
	if not string.isempty(buyReward) then
		self._buyReward = LxDataHelper.ParseItem(buyReward)

		local text1 = CS.FindTrans(self.mBuyTips, "Text1")
		self:SetWndText(text1, ccClientText(24701))
		for i, v in ipairs(self._buyReward) do
			local icon = CS.FindTrans(self.mBuyTips, "Icon" .. i)
			local text = CS.FindTrans(self.mBuyTips, "Text" .. i + 1)
			if icon then
				local res = gModelGeneral:GetCommonItemImgRef(v)
				self:SetWndEasyImage(icon, res)
				self:SetWndText(text, "x" .. v.itemNum .. " ")

				CS.ShowObject(icon, true)
				CS.ShowObject(text, true)
			end
		end
		-- CS.ShowObject(self.mBuyTips, true)
		UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mBuyTips)
	end
	if LxUiHelper.IsImgPathValid(bingoImg) then
		self:SetWndEasyImage(self.mBgImage,bingoImg)
	end
	if LxUiHelper.IsImgPathValid(bingoTitle) then
		CS.ShowObject(self.mTxtImg,true)
		self:SetWndEasyImage(self.mTxtImg,bingoTitle,nil,true)
		if not string.isempty(bingoTitlePos) then
			local Arr = string.split(bingoTitlePos,"|")
			self.mTxtImg.anchoredPosition = Vector3(tonumber(Arr[1]),tonumber(Arr[2]),0)
		end
	end
	--if not string.isempty(bingoRulesTxt) then
	--	self:SetWndText(self.mRulesText,bingoRulesTxt)
	--end
	if not string.isempty(awardShow) then
		local imgArr = string.split(awardShow,"=")
		local posParent
		if imgArr[1] == "1" then
			posParent = self.mHeroImg
			self:SetWndEasyImage(posParent,imgArr[2],nil,true)
		else
			posParent = self.mHeroSpine
			local spineName = imgArr[2]
			self:CreateWndSpine(posParent,spineName,spineName.."UINwYType6",false)
		end
		CS.ShowObject(posParent,true)
		if not string.isempty(awardShowPos) then
			local arr = string.split(awardShowPos,"|")
			posParent.anchoredPosition = Vector2(tonumber(arr[1]),tonumber(arr[2]))
		end
	end
	if not string.isempty(awardValue) then
		self:SetWndText(self.mValueText,awardValue)
		CS.ShowObject(self.mValueBg,true)
		if not string.isempty(awardValuePos) then
			local Arr = string.split(awardValuePos,"|")
			self.mValueBg.anchoredPosition = Vector3(tonumber(Arr[1]),tonumber(Arr[2]),0)
		end
	else
		CS.ShowObject(self.mValueBg,false)
	end
	--if LxUiHelper.IsImgPathValid(awardName) then
	--	CS.ShowObject(self.mHeroNameImg,true)
	--	self:SetWndEasyImage(self.mHeroNameImg,awardName,nil,true)
	--	if not string.isempty(awardNamePos) then
	--		local Arr = string.split(awardNamePos,"|")
	--		self.mHeroNameImg.anchoredPosition = Vector3(tonumber(Arr[1]),tonumber(Arr[2]),0)
	--	end
	--end
	local _giftType = self._giftType
	if _giftType == 2 then
		if not string.isempty(chooseTips2) then
			local itemName = gModelItem:GetNameByRefId(self._giftItemId)
			self: SetWndText(self.mBuyText, string.replace(chooseTips2, itemName))
		end
	else
		if not string.isempty(chooseTips) then
			self:SetWndText(self.mBuyText,chooseTips)
		end
	end


	local buyCostStr = gModelPay:GetShowByWelfareId(buyCost)
	local btnStr = string.replace(buyBtnTxt,buyCostStr)
	self:SetWndText(self.mBtnDesText,btnStr)

	local bingoRulesTimeBgImg, bingoRulesShopBgImg, bingoRulesBackImg
		= data.bingoRulesTimeBgImg, data.bingoRulesShopBgImg, data.bingoRulesBackImg
	if LxUiHelper.IsImgPathValid(bingoRulesTimeBgImg) then
		self:SetWndEasyImage(self.mTimeBg, bingoRulesTimeBgImg)
	end

	local bingoRulesShopBgImgData = string.split(bingoRulesShopBgImg, '=')
	local path = bingoRulesShopBgImgData[1]
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mBg, path, function()
			local pos = bingoRulesShopBgImgData[2]
			if not string.isempty(pos) then
				self:SetAnchorPos(self.mBg, LxDataHelper.ParseVector2NotEmpty2(pos))
			end
		end, true)
	end
	CS.ShowObject(self.mBg, true)

	if LxUiHelper.IsImgPathValid(bingoRulesTimeBgImg) then
		self:SetWndEasyImage(self.mTimeBg, bingoRulesTimeBgImg)
	end

	if LxUiHelper.IsImgPathValid(bingoRulesBackImg) then
		self:SetWndEasyImage(self.mBtnClose, bingoRulesBackImg, nil, true)
	end

	gModelActivity:OnActivityPageReq(self._sid)
	local activityDatas = gModelActivity:GetActivityBySid(self._sid)
	local _endTime = activityDatas.endTime
	if(_endTime and _endTime ~= -1)then
		self:TimerStop(self._timeKey)
		self:TimerStart(self._timeKey,1,false,-1)
		self:SetTime()
	end

	if(_giftType ==2)then
		CS.ShowObject(self.mGoldNode, true)
		local iconName = gModelItem:GetItemIconByRefId(tonumber(giftItems[2]))
		local haveNum = gModelItem:GetNumByRefId(tonumber(giftItems[2])) or 0
		self:SetWndEasyImage(self.mItemIcon, iconName)
		self:SetWndText(self.mItemNum, haveNum)
	else
		CS.ShowObject(self.mGoldNode, false)
	end
end

function UINwYType6:OnTryTcpReconnect()
	self:WndClose()
end

function UINwYType6:SetTime()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local endTime = activityData.endTime
	if endTime == 0 then
		self:TimerStop(self._timeKey)
		self:SetWndText(self.mTimeText,ccClientText(18404))
		CS.ShowObject(self.mTimeBg,true)
		return
	end
	local time = GetTimestamp()
	local timespan = endTime - time
	local  timeStr = ""
	if(timespan < 0)then
		timeStr = ccClientText(14301)
		self:TimerStop(self._timeKey)
	else
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(ccClientText(18400),timeStr)
	end
	self:SetWndText(self.mTimeText,timeStr)
	CS.ShowObject(self.mTimeBg,true)
end

function UINwYType6:InitCommand()
	self:SetWndText(self.mHelpText,ccClientText(24729))
	self:InitTextLineWithLanguage(self.mHelpText, -30)
	self:InitTextSizeWithLanguage(self.mHelpText, -2)
	local _sid = self:GetWndArg("sid")
	local _page = self:GetWndArg("page") --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		_sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	self._sid = _sid

	local modelId = gModelActivity:GetActivityModeIdBySid(self._sid)
	self._modelId = modelId

	self._modelClose = {
		[ModelActivity.MODEL_ACTIVITY_TYPE_57] = "UIActNewYear2022",
		[ModelActivity.FAIRY_FATHER_DAY] 	   = "UIActFairyFatherDay",
	}

	self._modelList = {
		[ModelActivity.MODEL_ACTIVITY_TYPE_57] = ModelActivity.NEWYEAR2022_ITEM_10,
		[ModelActivity.FAIRY_FATHER_DAY] 	   = ModelActivity.FATHER_DAY_BOX_NUM,
		[ModelActivity.MODEL_ACTIVITY_TYPE_129] = 1
	}

	local modelEnum = self._modelList[modelId]
	if modelEnum then
		self._modelEnum = modelEnum
	end

	gModelActivity:ReqActivityConfigData(_sid)
	gModelActivity:SetSaveRed(_sid)
end

function UINwYType6:OnActivityABCDRewardResp(pb)
	local reward = pb.itemList
	local tingsDetail = pb.thingsDetail
	local thingsDetail = gModelGeneral:GetThingsDetailInfoByPb(tingsDetail)
	local rewardList
	if thingsDetail then
		local rewardNum = thingsDetail:GetThingsDetailRewardNum()
		if rewardNum > 0 then
			rewardList = thingsDetail:GetThingsDetailAllRewardList() or {}
		end
	end

	local itemList = {}
	if table.isempty(itemList) then
		for k,v in ipairs(reward) do
			local itemType = tonumber(v.type)
			local itemId = tonumber(v.itemId)
			if itemType == LItemTypeConst.TYPE_RUNE then
				for p, q in ipairs(rewardList) do
					local data = q.serverData
					if data.refId == itemId then
						itemId = data.id
						break
					end
				end
			end

			local tab = {
				itype = itemType,
				itemId = itemId,
				count = tonumber(v.count),
			}
			table.insert(itemList, tab)
		end
	end


	local item = itemList[1]
	if not item then
		return
	end

	local func = function()
		gModelWndPop:TryOpenPopWnd("UIAward", {itemList = itemList})
	end
	local showMangheEffect = self._showMangheEffect
	if showMangheEffect == nil then
		showMangheEffect = true
	end
	if showMangheEffect then
		local eff = self._bingoFx
		GF.OpenWnd("UIBoxff",{func = func,item = item, eff = eff})
	else
		func()
	end
end

function UINwYType6:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	end
end

function UINwYType6:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ActivityABCDRewardResp,function (pb)
		if pb.sid ~= self._sid then return end
		self:OnActivityABCDRewardResp(pb)
		local _boxTransList = self._boxTransList
		if _boxTransList then
			for i, v in pairs(_boxTransList) do
				v.localRotation = Vector3.New(0,0,0)
			end
		end
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function() self:OnItemChange() end)
end

function UINwYType6:OnClickBuy()
	local _buyCost = self._buyCost
	local _buyTips = self._buyTips or 110033
	local _buyReward = self._buyReward
	local itemName = ""
	if _buyReward then
		local item = _buyReward[1]
		itemName = item.itemNum ..gModelItem:GetNameByRefId(item.itemId)
	end
	local buyCostStr = gModelPay:GetShowByWelfareId(_buyCost)
	gModelGeneral:OpenUIOrdinTips({refId = _buyTips,para = {buyCostStr,itemName,1},func = function()
		gModelPay:GiftPayCtrl(0,_buyCost,ModelPay.PAY_TYPE_ACTIVITY,nil,self._sid,0)
	end })

end

function UINwYType6:RefreshData()
	local _blindBoxCount = self._blindBoxCount
	local isNeedBuy = true
	local _giftType = self._giftType
	--local isNeedBuy = _blindBoxCount <= 0
	if(_giftType~=2)then
		isNeedBuy = _blindBoxCount <= 0
	end
	local isSellOut = true --是否抽完
	local _page = self._page
	local list = _page.entry
	for i, v in ipairs(list) do
		local goalData = v.goalData
		local status = goalData.status
		if status < 2 then
			isSellOut = false
			break
		end
	end
	self._isSellOut = isSellOut
	CS.ShowObject(self.mBtnBuy,isNeedBuy and not isSellOut and _giftType~=2)
	CS.ShowObject(self.mBuyTips,isNeedBuy and not isSellOut and _giftType~=2)
	CS.ShowObject(self.mBuyText,not isSellOut and (not isNeedBuy or _giftType==2))
	CS.ShowObject(self.mBuyMask,isSellOut)

	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
		--_uiCellList:DrawAllItems()
	else
		_uiCellList = self:GetUIScroll("UINwYType6mCellSuper")
		_uiCellList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end)
		_uiCellList:EnableScroll(false,false)
		self._uiCellList = _uiCellList
	end
	if not isNeedBuy or _giftType==2 then
		self:SetTween()
	else
		self:TweenSeqKill(self._newYearTweenKey)
	end
end

function UINwYType6:OnClickBlindBox(itemdata,name)
	local _blindBoxCount = self._blindBoxCount
	local _isSellOut = self._isSellOut
	local goalData = itemdata.goalData
	local status = goalData.status
	local _giftType = self._giftType
	if status > 1 then
		GF.ShowMessage(ccClientText(24717))
		return
	elseif _giftType~=2 and _blindBoxCount <= 0 then
		GF.ShowMessage(ccClientText(24716))
		return
	elseif _isSellOut then
		GF.ShowMessage(ccClientText(24722))
		return
	end
	if(_giftType == 2)then
		local have = gModelItem:GetNumByRefId(self._giftItemId);
		local need = self._giftNeedNum
		if(need > have)then
			if(self._jumpId) then
				gModelFunctionOpen:Jump(self._jumpId, self:GetWndName())
			end
			return
		end

	end
	gModelGeneral:OpenUIOrdinTips({refId = self._openTips,para = {name},func = function()
		gModelActivity:OnActivitySpecialOpReq(self._sid,itemdata.pageId,itemdata.entryId,0, nil, ModelActivity.SPRING_FESTIVAL_OPEN_BLIND_BOX)
	end })
end

function UINwYType6:InitEvent()
	self:SetWndClick(self.mBtnClose,function () self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnBuy,function () self:OnClickBuy() end)
	self:SetWndClick(self.mBtnRulesHelp,function () self:OnClickRulesHelp() end,LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mBtnHelp,function () self:OnClickHelp() end,LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mValueBg,function () self:OpenHeroPreview() end)
	self:SetWndClick(self.mGoldNode,function() self:OnBtnItemAddClick() end)
end

function UINwYType6:ListItem(list, item, itemdata, itempos)
	local entryId = itemdata.entryId
	local pageId  = itemdata.pageId
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,pageId,entryId)
	local root = self:FindWndTrans(item,"Root")
	local icon 	= self:FindWndTrans(root,"Icon")
	local mask 	= self:FindWndTrans(root,"Mask")
	local nameText 	= self:FindWndTrans(root,"NameText")


	local name = entryCfg.name
	local moreInfo = entryCfg.moreInfo
	local goalData = itemdata.goalData
	local status = goalData.status

	if status <= 1 then
		self._boxTransList[itempos] = root
	else
		self._boxTransList[itempos] = nil
		root.localRotation = Vector3.New(0,0,0)
	end

	if not string.isempty(moreInfo) then
		local arr = string.split(moreInfo,"=")
		if arr[2] then
			self:SetWndEasyImage(icon,arr[2])
			-- self:SetWndEasyImage(mask,arr[2])
		end
		if arr[1] == "1" then
			icon.localScale = Vector2.New(-1,1)
		else
			icon.localScale = Vector2.New(1,1)
		end
	end
	CS.ShowObject(mask,status > 1)

	--self:SetWndText(nameText,name)
	--CS.ShowObject(mask,status > 1)
	self:SetWndClick(root,function ()
		self:OnClickBlindBox(itemdata,name)
	end)
end

function UINwYType6:OpenHeroPreview()
	local heroRefId = self._heroRefId
	if not heroRefId then
		return
	end
	--gModelGeneral:OpenHeroStarPre({refId = heroRefId})

	gModelGeneral:OpenHeroSkin({skinRefId = heroRefId})
end

function UINwYType6:SetTween()
	local _boxTransList = self._boxTransList
	local tweens = {}
	for i, v in pairs(_boxTransList) do
		table.insert(tweens,v)
	end
	local seqTween
	self:TweenSeqKill(self._newYearTweenKey)
	if #tweens < 1 then
		return
	end
	local time = 0.1
	local rotate = 2.5
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._newYearTweenKey,function(seq)
			for i, v in ipairs(tweens) do
				local tweener = v.transform:DOLocalRotate(Vector3.New(0,0,-rotate),time):SetEase(DG.Tweening.Ease.InSine)
				seq:Join(tweener)
			end
			seq:AppendInterval(time)
			for i, v in ipairs(tweens) do
				local tweener = v.transform:DOLocalRotate(Vector3.New(0,0,rotate),time*2):SetEase(DG.Tweening.Ease.InSine)
				seq:Join(tweener)
			end
			seq:AppendInterval(time)
			for i, v in ipairs(tweens) do
				local tweener = v.transform:DOLocalRotate(Vector3.New(0,0,0),time*2):SetEase(DG.Tweening.Ease.InSine)
				seq:Join(tweener)
			end
			--seq:AppendInterval(0.5)
			return seq
		end)
	end
	seqTween:SetLoops(-1)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._newYearTweenKey)
	end)
end

function UINwYType6:OnClickRulesHelp()
	local content = self._bingoRulesTxt
	local title = ccClientText(24728)
	GF.OpenWnd("UIBzTips",{title= title,text = content})

end

function UINwYType6:ResetData(pb)
	local sid = pb.sid
	if(self._sid ~= sid)then
		return
	end
	for i, v in ipairs(pb.pages) do
		if v.pageId == self._modelEnum then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			self._page = page

			local moreInfo = JSON.decode(page.moreInfo)
			self._blindBoxCount = moreInfo.blindBoxCount
		end
	end
	self:RefreshData()
end

function UINwYType6:OnClickHelp()
	GF.OpenWnd("UIProlicPop",{sid = self._sid})
end

function UINwYType6:OnItemChange()
	if(self._giftType~=2)then
		return
	end
	local have = gModelItem:GetNumByRefId(self._giftItemId) or 0
	self:SetWndText(self.mItemNum, have)
end

function UINwYType6:OnClickClose()
	local closeName = self._modelClose[self._modelId]
	if closeName then
		GF.OpenWnd(closeName,{sid = self._sid})
	end

	self:WndClose()
end

function UINwYType6:OnBtnItemAddClick()
	if not self._jumpId then
		return
	end
	gModelFunctionOpen:Jump(self._jumpId, self:GetWndName())
end
------------------------------------------------------------------
return UINwYType6