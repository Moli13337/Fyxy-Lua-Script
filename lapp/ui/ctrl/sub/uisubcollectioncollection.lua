---
--- Created by admin.
--- DateTime: 2023/10/8 17:30:04
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubCollectionCollection:LChildWnd
local UISubCollectionCollection = LxWndClass("UISubCollectionCollection", LChildWnd)
local typeVerticalLayoutGroup = typeof(UnityEngine.UI.VerticalLayoutGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubCollectionCollection:UISubCollectionCollection()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubCollectionCollection:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubCollectionCollection:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubCollectionCollection:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsJapanVersion()
	
	self:InitData()
end
function UISubCollectionCollection:InitData()
	self._sid = self:GetWndArg("sid")
	self._pbData = self:GetWndArg("pbData")
	self._activityWebData = self:GetWndArg("activityWebData")
	self._endActivityTime = self:GetWndArg("endTime") --活动结束事件
	self._showEndActivityTime = self:GetWndArg("showEndTime") --活动延迟展示时间
	self._showTimeKey = "_endTimeKey"
	self._config = self._activityWebData.config--配置表
	self._pageId = self:GetWndArg("pageId")
	self._showBg = self:GetWndArg("showBg")
	self._chunk = self._activityWebData.chunk[self._pageId] --分页表sa
	self._entries = self._chunk.entries
	self._moveToIndex = 1
	self:SetUI()
end

function UISubCollectionCollection:OnWndRefresh()
	self:InitData()
end
function UISubCollectionCollection:SetHeroSpine(heroId,heroPos,isTurn)
	--local effectId = tonumber(heroId)
	--local effRef = gModelHero:GetShowEffectById(effectId)
	--local spineName = effRef.heroDrawing
	local spineName = heroId
	CS.ShowObject(self.mHeroPaint, spineName)
	self:CreateWndSpine(self.mHeroPaint, spineName, spineName, false, function(dpSpine)
		dpSpine:SetIgnoreTimeScale(true)
	end)
	if self._config.enterHeroPos then
		local posArr = string.split(heroPos,"|")
		local v2 = Vector2.New(tonumber(posArr[1]),tonumber(posArr[2]))
		self:SetAnchorPos(self.mHeroPaint, v2)
	end
	if isTurn == 1 then
		self.mHeroPaint.localScale = Vector3.New(-1, 1, 1)
	end
end

function UISubCollectionCollection:StopShowTimer()
	self:TimerStop(self._showTimeKey)
	--self:WndClose()
end

--region 活动倒计时
function UISubCollectionCollection:RefreshShowTime()
	local timeValue = self._endActivityTime or 0
	local showEndActivityTime = self._showEndActivityTime
	if showEndActivityTime and showEndActivityTime > timeValue then
		timeValue = showEndActivityTime
	end
	self._endTime = timeValue
	local showTime = self._endTime > 0
	if(self._config.timePos)then
		local pos = LxDataHelper.ParseVector2NotEmpty2(self._config.timePos)
		self:SetAnchorPos(self.mTimeBg, pos)
	end
	CS.ShowObject(self.mTimeBg, showTime)
	if not showTime then
		return
	end
	self:ShowTimerFunc()
	self:TimerStart(self._showTimeKey, 1, false, -1)
end
function UISubCollectionCollection:OnTextIconList(list, item, itemdata, itempos)
	local itemRoot = self:FindWndTrans(item, "ItemRoot")
	local cntTxt = self:FindWndTrans(item, "CntTxt")
	-- local icon = self:FindWndTrans(item, "Icon")
	--local IconBg = self:FindWndTrans(item,"IconBg")
	local itemId = tonumber(itemdata)
	-- local iconRef = gModelItem:GetRefByRefId(itemId)    --道具图标
	-- local iconPath = iconRef.icon
	-- self:SetWndEasyImage(icon, iconPath, nil, true)
	--local iconBg = gModelItem:GetIconBgByQualityId(iconRef.quality)
	--self:SetWndEasyImage(IconBg,iconBg,function()
	--	CS.ShowObject(IconBg,true)
	--end ,true)

	local hadCnt = gModelItem:GetNumByRefId(itemId)
	local numStr = tostring(hadCnt)
	local coversionHadCnt
	if(#numStr >= 9)then
		local displayNum =  math.floor(hadCnt / math.pow(10,8))
		coversionHadCnt = displayNum .. ccClientText(2014)--"亿"
	elseif(#numStr >= 5)then
		local displayNum =  math.floor(hadCnt / math.pow(10,4))
		coversionHadCnt = displayNum .. ccClientText(2013)--"万"
	else
		coversionHadCnt = tostring(hadCnt)
	end
	self:SetWndText(cntTxt,coversionHadCnt)
	-- self:SetWndClick(icon,function()
	-- 	local ref = gModelItem:GetRefByRefId(itemId)
	-- 	if not string.isempty(ref.jump)then
	-- 		gModelGeneral:OpenItemInfoTip(itemId, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 1)
	-- 	else
	-- 		gModelGeneral:ShowCommonItemTipWnd({
	-- 			itemType = LItemTypeConst.TYPE_ITEM,
	-- 			itemId = itemId,
	-- 			itemNum = hadCnt,
	-- 		})
	-- 	end
	-- end)
	self.commonUIList = table.isempty(self.commonUIList) and {} or self.commonUIList
	local instanceId = item:GetInstanceID()
	if not self.commonUIList[instanceId] then
		self.commonUIList[instanceId] = CommonIcon:New()
		self.commonUIList[instanceId]:Create(itemRoot)
	end
	self.commonUIList[instanceId]:SetCommonReward(LItemTypeConst.TYPE_ITEM, itemId, 0)
	self.commonUIList[instanceId]:DoApply()
	self:SetWndClick(itemRoot, function()
		gModelGeneral:ShowCommonItemTipWnd({itemType = LItemTypeConst.TYPE_ITEM, itemId = itemId, data = hadCnt})
	end)
end
function UISubCollectionCollection:OnTextItemList(list, item, itemdata, itempos)
	local nameTxt = self:FindWndTrans(item, "NameTxt")
	self:SetWndText(nameTxt,itemdata)
	if gLGameLanguage:IsJapanVersion() then
		self:InitTextLineWithLanguage(nameTxt,-50)
	end

end

function UISubCollectionCollection:ShowTimerFunc()
	local nowTime = GetTimestamp()
	local timeDif = os.difftime(self._endTime, nowTime)
	if timeDif <= 0 then
		self:SetWndText(self.mTimeTxt, "")
		self:StopShowTimer()
		return
	end
	local timeStr = LUtil.FormatTimespanCn(timeDif)
	timeStr = string.replace(ccClientText(11637), timeStr)
	self:SetWndText(self.mTimeTxt, timeStr)
end
--描述文本列表
function UISubCollectionCollection:SetTxtList()
	local list = string.split(self._config.tipsDescription,"|")
	local itemList = self._textItemList
	local textRoot = self._isEnus and self.mTextList_Enus or self.mTextList

	if gLGameLanguage:IsJapanVersion() then
		local tran = CS.FindTrans(self.mTextList_Enus,"ItemRoot")
		local group = tran:GetComponent(typeVerticalLayoutGroup)
		group.spacing = 20
	end

	if itemList then
		itemList:RefreshList(list)
	else
		itemList = self:GetUIScroll("mTextItemList")
		itemList:Create(textRoot, list, function(...)
			self:OnTextItemList(...)
		end)
		self._textItemList = itemList
		self._textItemList:EnableScroll(true, false)
	end
end
function UISubCollectionCollection:SetUI()
	if(self._showBg)then
		self:SetWndEasyImage(self.mBgImg, self._config.image)
		CS.ShowObject(self.mBgImg,true)
	end
	self:SetWndText(self.mDialogueTxt,self._config.dropTxt)
	self:SetWndText(self.mDesTitleTxt,ccClientText(32200))
	-- self:SetWndText(self.mListTitleTxt,ccClientText(32201))
	self:SetWndText(self.mListTitleTxt,self._config.heroCollrctTitleTxt)
	self:SetWndButtonText(self.mGoBtn, self._config.jumpTxt)
	self:SetWndClick(self.mGoBtn, function()
		if self._config.jump then
			gModelFunctionOpen:Jump(self._config.jump, self:GetWndName())
		end
	end)
	self:SetHeroSpine(self._config.enterHero,self._config.enterHeroPos,self._config.enterHeroTurn)
	self:SetTxtList()
	self:SetTextIconList()
	self:SetDesBg(self._config.dropTxtPos)
	self:RefreshShowTime()
end
--收集文字图标列表
function UISubCollectionCollection:SetTextIconList()
	local dropItemId = self._config.dropItemId
	local dropArr = string.split(dropItemId,"|")
	local list = dropArr
	local itemList = self._textIconList
	if itemList then
		itemList:RefreshList(list)
	else
		itemList = self:GetUIScroll("mTextIconList")
		itemList:Create(self.mItemList, list, function(...)
			self:OnTextIconList(...)
		end)
		self._textIconList = itemList
		self._textIconList:EnableScroll(false, true)
	end
end

function UISubCollectionCollection:OnTimer(key)
	if key == self._showTimeKey then
		self:ShowTimerFunc()
	end
end
function UISubCollectionCollection:SetDesBg(dropTxtPos)
	local arr = string.split(dropTxtPos,"|")
	local isScale = arr[1] and arr[1] == "1"
	local x = isScale and -1 or 1
	self.mDialogueBg.localScale = Vector2(x,1)
	if arr[2] then
		local pos = string.split(arr[2],",")
		self.mDesBg.anchoredPosition = Vector2(tonumber(pos[1]),tonumber(pos[2]))
	end
end
--endregion

------------------------------------------------------------------
return UISubCollectionCollection


