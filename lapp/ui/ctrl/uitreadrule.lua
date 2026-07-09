---
--- Created by Administrator.
--- DateTime: 2023/10/26 11:59:25
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITreadRule:LWnd
local UITreadRule = LxWndClass("UITreadRule", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITreadRule:UITreadRule()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITreadRule:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITreadRule:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITreadRule:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mMaskBg,function () self:WndClose() end)

	self:RefreshUI()
end

function UITreadRule:OnDrawItem(list,item,itemdata,itempos)
	local root = self:FindWndTrans(item,"root")
	local rootTop = self:FindWndTrans(root,"Top")
	local TopTypeName = self:FindWndTrans(rootTop,"TypeName")
	local rootFind = self:FindWndTrans(root,"Find")
	local FindFindBtn = self:FindWndTrans(rootFind,"FindBtn")
	local FindBtnXUIText = self:FindWndTrans(FindFindBtn,"XUIText")
	local rootDesc = self:FindWndTrans(root,"Desc")
	local rootItems = self:FindWndTrans(root,"items")



	self:SetWndText(TopTypeName,itemdata.title)
	self:SetWndText(rootDesc,itemdata.content)
	CS.ShowObject(rootFind,itemdata.showFind)
	if itemdata.showFind then
		self:SetWndClick(rootFind,itemdata.func)
		self:SetWndText(FindBtnXUIText,ccClientText(15700))
	end

	if not itemdata.items then
		return
	end
	for i,v in ipairs(itemdata.items) do
		local itemTrans = CS.FindTrans(rootItems,"item"..i)
		if itemTrans then
			CS.ShowObject(itemTrans,true)
			local textTrans = CS.FindTrans(itemTrans,"text")
			if textTrans then self:SetWndText(textTrans,v) end
		end
	end

end

function UITreadRule:OnClickDetail()
	GF.OpenWnd("UIYellAwardLook",{wndType = 2})
end

function UITreadRule:RefreshUI()
	local str = ccClientText(19419)
	self:SetWndText(self.mTitle,str)

	self:InitTextSizeWithLanguage(self.mTitle,-2)
	str = ccClientText(10103)
	self:SetWndText(self.mCloseTip,str)
	local dataList =
	{
		[1]=
		{
			title = ccClientText(19420),
			content = ccClientText(19421),
			showFind = false,
		},
		[2] =
		{
			title = ccClientText(19413),
			content = ccClientText(19422),
			showFind = true,
			func = function() self:OnClickDetail() end,
			items = string.split(ccClientText(19423),',')
		}
	}

	local list = self:GetUIScroll("uiList")
	list:Create(self.mRuleList,dataList,function (...) self:OnDrawItem(...) end)
	list:EnableScroll(true, false)
end
------------------------------------------------------------------
return UITreadRule


