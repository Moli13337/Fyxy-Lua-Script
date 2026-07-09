---
--- Created by Administrator.
--- DateTime: 2024/7/30 14:27:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInsKey:LWnd
local UIInsKey = LxWndClass("UIInsKey", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInsKey:UIInsKey()
	self.curSelIndexs = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInsKey:OnWndClose()
	LWnd.OnWndClose(self)
	if self.loveInfo then gModelHeroExtra:OnHeroGiveGiftResp(self.loveInfo) end
	-- gModelHeroExtra:OnHeroInteractQuestReq()--互动任务信息
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInsKey:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInsKey:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:OnAddEevetMsg()
	self.options = {
		self.mOption1,
		self.mOption2,
		self.mOption3,
		self.mOption4
	}
	self.optionSel = {
		self.mImgSelect1,
		self.mImgSelect2,
		self.mImgSelect3,
		self.mImgSelect4
	}
	self.optionMarking = {
		self.mImgMarking1,
		self.mImgMarking2,
		self.mImgMarking3,
		self.mImgMarking4
	}
	self.optionDesc = {
		self.mTxtDesc1,
		self.mTxtDesc2,
		self.mTxtDesc3,
		self.mTxtDesc4
	}
	self.Abcd = {"A","B","C","D"}
	local eventId = self:GetWndArg("eventId")
	self.eventRef = GameTable.GardenEventRef[eventId]
	self:SetWndText(self.mTxtName,ccLngText(self.eventRef.name))
	self:SetTextTile(self.mTitleText,ccClientText(41651))
	self:SetWndButtonText(self.mBtnComfirm,ccClientText(42044))
	self:OnUpdateSpine(self.eventRef.type == LInteractEventType.INTERACT_EVT_2)
	if self.eventRef.type == LInteractEventType.INTERACT_EVT_1 then 
		self:OnAnswerPanel()
	else
		self:OnGuessHeroPanel()
	end
end
function UIInsKey:OnAnswerPanel()
	CS.ShowObject(self.mTxtTopic,true)
	CS.ShowObject(self.mOption,true)
	local moreInfo = self:GetWndArg("moreInfo")
	local questRef = GameTable.GardenQuestRef[moreInfo]
	self:SetWndText(self.mTxtTopic,ccLngText(questRef.dec))
	self:UpdateOptionPos(nil,-29.5)
	self:UpdateTitlePos(nil,57)
	self:OnInitOption()
end
function UIInsKey:OnAddEevetMsg()
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
	self:SetWndClick(self.mBtnComfirm,function()
		if self.isRight then
			self:WndClose()
			return
		end
		if not self.curSelIndx then
			for _, value in pairs(self.curSelIndexs) do
				GF.ShowMessage(ccClientText(41667))
				return
			end
			GF.ShowMessage(ccClientText(41653))
			return
		end

		self.isMarking = true
		self:OnInitOption()
	end)
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
end

function UIInsKey:UpdateTitlePos(x,y)
	local pos = self.mTitleText.anchoredPosition
	pos.y = y
	pos.x = x or pos.x
	self.mTitleText.anchoredPosition = pos
end

function UIInsKey:OnGuessHeroPanel()
	CS.ShowObject(self.mTxtTopic,false)
	CS.ShowObject(self.mOption,true)
	self:UpdateOptionPos(nil,-9)
	self:UpdateTitlePos(nil, 96)
	self:OnInitOption()
end



function UIInsKey:OnUpdateSpine(guessHero)
	self._heroEffectRef = self:GetWndArg("heroEffectRef")
	if self._heroEffectRef then
		local spineName = self._heroEffectRef.heroDrawing
		local spine = self:FindWndSpineByKey("anwserSpine")
		if not spine then
			self:CreateWndSpine(self.mRoleRoot,spineName,"anwserSpine",nil,function(spine)
				spine:PlayAnimationSolid("idle",true)
				if guessHero then
					spine:SetColor(Color.New(0, 0, 0, 1))
				end
			end)
		else
			if guessHero and self.isMarking then
				spine:SetColor(Color.New(1, 1, 1, 1))
			end
		end
	end
end
function UIInsKey:OnDrawRewardItem(list, item, itemData, index)
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
function UIInsKey:UpdateOptionPos(x,y)
	local pos = self.mOption.anchoredPosition
	pos.y = y
	pos.x = x or pos.x
	self.mOption.anchoredPosition = pos
end

function UIInsKey:CreateRwdList()
	if not self.eventRef then return end
	local list = {}
	local reward = self.isRight and self.eventRef.reward1 or self.eventRef.reward2
	list = LxDataHelper.ParseItem(reward)
    local list = self:CreateUIScrollImpl("GuessWwdScroll",self.mListRwdScroll,list,function (...)
        self:OnDrawRewardItem(...)
    end)
    self.rwdList = list
end

function UIInsKey:OnResultPanel()
	CS.ShowObject(self.mOption,false)
	CS.ShowObject(self.mTxtTopic,false)
	self:UpdateOptionPos(nil,111)
	self:UpdateTitlePos(nil,108)
	self:SetTextTile(self.mTitleText,ccClientText(41655))
	self:SetWndText(self.mTxtName,ccClientText(41659))
	self:CreateWndEffect(self.mTxtName,"fx_ui_garden_huidazhengque",nil,100,false,false,nil,nil,nil,nil,nil,nil)
	self:CreateRwdList()
end

function UIInsKey:OnInitOption()
	local moreInfo = self:GetWndArg("moreInfo")
	local questRef = GameTable.GardenQuestRef[moreInfo]
	if not questRef then return end
	local answers = string.split(ccLngText(questRef.answer),"|")
	for index, value in ipairs(self.options) do
		if answers[index] then
			CS.ShowObject(value,true)
			self:SetWndText(self.optionDesc[index],answers[index])
			if self.curSelIndx and self.curSelIndx == index then
				CS.ShowObject(self.optionSel[index],true)
			else
				CS.ShowObject(self.optionSel[index],false)
			end
			local selIndex = self.curSelIndx
			if self.isMarking and selIndex and selIndex == index then
				self.curSelIndexs[selIndex] = selIndex
				CS.ShowObject(self.optionMarking[index],true)
				self.isRight = selIndex == index and questRef.right==self.Abcd[index]
				if questRef.right~=self.Abcd[index] then
					self:SetWndEasyImage(self.optionMarking[index],"public_icon_false_2")
				elseif questRef.right==self.Abcd[index] then
					self:SetWndEasyImage(self.optionMarking[index],"public_icon_right_2")
				end
				if self.isRight then
 					gModelHeroExtra:OnHeroInteractGameOpsReq(1,1,"")
				else
					self.isMarking = false
				end
				self:OnUpdateSpine(self.eventRef.type == LInteractEventType.INTERACT_EVT_2)
				local sound = self.isRight and LSoundConst.INTERACT_ANSWER or LSoundConst.FAIRYTALE_MONSTERHIDH
				LxUiHelper.PlayAudioSoundName(sound)
				self.curSelIndx =  nil
			end
			self:SetWndClick(value,function()
				if self.curSelIndexs[index] then return end
				self.curSelIndx = index
				self.isRight = nil
				self:OnInitOption()
			end)
		else
			CS.ShowObject(value,false)
		end
	end
end


------------------------------------------------------------------
return UIInsKey