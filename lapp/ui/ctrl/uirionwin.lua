---
--- Created by Administrator.
--- DateTime: 2024/8/7 20:54:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRionWin:LWnd
local UIRionWin = LxWndClass("UIRionWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRionWin:UIRionWin()
	self.timeKey ="regressionTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRionWin:OnWndClose()
	LWnd.OnWndClose(self)
	FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.CITY })
	self:TimerStop(self.timeKey)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRionWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRionWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self.listTrans = {
		self.mItemObj1,
		self.mItemObj2,
		self.mItemObj3,
		self.mItemObj4,
		self.mItemObj5,
	}
	self:OnAddClick()
	self:InitSpine()
	self:OnUpdateList()
	self:InitRegressionTime()
	
end

function UIRionWin:OnUpdateList()
	local regressionCfg = GameTable.ReturnBackBackflowRef
	local list = {}
	for _, value in pairs(regressionCfg) do
		table.insert(list,value)
	end
	table.sort(list,function(a, b) return a.refId<b.refId end)
	local isNull = self.timeTrans
	self.timeTrans = {}
	for index, value in ipairs(list) do
		local itemTran = self.listTrans[index]
		self:OnSetItemData(itemTran,value)
		if not isNull then
			local timeTran = self:FindWndTrans(itemTran,"TxtTime")
			if timeTran then table.insert(self.timeTrans,timeTran) end
			self:SetWndClick(itemTran,function()
				if not gModelFunctionOpen:CheckIsOpened(value.functionId,true) then return end
				-- GF.OpenWnd("UIRegressionMinWin",{funcType = value.type})
				gModelFunctionOpen:Jump(value.functionId)
			end)
		end
	end

end

function UIRionWin:OnTimer(key)
	if key == self.timeKey then
		self:SetTimeTxt()
	end
end
function UIRionWin:InitSpine()
	local showHero = GameTable.ReturnBackConfigRef.showHero
	if not showHero or string.isempty(showHero) then return end
	local dpSpine = self:CreateWndSpine(self.mSpine,showHero,nil,true,function (dpLoaded)
		dpLoaded:PlayAnimation(0,"idle",true)
	end,true)
	dpSpine:StartLoad()
end
function UIRionWin:OnSetItemData(itemTran,data)
	local TxtTitle = self:FindWndTrans(itemTran,"TxtTitle")
	self:SetWndEasyImage(itemTran,data.showIcon,function()
		LxUiHelper.FindImageCtrl(itemTran):SetNativeSize()
	end)

	self:SetWndText(TxtTitle,ccLngText(data.name))
end

function UIRionWin:OnAddClick()
	self:SetTextTile(self.mBtnPrivilege,ccClientText(45101))
	self:SetTextTile(self.mBtnShop,ccClientText(10362))
	self:SetTextTile(self.mReturnBtn,ccClientText(36304))
	self:SetWndClick(self.mReturnBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnPrivilege,function()
		GF.OpenWnd("UIRegressionPrige")
	end)
	self:SetWndClick(self.mBtnShop,function()
		GF.OpenWnd("UIDian", { shopId = 2010 })
	end)

	self:WndEventRecv(EventNames.PET_CHANGE_LEVEL,function ()
	end)
	self:WndEventRecv(EventNames.PET_CHANGE_STAR,function ()
	end)

end
function UIRionWin:InitRegressionTime()
	self.endTime =  gModelRegression.endTime--GetTimestamp() +100000
	self:TimerStart(self.timeKey, 1, false, -1)
	self:SetTimeTxt()
end

function UIRionWin:SetTimeTxt()
	local nowTime = GetTimestamp()
	local timeDif = os.difftime(self.endTime, nowTime)
	if timeDif <= 0 then
		self:TimerStop(self.timeKey)
	end
	local timeStr =LUtil.FormatTimespanCn(timeDif) --LUtil.FormatTimeToCn3(timeDif)
	for _, itemTran in pairs(self.timeTrans) do
		if itemTran then self:SetWndText(itemTran,string.replace(ccClientText(18400),timeStr)) end
	end
	self:SetWndText(self.mTxtTime,string.replace(ccClientText(18400),timeStr))
end

------------------------------------------------------------------
return UIRionWin