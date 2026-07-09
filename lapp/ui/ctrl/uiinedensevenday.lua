---
--- Created by Administrator.
--- DateTime: 2023/10/8 14:16:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInEdenSevenDay:LWnd
local UIInEdenSevenDay = LxWndClass("UIInEdenSevenDay", LWnd)
local UnityEngine 	 = UnityEngine
local typeof 		 = typeof
local typeofImage = typeof(UnityEngine.UI.Image)
local typeofCanvas = typeof(UnityEngine.Canvas)
local typeofUISorting = typeof(CS.YXUISorting)


UIInEdenSevenDay.TYPE_BUY_FREE = 0
UIInEdenSevenDay.TYPE_BUY_ITEM = 1
UIInEdenSevenDay.TYPE_BUY_RMB = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInEdenSevenDay:UIInEdenSevenDay()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInEdenSevenDay:OnWndClose()
	self:DestroyWndEffectAll()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInEdenSevenDay:OnCreate()
	LWnd.OnCreate(self)

	self._uiCommonList = {}
	self._uiBoxCommonList = {}
	self._effList = {}
	self._actSeventDays = "actWonderlandSevenDays"
	self._canGetEffName = "fx_myxj_lingqutishi"
	-- 礼包标题颜色，底图配置
	self._titleColorList = {
		[1] = {"9BBBFFFF" , "dailygift_bg_cell_2"},-- 蓝色
		[2] = {"E7B6EDFF" , "dailygift_bg_cell_3"},-- 粉红
		[3] = {"B9EAEBFF" , "dailygift_bg_cell_1"},-- 绿色
		[4] = {"F5EAC0FF" , "dailygift_bg_cell_4"},-- 橙色
	}
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInEdenSevenDay:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._sid = self:GetWndArg("sid")
	self:InitEvent()
	self:InitMsg()
	self:InitPara()
end

function UIInEdenSevenDay:OnClickDay(day)
	if(day>self._currDay)then
		GF.ShowMessage(ccClientText(15909))
		return
	end
	if(self._nowDay > 0 and self._nowDay ~= day)then
		local trans = self._sevenDaysTrans[self._nowDay]
		self:ChangeDayImage(trans,false, self._nowDay)
		self:ChangeDayTransTop(trans, false)
		self:ChangeDayEffect(false, self._nowDay)
		self:ChangeDayOrderLayer(self._nowDay, false)
		self._dayBgImgList[self._nowDay].raycastTarget = true
	end
	local trans = self._sevenDaysTrans[day]
	self:ChangeDayImage(trans,true, day)
	self:ChangeDayTransTop(trans, true)
	self:ChangeDayEffect(true, day)
	self:ChangeDayOrderLayer(day, true)
	self._dayBgImgList[day].raycastTarget = false
	self._nowDay =  day
	self:InitBottomBtnList()
	self:ShowRedPoint()
end
-------------------------------------------------设置Cell----------------------------------------------------------
function UIInEdenSevenDay:InitShopList(itemdata)
	local zeroList = {}
	if not itemdata then
		itemdata = {}
	end
	for i, v in ipairs(itemdata) do
		table.insert(zeroList,v)
	end
	if self._curShopId ~= 4 then
		table.sort(zeroList,function (a,b)
			local aStatus = a.goalData.status
			local bStatus = b.goalData.status
			local aIndex = aStatus == 1 and 1 or aStatus == 0 and 2 or 3
			local bIndex = bStatus == 1 and 1 or bStatus == 0 and 2 or 3
			local aSort = a.sort
			local bSort = b.sort
			if(aIndex~=bIndex)then
				return aIndex<bIndex
			end
			if(aSort~=bSort)then
				return aSort<bSort
			end
			return false
		end)
	else
		table.sort(zeroList,function (a,b)
			local aCount = (a.MarketData.personalGoal - a.MarketData.personal)==0 and 1 or 0
			local bCount = (b.MarketData.personalGoal - b.MarketData.personal)==0 and 1 or 0
			local aSort = a.sort
			local bSort = b.sort
			if(aCount~=bCount)then
				return aCount<bCount
			end
			if(aSort~=bSort)then
				return aSort<bSort
			end
			return false
		end)
	end

	if(self._celluiList)then
		self._celluiList:RefreshSimpleList(zeroList)
	else
		self._celluiList = self:GetUIScroll("_celluiList")
		self._celluiList:Create(self.mItemList,zeroList,function (...) self:OnDrawShop(...) end, UIItemList.WRAP)
	end
	--local uiList = self._celluiList:GetList()
	--uiList:EnableLoadAnimation(true, 0.1, 1)
end

function UIInEdenSevenDay:Reset(pb)
	local sid = pb.sid
	if self._sid ~= sid then return end
	local count = 0
	local pageId = 0
	-- 活动分页数据
	for i, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		if page then
			if not self._pages then
				self._pages = {}
			end

			self._pages[v.pageId] = {}
			self._pages[v.pageId].entry = {}

			for p,q in pairs(page.entry) do
				local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,q.pageId,q.entryId)
				if not entryCfg then
					return
				end
				local data = {
					pageId  = q.pageId,
					entryId = q.entryId,
					title   = entryCfg.name,
					desc	= entryCfg.description,
					items	= LxDataHelper.ParseItem(entryCfg.reward),
					MarketData = q.MarketData,
					moreInfo = q.moreInfo,
					goalData = q.goalData,
					sort	= entryCfg.sort,
				}

				table.insert(self._pages[v.pageId].entry, data)
			end

			count = i
			pageId = tonumber(v.pageId)
		end
	end
	if(#pb.pages<=1)then
		if((pageId == 8 and self._curShopId == 4) or (pageId < 8 and self._curShopId < 4))then
			self:OnSelectShop(self._curShopId)
		elseif(pageId == 9)then
			self:InitBoxBtnList()
		end
		self:ShowRedPoint()
		return
	end
	self:InitBoxBtnList()

	if count == 1 and pageId == 9 then
		return
	end
	self:OnClickDay(self._nowDay)
	--self:InitBottomBtnList()
	--self:ShowRedPoint()
end

function UIInEdenSevenDay:OnDrawBoxFunc(itemdata,itempos)
	local item = self._boxListTrans[itempos]
	local Num = self:FindWndTrans(item,"Num")
	local IconList = self:FindWndTrans(item,"IconList")
	local iconTrans = self:FindWndTrans(IconList,"Icon")
	local itemNum = self:FindWndTrans(IconList, "Num")
	local eff = self:FindWndTrans(IconList,"Eff")
	--local redPoint = self:FindWndTrans(item,"redPoint")

	local entryId = itemdata.entryId
	local itemsList = itemdata.items
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local jumpId = tonumber(entryCfg.jumpId)
	local goalData = itemdata.goalData

	-- 状态(0-不可领取, 1-可领取，2-已领取)
	local status = tonumber(goalData.status)
	local schedules = goalData.schedules
	local schedule = tonumber(schedules[1].schedule)  	-- 当前进度
	local goal = tonumber(schedules[1].goal)			-- 目标进度
	--local isShowRed = status == 1 and true or false

	local color
	if schedule >= goal then
		color = "ffffffff"
	else
		color = "e5e5e5ff"
	end

	self:SetWndText(Num,goal)
	color = LUtil.ColorByHex(color)
	local numText = self:FindWndText(Num)
	self:SetXUITextColor(numText,color)
	--CS.ShowObject(redPoint,isShowRed)

	-- 宝箱道具
	--local numText = CS.FindTrans(item,"NumText")

	local itemInfo = itemsList[1]
	local itemData = {
		itemType 	= tonumber(itemInfo.itemType),
		itemId 		= tonumber(itemInfo.itemId),
		itemNum 	= tonumber(itemInfo.itemNum)
	}

	local uiCommonList = self._uiBoxCommonList
	local InstanceID = itempos
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(iconTrans)
	end
	baseClass:SetCommonReward(itemData.itemType, itemData.itemId,itemData.itemNum)
	self:SetWndClick(iconTrans,function()
		if status == 1 then
			gModelActivity:OnActivityReceiveGoalReq(self._sid,9,entryId)
		else
			gModelGeneral:ShowCommonItemTipWnd(itemData)
		end
	end)

	baseClass:SetShowGouImg(status == 2)
	baseClass:DoApply()
	CS.ShowObject(eff,status == 1)
	if(status == 1)then
		self:PlayEff(eff,"fx_ui_qiandao_lingqutishi","box"..itempos,nil, 65)
	end

	if entryId == self._boxCount then
		local value = schedule/goal
		self._progress:SetUIProgress(value)
		self:SetWndText(self.mStartNum, string.replace(ccClientText(15912), schedule))
	end
end

-- 获取对应页签任务
function UIInEdenSevenDay:GetTaskByTabIndex(shopId)
	if not shopId then
		return
	end
	local taskList = {}
	local curDayTaskList = self:GetDailyTaskByDay(self._nowDay)
	for i, v in pairs(curDayTaskList) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		local moreInfoList = string.split(entryCfg.moreInfo,"=")
		local index = tonumber(moreInfoList[2])

		if index == shopId then
			table.insert(taskList,v)
		end
	end
	return self:Sort(taskList)
end

function UIInEdenSevenDay:InitPara()
	--self._activity = self:GetWndArg("activityData")

	local page = self:GetWndArg("page")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	self._bookPageSpIsLoaded = false
	self._heroSp = self:CreateWndSpine(self.mHeroCGEffRoot, "Mengyouxianjing_ailisi", "Mengyouxianjing_ailisi", false)
	self._bookPageSp = self:CreateWndSpine(self.mChangePageEffRoot, "Mengyouxianjing", "MengyouxianjingPage", false,
			function(dpSpine)
				self._bookPageSp = dpSpine
				self:BookPageSpineLoadFunc() end)

	--7天卡牌翻转动作名字
	self._sevenDaysSpineNameList = {
		[1] = "idle4",
		[2] = "idle5",
		[3] = "idle6",
		[4] = "idle7",
		[5] = "idle8",
		[6] = "idle9",
		[7] = "idle10",
	}

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIInEdenSevenDay:PlayBookPageCardDrawSpine()
	local curDay = self._currDay
	if not curDay then
		return
	end

	local animName = self._sevenDaysSpineNameList[curDay]
	self._bookPageSp:PlayAnimationSolid(animName,false)
	self._bookPageSp:SetAnimationCompleteFunc(function()
		CS.ShowObject(self.mChangePageEffRoot, false)
		CS.ShowObject(self.mDayList, true)
	end)
end

--设置标题图片
function UIInEdenSevenDay:ShowTitle(imgpath,imgPos)
	if string.isempty(imgpath) then
		CS.ShowObject(self.mTitleImg,false)
		return
	end
	CS.ShowObject(self.mTitleImg,true)
	self:SetWndEasyImage(self.mTitleImg,imgpath,nil,true)
	if string.isempty(imgPos) then
		return
	end
	local strs = string.split(imgPos,",")
	if #strs>=2 then
		local posX = tonumber(strs[1])
		local posY = tonumber(strs[2])
		local pos = Vector2.New(posX,posY)
		self.mTitleImg.anchoredPosition = pos
	end
end

function UIInEdenSevenDay:ChangeDayEffect(bool, dayIndex)
	local eff    = self._dayEffTransList[dayIndex]
	if not eff then
		return
	end

	local effectName = self._dayEffectName
	local effKey = effectName.. dayIndex

	CS.ShowObject(self._dayEffTransList[dayIndex], bool)
	if bool and not self:FindWndEffectByKey(effKey) then
		self:CreateWndEffect(eff,effectName,effKey,100,false,false,
		nil, nil, nil, nil, nil, nil, 2)
	end
end


--#####################################################################################################################
--## Spine ############################################################################################################
--#####################################################################################################################
function UIInEdenSevenDay:PlayBookPageStartSpine()
	CS.ShowObject(self.mCoverBg, false)
	CS.ShowObject(self.mChangePageEffRoot, true)
	self._bookPageSp:PlayAnimationSolid("idle1",false)
	self._bookPageSp:SetAnimationCompleteFunc(function()
		self:PlayBookPageCardDrawSpine()
	end)
end

function UIInEdenSevenDay:OnDrawItemFunc(list,item,itemdata,itempos)
	local root = self:FindWndTrans(item,"Root")
	--local numText = CS.FindTrans(item,"NumText")

	local itemData = {
		itemType = itemdata.itemType,
		itemId = itemdata.itemId,
		itemNum = tonumber(itemdata.itemNum)
	}

	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	baseClass:SetCommonReward(itemData.itemType, itemData.itemId,itemData.itemNum)
	self:SetWndClick(root,function()
		gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)
	baseClass:DoApply()

	--self:SetWndText(numText, LUtil.NumberCoversion(itemData.itemNum))
end

-- 显示红点
function UIInEdenSevenDay:ShowRedPoint()
	if table.isempty(self._pages) then return end
	for i, obj in pairs(self._dayCanGetEffTransList) do
		CS.ShowObject(obj,false)
	end
	for i, obj in pairs(self._redPointList) do
		CS.ShowObject(obj,false)
	end
    for i, obj in pairs(self._redPointTransList) do
        CS.ShowObject(obj,false)
    end

	for i = 1, 7 do

		if(i>self._currDay)then
			break
		end
        local isRed = gModelRedPoint:GetActivityRedPointPage(self._sid,i)
        local bool = isRed
        local pagesData = self._pages[i]
        local dataList = pagesData and pagesData.entry or {}
        --local bool = false
        local obj = self._dayCanGetEffTransList[i]
        local redObj = self._redPointTransList[i]
        --for j, v in ipairs(dataList) do
        --    if v.goalData and v.goalData.status == 1 then  -- 可领取的任务
        --        bool = true
        --        break
        --    end
        --end
        --if(not bool)then
        --    bool = self:GetShopRedPoint(i)
        --end
		if(self._nowDay~=i)then
			if bool then
				local effKey = self._canGetEffName..i
				local endFunc = function(effNode)
					self:ChangeDayEffectOrderLayer(effNode, i)
				end
				self:CreateWndEffect(obj,self._canGetEffName,effKey,100,false,
						false, nil,nil,nil,nil,
						nil, endFunc)
			end
			CS.ShowObject(obj,bool)
		else
			for j, v in ipairs(dataList) do
				if v.goalData and v.goalData.status == 1 then  -- 可领取的任务
					local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
					local moreInfoList = string.split(entryCfg.moreInfo,"=") or {}
					local index = tonumber(moreInfoList[2])
					local obj = self._redPointList[index]
					CS.ShowObject(obj,true)
				end
			end
			local redBool = self:GetShopRedPoint(i)
			local obj = self._redPointList[4]
			CS.ShowObject(obj,redBool)
		end
        --CS.ShowObject(redObj,bool)
	end
end

-- 获取对应天数的任务
function UIInEdenSevenDay:GetDailyTaskByDay(day)
	if not day or table.isempty(self._pages) then
		return {}
	end
	local index = day > 7 and 7 or day
	-- 活动条目
	if(not self._pages[index])then
		return {}
	end
	return self:Sort(self._pages[index].entry)
end

function UIInEdenSevenDay:Sort(list)
	local data = list
	table.sort(data,function (a,b)
		return a.entryId < b.entryId
	end)
	return data
end
-------------------------------------------------设置天数----------------------------------------------------------
-- 七天图标
function UIInEdenSevenDay:OnSevenDayClick()
	if(not self._sevenDaysTrans)then
		self._sevenDaysTrans = {}
		for i = 1, 7 do
			local item = CS.FindTrans(self.mDayList,"Day" .. i)
			local dayEffTrans = CS.FindTrans(item,"Eff/SelectEff")
			local canGetEffTrans = self:FindWndTrans(item, "Eff/CanGetEff")
            local redPoint = self:FindWndTrans(item, "redPoint")
			self._sevenDaysTrans[i] = item
			self._dayCanGetEffTransList[i] = canGetEffTrans
			self._dayEffTransList[i] = dayEffTrans
            self._redPointTransList[i] = redPoint
		end
	end
	for i, v in ipairs(self._sevenDaysTrans) do
		local bg = CS.FindTrans(v,"Bg")
		local icon = self._currDay < i and self._sevenDayNoOpenIcon or self._sevenDaysIconList[i]
		self:SetWndEasyImage(bg,icon, function () CS.ShowObject(bg,true) end)
		self:SetWndClick(v,function () self:OnClickDay(i) end,LSoundConst.CLICK_PAGE_COMMON)

		local bgImg = bg.gameObject:GetComponent(typeofImage)
		self._dayBgImgList[i] = bgImg
	end
end
-----------------------------------------------------------------------------------------------------------
-- 宝箱领取
function UIInEdenSevenDay:InitBoxBtnList()
	if(not self._pages[9])then
		return
	end
	-- 条目id：目标奖励9
	local data = self:Sort(self._pages[9].entry)
	self._boxCount = #data

	if(not self._boxListTrans)then
		self._boxListTrans = {}
		for i = 1, 4 do
			local item = CS.FindTrans(self.mBoxList,"Box" .. i)
			local redPoint = CS.FindTrans(item,"redPoint")
			self._boxListTrans[i] = item
			self._boxRedPointList[i] = redPoint
		end
	end
	for i, v in ipairs(self._boxListTrans) do
		self:OnDrawBoxFunc(data[i], i)
		self:OnBoxRed(data[i], i)
	end

	CS.ShowObject(self.mBox, true)
end

function UIInEdenSevenDay:OnBoxRed(itemdata,itempos)
	local redPoint = self._boxRedPointList[itempos]
	local goalData = itemdata.goalData

	-- 状态(0-不可领取, 1-可领取，2-已领取)
	local status = tonumber(goalData.status)
	CS.ShowObject(redPoint,status == 1)
end

function UIInEdenSevenDay:PlayEff(trans,eff,key,isDes, scale)
	if(isDes)then
		self:DestroyWndEffectByKey(key)
	end
	self:CreateWndEffect(trans,eff,key,scale or 100,
			false,false,0,nil,scale or 100)
end

function UIInEdenSevenDay:OnDrawShop(list,item, itemdata, itempos)
	local titleBgTrans = self:FindWndTrans(item,"titleBg")
	local titleTrans = self:FindWndTrans(item,"titleBg/title")
	local rewardList = self:FindWndTrans(item,"rewardList")
	local OriginalPrice = self:FindWndTrans(item,"OriginalPrice")
	local BuyBtn = self:FindWndTrans(item,"BtnList/BuyBtn")				-- 购买
	local ReceiveBtn = self:FindWndTrans(item,"BtnList/ReceiveBtn")		-- 领取
	local GoToBtn = self:FindWndTrans(item,"BtnList/GoToBtn")			-- 前往
	local eff = self:FindWndTrans(item,"BtnList/Eff")
	local SellOut = self:FindWndTrans(item,"SellOut")
	local Received = self:FindWndTrans(item,"Received")
	local TaskProgress = self:FindWndTrans(item,"TaskProgress")
	local buyCount = self:FindWndTrans(item,"BuyCount")
	CS.ShowObject(OriginalPrice,false)
	CS.ShowObject(BuyBtn,false)
	CS.ShowObject(ReceiveBtn,false)
	CS.ShowObject(GoToBtn,false)
	CS.ShowObject(SellOut,false)
	CS.ShowObject(Received,false)
	self:SetWndText(TaskProgress,"")
	self:SetWndText(buyCount,"")

	local isTask = self._curShopId ~= 4 and true or false --是否任务
	-- 礼包标题颜色底图
	--local titleColorIndex = tonumber(itemdata.desc)
	--local curColorList = self._titleColorList[titleColorIndex]
	self:SetWndText(titleTrans,itemdata.title)
	self:InitTextSizeWithLanguage(titleTrans, -4)
	self:InitTextLineWithLanguage(titleTrans, -40)
	--self:SetWndText(titleTrans,string.replace(ccClientText(15910),curColorList[1],itemdata.title))
	--self:SetWndEasyImage(titleBgTrans,curColorList[2])
	local InstanceID = item:GetInstanceID()
	if not isTask then
		self:SetGiftInfo(item,itemdata)	-- 礼包
	else
		self:SetTaskInfo(item,itemdata)	-- 任务
	end
	local status = tonumber(itemdata.goalData.status)
	CS.ShowObject(eff,isTask and status == 1)
	if(isTask and status == 1)then
		if(not self._effList[InstanceID])then
			local res2 = "fx_anniu_02"
			self:PlayEff(eff,res2,InstanceID)
			self._effList[InstanceID] = true
		end
	end
	-- 礼包奖励
	local uiList = self:GetUIScroll(InstanceID)
	local itemsList = itemdata.items
	local itemNum   = #itemsList
	if(uiList:GetList())then
		uiList:RefreshList(itemsList)
	else
		uiList:Create(rewardList,itemsList,function (...) self:OnDrawItemFunc(...) end)
	end
	uiList:EnableScroll(true,true)
end

function UIInEdenSevenDay:SetTaskInfo(item,itemdata)
	local ReceiveBtn = CS.FindTrans(item,"BtnList/ReceiveBtn")		-- 领取
	local GoToBtn = CS.FindTrans(item,"BtnList/GoToBtn")			-- 前往
	local Received = CS.FindTrans(item,"Received")
	local TaskProgress = CS.FindTrans(item,"TaskProgress")
	local goalData = itemdata.goalData
	local status,schedule,goal
	status = tonumber(goalData.status)	-- 状态(0-不可领取, 1-可领取，2-已领取)
	schedule = tonumber(goalData.schedules[1].schedule) --当前值
	goal = tonumber(goalData.schedules[1].goal) --目标值
	local color = goal == schedule and "#139057" or "#c81212"
	local countStr = "(" .. schedule .. "/" .. goal .. ")"
	local buyCountText = string.format("<%s>%s</color>",color,countStr)
	self:SetWndText(TaskProgress,buyCountText)
	if status == 0 then
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
		CS.ShowObject(GoToBtn,true)
		self:SetWndButtonText(GoToBtn, ccClientText(10152))
		self:SetWndClick(GoToBtn,function()
			local jumpId = tonumber(entryCfg.jumpId)
			local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,true)
			if isOpen then
				gModelFunctionOpen:Jump(jumpId,self:GetWndName())
				--self:WndClose()
			end
		end)
	elseif status == 1 then
		CS.ShowObject(ReceiveBtn,true)
		self:SetWndButtonText(ReceiveBtn, ccClientText(10151))
		local entryId = tonumber(itemdata.entryId)
		self:SetWndClick(ReceiveBtn,function() gModelActivity:OnActivityReceiveGoalReq(self._sid,self._nowDay,entryId) end)
	else
		CS.ShowObject(Received,true)
	end
end

function UIInEdenSevenDay:SetContent()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	self._activity =gModelActivity:GetActivityBySid(self._sid)
	local activityData = JSON.decode(self._activity.moreInfo)

	local data =webData.config
	--7天类型标签
	self._sevenDaysTabNameList = {
		[1] = string.split(data.oneTabName,","),
		[2] = string.split(data.twoTabName,","),
		[3] = string.split(data.threeTabName,","),
		[4] = string.split(data.fourTabName,","),
		[5] = string.split(data.fiveTabName,","),
		[6] = string.split(data.sixTabName,","),
		[7] = string.split(data.sevenTabName,","),
	}
	-- 七天图标
	self._sevenDayNoOpenIcon = "activity_dream_btn_0";	--未开放时图标
	self._sevenDaysIconList = string.split(data.tabIcon,",")
	-- 额外参数
	self._moreInfo = self._activity.moreInfo
	-- 天数
	self._currDay = tonumber(activityData.nowDay)--math.floor(tonumber(data.nowDay) / 1000 / 86400)
	self._currDay = math.range(self._currDay, 1, 7)-- 最大七天
	if not self._nowDay then
		self._nowDay = self._currDay	--默认当前天数index
	end
	if not self._curShopId then
		self._curShopId = 1		--默认当前标签
	end
	local titlePath = data.titleIcon
	local titlePos = data.titleIconPos
	self:ShowTitle(titlePath,titlePos)
	-- 顶部背景图
	--self._image = data.image
	--self:SetWndEasyImage(self.mBg,self._image)
	-- 宝箱进度条初始点图片资源——数值条0的位置
	local consumeData  = string.split(data.initialItem, '=')
	local boxItemId   = tonumber(consumeData[2])
	self._consumeData	= {
		itemType = tonumber(consumeData[1]),
		itemId = boxItemId,
	}
	self:SetWndEasyImage(self.mStart,gModelItem:GetItemIconByRefId(boxItemId))
	-------------------------------------------------------------------------------------------------
	-- 活动剩余时间
	self._endTime = tonumber(self._activity.endTime)
	--printInfoN("endtime "..self._endTime)
	self:TimerStop(self._actSeventDays)
	if self._endTime> 0 then   --非永久活动
		local curTime = GetTimestamp()
		local time = self._endTime - curTime
		if time <= 0 then
			self:WndClose()
			return
		else
			self:TimerStart(self._actSeventDays,1,false,-1)
		end

		self:SetTimeStr()
	else
		local strText = ccClientText(16800)
		self:SetWndText(self.mTimeText,strText .. ccClientText(10170))
	end

	-- 页签红点列表
	self._redPointList = {}
	-- 天数红点列表
	self._dayRedPointList = {}
	-- 天数提示可领取特效列表
	self._dayCanGetEffTransList = {}
	-- 天数选择特效列表
	self._dayEffTransList = {}
    self._redPointTransList = {}
	-- 天数点击检测的背景图
	self._dayBgImgList = {}
	-- 宝箱进度条
	self._progress = self:UIProgressFind(self.mProgressBg,"meWonderlandSevenDayProgress",0)
	-- 宝箱红点列表
	self._boxRedPointList = {}
	-- 活动分页数据
	self._pages = {}
	self:OnSevenDayClick()
	self:SetWndText(self.mButtomDesc, ccClientText(10103))

	self._dayEffectName = "fx_mengyouxianjing_kapai"
end

function UIInEdenSevenDay:OnSelectShop(index)
	if not self._uiShopTypeList then
		return
	end
	if(self._curShopId > 0)then
		local trans = self._uiShopTypeList[self._curShopId]
		self:ChangeTypeItem(trans,false)
	end
	local trans = self._uiShopTypeList[index]
	self:ChangeTypeItem(trans,true)
	self._curShopId =  index
	local shopList = self:GetShopShow()
	local itemdata =  shopList[index]
	self:InitShopList(itemdata)
end

function UIInEdenSevenDay:InitEvent()
	self:SetWndClick(self.mBgImage,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIInEdenSevenDay:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)

	self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
		self._activity =gModelActivity:GetActivityBySid(self._sid)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
		self._activity =gModelActivity:GetActivityBySid(self._sid)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		self:Reset(pb)
	end)

	self:WndEventRecv(EventNames.ON_TIME_ZERO, function ()
		self:SetContent()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end

function UIInEdenSevenDay:ChangeDayOrderLayer(dayIndex, isTop)
	--只有顶部的3个要调整层级+
	if dayIndex > 3 then return end

	local trans = self._sevenDaysTrans[dayIndex]

	local itemChangeOrder
	if isTop then
		itemChangeOrder = 5
	else
        itemChangeOrder = 1
	end

	local instCanvas = trans:GetComponent(typeofCanvas)
	if instCanvas then
		instCanvas.sortingOrder = self:GetWndSortOrder() + itemChangeOrder
	end
    local changeOrder
	--修改特效层级
	if isTop then
		changeOrder = 2
	else
		changeOrder = 0
	end
	local selectEffTrans = self._dayEffTransList[dayIndex]
	if selectEffTrans and CS.IsValidObject(selectEffTrans) then
		local rendererSort = selectEffTrans:GetComponent(typeofUISorting)
		if rendererSort then
			rendererSort:SetParentOrder(self:GetWndSortOrder() + changeOrder)
			rendererSort:UpdateSorting()
		end
	end

	local canGetEffTrans = self._dayCanGetEffTransList[dayIndex]
	if canGetEffTrans and CS.IsValidObject(canGetEffTrans) then
		local rendererSort = selectEffTrans:GetComponent(typeofUISorting)
		if rendererSort then
			rendererSort:SetParentOrder(self:GetWndSortOrder() + changeOrder)
			rendererSort:UpdateSorting()
		end
	end
    local _redPointTrans = self._redPointTransList[dayIndex]
    if _redPointTrans and CS.IsValidObject(_redPointTrans) then
        local rendererSort = _redPointTrans:GetComponent(typeofCanvas)
        if rendererSort then
            rendererSort.sortingOrder = self:GetWndSortOrder() + itemChangeOrder + 1
        end
    end
end

function UIInEdenSevenDay:ChangeDayTransTop(trans, isTop)
	local layerIndex
	if isTop then
		layerIndex = 6
	else
		layerIndex = self._nowDay - 1
	end

	trans:SetSiblingIndex(layerIndex)
end

function UIInEdenSevenDay:OnDrawShopTypeBtn(list,item, itemdata, itempos)
	local nameText = CS.FindTrans(item,"NameText")
	local redPoint = CS.FindTrans(item,"redPoint")
	local index = itempos
	itemdata.index = index
	self._redPointList[index] = redPoint
	self._uiShopTypeList[index]= item
	local nameCfg =self._sevenDaysTabNameList[self._nowDay][index] or ""
	--local colorName =LUtil.FormatColorStr(nameCfg,"lightGrey")
	local str = string.gsub(nameCfg,"\\n","\n")
	self:SetWndText(nameText,str)
	self:InitTextSizeWithLanguage(nameText, -6)
	self:SetWndClick(item,function () self:OnSelectShop(index) end,LSoundConst.CLICK_PAGE_COMMON)
end

function UIInEdenSevenDay:ChangeDayImage(trans,bool, dayIndex)
	--local click = CS.FindTrans(trans,"Click")
	--CS.ShowObject(click,bool)


	local bg = CS.FindTrans(trans,"Bg")
	local icon = self._sevenDaysIconList[dayIndex]
	if icon then
		if bool then
			icon = icon.."_1"
		end

		self:SetWndEasyImage(bg,icon)
	end

	--self._dayEffTransList[i]
end

function UIInEdenSevenDay:GetShopRedPoint(day)
	local list = self:GetShopByDay(day) or {}
	for i, v in pairs(list) do
		if v.MarketData.personalGoal - v.MarketData.personal>0 then  -- 可购买的任务
			local exp = v.MarketData.expend2
			local expArr = string.split(exp,"=")
			if(tonumber(expArr[3]) == 0)then
				return true
			end
		end
	end
	return false
end

function UIInEdenSevenDay:BookPageSpineLoadFunc()
	self._bookPageSpIsLoaded = true
	if self._bookPageSpIsLoaded and self._activityCfgDataLoad then
		self:PlayBookPageStartSpine()
	end
end
-------------------------------------------------设置页签----------------------------------------------------------
-- 页签列表显示
function UIInEdenSevenDay:InitBottomBtnList()
	local shopList = self:GetShopShow()
	self._uiShopTypeList = {}
	if(self._typeuiList)then
		self._typeuiList:RefreshData(shopList)
	else
		self._typeuiList = self:GetUIScroll("_typeuiList")
		self._typeuiList:Create(self.mShopTypeList,shopList,function (...) self:OnDrawShopTypeBtn(...) end)
	end
	self:OnSelectShop(self._curShopId)
end

function UIInEdenSevenDay:SetTimeStr()
	local curTime = GetTimestamp()
	local time = self._endTime - curTime
	if time > 0 then
		local strText = ccClientText(15506)
		local str = LUtil.FormatTimespanCn(time)
		self:SetWndText(self.mTimeText,strText .. str)
	else
		self:TimerStop(self._actSeventDays)
		self:WndClose()
	end
end

function UIInEdenSevenDay:GetShopShow()
	local data = {}
	for i = 1, 3 do
		local list = self:GetTaskByTabIndex(i)
		list.index = i
		table.insert(data,list)
	end
	local list = self:GetShopByDay(self._nowDay)
	if list then
		list.index = 4
		table.insert(data,list)
	end
	return data
end

function UIInEdenSevenDay:ChangeTypeItem(trans,bool)
	if not trans then
		return
	end
	local onImg = CS.FindTrans(trans,"OnImage")
	local nameText = CS.FindTrans(trans,"NameText")
	local color
	if bool then
		color = "513310ff"
	else
		color = "dfe3ebff"
	end
	CS.ShowObject(onImg,bool)
	color = LUtil.ColorByHex(color)
	local xuitxt = self:FindWndText(nameText)
	self:SetXUITextColor(xuitxt,color)
end

-- 获取对应天数的商品
function UIInEdenSevenDay:GetShopByDay(day)
	if not day or table.isempty(self._pages) then
		return
	end
	local List = {}
	local index = day > 7 and 7 or day
	local curPage = self._pages[8]
	local dataList
	if curPage then
		dataList = curPage.entry
	end

	if not dataList then return end

	for i, v in ipairs(dataList) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		local moreInfoList = string.split(entryCfg.moreInfo,",")
		if tonumber(moreInfoList[1]) == index then
			table.insert(List,v)
		end
	end
	return self:Sort(List)
end

function UIInEdenSevenDay:SetGiftInfo(item,itemdata)
	local OriginalPrice = CS.FindTrans(item,"OriginalPrice")
	local OriginalNum = CS.FindTrans(OriginalPrice,"AutoDiv/ZheKouTxt")
	local BuyBtn = CS.FindTrans(item,"BtnList/BuyBtn")	--购买
	local text = CS.FindTrans(BuyBtn,"text")
	local Image = CS.FindTrans(BuyBtn,"Image")
	local freeTxt = CS.FindTrans(BuyBtn,"freeTxt")
	local buyCount = CS.FindTrans(item,"BuyCount")
	local SellOut = CS.FindTrans(item,"SellOut")
	local marketData = itemdata.MarketData
	local personal,personalGoal,item1,item2
	personal = tonumber(marketData.personal)  -- 已使用个人限购次数
	personalGoal = tonumber(marketData.personalGoal)  -- 个人可购买次数
	--item1 = LxDataHelper.ParseItem_3(marketData.expend1)

	local pageId = itemdata.pageId
	local entryId = itemdata.entryId
	local expend2 = marketData.expend2
	local expend2List = string.split(expend2 or "" , "=")
	local isShowCost = #expend2List <= 1
	local title = itemdata.title
	local items = itemdata.items
	local btnStr
	local showBtnItem = false
	local isFree = false
	local buyType
	local img
	local iconImgPath
	if isShowCost then
		btnStr = gModelPay:GetShowByWelfareId(tonumber(expend2))
		buyType = UIInEdenSevenDay.TYPE_BUY_RMB
	else
		item2 = LxDataHelper.ParseItem_3(marketData.expend2)
		isFree = item2.itemNum == 0
		if isFree then
			btnStr = ccClientText(15911)
			buyType = UIInEdenSevenDay.TYPE_BUY_FREE
		else
			showBtnItem = true
			btnStr = item2.itemNum
			local iconRef = gModelItem:GetRefByRefId(tonumber(item2.itemId))
			iconImgPath = iconRef.icon
			buyType = UIInEdenSevenDay.TYPE_BUY_ITEM
		end
		img = "public_btn_2_2"
	end

	--server = tonumber(marketData.server)  -- 已使用全服限购次数
	--serverGoal = tonumber(marketData.serverGoal)  -- 全服可购买次数
	--resetRemainTime = tonumber(marketData.resetRemainTime) -- 距离下一次重置剩余毫秒时间，永不重置返回-1
	--condResetType = tonumber(marketData.condResetType) -- 限购重置类型
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,pageId,entryId)
	local moreInfoData = string.split(entryCfg.moreInfo,",")
	local discountNum  = tonumber(moreInfoData[3])

	CS.ShowObject(Image,showBtnItem)
	CS.ShowObject(text,showBtnItem)
	CS.ShowObject(freeTxt,not showBtnItem)
	self:SetWndEasyImage(Image,iconImgPath)
	local btnTextTrans = showBtnItem and text or freeTxt
	self:SetWndText(btnTextTrans,btnStr)
	self:SetBtnImageAndMat(BuyBtn,img,btnTextTrans)

	-- 礼包剩余次数
	local countStr = personalGoal - personal
	local buyCountText = string.replace(ccClientText(15905),countStr)
	self:SetWndText(buyCount,buyCountText)
	local isShow = countStr > 0
	CS.ShowObject(buyCount,isShow)
	CS.ShowObject(BuyBtn,isShow)
	CS.ShowObject(SellOut,not isShow)

	local isShowDiscount = (discountNum and discountNum > 0) and isShow
	CS.ShowObject(OriginalPrice,isShowDiscount)
	if isShowDiscount then
		self:SetWndText(OriginalNum,discountNum.."%")
	end

	-- 购买按钮
	self:SetWndClick(BuyBtn,function()
		local callFunc
		if(buyType == UIInEdenSevenDay.TYPE_BUY_FREE)then
			callFunc = function()
				gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId,entryId)-- 免费购买
			end
		else
			local needVIP = tonumber(moreInfoData[2])
			local vipLv = tonumber(gModelPlayer:GetVipLevel())
			if(buyType == UIInEdenSevenDay.TYPE_BUY_ITEM)then
				-- 钻石购买
				local itemId2 = item2.itemId
				local itemNum2 = item2.itemNum
				local func = function()
					if vipLv >= needVIP then
						local bagNum = gModelItem:GetNumByRefId(itemId2)
						if bagNum >= itemNum2 then
							gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId,entryId)
						else
							gModelGeneral:OpenGetWayWnd({itemId = itemId2})
						end
					else
						GF.ShowMessage(string.replace(ccClientText(15908),needVIP))
					end
				end

				callFunc = function()
					GF.OpenWnd("UIOrdinTip",{refId = 110004,func = func,
											   para = {itemNum2,title}, consume={itemNum2, itemId2}})
				end
			else
				callFunc = function()
					if vipLv >= needVIP then
						gModelPay:GiftPayCtrl(entryId,tonumber(expend2),ModelPay.PAY_TYPE_ACTIVITY,nil,self._sid,pageId)
					else
						GF.ShowMessage(string.replace(ccClientText(15908),needVIP))
					end
				end
			end
		end
		GF.OpenWnd("UIGiftBuyPop", {
			title = title,
			desc = buyCountText,
			payStr = btnStr,
			payItemId = item2 and item2.itemId or nil,
			payFunc = callFunc,
			itemList = items,
		})
	end)
end

function UIInEdenSevenDay:ChangeDayEffectOrderLayer(effTrans, dayIndex)
	if dayIndex < 4 then
		return
	end

	if not CS.IsValidObject(effTrans) then return end
	local dpParentTrans = 	effTrans.parent.transform
	if dpParentTrans and CS.IsValidObject(dpParentTrans) then
		local rendererSort = dpParentTrans:GetComponent(typeofUISorting)
		if not rendererSort then
			rendererSort = dpParentTrans.gameObject:AddComponent(typeofUISorting)
		end
		rendererSort:SetParentOrder(self:GetWndSortOrder() + 1)
		rendererSort:UpdateSorting()
	end
end


function UIInEdenSevenDay:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:SetContent()

	self._activityCfgDataLoad = true
	if self._bookPageSpIsLoaded and self._activityCfgDataLoad then
		self:PlayBookPageStartSpine()
	end

	gModelActivity:OnActivityPageReq(self._sid)
end

function UIInEdenSevenDay:OnTimer(key)
	if(key == self._actSeventDays)then
		self:SetTimeStr()
	end
end

------------------------------------------------------------------
return UIInEdenSevenDay


