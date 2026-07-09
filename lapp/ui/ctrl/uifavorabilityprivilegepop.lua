---
--- Created by Administrator.
--- DateTime: 2024/4/24 18:28:59
---
------------------------------------------------------------------
local typeofRenderer = typeof(UnityEngine.Renderer)
local typeofCanvas = typeof(UnityEngine.Canvas)
local LWnd = LWnd
---@class UIFavorabilityPrivilegePop:LWnd
local UIFavorabilityPrivilegePop = LxWndClass("UIFavorabilityPrivilegePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFavorabilityPrivilegePop:UIFavorabilityPrivilegePop()
	self._effectKey = "_effectKey"

	self.data = {
		["heroClickSpAction"] = {
			icon = "garden_icon_love_1",
			text = "herobook_txt_7"
		},
		["heroPlayItemSpAction"] = {
			icon = "garden_icon_love_2",
			text = "herobook_txt_5"
		},
		["heroCloseUpSpAction"] = {
			icon = function()
				local heroRefId = self:GetWndArg("heroRefId")
				local heroData = gModelHero:GetFavorabilityInfo(heroRefId)
				local heroEffRef = GameTable.CharacterEffectRef[heroData.heroRefId]
				return heroEffRef.playItemIcon
			end,
			text = "herobook_txt_6"
		}
	}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFavorabilityPrivilegePop:OnWndClose()
	LWnd.OnWndClose(self)
	self._rendererList = nil
	self:TweenSeqKill(self._effectKey)
	if self.isTotalPop then
		GF.OpenWnd("UIFavorabilityUpLvPop")
	end
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFavorabilityPrivilegePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFavorabilityPrivilegePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mTxtCloseTips, function(...) self:WndClose()  end)
	self:SetWndText(self.mTxtCloseTips ,ccClientText(41037))
	self:OnUpdatePanel()
	self:InitLoveLvOrder()
end
function UIFavorabilityPrivilegePop:PlayEffect()
	local seqTween
	self:TweenSeqKill(self._effectKey)
	seqTween = self:TweenSeqCreate(self._effectKey,function(seq)
		local showTopTime = 0.2
		local showAttrTime = 0.1

		CS.ShowObject(self.mImgTitle,true)
		seq:AppendCallback(function ()
			self:CreateEffect(self.mImgTitle,"fx_ui_shengxing_1")
		end)
		seq:AppendInterval(showTopTime)

		-- CS.ShowObject(self.mImgQuality,true)
		-- seq:AppendCallback(function ()
		-- 	self:CreateEffect(self.mImgQuality,"fx_ui_shengxing_2")
		-- end)
		-- seq:AppendInterval(showTopTime)

		CS.ShowObject(self.mImgLove,true)
		self:OnUpdateEffectLove()
		seq:AppendCallback(function ()
			self:CreateEffect(self.mImgLove,"fx_ui_shengxing_4")
		end)
		seq:AppendInterval(showTopTime)

		for i,v in ipairs(self._starTransList) do
			seq:AppendCallback(function ()
				self:CreateEffect(v,"fx_ui_shengxing_3","eff"..i)
				CS.ShowObject(v,true)
			end)
			seq:AppendInterval(showAttrTime)
		end
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
	end)
	LxUiHelper.PlayAudioSoundName(LSoundConst.FAIRYTALE_MONSTERSHOW)
end


function UIFavorabilityPrivilegePop:OnUpdatePanel()
	local heroRefId = self:GetWndArg("heroRefId")
	self.isTotalPop = self:GetWndArg("isTotalPop")
	local heroData = gModelHero:GetFavorabilityInfo(heroRefId)
	self:SetWndText(self.mTxtLv,heroData.loveLevel)
	local ref = GameTable.CharacterFavorabilityRef[heroData.loveLevel]
	CS.ShowObject(self.mPrivilegeItem,ref.text1~="")
	CS.ShowObject(self.mPrivilegeItem2,ref.text2~="")
	CS.ShowObject(self.mImgTitle,false)
	-- CS.ShowObject(self.mImgQuality,false)
	CS.ShowObject(self.mImgLove,false)
	self._starTransList = {}
	if ref.text1~="" then
		table.insert(self._starTransList,self.mPrivilegeItem)
		CS.ShowObject(self.mPrivilegeItem,false)
	end
	if ref.text2~="" then
		CS.ShowObject(self.mPrivilegeItem2,false)
		table.insert(self._starTransList,self.mPrivilegeItem2)
	end
	self:SetWndText(self.mTxtDesc,(ccLngText(ref.text1)))
	self:SetWndText(self.mTxtDesc2,(ccLngText(ref.text2)))
	-- local heroEffRef = GameTable.CharacterEffectRef[heroData.heroRefId]
	-- local heroRef = GameTable.CharacterRef[heroData.heroRefId]
	-- self:SetWndText(self.mTxtName,heroEffRef and ccLngText(heroEffRef.name) or "")
	-- self:SetWndEasyImage(self.mImgIcon,heroEffRef and heroEffRef.icon or "")
	-- self:SetWndEasyImage(self.mImgQuality,heroRef and "public_item_bg_"..heroRef.quality or "")

	if ref.spAction ~= "" then
		local data = self.data[ref.spAction]
		local res
		if type(data.icon) == "string" then
			res = data.icon
		else
			res = data.icon()
		end
		self:SetWndEasyImage(self.mIcon, res)
		self:SetWndEasyImage(self.mText, data.text)
	end
	CS.ShowObject(self.mOn, ref.spAction ~= "")
	CS.ShowObject(self.mOff, ref.spAction == "")

	self:CreateWndEffect(self.mBg, "fx_ui_huayuanmutang_tequan", "fx_ui_huayuanmutang_tequan", 1)

	self:PlayEffect()
end
function UIFavorabilityPrivilegePop:OnUpdateEffectLove()
    -- local curTotalLv = gModelHero._loveTotalLevel
    -- local totalRef = GameTable.CharacterFavorabilityAttrRef[curTotalLv + 1]
    -- local nexTotalExp = totalRef and totalRef.exp or GameTable.CharacterFavorabilityAttrRef[curTotalLv].exp

    -- self:CreateWndEffect(self.mEffectLove,"fx_haogandu_yeti","haogandulove_yeti",100,nil,nil,nil,nil,nil,true,nil,nil)
	-- self:CreateWndEffect(self.mImgLove,"fx_haogandu","haogandulove",100,nil,nil,nil,nil,nil,true,nil,function()
    --     if not self._rendererList then
    --         local rendererList = self.mEffectLove:GetComponentsInChildren(typeofRenderer, true)
    --         self._rendererList = rendererList:ToTable()
    --     end-- 初0.25
    --     local temp = (gModelHero._loveTotalValue/nexTotalExp)*0.4
    --     for k,v in ipairs(self._rendererList) do
    --         local material = v.material
    --         if material then
    --             material.mainTextureOffset = Vector2(0,0.26-temp)
    --         end
    --     end
    -- end)
end
function UIFavorabilityPrivilegePop:CreateEffect(trans,effectName,effectKey,effectSize)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans,effectName,effectKey,effectSize,false,false)
end
function UIFavorabilityPrivilegePop:InitLoveLvOrder()
    local canvas = self.mTxtLv:GetComponent(typeofCanvas)
    if not canvas then
        canvas = self.mTxtLv.gameObject:AddComponent(typeofCanvas)
    end
    canvas.overrideSorting = true
    canvas.sortingLayerName = self:GetWndSortLayer()
    canvas.sortingOrder = self:GetWndSortOrder()+2
end
------------------------------------------------------------------
return UIFavorabilityPrivilegePop