---
--- 皮肤图鉴-收集奖励弹框
--- Created by Ease.
--- DateTime: 2023/10/25 20:57:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISnBookCollectPop:LWnd
local UISnBookCollectPop = LxWndClass("UISnBookCollectPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISnBookCollectPop:UISnBookCollectPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISnBookCollectPop:OnWndClose()
	self:ClearCommonIconList(self._propList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISnBookCollectPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISnBookCollectPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitBtnEvent()
	self:InitMessage()
end

function UISnBookCollectPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.HeroSkinPropertyListResp,function(...)
		self:OnHeroSkinPropertyListResp(...)
	end)
end
function UISnBookCollectPop:OnDrawCollectListCell(list, item, itemdata, itempos)
	local skinCntTxt = self:FindWndTrans(item, "SkinCntTxt")
	local activityBtn = self:FindWndTrans(item, "ActivityBtn")
	local activityTxt = self:FindWndTrans(activityBtn, "ActivityTxt")
	local activityImg = self:FindWndTrans(item, "ActivityImg")
	local propList = self:FindWndTrans(item, "PropList")
	local isActive = false
	local canActive = false
	local showColorStr = false
	if (self._collectDataList and self._collectDataList[tonumber(itemdata.refId)]) then
		isActive = true
		showColorStr = true
	else
		isActive = false
		self:SetWndText(activityTxt, ccClientText(27050)) --27050 激活
		self:InitTextSizeWithLanguage(activityTxt, -4)
		self:InitTextCharacterWithLanguage(activityTxt, -35.6)
		if(self._curSkinCnt >= itemdata.need)then
			canActive = true
			showColorStr = true
		end
	end
	local needStr = itemdata.need
	if showColorStr then
		needStr = "<color=#139056>"..needStr.."</color>"
	end
	local desStr = string.replace(ccClientText(30201), needStr) --30201 收集任意皮肤:   %s
	self:SetWndText(skinCntTxt, desStr)

	CS.ShowObject(activityBtn, not isActive)
	self:SetWndEasyImage(activityBtn,"public_btn_2_2")
	if(not canActive)then
		--self:SetWndImageGray(activityBtn,not isActive)
		self:SetWndEasyImage(activityBtn,"public_btn_ash_2")
	end
	CS.EnableClickListener(activityBtn.gameObject,canActive)
	self:SetWndClick(activityBtn, function()
		--self:SetWndImageGray(activityBtn,true)
		CS.EnableClickListener(activityBtn.gameObject,false)
		if(self._curSkinCnt >= itemdata.need)then
			gModelSkinBook:OnHeroSkinPropertyActiveReq(itemdata.refId)
		end
	end, LSoundConst.CLICK_BUTTON_COMMON)
	CS.ShowObject(activityImg, isActive)
	local sttrArr = string.split(itemdata.attr, ",")
	local dataList = sttrArr
	local list = self._propList[itemdata.refId]
	if (self.list) then
		list:RefreshList(dataList)
	else
		local insId = item:GetInstanceID()
		list = self:GetUIScroll(insId)
		self._propList[insId] = list
		list:Create(propList, dataList, function(...)
			self:OnDrawPropListCell(...)
		end)
	end
end
--收集列表
function UISnBookCollectPop:InitCollectList()
	local list = self._properRef
	if (self._collectList) then
		self._collectList:RefreshData(list)
	else
		self._collectList = self:GetUIScroll("mCollectList")
		self._collectList:Create(self.mCollectList, list, function(...)
			self:OnDrawCollectListCell(...)
		end, UIItemList.SUPER)
		--self._collectList:EnableScroll(true, false)
	end
	self._collectList:DrawAllItems(false)

	if not self._init then
		local heroListPos = gModelSkinBook:GetCollectListActivityIndex(list,self._collectDataList,self._curSkinCnt)
		local hasWaitGuide = gModelGuide:HasWaitGuide()
		if  hasWaitGuide then
			heroListPos = 1
		end
		self._collectList:MoveToPos(heroListPos)
		self._init = true
	end
end
function UISnBookCollectPop:SetUI()
	CS.ShowObject(self.mMask, true)
	CS.ShowObject(self.mCollectList, true)
	self:SetWndText(self.mCloseTxt, ccClientText(10103)) --10103 点击空白处关闭界面
	self:SetWndText(self.mTitleTxt, ccClientText(30200)) --30200 收集奖励
	self:SetWndText(self.mDesTxt, ccClientText(30202)) --30202 注：皮肤加成对全体伙伴生效
	self:InitTextLineWithLanguage(self.mDesTxt, -30)
	self:InitCollectList()
end
function UISnBookCollectPop:InitBtnEvent()
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UISnBookCollectPop:InitData()
	self._collectDataList = self:GetWndArg("collectDataList")
	self._curSkinCnt =self:GetWndArg("curSkinCnt")
	self._properRef = gModelSkinBook:GetHeroSkinPropertyRef()
	self._propList = {}
	self:SetUI()
end
function UISnBookCollectPop:OnDrawPropListCell(list, item, itemdata, itempos)
	local propIcon = self:FindWndTrans(item, "PropIcon")
	local propNameTxt = self:FindWndTrans(item, "PropNameTxt")
	local propValueTxt = self:FindWndTrans(item, "PropValueTxt")

	local dataArr = string.split(itemdata, "=")
	local attRefId = dataArr[1] --属性id
	--local attType = dataArr[2] --属性加成类型 1固伤 2百分比 (弃用 改为 数值小于1显示百分比)
	local attValue = dataArr[3] --属性值
	local attributeRef = gModelHero:GetAttributeRefById(tonumber(attRefId))--属性表
	local attName = attributeRef.name --属性名
	self:SetWndText(propNameTxt, ccLngText(attName))
	local attNum = tonumber(attValue)
	attValue = attNum > 1 and attValue or attValue * 100
	local valueStr = attNum > 1 and "+" .. attValue or "+" .. attValue .. "%"
	self:SetWndText(propValueTxt, valueStr)
	local iconPath = attributeRef.icon --图标名
	self:SetWndEasyImage(propIcon, iconPath)
end

function UISnBookCollectPop:OnHeroSkinPropertyListResp(pb, ret)
	self._collectDataList = {}
	for i, v in pairs(pb.refId) do
		if(type(v) and type(v) == "number")then
			self._collectDataList[v] = v
		end
	end
	gModelSkinBook:SetCollectDataList(self._collectDataList)
	self:SetUI()
end
------------------------------------------------------------------
return UISnBookCollectPop


