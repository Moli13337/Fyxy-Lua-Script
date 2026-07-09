---
--- Created by BY.
--- DateTime: 2023/10/29 10:59:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdBraveAwardPoints:LWnd
local UIGdBraveAwardPoints = LxWndClass("UIGdBraveAwardPoints", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdBraveAwardPoints:UIGdBraveAwardPoints()
	self._awardEasyIconList = {}
	self._tabTrList = {}
	self._ratingTrList = {}
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdBraveAwardPoints:OnWndClose()
	self:ClearCommonIconList(self._awardEasyIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdBraveAwardPoints:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdBraveAwardPoints:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()

	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIGdBraveAwardPoints:RewardListItem(list, item, itemdata, itempos)
	local hpText = self:FindWndTrans(item,"HpText")
	local raceText = self:FindWndTrans(item,"RaceText")

	local remainingHp = string.split(itemdata.remainingHp,",")
	local hpStr = ""
	if remainingHp[1] == remainingHp[2] then
		hpStr = remainingHp[1].."%"
	elseif remainingHp[2] then
		hpStr = remainingHp[1].."%-"..remainingHp[2].."%"
	end
	self:SetWndText(hpText,hpStr)
	self:SetWndText(raceText,string.replace(ccClientText(32726),itemdata.reward - 1))
end
function UIGdBraveAwardPoints:RefreshRankRating()
	local list = gModelGuildBoss:GetNewGuildDungeonRatingRef()
	local info = gModelGuildBoss:GetGuildBraveInfo()
	local scoreLevel = info.scoreLevel

	if not self._isRating then
		self._ratingRefId = scoreLevel
	end

	local ratingUiList = self._ratingUiList
	if ratingUiList then
		ratingUiList:RefreshList(list)
		--ratingUiList:DrawAllItems()
	else
		ratingUiList = self:GetUIScroll("ratingUiList")
		ratingUiList:Create(self.mRatingScroll,list,function(...) self:RatingListItem(...) end,UIItemList.SUPER)
		self._ratingUiList = ratingUiList
		ratingUiList:EnableScroll(true,true)
	end
	if not self._isRating then
		self._isRating = true
		local index = 1
		for i, v in ipairs(list) do
			if v.refId == scoreLevel then
				index = i
				break
			end
		end
		ratingUiList:MoveToPos(index)
		self:RefreshRankReward()
	end
end
function UIGdBraveAwardPoints:RatingListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local image = self:FindWndTrans(root,"Image")
	local selImage = self:FindWndTrans(root,"SelImage")

	self:SetWndEasyImage(image,itemdata.ratingIcon)
	CS.ShowObject(selImage,self._ratingRefId == itemdata.refId)
	--self._ratingTrList[itemdata.refId] = selImage
	self:SetWndClick(root,function  ()
		self:OnClickRating(itemdata.refId)
	end)
end
function UIGdBraveAwardPoints:RefreshMeReward()
	local info = gModelGuildBoss:GetGuildBraveInfo()
	local selfRank = info.selfRank or -1
	local currentHp = info.currentHp
	local level = info.level

	local levelRef = gModelGuildBoss:GetNewGuildDungeonLevelRefByRefId(level)
	local rankList = gModelGuildBoss:GetNewGuildDungeonRankRefByRating(info.scoreLevel,levelRef.level)

	local totalHp = levelRef.totalHp
	local curHpRace = math.floor(currentHp/totalHp * 100)
	self:SetWndText(self.mRankTipsText,string.replace(ccClientText(32704),selfRank))
	local lineb = -30
	if self._isVie then
		lineb = 10
	end
	self:InitTextLineWithLanguage(self.mRankTipsText, lineb)
	local list = {}
	for i, v in ipairs(rankList) do
		local rank = string.split(v.rank,",")
		if tonumber(rank[1]) <= selfRank and selfRank <= tonumber(rank[2]) then
			list = LxDataHelper.ParseItem(v.reward)
			break
		end
	end
	local rankAwardLen = #list
	CS.ShowObject(self.mRankAwardScroll,rankAwardLen > 0)
	CS.ShowObject(self.mRankAwardTipsText,rankAwardLen <= 0)
	local rankAwardScroll = self._rankAwardScroll
	if rankAwardScroll then
		rankAwardScroll:RefreshList(list)
	else
		rankAwardScroll = self:GetUIScroll("mRankAwardScroll")
		rankAwardScroll:Create(self.mRankAwardScroll,list,function(...) self:AwardListItem(...) end)
		self._rankAwardScroll = rankAwardScroll
	end

	local rewardRace = 0
	local integralList = gModelGuildBoss:GetNewGuildDungeonIntegralRewardRefByRating(info.scoreLevel)
	for i, v in ipairs(integralList) do
		local remainingHp = string.split(v.remainingHp,",")
		if tonumber(remainingHp[1]) <= curHpRace and curHpRace <= tonumber(remainingHp[2]) then
			rewardRace = v.reward -1
			break
		end
	end
	local integralAwardList = {}
	for i, v in ipairs(list) do
		local data = {
			itemType = v.itemType,
			itemId = v.itemId,
			itemNum = math.floor(v.itemNum * rewardRace),
		}
		table.insert(integralAwardList,data)
	end
	local integralAwardLen = #integralAwardList
	CS.ShowObject(self.mIntegraAwardScroll,integralAwardLen > 0)
	CS.ShowObject(self.mIntegraAwardTipsText,integralAwardLen <= 0)
	local integraAwardScroll = self._integraAwardScroll
	if integraAwardScroll then
		integraAwardScroll:RefreshList(integralAwardList)
	else
		integraAwardScroll = self:GetUIScroll("mIntegraAwardScroll")
		integraAwardScroll:Create(self.mIntegraAwardScroll,integralAwardList,function(...) self:AwardListItem(...) end)
		self._integraAwardScroll = integraAwardScroll
	end

	local integraTipsStr = ""
	if curHpRace >= 100 then
		integraTipsStr = string.replace(ccClientText(32728),curHpRace .. "%")
	else
		integraTipsStr = string.replace(ccClientText(32727),curHpRace .. "%",rewardRace)
	end
	self:SetWndText(self.mIntegraTipsText,integraTipsStr)
	local linea = -30
	if self._isVie then
		linea = 10
	end
	self:InitTextLineWithLanguage(self.mIntegraTipsText, linea)
end
function UIGdBraveAwardPoints:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(32700))
	self:SetWndText(self.mRankTitleText,ccClientText(32701))
	self:SetWndText(self.mRankAwardTipsText,ccClientText(32730))
	self:SetWndText(self.mIntegraTitleText,ccClientText(32702))
	self:SetWndText(self.mIntegraAwardTipsText,ccClientText(32730))
	self:SetWndText(self.mRatingText,ccClientText(32706))
	self:SetWndText(self.mTopText1,ccClientText(32705))
	self:SetWndText(self.mTopText2,ccClientText(32725))
	self:SetWndText(self.mMeTipsText,ccClientText(32729))
	self:InitTextLineWithLanguage(self.mMeTipsText, -30)

	if self.jpj then
		self:InitTextSizeWithLanguage(self.mRatingText,-4)
	end
	local list = {}
	if PRODUCT_G_VER == 0 then
		table.insert(list,{type = 1,title = ccClientText(32701)})
	end
	table.insert(list,{type = 2,title = ccClientText(32702)})
	local uiList = self:GetUIScroll("TabScroll")
	uiList:Create(self.mTabScroll,list,function(...) self:ListItem(...) end)
	self:OnClickTab(list[1].type)
end

function UIGdBraveAwardPoints:RefreshData()
	local _type = self._type
	CS.ShowObject(self.mMeReward,_type == 1)
	CS.ShowObject(self.mRankReward,_type == 2)
	if _type == 1 then
		self:RefreshMeReward()
	else
		self:RefreshRankRating()
	end
end
function UIGdBraveAwardPoints:RefreshRankReward()
	local rating = self._ratingRefId
	local list = gModelGuildBoss:GetNewGuildDungeonIntegralRewardRefByRating(rating)

	local rankRewardUiList = self._rankRewardUiList
	if rankRewardUiList then
		rankRewardUiList:RefreshList(list)
		rankRewardUiList:DrawAllItems()
	else
		rankRewardUiList = self:GetUIScroll("rankRewardUiList")
		rankRewardUiList:Create(self.mCellSuper,list,function(...) self:RewardListItem(...) end,UIItemList.SUPER)
		self._rankRewardUiList = rankRewardUiList
	end
end
function UIGdBraveAwardPoints:OnClickRating(rating)
	--local _ratingRefId = self._ratingRefId
	--local _ratingTrList = self._ratingTrList
	--if _ratingRefId then
	--	local trans = _ratingTrList[_ratingRefId]
	--	CS.ShowObject(trans,false)
	--end
	--local trans = _ratingTrList[rating]
	--CS.ShowObject(trans,true)
	self._ratingRefId = rating
	self._ratingUiList:DrawAllItems()
	self:RefreshRankReward()
end
function UIGdBraveAwardPoints:AwardListItem(list, item, itemdata, itempos)
	local root = CS.FindTrans(item,"CommonUI/Icon")
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

function UIGdBraveAwardPoints:OnClickTab(type)
	local _type = self._type
	local _tabTrList = self._tabTrList
	if _type then
		local tab = _tabTrList[_type]
		self:SetWndTabStatus(tab, 1)
	end
	local tab = _tabTrList[type]
	self:SetWndTabStatus(tab, 0)
	self._type = type
	self:RefreshData()
end

function UIGdBraveAwardPoints:ListItem(list, item, itemdata, itempos)
	local btnTab = self:FindWndTrans(item,"BtnTab1")
	local type = itemdata.type
	local title = itemdata.title
	self._tabTrList[type] = btnTab
	self:SetWndTabText(btnTab,title)
	self:SetWndTabStatus(btnTab, 1)
	self:SetWndClick(item,function  ()
		self:OnClickTab(type)
	end)
end

function UIGdBraveAwardPoints:InitEvent()
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
end
function UIGdBraveAwardPoints:InitMessage()

end
------------------------------------------------------------------
return UIGdBraveAwardPoints


