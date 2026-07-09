---
--- Created by BY.
--- DateTime: 2023/10/16 14:37:02
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdFlagPop:LWnd
local UIGdFlagPop = LxWndClass("UIGdFlagPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdFlagPop:UIGdFlagPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdFlagPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdFlagPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdFlagPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdFlagPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(12603))
	self:SetWndText(self.mTextFlagBg,ccClientText(12600))
	self:SetWndText(self.mTextFlagIcon,ccClientText(12601))
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(12605))

	local confirmType = self:GetWndArg("confirmType") or ModelGuild.GUILD_FLAG_TYPE_FOUND
	local flagId = self:GetWndArg("flagId")
	local flagBgId = self:GetWndArg("flagBgId")
	self._callFunc = self:GetWndArg("callFunc")
	self._flagId = flagId
	self._flagBgId = flagBgId
	self._selFlagId = flagId
	self._selFlagBgId = flagBgId
	self._confirmType = confirmType

	self:RefreshFlag()

	local list = gModelGuild:GetGuildFlagRefByType(1)
	local bgList = self:GetUIScroll("bgList")
	bgList:Create(self.mFlagBgSuper,list,function (...) self:ItemList(...) end, UIItemList.SUPER_GRID)
	bgList:EnableScroll(true,true)
	bgList:DrawAllItems()
	self._uiBgList = bgList

	list = gModelGuild:GetGuildFlagRefByType(2)
	local iconList = self:GetUIScroll("iconList")
	local loopGridView = self.mFlagIconSuper:GetComponent(typeof(SuperScrollView.LoopGridView))
	loopGridView.ColumnCount = math.ceil(#list / 2)
	iconList:Create(self.mFlagIconSuper,list,function (...) self:ItemList(...) end, UIItemList.SUPER_GRID)
	-- iconList:EnableScroll(false,true)
	iconList:DrawAllItems()
	self._uiIconList = iconList

	CS.ShowObject(self.mCostMar,confirmType == ModelGuild.GUILD_FLAG_TYPE_ALTER)
	if confirmType == ModelGuild.GUILD_FLAG_TYPE_FOUND then
		return
	end
	local guildInfo = gModelGuild:GetGuildInfo()
	local serverFlag = guildInfo.serverFlag
	local isFree = serverFlag == 1
	CS.ShowObject(self.mCostIcon,not isFree)
	if isFree then
		self:SetWndText(self.mCostText,ccClientText(12604))
		return
	end
	local item = gModelGuild:GetChangeFlagSpendConsume()
	self:SetWndText(self.mCostText,item.count)
	local icon = gModelItem:GetItemIconByRefId(item.refId)
	self:SetWndEasyImage(self.mCostIcon,icon)
end

function UIGdFlagPop:OnClickWndClose()
	local callFunc = self._callFunc
	if callFunc then
		callFunc()
	end
	self:WndClose()
end

function UIGdFlagPop:RefreshFlag()
	local flagId = self._selFlagId
	local flagBgId = self._selFlagBgId
	local ref = gModelGuild:GetGuildFlagRefByRefId(flagBgId)
	if ref then
		self:SetWndEasyImage(self.mFlagBg,ref.res)
	end
	ref = gModelGuild:GetGuildFlagRefByRefId(flagId)
	if ref then
		self:SetWndEasyImage(self.mFlagIcon,ref.res)
	end
end

function UIGdFlagPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:OnClickWndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickWndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnConfirm, function(...) self:OnClickConfirm() end)
end

function UIGdFlagPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildSetFlagResp,function (...)
		GF.ShowMessage(ccClientText(12606))
		self:OnClickWndClose()
	end)
end

function UIGdFlagPop:OnClickFlag(itemdata)
	local type = itemdata.type
	if type == 1 then
		self._selFlagBgId = itemdata.refId
		self._uiBgList:DrawAllItems()
	else
		self._selFlagId = itemdata.refId
		self._uiIconList:DrawAllItems()
	end
	self:RefreshFlag()
end

function UIGdFlagPop:ItemList(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local icon = self:FindWndTrans(root,"Icon")
	local selImg = self:FindWndTrans(root,"SelImg")
	local useImg = self:FindWndTrans(root,"UseImg")

	local res = itemdata.type == 1 and itemdata.color or itemdata.res
	self:SetWndEasyImage(icon, res)
	local isSel = itemdata.refId == self._selFlagId or itemdata.refId == self._selFlagBgId
	CS.ShowObject(selImg,isSel)
	local isUse = itemdata.refId == self._flagId or itemdata.refId == self._flagBgId
	CS.ShowObject(useImg,isUse)
	if isUse then
		self:SetWndEasyImage(useImg, "role_txt_1") --防止加载中文
	end
	self:SetWndClick(root,function ()
		self:OnClickFlag(itemdata)
	end)
end

function UIGdFlagPop:OnClickConfirm()
	local _selFlagBgId = self._selFlagBgId
	local _selFlagId = self._selFlagId
	if self._confirmType == ModelGuild.GUILD_FLAG_TYPE_FOUND then
		FireEvent(EventNames.ON_GUILD_FLAG_CHANGE,_selFlagBgId,_selFlagId)
		self:OnClickWndClose()
	else
		if _selFlagBgId == self._flagBgId and _selFlagId == self._flagId then
			self:OnClickWndClose()
			return
		end
		local guildInfo = gModelGuild:GetGuildInfo()
		local serverFlag = guildInfo.serverFlag
		local isFree = serverFlag == 1
		if not isFree then
			local item = gModelGuild:GetChangeFlagSpendConsume()
			local num = gModelItem:GetNumByRefId(item.refId)
			if(num < item.count)then
				local wndName = self:GetWndName()
				gModelGeneral:OpenGetWayWnd({itemId=item.refId,srcWnd = wndName})
				return
			end
		end
		gModelGuild:OnGuildSetFlagReq(_selFlagId,_selFlagBgId)
	end
end
------------------------------------------------------------------
return UIGdFlagPop


