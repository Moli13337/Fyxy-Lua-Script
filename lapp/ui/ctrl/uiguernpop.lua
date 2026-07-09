---
--- Created by Administrator.
--- DateTime: 2023/10/2 15:51:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGuernPop:LWnd
local UIGuernPop = LxWndClass("UIGuernPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGuernPop:UIGuernPop()
	---@type table<number,CommonIcon>
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGuernPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil
	
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGuernPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGuernPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitUIEvent()
	self:SetStaticContent()
end

function UIGuernPop:OnClickGo1()
	GF.OpenWnd("UIRiskRtWin", {lvl = self._riskRatingLvl})
end

function UIGuernPop:SetStaticContent()
	local str = ccClientText(21300)
	self:SetWndText(self.mTitleText, str)
	str = ccClientText(21302)
	local addSize = -2
	local addLine = -30
	if gLGameLanguage:IsJapanVersion() then
		addLine = -48
	end

	local text = self:FindWndTrans(self.mPageMag1,"desc_1")
	self:SetWndText(text,str)
	self:InitTextSizeWithLanguage(text, addSize)
	self:InitTextLineWithLanguage(text, addLine)
	str = ccClientText(21303)
	text = self:FindWndTrans(self.mPageMag1,"desc_2")
	self:SetWndText(text,str)
	self:InitTextSizeWithLanguage(text, addSize)
	self:InitTextLineWithLanguage(text, addLine)
	str = ccClientText(21305)
	text = self:FindWndTrans(self.mPageMag2,"desc_1")
	self:SetWndText(text,str)
	self:InitTextSizeWithLanguage(text, addSize)
	self:InitTextLineWithLanguage(text, addLine)
	str = ccClientText(21315)
	text = self:FindWndTrans(self.mPageMag2,"desc_2")
	self:SetWndText(text,str)
	self:InitTextSizeWithLanguage(text, addSize)
	self:InitTextLineWithLanguage(text, addLine)
	str = ccClientText(21301)
	text = self:FindWndTrans(self.mPageMag1,"TitleText")
	self:SetWndText(text,str)
	str = ccClientText(21304)
	text = self:FindWndTrans(self.mPageMag2,"TitleText")
	self:SetWndText(text,str)

	str = ccClientText(21306)
	local btn = self:FindWndTrans(self.mPageMag1,"BtnPageGo")
	self:SetWndButtonText(btn,str)
	str = ccClientText(21307)
	local btn = self:FindWndTrans(self.mPageMag2,"BtnPageGo")
	self:SetWndButtonText(btn,str, nil, -4)

	self:InitPage1()
	self:InitPage2()
end

function UIGuernPop:InitUIEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)

	local btn = self:FindWndTrans(self.mPageMag1,"BtnPageGo")
	self:SetWndClick(btn,function ()
		self:OnClickGo1()
	end)
	btn = self:FindWndTrans(self.mPageMag2,"BtnPageGo")
	self:SetWndClick(btn,function ()
		self:OnClickGo2()
	end)
end

function UIGuernPop:InitPage2()
	local page = self:FindWndTrans(self.mPageMag2, "Page")
	local icon = self:FindWndTrans(page, "Icon")
	local desText = self:FindWndTrans(page, "DesText")

	local trans = icon
	local key = trans:GetInstanceID()
	local uiCommonList = self._uiCommonList
	local baseClass = uiCommonList[key]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		uiCommonList[key] = baseClass
		baseClass:Create(icon)
	end

-- 	local treasureRefId = self._treasureRefId

-- 	baseClass:SetTreasureSkillData({
-- 		refId = treasureRefId,
-- 		--skillRefId = serverData.skillRefId,
-- 	})
-- 	baseClass:ShowTreasureSkillInfo(false,false)
-- 	baseClass:DoApply()

-- 	local name = gModelTreasure:GetTreasureNameByRefId(treasureRefId)
-- 	local color = "#" .. gModelTreasure:GetTreasureColorByRefId(treasureRefId)
-- 	local colorName = LUtil.FormatColorStr(name,color)
-- 	self:SetWndText(desText,colorName)

-- 	self:SetWndClick(page,function()
-- 		self:OnClickGo2()
-- 	end)
end

function UIGuernPop:InitPage1()
	local ref = gModelGrade:GetGradeLvRefByRefId(self._riskRatingLvl)
	if not ref then
		return
	end

	local page = self:FindWndTrans(self.mPageMag1, "Page")
	local icon = self:FindWndTrans(page, "Icon")
	local nameIcon = self:FindWndTrans(page, "NameIcon")
	local statList = self:FindWndTrans(page, "StarList")

	self:SetWndEasyImage(icon,ref.iconBig,function ()
		CS.ShowObject(icon,true)
	end)

	self:SetWndEasyImage(nameIcon,ref.iconSmall,function ()
		CS.ShowObject(nameIcon,true)
	end)

	local starNum = ref.starNum
	if starNum > 0 then
		local starIconStr = ref.iconBigStarColor
		for i = 1, 5 do
			local trans = self:FindWndTrans(statList,"Star"..i)
			local isShow = i <= starNum
			CS.ShowObject(trans, isShow)
			if isShow then
				self:SetWndEasyImage(trans, starIconStr)
			end
		end
	end

	self:SetWndClick(page,function()
		self:OnClickGo1()
	end)
end

function UIGuernPop:InitData()
	self._riskRatingLvl = 10
	-- self._treasureRefId = ModelTreasure.GUESS_RETURN_REF_ID
end

-- function UIGuernPop:OnClickGo2()
-- 	local refId = self._treasureRefId
-- 	GF.OpenWnd("WndTreasureSkillEffectShowPop", {
-- 		refId = refId,
-- 	})
-- end



------------------------------------------------------------------
return UIGuernPop


