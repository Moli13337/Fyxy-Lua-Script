---
--- Created by BY.
--- DateTime: 2022/11/17 20:10:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemSelPop:LWnd
local UIGolemSelPop = LxWndClass("UIGolemSelPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemSelPop:UIGolemSelPop()
	self._mainAttrId = -1
	self._minorAttrIdList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemSelPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemSelPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemSelPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGolemSelPop:InitEvent()
	self:SetWndClick(self.mBgImage,function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mBtnMainSel,function() self:OnClickArrtSel(ModelGolem.GOLEM_DIV_ATTR_PRIME) end)
	self:SetWndClick(self.mBtnMinorSel,function() self:OnClickArrtSel(ModelGolem.GOLEM_DIV_ATTR_DEPUTY) end)
	self:SetWndClick(self.mBtnUse,function() self:OnClickUse() end)
end
function UIGolemSelPop:ListItem(list,item, itemdata, itempos)
	local desText = self:FindWndTrans(item,"DesText")
	local attrBg = self:FindWndTrans(item,"AttrBg")

	local minorAttrId = itemdata
	CS.ShowObject(desText,minorAttrId == -1)
	CS.ShowObject(attrBg,minorAttrId ~= -1)
	self:SetWndText(desText,string.replace(ccClientText(33286),itempos))
	if minorAttrId ~= -1 then
		local arrtRef = gModelGolem:GetGolemAttrRefByAttrGroupIdAndLv(minorAttrId,1)
		self:SetAttrItem(attrBg,arrtRef)
	end
end
function UIGolemSelPop:InitCommand()
	self:SetWndText(self.mMainTitleText,ccClientText(33282))
	self:SetWndText(self.mMinorTitleText,ccClientText(33285))
	self:SetWndButtonText(self.mBtnMainSel,ccClientText(33284))
	self:SetWndButtonText(self.mBtnMinorSel,ccClientText(33284))
	self:SetWndButtonText(self.mBtnUse,ccClientText(29546))

	local refId = self:GetWndArg("refId")
	self.refId = refId
	self:SetItemInfo(refId)
	local ref = gModelItem:GetRefByRefId(refId)
	local typeDate = string.split(ref.typeDate,"|")
	local mainAttr = typeDate[2]
	local minorAttrList = {}
	for i, v in ipairs(typeDate) do
		if i > 2 then
			table.insert(minorAttrList,v)
			table.insert(self._minorAttrIdList,-1)
		end
	end
	self._mainAttr = mainAttr
	self._minorAttrList = minorAttrList
	self:RefreshData()
end
function UIGolemSelPop:InitMessage()
	self:WndEventRecv(EventNames.ON_GOLEM_SELECT_ATTR,function (mainAttrId,minorAttrIdList)
		self._mainAttrId = mainAttrId
		self._minorAttrIdList = minorAttrIdList
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.ItemUseResp,function (...)
		self:WndClose()
	end)
end

function UIGolemSelPop:RefreshData()
	local mainAttrId = self._mainAttrId
	CS.ShowObject(self.mMainAttrText,mainAttrId == -1)
	CS.ShowObject(self.mMainAttrBg,mainAttrId ~= -1)

	local mainAttr = string.split(self._mainAttr,"=")
	local isSel = tonumber(mainAttr[2]) == 1
	CS.ShowObject(self.mBtnMainSel,isSel)

	if mainAttrId ~= -1 then
		local arrtRef = gModelGolem:GetGolemAttrRefByAttrGroupIdAndLv(mainAttrId,ModelGolem.GOLEM_ATTRGROUP_INIT_LV)
		self:SetAttrItem(self.mMainAttrBg,arrtRef)
	else
		local mainStr = ""
		if isSel then
			mainStr = string.replace(ccClientText(33283),ccClientText(33289))
		else
			local mainAttrGroup = string.split(mainAttr[1],",")
			local len = #mainAttrGroup
			if len > 1 then
				mainStr = string.replace(ccClientText(33283),ccClientText(33287))
			elseif len == 1 then
				local first = tonumber(mainAttrGroup[1])
				if first then
					local arrtRef = gModelGolem:GetGolemAttrRefByAttrGroupIdAndLv(first,ModelGolem.GOLEM_ATTRGROUP_INIT_LV)
					self:SetAttrItem(self.mMainAttrBg,arrtRef)
					CS.ShowObject(self.mMainAttrBg,true)
				end
			end
		end
		self:SetWndText(self.mMainAttrText,mainStr)
	end

	local list = self._minorAttrIdList
	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mMinorScroll")
		self._uiList = uiList
		uiList:Create(self.mMinorScroll,list,function(...) self:ListItem(...) end)
	end
end

function UIGolemSelPop:OnClickArrtSel(selAttrType)
	local attrList = {}
	local mainAttr = string.split(self._mainAttr,"=")

	local minorAttrList = self._minorAttrList or {}
	local showTitle = ""
	local str = ""
	if mainAttr[2] == "1"then
		str = string.replace(ccClientText(33280),1)
		str = string.replace(ccClientText(33279),str)
		table.insert(attrList,{type = ModelGolem.GOLEM_DIV_ATTR_PRIME ,attr = mainAttr[1]})

		if selAttrType == ModelGolem.GOLEM_DIV_ATTR_PRIME then
			showTitle = string.replace(ccClientText(33279),string.replace(ccClientText(33280),1))
		end
	end

	if #minorAttrList > 0 then
		local num = 0
		for i, v in ipairs(minorAttrList) do
			local arr = string.split(v,"=")
			if arr[2] == "1"then
				num = num + 1
				table.insert(attrList,{type = ModelGolem.GOLEM_DIV_ATTR_DEPUTY ,attr = arr[1]})
			end
		end

		local minorStr
		if selAttrType == ModelGolem.GOLEM_DIV_ATTR_PRIME then
			minorStr = string.replace(ccClientText(33279),num)
		elseif selAttrType == ModelGolem.GOLEM_DIV_ATTR_DEPUTY then
			minorStr = string.replace(ccClientText(33281),num)

			showTitle = string.replace(ccClientText(33281),string.replace(ccClientText(33280),num))
		end

		if string.isempty(str) then
			str = minorStr
		else
			str = str .."\n\n"..minorStr
		end
	end
	GF.OpenWnd("UIGolemAttrSelPop",{
		desStr = str,
		showTitle = showTitle,
		selAttrType = selAttrType,
		attrList = attrList,
		mainAttrId = self._mainAttrId,
		minorAttrIdList = self._minorAttrIdList
	})
end
function UIGolemSelPop:SetAttrItem(trans,arrtRef)--GolemAttrRef
	local attrIcon = self:FindWndTrans(trans,"AttrIcon")
	local attrNameText = self:FindWndTrans(trans,"AttrNameText")
	local attrNumText = self:FindWndTrans(trans,"AttrNumText")

	local attr = arrtRef.attr[1]
	local attrRefId,attrType,attrNum = attr.attrRefId,attr.attrType,attr.attrNum
	local attriconStr = gModelHero:GetAttributeIconById(attrRefId)
	local attrName = gModelHero:GetAttributeNameById(attrRefId)
	local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrNum)
	self:SetWndEasyImage(attrIcon,attriconStr)
	self:SetWndText(attrNameText,attrName)
	self:SetWndText(attrNumText,value)
end
function UIGolemSelPop:SetItemInfo(refId)
	local ref = gModelItem:GetRefByRefId(refId)
	local itemInfo = {
		itemId = ref.refId,
		itemType = LItemTypeConst.TYPE_ITEM,
	}
	local heroMessage = gModelItem:GetHeroMessQualityById(ref.quality)
	local name = gModelGeneral:GetCommonItemName(itemInfo)
	local color = gModelGeneral:GetCommonItemColor(itemInfo)
	local nameStr = LUtil.FormatColorStr(name, color)

	self:SetWndEasyImage(self.mTopImg,heroMessage)
	self:CreateCommonIconImpl(self.mIcon,itemInfo,{showNum = false})
	self:SetWndText(self.mNameText,nameStr)

	local typeDate = string.split(ref.typeDate,"|")
	local golemId = tonumber(typeDate[1])
	local golemRef = gModelGolem:GetGolemElementRefByRefId(golemId)
	if golemRef then
		local typeStr = string.replace(ccClientText(33276),golemRef.type)
		self:SetWndText(self.mTypeText,LUtil.FormatColorStr(typeStr, color))
	end
end

function UIGolemSelPop:OnClickUse()
	local mainAttrId = self._mainAttrId
	local mainAttr = string.split(self._mainAttr,"=")
	if mainAttr[2] == "1" and mainAttrId == -1 then
		GF.ShowMessage(ccClientText(33290))
		return
	end
	local minorAttrList = self._minorAttrList or {}
	local minorAttrIdStr = ""
	for i, v in ipairs(minorAttrList) do
		local minorAttr = string.split(v,"=")
		local minorAttrId = self._minorAttrIdList[i]
		if string.isempty(minorAttrIdStr)then
			minorAttrIdStr = minorAttrId
		else
			minorAttrIdStr = minorAttrIdStr .."_".. minorAttrId
		end
		if minorAttr[2] == "1" and minorAttrId == -1 then
			GF.ShowMessage(string.replace(ccClientText(33291),i))
			return
		end
	end
	local params = mainAttrId .. "_" .. minorAttrIdStr
	local info = {}
	table.insert(info,{refId = self.refId,num = 1,params = params})
	gModelGolem:CheckIsBagFull(1,function()
		gModelItem:OnItemUseReq(info)		 --向服务器发送物品使用请求
	end,self:GetWndName())
end
------------------------------------------------------------------
return UIGolemSelPop


