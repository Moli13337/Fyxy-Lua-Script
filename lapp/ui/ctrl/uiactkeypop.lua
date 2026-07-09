---
--- Created by BY.
--- DateTime: 2023/10/29 11:47:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActKeyPop:LWnd
local UIActKeyPop = LxWndClass("UIActKeyPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActKeyPop:UIActKeyPop()
	self._timeKey = "ActivityAnswerPop_timeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActKeyPop:OnWndClose()
	self:TimerStop(self._timeKey)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActKeyPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActKeyPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIActKeyPop:InitEvent()
	self:SetWndClick(self.mBtnBg, function(...) self:WndClose() end)
end
function UIActKeyPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (pb)
		local sid = pb.sid
		if(self._sid ~= sid)then return end
		self:WndClose()
	end)
end

function UIActKeyPop:ListItem(list,item, itemdata, itempos)
	local itext = self:FindWndTrans(item,"IText")
	local text = self:FindWndTrans(item,"UIText")
	local yesImg = self:FindWndTrans(item,"YesImg")
	local list = {
		"A","B","C","D"
	}
	self:SetWndText(itext,list[itempos])
	self:SetWndText(text,itemdata)
	CS.ShowObject(yesImg,self._msIsAnswer and self._msIsAnswer == itempos)
	self:SetWndClick(item,function ()
		local _rounds = self._rounds
		if _rounds then
			gModelGeneral:OpenUIOrdinTips({refId = 110040,para = {list[itempos]},func = function()
				if not self._rounds then return end
				gModelActivity:OnActivitySpecialOpReq(self._sid,0,0,nil,"2|"..self._rounds.."="..itempos,ModelActivity.MAGIC_ACADEMY_ANSWER_QUESTIONS)
			end})
		elseif self._meIsWeed then
			GF.ShowMessage(ccClientText(26438))
		end
	end)
end

function UIActKeyPop:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	end
end

function UIActKeyPop:InitCommand()
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	local type = self:GetWndArg("type") or 2
	CS.ShowObject(self.mBtnBg,type == 1)
	CS.ShowObject(self.mCloseTip,type == 1)
	local para = self:GetWndArg("para")
	if not para then return end

	self._sid = para.sid
	local title = para.title or ""
	local endTime = para.endTime or 0
	local refId = para.refId
	self._rounds = para.rounds
	self._msIsAnswer = para.msIsAnswer
	self._meIsWeed = para.meIsWeed
	if not refId then return end
	local ref = GameTable.IssueRef[refId]
	self:SetWndText(self.mTitleText,title)
	self:SetWndText(self.mDesText,ccLngText(ref.dec))
	self:SetWndText(self.mTipsText,ccClientText(26429))
	local list = string.split(ccLngText(ref.question),"|")
	local _uiList = self:GetUIScroll("ActivityAnswerAwardPop_mCellScroll")
	_uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)

	if not endTime then return end
	if endTime <= 0 then return end
	self._endTime = endTime
	self:TimerStop(self._timeKey)
	self:TimerStart(self._timeKey,1,false,-1)
	self:SetTime()
end

function UIActKeyPop:SetTime()
	local endTime = self._endTime or 0
	local time = GetTimestamp()
	local timespan = endTime/1000 - time
	if(timespan < 0)then
		self:WndClose()
		return
	end
	local timeStr = LUtil.FormatTimespanCn(timespan)
	timeStr = string.replace(ccClientText(26428),timeStr)
	self:SetWndText(self.mTimeText,timeStr)
end
------------------------------------------------------------------
return UIActKeyPop


