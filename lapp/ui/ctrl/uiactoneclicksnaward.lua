---
--- Created by Administrator.
--- DateTime: 2023/10/30 10:45:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActOneClickSnAward:LWnd
local UIActOneClickSnAward = LxWndClass("UIActOneClickSnAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActOneClickSnAward:UIActOneClickSnAward()
	---@type table<number,UIIconEasyList>
	self._uiListTbl = {}

	self._rewardEffName = "fx_anniu_02"

	self._progressFormat = " (%s/%s)"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActOneClickSnAward:OnWndClose()
	for k,v in pairs(self._effectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._effectKeyList= nil

	self:ClearCommonIconList(self._uiListTbl)
	self._uiListTbl = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActOneClickSnAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActOneClickSnAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitCommand()
	self:InitStaticData()
end

function UIActOneClickSnAward:InitStaticData()
	--self:SetWndText(self.mLblBiaoti, ccClientText(24000))
end

--####################################################################################################################
--### Server #########################################################################################################
--####################################################################################################################
function UIActOneClickSnAward:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if webData then
		local data = webData.config
		local str = data.rewardTxt or ccClientText(24000)
		self._title = str
		self:SetWndText(self.mLblBiaoti,str)
	end



	gModelActivity:OnActivityPageReq(self._sid)
end

function UIActOneClickSnAward:OnItemReturn(list,item,itemdata,itemPos)
	if not itemdata then
		return
	end
	local instanceId = item:GetInstanceID()
	local key = "item"..tostring(instanceId)
	self:DestroyWndEffectByKey(key)
end

function UIActOneClickSnAward:InitItemList(root,itemList)
	local instanceId = root:GetInstanceID()
	local uiList = self._uiListTbl[instanceId]
	if not uiList then
		uiList = UIIconEasyList:New()
		self._uiListTbl[instanceId] = uiList
		uiList:Create(self, root)
		--uiList:SetShowNum(true)
		uiList:SetIconParentPath("itemRoot/CommonUI/Icon")
		--uiList:SetShowExtraNum(true, "itemNum")
		local maxNum = #itemList
		uiList:EnableScroll(maxNum > 4,true)
	end
	uiList:RefreshList(itemList)
end

function UIActOneClickSnAward:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function ()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end

--####################################################################################################################
--### Content ########################################################################################################
--####################################################################################################################
function UIActOneClickSnAward:RefreshContent()
	local itemDataList = self._pageData

	for k,v in ipairs(self._effectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._effectKeyList={}

	local isForeign = gLGameLanguage:IsForeignRegion()
	CS.ShowObject(self.mItemContent, not isForeign)
	CS.ShowObject(self.mItemContentEn, isForeign)
	local itemContentTrans = isForeign and self.mItemContentEn or self.mItemContent

	local uiList = self._itemDataList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,itemContentTrans)
		uiList:SetFuncOnItemDraw(function(...)
			self:SetItemDraw(...)
		end)
		uiList:SetFuncOnItemReturn(function(...)
			self:OnItemReturn(...)
		end)

		uiList:EnableLoadAnimation(true, 0.03, 1, 2)
		uiList:SetLoadAnimationScale(nil, 0.03)
		self._itemDataList = uiList
	else
		uiList:EnableLoadAnimation(false)
	end
	uiList:RemoveAll()

	for k,v in ipairs(itemDataList) do
		local refId = v.entryId
		uiList:AddData(refId,v)
	end

	uiList:RefreshSimpleList(UIListWrap.RefreshMode.Top)
end

function UIActOneClickSnAward:OnActivityResp(pb,ret)
	if self._sid ~= pb.sid then return end

	self:RefreshContent()
end

function UIActOneClickSnAward:InitEvent()
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mFullBg,function() self:WndClose() end)
end

function UIActOneClickSnAward:OnActivityPageResp(pb,ret)
	if self._sid ~= pb.sid then return end

	self:ResetActivePageData(pb)
	self:RefreshContent()
end

function UIActOneClickSnAward:InitCommand()
	self._func = self:GetWndArg("func")
	self._sid = self:GetWndArg("sid")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	self._effectKeyList = {}

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActOneClickSnAward:ResetActivePageData(pb)
	local activityPage
	for i, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		if v.pageId == 2 and page then
			activityPage = page
			break
		end
	end

	if not activityPage then
		printInfoNR("activityPage is a nil")
		return
	end

	self._pageData = {}
	for k,v in pairs(activityPage.entry) do
		local entryCfg  = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		if entryCfg then
			local data = {
				entryId = v.entryId,	--序号
				pageId   = v.pageId,	--条目id
				status  = v.goalData.status,	--完成状态
				schedules = v.goalData.schedules,	--进度
				sort	 = entryCfg.sort,		--排序
				desc	= entryCfg.description,
				items	= LxDataHelper.ParseItem(entryCfg.reward),
				moreInfo = entryCfg.moreInfo,
			}
			table.insert(self._pageData, data)
		end
	end

	table.sort(self._pageData, function(a, b)
		return a.sort < b.sort
	end)
end

function UIActOneClickSnAward:SetItemDraw(list,item,itemdata,itemPos)
	local bg = self:FindWndTrans(item,"bg")
	local bgTitle = self:FindWndTrans(bg,"title")
	local bgItemList = self:FindWndTrans(bg,"itemList")
	local btnYellow = self:FindWndTrans(bg,"BtnYellow3")
	local BtnRed = self:FindWndTrans(bg,"BtnRed3")
	local unfinishedImg = self:FindWndTrans(bg,"UnfinishedImg")
	local finishedImg = self:FindWndTrans(bg,"FinishedImg")
	local helpBtn    = self:FindWndTrans(bg, "HelpBtn")

	local instanceId = item:GetInstanceID()
	local pageId     = itemdata.pageId
	local entryId 	 = itemdata.entryId

	local rewards = itemdata.items
	if rewards then
		self:InitItemList(bgItemList,rewards)
	end

	local schedulesData = itemdata.schedules
	local goal 	= #schedulesData
	local schedule     = 0
	for k,v in ipairs(schedulesData) do
		if tonumber(v.schedule) == 1 then
			schedule = schedule + 1
		end
	end

	local isNeed = schedule >= goal
	local color = "red"
	if isNeed then
		color = "green"
	end

	local haveValue = LUtil.NumberCoversion(schedule)
	local needValue = LUtil.NumberCoversion(goal)
	local haveStr   = LUtil.FormatColorStr(haveValue, color)
	local str = string.replace(self._progressFormat,haveStr,needValue)

	local nameStr = itemdata.desc
	self:SetWndText(bgTitle, nameStr..str)
	self:InitTextLineWithLanguage(bgTitle, -30)
	self:InitTextSizeWithLanguage(bgTitle, -6)

	local state= itemdata.status
	local btnIsGray
	local btnStr    = ""
	local btnTrans  = btnYellow
	local hideBtnTrans  = BtnRed
	local clickFunc = nil

	btnIsGray = state == 2
	if state == 0 then
		clickFunc = function()
			GF.ShowMessage(ccClientText(10411))
		end
	elseif state == 1 then
		btnStr	  = ccClientText(10151)
		clickFunc = function()
			gModelActivity:OnActivityReceiveGoalReq(self._sid, pageId,entryId)
		end
	end

	CS.ShowObject(unfinishedImg, state == 0)
	CS.ShowObject(finishedImg, state == 2)
	CS.ShowObject(hideBtnTrans, false)
	CS.ShowObject(btnTrans, state == 1)
	self:SetWndButtonText(btnTrans, btnStr)
	self:SetWndButtonGray(btnTrans, btnIsGray)

	if state == 1 then
		local key = "item"..tostring(instanceId)
		table.insert(self._effectKeyList,key)
		self:CreateWndEffect(btnTrans,self._rewardEffName,key,
				100,nil,nil,nil,
				nil,nil,true)
	end


	self:SetWndClick(btnTrans, clickFunc)

	local helpText = itemdata.moreInfo
	local title = self._title or ccClientText(24000)
	self:SetWndClick(helpBtn, function()
		GF.OpenWndUp("UIBzTips",{title = title, text = helpText})
	end)
end




------------------------------------------------------------------
return UIActOneClickSnAward


