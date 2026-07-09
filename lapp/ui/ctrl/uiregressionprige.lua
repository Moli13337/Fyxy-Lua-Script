---
--- Created by Administrator.
--- DateTime: 2024/8/8 22:16:18
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRegressionPrige:LWnd
local UIRegressionPrige = LxWndClass("UIRegressionPrige", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRegressionPrige:UIRegressionPrige()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRegressionPrige:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRegressionPrige:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRegressionPrige:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:OnAddClick()
	self:OnUpdateList()
end
function UIRegressionPrige:OnDrawPetCell(list, item, itemdata, itempos)
	local listDesc = self:FindWndTrans(item, "ListPrivilege")
	local BtnGoto = self:FindWndTrans(item,"BtnGoto")
	local ImgTitle = self:FindWndTrans(item,"ImgTitle")
	local BtnGoToText = self:FindWndTrans(BtnGoto,"BtnGoToText")
	self:SetWndEasyImage(ImgTitle,itemdata.icon)
	self:SetWndEasyImage(item,itemdata.bg)
	self:SetWndText(BtnGoToText,ccClientText(24213))
	self:OnUpdateDescList(item,listDesc,itemdata)
	self:SetWndClick(BtnGoto,function()
		if itemdata.jump == 17100010 then
			GF.CloseWndByName("UIRegressionPrige")
			GF.CloseWndByName("UIRionWin")
		end
		gModelFunctionOpen:Jump(itemdata.jump)
	end)
end
function UIRegressionPrige:OnAddClick()
	self:SetWndText(self.mLblBiaoti,ccClientText(45118))
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mMaks,function()
		self:WndClose()
	end)
	-- self:WndEventRecv(EventNames.PET_CHANGE_LEVEL,function ()
	-- end)
	-- self:WndEventRecv(EventNames.PET_CHANGE_STAR,function ()
	-- end)

end

function UIRegressionPrige:OnHeroCell(list,item,itemdata,itempos)
	local TxtTime = self:FindWndTrans(item,"TxtTime")
	self:SetWndText(TxtTime,ccLngText(itemdata))
end

function UIRegressionPrige:OnUpdateList()
	local cfgs = GameTable.ReturnBackPrivilegesShowRef
	local privilegeList = {}
	for _, value in pairs(cfgs or {}) do
		if gModelFunctionOpen:CheckIsOpened(value.jump) then
			table.insert(privilegeList,value)
		end
	end
	table.sort(privilegeList,function(a, b) return a.Type<b.Type end)
	local uiList = self._uiList
	if not uiList then
        uiList = self:GetUIScroll("mRegressionPrivilege")
        self._uiList = uiList
        uiList:Create(self.mListTask, privilegeList, function(...)
            self:OnDrawPetCell(...)
        end, UIItemList.SUPER_GRID, false)
    else
        uiList:RefreshList(privilegeList)
		local superList = uiList:GetList()
		superList:DrawAllItems()
	end
end

function UIRegressionPrige:OnUpdateDescList(item,uiList,itemdata)
	local privilege = {}
	local sysBuff =string.split(itemdata.sysbuff,",")
	local sysBuffRef = GameTable.SysBuffRef
	for _, value in pairs(sysBuff or {}) do
		local sysRef = sysBuffRef[tonumber(value)]
		if sysRef and not string.isempty(sysRef.desc) then table.insert(privilege,sysRef.desc) end
	end
	self:CreateUIScrollImpl(nil,uiList,privilege,function(...) self:OnHeroCell(...) end)
end
------------------------------------------------------------------
return UIRegressionPrige