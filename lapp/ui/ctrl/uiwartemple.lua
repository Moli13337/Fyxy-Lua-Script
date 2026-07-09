---
--- Created by wzz.
--- DateTime: 2024/5/8 15:56:23
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWarTemple:LWnd
local UIWarTemple = LxWndClass("UIWarTemple", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWarTemple:UIWarTemple()
	self.noNeedRegisterRed = true
	ModelWarTemple:WarTempleRankReq()
	gModelWarTemple:WarTempleInfoReq()
	gModelRank:OnRankReq(2, gModelRank.RANK_WARTEMPLE, 1, 150)
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWarTemple:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWarTemple:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWarTemple:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isJapaness  =gLGameLanguage:IsJapanVersion()

	self._isVie = gLGameLanguage:IsVieVersion() 
	
	if self._isJapaness or self._isVie then
		local imgTran =CS.FindTrans(self.mBottom,"Img0")
		LxUiHelper.SetSizeWithCurAnchor(imgTran,0,200)
	end

	if self._isVie then 
		local textTran =CS.FindTrans(self.mBtnReward,"UIText")
		self:InitTextLineWithLanguage(textTran,0)
		local text =CS.FindTrans(self.mBtnEffigy,"UIText")
		local textTran2 = LxUiHelper.FindXTextCtrl(text)
		textTran2.enableWordWrapping = true
	end 

	self._baseInfo = gModelWarTemple:GetBaseInfo()

	local dataList = gModelWarTemple:GetWarTempleRefList()
	self._uiDataList = dataList
	self:CheckNewUnlock()

	self:InitTexts()
	self:InitEvent()
	self:InitList()

	self:Refresh()

	local canvas = self.mTop:GetComponent(typeof(UnityEngine.Canvas))
	canvas.sortingOrder = self:GetWndSortOrder() + 4
	canvas = self.mBottom:GetComponent(typeof(UnityEngine.Canvas))
	canvas.sortingOrder = self:GetWndSortOrder() + 4
end

-- 刷新排行榜
function UIWarTemple:RefreshRank()
	local pb = gModelWarTemple:GetMainUiRankPb()
	if not pb then
		return
	end

	for i = 1, 3 do
		local rankText = CS.FindTrans(self["mRank" .. i], "RankText")
		local txtRank = CS.FindTrans(self["mRank" .. i], "TxtRank")
		local img0 = CS.FindTrans(self["mRank" .. i], "Img0")
		local rankInfo = pb.infos[i]
		local strName = ccClientText(42005)
		local strRank = ccClientText(42017)
		if rankInfo then
			strName = rankInfo.info.name
			local cfg = gModelWarTemple:GetWarTemplePalaceRefByRank(rankInfo.rank)
			local _, _, _, palaceRank = gModelWarTemple:GetNpcIdByRank(rankInfo.rank)
			if cfg then
				strRank = string.replace(ccClientText(27432, ccLngText(cfg.list) .. "-" .. palaceRank))
			end
			if rankInfo.rank > 3 then
				self:SetWndText(txtRank, rankInfo.rank)
			else
				self:SetWndEasyImage(img0, "public_num_" .. rankInfo.rank)
			end
			CS.ShowObject(txtRank, rankInfo.rank > 3)
			CS.ShowObject(img0, rankInfo.rank <= 3)
		else
			CS.ShowObject(img0, false)
			CS.ShowObject(txtRank, false)
		end
		self:SetWndText(rankText, strRank)
		self:SetTextTile(self["mRank" .. i], strName)
	end

	local baseInfo = self._baseInfo
	local meRank = baseInfo.allRank
	CS.ShowObject(self.mRank4, meRank > 0)

	if meRank == 0 then
		return
	end

	local strMeName = gModelPlayer:GetPlayerName()
	self:SetWndText(self.mTxtMeRank, meRank)
	self:SetWndText(self.mTxtMeName, strMeName)

	local rankText = CS.FindTrans(self.mRank4, "RankText")
	local cfg = gModelWarTemple:GetWarTemplePalaceRefByRank(meRank)
	if cfg then
		local s = string.replace(ccClientText(27432, ccLngText(cfg.list) .. "-" .. baseInfo.rank))
		self:SetWndText(rankText, s)
	end

	CS.ShowObject(self.mMeRank1, meRank == 1)
	CS.ShowObject(self.mMeRank2, meRank == 2)
	CS.ShowObject(self.mMeRank3, meRank == 3)
end

-- 点击布阵
function UIWarTemple:OnClickBtnFormation()
	local param = {
		setTargetType = LCombatTypeConst.COMBAT_WAR_TEMPLE_DEF,
		returnFunc = function()
			GF.OpenWnd("UIWarTemple")
		end,
	}

	gModelFormation:OpenSetFormationWnd(param)
end

-- 刷新界面
function UIWarTemple:Refresh()
	if not next(self._baseInfo) then
		return
	end
	if self._isJapaness then
		local img0 =CS.FindTrans(self.mBottom,"Img0")
		img0.sizeDelta = Vector2.New(270,60)
	end
	local baseInfo = self._baseInfo
	local leftTime = baseInfo.challengeCnt + baseInfo.freeChallengeCnt
	self:SetWndText(self.mTxtTimes, ccClientText(42008, baseInfo.challengeCnt + baseInfo.freeChallengeCnt))

	local free = baseInfo.freeChallengeCnt > 0
	local noTimes = baseInfo.buyChallengeCnt > 0
	local btnStr = ccClientText(42015)
	if free then
		btnStr = ccClientText(42007)
	end
	self:SetWndButtonText(self.mBtnFight, btnStr)
	self:SetWndButtonGray(self.mBtnFight, leftTime <= 0 and not noTimes)

	if self._isVie then
		local txtTran =CS.FindTrans(self.mBtnFight,"Light/Text")
		self:InitTextSizeWithLanguage(txtTran,-10)
		txtTran =CS.FindTrans(self.mBtnFight,"Gray/Text")
		self:InitTextSizeWithLanguage(txtTran,-10)
	end
	local freeRed = gModelWarTemple:HadFreeFightRed()
	self:SetRed(self.mBtnFight, freeRed)


	self:RefreshList()
	self:RefreshRank()

	local hadRed = gModelWarTemple:HadPalaceReward()
	if not hadRed then
		hadRed = gModelWarTemple:HadTargetReward()
	end
	self:SetRed(self.mBtnReward, hadRed)
	self:RefreshUpLevRed()
end

-- 点击挑战
function UIWarTemple:OnClickBtnFight()
	if gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_WAR_TEMPLE) then
		gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_WAR_TEMPLE, {})
		return
	end

	if gModelWarTemple:DuringSettlement(true) then
		return
	end

	local baseInfo = self._baseInfo
	if baseInfo.challengeCnt > 0 or baseInfo.freeChallengeCnt > 0 then
		GF.OpenWnd("UIWarTempleFightList")
		gModelWarTemple:SaveTodyWarTempleFreeFightRed()
		return
	end

	if self._baseInfo.buyChallengeCnt <= 0 then
		GF.ShowMessage(ccClientText(42016))
		return
	end

	GF.OpenWnd("UIWarTempleBuyTimes")
end

-- 初始界面化文本
function UIWarTemple:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(42000))
	self:SetWndText(self.mTxtTips1, ccClientText(42002))
	self:SetWndText(self.mTxtClose, ccClientText(42010))

	self:SetTextTile(self.mBtnBox, ccClientText(42001))
	self:SetTextTile(self.mBtnMore, ccClientText(42004))
	self:SetTextTile(self.mBtnFormation, ccClientText(42006))
	self:SetTextTile(self.mBtnShop, ccClientText(42013))
	self:SetTextTile(self.mBtnReward, ccClientText(42012))
	self:SetTextTile(self.mBtnEffigy, ccClientText(42009))
	self:SetTextTile(self.mBtnReport, ccClientText(42011))
end

-- 点击战报
function UIWarTemple:OnClickBtnReport()
	GF.OpenWnd("UIWarTempleReport")
end

-- 初始化事件
function UIWarTemple:InitEvent()
	self:SetWndClick(self.mCloseBtn, function()
		GF.OpenWndBottom("UIOutts", { childIndex = 2 })
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnBox, function() self:OnClickBtnBox() end)
	self:SetWndClick(self.mBtnMore, function() self:OnClickBtnMore() end)
	self:SetWndClick(self.mBtnFormation, function() self:OnClickBtnFormation() end)
	self:SetWndClick(self.mBtnShop, function() self:OnClickBtnShop() end)
	self:SetWndClick(self.mBtnReward, function() self:OnClickBtnReward() end)
	self:SetWndClick(self.mBtnEffigy, function() self:OnClickBtnEffigy() end)
	self:SetWndClick(self.mBtnFight, function() self:OnClickBtnFight() end)
	self:SetWndClick(self.mBtnReport, function() self:OnClickBtnReport() end)
	self:SetWndClick(self.mBtnHelp, function() GF.OpenWnd("UIBzTips", { refId = 171 }) end)

	self:WndEventRecv(EventNames.WARTEMPLE_INFO_RETURN,
			function(...)
				self._baseInfo = gModelWarTemple:GetBaseInfo()
				self:Refresh(...)
			end)

	self:WndEventRecv(EventNames.ON_LIKE_RETURN,
			function(...)
				self._uiList:DrawAllItems()
			end)
	self:WndEventRecv(EventNames.ON_LIKE_HISTORY_RET,
			function(...)
				self._uiList:DrawAllItems()
			end)
	self:WndEventRecv(EventNames.WARTEMPLE_MAIN_RANK_RETURN, function(...) self:OnRankUpdate(...) end)
	self:WndEventRecv(EventNames.On_Item_Change, function(...) self:RefreshUpLevRed(...) end)
	self:WndEventRecv(EventNames.ON_WND_CLOSE, function(wndName)
		if wndName == "UIWarTempleFastFight" then
			self:CheckNewUnlock()
		end
	end)
end

-- 绘制列表item项
function UIWarTemple:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			root    = CS.FindTrans(item, "root"),
			icon    = CS.FindTrans(item, "root/bg"),
			ui      = CS.FindTrans(item, "root/UI"),
			txtName = CS.FindTrans(item, "root/UI/0/TxtName"),
			txtLvl  = CS.FindTrans(item, "root/UI/0/TxtLvl"),
			used    = CS.FindTrans(item, "root/UI/used"),
			txtRank = CS.FindTrans(item, "root/UI/1/TxtRank"),
		}
		self:SetComponentCache(instanceID, itemCache)
	end

	local canvas = itemCache.icon:GetComponent(typeof(UnityEngine.Canvas))
	canvas.sortingOrder = self:GetWndSortOrder() + 2
	canvas = itemCache.ui:GetComponent(typeof(UnityEngine.Canvas))
	canvas.sortingOrder = self:GetWndSortOrder() + 3

	if itemPos % 2 == 0 then
		itemCache.root.transform.anchoredPosition = Vector2(106, 20)
	else
		itemCache.root.transform.anchoredPosition = Vector2(-106, 20)
	end

	local ref = itemData
	local baseInfo = self._baseInfo
	if not baseInfo then
		return
	end

	self:SetWndText(itemCache.txtName, ccLngText(itemData.name))
	self:SetWndText(itemCache.txtLvl, itemData.list)
	self:SetWndEasyImage(itemCache.icon, ref.icon, nil, true)

	local rank = baseInfo.rank
	local used = baseInfo.palace == ref.refId and rank > 0

	CS.ShowObject(itemCache.used, used)
	CS.ShowObject(itemCache.txtRank.parent, used)
	if used then
		if rank == 0 then
			rank = ccClientText(42017)
		end
		self:SetWndText(itemCache.txtRank, ccClientText(42014, rank))
	end
	self:SetWndClick(itemCache.icon, function() self:OnClickItem(ref.refId) end)

	local showRed = false
	if ref.like > 0 then
		showRed = not gModelRank:IsLikeLimit(ref.like, false)
	end
	self:SetRed(itemCache.ui, showRed)


	if self._needPlayEffRefId == ref.refId then
		self._needPlayEffRefId = nil
		-- self:DestroyWndEffectByKey("eff")
		self:CreateWndEffect(itemCache.icon, "fx_wushendian_diantangtisheng", "eff", 200)
	end

	if ref.effName and not string.isempty(ref.effName) then
		self:DestroyWndEffectByKey(instanceID)
		self:CreateWndEffect(itemCache.icon, ref.effName, instanceID, 100)
	end

	if self._isVie then
		self:InitTextSizeWithLanguage(itemCache.txtName,-4)
		self:SetAnchorPos(itemCache.txtName,Vector2.New(50,-2))
		local uiText =LxUiHelper.FindXTextCtrl(itemCache.txtName)
		uiText.characterSpacing = -8
	end
	if self._isJapaness then
		self:InitTextSizeWithLanguage(itemCache.txtName,-2)
		self:SetAnchorPos(itemCache.txtName,Vector2.New(50,-2))
		local uiText =LxUiHelper.FindXTextCtrl(itemCache.txtName)
		uiText.characterSpacing = -8
	end
end

-- 点击商店
function UIWarTemple:OnClickBtnShop()
	GF.OpenWndBottom("UIDian", { shopId = 2011 })
end

-- 点击更多
function UIWarTemple:OnClickBtnMore()
	GF.OpenWnd("UIWarTempleRank")
end

-- 刷新列表
function UIWarTemple:RefreshList()
	local pos
	local baseInfo = self._baseInfo
	local palace = baseInfo.palace
	for k, v in pairs(self._uiDataList) do
		if palace == v.refId then
			pos = k
			break
		end
	end
	self._uiList:DrawAllItems()
	if pos then
		if pos == #self._uiDataList then
			self._uiList:MoveToPos(pos, 0, -150)
		else
			self._uiList:MoveToPos(pos, 0, 50)
		end
	end
end

-- 刷新升级红点
function UIWarTemple:RefreshUpLevRed()
	self:SetRed(self.mBtnEffigy, gModelWarTemple:CanLvUpEgffigy())
end

-- 点击武神殿
function UIWarTemple:OnClickBtnEffigy()
	GF.OpenWnd("UIWarTempleEffigy")
end

-- 排行榜数据返回
function UIWarTemple:OnRankUpdate()
	self:RefreshRank()
end

-- 点击武神殿
function UIWarTemple:OnClickItem(refId)
	local ref = GameTable.BattleTemplePalaceRef[refId]
	if ref.playerShow == 0 then
		GF.ShowMessage(ccClientText(42061, ccLngText(ref.name)))
		return
	end

	GF.OpenWnd("UIWarTempleShowList", { refId = refId })
end

-- 点击奖励
function UIWarTemple:OnClickBtnReward()
	GF.OpenWnd("UIWarTempleAward")
end

-- 点击宝箱
function UIWarTemple:OnClickBtnBox()
	local baseInfo = self._baseInfo
	local itemList = gModelWarTemple:GetDailyRewardItem(baseInfo.palace, baseInfo.rank)
	local id = 150008
	local rank = baseInfo.rank
	if rank == 0 then
		id = 150009
		rank = ccClientText(42017)
	end

	local ref = GameTable.BattleTemplePalaceRef[baseInfo.palace]
	local para = { ccLngText(ref.name), rank }

	gModelGeneral:OpenUIOrdinTips({
		refId = id,
		itemList = itemList,
		para = para,
		func = function() self:OnClickBtnFight() end,
	})
end

-- 检查新解锁
function UIWarTemple:CheckNewUnlock()
	if not next(self._baseInfo) then
		return
	end
	self._needPlayEffRefId = nil
	local dataList = self._uiDataList
	for k, v in ipairs(dataList) do
		if gModelWarTemple:NeedPlayEff(v.refId) and dataList[k - 1] then
			self._needPlayEffRefId = v.refId
			GF.OpenWnd("UIWarTUp", { placeRefId1 = dataList[k - 1].refId, placeRefId2 = v.refId })
			break
		end
	end
end

-- 初始化列表
function UIWarTemple:InitList()
	local uiList = self:GetUIScroll("mList")
	self._uiList = uiList

	uiList:Create(self.mList, self._uiDataList, function(...)
		self:OnDrawListItem(...)
	end, UIItemList.SUPER_GRID)
end

------------------------------------------------------------------
return UIWarTemple