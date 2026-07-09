---
--- Created by Administrator.
--- DateTime: 2025/6/6 15:01:30
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandWearPop:LWnd
local UIBrandWearPop = LxWndClass("UIBrandWearPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandWearPop:UIBrandWearPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandWearPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandWearPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandWearPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI({
		refId = 50000,
		IntroTran = self.mEmptyText,
		IconTran = self.mEmptyIcon,
		TextBgTran = self.mEmptyTextBg,
		GetBtn = self.mGetBtn,
		GetBtnText = self.mGetBtnTxt,
		ButtonRoot = self.mGetBtn,
	})

	self:OnClickEvent()
	self:InitData()
	self:InitWear()
	self:InitTabList()
	self:InitEmptyPosList()
	self:InitBadgeList()
	self:RefreshWear()
end

function UIBrandWearPop:OnClickBadgeIcon(index,badgeId)
	local isLock,str= gModelBadge:IsLockBadgeSlot(self.heroId,self.curType,index)
	if isLock then--已解锁
		self.selWearIndx = index
		self:RefreshWear()
		if badgeId then --已装配

		else--可装配

		end
	else--未解锁
		GF.ShowMessage(str)
	end
end

function UIBrandWearPop:InitTalentTransInfo(item)
	local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
	local Lock = self:FindWndTrans(IconTrans,"Lock")
	return {
		IconTrans = IconTrans,
		Empty = self:FindWndTrans(IconTrans,"Empty"),
		LockDiv = Lock,
		LockTxt = self:FindWndTrans(Lock,"LockMask/LockTxt"),
		redPoint = self:FindWndTrans(item,"CommonUI/redPoint"),
		ImgSel = self:FindWndTrans(item,"CommonUI/ImgSel"),
	}
end

function UIBrandWearPop:InitWear()
	local talentTransInfoList = {}
	local talentTransList = {self.mTalent1,self.mTalent2,self.mTalent3,self.mTalent4,
							 self.mTalent5,self.mTalent6,self.mTalent7,self.mTalent8}
	for i,v in ipairs(talentTransList) do
		table.insert(talentTransInfoList,self:InitTalentTransInfo(v))
	end
	self._talentTransInfoList = talentTransInfoList
end

function UIBrandWearPop:OnClickEvent()
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
	self:WndEventRecv(EventNames.BADGE_BAG_UPDATE_WEAR,function()
		if self._autoSelNext then
			self:InitEmptyPosList()
			local emptyPosList = self._emptyPosList
			if emptyPosList and #emptyPosList > 0 then
				if not self._emptyPosMap[self.selWearIndx] then
					self.selWearIndx = emptyPosList[1]
				else
					local minPos = emptyPosList[1]
					if minPos < self.selWearIndx then
						self.selWearIndx = minPos
					end
				end
			end
		end

		self:InitBadgeList()
		self:RefreshWear()
	end)
end

function UIBrandWearPop:InitEmptyPosList()
	local emptyPosMap = {}
	local emptyPosList = {}
	local heroId = self.heroId
	local curType = self.curType
	local badges = gModelBadge:GetHeroWearBadges(heroId) or {}
	local count = #self._talentTransInfoList
	for i = 1,count do
		if not badges[i] and gModelBadge:IsLockBadgeSlot(heroId,curType,i) then
			table.insert(emptyPosList,i)
			emptyPosMap[i] = true
		end
	end
	self._emptyPosMap = emptyPosMap
	self._emptyPosList = emptyPosList
end

function UIBrandWearPop:RefreshWear()
	local talentTransInfoList = self._talentTransInfoList
	local badges = gModelBadge:GetHeroWearBadges(self.heroId) or {}
	local badgeId = nil
	for i,v in ipairs(talentTransInfoList) do
		badgeId = badges[i]
		local baseClass
		if badgeId then--有穿戴
			baseClass = self:GetCommonIcon(v.IconTrans)
			baseClass:Create(v.IconTrans)
			baseClass:SetCommonReward(LItemTypeConst.TYPE_BADGE, badgeId)
			baseClass:EnableShowNum(false)
			baseClass:DoApply()
		else
			self:DeleteCommonIcon(v.IconTrans)
			local isLock,str= gModelBadge:IsLockBadgeSlot(self.heroId,self.curType,i)
			CS.ShowObject(v.Empty,isLock)
			CS.ShowObject(v.LockDiv,not isLock)
			if not isLock then --未解锁
				self:SetWndText(v.LockTxt,str)
			end
		end
		CS.ShowObject(v.ImgSel,self.selWearIndx == i)
		self:SetWndClick(v.IconTrans,function() self:OnClickBadgeIcon(i,badges[i]) end)
	end
end

function UIBrandWearPop:InitTabList()
	local uiList = self:GetUIScroll("badgeWearPop")
	uiList:Create(self.mTabScroll,self._tabDatas,function(...) self:OnDrawTab(...) end)
	self._tabUiList = uiList
end

function UIBrandWearPop:InitEmptyShow(isShow)
	CS.ShowObject(self.mEmptyTips,isShow)
	if not isShow then return end
	--CS.ShowObject(self.mGetBtn, true)
end

function UIBrandWearPop:DoChangeTab(index)
	if self.selTabIndx == index then return end
	self.selTabIndx = index
	self:InitTabList()
	self:InitBadgeList()
end

function UIBrandWearPop:InitData()
	self.heroId = self:GetWndArg("heroId")
	self.selWearIndx = self:GetWndArg("index") or 1
	self.curType = 1--暂只有类型1
	self.selTabIndx = 1
	local heroData = gModelHero:GetHeroById(self.heroId)
	local heroCfg= GameTable.CharacterEffectRef[heroData._refId]
	self:SetWndText(self.mTxtTitle,ccClientText(47563))
	self:SetWndText(self.mTxtName,ccLngText(heroCfg.name))
	---@type table<number,number> slot=badgeId
	self.wearBadges = gModelBadge:GetHeroWearBadges(self.heroId) or {}

	self._tabDatas = {
		{skillType = 0,icon ="public_race_0", name=""},
		{skillType = 1,icon ="jewelry_job_2", name=""},
		{skillType = 2,icon ="jewelry_job_1", name=""},
		{skillType = 3,icon ="jewelry_job_3", name=""},
	}
	local list = gModelBadge.badgeBagList
	self.badgeList = {}--skillType = table
	local ref = nil
	local allList = {}
	for _, badge in pairs(list) do
		ref = badge:GetBadgeRef()
		if not self.badgeList[ref.skillType] then self.badgeList[ref.skillType] = {} end
		table.insert(self.badgeList[ref.skillType],badge)
		table.insert(allList,badge)
	end
	local aRef,bRef = nil,nil
	for _, badgeList in pairs(self.badgeList) do
		table.sort(badgeList,function(a, b)
			if a.wearNum~=b.wearNum then
				return a.wearNum>b.wearNum
			else
				aRef = a:GetBadgeRef()
				bRef = b:GetBadgeRef()
				if aRef.quality~=bRef.quality then
					return aRef.quality>bRef.quality
				else
					if a:GetBadgeStar()~=b:GetBadgeStar() then
						return a:GetBadgeStar()>b:GetBadgeStar()
					else
						if a:CanWearNum()~=b:CanWearNum() then
							return a:CanWearNum()>b:CanWearNum()
						else
							return a.refId<b.refId
						end
					end
				end
			end
		end)
	end
	self.badgeList[self._tabDatas[1].skillType] = allList

	local autoSelNext = GameTable.BadgeConfigRef.autoSelNext
	if not autoSelNext then
		autoSelNext = 1
		if LOG_INFO_ENABLED then
			printInfoNR("默认自动选择，如需要取消，请配置字段 autoSelNext 为 0")
		end
	end
	self._autoSelNext = autoSelNext == 1
end

function UIBrandWearPop:OnDrawTab(list, item, itemData, index)
	-- self:SetWndTabText(item,itemData.name,nil,nil)
	self:SetWndTabStatus(item, self.selTabIndx == index and 0 or 1)
	local icon = itemData.icon
	self:SetWndTabIcon(item,icon,icon)
	-- self._tabList[index] = item
	self:SetWndClick(item, function (...) self:DoChangeTab(index) end)
end

function UIBrandWearPop:OnDrawBadgeCell(list, item, itemdata, itempos)
	CS.ShowObject(item,true)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		local aniRootTrans = self:FindWndTrans(item, "AniRoot")
		itemCache = {
			aniRootTrans = aniRootTrans,
			TxtWearNum = self:FindWndTrans(aniRootTrans, "TxtWearNum"),
			TxtName = self:FindWndTrans(aniRootTrans, "TxtName"),
			TxtDesc = self:FindWndTrans(aniRootTrans, "TxtDesc"),
			Icon = self:FindWndTrans(aniRootTrans, "Icon"),
			BtnWear = self:FindWndTrans(aniRootTrans, "BtnWear"),
			ImgSel = self:FindWndTrans(aniRootTrans, "ImgSel"),
		}
		self:SetComponentCache(instanceID,itemCache)
	end
	local refId = itemdata.refId
	local wearSlot = gModelBadge:GetBadgeIdWearPos(self.heroId,refId)
	CS.ShowObject(itemCache.ImgSel,false)

	local ref = GameTable.BadgeRef[refId]
	local starCfg = itemdata:GetStarRef()
	local baseClass = self:GetCommonIcon(itemCache.Icon)
	baseClass:Create(itemCache.Icon)
	baseClass:SetCommonReward(LItemTypeConst.TYPE_BADGE, refId,1)
	baseClass:EnableShowNum(false)
	baseClass:SetShowGouImg(wearSlot and true or false)
	baseClass:DoApply()

	local color = (starCfg.wearNum<0 or starCfg.wearNum-itemdata.wearNum>0) and "#0f6f23"  or "#b20000"
	self:SetWndText(itemCache.TxtWearNum,string.replace(ccClientText(47562),color,itemdata.wearNum,starCfg.wearNum>0 and starCfg.wearNum or ccClientText(47551)))
	self:SetWndText(itemCache.TxtName,ccLngText(ref.name))
	local color = gModelItem:GetColorByQualityId(ref.quality)
	if color then
		local naneTxt = self:FindWndText(itemCache.TxtName)
		self:SetXUITextColor(naneTxt, color)
	end

	local txtDesc = ""
	local skillCfg = gModelSkill:GetSkillRef(starCfg.skill)
	if skillCfg then
		txtDesc = ccLngText(skillCfg.description)
	end
	self:SetWndText(itemCache.TxtDesc,txtDesc)

	self:SetWndEasyImage(itemCache.BtnWear,wearSlot and "draconic_cell_15" or "formation_up")
	self:SetWndClick(itemCache.BtnWear,function()
		if wearSlot then
			gModelBadge:BadgeWearReq(2,self.heroId,{slot = wearSlot,refId = refId})--卸下
		else
			if self.selWearIndx>0 then
				local ownWear = itemdata:CanWearNum()
				if ownWear>0 or ownWear<0 then
					gModelBadge:BadgeWearReq(1,self.heroId,{slot = self.selWearIndx,refId = refId})--装配
				else
					--抢来穿
					GF.OpenWnd("UIBrandWearReplace",{refId = refId,heroId = self.heroId,index = self.selWearIndx})
				end
			end
		end
	end)
	self:SetWndClick(itemCache.Icon,function()
		GF.OpenWnd("UIBrandTips",{from = false,refId = refId,noShowBtn=true})
	end)
end

function UIBrandWearPop:InitBadgeList()
	local skillType = self._tabDatas[self.selTabIndx].skillType
	local list = self.badgeList[skillType] or {}
	local petList = self._badgeList
	local superList
	if not petList then
		petList = self:GetUIScroll("mBadgeList")
		self._badgeList = petList
		petList:Create(self.mBadgeList, list, function(...)
			self:OnDrawBadgeCell(...)
		end, UIItemList.SUPER_GRID, false)
		superList = petList:GetList()
	else
		petList:RefreshList(list)
		superList = petList:GetList()
		superList:DrawAllItems()
	end
	-- superList:MoveToPos(moveIndx)
	self:InitEmptyShow(#list<=0)
end
------------------------------------------------------------------
return UIBrandWearPop