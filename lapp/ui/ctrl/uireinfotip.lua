---
--- Created by Administrator.
--- DateTime: 2023/10/6 17:55:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReInfoTip:LWnd
local UIReInfoTip = LxWndClass("UIReInfoTip", LWnd)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReInfoTip:UIReInfoTip()
	---@type CommonIcon
	self._runeIconCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReInfoTip:OnWndClose()
	if self._runeIconCls then
		self._runeIconCls:Destroy()
		self._runeIconCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReInfoTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReInfoTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitText()
	self:InitData()
	self:RefreshShow()
	self:InitEvent()
	self:InitMsg()
	self:RefrshView()
	self:RefreshForeign()
end

function UIReInfoTip:RefreshForeign()
	if self._isVie then
		self:SetAnchorPos(self.mOptBtnDiv,Vector2.New(-32,-85))
	end
end

function UIReInfoTip:RuneShare()
	--if self._shareFunc then
	--	self:OnClickChatShare()
	--else
	--	self:OnClickShare()
	--end
	if not self._runeData or not self._runeData.id then
		return
	end
	local data = {
		root = self.mShareBtn,
		shareType = ModelChat.CHATSHARE_RUNE,
		shareData = self._runeData.id,
	}
	gModelGeneral:OpenShareTip(data)
end

function UIReInfoTip:OnDrawAttrCell(list, item, itemdata, itempos, fromHeadTail)
	local runeAttrRef = gModelRune:GetAttrInfoByRefId(itemdata)
	if runeAttrRef then
		local attr = runeAttrRef.attr
		local first = attr[1]
		self:CreateAttrTransInfo(item,first)

--[[
		local attrRefId,attrType,attrValue = first.attrRefId,first.attrType,first.attrVal
		local AttrIconTrans = CS.FindTrans(item,"AttrIcon")
		if AttrIconTrans then
			local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
			self:SetWndEasyImage(AttrIconTrans,attrIcon)
		end

		local AttrNameTrans = CS.FindTrans(item,"AttrName")
		if AttrNameTrans then
			local attrName = gModelHero:GetAttributeNameById(attrRefId)
			local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrValue)
			local str = string.replace(ccClientText(13271),attrName,value)
			self:SetWndText(AttrNameTrans,str)
		end

		local AttrValueTrans = CS.FindTrans(item,"AttrValue")
		if AttrValueTrans then
			--local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrValue)
			local value = ""
			self:SetWndText(AttrValueTrans,value)
		end]]
	end
end
function UIReInfoTip:InitText()
	self:SetWndText(self.mTitleTxt,ccClientText(11307))
	self:SetWndText(self.mSkillTitleTxt,ccClientText(13258))
	self:SetWndButtonText(self.mRecastBtn,ccClientText(13208),nil,nil, -30)
	--self:SetWndButtonText(self.mQuenchingBtn,ccClientText(24917), nil,nil, -30)
	self:SetWndText(self.mQuenchingBtnName,ccClientText(24917))
	self:SetWndText(self.mCompoundBtnName,ccClientText(11316))
	self:SetWndText(self.mShareBtnName,ccClientText(13273))
	self:SetWndText(self.mCLTitleTxt,ccClientText(24818))



	--self:SetWndText(self.mSkillPreViewBtnName,ccClientText(13205))
end

function UIReInfoTip:InitSkillList(skillList)
	local uiSkillList = self._uiSkillList
	if not uiSkillList then
		uiSkillList = UIListEasy:New()
		uiSkillList:Create(self,self.mSkillList)
		uiSkillList:SetFuncOnItemDraw(function(...)
			self:OnDrawSkillCell(...)
		end)
		self._uiSkillList = uiSkillList
	end
	uiSkillList:RemoveAll()
	for i,v in ipairs(skillList) do
		uiSkillList:AddData(i,v)
	end
	uiSkillList:RefreshList()
end

function UIReInfoTip:GetCLAttrList()
	local list = {}
	local runeData = self._runeData
	if runeData then
		list = gModelRune:GetLevelAndClassAttrList(runeData,true)
	end
	return list
end

function UIReInfoTip:OnDrawCLAttrCell(list, item, itemdata, itempos, fromHeadTail)
	self:CreateAttrTransInfo(item,itemdata)
end

function UIReInfoTip:InitData()
	self._openWay = self:GetWndArg("openWay") 					-- nil:预览  1:分解/穿戴  2:卸下/替换
	self._runeData = self:GetWndArg("runeData")
	self._runeId = self:GetWndArg("runeId")
	self._leftFunc = self:GetWndArg("leftFunc")
	self._rightFunc = self:GetWndArg("rightFunc")
	self._share = self:GetWndArg("share")
	self._shareFunc = self:GetWndArg("shareFunc")

	local isTry   = self._runeData.isTry
	self._isTry   = isTry

	self._btnList = {self.mBtn1,self.mBtn2}
	self._btnNameList = {self.mBtn1Name,self.mBtn2Name}
	self._btnCodeList = {}
	local showShare = (self._share or self._openWay ~= nil) and not isTry
	CS.ShowObject(self.mShareBtn,showShare)
end

function UIReInfoTip:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end)
	self:SetWndClick(self.mRecastBtn,function()
		self:OpenRuneRecastWnd()
	end)
	self:SetWndClick(self.mCompoundBtn,function()
		--local newInfo = gModelGeneral:IsNewHeroWnd()
		local wndHeroInfo = "UINewSagaInfo" --newInfo.wndHeroInfo
		-- 合成
		--local wndInst= GF.FindFirstWndByName(wndHeroInfo)
		--if wndInst then
			GF.CloseWndByName(wndHeroInfo)
		--end
		self:WndClose()

        FireEvent(EventNames.CHANGE_MAIN_BTN,LMainBtnIndexConst.CITY)
        --GF.OpenWndBottom("UIEqCompound",{page = 2})
		GF.OpenWnd("UIMid", {page = 1})
	end)
	self:SetWndClick(self.mSkillPreViewBtn,function()
		-- 技能预览
		GF.OpenWndTop("UIReJNPreView")
	end)
	self:SetWndClick(self.mBtn1,function()
		if self._openWay == 1 then
			local data = {}
			data.runeId = self._runeData.id
			data.itemList = {}
			data.itemList = self._itemList
			gModelGeneral:RunOriginConfigCode(self._btnCodeList[1],data)
			self:WndClose()
		else
			-- 卸下
			if self._leftFunc then self._leftFunc() end
		end
	end)
	self:SetWndClick(self.mBtn2,function()
        if self._openWay == 1 then
            -- 穿戴
			gModelFunctionOpen:Jump(10300000)
			--gModelGeneral:RunOriginConfigCode(self._btnCodeList[2])
            self:WndClose()
        else
            -- 替换
            if self._rightFunc then self._rightFunc() end
        end
	end)
	self:SetWndClick(self.mShareBtn,function()
		self:RuneShare()
	end)
	self:SetWndClick(self.mShareMask,function()
		CS.ShowObject(self.mShareMask,false)
	end)
	self:SetWndClick(self.mQuenchingBtn,function()
		self:OpenRuneRecastWnd(ModelRune.TYPE_QUENCHING)
	end)
end

function UIReInfoTip:RefrshView()
	local runeData = self._runeData
	local show = table.isempty(runeData)
	CS.ShowObject(self.mDescBg,not show)
	if table.isempty(runeData) then
		local refId = self._runeId
		local runeRef = gModelRune:GetRuneInfoByRefId(refId)
		if runeRef then
			self:SetRunIcon(self.mRuneIcon, {refId = refId})

			local attrText = ccLngText(runeRef.attrText)
			local skillText = ccLngText(runeRef.skillText)
			self:SetWndText(self.mRandAttrTxt,attrText)
			self:SetWndText(self.mRandSkillTitle,skillText)

			local name = ccLngText(runeRef.name)
			self:SetWndText(self.mNameTxt,name)
			local quality = runeRef.quality
			local heroMessage = gModelItem:GetHeroMessQualityById(quality)
			if heroMessage then self:SetWndEasyImage(self.mHeadImg,heroMessage) end
			local color = gModelItem:GetColorByQualityId(quality)
			self:SetXUITextTransColor(self.mNameTxt,color)
		end
		self:SetWndText(self.mRandTitleTxt,ccClientText(10068))
		self:SetWndText(self.mRandSkilTitleTxt,ccClientText(13258))
	else
		local refId = runeData.refId
		local data = {
			trans = self.mRuneIcon,
			refId = refId,
			skillId = runeData.skillId,
			attrId = runeData.attrId,
		}
		self:SetRunIcon(self.mRuneIcon, runeData)

		local attrId = runeData.attrId
		local skillId = runeData.skillId
		local runeRef = gModelRune:GetRuneInfoByRefId(refId)
		if runeRef then
			if self._openWay == 1 then
				local btn = runeRef.btn
				btn = string.split(btn,",")
				for i,v in ipairs(btn) do
					local originRef = gModelGeneral:GetOriginConfigRef(v)
					if originRef then
						local btnIcon = originRef.btnIcon
						self:SetWndEasyImage(self._btnList[i],btnIcon)

						local name = ccLngText(originRef.name)
						self:SetWndText(self._btnNameList[i],name)

						self._btnCodeList[i] = originRef.code
					end
				end
			end

--[[			self._itemList = {}
			local decompose = runeRef.decompose
			decompose = string.split(decompose,",")
			for i,v in ipairs(decompose) do
				v = string.split(v,"=")
				table.insert(self._itemList,{itype = tonumber(v[1]),refId = tonumber(v[2]),count = tonumber(v[3])})
			end]]

			self._itemList = gModelRune:GetRuneDecomposeItemListByRuneData(runeData)

			--local name = ccLngText(runeRef.name)
			local name = gModelRune:GetRuneNameByServerData(runeData)
			self:SetWndText(self.mNameTxt,name)

			local quality = runeRef.quality
			local heroMessage = gModelItem:GetHeroMessQualityById(quality)
			if heroMessage then self:SetWndEasyImage(self.mHeadImg,heroMessage) end

			local color = gModelItem:GetColorByQualityId(quality)
			self:SetXUITextTransColor(self.mNameTxt,color)

			local score = runeData.score
			if not score then
				score = gModelRune:GetRuneScore(attrId,skillId)
			end
            score = math.floor(score + 0.5)
			local str = string.replace(ccClientText(11306),score)
			self:SetXUITextTransColor(self.mScoreTxt,color)
			self:SetWndText(self.mScoreTxt,str)
		end
		self:InitAttrList(attrId)
		if table.isempty(skillId) then
			CS.ShowObject(self.mSkillTitleDiv,false)
			CS.ShowObject(self.mSkillDiv,false)
			CS.ShowObject(self.mLayRootSkill,true)
		else
			CS.ShowObject(self.mSkillTitleDiv,true)
			CS.ShowObject(self.mSkillDiv,true)
			self:InitSkillList(skillId)
		end
	end
	CS.ShowObject(self.mRandDescBg,show)
end

function UIReInfoTip:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RuneUnloadResp, function() self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.RuneWearResp, function() self:WndClose() end)
end

function UIReInfoTip:CreateAttrTransInfo(item,itemdata)
	local attrRefId,attrType,attrValue = itemdata.attrRefId,itemdata.attrType,itemdata.attrVal
	local AttrIconTrans = CS.FindTrans(item,"AttrIcon")
	if AttrIconTrans then
		local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
		self:SetWndEasyImage(AttrIconTrans,attrIcon)
	end

	local AttrNameTrans = CS.FindTrans(item,"AttrName")
	if AttrNameTrans then
		local attrName = gModelHero:GetAttributeNameById(attrRefId)
		local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrValue)
		local str = string.replace(ccClientText(13271),attrName,value)
		self:SetWndText(AttrNameTrans,str)
	end

	local AttrValueTrans = CS.FindTrans(item,"AttrValue")
	if AttrValueTrans then
		--local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrValue)
		local value = ""
		self:SetWndText(AttrValueTrans,value)
	end
end

function UIReInfoTip:OpenSkillTips(skillData)
	if not skillData then return end
	local skillType = skillData.skillType
	local refId = skillData.refId
	gModelRune:OpenNewRuneSkillWnd(refId,skillType)
end

function UIReInfoTip:OpenRuneRecastWnd(page)
	-- 重铸
	--GF.OpenWnd("UIReRecast",{runeId = self._runeData.id})
	local runeData = self._runeData
	if not runeData then return end
	local id = runeData.id
	local serverData = gModelRune:GetServerDataById(id)
	if not serverData then return end
	local heroId = runeData.heroId
	GF.OpenWnd("UIReRecastNew",{runeData = serverData,page = page, heroId = heroId})
	self:WndClose()
end

function UIReInfoTip:SetRunIcon(runeIconTrans, runeData)
	local runeIconCls = self._runeIconCls
	if not runeIconCls then
		runeIconCls = CommonIcon:New()
		self._runeIconCls = runeIconCls
		runeIconCls:Create(runeIconTrans)
	end
	runeIconCls:SetRuneData(runeData)

	runeIconCls:DoApply()
	runeIconCls:EnableShowBg(false)
end

function UIReInfoTip:InitCLAttrList()
	local list = self:GetCLAttrList()
	local uiCLAttrList = self._uiCLAttrList
	if uiCLAttrList then
		uiCLAttrList:RefreshList(list)
	else
		uiCLAttrList = self:GetUIScroll("uiCLAttrList")
		self._uiCLAttrList = uiCLAttrList
		uiCLAttrList:Create(self.mCLAttrList,list,function(...) self:OnDrawCLAttrCell(...) end)
	end
end

function UIReInfoTip:OnDrawSkillCell(list, item, itemdata, itempos, fromHeadTail)
	local skillData = gModelRune:GetSkillInfoByRefId(itemdata)
	if skillData then
		local skill = tonumber(skillData.SkillId)
		local skillTrans = CS.FindTrans(item,"Skill")
		if skillTrans then
			local SkillIconTrans = CS.FindTrans(skillTrans,"SkillIcon")
			if SkillIconTrans then
				local baseClass = SkillIcon:New(self)
				baseClass:Create(SkillIconTrans,skill,function()
--[[					local lv = skillData.skillLevel
					local other = {
						lv = lv
					}
					GF.OpenWndTop("UIJNInfo",{skillId = skill,other = other})]]

					self:OpenSkillTips(skillData)
				end)
			end
		end
		local skillRef = gModelHero:GetSkillByStarId(skill)
		if skillRef then
			local SkillNameTrans = CS.FindTrans(item,"SkillName")
			if SkillNameTrans then
				local skillName = ccLngText(skillRef.name)
				self:SetWndText(SkillNameTrans,skillName)



				local quality = skillData.quality
				local qualityRef =  GameTable.RarityRef[quality + 2]
				self:SetXUITextTransColor(SkillNameTrans,qualityRef.nameColor)

			end
			local SkillDescTrans = CS.FindTrans(item,"SkillDesc")
			if SkillDescTrans then
				local desc = ccLngText(skillRef.description)
				self:SetWndText(SkillDescTrans,desc)
			end
		end
		self:SetWndClick(item,function()
			self:OpenSkillTips(skillData)
		end)
	end
end

function UIReInfoTip:InitAttrList(attrList)
	local uiAttrList = self._uiAttrList
	if not uiAttrList then
		uiAttrList = UIListEasy:New()
		uiAttrList:Create(self,self.mAttrList)
		uiAttrList:SetFuncOnItemDraw(function(...)
			self:OnDrawAttrCell(...)
		end)
		self._uiAttrList = uiAttrList
	end
	uiAttrList:RemoveAll()
	for i,v in ipairs(attrList) do
		uiAttrList:AddData(i,v)
	end
	uiAttrList:RefreshList()
end

function UIReInfoTip:RefreshShow()
	local show = self._openWay ~= nil
	local isTry = self._isTry
	CS.ShowObject(self.mBtnDiv,show and not isTry)

	CS.ShowObject(self.mCompoundBtn,show and not isTry)
	CS.ShowObject(self.mSkillPreViewBtn,show)
	CS.ShowObject(self.mTipBg2,show)
	CS.ShowObject(self.mTipBg3,not show)
	CS.ShowObject(self.mLayRootSkill,not show)

	if self._openWay then
		local leftStr,rightStr
		if self._openWay == 2 then
			leftStr,rightStr = ccClientText(11302),ccClientText(11310)
			self:SetWndText(self.mBtn1Name,leftStr)
			self:SetWndText(self.mBtn2Name,rightStr)
			local leftImg,rightImg = "public_btn_1_3","public_btn_1_2"
			--[[			self:SetWndEasyImage(self.mBtn1,leftImg)
                        self:SetWndEasyImage(self.mBtn2,rightImg)]]
			-- self:SetBtnImageAndMat(self.mBtn1,leftImg,self.mBtn1Name)
			-- self:SetBtnImageAndMat(self.mBtn2,rightImg,self.mBtn2Name)
		end
	end
	local showCLDiv = false
	CS.ShowObject(self.mCLTitleDiv,showCLDiv)
	CS.ShowObject(self.mCLAttrDiv,showCLDiv)
--[[	local runeData = self._runeData
	if runeData then
		showCLDiv = gModelRune:IsCanQuenchingByRefId(runeData.refId)
	end
	CS.ShowObject(self.mCLTitleDiv,showCLDiv)
	CS.ShowObject(self.mCLAttrDiv,showCLDiv)
	if showCLDiv then
		self:InitCLAttrList()
	end]]
	local ref  = gModelRune:GetRuneInfoByRefId(self._runeData.refId)
	CS.ShowObject(self.mQuenchingBtn,show and not isTry and ref.quenching ~= 0)
	CS.ShowObject(self.mRecastBtn,show and not isTry and ref.mechanism ~= "0,0,0")
end

--function UIReInfoTip:OnClickChatShare()
--	if self._shareFunc then
--		self._shareFunc()
--	end
--	self:WndClose()
--end

--function UIReInfoTip:OnClickShare()
	--CS.ShowObject(self.mShareMask,true)
	--local canvasRect =LGameUI.GetUICanvasRoot()
	--local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,self.mShareBtn)
	--self.mShareImage.localPosition = targetPos - Vector3.New(20,20,0)
	--local list = gModelChat:GetShareConfigChannlByRefId(8)
	--local uiList = self._uiShareList
	--if uiList then
	--	uiList:RefreshList(list)
	--else
	--	uiList = self:GetUIScroll("ShareList")
	--	self._uiShareList = uiList
	--	uiList:Create(self.mShareScroll,list,function (...) self:ListChannelCell(...) end)
	--end
--end
--
--function UIReInfoTip:ListChannelCell(list,item, itemdata, itempos)
--	local btn = CS.FindTrans(item,"ChannelBtn")
--	local btnText = CS.FindTrans(btn,"XUIText")
--	self:SetWndText(btnText,itemdata.name)
--	if itemdata.channelId == 4 then
--		local guildBool = gModelGuild:GetBHaveGuild()
--		if not guildBool then
--			self:SetWndImageGray(btn,not guildBool)
--			self:SetWndClick(btn, function(...)
--				GF.ShowMessage(ccClientText(11526))
--			end)
--			return
--		end
--	end
--	self:SetWndClick(btn, function(...)
--		self:OnClickShareRune(itemdata.channelId)
--	end)
--end
--
--function UIReInfoTip:OnClickShareRune(channelId)
--	gModelChat:OnChatShareReq(channelId,ModelChat.CHATSHARE_RUNE,self._runeData.id)
--	CS.ShowObject(self.mShareMask,false)
--	self:WndClose()
--end
------------------------------------------------------------------
return UIReInfoTip