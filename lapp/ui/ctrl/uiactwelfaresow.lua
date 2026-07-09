---
--- Created by Administrator.
--- DateTime: 2023/10/7 15:35:44
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActWelfareSow:LWnd
local UIActWelfareSow = LxWndClass("UIActWelfareSow", LWnd)

UIActWelfareSow.YQFL = 1
UIActWelfareSow.MXFL = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActWelfareSow:UIActWelfareSow()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActWelfareSow:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActWelfareSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActWelfareSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitText()
	self:Refresh()
	gModelActivity:ReqActivityConfigData(self._sid)
--[[	if self._actType == UIActWelfareSow.MXFL then
		gModelActivity:OnActivityInvitationReq(ModelActivity.INVITATION_PLAYER_INFO,self._sid)
	end]]
	gModelActivity:OnActivityInvitationReq(ModelActivity.INVITATION_PLAYER_INFO,self._sid)
end

function UIActWelfareSow:OnDrawRewardItemCell(list,item,itemdata,itempos)
	local CommonIcon = self:FindWndTrans(item,"CommonIcon")
	local Icon = self:FindWndTrans(CommonIcon,"Icon")
	local ItemNum = self:FindWndTrans(item,"ItemNum")

	local itemType,itemId,itemNum = itemdata.itemType,itemdata.itemId,itemdata.itemNum
	local instance = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instance)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()

	self:DestroyWndEffectByKey(instance)
	local showEff = itemdata.showEff
	if showEff then
		self:CreateWndEffect(CommonIcon,"fx_ui_qiandao_lingqutishi",instance,100)
	end

	self:SetWndClick(CommonIcon,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)

	local itemNumStr = LUtil.NumberCoversion(itemNum)
	self:SetWndText(ItemNum,itemNumStr)
end

function UIActWelfareSow:InitText()
	self:SetWndText(self.mTitle,self._title)
	self:SetWndText(self.mTextDesc,self._talkTxt)
	self:SetWndButtonText(self.mYaoQingBtn,ccClientText(20828))
	self:SetWndButtonText(self.mYaoQinglIstBtn,ccClientText(20829))

	local str = string.replace(ccClientText(20831),"")
	self:SetWndText(self.mYQRTxt,str)
end

function UIActWelfareSow:InitTaskList()
	local list = self.entryData or {}
	local uiTaskList = self._uiTaskList
	if uiTaskList then
		uiTaskList:RefreshList(list)
	else
		uiTaskList = self:GetUIScroll("uiTaskList")
		self._uiTaskList = uiTaskList
		uiTaskList:Create(self.mTaskList,list,function(...) self:OnDrawTaskCell(...) end)
	end
end

function UIActWelfareSow:GetEvent(itemdata)
	local goalData = itemdata.goalData
	local status = goalData.status
	if status == 1 then
		gModelActivity:OnActivityReceiveGoalReq(self._sid,itemdata.pageId,itemdata.entryId)
	end
end

function UIActWelfareSow:Refresh()
	local actType = self._actType
	if actType == UIActWelfareSow.YQFL then
		self:RefreshYQFLView()
	elseif actType == UIActWelfareSow.MXFL then
	end
end

function UIActWelfareSow:RefreshMXFLView(selPlayer,beInvitation)
	if selPlayer then
		local player = gModelGeneral:SetPlayerInfo(beInvitation)
		local HeadIconTrans = self:FindWndTrans(self.mYQRHead,"HeadIcon")
		local playerId = player._playerId
		local playerInfo={
			trans = HeadIconTrans,
			playerId = playerId,
			icon = player._head,
			headFrame = player._headFrame,
			level = player._grade,
			func = function()
				gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
			end
		}
		local InstanceID = HeadIconTrans:GetInstanceID()
		local uiheadlist = self._uiheadList
		local baseClass = uiheadlist[InstanceID]
		if not baseClass then
			baseClass = HeadIcon:New(self)
			uiheadlist[InstanceID] = baseClass
		end
		baseClass:SetHeadData(playerInfo)

		self:SetWndText(self.mYQRName,player._name)
		--self:SetWndText(self.mPowerText,LUtil.FormatCoversionHurtNumSpriteText(player._power,false,nil, 20))
		self:SetWndText(self.mPowerText,LUtil.PowerNumberCoversion(player._power))
	end
	CS.ShowObject(self.mMXDiv,selPlayer)
	CS.ShowObject(self.mYQRDiv,selPlayer)
	local str = ""
	if not selPlayer then
		str = ccClientText(20857)
	end
	self:SetWndText(self.mMXNoYQTxt,str)
end

function UIActWelfareSow:OnActivityPageResp(pb)
	local pageEntry = {}
	self.entryData = {}
	for i,v in ipairs(pb.pages) do
		local page
		local pageId = v.pageId
		if self._actType == pageId then
			page = gModelActivity:GenerateActivePageDataFromPb(v)
		end
		if page then
			pageEntry = page.entry
		end
	end
--[[	local statusSort = {
		[0] = 1,
		[1] = 2,
		[2] = 0,
	}
	local indexPage = {}
	for i,v in ipairs(pageEntry) do
		local moreInfo = JSON.decode(v.moreInfo)
		local index = tonumber(moreInfo.moreInfo)
		local goalData = v.goalData
		local status = goalData.status
		local indexInfo = indexPage[index]
		if not indexInfo then
			indexInfo = {}
			indexPage[index] = indexInfo
		end
		table.insert(indexInfo,{
			status = status,
			index = v.entryId
		})
	end

	local page = {}
	for i,v in ipairs(indexPage) do
		local finshNum = 0
		local len = #v
		local notFinshIndex = 0
		local finshIndex = 0
		for idx,val in ipairs(v) do
			local index = val.index
			local status = val.status
			if status == 2 then
				finshNum = finshNum + 1
				finshIndex = index
			elseif notFinshIndex == 0 then
				notFinshIndex = index
			end
		end
		local finshStatus = len == finshNum or false
		if finshStatus then
			table.insert(page,pageEntry[finshIndex])
		elseif notFinshIndex ~= 0 then
			table.insert(page,pageEntry[notFinshIndex])
		end
	end]]
	self.entryData = pageEntry
	if not self.selEntryId then
		local first = self.entryData[1]
		self.selEntryId = first and first.entryId
	end
	self:InitTaskList()
end

function UIActWelfareSow:RefreshYQFLView()
	CS.ShowObject(self.mYQDiv,true)

	local str = string.replace(ccClientText(20821),self._yqmNum)
	self:SetWndText(self.mYQMTxt,str)
end

function UIActWelfareSow:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if sid ~= self._sid then return end
		self:OnActivityPageResp(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityInvitationResp,function (pb)
		self:OnActivityInvitationResp(pb)
	end)
end

function UIActWelfareSow:OnDrawTaskCell(list,item,itemdata,itempos)
	local NoSelImg = self:FindWndTrans(item,"NoSelImg")
	local SelImg = self:FindWndTrans(item,"SelImg")
	local Desc = self:FindWndTrans(item,"Desc")
	local RewardList1 = self:FindWndTrans(item,"RewardList1")
	local RewardList2 = self:FindWndTrans(item,"RewardList2")

	local pageId = itemdata.pageId
	local entryId = itemdata.entryId
	local show = self.selEntryId == entryId

	local icon = itemdata.icon
	printInfoNR("==== icon = " .. icon)
	self:SetWndEasyImage(NoSelImg,icon)
	self:SetWndEasyImage(SelImg,icon)
	CS.ShowObject(SelImg,show)

	local descList = self._descList
	if not descList then
		descList = {}
		self._descList = descList
	end
	local pageDescList = descList[pageId] or {}
	local entryDescList = pageDescList[entryId] or {}
	local desc = entryDescList.desc or ""
	self:SetWndText(Desc,desc)
	self:InitTextSizeWithLanguage(Desc, -2)
	self:InitTextLineWithLanguage(Desc, -7)

	local YQDiv = self:FindWndTrans(item,"YQDiv")
	local MXDiv = self:FindWndTrans(item,"MXDiv")
	local actType = self._actType
	local goalData = itemdata.goalData
	local status = goalData.status
	local getReward = status == 1
	if actType == UIActWelfareSow.YQFL then
		CS.ShowObject(YQDiv,true)
		CS.ShowObject(MXDiv,false)
		local UIText = self:FindWndTrans(YQDiv,"UIText")
		local schedules = goalData.schedules[1]
		local goal,schedule = tonumber(schedules.goal),tonumber(schedules.schedule)
		local moreInfo = JSON.decode(itemdata.moreInfo)
		--local lastNum = goal - schedule
		local lastNum = tonumber(moreInfo.num)
		local haveLastNum = lastNum > 0
		local lastNumStr = LUtil.FormatColorStr(lastNum,haveLastNum and "green" or "red")
		local str = string.replace(ccClientText(20833),lastNumStr)
		self:SetWndText(UIText,str)

        local redPoint = self:FindWndTrans(YQDiv,"redPoint")
        CS.ShowObject(redPoint,false)

	elseif actType == UIActWelfareSow.MXFL then
		CS.ShowObject(MXDiv,true)
		CS.ShowObject(YQDiv,false)
		local CanGetImg = self:FindWndTrans(MXDiv,"CanGetImg")
		local NoCanGetImg = self:FindWndTrans(MXDiv,"NoCanGetImg")
		local GetImg = self:FindWndTrans(MXDiv,"GetImg")
		CS.ShowObject(CanGetImg,status == 1)
		CS.ShowObject(NoCanGetImg,status == 0)
		CS.ShowObject(GetImg,status == 2)
	end

	local items = itemdata.items
	local more = #items > 2
	local moreTrans = more and RewardList2 or RewardList1
	CS.ShowObject(RewardList1,not more)
	CS.ShowObject(RewardList2,more)

	local rewardList = self:GetRewardList(items,getReward)
	self:CreateRewardList(moreTrans,rewardList,more)

	local GetBtn = self:FindWndTrans(item,"GetBtn")
	CS.ShowObject(GetBtn,getReward)

	self:SetWndClick(GetBtn,function()
		self:GetEvent(itemdata)
	end)

	self:SetWndClick(NoSelImg,function()
		self:GetEvent(itemdata)
	end)
end

function UIActWelfareSow:OnActivityInvitationResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end
	local opera = pb.opera
	if opera ~= ModelActivity.INVITATION_PLAYER_INFO then return end

	local invitation = pb.invitation
	local beInvitation = invitation.beInvitation
	local selPlayer = beInvitation.playerId and beInvitation.playerId ~= nil and beInvitation.playerId ~= 0 or false

	if self._actType == ModelActivity.INVITATION_PLAYER_INFO then
		self:RefreshMXFLView(selPlayer,beInvitation)
	else
		local invitations = invitation.invitations
		local len = #invitations
		self._isInvitation = len > 0
	end
end

function UIActWelfareSow:CopyFunc()
	local str = self._yqmNumStr
	if string.isempty(str) then return end
	if LNativeHelper.CopyToClipboard(str) then
		--LNativeHelper.ShowToast(str)
		GF.ShowMessage(ccClientText(20846))
		gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_INVITE,"分享邀请码","复制邀请码",str)
	end
end

function UIActWelfareSow:GetRewardList(items,status)
	local list = {}
	for i,v in ipairs(items) do
		local itemType,itemId,itemNum = v.type,v.itemId,v.count
		table.insert(list,{
			itemType = itemType,
			itemId = itemId,
			itemNum = itemNum,
			showEff = status,
		})
	end
	return list
end

function UIActWelfareSow:CreateRewardList(trans,list,enable)
	local key = trans:GetInstanceID()
	local uiTransList = self:FindUIScroll(key)
	if uiTransList then
		uiTransList:RefreshList(list)
	else
		uiTransList = self:GetUIScroll(key)
		uiTransList:Create(trans,list,function(...) self:OnDrawRewardItemCell(...) end)
		uiTransList:EnableScroll(enable,true)
	end
end

function UIActWelfareSow:InitData()
	self._actType = self:GetWndArg("actType")
	self._title = self:GetWndArg("title")
	self._talkTxt = self:GetWndArg("talkTxt")
	self._sid = self:GetWndArg("sid")
	self._yqmNum = self:GetWndArg("yqmNum")
	self._yqmNumStr = self:GetWndArg("yqmNumStr")
end

function UIActWelfareSow:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCopyBtn,function()
		self:CopyFunc()
	end)
	self:SetWndClick(self.mYaoQingBtn,function()
		gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_INVITE,"打开分享界面","分享")
		GF.OpenWnd("UIGameSpread",{sid = self._sid})
	end)
	self:SetWndClick(self.mYaoQinglIstBtn,function()
		if self._isInvitation then
			GF.OpenWnd("UIInviteListSow",{sid = self._sid})
		else
			GF.ShowMessage(ccClientText(20850))
		end
	end)
end

function UIActWelfareSow:OnActivityConfigData()
	local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityWebData then return end
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local chunk = activityWebData.chunk
	local list = {}
	for i,v in ipairs(chunk) do
		local id = v.id
		local idList = list[id]
		if not idList then
			idList = {}
			list[id] = idList
		end
		local entries = v.entries or {}
		for idx,val in ipairs(entries) do
			idList[val.id] = {desc = val.description}
		end
	end

	self._descList = list

	gModelActivity:OnActivityPageReq(self._sid)
end

------------------------------------------------------------------
return UIActWelfareSow


