---
--- Created by Administrator.
--- DateTime: 2023/10/26 20:46:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFeback:LWnd
local UIFeback = LxWndClass("UIFeback", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFeback:UIFeback()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFeback:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFeback:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFeback:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitUIEvent()

	self:RefreshUI()
end

function UIFeback:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	--self:SetWndClick(self.mMask,function ()
	--	self:WndClose()
	--end)

	self:SetWndClick(self.mGoBtn,function ()
		self:OnClickGo()
	end)
end

function UIFeback:OnClickCopy(itemdata)
	LNativeHelper.CopyToClipboard(itemdata.link)
	GF.ShowMessage(ccClientText(22108))
end

function UIFeback:OnDrawLink(list,item,itemdata,itempos)
	local UIText = self:FindWndTrans(item,"UIText")
	local copyBtn = self:FindWndTrans(item,"copyBtn")
	local copyBtnText = self:FindWndTrans(copyBtn,"Text")


	local str = ccClientText(22105)--"复制"
	self:SetWndText(copyBtnText,str)

	str = nil
	if itemdata.type == 1 then
		str = string.replace(ccClientText(22106),itemdata.link)
	elseif itemdata.type == 2 then
		str = string.replace(ccClientText(22107),itemdata.link)
	end

	self:SetWndText(UIText,str)

	self:SetWndClick(copyBtn,function () self:OnClickCopy(itemdata) end)
end

function UIFeback:SetStaticContent()
	local str =ccClientText(22102) --"意见反馈"
	self:SetWndText(self.mLblBiaoti,str)

	str =ccClientText(22103) --"感谢您的评分，欢迎前往客服反馈您的建议哦！"
	self:SetWndText(self.mIntro,str)

	str =ccClientText(22109) --"前往"
	self:SetWndButtonText(self.mGoBtn,str)

end

function UIFeback:RefreshUI()
	local gradeRela = gModelNormalActivity:GetBIActivityConfigRefByKey("gradeRelation")

	local isForeign = LGameSettings.platformRegion == LRegionConst.AMERICA

	local dataList = {}
	local strs = string.split(gradeRela,",")
	for k,v in ipairs(strs) do
		local temdStrs = string.split(v,'=')
		local type = tonumber(temdStrs[1])
		local link = temdStrs[2]


		if type >0 then
			local data =
			{
				type = tonumber(type),
				link = link,
			}

			if type == 2 then
				if isForeign then
					table.insert(dataList,data)
				end
			else
				table.insert(dataList,data)
			end
		end

	end

	local uiList = self:GetUIScroll("linkList")

	uiList:Create(self.mItemList,dataList,function (...) self:OnDrawLink(...) end)


end

function UIFeback:OnClickGo()
	self:WndClose()
end

------------------------------------------------------------------
return UIFeback


