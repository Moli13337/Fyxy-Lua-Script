---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringBettingResult:LWnd
local UIringBettingResult = LxWndClass("UIringBettingResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringBettingResult:UIringBettingResult()
	---@type CommonIcon
	self._commonIcon = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringBettingResult:OnWndClose()
	if self._commonIcon then
		self._commonIcon:Destroy()
		self._commonIcon = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringBettingResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringBettingResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetWndText(self.mCloseTip,ccClientText(10103))

	self:InitList()
	self:RefreshUI()
end

function UIringBettingResult:RefreshUI()
	local arg = self:GetWndArg("guessInfo")
	local result = arg.result
	local isWin = true
	--local resultStr= nil
	local coinNum =0
	local text = ccClientText(11885)
	local resultImg = "settlement_bg_title_2"

	if result ==0 then
		isWin = false
		--resultStr = self._resultStrList[2]
		local buffBack = arg.buffBack or 0
		coinNum = buffBack
        text = ccClientText(11884)
		local isPrivilegeActive ,ratio = gModelGeneral:IsGuessPrivilegeActive()
		-- local isTreasureActive, effectValue = gModelGeneral:IsGuessTreasureSkillActive()
		local isTreasureActive, effectValue = false, 0
		local para
		if isPrivilegeActive and not isTreasureActive then
			para = tostring(math.floor(ratio*100)) .."%"
			text = string.replace(ccClientText(11883),para)
		elseif not isPrivilegeActive and isTreasureActive then
			para = tostring(math.floor(effectValue*100)) .."%"
			text = string.replace(ccClientText(21316),para)
		elseif isPrivilegeActive and isTreasureActive then
			para = tostring(math.floor((ratio + effectValue)*100)) .."%"
			text = string.replace(ccClientText(21317),para)
		end
	else
		resultImg = "settlement_bg_title_1"
		coinNum = result
		--resultStr = self._resultStrList[1]
	end
	--local color = "red"
	--if isWin then
	--	color = "yellow_2"
	--end

	--local str = LUtil.FormatColorStr(resultStr[1], color)

	self:SetWndEasyImage(self.mResultBg, resultImg)

	-- local effName = "fx_ui_shibai"
	local effName = "fx_ui_jingcaishibai"
	if isWin then
		-- effName = "fx_ui_shengli"
		effName = "fx_ui_jingcaichenggong"
	end
	self:CreateWndEffect(self.mTitleEff,effName,effName,100)

	--self:SetWndText(self.mTitle,str)
	self:SetWndText(self.mIntro,text)
	--self:SetWndText(self.mGetText,text)

	self:SetWndText(self.mCloseIntro,ccClientText(10103))
	-- self:SetWndClick(self.mCloseBtn,function () self:WndClose() end)
	self:SetWndClick(self.mMask,function () self:WndClose() end)

	local itemInfo = gModelArena:GetArenaPeakRef("guessCoin")
	local itemId = string.split(itemInfo, "=")[2]

	if coinNum > 0 then
		local iconTrans = CS.FindTrans(self.mItemRoot,"CommonUI/Icon")
		local icon = self._commonIcon
		if not icon then
			icon = CommonIcon:New()
			self._commonIcon = icon
			icon:Create(iconTrans)
		end

		local itemType = 1
		local refId = tonumber(itemId)

		icon:SetCommonReward(itemType, refId, coinNum)
		icon:EnableShowNum(true)
		icon:DoApply()

		self:SetWndClick(iconTrans,function()
			gModelGeneral:OpenItemInfoTip(refId,coinNum)
		end)

		self.mImgObj.sizeDelta = Vector2.New(100, 130)
	else
		self.mImgObj.sizeDelta = Vector2.New(100, 100)
	end

end
function UIringBettingResult:InitList()
	self._resultStrList=
	{
		{ccClientText(11871),ccClientText(11872)},
		{ccClientText(11873),ccClientText(11874)}
	}
end



------------------------------------------------------------------
return UIringBettingResult


