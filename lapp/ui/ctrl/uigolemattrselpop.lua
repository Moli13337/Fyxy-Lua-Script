---
--- Created by BY.
--- DateTime: 2022/11/17 21:29:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemAttrSelPop:LWnd
local UIGolemAttrSelPop = LxWndClass("UIGolemAttrSelPop", LWnd)
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemAttrSelPop:UIGolemAttrSelPop()
	self._toggleList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemAttrSelPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemAttrSelPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemAttrSelPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIGolemAttrSelPop:InitMessage()

end

function UIGolemAttrSelPop:InitEvent()
	self:SetWndClick(self.mBgImage,function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mBtnSel,function() self:OnClickSel() end)
end

function UIGolemAttrSelPop:AttrListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local attrIcon = self:FindWndTrans(root,"AttrIcon")
	local nameText = self:FindWndTrans(root,"NameText")
	local numText = self:FindWndTrans(root,"NumText")
	local checkmark = self:FindWndTrans(root,"Toggle/Background/Checkmark")

	local type = itemdata.type
	local attrId = itemdata.attrId
	local index = itemdata.index

	local selId = -1
	if type == 1 then
		selId = self._mainAttrId
	else
		local _i = self._isHaveMain and index - 1 or index
		selId = self._minorAttrIdList[_i]
	end
	CS.ShowObject(checkmark,selId == attrId)
	self._toggleList[index.."_"..attrId] = checkmark
	local arrtRef = gModelGolem:GetGolemAttrRefByAttrGroupIdAndLv(attrId,1)
	local attr = arrtRef.attr[1]

	local attrRefId,attrType,attrNum = attr.attrRefId,attr.attrType,attr.attrNum
	local attriconStr = gModelHero:GetAttributeIconById(attrRefId)
	local attrName = gModelHero:GetAttributeNameById(attrRefId)
	local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrNum)
	self:SetWndEasyImage(attrIcon,attriconStr)
	self:SetWndText(nameText,attrName)
	self:SetWndText(numText,value)

	self:SetWndClick(root,function ()
		self:OnClickToogle(type,attrId,index)
	end)
end

function UIGolemAttrSelPop:InitAttrList(trans,list)
	local key = trans:GetInstanceID()
	local uiAttrList = self:FindUIScroll(key)
	if uiAttrList then
		uiAttrList:RefreshList(list)
	else
		uiAttrList = self:GetUIScroll(key)
		uiAttrList:Create(trans,list,function(...) self:AttrListItem(...) end)
	end
end

function UIGolemAttrSelPop:ListItem(list,item, itemdata, itempos)
	local titleText = self:FindWndTrans(item,"TitleBg/TitleText")
	local attrScroll = self:FindWndTrans(item,"AttrScroll")

	local layoutEle = item:GetComponent(typeLayoutElement)

	local type = itemdata.type
	local attr = string.split(itemdata.attr,",")

	local titleStr
	if type == ModelGolem.GOLEM_DIV_ATTR_PRIME then
		titleStr = ccClientText(33282)
	else
		if self._isHaveMain then
			titleStr = string.replace(ccClientText(33292),itempos - 1)
		else
			titleStr = string.replace(ccClientText(33292),itempos)
		end
	end
	self:SetWndText(titleText,titleStr)

	local attrList = {}
	for i, v in ipairs(attr) do
		table.insert(attrList,{type = type,attrId = tonumber(v),index = itempos})
	end
	self:InitAttrList(attrScroll,attrList)

	if layoutEle then
		local hI = math.ceil(#attrList / 2)
		layoutEle.preferredHeight = hI * 40 + 58
	end
end

function UIGolemAttrSelPop:OnClickToogle(type,attrId,index)
	local mainAttrId = self._mainAttrId
	local minorAttrIdList = self._minorAttrIdList
	local _toggleList = self._toggleList or {}
	local oldId = -1
	if type == 1 then
		oldId = mainAttrId
	else
		local _i = self._isHaveMain and index - 1 or index
		oldId = minorAttrIdList[_i]
		for i, v in ipairs(minorAttrIdList) do
			if _i ~= i and v == attrId then
				GF.ShowMessage(ccClientText(33293))
				return
			end
		end
	end
	if oldId and oldId > 0 then
		local trans = _toggleList[index.."_"..oldId]
		CS.ShowObject(trans,false)
	end
	local trans = _toggleList[index.."_"..attrId]
	CS.ShowObject(trans,true)
	if type == 1 then
		self._mainAttrId = attrId
	else
		local _i = self._isHaveMain and index - 1 or index
		self._minorAttrIdList[_i] = attrId
	end
end
function UIGolemAttrSelPop:OnClickSel()
	FireEvent(EventNames.ON_GOLEM_SELECT_ATTR,self._mainAttrId,self._minorAttrIdList)
	self:WndClose()
end
function UIGolemAttrSelPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(33284))
	self:SetWndButtonText(self.mBtnSel,ccClientText(29546))

--[[	local desStr = self:GetWndArg("desStr")
	self:SetWndText(self.mDesText,desStr)]]

	local showTitle = self:GetWndArg("showTitle")
	self:SetWndText(self.mDesText,showTitle)

	local attrList = self:GetWndArg("attrList") or {}
	self._mainAttrId = self:GetWndArg("mainAttrId") or -1
	self._minorAttrIdList = self:GetWndArg("minorAttrIdList") or {}


	local isHaveMain = false
	for i, v in ipairs(attrList) do
		if v.type == 1 then
			isHaveMain = true
			break
		end
	end
	self._isHaveMain = isHaveMain
	local uiList = self:GetUIScroll("mCellScroll")
	uiList:Create(self.mCellScroll,attrList,function(...) self:ListItem(...) end)
	uiList:EnableScroll(true,false)
end
------------------------------------------------------------------
return UIGolemAttrSelPop


