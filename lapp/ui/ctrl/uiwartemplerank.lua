---
--- Created by wzz.
--- DateTime: 2024/5/13 16:59:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWarTempleRank:LWnd
local UIWarTempleRank = LxWndClass("UIWarTempleRank", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWarTempleRank:UIWarTempleRank()
	local ref = GameTable.LeaderboardingRef[gModelRank.RANK_WARTEMPLE]
	local pageSize = ref.quantity -- 数量过多，再优化
	gModelRank:OnRankReq(2, gModelRank.RANK_WARTEMPLE, 1, pageSize)
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWarTempleRank:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWarTempleRank:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWarTempleRank:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitEvents()

	self:Refresh()
end

--设置英雄头像
function UIWarTempleRank:SetHeroIcon(heroIcon, heroInfo, playerId)
	local heroData = {
		id = heroInfo.id,
		refId = heroInfo.refId,
		star = heroInfo.star,
		level = heroInfo.lv,
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
		self:SetWndClick(heroIcon, function(...)
			gModelHero:ReqShowHeroTip(playerId, heroInfo)
		end)
end

-- 初始界面化文本
function UIWarTempleRank:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(42050))
	self:SetWndText(self.mCloseTip, ccClientText(10103))
end

-- 绘制列表item
function UIWarTempleRank:OnDrawListItem(list, item, itemData, itemPos, isSelf)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			empty         = CS.FindTrans(item, "AniRoot/Empty"),
			had           = CS.FindTrans(item, "AniRoot/Had"),
			headIcon      = CS.FindTrans(item, "AniRoot/HeadIcon"),
			name          = CS.FindTrans(item, "AniRoot/Had/Name"),
			txtGuild      = CS.FindTrans(item, "AniRoot/Had/TxtGuild"),
			txtPalace     = CS.FindTrans(item, "AniRoot/Had/TxtPlace"),
			txtPalaceRank = CS.FindTrans(item, "AniRoot/Had/TxtPlaceRank"),
			txtRank       = CS.FindTrans(item, "AniRoot/Img0/TxtRank"),
		}
		if isSelf then
			itemCache.imgRank1   = CS.FindTrans(item, "AniRoot/ImgRank1")
			itemCache.imgRank2   = CS.FindTrans(item, "AniRoot/ImgRank2")
			itemCache.imgRank3   = CS.FindTrans(item, "AniRoot/ImgRank3")
			itemCache.myRankTips = CS.FindTrans(item, "AniRoot/MyRankTips")

			self:SetTextTile(itemCache.myRankTips, ccClientText(42051))
		end
		self:SetTextTile(itemCache.empty, ccClientText(42053))

		itemCache.headIconClass = HeadIcon:New(self)
		self:SetComponentCache(instanceID, itemCache)
	end

	CS.ShowObject(itemCache.empty, itemData == false)
	CS.ShowObject(itemCache.had, itemData ~= false)

	local headData = {
		roleId = 0,
		trans = itemCache.headIcon,
	}

	local rank = itemPos + 3

	local strRank = rank
	local npcId, strName, palaceName, palaceRank
	if isSelf then
		npcId, strName, palaceName, palaceRank = gModelWarTemple:GetNpcIdByRank(itemData.rank)
	else
		npcId, strName, palaceName, palaceRank = gModelWarTemple:GetNpcIdByRank(rank)
	end
	if itemData then
		local info = itemData.info:GetServerData()
		self:SetWndText(itemCache.txtGuild, info.guildName)

		local playerId = tonumber(info.playerId) or 0
		headData.roleId = playerId
		if playerId == 0 then
			local hoerRefId = gModelWarTemple:GetShowHeroRefId(npcId)
			headData.icon = gModelWarTemple:GetHeroHeadByRefId(hoerRefId)
		else
			strName = itemData.info:GetName()
			headData.icon = info.head
		end

		self:SetWndText(itemCache.name, strName)
	end
	itemCache.headIconClass:SetHeadData(headData)
	self:SetWndClick(headData.trans, function(...)
		self:OnClickPlayer(headData.roleId)
	end)

	palaceRank = ccClientText(42052, palaceRank)
	if isSelf then
		if itemData then
			local rank = itemData.rank
			CS.ShowObject(itemCache.imgRank1, rank == 1)
			CS.ShowObject(itemCache.imgRank2, rank == 2)
			CS.ShowObject(itemCache.imgRank3, rank == 3)

			if rank <= 0 then
				strRank = ccClientText(42054)
				palaceRank = strRank
			else
				strRank = rank
			end
		end
	end

	self:SetWndText(itemCache.txtRank, strRank)
	self:SetWndText(itemCache.txtName, strName)
	self:SetWndText(itemCache.txtPalace, palaceName)
	self:SetWndText(itemCache.txtPalaceRank, palaceRank)
end

--设置形象
function UIWarTempleRank:SetSpine(paintTans, ref, key)
	local paintFlip = ref.paintFlip2 == 1
	local paintMultiple = ref.paintMultiple2
	local offset = LxDataHelper.ParseVector2(ref.paintPaint2, ',')
	self:CreateWndSpine(paintTans, ref.spine, key, false, function(dpSpine)
		dpSpine:SetScale(paintMultiple)
		dpSpine:SetFlipX(paintFlip)
		local dpTrans = dpSpine:GetDisplayTrans()
		if dpTrans then
			dpTrans.anchorMin = Vector2.New(0.5, 0.5)
			dpTrans.anchorMax = Vector2.New(0.5, 0.5)
			dpTrans.localPosition = offset
		end
	end)
end

-- 绘制前三item
function UIWarTempleRank:DrawTopThree(item, data, rank)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			had           = CS.FindTrans(item, "Had"),
			empty         = CS.FindTrans(item, "Empty"),
			playIcon      = CS.FindTrans(item, "Had/Mask/PlayIcon"),
			txtPalace     = CS.FindTrans(item, "Had/0/TxtPalace"),
			txtPalaceRank = CS.FindTrans(item, "Had/1/TxtPalaceRank"),
			txtName       = CS.FindTrans(item, "Had/TxtName"),
		}
		self:SetComponentCache(instanceID, itemCache)
		self:SetTextTile(itemCache.txtName, "")
	end

	CS.ShowObject(itemCache.empty, data == nil)
	CS.ShowObject(itemCache.had, data ~= nil)
	if not data then
		return
	end
	local info = data.info:GetServerData()

	local heroData = { key = instanceID }
	local playerId = tonumber(info.playerId) or 0
	local npcId, strName, palaceName = gModelWarTemple:GetNpcIdByRank(rank)
	if playerId == 0 then
		heroData.refId = gModelWarTemple:GetShowHeroRefId(npcId)
	else
		heroData.refId = data.hero.refId
		heroData.star = data.hero.star
		heroData.figure = info.figure
		strName = data.info:GetName()
	end
	self:SetWndText(itemCache.txtName, strName)
	self:SetWndText(itemCache.txtPalace, palaceName)
	self:SetWndText(itemCache.txtPalaceRank, ccClientText(42052, rank))

	self:SetHeroPaint(itemCache.playIcon, heroData, 2)

	self:SetWndClick(item, function(...)
		self:OnClickPlayer(playerId)
	end)
end

-- 初始事件
function UIWarTempleRank:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:WndEventRecv(EventNames.RANK_UPDATE_END, function(...) self:OnRankUpdate(...) end)
end

-- 刷新界面
function UIWarTempleRank:Refresh()
	local rankInfos = gModelRank:GetRankListInfo(2, gModelRank.RANK_WARTEMPLE)
	for i = 1, 3 do
		local rankInfo = rankInfos[i]
		self:DrawTopThree(self["mRank" .. i], rankInfo, i)
	end

	local dataList = {}
	if #rankInfos <= 6 then
		for i = 4, 6 do
			table.insert(dataList, rankInfos[i] or false)
		end
	else
		for i = 4, #rankInfos do
			table.insert(dataList, rankInfos[i])
		end
	end

	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList

		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList:RefreshList(dataList)
		self._uiList:DrawAllItems()
	end

	local info = gModelRank:GetMeRank()
	self:OnDrawListItem(nil, self.mMyItem, info, 0, true)
end

-- 点击头像
function UIWarTempleRank:OnClickPlayer(playerId)
	if playerId == 0 then
		GF.ShowMessage(ccClientText(42040))
		return
	end
	gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_WAR_TEMPLE, LPlayerShowConst.OTHER_SYSTEM)
end

--设置立绘
function UIWarTempleRank:SetHeroPaint(paintTans, info, index) --index = 1 文件形象， = 2 英雄形象
	local refId = info.refId
	local starLv = info.star
	local key = info.id or info.key
	local ref

	if (info.skin and info.skin > 0) then
		ref = gModelHero:GetShowEffectById(info.skin)
		ref = gModelPlayer:GetRoleAdventureImage(ref.rankingId)
	elseif info.figure then
		ref = gModelPlayer:GetRoleAdventureImage(info.figure)
	else
		if refId == 0 then
			return
		end
		ref = gModelHero:GetHeroShowRefByRefId(refId, starLv)
		ref = gModelPlayer:GetRoleAdventureImage(ref.rankingId)
	end
	if (not ref) then
		return
	end

	self:SetSpine(paintTans, ref, key)
end

-- 排行榜数据返回
function UIWarTempleRank:OnRankUpdate(type, rankType)
	if rankType ~= gModelRank.RANK_WARTEMPLE then
		return
	end
	self:Refresh()
end

------------------------------------------------------------------
return UIWarTempleRank