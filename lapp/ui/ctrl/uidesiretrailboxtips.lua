---
--- Created by wzz.
--- DateTime: 2024/9/10 21:20:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDesireTrailBoxTips:LWnd
local UIDesireTrailBoxTips = LxWndClass("UIDesireTrailBoxTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDesireTrailBoxTips:UIDesireTrailBoxTips()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDesireTrailBoxTips:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDesireTrailBoxTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDesireTrailBoxTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 初始界面化文本
function UIDesireTrailBoxTips:InitTexts()
	self:SetWndText(self.mTxtTitle, ccClientText(45407))
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndButtonText(self.mBtnConfirm, self._canMove and ccClientText(10151) or ccClientText(10102))
end

-- 奖励列表 item
function UIDesireTrailBoxTips:OnDrawAwardItem(uilist, root, data)
	if not uilist then
		uilist = {}
		uilist.itemRoot = CS.FindTrans(root, "itemRoot")
		uilist.random = CS.FindTrans(root, "random")
	end
	CS.ShowObject(uilist.random, data.isRandom)

	self:CreateCommonIconImpl(uilist.itemRoot, data, { showNum = true })
	return uilist
end

-- 刷新界面
function UIDesireTrailBoxTips:Refresh()
	local eventRefId = self._eventRefId
	local floor      = self._floor
	self._ref        = gModelDesireTrail:GetEventAwardRef(eventRefId, floor)

	self:SetWndButtonGray(self.mBtnConfirm, not self._canMove)

	if not self._ref then
		printInfoN("奖励配置为空，eventRefId=" .. tostring(eventRefId) .. " floor=" .. tostring(floor))
		return
	end

	self:RefreshAward()
end

-- 刷新奖励
function UIDesireTrailBoxTips:RefreshAward()
	local ref = self._ref

	local itemList = LUtil.GetRefItemDataList(ref.reward)

	-- 随机奖励
	local itemList2 = LUtil.GetRefItemDataList(self._gridData.moreInfo)
	for k, v in ipairs(itemList2) do
		v.isRandom = true
		table.insert(itemList, v)
	end

	self:SetComList(self.mItemList, itemList, function(...) return self:OnDrawAwardItem(...) end)
end

-- 点击时，格子状态为移动
function UIDesireTrailBoxTips:OnClickWhenMove()
    local eventRef = gModelDesireTrail:GetEventConfig(self._eventRefId)
	local y, x = self._y, self._x

    local param = {
        x = x,
        y = y,
        type = 0,
        callback = function()
			self:OnClickWhenSelect()
		end,
    }

    gModelDesireTrail:DesireTrailOpsReq(param)
end

-- 点击时，格子状态为选中
function UIDesireTrailBoxTips:OnClickWhenSelect()
    local eventRef = gModelDesireTrail:GetEventConfig(self._eventRefId)
	local y, x = self._y, self._x

    local param = {
        x = x,
        y = y,
        type = eventRef.type,
        callback = function()
			self:WndClose()
		end,
    }

    gModelDesireTrail:DesireTrailOpsReq(param)
end

-- 点击确认按钮
function UIDesireTrailBoxTips:OnClickBtnConfirm()
	if not self._canMove then
		GF.ShowMessage(ccClientText(45431, ccClientText(45407)))
		self:WndClose()
		return
	end

	if self._gridData.status == ModelDesireTrail.GridStatus.CanMove then
        self:OnClickWhenMove()
		return
	end
    if self._gridData.status == ModelDesireTrail.GridStatus.Selected then
		self:OnClickWhenSelect()
		return
    end
end

-- 初始化数据
function UIDesireTrailBoxTips:InitData()
	local argMap     = self:GetWndArgList()
	self._y          = argMap.y
	self._x          = argMap.x
	self._eventRefId = argMap.eventRefId

	self._gridData   = gModelDesireTrail:GetGridData(self._y, self._x)
	local isLoatGrid = gModelDesireTrail:IsLastGrid(self._y)
	self._floor      = isLoatGrid and -1 or self._y

	self._canMove    = false
	local status     = self._gridData.status
	if status == ModelDesireTrail.GridStatus.CanMove or status == ModelDesireTrail.GridStatus.Selected then
		self._canMove = true
	end
end

-- 初始事件
function UIDesireTrailBoxTips:InitEvents()
	self:SetWndClick(self.mBtnConfirm, function() self:OnClickBtnConfirm() end)
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

------------------------------------------------------------------
return UIDesireTrailBoxTips