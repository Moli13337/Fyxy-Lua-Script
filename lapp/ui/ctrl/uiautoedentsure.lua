---
--- Created by LCM.
--- DateTime: 2024/3/6 15:32:17
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAutoEdenTsure:LWnd
local UIAutoEdenTsure = LxWndClass("UIAutoEdenTsure", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAutoEdenTsure:UIAutoEdenTsure()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAutoEdenTsure:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAutoEdenTsure:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAutoEdenTsure:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitMsg()
	self:InitData()
end

function UIAutoEdenTsure:TweenTreasure(bufRefId)
	local canLv,newId,level = gModelWonderland:CanTreasureLvUp(bufRefId)
	local data = {
		refId = newId,
		lv = level,
		canLvUp = canLv,
	}
	local treasure = self:FindWndTrans(self.mFlyRoot,"TreasureIcon")
	TreasureIcon.SetIcon(treasure,data,self)

	treasure.localPosition = Vector3.New(0,30,0)
	treasure.localScale = Vector3.New(1.1,1.1,1.1)

	local startPos = Vector3.zero
	self.mFlyRoot.transform.position = startPos
	CS.ShowObject(self.mFlyRoot,true)

	local wnd = GF.FindFirstWndByName("UIEden")
	if not wnd then
		self:WndClose()
		return
	end

	local endPos = wnd:GetTreasureBtnPos()
	local seqCom = self:GetSeqCom()
	local seq =seqCom:CreateSeq("cardFly")
	self._moveTweenSeq = seq
	seq:SetAutoKill(true)
	local duration = 0.6
	local tween = self.mFlyRoot.transform:DOMove(endPos,duration)
	local scaleTween = self.mFlyRoot.transform:DOScale(Vector3.New(0.5,0.5,0.5),duration)
	local rotateTween = self.mFlyRoot.transform:DORotate(Vector3.New(0,0,30),duration)
	if canLv then
		seq:AppendCallback(function ()
			self:CreateWndEffect(treasure,"ui_fx_mokashengji","lvEff",100)
		end)
		seq:AppendInterval(1)
	end
	seq:Append(tween)
	seq:Join(scaleTween)
	seq:Join(rotateTween)
	seq:OnComplete(function ()
		self._moveTweenSeq = nil
		wnd:TweenTreasureBtn()
		self:WndClose()
	end)
	seq:PlayForward()
end

function UIAutoEdenTsure:InitData()
	local bufRefId = self:GetWndArg("bufRefId")
	if not bufRefId then
		self:WndClose()
		return
	end
	self:TweenTreasure(bufRefId)
end


function UIAutoEdenTsure:InitMsg()

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end
------------------------- List -------------------------


------------------------- List -------------------------

------------------------------------------------------------------
return UIAutoEdenTsure



