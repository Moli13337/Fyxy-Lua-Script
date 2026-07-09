---
--- Created by Administrator.
--- DateTime: 2023/10/22 15:43:17
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFoionSyc:LWnd
local UIFoionSyc = LxWndClass("UIFoionSyc", LWnd)

UIFoionSyc.NORMAL = 1
UIFoionSyc.SIMULATE = 2

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFoionSyc:UIFoionSyc()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFoionSyc:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFoionSyc:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFoionSyc:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitUIEvent()



    self:OnWndRefresh()
end

function UIFoionSyc:CheckHaveTryHero()
	local formationData = self:GetWndArg("formationData")
	if not formationData then
		return false
	end

	local grids = formationData.grids
	for k,v in pairs(grids) do
		local id = v.id
		local serverData = gModelHero:GetHeroServerDataById(id)
		if serverData.isTry then
			return true
		end
	end

	return false
end

function UIFoionSyc:OnClickConfirm()

	local wndType = self:GetWndArg("wndType") or UIFoionSyc.NORMAL
	if wndType == UIFoionSyc.NORMAL then
		self:SingleConfirm()
	else
		self:MultiConfirm()
	end

	self:WndClose()
end

function UIFoionSyc:SingleConfirm()
	local formationData = self:GetWndArg("formationData")
	if not formationData then
		return
	end
	local typeList = {}
	for k,v in pairs(self._combatTypeRecord) do
		if v then
			local list = {0}
			typeList[k] = list
		end
	end
	formationData.combatTypeList = typeList

	gModelFormation:OnSetFormationList(formationData)
end


function UIFoionSyc:SetStaticContent()

	local wndType = self:GetWndArg("wndType") or UIFoionSyc.NORMAL


	local str =ccClientText(22300)-- "布阵同步"
	self:SetWndText(self.mLblBiaoti,str)
	str =ccClientText(22301)  --"布阵同步，可以将当前阵型同步至其他玩法阵型"
	if wndType == UIFoionSyc.SIMULATE then
		str =ccClientText(25326)  --"快捷同步阵型到小组赛的其他轮次"
	end

	self:SetWndText(self.mIntro,str)
	str =ccClientText(22302)  --"选择阵容"
	self:SetTextTile(self.mTextTitle,str)
	str = ccClientText(22303)  --"请选择需要同步的阵容"
	self:SetTextTile(self.mTextContent,str)

	str = ccClientText(22304)  --"取 消"

	self:SetWndButtonText(self.mCancelBtn,str)
	str = ccClientText(22305)  --"确 定"
	self:SetWndButtonText(self.mConfirmBtn,str)

	self:InitTextLineWithLanguage(self.mIntro,-40)
end

function UIFoionSyc:OnWndRefresh()
	self._haveTryHero = self:CheckHaveTryHero()

    self._combatTypeRecord = {}

    --local combatType = self:GetWndArg("combatType")

    local dataList = self:GetWndArg("dataList") -- gModelFormation:GetCombatTypeList(nil,nil,{[combatType] = true})

	for k,v in ipairs(dataList) do
		local refId = v.refId
		local canChange = gModelFormation:CanChangeFormation(refId)

		if self._haveTryHero then
			local showTyeHero = gModelBattle:CheckCombatPlayCampShowHeroFree(refId)
			canChange = canChange and showTyeHero
		end

		self._combatTypeRecord[v.refId] = canChange
	end

	local uiList = self:GetUIScroll("uiList")
	uiList:Create(self.mItemList,dataList,function (...) self:OnDrawItem(...) end)

end

function UIFoionSyc:OnDrawItem(list,item,itemdata,itempos)
    local Toggle = self:FindWndTrans(item,"Toggle")
    --local ToggleBackground = self:FindWndTrans(Toggle,"Background")
    --local BackgroundCheckmark = self:FindWndTrans(ToggleBackground,"Checkmark")
    local ToggleXUIText = self:FindWndTrans(Toggle,"XUIText")

    self:SetWndText(ToggleXUIText,ccLngText(itemdata.name))

    local combatType =  itemdata.refId
	local value = self._combatTypeRecord[combatType]
	self:SetWndToggleValue(Toggle,value)
    self:SetWndToggleDelegate(Toggle,function (value)
		if not self:OnValueChange(combatType,value) then
			self:SetWndToggleValue(Toggle,false)
		end
    end)
end

function UIFoionSyc:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mCancelBtn,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mConfirmBtn,function ()
		self:OnClickConfirm()
	end)
end

function UIFoionSyc:MultiConfirm()
	local formationMap = self:GetWndArg("formationMap")
	local teamCnt = self:GetWndArg("teamCnt")


	local formationList = {}

	for k,v in pairs(formationMap) do
		table.insert(formationList,v)
	end

	local clearList = {}

	for k,v in pairs(self._combatTypeRecord) do
		if v then
			for k1 = 0,teamCnt - 1 do
				local data = formationMap[k1]
				if data then
					local dataClone = StructFormationData.Clone(data) -- table.clone(data)
					dataClone.formationType = k
					dataClone.teamIndex = k1

					table.insert(formationList,dataClone)

					local clearData = {}
					clearData.formationType = k
					clearData.teamIndex = k1
					clearData.grids = {}
					clearData.formationRefId = data.formationRefId
					clearData.treasureSkilIds = {}

					table.insert(clearList,clearData)
				end

			end
		end
	end

	local totalList = {}
	for k,v in ipairs(clearList) do
		table.insert(totalList,v)
	end

	for k,v in ipairs(formationList) do
		table.insert(totalList,v)
	end

	gModelFormation:OnSetFormationMultipleReqEx(totalList,1,0)


end

function UIFoionSyc:OnValueChange(combatType,value)

	if value then
		if not gModelFormation:CanChangeFormation(combatType) then
			GF.ShowMessage(ccClientText(22306))
			return false
		end

		if self._haveTryHero and not gModelBattle:CheckCombatPlayCampShowHeroFree(combatType) then
			GF.ShowMessage(ccClientText(22318))
			return false
		end

		self._combatTypeRecord[combatType] = true
	else
		self._combatTypeRecord[combatType] = nil
	end
	return true
end

------------------------------------------------------------------
return UIFoionSyc


