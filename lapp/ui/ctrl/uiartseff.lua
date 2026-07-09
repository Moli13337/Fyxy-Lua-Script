---
--- Created by Administrator.
--- DateTime: 2023/10/25 20:56:44
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIArtsEff:LWnd
local UIArtsEff = LxWndClass("UIArtsEff", LWnd)

UIArtsEff.ACT_ATTR_COLOR = "#feeba7"

UIArtsEff.ACT_COLOR = "#ffffff"
UIArtsEff.NOACT_COLOR = "#e5e5e5"
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIArtsEff:UIArtsEff()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIArtsEff:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIArtsEff:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIArtsEff:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitData()
	self:RefreshArticle()
end

function UIArtsEff:InitData()
	self._articleData = self:GetWndArg("articleData")
end

function UIArtsEff:OnClassArticleCell(list,item,itemdata,itempos)
	local JiejiDiv = self:FindWndTrans(item,"JiejiDiv")
	local ActImg = self:FindWndTrans(JiejiDiv,"ActImg")
	local ClassTxt = self:FindWndTrans(JiejiDiv,"ClassTxt")

	local AttrList = self:FindWndTrans(item,"AttrList")

	local InstanceID = item:GetInstanceID()
	local isAct = itemdata.isAct
	CS.ShowObject(ActImg,isAct)

	if ClassTxt then
		local str = ccClientText(19045)
		str = string.replace(str,itemdata.rankNow)
		local color = isAct and UIArtsEff.ACT_COLOR or UIArtsEff.NOACT_COLOR
		str = LUtil.FormatColorStr(str,color)
		self:SetWndText(ClassTxt,str)
	end

	if AttrList then
		self:RefreshAttrList(InstanceID,AttrList,itemdata.actAttrList)
	end
end


function UIArtsEff:InitText()
	self:SetWndText(self.mTitle,ccClientText(19018))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mTitle,ccClientText(19018))
end

function UIArtsEff:RefreshArticle()
	local list = self:GetClassList()
	local uiClassList = self._uiClassList
	if uiClassList then
		uiClassList:RefreshList(list)
	else
		uiClassList = self:GetUIScroll("uiClassList")
		self._uiClassList = uiClassList
		uiClassList:Create(self.mAddAttrList,list,function(...) self:OnClassArticleCell(...) end)
	end
end

function UIArtsEff:InitEvent()
	self:SetWndClick(self.mBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIArtsEff:OnDrawAttrCell(list,item,itemdata,itempos)
	local isAct = itemdata.isAct
	local refId,numType,value = itemdata.refId,itemdata.numType,itemdata.value
--[[	local Attr = self:FindWndTrans(item,"Attr")
	if Attr then
		local name = gModelHero:GetAttributeNameById(refId)
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		local str
		local attrStr
		if isAct then
			str = "<color=%s>%s：</color><color=%s>+%s</color>"
			attrStr = string.replace(str,UIArtsEff.ACT_COLOR,name,UIArtsEff.ACT_ATTR_COLOR,valueStr)
		else
			str = "<color=%s>%s：+%s</color>"
			attrStr = string.replace(str,UIArtsEff.NOACT_COLOR,name,valueStr)
		end
		self:SetWndText(Attr,attrStr)
	end]]

	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrVlaue = self:FindWndTrans(item,"AttrVlaue")

	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon,function()
			CS.ShowObject(AttrIcon,true)
		end)
	end


	local color
	if isAct then
		color = UIArtsEff.ACT_ATTR_COLOR
	else
		color = UIArtsEff.NOACT_COLOR
	end

	if AttrName then
		local nameColor = color
		local name = gModelHero:GetAttributeNameById(refId)
		name = LUtil.FormatColorStr(name,nameColor)
		name = name .. "："
		self:SetWndText(AttrName,name)
	end

	if AttrVlaue then
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		local str = "<color=%s>+%s</color>"
		if isAct then
			str = string.replace(str,UIArtsEff.ACT_ATTR_COLOR,valueStr)
		else
			str = string.replace(str,UIArtsEff.NOACT_COLOR,valueStr)
		end
		self:SetWndText(AttrVlaue,str)
	end
end

function UIArtsEff:GetClassList()
	local list = {}
	local articleData = self._articleData
	if not articleData then return list end
	-- local refId = articleData.refId
	-- local rankRefId = articleData.rankRefId
	-- local rankList = gModelTreasure:GetTreasureObjectRankRefByType(refId)
	-- for k,v in pairs(rankList) do
	-- 	if v.rankNow ~= 0 then
	-- 		local attrExtraList = v.attrExtraList
	-- 		if #attrExtraList > 0 then
	-- 			local cRefId = v.refId
	-- 			local data = {
	-- 				rankNow = v.rankNow,
	-- 				attrList = attrExtraList,
	-- 				refId = cRefId,
	-- 				type = v.type,
	-- 			}
	-- 			local isAct = rankRefId >= cRefId
	-- 			data.isAct = isAct
	-- 			local actAttrList = {}
	-- 			for idx,val in ipairs(attrExtraList) do
	-- 				local t = table.clone(val)
	-- 				t.isAct = isAct
	-- 				table.insert(actAttrList,t)
	-- 			end
	-- 			data.actAttrList = actAttrList
	-- 			table.insert(list,data)
	-- 		end
	-- 	end
	-- end
	-- table.sort(list,function(a,b)
	-- 	local rankNow1,rankNow2 = a.rankNow,b.rankNow
	-- 	return rankNow1 < rankNow2
	-- end)
	return list
end

function UIArtsEff:RefreshAttrList(key,trans,list)
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawAttrCell(...) end)
	end
end

------------------------------------------------------------------
return UIArtsEff


