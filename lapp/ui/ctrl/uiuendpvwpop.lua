---
--- Created by BY.
--- DateTime: 2023/10/5 14:54:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIUendPvwPop:LWnd
local UIUendPvwPop = LxWndClass("UIUendPvwPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIUendPvwPop:UIUendPvwPop()
	---@type table<number, CommonIcon>
	self._heroIconList = {}

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIUendPvwPop:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIUendPvwPop:OnCreate()
	LWnd.OnCreate(self)

	self._nextFlushTimeKey = "_nextFlushTimeKey"
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIUendPvwPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	--self:InitMessage()
	self:InitCommand()
end

function UIUendPvwPop:ListItem(list,item, itemdata, itempos)
	local icon = CS.FindTrans(item,"Icon")
	local titleImage = CS.FindTrans(item,"TitleImage")
	local titleText = CS.FindTrans(item,"TitleImage/TitleText")
	local timeText = CS.FindTrans(item,"TimeText")
	local scrollRect = self:FindWndTrans(item,"scrollRect")
	local desText = CS.FindTrans(scrollRect,"DesText")
	local heroScroll = CS.FindTrans(item,"HeroScroll")

	self:SetWndText(titleText,ccClientText(17240))
	self:InitTextSizeWithLanguage(titleText, -4)
	local timeStr = ""
	if(itempos == 1)then
		local time=GetTimestamp()
		local endTime = self._nextFlushTime
		local timespan= endTime/1000-time
		self._TimeText = timeText
		if(timespan>0)then
			self:SetTime()
			self:TimerStop(self._nextFlushTimeKey)
			self:TimerStart(self._nextFlushTimeKey,1,false,-1)
		end
	else
		local oldTime = self._currFlushTime
		local timeGs = ccClientText(17243)
		local oldTimeStr = LUtil.OSDate(timeGs, oldTime)
		self._currFlushTime = self._currFlushTime + itemdata.time
		local newTimeStr = LUtil.OSDate(timeGs, self._currFlushTime)
		timeStr = string.replace(ccClientText(17242),oldTimeStr,newTimeStr)
		self:SetWndText(timeText,timeStr)
	end
	self:SetWndText(desText,ccLngText(itemdata.noticeDesc))
	if(itemdata.recommendIcon~="")then
		self:SetWndEasyImage(icon,itemdata.recommendIcon)
	end
	local arr=string.split(itemdata.recommendHero,",")
	local list={}
	for i, v in ipairs(arr) do
		local data={
			refId=tonumber(v)
		}
		table.insert(list,data)
	end
	local InstanceID = item:GetInstanceID()
	local uiList = self:GetUIScroll(InstanceID)
	if(uiList:GetList())then
		uiList:RefreshData(list)
	else
		uiList:Create(heroScroll,list,function (...) self:HeroListItem(...) end)
	end
end

function UIUendPvwPop:HeroListItem(list,item, itemdata, itempos)
	local heroTrans = CS.FindTrans(item,"Root/HeroIcon")
	local heroData={
		refId=itemdata.refId,
		star=gModelHero:GetHeroRef(itemdata.refId).initStar,
		trans=heroTrans,
	}
	local InstanceID = item:GetInstanceID()
	local baseClass = self._heroIconList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._heroIconList[InstanceID] = baseClass
		baseClass:Create(heroTrans)
		self:SetIconClickScale(heroTrans, true)
	end
	baseClass:SetHeroDataSet(heroData)
	baseClass:DoApply()

	self:SetWndClick(heroTrans,function ()
		gModelGeneral:OpenHeroSimpleTip(itemdata.refId)
		--gModelGeneral:OpenHeroTipByRefId(itemdata.refId)
	end)
end

function UIUendPvwPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIUendPvwPop:OnTimer(key)
	if(self._nextFlushTimeKey==key)then
		self:SetTime()
	end
end

function UIUendPvwPop:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(17219))
	local manList = {}
	local list = {}
	local specialType = gModelEndles:GetSpecialType()
	self._nextFlushTime = gModelEndles:GetEndTime()
	self._currFlushTime = self._nextFlushTime/1000
	local cRef = gModelEndles:GetEndlessRefByRefId(specialType)
	local currSort = cRef.rotateSort
	local ref = gModelEndles:GetEndlessRef()
	for i, v in pairs(ref) do
		if(v.openType==2)then
			if(v.rotateSort>=currSort)then
				table.insert(list,v)
			else
				table.insert(manList,v)
			end
		end
	end
	table.sort(list,function(a,b)
		return self:Sort(a,b)
	end)
	table.sort(manList,function(a,b)
		return self:Sort(a,b)
	end)
	if(#manList>0)then
		for i, v in ipairs(manList) do
			table.insert(list,v)
		end
	end
	local _uiList = self:GetUIScroll("cell")
	_uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
	_uiList:EnableScroll(true,false)
end

function UIUendPvwPop:SetTime()--设置时间
	local time=GetTimestamp()
	local endTime = self._nextFlushTime
	local timespan= endTime/1000-time
	if(timespan <= 0)then
		self:TimerStop(self._nextFlushTimeKey)
		self:WndClose()
		return
	end
	local timeStr = LUtil.FormatTimespanCn(timespan)
	self:SetWndText(self._TimeText,string.replace(ccClientText(17241),timeStr))
end

function UIUendPvwPop:Sort(a,b)
	local aSort = a.rotateSort
	local bSort = b.rotateSort
	if(aSort ~= bSort)then
		return aSort < bSort
	end
	return false
end
------------------------------------------------------------------
return UIUendPvwPop


