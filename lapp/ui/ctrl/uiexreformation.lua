---
--- Created by Administrator.
--- DateTime: 2023/10/15 17:25:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIExreFormation:LWnd
local UIExreFormation = LxWndClass("UIExreFormation", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIExreFormation:UIExreFormation()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIExreFormation:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIExreFormation:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIExreFormation:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetPara()
	self:InitData()

	self:SetStaticContent()
	self:ShowContent()
	self:ShowRaceFilter()
	self:ShowHeroList()

	self:InitUIEvent()

	self:WndEventRecv(EventNames.On_Item_Change,function () self:ShowExploreInfo() end)
	self:WndNetMsgRecv(LProtoIds.CreateExploreResp,function ()
		self:WndClose()
	end)
end


function UIExreFormation:OnClickHero(itemdata,itempos,selected)
	local heroId = itemdata:GetId()

	local isOn = gModelExplore:IsHeroExecuted(heroId)
	if isOn then
		local str =ccClientText(12329) --"该伙伴进行任务中"
		GF.ShowMessage(str)
		return
	end

	local receive =nil
	if selected then
		receive =self:HeroDown(heroId)
		if not receive then
			return
		end
	else
		local receive = self:HeroUp(heroId)
		if not receive then
			GF.ShowMessage(ccClientText(12322))
			return
		end
	end

	local list = self._heroUIList:GetList()
	list:DrawItemByIndex(itempos)

	self:ShowExploreHero()
	self:ShowConditionList()
end

function UIExreFormation:SetSectionText(tran,str)
	local text = self:FindWndTrans(tran,"UIText")
	self:SetWndText(text,str)
end

function UIExreFormation:ShowConditionTip(refId,tran)
    CS.ShowObject(self.mTipsBg,true)
	local ref = gModelExplore:GetConditionRef(refId)
	self:SetWndText(self.mTipText,ccLngText(ref.description))

    local uiCam = gLGameUI:GetCSUICamera()
    local screenPos =uiCam:WorldToScreenPoint(tran.position)
	screenPos = screenPos + Vector3.New(0,64,0)
	local pos = uiCam:ScreenToWorldPoint(screenPos)
	self.mTipRoot.position = pos
end

function UIExreFormation:TweenBottomPart()

	if self._isTweened then
		return
	end

	self._isTweened = true

	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("move")
	local tween = YXTween.TweenFloat(0,1,0.3,function (t)
		local pos = Vector3.Lerp(Vector3.zero,Vector3(0,568,0),t)
		self.mBottom.anchoredPosition = pos
		pos = Vector3.Lerp(Vector3.zero,Vector3(0,214,0),t)
		self.mTop.anchoredPosition = pos
	end)
	seq:Append(tween)
	seq:Play()
end


function UIExreFormation:OnClickGoto()

	local isPass = self:CheckCondition(true)

	if not isPass then
		return
	end



	local id = self._explore:GetRefId()
	local heroList = {}
	for k,v in ipairs(self._heroData.heroList) do
		if not v.isEmpty then
			table.insert(heroList,v.heroId)
		end
	end



	gModelExplore:CreateExploreReq(id,heroList)

end

function UIExreFormation:HeroUp(heroId)

	local race = gModelHero:GetTypeById(heroId)
	if not race then
		return false
	end

	local heroList =self._heroData.heroList
	local received = false
	for k,v in ipairs(heroList) do
		if v.isEmpty then
			v.heroId = heroId
			v.isEmpty = false
			received = true
			break
		end
	end
	if not received then
		return false
	end


	local selectList = self._heroData.selectList
	selectList[heroId]= true
	local raceList = self._heroData.raceList
	local cnt = raceList[race] or 0
	cnt = cnt+1
	raceList[race] = cnt

	return true
end

function UIExreFormation:OnClickOnKey()
	local raceList = self._raceList
	local filter = {}
	local filterCnt = {}
	local total = 0
	for k,v in pairs(raceList) do
		local race = v.race
		filter[race] = true
		if not filterCnt[race] then
			filterCnt[race] = 1
		else
			filterCnt[race] = filterCnt[race]+ 1
		end
		total = total +1
	end

	local starNum = self._starNum
	local heroList = gModelHero:GetHeroList()
	local filteredList = {}
	for k,v in pairs(filter) do
		filteredList[k] = {}
	end

	local otherRaceList ={}
	for k,v in pairs(heroList) do
		local heroId = v:GetId()
		local star = v:GetStar()
		local race = gModelHero:GetTypeById(heroId)
		local isExecuted = gModelExplore:IsHeroExecuted(heroId)
		if not isExecuted then
			if filter[race] then
				local raceHeroList = filteredList[race]
				table.insert(raceHeroList,v)
			else
				if star>= starNum then
					table.insert(otherRaceList,v)
				end
			end
		end
	end

	local receiveList ={}
	local isFind = false
	for k,v in pairs(filter) do
		local raceHeroList = filteredList[k]
		if #raceHeroList>0 then
			table.sort(raceHeroList,function (a,b) return
			a:GetStar()<b:GetStar()
			end)
		end
		local cnt = filterCnt[k]
		local isSearched = false
		for i=1,cnt do
			local herodata =nil
			if #raceHeroList <=0 then
				break
			end
			if not isFind and not isSearched then

				local totalNum = #raceHeroList
				for j=1,totalNum do
					local data = raceHeroList[j]
					if data:GetStar()>= starNum then
						isFind = true
						herodata = table.remove(raceHeroList,j)
						break
					end
				end
				isSearched = true
				if not isFind then
					herodata = table.remove(raceHeroList,1)
				end
			else
				herodata = table.remove(raceHeroList,1)
			end
			table.insert(receiveList,herodata)
		end
	end

	local isSuc = false
	if  #receiveList == total then
		if isFind then
			isSuc = true
		else
			if #otherRaceList > 0 then
				table.sort(otherRaceList,function (a,b) return
					a:GetStar()<b:GetStar()
				end)
				table.insert(receiveList,otherRaceList[1])
				isSuc = true
			end
		end
	end

	if isSuc then

		local oldIds = {}
		for k,v in ipairs(self._heroData.heroList) do
			if not v.isEmpty then
				table.insert(oldIds,v.heroId)
			end
		end

		for k,v in ipairs(oldIds) do
			self:HeroDown(v)
		end

		for k,v in ipairs(receiveList) do
			local heroId = v:GetId()
			self:HeroUp(heroId)
		end

		self:ShowExploreHero()
		self:ShowConditionList()
		local list = self._heroUIList:GetList()
		list:DrawAllItems()
	else
		local str = ccClientText(12326)
		GF.ShowMessage(str)
	end
end

function UIExreFormation:OnDrawRace(list, item,itemdata)
	local raceIcon = self:FindWndTrans(item,"raceIcon")
	local select = self:FindWndTrans(item,"select")
	--local selectIcon = self:FindWndTrans(select,"icon")
	--local selectCheck = self:FindWndTrans(select,"check")

	local race = itemdata.race
	local icon = gModelHero:GetRaceImgByRefId(race)
	if icon then
		self:SetWndEasyImage(raceIcon,icon)
	end
	CS.ShowObject(select,not itemdata.isEmpty)

	self:SetWndClick(item,function ()
		self:ShowConditionTip(itemdata.refId,item)
	end)
end



function UIExreFormation:ShowRaceFilter()
	--local raceList = {0,1,2,3,4,5,6}
	local raceList = {0,1,2,3,4,5}
	local itemList = self:GetUIScroll("showList")

	local raceList=gModelHero:GetHeroRaceRefSortByRank()
	itemList:Create(self.mRaceTypeList,raceList,function (...) self:OnDrawRaceFilter(...) end)
end

function UIExreFormation:FormatTimeStr(timespan)
	local t2 = ccClientText(10305)
	local t3 = ccClientText(10306)
	local t4 = ccClientText(10355)
	if timespan >3600 then
		local hour = math.floor(timespan/3600)
		local min = math.floor(timespan/60)%60
		local str = nil
		if min == 0 then
			str = string.format("%d%s", hour,t2)
		else
			str = string.format("%d%s%d%s", hour,t2,min,t3)
		end
		return str
	else
		local min = math.floor(timespan/60)
		return string.format("%d%s",min,t3)
	end
end

function UIExreFormation:InitUIEvent()
	self:SetWndClick(self.mEnvoyBtn,function () self:OnClickGoto() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mGotoBtn,function () self:OnClickOnKey() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mTipsBg,function ()
		CS.ShowObject(self.mTipsBg,false)

	end)
end

function UIExreFormation:OnDrawExploreHero(list, item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootItem = self:FindWndTrans(AniRoot,"item")
	local itemHeroIcon = self:FindWndTrans(AniRootItem,"heroIcon")
	local itemAdd = self:FindWndTrans(AniRootItem,"add")


	local isEmpty = itemdata.isEmpty
	CS.ShowObject(itemAdd,isEmpty)
	CS.ShowObject(itemHeroIcon,not isEmpty)
	if not isEmpty then
		local heroId = itemdata.heroId
		local heroData = gModelHero:GetHeroById(heroId)
		local refId = heroData:GetRefId()
		local data =
		{
			id =heroId,
			refId = refId,
			star = heroData:GetStar(),
			level = heroData:GetLv(),
			skin = heroData:GetSkin(),
			isResonance = heroData:GetResonanceStatus(),
			treeInfo = heroData:GetTreeInfo(),
		}
		self:CreateHeroIconImpl(itemHeroIcon,data)
		self:SetIconClickScale(AniRoot, true)
	end


	self:SetWndClick(AniRoot,function ()

		self:TweenBottomPart()
		if not isEmpty then
			self:OnClickExploreHero(itemdata,itempos)
		end

	end)
end

function UIExreFormation:ShowExploreHero()
	local heroList =self._heroData.heroList
	local itemList =self._exploreHeroUIList
	if not itemList then
		itemList = self:GetUIScroll("exploreHeroUIList")
		self._exploreHeroUIList = itemList
		itemList:Create(self.mExploreList,heroList,function (...) self:OnDrawExploreHero(...) end)
	else
		itemList:RefreshList(heroList)
	end
end

function UIExreFormation:RefreshBtnShow()
	local isPass = self:CheckCondition()
	self:SetWndButtonGray(self.mEnvoyBtn,not isPass)
end

function UIExreFormation:OnSelectChange(race)
	local curSelect = self._curSelect or 0
	if curSelect == race then
		return
	end

	local item = self._raceFilterItemList[curSelect]
	local select = self:FindWndTrans(item,"select")
	CS.ShowObject(select,false)
	item = self._raceFilterItemList[race]
	select = self:FindWndTrans(item,"select")
	CS.ShowObject(select,true)

	self._curSelect = race
	self:ShowHeroList()
end

function UIExreFormation:HeroDown(heroId)
	local heroList =self._heroData.heroList
	local received = false
	for k,v in ipairs(heroList) do
		if not v.isEmpty and v.heroId== heroId then
			v.isEmpty = true
			received = true
			break
		end
	end

	if not received then
		return false
	end

	local selectList = self._heroData.selectList
	selectList[heroId]= nil

	local raceList = self._heroData.raceList
	local race = gModelHero:GetTypeById(heroId)
	local cnt = raceList[race]
	if cnt then
		cnt = cnt-1
		raceList[race] = cnt
	end

	return true
end

function UIExreFormation:OnDrawHero(list, item,itemdata,itempos)
	local heroTran = self:FindWndTrans(item,"HeroIcon")
	local mask = self:FindWndTrans(item,"mask")
	local maskUIText = self:FindWndTrans(mask,"UIText")
	local heroId = itemdata:GetId()
	local selected = self:IsHeroSelected(heroId)

	local data =
	{
		id = heroId,
		refId = itemdata:GetRefId(),
		star = itemdata:GetStar(),
		level = itemdata:GetLv(),
		skin = itemdata:GetSkin(),
		isResonance = itemdata:GetResonanceStatus(),
		selected = selected,
		treeInfo = itemdata:GetTreeInfo(),
	}

	self:CreateHeroIconImpl(heroTran,data)


	self:SetIconClickScale(heroTran, true)
	self:SetWndClick(heroTran, function ()
		self:OnClickHero(itemdata,itempos,selected)
	end)

	local isOn = gModelExplore:IsHeroExecuted(heroId)
	CS.ShowObject(mask,isOn)
	self:SetWndText(maskUIText,ccClientText(12328))
end

function UIExreFormation:SetPara()
	self._explore  = self:GetWndArg("exploreItem")
	self._actData = self:GetWndArg("actData") or 1

end

function UIExreFormation:ShowConditionList()
	local raceList =self._raceList
	for k,v in ipairs(raceList) do
		local race = v.race
		local cnt = self._heroData.raceList[race]
		if cnt and cnt>= v.cnt then
			v.isEmpty = false
		else
			v.isEmpty = true
		end
	end

	local itemList = self:FindUIScroll("expList")
	if not itemList then
		itemList = self:GetUIScroll("expList")
		itemList:Create(self.mRaceList,raceList,function (...) self:OnDrawRace(...) end)
	else
		itemList:RefreshList(raceList)
	end

	local starNum = self._starNum
	local max =0
	for k,v in ipairs(self._heroData.heroList) do
		if not v.isEmpty then
			local heroId = v.heroId
			local data = gModelHero:GetHeroById(heroId)
			if data then
				max = math.max(max,data:GetStar())
			end
		end
	end
	self._maxStar = max

	local showCheck = false
	local maxStr = tostring(max)
	if max>=starNum then
		maxStr = LUtil.FormatColorStr(maxStr,"green")
		showCheck = true
	end
	self:SetWndText(self.mStarNum,maxStr.."/"..starNum)
	CS.ShowObject(self.mStarCheck,showCheck)

	self:SetWndClick(self.mStar,function ()
        if not self._startCondition then
            return
        end
        self:ShowConditionTip(self._startCondition,self.mStar)
    end)


	self:RefreshBtnShow()
end

function UIExreFormation:SetStaticContent()
	--local str = ccClientText(12316)
	--self:SetWndText(self.mSection1,str)
	local str = ccClientText(12317)
	self:SetSectionText(self.mSection2,str)
	str = ccClientText(12318)
	self:SetSectionText(self.mSection3,str)
	--str = ccClientText(12319)
	--self:SetWndText(self.mInfoText,str)
	--local text = self:FindWndTrans(self.mGotoBtn,"text")
	str = ccClientText(12320)
	--self:SetWndText(text,str)

	self:SetWndButtonText(self.mGotoBtn,str)
	--text = self:FindWndTrans(self.mEnvoyBtn,"text")
	str = ccClientText(12321)
	--self:SetWndText(text,str)
	self:SetWndButtonText(self.mEnvoyBtn,str)

	local itemId = tonumber(gModelExplore:GetExplorePara("expendItem"))
	local iconPath = gModelItem:GetItemImgByRefId(itemId)
	self:SetWndEasyImage(self.mPointIcon,iconPath)
end

function UIExreFormation:OnClickExploreHero(itemdadta,itempos)
	local receive = self:HeroDown(itemdadta.heroId)
	if not receive then
		return
	end
	local list = self._exploreHeroUIList:GetList()
	list:DrawItemByIndex(itempos)
	self:ShowConditionList()

	list = self._heroUIList:GetList()
	list:DrawAllItems()
end

function UIExreFormation:OnDrawRaceFilter(list,item,itemdata)
	local icon = self:FindWndTrans(item,"icon")
	local select = self:FindWndTrans(item,"select")

	--local iconPath = self._raceIconList[itemdata]
	local iconPath =itemdata.icon
	if iconPath then
		self:SetWndEasyImage(icon,iconPath)
	end

	local curSelect = self._curSelect or 0
	local show = curSelect == itemdata.refId
	CS.ShowObject(select,show)
	self._raceFilterItemList[itemdata.refId] = item
	self:SetWndClick(icon,function () self:OnSelectChange(itemdata.refId) end)
end

function UIExreFormation:InitData()
	self._qualityTitlePath=
	{
		[1]= "explore_ui_title_1",
		[2]= "explore_ui_title_2",
		[3]= "explore_ui_title_3",
		[4]= "explore_ui_title_4",
		[5]= "explore_ui_title_5",
		[6]= "explore_ui_title_6",
	}

	self._raceIconList=
	{
		[0]= "public_race_0",
		[1]= "public_race_icon_1",
		[2]= "public_race_icon_2",
		[3]= "public_race_icon_3",
		[4]= "public_race_icon_4",
		[5]= "public_race_icon_5",
		[6]= "public_race_icon_6",
	}


	self._heroData={
		heroList={},
		selectList ={},
		raceList={}
	}
	self._raceFilterItemList= {}

end


function UIExreFormation:ShowHeroList()
	local curRace = self._curSelect or 0
	local heroDataList = {}
	local allHero = gModelHero:GetHeroList()
	for k,v in pairs(allHero) do
		local heroId = v:GetId()

		--if not isExecuted then
			if curRace ==0 or  curRace == gModelHero:GetTypeById(heroId) then
				table.insert(heroDataList,v)
			end
		--end
	end
	--local isExecuted = gModelExplore:IsHeroExecuted(heroId)

	local comp = function(hero1,hero2)


		local star1,star2 = hero1:GetStar(),hero2:GetStar()
		local lv1,lv2 = hero1:GetLv(),hero2:GetLv()
		local power1,power2 = hero1:GetPower(),hero2:GetPower()
		local refId1,refId2 = hero1:GetRefId(),hero2:GetRefId()
		local id1,id2 = hero1:GetId(),hero2:GetId()

		local isOneOn = gModelExplore:IsHeroExecuted(id1) and 2 or 1
		local isTwoOn = gModelExplore:IsHeroExecuted(id2) and 2 or 1
		if isOneOn ~= isTwoOn then
			return isOneOn<isTwoOn
		end

		if star1 ~= star2 then
			return star1 > star2
		end
		if lv1 ~= lv2 then
			return lv1 > lv2
		end
		if power1 ~= power2 then
			return power1 > power2
		end
		--if refId1 ~= refId2 then
		--	return refId1 < refId2
		--end
		--
		local ref1 = gModelHero:GetHeroRef(refId1)
		local ref2 = gModelHero:GetHeroRef(refId2)

		local rank1=gModelHero:GetHeroRaceRefRank(ref1.raceType)
		local rank2=gModelHero:GetHeroRaceRefRank(ref2.raceType)
		if rank1 ~= rank2 then
			return rank1 < rank2
		end

		return id1 > id2
	end
	table.sort(heroDataList,comp)

	local itemList  = self._heroUIList
	if not itemList then
		itemList = self:GetUIScroll("heroUIList")
		self._heroUIList= itemList
		itemList:Create(self.mHeroList,heroDataList,function (...) self:OnDrawHero(...) end,UIItemList.WRAP)
	else
		itemList:RefreshList(heroDataList)
	end
end

function UIExreFormation:IsHeroSelected(heroId)
	local heroList = self._heroData.heroList
	local selected = false
	for k,v in ipairs(heroList) do
		if not v.isEmpty and v.heroId== heroId then
			selected = true
			break
		end
	end
	return selected
end


function UIExreFormation:ShowContent()
	local refId = self._explore:GetRefId()
	local cfg = gModelExplore:GetExploreConfig(refId)
	local time = cfg.needTime
	local timeStr = self:FormatTimeStr(time)
	local str =string.replace(ccClientText(12319),timeStr)
	self:SetWndText(self.mInfoText,str)


	--local reward = gModelExplore:GetRewardList(refId)
	--if reward then
	--	local iconTrans = CS.FindTrans(self.mReward, "CommonUI/Icon")
	--	local itemdata = reward[1]
	--	local rewardIcon= self._rewardIcon
	--	if not rewardIcon then
	--		rewardIcon = CommonIcon:New()
	--		self._rewardIcon = rewardIcon
	--		rewardIcon:Create(iconTrans)
	--	end
	--	rewardIcon:SetCommonReward(itemdata.itemType,itemdata.itemId,itemdata.itemNum)
	--	rewardIcon:EnableShowNum(true)
	--	rewardIcon:DoApply()
    --
	--	self:SetIconClickScale(iconTrans, true)
	--	self:SetWndClick(iconTrans, function() gModelGeneral:ShowCommonItemTipWnd(itemdata) end)
	--end

	local quality = self._explore:GetQuality()
	local imgPath = self._qualityTitlePath[quality]
	if imgPath then
		self:SetWndEasyImage(self.mTitleBg,imgPath)
	end
	local name =""
	local cfg = gModelExplore:GetExploreConfig(refId)
	if cfg then
		name = ccLngText(cfg.name)
	end
	self:SetWndText(self.mTitleText,name)

	local heroNum = cfg.herNum
	local heroList = {}
	for k=1 ,heroNum do
		local data ={
			isEmpty = true,
			index = k
		}
		table.insert(heroList,data)
	end

	self._heroData.heroList = heroList
	self._heroNum = heroNum
	self:ShowExploreHero()

	local condition =LxDataHelper.ParseNumber_Sign(cfg.condition,';')
	local starNum= 0
	local raceList = {}
	--local raceFilter ={}
	local starCondition = nil
	for k,v in ipairs(condition) do
		local ref = gModelExplore:GetConditionRef(v)
		local para = gModelExplore:ParseCondition(ref.condition)
		if para.type == ModelExplore.CONDITION_TYPE_STAR then
			starNum = para.typePara
			starCondition = v
		elseif para.type == ModelExplore.CONDITION_TYPE_RACE then
			local race = para.typePara

			local data =
			{
				refId = v,
				race = race,
				isEmpty = true,
				cnt = para.itemNum,
			}

			table.insert(raceList,data)
		end
	end

	self._starNum = starNum
	self._startCondition = starCondition
	self._raceList = raceList



	self:ShowConditionList()

	self:ShowExploreInfo()
end

function UIExreFormation:CheckCondition(showTip)

	if not self._isInfoEnough then
		if showTip then
			GF.ShowMessage(ccClientText(12325))
		end
		return
	end

	if self._maxStar <self._starNum then
		if showTip then
			local str = string.replace(ccClientText(12323),self._starNum)
			GF.ShowMessage(str)
		end

		return
	end

	local ispass = true
	local race = 0
	local raceList =self._raceList
	for k,v in ipairs(raceList) do
		if v.isEmpty then
			ispass = false
			race = v.race
			break
		end
	end

	if not ispass then
		if showTip then
			local raceCfg = gModelHero:GetHeroRaceRefByRefId(race)
			local raceName =ccLngText(raceCfg.name)
			local str = string.replace(ccClientText(12324),raceName)
			GF.ShowMessage(str)
		end

		return
	end



	return true
end


function UIExreFormation:ShowExploreInfo()
	local refId = self._explore:GetRefId()
	self._isInfoEnough = true
	local own = gModelExplore:GetCurExplorePoint()
	local expend = gModelExplore:GetExploreExpend(refId)
	local req = expend.itemNum * self._actData
	local color= "green"
	if req>own then
		color = "red"
		self._isInfoEnough = false
	end
	local str = LUtil.FormatColorStr(req,color).."/"..own
	self:SetWndText(self.mExploreNum,str)
end

------------------------------------------------------------------
return UIExreFormation


