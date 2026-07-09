---
--- Created by BY.
--- DateTime: 2023/10/16 17:06:42
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubMalCopy:LChildWnd
local UISubMalCopy = LxWndClass("UISubMalCopy", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubMalCopy:UISubMalCopy()
	self._timeKey = "UISubMalCopy"
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubMalCopy:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubMalCopy:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubMalCopy:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISubMalCopy:RefreshData()
	local _pages = self._pages
	local _pageId = self._turnBossEnum
	local page = _pages[_pageId]
	if not page then return end
	local activityDataS = gModelActivity:GetActivityBySid(self._sid)
	local moreInfoS = JSON.decode(activityDataS.moreInfo)
	local openDay = moreInfoS.openDay

	local list = page.entry
	local bossItem = self:GetOpenItem(list,openDay)
	local moreInfo = JSON.decode(bossItem.moreInfo)
	local buyChallengeNum = moreInfo.buyChallengeNum			--购买次数
	local myChallengeNum = moreInfo.myChallengeNum				--挑战次数
	self._bossItem = bossItem
	self._max_boss_hurt = moreInfo.max_boss_hurt or -1

	local entryCfg = bossItem.entryCfg
	local moreInfoW = entryCfg.moreInfo
	local show,showPos,showSize,bgImage,name,skill
	= entryCfg.show,entryCfg.showPos,entryCfg.showSize,entryCfg.bgImage,entryCfg.name,entryCfg.skill
	local challengeNum = entryCfg.challengeNum					--免费挑战上限

	local numStr = challengeNum - myChallengeNum + buyChallengeNum
	self:SetWndText(self.mNumText,string.replace(ccClientText(27610),numStr))
	if LxUiHelper.IsImgPathValid(bgImage) then
		CS.ShowObject(self.mBg,true)
		self:SetWndEasyImage(self.mBg,bgImage)
	end
	if not string.isempty(show) then
		local heroImageArr = string.split(show,"=")
		local type = heroImageArr[1]
		local heroImage = heroImageArr[2] or heroImageArr
		local parent
		if type == "1" or not heroImageArr[2] then
			parent = self.mHeroImg
			self:SetWndEasyImage(parent,heroImage,nil,true)
		else
			parent = self.mHeroSpine
			self:CreateWndSpine(parent,heroImage,heroImage,false)
		end
		parent.localScale = Vector2.New(showSize/10,showSize/10)
		CS.ShowObject(parent,true)
		if not string.isempty(showPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty(showPos)
			self:SetAnchorPos(parent, pos)
		end
	end
	if not string.isempty(name) then
		local prant = self.mBossText
		if LxUiHelper.IsImgPathValid(name) then
			prant = self.mBossNameImg
			self:SetWndEasyImage(prant,name,nil,true)
		else
			prant = self.mBossText
			self:SetWndText(prant,name)
		end
		CS.ShowObject(prant,true)
	end
	if not string.isempty(skill) then
		local skillArr = string.split(skill,",")
		local list = {}
		for i = 1, 4 do
			local skillId = skillArr[i]
			table.insert(list,{skill = skillId and tonumber(skillId) or 0})
		end

		local uiSkillList = self._uiSkillList
		if uiSkillList then
			uiSkillList:RefreshList(list)
		else
			uiSkillList = self:GetUIScroll("UISubMalCopy_mSkillScroll")
			self._uiSkillList = uiSkillList
			uiSkillList:Create(self.mSkillScroll,list,function(...) self:SkillListItem(...) end)
		end
	end
	if not string.isempty(moreInfoW) then
		local moreInfo = string.split(moreInfoW,"|")
		local itemList = LxDataHelper.ParseItem_3List(moreInfo[2])
		local _uiRwardList = self._uiRwardList
		if _uiRwardList then
			_uiRwardList:RefreshList(itemList)
			_uiRwardList:DrawAllItems()
		else
			_uiRwardList = self:GetUIScroll("UISubMalCopy_mRwardSuper")
			self._uiRwardList = _uiRwardList
			_uiRwardList:Create(self.mRwardSuper,itemList,function(...) self:AwardListItem(...) end,UIItemList.SUPER)
		end
	end
end
function UISubMalCopy:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	end
end
---------------------------------------------------------------------------------------------------------
function UISubMalCopy:SkillListItem(list, item, itemdata, itempos)
	local skillIcon = self:FindWndTrans(item,"SkillIcon")
	local skill = itemdata.skill
	CS.ShowObject(skillIcon,skill > 0)
	if skill > 0 then
		local ref = gModelHero:GetSkillByStarId(skill)
		self:SetWndEasyImage(skillIcon,ref.icon)
	end
	self:SetWndClick(item,function ()
		self:OnClickInformation()
	end)
end
function UISubMalCopy:OnClickChangle()
	local sid = self._sid
	local _bossItem = self._bossItem
	local moreInfo = JSON.decode(_bossItem.moreInfo)
	local entryCfg = _bossItem.entryCfg
	local buyChallengeNum = moreInfo.buyChallengeNum			--购买次数
	local myChallengeNum = moreInfo.myChallengeNum				--挑战次数
	local challengeNum = entryCfg.challengeNum					--免费挑战上限
	local num = challengeNum - myChallengeNum + buyChallengeNum
	if num <= 0 then
		local isGuy = self:GetIsBuyCard()
		if isGuy then
			GF.ShowMessage(ccClientText(27613))
		else
			GF.OpenWnd("UIActPrigeTipsBuyPop",{sid = sid})
		end
		return
	end
	local max_boss_hurt = self._max_boss_hurt or -1
	local _isSweep = self._isSweep
	if _isSweep  then
		if max_boss_hurt > 0 then
			if gModelActivity:GetBossSweepPopSignBySid(sid) then
				gModelActivity:OnActivitySpecialOpReq(sid,_bossItem.pageId,_bossItem.entryId,0,nil,self._turnBossSweepEnum)
			else
				GF.OpenWnd("UIMalCopySweepPop",{sid = sid,bossItem = _bossItem,pages = self._pages})
			end


		else
			GF.ShowMessage(ccClientText(27631))
		end
		--gModelActivity:OnActivitySpecialOpReq(self._sid,_bossItem.pageId,_bossItem.entryId,0,nil,self._turnBossSweepEnum)
		return
	end

	local mapRefId, monster, method, skill = tonumber(entryCfg.map),entryCfg.monster, entryCfg.method, entryCfg.skill
	local sid, pageId, entryId = self._sid,_bossItem.pageId, _bossItem.entryId
	local rewardBoxData = self:GetBossStrategyDataWhenFight(entryId)
	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_SWEETCOUNTRY_BOSS,{
		mapRefId = mapRefId,
		bossMonsterId = monster,
		method = method,
		skill = skill,
		sid = sid,
		pageId = pageId,
		entryId = entryId,
		bossRefId = entryId,
		rewardBoxData = rewardBoxData
	})
end

function UISubMalCopy:InitData()
	self._modelEnumList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = { ModelActivity.SWEET_COUNTRY_17, ModelActivity.SWEET_COUNTRY_18,ModelActivity.SWEET_COUNTRY_19 },
	}
	self._modelOpTypeList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = { ModelActivity.SWEETS_COUNTRY_SWEEP_BOSS, ModelActivity.BUY_BOSS_CHALLENGE_COUNT, }
	}

	self:SetWndText(self.mRwardText,ccClientText(27608))
	self:SetWndText(self.mInformationText,ccClientText(27609))
	self:SetWndText(self.mToggleText,ccClientText(27611))
	--self:SetWndButtonText(self.mBtnChangle,ccClientText(27612))
end
function UISubMalCopy:GetIsBuyCard()
	local pages = self._pages[self._turnPrivilegeEnum]
	local _cardList = pages.entry
	local _privilegeCard = _cardList[1]
	local marketData = _privilegeCard.MarketData
	local personal = marketData.personal
	local personalGoal = marketData.personalGoal
	local isGuy = personal >= personalGoal
	return isGuy
end
function UISubMalCopy:OnClickAddNum()
	local _bossItem = self._bossItem
	local moreInfo = JSON.decode(_bossItem.moreInfo)
	local buyChallengeNum = moreInfo.buyChallengeNum			--购买次数
	local _buyTimeLimit = self._buyTimeLimit					--购买上限
	local _candyCardbuyTimeTxt = self._candyCardbuyTimeTxt
	local isCard = self:GetIsBuyCard()
	if isCard then
		_buyTimeLimit = _buyTimeLimit + _candyCardbuyTimeTxt
	end
	local num = 1
	if buyChallengeNum + num > _buyTimeLimit then
		GF.ShowMessage(ccClientText(27614))
		return
	end
	GF.OpenWnd("UIMalCopyBuyNumPop",{sid = self._sid,bossItem = _bossItem,pages = self._pages})
	--gModelActivity:OnActivitySpecialOpReq(self._sid,_bossItem.pageId,_bossItem.entryId,0,tostring(num),self._turnBossCountEnum)
end
function UISubMalCopy:SetTime()
	local _timeKey = self._timeKey
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local endTime = activityData.endTime
	if endTime <= 0 then
		self:TimerStop(_timeKey)
		self:SetWndText(self.mTimeText,ccClientText(18404))
		CS.ShowObject(self.mTimeBg,true)
		return
	end
	local time = GetTimestamp()
	local timespan = endTime - time
	local  timeStr = ""
	if(timespan < 0)then
		timeStr = ccClientText(14301)
		self:TimerStop(_timeKey)
	else
		local timeF = ccClientText(27607)
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(timeF,timeStr)
	end
	self:SetWndText(self.mTimeText,timeStr)
	CS.ShowObject(self.mTimeBg,true)
end
-------------------------------------------------获取数据------------------------------------------------
function UISubMalCopy:GetOpenItem(list,day)
	local item
	for i, v in ipairs(list) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		local moreInfo = string.split(entryCfg.moreInfo,"|")
		local _dayArr = string.split(moreInfo[1],",")
		local _day = tonumber(_dayArr[1])
		if _day <= day then
			item = v
			item.entryCfg = entryCfg
		end
	end
	return item
end
-------------------------------------------------点击事件------------------------------------------------

-------------------------------------------------倒计时--------------------------------------------------
function UISubMalCopy:RefreshTime()
	local _timeKey = self._timeKey
	local activityDatas = gModelActivity:GetActivityBySid(self._sid)
	local _endTime = activityDatas.endTime
	if(_endTime and _endTime > 0)then
		self:TimerStop(_timeKey)
		self:TimerStart(_timeKey,1,false,-1)
		self:SetTime()
	end
end
-------------------------------------------------获取数据------------------------------------------------

-------------------------------------------------点击事件------------------------------------------------
function UISubMalCopy:OnClickInformation()
	local _bossItem = self._bossItem
	GF.OpenWnd("UIMalCopySowPop",{boss = _bossItem})
end
function UISubMalCopy:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	--self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
	--	if sid ~= self._sid then return end
	--	self:OnActivityConfigData()
	--end)
	self:SetWndToggleDelegate(self.mToggle,function (value)
		self:SetWndButtonText(self.mBtnChangle,value and ccClientText(27632) or ccClientText(27612))
		gModelActivity:SetActivityBossSweepBySid(self._sid,value)
		self._isSweep = value
	end)
end
function UISubMalCopy:AwardListItem(list, item, itemdata, itempos)
	local root = CS.FindTrans(item,"Root/Icon")
	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
		self:SetIconClickScale(root, true)
	end
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	self:SetWndClick(root,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
	baseClass:DoApply()
end
function UISubMalCopy:InitEvent()
	self:SetWndClick(self.mBtnAddNum,function () self:OnClickAddNum() end)
	self:SetWndClick(self.mBtnChangle,function () self:OnClickChangle() end)
	self:SetWndClick(self.mBtnInformation,function () self:OnClickInformation() end)
end
function UISubMalCopy:GetBossStrategyDataWhenFight(entryId)
	local _turnBossRwardEnum = self._turnBossRwardEnum
	local _page = self._pages[_turnBossRwardEnum]
	local dataList = _page.entry
	local _bossItem = self._bossItem

	local data ={}
	for k,v in ipairs(dataList) do
		local status = v.goalData.status
		if status == 0 then --未完成
			local _entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
			if _entryCfg then
				local moreInfo = string.split(_entryCfg.moreInfo,"=")
				if tonumber(moreInfo[1]) == _bossItem.entryId then
					--local condition = string.split(_entryCfg.condition, '=')
					local info = {
						--entryId = v.entryId,	--序号
						--pageId   = v.pageId,	--条目id
						--status  = status,	--完成状态
						goal 	= tonumber(moreInfo[2]),
						--sort	 = _entryCfg.sort,		--排序
						--bossRefId = entryId,
					}
					table.insert(data, info)
				end
			end
		end
	end

	table.sort(data, function(a, b)
		return a.goal < b.goal
	end)

	return data
end
function UISubMalCopy:InitCommand()
	local sid = self:GetWndArg("sid")
	self._sid = sid
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._modelId = modelId

	local enums = self._modelEnumList[modelId]
	self._turnBossEnum = enums[1]
	self._turnBossRwardEnum = enums[2]
	self._turnPrivilegeEnum = enums[3]
	local opTypes = self._modelOpTypeList[modelId]
	self._turnBossSweepEnum = opTypes[1]
	self._turnBossCountEnum = opTypes[2]

	local _isSweep = gModelActivity:GetActivityBossSweepBySid(sid)
	self._isSweep = _isSweep
	self:SetWndToggleValue(self.mToggle, _isSweep)
	self:SetWndButtonText(self.mBtnChangle,_isSweep and ccClientText(27632) or ccClientText(27612))

	self:OnActivityConfigData()
	self:RefreshTime()
end
function UISubMalCopy:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = page.pageId
		_pages[pageId] = page
	end
	self._pages = _pages
	self:RefreshData()
end

function UISubMalCopy:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config

	self._buyTimeLimit = data.buyTimeLimit
	self._candyCardbuyTimeTxt = data.candyCardbuyTimeTxt
	local payTimeCost = data.payTimeCost
	if not string.isempty(payTimeCost) then
		self._payTimeCost = LxDataHelper.ParseItem_3(payTimeCost)
	end

	local enums = self._modelEnumList[self._modelId]
	gModelActivity:OnActivityPageReq(self._sid,enums)
end
-------------------------------------------------倒计时--------------------------------------------------
------------------------------------------------------------------
return UISubMalCopy


