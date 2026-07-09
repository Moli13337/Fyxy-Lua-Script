---
--- Created by Administrator.
--- DateTime: 2023/10/20 10:54:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaMl:LWnd
local UISagaMl = LxWndClass("UISagaMl", LWnd)

------------------------------------------------------------------
---@type LUIHeroObject
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
---@type LUIDrawingCtrl
local LUIDrawingCtrl = LxRequire("LApp.UI.Display.LUIDrawingCtrl")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaMl:UISagaMl()
	---@type table<string,LUIHeroObject>
	self._uiHeroObjList = nil
	---@type LUIHeroObject
	self._curUIHeroObj = nil
	---@type LUIDrawingCtrl
	self._uiDrawingCtrl = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaMl:OnWndClose()
	if self._uiDrawingCtrl then
		self._uiDrawingCtrl:Destroy()
		self._uiDrawingCtrl = nil
	end

	--这个是从列表器拿出来的，列表进行删除就好了
	self._curUIHeroObj = nil

	LUtil.ClearHashTable(self._uiHeroObjList)
	self._uiHeroObjList = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaMl:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaMl:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetXUITextText(self.mSkillBtnName,ccClientText(10107))
	self:SetXUITextText(self.mCommentBtnName,ccClientText(10110))
	self:SetXUITextText(self.mShareBtnName,ccClientText(10118))
	self:SetXUITextText(self.mScreenBtnName,ccClientText(10120))
	self:SetXUITextText(self.mOpenBtnName,ccClientText(10117))
	self:SetXUITextText(self.mStarBtnName,ccClientText(10119))

	self:InitData()
	self:InitEvent()
	self:Refresh()
end

function UISagaMl:Init(refresh)
	self._heroEffId = gModelHero:GetHeroEffectByRefId(self._refId,self._star)
	if refresh then
		self:Refresh()
	end
end

function UISagaMl:InitData()
	self._refId = self:GetWndArg("refId")
	self._star = self:GetWndArg("star")
	self._list = self:GetWndArg("list")
	if self._list then
		for k,v in pairs(self._list) do
			if v == self._refId then
				self._index = k
			end
		end
	end
	self._openStory = false
	self:Init()
end

function UISagaMl:InitEvent()
	self:SetWndClick(self.mReturnBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mOpenBtn,function()
		if self._openStory then
			-- 打开传记
			GF.OpenWnd("UISagaBirth",{refId = self._refId})
		else
			GF.ShowMessage(ccClientText(10058))
		end
	end)
	self:SetWndClick(self.mSkillBtn,function()
		-- 皮肤
	end)
	self:SetWndClick(self.mCommentBtn,function()
		-- 评论
	end)
	self:SetWndClick(self.mShareBtn,function()
		-- 分享
	end)
	self:SetWndClick(self.mScreenBtn,function()
		-- 截屏
		GF.OpenWnd("UISchot",{refId = self._refId})
	end)
	self:SetWndClick(self.mStarBtn,function()
		-- 星级预览
--[[		GF.OpenWnd("UISagaStarPre",{refId = self._refId,list = self._list,index = self._index,func = function(refId)
			if self._refId ~= refId then
				self._refId = refId
				self._star = gModelHero:GetHeroInitStarByRefId(refId)
				for k,v in pairs(self._list) do
					if v == self._refId then
						self._index = k
					end
				end
				self:Init(true)
			end
		end})]]
		gModelGeneral:OpenHeroStarPre({refId = self._refId,list = self._list,index = self._index,func = function(refId)
			if self._refId ~= refId then
				self._refId = refId
				self._star = gModelHero:GetHeroInitStarByRefId(refId)
				for k,v in pairs(self._list) do
					if v == self._refId then
						self._index = k
					end
				end
				self:Init(true)
			end
		end})
	end)
end


function UISagaMl:OnDragHeroSpineEnd(heroObj, beginPos, endPos)
	if not self._index then return end
	if self._curUIHeroObj == nil then return end
	if self._curUIHeroObj ~= heroObj then return end
	local beginX = beginPos.x
	local endX = endPos.x
	if beginX - endX > 20 then
		self:CutHero(1)
	elseif beginX - endX < -20 then
		self:CutHero(-1)
	end
end

function UISagaMl:Refresh()
	local heroEffectRef = gModelHero:GetShowEffectById(self._heroEffId)
	if heroEffectRef then
		local name = ccLngText(heroEffectRef.name)
		self:SetXUITextText(self.mHeroName,name)
		local nickName = ccLngText(heroEffectRef.nickName)
		self:SetXUITextText(self.mNickName,"")
		local heroBookIcon = heroEffectRef.heroDrawing
		--local heroDrawingImage = heroEffectRef.heroDrawingImage
		local heroDrawingImage = nil

		if not string.isempty(heroBookIcon) then
			self:ChangeHeroObject(self._heroEffId, heroBookIcon)
			if self._heroImg then
				CS.ShowObject(self.mHeroImg,false)
			end
			self._spineKey = heroBookIcon
		elseif not string.isempty(heroDrawingImage) then
			local bgTrans = self.mHeroImg
			self:SetWndEasyImage(bgTrans,heroDrawingImage,function()
				local csImage = LxUiHelper.FindImageCtrl(bgTrans)
				csImage:SetNativeSize()
				CS.ShowObject(bgTrans,true)
			end)

			if self._uiDrawingCtrl then
				self._uiDrawingCtrl:Destroy()
				self._uiDrawingCtrl = nil
			end

			if self._curUIHeroObj then
				self._curUIHeroObj:ShowHero(false)
				self._curUIHeroObj = nil
			end

			self._heroImg = heroDrawingImage
		end
	end
end


function UISagaMl:CutHero(optNum)
	local newIndex = self._index + optNum
	local listLen = #self._list
	if newIndex > listLen then
		newIndex = 1
	elseif newIndex < 1 then
		newIndex = listLen
	end
	local heroRefId = self._list[newIndex]
	if heroRefId then
		self._refId = heroRefId
		self._star = gModelHero:GetHeroInitStarByRefId(heroRefId)
		self._index = newIndex
	end
	self:Init(true)
end

function UISagaMl:ChangeHeroObject(effectId, pbName)
	local uiHeroObjList = self._uiHeroObjList
	if not uiHeroObjList then
		uiHeroObjList = {}
		self._uiHeroObjList = uiHeroObjList
	end

	if self._uiDrawingCtrl then
		self._uiDrawingCtrl:Destroy()
		self._uiDrawingCtrl = nil
	end

	local newUIHeroObj = uiHeroObjList[pbName]
	local oldUIHeroObj = self._curUIHeroObj
	self._curUIHeroObj = nil

	if oldUIHeroObj and newUIHeroObj ~= oldUIHeroObj then
		oldUIHeroObj:ShowHero(false)
	end

	if not newUIHeroObj then
		newUIHeroObj = LUIHeroObject:New(self)
		uiHeroObjList[pbName] = newUIHeroObj

		self._curUIHeroObj = newUIHeroObj
		newUIHeroObj:Create(self.mHeroIcon,pbName,pbName)
		newUIHeroObj:SetDragFunc(function(...) self:OnDragHeroSpineEnd(...) end )
		newUIHeroObj:SetRectMatch(true)
		newUIHeroObj:ShowHero(true)
		newUIHeroObj:StartLoad()
	else
		self._curUIHeroObj = newUIHeroObj
		newUIHeroObj:ShowHero(true)
	end
	local uiDrawCtrl = LUIDrawingCtrl:New()
	self._uiDrawingCtrl = uiDrawCtrl
	uiDrawCtrl:SetHeroObject(newUIHeroObj)
	uiDrawCtrl:SetEffectInfo(self.mEffectRoot, 0, 3, 100)
	uiDrawCtrl:InitHeroEffectInfo(effectId)
	uiDrawCtrl:StartPlay()

end
------------------------------------------------------------------
return UISagaMl


