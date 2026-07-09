---
--- Created by BY.
--- DateTime: 2022/11/17 15:27:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemItemPop:LWnd
local UIGolemItemPop = LxWndClass("UIGolemItemPop", LWnd)
local typeof = typeof
local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemItemPop:UIGolemItemPop()
	self._delayUpdateScrollTimerList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemItemPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemItemPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemItemPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGolemItemPop:InitEvent()
	self:SetWndClick(self.mBgImage,function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mBtnUse,function() self:OnClickUse() end)
end

function UIGolemItemPop:UpdateResultText(ResultText, ResultNode, text, key, normalized)
	self:SetWndText(ResultText, text)
	self:StartDelayTimer(ResultNode, key, normalized)
end

function UIGolemItemPop:SetItemInfo(refId)
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
function UIGolemItemPop:StartDelayTimer(ResultNode, key, normalized)
	if not ResultNode then
		return
	end
	local resultNode = ResultNode:GetComponent(typeOfScrollRect)
	local _delayUpdateScrollTimerList = self._delayUpdateScrollTimerList
	local _delayUpdateScrollTimer = _delayUpdateScrollTimerList[key]
	if _delayUpdateScrollTimer then
		return
	end
	_delayUpdateScrollTimer = LxTimer.DelayFrameCall(function()
		if normalized then
			resultNode.verticalNormalizedPosition = normalized
		end
		_delayUpdateScrollTimer = nil
	end, 1)
	self._delayUpdateScrollTimerList[key] = _delayUpdateScrollTimer
end


function UIGolemItemPop:SetAttrItem(trans,arrtRef)--GolemAttrRef
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
function UIGolemItemPop:InitMessage()

end
function UIGolemItemPop:InitCommand()
	self:SetWndText(self.mDesTitleText,ccClientText(33277))
	self:SetWndText(self.mSelTitleText,ccClientText(33278))
	self:SetWndButtonText(self.mBtnUse,ccClientText(10228))

	local refId = self:GetWndArg("refId")
	self.refId = refId
	local ref = gModelItem:GetRefByRefId(refId)
	self:SetItemInfo(refId)
	self:UpdateResultText(self.mDesText, self.mResultNode, ccLngText(ref.description), "key")

	local showResultNode = true
	if string.isempty(ref.typeDate)then
		CS.ShowObject(self.mResultNode,showResultNode)
		return
	end

	local typeDate = string.split(ref.typeDate,"|")
	local mainAttr = typeDate[2]
	local minorAttrList = {}
	for i, v in ipairs(typeDate) do
		if i > 2 then
			table.insert(minorAttrList,v)
		end
	end
	local arrtStr = ""
	if not string.isempty(mainAttr)then
		local arr = string.split(mainAttr,"=")
		local attrRandom = tonumber(arr[2])
		if attrRandom == 0 then
			local mainAttrGroup = string.split(arr[1],",")
			local len = #mainAttrGroup
			if len > 1 then
				arrtStr = string.replace(ccClientText(33288),1)
				arrtStr = string.replace(ccClientText(33279),arrtStr)
			elseif len == 1 then
				local first = tonumber(mainAttrGroup[1])
				if first then
					local arrtRef = gModelGolem:GetGolemAttrRefByAttrGroupIdAndLv(first,ModelGolem.GOLEM_ATTRGROUP_INIT_LV)
					if arrtRef then
						local attr = arrtRef.attr[1]
						local attrRefId,attrType,attrNum = attr.attrRefId,attr.attrType,attr.attrNum
						local attrName = gModelHero:GetAttributeNameById(attrRefId)
						local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrNum)
						local attrStr = string.replace("#a1# +#a2#",attrName,value)
						arrtStr = string.replace(ccClientText(33279),attrStr)
						--self:SetAttrItem(self.mMainAttrBg,arrtRef)
						--CS.ShowObject(self.mMainAttrBg,true)
					end
				end
			end
		else
			arrtStr = string.replace(ccClientText(33280),1)
			arrtStr = string.replace(ccClientText(33279),arrtStr)
		end
	end
	CS.ShowObject(self.mResultNode,showResultNode)

	arrtStr = arrtStr .."\n\n"
	if #minorAttrList > 0 then
		local minorStr = ""
		local gNum,sNum = 0,0
		for i, v in ipairs(minorAttrList) do
			local arr = string.split(v,"=")
			if arr[2] == "0" then
				sNum = sNum + 1
			else
				gNum = gNum + 1
			end
		end
		if gNum > 0 then
			minorStr = string.replace(ccClientText(33280),gNum)
		end
		if sNum > 0 then
			if string.isempty(minorStr)then
				minorStr = string.replace(ccClientText(33280),sNum)
			else
				minorStr = minorStr .. "\n" ..string.replace(ccClientText(33280),sNum)
			end
		end
		if gNum > 0 or sNum > 0 then
			minorStr = string.replace(ccClientText(33281),minorStr)
		end
		arrtStr = arrtStr ..minorStr
	end
	self:SetWndText(self.mSelDesText,arrtStr)
end

function UIGolemItemPop:OnClickUse()
	GF.OpenWnd("UIGolemSelPop",{refId = self.refId})
	self:WndClose()
end
------------------------------------------------------------------
return UIGolemItemPop


