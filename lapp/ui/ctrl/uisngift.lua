---
----活动82 皮肤礼包主窗口
--- Created by Ease.
--- DateTime: 2023/10/7 21:03:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISnGift:LWnd
local UISnGift = LxWndClass("UISnGift", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISnGift:UISnGift()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISnGift:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISnGift:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISnGift:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
end
--初始化数据
function UISnGift:InitData()
	self._sid = self:GetWndArg("sid")
	self._pageId = self:GetWndArg("pageId") or 1
	self._entryId =self:GetWndArg("entryId") or 1
	self._enterSid = self:GetWndArg("enterSid")
	local subpage = self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end
	gModelActivity:ReqActivityConfigData(self._sid)
end
--设置底部按钮
function UISnGift:SetBotList(pageList)
	if (self._pageList and pageList) then
		for i, v in pairs(pageList) do
			self._pageList[i] = pageList[i]
		end
	else
		self._pageList = pageList
	end
	local list = self._pageList
	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mBotBtnScroll")
		self._uiList = uiList
		uiList:Create(self.mBotBtnScroll, list, function(...)
			self:ListItem(...)
		end)
		--uiList:EnableScroll(#list > 4, false)
		--uiList:EnableScroll(false, false)
	end
end

function UISnGift:SetJumpData(data)
	self._pageId = data.pageId
	self._entryId = data.entryId
end

--设置选中底部按钮状态
function UISnGift:SetSeleBtn()
	if (not self._btnList or #self._btnList == 0) then
		return
	end
	for i, v in ipairs(self._btnList) do
		local seleBg = self:FindWndTrans(v.obj, "SelBg")
		local txt = self:FindWndTrans(v.obj, "NoSelTxt")
		local pId = self._pageId
		local nameTxtColorHex = v.itemData.pageId == pId and "FFFFFF" or "BFBDDB"
		local nameTxtCmp = txt:GetComponent("YXUIText")
		nameTxtCmp.color = LUtil.ColorByHex_6(nameTxtColorHex)
		CS.ShowObject(seleBg, v.itemData.pageId == pId)
	end
end
--消息事件监听初始化
function UISnGift:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
		self:OnActivityConfigData(...)	--活动配置
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
		gModelActivity:OnActivityPageReq(self._sid) --零点
	end)
end

function UISnGift:GetHistory()
	local list = LWnd.GetHistory(self)
	local wndArgList = list.wndArgList
	wndArgList.pageId = self._pageId
	wndArgList.entryId = self._entryId
	wndArgList.enterSid = self._enterSid
	return list
end

--获取底部页签按钮回调函数
function UISnGift:GetBotBtnFuncByType(data)
	local argList = { sid = self._sid, entry = data.pbData.entry, pageId = data.pageId, isClickBot = true,entryId = self._entryId }
	local func = function()
		self._pageId = data.pageId
		self:SetSeleBtn()
		self._wnd = self:CreateChildWnd(self.mChildRoot, "UISubAnniversarySn", argList)
		self._entryId = nil
	end
	return func
end
--活动分页数据 ActivityPage
function UISnGift:OnActivityPageResp(pb)
	local sid = pb.sid
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end
	if sid ~= self._sid then
		return
	end
	local pageList = self._pageList or {}
	local springTimeTab = self._cfgData.config.springtimeTab
	local tabList = LxDataHelper.ParseStringParam_Semicolon(springTimeTab)
	local tabDataList = {}
	for i, v in ipairs(tabList) do
		local data = string.split(v, '=')
		if (data and #data > 0) then
			table.insert(tabDataList, data)
		end
	end
	for i, v in ipairs(pb.pages) do
		local page = {}
		page.pbData = gModelActivity:GenerateActivePageDataFromPb(v)
		page.pageId = page.pbData.pageId
		page.iconName = tabDataList[page.pageId][2]
		page.startDays = tabDataList[page.pageId][3]
		page.icon = tabDataList[page.pageId][4]--page.pageId
		local isIns = false
		for k, j in pairs(pageList) do
			if (page.pageId == j.pageId) then
				pageList[k] = page
				isIns = true
			end
		end
		if not isIns then
			table.insert(pageList, page)
		end
	end
	table.sort(pageList, function(a, b)
		return a.pageId < b.pageId
	end)
	self:SetBotList(pageList)
	local wndData = self:GetPageNameAndArgByType(pageList[self._pageId])
	if (wndData) then
		self:CreateChildWnd(self.mChildRoot, wndData[1], wndData[2])
		self._entryId = nil
	end
end
--按钮事件监听初始化
function UISnGift:InitBtnEvent()
	self:SetWndClick(self.mReturnBtn, function()
		if (self._enterSid) then
			local activityData = gModelActivity:GetActivityBySid(self._enterSid)
			local func = gModelActivity:GetShowActivityFun(activityData.model)
			if func then
				func(activityData)
			end
		end
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

--获取分页窗口名和参数
function UISnGift:GetPageNameAndArgByType(data)
	if (data) then
		local argList = { sid = self._sid, entry = data.pbData.entry, pageId = data.pageId,entryId = self._entryId }
		return { "UISubAnniversarySn", argList }
	end
end
--活动条目页签列表子项
function UISnGift:ListItem(list, item, itemdata, itempos)
	local noSelTxt = self:FindWndTrans(item, "NoSelTxt")
	local lock = self:FindWndTrans(item, "Lock")
	local unLockTimeTxt = self:FindWndTrans(item, "UnLockTimeTxt")
	local selIcon = self:FindWndTrans(item, "NoSelIcon")
	local icon = itemdata.icon
	local iconName = itemdata.iconName
	local startDays = itemdata.startDays
	self:SetWndEasyImage(selIcon,icon)
	self._btnList = self._btnList and self._btnList or {}
	self._btnList[itempos] = { itemData = itemdata, obj = item }
	self:SetWndText(noSelTxt, iconName)
	self:InitTextLineWithLanguage(noSelTxt, -30)
	self:SetSeleBtn()
	local intervalDays = self:GetIntervalDays() --活动开始到现在间隔天数
	local isOpen = intervalDays >= tonumber(startDays)
	local intervalOpenDays = tostring(startDays - intervalDays) --页签开启到现在间隔天数 大于0代表未开启页签
	CS.ShowObject(lock, not isOpen)
	CS.ShowObject(unLockTimeTxt, not isOpen)
	if (isOpen) then
		local func = self:GetBotBtnFuncByType(itemdata)
		self:SetWndClick(item, func)
	else
		local unLockTxt = ccClientText(29801)
		local nTime = GetTimestamp()
		nTime = math.ceil(nTime)
		local oTime = nTime + (86400 * (startDays - intervalDays))
		oTime = math.ceil(oTime)
		local yTxt, mTxt, dTxt = LUtil.GetYmdByTimestamp(oTime)
		mTxt = tostring(mTxt)
		dTxt = tostring(dTxt)
		unLockTxt = string.replace(unLockTxt, mTxt, dTxt)
		self:SetWndText(unLockTimeTxt, unLockTxt) --29801 %s年%s月解锁
		self:InitTextLineWithLanguage(unLockTimeTxt, -30)
		self:SetWndClick(item, function()
			local clientText = ccClientText(29800)-- or "%s 天后解锁该主题"
			local showStr = string.replace(clientText, intervalOpenDays)
			GF.ShowMessage(showStr)
			--printInfoNR("现在是第" .. tostring(days) .. "天，活动" .. iconName .. "在第" .. startDays .. "天开启")
		end)
	end
end
--协议监听初始化
function UISnGift:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		self:OnActivityPageResp(pb) 	--分页数据返回
	end)
end
--获取活动开启距离现在间隔天数
function UISnGift:GetIntervalDays()
	self._activityCfg = gModelActivity:GetActivityBySid(self._sid)
	local startTime = self._activityCfg.startTime
	local curTime = tonumber(GetTimestamp())
	local intervalTime = curTime - startTime
	return math.ceil(intervalTime / 86400)
end

--后台活动配置回调
function UISnGift:OnActivityConfigData(data, sid)
	if sid ~= self._sid then
		return
	end
	self._cfgData = data
	gModelActivity:OnActivityPageReq(self._sid)
end
------------------------------------------------------------------
return UISnGift


