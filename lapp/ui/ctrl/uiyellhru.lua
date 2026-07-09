---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIYellHRu:LWnd
local UIYellHRu = LxWndClass("UIYellHRu", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIYellHRu:UIYellHRu()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIYellHRu:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIYellHRu:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIYellHRu:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitList()
	self:SetXUITextText(self.mCloseTip,ccClientText(10103))
	self:SetXUITextText(self.mTitle,ccClientText(11614))
end

function UIYellHRu:OnDrawHeroCell(list, item, itemdata, itempos, fromHeadTail)
	local rootTrans = CS.FindTrans(item,"root")
	if rootTrans then
		local topTrans = CS.FindTrans(rootTrans,"Top")
		local descTrans = CS.FindTrans(rootTrans,"Desc")
		local itemsTrans = CS.FindTrans(rootTrans,"items")
		local separate = itemdata.separate 					-- 是否使用分隔符机制
		local textId = itemdata.text
		local text = ccClientText(textId)
		if topTrans then
			local findTran = self:FindWndTrans(rootTrans,"Find")
			local FindBtnTrans = CS.FindTrans(findTran,"FindBtn")
			local text = self:FindWndTrans(FindBtnTrans,"XUIText")
			self:SetWndText(text,ccClientText(15700))
			if FindBtnTrans then
				if separate ~= 0 then
					CS.ShowObject(FindBtnTrans,true)
					self:SetWndClick(FindBtnTrans,function()
						-- 奖励详情窗口
						GF.OpenWnd("UIYellAwardLook",{callRefId = itemdata.callRefId})
					end)
				else
					CS.ShowObject(FindBtnTrans,false)
				end
			end
			local TypeNameTrans = CS.FindTrans(topTrans,"TypeName")
			if TypeNameTrans then
				self:SetWndText(TypeNameTrans,ccLngText(itemdata.title))
			end
		end
		if descTrans then
			if separate ~= 0 then
				CS.ShowObject(descTrans,false)
			else
				CS.ShowObject(descTrans,true)
				self:SetWndText(descTrans,text)
			end
		end
		if itemsTrans then
			if separate == 0 then
				CS.ShowObject(itemsTrans,false)
			else
				CS.ShowObject(itemsTrans,true)
				local textList = string.split(text,";")
				for i,v in ipairs(textList) do
					local itemTrans = CS.FindTrans(itemsTrans,"item"..i)
					if itemTrans then
						CS.ShowObject(itemTrans,true)
						local textInfo = string.split(v,",")
						local text1Trans = CS.FindTrans(itemTrans,"text1")
						if text1Trans then self:SetWndText(text1Trans,textInfo[1]) end
						local text2Trans = CS.FindTrans(itemTrans,"text2")
						if text2Trans then self:SetWndText(text2Trans,textInfo[2]) end
					end
				end
			end
		end
	end
end

function UIYellHRu:InitList()
	local uiList = self._uiList
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self,self.mRuleList)
		uiList:EnableScroll(true,false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawHeroCell(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	local data = {}
	for k,v in pairs(GameTable.SummonTextRef) do
		local extractType = v.extractType
		if extractType == self._extractType then
			table.insert(data,v)
		end
	end
	table.sort(data,function(ref1,ref2)
		return ref1.sort < ref2.sort
	end)
	for i,v in ipairs(data) do
		uiList:AddData(i,v)
	end
	uiList:RefreshList()
end

function UIYellHRu:InitEvent()
	self:SetWndClick(self.mMaskBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIYellHRu:InitData()
	self._extractType = self:GetWndArg("extractType")
end

------------------------------------------------------------------
return UIYellHRu


