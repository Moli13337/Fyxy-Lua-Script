---
--- Created by BY.
--- DateTime: 2023/10/11 11:47:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISayAirSetPop:LWnd
local UISayAirSetPop = LxWndClass("UISayAirSetPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISayAirSetPop:UISayAirSetPop()
	self._channelChecks = {}
	self._channelBools = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISayAirSetPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISayAirSetPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISayAirSetPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISayAirSetPop:OnClickClose()
	local list = {}
	for i, v in pairs(self._channelBools) do
		if v then
			table.insert(list,i)
		end
	end
	gModelChat:SetAirChannelList(list)
	FireEvent(EventNames.ON_CHAT_CHANNEL_SET)
	self:WndClose()
end

function UISayAirSetPop:InitEvent()
	self:SetWndClick(self.mBgImage, function (...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnClose, function (...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnHelp, function (...) self:OnClickHelp() end)
end

function UISayAirSetPop:InitMessage()

end

function UISayAirSetPop:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local toggleText = self:FindWndTrans(item,"Root/ToggleText")
	local checkmark = self:FindWndTrans(item,"Root/Background/Checkmark")
	local ref = itemdata.ref
	local bool = itemdata.bool
	CS.ShowObject(checkmark,bool)

	local channelId = ref.channelId
	self._channelChecks[channelId] = checkmark
	self._channelBools[channelId] = bool
	self:SetWndText(toggleText,ccLngText(ref.channel))
	self:SetWndClick(root,function ()
		local bool = gModelChat:GetChatChannelIsOpent(channelId,1,true)
		if(not bool)then
			return
		end
		self:OnClickToogle(channelId)
	end)
end

function UISayAirSetPop:OnClickHelp()
	GF.OpenWndUp("UIBzTips",{refId = 87})
end

function UISayAirSetPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(11136))
	self:SetWndText(self.mTitleText,ccClientText(11137))
	self:InitTextLineWithLanguage(self.mTitleText, 40)

	local list = gModelChat:GetAirChannelSetList()
	local msgList = self:GetUIScroll("mChannelCellSuper")
	msgList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end, UIItemList.SUPER_GRID)
	msgList:EnableScroll(false,false)
end

function UISayAirSetPop:OnClickToogle(channelId)
	local bool = self._channelBools[channelId]
	if bool then
		local isShow = false
		for i, v in pairs(self._channelBools) do
			if channelId ~= i and v then
				isShow = true
				break
			end
		end
		if not isShow then
			GF.ShowMessage(ccClientText(11138))
			return
		end
	end
	local checkmark = self._channelChecks[channelId]
	CS.ShowObject(checkmark,not bool)
	self._channelBools[channelId] = not bool
end
------------------------------------------------------------------
return UISayAirSetPop


