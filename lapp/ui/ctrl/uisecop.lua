---
--- Created by Administrator.
--- DateTime: 2023/10/24 20:00:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISecop:LWnd
local UISecop = LxWndClass("UISecop", LWnd)
------------------------------------------------------------------

local pattern = "<image>([%w_]+)</image>"

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISecop:UISecop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISecop:OnWndClose()
	self:ClearCommonIconList(self._hyperList)
	gLSdkImpl:WebViewDestroy()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISecop:OnCreate()
	LWnd.OnCreate(self)

	self._hyperList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISecop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitPara()
	self:InitEvent()
	self:InitUIEvent()
	self:InitTop()


	gModelActivity:ReqActivityConfigData(self._sid)
end

function UISecop:ShowItem(data)
	local isShowTitle = true

	if gLGameLanguage:IsJapanRegion() then
		isShowTitle = false
	end

	if isShowTitle then
		self:SetWndText(self.mTitle,data.title1)
		local str =ccClientText(14312) --"%s发布"
		str = string.replace(str,data.title2)
		self:SetWndText(self.mSendder,str)
	end

	local isLink = not string.isempty(data.link)
	CS.ShowObject(self.mTextContent,not isLink)
	CS.ShowObject(self.mLinkContent,isLink)

	if isLink then
		self:ShowLinkContent(data.link)
	else
        gLSdkImpl:WebViewDestroy()
		self:ShowTextContent(data.text)
	end


end

function UISecop:InitPara()
	local sid = self:GetWndArg("sid")
	self._sid = sid
	self._curRefId = self:GetWndArg("refId")

	self._rightTopPosList = {
		COMMON = Vector2.New(240, 246,0),
		JAPAN = Vector2.New(240,370,0),
	}
end

function UISecop:ResetData(pb)
	local sid = pb.sid
	if(self._sid ~= sid)then
		return
	end
	local list = self.pages
	if not list then
		list = {}
	end
	for i, v in ipairs(pb.pages) do
		local pageData = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = pageData.pageId
		local entryList = {}
		if pageId == 1 then
			for p,q in pairs(pageData.entry) do
				local entryId = q.entryId
				local entryCfg  = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,entryId)
				entryList[entryId] = entryCfg
			end

			list = entryList
		end
	end
	self.pages = list
	self:RefreshUI()
end

function UISecop:OnClickTab(itemdata)
	if self._curRefId == itemdata.refId then
		return
	end

	self._curRefId = itemdata.refId

	local list = self:FindUIScroll("tabList")
	if list then
		list:DrawAllItems(false)
	end

	self:ShowItem(itemdata)
end

function UISecop:InitTop()
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	local bgPath = "activity_news_bg_1"

	if gLGameLanguage:IsJapanRegion() then
		bgPath = "activity_news_bg_6"
	end

	if LxUiHelper.IsImgPathValid(bgPath) then
		self:SetWndEasyImage(self.mBg, bgPath)
	end
end

function UISecop:OnDrawContent(list,item,itemdata,itempos)
	local UIText = self:FindWndTrans(item,"UIText")
	local Image = self:FindWndTrans(item,"Image")

	CS.ShowObject(UIText,itemdata.type == 1)
	CS.ShowObject(Image,itemdata.type == 2)

	if itemdata.type == 1 then


		local text = itemdata.para

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
		local content = LUtil.CreateHyperWithValue(UIText,text,hyperCreateFun,function (data)

			if data.key == ModelChat.HYPER_WEB_LINK or data.key == ModelChat.HYPER_KEY_4 then
				local itemdata = {
					name = self._title,
					desc = data.msg,
					desc2 = "",
				}

				gLxTKData:OnClickSecretLink(itemdata)
			end

			gModelChat:ClickHyper(data,wndName)
		end)

		self:SetWndText(UIText,content)
	else
		self:SetWndEasyImage(Image,itemdata.para,nil,true)
	end
end

function UISecop:InitUIEvent()
	self:SetWndClick(self.mBg,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
end

function UISecop:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function(data,sid)
		if sid ~= self._sid then
			return
		end
		gModelActivity:OnActivityPageReq(self._sid)
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
end

function UISecop:OnDrawTab(list,item,itemdata,itempos)
	local BtnTab3 = self:FindWndTrans(item,"BtnTab3")

	self:SetWndTabText(BtnTab3,itemdata.name)
	local isSel = itemdata.refId == self._curRefId

	self:SetWndTabStatus(BtnTab3,isSel and LWnd.StateOn or LWnd.StateOff)

	self:SetWndClick(BtnTab3,function ()
		self:OnClickTab(itemdata)
	end)
end



function UISecop:RefreshUI()
	local index = 1
	local dataList = {}
	local pageData = gModelActivity:GetWebActivityPageData(self._sid,1)
	if not pageData then

		local actWebData = gModelActivity:GetWebActivityDataById(self._sid)
		if actWebData then
			local config = actWebData.config
			local data =
			{
				refId = -1,
				name = "",
				title1 = config.titleName,
				title2 = config.sendName,
				link = config.link,
				text = config.text,
			}

			table.insert(dataList,data)
		end
	else
		for k,v in ipairs(pageData.entries) do
			local refId = v.id
			if self.pages[refId] then
				local data =
				{
					refId = refId,
					name = v.name,
					title1 = v.title1,
					title2 = v.title2,
					link = v.link,
					text = v.text,
				}

				if not self._curRefId  then
					self._curRefId = data.refId
					index = 1
				else
					if self._curRefId == data.refId then
						index = k
					end
				end

				table.insert(dataList,data)
			end
		end
	end

	self._dataList = dataList
	local showTab = #dataList > 1

	CS.ShowObject(self.mTabList,showTab)
	if showTab then
		self:CreateUIScrollImpl("tabList",self.mTabList,dataList,function (...)
			self:OnDrawTab(...)
		end,UIItemList.SUPER)

		local list = self:FindUIScroll("tabList")
		list:MoveToPos(index)
	end


	local data = self._dataList[index]
	if data then
		self:ShowItem(data)
	end
end

function UISecop:ShowTextContent(text)


	local dataList = {}
	local s = 1
	local e = 0
	local start = 1
	local len = string.len(text)
	local cap = nil
	while start<len do
		s,e,cap =string.find(text,pattern,start)
		if s then
			local text = string.sub(text,start,s-1)
			local data =
			{
				type = 1,
				para = text,
			}
			table.insert(dataList,data)
			local data =
			{
				type = 2,
				para = cap,
			}
			table.insert(dataList,data)
			start = e + 1
		else
			text = string.sub(text,start,len)
			local data =
			{
				type = 1,
				para = text,
			}
			table.insert(dataList,data)
			break
		end
	end

	--local uiList = self._uiList
    --
	--if not uiList then
	--	uiList = self:GetUIScroll("contentList")
	--	self._uiList = uiList
	--	uiList:Create(self.mItemList,dataList,function (...) self:OnDrawContent(...) end)
	--	uiList:EnableScroll(true,false)
	--end

	self:CreateUIScrollImpl("contentList",self.mItemList,dataList,function (...)
		self:OnDrawContent(...)
	end)
	local list = self:FindUIScroll("contentList")
	list:EnableScroll(true,false)
end

function UISecop:ShowLinkContent(link)
	if gLGameLanguage:IsJapanRegion() then
		local pos = self._rightTopPosList.JAPAN
		self.mRightTop.localPosition = pos
	end

	local margin = LUtil.GetWebViewMargin(self.mLeftBottom.position,self.mRightTop.position,gLGameUI:GetCSUICamera())
	gLSdkImpl:WebViewShow(link, margin.left, margin.top, margin.right, margin.bottom)
end

------------------------------------------------------------------
return UISecop


