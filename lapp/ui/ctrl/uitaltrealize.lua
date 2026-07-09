---
--- Created by Administrator.
--- DateTime: 2023/10/11 10:53:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITaltRealize:LWnd
local UITaltRealize = LxWndClass("UITaltRealize", LWnd)
UITaltRealize.TUIJIAN_TYPE = 1
UITaltRealize.COMMON_TYPE = 2

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaltRealize:UITaltRealize()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaltRealize:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaltRealize:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaltRealize:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitStaticContent()

	self:InitData()
	self:InitEvent()
	self:InitMsg()


	self:TryGetRecommendData()
end

function UITaltRealize:GetTalentDataList()
	local recommendRuneList = {}
	local recommendHotNumList = {}
	local refId = self._refId
	local isHot = false
	if refId then
		local hotMap = self._hotDataMap or {}
		local refTbl = GameTable.MagicRuneSkillRef
		for k,v in pairs(hotMap) do
			local runRef = refTbl[k]
			local skillType = runRef.skillType
			local skillTypeList = gModelRune:GetSkillTypeListBySkillType(skillType)
			local skillRune
			if skillTypeList then
				skillRune = skillTypeList[1]
				skillRune = skillRune and refTbl[skillRune.refId]
			end

			if skillRune and skillRune.quality == 1 then
				isHot = true
				local runeReId = skillRune.refId
				recommendRuneList[runeReId] = runeReId
				recommendHotNumList[runeReId] = v
			end
		end

		if not isHot then
			local ref =  gModelHero:GetHeroRef(refId)
			if ref then
				local recommendRune = ref.recommendRune or ""
				recommendRune = string.split(recommendRune,",")
				for i,v in ipairs(recommendRune) do
					local temp = tonumber(v)
					recommendRuneList[temp] = temp
				end
			end
		end
	end

	local haveTalentList = {}
	for k,v in pairs(self._talentList) do
		local ref = gModelRune:GetSkillInfoByRefId(v)
		local skillType = ref.skillType
		haveTalentList[skillType] = true
	end
	self._haveTalentList = haveTalentList
	local talentList = {}
	for k,v in pairs(GameTable.MagicRuneSkillRef) do
		if v.quality == 1 then
			local runeRefId = v.refId
			local skillType = v.skillType
			local recommend = string.split(v.recommend,",")
			local recommendList = {}
			for index,value in ipairs(recommend) do
				table.insert(recommendList,tonumber(value))
			end
			local upItem = string.split(v.upItem,"=")
			local needRefId,needItem = tonumber(upItem[2]),tonumber(upItem[3])
			local haveNum = gModelItem:GetNumByRefId(needRefId)
			-- 是否可领悟
			local isRealize = -1
			if haveNum >= needItem then
				isRealize = 1
			end
			local isStudy
			if  haveTalentList[skillType] ~= nil then
				isStudy = 1
			else
				isStudy = -1
			end

			local data = {
				ref = v,
				refId = runeRefId,
				recommendList = recommendList,
				isRealize = isRealize,
				isStudy = isStudy,
				hotNum = recommendHotNumList[runeRefId]
			}

			local isTuiJian = recommendRuneList[runeRefId] and true or false
			local talentKey = isTuiJian and UITaltRealize.TUIJIAN_TYPE or UITaltRealize.COMMON_TYPE

			if not talentList[talentKey] then
				talentList[talentKey] = {}
			end
			table.insert(talentList[talentKey],data)
		end
	end

	-- 未学习 》 可领悟 》 英雄推荐
	local cmpFun = function(talent1,talent2)
		local isStudy1,isStudy2 = talent1.isStudy,talent2.isStudy
		if isStudy1 ~= isStudy2 then
			return isStudy1 < isStudy2
		else
			local isRealize1,isRealize2 = talent1.isRealize,talent2.isRealize
			if isRealize1 ~= isRealize2 then
				return isRealize1 > isRealize2
			else
				--[[				local recommendList1,recommendList2 = talent1.recommendList,talent2.recommendList
								local recommend1,recommend2 = recommendList1[self._heroJob],recommendList2[self._heroJob]
								if recommend1 ~= recommend2 then
									return recommend1 > recommend2
								else
									local sort1,sort2 = talent1.ref.sort,talent2.ref.sort
									return sort1 < sort2
								end]]
				local refId1,refId2 = talent1.refId,talent2.refId
				local sel1 = recommendRuneList[refId1] and 1 or 0
				local sel2 = recommendRuneList[refId2] and 1 or 0
				if sel1 == sel2 then
					local sort1,sort2 = talent1.ref.sort,talent2.ref.sort
					return sort1 < sort2
				else
					return sel1 > sel2
				end
			end
		end
	end


	local commoeList = talentList[UITaltRealize.COMMON_TYPE] or {}
	table.sort(commoeList,cmpFun)

	local tuijianlist = talentList[UITaltRealize.TUIJIAN_TYPE] or {}
	if isHot then
		table.sort(tuijianlist,function (talent1,talent2)
			local hotNum1 = talent1.hotNum or 0
			local hotNum2 = talent2.hotNum or 0
			if (hotNum1 ~= hotNum2) then
				return hotNum1 > hotNum2
			end
			local sort1,sort2 = talent1.ref.sort,talent2.ref.sort
			return sort1 < sort2
		end)
	else
		table.sort(tuijianlist,cmpFun)
	end

	return talentList
end

function UITaltRealize:TryGetRecommendData()
	local refId = self._refId
	self._hotDataMap = {}
	if refId then
		local heroRef = gModelHero:GetHeroRef(refId)
		if heroRef and heroRef.quality >= 6 then -- 传说已经神话才需要显示热门数据
			local hotData = gModelGeneral:OnGetHeroRecommendData(1, refId)
			if not hotData then
				gModelGeneral:OnHeroRecommendDataReq(1, refId)
				return
			end
			self._hotDataMap = hotData
		end
	end
	self:InitTalentList()
end

function UITaltRealize:InitDescView(desc)
	local uiList = self._uiDescList
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self, self.mDescList)
		uiList:EnableScroll(true,false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawDescCell(...)
		end)
		self._uiDescList = uiList
	end
	uiList:RemoveAll()
	uiList:AddData(1,desc)
	uiList:RefreshList()
end

function UITaltRealize:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RuneUpTalentSkillResp, function() self:WndClose() end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self._selectRef = nil
		self:InitTalentList() end)
	self:WndNetMsgRecv(LProtoIds.HeroRecommendDataResp, function(pb)
		self:OnHeroRecommendDataResp(pb)
	end)
end

function UITaltRealize:RefreshBaseInfo(func)
	local selRef = self._selectRef

	local skillId = tonumber(selRef.SkillId)
	local baseClass = SkillIcon:New(self)
	baseClass:Create(self.mSkillIcon,skillId)

	local skillRef = gModelHero:GetSkillByStarId(skillId)
	if skillRef then
		local skillName = ccLngText(skillRef.name)
		self:SetWndText(self.mSkillName,skillName)

		local description = ccLngText(selRef.skillDesc)
		--self:SetWndText(self.mSkillDesc,description)
		self:InitDescView(description)
	end

	local upItem = selRef.upItem
	upItem = string.split(upItem,"=")
	local needRefId,needNum = tonumber(upItem[2]),tonumber(upItem[3])
	local haveNum = gModelItem:GetNumByRefId(needRefId)
	local itemName = gModelItem:GetNameByRefId(needRefId)
	self._enough = haveNum >= needNum
	local color = "0fb93f"
	if haveNum < needNum then color = "844141" end
	haveNum = LUtil.NumberCoversion(haveNum)
	local str = string.format("<color=#%s>%s</color><color=#734f22>/%s   %s</color>",color,haveNum,needNum,itemName)
	self:SetWndText(self.mConsumeInfo,str)
	self._upItemRefId = needRefId
	local itemIcon = gModelItem:GetItemIconByRefId(needRefId)
	if itemIcon then self:SetWndEasyImage(self.mConsumeIcon,itemIcon) end

	self:InitAttrList(LUtil.ConvertCommonAttrStrToList(selRef.talentAttr))

	if func then func() end
end

function UITaltRealize:OnDrawAttrCell(list,item,itemdata,itempos)
	local Image_Icon = self:FindWndTrans(item,"Image_Icon")
	local Attr_Name = self:FindWndTrans(item,"Attr_Name")
	local Attr_Old = self:FindWndTrans(item,"Attr_Old")
	local Attr_New = self:FindWndTrans(item,"Attr_New")

	local attrRefId,attrType,attrNum = itemdata.attrRefId,itemdata.attrType,itemdata.attrNum

	local icon = gModelHero:GetAttributeIconById(attrRefId)
	self:SetWndEasyImage(Image_Icon,icon)

	local attrName = gModelHero:GetAttributeNameById(attrRefId)
	self:SetWndText(Attr_Name,attrName)

	self:SetWndText(Attr_Old,0)

	local attrValue = "+" .. gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrNum)
	self:SetWndText(Attr_New,attrValue)
end

function UITaltRealize:InitData()
	self._heroId = self:GetWndArg("heroId")
	self._pos = self:GetWndArg("pos")
	self._heroJob = self:GetWndArg("HeroJob")
	self._talentList = self:GetWndArg("talentList")
	self._refId = self:GetWndArg("refId")
	self._selectRef = nil
	self._gouTransList = {}
	self._upItemRefId = nil
	self._enough = false
	self._baseClassList = {}
	self._uiTalentList = {}
	self._uiListKey = "_uiListKey"
	self._recommendShowFmtStr =  ccClientText(26692) or ""
end

function UITaltRealize:InitTalentList()
	local talentDataList =self:GetTalentDataList()
	self._talentDataList = talentDataList

	if not self._selectRef then
		self._selectRef = talentDataList[1][1].ref
		self:RefreshBaseInfo()
	end

	self._gouTransList = {}
	--local dataList = {ccClientText(13278), ccClientText(13279)}
	local dataList = {ccClientText(26691), ccClientText(13279)}
	local uiList = self._uiList
	if not uiList then
		uiList = self:GetUIScroll("key_uiList")
		self._uiList = uiList
		uiList:Create(self.mRuneList, dataList, function(...)
			self:OnDrawRuneCell(...)
		end, UIItemList.NORMAL,false)
		local list = uiList:GetList()
		list:EnableScroll(true,false)
		list:RefreshList()
	else
		uiList:RefreshList(dataList)
	end

	LayoutRebuilder.ForceRebuildLayoutImmediate(self.mRuneList)
end

function UITaltRealize:InitAttrList(list)
	local uiList = self:FindUIScroll("attrList")
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("attrList")
		uiList:Create(self.mAttrList,list,function (...) self:OnDrawAttrCell(...) end)
	end
end


function UITaltRealize:InitStaticContent()
	self:SetWndText(self.mTitle,ccClientText(13232))
	--self:SetWndText(self.mConsumeTxt,ccClientText(11320))
	self:SetWndText(self.mShopBtnTxt,ccClientText(13239))
	self:SetWndText(self.mSkillBtnTxt,ccClientText(13278))
	self:SetWndButtonText(self.mRealizeBtn,ccClientText(13234))
end


function UITaltRealize:OnHeroRecommendDataResp(pb)
	if self._refId ~= pb.heroRefId  then return end
	if pb.type ~= 1 then return end
	self._hotDataMap = gModelGeneral:OnGetHeroRecommendData(1, self._refId)
	self:InitTalentList()
end

function UITaltRealize:OnDrawRuneCell(list, item, itemdata, itempos)
	local titleText = self:FindWndTrans(item, "Title/TitleText")
	local listTrans	= self:FindWndTrans(item, "List")

	self:SetWndText(titleText, itemdata)
	local talentList = self._talentDataList[itempos]
	local uiListKey = self._uiListKey..itempos
	local uiList 	= self._uiTalentList[uiListKey]
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self, listTrans)
		uiList:EnableScroll(false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawRuneListCell(...)
		end)
		uiList:EnableLoadAnimation(true, 0, 2)
		self._uiTalentList[uiListKey] = uiList
	end

	uiList:RemoveAll()

	for i,v in ipairs(talentList) do
		uiList:AddData(i,v)
	end

	uiList:RefreshList()
end

function UITaltRealize:SelectEvent(data,gouTrans)
	local oldData = self._selectRef
	local oldRefId = oldData.refId
	local newRefId = data.refId

	if oldRefId == newRefId then return end

	local oldGouTrans = self._gouTransList[oldRefId]
	local oldBaseClass = self._baseClassList[oldRefId]
	if oldGouTrans then CS.ShowObject(oldGouTrans,false) end
	if oldBaseClass then oldBaseClass:SetIconAndIconBgGray(false) end

	self._selectRef = data
	local newGouTrans = self._gouTransList[newRefId]
	local newBaseClass = self._baseClassList[newRefId]
	if newGouTrans then CS.ShowObject(newGouTrans,true) end
	if newBaseClass then newBaseClass:SetIconAndIconBgGray(true) end

	self:RefreshBaseInfo()
end

function UITaltRealize:OnDrawRuneListCell(list, item, itemdata, itempos, fromHeadTail)
	local SkillTrans = CS.FindTrans(item,"Skill")
	local hotNodeTrans = self:FindWndTrans(item,"hotNode")
	local hotNumTrans = self:FindWndTrans(hotNodeTrans,"HotNum")

	if itemdata.hotNum then
		CS.ShowObject(hotNodeTrans, true)
		self:SetWndText(hotNumTrans, string.replace(self._recommendShowFmtStr, tostring(itemdata.hotNum)))
	else
		CS.ShowObject(hotNodeTrans, false)
	end

	local skillData = itemdata.ref
	local skill = tonumber(skillData.SkillId)
	local refId = skillData.refId
	local selRefId = self._selectRef.refId
	local skillType = skillData.skillType
	local showGou = refId == selRefId

	local skillIconTrans = CS.FindTrans(SkillTrans,"SkillIcon")
	if not skillIconTrans then return end

	local baseClass = SkillIcon:New(self)
	baseClass:Create(skillIconTrans,skill)

	self._baseClassList[refId] = baseClass
	baseClass:SetIconAndIconBgGray(showGou)

	local SkillNameTrans = CS.FindTrans(item,"SkillName")
	if SkillNameTrans then
		local skillRef = gModelHero:GetSkillByStarId(skill)
		if skillRef then
			local skillName = ccLngText(skillRef.name)
			self:SetWndText(SkillNameTrans,skillName)
			self:InitTextShowWithLanguage(SkillNameTrans)
		end
	end

	local UseImgTrans = CS.FindTrans(item,"UseImg")
	if UseImgTrans then
		local show = false
		local img = ""
		local isStudy = itemdata.isStudy
		if isStudy == 1 then
			show = true
			img = "rune_txt_5"
		else
			local isRealize = itemdata.isRealize
			if isRealize == 1 then
				show = true
				img = "rune_txt_3"
			elseif self._haveTalentList[skillType] then
				show = true
				img = "rune_txt_5"
			else
				--[[						local recommendList = itemdata.recommendList
                                        if recommendList[self._heroJob] ~= 0 then
                                            show = true
                                            img = "rune_txt_4"
                                        end]]
				--if itemdata.isTuiJian then
				--	show = true
				--	img = "rune_txt_4"
				--end
			end
		end
		CS.ShowObject(UseImgTrans,show)
		if show then self:SetWndEasyImage(UseImgTrans,img) end
	end

	local GouTrans = CS.FindTrans(item,"Gou")
	if GouTrans then
		CS.ShowObject(GouTrans,showGou)

		self._gouTransList[refId] = GouTrans
		self:SetWndClick(skillIconTrans,function()
			self:SelectEvent(skillData,GouTrans)
		end)
	end
end

function UITaltRealize:OnDrawDescCell(list, item, itemdata, itempos, fromHeadTail)
	local SkillDescTrans = CS.FindTrans(item,"SkillDesc")
	if SkillDescTrans then
		self:SetWndText(SkillDescTrans,itemdata)
	end
end

function UITaltRealize:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mRealizeBtn,function()
		if self._enough then
			local refId = self._selectRef.refId
			-- 领悟
			gModelRune:OnRuneUpTalentSkillReq(self._heroId,refId,self._pos)
		else
			gModelGeneral:OpenGetWayWnd({itemId = self._upItemRefId})
		end
	end)
	self:SetWndClick(self.mShopBtn,function()
		local functionId = gModelRune:GetConfig("talentShopJump")
		gModelFunctionOpen:Jump(functionId)
	end)
	self:SetWndClick(self.mSkillBtn,function()
		GF.OpenWnd("UIReJNRecommend", {refId = self._refId})
	end)
end
------------------------------------------------------------------
return UITaltRealize


