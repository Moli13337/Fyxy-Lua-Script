---
--- Created by Administrator.
--- DateTime: 2023/10/17 11:51:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBfTip:LWnd
local UIBfTip = LxWndClass("UIBfTip", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBfTip:UIBfTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBfTip:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBfTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBfTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:RefreshUI()
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
end

function UIBfTip:RefreshUI()
	local buffId = self:GetWndArg("refId")
    local layer = self:GetWndArg("layer")
    if layer then
        local str =ccClientText(16790) --"深渊难度中达到%s层时自动激活"
        str= string.replace(str,layer)
        self:SetWndText(self.mCondition,str)
    end

    CS.ShowObject(self.mCondition,layer~=nil)

	local buffRef = gModelSkill:GetBuffRef(buffId)
	local icon = buffRef.icon
	local name = ccLngText(buffRef.name)
	local description = ccLngText(buffRef.description)
	local level = buffRef.groupLv

	self:SetWndEasyImage(self.mIcon,icon)
	self:SetWndText(self.mName,name)
	local str = "【%s Lv.%s】"
	str = string.replace(str,name,level)
	self:SetWndText(self.mName,str)
	self:SetWndText(self.mInfo,description)

end


------------------------------------------------------------------
return UIBfTip


