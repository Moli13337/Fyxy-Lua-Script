---
---	纯传数据显示技能弹框
--- Created by Ease.
--- DateTime: 2023/10/29 11:42:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOrdinJNTip:LWnd
local UIOrdinJNTip = LxWndClass("UIOrdinJNTip", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOrdinJNTip:UIOrdinJNTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOrdinJNTip:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOrdinJNTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOrdinJNTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitEvent()
	self:InitData()
end
function UIOrdinJNTip:OnDrawBtnCell(list,item,itemdata,itempos)
	--local skillId = itemdata.skillId
	local sel = itempos == self._curSkillIndex + 1
	local BtnTab1 = self:FindWndTrans(item,"BtnTab1")
	if BtnTab1 then
		local str = string.replace(ccClientText(20125),itemdata.level)
		self:SetWndTabText(BtnTab1,str)
		local status = sel and 0 or 1
		self:SetWndTabStatus(BtnTab1,status)
		self:SetWndClick(BtnTab1,function()
			self:ClickBtnEvent(itemdata.level)
		end)
	end
	local SelImg = self:FindWndTrans(item,"SelImg")
	if SelImg then
		CS.ShowObject(SelImg,sel)
	end
end
function UIOrdinJNTip:InitEvent()

end

function UIOrdinJNTip:SetSkillData()
	local skillData = self._skillDataList[self._curSkillIndex + 1]
	local skillName = skillData.name
	local skillIconPath = skillData.skillIconPath
	local typeTxt = skillData.typeTxt
	local lengQueTxt = skillData.lengQueTxt
	local skillDescDivData = skillData.skillDescDivData
	local upDescData = skillData.upDescData
	local skillDescTitle = skillDescDivData and skillDescDivData.title or ""
	local skillDescTxt = skillDescDivData and skillDescDivData.desc or ""

	local upDescTitle = upDescData and upDescData.title or ""
	local upDescTxt = upDescData and upDescData.desc or ""

	-- 【C宠物系统】删掉宠物系统相关
	-- local talentQuality = skillData.quality
	-- local colorQuality =gModelPetSpace:GetQualityData(talentQuality)
	-- local skillColor = self._qualityColorList2[colorQuality.quaIndex]
	-- skillName = string.format("<color=#%s>%s</color>", skillColor, skillName)
	-- self:SetTxt(self.mNameTxt,skillName)
	self:SetTxt(self.mTypeTxt,typeTxt)
	self:SetTxt(self.mLengQueTxt,lengQueTxt)
	self:SetTxt(self.mSkillDescTitle,skillDescTitle)
	self:SetTxt(self.mSkillDescTxt,skillDescTxt)

	self:SetTxt(self.mUpDescTitle,upDescTitle)
	self:SetTxt(self.mUpSkillDescTxt,upDescTxt)

	CS.ShowObject(self.mSkillDescDiv,skillDescDivData)
	CS.ShowObject(self.mUpSkillDiv,upDescData)
	local skillIconTrans = self:FindWndTrans(self.mSkillInfo,"SkillIcon/IconBg/Icon")
	self:SetImage(skillIconTrans,skillIconPath)
	CS.ShowObject(skillIconTrans,skillIconPath)
end

function UIOrdinJNTip:SetTxt(txtTrans,str)
	if(str)then
		self:SetWndText(txtTrans,str)
	end
end
function UIOrdinJNTip:InitData()
	local tmpList = {}
	local talentSkillList = self:GetWndArg("skillDataList")
	self._curSkillIndex = self:GetWndArg("curSkillIndex") or 0
	-- 【C宠物系统】删掉宠物系统相关
	-- self._qualityColorList2 = gModelPetSpace:GetQualityColorList2()
	for i, v in pairs(talentSkillList) do
		tmpList[v.level+1] = v
	end
	self._skillDataList = tmpList
	self:SetBotBtnList()
	self:ClickBtnEvent(self._curSkillIndex,true)
end
function UIOrdinJNTip:InitBtnEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end
function UIOrdinJNTip:ClickBtnEvent(index,isInit)
	if index == self._curSkillIndex and not isInit then return end
	self._curSkillIndex = index
	local uiBtnList = self._uiBtnList
	if uiBtnList then
		local uiList = uiBtnList:GetList()
		uiList:RefreshList()
	end
	self:SetSkillData()
end
function UIOrdinJNTip:SetBotBtnList()
	local uiBtnList = self._uiBtnList
	local list = self._skillDataList
	if uiBtnList then
		uiBtnList:RefreshList(list)
	else
		uiBtnList = self:GetUIScroll("uiBtnList")
		self._uiBtnList = uiBtnList
		uiBtnList:Create(self.mBtnList,list,function(...) self:OnDrawBtnCell(...) end)
		uiBtnList:EnableScroll(#list > 3,true)
	end
	local uiList = uiBtnList:GetList()
	uiList:DelayScrollTo(self._curSkillIndex,UIListEasy.SCROLL_CENTER)
end
function UIOrdinJNTip:SetImage(imgTrans,path)
	if(path)then
		self:SetWndEasyImage(imgTrans,path)
	end
end


------------------------------------------------------------------
return UIOrdinJNTip


