---
--- Created by wzz.
--- DateTime: 2025/3/13 17:02:06
---
------------------------------------------------------------------
local LWnd                      = LWnd
---@class UIDefenceWarBattleDetail:LWnd
local UIDefenceWarBattleDetail = LxWndClass("UIDefenceWarBattleDetail", LWnd)
------------------------------------------------------------------

local typeUIImage               = typeof(UnityEngine.UI.Image)

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarBattleDetail:UIDefenceWarBattleDetail()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarBattleDetail:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarBattleDetail:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------

function UIDefenceWarBattleDetail:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isWin = self:GetWndArg("isWin")
	self._mgr = gLGpManager:FindDefenceWarGp()
	self._dataList = self._mgr:GetHeroHurtList()

	self:InitTexts()
	self:InitEvents()
	self:InitList()
	self:Refresh()
end

-- 初始事件
function UIDefenceWarBattleDetail:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)

	self:WndEventRecv(EventNames.DEFENCEWAR_HERO_HURT, function(...)
		self:OnHeroHurt(...)
	end)
end

-- 刷新伤害
function UIDefenceWarBattleDetail:RefreshHurt()
	local totalHurt = self:GetTotalHurt(self._dataList)

	self:SetWndText(self.mTxtHurt, ccClientText(46847, LUtil.NumberCoversion(totalHurt)))
	for index, ui in ipairs(self._uiList) do
		local data = self._dataList[index]
		if data then
			local hurt = data.hurt
			if totalHurt == 0 then
				ui.imgHurt.fillAmount = 0
			else
				ui.imgHurt.fillAmount = hurt / totalHurt
			end
			self:SetWndText(ui.txtHurt, LUtil.NumberCoversion(hurt))
		end
	end
end

-- 初始界面化文本
function UIDefenceWarBattleDetail:InitTexts()
	self:SetWndText(self.mCloseTip, ccClientText(10103))

	self:SetWndText(self.mTitle, ccClientText(46826))
	self:SetWndText(self.mTxtTips, ccClientText(46827))
end

-- 刷新界面
function UIDefenceWarBattleDetail:Refresh()
	local res = "settlement_txt_5"
	if self._isWin == true or self._isWin == nil then
		res = "settlement_txt_4"
	end
	self:SetWndEasyImage(self.mImgTitle, res)


	local playName = gModelPlayer:GetPlayerName()
	self:SetWndText(self.mTxtPlayerName, playName)

	self:RefreshHurt()
end

-- 获取总伤害
function UIDefenceWarBattleDetail:GetTotalHurt(list)
	local totalHurt = 0
	for i, data in ipairs(list) do
		totalHurt = totalHurt + data.hurt
	end
	return totalHurt
end

-- 英雄造成了伤害
function UIDefenceWarBattleDetail:OnHeroHurt()
	self._dataList = self._mgr:GetHeroHurtList()
	self:RefreshHurt()
end

-- 初始化列表
function UIDefenceWarBattleDetail:InitList()
	self._uiList = {}
	for i = 1, 5 do
		local trans = self["mItem" .. i]
		local txtHurt = CS.FindTrans(trans, "TxtHurt")
		local iconBg = CS.FindTrans(trans, "IconBg")
		local icon = CS.FindTrans(trans, "IconBg/Icon")
		local imgHurt = CS.FindTrans(trans, "Img0/ImgHurt")
		imgHurt = self:FindCommonComponent(imgHurt, typeUIImage)

		local tab = {}
		tab.txtHurt = txtHurt
		tab.iconBg = iconBg
		tab.icon = icon
		tab.imgHurt = imgHurt
		self._uiList[i] = tab

		local data = self._dataList[i]
		if data then
			local heroId = data.heroId
			local heorRef = gModelDefenceWar:GetHeroRef(heroId)
			self:SetWndEasyImage(tab.icon, heorRef.headIcon)
			self:SetWndEasyImage(tab.iconBg, "public_item_bg_" .. heorRef.quality)
		end
		CS.ShowObject(trans, data ~= nil)
	end
end

------------------------------------------------------------------
return UIDefenceWarBattleDetail