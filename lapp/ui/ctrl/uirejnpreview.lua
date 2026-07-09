---
--- Created by Administrator.
--- DateTime: 2023/10/10 16:14:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReJNPreView:LWnd
local UIReJNPreView = LxWndClass("UIReJNPreView", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReJNPreView:UIReJNPreView()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReJNPreView:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReJNPreView:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReJNPreView:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetWndTabText(self.mChujiBtn, ccClientText(13226), nil, -30)
	self:SetWndTabText(self.mZhongjiBtn, ccClientText(13227),nil,-30)
	self:SetWndTabText(self.mGaojiBtn, ccClientText(13228), nil, -30)
	self:SetWndTabText(self.mSuperBtn, ccClientText(13280), nil, -30)
	self:InitData()
	self:SetWndText(self.mTitle,ccClientText(13225))

	self:InitEvent()
	self:InitMsg()
end

function UIReJNPreView:BtnEvent(index)
	if index == self._page then return end
	local old = self._page
	local btnTrans = self._botBtnList[old]
	self:SetWndTabStatus(btnTrans, LWnd.StateOff)

	self._page = index
	btnTrans = self._botBtnList[index]
	self:SetWndTabStatus(btnTrans, LWnd.StateOn)
	self:InitSkillList()
end

function UIReJNPreView:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpBtn,function() GF.OpenWndTop("UIBzTips",{refId = 41}) end)
	for i,v in ipairs(self._botBtnList) do
		self:SetWndClick(v,function()
			self:BtnEvent(i)
		end)
	end
end

function UIReJNPreView:InitSkillList()
	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mSkillList)
		uiList:EnableScroll(true,false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawSkillCell(...)
		end)
		uiList:EnableLoadAnimation(true, 0, 1)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	local skillList = {}
	for k,v in pairs(GameTable.MagicRuneSkillRef) do
		if v.quality == self._page then
			table.insert(skillList,v)
		end
	end
	table.sort(skillList,function(skill1,skill2)
		local sign1,sign2 = skill1.sign,skill2.sign
		if sign1 ~= sign2 then
			return sign1 > sign2
		else
			return skill1.sort < skill2.sort
		end
	end)
	for i,v in ipairs(skillList) do
		uiList:AddData(i,v)
	end
	uiList:RefreshList(UIListWrap.RefreshMode.Solid)
end

function UIReJNPreView:InitMsg()

end

function UIReJNPreView:OnDrawSkillCell(list, item, itemdata, itempos, fromHeadTail)
	local skill = tonumber(itemdata.SkillId)
	local skillRef = gModelHero:GetSkillByStarId(skill)
	local SkillTrans = CS.FindTrans(item,"Skill")
	if SkillTrans then
		local skillIconTrans = CS.FindTrans(SkillTrans,"SkillIcon")
		if skillIconTrans then
			local baseClass = SkillIcon:New(self)
			baseClass:Create(skillIconTrans,skill,function()
--[[				local lv = itemdata.skillLevel
				local other = {
					lv = lv
				}
				GF.OpenWndTop("UIJNInfo",{skillId = skill,other = other})]]
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
end

function UIReJNPreView:InitData()
	local page = self:GetWndArg("page") or 1
	self._page = 1
	self._botBtnList = {
		self.mChujiBtn,
		self.mZhongjiBtn,
		self.mGaojiBtn,
		self.mSuperBtn,
	}
	if page ~= self._page then
		self:BtnEvent(page)
	else
		self:InitSkillList()
	end
end
------------------------------------------------------------------
return UIReJNPreView