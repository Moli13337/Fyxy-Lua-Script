---
--- Created by Administrator.
--- DateTime: 2023/10/20 16:34:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenDestRwd:LWnd
local UIEdenDestRwd = LxWndClass("UIEdenDestRwd", LWnd)
local Tweening = DG.Tweening

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenDestRwd:UIEdenDestRwd()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenDestRwd:OnWndClose()

	self:ClearTween()

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenDestRwd:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenDestRwd:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()

	--self:StartTween()
	self:InitUIEvent()

	self:WndNetMsgRecv(LProtoIds.WonderlandDestinationResp,function (pb)
		self._reward = pb
		self:StartTween()
	end)
	gModelWonderland:WonderlandDestinationReq()
end

function UIEdenDestRwd:ClearTween()
	if self._seq then
		self._seq:Kill(false)
		self._seq = nil
	end

	if self._iconList then
		self._iconList:Destroy()
		self._iconList = nil
	end
end

function UIEdenDestRwd:StartTween()
	local root = self.mCommonBg_5
	root.transform.localRotation = Quaternion.Euler(90,0,0)
	local seq =Tweening.DOTween.Sequence()
	local duration = 0.4
	local rotateTween = root.transform:DORotate(Vector3.New(0,0,0),duration)
	seq:Append(rotateTween)
	seq:InsertCallback(0.1,function ()
		self:RefreshUI()
	end)
	seq:OnComplete(function()
		self._seq = nil
	end)
	seq:PlayForward()

	self._seq = seq
end

function UIEdenDestRwd:RefreshUI()
	local itemList = {}
	if self._reward then
		for k,v in ipairs(self._reward.itemList) do
			local data = {
				itemId = v.itemId,
				itemNum = v.count,
				itemType = v.type,

			}
			table.insert(itemList,data)
		end
	end


	local uiIconEasyList = self._iconList
	if not uiIconEasyList then
		uiIconEasyList = UIIconEasyList:New()
		self._iconList = uiIconEasyList
		uiIconEasyList:Create(self, self.mItemList)
		uiIconEasyList:EnableIconAni(true)

	end
	uiIconEasyList:EnableScroll(true, true)
	uiIconEasyList:RefreshList(itemList)

	if #itemList>4 then
		uiIconEasyList:EnableScroll(true,true)
		local list = uiIconEasyList:GetUIList()
		list:SetContentPosition(0,0)
	end

	local effectName = "fx_ui_gongxihuode"
	self:CreateWndEffect(self.mTitle,effectName,effectName,120)

	self:CreateRole()
end

function UIEdenDestRwd:InitUIEvent()
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEndBtn,function ()
		--GF.CloseWndByName("UIEden")
		--GF.ChangeMap("LCityMap")
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIEdenDestRwd:CreateRole()
	local themeId = gModelWonderland:GetThemeId()
	local spineName = gModelWonderland:GetRoleRes(themeId)
	self:CreateWndSpine(self.mRole,spineName,"rolekey",false,function (spine)
		spine:SetScale(2)
		spine:PlayAnimation(0,"idle",true)
	end)
end


function UIEdenDestRwd:SetStaticContent()
	self:SetTextTile(self.mSubTitle,ccClientText(10721))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	--local text = self:FindWndTrans(self.mEndBtn,"text")
	--self:SetWndText(text,ccClientText(16757))

	self:SetWndButtonText(self.mEndBtn,ccClientText(16757))
end


------------------------------------------------------------------
return UIEdenDestRwd


