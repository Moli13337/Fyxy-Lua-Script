---
--- Created by Administrator.
--- DateTime: 2023/10/11 16:30:37
---
---活动2 ---每日首充
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubOrdinTarget:LChildWnd
local UISubOrdinTarget = LxWndClass("UISubOrdinTarget", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubOrdinTarget:UISubOrdinTarget()
	---@type table<number,CommonIcon>
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubOrdinTarget:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubOrdinTarget:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubOrdinTarget:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self.jpj = gLGameLanguage:IsJapanVersion()
	self:RefreshForeign()
	self:InitData()
	self:SetPara()
	--self:SetTop()
	self:InitMsg()
	self:InitUIEvent()
	
	--local pbData = gModelActivity:GetActivityPageBySid(self._sid)
	--if pbData then
	--	self:OnActivityPageResp(pbData)
	--else
	--	gModelActivity:OnActivityPageReq(self._sid)
	--end
	self._isVie = gLGameLanguage:IsVieVersion()
	self:RefreshForeign()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if self._sid ~= sid then
			return
		end
		self:SetTop()
		gModelActivity:OnActivityPageReq(self._sid)
	end)

	gModelActivity:ReqActivityConfigData(self._sid)

	self:TimerStart("delaySetRect",0.4,false,1)
end

function UISubOrdinTarget:OnDrawReward(list, item,itemdata,itempos)
	local itemType,itemRefId,itemCount = itemdata.itemType,itemdata.itemId,itemdata.itemNum
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local EffTrans = self:FindWndTrans(item,"Eff")
	if EffTrans then
		local show = false
		if itemType == LItemTypeConst.TYPE_ITEM then
			LxResUtil.DestroyChildImmediate(EffTrans)
			local itemRef = gModelItem:GetRefByRefId(itemRefId)
			local bgEff = itemRef and itemRef.bgEff or nil
			if not string.isempty(bgEff) then
				show = true
				local instanceId = item:GetInstanceID()
				self:CreateWndEffect(EffTrans,bgEff,instanceId,90,false,false)
			end
		end
		CS.ShowObject(EffTrans,show)
	end
--[[	local baseClass = UICommon:New()
	local formatData =
	{
		itemId = itemRefId,
		itemType = itemType,
		itemNum = itemCount,
	}
	local data =
	{
		showName = false,
		showTip = true,
		itemType = itemCount,
		itemId = itemRefId,
		itemNum = -1,
		parentTran = itemRoot,
		clickFunc =function() gModelGeneral:ShowCommonItemTipWnd(formatData) end
	}
	baseClass:Show(data)]]

	if itemRoot then
		local formatData =
		{
			itemId = itemRefId,
			itemType = itemType,
			itemNum = itemCount,
		}
		local uiCommonList = self._uiCommonList
		local InstanceID = item:GetInstanceID()
		local baseClass = uiCommonList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiCommonList[InstanceID] = baseClass
			baseClass:Create(CS.FindTrans(itemRoot,"Icon"))
		end
		baseClass:SetCommonReward(itemType, itemRefId, -1)
		self:SetWndClick(itemRoot, function()
			gModelGeneral:ShowCommonItemTipWnd(formatData)
		end)
		baseClass:DoApply()
	end

	local numStr = LUtil.NumberCoversion(itemCount)
	self:SetWndText(itemNum,numStr)
end

function UISubOrdinTarget:GetSortFunc()
	return function (a,b)
		local aPrio = self._statePriority[a.state] or 1
		local bPrio = self._statePriority[b.state] or 1

		if aPrio ~=bPrio then
			return aPrio<bPrio
		end
		return a.entryId<b.entryId
	end
end

function UISubOrdinTarget:RefreshForeign()
	local Text1 = CS.FindTrans(self.mTextObj, "Text1")
	local Text2 = CS.FindTrans(self.mTextObj, "Text2")
	if self._isVie then
		self:InitTextSizeWithLanguage(Text1,-2)
		self:InitTextSizeWithLanguage(Text2,-2)
		self:SetAnchorPos(self.mTextObj,Vector2.New(0,16.5))
		LxUiHelper.SetSizeWithCurAnchor(Text1, 0, 80)
	end
end


function UISubOrdinTarget:OnClickHelp()
	local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityCfg then
		return
	end
	local data = activityCfg.config
	local title = gModelActivity:GetLngNameByActivitySid(self._sid)
	local content = data.helpTipsContent

	GF.OpenWnd("UIBzTips",{title= title,text = content})
end

function UISubOrdinTarget:InitData()
	self._countDownTimer = "_countDownTimer"
	self._entryIdToIndex ={}

	self._btnStrs=
	{
		[0] =ccClientText(12206),-- "未完成"),
		[1] =ccClientText(12207), --"领  取",
		[2] =ccClientText(12208), --"已领取",
	}
	---(0-不可领取, 1-可领取，2-已领取)
	self._statePriority =
	{
		[0] = 2,
		[1] = 1,
		[2] = 3,
	}
	self._uiCommonList = {}

	self._stateImg =
	{
		[0] = "public_btn_2_1",
		[1] = "public_btn_2_2",
		[2] = "public_btn_ash_2",
	}
	self._stateColor =
	{
		[0] = "5C6D9AFF",
		[1] = "FFFFFFFF",
		[2] = "FFFFFFFF",
	}

	local Text1 = CS.FindTrans(self.mTextObj, "Text1")
	self:SetWndText(Text1, ccClientText(11936))
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(Text1)
end

function UISubOrdinTarget:OnClickEntry(itemdata)
	local state = itemdata.state
	if state == 0 then

		if self._isEnd then
			local str =ccClientText(14301) --"活动已结束"
			GF.ShowMessage(str)
			return
		end

		if itemdata.jumpId and itemdata.jumpId>0 then
			local isOpen = gModelFunctionOpen:CheckIsOpened(itemdata.jumpId,true)
			if isOpen then
				gModelFunctionOpen:Jump(itemdata.jumpId)
				local wnd = self:GetParentWnd()
				if wnd then
					wnd:WndClose()
				end
			end
		else
			GF.ShowMessage(ccClientText(14303)) --"任务未完成，无法领取"
		end

	elseif state == 1 then
		local sid = self._sid
		local pageId = self._pageId
		local entryId = itemdata.entryId
		gModelActivity:OnActivityReceiveGoalReq(sid,pageId,entryId)
	elseif state == 2 then
		GF.ShowMessage(ccClientText(12208))
	end

end

function UISubOrdinTarget:RefreshForeign()
	local Text1 = CS.FindTrans(self.mTextObj, "Text1")
	local Text2 = CS.FindTrans(self.mTextObj, "Text2")
	if self.jpj then
		self:InitTextSizeWithLanguage(Text1,-2)
		self:InitTextSizeWithLanguage(Text2,-2)
		self:SetAnchorPos(self.mTextObj,Vector2.New(8,16.5))
		LxUiHelper.SetSizeWithCurAnchor(Text1, 0, 80)
	end
end

function UISubOrdinTarget:FindVipRef(vipLv)
	for _, v in pairs(GameTable.PremiumLevelRef) do
		if v.level == vipLv then
			return v
		end
	end
end

function UISubOrdinTarget:SetPara()
	self._sid = self:GetWndArg("sid")

end

function UISubOrdinTarget:SetTop()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end

	local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityCfg then
		return
	end
	--local moreInfo = activityData.moreInfo
	local data = activityCfg.config
	local path = data.image
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTop,path,function ()
			CS.ShowObject(self.mTop,true)
		end)
	end
	path = data.descIcon
	if LxUiHelper.IsImgPathValid(path) then
		CS.ShowObject(self.mTextImg,true)
		self:SetWndEasyImage(self.mTextImg,path,nil, true, true)
	end

	self.vipShow = data.vipShow
	if self.vipShow == 1 then
		CS.ShowObject(self.mVipLvBg, true)
		self:UpdataVipShow()
		if not string.isempty(data.vipPosition) then
			self:SetAnchorPos(self.mVipLvBg, LxDataHelper.ParseVector2NotEmpty(data.vipPosition))
		end
	end

	self:SetAnchorPos(self.mTextImg, LxDataHelper.ParseVector2NotEmpty(data.descIconPosition))

	--if not gLGameLanguage:IsForeignRegion() then
	--	self:SetSize(self.mTextImg,data.descIconSize)
	--end

	if not string.isempty(data.Text) then
		local text =string.gsub(data.Text,"\\n",'\n')

		self:SetWndText(self.mIntro,text)
		local textPos = data.TextPosition
		self:SetAnchorPos(self.mTextBg, LxDataHelper.ParseVector2NotEmpty(textPos))
		CS.ShowObject(self.mTextBg, true)
	else
		self:SetWndText(self.mIntro,"")
		CS.ShowObject(self.mTextBg, false)
	end


	local showHelp = data.helpTips == 1
	CS.ShowObject(self.mHelpBtn,showHelp)
	if showHelp then
		self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(data.helpTipsPosition))
	end

	local showEndTime = data.endTime == 1
	if showEndTime then
		self:SetAnchorPos(self.mTimeBg, LxDataHelper.ParseVector2NotEmpty(data.endTimePosition))

		self:SetCountDown()
		self:TimerStop(self._countDownTimer)
		self:TimerStart(self._countDownTimer,1,false,-1)
	end

	CS.ShowObject(self.mTimeBg,showEndTime)

	local showJumpBtn = not string.isempty(data.jumpBtn)

	CS.ShowObject(self.mJumpBtn,showJumpBtn)
	if showJumpBtn then
		self:SetWndEasyImage(self.mJumpBtn,data.jumpBtn)
		--local text = self:FindWndTrans(self.mJumpBtn,"text")
		--self:SetWndText(text,data.jumpBtnText)
		self:SetWndButtonText(self.mJumpBtn,data.jumpBtnText)
		self:SetAnchorPos(self.mJumpBtn, LxDataHelper.ParseVector2NotEmpty(data.jumpBtnPosition))
		self:SetWndClick(self.mJumpBtn,function ()
			if not gModelFunctionOpen:CheckIsOpened(data.jumpBtnId,true) then
				return
			end
			gModelFunctionOpen:Jump(data.jumpBtnId)
		end)

	end
end

function UISubOrdinTarget:InitUIEvent()
	self:SetWndClick(self.mHelpBtn,function () self:OnClickHelp() end)
end

function UISubOrdinTarget:SetCountDown()
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

			local list = self:GetUIScroll("itemList")
			local uiList = list:GetList()
			if uiList then
				uiList:DrawAllItems()
			end

			self:TimerStop(self._countDownTimer)
		else
			str = LUtil.FormatTimespanCn(timeSpan)
			str = ccClientText(14302)..str  --活动剩余时间：
		end
	end

	self:SetWndText(self.mTimeText,str)
end

--function UISubOrdinTarget:SetAnchorPos(rectTran,str)
--	if string.isempty(str) then
--		return
--	end
--	local strs = string.split(str,",")
--	if #strs>=2 then
--		local posX = tonumber(strs[1])
--		local posY = tonumber(strs[2])
--		local pos = Vector2.New(posX,posY)
--		rectTran.anchoredPosition = pos
--	end
--end

function UISubOrdinTarget:SetSize(rectTran,str)
	if string.isempty(str) then
		return
	end
	local strs = string.split(str,",")
	if #strs>=2 then
		local width = tonumber(strs[1])
		local height = tonumber(strs[2])
		local size = Vector2.New(width,height)
		rectTran.sizeDelta = size
	end
end

function UISubOrdinTarget:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then
		return
	end

	local page = pb.pages[1]
	if not page then
		return
	end
	self._pageId = page.pageId
	local structPage = StructActivityPage:New()
	structPage:CreateByPb(page)
	self:RefreshUI(structPage)
end

function UISubOrdinTarget:OnDrawItem(list,item,itemdata,itempos)
	local titleBg = self:FindWndTrans(item,"titleBg")
	local titleBgTitle = self:FindWndTrans(titleBg,"title")
	local rewardList = self:FindWndTrans(item,"rewardList")
	local btn = self:FindWndTrans(item,"btn")
	local btnText = self:FindWndTrans(btn,"text")
	local ShowText = self:FindWndTrans(item,"Show")

	local progressStr = string.format("(%s/%s)",itemdata.schedule,itemdata.goal)
    progressStr = LUtil.FormatColorStr(progressStr,"lightYellow")
	--printInfoNR("======itemdata.icon = 	",itemdata.icon)
	self:SetWndEasyImage(titleBg,itemdata.icon,function()
		CS.ShowObject(titleBg,true)
	end)
	local title =itemdata.desc
	self:SetWndText(titleBgTitle,title)
	local InstanceID = item:GetInstanceID()
	local uiList =  self:GetUIScroll("key"..InstanceID)
	local list = uiList:GetList()
	if(list)then
		uiList:RefreshList(itemdata.rewards)
		list:SetContentPosition(0,0)
	else
		uiList:Create(rewardList,itemdata.rewards,function (...) self:OnDrawReward(...)  end)
		list = uiList:GetList()
		list:SetContentPosition(0,0)
	end
	if #itemdata.rewards >5 then
		uiList:EnableScroll(true,true)
	end

	local btnstr = self._btnStrs[itemdata.state]
	local btnState = 0
	if itemdata.state == 0 then
		btnState = 0
		if itemdata.jumpId and itemdata.jumpId >0 then
			btnstr = itemdata.jumpDesc
		end
		if self._isEnd then
			btnstr = ccClientText(14304)
			btnState = 2
		end
	elseif itemdata.state == 1 then
		btnState = 1
	elseif itemdata.state == 2 then
		btnState = 2
	end

	local showBtnEff = btnState== 1
	local instanceId = btn:GetInstanceID()
	if showBtnEff then
		self:CreateWndEffect(btn,"fx_anniu_02",instanceId,100)
	else
		self:DestroyWndEffectByKey(instanceId)
	end

	local img = self._stateImg[btnState]
	self:SetWndEasyImage(btn, img)
	self:SetXUITextTransColor(btnText, self._stateColor[btnState])

	if ShowText then
		CS.ShowObject(ShowText,itemdata.state == 2)
	end
	CS.ShowObject(btn,itemdata.state ~= 2)

	local DescTxtTrans = self:FindWndTrans(item, "DescTxt")
	if DescTxtTrans then
		local color = "red"
		if btnState ~= 0 then color = "green" end

		local str = string.format("(%s/%s)",itemdata.schedule,itemdata.goal)
		str = LUtil.FormatColorStr(str,color)
		self:SetWndText(DescTxtTrans,str)
		if self.jpj then
			self:InitTextSizeWithLanguage(DescTxtTrans,-4)
		end
	end

	--self:SetImageActorState(btn,btnState)
	self:SetWndText(btnText,btnstr)
	self:SetWndClick(btn,function () self:OnClickEntry(itemdata) end)

	self._entryIdToIndex[itemdata.entryId]= itempos
end

function UISubOrdinTarget:InitItemList(dataList)
	local uiList = self:GetUIScroll("itemList")


	uiList:Create(self.mItemList,dataList,function (...) self:OnDrawItem(...)  end,UIItemList.WRAP)
end

function UISubOrdinTarget:OnTimer(key)
	if key == self._countDownTimer then
		self:SetCountDown()
	elseif key == "delaySetRect" then
		self:ChangeEffMaskRect()

	end
end

function UISubOrdinTarget:UpdataVipShow()
	if self.vipShow ~= 1 then
		CS.ShowObject(self.mVipLvBg, false)
		return
	end

	local serVipExp = gModelPlayer:GetVipExp()
	local vip = gModelPlayer:GetVipLevel()
	local curRef = self:FindVipRef(vip)
	local nextVip = vip + 1
	local nextRef = self:FindVipRef(nextVip)
	local isMax = false
	if not nextRef then
		nextVip = vip
		nextRef = self:FindVipRef(nextVip)
		isMax = true
	end
	local curExp = curRef.upNeed
	local nextExp = nextRef.upNeed
	local needExp = nextExp - curExp
	local tempCurExp = serVipExp - curExp
	local percentage = tempCurExp / needExp
	LxUiHelper.SetProgress(self.mVipLvBar, percentage)
	self:SetWndEasyImage(self.mVipLvIcon, "vip_icon_bg_" .. curRef.level)
	local str = string.format("%s/%s", tempCurExp, needExp)
	self:SetXUITextText(self.mVipLvExpTxt, str)

	if isMax then
		CS.ShowObject(self.mTextObj, false)
		return
	end
	local s = string.replace(ccClientText(11937), needExp - tempCurExp, string.replace(ccClientText(11900), nextRef.level))
	local tran = CS.FindTrans(self.mTextObj, "Text2")
	self:SetWndText(tran, s)
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(tran)
end

--function UISubOrdinTarget:OnActivityReceiveGoalResp(pb)
	--if self._sid ~= pb.sid or self._pageId ~= pb.pageId then
	--	return
	--end
    --
	--local index = self._entryIdToIndex[pb.entryId]
	--if not index then
	--	return
	--end
    --
	--local data = self._dataList[index]
	--if data then
	--	data.state = 2
	--end
	--local func = self:GetSortFunc()
	--table.sort(self._dataList,func)
    --
	--self._entryIdToIndex={}
	--local list = self:GetUIScroll("itemList")
	--list:RefreshData(self._dataList)

--end

function UISubOrdinTarget:RefreshUI(page)
	local pageId = page.pageId
	local pageCfg = gModelActivity:GetWebActivityPageData(self._sid,pageId)
	if not pageCfg then
		return
	end


	local dataList = {}
	for k,v in ipairs(pageCfg.entries) do
		local entryId = v.id
		local entryData = page:GetEntry(entryId)
		if entryData then
			local data ={}
			data.entryId = entryId
			data.title = v.name
			data.desc = v.description
			data.state = entryData.goalData.status  --(0-不可领取, 1-可领取，2-已领取)
			data.schedule = entryData.goalData.schedules[1].schedule
			data.goal = entryData.goalData.schedules[1].goal
			data.rewards = LxDataHelper.ParseItem(v.reward)
			data.icon = v.icon
			data.jumpId = tonumber(v.jumpId)
			data.jumpDesc = v.jumpDesc
			table.insert(dataList,data)
		end

	end

	local func = self:GetSortFunc()
	table.sort(dataList,func)

	self._dataList = dataList
	self:InitItemList(dataList)
end

function UISubOrdinTarget:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			local sid = v.sid
			if self._sid == sid then
				gModelActivity:OnActivityPageReq(self._sid)
				break
			end
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
	self:WndNetMsgRecv(LProtoIds.PlayerChangeResp,function() self:UpdataVipShow() end)
	--self:WndNetMsgRecv(LProtoIds.ActivityReceiveGoalResp,function (...) self:OnActivityReceiveGoalResp(...) end)
end


------------------------------------------------------------------
return UISubOrdinTarget


