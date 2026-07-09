---
--- Created by BY.
--- DateTime: 2023/10/7 17:20:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActRkTopThreePop:LWnd
local UIActRkTopThreePop = LxWndClass("UIActRkTopThreePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActRkTopThreePop:UIActRkTopThreePop()
	self._timeKey = "UIActRkTopThreePop_timeKey"
	self._uiheadList = {}
	self._uiHeroIconClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActRkTopThreePop:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	self:ClearCommonIconList(self._uiHeroIconClsList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActRkTopThreePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActRkTopThreePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitCommand()
end

function UIActRkTopThreePop:InitData()
	self:SetWndButtonText(self.mBtnRank,ccClientText(27636))
	self:CreateWndEffect(self.mRankEff,"fx_ui_bisaijieguo_01","UIActRkTopThreePop",100)
end
--设置英雄头像
function UIActRkTopThreePop:SetHeroIcon(heroIcon,heroInfo,playerId)
	local heroData={
		id=heroInfo.id,
		refId=heroInfo.refId,
		star=heroInfo.star,
		level=heroInfo.lv,
		skin = heroInfo.skin,
		isResonance = heroInfo.isResonance,
	}
	local instanceId = heroIcon:GetInstanceID()
	local uicommonlist = self._uiHeroIconClsList
	local baseClass = uicommonlist[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		uicommonlist[heroInfo.id] = baseClass
		baseClass:Create(heroIcon)
		self:SetIconClickScale(heroIcon, true)
	end
	baseClass:SetHeroDataSet(heroData)
	baseClass:DoApply()

	heroInfo.level = heroInfo.lv
	heroInfo.skin = heroInfo.skin,
	self:SetWndClick(heroIcon, function (...)
		gModelHero:ReqShowHeroTip(playerId,heroInfo)
	end)
end
function UIActRkTopThreePop:InitEvent()
	self:SetWndClick(self.mBg,function (...)self:WndClose() end)
	self:SetWndClick(self.mBtnRank,function (...)self:OnClickRank() end)

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
end

--设置玩家头像
function UIActRkTopThreePop:SetHeadIcon(item,info,bool)
	local iconBg = self:FindWndTrans(item, "IconBg")
	local headIcon = self:FindWndTrans(item, "HeadIcon")
	CS.ShowObject(iconBg,true)
	CS.ShowObject(headIcon,false)
	if(not info or bool or (info._playerId and info._playerId == 0))then
		return
	end
	CS.ShowObject(iconBg,false)
	CS.ShowObject(headIcon,true)
	local InstanceID = item:GetInstanceID()

	local playerInfo={
		trans = headIcon,
		playerId = info._playerId,
		icon = info._head,
		headFrame = info._headFrame,
		level = info._grade,
	}
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)
	self:SetWndClick(headIcon, function (...)
		self:OnClickPlayer(info)
	end)
end
function UIActRkTopThreePop:InitServerRank(item,info,isThree)--isThree=1前面3，=2列表，=3自

	local bgImage1 = self:FindWndTrans(item,"BgImage3")
	local groupBg = self:FindWndTrans(item,"Group/GroupBg")
	local serverText = self:FindWndTrans(item,"Group/ServerText")
	local nameText = self:FindWndTrans(item,"Group/NameText")
	local bgImg1 = self:FindWndTrans(item,"Group/Bg/BgImg1")
	local icon = self:FindWndTrans(item,"Group/Bg/Icon")
	local valueText1 = self:FindWndTrans(item,"Group/Bg/valueText1")

	CS.ShowObject(bgImage1,true)
	CS.ShowObject(groupBg,true)
	if not info then return end
	CS.ShowObject(serverText,info.serverName)
	CS.ShowObject(nameText,not info.score)
	CS.ShowObject(bgImg1,info.score)
	CS.ShowObject(icon,false)

	if info.score then
		local score = LUtil.NumberCoversion(info.score)
		self:SetWndText(valueText1,score)
		local serverStr = LUtil.FormatColorStr(info.serverName,"lightGreen")
		self:SetWndText(serverText,serverStr)
	end

end

function UIActRkTopThreePop:InitRank(item,itemdata,position)
	self:InitRankItem(item,itemdata,1)
end
--设置立绘
function UIActRkTopThreePop:SetHeroPaint(paintTans,info,index)--index = 1 文件形象， = 2 英雄形象
	if(info and index == 1)then
		local ref=gModelPlayer:GetRoleAdventureImage(info._figure)
		local key = info._playerId
		if(not ref)then
			return
		end
		self:SetSpine(paintTans,ref,key)
	elseif(info and index==2)then
		local refId = info.refId
		local starLv = info.star
		local key = info.id
		local ref
		if(info.skin > 0)then
			ref=gModelHero:GetShowEffectById(info.skin)
			ref=gModelPlayer:GetRoleAdventureImage(ref.rankingId)
		else
			ref=gModelHero:GetHeroShowRefByRefId(refId,starLv)
			ref=gModelPlayer:GetRoleAdventureImage(ref.rankingId)
		end
		if(not ref)then
			return
		end
		self:SetSpine(paintTans,ref,key)
	end
end

function UIActRkTopThreePop:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	end
end
--设置形象
function UIActRkTopThreePop:SetSpine(paintTans,ref,key)
	local paintFlip=ref.paintFlip2==1
	local paintMultiple=ref.paintMultiple2
	self:CreateWndSpine(paintTans,ref.spine,key,false,function(dpSpine)
		dpSpine:SetScale(paintMultiple)
		dpSpine:SetFlipX(paintFlip)
		local dpTrans =dpSpine:GetDisplayTrans()
		dpTrans.anchorMin = Vector2.New(0.5,0.5)
		dpTrans.anchorMax = Vector2.New(0.5,0.5)
	end)
end

function UIActRkTopThreePop:OnActivityConfigData()
	self._isWeb = true
end
function UIActRkTopThreePop:SetTime()
	CS.ShowObject(self.mInfoPop,true)
	local info = self._info
	local infos = info.infos
	for i = 1, 3 do
		local item = self:FindWndTrans(self.mRankMag,"Rank"..i)
		local _info = infos[i]
		self:InitRank(item,_info,i)
	end
end
function UIActRkTopThreePop:InitCommand()
	local info = self:GetWndArg("info")		--StructActivityRankSettlement
	self._info = info
	self._sid = info.sid
	local rankType = info.rankType
	self._rankType = rankType
	local rankRef = gModelRank:GetRankingRefData(rankType)
	self:SetWndText(self.mTitleText,ccLngText(rankRef.nameTitle))

	gModelActivity:ReqActivityConfigData(info.sid)
	self:TimerStart(self._timeKey,0.5,false,1)
end
-----------------------------------------------------------------------------------------------
function UIActRkTopThreePop:InitRankItem(item,info,isThree)--isThree=1前面3，=2列表，=3自
	local image = self:FindWndTrans(item,"Image")
	local bgImage1 = self:FindWndTrans(item,"BgImage1")
	local bgImage2 = self:FindWndTrans(item,"BgImage2")
	local flagBg = self:FindWndTrans(item,"FlagBg")
	local flagIcon = self:FindWndTrans(item,"FlagBg/FlagIcon")
	local guildLvText = self:FindWndTrans(item,"FlagBg/GuildLvBg/GuildLvText")
	local mask = self:FindWndTrans(item,"Mask")
	local iconBg = self:FindWndTrans(item,"IconBg")
	local rankIcon = self:FindWndTrans(item,"RankIcon")
	local group = self:FindWndTrans(item,"Group")
	local groupBg = self:FindWndTrans(group,"GroupBg")
	local bg = self:FindWndTrans(item,"Group/Bg")
	local bg2 = self:FindWndTrans(item,"Group/Bg2")
	local bg3 = self:FindWndTrans(item,"Group/Bg3")
	local bgImg1 = self:FindWndTrans(bg, "BgImg1")
	local bgImg2 = self:FindWndTrans(bg, "BgImg2")
	local serverText = self:FindWndTrans(item,"Group/ServerText")
	local nameText = self:FindWndTrans(item,"Group/NameText")
	local guildNameText = self:FindWndTrans(item,"Group/GuildNameText")
	local memberText = self:FindWndTrans(item,"Group/MemberText")
	local rankText = self:FindWndTrans(item,"RankText")
	local heroIcon = self:FindWndTrans(item,"Root/HeroIcon")
	local iconImg = self:FindWndTrans(bg,"Icon")
	local desIcon = self:FindWndTrans(bg,"DesIcon")
	local valueText1 = self:FindWndTrans(bg,"valueText1")
	local valueText2 = self:FindWndTrans(bg,"valueText2")
	local lookBtn = self:FindWndTrans(bg,"LookBtn")
	local likeBG = self:FindWndTrans(item,"Group/LinkBg")
	local like 	 = self:FindWndTrans(likeBG,"like")
	local likeText = self:FindWndTrans(like,"layout/text")
	local rankImg =  self:FindWndTrans(item,"RankImg")
	local homeBtn = self:FindWndTrans(bg3,"HomeBtn")
	local valueHot = self:FindWndTrans(bg3,"valueHot")
	local formationBtn = self:FindWndTrans(bg, "FormationBtn")


	self:SetWndText(nameText,ccClientText(11711))
	self:SetWndText(guildNameText,"")
	self:SetWndText(memberText,"")
	CS.ShowObject(nameText,true)
	CS.ShowObject(bgImg1, false)
	CS.ShowObject(bgImg2, false)
	CS.ShowObject(iconImg, false)
	CS.ShowObject(desIcon, false)
	CS.ShowObject(serverText, false)
	CS.ShowObject(memberText,false)
	CS.ShowObject(lookBtn, false)
	CS.ShowObject(bg,true)
	CS.ShowObject(heroIcon,false)
	CS.ShowObject(likeBG,false)
	CS.ShowObject(valueText1, true)
	CS.ShowObject(valueText2, false)
	CS.ShowObject(group,true)
	CS.ShowObject(rankIcon,true)
	CS.ShowObject(bg2, false)
	CS.ShowObject(bg3, false)
	CS.ShowObject(rankImg,false)
	CS.ShowObject(formationBtn, false)

	self:SetWndText(valueText1, "")

	local isShowLike = false
	local _rankRefId = self._rankType
	local _rankRef = gModelRank:GetRankingRefData(_rankRefId)
	local isGuildRank = _rankRef.showType == 1
	local isServerType = _rankRef.showType == 2
	if isServerType then
		self:InitServerRank(item,info,isThree)
		return
	end
	CS.ShowObject(bgImage1,not isGuildRank)
	CS.ShowObject(bgImage2,isGuildRank)
	CS.ShowObject(flagBg,false)
	CS.ShowObject(mask,not isGuildRank)
	CS.ShowObject(groupBg,not isGuildRank)

	if not info then return end
	if(isThree ~= 1)then
		local headIcon = self:FindWndTrans(item, "HeadIcon")
		CS.ShowObject(headIcon,not isGuildRank)
		if not isGuildRank then
			self:SetHeadIcon(item,info.info,not info.score)
		end
		local rankStr = ccClientText(11708)
		if(isThree==2)then
			rankStr = string.replace(ccClientText(11725), info.index)
		end
		self:SetWndText(rankText,rankStr)
	end
	self:SetWndClick(item, function (...) end)
	if image then
		self:SetWndClick(image, function (...) end)
	end

	if(not info.score )then
		return
	end
	local playerInfo = info.info
	if(not playerInfo or playerInfo._playerId == 0)then
		return
	end

	local playerId = playerInfo._playerId


	local nameStr =  playerInfo._name
	local serverName
	local serverStr = ""
	local showServerNameRankList = {
		ModelRank.RANK_TYPE_CROSSSERVER,
		ModelRank.RANK_MELEE,
		ModelRank.RANK_INTEGRAL
	}

	if showServerNameRankList[_rankRef.type] or _rankRef.rankSerNameShow == 1 then
		serverName = gModelFriend:GetSevenName(playerInfo._serverId)
		serverStr = string.replace(ccClientText(11730),serverName)
		serverStr = LUtil.FormatColorStr(serverStr,"green")
		self:SetWndText(serverText, serverStr)
		CS.ShowObject(serverText, true)
	end
	local guildNameStr = playerInfo._guildName
	local meleeInfo = info.guildMeleeRankInfo
	local _descriptionDetail = ccLngText(_rankRef.descriptionDetail)

	if isGuildRank  then
		CS.ShowObject(flagBg,isGuildRank)
		CS.ShowObject(iconBg,false)
		local bgRef = gModelGuild:GetGuildFlagRefByRefId(info.flagBgId)
		local iconRef = gModelGuild:GetGuildFlagRefByRefId(info.flagId)
		if bgRef then
			self:SetWndEasyImage(flagBg,bgRef.res)
		end
		if iconRef then
			self:SetWndEasyImage(flagIcon,iconRef.res)
		end
		self:SetWndText(guildLvText,info.guildLevel)
	end

	local showLink = false
	if _rankRefId == ModelRank.RANK_TYPE_SERVERLUCK then
		local callInfo = info.callInfo
		if callInfo.extraReward and #callInfo.extraReward > 0 then
			CS.ShowObject(bgImg2,true)
			self:SetWndText(valueText1,info.score)
			CS.ShowObject(lookBtn, true)
			self:SetWndClick(lookBtn,function ()
				self:OnClickLook(playerInfo._name,callInfo)
			end)
		end
	elseif _rankRef.showPower == 1 then
		CS.ShowObject(bgImg1,true)
		CS.ShowObject(iconImg, true)
		self:SetWndText(valueText1,LUtil.PowerNumberCoversion(info.score))
	elseif(_rankRefId == ModelRank.RANK_GUILDBBRAVE or _rankRefId == ModelRank.RANK_1600 or _rankRefId == ModelRank.RANK_1601) then
		CS.ShowObject(bgImg2,true)
		CS.ShowObject(desIcon, true)
		CS.ShowObject(valueText1,false)
		CS.ShowObject(valueText2,true)
		self:SetWndText(valueText2,LUtil.NumberCoversion(info.score))
		guildNameStr = ""
	elseif _rankRefId == ModelRank.RANK_ONE_NIGHT then
		CS.ShowObject(bg, false)
		CS.ShowObject(bg2, false)
		CS.ShowObject(bg3, true)
		if isThree == 1 then
			CS.ShowObject(bg, true)
			CS.ShowObject(bgImg1, true)
			valueHot = valueText1
			homeBtn = self:FindWndTrans(bg, "HomeBtn")
		end
		self:SetWndText(valueHot, info.score)
		if playerInfo._playerId == gModelPlayer:GetPlayerId() and isThree == 3 then
			CS.ShowObject(homeBtn, false)
		else
			CS.ShowObject(homeBtn, true)
			self:SetWndClick(homeBtn,function ()
				GF.OpenWndWait("UIOneNightSpaceOpenEffect", {type = 1, targetId = playerInfo._playerId})
				self:WndClose()
			end)
		end
	elseif (_rankRefId >= ModelRank.RANK_FAIRYLAND_BOSS_BEGIN and _rankRefId <= ModelRank.RANK_FAIRYLAND_BOSS_END) then
		if not isGuildRank then
			guildNameStr = ""
		end
		CS.ShowObject(bgImg2,true)
		CS.ShowObject(desIcon, true)
		CS.ShowObject(valueText1, false)--isBossRankSelf)
		CS.ShowObject(valueText2, true)--not isBossRankSelf)
		self:SetWndText(valueText2,LUtil.NumberCoversion(math.max(info.score, 0)))
	elseif _rankRefId == ModelRank.RANK_INVASION then
		CS.ShowObject(bgImg2,true)
		CS.ShowObject(desIcon, true)
		self:SetWndText(valueText2,LUtil.NumberCoversion(info.score))
		CS.ShowObject(valueText1,false)
		CS.ShowObject(valueText2,true)
		guildNameStr = ""
	elseif (_rankRefId == ModelRank.RANK_MELEE or _rankRefId == ModelRank.RANK_INTEGRAL) and meleeInfo then
		local power = ""
		if(_rankRefId == ModelRank.RANK_MELEE)then
			nameStr      = guildNameStr
			guildNameStr = string.replace(_descriptionDetail, meleeInfo.num)
			power = meleeInfo.power
		else
			guildNameStr = string.replace(_descriptionDetail, info.score)
			power = meleeInfo.power --info.info._figure
		end

		CS.ShowObject(bgImg1,true)
		CS.ShowObject(iconImg,true)
		self:SetWndText(valueText1,LUtil.PowerNumberCoversion(power))
	elseif _rankRefId == ModelRank.RANK_1800 or _rankRefId == ModelRank.RANK_1802 then
		CS.ShowObject(bgImg2,true)
		self:SetWndText(valueText1,string.replace(_descriptionDetail,info.score))
	elseif _rankRefId == ModelRank.RANK_2200 then
		CS.ShowObject(bgImg2,true)
		CS.ShowObject(formationBtn, true)
		local towerdefenceMissionCfg = GameTable.TowerDefenceMissionRef[info.score]
		self:SetWndText(valueText1, string.replace(_descriptionDetail,towerdefenceMissionCfg and tostring(towerdefenceMissionCfg.sort) or "0"))
		local selfPlayerId = gModelPlayer:GetPlayerId()
		if selfPlayerId ~= playerInfo._playerId then
			self:SetWndClick(formationBtn,function ()
				self:OnClickFormation(playerInfo._playerId)
			end)
		end
	elseif(info.score > 0)then
		CS.ShowObject(bgImg2,true)
		local desStr = info.score
		if _rankRef.detailsRef ~= "" then
			local ref = GameTable[_rankRef.detailsRef]
			local itemRef = ref[desStr]
			local detailsFields = string.split(_rankRef.detailsFields,"=")
			desStr = itemRef[detailsFields[1]]
			if detailsFields[2] == "1" then
				desStr = ccLngText(desStr)
			end
		else
			desStr = LUtil.NumberCoversion(info.score)
		end

		local valueText = valueText1
		if gLGameLanguage:IsForeignRegion() and _rankRefId == ModelRank.RANK_TYPE_ADVENTURE then
			valueText = self:FindWndTrans(item,"EnglishText")
			CS.ShowObject(bgImg2,false)
		end
		self:SetWndText(valueText,string.replace(_descriptionDetail,desStr))
	end
	CS.ShowObject(nameText,true)
	if isGuildRank then
		local str = ""
		if(info.guildLevel>0)then
			local s = ccClientText(11721)
			str = string.replace(s,info.guildCount,gModelGuild:GetGuildNumByLv(info.guildLevel))
		end

		CS.ShowObject(memberText,true)
		if str == "" and guildNameStr ~= "" then
			str = guildNameStr
		end
		if _rankRefId == ModelRank.RANK_MELEE then
			str = guildNameStr
		end
		self:SetWndText(memberText,str)

		if isThree ~= 1 then

			self:SetWndText(serverText,guildNameStr)
			if _rankRefId == ModelRank.RANK_MELEE then
				self:SetWndText(serverText,nameStr)
			end
			if serverName then
				CS.ShowObject(serverText, false)
				nameStr = string.replace(ccClientText(11730),serverName)
			else
				nameStr = string.replace(ccClientText(11732),nameStr)
			end
			CS.ShowObject(nameText,false)
			CS.ShowObject(serverText,true)
			guildNameStr = nameStr
		else
			if _rankRefId == ModelRank.RANK_CROSS_GUILD then
				self:SetWndText(serverText,guildNameStr)
				nameStr = string.replace(ccClientText(11730),serverName)
			elseif _rankRefId == ModelRank.RANK_MELEE then
				self:SetWndText(serverText,nameStr)
				nameStr = string.replace(ccClientText(11730),serverName)
			else
				CS.ShowObject(guildNameText,false)
				CS.ShowObject(serverText, true)
				self:SetWndText(serverText,guildNameStr)
				nameStr = string.replace(ccClientText(11732),nameStr)
			end
		end
	end

	CS.ShowObject(likeBG,showLink)
	local needServerInNameEnd = showLink and isThree ~= 1 and not isGuildRank
	if needServerInNameEnd then
		nameStr = nameStr..serverStr
		CS.ShowObject(serverText, false)
	end

	self:SetWndText(nameText,nameStr)
	self:SetWndText(guildNameText,guildNameStr)

	local playIcon = self:FindWndTrans(item,"Mask/PlayIcon")

	self:SetHeroPaint(playIcon,info.info,1)
end

function UIActRkTopThreePop:OnClickRank()
	if not self._isWeb then
		self:WndClose()
		return
	end
	local _info = self._info
	local sid = _info.sid
	local pageId = _info.pageId or 0
	local rankType = _info.rankType
	local _rewardList = nil
	if pageId and pageId > 0 then
		local page = gModelActivity:GetWebActivityPageData(sid,pageId)
		local list = LxDataHelper.SevenEntryConditionRewardList(sid,page.entries)
		if #list > 0 then
			_rewardList = list
		end
	end
	GF.OpenWndBottom("UIRkPop",{refId = rankType,sid = sid,rewardList = _rewardList})
	self:WndClose()
end
------------------------------------------------------------------
return UIActRkTopThreePop


