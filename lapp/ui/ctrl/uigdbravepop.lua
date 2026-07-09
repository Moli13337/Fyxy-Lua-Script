---
--- Created by BY.
--- DateTime: 2023/10/13 17:43:06
---
------------------------------------------------------------------
local Color = Color
local LWnd = LWnd
---@class UIGdBravePop:LWnd
local UIGdBravePop = LxWndClass("UIGdBravePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdBravePop:UIGdBravePop()
	---@type UIIconEasyList
	self._awardEasyIconList = nil
	self:SetHideHurdle()
	self._bossTimeKey = "bossTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdBravePop:OnWndClose()
	if self._awardEasyIconList then
		self._awardEasyIconList:Destroy()
		self._awardEasyIconList = nil
	end
	self:ClearTimerClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdBravePop:OnCreate()
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	LWnd.OnCreate(self)
	--self._braveInfo=nil					--公会副本信息
	self._bSweep=false 					--是否扫荡
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdBravePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()

	self._bSweep= self:GetWndArg("bSweep")

	if not gModelFunctionOpen:CheckIsShow(12102010) then
		if self.mRankScroll then
			CS.ShowObject(self.mRankScroll.parent, false)
		end
	end
	--gModelBackflow:SetPrivileBtn(self.mBtnPrivile,8,self)

	-- local priviCom = self:GetPrivilegeCom()
	-- priviCom:Create(self.mBtnPrivile,8,self)
end

function UIGdBravePop:OnClickInspire()--点击鼓舞
	local ref=gModelGuild:GetGuildDungeonEncourageRefByRefId()
	if(not ref)then
		GF.ShowMessage(ccClientText(14107))
		return
	end
	local buffCount=self._braveInfo.buffCount
	local attr=LUtil.GetRefAttr(ref.attr)
	local value=""
	if(attr.numType==1)then
		value = attr.value
	else
		value = (attr.value*100).."%"
	end
	local item=gModelGeneral:GetParseItem_3(ref.needItem)
	local itemId  = item.itemId
	local itemNum = item.itemNum
	local needStr=gModelItem:GetNameByRefId(itemId)..itemNum
	GF.OpenWnd("UIOrdinTip",{refId=100013,para={needStr,value,ref.addTime/3600},func=function (...)
		local num=gModelItem:GetNumByRefId(item.itemId)
		if(num<item.itemNum)then
			local wndName = self:GetWndName()
			gModelGeneral:OpenGetWayWnd({itemId=item.itemId,srcWnd = wndName})
			return
		end
		gModelGuildBoss:OnGuildBraveBuffReq(buffCount)
	end , consume = {itemNum, itemId}} )
end

function UIGdBravePop:ClearTimerClose()
	if self._timerClose then
		LxTimer.DelayTimeStop(self._timerClose)
		self._timerClose = nil
	end
end

function UIGdBravePop:OnClickDes()
	local rewardList =gModelGuild:GetGuildDungeonRankRef()
	GF.OpenWndBottom("UIRkPop",{refId = ModelRank.RANK_GUILDBBRAVE,rewardList = rewardList})
end

function UIGdBravePop:SetBossPaint(paintTans,monsterRef,isSurvive)--设置Boss立绘
	if(monsterRef)then
		local ref=gModelGuild:GetMonsterShow(monsterRef.monsterShowId)
		if(not ref)then
			return
		end
		local oldKey = self._oldSpineKey
		local key = ref.prefabName.."spineKey"
		if(oldKey and key ~= oldKey)then
			self:DestroyWndSpineByKey(oldKey)
		end
		local spine = self:FindWndSpineByKey(key)
		if not spine then
			self:CreateWndSpine(paintTans,ref.prefabName,key,false,function(dpSpine)
				local scale = monsterRef.scale
				local moveXY = monsterRef.moveXY
				local posX,posY
				local posArr = string.split(moveXY,",")
				posX = tonumber(posArr[1])
				posY = tonumber(posArr[2])
				paintTans.localPosition = Vector2.New(posX,posY)
				dpSpine:SetScale(scale)
				if(isSurvive)then
					dpSpine:SetColor(Color.New(1, 1, 1, 1))
				else
					dpSpine:SetColor(Color.New(0.5, 0.5, 0.5, 1))
				end
			end)
			self._oldSpineKey = key
		else
			if(isSurvive)then
				spine:SetColor(Color.New(1, 1, 1, 1))
			else
				spine:SetColor(Color.New(0.5, 0.5, 0.5, 1))
			end
		end

	end
end

function UIGdBravePop:RefreshData()
	local braveInfo=gModelGuild:GetGuildBraveInfo()
	local guildInfo=gModelGuild:GetSelfGuildInfo()
	if(guildInfo.position==1 or guildInfo.position==2)then
		CS.ShowObject(self.mMassBtn,true)
	else
		CS.ShowObject(self.mMassBtn,false)
	end
	self._braveInfo=braveInfo
	local ref=gModelGuild:GetGuildDungeonMonsterRefByRefId(braveInfo.braveId)
	self:SetWndText(self.mTitleText,string.replace(ccClientText(14100),ref.refId,ccLngText(ref.chapterName)))
	if(ref.showBG and ref.showBG~="")then
		self:SetWndEasyImage(self.mBgImage,ref.showBG)
	end
	local bossMaxHp,bossCurHp
	local hHp = tonumber(braveInfo.currentHp)
	for i, v in ipairs(braveInfo.hurtRankCount) do
		hHp = hHp + tonumber(v)
	end
	if(hHp>ref.monsterBoss)then
		bossMaxHp = hHp
		bossCurHp = tonumber(braveInfo.currentHp)
	else
		bossMaxHp=gModelGuild:GetBossMaxHP(ref.monsterBoss)
		bossCurHp = tonumber(braveInfo.currentHp)
	end
	local isSurvive = bossCurHp > 0
	CS.ShowObject(self.mBossHPBar,isSurvive)
	CS.ShowObject(self.mBossHPText,isSurvive)
	CS.ShowObject(self.mChallengeBtn,isSurvive)
	CS.ShowObject(self.mSweepBtn,isSurvive)
	CS.ShowObject(self.mPursueBtn,not isSurvive)
	CS.ShowObject(self.mBossTimeBg,not isSurvive)
	CS.ShowObject(self.mDefeatImg,not isSurvive)
	local _bossTimeKey = self._bossTimeKey
	if isSurvive then
		self.mBossHPBar.maxValue = bossMaxHp
		self.mBossHPBar.value=bossCurHp
		local bossHp = math.floor(tonumber(braveInfo.currentHp)/bossMaxHp*1000)
		if bossHp <= 0 then
			bossHp = 1
		end
		local hpPercentum = (bossHp/10).."%"
		self:SetWndText(self.mBossHPText,hpPercentum)
		if self:IsTimerExist(_bossTimeKey)then
			self:TimerStop(_bossTimeKey)
		end
	else
		self:SetTime()
		if not self:IsTimerExist(_bossTimeKey)then
			self:TimerStart(_bossTimeKey,1,false,-1)
		end
	end

	local rewardList= gModelGeneral:GetParseItem_3List(ref.showReward)

	local awardEasyIconList = self._awardEasyIconList
	if not awardEasyIconList then
		awardEasyIconList = UIIconEasyList:New()
		self._awardEasyIconList = awardEasyIconList
		awardEasyIconList:Create(self, self.mAwardScroll)
	end
	awardEasyIconList:RefreshList(rewardList)

	local challengeNum=gModelGuild:GetVipBraveAddNum(1)--免费挑战次数
	local battleCount=challengeNum-braveInfo.battleCount+braveInfo.battleBuyCount+braveInfo.extraCount
	local battleCount = battleCount >= 0 and battleCount or 0
	local guyNum=gModelGuild:GetVipBraveAddNum(2)
	self:SetWndText(self.mBuyText,string.replace(ccClientText(14132),guyNum-braveInfo.battleBuyCount))
	self:SetWndText(self.mNumText,string.replace(ccClientText(14101),battleCount))
	self:SetBossPaint(self.mBossImage,ref,isSurvive)

	local logList= {}
	for i, v in ipairs(braveInfo.hurtRankName) do
		local log={
			hurtRankName=v,
			hurtRankCount=braveInfo.hurtRankCount[i],
		}
		logList[i]=log
	end
	for i = #logList+1, 3 do
		local log={
			hurtRankName=ccClientText(14118),
			hurtRankCount=0,
		}
		logList[i]=log
	end
	if(self._uiLogList)then
		self._uiLogList:RefreshList(logList)
	else
		self._uiLogList = self:GetUIScroll("_uiLogList")
		self._uiLogList:Create(self.mRankScroll,logList,function (...) self:LogListItem(...) end)
	end
	self:ShowInspireTime()

	if(tonumber(braveInfo.lastHurtCount)>=0)then
		--self:SetWndClick(self.mSweepBtn, function(...) gModelGuild:OnClickSweep() end)
	end
	self:SetWndButtonGray(self.mSweepBtn,braveInfo.lastHurtCount < 0)
	if(self._bSweep)then
		self._bSweep=false
		if(braveInfo.lastHurtCount>=0)then
			--gModelGuild:OnClickSweep()
		else
			GF.ShowMessage(ccClientText(14130))
		end
	end
end

---延迟执行----------------------------------------------------------------------
function UIGdBravePop:OnTimerFun()
	self:ShowInspireTime()
end

function UIGdBravePop:InitEvent()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function (index)
		if index == 4 then self:OnClickCloseWnd() end
	end)
	self:SetWndClick(self.mCloseBtn, function(...) self:OnClickCloseWnd() end)
	self:SetWndClick(self.mHelfBtn, function(...) self:OnClickHelf() end)
	self:SetWndClick(self.mLogBtn, function(...) self:OnClickLog() end)
	self:SetWndClick(self.mMassBtn, function(...) self:OnClickMass() end)
	self:SetWndClick(self.mInspireMange, function(...) self:OnClickInspire() end)
	self:SetWndClick(self.mAwardBtn, function(...) self:OnClickAwardDes() end)
	self:SetWndClick(self.mChallengeBtn, function(...) self:OnClickChallenge() end)
	self:SetWndClick(self.mPursueBtn, function(...) self:OnClickChase() end)
	self:SetWndClick(self.mAddNumBtn, function(...) self:OnClickAddNum() end)
	self:SetWndClick(self.mDesBtn, function(...) self:OnClickDes() end)
end

function UIGdBravePop:OnClickLog()
	GF.OpenWnd("UIGdBraveLogPop")
end

function UIGdBravePop:OnClickCloseWnd()
	if not self:WndCloseAndBack() then
		GF.OpenWnd("UIGdWin")
	end
end

function UIGdBravePop:LogListItem(list,item, itemdata, itempos)
	local rankIcon=CS.FindTrans(item,"Image")
	local nameText=CS.FindTrans(item,"NameText")
	local desText=CS.FindTrans(item,"DesText")

	if(itempos==1)then
		self:SetWndEasyImage(rankIcon,"public_num_1")
	elseif(itempos==2)then
		self:SetWndEasyImage(rankIcon,"public_num_2")
	else
		self:SetWndEasyImage(rankIcon,"public_num_3")
	end
	self:SetWndText(nameText,itemdata.hurtRankName)

	local num = LUtil.NumberCoversion(itemdata.hurtRankCount)
	self:SetWndText(desText,"["..string.replace(ccClientText(14112),num).."]")
end

function UIGdBravePop:InitMessage()
	--self:WndNetMsgRecv(LProtoIds.GuildBraveResp,function (...)
	--	self:RefreshData()
	--end)
	self:WndNetMsgRecv(LProtoIds.GuildBraveBuffResp,function (...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildBraveChangeResp,function (...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildBraveChaseResp,function (...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildBuyResp,function (pb)
		if(pb.buyType==2)then
			self:RefreshData()
		end
	end)
	self:WndEventRecv(EventNames.ON_GUILD_BRAVE_SWEEP,function()
		self._bSweep=true
		self:RefreshData()
	end)
	--self:WndEventRecv(EventNames.ON_TIME_ZERO,function()
	--	gModelGuild:OnGuildBraveReq()
	--end)
end

function UIGdBravePop:SetTime()--设置时间
	local endTime = LUtil.GetNextDayTimes(nil,1)
	local timespan = endTime - GetTimestamp()
	if(timespan <= 0)then
		self:TimerStop(self._bossTimeKey)
		return
	end
	local timeStr = LUtil.FormatTimeToCn3(timespan)
	self:SetWndText(self.mBossTimeText,string.replace(ccClientText(14139),timeStr))
end

function UIGdBravePop:StartDelayTimerClose(time)
	self:ClearTimerClose()
	if time<=0 then
		self:OnTimerFun()
		return
	end
	if self._timerClose == nil then
		local iTimeOut = time
		self._timerClose = LxTimer.DelayTimeCall(function()
			self:OnTimerFun()
		end, iTimeOut)
	end
end

function UIGdBravePop:OnClickHelf()
	GF.OpenWnd("UIBzTips",{refId=38})
end

function UIGdBravePop:InitCommand()
	self:SetWndText(self.mBtnAwardText,ccClientText(14105))
	self:SetWndText(self.mInspireText,ccClientText(14135))
	self:SetWndButtonText(self.mChallengeBtn,ccClientText(14103))
	self:SetWndButtonText(self.mSweepBtn,ccClientText(14104))
	self:SetWndButtonText(self.mPursueBtn,ccClientText(14138))
	self:SetWndText(self.mAwardText,ccClientText(14109))
	self:SetWndText(self.mRankText,ccClientText(14110))
	local btnText=CS.FindTrans(self.mDesBtn,"UIText")
	self:SetWndText(btnText,ccClientText(14111))
	local text = CS.FindTrans(self.mLogBtn,"text")
	self:SetWndText(text,ccClientText(14136))
	local text = CS.FindTrans(self.mMassBtn,"text")
	self:SetWndText(text,ccClientText(14137))
	--gModelGuild:OnGuildBraveReq()
end

function UIGdBravePop:OnTimer(key)
	if(self._bossTimeKey == key)then
		self:SetTime()
	end
end

function UIGdBravePop:OnClickAddNum()--点击添加挑战次数
	--gModelGuild:SetGuyNumPop(2)
end

function UIGdBravePop:OnClickMass()
	GF.OpenWnd("UIOrdinTip",{refId=100015,func=function (...)
		gModelGuildBoss:OnGuildCallMemberReq()
	end })
end

function UIGdBravePop:OnClickAwardDes()--点击奖励详情
	GF.OpenWnd("UIGdBraveAwardPop",{refId=self._braveInfo.braveId})
end

function UIGdBravePop:ShowInspireTime()--设置鼓舞时间
	local buffTime= tonumber(self._braveInfo.buffTime)
	if(buffTime<=0)then
		self:SetWndText(self.mInspireArrt,ccClientText(14117))
		self:SetWndText(self.mInspireTime,ccClientText(14116))
		return
	end
	local time=GetTimestamp()
	local timespan= buffTime/1000-time
	local h=math.floor(timespan/3600)
	local m=math.floor(timespan/60)%60
	local s=math.floor(timespan)%60
	local timeStr= string.format("%02d:%02d:%02d",h,m,s)
	if(h>0 or m>0 or s>0)then
		self:SetWndText(self.mInspireArrt,string.replace(ccClientText(14108),gModelGuild:GetBuffAttr()))
		self:SetWndText(self.mInspireTime,string.replace(ccClientText(14106),timeStr))
		self:StartDelayTimerClose(1)
		return
	end
	self:SetWndText(self.mInspireTime,"")
end

function UIGdBravePop:OnClickChase()
	local braveInfo = self._braveInfo
	local challengeNum = gModelGuild:GetVipBraveAddNum(1)--免费挑战次数
	local battleCount = challengeNum - braveInfo.battleCount + braveInfo.battleBuyCount + braveInfo.extraCount
	local guyNum=gModelGuild:GetVipBraveAddNum(2)
	local battleCount = battleCount >= 0 and battleCount or 0
	local buyNum = guyNum-braveInfo.battleBuyCount
	if battleCount <= 0 and buyNum <= 0 then
		GF.ShowMessage(ccClientText(14147))
		return
	end
	GF.OpenWnd("UIGdBraveChasePop")
end

function UIGdBravePop:OnClickChallenge()--点击挑战
	if(not self._braveInfo)then
		return
	end
	local battleCount=self._braveInfo.battleCount
	local battleBuyCount=self._braveInfo.battleBuyCount
	local challengeNum=gModelGuild:GetVipBraveAddNum(1)--免费挑战次数
	if(battleCount-(challengeNum+battleBuyCount+self._braveInfo.extraCount)>=0)then
		--gModelGuild:SetGuyNumPop(1)
		return
	end
	--self:WndClose()
	--GF.CloseWndByName("UIGdWin")
	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_GUILD_BRAVE,{})
end
------------------------------------------------------------------
return UIGdBravePop


