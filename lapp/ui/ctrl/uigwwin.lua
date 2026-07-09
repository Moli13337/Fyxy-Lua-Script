---
--- Created by BY.
--- DateTime: 2023/10/31 10:17:30
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGwWin:LWnd
local UIGwWin = LxWndClass("UIGwWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGwWin:UIGwWin()
	self:SetHideHurdle()

	---@type table<number,CommonIcon>
	self._heroIconList={}			--英雄Icon列表

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGwWin:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)
	self:ClearCommonIconList(self._hyperList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGwWin:OnCreate()
	LWnd.OnCreate(self)
	self._tabTransList={}			--标签列表
	self._tabIndex=0				--标签索引

	self._heroTransList={}			--英雄列表
	self._heroIndex=0				--英雄索引
	self._resourceTransList={}		--资源获取列表
	self._resourceIndexList={}		--资源获取索引
	self._recommendTransList={}		--推荐阵容列表
	self._recommendIndexList={}		--推荐阵容索引
	self._hyperList			= {}	--描述超链接
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGwWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	
	self:RefreshForeign()
end

function UIGwWin:ChangeBtnImage(trans,bool)
	local color
	local onImage = self:FindWndTrans(trans,"OnImage")
	local text = self:FindWndTrans(trans,"UIText")
	if bool then
		CS.ShowObject(onImage,true)
		color = "734f22ff"
	else
		CS.ShowObject(onImage,false)
		color = "cbe3faff"
	end
	color = LUtil.ColorByHex(color)
	local xuitxt = self:FindWndText(text)
	self:SetXUITextColor(xuitxt,color)
end

function UIGwWin:RefreshCultivate()
	CS.ShowObject(self.mDi, false)
	CS.ShowObject(self.mCultivate,true)
	CS.ShowObject(self.mBg_Image,true)
	CS.ShowObject(self.mTasText,true)
	self._selfInfos=gModelGrow:GetStrengthMe()
	if(self._heroList)then
		self._heroList:RefreshList(self._selfInfos)
	else
		self._heroList = self:GetUIScroll("heroList")
		self._heroList:Create(self.mHeroScroll,self._selfInfos,function (...) self:HeroListItem(...)  end)
	end
	if(#self._selfInfos>0)then
		self:OnClickHeroIcon(1)
	end
end

function UIGwWin:SaveWndArg()
	if self._tabIndex then
		local argList = self:GetWndArgList() or {}
		argList["page"] = self._tabIndex
		self:SetWndArg(argList)
	end
end

function UIGwWin:RefreshRecommend()
	self:InitTabUI()
	CS.ShowObject(self.mRecommend,true)

	local _recommendRefList = gModelGrow:GetGrowLineupRef()
	if(self._recommendList)then
		self._recommendList:RefreshList(_recommendRefList)
	else
		self._recommendList = self:GetUIScroll("recommendCell")
		self._recommendList:Create(self.mRecommendScroll,_recommendRefList,function (...) self:RecommendListItem(...) end)
		self._recommendList:EnableScroll(true,false)
	end

	local jumpCanGetIndex
	for k,v in ipairs(_recommendRefList) do
		local finishCond = v.finishCond
		local taskData = gModelQuest:GetTaskDataByRefId(finishCond)
		if taskData then
			local state= taskData:GetState()
			if state == 1 then
				jumpCanGetIndex = k
				break
			end
		end
	end

	if jumpCanGetIndex then
		self._jumpRecommendIndex = jumpCanGetIndex
		self:TimerStop("time2")
		self:TimerStart("time2",0.1,false,1)
	end
end

function UIGwWin:ChangeResourceCell(trans,bool,index)
	self._resourceIndexList[index]=bool
	local InstanceID = trans:GetInstanceID()
	local cellScroll = self:FindWndTrans(trans,"CellScroll")
	self:RefreshArrowShow(trans,index,"ResourceListItem")
	if not bool then
		CS.ShowObject(cellScroll,false)
		return
	end
	CS.ShowObject(cellScroll,true)
	local list = gModelGrow:GetGrowItemJumpRef(index)
	local uiList = self:GetUIScroll(InstanceID)
	if(uiList:GetList())then
		uiList:RefreshData(list)
	else
		uiList:Create(cellScroll,list,function (...) self:ResourceCellListItem(...) end)
	end
end

function UIGwWin:RefreshForeign()
	if self._isVie then
		self:InitTextLineWithLanguage(self.mAttrRestrainBtnTxt,0)
		LxUiHelper.SetSizeWithCurAnchor(self.mAttrRestrainBtnTxt,0,100)
		self:SetAnchorPos(self.mAttrRestrainName5,Vector2.New(100,95))
	end
end

function UIGwWin:OnClickResourceCell(index)--点击资源获取
	local _index = 0
	for i, v in pairs(self._resourceIndexList) do
		if(v)then
			_index = i
			break
		end
	end
	if(_index>0)then
		local trans=self._resourceTransList[_index]
		self:ChangeResourceCell(trans,false,_index)
	end
	if(_index == index)then
		return
	end
	local trans=self._resourceTransList[index]
	self:ChangeResourceCell(trans,true,index)

	local maxNum = #self._resourceTransList
	if index >= maxNum then	--只有最后一个上提一下
		self._resIndex = index
		self:TimerStop("time")
		self:TimerStart("time",0.1,false,1)
	end
end

function UIGwWin:OnClickHeroIcon(index)--点击英雄列表
	if(self._heroIndex == index)then
		return
	end
	if(self._heroIndex>0)then
		local trans=self._heroTransList[self._heroIndex]
		self:ChangeHeroIconImage(trans,false)
	end
	local trans=self._heroTransList[index]
	self:ChangeHeroIconImage(trans,true)
	self._heroIndex=index
	local heroId= self._selfInfos[index].id
	gModelGrow:OnStrengthOtherReq(heroId)
end

function UIGwWin:ChangeRecommendCell(trans,bool,index)
	self._recommendIndexList[index]=bool
	local image = self:FindWndTrans(trans,"Image")
	self:RefreshArrowShow(trans,index,"RecommendListItem")
	if not bool then
		CS.ShowObject(image,false)
		--self:SetWndText(toggle,ccClientText(15108))
		return
	end
	CS.ShowObject(image,true)
	--self:SetWndText(toggle,ccClientText(15109))
end

function UIGwWin:RefreshAttrRestrain()
    local tabIndex = self._tabIndex
    local isShowBtn = tabIndex == 3
    CS.ShowObject(self.mAttrRestrainBtn, isShowBtn)
    self:SetAttrRestrainShow(false)
end

function UIGwWin:TabListItem(list,item, itemdata, itempos)--标签cell
	self._tabTransList[itempos]=item
	local text = self:FindWndTrans(item,"UIText")
	self:SetWndText(text,ccLngText(itemdata.name))
	self:InitTextSizeWithLanguage(text, -2)
	self:SetWndClick(item, function(...) self:OnClickTab(itempos) end)
end

function UIGwWin:OnClickRecommendCell(index)--点击推荐阵容
	local _index = 0
	for i, v in pairs(self._recommendIndexList) do
		if(v)then
			_index = i
			break
		end
	end
	if(_index>0)then
		local trans=self._recommendTransList[_index]
		self:ChangeRecommendCell(trans,false,_index)
	end
	if(_index == index)then
		return
	end
	local trans=self._recommendTransList[index]
	self:ChangeRecommendCell(trans,true,index)

	local maxNum = #self._recommendTransList
	if index >= maxNum then	--只有最后一个上提一下
		self._jumpRecommendIndex = index
		self:TimerStop("time2")
		self:TimerStart("time2",0.1,false,1)
	end
end

function UIGwWin:SetAttrRestrainShow(isShow)
    self._isShowAttrRestrainPop = isShow
    CS.ShowObject(self.mAttrRestrainPop, isShow)
end

function UIGwWin:OnClickAttrRestrain()
    local isShow = not self._isShowAttrRestrainPop
    self:SetAttrRestrainShow(isShow)
end

function UIGwWin:ChangeHeroIconImage(trans,bool)
	local onImage = self:FindWndTrans(trans,"OnImage")
	if not bool then
		CS.ShowObject(onImage,false)
		return
	end
	CS.ShowObject(onImage,true)
end

function UIGwWin:SetHeroIcon(iconTrans, instanceId, heroData, showMask)
	local baseClass = self._heroIconList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._heroIconList[instanceId] = baseClass
		baseClass:Create(iconTrans)
		self:SetIconClickScale(iconTrans, true)
	end
	baseClass:SetHeroDataSet(heroData)
	baseClass:SetShowMaskOnly(showMask or false)
	baseClass:DoApply()
end

function UIGwWin:InitEvent()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end)
    self:SetWndClick(self.mAttrRestrainBtn, function() self:OnClickAttrRestrain() end)
    self:SetWndClick(self.mAttrRestrainPop, function() self:SetAttrRestrainShow(false) end)
end

function UIGwWin:OnClickCombat(itemdata)--点击战斗预览
	--gModelBattle:OnClickShamBattle(itemdata.warReport,function ()
	--	GF.OpenWnd("UIGwWin",{index = 3})
	--end)
	--gModelBattle:OnClickShamBattle(itemdata.warReport,function()
	--	FireEvent(EventNames.OPEN_HISTROY_WND)
	--end)
	--self:WndClose()

	gModelBattle:OnClickShamBattle(itemdata.warReport)
end

function UIGwWin:RecommendHeroListItem(list,item, itemdata, itempos)--推荐阵容英雄列表cell
	local heroTrans = self:FindWndTrans(item,"Root/HeroIcon")
	local heroName  = self:FindWndTrans(item, "Name")
	local refId		= itemdata.refId
	local heroData={
		refId=refId,
		star=gModelHero:GetHeroRef(refId).initStar,
	}
	local InstanceID = item:GetInstanceID()
	local name = gModelHero:GetHeroNameByRefId(heroData.refId,heroData.star)


	self:SetHeroIcon(heroTrans, InstanceID, heroData, not itemdata.have)
	self:SetWndText(heroName, name)
	self:InitTextShowWithLanguage(heroName)

	self:SetWndClick(heroTrans,function ()
		gModelGeneral:OpenHeroSimpleTip(refId)
		--gModelGeneral:OpenHeroTipByRefId(itemdata.refId)
	end)
end

function UIGwWin:InitCultivate()
	self:InitTabUI()
	if(not self._selfInfos)then
		gModelGrow:OnStrengthReq()
		return
	end
	self:RefreshCultivate()
end

function UIGwWin:InitCommand()
	local index = self:GetWndArg("page") or 1
	self:SetWndText(self.mTasText,ccClientText(15103))
	local list=gModelGrow:GetGrowConfigRef()
	local uiList = self:GetUIScroll("tabCell")
	uiList:Create(self.mTabScroll,list,function (...) self:TabListItem(...) end)
	self:OnClickTab(index)

    self:SetWndText(self.mAttrRestrainBtnTxt, ccClientText(16622))
    self:SetWndText(self.mAttrRestrainTitle, ccClientText(16622))
    self:SetWndText(self.mAttrRestrainName1, ccClientText(16614))
    self:SetWndText(self.mAttrRestrainName2, ccClientText(16615))
    self:SetWndText(self.mAttrRestrainName3, ccClientText(16613))
    self:SetWndText(self.mAttrRestrainName4, ccClientText(16617))
    self:SetWndText(self.mAttrRestrainName5, ccClientText(16616))
    self:SetWndText(self.mAttrRestrainName6, ccClientText(1010401))
    self:SetWndText(self.mAttrRestrainDesc, ccClientText(1010402))
	self:InitTextLineWithLanguage(self.mAttrRestrainDesc, -30)
end

function UIGwWin:RefreshVSData()
	CS.ShowObject(self.mVS_Image,true)
	local _strengthInfo = gModelGrow:GetStrengthOther()
	local _selfInfos= self._selfInfos[self._heroIndex]
	self._info={}
	for i, v in ipairs(_selfInfos.info) do
		self._info[v.type]=v.score
	end
	self:SetVSData(self.mMe,_selfInfos, true)
	self:SetVSData(self.mOher,_strengthInfo, false)
	local list ={}
	for i, v in ipairs(_strengthInfo.info) do
		if v.score and self._info[v.type] then
			if(v.score~=0 or self._info[v.type]~=0)then
				table.insert(list,v)
			end
		end

	end
	if(self._cultivateList)then
		self._cultivateList:RefreshList(list)
	else
		self._cultivateList = self:GetUIScroll("cultivateCell")
		self._cultivateList:Create(self.mCultivateScroll,list,function (...) self:CultivateListItem(...) end)
		self._cultivateList:EnableScroll(true,false)
	end
end

function UIGwWin:RefreshArrowShow(trans,index,key)
	local list
	if key == "ResourceListItem" then
		list = self._resourceIndexList
	elseif key == "RecommendListItem" then
		list = self._recommendIndexList
	end
	if not list then return end

	local bool = list[index]
	local upArrow = self:FindWndTrans(trans, "Info/ToggleBtn/UpArrow")
	local downArrow = self:FindWndTrans(trans, "Info/ToggleBtn/DownArrow")
	CS.ShowObject(upArrow, bool)
	CS.ShowObject(downArrow, not bool)
end

function UIGwWin:CultivateListItem(list,item, itemdata, itempos)--养成对决cell
	local icon = self:FindWndTrans(item,"Icon")
	local result = self:FindWndTrans(item,"ResultImage")
	local nameText = self:FindWndTrans(item,"NameText")
	local desText = self:FindWndTrans(item,"DesText")
	local meBar = self:FindWndSlider(self:FindWndTrans(item,"MeBar"))
	local oherBar = self:FindWndSlider(self:FindWndTrans(item,"OherBar"))
	local meValueText = self:FindWndTrans(item,"MeValueText")
	local oherValueText = self:FindWndTrans(item,"OherValueText")
	local steadyBtn = self:FindWndTrans(item,"SteadyBtn")
	local goOnBtn = self:FindWndTrans(item,"GoOnBtn")

	local growType = itemdata.type

	local ref =gModelGrow:GetGrowCompareRefByRefId(growType)
	local meValue = self._info[growType]
	printInfoN(string.format("meValue %s ,other %s",meValue,itemdata.score))
	local win
	if(meValue>=itemdata.score)then
		win = 1
	else
		win = 2
	end

	local jump = gModelGrow:GetCompareJumpByType(growType)--根据类型获取跳转id

	local winIcon=""
	if(win==1)then
		winIcon="bestronger_txt_1"
		local text=self:FindWndTrans(steadyBtn,"XUIText")
		self:InitTextSizeWithLanguage(text, -4)
		self:SetWndText(text,ccClientText(15106))

		meBar.maxValue = meValue
		oherBar.maxValue = meValue
		self:SetWndClick(steadyBtn, function(...)
			if(gModelFunctionOpen:CheckIsOpened(jump,true))then
				gModelFunctionOpen:Jump(jump,self:GetWndName())
			end
		end)
	else
		winIcon="bestronger_txt_2"
		local text=self:FindWndTrans(goOnBtn,"XUIText")
		self:SetWndText(text,ccClientText(15107))
		self:InitTextSizeWithLanguage(text, -4)
		self:InitTextLineWithLanguage(text, -50)

		meBar.maxValue = itemdata.score
		oherBar.maxValue = itemdata.score
		self:SetWndClick(goOnBtn, function(...)
			if(gModelFunctionOpen:CheckIsOpened(jump,true))then
				gModelFunctionOpen:Jump(jump,self:GetWndName())
			end
		end)
	end
	CS.ShowObject(steadyBtn,win==1)
	CS.ShowObject(goOnBtn,win==2)
	self:SetWndEasyImage(result,winIcon,function ()
		CS.ShowObject(result,true)
	end)
	if(ref.icon~="")then
		self:SetWndEasyImage(icon,ref.icon,function ()
			CS.ShowObject(icon,true)
		end)
	end
	self:SetWndText(nameText,ccLngText(ref.name))
	self:SetWndText(desText,ccLngText(ref.des))
	self:SetWndText(meValueText,LUtil.NumberCoversion(meValue))
	self:SetWndText(oherValueText,LUtil.NumberCoversion(itemdata.score))
	meBar.value=meValue
	oherBar.value=itemdata.score
end

function UIGwWin:RefreshResourceGet()
	self:InitTabUI()
	CS.ShowObject(self.mResourceGet,true)
	if(self._resourceRefList)then
		return
	end
	self._resourceRefList = gModelGrow:GetGrowItemRef()
	if(self._resourceList)then
		self._resourceList:RefreshList(self._resourceRefList)
	else
		self._resourceList = self:GetUIScroll("resourceCell")
		self._resourceList:Create(self.mResourceScroll,self._resourceRefList,function (...) self:ResourceListItem(...) end)
		self._resourceList:EnableScroll(true,false)
	end
end

function UIGwWin:SetVSData(trans,data, isMe)
	local rank = self:FindWndTrans(trans,"RankText")
	local heroIcon = self:FindWndTrans(trans,"Root/HeroIcon")
	local nameText = self:FindWndTrans(trans,"NameText")
	local powerText = self:FindWndTrans(trans,"PowerText")
	local lvTxt = self:FindWndTrans(trans,"LvTxt")
	local rankStr = ""
	local rankRef = gModelRank:GetRankingRefData(ModelRank.RANK_GROW)
	if(data.rank <= 0 or data.rank > rankRef.quantity)then
		rankStr = ccClientText(15111)
	else
		rankStr = string.replace(ccClientText(15104),data.rank)
	end
	self:SetWndText(rank,rankStr)
	self:SetWndText(nameText,data.playerName)
	--local lv = gModelGrow:GetTypeValue(ModelGrow.TYPE_LV,data.info)
	--local lvColor = "DDE1E1"
	if data.isResonance == 1 then lvColor = "1bdef2" end
	--self:SetWndText(lvTxt,string.replace(ccClientText(15113),lvColor,lv))
	self:SetWndText(powerText,string.replace(ccClientText(isMe and 15105 or 15116),LUtil.PowerNumberCoversion(data.power)))
	local heroData={
		id=data.id,
		refId=data.refId,
		star=gModelGrow:GetTypeValue(ModelGrow.TYPE_STAR,data.info),
		level=gModelGrow:GetTypeValue(ModelGrow.TYPE_LV,data.info),
		fightPower = data.power,
		grade = data.grade,
		isResonance = data.isResonance,
		skin = data.skin,
	}
	self:SetHeroIcon(heroIcon, heroIcon:GetInstanceID(), heroData)

	self:SetWndClick(heroIcon,function ()
		if(not data.playerId or data.playerId == 0)then
			--gModelGeneral:OpenHeroSimpleTip(data.refId)
			GF.ShowMessage(ccClientText(15114))
		else
			gModelHero:ReqShowHeroTip(data.playerId,heroData)
		end
	end)
end

function UIGwWin:OnClickTab(index)--点击标签
	if(self._tabIndex == index)then
		return
	end
	if(self._tabIndex>0)then
		local trans = self._tabTransList[self._tabIndex]
		self:ChangeBtnImage(trans,false)
	end
	local trans = self._tabTransList[index]
	self:ChangeBtnImage(trans,true)
	self._tabIndex = index
	self:SaveWndArg()
	if(index == 1)then
		self:InitCultivate()
	elseif(index == 2)then
		self:RefreshResourceGet()
	elseif(index == 3)then
		self:RefreshRecommend()
	end
	local list=gModelGrow:GetGrowConfigRef()
	local titleName=ccLngText(list[self._tabIndex].name)
	self:SetWndText(self.mTitleText,titleName)


	--每次切换刷新
    self:RefreshAttrRestrain()
end

function UIGwWin:OnClickGetReward(taskRefId, rewardTrans)
	local netData = gModelQuest:GetTaskDataByRefId(taskRefId)
	if not netData then
		return
	end
	local state = netData:GetState()
	if state ==0 then
		GF.ShowMessage(ccClientText(17266))
	elseif state== 1 then
		gModelQuest:OnQuestReceiveReq(taskRefId)
		CS.ShowObject(rewardTrans, false)
	end
end

function UIGwWin:ResourceCellListItem(list,item, itemdata, itempos)--资源获取途径cell
	local nameText = self:FindWndTrans(item,"NameText")
	local desText = self:FindWndTrans(item,"DesText")
	local goOnBtn = self:FindWndTrans(item,"GoOnBtn")
	local goOnText = self:FindWndTrans(goOnBtn,"XUIText")
	self:SetWndText(nameText,ccLngText(itemdata.name))
	self:SetWndText(desText,ccLngText(itemdata.description))
	self:InitTextLineWithLanguage(desText, -50)
	self:InitTextSizeWithLanguage(desText, -2)
	self:SetWndText(goOnText,ccClientText(15112))
	self:SetWndClick(goOnBtn, function(...)
		if(gModelFunctionOpen:CheckIsOpened(itemdata.jump,true))then
			gModelFunctionOpen:Jump(itemdata.jump,self:GetWndName())
		end
	end)
end

function UIGwWin:HeroListItem(list,item, itemdata, itempos)--英雄头像列表cell
	self._heroTransList[itempos]=item
	local heroTrans = self:FindWndTrans(item,"Root/HeroIcon")
	local text = self:FindWndTrans(item,"NameText")
	local lvTxt = self:FindWndTrans(item,"LvTxt")
	local heroData={
		index=itempos,
		id=itemdata.id,
		refId=itemdata.refId,
		star=gModelGrow:GetTypeValue(ModelGrow.TYPE_STAR,itemdata.info),
		level=gModelGrow:GetTypeValue(ModelGrow.TYPE_LV,itemdata.info),
		isResonance = itemdata.isResonance,
		skin = itemdata.skin
	}
	local rankStr = ""
	local rankRef = gModelRank:GetRankingRefData(ModelRank.RANK_GROW)
	if(itemdata.rank <= 0 or itemdata.rank > rankRef.quantity)then
		rankStr = ccClientText(15111)
	else
		rankStr = string.replace(ccClientText(15115),itemdata.rank)
	end
	self:SetWndText(text,rankStr)
	local addLine = -30
	if gLGameLanguage:IsJapanRegion() then
		addLine = -50
		self:InitTextSizeWithLanguage(text, -2)
	end
	self:InitTextLineWithLanguage(text, addLine)
	local lv = gModelGrow:GetTypeValue(ModelGrow.TYPE_LV,itemdata.info)
	--local lvColor = "DDE1E1"
	if itemdata.isResonance == 1 then lvColor = "1bdef2" end
	--self:SetWndText(lvTxt,string.replace(ccClientText(15113),lvColor,lv))

	local InstanceID = item:GetInstanceID()
	self:SetHeroIcon(heroTrans, InstanceID, heroData)

	self:SetWndClick(heroTrans, function(...) self:OnClickHeroIcon(itempos) end)
end

function UIGwWin:OnTimer(key)
	if key == "time" then
		self:TimerStop("time")
		local list = self._resourceList:GetList()
		if(not list)then
			return
		end
		list:ScrollToIndex(self._resIndex)
	elseif key == "time2" then
		self:TimerStop("time")
		local list = self._recommendList:GetList()
		if(not list)then
			return
		end
		list:ScrollToIndex(self._jumpRecommendIndex)
	end
end

function UIGwWin:RecommendListItem(list,item, itemdata, itempos)--推荐阵容cell
	local InstanceID = item:GetInstanceID()
	self._recommendTransList[itempos]=item
	local nameText = self:FindWndTrans(item,"Info/NameText")
	local desText = self:FindWndTrans(item,"Image/DesText")
	local toggleBtn = self:FindWndTrans(item,"Info/ToggleBtn")
	local toggleText = self:FindWndTrans(toggleBtn,"XUIText")
	local previewBtn = self:FindWndTrans(item,"Image/GameObject/PreviewBtn")
	local previewText = self:FindWndTrans(previewBtn,"XUIText")
	local heroScroll = self:FindWndTrans(item,"Info/HeroScroll")
	local reward	=  self:FindWndTrans(item, "Info/Reward")
	local rewardNum = self:FindWndTrans(reward, "Num")
	local rewardRed = self:FindWndTrans(reward, "redPoint")

	local titleName = ccLngText(itemdata.name)
	local arr=string.split(itemdata.hero,",")
	local list={}
	for i, v in ipairs(arr) do
		local data={
			refId=tonumber(v),
			have = true,
		}
		table.insert(list,data)
	end

	local finishCond = itemdata.finishCond
	local taskData = gModelQuest:GetTaskDataByRefId(finishCond)
	if taskData then
		local schedule = tonumber(taskData:GetSchedule())
		local goal = tonumber(taskData:GetGoal())
		local state= taskData:GetState()
		local isGet = state == 2
		CS.ShowObject(reward, not isGet)
		CS.ShowObject(rewardRed, state == 1)
		if not isGet then
			if state == 0 then
				for k,v in ipairs(list) do
					list[k].have = gModelHeroBook:FindHeroInfoStatusByHeroRefId(v.refId)--gModelHero:CheckHaveHeroByRefId(v.refId)
				end
			end

			local rewards = gModelQuest:GetRewardList(finishCond)
			local curReward = rewards[1]
			if curReward then
				local icon = gModelItem:GetItemIconByRefId(curReward.itemId)
				self:SetWndEasyImage(reward, icon)
				self:SetWndText(rewardNum, curReward.itemNum)
			end

			if gLGameLanguage:IsJapanRegion() then
				if nil==curReward or  curReward.itemNum == 0  then
					CS.ShowObject(reward,false)
				end
			end

			self:SetWndClick(reward, function()
				self:OnClickGetReward(finishCond, reward)
			end)
		end

		local color = "red"
		if schedule>=goal then
			color = "green"
		end
		local str = LUtil.FormatColorStr(string.format("(%s/%s)",schedule,goal),color)
		titleName = titleName..str
	end


	local addLine = -30
	local addSize = -2
	if gLGameLanguage:IsVietnamVersion() or gLGameLanguage:IsThaiVersion() then
		addSize = -6
	end
	self:SetWndText(nameText,titleName)
	self:InitTextLineWithLanguage(nameText, addLine)
	self:InitTextSizeWithLanguage(nameText, addSize)

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
	local description = ccLngText(itemdata.description)
	description = LUtil.CreateHyperWithValue(desText,description,hyperCreateFun,function (data)
		gModelChat:ClickHyper(data,wndName)
	end)

	self:RefreshArrowShow(item,itempos,"RecommendListItem")

	self:SetWndText(desText,description)
	self:SetWndText(toggleText,ccClientText(15108))
	self:SetWndClick(toggleBtn, function(...)
		self:OnClickRecommendCell(itempos)
	end)
	self:SetWndText(previewText,ccClientText(15110))

	local itemRoot = self:FindWndTrans(heroScroll,"ItemRoot")
	--self:InitULayoutByLanguage(itemRoot,Vector4.New(5,0,20,0))

	local uiList = self:GetUIScroll(InstanceID)
	if(uiList:GetList())then
		uiList:RefreshData(list)
	else
		uiList:Create(heroScroll,list,function (...) self:RecommendHeroListItem(...) end)
	end

	self:SetWndClick(previewBtn, function(...)
		self:OnClickCombat(itemdata)
	end)
end

function UIGwWin:InitTabUI()
	CS.ShowObject(self.mDi, true)
	CS.ShowObject(self.mCultivate,false)
	CS.ShowObject(self.mResourceGet,false)
	CS.ShowObject(self.mRecommend,false)
end

function UIGwWin:InitMessage()
	self:WndNetMsgRecv(LProtoIds.StrengthResp,function (...)
		self:RefreshCultivate()
	end)
	self:WndNetMsgRecv(LProtoIds.StrengthOtherResp,function (...)
		self:RefreshVSData()
	end)
end

function UIGwWin:ResourceListItem(list,item, itemdata, itempos)--资源获取cell
	self._resourceTransList[itempos]=item
	local icon = self:FindWndTrans(item,"Info/Icon")
	local nameText = self:FindWndTrans(item,"Info/NameText")
	local desText = self:FindWndTrans(item,"Info/DesText")
	local toggleBtn = self:FindWndTrans(item,"Info/ToggleBtn")
	local toggleText = self:FindWndTrans(toggleBtn,"XUIText")
	if(itemdata.icon~="")then
		self:SetWndEasyImage(icon,itemdata.icon,function ()
			CS.ShowObject(icon,true)
		end)
	end
	self:RefreshArrowShow(item,itempos,"ResourceListItem")
	self:SetWndText(nameText,ccLngText(itemdata.name))
	self:SetWndText(desText,ccLngText(itemdata.description))
	self:SetWndText(toggleText,ccClientText(15108))
	self:SetWndClick(toggleBtn, function(...)
		self:OnClickResourceCell(itempos)
	end)
end

------------------------------------------------------------------
return UIGwWin


