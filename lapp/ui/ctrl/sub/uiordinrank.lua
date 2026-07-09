---
--- Created by Administrator.
--- DateTime: 2023/10/14 16:52:07
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UIOrdinRank:LChildWnd
local UIOrdinRank = LxWndClass("UIOrdinRank", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOrdinRank:UIOrdinRank()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOrdinRank:OnWndClose()
	self:ClearTimer()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOrdinRank:OnCreate()
	LChildWnd.OnCreate(self)
	self._uiCommonList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOrdinRank:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:SetTop()
	self:InitEvent()
	self:InitMsg()
	self:InitStaticContent()

	--[[	local pbData = gModelActivity:GetActivityPageBySid(self._sid)
        if pbData then
            self:OnActivityPageResp(pbData)
        else
            gModelActivity:OnActivityPageReq(self._sid)
        end]]

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if self._sid ~= sid then return end
		self:SetTop()
		gModelActivity:OnActivityPageReq(self._sid)
	end)

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIOrdinRank:OnActivityPageResp(pb,ret)
	local sid = pb.sid
	if sid ~= self._sid then return end

	local pageData = pb.pages[1]
	if not pageData then
		return
	end
	local page1 = StructActivityPage:New()
	page1:CreateByPb(pageData)
	self._pageId = page1.pageId

	--pageData = pb.pages[2]
	--if not pageData then
	--	return
	--end

	local page2
	pageData = pb.pages[2]
	if pageData then
		page2 = StructActivityPage:New()
		page2:CreateByPb(pageData)
	end

	self:RefreshUI(page1, page2)
end

function UIOrdinRank:SetTop()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

	local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityCfg then return end

	--local moreInfo = activityData.moreInfo
	local data = activityCfg.config
	local path = data.image
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTop, path)
	end
	path = data.titleIcon or "activity_rank_txt_1"
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTextImg, path,nil,true)
		CS.ShowObject(self.mTextImg, true)
	end

	local strs = string.split(data.tipsDescription,"\n")
	if #strs <= 1 then
		strs = string.split(data.tipsDescription,"<br>")
	end

	local list = self:FindUIScroll("descList")
	if not list then
		list = self:GetUIScroll("descList")
		list:Create(self.mDescList,strs,function (...) self:OnDrawDesc(...) end)
	else
		list:RefreshList(strs)
	end

	list:EnableScroll(true,false)

	--self:SetWndText(self.mDescTxt,data.tipsDescription)
	--self:SetWndText(self.mDescTxt_1,strs[2])

    --
	--self:InitTextLineWithLanguage(self.mDescTxt,-50)
	--self:InitTextLineWithLanguage(self.mDescTxt_1,-50)

	--self:InitTextLineWithLanguage(self.mDescTxt, 41)
	--[[	local desc = "活动期间快速战斗次数增加1次\n活动结束后邮件发放排行奖励"
        self:SetWndText(self.mDescTxt,desc)]]
	self._receiveCount = data.receiveCount_2
	self._rankId = data.rankId
	local endTime = activityData.endTime

	local subTime = endTime - GetTimestamp()
	self._activityStatus = subTime > 0


	local text = self:FindWndTrans(self.mDetailsBtn,"text")
	local str = ccClientText(10360)
	self:SetWndText(text,str)
	self:InitTextLineWithLanguage(text,-40)
	text = self:FindWndTrans(self.mRewardBtn,"text")
	str = ccClientText(10361)
	self:SetWndText(text,str)
	self:InitTextLineWithLanguage(text,-40)

	self:CreateTimer(endTime)
end

function UIOrdinRank:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
		self:OnActivityPageResp(...)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityReceiveGoalResp, function(...)
		self:OnActivityReceiveGoalResp(...)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function() self:SetTop() end)
end

function UIOrdinRank:SetTimeStr(times)
	local curTime = times - GetTimestamp()
	if curTime > 0 then
		local str = string.replace(ccClientText(15610),LUtil.FormatTimespanCn(curTime))
		self:SetWndText(self.mTimeStr,str)
	else
		self:SetWndText(self.mTimeStr,ccClientText(14301))
		self:ClearTimer()
	end
end

function UIOrdinRank:OnActivityReceiveGoalResp(pb,ret)
	if self._sid ~= pb.sid or self._pageId ~= pb.pageId then return end
	local index = self._entryIdToIndex[pb.entryId]
	if not index then return end
	local list = self._itemUIList:GetList()
	local data = list:GetDataByIndex(index)
	data.state = 2
	list:DrawItemByIndex(index)
end

function UIOrdinRank:CreateTimer(times)
	self:ClearTimer()
	self:SetTimeStr(times)
	self._timer = LxTimer.LoopTimeCall(function()
		self:SetTimeStr(times)
	end, 1, false, -1)
end

function UIOrdinRank:InitStaticContent()

	local isShowDetailsBtn = not gLGameLanguage:IsJapanRegion()
	CS.ShowObject(self.mDetailsBtn, isShowDetailsBtn)
end

function UIOrdinRank:RefreshUI(page1, page2)
	local dataList = {}
	for i,v in ipairs(page1.entry) do

		local entryCfg = gModelActivity:GetWebActivityEntryData(page1.sid,v.pageId,v.entryId)
		if entryCfg then
			local data = {}
			data.entryId = v.entryId
			data.title = entryCfg.name
			data.rewards = LxDataHelper.ParseItem(entryCfg.reward)
			data.status = v.goalData.status
			data.sort = entryCfg.sort
			data.schedule = tonumber(v.goalData.schedules[1].schedule)
			data.times = tonumber(v.goalData.schedules[1].goal)
			--local moreInfo = JSON.decode(v.moreInfo)
			data.jumpId = tonumber(entryCfg.jumpId)
			table.insert(dataList,data)
		end

	end
	table.sort(dataList,function (a,b)
		local aPrio = self._statePriority[a.status] or 1
		local bPrio = self._statePriority[b.status] or 1
		if aPrio ~= bPrio then return aPrio < bPrio end
		return a.sort < b.sort
	end)
	if not self._rewardList then
		self._rewardList = {}
		if page2 then
			for i,v in ipairs(page2.entry) do
				local entryCfg = gModelActivity:GetWebActivityEntryData(page2.sid,v.pageId,v.entryId)
				if entryCfg then
					local entryId = v.entryId
					local data = {}
					data.index = entryId
					data.reward = LxDataHelper.ParseItem(entryCfg.reward)
					--for _i,_v in ipairs(v.items) do
					--	table.insert(data.reward,{
					--		isShowEff = false,
					--		itemId = _v.itemId,
					--		itemNum = tonumber(_v.count),
					--		itemType = _v.type,
					--	})
					--end
					local str = string.split(entryCfg.name,"~")
					local left = tonumber(str[1])
					local right = (str[2] and tonumber(str[2])) or left
					local rank = {}
					table.insert(rank,left)
					table.insert(rank,right)
					data.rank = rank
					table.insert(self._rewardList,data)
				end

			end
		end
	end
	self:InitItemList(dataList)
end

function UIOrdinRank:BtnEvent(itemdata)
	--if self._activityStatus then
	local status = itemdata.status
	if status == 0 then
		if self._activityStatus then
			local jumpId = itemdata.jumpId
			local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,true)
			if isOpen then
				gModelFunctionOpen:Jump(jumpId)
			end
		else
			GF.ShowMessage(ccClientText(14301))
		end
	elseif status == 1 then
		local sid = self._sid
		local pageId = self._pageId
		local entryId = itemdata.entryId
		gModelActivity:OnActivityReceiveGoalReq(sid,pageId,entryId)
	end
	--else
	--	GF.ShowMessage(ccClientText(14301))
	--end
end

function UIOrdinRank:InitEvent()
	self:SetWndClick(self.mDetailsBtn,function()
		if self._rankId then
			GF.OpenWndBottom("UIRkPop",{refId=self._rankId,sid = self._sid,page = 1,rewardList = self._rewardList})
			--GF.OpenWndBottom("WndRankAwardWin",{refId = self._rankId,sid = self._sid,rewardList = self._rewardList,btnIdx = 1})
		end
	end)
	self:SetWndClick(self.mRewardBtn,function()
		GF.OpenWndBottom("UIRkPop",{refId=self._rankId,sid = self._sid,page = 2,rewardList = self._rewardList})

		--GF.OpenWnd("UIringPkAward",{rewardList = self._rewardList})

		--GF.OpenWndBottom("WndRankAwardWin",{refId = self._rankId,sid = self._sid,rewardList = self._rewardList,btnIdx = 2})
	end)
end

function UIOrdinRank:InitItemList(dataList)
	local uiList = self._itemUIList
	if uiList then
		uiList:RefreshList(dataList)
	else
		uiList = self:GetUIScroll("list")
		self._itemUIList = uiList
		uiList:Create(self.mItemList, dataList, function(...)
			self:OnDrawItem(...)
		end, UIItemList.WRAP)
	end
end

function UIOrdinRank:OnDrawItem(list,item, itemdata, itempos)
	local times,schedule,status = itemdata.times,itemdata.schedule,itemdata.status
	local pass = times <= schedule
	local DescTxtTrans = self:FindWndTrans(item, "DescTxt")
	if DescTxtTrans then
		local color = "c81212"
		if pass then color = "0fb93f" end
		local str = string.replace(ccClientText(16211),color,schedule,times)
		self:SetWndText(DescTxtTrans,str)
	end
	local TopBgTrans = self:FindWndTrans(item, "TopBg")
	if TopBgTrans then
		local TitleTxtTrans = self:FindWndTrans(TopBgTrans, "TitleTxt")
		if TitleTxtTrans then
			self:SetWndText(TitleTxtTrans,itemdata.title)
		end
	end
	local BtnTrans = self:FindWndTrans(item, "Btn")
	local BtnNameTrans = self:FindWndTrans(BtnTrans, "BtnName")

	local btnstr = nil
	local btnState = 0
	if itemdata.status == 0 then
		btnState = 0
		btnstr = ccClientText(14003)
		if not self._activityStatus then
			btnstr = ccClientText(14304)
			btnState = 2
		end
	elseif itemdata.status == 1 then
		btnState = 1
		btnstr = ccClientText(14007)
	end
	self:SetWndText(BtnNameTrans,btnstr)
	self:InitTextLineWithLanguage(BtnNameTrans,-40)
	-- local img = self._stateImg[btnState]
	-- self:SetBtnImageAndMat(BtnTrans,img)
	CS.ShowObject(BtnTrans,status ~= 2)

	--local isGray = false
	--local str = ccClientText(14003)
	--if pass then str = ccClientText(14007) end
	--if not self._activityStatus and not pass and status ~= 1 then
	--	isGray = true
	--	str = ccClientText(14304) 			-- 活动时间结束为不可完成
	--end
	--self:SetWndText(BtnNameTrans,str)
	--self:SetWndImageGray(BtnTrans,isGray)
	--local btnImg = "public_btn_2_1"
	--if pass then btnImg = "public_btn_2_2" end
	--self:SetWndEasyImage(BtnTrans,btnImg,function()
	--	CS.ShowObject(BtnTrans,status ~= 2)
	--end)

	if status ~= 2 then
		self:SetWndClick(BtnTrans,function()
			self:BtnEvent(itemdata)
		end)
	end
	local redPointTrans = self:FindWndTrans(BtnTrans,"RedPoint")
	if redPointTrans then
		CS.ShowObject(redPointTrans,false)
	end
	local StatusImgTrans = self:FindWndTrans(item, "StatusImg")
	if StatusImgTrans then
		CS.ShowObject(StatusImgTrans,status == 2)
	end
	local RewardListTrans = self:FindWndTrans(item, "RewardList")
	if RewardListTrans then
		--local itemList = {}
		--for i,v in ipairs(itemdata.rewards) do
		--	table.insert(itemList,{
		--		itemId = v.itemId,
		--		itemType = v.type,
		--		itemNum = v.count,
		--	})
		--end
		self:InitRewardList(RewardListTrans,itemdata.rewards,"reward"..itempos)
	end
	self._entryIdToIndex[itemdata.entryId]= itempos
end

function UIOrdinRank:InitRewardList(trans,dataList,keyName)
	--[[	local uiList = self:GetUIScroll(keyName)
        uiList:Create(trans, dataList, function(...)
            self:OnDrawRewardItem(...)
        end, UIItemList.WRAP,false)
        local list = uiList:GetList()
        list:RefreshList(UIListWrap.RefreshMode.Solid)]]
	local InstanceID = trans:GetInstanceID()
	local uiList1 = self:GetUIScroll("key"..InstanceID)
	if(uiList1:GetList())then
		uiList1:RefreshList(dataList)
	else
		uiList1:Create(trans,dataList,function(...) self:OnDrawRewardItem(...) end)
		uiList1:EnableScroll(#dataList > 4,true)
	end
end

function UIOrdinRank:ClearTimer()
	local timer = self._timer
	if timer then
		LxTimer.DelayTimeStop(timer)
		self._timer = nil
	end
end

function UIOrdinRank:InitData()
	self._sid = self:GetWndArg("sid")

	self._entryIdToIndex = {}
	self._statePriority = {
		[0] = 2,
		[1] = 1,
		[2] = 3,
	}

	self._stateImg =
	{
		[0] = "public_btn_2_2",
		[1] = "public_btn_2_2",
		[2] = "public_btn_ash_2",
	}
end

function UIOrdinRank:OnDrawDesc(list,item,itemdata,itempos)
	--local star = self:FindWndTrans(item,"star")
	local DescTxt = self:FindWndTrans(item,"DescTxt")

	self:SetWndText(DescTxt,itemdata)
	self:InitTextLineWithLanguage(DescTxt,-40)
end

function UIOrdinRank:OnDrawRewardItem(list, item, itemdata, itempos)
	local itemRefId,itemType,itemCount = itemdata.itemId,itemdata.itemType,itemdata.itemNum
	local root = self:FindWndTrans(item,"Icon")
	local formatData = {
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
		baseClass:Create(root)
	end
	baseClass:SetCommonReward(formatData.itemType, formatData.itemId, -1)
	baseClass:DoApply()
	self:SetIconClickScale(root, true)
	self:SetWndClick(root, function() gModelGeneral:ShowCommonItemTipWnd(formatData) end)

	local ItemNumTrans = self:FindWndTrans(item,"ItemNum")
	if ItemNumTrans then
		itemCount = LUtil.NumberCoversion(itemCount)
		self:SetWndText(ItemNumTrans,itemCount)
	end
end

------------------------------------------------------------------
return UIOrdinRank


