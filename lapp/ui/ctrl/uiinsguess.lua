---
--- Created by Administrator.
--- DateTime: 2024/7/29 21:48:51
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInsGuess:LWnd
local UIInsGuess = LxWndClass("UIInsGuess", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInsGuess:UIInsGuess()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInsGuess:OnWndClose()
	LWnd.OnWndClose(self)
	if self.loveInfo then gModelHeroExtra:OnHeroGiveGiftResp(self.loveInfo) end
	-- gModelHeroExtra:OnHeroInteractQuestReq()--互动任务信息
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInsGuess:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInsGuess:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	self._heroEffectRef = self:GetWndArg("heroEffectRef")
	local eventId = self:GetWndArg("eventId")
	self.eventRef = GameTable.GardenEventRef[eventId]
	self:SetWndText(self.mTxtName,ccLngText(self.eventRef.name))
	self:SetWndButtonText(self.mBtnComfirm,ccClientText(42044))
	if self._heroEffectRef then
		local spineName = self._heroEffectRef.heroDrawing
		self:CreateWndSpine(self.mRoleRoot,spineName,"guessSpine",nil,function(spine)
			spine:PlayAnimationSolid("idle",true)
		end)
	end
	self:OnAddEevetMsg()
	self:OnSelectPanel()
	self:RefreshForeign()
end
function UIInsGuess:OnDrawRewardItem(list, item, itemData, index)
	local CommonUIIcon = self:FindWndTrans(item,"CommonUI/Icon")
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(CommonUIIcon)

	baseClass:SetCommonReward(itemData.itemType, itemData.itemId, itemData.itemNum)
	baseClass:DoApply()
	self:SetWndClick(CommonUIIcon,function()
        gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)
end
function UIInsGuess:SetGuessIconPos()

end

function UIInsGuess:OnResultPanel()
	CS.ShowObject(self.mImgReslutL,true)
	CS.ShowObject(self.mImgReslutR,true)
	CS.ShowObject(self.mTitleText,true)
	CS.ShowObject(self.mListRwdScroll,true)
	CS.ShowObject(self.mImgIconBg1,false)
	CS.ShowObject(self.mImgIconBg2,false)
	CS.ShowObject(self.mImgIconBg3,false)
	CS.ShowObject(self.mBtnComfirm,true)
	CS.ShowObject(self.mImgDesc,true)
	local pos = self.mTitleText.anchoredPosition
	pos.y = 47
	self.mTitleText.anchoredPosition = pos
	self:SetTextTile(self.mTitleText,ccClientText(41655))
	local isWin = self.isWin
	local desc = ""
	if self.selIndex~=self.heroSelIndx then
		desc = isWin and ccClientText(41656) or ccClientText(41657)
	else
		CS.ShowObject(self.mImgReslutL,false)
		CS.ShowObject(self.mImgReslutR,false)
		desc = ccClientText(41658)
	end
	self:SetWndText(self.mTxtDesc,desc)
	local func = function(isWin)
		local imgPath = isWin and "settlement_bg_title_3" or "settlement_bg_title_4"
		local imgTxtPath = isWin and "settlement_txt_2" or "settlement_txt_3"
		return imgPath,imgTxtPath
	end
	local imgPath,imgTxtPath = func(not isWin)
	self:SetWndEasyImage(self.mImgReslutL,imgPath)
	self:SetWndEasyImage(self.mImgTxtResultL,imgTxtPath)
	imgPath,imgTxtPath = func(isWin)
	self:SetWndEasyImage(self.mImgReslutR,imgPath)
	self:SetWndEasyImage(self.mImgTxtResultR,imgTxtPath)
	self:CreateRwdList(isWin)

end
function UIInsGuess:CreateRwdList(isWin)
	if not self.eventRef then return end
	local list = {}
	local reward = isWin and self.eventRef.reward1 or self.eventRef.reward2
	list = LxDataHelper.ParseItem(reward)
    local list = self:CreateUIScrollImpl("GuessWwdScroll",self.mListRwdScroll,list,function (...)
        self:OnDrawRewardItem(...)
    end)
    self.rwdList = list
end
function UIInsGuess:SetTitlePos(x,y)
	local pos = self.mTitleText.anchoredPosition
	pos.x = x or pos.x
	pos.y = y or pos.y
	self.mTitleText.anchoredPosition = pos
end

function UIInsGuess:OnGuessClick(selIndex)
	local selectIcon = {self.mImgSelect1,self.mImgSelect2,self.mImgSelect3}
	self.selIndex = selIndex
	for i = 1, 3 do
		local icon = selectIcon[i]
		CS.ShowObject(icon,selIndex==i)
	end
end
function UIInsGuess:OnSelectPanel()
	CS.ShowObject(self.mResult,false)
	CS.ShowObject(self.mImgIcon3,true)
	CS.ShowObject(self.mTitleText,true)
	CS.ShowObject(self.mImgReslutL,false)
	CS.ShowObject(self.mImgReslutR,false)
	self:SetTextTile(self.mTitleText,ccClientText(41654))
	self:SetWndEasyImage(self.mImgIcon1,"garden_icon_2")
	self:SetWndEasyImage(self.mImgIcon2,"garden_icon_3")
	self:SetWndEasyImage(self.mImgIcon3,"garden_icon_1")
	self:SetTitlePos(nil,106)
end

function UIInsGuess:OnGuessPanel()
	CS.ShowObject(self.mResult,true)
	CS.ShowObject(self.mImgIconBg3,false)
	CS.ShowObject(self.mImgIcon2,false)
	CS.ShowObject(self.mImgIcon1,false)
	CS.ShowObject(self.mImgSelect1,false)
	CS.ShowObject(self.mImgSelect2,false)
	CS.ShowObject(self.mTitleText,false)
	local pos = self.mImgIconBg1.anchoredPosition
	pos.x = -120
	self.mImgIconBg1.anchoredPosition = pos
	local pos2 = self.mImgIconBg2.anchoredPosition
	pos2.x = 120
	self.mImgIconBg2.anchoredPosition = pos2

	self.heroSelIndx = math.random(1,3)
	local name = self._heroEffectRef and ccLngText(self._heroEffectRef.name) or ""
	self:SetWndText(self.mTxtHeroNameL,name)
	name = gModelPlayer:GetPlayerName()
	self:SetWndText(self.mTxtHeroNameR,name)

	local guessSpine = {"ui_garden_jiandao","ui_garden_shitou","ui_garden_bu"}
	local guessAnimation = {"bu","shitou","bu"}
	self:CreateWndSpine(self.mImgIconBg1,guessSpine[self.heroSelIndx],"guessSpine_1",nil,function(spine)
		spine:PlayAnimationSolid(guessAnimation[self.heroSelIndx],false)
		spine:SetFlipX(true)
		local dpTrans = spine:GetDisplayTrans()
		dpTrans.anchoredPosition = Vector2(-10,23)
	end)
	self:CreateWndSpine(self.mImgIconBg2,guessSpine[self.selIndex],"guessSpine_2",nil,function(spine)
		spine:PlayAnimationSolid(guessAnimation[self.selIndex],false)
		local dpTrans = spine:GetDisplayTrans()
		dpTrans.anchoredPosition = Vector2(10,23)
		spine:SetAnimationCompleteFunc(function()
			-- self:OnResultPanel()
			self.isWin = false
			if self.selIndex~=self.heroSelIndx then
				if self.selIndex==1 then
					self.isWin = self.heroSelIndx~=2
				elseif self.selIndex==2 then
					self.isWin = self.heroSelIndx ~=3
				else
					self.isWin = self.heroSelIndx~=1
				end
				local sound = self.isWin and LSoundConst.INTERACT_GUESS_WIN or LSoundConst.INTERACT_GUESS_FAIL
				LxUiHelper.PlayAudioSoundName(sound)
			end
			gModelHeroExtra:OnHeroInteractGameOpsReq(1,self.isWin and 1 or 2,"")
		end)
	end)
end

function UIInsGuess:RefreshForeign()
	if self._isVie then
		self:InitTextLineWithLanguage(self.mTxtDesc,0)
	end
end
function UIInsGuess:OnAddEevetMsg()
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mImgIcon1,function()
		self:OnGuessClick(1)
	end)
	self:SetWndClick(self.mImgIcon2,function()
		self:OnGuessClick(2)
	end)
	self:SetWndClick(self.mImgIcon3,function()
		self:OnGuessClick(3)
	end)
	self:SetWndClick(self.mBtnComfirm,function()
		if self.selIndex then
			if self.heroSelIndx then
				self:WndClose()
			else
				self:OnGuessPanel()
				CS.ShowObject(self.mBtnComfirm,false)
			end
		else
			GF.ShowMessage(ccClientText(41654))
		end
	end)

	self:WndNetMsgRecv(LProtoIds.HeroInteractGameOpsResp,function(pb)
		if pb.rewardInfo then
			local thingsDetail = gModelGeneral:GetThingsDetailInfoByPb(pb.rewardInfo)
			if thingsDetail.rewardNum>0 then
				self:OnResultPanel()
			end
		end
		if pb.gift.addLoveValue>0 then
			self.loveInfo = pb.gift
		end
	end)
end
------------------------------------------------------------------
return UIInsGuess