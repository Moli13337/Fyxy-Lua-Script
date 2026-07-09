---
--- Created by BY.
--- DateTime: 2023/10/25 20:15:48
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubCHNCollection:LChildWnd
local UISubCHNCollection = LxWndClass("UISubCHNCollection", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubCHNCollection:UISubCHNCollection()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubCHNCollection:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubCHNCollection:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubCHNCollection:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

--function UISubCHNCollection:ResetData(pb)
--	local sid = pb.sid
--	if(self._sid ~= sid)then
--		return
--	end
--	for i, v in ipairs(pb.pages) do
--		if self._pageId == v.pageId then
--			local page = gModelActivity:GenerateActivePageDataFromPb(v)
--			self._entry = page.entry
--			break
--		end
--	end
--	self:RefreshData()
--end

function UISubCHNCollection:RefreshData()
	local _itemId = self._itemId
	if _itemId and _itemId ~= "" then
		local list =  string.split(_itemId,"|")
		local _uiItemList = self._uiItemList
		if _uiItemList then
			_uiItemList:RefreshList(list)
		else
			_uiItemList = self:GetUIScroll("collectionList")
			_uiItemList:Create(self.mItemSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
			_uiItemList:EnableScroll(true,true)
			self._uiItemList = _uiItemList
		end
		_uiItemList:DrawAllItems()
	end
end

function UISubCHNCollection:InitMessage()
	--self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
	--self:ResetData(pb)
	--end)
end

function UISubCHNCollection:InitEvent()

end

function UISubCHNCollection:InitCommand()
	self._sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	self._pageId = entry[1].pageId
	self._entry = entry
	--local activitySidData = gModelActivity:GetActivityBySid(self._sid)
	--local dataSid = JSON.decode(activitySidData.moreInfo)
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config

	local privilegeHero,heroCollectPos,privilegeHeroTxt,tipsDescription,itemId,heroCollrctTitleTxt,dropTxtPos
	= data.heroCollect,data.heroCollectPos,data.dropTxt,data.tipsDescription,data.dropItemId,data.heroCollrctTitleTxt,data.dropTxtPos
	if privilegeHero and privilegeHero > 0 then
		local ref = gModelHero:GetShowEffectById(privilegeHero)
		self:CreateWndSpine(self.mHeroPaint,ref.heroDrawing,"collectionHero",false,function(dpSpine)
			dpSpine:SetScale(0.8)
		end)
		local privilegeHeroPosArr = string.split(heroCollectPos,"|")
		self.mHeroPaint.anchoredPosition = Vector3(tonumber(privilegeHeroPosArr[1]),tonumber(privilegeHeroPosArr[2]),0)
	end
	if not string.isempty(privilegeHeroTxt) then
		local str = string.gsub(privilegeHeroTxt,"\\n","\n")
		self:SetWndText(self.mDesText,str)
		CS.ShowObject(self.mDesBg,true)
		local arr = string.split(dropTxtPos,"|")
		local isScale = arr[1] and arr[1] == "1"
		if isScale then
			self.mBg.localScale = Vector2(-1,1)
		end
		if arr[2] then
			local pos = string.split(arr[2],",")
			self.mDesBg.anchoredPosition = Vector2(tonumber(pos[1]),tonumber(pos[2]))
		end
	end
	if not string.isempty(heroCollrctTitleTxt) then
		self:SetWndText(self.mRuleTitleText,ccClientText(22200))
		self:SetWndText(self.mItemTitleText,heroCollrctTitleTxt)
	end
	if tipsDescription and tipsDescription ~= "" then
		local strArr = string.split(tipsDescription,"|")
		local _uiRuleList = self:GetUIScroll("mRuleSuper")
		_uiRuleList:Create(self.mRuleSuper,strArr,function (...) self:RuleListItem(...) end,UIItemList.SUPER)
		_uiRuleList:EnableScroll(true,false)
	end
	self._itemId = itemId
	self:RefreshData()
end

function UISubCHNCollection:RuleListItem(list, item, itemdata, itempos)
	local text = CS.FindTrans(item,"UIText")
	self:SetWndText(text,itemdata)
	local uiText = LxUiHelper.FindXTextCtrl(text)
	local height = uiText.preferredHeight
	LxUiHelper.SetSizeWithCurAnchor(item,1,height)
end

function UISubCHNCollection:ListItem(list,item, itemdata, itempos)
	local icon = CS.FindTrans(item,"Image")
	local text = CS.FindTrans(item,"NumBg/UIText")

	local refId = tonumber(itemdata)
	local ref = gModelItem:GetRefByRefId(refId)
	local itemNum = gModelItem:GetNumByRefId(refId)
	self:SetWndEasyImage(icon,ref.icon)
	self:SetWndText(text,itemNum)

	local itemInfo = {
		itemId = refId,
		itemNum = itemNum,
		itemType = 1,
	}
	self:SetWndClick(item,function ()
		gModelGeneral:ShowCommonItemTipWnd(itemInfo,{showSkinCode=true})
	end)
end
------------------------------------------------------------------
return UISubCHNCollection


