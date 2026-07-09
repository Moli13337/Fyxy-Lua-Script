
---
--- Created by Administrator.
--- DateTime: 2023/10/23 14:32:00
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPkWait:LChildWnd
local UISubPkWait = LxWndClass("UISubPkWait", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPkWait:UISubPkWait()
	self.commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPkWait:OnWndClose()
	self:ClearCommonIconList(self.commonUIList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPkWait:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPkWait:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	
	if self._isEnus then 
		
		self.mMidRankBg.localScale=Vector3.New(1.6,1.4,1)
	end 
	
	
	self:InitData()
	self:InitView()
	self:InitEvent()
	self:ShowReward()

	self:SetTextList()
	self:SetRewardList()

	gModelRank:OnRankReq(2, 505, 1, 25) --排行榜请求
end

function UISubPkWait:ShowReward()

end

function UISubPkWait:SetRankTopThree(pb)
	if pb.infos then
		for i = 1, 3 do
			if pb.infos[i] then
				self:SetRankTrans(self["mRank" .. i], pb.infos[i])
			end
		end
	else
		-- CS.ShowObject(self.mRank1, false)
		-- CS.ShowObject(self.mRank2, false)
		-- CS.ShowObject(self.mRank3, false)
	end

	local rank = pb.selfRank and pb.selfRank.rank or 0
	local id = rank == -1 and 11818 or 11815
	self:SetWndText(self.mRankText, string.replace(ccClientText(id), rank))
end

function UISubPkWait:OnTimer(key)
	if key == self._countDownKey then
		self:SetCountDown()
	end
	if key == "setTextContentSize" then
		local height = 0
		for i = 1, self.mTextContent.childCount do
			local trans = CS.FindTrans(self.mTextContent, "TextRoot" .. i)
			local text = self:FindWndTrans(trans, "Text")
			height = text.rect.height + height
			trans.sizeDelta = Vector2(trans.rect.width, text.rect.height)
		end
		self.mTextContent.sizeDelta = Vector2(self.mTextContent.rect.width, height)
		CS.ShowObject(self.mTextContent, false)
		CS.ShowObject(self.mTextContent, true)
	end
end

function UISubPkWait:SetRewardList()
	local rewardCfg = gModelArena:GetArenaPeakRef("alterAward1")
	local rewardList = LxDataHelper.ParseItem(rewardCfg)
	for i = 1, #rewardList do
		local item = self["mItem" .. i]
		if item then
			self:SetRewardIcon(item, rewardList[i])
			CS.ShowObject(item, true)
		end
	end
end
function UISubPkWait:InitView()

	local state = gModelArena:GetPeakState()
	local isStateBefore = state==ModelArena.PEAK_STATE_BEFORE
	if self._isShowForeignGuess then
		local combatState = gModelArena:GetPeakCombatState()
		isStateBefore = isStateBefore or combatState == ModelArena.PEAK_BATTLE_STATE_BETTING
	end

	if state == ModelArena.PEAK_STATE_BEFORE then
		self:ShowBeforeGame()
		self:SetWndText(self.mMidText, ccClientText(11821))
	elseif state == ModelArena.PEAK_STATE_STARTED then
		local isIn = gModelArena:GetIsInCircle()
		local text = isIn and ccClientText(11843) or ccClientText(11842)
		self:SetWndText(self.mMidText, text)
		-- if not isIn then
		-- 	self:ShowOnGame()
		-- end
	elseif state == ModelArena.PEAK_STATE_END then
		self:SetWndText(self.mMidText, ccClientText(11893))
		-- self:ShowAfterGame()
	end


	CS.ShowObject(self.mOpenInfo, true)

	self:SetWndText(self.mMidRewardText, ccClientText(29708))

end

function UISubPkWait:ShowOnGame()
	-- local str =ccClientText(11857) --"比赛进行中"
	-- str=ccClientText(11889) --"很遗憾,您未能进入排位赛前%s名获得参赛资格"
	-- -- local playerNum = gModelArena:GetArenaPara("PlayerNum")
	-- local playerNum = ""
	-- str= string.replace(str,playerNum)
	-- str =ccClientText(11890) ---"可选择前往竞猜和观战"
end

function UISubPkWait:ShowBeforeGame()
	local peakStartTime = gModelArena:GetPeakStartTime()
	local nextCombatStateTime = gModelArena:GetNextCombatStateTime()
	local peakDate= LUtil.OSDate("*t",nextCombatStateTime)

	local month, day = "/",""
	if not gLGameLanguage:IsForeignVersion() then
		month = ccClientText(11808)
		day = ccClientText(11807)
	end

	local timeStr = string.format("%d %s %d %s %d:%02d ",peakDate["month"],month,
			peakDate["day"],day,peakDate["hour"],peakDate["min"])

	local strClientKey = 11831
	local state = gModelArena:GetPeakState()
	if self._isShowForeignGuess and state==ModelArena.PEAK_STATE_BEFORE then
		strClientKey =  27424
	end

	local str = ccClientText(strClientKey,timeStr)
	self:SetWndText(self.mOpenTips1,str)

	-- local playerNum = gModelArena:GetArenaPara("PlayerNum")
	local playerNum = ""
	str = string.replace(ccClientText(11832),playerNum)
	str = string.replace(str,playerNum)

	local timeLeft= peakStartTime - GetTimestamp()
	if timeLeft>0 then
		self:TimerStop(self._countDownKey)
		self:TimerStart(self._countDownKey,1,false,-1)
	end
	self:SetCountDown()
end
function UISubPkWait:InitData()
	self._countDownKey = "_countDownKey"
	self._isShowForeignGuess = false

	self.textList = {ccClientText(17586), ccClientText(17587)}
end

function UISubPkWait:InitEvent()
	self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE,function () self:OnStateUpdate() end)
	self:WndNetMsgRecv(LProtoIds.RankResp, function(...) self:SetRankTopThree(...) end)
	self:WndNetMsgRecv(LProtoIds.PlayerLikeResp, function(...) gModelRank:OnRankReq(2, 505, 1, 25) end)
end

function UISubPkWait:ShowAfterGame()
	-- local str = ccClientText(11893)
	-- local str = ccClientText(11894)
end

function UISubPkWait:SetRewardIcon(item, data)
	local itemRoot = self:FindWndTrans(item, "ItemRoot")
	local itemName = self:FindWndTrans(item, "ItemName")
	if not self.commonUIList[item.gameObject.name] then
		self.commonUIList[item.gameObject.name] = CommonIcon:New()
		self.commonUIList[item.gameObject.name]:Create(itemRoot)
	end
	self.commonUIList[item.gameObject.name]:SetCommonReward(data.itemType, data.itemId, data.itemNum)
	self.commonUIList[item.gameObject.name]:EnableShowNum(false)
	self.commonUIList[item.gameObject.name]:DoApply()

	self:SetWndText(itemName, gModelGeneral:GetCommonItemName(data))

	self:SetWndClick(itemRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end


function UISubPkWait:SetCountDown()
	local peakStartTime = gModelArena:GetPeakStartTime()
	local timeLeft= peakStartTime - GetTimestamp()
	if timeLeft < 0 then
		self:TimerStop(self._countDownKey)
		return
	end
	local timeStr = LUtil.FormatTimespanCn(timeLeft)
	timeStr = LUtil.FormatColorStr(timeStr,"green")
	local str = string.replace(ccClientText(11833),timeStr)
end

function UISubPkWait:SetTextList()
	for i = 1, self.mTextContent.childCount do
		local trans = CS.FindTrans(self.mTextContent, "TextRoot" .. i)
		local text = self:FindWndTrans(trans, "Text")
		CS.ShowObject(trans, self.textList[i] ~= nil)
		self:SetWndText(text, self.textList[i])
	end
	self:TimerStart("setTextContentSize" , 0.1, false, 1)
end

function UISubPkWait:SetRankTrans(trans, data)
	local serverText = self:FindWndTrans(trans,"ServerText")
	local nameText = self:FindWndTrans(trans, "NameText")
	local likeBtn = self:FindWndTrans(trans, "LikeBtn")
	local likeBtnImg = self:FindWndTrans(likeBtn, "Image")
	local likeText = self:FindWndTrans(likeBtn, "Text")
	local SelfTag = self:FindWndTrans(trans, "SelfTag")

	self:SetHeroPaint(trans, data.info)

	local instanceId = trans:GetInstanceID()
	local likeType = gModelArena:GetArenaPeakRef("historyLike")
	local isLiked = gModelRank:IsLiked(likeType, data.info.playerId)
	-- local isSelf = data.info.playerId == gModelPlayer:GetPlayerId()
	local isGray = isLiked
	self:SetWndTabStatus(likeBtn, isGray and 0 or 1) --点赞0 没点1

	self:SetWndText(serverText, string.replace("【#a1#】", data.info.serverName))
	self:SetWndText(nameText, data.info.name)
	self:SetWndText(likeText, LUtil.NumberCoversion(data.info.like))

	if isGray then
        self:DestroyWndEffectByKey(instanceId .. "show")
    else
        self:CreateWndEffect(likeBtnImg, "fx_ui_dianzanchangzhu", instanceId .. "show", 100)
    end

	local selfPlayerId = gModelPlayer:GetPlayerId()
	CS.ShowObject(SelfTag,selfPlayerId == data.info.playerId)

	self:SetWndClick(trans, function()
		gModelGeneral:PlayerShowReq(
			data.info.playerId,
			LCombatTypeConst.COMBAT_MAIN,
			LPlayerShowConst.OTHER_SYSTEM
		)
	end)
	self:SetWndClick(likeBtn, function()
		-- if isSelf then
		-- 	GF.ShowMessage(ccClientText(11877))
		-- 	return
		-- end
		if isLiked then
			GF.ShowMessage(ccClientText(11878))
			return
		end
		gModelRank:OnPlayerLikeReq(data.info.playerId, likeType)
        local eff = self:FindWndEffectByKey(instanceId)
        if eff then
            eff:SetVisible(false)
            eff:SetVisible(true)
        else
            self:CreateWndEffect(likeBtnImg, "fx_ui_dianzan", instanceId, 100)
        end
	end)
end

function UISubPkWait:SetHeroPaint(trans, info)
	local paintTans = self:FindWndTrans(trans, "Spine/SpineRoot")
	local ref = gModelPlayer:GetRoleAdventureImage(info.figure)
	if not ref then return end
	local key = trans.gameObject.name

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
function UISubPkWait:OnStateUpdate()
	self:InitView()
end

------------------------------------------------------------------
return UISubPkWait


