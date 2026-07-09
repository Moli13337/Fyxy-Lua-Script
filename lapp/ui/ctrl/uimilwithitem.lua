---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMilWithItem:LWnd
local UIMilWithItem = LxWndClass("UIMilWithItem", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMilWithItem:UIMilWithItem()
	self._validTimerKey = "_validTimerKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMilWithItem:OnWndClose()

	self:ClearCommonIconList(self._hyperList)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMilWithItem:OnCreate()
	LWnd.OnCreate(self)

	self._hyperList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMilWithItem:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:RefreshUI()
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mOkBtn,function () self:OnClickOK() end,LSoundConst.CLICK_BUTTON_COMMON)

	self:WndNetMsgRecv(LProtoIds.MailReceiveResp,function () self:OnMailReceiveResp()  end)


end

function UIMilWithItem:OnClickOK()
	if self._mail._fetch then
		gModelMail:MailRemoveReq(1,self._mail._mailId)
		self:WndClose()
	elseif(self._mail._mailType == 3)then
		gModelMail:MailReceiveReq(1,self._mail._mailId)
		self:WndClose()
	else
		gModelMail:MailReceiveReq(1,self._mail._mailId)
	end
end

function UIMilWithItem:RefreshValidTime()
	local expiredTime = self._expiredTime
	local haveValid = expiredTime and expiredTime ~= 0

	CS.ShowObject(self.mValidTime, haveValid)
	if not haveValid then
		return
	end

	self:TimerStart(self._validTimerKey, 1, false, -1)
	self:StarCountDown()
end

function UIMilWithItem:OnDrawItem(list,item, itemdata, itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local getTag = self:FindWndTrans(item,"getTag")

	local iconTrans = CS.FindTrans(itemRoot, "CommonUI/Icon")
	local instanceId = item:GetInstanceID()
	local uiItemList = self._uiItemList
	local baseClass = uiItemList:GetItemCls(instanceId)
	if not baseClass then
		baseClass = CommonIcon:New()
		uiItemList:SetItemCls(instanceId, baseClass)
		baseClass:Create(iconTrans)
	end

	local itemId = itemdata.itemId
	local itemType = itemdata.itemType
	local itemNum = itemdata.itemNum

	baseClass:SetCommonReward(itemType, itemId ,itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)

	CS.ShowObject(getTag,self._mail._fetch)

	table.insert(self._uiItems,item)
end

function UIMilWithItem:InitData()
	self._uiItems ={}

	self._stateImgMap =
	{
		[1] = "public_btn_1_2",
		[2] = "public_btn_1_3"
	}
end

function UIMilWithItem:OnMailReceiveResp()
	local mailId = self._mail._mailId
	local mail = gModelMail:GetMailByMailId(mailId)
	self._mail = mail
	local text =self:FindWndTrans(self.mOkBtn,"text")
	local str = ccClientText(11205)
	if mail._fetch then
		str = ccClientText(11213)
	end
	local state = mail._fetch and 2 or 1
	local img = self._stateImgMap[state]
	--self:SetBtnImageAndMat(self.mOkBtn,img,text)
	--self:SetImageActorState(self.mOkBtn,state)



	self:SetWndText(text,str)
	--self:SetWndImageGray(self.mOkBtn,mail._fetch)

	for k,v in ipairs(self._uiItems) do
		local getTag = self:FindWndTrans(v,"getTag")
		CS.ShowObject(getTag,mail._fetch)
	end
end

function UIMilWithItem:StarCountDown()
	local lastTime = self._expiredTime - GetTimestamp()
	if lastTime < 0 then
		CS.ShowObject(self.mValidTime, false)
		self:TimerStop(self._validTimerKey)
		return
	end

	local timeStr = LUtil.FormatTimespanCn(lastTime)
	timeStr = string.replace(ccClientText(11217),timeStr)
	self:SetWndText(self.mValidTime,timeStr)
end

function UIMilWithItem:RefreshUI()
	local str = ccClientText(11202)
	self:SetWndText(self.mMailTitle,str)

	local text = self:FindWndTrans(self.mTextTitle,"UIText")
	self:SetWndText(text,ccClientText(11208))
	self._mail = self:GetWndArg("mail")
	local mail = self._mail
	--if not mail._read then
	--	gModelMail:MailReaderReq(mail._mailId)
	--end
	local text =self:FindWndTrans(self.mOkBtn,"text")
	local str = ccClientText(11205)
	if mail._fetch then
		str = ccClientText(11213)
	end
	self:SetWndText(text,str)
	local state = mail._fetch and 2 or 1
	local img = self._stateImgMap[state]
	--self:SetBtnImageAndMat(self.mOkBtn,img,text)

	local refId = mail._refId
	local title = nil

	if LOG_INFO_ENABLED then
		printInfoN2("邮件RefId", "mail refId = "..refId)
		printInfoNR(mail)
	end

	local replacedContent = nil
	local sender = nil

	local hyperCreateFun = function(tran)
		if not CS.IsValidObject(tran) then
			return
		end
		local instanceId = tran:GetInstanceID()
		local hyper = self._hyperList[instanceId]
		if not hyper then
			hyper = UIHyperText:New()
			self._hyperList[instanceId] = hyper
			hyper:Create(tran)
		end
		return hyper
	end

	local wndName = self:GetWndName()

	if refId == 0 then
		title = mail._tile
		replacedContent = mail._content
		sender = mail._signature

		replacedContent = LUtil.CreateHyperWithValue(self.mContent,replacedContent,hyperCreateFun,function (data)
			local key = data.key
			if key == "keysdkurl" then
				local v = data.msg
				--if LGameSettings.platformRegion == LRegionConst.JAPAN then
					if not string.isempty(v) then
						gLSdkImpl:CallMethod(LSdkMethod.OpenSurvey, v, true)
					end
					return
				--end
			end
			gModelChat:ClickHyper(data,wndName)
		end)
		replacedContent = string.gsub(replacedContent,"\\n","\n")


	else
		local cfg =gModelMail:GetMailCfg(refId)
		if not cfg then
			--print("no mail cfg "..refId)
			return
		end


		local cfgContent =ccLngText(cfg.content)
		local cfgTitle =ccLngText(cfg.title)
		local shiftNumIndex = cfg.shiftNumIndex

		local content = mail._content
		local netTitle = mail._tile
		if refId == 1 then --新角色登录游戏第一份邮件特殊处理
			local appName = LNativeHelper.GetAppName();
			netTitle = "{\"a1\":\""..appName.."\"}"
			content = netTitle
		end

		title =LUtil.GetReplacedContent(cfgTitle,netTitle)
		title = string.gsub(title,"\\n","\n")
		--if shiftNumIndex then
		--	content =gModelMail:GetReplacedNeedShiftContent(content, shiftNumIndex)
		--end


		replacedContent =LUtil.GetReplacedContent(cfgContent,content,shiftNumIndex) -- gModelMail:GetReplacedContent(cfgContent,content,shiftNumIndex)

		replacedContent = LUtil.CreateHyperWithValue(self.mContent,replacedContent,hyperCreateFun,function (data)
			gModelChat:ClickHyper(data,wndName)
		end)

		replacedContent = string.gsub(replacedContent,"\\n","\n")
		sender =ccLngText(cfg.signature)

		local needCheck = gModelMail:CheckNeedShield(refId)
		if needCheck then
			replacedContent = LWordMaskUtil.ClearShieldWord(replacedContent,true) --屏蔽字
		end
	end

	self:SetWndText(self.mTitle,title)
	self:SetWndText(self.mContent,replacedContent)
	self:SetWndText(self.mSender,sender)
	local receiveTime = LUtil.OSDate("*t",mail._receiveTime/1000)
	local timeStr = string.format("%d.%d.%d",receiveTime["year"],receiveTime["month"],receiveTime["day"])
	self:SetWndText(self.mDate,timeStr)

	--有效期
	local expiredTime = mail._expiredTime
	if expiredTime then
		self._expiredTime = expiredTime/1000
	end
	self:RefreshValidTime()

	self:InitItemList()
end

function UIMilWithItem:InitItemList()
	local itemList = self._mail._attachments

	local dataList= gModelMail:FormatShowItems(itemList)

	local list = self._uiItemList
	if not list then
		list = self:GetUIScroll("itemList")
		self._uiItemList = list
		list:Create(self.mItemList,dataList,function (...) self:OnDrawItem(...) end,UIItemList.WRAP)
	else
		list:RefreshList(dataList)
	end

end

function UIMilWithItem:OnTimer(key)
	if key == self._validTimerKey then
		self:StarCountDown()
	end
end

------------------------------------------------------------------
return UIMilWithItem


