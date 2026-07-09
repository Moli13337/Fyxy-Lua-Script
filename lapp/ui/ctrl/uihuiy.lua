---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHuiY:LWnd
local UIHuiY = LxWndClass("UIHuiY", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHuiY:UIHuiY()
	self._key = "ShowVipIconImg"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHuiY:OnWndClose()
	self:ClearCommonIconList(self._hyperList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHuiY:OnCreate()
	LWnd.OnCreate(self)
	self._hyperList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHuiY:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitList()
	self:CreateWndEffect(self.mTitleImg,"fx_VIP_biaoti","fx_VIP_biaoti",100,false,false)

	local key = "fx_VIP_dengji_00"
	self:CreateWndEffect(self.mVipIcon,key,key,100,false,false,nil,nil,nil,nil,nil,function()
		self:StartTween()
	end)
	self:RefreshUI()
end

function UIHuiY:InitList()
	local uiList = self._uiList
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self,self.mVipDescList)
		uiList:EnableScroll(true,false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawDescItem(...)
		end)
		uiList:EnableLoadAnimation(true, 0, 1)
		self._uiList = uiList
	end
	LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_VIP_LVUP)
	uiList:RemoveAll()
	local list = gModelPay:GetVipDescListByVipLv(self._vip)
	for i,v in ipairs(list) do
		uiList:AddData(i,v)
	end
	uiList:RefreshList()
end

function UIHuiY:StartTween()
	local key = self._key
	local seqTween = self:TweenSeqCreate(key,function(seq)
		local waitIconTime = 2.5
		seq:AppendInterval(waitIconTime)
		seq:AppendCallback(function()
			CS.ShowObject(self.mVipIconImg,true)
		end)
		local show = YXTween.TweenFloat(0, 1, 1, function(ival)
			self.mContentCG.alpha = ival
		end):SetEase(DG.Tweening.Ease.InQuad)
		seq:Append(show)
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(key)
	end)
end

function UIHuiY:OnDrawDescItem(list, item, itemdata, itempos)
	local Div = self:FindWndTrans(item,"Div")
	local NewImgTrans = self:FindWndTrans(Div,"NewImg")
	local UpImgTrans = self:FindWndTrans(Div,"UpImg")
	local dianImgTrans = self:FindWndTrans(Div,"dianImg")
	local DescTxtTrans = self:FindWndTrans(item,"DescTxt")
	local up = itemdata.up
	local showDian = true
	if up == 1 then
		if NewImgTrans then CS.ShowObject(NewImgTrans,true) end
		--showDian = false
	else
		local nowValue = itemdata.nowValue
		if nowValue == 1 then
			if UpImgTrans then CS.ShowObject(UpImgTrans,true) end
			showDian = false
		end
	end
	if dianImgTrans then
		CS.ShowObject(dianImgTrans,showDian)
	end
	if DescTxtTrans then
		local hyperCreateFun = function(tran)
			if not CS.IsValidObject(tran) then
				return
			end
			local instanceId = tran:GetInstanceID()
			local hyper = self._hyperList[instanceId]
			if not hyper then
				hyper = UIHyperText:New()
				self._hyperList[instanceId] = hyper
				hyper:Create(tran)
			end
			return hyper
		end

		local des = ccLngText(itemdata.des)
		des = LUtil.CreateHyperWithValue(DescTxtTrans,des,hyperCreateFun,function (data)
			gModelChat:ClickHyper(data,self:GetWndName())
		end)
		--print(des,itemdata.refId)
		self:SetWndText(DescTxtTrans,des)
	end
end

function UIHuiY:InitData()
	self._vip = gModelPlayer:GetVipLevel()
	local ref = gModelVip:GetRefByVipLv(self._vip)
	if ref then
		self:SetWndEasyImage(self.mVipIconImg,ref.icon,nil,true)
	end
end

function UIHuiY:RefreshUI()
	self:SetXUITextText(self.mSecTitle,ccClientText(11908))
	self:SetWndButtonText(self.mGoToVipBtn,ccClientText(11909))
	self:SetWndText(self.mCloseTip,ccClientText(15702))
end

function UIHuiY:InitEvent()
	self:SetWndClick(self.mMask,function()
		if self:TweenSeqFind(self._key) then return end
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mGoToVipBtn,function()
		FireEvent(EventNames.ON_JUMP)						--打开vip界面请求了新活动，用于关闭老活动界面
		local wndInst = GF.FindFirstWndByName("UIHuiYPay")
		if not wndInst then
			GF.OpenWndBottom("UIHuiYPay")
		else
			FireEvent(EventNames.ON_VIPLEVEL_CHANGE)
		end
		self:WndClose()
	end)
end
------------------------------------------------------------------
return UIHuiY


