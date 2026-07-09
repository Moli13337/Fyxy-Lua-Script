---
--- Created by BY.
--- DateTime: 2023/10/13 19:58:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITaMopUpPop:LWnd
local UITaMopUpPop = LxWndClass("UITaMopUpPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaMopUpPop:UITaMopUpPop()
	---@type table<number, CommonIcon>
	self._commonIconTbl ={}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaMopUpPop:OnWndClose()
	self:ClearCommonIconList(self._commonIconTbl)
	self._commonIconTbl = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaMopUpPop:OnCreate()
	LWnd.OnCreate(self)

	self._rawardList={}--扫荡的奖励
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaMopUpPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	local itemFunc = function(refId,num)
		gModelGeneral:OpenItemInfoTip(refId,num)
	end
	local heroFunc = function()

	end
	local equipFunc = function(refId)
		gModelGeneral:OpenEquipInfoTip(refId,nil,nil,true)
	end
	self._funcList = {
		itemFunc,
		heroFunc,
		equipFunc,
	}
	self:InitCommand()
end

function UITaMopUpPop:InitEvent()
	self:SetWndClick(self.mCloseBtn, function(...)
		self:OnClickCloseWnd()
	end)
	self:SetWndClick(self.mBgImage, function(...)
		self:OnClickCloseWnd()
	end)
	self:SetWndClick(self.mVideoBtn, function(...)
		self:OnClickVideo()
	end)
	self:SetWndClick(self.mChallengeBtn, function(...)
		self:OnClickChallenge()
	end)
	self:SetWndClick(self.mMopUpBtn, function(...)
		self:OnClickChallenge()
	end)
end

function UITaMopUpPop:InitCommand()
	local refId = self:GetWndArg("refId")
	local _towerType = self:GetWndArg("towerType")
	self._towerType = _towerType
	self._refId = refId
	local ref = gModelTower:GetTowerLayer(_towerType,refId)
	self:SetWndText(self.mTitleText,string.replace(ccClientText(12113),ref.floorNum))
	self:SetWndText(self.mPassXUIText,ccClientText(12123))
	self:SetWndText(self.mTasXUIText,ccClientText(12114))
	self:SetWndText(self.mVideoText,ccClientText(11000))
	self:InitTextSizeWithLanguage(self.mPassXUIText,-2)
	self:InitTextSizeWithLanguage(self.mTasXUIText,-2)
	local _playerPower=gModelPower:GetMainCityPower()--gModelPlayer:GetPlayerFightPower()
	local str=""
	local recommendArr = string.split(ref.recommend,";")
	for i, v in ipairs(recommendArr) do
		local power = ""
		local recommend = tonumber(v)
		if(_playerPower >= recommend)then
			power = "<#139057>"..LUtil.PowerNumberCoversion(recommend).."</color>"
		else
			power = "<#ff5151>"..LUtil.PowerNumberCoversion(recommend).."</color>"
		end
		if i == 1 then
			str = power
		else
			str = str..";"..power
		end
	end

	self:SetWndText(self.mPowerText,string.replace(ccClientText(12109),str))
	local _rList={}
	local list=gModelTower:SetAawardDataList(ref.rewardFirst)
	for i = 1, #list do
		list[i].bOne=true
	end
	_rList=list
	local  olist=gModelTower:SetAawardDataList(ref.reward)
	for i = 1, #olist do
		table.insert(_rList,olist[i])
	end
	self._rawardList={}
	for i = 1, #olist do
		table.insert(self._rawardList,olist[i])
	end
	if(self._uiList)then
		self._uiList:RefreshList(_rList)
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mAwardScroll,_rList,function (...) self:ListItem(...) end)
		self._uiList:EnableScroll(true,true)
	end
	gModelTower:OnTowerFloorReq(ref.floorNum,_towerType)
end

function UITaMopUpPop:OnClickCloseWnd()
	--print("点击关闭界面")
	self:WndClose()
end

function UITaMopUpPop:ListItem(list,item, itemdata, itempos)
	local imageTrans= CS.FindTrans(item,"Image")
	local refId = itemdata.refId
	local itype = itemdata.type
	local num=itemdata.count
	local bEff=itemdata.bEff
	local bOne=itemdata.bOne or false
	CS.ShowObject(imageTrans,bOne)

	local iconTrans = CS.FindTrans(item ,"CommonUI/Icon")

	local uiCommonList = self._commonIconTbl
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(iconTrans)
	end
	baseClass:SetCommonReward(itype, refId, num)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()
	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		local data =
		{
			itemId = refId,
			itemType = itype,
			itemNum = num,
		}
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end

function UITaMopUpPop:OnClickVideo()
	--print("点击录像")
	GF.OpenWnd("UITaVdoPop",{refId=self._refId,towerType = self._towerType,openType = 1})

end

function UITaMopUpPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.TowerFloorResp,function (...)
		self:RefreshPopData()
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function (pb)
		self:OnClickCloseWnd()
	end)
end

function UITaMopUpPop:RefreshPopData()
	local player,minPower,num
	local str=ccClientText(12137)

	local firstFloorPlayer= gModelTower:GetFirstFloorPlayer()
	if(firstFloorPlayer and firstFloorPlayer.playerName~="")then
		player=firstFloorPlayer.playerName
	end
	local minFloorPlayer= gModelTower:GetMinFloorPlayer()
	if(minFloorPlayer and minFloorPlayer.playerName~="")then
		minPower=minFloorPlayer.playerName
	end

	num=gModelTower:GetCurrNum()
	self:SetWndText(self.mPlayerText,string.replace(ccClientText(12146),player or str))
	self:SetWndText(self.mLowestText,string.replace(ccClientText(12147),minPower or str))
	CS.ShowObject(self.mNumText,false)
	CS.ShowObject(self.mMopUpBtn,false)
	CS.ShowObject(self.mChallengeBtn,false)
	local refId = self._refId
	local _towerType = self._towerType
	local layer = gModelTower:GetCurrLayer(_towerType)
	local ref = gModelTower:GetTowerLayer(_towerType,refId)
	CS.ShowObject(self.mImgPassed,ref.floorNum<layer)
	--if ref.floorNum >= layer - 1 and _towerType ~= ModelTower.RACE_COM then
	--	return
	--end
	if(ref.floorNum < layer and _towerType == ModelTower.RACE_COM)then
		if( num<=0)then
			local vipNum=gModelTower:GetVipGoBuy()
			local guyNum=gModelTower:GetBuySweepNum()
			local guyStr=gModelTower:GetExpend(guyNum+1)
			-- CS.ShowObject(self.mMopUpBtn,true)
			self:SetWndText(CS.FindTrans(self.mMopUpBtn,"XUIText"),guyStr..ccClientText(12106))
			self:SetWndText(self.mNumText,string.replace(ccClientText(12107),vipNum-guyNum))
		else
			-- CS.ShowObject(self.mChallengeBtn,true)
			-- self:SetWndButtonText(self.mChallengeBtn,ccClientText(12105))
			-- self:SetWndText(self.mNumText,string.replace(ccClientText(12141),num))
		end
		-- CS.ShowObject(self.mNumText,true)

	elseif _towerType == ModelTower.RACE_COM then
		CS.ShowObject(self.mChallengeBtn,true)
		self:SetWndButtonText(self.mChallengeBtn,ccClientText(12104))
	elseif ref.floorNum >= layer then
		local _towerInfo = gModelTower:GetTowerInfoByTowerType(_towerType)
		if  _towerInfo.maxChallengesNum - _towerInfo.battleNum > 0 then
			CS.ShowObject(self.mChallengeBtn,true)
			self:SetWndButtonText(self.mChallengeBtn,ccClientText(12104))
		end
	end
end

function UITaMopUpPop:OnClickChallenge()
	local func= function()
		self:OnClickCloseWnd()
	end
	gModelTower:OnClickLayerBtn(self._towerType,self._refId,func)
end

------------------------------------------------------------------
return UITaMopUpPop


