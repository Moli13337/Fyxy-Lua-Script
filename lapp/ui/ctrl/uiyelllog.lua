---
--- Created by Administrator.
--- DateTime: 2023/10/6 10:50:17
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIYellLog:LWnd
local UIYellLog = LxWndClass("UIYellLog", LWnd)

local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIYellLog:UIYellLog()
	---@type table<number,CommonIcon>
	self._uiCommonList = {}

	self._showItemEffName = "fx_daoju_orange"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIYellLog:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIYellLog:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIYellLog:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	CS.ShowObject(self.mTypeBtnList,false)

	local emptyRefId = self:GetWndArg("emptyRefId") or 201
	self:InitEmptyList(emptyRefId)

	local special = self:GetWndArg("special")
	local isSpecial = special == 1
	if isSpecial then
		self:InitSpecialData()
	else
		self:InitData()
		self:SetXUITextText(self.mTitle,self._titleStr)
	end

	self:InitEvent()
	self:InitMsg()

	CS.ShowObject(self.mCallLogList,false)
	CS.ShowObject(self.mCallLogNewList,true)
	if self._callType then
		gModelCallHero:OnCallLogReq(self._callType,self._sid)
	elseif isSpecial then
		self:InitSpecialList()
	else
		self:InitList()
	end
end

function UIYellLog:GetActivityLog()
	local list = {}
	local activityCallHeroLog = LPlayerPrefs.activityCallHeroLog
	local actLogList = string.split(activityCallHeroLog,"-")
	for i,v in ipairs(actLogList) do
		v = string.split(v,"|")
		local actSid,actCreateTime,actNum,actName,rewards = tonumber(v[1]),tonumber(v[2]),tonumber(v[3]),v[4],v[5]
		if actSid == self._sid then
			local rewardList = string.split(rewards,";")
			local keyList = {}
			for rewardIdx,rewardData in ipairs(rewardList) do
				rewardData = string.split(rewardData,":")
				local rewardKey,rewardInfo = rewardData[1],rewardData[2]
				local rewardInfoList = string.split(rewardInfo,",")
				for idx,data in ipairs(rewardInfoList) do
					local keyDataList = keyList[rewardKey]
					if not keyDataList then
						keyDataList = {}
						keyList[rewardKey] = keyDataList
					end
					data = string.split(data,"=")
					table.insert(keyDataList,{
						type = tonumber(data[1]),
						itemId = tonumber(data[2]),
						count = tonumber(data[3]),
					})
				end
			end
			table.insert(list,{
				sid = actSid,
				name = actName,
				num = actNum,
				fixedReward = keyList.fixedReward or {},
				extraReward = keyList.extraReward or {},
				consume = keyList.consume or {},
				createTime = actCreateTime,
			})
		end
	end
	return list
end

function UIYellLog:ChangeLogNum()
	local str = ccClientText(11622)
	if self._tipsStr then
		str = self._tipsStr
	elseif self._callType == 1 then
		local refId = self._btnRefId
		local ref = gModelCallHero:GetCallRefByRefId(refId)
		if ref then
			str = string.replace(str,ref.journalNumMax)
		end
	elseif self._callType == 2 then
		local heartCallJournalNumMax = GameTable.SummonConfigRef["heartCallJournalNumMax"]
		str = string.replace(str,heartCallJournalNumMax)
	elseif self._callType == 4  then
		local callRefData = gModelCallHero:GetTypeData(self._callType)[ModelCallHero.CALL_TYPE_REGRESSION]
		local ref = gModelCallHero:GetCallRefByRefId(callRefData and callRefData.refId)
		if ref then
			str = string.replace(str,ref.journalNumMax)
		end
	elseif self._sid then
		if self._maxNum then
			str = string.replace(str,self._maxNum)
		else
			str = ""
		end
	end
	self:SetWndText(self.mDesc,str)
end

function UIYellLog:OnDrawBtn(list, item, itemdata, itempos, fromHeadTail)
--[[	local btnTrans = CS.FindTrans(item,"Btn")
	if btnTrans then
		local srot = itemdata.srot
		local refId = itemdata.refId
		local name = ccLngText(itemdata.typeName)
		local btnList = self._btnList
		local curBtn = btnList[srot]
		if not curBtn then
			curBtn = btnTrans
			btnList[srot] = curBtn
		end
		local SelImg = CS.FindTrans(btnTrans,"SelImg")
		self:SetWndClick(curBtn,function()
			self:BtnEvent(refId,srot)
		end)
		local XUITrans = CS.FindTrans(btnTrans,"BtnName")
		if XUITrans then
			local xui = self:FindWndText(XUITrans)
			self:SetXUITextText(xui,name)
		end
		self:ChangeBtnImage(srot,SelImg,XUITrans)
	end]]

	local srot = itemdata.srot
	local refId = itemdata.refId
	local name = ccLngText(itemdata.typeName)
	local BtnTab1Trans = self:FindWndTrans(item,"BtnTab1")
	if BtnTab1Trans then
		self._btnList[srot] = BtnTab1Trans
		self:SetWndClick(BtnTab1Trans,function()
			self:BtnEvent(refId,srot)
		end)
		local status = self._lastbtn == srot and 0 or 1
		self:SetWndTabStatus(BtnTab1Trans,status)
		self:SetWndTabText(BtnTab1Trans,name,-4)
	end
end

function UIYellLog:CreatePayList(trans,list)
	local InstanceID = trans:GetInstanceID()
	local uiList = self:FindUIScroll(InstanceID)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(InstanceID)
		uiList:Create(trans,list,function(...) self:OnDrawPayCell(...)  end)
	end
end

function UIYellLog:InitEvent()
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mShareMask,function() CS.ShowObject(self.mShareMask,false) end)
end

function UIYellLog:GetCallLogList()
	local list = {}
	local logs = {}
	local callType = self._callType
	if callType then
		logs = gModelCallHero:GetLogList()
	else
		logs = self:GetActivityLog()
	end
	if logs and #logs > 0 then
		table.sort(logs,function(log1,log2)
			local time1,time2 = tonumber(log1.createTime),tonumber(log2.createTime)
			return time1 > time2
		end)
		local lastbtn = self._lastbtn
		for i,v in ipairs(logs) do
			if callType == 1 then
				local ref = gModelCallHero:GetCallRefByRefId(v.refId)
				if ref.srot == lastbtn then
					table.insert(list,v)
				end
			else
				table.insert(list,v)
			end
		end
	end
	return list
end

function UIYellLog:BtnEvent(refId,index)
	print("---- refId,index = ",refId,index)
	self._btnRefId = refId
	-- 按钮背景换颜色
	self._lastbtn = index
	self:ChangeBtnImage()
	self._changeBtn = true
	self:InitList()
end

function UIYellLog:InitSpecialData()
	---@type StructLotteryLogData[]
	self._logList = self:GetWndArg("logList")

	self._logTimeTips = self:GetWndArg("logTimeTips")

	self:SetXUITextText(self.mTitle,self:GetWndArg("logTitle"))
	self:SetWndText(self.mDesc,self:GetWndArg("logTips"))
end

function UIYellLog:InitMsg()
	self:WndNetMsgRecv(LProtoIds.CallLogResp,function()
		self:InitList()
	end)
end

function UIYellLog:OnDrawCallLogNewItem(list, item, itemdata, itempos, fromHeadTail)
	local HeroList = self:FindWndTrans(item,"HeroList")
	local BottomDiv = self:FindWndTrans(item,"BottomDiv")

	local ShareDiv = self:FindWndTrans(BottomDiv,"ShareDiv")
	local AutoDiv = self:FindWndTrans(ShareDiv,"AutoDiv")
	local ouqiTxt = self:FindWndTrans(AutoDiv,"ouqiTxt")
	local Image = self:FindWndTrans(AutoDiv,"Image")
	local ShareBtn = self:FindWndTrans(AutoDiv,"ShareBtn")

	local TopDiv = self:FindWndTrans(BottomDiv,"TopDiv")
	local XHTxt = self:FindWndTrans(TopDiv,"XHTxt")
	local FreeTxt = self:FindWndTrans(XHTxt,"FreeTxt")
	local CallTime = self:FindWndTrans(TopDiv,"CallTime")
	local PayList = self:FindWndTrans(XHTxt,"PayList")

	local descDiv = self:FindWndTrans(BottomDiv, "DescribeDiv")

	--- TopDiv 高度 默认开启的
	local height = 40
	local fixedReward,extraReward = itemdata.fixedReward,itemdata.extraReward
	if HeroList then
		local listNum = self:CreateIconList(HeroList,fixedReward,extraReward)
		height = height + math.ceil(listNum / 6) * 80
	end

	if XHTxt then
		self:SetWndText(XHTxt,ccClientText(11654))
	end

	if CallTime then
		local createTime = itemdata.createTime
		local str = self._timeStr or ccClientText(11655)
		local timeStr = LUtil.FormatTimeStr(createTime,"%Y/%m/%d %H:%M")
		str = string.replace(str,timeStr)
		self:SetWndText(CallTime,str)
		self:InitTextSizeWithLanguage(CallTime, -2)
	end

	local consume = itemdata.consume
	local isFree = #consume <= 0
	if FreeTxt then
		self:SetWndText(FreeTxt,ccClientText(11657))
	end
	CS.ShowObject(FreeTxt,isFree)

	if PayList and not isFree then
		self:CreatePayList(PayList,consume)
	end
	CS.ShowObject(PayList,not isFree)

	local rankValue,id = itemdata.rankValue,itemdata.id
	local showShareDiv = rankValue ~= nil and rankValue ~= 0 and id ~= nil and id ~= 0 and self._callType == 1 or false
	if showShareDiv then
		height = height + 45
		local oqStr = string.replace(ccClientText(11678),rankValue)
		self:SetWndText(ouqiTxt,oqStr)
		self:SetWndClick(ShareBtn,function()
			self:OnClickShareFunc(Image,id,ShareBtn)
		end)
	end
	CS.ShowObject(ShareDiv,showShareDiv)

	local _showDescStr = self._showDescStr
	if _showDescStr then
		local txtTrans = self:FindWndTrans(descDiv,"Txt")
		local otherInfo = itemdata.otherInfo
		local otherInfoArr = string.split(otherInfo,"|")
		local txtStr = string.replace(_showDescStr,otherInfoArr[1],otherInfoArr[2])
		self:SetWndText(txtTrans, txtStr)
		height = height + 45
	end
	CS.ShowObject(descDiv, _showDescStr)


	LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
end

function UIYellLog:OnClickShareFunc(iconTrans,id,ShareBtn)
	local data = {
		root = ShareBtn,
		shareType = ModelChat.CHATSHARE_CALL,
		shareData = tostring(id),
	}
	gModelGeneral:OpenShareTip(data)

--
--	if not gModelFunctionOpen:CheckIsOpened(11700000,true) then
--		return
--	end
--	CS.ShowObject(self.mShareMask,true)
--
--	self._callLogId = id
--
--	local canvasRect = LGameUI.GetUICanvasRoot()
--	local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,iconTrans)
--	self.mShareImage.localPosition = targetPos - Vector3.New(100,75,0)
--
--	local list = gModelChat:GetShareConfigChannlByRefId(gModelChat:GetChatConfigRefByKey("chatHeroShareRefId"))
--	local uiShareList = self._uiShareList
--	if uiShareList then
--		uiShareList:RefreshList(list)
--	else
--		uiShareList = self:GetUIScroll("ShareList")
--		self._uiShareList = uiShareList
--		uiShareList:Create(self.mShareScroll,list,function (...) self:ListChannelCell(...) end)
--	end
end




function UIYellLog:InitSpecialList()
	local list = self._logList or {}

	---@type UIItemList
	local uiCallLogNewList = self._uiCallLogNewList
	if not uiCallLogNewList then
		uiCallLogNewList = self:GetUIScroll("uiCallLogNewList")
		self._uiCallLogNewList = uiCallLogNewList
		uiCallLogNewList:Create(self.mCallLogNewList,list,function(...)
			self:OnDrawCallLogSpecialItem(...)
		end,UIItemList.SUPER,false)
		local superList = uiCallLogNewList:GetList()
		superList:RefreshList()
	else
		local superList = uiCallLogNewList:GetList()
		uiCallLogNewList:RefreshList(list)
		if self._changeBtn then
			self._changeBtn = false
			superList:MoveToPos(1,0)
		else
			superList:DrawAllItems(true)
		end
	end

	local isEmpty = #list < 1
	CS.ShowObject(self.mNoRecord,isEmpty)
	CS.ShowObject(self.mDesc,not isEmpty)
end
--
--function UIYellLog:ListChannelCell(list,item, itemdata, itempos)
--	local btn = CS.FindTrans(item,"ChannelBtn")
--	local btnText = CS.FindTrans(btn,"XUIText")
--	self:SetWndText(btnText,itemdata.name)
--	local channelId = itemdata.channelId
--	if channelId == 4 then
--		local guildBool = gModelGuild:GetBHaveGuild()
--		if not guildBool then
--			self:SetWndImageGray(btn,not guildBool)
--			self:SetWndClick(btn, function(...)
--				GF.ShowMessage(ccClientText(11526))
--			end)
--			return
--		end
--	end
--	self:SetWndClick(btn, function(...) self:OnClickShareHero(channelId) end)
--end
--
--function UIYellLog:OnClickShareHero(channelId)
--	gModelChat:OnChatShareReq(channelId,ModelChat.CHATSHARE_CALL,tostring(self._callLogId))
--	CS.ShowObject(self.mShareMask,false)
--end

function UIYellLog:CreateIconList(trans,fixedReward,extraReward)
	local list = {}
	for i,v in ipairs(fixedReward or {}) do
		table.insert(list,v)
	end
	for i,v in ipairs(extraReward or {}) do
		table.insert(list,v)
	end
	table.sort(list,function(d1,d2)
		local type1,type2 = d1.type,d2.type
		if type1 ~= type2 then
			return type1 > type2
		else
			local refId1,refId2 = d1.itemId,d2.itemId
			if type1 == LItemTypeConst.TYPE_ITEM then
				local ref1,ref2 = gModelItem:GetRefByRefId(refId1),gModelItem:GetRefByRefId(refId2)
				if ref1 and ref2 then
					return ref1.order < ref2.order
				else
					return false
				end
			else
				local ref1,ref2 = gModelHero:GetHeroRef(refId1),gModelHero:GetHeroRef(refId2)
				if ref1 and ref2 then
					local initStar1,initStar2 = ref1.initStar,ref2.initStar
					if initStar1 ~= initStar2 then
						return initStar1 > initStar2
					else
						return refId1 > refId2
					end
				else
					return false
				end
			end
		end
	end)

	local InstanceID = trans:GetInstanceID()
	local uiList = self:GetUIScroll(InstanceID)
	uiList:Create(trans,list,function(...) self:OnDrawIconCell(...)  end)
	return #list
--[[
	local transList = uiList:GetList()
	transList:EnableScroll(#list >= 6,#list >= 6)]]
end

function UIYellLog:OnDrawPayCell(list,item,itemdata,itempos)
	local PayIcon = self:FindWndTrans(item,"PayIcon")
	local PayNum = self:FindWndTrans(item,"PayNum")

	local itemId,count,itype = itemdata.itemId,itemdata.count,itemdata.type
	if PayIcon then
		local icon
		if itype == LItemTypeConst.TYPE_ITEM then
			icon = gModelItem:GetItemIconByRefId(itemId)
		end
		if icon then
			self:SetWndEasyImage(PayIcon,icon,function()
				CS.ShowObject(PayIcon,true)
			end)
		end
	end

	if PayNum then
		local number = tonumber(count)
		local num = LUtil.NumberCoversion(number)
		self:SetWndText(PayNum,num)
	end
end

function UIYellLog:InitBtnList()
	CS.ShowObject(self.mTypeBtnList,true)
	local uiBtnList = self._uiBtnList
	if not uiBtnList then
		uiBtnList = UIListEasy:New()
		uiBtnList:Create(self,self.mTypeBtnList)
		uiBtnList:EnableScroll(true,true)
		uiBtnList:SetFuncOnItemDraw(function(...)
			self:OnDrawBtn(...)
		end)
		self._uiBtnList = uiBtnList
	end
	uiBtnList:RemoveAll()
	local callRefData = gModelCallHero:GetTypeData(self._callType)
	local list = {}
	for k,v in pairs(callRefData) do
		table.insert(list,v)
	end
	table.sort(list,function(refId1,refId2)
		return refId1.srot < refId2.srot
	end)
	for i,v in ipairs(list) do
		uiBtnList:AddData(i,v)
	end
	self._lastbtn = 1
	self._btnRefId = list[1].refId
	self:ChangeBtnImage()
	uiBtnList:RefreshList()
end

function UIYellLog:InitEmptyList(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIYellLog:InitList()
	local list = self:GetCallLogList() or {}
	---@type UIItemList
	local uiCallLogNewList = self._uiCallLogNewList
	if not uiCallLogNewList then
		uiCallLogNewList = self:GetUIScroll("uiCallLogNewList")
		self._uiCallLogNewList = uiCallLogNewList
		uiCallLogNewList:Create(self.mCallLogNewList,list,function(...)
			self:OnDrawCallLogNewItem(...)
		end,UIItemList.SUPER,false)
		local superList = uiCallLogNewList:GetList()
		superList:RefreshList()
	else
		local superList = uiCallLogNewList:GetList()
		uiCallLogNewList:RefreshList(list)
		if self._changeBtn then
			self._changeBtn = false
			superList:MoveToPos(1,0)
		else
			superList:DrawAllItems(true)
		end
	end
	local isEmpty = #list < 1
	CS.ShowObject(self.mNoRecord,isEmpty)
	CS.ShowObject(self.mDesc,not isEmpty)
	self:ChangeLogNum()


--[[	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mCallLogList)
		uiList:EnableScroll(true,false)
		uiList:SetFuncOnItemDraw(function(...)
			--self:OnDrawLogCell(...)
			self:OnDrawItemLogCell(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	local list
	if self._callType then
		list = gModelCallHero:GetLogList()
	else
		list = self:GetActivityLog()
	end
	local showDesc = false
	if list then
		table.sort(list,function(log1,log2)
			local time1,time2 = tonumber(log1.createTime),tonumber(log2.createTime)
			return time1 > time2
		end)
		local insNum = 0
		for i,v in ipairs(list) do
			if self._callType == 1 then
				local ref = gModelCallHero:GetCallRefByRefId(v.refId)
				if ref.srot == self._lastbtn then
					insNum = insNum + 1
					uiList:AddData(i,v)
				end
			else
				insNum = insNum + 1
				uiList:AddData(i,v)
			end
		end
		uiList:RefreshSimpleList(UIListWrap.RefreshMode.Top)
		showDesc = true
		CS.ShowObject(self.mNoRecord,insNum == 0)
		self:ChangeLogNum()
	else
		CS.ShowObject(self.mNoRecord,true)
	end
	CS.ShowObject(self.mDesc,showDesc)]]
end


---@param itemdata StructLotteryLogData
function UIYellLog:OnDrawCallLogSpecialItem(list, item, itemdata, itempos, fromHeadTail)
	local HeroList = self:FindWndTrans(item,"HeroList")
	local BottomDiv = self:FindWndTrans(item,"BottomDiv")

	local ShareDiv = self:FindWndTrans(BottomDiv,"ShareDiv")
	local AutoDiv = self:FindWndTrans(ShareDiv,"AutoDiv")
	local ouqiTxt = self:FindWndTrans(AutoDiv,"ouqiTxt")
	local Image = self:FindWndTrans(AutoDiv,"Image")
	local ShareBtn = self:FindWndTrans(AutoDiv,"ShareBtn")

	local TopDiv = self:FindWndTrans(BottomDiv,"TopDiv")
	local XHTxt = self:FindWndTrans(TopDiv,"XHTxt")
	local FreeTxt = self:FindWndTrans(XHTxt,"FreeTxt")
	local CallTime = self:FindWndTrans(TopDiv,"CallTime")
	local PayList = self:FindWndTrans(XHTxt,"PayList")

	local descDiv = self:FindWndTrans(BottomDiv, "DescribeDiv")

	--- TopDiv 高度 默认开启的
	local height = 40
	if HeroList then
		local listNum = self:CreateIconList(HeroList,itemdata.itemList)
		height = height + math.ceil(listNum / 6) * 80
	end

	if XHTxt then
		self:SetWndText(XHTxt,ccClientText(11654))
	end

	if CallTime then
		local createTime = itemdata.createTime
		local str = self._logTimeTips or ccClientText(11655)
		local timeStr = LUtil.FormatTimeStr(createTime,"%Y/%m/%d %H:%M")
		str = string.replace(str,timeStr)
		self:SetWndText(CallTime,str)
		self:InitTextSizeWithLanguage(CallTime, -2)
	end

	local consume = itemdata.consume
	local isFree = #consume <= 0
	if FreeTxt then
		self:SetWndText(FreeTxt,ccClientText(11657))
	end
	CS.ShowObject(FreeTxt,isFree)

	local showPay = not isFree
	if PayList and showPay then
		self:CreatePayList(PayList,consume)
	end
	CS.ShowObject(PayList,showPay)

	CS.ShowObject(ShareDiv,false)

	local _showDescStr = self._showDescStr
	if _showDescStr then
		local txtTrans = self:FindWndTrans(descDiv,"Txt")
		local otherInfo = itemdata.otherInfo
		local otherInfoArr = string.split(otherInfo,"|")
		local txtStr = string.replace(_showDescStr,otherInfoArr[1],otherInfoArr[2])
		self:SetWndText(txtTrans, txtStr)
		height = height + 45
	end
	CS.ShowObject(descDiv, _showDescStr)


	LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
end

function UIYellLog:InitData()
	local callType = self:GetWndArg("callType")
	self._callType = callType
	self._sid = self:GetWndArg("sid")
	self._maxNum = self:GetWndArg("maxNum")
	self._titleStr = self:GetWndArg("titleStr") or ccClientText(11621)
	self._tipsStr = self:GetWndArg("tipsStr")
	self._timeStr = self:GetWndArg("timeStr")
	self._showDescStr = self:GetWndArg("showDescStr")
	self._showEffItemList = self:GetWndArg("showEffItemList")
	if callType then
		self._btnList = {}
		if callType == 1 then
			CS.ShowObject(self.mTypeBtnList,true)
			self:InitBtnList()
		else
			CS.ShowObject(self.mTypeBtnList,false)
		end
	end

	self._heroEffectList = {
		[4] = "fx_ui_ZHJS_yingxiong_zise",
		[5] = "fx_ui_ZHJS_yingxiong_chengse",
	}
end

-- 修改底部按钮选中状态时的图片
--[[function UIYellLog:ChangeBtnImage(index,SelImg,BtnName)
	if index then
		local color
		if index == self._lastbtn then
			CS.ShowObject(SelImg,true)
			color = "c7cce2FF"
		else
			CS.ShowObject(SelImg,false)
			color = "9398aeFF"
		end
		color = LUtil.ColorByHex(color)
		local xuitxt = self:FindWndText(BtnName)
		self:SetXUITextColor(xuitxt,color)
	else
		local btnList = self._btnList
		for i = 1,#btnList do
			local btn = btnList[i]
			local color
			SelImg = CS.FindTrans(btn,"SelImg")
			BtnName = CS.FindTrans(btn,"BtnName")
			if i == self._lastbtn then
				CS.ShowObject(SelImg,true)
				color = "c7cce2FF"
			else
				CS.ShowObject(SelImg,false)
				color = "9398aeFF"
			end
			color = LUtil.ColorByHex(color)
			local xuitxt = self:FindWndText(BtnName)
			self:SetXUITextColor(xuitxt,color)
		end
	end
end]]

function UIYellLog:ChangeBtnImage()
	local btnList = self._btnList or {}
	for k,v in pairs(btnList) do
		local status = self._lastbtn == k and 0 or 1
		self:SetWndTabStatus(v,status)
	end
end








--[[function UIYellLog:OnDrawLogCell(list, item, itemdata, itempos, fromHeadTail)
	local DivTrans = CS.FindTrans(item,"Div")
	if DivTrans then
		local TimeDivTrans = CS.FindTrans(DivTrans,"TimeDiv")
		if TimeDivTrans then
			local ExpendTimeTrans = CS.FindTrans(TimeDivTrans,"ExpendTime")
			if ExpendTimeTrans then
				local createTime = itemdata.createTime
				local str = "%s"
				local timeStr = LUtil.FormatTimeStr(createTime,"%Y/%m/%d\n%H:%M:%S")
				str = string.replace(str,timeStr)
				self:SetWndText(ExpendTimeTrans,str)
			end
		end
		local DescDivTrans = CS.FindTrans(DivTrans,"DescDiv")
		if DescDivTrans then
			local RewardDivTrans = CS.FindTrans(DescDivTrans,"RewardDiv")
			if RewardDivTrans then
				local RewardTxtTrans = CS.FindTrans(RewardDivTrans,"RewardTxt")
				if RewardTxtTrans then
					local str = ccClientText(11620)
					local fixedRewardTxt,extraRewardTxt = "",""
					local fixedReward = itemdata.fixedReward
					if table.isempty(fixedReward) then str = ccClientText(11625) end
					for i,v in ipairs(fixedReward) do
						local itemId,count,itype = v.itemId,v.count,v.type
						local name
						if itype == 1 then
							name = gModelItem:GetNameByRefId(itemId)
						elseif itype == 2 then
							local ref = gModelHero:GetHeroRef(itemId)
							name = gModelHero:GetHeroNameByRefId(ref.refId,ref.initStar)
						elseif itype == 3 then
							local ref = gModelEquip:GetEquipRefByRefId(itemId)
							name = ccLngText(ref.name)
						else
							name = itemId
						end
						local temp = string.format("%s * %s",name,count)
						if string.isempty(extraRewardTxt) then
							fixedRewardTxt = temp
						else
							fixedRewardTxt = fixedRewardTxt .. "," .. temp
						end
					end
					local extraReward = itemdata.extraReward
					for i,v in ipairs(extraReward) do
						local itemId,count,itype = v.itemId,v.count,v.type
						local name
						if itype == 1 then
							name = gModelItem:GetNameByRefId(itemId)
						elseif itype == 2 then
							local ref = gModelHero:GetHeroRef(itemId)
							name = gModelHero:GetHeroNameByRefId(ref.refId,ref.initStar)
						elseif itype == 3 then
							local ref = gModelEquip:GetEquipRefByRefId(itemId)
							name = ccLngText(ref.name)
						else
							name = itemId
						end
						local color = "c5ccedFF"
						if itype == 1 then
							color = gModelItem:GetItemNameColorString(itemId)
						elseif itype == 2 then
							color = gModelHero:GetHeroNameColorByRefId(itemId)
						elseif itype == 3 then
							color = gModelEquip:GetEquipColorByRefId(itemId,true)
						end
						local temp = string.format("<color=#%s>%s</color> * %s",color,name,count)
						if string.isempty(extraRewardTxt) then
							extraRewardTxt = temp
						else
							extraRewardTxt = extraRewardTxt .. "," .. temp
						end
					end
					local callName
					if itemdata.refId then
						local callRef = gModelCallHero:GetCallRefByRefId(itemdata.refId)
						callName = ccLngText(callRef.typeName)
					else
						callName = itemdata.name
					end
					if table.isempty(fixedReward) then
						str = string.replace(str,itemdata.num,callName,extraRewardTxt)
					else
						str = string.replace(str,itemdata.num,callName,fixedRewardTxt,extraRewardTxt)
					end
					self:SetWndText(RewardTxtTrans,str)
				end
			end
		end
	end
end]]

function UIYellLog:OnDrawItemLogCell(list, item, itemdata, itempos, fromHeadTail)
	local HeroList = self:FindWndTrans(item,"HeroList")
	local BottomDiv = self:FindWndTrans(item,"BottomDiv")
	local ShareDiv = self:FindWndTrans(BottomDiv,"ShareDiv")
	local AutoDiv = self:FindWndTrans(ShareDiv,"AutoDiv")
	local ouqiTxt = self:FindWndTrans(AutoDiv,"ouqiTxt")
	local Image = self:FindWndTrans(AutoDiv,"Image")
	local ShareBtn = self:FindWndTrans(AutoDiv,"ShareBtn")

	local rankValue,id = itemdata.rankValue,itemdata.id
	local showShareDiv = rankValue ~= nil and rankValue ~= 0 and id ~= nil and id ~= 0 and self._callType == 1 or false
	CS.ShowObject(ShareDiv,showShareDiv)


	local TopDiv = self:FindWndTrans(BottomDiv,"TopDiv")
	local XHTxt = self:FindWndTrans(TopDiv,"XHTxt")
	local FreeTxt = self:FindWndTrans(XHTxt,"FreeTxt")
	local CallTime = self:FindWndTrans(TopDiv,"CallTime")
	local PayList = self:FindWndTrans(XHTxt,"PayList")

	if XHTxt then
		self:SetWndText(XHTxt,ccClientText(11654))
	end

	local fixedReward,extraReward = itemdata.fixedReward,itemdata.extraReward
	local consume = itemdata.consume
	local isFree = #consume <= 0
	if PayList and not isFree then
		self:CreatePayList(PayList,consume)
	end
	CS.ShowObject(PayList,not isFree)

	if FreeTxt then
		self:SetWndText(FreeTxt,ccClientText(11657))
	end
	CS.ShowObject(FreeTxt,isFree)

	if HeroList then
		self:CreateIconList(HeroList,fixedReward,extraReward)
	end

	if CallTime then
		local createTime = itemdata.createTime
		local str = self._timeStr or ccClientText(11655)
		local timeStr = LUtil.FormatTimeStr(createTime,"%Y/%m/%d %H:%M")
		str = string.replace(str,timeStr)
		self:SetWndText(CallTime,str)
		self:InitTextSizeWithLanguage(CallTime, -2)
	end

	if showShareDiv then
		local oqStr = string.replace(ccClientText(11678),rankValue)
		self:SetWndText(ouqiTxt,oqStr)
		self:SetWndClick(ShareBtn,function()
			self:OnClickShareFunc(Image,id,ShareBtn)
		end)
	end
--[[	local height = item.sizeDelta.y
	LxUiHelper.SetSizeWithCurAnchor(item, 1, height)]]

	local descDiv = self:FindWndTrans(BottomDiv, "DescribeDiv")
	local _showDescStr = self._showDescStr
	if(_showDescStr)then
		local txtTrans = self:FindWndTrans(descDiv,"Txt")
		local otherInfo = itemdata.otherInfo
		local otherInfoArr = string.split(otherInfo,"|")
		--local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
		--local chunk = activityWebData.chunk
		--local cfg = chunk[tonumber(otherInfoArr[1])]
		--if(cfg)then
		local txtStr = string.replace(_showDescStr,otherInfoArr[1],otherInfoArr[2])
		self:SetWndText(txtTrans, txtStr)
		--end
	end
	CS.ShowObject(descDiv, _showDescStr)
end

function UIYellLog:OnDrawIconCell(list,item,itemdata,itempos)
	local uiCommonList = self._uiCommonList
	if not uiCommonList then
		uiCommonList = {}
		self._uiCommonList = uiCommonList
	end
	local InstanceID = item:GetInstanceID()

	local itemId,count,itype = itemdata.itemId,itemdata.count,itemdata.type

	local CommonUI = self:FindWndTrans(item,"CommonUI")
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(CS.FindTrans(CommonUI,"Icon"))
	end
	baseClass:SetCommonReward(itype, itemId, count)
	baseClass:DoApply()

	self:SetWndClick(CommonUI,function()
		if itype == 1 then
			gModelGeneral:OpenItemInfoTipsFormChat(itemdata)
		else
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end
	end)

	self:DestroyWndEffectByKey(InstanceID)
	local eff
	local effScaleSize = 100
	local target = false
	if --[[gLGameLanguage:IsJapanRegion() and]] itype == LItemTypeConst.TYPE_HERO then
		local heroId = itemId

		effScaleSize = 95
--[[		if gModelHero:CheckIsShowHeroQualityForeign() then
		else
		end]]
		local heroRef  = gModelHero:GetHeroRef(heroId)
		if heroRef then
			local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
			if qualityRef then
				local heroCallFxList = string.split(qualityRef.heroCallFx, '=')
				eff = heroCallFxList[1]
				target = not string.isempty(eff)
				local fxEffSize = heroCallFxList[2]
				if not string.isempty(fxEffSize) then
					effScaleSize = tonumber(fxEffSize) * 95
				end
			end
		end
		if not eff then
			local initStar = gModelHero:GetHeroInitStarByRefId(heroId)
			if initStar >= 5 then
				eff = self._heroEffectList[initStar]
			end
		end
	elseif self._showEffItemList and self._showEffItemList[itemId] then
		for k,v in ipairs(self._showEffItemList[itemId]) do
			if v == tonumber(count) then
				eff = self._showItemEffName
				effScaleSize = 120
				break
			end
		end
	end

	if eff then
		self:CreateWndEffect_Ex({
			trans = CommonUI,
			effKey = InstanceID,
			effName = eff,
			scale = Vector3.New(effScaleSize,effScaleSize,effScaleSize),
			endFunc = function(dpEff)
				if not target then return end
				local dpTrans = dpEff:GetDisplayTrans()
				local kuangTrans = self:FindWndTrans(dpTrans,"kuang")
				local neibu = self:FindWndTrans(kuangTrans,"neibu")
				local waibu = self:FindWndTrans(kuangTrans,"waibu")
				CS.ShowObject(neibu,false)
				CS.ShowObject(waibu,false)
			end
		})
		--self:CreateWndEffect(CommonUI,eff,InstanceID,effScaleSize,false,false)
	end
end
------------------------------------------------------------------
return UIYellLog


