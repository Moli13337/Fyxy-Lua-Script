---
--- Created by Administrator.
--- DateTime: 2023/10/21 22:20:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaBirth:LWnd
local UISagaBirth = LxWndClass("UISagaBirth", LWnd)
local typeof = typeof
local typeSpineClick = typeof(CS.SpineClick)


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaBirth:UISagaBirth()
	---@type CommonIcon
	self._itemIconCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaBirth:OnWndClose()
	if self._itemIconCls then
		self._itemIconCls:Destroy()
		self._itemIconCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaBirth:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaBirth:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mRewardTxt,ccClientText(10122))
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:Refresh()
end

function UISagaBirth:InitData()
	self._refId = self:GetWndArg("refId")
end

function UISagaBirth:OnDrawDesc(list, item, itemdata, itempos, fromHeadTail)
	local textTrans = CS.FindTrans(item,"text")
	if textTrans then
		self:SetWndText(textTrans,ccLngText(itemdata))
	end
end


function UISagaBirth:OnSpineLoaded(spine,refId)

	spine:SetAnimationCompleteFunc(function()
		spine:PlayAnimation(0,"idle",true)
	end)

	local spineTrans = spine:GetSpineTrans()
	local spineClick = spineTrans:GetComponent(typeSpineClick)
	if not spineClick then
		spineClick = spineTrans.gameObject:AddComponent(typeSpineClick)
		spineClick.isUISpine = true
	end

	spineClick.onClick = function()
		local nowPlayAniName = spine:GetCurTrackEntryName()
		if nowPlayAniName == nil or nowPlayAniName == "idle" then

			local starRef = gModelHero:GetHeroStarRef(refId)
			local commonSkill,activeSkillGroup = starRef.commonSkill,starRef.activeSkillGroup
			local tempSkillList = {}
			table.insert(tempSkillList,commonSkill)
			activeSkillGroup = string.split(activeSkillGroup,",")
			for i,v in ipairs(activeSkillGroup) do
				local temp = string.split(v,"=")
				table.insert(tempSkillList,tonumber(temp[1]))
			end
			math.randomseed(tostring(os.time()):reverse():sub(1, 7))
			local rang = math.random(1, #tempSkillList)
			local skillId = tempSkillList[rang]
			local skillEffIdList = gModelHero:GetSkillShowEffListBySkillRefId(skillId)
			local skillShowEff = #skillEffIdList > 0  and  skillEffIdList[1] or 0
			local skillExpRef = GameTable.SnakeSkillExpressionRef[skillShowEff]
			if not skillExpRef then
				spine:PlayAnimation(0,"attack1",false)
				return
			end
			local panelPlayEff = skillExpRef.panelPlayEff
			if not string.isempty(panelPlayEff) then
				local arrPlayEffId = string.split(panelPlayEff or "","|") or {}
				local playEffList = {}
				for k,strId in ipairs(arrPlayEffId) do
					local arrPlayRefId = tonumber(strId)
					local skillVfxRef = GameTable.SnakeSkillVfxRef[arrPlayRefId]
					local delayTime = skillVfxRef.delayTime
					local playTime = skillVfxRef.playTime
					local data = {refId = arrPlayRefId,effType = skillVfxRef.effType,effRef = skillVfxRef.effRes,delayTime = delayTime,playTime = playTime,}
					table.insert(playEffList,data)
				end
				self:PlaySkillShow(playEffList,spine)
			else
				spine:PlayAnimation(0,"attack1",false)
			end
		end
	end
end


function UISagaBirth:InitScrollView(description)
	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mDescList)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawDesc(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	uiList:AddData(1,description)
	uiList:RefreshList()
end

function UISagaBirth:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISagaBirth:Refresh()
	local refId = self._refId
	local ref = gModelHero:GetHeroRef(refId)
	local heroBookList = gModelHero:GetHeroBookList()
	local serData = heroBookList[refId]
	if ref then
		local initStar = ref.initStar
		local bookFirstReward = ref.bookFirstReward
		local showReward = false
		if serData and serData == 0 then showReward = true end
		if (not string.isempty(bookFirstReward)) and showReward then
			local strList = string.split(bookFirstReward,"=")
			local itemRefId,num = tonumber(strList[2]),tonumber(strList[3])

			local baseClass = self._itemIconCls
			if not baseClass then
				baseClass = CommonIcon:New()
				self._itemIconCls = baseClass
				baseClass:Create(self.mItemIcon)
			end
			baseClass:SetCommonReward(LItemTypeConst.TYPE_ITEM, itemRefId, num)
			baseClass:EnableShowNum(true)
			baseClass:DoApply()

			self:SetIconClickScale(self.mItemIcon, true)
			self:SetWndClick(self.mItemIcon,function()
				if showReward then
					gModelHero:OnHeroBookRewardOldReq(refId)
				end
			end)
			CS.ShowObject(self.mItemIcon,showReward)
			CS.ShowObject(self.mRewardTxt,showReward)
		else
			CS.ShowObject(self.mItemIcon,showReward)
			CS.ShowObject(self.mRewardTxt,showReward)
		end

		local effId = gModelHero:GetHeroEffectByRefId(refId,initStar)
		local heroEffectRef = gModelHero:GetShowEffectById(effId)

		local prefabName = heroEffectRef.prefabName
		self:CreateWndSpine(self.mPbPos,prefabName,prefabName,false,function(dpSpine)
			self:OnSpineLoaded(dpSpine,refId)
		end)

		local description = heroEffectRef.description
		self:InitScrollView(description)

		local heroName = ccLngText(heroEffectRef.name)
		self:SetXUITextText(self.mHeroName,heroName)

		local nickName = ccLngText(heroEffectRef.nickName)
		self:SetXUITextText(self.mNickName,"")
	end
end

function UISagaBirth:PlaySkillShow(playList,spine)
	local maxTime = 0
	for i,v in ipairs(playList) do
		v.isPlay = false
		if maxTime < v.playTime then maxTime = v.playTime end
	end
	table.sort(playList,function(eff1,eff2)
		return eff1.delayTime < eff2.delayTime
	end)
	local dpTrans = spine:GetDisplayTrans()
	LxTimer.LoopTimeStop(self._playEffTime)
	local starTime
	self._playEffTime = LxTimer.LoopTimeCall(function()
		if starTime == nil then
			starTime = Time.time
		end
		for i,v in ipairs(playList) do
			local time = Time.time
			local tempTime = time - starTime
			if tempTime >= v.delayTime and (not v.isPlay) then
				v.isPlay = true
				if v.effType == 2 then
					spine:PlayAnimation(0,v.effRef,false)
				else
					self:CreateWndEffect(dpTrans,v.effRef,v.effRef,100,false,false)
				end
				printInfoN("=========== v.effRef = ",v.effRef,v.refId)
			end
			if tempTime > maxTime then
				LxTimer.LoopTimeStop(self._playEffTime)
				self._playEffTime = nil
				self:DestroyWndEffectAll()
			end
		end
	end,0,false,-1)
end

function UISagaBirth:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeroBookResp,function()
		local heroBookList = gModelHero:GetHeroBookList()
		local serData = heroBookList[self._refId]
		local showReward = false
		if serData and serData == 0 then showReward = true end
		CS.ShowObject(self.mItemIcon,showReward)
		CS.ShowObject(self.mRewardTxt,showReward)
	end)
end
------------------------------------------------------------------
return UISagaBirth


