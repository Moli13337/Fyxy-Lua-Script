---
--- Created by Administrator.
--- DateTime: 2023/10/25 18:27:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaResSel:LWnd
local UISagaResSel = LxWndClass("UISagaResSel", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaResSel:UISagaResSel()
	---@type table<number,CommonIcon>
	self._iconHeroClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaResSel:OnWndClose()
	self:ClearCommonIconList(self._iconHeroClsList)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaResSel:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaResSel:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:SetWndText(self.mTitle,ccClientText(14707))
	self:SetWndButtonText(self.mCancelBtn, ccClientText(14422))
	self:SetWndButtonText(self.mEnterBtn, ccClientText(10102))
	self:SetWndText(self.mDesc,ccClientText(14706))
	self:InitEvent()
	self:InitMsg()
	local data = {
		refId = 2001,
		IntroTran = self.mEmptyText,
		IconTran = self.mEmptyIcon,
		TextBgTran = self.mEmptyTextBg
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)

	self:InitHeroList()
end

function UISagaResSel:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCancelBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mAllRaceBtn,function() self:TypeBtnEvent(0) end,LSoundConst.CLICK_PAGE_COMMON)
	for i,v in ipairs(self._typeBtbList) do
		self:SetWndClick(v,function() self:TypeBtnEvent(i) end,LSoundConst.CLICK_PAGE_COMMON)
	end
	self:SetWndClick(self.mEnterBtn,function()
		if string.isempty(self._selectId) then
			GF.ShowMessage(ccClientText(14733))
			return
		end
		gModelResonance:OnResonanceHeroReq(self._selectId,self._pos,1)
	end)
end

function UISagaResSel:OnDrawHeroCell(list, item, itemdata, itempos, fromHeadTail)
	local heroIconTrans = CS.FindTrans(item,"HeroIcon")
	if heroIconTrans then
		local id = itemdata.id
		local lv = itemdata.lv
		local refId = itemdata.refId

		local instanceId = item:GetInstanceID()
		local baseClass = self._iconHeroClsList[instanceId]
		if not baseClass then
			baseClass = CommonIcon:New(self)
			self._iconHeroClsList[instanceId] = baseClass
			baseClass:Create(heroIconTrans)
			self:SetIconClickScale(heroIconTrans, true)
		end
		baseClass:SetHeroPlayer(id)
		baseClass:SetShowGouImg(self._selectId == id)
		baseClass:DoApply()

		self:SetWndClick(heroIconTrans,function()
			--printInfoN("=============== refId = ",itemdata.refId)
			self._oldLv = lv
			local old = self._selectId
			if old == id then
				self._selectId = ""
				if self._uiList then self._uiList:DrawItemByKey(old) end
			else
				self._selectId = id
				if not string.isempty(old) then
					if self._uiList then self._uiList:DrawItemByKey(old) end
				end
				if self._uiList then self._uiList:DrawItemByKey(id) end
			end
		end)
		self:SetWndLongClick(heroIconTrans,function()
			local data = {
				id = id,
				refId = refId,
				level = lv,
				star = itemdata.star,
				grade = itemdata.grade,
				fightPower = itemdata.fightPower,
				isResonance = itemdata.isResonance,
				skin = itemdata.skin,
			}
			gModelHero:ReqShowHeroTip("",data)
		end,0.8,false)
	end
end

function UISagaResSel:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ResonanceHeroResp, function(pb,ret)
		if pb.opera == 1 then
			local oldHero = pb.oldHero
			local newHero = pb.newHero
			local heroId = pb.heroId
			GF.OpenWndUp("UIReeResult",{heroId = heroId,oldHero = oldHero,newHero = newHero})
		end
		self:WndClose()
	end)
end

function UISagaResSel:InitData()
	self._resonanceList = self:GetWndArg("resonanceList")
	self._resonanceLevel = self:GetWndArg("resonanceLevel")
	self._pos = self:GetWndArg("pos")
	self._type = 0
	self._typeBtbList = {
		self.mRaceBtn1,
		self.mRaceBtn2,
		self.mRaceBtn3,
		self.mRaceBtn4,
		self.mRaceBtn5,
	}
	self._selectId = ""
	self._oldLv = 0
end

function UISagaResSel:InitHeroList()
	CS.ShowObject(self.mHeroList,true)
	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mHeroList)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawHeroCell(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	local selectHeroList = {}
	local heroList = gModelHero:GetHeroList()
	for k,v in pairs(heroList) do
		local hero = v:GetServerData()
		local refId = hero.refId
		local id = hero.id
		if not self._resonanceList[id] then
			local lv = hero.lv
			if lv < self._resonanceLevel and not hero.isTry then
				if not gModelSpiritHero:CheckIsSpiritHero(refId) then
					local ref = gModelHero:GetHeroRef(refId)
					if ref then
						local race = ref.raceType
						if self._type == 0 then
							table.insert(selectHeroList,hero)
						elseif self._type == race then
							table.insert(selectHeroList,hero)
						end
					end
				end
			end
		end
	end
	table.sort(selectHeroList,function(hero1,hero2)
		local star1,star2 = hero1.star,hero2.star
		if star1 ~= star2 then
			return star1 > star2
		else
--[[			local refId1,refId2 = hero1.refId,hero2.refId
			--
			--local race1=gModelHero:GetHeroRaceRefByRefId(refId1)
			--local race2=gModelHero:GetHeroRaceRefByRefId(refId2)


			local ref1 = gModelHero:GetHeroRef(refId1)
			local ref2 = gModelHero:GetHeroRef(refId2)

			local rank1=gModelHero:GetHeroRaceRefRank(ref1.raceType)
			local rank2=gModelHero:GetHeroRaceRefRank(ref2.raceType)
			if rank1 ~= rank2 then
				return rank1 < rank2
			else
				return hero1.lv > hero2.lv
			end]]

			--- UISagaResSel
			--- 这里头像排序优化下：
			--- 星级高的>初始星级高的>英雄 refId~
			local initStarA = gModelHero:GetHeroInitStarByRefId(hero1.refId) or 0
			local initStarB = gModelHero:GetHeroInitStarByRefId(hero2.refId) or 0
			if initStarA ~= initStarB then
				return initStarA > initStarB
			end
			return hero1.refId > hero2.refId
		end
	end)
	if table.isempty(selectHeroList) then
		CS.ShowObject(self.mNoRecord,true)
	else
		CS.ShowObject(self.mNoRecord,false)
		for i,v in ipairs(selectHeroList) do
			local id = v.id
			uiList:AddData(id,v)
		end
	end
	uiList:RefreshList()
end

function UISagaResSel:TypeBtnEvent(index)
	if self._type == index then return end
	if index == 0 then
		CS.SetParentTrans(self.mRaceSelImg,self.mAllRaceBtn)
	else
		CS.SetParentTrans(self.mRaceSelImg,self._typeBtbList[index])
	end
	self._type = index
	self:InitHeroList()
end
------------------------------------------------------------------
return UISagaResSel


