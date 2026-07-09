---
--- Created by Administrator.
--- DateTime: 2023/10/10 15:03:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReJNSel:LWnd
local UIReJNSel = LxWndClass("UIReJNSel", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReJNSel:UIReJNSel()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReJNSel:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReJNSel:OnCreate()
	LWnd.OnCreate(self)

	self._skillIconList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReJNSel:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetWndText(self.mTitle,ccClientText(13222))
	self:SetWndText(self.mCancelBtnName,ccClientText(10101))
	self:SetWndText(self.mEnterBtnName,ccClientText(10102))
	self:SetWndText(self.mDescTxt,ccClientText(13223))
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	self:InitData()
	self:InitEvent()
	self:InitMsg()
--[[	self:Refresh()]]
	self:InitSkillList()
end

function UIReJNSel:InitSkillList()
	local list = self:GetSkillList()
	local uiSkillList = self._uiSkillList
	if uiSkillList then
		uiSkillList:RefreshData(list)
	else
		uiSkillList = self:GetUIScroll("uiSkillList")
		self._uiSkillList = uiSkillList
		uiSkillList:Create(self.mSkillList,list,function(...) self:OnDrawSkillCell(...) end,UIItemList.WRAP)
	end
end

function UIReJNSel:OnDrawSkillCell(list,item,itemdata,itempos)
	local skill = tonumber(itemdata.SkillId)
	local skillRef = gModelHero:GetSkillByStarId(skill)
	if not skillRef then return end
	local SkillTrans = self:FindWndTrans(item,"Skill")
	local SkillIconTrans = self:FindWndTrans(SkillTrans,"SkillIcon")
	local SkillNameTrans = self:FindWndTrans(item,"SkillName")
	local SignImgTrans = self:FindWndTrans(item,"SignImg")
	local SignTextTrans = self:FindWndTrans(item,"SignText")
	local SelImgTrans = self:FindWndTrans(item,"SelImg")

	local skillIconList = self._skillIconList
	if not skillIconList then
		skillIconList = {}
		self._skillIconList = skillIconList
	end
	local InstanceID = item:GetInstanceID()
	local baseClass = skillIconList[InstanceID]
	if not baseClass then
		baseClass = SkillIcon:New(self)
	end
	skillIconList[InstanceID] = baseClass
	baseClass:Create(SkillIconTrans,skill,function()
		local skillType = itemdata.skillType
		local refId = itemdata.refId
		gModelRune:OpenNewRuneSkillWnd(refId,skillType)
	end)
	local skillName = ccLngText(skillRef.name)
	self:SetWndText(SkillNameTrans,skillName)
	CS.ShowObject(SkillNameTrans,true)

	local skillId = itemdata.refId
	local textId = 13269
	local sign = tonumber(itemdata.sign)
	local showSign = sign ~= 0
	CS.ShowObject(SignImgTrans,showSign)
	if showSign then
		local img = "public_bg_di_13"
		if sign == 2 then
			img = "activity_zygift_ui_3"
			textId = 13268
		end
		self:SetWndEasyImage(SignImgTrans,img)
	end
	self:SetWndText(SignTextTrans,ccClientText(textId))
	CS.ShowObject(SignTextTrans,showSign)

	self:SetWndClick(SkillIconTrans,function()
		self:OnClickSkillIconFunc(skillId)
	end)
	self:SetWndLongClick(SkillIconTrans,function()
		gModelRune:OpenNewRuneSkillWnd(itemdata.refId,itemdata.skillType)
	end,0.2,true)

	local isSel = self._skillId == skillId
	CS.ShowObject(SelImgTrans,isSel)
end

function UIReJNSel:OnClickSkillIconFunc(skillId)
	if self._skillId == skillId then
		self._skillId = nil
	else
		self._skillId = skillId
	end
	self:InitSkillList()
end

function UIReJNSel:InitData()
	self._runeId = self:GetWndArg("runeId")
	self._selectType = self:GetWndArg("selectType")
	self._skillList = self:GetWndArg("skillList")
	self._useItemType = self:GetWndArg("useItemType")
	self._skillId = nil
	self._gouTransList = {}
	self._skillTransList = {
		self.mSkill1,
		self.mSkill2,
		self.mSkill3,
		self.mSkill4,
	}
end

function UIReJNSel:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
	self:SetWndClick(self.mCancelBtn,function() self:WndClose() end)
	self:SetWndClick(self.mEnterBtn,function()
		if self._skillId then
			printInfoN("============ self._skillId = ",self._skillId)
			gModelRune:OnRuneRecastReq(self._runeId,self._selectType,self._skillId,self._useItemType)
		else
			GF.ShowMessage(ccClientText(13267))
		end
	end)
end

function UIReJNSel:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RuneRecastResp, function() self:WndClose() end)
end

function UIReJNSel:GetSkillList()
	local list = {}
	local skillList = self._skillList
	local quality = skillList and tonumber(skillList) or 1
	for k,v in pairs(GameTable.MagicRuneSkillRef) do
		if v.quality == quality then
			table.insert(list,v)
		end
	end
	table.sort(list,function(skill1,skill2)
		local sign1,sign2 = skill1.sign,skill2.sign
		if sign1 ~= sign2 then
			return sign1 > sign2
		else
			return skill1.sort < skill2.sort
		end
	end)
	return list
end





--[[function UIReJNSel:Refresh()
	local skillList = string.split(self._skillList,",")
	local skillTransList = self._skillTransList
	for i,v in ipairs(skillList) do
		v = tonumber(v)
		local trans = skillTransList[i]
		self:SkillEvent(v,trans,i)
	end
	self:SkillEvent(0,skillTransList[4],4)
end

function UIReJNSel:SkillEvent(skillId,trans,index)
	local skillData
	local skillName = ""
	local skill
	if skillId ~= 0 then
		skillData = gModelRune:GetSkillInfoByRefId(skillId)
		skill = tonumber(skillData.SkillId)
		local skillRef = gModelHero:GetSkillByStarId(skill)
		if skillRef then skillName = ccLngText(skillRef.name) end
	else
		skillName = ccClientText(13215)
	end
	local SkillIconTrans = CS.FindTrans(trans,"SkillIcon")
	if SkillIconTrans then
		local baseClass = SkillIcon:New(self)
		if not skill then
			baseClass:ShowWenHao(true)
		end
		baseClass:Create(SkillIconTrans,skill)

		local GouTrans = CS.FindTrans(trans,"Gou")
		if GouTrans then
			self._gouTransList[skillId] = GouTrans
			self:SetWndClick(SkillIconTrans,function()
				self:GouEvent(skillId,GouTrans)
			end)

			self:SetWndLongClick(SkillIconTrans,function()
				if skillData then
					gModelRune:OpenNewRuneSkillWnd(skillData.refId,skillData.skillType)
				else
					GF.OpenWnd("UIReJNPreView")
				end
			end,0.2,true)
		end
	end
	local SkillNameTrans = CS.FindTrans(trans,"SkillName")
	if SkillNameTrans then
		self:SetWndText(SkillNameTrans,skillName)
	end
end

function UIReJNSel:GouEvent(skillId,gouTrans)
	if self._skillId == skillId then
		CS.ShowObject(gouTrans,false)
		self._skillId = nil
	else
		local oldSelId = self._skillId
		local trans = self._gouTransList[oldSelId]
		if trans then CS.ShowObject(trans,false) end
		trans = self._gouTransList[skillId]
		if trans then CS.ShowObject(trans,true) end

		self._skillId = skillId
	end
end]]


------------------------------------------------------------------
return UIReJNSel


