---
--- Created by Administrator.
--- DateTime: 2024/8/13 22:01:41
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubRegressionPuzzle:LChildWnd
local UISubRegressionPuzzle = LxWndClass("UISubRegressionPuzzle", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubRegressionPuzzle:UISubRegressionPuzzle()
	gModelRegression:OnRegressionAssemblyPictureReq(0,0)
	self.rewardIcon = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubRegressionPuzzle:OnWndClose()
	LChildWnd.OnWndClose(self)
	self.rewardIcon = nil
	self:TimerStop(self.timeKey)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubRegressionPuzzle:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubRegressionPuzzle:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:AddEventClick()
	self:OnStartTime()
	self:InitSpine()
	self:UpdateRewards()
	self:UpdateCost()
	self:OnUpdateList()
end

function UISubRegressionPuzzle:SetReward(rwdTran,rwdCfg,index)
	if not rwdTran then return end
	local icon = self:FindWndTrans(rwdTran,"ImgIcon")
	local ImgMaks = self:FindWndTrans(rwdTran,"ImgMaks")
	local item  = LxDataHelper.ParseItem_4(rwdCfg.reward)
	local instanceId = rwdTran:GetInstanceID()
	local baseClass = self.rewardIcon[instanceId]
	local canGet = gModelRegression:GetPuzzleRwdState(rwdCfg.refId)
	if not baseClass then
		baseClass = CommonIcon:New()
	end
	local goted = gModelRegression.puzzleRwdGoted[rwdCfg.refId]
	self:SetWndClick(rwdTran,function()
		if canGet then
			self:OnPuzzleReq(2,rwdCfg.refId)
		else
			if not goted then
				GF.ShowMessage(ccClientText(45109))
			end
			gModelGeneral:ShowCommonItemTipWnd(item)
		end
	end)
	self.rewardIcon[instanceId] = baseClass
	baseClass:Create(icon)
	baseClass:SetCommonReward(item.itemType, item.itemId, item.itemNum)
	baseClass:DoApply()
	CS.ShowObject(ImgMaks,goted)
	local effKey = "item"..index
	if canGet and not goted then
		self:CreateWndEffect(rwdTran,"fx_ui_pintu_kelingqu",effKey,100,false,false,nil,nil,nil,nil,nil)
	else
		self:DestroyWndEffectByKey(effKey)
	end
end

function UISubRegressionPuzzle:UpdateMaxReward()
	-- self.mImgBox
end

function UISubRegressionPuzzle:InitSpine()
	local refId = self:GetWndArg("refId")
	local ref = GameTable.ReturnBackBackflowRef[refId]
	if not ref or string.isempty(ref.showImage) then return end
	local dpSpine = self:CreateWndSpine(self.mSpine,ref.showImage,nil,true,function (dpLoaded)
		dpLoaded:PlayAnimation(0,"idle",true)
	end,true)
	dpSpine:StartLoad()

	self:SetWndEasyImage(self.mImgPuzzleBg,GameTable.ReturnBackConfigRef.puzzleBg)
	self:SetWndEasyImage(self.mImgText,ref.showTitle)
end

function UISubRegressionPuzzle:OnDrawCostItem(list,item, itemdata, itempos)
	local SellIconTrans = self:FindWndTrans(item,"SellIcon")
	if SellIconTrans then
		local iconImg = gModelItem:GetItemIconByRefId(itemdata.itemId)
		self:SetWndEasyImage(SellIconTrans,iconImg,function()
			CS.ShowObject(SellIconTrans,true)
		end)
	end
	local SellValueTrans = self:FindWndTrans(item,"SellValue")
	if SellValueTrans then
		local haveCount = gModelItem:GetNumByRefId(itemdata.itemId)
		local color = haveCount>=itemdata.itemNum and "#139057" or "#FB1E12"
		local str = string.format("<color=%s>%s</color>/%s",color, LUtil.NumberCoversion(haveCount),LUtil.NumberCoversion(itemdata.itemNum))
		self:SetWndText(SellValueTrans,str)
	end
end

function UISubRegressionPuzzle:UpdateCost()
	local costStr = GameTable.ReturnBackConfigRef.puzzleConsume
	local list = LxDataHelper.ParseItem(costStr) or {}
	local uiList = self:FindUIScroll("holyLandCost")
	if uiList then
		uiList:RefreshData(list)
	else
		uiList = self:GetUIScroll("holyLandCost")
		uiList:Create(self.mSellItemList,list,function(...) self:OnDrawCostItem(...) end)
	end
end

function UISubRegressionPuzzle:SetTimeTxt()
	local nowTime = GetTimestamp()
	local timeDif = os.difftime(self.endTime, nowTime)
	if timeDif <= 0 then
		self:TimerStop(self.timeKey)
	end
	local timeStr = LUtil.FormatTimespanCn(timeDif)
	self:SetWndText(self.mTxtTime,string.replace(ccClientText(45102),timeStr))
end
function UISubRegressionPuzzle:OnDrawChapterItem(list,item,itemData,index)
    local ImgIcon = self:FindWndTrans(item,"ImgIcon")
    local EffTran = self:FindWndTrans(item,"Eff")
	local image = self:FindWndImage(item)
	local state = gModelRegression.puzzleActivate[itemData]
	CS.ShowObject(ImgIcon,not state)
	image.enabled = not state
	if self.activeId == itemData  then
		local eff = self:FindWndEffectByKey("fx_ui_pintu_jihuo")
		if not eff then
			self:CreateWndEffect(EffTran,"fx_ui_pintu_jihuo","fx_ui_pintu_jihuo",100,false,false,nil,nil,nil,nil,nil,function()
			end)
		else
			local dpTrans = eff:GetDisplayTrans()
			eff:SetVisible(false)
			dpTrans:SetParent(EffTran,false)
			eff:SetVisible(true)
		end
	end
end

function UISubRegressionPuzzle:OnStartTime()
	self.timeKey = "timeKey_puzzle"
	self.endTime = gModelRegression.endTime
	self:TimerStart(self.timeKey,false,-1)
	self:SetTimeTxt()
end

function UISubRegressionPuzzle:OnUpdateList()
	local refId = GameTable.ReturnBackConfigRef.puzzleReward
	self.maxRwdState = not gModelRegression.puzzleRwdGoted[refId] and gModelRegression:ActivatePuzzle()
	self:SetWndEasyImage(self.mImgBox, not gModelRegression.puzzleRwdGoted[refId] and "draconic_box_icon_off" or "draconic_box_icon_on")
	local effName = "fx_VIPchongzhiwupo"
	if self.maxRwdState then
		self:CreateWndEffect(self.mImgBox,effName,effName,100,nil,nil,nil,nil,nil,nil,nil,function(dpEff)
			dpEff.localPosition = Vector3(55,-136,0)
		end)
	else
		self:DestroyWndEffectByKey(effName)
	end
	local list = {}
	local puzzleCount = GameTable.ReturnBackConfigRef.puzzleNums
	for i = 1, puzzleCount do
		table.insert(list,i)
	end
	if self.uiList then
		self.uiList:RefreshData(list)
	else
		self.uiList = self:CreateUIScrollImpl(nil,self.mListPuzzle,list,function(...) self:OnDrawChapterItem(...) end,UIItemList.WRAP)
	end
	self.uiList:EnableScroll(false,false)
end

function UISubRegressionPuzzle:OnTimer(key)
	if key == self.timeKey then
		self:SetTimeTxt()
	end
end

function UISubRegressionPuzzle:UpdateRewards()
	local refs = GameTable.ReturnBackPuzzleRef
	for index, value in pairs(refs) do
		self:SetReward(self["mRwdItem"..value.sort],value,index)
	end
end

function UISubRegressionPuzzle:OnPuzzleReq(type,refId)
	gModelRegression:OnRegressionAssemblyPictureReq(type,refId or 0)

end

function UISubRegressionPuzzle:AddEventClick()
	self:SetWndButtonText(self.mBtnActive,ccClientText(45110))
	self:SetWndClick(self.mBtnActive,function()
		if gModelRegression:OnCheckCost(LxDataHelper.ParseItem(GameTable.ReturnBackConfigRef.puzzleConsume),true) then
			self:OnPuzzleReq(1,0)
		else
			GF.ShowMessage(ccClientText(45123))
		end
	end)
	self:SetWndText(self.mTaskBtnText,ccClientText(20308))
	self:SetWndClick(self.mTaskBtn,function()
		GF.OpenWnd("UIRegressionQst")
	end)
	self:SetWndClick(self.mImgBox,function()
		local refId = GameTable.ReturnBackConfigRef.puzzleReward
		if self.maxRwdState then
			self:OnPuzzleReq(2,refId)
		else
			local rwdStr= GameTable.ReturnBackPuzzleRef[refId].reward
			local rewardList = LxDataHelper.ParseItem(rwdStr)
			GF.OpenWnd("UIringBoxDetail",{self.mImgBox,rewardList})
		end
	end)
	self:WndEventRecv(EventNames.REGRESSION_PUZZLE,function(data)
		self.activeId = data and data.activeId
		self:OnUpdateList()
		self:UpdateRewards()
		if data and data.allActive then
			self:CreateWndEffect(self.mImgPuzzleBg,"fx_ui_pintu_jihuo_wancheng","fx_ui_pintu_jihuo_wancheng",100,false,false,nil,nil,nil,nil,nil)
		end
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:UpdateCost()
	end)
end


------------------------------------------------------------------
return UISubRegressionPuzzle