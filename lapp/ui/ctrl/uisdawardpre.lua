---
--- Created by Administrator.
--- DateTime: 2024/5/20 22:30:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISdAwardPre:LWnd
local UISdAwardPre = LxWndClass("UISdAwardPre", LWnd)
------------------------------------------------------------------

local UIBtnTabList = LXImport('LApp.UI.Common.UIBtnTabList')

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISdAwardPre:UISdAwardPre()
	---@type UIBtnTabList
	self._uiBtnTabList = nil

	self._curSelLv = 1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISdAwardPre:OnWndClose()
	if self._uiBtnTabList then
		self._uiBtnTabList:Destroy()
		self._uiBtnTabList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISdAwardPre:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISdAwardPre:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:CreateTabBtnList()
	self:RefreshView()
end

function UISdAwardPre:InitEvent()
	--- 返回按钮必备
	 self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	 self:SetWndClick(self.mMaskBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISdAwardPre:OnDrawProbabilityCell(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item,"CommonUI/Icon")
	local UIText = self:FindWndTrans(item,"UIText")

	local reward = itemdata.reward
	local instanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(reward.itemType,reward.itemId,reward.itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	self:SetWndClick(Icon,function()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end)

	self:SetWndText(UIText,itemdata.numStr)
end

function UISdAwardPre:InitProbabilityList()
	local list = self:GetProbabilityList()
	local uiList = self:FindUIScroll("ProbabilityList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("ProbabilityList")
		uiList:Create(self.mProbabilityList, list, function(...)
			self:OnDrawProbabilityCell(...)
		end,UIItemList.SUPER_GRID)
	end

	uiList:DrawAllItems()
	uiList:MoveToPos(0)
end

function UISdAwardPre:OnEventXXXXX()
end

function UISdAwardPre:OnMsgXXXXX()
end

function UISdAwardPre:RefreshJackpot()
	--- 默认为当前的进度
	local jackpotLv = gModelHalidom:GetHalidomJackpotLv()

	local isMaxLv = gModelHalidom:CheckIsMaxJackpotLv()
	local curNum = gModelHalidom:GetHalidomDrawCnt()

	local num = 0
	if isMaxLv then
		num = gModelHalidom:GetHalidomRewardLvNum(jackpotLv)
	else
		num = gModelHalidom:GetHalidomRewardLvNum(jackpotLv + 1)
	end

	if curNum > num then curNum = num end
	local progress = curNum / num
	self:SetWndText(self.mJackpotNum,string.replace(ccClientText(41518),curNum,num))

	local slider = self:UIProgressFind(self.mJackpotSlider, "mJackpotSlider", progress)
	slider:SetUIProgress(progress)

	local showStr = ""
	if isMaxLv then
		showStr = ccClientText(41535)
	else
		showStr = string.replace(ccClientText(41546),num,jackpotLv + 1)
	end
	self:SetWndText(self.mJackpotFullTxt,showStr)


--[[

	--- 按照当前选择的等级显示
	local jackpotLv = gModelHalidom:GetHalidomJackpotLv()
	local curNum = gModelHalidom:GetHalidomDrawCnt()
	local num = gModelHalidom:GetHalidomRewardLvNum(self._curSelLv)
	local progress = 1
	if jackpotLv >= self._curSelLv then
		num = gModelHalidom:GetHalidomRewardLvNum(self._curSelLv + 1)
	end
	progress = curNum / num
	self:SetWndText(self.mJackpotNum,string.replace(ccClientText(41518),curNum,num))
	local slider = self:UIProgressFind(self.mJackpotSlider, "mJackpotSlider", progress)
	slider:SetUIProgress(progress)

	CS.ShowObject(self.mJackpotFullTxt,gModelHalidom:CheckIsMaxJackpotLv())]]
end

function UISdAwardPre:CreateTabBtnList()
	local dataList = {}
	for i,v in ipairs(self._halidomExplainShowList) do
		table.insert(dataList,{
			btnName = string.replace(ccClientText(41511),v.type),
			btnType = v.type,
			clickFunc = function(itemdata)
				self._curSelLv = itemdata.btnType
				self:RefreshView()
				return true
			end
		})
	end

	table.sort(dataList,function(a, b) return a.btnType < b.btnType end)

	local curSelLv
	local jackpotLv = self:GetWndArg("jackpotLv")
	if jackpotLv and jackpotLv > 0 then
		curSelLv = jackpotLv
	else
		curSelLv = dataList[1].btnType
	end
	self._curSelLv = curSelLv

	---@type UIBtnTabList
	self._uiBtnTabList = UIBtnTabList:New()
	self._uiBtnTabList:SetData(self,self.mTabBtnList,dataList,self._curSelLv)
end

function UISdAwardPre:OnClickXXXBtnFunc()
end


function UISdAwardPre:GetProbabilityList()
	local list = {}
	local data = self._halidomExplainShowMap[self._curSelLv]
	if data then
		for i,v in ipairs(data) do
			table.insert(list,{
				numStr = v.numStr,
				reward = v.reward,
			})
		end
	end
	return list
end


function UISdAwardPre:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(41515))
	self:SetWndText(self.mDescTxt,ccClientText(41512))

	--- 修改为帮助文本163
	local ref = GameTable.SupportTipsRef[162]
	self:SetWndText(self.mAboutTxt,ccLngText(ref.text))

	self:SetTextTile(self.mRuleTitle,ccClientText(41514))
	self:SetTextTile(self.mProbabilityTitle,ccClientText(41515))
end

function UISdAwardPre:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)
end

function UISdAwardPre:RefreshView()
	self:InitProbabilityList()
	self:RefreshJackpot()
end


function UISdAwardPre:InitData()
	local showList = gModelHalidom:GetHalidomExplainShowList()
	local showMap = {}
	for i,v in ipairs(showList) do
		showMap[v.type] = v.refData
	end
	self._halidomExplainShowMap = showMap
	self._halidomExplainShowList = showList
end

------------------------------------------------------------------
return UISdAwardPre