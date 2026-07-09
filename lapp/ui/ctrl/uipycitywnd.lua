---
--- Created by BY.
--- DateTime: 2023/10/2 15:22:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPYCityWnd:LWnd
local UIPYCityWnd = LxWndClass("UIPYCityWnd", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPYCityWnd:UIPYCityWnd()
	--self:SetHideBottom()
	--self:SetHideTop()
	FireEvent(EventNames.ON_STORY_SHOW_WND,"friendCity",false)
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPYCityWnd:OnWndClose()
	LWnd.OnWndClose(self)
	self:SetChangeCity()
	FireEvent(EventNames.ON_STORY_SHOW_WND,"friendCity",true)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPYCityWnd:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPYCityWnd:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIPYCityWnd:SetChangeCity(_playerId)
	gModelPlayerSpace:SetFriendPlayerId(_playerId)
	FireEvent(EventNames.SHOW_MAIN_CHANGE_CITY)
end

function UIPYCityWnd:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end)
end

function UIPYCityWnd:InitMessage()
	--self:WndNetMsgRecv(LProtoIds.DreamFountainOtherInfoResp,function (pb)
	--	self:WndClose()
	--end)
end

function UIPYCityWnd:OnClickHelp()--点击帮助
	--local playerId = self._friendInfo._playerId
	--local helps = gModelDreamFountain:GetHelpList()
	--local helpNum = gModelDreamFountain:GetDreamFountainRefByKey("dreamFountainHelpGetNum")
	--local num = 0
	--for i, v in pairs(helps) do
	--	num = num + 1
	--	if v == playerId then
	--		GF.ShowMessage(string.replace(ccClientText(19650),self._friendInfo._name))
	--		return
	--	end
	--end
	--if num >= helpNum then
	--	GF.ShowMessage(ccClientText(19649))
	--	return
	--end
	--local list = {}
	--table.insert(list,playerId)
	--gModelDreamFountain:OnDreamFountainHelpReq(list,1)
end

function UIPYCityWnd:ListItem(list, item, itemdata, itempos)
	local icon = CS.FindTrans(item,"Icon")
	local countBar = CS.FindTrans(item,"CountBar")
	local countText = CS.FindTrans(item,"CountText")
	local countSlider = self:FindWndSlider(countBar)

	local add = itemdata.add		--加成值
	local h = itemdata.h			--基础数量
	local max = itemdata.max		--最大容量
	local item = itemdata.item		--当前物品StructRewardItem
	local refId = itemdata.refId	--物品id

	local sliderValue = item and item.count or 0
	countSlider.maxValue = max
	countSlider.value = sliderValue
	local countValue = math.floor(h * (1 + add))
	if countValue < 10 then
		countValue = string.format("%.2f",h * (1 + add))
	else
		countValue  = LUtil.NumberCoversion(countValue)
	end
	countValue = string.replace(ccClientText(19601),countValue)
	if sliderValue >= max then
		countValue = ccClientText(19663)
	end
	self:SetWndText(countText,countValue)

	local itemIcon,itemIconBg = gModelItem:GetItemImgByRefId(refId)
	self:SetWndEasyImage(icon,itemIcon)
end

function UIPYCityWnd:InitCommand()
    self:SetWndButtonText(self.mBtnHelp,ccClientText(19651))
	local list = gModelFriend:GetFriendData()
	--local _dreamInfo = gModelDreamFountain:GetFriendDreamInfo()
	--if not _dreamInfo then
	if true then
		self:WndClose()
		return
	end
	local friendInfo = nil
	for i, v in ipairs(list) do
		local id = v._playerId
		if id == _dreamInfo.playerId then
			friendInfo = v
			break
		end
	end
	if not friendInfo then
		self:WndClose()
		return
	end
	self._friendInfo = friendInfo
	self:SetWndText(self.mPowerText,LUtil.PowerNumberCoversion(friendInfo._power))
	self:SetWndText(self.mNameText,friendInfo._name)
	self:SetChangeCity(friendInfo._playerId)

	local info = {
		playerId = friendInfo._playerId,
		icon = friendInfo._head,
		headFrame = friendInfo._headFrame,
		level = friendInfo._grade,
		trans = self.mHeadIcon
	}
	local baseClass = self._baseClass
	if not baseClass then
		baseClass = HeadIcon:New(self)
		self._baseClass = baseClass
	end
	baseClass:SetHeadData(info)
	--
	--local list = gModelDreamFountain:GetItemInfoList(_dreamInfo.infos)
	--if self._uiList then
	--	self._uiList:RefreshList(list)
	--else
	--	self._uiList = self:GetUIScroll("itemList")
	--	self._uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
	--end
end

function UIPYCityWnd:OnTryTcpReconnect()
	--self:WndClose()
end

------------------------------------------------------------------
return UIPYCityWnd


