---
--- Created by Administrator.
--- DateTime: 2024/11/20 21:49:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineResonancePop:LWnd
local UIDivineResonancePop = LxWndClass("UIDivineResonancePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineResonancePop:UIDivineResonancePop()
	self.typeName = {
		[1] = ccClientText(46129),
		[2] = ccClientText(46130),
		[3] = ccClientText(46131),
	}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineResonancePop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineResonancePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineResonancePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self.jpj = gLGameLanguage:IsJapanVersion()
	self:SetWndText(self.mLblBiaoti,ccClientText(46125))
	self:SetTextTile(self.mImgFull,ccClientText(42021))	
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mBtnUpLv,function() self:OnClickUpLv() end)
	self:SetWndButtonText(self.mBtnUpLv,ccClientText(43710))
	self:SetWndText(self.mTxtCurTitle,string.replace(ccClientText(46126)))
	self:SetWndText(self.mTxtNextTitle,string.replace(ccClientText(46127)))
	self:WndEventRecv(EventNames.DIVINE_WEAPON_RESONANCE,function() self:UpdatePanel() end)
	self:WndEventRecv(EventNames.On_Item_Change,function() self:UpdatePanel() end)
	self.refId = self:GetWndArg("refId")
	self:UpdatePanel()
end

function UIDivineResonancePop:OnClickUpLv()
	if self.cost.isUp then
		gModelDivineWeapon:OnDivineWeaponResonanceUpLvReq(self.refId)
	else
		self:WndClose()
		gModelGeneral:OpenGetWayWnd({ itemId = self.cost.itemId })
	end
end

function UIDivineResonancePop:UpdatePanel()
	local cfgs = gModelDivineWeapon:GetDiviWeaponResonanceLvRef(self.refId)
	local lvCfg = gModelDivineWeapon:GetDivineCurResonanceRef(self.refId)
	local nexCfg
	local curAttr = ""
	local nexAttr = ""
	local cost
	local lv
	if not lvCfg then --沒激活-未學習
		lvCfg = cfgs[1]
		curAttr = ccClientText(46128)
		nexAttr = ccLngText(lvCfg.desc)
		cost = LxDataHelper.ParseItem_4(lvCfg.upNeed)
		self:SetWndButtonText(self.mBtnUpLv,ccClientText(46117))
		lv = 0
	else
		self:SetWndButtonText(self.mBtnUpLv,ccClientText(43710))
		curAttr = ccLngText(lvCfg.desc)
		lv = lvCfg.level
		nexCfg = cfgs[lvCfg.level+1]
		cost = nexCfg and LxDataHelper.ParseItem_4(nexCfg.upNeed)
		nexAttr = nexCfg and ccLngText(nexCfg.desc) or ccClientText(42021)

	end
	self:SetWndText(self.mTxtCurAttr,curAttr)
	self:SetWndText(self.mTxtNextAttr,nexAttr)
	self:SetWndText(self.mTxtLv,"Lv."..lv)
	local ref = GameTable.DivineWeaponTechnologyRef[self.refId]
	self:SetWndText(self.mTxtName,ccLngText(ref.name))
	if self.jpj then
		local textTran = LxUiHelper.FindXTextCtrl(self.mTxtName)
		textTran.enableWordWrapping = true
		self:InitTextLineWithLanguage(self.mTxtName,-50)
		self:SetAnchorPos(self.mTxtLv,Vector2.New(200,58))
		local textTran2 = LxUiHelper.FindXTextCtrl(self.mTxtCondition)
		textTran2.enableWordWrapping = true
		self:InitTextLineWithLanguage(self.mTxtCondition,-30)
	end
	self:SetWndEasyImage(self.mItemIcon,ref.icon)
	self:SetWndEasyImage(self.mItemIconBg,ref.iconBg)
	local image = self:FindWndImage(self.mItemIconBg)
	image.enabled = not string.isempty(ref.iconBg)

	local showCondi,conditionMap,condiState = gModelDivineWeapon:GetForeCondition(self.refId)
	CS.ShowObject(self.mBtnUpLv, showCondi)
	CS.ShowObject(self.mImgCost, showCondi)
	self:SetWndText(self.mTxtCondition,"")
	if not showCondi then
		local str = ""
		local count = table.keysize(conditionMap)
		local indx = 0
		for type, value in pairs(conditionMap or {}) do
			indx = indx+1
			local color = condiState[type] and "#38962e" or "#F21515"
			str =str..string.replace(self.typeName[type],color,value)
			if indx ~= count then str = str.."\n" end
		end
		self:SetWndText(self.mTxtCondition,str)
	end
	self.cost = cost
	if cost then
		local curNum =  gModelItem:GetNumByRefId(cost.itemId)
		local icon = gModelItem:GetItemIconByRefId(cost.itemId)
		local color = curNum>=cost.itemNum and "#38962e" or "#FF2010"
		cost.isUp = curNum>=cost.itemNum
		self:SetWndText(self.mTxtCost,string.replace("<color=#a1#>#a2#</color>/#a3#",color,curNum,cost.itemNum))
		self:SetWndEasyImage(self.mCostIcon,icon)
	else
		CS.ShowObject(self.mBtnUpLv,false)
		CS.ShowObject(self.mImgCost,false)
		CS.ShowObject(self.mTxtCondition,false)
	end
	CS.ShowObject(self.mImgFull, not cost)
	self:SetRed(self.mBtnUpLv, cost and cost.isUp)
end
------------------------------------------------------------------
return UIDivineResonancePop