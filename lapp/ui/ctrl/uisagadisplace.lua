---
--- Created by Administrator.
--- DateTime: 2023/10/10 20:22:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaDisplace:LWnd
local UISagaDisplace = LxWndClass("UISagaDisplace", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaDisplace:UISagaDisplace()
	---@type CommonIcon
	self._iconDisplaceHeroCls = nil
	---@type CommonIcon
	self._iconCurHeroCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaDisplace:OnWndClose()
	if self._iconCurHeroCls then
		self._iconCurHeroCls:Destroy()
		self._iconCurHeroCls = nil
	end
	if self._iconDisplaceHeroCls then
		self._iconDisplaceHeroCls:Destroy()
		self._iconDisplaceHeroCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaDisplace:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaDisplace:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:SetWndText(self.mEnterBtnName,ccClientText(10102))
	self:SetWndText(self.mCancelBtnName,ccClientText(10101))
	self:InitEvent()
	self:InitMsg()
	self:Refresh()
end

function UISagaDisplace:Refresh()
	local selectInfo = self._selectInfo
	local heroId,selectList = self._heroId,self._selectList
	local displaceHeroId
	local displaceHeroRefId
	for k,v in pairs(selectList) do
		if displaceHeroId and displaceHeroRefId then break end
		displaceHeroId = v
		displaceHeroRefId = gModelHero:GetRefIdById(v)
	end
	local needStar = selectInfo.needStar
	local selectName = gModelHero:GetHeroNameByRefId(displaceHeroRefId,needStar)
	local serverData = gModelHero:GetHeroServerDataById(heroId)
	local star = serverData.star
--[[	local zhihuanData = gModelHeroSpirit:GetZhiHuanData()
	local starList = zhihuanData.star]]
	local needItem,needNum,needHeroNum = selectInfo.needItemRefId,selectInfo.needItemNum,selectInfo.needHeroNum
--[[	for k,v in pairs(starList) do
		if needItem and needNum and needHeroNum then break end
		if v.heroStar == star then
			needItem,needNum,needHeroNum = v.refId,v.num,v.heroNum
		end
	end]]
	local starStr = string.replace(ccClientText(10050),needStar)
	selectName = starStr .. selectName .. "*" .. needHeroNum
	local itemName = gModelItem:GetNameByRefId(needItem)
	itemName = itemName .. "*" .. needNum
	local color = "fe8e16"
	local str = string.replace(ccClientText(14414),color,selectName,color,itemName)
	self:SetWndText(self.mDesc,str)
	--GetHeroNameByRefId
	local curHeroIconTrans = CS.FindTrans(self.mCurHero,"HeroIcon")
	if curHeroIconTrans then
		local baseClass = self._iconCurHeroCls
		if not baseClass then
			baseClass = CommonIcon:New()
			self._iconCurHeroCls = baseClass
			baseClass:Create(curHeroIconTrans)
		end
		baseClass:SetHeroPlayer(heroId)
		baseClass:DoApply()
	end

	local displaceHeroIconTrans = CS.FindTrans(self.mDisplaceHero,"HeroIcon")
	if displaceHeroIconTrans then
		local disHeroData = {
			id = displaceHeroId,
			refId = displaceHeroRefId,
			star = star,
			level = serverData.lv,
		}
		local baseClass = self._iconDisplaceHeroCls
		if not baseClass then
			baseClass = CommonIcon:New()
			self._iconDisplaceHeroCls = baseClass
			baseClass:Create(displaceHeroIconTrans)
		end
		baseClass:SetHeroDataSet(disHeroData)
		baseClass:DoApply()
	end
end

function UISagaDisplace:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeroDisplaceResp,function(pb)
		self:WndClose()
	end)
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error,argList)
		local needItemRefId = self._selectInfo.needItemRefId
		gModelGeneral:OpenGetWayWnd({itemId = needItemRefId})
	end)
end

function UISagaDisplace:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCancelBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function()
		if self._func then self._func() end
	end)
end

function UISagaDisplace:InitData()
	local selectInfo = self:GetWndArg("selectInfo")
	self._selectInfo = selectInfo
	self._heroId = selectInfo.heroId
	self._selectList = selectInfo.selectList
	self._func = selectInfo.func
end


------------------------------------------------------------------
return UISagaDisplace


