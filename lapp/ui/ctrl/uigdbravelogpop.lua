---
--- Created by BY.
--- DateTime: 2023/10/19 19:58:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdBraveLogPop:LWnd
local UIGdBraveLogPop = LxWndClass("UIGdBraveLogPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdBraveLogPop:UIGdBraveLogPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdBraveLogPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdBraveLogPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdBraveLogPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end


function UIGdBraveLogPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildBraveLogResp,function (...)
		self:RefreshData()
	end)
end

function UIGdBraveLogPop:RefreshData()
	local list=gModelGuild:GetGuildBraveLogList()
	CS.ShowObject(self.mTipsImage,#list<=0)
	if(self._uiList)then
		self._uiList:RefreshList(list)
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end, UIItemList.WRAP)
	end
end

function UIGdBraveLogPop:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(14120))
	self:SetWndText(self.mTipsText,ccClientText(14127))


	--self:RefreshData()
	gModelGuild:OnGuildBraveLogReq()
end

function UIGdBraveLogPop:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
end

function UIGdBraveLogPop:ListItem(list,item, itemdata, itempos)
	local passText= CS.FindTrans(item,"PassText")
	local nameText= CS.FindTrans(item,"NameText")
	local timeText= CS.FindTrans(item,"TimeText")
	local text1= CS.FindTrans(item,"Text1")
	--local textList={}
	--for i = 1, 8 do
	--	local text= CS.FindTrans(item,"Text"..i)
	--	textList[i]=text
	--end
	self:SetWndText(passText,string.replace(ccClientText(14121),itemdata.braveId))
	local ref=gModelGuild:GetGuildDungeonMonsterRefByRefId(itemdata.braveId)
	self:SetWndText(nameText,ccLngText(ref.chapterName))
	self:InitTextSizeWithLanguage(nameText,-4)
	self:InitTextLineWithLanguage(nameText,-40)
	local time=tonumber(itemdata.killTime)
	local str=LUtil.OSDate("%Y/%m/%d", time/1000)
	self:SetWndText(timeText,str)
	--self:SetWndText(textList[1],ccClientText(14122))
	--self:SetWndText(textList[2],ccClientText(14123))
	--self:SetWndText(textList[3],ccClientText(14124))
	--self:SetWndText(textList[4],ccClientText(14125))
	local timespan=tonumber(itemdata.battleTime)/1000
	--local systime=GetTimestamp()
	--local timespan= systime-battTime/1000
	local h=math.floor(timespan/3600)
	local spanStr=""
	if(h<24)then
		local m=math.floor(timespan/60)%60
		local s=math.floor(timespan)%60
		spanStr= string.format("%02d:%02d:%02d",h,m,s)
	else
		spanStr=math.floor(timespan/(3600*24))..ccClientText(10304)
	end

	local str = string.replace(ccClientText(14122),spanStr)
	--self:SetWndText(textList[1],str)
	str = str .."\n".. string.replace(ccClientText(14123),itemdata.attackCount)
	--self:SetWndText(textList[2],str)
	local num = LUtil.NumberCoversion(itemdata.hurtCount)
	str = str .."\n".. string.replace(ccClientText(14124),itemdata.hurtName,num)
	--self:SetWndText(textList[3], str)
	local _item = LxDataHelper.ParseItem_3(ref.killRewardGuild)
	str = str .."\n".. string.replace(ccClientText(14125),_item.itemNum)
	self:SetWndText(text1,str)
	local uiText = LxUiHelper.FindXTextCtrl(text1)
	local height = uiText.preferredHeight
	LxUiHelper.SetSizeWithCurAnchor(item,1,height + 20)
end
------------------------------------------------------------------
return UIGdBraveLogPop


