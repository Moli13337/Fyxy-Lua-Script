---
--- Created by Administrator.
--- DateTime: 2023/10/8 11:28:10
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPkC:LChildWnd
local UISubPkC = LxWndClass("UISubPkC", LChildWnd)
UISubPkC.PAGE_BUY = 1				--档位购买
UISubPkC.PAGE_ELITE = 2			--精英战令
UISubPkC.PAGE_ADVANCE = 3			--进阶战令
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPkC:UISubPkC()
	self._passKey = "_passCKey"
	self._getBtnEff = "fx_anniu_02"
	self.pages = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPkC:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPkC:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPkC:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

--领取奖励后，弹奖励获得弹窗
function UISubPkC:OnActivityABCDRewardResp(pb)
	if pb.sid ~= self._sid then return end

	local reward = pb.itemList
	local itemList = {}
	for k,v in ipairs(reward) do
		local tab = {
			itype = tonumber(v.type),
			itemId = tonumber(v.itemId),
			count = tonumber(v.count),
		}
		table.insert(itemList, tab)
	end

	local isShowPassReward = not table.isempty(self._passRewardItemList)
	if isShowPassReward and not self._needShowGift then
		GF.OpenWnd("UIPkAward",{
			itemList = itemList,
			passItemList = self._passRewardItemList,
			passDesc = ccClientText(15813),
			btnTextList = {ccClientText(10102), ccClientText(15812)},
			func = function() self:OnClickBuy() end,
		})
	else
		gModelWndPop:TryOpenPopWnd("UIAward", {itemList = itemList})
	end
end

function UISubPkC:OnClickGoTo()
	gModelFunctionOpen:Jump(self._jump,self:GetWndName())
end

function UISubPkC:OnClickOneKeyGet()--一键领取
	local list ={}
	local checkList = {}
	local getEntryIdList = {}
	local isBuy = self._isGuyPass

	for i, v in ipairs(self.pages[UISubPkC.PAGE_ELITE].entry) do
		local status = v.goalData.status
		local entryId = v.entryId
		if(v.goalData.status==1)then
			local data1 = { sid = self._sid,pageId = v.pageId,entryId = entryId}
			table.insert(list,data1)
			table.insert(checkList,data1)
			getEntryIdList[entryId] = true
		elseif not isBuy and status == 2 then
			getEntryIdList[entryId] = true
		end
	end

	if(isBuy)then
		for i, v in ipairs(self.pages[UISubPkC.PAGE_ADVANCE].entry) do
			if(v.goalData.status==1)then
				local data1 = { sid = self._sid,pageId = v.pageId,entryId = v.entryId}
				table.insert(list,data1)
			end
		end
	end

	--检测是否要显示礼包购买弹窗
	self._needShowGift = self:CheckNeedShowGiftPop(checkList)

	--检测是否显示战令奖励弹窗
	self._passRewardItemList = self:GetShowPassRewardList(getEntryIdList)

	gModelActivity:OnActivityReceiveGoalListReq(list)
end

function UISubPkC:SetTime()--设置时间
	local time = GetTimestamp()
	local timespan = self._endTime - time
	if(timespan <= 0)then
		self:TimerStop(self._passKey)
		CS.ShowObject(self.mTimeBg,false)
		return
	end
	local timeStr = LUtil.FormatTimespanCn(timespan)
	local str = ""
	local _timeDes = self._timeDes
	if not string.isempty(_timeDes) then
		str = string.replace(_timeDes,timeStr)
	end
	self:SetWndText(self.mTimeText,str)
	CS.ShowObject(self.mTimeBg,true)
end

function UISubPkC:OnClickByTips()
	if not self._helpTipsContent then return end

	local title = gModelActivity:GetLngNameByActivitySid(self._sid)
	GF.OpenWnd("UIBzTips",{title= title,text = self._helpTipsContent})
end

function UISubPkC:ListItem(list,item, itemdata, itempos)
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local entryCfg2 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId2,itemdata.entryId2)
	if not entryCfg1 or not entryCfg2 then
		return
	end
	local InstanceID = item:GetInstanceID()
	local wire1 = CS.FindTrans(item,"Wire1")
	local line1 = CS.FindTrans(wire1,"Line")
	local wire2 = CS.FindTrans(item,"Wire2")
	local line2 = CS.FindTrans(wire2,"Line")
	local numText = CS.FindTrans(item,"NumBg/NumText")
	local rewardList1 = CS.FindTrans(item,"RewardList1")
	local rewardList2 = CS.FindTrans(item,"RewardList2")
	local getImage = CS.FindTrans(item,"GetImage")
	local btnGet = CS.FindTrans(item,"BtnGet")
	local btnGo = CS.FindTrans(item,"BtnGo")
	local payBtnEff = CS.FindTrans(btnGet,"Eff")

	local getIconPath = self._getIconPath

	CS.ShowObject(wire1,itempos ~= 1)
	CS.ShowObject(getImage,false)
	CS.ShowObject(btnGet,false)
	CS.ShowObject(btnGo,false)
	local goal = itemdata.goalData.schedules[1].goal
	local status1 = itemdata.goalData.status
	local status2 = itemdata.goalData2.status

	self:SetWndClick(btnGet,function ()
		self:OnClickOneKeyGet()
	end)
	self:SetWndButtonText(btnGo,ccClientText(15804))
	self:SetWndButtonText(btnGet,ccClientText(15802))
	local isShowLine1 = true
	local isShowLine2 = true
	local isShowGetEff = false
	if status1 == 0 then
		isShowLine1 = false
		isShowLine2 = false
		if not self._needQuick then
			CS.ShowObject(btnGo,true)
			self:SetWndClick(btnGo,function ()
				self:OnClickGoTo()
			end)
		else
			CS.ShowObject(btnGet,true)
			self:SetWndClick(btnGet,function ()
				self:OnClickShowQuickPop()
			end)

			self:SetWndButtonText(btnGet,ccClientText(15803))
		end
	elseif status1 == 1 then
		isShowGetEff = true
		CS.ShowObject(btnGet,true)
	elseif status1 == 2 then
		if status2 == 1 then
			CS.ShowObject(btnGet,true)
			self:SetWndButtonText(btnGet,ccClientText(15803))
			if(not self._isGuyPass)then
				self:SetWndClick(btnGet,function ()
					self:OnClickBuy()
				end)
			else
				isShowGetEff = true
			end
		else
			CS.ShowObject(getImage,true)
			if LxUiHelper.IsImgPathValid(getIconPath) then
				self:SetWndEasyImage(getImage, getIconPath, nil ,true)
			end
		end
	end

	CS.ShowObject(line1, isShowLine1)
	CS.ShowObject(line2, isShowLine2)
	self:SetWndText(numText,goal)

	local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
	local keyA = InstanceID.."A"
	local uiIconEasyList = self._uiList:GetItemCls(keyA)
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiList:SetItemCls(keyA, uiIconEasyList)
		uiIconEasyList:Create(self, rewardList1)
		--uiIconEasyList:SetShowMask(false,"Mask")
		uiIconEasyList:SetShowNum(false)
		uiIconEasyList:SetShowExtraNum(true, "TextNum")
	end
	uiIconEasyList:RefreshList(itemList)

	local itemList2 = LxDataHelper.ParseItem(entryCfg2.reward)
	local keyB = InstanceID.."B"
	local uiIconEasyList2 = self._uiList:GetItemCls(keyB)
	if(not uiIconEasyList2)then
		uiIconEasyList2 = UIIconEasyList:New()
		self._uiList:SetItemCls(keyB, uiIconEasyList2)
		uiIconEasyList2:Create(self, rewardList2)
		uiIconEasyList2:SetIconClickPath("CommonUI/Icon")
		uiIconEasyList2:SetIconParentPath("CommonUI/Icon/Root")
		uiIconEasyList2:SetShowNum(false)
		uiIconEasyList2:SetShowExtraNum(true, "TextNum")
	end
	uiIconEasyList2:SetShowMask(not self._isGuyPass,"Mask")
	uiIconEasyList2:RefreshList(itemList2)

	LxUiHelper.SetSizeWithCurAnchor(item,1,83)

	local instanceId = item:GetInstanceID()
	local effKey = self._getBtnEff..instanceId
	self:DestroyWndEffectByKey(effKey)

	if isShowGetEff then
		self:CreateWndEffect(payBtnEff,self._getBtnEff,effKey,100,false,false)
	end
	CS.ShowObject(payBtnEff,isShowGetEff)
end

function UISubPkC:OnClickShowQuickPop()
	GF.OpenWnd("UIPkQukBuyPop",{sid = self._sid})
end

function UISubPkC:CheckNeedShowGiftPop(getList)
	if self._isGuyPass then
		return false
	end

	local getLastData = getList[#getList]
	if not getLastData then
		return false
	end

	--检测是否领取了当前阶级的最后一个
	local nextEntryCfg1 = gModelActivity:GetWebActivityEntryData(getLastData.sid,getLastData.pageId,getLastData.entryId)
	local nextEntryCfg2 = gModelActivity:GetWebActivityEntryData(getLastData.sid,getLastData.pageId,getLastData.entryId + 1)
	if not nextEntryCfg2 then
		--为最后一个，没有下一个了
		return true
	end

	if nextEntryCfg1.moreInfo ~= nextEntryCfg2.moreInfo then
		return true
	end

	return false
end

function UISubPkC:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config
	self._activityCfg = data
	local path,pos,text
	path = data.image
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTop,path)
	end
	path,pos = data.descIcon,data.descIconPosition
	if LxUiHelper.IsImgPathValid(path) and pos then
		self:SetWndEasyImage(self.mTextImg,path,function ()
			CS.ShowObject(self.mTextImg,true)
		end,true)
		self:SetAnchorPos(self.mTextImg, LxDataHelper.ParseVector2NotEmpty(pos))
	end
	self._showItemDesc = data.showItemDesc or "%s"
	pos  = data.buttonDescPosition
	if pos then
		self:SetAnchorPos(self.mBtnBuy, LxDataHelper.ParseVector2NotEmpty(pos))
	end
	path,text = data.freeIcon,data.freeDes
	self._jump = data.jump
	self._timeDes = data.timeDes or "%s"
	text = data.listDesc
	if text then
		local textArr = string.split(text,"|")
		self:SetWndText(self.mText1,textArr[1])
		self:SetWndText(self.mText2,textArr[2] or "")
		self._popDescStr = textArr[2] or ""
	end

	path = data.activateIcon
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mShowImg,path,nil,true)
	end

	text = ccClientText(156)
	if not string.isempty(text) then
		self._helpTipsContent = text
		self:SetWndText(self.mBuyTipsText, text)
		CS.ShowObject(self.mBuyTipsText, true)
		--CS.ShowObject(self.mBuyTipsBtn, true)
	end

	self._getIconPath = data.getIcon

	self._quickBuyDay = data.quickBuyDay
	gModelActivity:OnActivityPageReq(self._sid)
end

---------------------------------------点击----------------------------------------------
function UISubPkC:OnClickHelp()--点击帮助
	local _sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	if not activityData then
		return
	end
	local data = activityData.config
	local title = gModelActivity:GetLngNameByActivitySid(_sid)
	local content = data.helpTipsContent
	GF.OpenWnd("UIBzTips",{title= title,text = content})
end

function UISubPkC:CheckNeedQuick()
	local time = GetTimestamp()
	local timespan = (self._endTime - time) / 86400
	local isOpen =  timespan <= self._quickBuyDay
	if not isOpen then
		return false
	end

	local eliteList = self.pages[UISubPkC.PAGE_ELITE].entry
	local haveNoGet = false
	for i, v in ipairs(eliteList) do
		local goalData	  	= v.goalData
		if(goalData.status == 0)then
			haveNoGet = true
			break
		end
	end

	return haveNoGet
end

function UISubPkC:OnTimer(key)
	self:SetTime()
end

function UISubPkC:OnClickBuy()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local entry = self.pages[UISubPkC.PAGE_BUY].entry[1]
	GF.OpenWnd("UIPkBuyPopBig",
			{sid = self._sid,entry = entry, modelActivityType = ModelActivity.MODEL_PASSC})
end

function UISubPkC:RefreshData()
	local pages = self.pages
	if table.isempty(pages) then return end
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	local data = JSON.decode(activityData.moreInfo)
	self._endTime = (tonumber(data.playerEndTime) / 1000) or tonumber(activityData.endTime)
	self:SetTime()
	if not self:IsTimerExist(self._passKey) then
		self:TimerStart(self._passKey,1,false,-1)
	end

	local isGuyPass = data.buyPassNum > 0
	self._isGuyPass = isGuyPass
	CS.ShowObject(self.mBtnBuy,not isGuyPass)
	CS.ShowObject(self.mShowImg,isGuyPass)

	CS.ShowObject(self.mUpRedImg,not isGuyPass)
	if not isGuyPass then
		local entry = pages[UISubPkC.PAGE_BUY].entry
		local data = entry[1]
		local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,data.pageId,data.entryId)
		local str = entryCfg1.moreInfo
		self:SetWndText(self.mUpRedTxt,str)

		local expend2 = tonumber(entryCfg1.expend2)
		str = gModelPay:GetShowByWelfareId(expend2)
		self._buyBtnStr = str
		self:SetWndButtonText(self.mBtnBuy,str)
	end

	self._needQuick = self:CheckNeedQuick()
	CS.ShowObject(self.mQuickBtn, self._needQuick)
	if self._needQuick then
		self:CreateWndEffect(self.mQuickBtn,"fx_ui_tubiaorukou",self._quickEffectKey,100,false,false)
	else
		self:DestroyWndEffectByKey(self._quickEffectKey)
	end

	local eliteList = pages[UISubPkC.PAGE_ELITE].entry
	local advanceList = pages[UISubPkC.PAGE_ADVANCE].entry
	local _completeIndex,schedule = 0,0
	for i, v in ipairs(eliteList) do
		local data = advanceList[i]
		v.goalData2 = data.goalData
		v.pageId2 = data.pageId
		v.entryId2 = data.entryId
		if(v.goalData.status ~= 0)then
			_completeIndex = i
		end
		local scdle = tonumber(v.goalData.schedules[1].schedule)
		if(scdle > 0 and schedule<scdle)then
			schedule = scdle
		end
	end
	if self._showItemDesc then
		self:SetWndText(self.mDesText,string.replace(self._showItemDesc,schedule))
	end

	local text = self._activityCfg.taskDesc
	if text then
		self:SetWndText(self.mDesText2,text)
	end

	if(self._uiList)then
		self._uiList:RefreshList(eliteList)
	else
		self._uiList = self:GetUIScroll("cell")
		self._uiList:Create(self.mCellScroll,eliteList,function (...) self:ListItem(...) end, UIItemList.SUPER)
	end
	local _uilist = self._uiList:GetList()
	local index = _completeIndex
	_uilist:MoveToPos(index)
end
---------------------------------------引导礼包购买弹窗----------------------------------------------
function UISubPkC:ShowGiftPop() --显示礼包购买弹窗界面
	self._needShowGift = false
	local entry = self.pages[UISubPkC.PAGE_BUY].entry
	local reward1 =  self._activityCfg.popupShowItem
	local descStr = self._popDescStr
	descStr = string.replace(ccClientText(15811), descStr)
	local buyBtnStr = self._buyBtnStr or ""

	GF.OpenWnd("UIPkBuyPop",
			{sid = self._sid,entry = entry, reward1 = reward1,
			 descStr = descStr, buyBtnStr = buyBtnStr})
end

function UISubPkC:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then
			return
		end
		self:OnActivityConfigData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			local sid = v.sid
			if sid == self._sid then
				self:RefreshData()
				return
			end
		end
	end)

	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (...) self:OnTargetWndClose(...) end)

	self:WndNetMsgRecv(LProtoIds.ActivityABCDRewardResp,function (pb)
		self:OnActivityABCDRewardResp(pb)
	end)
end

function UISubPkC:InitCommand()
	self._sid = self:GetWndArg("sid")
	local _sid = self._sid
	gModelActivity:ReqActivityConfigData(_sid)
end

function UISubPkC:ResetData(pb)
	local sid = pb.sid
	if(self._sid ~= sid)then
		return
	end
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		self.pages[v.pageId] = page
	end
	self:RefreshData()
end

---------------------------------------获得奖励弹窗----------------------------------------------
function UISubPkC:GetShowPassRewardList(getEntryIdList) --检测是否显示战令的特殊获得奖励弹窗
	--礼包已购买
	if self._isGuyPass then
		return nil
	end

	local list = {}

	--可以领取的进阶版奖励
	for i, v in ipairs(self.pages[UISubPkC.PAGE_ADVANCE].entry) do
		local entryId = v.entryId
		if getEntryIdList[entryId] then
			local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,entryId)
			local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
			for p,q in ipairs(itemList) do
				local itemId = q.itemId
				if list[itemId] then
					local oldItemNum = list[itemId].itemNum
					list[itemId].itemNum = oldItemNum + q.itemNum
				else
					list[itemId] = q
				end
			end
		end
	end

	--直购奖励
	local data = self.pages[UISubPkC.PAGE_BUY].entry[1]
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,data.pageId,data.entryId)
	local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
	for p,q in ipairs(itemList) do
		local itemId = q.itemId
		if list[itemId] then
			local oldItemNum = list[itemId].itemNum
			list[itemId].itemNum = oldItemNum + q.itemNum
		else
			list[itemId] = q
		end
	end

	local resultList = {}
	for k,v in pairs(list) do
		table.insert(resultList, v)
	end

	return resultList
end

function UISubPkC:InitEvent()
	self:SetWndClick(self.mHelpBtn, function(...) self:OnClickHelp() end)
	self:SetWndClick(self.mBtnBuy, function(...) self:OnClickBuy() end)
	self:SetWndClick(self.mQuickBtn, function(...) self:OnClickShowQuickPop() end)
	self:SetWndClick(self.mDesText2, function(...) self:OnClickGoTo() end)
	self:SetWndClick(self.mBuyTipsBtn, function(...) self:OnClickByTips() end)
end

function UISubPkC:OnTargetWndClose(wndName)
	if wndName == "UIAward" and self._needShowGift then
		--重新开启滑动
		self:ShowGiftPop()
	end
end
------------------------------------------------------------------
return UISubPkC


