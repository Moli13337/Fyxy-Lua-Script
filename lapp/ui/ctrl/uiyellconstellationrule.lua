---
--- Created by admin.
--- DateTime: 2023/8/19 14:29:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIYellConstellationRule:LWnd
local UIYellConstellationRule = LxWndClass("UIYellConstellationRule", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIYellConstellationRule:UIYellConstellationRule()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIYellConstellationRule:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIYellConstellationRule:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIYellConstellationRule:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:SetUI()
end
function UIYellConstellationRule:SetUI()
	local titleTxt = self:FindWndTrans(self.mRuleTitle,"UIText")
	local heroImg = self._ruleData.heroImg
	local pos = Vector2.zero
	if not string.isempty(heroImg)then
		pos = Vector2.New(0,-85)
	end
	self:SetAnchorPos(self.mBg, pos)
	self:SetBgImgAndPos(self.mHeroImg,self._ruleData.heroImg,self._ruleData.heroImgPos, true)
	self:SetBgImgAndPos(self.mBotImg,self._ruleData.botImg,self._ruleData.botImgPos)

	self:SetWndEasyImage(self.mBotImg,self._ruleData.botImg)
	self:SetWndText(titleTxt,self._ruleData.title)
	self:SetRuleDivText(self._ruleData.policyTxt)
	self:SetWndText(self.mExplainTxt,self._ruleData.helpTitle)
	self:SetExplainList()
	self:SetRuleMoreList()
end

function UIYellConstellationRule:SetExplainList()
	local textArr = string.split(self._ruleData.helpTxt,"|")
	local list = textArr or {}
	local uiExplainList = self._uiExplainList
	if uiExplainList then
		uiExplainList:RefreshList(list)
	else
		uiExplainList = self:GetUIScroll("uiExplainList")
		self._uiExplainList = uiExplainList
		uiExplainList:Create(self.mExplainList,list,function(...) self:OnDrawExplainCell(...) end,UIItemList.WRAP)
	end

	local isShow = not table.isempty(list)
	CS.ShowObject(self.mExplain, isShow)
end
function UIYellConstellationRule:CreateCommonHero(item,itemdata)
	local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
	local ProbabilityTxtTrans = self:FindWndTrans(item,"ProbabilityTxt")
	local itemType,itemId,itemNum = itemdata.items[1].type,itemdata.items[1].itemId,itemdata.items[1].count
	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(IconTrans)
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	baseClass:EnableShowNum(itemNum > 1)
	baseClass:SetNoShowLv(true)
	baseClass:DoApply()
	self:SetIconClickScale(IconTrans, true)
	self:SetWndClick(IconTrans,function()
		if itemType == 2 then
			gModelGeneral:OpenHeroSimpleTip(itemId,true)
		else
			gModelGeneral:OpenItemInfoTip(itemId,itemNum)
		end
	end)
	local str = ""
	local listType = self._ruleData.listType or 1
	if listType == 2 then
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
		local moreInfo = string.split(entryCfg.moreInfo,"|")
		str = moreInfo[2] or ""
	else
		local moreInfo = string.split(JSON.decode(itemdata.moreInfo).moreInfo,"|")
		local probability = moreInfo[2]
		if(probability)then
			str = probability * 100 .. "%"
		end
	end
	self:SetWndText(ProbabilityTxtTrans,str)
end
function UIYellConstellationRule:OnDrawExplainCell(list,item,itemdata,itempos)
	local UITextTrans = self:FindWndTrans(item,"DescDiv/UIText")
	self:SetWndText(UITextTrans,itemdata)
end

function UIYellConstellationRule:SetBgImgAndPos(imgTrans, imgPath, offset, isNatize)
	if (imgPath) then
		self:SetWndEasyImage(imgTrans, imgPath,nil,true)
		if (offset and not string.isempty(offset)) then
			local pos = LxDataHelper.ParseVector2NotEmpty3(offset)
			self:SetAnchorPos(imgTrans, pos)
		end
	end
	CS.ShowObject(imgTrans, imgPath ~= nil)
end

function UIYellConstellationRule:SetRuleDivText(str)
	local isShow = not string.isempty(str)

	if gLGameLanguage:IsKoreaRegion() then
		isShow = false
	end

	CS.ShowObject(self.mPrivate, isShow)
	if not isShow then return end

	self:SetWndText(self.mRuleTxt, str)
end
function UIYellConstellationRule:InitData()
	self._ruleData = self:GetWndArg("ruleData")
	self._sid = self._ruleData.sid
end

function UIYellConstellationRule:GetItemList()
	local list ={}
	local playerLV = gModelPlayer:GetPlayerLv()
	for i, v in pairs(self._ruleData.rewardList) do
		local moreInfo = v.moreInfo
		moreInfo = JSON.decode(moreInfo)
		local moreArr = string.split(moreInfo.moreInfo,"|")
		local lvLimit = moreArr[1]
		local lvLimitArr = string.split(lvLimit,",")
		local probability = moreArr[2]
		if(playerLV >= tonumber(lvLimitArr[1]) and playerLV <= tonumber(lvLimitArr[2]) and probability)then
			table.insert(list,v)
		end
	end

	if nil~= self._ruleData.select then
		table.insert(list,self._ruleData.select )
	end
	return list
end
function UIYellConstellationRule:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mSpecialHelpBtn,function() self:OnClickSpecialHelpBtnFunc() end)
end
function UIYellConstellationRule:OnDrawRuleMoreCell(list,item,itemdata,itempos)
	self:CreateCommonHero(item,itemdata)
end
function UIYellConstellationRule:SetRuleMoreList()
	CS.ShowObject(self.mRuleMoreList,true)
	local listType = self._ruleData.listType or 1
	local list = {}
	if listType == 2 then
		list = self:GetItemList2()
	else
		list = self:GetItemList()
	end
	local uiRuleMoreList = self._uiRuleMoreList
	if uiRuleMoreList then
		uiRuleMoreList:RefreshList(list)
	else
		uiRuleMoreList = self:GetUIScroll("uiRuleMoreList")
		self._uiRuleMoreList = uiRuleMoreList
		uiRuleMoreList:Create(self.mRuleMoreList,list,function(...) self:OnDrawRuleMoreCell(...) end,UIItemList.WRAP)
	end
end
function UIYellConstellationRule:GetItemList2()
	local list ={}
	for i, v in pairs(self._ruleData.rewardList) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		local moreInfo = string.split(entryCfg.moreInfo,"|")
		local moreInfo1Arr = string.split(moreInfo[1],"=")
		if(moreInfo1Arr[3] ~= "1")then
			table.insert(list,v)
		end
	end

	if nil~= self._ruleData.select then
		table.insert(list,1,self._ruleData.select )
	end
	return list
end
------------------------------------------------------------------
return UIYellConstellationRule


