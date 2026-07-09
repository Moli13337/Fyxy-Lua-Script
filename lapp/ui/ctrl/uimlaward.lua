---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMlAward:LWnd
local UIMlAward = LxWndClass("UIMlAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMlAward:UIMlAward()
	---@type UIIconEasyList
	self._uiHandList = nil

	---@type UIIconEasyList
	self._uiTasList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMlAward:OnWndClose()
	if self._uiHandList then
		self._uiHandList:Destroy()
		self._uiHandList = nil
	end
	if self._uiTasList then
		self._uiTasList:Destroy()
		self._uiTasList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMlAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMlAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self._uicommonList={}
	self._playAni=true
	self:InitCommand()
end

function UIMlAward:InitEvent()
	self:SetWndClick(self.mBgImageObj,function (...) self:WndClose() end)
	self:SetWndClick(self.mCloseBtnObj,function (...) self:WndClose() end)
end

function UIMlAward:OnDestroy()

	if self._uicommonList then
		for k,v in pairs(self._uicommonList) do
			v:Destroy()
		end
	end
	self._uicommonList = nil

	LWnd.OnDestroy(self)
end

function UIMlAward:InitCommand()
	local battleNum=self:GetWndArg(1)
--关卡据点配置表

	local ref=GameTable.MainInstanceMissionRef[battleNum]

	self:SetWndText(self.mNameXUIText, ccLngText(ref.nameWorld))
	self:InitTextSizeWithLanguage(self.mNameXUIText,-6)
	self:SetWndText(self.mHangXUIText,ccClientText(10609))
	self:SetWndText(self.mTasXUIText,ccClientText(10610))


	local rewardRef= gModelInstance:GetMissionCfg(battleNum)

	local handRewardDatalist= LxDataHelper.ParseItem(rewardRef.showReward)--self:SetItemData(rewardRef.showReward,true)
	local handList = self._uiHandList
	if(not handList)then
		handList = UIIconEasyList:New()
		self._uiHandList = handList
		handList:Create(self, self.mHangAwardList)
		handList:EnableScroll(true,true)
		handList:SetShowNum(false)
	end
	handList:RefreshList(handRewardDatalist)

	local tasRewardDatalist= LxDataHelper.ParseItem(ref.winReward)
	local tasList = self._uiTasList
	if(not tasList)then
		tasList = UIIconEasyList:New()
		self._uiTasList = tasList
		tasList:Create(self, self.mTasAwardList)
		tasList:EnableScroll(true,true)
	end
	tasList:RefreshList(tasRewardDatalist)

	local datalist= LxDataHelper.ParseItem(ref.timeRewardFixed)
	if(self._uiList)then
		self._uiList:RefreshList(datalist)
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mTimeAwardList,datalist,function (...) self:ListTimeItem(...) end)
	end
end

function UIMlAward:SetItemData(rewardList,isShow)
	local _itemList = {}
	local rwewardArr=string.split(rewardList,",")
	for i = 1, #rwewardArr do
		local rewardData=string.split(rwewardArr[i],"=")
		_itemList[i]={
			itype = tonumber(rewardData[1]),itemId = tonumber(rewardData[2]),count = tonumber(rewardData[3]),isShow=isShow
		}
	end
	return _itemList
end

function UIMlAward:ListTimeItem(list,item, itemdata, itempos)
--关卡据点配置表
	local ref=GameTable.PlayerItemRef[itemdata.itemId]
	local iconTran=CS.FindTrans(item,"IconImage")
	self:SetWndEasyImage(iconTran,ref.icon)
	local textTran=CS.FindTrans(item,"NumXUIText")
	self:SetWndText(textTran,itemdata.itemNum.."/m")
end

------------------------------------------------------------------
return UIMlAward


