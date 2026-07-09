---
--- Created by BY.
--- DateTime: 2023/10/30 20:24:53
---
---活动24 周末狂欢
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubWeekend:LChildWnd
local UISubWeekend = LxWndClass("UISubWeekend", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubWeekend:UISubWeekend()
	self._bgImages = {
		"activity5_itembg1",
		"activity5_itembg2",
		"activity5_itembg3"
	}

	self._itemColors = {
		"139057FF",
		"133f90FF",
		"734f22FF"
	}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubWeekend:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubWeekend:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubWeekend:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubWeekend:RefreshData()
	local list = self.pages[1].entry
	self._currDay = 0
	table.sort(list,function (a,b)
		return a.sort < b.sort
	end)
	for i, v in ipairs(list) do
		local status = v.goalData.status
		if(status == 1 or status == 2)then
			self._currDay = i
		end
	end
	if(self._uiList)then
		self._uiList:RefreshData(list)
	else
		self._uiList = self:GetUIScroll("cell")
		self._uiList:Create(self.mGiftScroll,list,function (...) self:ListItem(...) end)
	end
end

function UISubWeekend:PlayEff(trans,eff,key)
	self:CreateWndEffect(trans,eff,key,100,false,false)
end

function UISubWeekend:OnClickGet(itemdata)--点击领取
	gModelActivity:OnActivityReceiveGoalReq(self._sid,itemdata.pageId,itemdata.entryId)
end

function UISubWeekend:ResetData(pb)
	local sid = pb.sid
	if(self._sid ~= sid)then
		return
	end
	self.pages = {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		table.insert(self.pages,page)
	end
	self:RefreshData()
end

function UISubWeekend:InitEvent()
	self:SetWndClick(self.mHelpBtn, function(...) self:OnClickHelp() end,LSoundConst.CLICK_ERROR_COMMON)
end

function UISubWeekend:ListItem(list,item, itemdata, itempos)
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local bg = CS.FindTrans(item,"Image")
	local gift = CS.FindTrans(item,"Gift")
	local icon = CS.FindTrans(item,"Gift/Icon")
	local eff = CS.FindTrans(item,"Gift/Eff")
	local redPoint = CS.FindTrans(item,"Icon/redPoint")
	local nameText = CS.FindTrans(item,"NameText")
	local awardScroll = CS.FindTrans(item,"AwardScroll")
	local scrollRoot = CS.FindTrans(item,"AwardScroll/ItemRoot")
	local maskImage = CS.FindTrans(item,"MaskImage")
	local InstanceID = item:GetInstanceID()
	local entryId = itemdata.entryId
	local status = itemdata.goalData.status
	local maskIcon = ""
	local isGet = status == 1
	CS.ShowObject(eff,isGet)
	CS.ShowObject(redPoint,isGet)
--[[	CS.ShowObject(icon,not isGet)
	if(isGet)then
		self:PlayEff(eff,"fx_zhoumokuanghuan_"..entryId,InstanceID)
	else
		self:SetWndEasyImage(icon,entryCfg1.icon, nil ,true)
	end]]
	self:SetWndEasyImage(icon,entryCfg1.icon, function()
		CS.ShowObject(icon,true)
	end ,true)

	self:SetWndEasyImage(bg, self._bgImages[itempos])

	local isMask = false
	if(status == 0 and entryId < self._currDay)then
		isMask = true
		maskIcon = "activity_timeout"		--过期状态，前端判断
	elseif(status == 2)then
		isMask = true
		maskIcon = "public_txt_13_1"				--已领取状态
	end
	self:SetWndText(nameText,entryCfg1.name)
	self:SetXUITextTransColor(nameText, self._itemColors[itempos])
	CS.ShowObject(maskImage,maskIcon ~= "")
	if(maskIcon ~= "")then
		self:SetWndEasyImage(maskImage,maskIcon, nil, true)
	end
	self:SetWndClick(item, function(...)
		if(isGet)then
			self:OnClickGet(itemdata)
		end
	end)
	if awardScroll then
		local pageId = itemdata.pageId
		local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
		local showList = {}
		for i,v in ipairs(itemList) do
			table.insert(showList,{
				itemData = v,
				status = status,
				pageId = pageId,
				entryId = entryId,
			})
		end
		if(#showList>2)then
			scrollRoot.anchoredPosition = Vector2.New(0,0)
			scrollRoot.anchorMin = Vector2.New(0,1)
			scrollRoot.anchorMax = Vector2.New(0,1)
			scrollRoot.pivot = Vector2.New(0,1)
		else
			scrollRoot.anchoredPosition = Vector2.New(0,0)
			scrollRoot.anchorMin = Vector2.New(0.5,1)
			scrollRoot.anchorMax = Vector2.New(0.5,1)
			scrollRoot.pivot = Vector2.New(0.5,1)
		end
		self:InitAwardScroll(awardScroll,showList)


--[[		local uiIconEasyList = self._uiList:GetItemCls(InstanceID)
		if(not uiIconEasyList)then
			uiIconEasyList = UIIconEasyList:New()
			self._uiList:SetItemCls(InstanceID, uiIconEasyList)
			uiIconEasyList:Create(self, awardScroll)
			uiIconEasyList:SetShowNum(false)
			uiIconEasyList:SetShowExtraNum(true,"NumTxt")

			if(#itemList>2)then
				uiIconEasyList:EnableScroll(true,true)
				scrollRoot.anchoredPosition = Vector2.New(0,0)
				scrollRoot.anchorMin = Vector2.New(0,1)
				scrollRoot.anchorMax = Vector2.New(0,1)
				scrollRoot.pivot = Vector2.New(0,1)
			else
				scrollRoot.anchoredPosition = Vector2.New(0,0)
				scrollRoot.anchorMin = Vector2.New(0.5,1)
				scrollRoot.anchorMax = Vector2.New(0.5,1)
				scrollRoot.pivot = Vector2.New(0.5,1)
			end
		end
		uiIconEasyList:SetShowMask(isMask,"MaskImg")
		uiIconEasyList:RefreshList(itemList)]]
	end
end

function UISubWeekend:InitCommand()
	self._sid = self:GetWndArg("sid")
	gModelActivity:ReqActivityConfigData(self._sid)
end

function UISubWeekend:InitAwardScroll(listTrans,list)
	local listKey = listTrans:GetInstanceID()
	local uiList = self:FindUIScroll(listKey)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(listKey)
		uiList:Create(listTrans,list,function(...)
			self:OnDrawAwardItem(...)
		end)
	end
end

function UISubWeekend:OnClickHelp()--点击帮助
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local _sid = self._sid
	local activityWedData = gModelActivity:GetWebActivityDataById(_sid)
	if not activityData then
		return
	end
	local data = activityWedData.config
	local title = gModelActivity:GetLngNameByActivitySid(_sid)
	local content = data.helpTipsContent
	local formatStr = ccClientText(18100)
	local startTime = LUtil.OSDate(formatStr, activityData.startTime)
	local endTime = LUtil.OSDate(formatStr, activityData.endTime)
	local str = string.replace(content,startTime,endTime)
	GF.OpenWnd("UIBzTips",{title= title,text = str})
end

function UISubWeekend:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			if(v.sid == self._sid and v.status ~= 3)then
				gModelActivity:OnActivityPageReq(self._sid)
				return
			end
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		local activity = pb.activity
		if(activity.sid == self._sid and activity.status ~= 3)then
			gModelActivity:OnActivityPageReq(self._sid)
		end
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then
			return
		end
		self:OnActivityConfigData()
	end)
end

function UISubWeekend:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config
	local image,descIcon,text = data.image,data.descIcon,data.text
	if LxUiHelper.IsImgPathValid(image) then
		self:SetWndEasyImage(self.mHeroImage,image,function ()
		end,true)
	end
	CS.ShowObject(self.mHeroImage,true)
	if LxUiHelper.IsImgPathValid(descIcon) then
		self:SetWndEasyImage(self.mTextImage,descIcon,function ()
			CS.ShowObject(self.mTextImage,true)
		end,true)
	end
	if(text and text~="")then
		self:SetWndText(self.mTipsText,text)
	end
	CS.ShowObject(self.mHelpBtn,data.helpTips == 1)
	CS.ShowObject(self.mTipsBg,true)
	gModelActivity:OnActivityPageReq(self._sid)

	self:InitTextLineWithLanguage(self.mTipsText,-60)
end

function UISubWeekend:OnDrawAwardItem(list,item, itemdata, itempos)
	local Icon = self:FindWndTrans(item,"CommonUI/Icon")
	local NumTxt = self:FindWndTrans(item,"NumTxt")
	local MaskImg = self:FindWndTrans(item,"MaskImg")

	local itemData = itemdata.itemData
	local baseClass = self:GetCommonIcon(item)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(itemData.itemType, itemData.itemId, itemData.itemNum)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()

	self:SetWndText(NumTxt,LUtil.NumberCoversion(itemData.itemNum))

	local effkey = item:GetInstanceID()
	local status = itemdata.status
	local isGet = status == 1
	if isGet then
		self:CreateWndEffect(Icon,"fx_ui_qiandao_lingqutishi",effkey,100,false,false)
	else
		self:DestroyWndEffectByKey(effkey)
	end
	local isMask = status == 2
	CS.ShowObject(MaskImg,isMask)

	self:SetWndClick(Icon,function()
		if isGet then
			self:OnClickGet(itemdata)
		else
			gModelGeneral:ShowCommonItemTipWnd(itemData,{showSkinCode=true})
		end
	end)
end
------------------------------------------------------------------
return UISubWeekend


