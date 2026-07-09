---
--- Created by Administrator.
--- DateTime: 2026/6/1 16:25:02
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISkinUpOpt:LWnd
local UISkinUpOpt = LxClass("UISkinUpOpt", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISkinUpOpt:UISkinUpOpt()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISkinUpOpt:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISkinUpOpt:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISkinUpOpt:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
end

function UISkinUpOpt:InitEvent()
	self:SetWndClick(self.mBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISkinUpOpt:InitData()
	self:SetWndText(self.mBlankTxt,ccClientText(10103))
	self:SetWndEasyImage(self.mTitle,"draconic_txt_2",nil,true)
	self._heroId = self:GetWndArg("heroRefId")
	self.starRefId = self:GetWndArg("starRefId")
	self.OldplayerPower = self:GetWndArg("playerPower")
	self.CurstarRefId = self.starRefId -1
	self.SkinUpStarInfo = gModelSkinBook:GetSkinUpStarConfig(self.starRefId)
	self.CurSkinUpStarInfo = gModelSkinBook:GetSkinUpStarConfig(self.CurstarRefId)
	self:RefreshUI()
end

function UISkinUpOpt:RefreshUI()
	self:CreateEffect(self.mShengxingTitle,"fx_ui_shengxing_1")
	local SingelStr = ccClientText(17403)
	local Allstr = ccClientText(17429)
	SingelStr = string.replace(SingelStr, "")
	Allstr = string.replace(Allstr, "")
	
	local CurSkinUpStarInfo = self.CurSkinUpStarInfo
	local SkinUpStarInfo = self.SkinUpStarInfo
	
	local curUpStarStrSingle = CurSkinUpStarInfo.Attr
	local curUpStarStrAll = CurSkinUpStarInfo.AttrAll
	local UpStarStrSingle = SkinUpStarInfo.Attr
	local UpStarStrAll = SkinUpStarInfo.AttrAll
	self:InitAttr(curUpStarStrSingle,false,true)
	self:InitAttr(curUpStarStrAll,true,true)
	self:InitAttr(UpStarStrSingle,false,false)
	self:InitAttr(UpStarStrAll,true,false)
	self:InitSkinIcon(self.mHeroIconItem1,CurSkinUpStarInfo)
	self:InitSkinIcon(self.mHeroIconItem2,SkinUpStarInfo)

	self:SetWndText(self.mAllAttrTittle, Allstr)
	self:SetWndText(self.mSingleAttrTittle, SingelStr)

	self._NewPlayerPower = checknumber(gModelPower:GetMainCityPower())

	self:SetWndText(self.mPlayerPowOldNum, self.OldplayerPower)
	self:SetWndText(self.mPlayerPowNewNum, self._NewPlayerPower)

	self:SetWndText(self.mPlayerPowName,ccClientText(47302))
end

function UISkinUpOpt:InitSkinIcon(SkinIconTrans,UpStarInfo)
	local StarGroup = self:FindWndTrans(SkinIconTrans,"StarGroup")
	local effRef = gModelHero:GetShowEffectById(UpStarInfo.Skin)
	local ImgIcon = self:FindWndTrans(SkinIconTrans,"HeroIcon")
	self:SetWndEasyImage(ImgIcon,effRef.icon)
	for i = 1, UpStarInfo.lv do
		local starTrans = self:FindWndTrans(StarGroup, "Star"..i)
		CS.ShowObject(starTrans, true)
	end

	self:CreateEffect(SkinIconTrans,"fx_ui_huanraoliuxing",SkinIconTrans:GetInstanceID())
end

function UISkinUpOpt:InitAttr(attr,isAll,isCur)
	local constAttrStr = "+%s"
	local AttrTransRoot = {}
	if isAll then
		AttrTransRoot = self.mAllAttr
	else
		AttrTransRoot = self.mSingleAttr
	end
	local attrs = LxDataHelper.ParseAttrList(attr)
	local attrRefId
	for i,v in ipairs(attrs) do
		attrRefId = v.refId
		local attrBgIdxTrans = self:FindWndTrans(AttrTransRoot,"AttrBg"..i)
		local NameTxtTrans = self:FindWndTrans(attrBgIdxTrans,"AttrName")
		local txtTrans = isCur and self:FindWndTrans(attrBgIdxTrans,"CurAttr") or self:FindWndTrans(attrBgIdxTrans,"NewAttr")
		local tempStr = string.format(constAttrStr,gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, v.type, v.value))
		self:SetWndText(NameTxtTrans, gModelHero:GetAttributeNameById(attrRefId))
		self:SetWndText(txtTrans, tempStr)
	end
end

function UISkinUpOpt:CreateEffect(trans,effectName,effectKey,effectSize)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans,effectName,effectKey,effectSize,false,false)
end

------------------------------------------------------------------
return UISkinUpOpt