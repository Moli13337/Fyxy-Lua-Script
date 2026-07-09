---
--- Created by Administrator.
--- DateTime: 2024/9/19 11:34:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeStarSagaNum:LWnd
local UIPeStarSagaNum = LxWndClass("UIPeStarSagaNum", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeStarSagaNum:UIPeStarSagaNum()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeStarSagaNum:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeStarSagaNum:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeStarSagaNum:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	-- self.refId = self:GetWndArg("refId")
	self:SetWndText(self.mTxtDesc,ccClientText(43768))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mTxtTitle,ccClientText(43769))
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:UpdateAttrs()
end

function UIPeStarSagaNum:OnDrawSkillCell(list,item,itemdata,itempos)
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local imgActive = self:FindWndTrans(item,"ImgActive")
	local TxtLevel = self:FindWndTrans(item,"Image/TxtLevel")
	local refStar = itemdata.num
	local refStr = string.replace(ccClientText(43770),itemdata.refId)
	self:SetWndText(AttrName, refStr)
	self:SetWndText(AttrValue,refStar>self.totalStar and string.replace(ccClientText(43713),refStar) or (not self.isAcitve and ccClientText(43763) or ccClientText(43724) ) )
	-- self:SetXUITextTransColor(AttrValue, (refStar<=self.totalStar and self.isAcitve) and "259c43ff" or "c81212ff")
	CS.ShowObject(imgActive,refStar<=self.totalStar and self.isAcitve)
	CS.ShowObject(AttrValue,refStar>self.totalStar or not self.isAcitve)
	self:SetWndText(TxtLevel,string.replace(ccClientText(41637),refStar))
end
function UIPeStarSagaNum:UpdateAttrs()

	local petStarHeroRef = GameTable.MagicPetStarHeroNumRef
	local skills = {}
	for _, value in pairs(petStarHeroRef) do
		table.insert(skills,value)
	end
	table.sort(skills,function(a, b)
		return a.refId< b.refId
	end)
	local total = 0
	self.isAcitve = false
	for _, value in pairs(GameTable.MagicPetRef or {}) do
		local pet = gModelPet:GetPetById(value.refId)
		if pet.isActive then
			total = total+pet._star
			self.isAcitve = true
		end
	end
	self.totalStar = total

	if not self._uiList then
		local uiAttrList = self:GetUIScroll("PetLvAttrList")
		self._uiList = uiAttrList:Create(self.mListSkill,skills,function(...) self:OnDrawSkillCell(...) end,UIItemList.SUPER_GRID)
	else
		self._uiList:RefreshData(skills, true)
		self._uiList:DrawAllItems()
	end
end


------------------------------------------------------------------
return UIPeStarSagaNum