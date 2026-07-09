---
--- Created by LCM.
--- DateTime: 2024/3/4 10:35:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReAttrSow:LWnd
local UIReAttrSow = LxWndClass("UIReAttrSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReAttrSow:UIReAttrSow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReAttrSow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReAttrSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReAttrSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:RefreshView()
end

function UIReAttrSow:OnDrawAttrCell(list,item,itemdata,itempos)
	local TopDiv = self:FindWndTrans(item,"TopDiv")
	local AttrDiv = self:FindWndTrans(item,"AttrDiv")
	local showTop = itemdata.showTop
	CS.ShowObject(TopDiv,showTop)
	CS.ShowObject(AttrDiv,not showTop)
	if showTop then
		self:CreateTopDiv(TopDiv,itemdata)
	else
		self:CreateAttrDiv(AttrDiv,itemdata)
	end
end

function UIReAttrSow:InitText()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetTextTile(self.mTextTitle5,ccClientText(24915))
	self:SetWndText(self.mDescTxt,ccClientText(24832))
end

function UIReAttrSow:GetAttrDivList(itemdata)
	local list = {}
	local index = itemdata.index
	table.insert(list,{
		showDesc = true,
		index = index,
	})
	local attr = itemdata.attr
	table.insert(list,{
		showDesc = false,
		attr = attr,
	})
	return list
end

function UIReAttrSow:InitShowAttrList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawShowAttrCell(...) end)
	end
end

function UIReAttrSow:InitAttrDivList(item,itemdata)
	local list = self:GetAttrDivList(itemdata)
	local key = item:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(item,list,function(...) self:OnDrawAttrDivCell(...) end)
	end
end

function UIReAttrSow:OnDrawShowAttrCell(list,item,itemdata,itempos)
	local AttrIconTrans = self:FindWndTrans(item,"AttrIcon")
	local AttrNameTrans = self:FindWndTrans(item,"AttrName")
	local AttrNumTrans = self:FindWndTrans(item,"AttrNum")
	local attrRefId = itemdata.attrRefId
	local attrType = itemdata.attrType
	local attrVal = itemdata.attrVal
	local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
	self:SetWndEasyImage(AttrIconTrans,attrIcon)
	local attrName = gModelHero:GetAttributeNameById(attrRefId)
	self:SetWndText(AttrNameTrans,attrName)
	local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrVal)
	self:SetWndText(AttrNumTrans,value)
end

function UIReAttrSow:CreateTopDiv(item,itemdata)
	local TextTitle4 = self:FindWndTrans(item,"TextTitle4")
	local color = gModelItem:GetColorStringByQualityId(itemdata.quality)
	color = LUtil.FormatColorStr(itemdata.name, "#"..color)
	self:SetTextTile(TextTitle4,color)
end

function UIReAttrSow:GetRuneAttrList()
	local runeRefList = {}
	for k,v in pairs(GameTable.MagicRuneRef) do
		local attrGroupIdList = {}
		local attrGroupId = string.split(v.attrGroupId,",")
		for ind,val in ipairs(attrGroupId) do
			table.insert(attrGroupIdList,tonumber(val))
		end
		table.insert(runeRefList,{
			name = ccLngText(v.name),
			attrGroupId = attrGroupIdList,
			quality = v.quality,
			order = v.order,
		})
	end
	table.sort(runeRefList,function(a,b)
		return a.order > b.order
	end)
	local list = {}
	for i,v in ipairs(runeRefList) do
		table.insert(list,{
			showTop = true,
			name = v.name,
			quality = v.quality,
		})
		local attrGroupId = v.attrGroupId
		for idx,val in ipairs(attrGroupId) do
			local attrAllList = {}
			local attrGroupInfo = gModelRune:GetAttrGroupAttrListByAttrGroupId(val)
			for _idx,_val in ipairs(attrGroupInfo) do
				local attrList = _val.attr or {}
				for index,value in ipairs(attrList) do
					table.insert(attrAllList,value)
				end
			end
			table.insert(list,{
				showTop = false,
				index = idx,
				attr = attrAllList,
			})
		end
	end
	return list
end

function UIReAttrSow:CreateAttrDiv(item,itemdata)
	local AttrDivList = self:FindWndTrans(item,"AttrDivList")
	self:InitAttrDivList(AttrDivList,itemdata)
end

function UIReAttrSow:InitMsg()

end

function UIReAttrSow:InitRuneAttrList()
	local list = self:GetRuneAttrList()
	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(list)
	else
		uiAttrList = self:GetUIScroll("uiAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mAttrList,list,function(...) self:OnDrawAttrCell(...) end)
	end
	uiAttrList:EnableScroll(true)
end

function UIReAttrSow:RefreshView()
	self:InitRuneAttrList()
end

function UIReAttrSow:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIReAttrSow:OnDrawAttrDivCell(list,item,itemdata,itempos)
	local DescDiv = self:FindWndTrans(item,"DescDiv")
	local ShowAttrList = self:FindWndTrans(item,"ShowAttrList")
	local showDesc = itemdata.showDesc
	CS.ShowObject(DescDiv,showDesc)
	CS.ShowObject(ShowAttrList,not showDesc)
	if showDesc then
		local Desc = self:FindWndTrans(DescDiv,"Desc")
		self:SetWndText(Desc,string.replace(ccClientText(24816),itemdata.index))
	else
		self:InitShowAttrList(ShowAttrList,itemdata.attr)
	end
end
------------------------------------------------------------------
return UIReAttrSow