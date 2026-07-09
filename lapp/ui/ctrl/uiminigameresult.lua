---
--- Created by Administrator.
--- DateTime: 2025/3/27 18:10:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMiniGameResult:LWnd
local UIMiniGameResult = LxWndClass("UIMiniGameResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMiniGameResult:UIMiniGameResult()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMiniGameResult:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMiniGameResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMiniGameResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitEvent()
	self:InitMsg()
	self:InitPara()
	self:InitStaticText()
end

--结果 奖励或者文字
function UIMiniGameResult:CreateWndCenter(titleStr,desStr,itemList)
	self:SetWndText(self.mDungeonText,titleStr)

	if  table.isempty(itemList) then
		self:SetWndText(self.mDescriptionText,desStr)
	else
		self:SetItemList(itemList)
	end
end

--endregion --------------------------------------------------------------------------------------

--region 界面设置 --------------------------------------------------------------------------------
function UIMiniGameResult:InitStaticText()
	local UIText = self:FindWndTrans(self.mCloseButton,"UIText")
	self:SetWndText(UIText,ccClientText(11160))
end

--region 事件 --------------------------------------------------------------------------------
function UIMiniGameResult:InitEvent()
	self:SetWndClick(self.mCloseButton,function()
		if not string.isempty(self._needCloseWndName) then
			GF.CloseWndByName(self._needCloseWndName)
		end
		self:WndClose()
	end)
end
--胜负
function UIMiniGameResult:ShowTitleEff(isSuc)
	CS.ShowObject(self.mTitleIcon, false)
	CS.ShowObject(self.mTitleEff, true)
	CS.ShowObject(self.mWinBg, true)

	local effName = "fx_ui_shibai"
	local imgName = "settlement_bg_title_4"
	if isSuc then
		effName = "fx_ui_shengli"
		imgName = "settlement_bg_title_3"
	end
	self:CreateWndEffect(self.mTitleEff, effName, effName, 100)

	local pos = Vector2.New(-13.85, 10)

	self:SetAnchorPos(self.mTitleEff, pos)
	self:SetWndEasyImage(self.mWinBg, imgName)
end

--endregion --------------------------------------------------------------------------------------

--region 数据 --------------------------------------------------------------------------------
function UIMiniGameResult:InitPara()
	local isSuc = self:GetWndArg("isSuc")
	local heroEffectId= self:GetWndArg("heroEffectId")
	local titleStr= self:GetWndArg("titleStr")
	local desStr= self:GetWndArg("desStr")
	local itemList= self:GetWndArg("itemList")
	self._needCloseWndName  = self:GetWndArg("wndName")
	self:ShowTitleEff(isSuc)
	self:CreateUISagaSpine(heroEffectId)
	self:CreateWndCenter(titleStr,desStr,itemList)
end

--英雄立绘
function UIMiniGameResult:CreateUISagaSpine(heroEffectId)
	local scale = 0.95
	local flipx = false

	local heroShowRef = GameTable.CharacterEffectRef[heroEffectId]

	local res1 = heroShowRef.skinSpineBg
	local drawing = heroShowRef.heroDrawing
	local res3 = heroShowRef.skinSpineHd
	if res1 ~= "" then
		self:CreateWndSpine(self.mHeroSpine1, res1, res1.."UIMiniGameResult", false, function(dpSpine)
			dpSpine:SetScale(scale)
			dpSpine:SetFlipX(flipx)
		end)

	end
	self:CreateWndSpine(self.mHeroSpine2, drawing, drawing.."UIMiniGameResult", false, function(dpSpine)
		dpSpine:SetScale(scale)
		dpSpine:SetFlipX(flipx)
	end)
	if res3 ~= "" then
		self:CreateWndSpine(self.mHeroSpine3, res3, res3.."UIMiniGameResult", false, function(dpSpine)
			dpSpine:SetScale(scale)
			dpSpine:SetFlipX(flipx)
		end)
	end
end

function UIMiniGameResult:SetItemList(dataList, isDetail)
	isDetail = isDetail and true or false
	local uiRewardList = self._uiRewardList
	if not uiRewardList then
		uiRewardList = UIIconEasyList:New()
		self._uiRewardList = uiRewardList
		uiRewardList:Create(self, self.mItemList, nil, isDetail)
		uiRewardList:EnableLoadAnimation(true, 0.1, 1)
		uiRewardList:SetIconParentPath("Icon")
		uiRewardList:EnableScroll(true, false)
	end
	uiRewardList:RefreshList(dataList, true)
	uiRewardList:EnableScroll(true, false)
end

function UIMiniGameResult:InitMsg()

end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIMiniGameResult