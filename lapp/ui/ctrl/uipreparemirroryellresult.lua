---
--- Created by Administrator.
--- DateTime: 2023/10/13 10:52:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPrepareMirrorYellResult:LWnd
local UIPrepareMirrorYellResult = LxWndClass("UIPrepareMirrorYellResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPrepareMirrorYellResult:UIPrepareMirrorYellResult()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPrepareMirrorYellResult:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPrepareMirrorYellResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPrepareMirrorYellResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitPara()
	self:InitStaticInfo()
end

function UIPrepareMirrorYellResult:RefreshHero()
	local item = self.mItemInfo
	local aniRootTrans = self:FindWndTrans(item,"AniRoot")
	local QualityImgTrans = self:FindWndTrans(aniRootTrans,"QualityImg")
	local HeroMapImgTrans = self:FindWndTrans(aniRootTrans,"HeroMapImg")
	local HeroBgTrans = self:FindWndTrans(aniRootTrans,"HeroBg")
	local RaceImgTrans = self:FindWndTrans(item,"RaceImg")

	local StarListTrans = self:FindWndTrans(aniRootTrans,"StarList")

	local refId = self._heroRefId
	local star = gModelHero:GetHeroInitStarByRefId(refId)
	self:OnDrawStarList(StarListTrans,star)

	local raceType = gModelHero:GetHeroType(refId)
	local img = gModelHero:GetRaceImgByRefId(raceType)
	if img then
		self:SetWndEasyImage(RaceImgTrans, img, function()
			CS.ShowObject(RaceImgTrans, true)
		end)
	end

	local heroRef = gModelHero:GetHeroRef(refId)
	local quality
	if gLGameLanguage:IsUSARegion() then
		if heroRef then
			quality = heroRef.quality
		end
	else
		quality = gModelHero:GetHeroQualityByRefId(refId, star)
	end
	if quality then
		local listBgBig = gModelItem:GetListBgBigByQuality(quality)
		self:SetWndEasyImage(HeroBgTrans,listBgBig)
		local heorBook1Bg = gModelItem:GetHeorBook1BgByQuality(quality)
		self:SetWndEasyImage(QualityImgTrans,heorBook1Bg)
	end

	local effRef = gModelHero:GetHeroShowRefByRefId(refId,star)
	local iconBig = effRef and effRef.iconBig
	if iconBig then
		self:SetWndEasyImage(HeroMapImgTrans, iconBig, function()
			CS.ShowObject(HeroMapImgTrans, true)
		end, true)
	end

	local qualityIcon = heroRef.qualityIcon
	self:SetWndEasyImage(self.mQualityIcon,qualityIcon,function()
		CS.ShowObject(self.mQualityIcon,true)
	end, true)

	self:SetWndClick(HeroBgTrans,function()
		self:OpenHeroInfoWnd()
	end)
end


function UIPrepareMirrorYellResult:InitPara()
	self._heroRefId  = gModelCallHero:GetPrepareHeroId()

	self:RefreshView()
end


function UIPrepareMirrorYellResult:RefreshView()
	local refId = self._heroRefId
	local name = gModelHero:GetHeroNameByRefId(refId)
	self:SetWndText(self.mNameText,name)

	local locationStr = gModelHero:GetLocationByRefId(refId)

	local careerName = gModelHero:GetCareerImgAndNameByHeroRefId(refId)
	local descStr = string.format("[%s]%s", careerName, locationStr)
	self:SetWndText(self.mDescText,descStr)

	self:RefreshHero()
end

function UIPrepareMirrorYellResult:InitStaticInfo()
	self:SetWndText(self.mTextTitle,ccClientText(37411))
	self:SetWndButtonText(self.mOkBtn, ccClientText(37413))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
end


function UIPrepareMirrorYellResult:OnClickOkBtn()
	LPlayerPrefs.SetPrepareMirrorCall("")
	gModelCallHero:SetPrepareMirrorCallData(nil, 1)
	--gModelPlayer:OnKKKAuthReceiveReq(9)
end

function UIPrepareMirrorYellResult:OnDrawStarList(trans,star)
	local img,temp,index = LUtil.GetHeroStarImg(star)
	local StarTrans
	local showStarImg
	for i = 1,5 do
		StarTrans = self:FindWndTrans(trans,"Star" .. i)
		showStarImg = temp >= i
		CS.ShowObject(StarTrans,showStarImg)
		if showStarImg then
			self:SetWndEasyImage(StarTrans,img)
		end
	end
end

function UIPrepareMirrorYellResult:OpenHeroInfoWnd()
	local refId = self._heroRefId
	gModelGeneral:OpenHeroStarPre({refId = refId})
	self:WndClose()
end

function UIPrepareMirrorYellResult:InitMsg()
	self:WndEventRecv(EventNames.KKK_AUTH_RECEIVE, function (type)
		if type == 9 then
			self:WndClose()
		end
	end)
end

function UIPrepareMirrorYellResult:InitEvent()
	self:SetWndClick(self.mOkBtn,function() self:OnClickOkBtn() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end)
end


------------------------------------------------------------------
return UIPrepareMirrorYellResult


