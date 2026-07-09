---
--- Created by LCM.
--- DateTime: 2024/3/30 10:39:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuGradAwardSow:LWnd
local UIKuafuGradAwardSow = LxWndClass("UIKuafuGradAwardSow", LWnd)

UIKuafuGradAwardSow.CHALLENGE_REWARD = 1				-- 挑战奖励
UIKuafuGradAwardSow.GRADING_REWARD = 2				-- 段位奖励 		倒序(未改)
UIKuafuGradAwardSow.SEASON_REWARD = 3					-- 赛季奖励 		倒序(未改)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuGradAwardSow:UIKuafuGradAwardSow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuGradAwardSow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuGradAwardSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuGradAwardSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isVie = gLGameLanguage:IsVieVersion()
	self:SetWndText(self.mLblBiaoti,ccClientText(10154))
	self:SetWndText(self.mUIText, ccClientText(11733))
	self:InitTextLineWithLanguage(self.mUIText, -30)
	self:InitTextSizeWithLanguage(self.mUIText, -2)
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitBtnList()
end

function UIKuafuGradAwardSow:OnClickGetAll()
	gModelCrossGrading:OnCrossRankReceiveAllReq(ModelCrossGrading.GRADING_REWARD)
end

function UIKuafuGradAwardSow:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnGetAll,function () self:OnClickGetAll() end)
end

function UIKuafuGradAwardSow:GetRewardFunc(refId)
	local btnType = self._btnType
	if not btnType then return end
	local rrType = btnType == UIKuafuGradAwardSow.CHALLENGE_REWARD and ModelCrossGrading.CHALLENGE_REWARD or ModelCrossGrading.GRADING_REWARD
	gModelCrossGrading:OnCrossRankReceiveReq(rrType,refId)
end

function UIKuafuGradAwardSow:OnDrawRewardCell(list,item,itemdata,itempos)
	local ItemList = self:FindWndTrans(item,"ItemList")
	local TitleBg = self:FindWndTrans(item,"TitleBg")
	local Title = self:FindWndTrans(TitleBg,"Title")
	local scheduleTxt = self:FindWndTrans(item,"scheduleTxt")
	local GetBtn = self:FindWndTrans(item,"GetBtn")
	local NotGetImg = self:FindWndTrans(item,"NotGetImg")
	local AllGetImg = self:FindWndTrans(item,"AllGetImg")

	local btnType = self._btnType
	local refId = itemdata.refId
	local status = itemdata.status
	--local showNotGetImg = status == 0
	local showNotGetImg = false
	local showGetBtn = status == 1
	local showAllGetImg = status == 2

	local titleStr
	local scheduleStr = ""
	local shoSchedule = btnType == UIKuafuGradAwardSow.CHALLENGE_REWARD
	if shoSchedule then
		titleStr = string.replace(ccClientText(21827),itemdata.finishCond)
--[[		local dayBattleCount = gModelCrossGrading:GetBattleCount()
		scheduleStr = string.format("%s/%s",dayBattleCount,itemdata.finishCond)]]
	else
		local name = itemdata.name
		local nameColor = itemdata.nameColor
		if nameColor then
			nameColor = self:GetNameColor(nameColor,itemdata)
			nameColor = "#" .. nameColor
			name = LUtil.FormatColorStr(name,nameColor)
		end
		titleStr = string.replace(ccClientText(21826),name)
	end
	self:SetWndText(Title,titleStr)
	self:SetWndText(scheduleTxt,scheduleStr)

	local rewardList = itemdata.reward
	self:InitItemList(ItemList,rewardList)

	CS.ShowObject(scheduleTxt,shoSchedule)
	CS.ShowObject(NotGetImg,showNotGetImg)
	if showNotGetImg then
		self:SetWndEasyImage(NotGetImg, "activity_turn_txt_16", nil, true)
	end

	CS.ShowObject(GetBtn,showGetBtn)
	CS.ShowObject(AllGetImg,showAllGetImg)
	if showAllGetImg then
		self:SetWndEasyImage(AllGetImg, "public_txt_13_1", nil, true)
	end

	local instance = item:GetInstanceID()
	self:DestroyWndEffectByKey(instance)
	if showGetBtn then
		self:SetWndButtonText(GetBtn,ccClientText(10151))

		self:CreateWndEffect(GetBtn,"fx_shouchong_anniu_zhong",instance,100,false,false)
	end

	self:SetWndClick(GetBtn,function()
		self:GetRewardFunc(refId)
	end)
end

function UIKuafuGradAwardSow:RefreshDesc()
	local btnType = self._btnType
	local isChallenge = btnType == UIKuafuGradAwardSow.CHALLENGE_REWARD
	local isGrading = btnType == UIKuafuGradAwardSow.GRADING_REWARD
	local isSeason = btnType == UIKuafuGradAwardSow.SEASON_REWARD

	local challengeStr,allChange = "",""
	local GandSRankStr,GandSDesc = "",""
	if isChallenge then
		challengeStr = ccClientText(21828)
		allChange = ccClientText(21838)
	elseif isGrading then
		local curRef = gModelCrossGrading:GetCurCrossGradingIntervalRef()
		local name = curRef and ccLngText(curRef.name) or ""
		local nameColor = curRef and curRef.nameColor
		if nameColor then
			nameColor = self:GetNameColor(nameColor,curRef)
			nameColor = "#" .. nameColor
			name = LUtil.FormatColorStr(name,nameColor)
		end
		GandSRankStr = string.replace(ccClientText(21824),name)
		GandSDesc = ccClientText(21825)
	elseif isSeason then
		local rank = gModelCrossGrading:GetRank()
		if rank == -1 then
			rank = ccClientText(11716)
		end
		GandSRankStr = string.replace(ccClientText(21822),rank)
		GandSDesc = ccClientText(21823)
	end

	if isChallenge then
		self:SetWndText(self.mChallengeDesc,challengeStr)
		self:InitTextLineWithLanguage(self.mChallengeDesc, -30)
		self:SetWndText(self.mAllChangeDesc,allChange)
		self:InitTextLineWithLanguage(self.mAllChangeDesc, -30)
	else
		self:SetWndText(self.mGandSRankDesc,GandSRankStr)
		self:InitTextLineWithLanguage(self.mGandSRankDesc, -30)
		self:SetWndText(self.mGandSDesc,GandSDesc)
		self:InitTextLineWithLanguage(self.mGandSDesc, -30)
	end

	CS.ShowObject(self.mChallengeDesc, isChallenge)
	CS.ShowObject(self.mAllChangeDesc, isChallenge)
	CS.ShowObject(self.mGandSRankDesc, not isChallenge)
	CS.ShowObject(self.mGandSDesc, not isChallenge)
end

function UIKuafuGradAwardSow:OnDrawBtnCell(list,item,itemdata,itempos)
	local btnType = itemdata.btnType
	local TabBtn = self:FindWndTrans(item,"TabBtn")
	if TabBtn then
		--local lineSize
		--if self._isGerman then
		--	lineSize = -50
		--end
		local size1 = -2
		local Line1 = -40
		if self._isVie then
			size1 = -4
			Line1 = -10
		end
		self:SetWndTabText(TabBtn,ccClientText(itemdata.textId), size1, Line1)

		local selTab = self._btnType == btnType and LWnd.StateOn or LWnd.StateOff
		self:SetWndTabStatus(TabBtn,selTab)

		self:SetWndClick(TabBtn,function()
			self:ClickTabBtnFunc(btnType)
		end)
	end
	local redPoint = self:FindWndTrans(item,"redPoint")
	if redPoint then
		local showRedPoint = btnType ~= UIKuafuGradAwardSow.SEASON_REWARD or false
		if showRedPoint then
			if btnType == UIKuafuGradAwardSow.CHALLENGE_REWARD then
				showRedPoint = gModelCrossGrading:GetChallengeRewardStatus()
			elseif btnType == UIKuafuGradAwardSow.GRADING_REWARD then
				showRedPoint = gModelCrossGrading:GetGradingRewardStatus()
			else
				showRedPoint = false
			end
		end
		CS.ShowObject(redPoint,showRedPoint)
	end
end

function UIKuafuGradAwardSow:OnDrawSeasonRewardCell(list,item,itemdata,itempos)
	local CurRank = self:FindWndTrans(item,"CurRank")
	local CurRankEnus = self:FindWndTrans(item, "CurRankEnus")
	local RankIcon = self:FindWndTrans(item,"RankIcon")
	local RankEff = self:FindWndTrans(RankIcon,"RankEff")
	local RankName = self:FindWndTrans(item,"RankName")
	local ItemList = self:FindWndTrans(item,"ItemList")

	local isEnglish = gLGameLanguage:IsForeignVersion()
	local isCurRank = itemdata.isCurRank
	CS.ShowObject(CurRank,not isEnglish and isCurRank)
	CS.ShowObject(CurRankEnus, isEnglish and isCurRank)

	local info = itemdata.ref
	self:SetWndEasyImage(RankIcon,info.icon,function()
		CS.ShowObject(RankIcon,true)
	end,true)

	local iconEffect = itemdata.iconEffect
	if not string.isempty(iconEffect) then
		local InstanceID = RankEff:GetInstanceID()
		self:CreateWndEffect(RankEff,iconEffect,InstanceID,100,false,false)
	end

	local name = ccLngText(info.name)
	local nameColor = info.nameColor
	if nameColor then
		nameColor = self:GetNameColor(nameColor,info)
		nameColor = "#" .. nameColor
		name = LUtil.FormatColorStr(name,nameColor)
	end
	self:SetWndText(RankName,name)

	local allRewardList = info.allRewardList
	self:InitItemList(ItemList,allRewardList)
end

function UIKuafuGradAwardSow:RefreshViewShow()
	local btnType = self._btnType
	local getRewardFuncList = self._getRewardFuncList or {}
	local getListFunc = getRewardFuncList[btnType]

	local list = {}
	if getListFunc then list = getListFunc() end

	local isOnlyShowReward = btnType == UIKuafuGradAwardSow.SEASON_REWARD
	CS.ShowObject(self.mRewardList,not isOnlyShowReward)
	CS.ShowObject(self.mSeasonRewardList,isOnlyShowReward)

	self:RefreshDesc()

	if isOnlyShowReward then
		self:InitSeasonRewardList(list)
	else
		self:InitRewardList(list)
	end
	self:RefreshBtnList()

	self:RefreshBtnShow()
end

function UIKuafuGradAwardSow:InitBtnList()
	local list = self._typeList
	local uiBtnList = self._uiBtnList
	if uiBtnList then
		uiBtnList:RefreshList(list)
	else
		uiBtnList = self:GetUIScroll("uiBtnList")
		self._uiBtnList = uiBtnList
		uiBtnList:Create(self.mBtnList,list,function(...) self:OnDrawBtnCell(...) end)
	end

	if not self._btnType then
		local redPointBtnType = self:GetRedPointIndex() or UIKuafuGradAwardSow.CHALLENGE_REWARD
		local selBtnType = self._selBtnType or redPointBtnType
		self:ClickTabBtnFunc(selBtnType)
	end
end

function UIKuafuGradAwardSow:InitItemList(listTrans,list)
	local key = listTrans:GetInstanceID()
	local uiList = self:FindUIScroll(listTrans)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(listTrans,list,function(...) self:OnDrawItemCell(...) end)
		--uiList:EnableScroll(true,true)
	end
end

function UIKuafuGradAwardSow:InitData()
	self._selBtnType = self:GetWndArg("selBtnType")

	local typeList = {
		{
			btnType = UIKuafuGradAwardSow.CHALLENGE_REWARD,
			textId = 21818,
		},
		{
			btnType = UIKuafuGradAwardSow.GRADING_REWARD,
			textId = 21819,
		},
		{
			btnType = UIKuafuGradAwardSow.SEASON_REWARD,
			textId = 21820,
		},
	}
	self._typeList = typeList

	self._sortStatusNum = {
		[0] = 2,
		[1] = 3,
		[2] = 1,
	}

	self._isGerman = gLGameLanguage:IsGermanVersion()

	local getRewardFuncList = {
		[UIKuafuGradAwardSow.CHALLENGE_REWARD] = function()
			return gModelCrossGrading:GetChallengeRewardList()
		end,
		[UIKuafuGradAwardSow.GRADING_REWARD] = function()
			return gModelCrossGrading:GetGradingRewardList()
		end,
		[UIKuafuGradAwardSow.SEASON_REWARD] = function()
			return gModelCrossGrading:GetEndRewardSortList()
		end,
	}
	self._getRewardFuncList = getRewardFuncList
end

function UIKuafuGradAwardSow:InitSeasonRewardList(list)
	local rankList = {}
	local curRankRefId = gModelCrossGrading:GetRankRefIdByScore()
	for i,v in ipairs(list) do
		local isCurRank = v.refId == curRankRefId
		table.insert(rankList,{
			ref = v,
			isCurRank = isCurRank,
		})
	end
	local uiSeasonRewardList = self._uiSeasonRewardList
	if uiSeasonRewardList then
		uiSeasonRewardList:RefreshList(rankList)
	else
		uiSeasonRewardList = self:GetUIScroll("uiSeasonRewardList")
		self._uiSeasonRewardList = uiSeasonRewardList
		uiSeasonRewardList:Create(self.mSeasonRewardList,rankList,function(...) self:OnDrawSeasonRewardCell(...) end,UIItemList.WRAP)
	end
end

function UIKuafuGradAwardSow:RefreshBtnList()
	local uiBtnList = self._uiBtnList
	if not uiBtnList then return end
	local uiList = uiBtnList:GetList()
	uiList:RefreshList()
end

function UIKuafuGradAwardSow:GetNameColor(nameColor,ref)
	local sort = ref.sort
	if sort <= 3 then
		nameColor = gModelCrossGrading:GetConfigByKey("rewardColor")
	end
	return nameColor
end

function UIKuafuGradAwardSow:InitRewardList(list)
	local jumpIndex = 0
	for i,v in ipairs(list) do
		local status = v.status or 0
		if status == 1 then
			jumpIndex = i
			break
		end
	end

	if jumpIndex > 0 then
		jumpIndex = jumpIndex - 1
	end

	local uiRewardList = self._uiRewardList
	if uiRewardList then
		uiRewardList:RefreshList(list,false)
	else
		uiRewardList = self:GetUIScroll("uiRewardList")
		self._uiRewardList = uiRewardList
		uiRewardList:Create(self.mRewardList,list,function(...) self:OnDrawRewardCell(...) end,UIItemList.WRAP,false)
		uiRewardList:EnableScroll(true)
	end

	local uiList = uiRewardList:GetList()
	uiList:RefreshList(UIListWrap.RefreshMode.Custom,jumpIndex)
end

function UIKuafuGradAwardSow:GetRedPointIndex()
	local selType
	for k,v in pairs(self._getRewardFuncList) do
		if selType then break end
		if k ~= UIKuafuGradAwardSow.SEASON_REWARD then
			local list = v() or {}
			for idx,val in ipairs(list) do
				local status = val.status or 0
				if status == 1 then
					selType = k
					break
				end
			end
		end
	end
	return selType
end

function UIKuafuGradAwardSow:OnDrawItemCell(list,item,itemdata,itempos)
	local CommonUI = self:FindWndTrans(item,"CommonUI")
	local Icon = self:FindWndTrans(CommonUI,"Icon")

	local itemType,itemId,itemNum = itemdata.itemType,itemdata.itemId,itemdata.itemNum
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	baseClass:DoApply()

	self:SetWndClick(CommonUI,function()
		if itemType == LItemTypeConst.TYPE_ITEM then
			local ref = gModelItem:GetRefByRefId(itemId)
			if not ref then
				LogError("请检查配置，不存在itemId = " .. itemId)
			else
				gModelGeneral:OpenItemInfoTip(itemId,itemNum)
			end
		else
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end
	end)
end

function UIKuafuGradAwardSow:RefreshBtnShow()

	local show = true
	if self._btnType ~= UIKuafuGradAwardSow.GRADING_REWARD then
		show = false
	end
	local list = {}
	local getRewardFuncList = self._getRewardFuncList or {}
	local getListFunc = getRewardFuncList[UIKuafuGradAwardSow.GRADING_REWARD]
	if getListFunc then
		list = getListFunc()
	end

	local cnt = 0
	for k,v in ipairs(list) do
		if v.status == 1 then
			cnt = cnt + 1
		end
	end

	if cnt <= 1 then
		show = false
	end

	CS.ShowObject(self.mBtnGetAll,show)
end

function UIKuafuGradAwardSow:InitMsg()
	self:WndNetMsgRecv(LProtoIds.CrossRankMatchInfoResp,function()
		self:RefreshViewShow()
		self:RefreshBtnList()
	end)
end

function UIKuafuGradAwardSow:ClickTabBtnFunc(btnType)
	if self._btnType and self._btnType == btnType then return end
	self._btnType = btnType
	self:RefreshViewShow()
end


------------------------------------------------------------------
return UIKuafuGradAwardSow


