---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISistemNotice:LWnd
local UISistemNotice = LxWndClass("UISistemNotice", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISistemNotice:UISistemNotice()
	self._MoveKey = "MoveKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISistemNotice:OnWndClose()
	self:ClearCommonIconList(self._uiHyperList)
	self._uiHyperList = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISistemNotice:OnCreate()
	LWnd.OnCreate(self)
	self._uiHyperList={}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISistemNotice:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitNotice()
end

function UISistemNotice:InitEvent()
	self._systemNoticeTrList = {
		[0] = {
			Scope = self.mScope,
			BGImage = self.mBGImage,
			XUIText = self.mXUIText,
			XUIText_1 = self.mXUIText_1,
		},
		[1] = {
			Scope = self.mScope2,
			BGImage = self.mBGImage2,
			XUIText = self.mXUIText2,
			XUIText_1 = self.mXUIText2_1,
		}
	}
	self:SetWndClick(self.mBtnClose, function (...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnClose2, function (...) self:OnClickClose() end)
end

function UISistemNotice:SetNoticeMove(trans,move,cutTime)
	local seqTween
	self:TweenSeqKill(self._MoveKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._MoveKey,function(seq)
			local vec,tweener
			vec = Vector2.New(move , trans.localPosition.y)
			tweener = trans:DOLocalMove(vec,cutTime)
			seq:Join(tweener)
			return seq
		end)
	end
	seqTween:SetUpdate(true)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._MoveKey)
		self:EndNotice()

	end)
end

function UISistemNotice:InitNotice()
	local info=gModelChat:GetNoticeInfo()

	local isVie119 = self:GetWndArg("isVie119")

	if isVie119 then
		info={}
		info.msg = ccClientText(180)
	end
	if not info then
		self:WndClose()
		return
	end
	local ref = gModelChat:GetMailNoticesRefByRefId(tonumber(info.atPlayerId))
	local bgRes = ref and ref.bgRes or 0
	local isRes = bgRes == 1
	CS.ShowObject(self.mBg1,not isRes)
	CS.ShowObject(self.mBg2,isRes)

	local _systemNoticeTrList = self._systemNoticeTrList or {}
	local _systemNoticeTr = _systemNoticeTrList[bgRes]
	if not _systemNoticeTr then
		self:OnClickClose()
		return
	end
	local Scope = _systemNoticeTr.Scope
	local XUIText = _systemNoticeTr.XUIText
	local XUIText_1 = _systemNoticeTr.XUIText_1
	local BGImage = _systemNoticeTr.BGImage

	self._width = Scope.rect.width
	local msg=gModelChat:SetChatSkipFun(XUIText,"key",info,info.msg,self._uiHyperList, self:GetWndName(),false)
	local name=gModelChat:GetMailNoticesRefName(tonumber(info.atPlayerId))
	if not isRes or gLGameLanguage:IsJapanRegion() then
		--防止超框去掉换行符号
		msg = string.gsub(msg, '<br>', "")
	end
	self:SetWndText(XUIText,name.."："..msg)
	local width = XUIText_1.preferredWidth
	BGImage.localPosition=Vector2.New(self._width/2,BGImage.localPosition.y)
	local noticesSpeed = gModelChat:GetChatConfigRefByKey("noticesSpeed")
	self:SetNoticeMove(BGImage,-(width + 60 + self._width/2),width / noticesSpeed)
end

function UISistemNotice:EndNotice()
	gModelChat:DelNoticeInfo()
	self:InitNotice()
end

function UISistemNotice:OnClickClose()
	gModelChat:DelAllNoticeInfo()
	LPlayerPrefs.SetAnnCloseTime(tostring(GetTimestamp()))
	self:WndClose()
end
------------------------------------------------------------------
return UISistemNotice


