---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBfDetails:LWnd
local UIBfDetails = LxWndClass("UIBfDetails", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBfDetails:UIBfDetails()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBfDetails:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBfDetails:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBfDetails:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
end

function UIBfDetails:Reset(heroData)
	self._heroData = heroData
	self._heroID = heroData:GetId()
	self:InitScrollView()
end

function UIBfDetails:InitData()
	self._heroData = self:GetWndArg("heroData")
	self._heroID = self._heroData:GetId()
	self:InitScrollView()
end

function UIBfDetails:OnDrawItemCell(list, item, itemdata, itempos, fromHeadTail)
	local BuffDetails = self:FindWndTrans(item,"BuffDetails")
	local BuffDetailsIcon = self:FindWndTrans(BuffDetails,"Icon")
	local BuffDetailsBuffName = self:FindWndTrans(BuffDetails,"BuffName")
	--local BuffDetailsBuffLevel = self:FindWndTrans(BuffDetails,"BuffLevel")
	local BuffDetailsBuffRound = self:FindWndTrans(BuffDetails,"BuffRound")
	local BuffDetailsDetails = self:FindWndTrans(BuffDetails,"Details")
	--local BuffDetailsLine = self:FindWndTrans(BuffDetails,"Line")

	local buffShowData = itemdata.buffShowData
	local cnt = #itemdata.buffShowList

	self:SetWndEasyImage(BuffDetailsIcon,buffShowData.icon)

	if string.isempty(buffShowData.name) then
		printErrorN(string.format("no name %s",buffShowData.refId))
	end
	local str = "【%s Lv.%s】*%s"
	str = string.replace(str,buffShowData.name,buffShowData.level,cnt)
	self:SetWndText(BuffDetailsBuffName,str)

	self:InitTextLineWithLanguage(BuffDetailsBuffName,-40)
	local str =""
	if buffShowData.round>0 then
		str = string.replace(ccClientText(16612),buffShowData.curRound)
	end
	self:SetWndText(BuffDetailsBuffRound,str)
	self:InitTextLineWithLanguage(BuffDetailsBuffRound, -30)
	self:SetWndText(BuffDetailsDetails,buffShowData.description)


end

-- 刷新buff详情列表
function UIBfDetails:InitScrollView()
	local buffList = self._heroData:GetBuffList()
	local dataList = gModelSkill:FormatBuffShowList(buffList)

	local uiList = self:FindUIScroll("buffList")
	if not uiList then
		uiList = self:GetUIScroll("buffList")
		uiList:Create(self.mItemList,dataList,function (...) self:OnDrawItemCell(...) end,UIItemList.SUPER)
	else
		uiList:RefreshList(dataList)
	end

end

function UIBfDetails:InitEvent()
	self:SetWndClick(self.mBg, function (...)
		self:WndClose()
	end)

end

------------------------------------------------------------------
return UIBfDetails


