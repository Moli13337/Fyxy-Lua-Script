---
--- Created by Administrator.
--- DateTime: 2023/10/20 10:45:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISpreadAct:LWnd
local UISpreadAct = LxWndClass("UISpreadAct", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISpreadAct:UISpreadAct()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISpreadAct:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISpreadAct:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISpreadAct:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self:InitEvent()
	self:InitUIEvent()
	self:InitData()
	self:SetStatic()
	self:InitActPara()

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UISpreadAct:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootItem = self:FindWndTrans(AniRoot,"item")
	self:CreateCommonIconImpl(AniRootItem,itemdata)
end

function UISpreadAct:OnClickTask(itemdata,pageId)
	local pageData = self._pages[pageId]
	local entryData = pageData:GetEntry(itemdata.id)
	local goaldata = entryData.goalData
	local status = goaldata.status
	if status ~= 1 then
		return
	end

	--todo

	local dataList = {}
	for k,v in ipairs(pageData.entry) do
		local goalData = v.goalData
		if goalData.status == 1 then
			local data = {
				sid = pageData.sid,
				pageId = pageData.pageId,
				entryId = v.entryId
			}

			table.insert(dataList,data)
		end
	end


	gModelActivity:OnActivityReceiveGoalListReq(dataList)

end

function UISpreadAct:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb)
		local sid = pb.sid
		if self._sid ~= sid then
			return
		end
		self:RefreshContent(pb)
	end)
end

function UISpreadAct:OnDrawTask(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootName = self:FindWndTrans(AniRoot,"name")
	local AniRootItemList = self:FindWndTrans(AniRoot,"itemList")
	local AniRootBtnGet = self:FindWndTrans(AniRoot,"btnGet")
	--local btnGetLight = self:FindWndTrans(AniRootBtnGet,"Light")
	--local LightText = self:FindWndTrans(btnGetLight,"Text")
	--local btnGetGray = self:FindWndTrans(AniRootBtnGet,"Gray")
	--local GrayText = self:FindWndTrans(btnGetGray,"Text")
	local AniRootGetTag = self:FindWndTrans(AniRoot,"getTag")


	self:SetWndText(AniRootName,itemdata.description)
	local dataList = LxDataHelper.ParseItem(itemdata.reward)
	local instanceId = item:GetInstanceID()
	self:CreateUIScrollImpl(instanceId,AniRootItemList,dataList,function (...)
		self:OnDrawItem(...)
	end)

	local pageData = self._pages[2]
	local entryData = pageData:GetEntry(itemdata.id)
	local goaldata = entryData.goalData
	local status = goaldata.status
	CS.ShowObject(AniRootBtnGet,status == 1)
	CS.ShowObject(AniRootGetTag,status == 0 or status == 2)
	local img = status == 0 and "activity_turn_txt_16" or "public_txt_13_1"
	self:SetWndEasyImage(AniRootGetTag,img)

	local str =ccClientText(27603) --"领取"
	self:SetWndButtonText(AniRootBtnGet,str)
	self:SetWndClick(AniRootBtnGet,function ()
		self:OnClickTask(itemdata,2)
	end)
end

function UISpreadAct:OnClickShare()
	local cnt = #self._shareImgList
	local rand = math.random(1,cnt)

	local bgPath = self._shareImgList[rand]
	local para = {
		sid = self._sid,
		bgPath = bgPath,
		showTwitter = self._showTwitter,
		onlySave = self._onlySave
	}
	GF.OpenWnd("UISpreadActContent",para)
end

function UISpreadAct:OnDrawItemOne(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootItem = self:FindWndTrans(AniRoot,"item")
	local AniRootItemNum = self:FindWndTrans(AniRoot,"itemNum")

	self:CreateCommonIconImpl(AniRootItem,itemdata,{showNum = false})

	self:SetWndText(AniRootItemNum,itemdata.itemNum)
end

function UISpreadAct:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	if not activityData then
		return
	end

	local config = activityData.config
	self._showTwitter = config.showTwitter == 1
	self._timeFormat = config.timeDes
	self._shareImgList = string.split(config.shareImage,",")
	self._onlySave = config.onlySave
	local showHelp = config.helpTips == 1
	CS.ShowObject(self.mBtnHelp,showHelp)
	if showHelp then
		local helpContent = config.helpTipsContent
		local helpTitle = config.helpTipsTitle
		local helpPos = LxDataHelper.ParseVector2(config.helpTipsPosition)
		self:SetAnchorPos(self.mBtnHelp,helpPos)
		self:SetWndClick(self.mBtnHelp,function ()
			GF.OpenWnd("UIBzTips",{title= helpTitle,text = helpContent})
		end)
	end

	local img = config.descIcon
	self:SetWndEasyImage(self.mTitle,img,nil,true)
	local pos = LxDataHelper.ParseVector2(config.descIconPosition)
	self:SetAnchorPos(self.mTitle,pos)


	gModelActivity:OnActivityPageReq(sid)

end

function UISpreadAct:InitActPara()
	local sid = self:GetWndArg("sid")
	if not sid then
		local subpage= self:GetWndArg("subPage") --支持跳转
		if subpage then
			sid = gModelActivity:GetSidByUniqueJump(subpage)
		end
	end

	self._sid = sid
end

function UISpreadAct:InitUIEvent()
	self:SetWndClick(self.mBtnShare,function ()
		self:OnClickShare()
	end)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)
end

function UISpreadAct:InitData()
	self._itemListTran = {
		[1] = self.mItem_1,
		[2] = self.mItem_2,
		[3] = self.mItem_3,
		[4] = self.mItem_4,
		[5] = self.mItem_5,
	}

	self._starStateImg = {
		[0]= "activity_dreamnight_star_4",
		[1]= "activity_dreamnight_star_3",
		[2]= "activity_dreamnight_star_2",
	}

	self._sliderNode = {
		[1] = 0.1,
		[2] = 0.3,
		[3] = 0.5,
		[4] = 0.7,
		[5] = 1,

	}
end


function UISpreadAct:RefreshContent(pb)
	local pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		pages[page.pageId] = page
	end
	---@type table<number,StructActivityPage>
	self._pages = pages

	local sid = self._sid
	local actData = gModelActivity:GetActivityBySid(sid)
	local moreInfo = JSON.decode(actData.moreInfo)
	local shareSum = moreInfo and moreInfo.ShareSum or 0
	shareSum = shareSum or 0

	local pageCfg = gModelActivity:GetWebActivityPageData(sid,1)
	local entryList =pageCfg.entries
	local pageData = pages[1]
	local goalList = {}
	for k,v in ipairs(entryList) do
		local item = self._itemListTran[k]
		if item then
			local star = self:FindWndTrans(item,"star")
			local bg = self:FindWndTrans(item,"bg")
			local bgItemList = self:FindWndTrans(bg,"itemList")
			local bgTargetNum = self:FindWndTrans(bg,"targetNum")
			local bgMask = self:FindWndTrans(bg,"mask")
			local bgSelect = self:FindWndTrans(bg,"select")
			local tag = self:FindWndTrans(item,"tag")


			local entryData = pageData:GetEntry(v.id)
			local goalData= entryData.goalData
			local status = goalData.status
			local schedule = goalData.schedules[1] or {}
			local goal = schedule.goal and tonumber(schedule.goal)
			local sliderValue = self._sliderNode[k] or 1
			table.insert(goalList,{goal = goal,sliderValue = sliderValue})

			local starImg = self._starStateImg[status]
			self:SetWndEasyImage(star,starImg)

			CS.ShowObject(bgSelect,status == 1)
			CS.ShowObject(bgMask,status == 2)
			CS.ShowObject(tag,status == 1 or status == 2)
			local tagImg = status == 1 and "public_txt_4_3" or "public_txt_13_1"
			self:SetWndEasyImage(tag,tagImg)


			self:SetWndText(bgTargetNum,v.description)
			local dataList = LxDataHelper.ParseItem(v.reward)
			local instanceId = bgItemList:GetInstanceID()
			self:CreateUIScrollImpl(instanceId,bgItemList,dataList,function (...)
				self:OnDrawItemOne(...)
			end)

			self:SetWndClick(item,function () self:OnClickTask(v,1) end)
		end
	end

	local percent = 0
	local lastNode = nil
	for k,v in ipairs(goalList) do
		if shareSum <= v.goal then
			local lastGoal = lastNode and lastNode.goal or 0
			local lastSliderValue = lastNode and lastNode.sliderValue or 0
			percent = (shareSum - lastGoal )/(v.goal - lastGoal) *(v.sliderValue - lastSliderValue) + lastSliderValue
			break
		end
	end

	self:SetWndSliderPara(self.mProgress,percent,0,1)

	local str = nil
	if shareSum > 10000 then
		str =tostring(math.floor(shareSum /10000)).."W"
	else
		str = tostring(shareSum)
	end
	self:SetWndText(self.mTotalShareNum,str)

	self._endTime = actData.endTime

	printInfoN("endTime "..self._endTime)
	if self._endTime > 0 then
		local para = {
			key="countDown",
			loopcnt = -1,
			interval = 1,
			func = function()
				self:SetCountDown()
			end
		}

		self:TimerStartImpl(para)
	else
		self:TimerStop("countDown")

	end




	pageCfg = gModelActivity:GetWebActivityPageData(sid,2)
	entryList = pageCfg.entries

	self:CreateUIScrollImpl("personalList",self.mTaskList,entryList,function (...)
		self:OnDrawTask(...)
	end,UIItemList.SUPER)
end



function UISpreadAct:SetCountDown()
	local endTime = self._endTime or 0
	local timeLeft =math.ceil(endTime - GetTimestamp())
	timeLeft = math.max(0,timeLeft)
	local str = LUtil.FormatTimeSpanShop(timeLeft)
	str = string.replace(self._timeFormat,str)
	self:SetWndText(self.mTime,str)
end

function UISpreadAct:SetStatic()
	local str =ccClientText(39100) --"<size=24>↓</size>点击下方按钮分享<size=24>↓</size>"
	self:SetWndText(self.mIntro2,str)
	str = ccClientText(39101) --"全服当前<#c34534>分享人次</color>"
	self:SetWndText(self.mIntro,str)
end

------------------------------------------------------------------
return UISpreadAct


