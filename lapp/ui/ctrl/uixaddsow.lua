---
--- Created by Administrator.
--- DateTime: 2023/10/3 16:26:25
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIXAddSow:LWnd
local UIXAddSow = LxWndClass("UIXAddSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIXAddSow:UIXAddSow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIXAddSow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIXAddSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIXAddSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitTxt()
	self:InitEvent()
	self:InitData()
	self:RefreshList()
end

function UIXAddSow:InitTxt()
	self:SetWndText(self.mDescTxt,ccClientText(19721))
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	local refId = self:GetWndArg("heroRefId")
	local str = ccClientText(19787)
	local heroName = gModelHero:GetHeroNameByRefId(refId)
	local addNum = gModelHero:GetCloseValueByRefId(refId)
	str ="(".. string.replace(str,heroName,addNum) ..")"

	self:SetWndText(self.mDescTxt2,str)
end

function UIXAddSow:OnDrawAttrCell(list,item, itemdata, itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = itemdata.numType,itemdata.refId,itemdata.value
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon,function()
			CS.ShowObject(AttrIcon,true)
		end)
	end
	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end
	if AttrValue then
		local attrValue = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		self:SetWndText(AttrValue,attrValue)
	end
end

function UIXAddSow:InitData()
	self._heroRefId = self:GetWndArg("heroRefId")
	local closeType = self:GetWndArg("closeType")
	if not closeType then return end
	self._closeType = closeType
end

function UIXAddSow:CreateAttrList(trans,list)
	list = list or {}
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawAttrCell(...) end)
	end
end

function UIXAddSow:OnDrawQMJDCell(list,item, itemdata, itempos)
	local TopDiv = self:FindWndTrans(item,"TopDiv")
	if TopDiv then
		local StarList = self:FindWndTrans(TopDiv,"StarList")
		if StarList then
			self:CreateStarList(StarList,itemdata.grade)
		end
		local JDTxt = self:FindWndTrans(TopDiv,"JDTxt")
		if JDTxt then
			local str = string.replace(ccClientText(19722),itemdata.needLevel)
			self:SetWndText(JDTxt,str)
		end
	end
	local AttrDiv = self:FindWndTrans(item,"AttrDiv")
	if AttrDiv then
		local AttrList = self:FindWndTrans(AttrDiv,"AttrList")
		if AttrList then
			self:CreateAttrList(AttrList,itemdata.attrList)
		end
	end
end

function UIXAddSow:RefreshList()
	local list = self:GetCloseList()
	local uiQMJDList = self._uiQMJDList
	if uiQMJDList then
		uiQMJDList:RefreshList(list)
	else
		uiQMJDList = self:GetUIScroll("uiQMJDList")
		self._uiQMJDList = uiQMJDList
		uiQMJDList:Create(self.mQMJDList,list,function(...) self:OnDrawQMJDCell(...) end,UIItemList.WRAP)
	end
end

function UIXAddSow:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIXAddSow:GetCloseList()
	local dataList = {}
	local closeTypeList = gModelHeroBook:GetHeroCloseLvRefListByCloseType(self._closeType)
	closeTypeList = closeTypeList or {}
	for k,v in pairs(closeTypeList) do
		if v.grade ~= ModelHeroBook.HEROCLOSELV_MIN then
			local beforeLevel = v.beforeLevel
			local ref = closeTypeList[beforeLevel]
			local jd = ref and ref.needLevel or 0
			local attrList = table.clone(v.attrList)
			local data = {
				attrList = attrList,
				refId = v.refId,
				grade = v.grade,
				needLevel = v.needLevelSum,
			}
			table.insert(dataList,data)
		end
	end
	table.sort(dataList,function(a,b)
		return a.grade < b.grade
	end)
	return dataList
end

function UIXAddSow:OnDrawStarCell(list,item, itemdata, itempos)
	local Star = self:FindWndTrans(item,"Star")
	if Star then
		self:SetWndImageGray(Star,itemdata.gray)
	end
end

function UIXAddSow:CreateStarList(trans,star)
	local key = trans:GetInstanceID()
	local list = {}
	local closeLv = gModelHeroBook:GetHeroCloseLv(self._heroRefId)
	for i = 1,closeLv do
		local gray = star < i
		table.insert(list,{gray = gray})
	end

	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawStarCell(...) end)
	end
end

------------------------------------------------------------------
return UIXAddSow