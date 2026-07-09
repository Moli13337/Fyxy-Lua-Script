---
--- Created by Administrator.
--- DateTime: 2023/10/10 16:14:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReJNRecommend:LWnd
local UIReJNRecommend = LxWndClass("UIReJNRecommend", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReJNRecommend:UIReJNRecommend()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReJNRecommend:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReJNRecommend:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReJNRecommend:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitStaticContent()
	self:InitData()
	self:InitEvent()
	self:InitMsg()

	self:TryGetRecommendData()
end

function UIReJNRecommend:TryGetRecommendData()
	local refId = self._refId
	self._hotDataMap = {}
	if refId then
		local heroRef = gModelHero:GetHeroRef(refId)
		if heroRef and heroRef.quality >= 6 then -- 传说已经神话才需要显示热门数据
			local hotData = gModelGeneral:OnGetHeroRecommendData(1, refId)
			if not hotData then
				gModelGeneral:OnHeroRecommendDataReq(1, refId)
				return
			end
			self._hotDataMap = hotData
		end
	end
	self:InitSkillList()
end

function UIReJNRecommend:InitSkillList()
	self:InitRunSkillData()
	local dataList = {ccClientText(26691), ccClientText(13279)}
	local uiList = self._uiList
	if not uiList then
		uiList = self:GetUIScroll("key_uiList")
		self._uiList = uiList
		uiList:Create(self.mSkillList, dataList, function(...)
			self:OnDrawRuneCell(...)
		end, UIItemList.NORMAL,false)
		local list = uiList:GetList()
		list:EnableScroll(true,false)
		list:RefreshList()
	else
		uiList:RefreshList(dataList)
	end
end

function UIReJNRecommend:OnDrawRuneListCell(list, item, itemdata, itempos, fromHeadTail)
	local skill = tonumber(itemdata.SkillId)
	local skillRef = gModelHero:GetSkillByStarId(skill)
	local SkillTrans = CS.FindTrans(item,"Skill")
	if SkillTrans then
		local skillIconTrans = CS.FindTrans(SkillTrans,"SkillIcon")
		if skillIconTrans then
			local baseClass = SkillIcon:New(self)
			baseClass:Create(skillIconTrans,skill,function()
				local skillType = itemdata.skillType
				local refId = itemdata.refId
				gModelRune:OpenNewRuneSkillWnd(refId,skillType)
			end)
			CS.ShowObject(SkillTrans,true)
		end
	end
	local skillNameTrans = CS.FindTrans(item,"SkillName")
	if skillNameTrans then
		if skillRef then
			local skillName = ccLngText(skillRef.name)
			self:SetWndText(skillNameTrans,skillName)
			CS.ShowObject(skillNameTrans,true)
		end
	end
	local showSign = false
	local textId = 13269
	local signImgTrans = CS.FindTrans(item,"SignImg")
	if signImgTrans then
		local sign = tonumber(itemdata.sign)
		local show = sign ~= 0
		showSign = show
		CS.ShowObject(signImgTrans,show)
		if show then
			local img = "public_bg_di_13"
			if sign == 2 then
				img = "activity_zygift_ui_3"
				textId = 13268
			end
			self:SetWndEasyImage(signImgTrans,img)
		end
	end

	local SignTextTrans = CS.FindTrans(item,"SignText")
	if SignTextTrans then
		self:SetWndText(SignTextTrans,ccClientText(textId))
		CS.ShowObject(SignTextTrans,showSign)
	end

	local hotNodeTrans = self:FindWndTrans(item , "hotNode")
	local hotNumTrans = self:FindWndTrans(hotNodeTrans , "hotNum")

	local hotNum = self._recommendHotNumList[itemdata.refId]
	if hotNum then
		CS.ShowObject(hotNodeTrans, true)
		self:SetWndText(hotNumTrans, string.replace(self._recommendShowFmtStr, tostring(hotNum)))
	else
		CS.ShowObject(hotNodeTrans, false)
	end
end

function UIReJNRecommend:InitRunSkillData()
	local recommendRuneList = {}
	local recommendHotNumList = {}

	self._recommendHotNumList = recommendHotNumList

	local refId = self._refId
	local isHot = false
	if refId then
		local hotMap = self._hotDataMap or {}
		local refTbl = GameTable.MagicRuneSkillRef
		for k,v in pairs(hotMap) do
			local runRef = refTbl[k]
			local skillType = runRef.skillType
			local skillTypeList = gModelRune:GetSkillTypeListBySkillType(skillType)
			local skillRune
			if skillTypeList then
				skillRune = skillTypeList[3]
				skillRune = skillRune and refTbl[skillRune.refId]
			end

			if skillRune and skillRune.quality == 3 then
				isHot = true
				local runeReId = skillRune.refId
				recommendRuneList[runeReId] = runeReId
				recommendHotNumList[runeReId] = v
			end
		end

		if not isHot then
			local ref =  gModelHero:GetHeroRef(refId)
			if ref then
				local recommendRune = ref.recommendRune or ""
				recommendRune = string.split(recommendRune,",")
				for i,v in ipairs(recommendRune) do
					local temp = tonumber(v)
					local runRef = refTbl[temp]
					local skillType = runRef.skillType
					local skillTypeList = gModelRune:GetSkillTypeListBySkillType(skillType)
					local skillRune
					if skillTypeList then
						skillRune = skillTypeList[3]
						skillRune = skillRune and refTbl[skillRune.refId]
					end
					if skillRune then
						local runeReId = skillRune.refId
						recommendRuneList[runeReId] = runeReId
					else
						recommendRuneList[temp] = temp
					end
				end
			end
		end
	end

	local talentList = {}
	for k,v in pairs(GameTable.MagicRuneSkillRef) do
		if v.quality == 3 then
			local isTuiJian = recommendRuneList[v.refId] and true or false
			local talentKey = isTuiJian and 1 or 2

			if not talentList[talentKey] then
				talentList[talentKey] = {}
			end
			table.insert(talentList[talentKey],v)
		end
	end

	-- 未学习 》 可领悟 》 英雄推荐
	local cmpFun = function(talent1,talent2)
		local sign1,sign2 = talent1.sign,talent2.sign
		if sign1 ~= sign2 then
			return sign1 > sign2
		end
		local sort1,sort2 = talent1.sort,talent2.sort
		return sort1 < sort2
	end

	local commoeList = talentList[2] or {}
	table.sort(commoeList,cmpFun)

	local tuijianlist = talentList[1] or {}
	if isHot then
		table.sort(tuijianlist,function (talent1,talent2)
			local hotNum1 = recommendHotNumList[talent1.refId] or 0
			local hotNum2 = recommendHotNumList[talent2.refId] or 0
			if (hotNum1 ~= hotNum2) then
				return hotNum1 > hotNum2
			end
			local sign1,sign2 = talent1.sign,talent2.sign
			if sign1 ~= sign2 then
				return sign1 > sign2
			end
			local sort1,sort2 = talent1.sort,talent2.sort
			return sort1 < sort2
		end)
	else
		table.sort(tuijianlist,cmpFun)
	end

	self._talentList = talentList
end

function UIReJNRecommend:InitData()
	local heroRefId = self:GetWndArg("refId")
	self._refId = heroRefId
	self._recommendShowFmtStr =  ccClientText(26692) or ""

	self._uiTalentList = {}
end

function UIReJNRecommend:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpBtn,function() GF.OpenWndTop("UIBzTips",{refId = 41}) end)
end

function UIReJNRecommend:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeroRecommendDataResp, function(pb)
		self:OnHeroRecommendDataResp(pb)
	end)
end


function UIReJNRecommend:OnHeroRecommendDataResp(pb)
	if self._refId ~= pb.heroRefId  then return end
	if pb.type ~= 1 then return end
	self._hotDataMap = gModelGeneral:OnGetHeroRecommendData(1, self._refId)
	self:InitSkillList()
end


function UIReJNRecommend:OnDrawRuneCell(list, item, itemdata, itempos)
	local titleText = self:FindWndTrans(item, "Title/TitleText")
	local listTrans	= self:FindWndTrans(item, "List")

	self:SetWndText(titleText, itemdata)
	local talentList = self._talentList[itempos] or {}
	local uiListKey = itempos
	local uiList 	= self._uiTalentList[uiListKey]
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self, listTrans)
		uiList:EnableScroll(false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawRuneListCell(...)
		end)
		uiList:EnableLoadAnimation(true, 0, 2)
		self._uiTalentList[uiListKey] = uiList
	end

	uiList:RemoveAll()

	for i,v in ipairs(talentList) do
		uiList:AddData(i,v)
	end

	uiList:RefreshList()
end


function UIReJNRecommend:InitStaticContent()
	self:SetWndText(self.mTitle,ccClientText(13278))
end
------------------------------------------------------------------
return UIReJNRecommend


