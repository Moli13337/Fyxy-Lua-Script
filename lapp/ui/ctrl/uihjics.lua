---
--- Created by Administrator.
--- DateTime: 2023/10/29 10:43:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIhjics:LWnd
local UIhjics = LxWndClass("UIhjics", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIhjics:UIhjics()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIhjics:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIhjics:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIhjics:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitUIEvent()
	self:RefreshContent()
end

function UIhjics:ShowSkillTip(skillId)
	local skillid = tonumber(skillId)
	if not skillid then
		return
	end

	--GF.OpenWnd("UINewJNTip",{curSkillId = skillid,wndType = 2})
	gModelGeneral:OpenSkillWnd({curSkillId = skillid,wndType = 2})
end

function UIhjics:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnComfirm,function ()
		self:OnClickConfirm()
	end)
end

function UIhjics:RefreshContent()

	local refIdRecord = self:GetWndArg("refIdRecord")
	local refIdList = self:GetWndArg("refIdList")
	local curSel = self:GetWndArg("curStrategy")

	self._refIdRecord = {}

	self._curSelect = curSel

	local uiList = self:FindUIScroll("uiList")
	if not uiList then
		uiList = self:GetUIScroll("uiList")
		uiList:Create(self.mItemList,refIdList,function (...) self:OnDrawItem(...) end)
	else
		uiList:RefreshList(refIdList)
	end

	uiList:EnableScroll(true,false)

end

function UIhjics:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	--local AniRootMask = self:FindWndTrans(AniRoot,"mask")
	--local AniRootTitleImg = self:FindWndTrans(AniRoot,"TitleImg")
	local AniRootIconBg = self:FindWndTrans(AniRoot,"iconBg")
	local iconBgIcon = self:FindWndTrans(AniRootIconBg,"icon")
	local AniRootName = self:FindWndTrans(AniRoot,"name")
	local AniRootScrollrect = self:FindWndTrans(AniRoot,"scrollrect")
	local scrollrectDesc = self:FindWndTrans(AniRootScrollrect,"desc")
	local AniRootBg = self:FindWndTrans(AniRoot,"bg")
	--local bgImage = self:FindWndTrans(AniRootBg,"Image")
	local bgIsOn = self:FindWndTrans(AniRootBg,"isOn")
	--local AniRootLine = self:FindWndTrans(AniRoot,"line")



	--local ToggleBackground = self:FindWndTrans(AniRootToggle,"Background")
	--local BackgroundCheckmark = self:FindWndTrans(ToggleBackground,"Checkmark")


	local ref = gModelSimuFight:GetSimulateGameSkill(itemdata)
	if not ref then
		printErrorN(string.format("not tactics cfg, SimulateGameSkillRef, id =  %s",itemdata))
		return
	end

	self:SetWndText(AniRootName,ccLngText(ref.name))
	self:SetWndText(scrollrectDesc,ccLngText(ref.description))

	self:SetWndEasyImage(iconBgIcon,ref.icon)

	local isSelect = false
	if self._refIdRecord[itemdata] or self._curSelect == itemdata then
		isSelect = true
	end

	CS.ShowObject(bgIsOn,isSelect)
	self:SetWndClick(AniRootBg,function ()
		self:OnSelectTactics(itemdata)
	end)

	self:SetWndClick(AniRootIconBg,function ()
		self:ShowSkillTip(ref.skill)
	end)


end

function UIhjics:OnClickConfirm()
	local saveFunc = self:GetWndArg("saveFunc")
	if saveFunc then
		saveFunc(self._curSelect)
	end

	self:WndClose()
end

function UIhjics:SetStaticContent()
	local str =ccClientText(25260) --"给队伍配置对应的战术，可以在战斗时生效对应的加成效果"
	self:SetWndText(self.mIntro,str)
	str =ccClientText(25261) -- "点击技能图标查看技能详情"
	self:SetWndText(self.mIntro_1,str)
	str = ccClientText(25263) --"保存"
	self:SetWndButtonText(self.mBtnComfirm,str)
	str = ccClientText(25262) --"战术"
	self:SetWndText(self.mLblBiaoti,str)

	self:InitTextLineWithLanguage(self.mIntro,-40)
	self:InitTextLineWithLanguage(self.mIntro_1,-40)

end

function UIhjics:OnSelectTactics(refId)
	if self._refIdRecord[refId] then
		local str =ccClientText(25264) --"不可重复选择"
		GF.ShowMessage(str)
	else
		if not self._curSelect then
			self._curSelect = refId
		else
			if self._curSelect == refId then
				self._curSelect = 0
			else
				self._curSelect = refId
			end
		end
	end

	local list = self:FindUIScroll("uiList")
	if list then
		list:DrawAllItems(false)
	end

end

------------------------------------------------------------------
return UIhjics


