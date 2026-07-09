---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringPerInfo:LWnd
local UIringPerInfo = LxWndClass("UIringPerInfo", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringPerInfo:UIringPerInfo()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringPerInfo:OnWndClose()
	--if self._heroList then
	--	self._heroList:Destroy()
	--	self._heroList =nil
	--end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringPerInfo:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringPerInfo:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetPara()
	self:InitUIEvent()
	self:InitEvent()


	gModelGeneral:PlayerShowReq(self._playerId,LCombatTypeConst.COMBAT_ARENA_DEFEND,LPlayerShowConst.ARENA_SYSTEM)
end

function UIringPerInfo:ChallengePlayer()
	gModelArena:GoToChallenge(self._playerData,self:GetWndName())
	self:WndClose()
end

function UIringPerInfo:SetHero(list, item,itemdata, itemPos)
	local heroTrans = CS.FindTrans(item,"HeroIcon")

	--local instanceId = item:GetInstanceID()
	--local heroIcon = self._heroList:GetItemCls(instanceId)
	--if not heroIcon then
	--	heroIcon = CommonIcon:New()
	--	self._heroList:SetItemCls(instanceId, heroIcon)
	--	heroIcon:Create(heroTrans)
	--end

	local id,refId,star,level,grade,fightPower = itemdata.id,itemdata.refId,itemdata.star,itemdata.level,itemdata.grade,itemdata.fightPower
	local skin = itemdata.skin
	local isResonance = itemdata.isResonance
	local herodata = {}
	herodata.trans = heroTrans
	herodata.id = id
	herodata.refId = refId
	herodata.star = star
	herodata.level = level
	herodata.isResonance = isResonance
	herodata.skin = skin

	--heroIcon:SetHeroDataSet(herodata)
	--heroIcon:DoApply()

	self:CreateHeroIconImpl(heroTrans,herodata)

	self:SetWndClick(heroTrans,function()
		local data = {
			id = id,
			refId = refId,
			level = level,
			star = star,
			grade = grade,
			fightPower = fightPower,
			isResonance = isResonance,
			skin = skin
		}
		gModelHero:ReqShowHeroTip(self._playerId,data)
	end)
	self:SetIconClickScale(heroTrans, true)
end

function UIringPerInfo:SetPara()
	self._playerData = self:GetWndArg("playerData")
	self._playerId = self._playerData.playerId

end

function UIringPerInfo:SetContent()
	self:SetWndText(self.mTitleText,ccClientText(10369))
	local playerInfo = self._netData.targetContent
	self:SetWndText(self.mDefendInfo,ccClientText(11858))

	self:SetWndText(self.mName,playerInfo.name)

	local headIcon = self._headIcon
	if not headIcon then
		headIcon = HeadIcon:New(self)
		self._headIcon = headIcon
	end

	local headData={
		trans=self.mHeadIcon,
		icon=playerInfo.head,
		headFrame=playerInfo.headFrame,
		name=playerInfo.name,
		level=playerInfo.grade,
	}
	headIcon:SetHeadData(headData)
	headIcon:RefreshUI()



	self:SetWndText(self.mPowerText,LUtil.PowerNumberCoversion(playerInfo.power))
    local str = string.replace(ccClientText(10368),playerInfo.score)
	self:SetWndText(self.mScore,str)

	local challengeBtnText = self:FindWndTrans(self.mChallengeBtn,"text")
	--local ticketRoot = self:FindWndTrans(self.mChallengeBtn,"ticket")
	--local ticketNum = self:FindWndTrans(ticketRoot,"num")
	--local ticketIcon = self:FindWndTrans(ticketRoot,"icon")
	local canFreeChallenge = gModelArena:CanFreeChallenge()
	local str = nil
	if canFreeChallenge then
		str = ccClientText(10313)
		--self:SetWndText(challengeBtnText,ccClientText(10313))--免费挑战
	else
		str = ccClientText(10370)
		--local ticketId =gModelArena:GetArenaPara("TciketId")
		--local icon,iconBg = gModelItem:GetItemImgByRefId(ticketId)
		--if icon then
		--	self:SetWndEasyImage(ticketIcon,icon)
		--end
		--local num = gModelArena:GetArenaPara("TicketNum")
		--local str = string.format("%s %s",num,ccClientText(10370))
		--self:SetWndText(ticketNum,str) --挑战
		--self:InitTextSizeWithLanguage(ticketNum, -2)
	end
	self:SetWndText(challengeBtnText,str)
	self:InitTextLineWithLanguage(challengeBtnText,-50)
	--CS.ShowObject(ticketRoot,not canFreeChallenge)
	--CS.ShowObject(challengeBtnText,canFreeChallenge)

	local dataList = {}
	local heroData =self._netData.heroData
	for k,v in ipairs(heroData.heros) do
		--local data ={}
		table.insert(dataList,v)
	end
	self:SetWndClick(self.mChallengeBtn,function ()self:ChallengePlayer() end,LSoundConst.CLICK_BUTTON_COMMON)

	local heroList = self:FindUIScroll("heroList")
	if not heroList then
		heroList = self:GetUIScroll("heroList")
		--self._heroList = heroList
		heroList:Create(self.mHeroList,dataList,function (...) self:SetHero(...) end)
	else
		heroList:RefreshList(dataList)
	end
end

function UIringPerInfo:InitEvent()
	self:WndNetMsgRecv(LProtoIds.PlayerShowResp,function (...) self:OnPlayerShowResp(...) end)
	local PbMsgId = LProtoHelper.GetProtoId("PlayerShowResp")
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(msgId,error, argList)
		if PbMsgId == msgId then
			self:WndClose()
		end
	end)
end


function UIringPerInfo:InitUIEvent()
	self:SetWndClick(self.mMask, function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIringPerInfo:OnPlayerShowResp(pb)
	local targetId = pb.targetContent.playerId
	if targetId ~= self._playerId then
		return
	end
	self:SetWndVisible(true)

	self._netData = pb
	self._name = pb.targetContent.name
	self:SetContent()
end

------------------------------------------------------------------
return UIringPerInfo


