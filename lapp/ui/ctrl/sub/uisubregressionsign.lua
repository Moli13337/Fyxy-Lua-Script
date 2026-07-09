---
--- Created by Administrator.
--- DateTime: 2024/8/8 12:10:46
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubRegressionSign:LChildWnd
local UISubRegressionSign = LxWndClass("UISubRegressionSign", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubRegressionSign:UISubRegressionSign()
	self.timeKey = "regressionSignTime"
	self.canGet = false
	gModelRegression:OnRegressionLoginAwardReq(0)
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubRegressionSign:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubRegressionSign:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubRegressionSign:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:OnAddClick()
	self:OnUpdateList()
	self.endTime = gModelRegression.endTime
	self:TimerStart(self.timeKey, 1, false, -1)
	self:SetTimeTxt()
	self:InitSpine()
end
function UISubRegressionSign:OnDrawChapterItem(list,item,itemData,index)
    local ImgIcon = self:FindWndTrans(item,"ImgIcon")
    local TxtDay = self:FindWndTrans(item,"TxtDay")
    local TxtCount = self:FindWndTrans(item,"TxtCount")
    local ImgMask = self:FindWndTrans(item,"ImgMask")
    local ImgBright = self:FindWndTrans(item,"ImgBright")

	self:SetWndText(TxtDay,string.replace(ccClientText(45104),itemData.receiveDay))
	local rewards = LxDataHelper.ParseItem(itemData.reward)
	self:SetWndText(TxtCount,rewards[1].itemNum)
	local itemRef
	if rewards[1].itemType == 1 then
	itemRef = GameTable.PlayerItemRef[rewards[1].itemId]
	elseif rewards[1].itemType == 2 then
	itemRef = GameTable.CharacterEffectRef[rewards[1].itemId]
	elseif rewards[1].itemType == 3 then
	itemRef = GameTable.RoleEquipRef[rewards[1].itemId]
	end
	self:SetWndEasyImage(ImgIcon,itemRef.icon)
	local state = gModelRegression.signState[itemData.refId]
	if state==1 then self.canGet = true end
	CS.ShowObject(ImgMask,state == 2)
	CS.ShowObject(ImgBright,state==1)
	self:SetWndClick(ImgIcon,function()
		gModelGeneral:ShowCommonItemTipWnd(rewards[1])
	end)
end

function UISubRegressionSign:SetTimeTxt()
	local nowTime = GetTimestamp()
	local timeDif = os.difftime(self.endTime, nowTime)
	if timeDif <= 0 then
		self:TimerStop(self.timeKey)
	end
	local timeStr = LUtil.FormatTimespanCn(timeDif)
	self:SetWndText(self.mTxtTime,string.replace(ccClientText(45102),timeStr))
end
function UISubRegressionSign:InitSpine()
	local refId = self:GetWndArg("refId")
	local ref = GameTable.ReturnBackBackflowRef[refId]
	if not ref or string.isempty(ref.showImage) then return end
	local dpSpine = self:CreateWndSpine(self.mSpine,ref.showImage,nil,true,function (dpLoaded)
		dpLoaded:PlayAnimation(0,"idle",true)
	end,true)
	dpSpine:StartLoad()
	self:SetWndEasyImage(self.mImgText,ref.showTitle)
end

function UISubRegressionSign:OnUpdateList()
	local list = {}
	local cfgs = GameTable.ReturnBackFixedRewardRef
	local curLv = gModelPlayer:GetPlayerLv()
	for key, value in pairs(cfgs or {}) do
		local levels = string.split(value.level,",")
		if tonumber(levels[1]) <= curLv and curLv<= tonumber(levels[2]) then
			table.insert(list,value)
		end
	end
	table.sort(list,function(a,b)
		return a.receiveDay<b.receiveDay
	end)
	self.canGet = false
	local maxIndex = #list
	self.maxSignData = table.remove(list,maxIndex)
	if self.uiList then
		self.uiList:RefreshData(list)--DrawAllItems()
	else
		self.uiList = self:CreateUIScrollImpl(nil,self.mListSign,list,function(...) self:OnDrawChapterItem(...) end,UIItemList.WRAP)
	end
	local enableSc = #list>6
	self.uiList:EnableScroll(enableSc,enableSc)
	self:OnDrawChapterItem(nil,self.mImgSign,self.maxSignData,maxIndex)
end

function UISubRegressionSign:OnTimer(key)
	if key == self.timeKey then
		self:SetTimeTxt()
	end
end

function UISubRegressionSign:OnAddClick()
	self:SetWndText(self.mLblBiaoti,ccClientText(45103))
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
	self:SetWndButtonText(self.mBtnGet,ccClientText(43114))
	self:SetWndClick(self.mBtnGet,function()
		if self.canGet then
			gModelRegression:OnRegressionLoginAwardReq(1)
		else
			GF.ShowMessage(ccClientText(45108))
		end
	end)
	self:WndNetMsgRecv(LProtoIds.RegressionLoginAwardResp,function()
		self:OnUpdateList()
	end)

end

------------------------------------------------------------------
return UISubRegressionSign