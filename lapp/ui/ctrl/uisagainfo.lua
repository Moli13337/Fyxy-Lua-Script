---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaInfo:LWnd
local UISagaInfo = LxWndClass("UISagaInfo", LWnd)

------------------------------------------------------------------
local Time = Time
local typeof = typeof
local typeSpineClick = typeof(CS.SpineClick)

local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISkillCtrl = LxRequire("LApp.UI.Display.LUISkillCtrl")

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaInfo:UISagaInfo()
	---@type table<string,LUIHeroObject>
	self._uiHeroObjList = nil
	self._uiCacheHeroCnt = 0
	---@type LUIHeroObject
	self._curUIHeroObj = nil
	---@type LUISkillCtrl
	self._uiSkillCtrl = nil

	---@type table<number, CommonIcon>
	self._commonUIList = {}

	---@type table<number,CommonIcon>
	self._equipUIIconList = {}

	---@type table<number,CommonIcon>
	self._runeUIIconList = {}

	self._loopHeroObjTimerKey = 1119

	self:SetHideBottom()
	self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaInfo:OnWndClose()
	if self._uiSkillCtrl then
		self._uiSkillCtrl:Destroy()
		self._uiSkillCtrl = nil
	end


	self:ClearCommonIconList(self._commonUIList)

	--这个是从列表器拿出来的，列表进行删除就好了
	self._curUIHeroObj = nil

	LUtil.ClearHashTable(self._uiHeroObjList)
	self._uiHeroObjList = nil

	self:ClearCommonIconList(self._equipUIIconList)
	self:ClearCommonIconList(self._runeUIIconList)

	if self._callFunc then self._callFunc() end
	gModelHero:ClearUpStarSelHeroList()

	if self._isUp then gModelResonance:OnResonanceInfoReq() end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaInfo:OnCreate()
	LWnd.OnCreate(self)

	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaInfo:OnAwake()
	LWnd.OnAwake(self)
	
	self:InitUI()

	self:InitData()
	self:SetWndTabText(self._upOptBtnList[1],ccClientText(10075))
	self:SetWndTabText(self._upOptBtnList[2],ccClientText(10076))
	self:SetWndTabText(self._upOptBtnList[3],ccClientText(10077))
	self:SetWndText(self.mKeZhiGuanXiTxt,ccClientText(10080))

	self:InitEvent()
	self:InitMsg()
	local isShow = false
	if self._curOptIndex == 1 then isShow = true end
	CS.ShowObject(self.mLvContent,isShow)
	CS.ShowObject(self.mStarContent,not isShow)
	self:SetWndText(self.mSkillShopBtnTxt,ccClientText(13239))
	--CS.ShowObject(self.mShareMask,true)
	self:SetWndText(self.mShareBtnTxt,ccClientText(12116))
	--CS.ShowObject(self.mShareMask,false)
	self:SetWndText(self.mTalentDdesc,ccClientText(10072))
	self:RefreshTop()
	self:CreateCurBtnEff()
end
function UISagaInfo:OnStart()
	LWnd.OnStart(self)
	
	self:RefreshContent()
end

-- 天赋
function UISagaInfo:GiftBtnEvent()
    CS.ShowObject(self.mUpBtnredPoint,false)
	CS.ShowObject(self.mResonanceTxt,false)
	CS.ShowObject(self.mOperateBtn,true)

	self:SetWndButtonGray(self.mOptTxt, false)

	self._optType = 8
	self:SetWndButtonText(self.mOptTxt,ccClientText(13225))
	--self:SetXUITextText(self.mOptTxt,ccClientText(13225))

	CS.ShowObject(self.mDressBtn,false)
	CS.ShowObject(self.mSkillShopBtn,true)
end

function UISagaInfo:GetUpStarStar(selNum,needNum)
	local color = "30e055"
	if selNum < needNum then color = "c81212" end
	local str = string.replace(ccClientText(10065),color,selNum,needNum)
	return str
end

function UISagaInfo:GetOptStatus(star,maxStar,lv,maxLevel,needLv,needStar)
	local optType = 0
	if star == maxStar then
		if lv == maxLevel then 								-- 满星满等级
			optType = 1
		else 												-- 满星不满等级,升级/升阶
			if needLv == lv and needStar <= star then 		-- 升阶
				optType = 4
			elseif needLv == lv and needStar > star then 	-- 升星界面
				optType = 3
			else 											-- 升级
				optType = 5
			end
		end
	else
		if lv == maxLevel then 								-- 等级达到最高则切换到升星界面
			optType = 3
		else 												-- 是否可以进阶
			if needLv == lv then 							-- 是否处于升阶状态
				optType = 4
			elseif needLv == lv and needStar > star then 	-- 升星界面
				optType = 3
			else 											-- 升级
				optType = 5
			end
		end
	end
	return optType
end

function UISagaInfo:RefreshSkinRedPoint(id)
	local state = gModelHero:CheckHeroSkinIsUpImpl(id)
	CS.ShowObject(self.mSkinBtnRedPoint,state)
end

function UISagaInfo:GetQualityHeroColor(needStar)
	local maxQuality = 0
	for nStar,nQuality in pairs(self._qualityList) do
		if needStar >= nStar and maxQuality <= nQuality then
			maxQuality = nQuality
		end
	end
	if maxQuality ~= 0 then return gModelItem:GetColorStringByQualityId(maxQuality) end
end

function UISagaInfo:OnDragHeroSpineEnd(heroObj, beginPos, endPos)
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

--function UISagaInfo:ListChannelCell(list,item, itemdata, itempos)
--	local btn= CS.FindTrans(item,"ChannelBtn")
--	local btnText= CS.FindTrans(btn,"XUIText")
--	self:SetWndText(btnText,itemdata.name)
--    if(itemdata.channelId==4 )then
--        local guildBool=gModelGuild:GetBHaveGuild()
--        if(not guildBool)then
--            self:SetWndImageGray(btn,not guildBool)
--            self:SetWndClick(btn, function(...)
--                GF.ShowMessage(ccClientText(11526))
--            end)
--            return
--        end
--    end
--	self:SetWndClick(btn, function(...) self:OnClickShareHero(itemdata.channelId) end)
--end

function UISagaInfo:InitData()
	self._refId = self:GetWndArg("refId")
	self._id = self:GetWndArg("id")
	self._heroIndex = self:GetWndArg("index")
	self._callFunc = self:GetWndArg("func")
	self._noShowSkinBtn = false 																				-- 屏蔽皮肤按钮
	self._payItemList = {}
	self._curOptIndex = 1 																					-- 当前操作按钮
	self._heroData = {} 																					-- 英雄数据
	self._optType = 0 																						-- 操作
	self._appointList = {} 																					-- 指定英雄消耗
	self._rangList = {} 																					-- 范围消耗
	self._rangItemList = {}																					-- 英魂道具
	self._isClick = false 																					-- 防止点击过快
	self._isUp = false 																						-- 是否升级
	self._isCutHero = false
	self._heroAttrDef = {1,3,4,5 } 																			-- 英雄基础属性自定义
	self._spineKey = nil																					-- 英雄预制体(refId)
	self._btnKey = "runEff"
	self._runeRefIdList = {1001,1002}
	self._talentRefIdList = {2001,2002}
	self._equipList = {self.mEquip1,self.mEquip2,self.mEquip3,self.mEquip4,self.mEquip5,self.mEquip6} 		-- 装备列表
	self._aniEquipLeftList = {self.mEquip1,self.mEquip3,self.mEquip5,} 										-- 左装备列表
	self._aniEquipRightList = {self.mEquip2,self.mEquip4,self.mEquip6,}										-- 右装备列表
	self._openEquipNum = 4
	self._equipTransList = {}
	self._runeTransList = {}
	self._talentTransList = {self.mSkillIconTalent1,self.mSkillIconTalent2}
	self._talentRedPointList = {self.mTalentRedPoint1,self.mTalentRedPoint2}
	self._lockHero = false																					-- 英雄是否锁定
	self._raceId = nil 																						-- 记录之前英雄的种族图标
	self._isChangeSkin = false 																				-- 是否切换皮肤
	for i = 1,self._openEquipNum do
		local trans = self._equipList[i]
		if trans then
			local equipTrans = CS.FindTrans(trans,"Icon")
			if equipTrans then self._equipTransList[i] = equipTrans end
		end
	end
	for i = 1,2 do
		local trans = self._equipList[self._openEquipNum + i]
		if trans then
			local runeTrans = CS.FindTrans(trans,"RuneIcon")
			if runeTrans then self._runeTransList[i] = runeTrans end
		end
	end
	self._curEquipList = {} 																		-- 当前穿戴的装备列表
	self._curOutfitList = {} 																		-- 当前穿戴的新装备列表
	self._showRedPoint = false 																		-- 穿戴or卸下
	self._heightEquipList = {} 																		-- 可穿戴的装备
	self._upOptBtnList = {self.mUpLvBtn,self.mUpStarBtn,self.mGiftBtn} 								-- 操作按钮
	self._lastUpOptBtn = self._upOptBtnList[1]														-- 默认最后一次点击按钮是第一个
	self._commonTransList = {self.mCommonUI1,self.mCommonUI2,self.mCommonUI3,self.mCommonUI4}						-- 升级材料 or 升星材料
	self._commonNameList = {self.mCommonName1,self.mCommonName2,self.mCommonName3,self.mCommonName4}
	self._commonNumList = {self.mCommonNum1,self.mCommonNum2,self.mCommonNum3,self.mCommonNum4}
	self._commonRedPointTransList = {self.mCommonRedPoint1,self.mCommonRedPoint2,self.mCommonRedPoint3,self.mCommonRedPoint4}
	self._redEquipTransList = {self.mRedEquipImg1,self.mRedEquipImg2,self.mRedEquipImg3,self.mRedEquipImg4}
	self._redRuneTransList = {self.mRedEquipImg5,self.mRedEquipImg6}
	self._dressBtnImgList = {"public_btn_2_1","public_btn_2_2"}
	self._skillTransList = {} 																		-- 技能Trans
	self._openStory = false 																		-- 是否打开故事
	self._isOpenDay = not gModelFunctionOpen:CheckServerOpen(GameTable.CharacterConfigRef["heroLevelRebornFree"]) -- gLGameLogin:IsNew(GameTable.CharacterConfigRef["heroLevelRebornFree"])
	for i = 1,4 do
		local skillTrans = CS.FindTrans(self.mSkillList,"Skill"..i)
		if skillTrans then self._skillTransList[i] = skillTrans end
	end
	self._skillIconList = {} 																		-- 存放SkillIcon
	self._starTransList = {}
	for i = 1,5 do
		local starTrans = CS.FindTrans(self.mStarRoot,"Star"..i)
		if starTrans then	self._starTransList[i] = starTrans	end
	end
	self._qualityList = gModelHero:GetQulityList()
	self._heroUpStarLimit = {}
	local heroUpStarLimit = GameTable.CharacterConfigRef["heroUpStarLimit"]
	heroUpStarLimit = string.split(heroUpStarLimit,",")
	for i,v in ipairs(heroUpStarLimit) do
		v = string.split(v,"=")
		local star,lv = tonumber(v[1]),tonumber(v[2])
		self._heroUpStarLimit[star] = lv
	end
	-- 文字更新
	local txt = {self.mPVWTxt,self.mSkinTxt,self.mLockTxt,self.mStoryTxt,self.mCommentTxt}
	local index = 10105
	for i = 1,#txt do
		index = index + 1
		self:SetXUITextText(txt[i],ccClientText(index))
	end
	self:UpBtnStatus()
	-- 检查是否是低星英雄，不显示升星按钮
	self:Examine()
end

function UISagaInfo:RemoveTheOlderCacheHeroObj(exceptHero)
	local olderObj = nil
	local minTime = 0
	local olderKey = nil
	for k,v in pairs(self._uiHeroObjList) do
		if not v:IsShow() and v ~= exceptHero and (not olderObj or v:GetLastHideTime() < minTime) then
			olderObj = v
			minTime = v:GetLastHideTime()
			olderKey = k
		end
	end
	if olderObj then
		self._uiHeroObjList[olderKey] = nil
		self._uiCacheHeroCnt = self._uiCacheHeroCnt - 1
		olderObj:Destroy()
	end
end
------------------------------------------------------------------
-- 升级、升阶
function UISagaInfo:RefreshUpLvView(network)
	self._payItemList = {}
	CS.ShowObject(self.mUpBtnredPoint,false)
	CS.ShowObject(self.mUpLvredPoint,false)
	CS.ShowObject(self.mLVBg,true)
	CS.ShowObject(self.mResonanceTxt,false)
	CS.ShowObject(self.mOperateBtn,true)
	self:SetXUITextText(self.mConsumeTxt,ccClientText(10016))
	local refId,id = self._refId,self._id
	local heroRef = gModelHero:GetHeroRef(refId) 				-- 英雄表
	local hero = gModelHero:GetHeroById(id) 					-- 英雄Info
	if not heroRef or not hero then return end

	local serData = hero:GetServerData() 					-- 服务器数据
	local star = serData.star
	local lv = hero:GetLv()
	local grade = serData.grade
	--local levelRef = gModelHero:GetHeroLevelById(lv) 		-- 等级表
	local classType = heroRef.classType 				-- 阶级数据
	local classId = gModelHero:ConvertToHeroGradeId(classType,grade) 	-- 阶级Id
	local classRef = gModelHero:GetHeroClassById(classId) 	-- 阶级表
	local needLv = classRef.needLevel 				-- 升到下一阶的等级需求
	local needStar = classRef.needStar 				-- 升到下一阶的星级需求
	local needItem = classRef.needItem 				-- 升到下一阶的道具需求
	local maxStar = heroRef.maxStar 					-- 星级上限
	local starUpLevellimit = heroRef.starUpLevellimit 		-- 可升级的最高等级

	local heroStarRef = gModelHero:GetStarRefById(id)	-- 星级表

	local isResonance = serData.isResonance

	self:SetWndButtonGray(self.mOptTxt, isResonance == 1)

	self:ResetTrans()
	local tmpLv = needLv - lv
	if tmpLv > 5 then tmpLv = 5 end
	if tmpLv < 0 then tmpLv = 5 end
	self._upLv = tmpLv
	local temp = string.replace(ccClientText(10063),self._upLv)
	self._needItemList = {}
	if isResonance == 1 then
		self._optType = 9
		CS.ShowObject(self.mConsumeBg,false)
		CS.ShowObject(self.mUpTips,true)
		self:SetWndText(self.mUpTips,ccClientText(14723))
		lv = string.format("<color=#%s>%s</color>",LUtil.GetResonanceColor(isResonance),lv)
		--lv = "<color=#1bdef2ff>"..lv.."</color>"
		local lvStr = ccClientText(10011)
		lvStr = string.replace(lvStr,lv)
		self:SetXUITextText(self.mLvTxt,lvStr)
		--self:SetXUITextText(self.mOptTxt,temp)
		self:SetWndButtonText(self.mOptTxt,temp)
	else
		local maxLevel = heroStarRef.maxLevel 			-- 等级上限
		-- 0:开始 1:满星满等级 2:满星不满等级 3:不满星满等级(去升星) 4:升阶 5:升级 6:升星 7:满星提示 8:伙伴已满级（卓越及以上可以通过共鸣继续提升等级）
		local optType = self:GetOptStatus(star,maxStar,lv,maxLevel,needLv,needStar) 										-- 操作按钮状态
		if starUpLevellimit <= lv then
			optType = 8
		end
--[[			if star == maxStar then
			if lv == maxLevel then 								-- 满星满等级
				optType = 1
			else 												-- 满星不满等级,升级/升阶
				if needLv == lv and needStar <= star then 		-- 升阶
					optType = 4
				elseif needLv == lv and needStar > star then 	-- 升星界面
					optType = 3
				else 											-- 升级
					optType = 5
				end
			end
		else
			if lv == maxLevel then 								-- 等级达到最高则切换到升星界面
				optType = 3
			else 												-- 是否可以进阶
				if needLv == lv then 							-- 是否处于升阶状态
					optType = 4
				elseif needLv == lv and needStar > star then 	-- 升星界面
					optType = 3
				else 											-- 升级
					optType = 5
				end
			end
		end]]
		printInfoN("-------- optType = ",optType)

		self._optType = optType
		if optType == 1 or optType == 3 then
			CS.ShowObject(self.mUpTips,true)
			local text = ccClientText(10004)
			if optType == 3 then
				if needStar == -1 then
					text = ccClientText(10051)
					needStar = star + 1
				else
					text = ccClientText(10025)
				end
				text = string.replace(text,needStar)
			end
			self:SetWndText(self.mUpTips,text)
		else
			CS.ShowObject(self.mUpTips,false)
		end
		CS.ShowObject(self.mConsumeBg,optType ~= 1)
		local commonTransList = self._commonTransList 			-- 道具
		local commonNameList = self._commonNameList 			-- 名字
		local commonNumList = self._commonNumList	 			-- 数量
		--lv = "<color=#DDE1E1FF>"..lv.."</color>"
		local lvStr = ccClientText(10011)
		lvStr = string.replace(lvStr,lv)
		self:SetXUITextText(self.mLvTxt,lvStr)
		if optType == 1 then
			--self:SetXUITextText(self.mOptTxt,ccClientText(10000))
			self:SetWndButtonText(self.mOptTxt,ccClientText(10000))
			CS.ShowObject(self.mOperateBtn,false)
		elseif optType == 2 then

		elseif optType == 3 then
			--self:SetXUITextText(self.mOptTxt,ccClientText(10003))
			self:SetWndButtonText(self.mOptTxt,ccClientText(10003))
		elseif optType == 4 then
			self:SetXUITextText(self.mConsumeTxt,ccClientText(10034))
			--self:SetXUITextText(self.mOptTxt,ccClientText(10002))
			self:SetWndButtonText(self.mOptTxt,ccClientText(10002))
			if not string.isempty(needItem) then
				local list = string.split(needItem,",")
				for i,v in ipairs(list) do
					local trans,nameTrans,numTrans = commonTransList[i],commonNameList[i],commonNumList[i]
					local data = string.split(v,"=")
					local _itype,_refId,_num = tonumber(data[1]),tonumber(data[2]),tonumber(data[3])
					table.insert(self._needItemList,{refId = _refId,num = _num})
					if _itype == 1 then
						self._payItemList[_refId] = gModelItem:GetNumByRefId(_refId)
					end

					CS.ShowObject(trans,true)
					--CS.ShowObject(nameTrans,true)
					CS.ShowObject(numTrans,true)

					self:SetConsumeItemIcon(trans, _itype, _refId, i)

					self:SetConsumeItemNameInfo(nameTrans, numTrans, _refId, _num, true)

					printInfoN("_itype,_refId,_num = ",_itype,_refId,_num)
				end
				local show = true
				for i,v in ipairs(self._needItemList) do
					if not show then break end
					local have = gModelItem:GetNumByRefId(v.refId)
					show = have >= v.num
				end
				CS.ShowObject(self.mUpBtnredPoint,show)
				CS.ShowObject(self.mUpLvredPoint,show)
			end
		elseif optType == 5 then
--[[			local needExp = levelRef.needExp
			local needGold = levelRef.needGold--]]

			local itemRefIdList = {101001,104001}

			local haveGold,haveExp = gModelItem:GetNumByRefId(101001),gModelItem:GetNumByRefId(104001)
			local needGold,needExp,addLv = gModelHero:GetUpNumLvPayItem(id,hero:GetLv(),classId,grade)

			if haveGold >= needGold and haveExp >= needExp then
				CS.ShowObject(self.mUpBtnredPoint,true)
				CS.ShowObject(self.mUpLvredPoint,true)
			else
				CS.ShowObject(self.mUpBtnredPoint,false)
				CS.ShowObject(self.mUpLvredPoint,false)
			end

			local needList = {needGold,needExp}
			self._upLv = addLv
			-- 计算升5级的材料消耗
			-- local maxAddLv = self._upLv

			for i = 1,#commonTransList do
				local trans,nameTrans,numTrans = commonTransList[i],commonNameList[i],commonNumList[i]
				if i < 3 then
					CS.ShowObject(trans,true)
					--CS.ShowObject(nameTrans,true)
					CS.ShowObject(numTrans,true)

					local _refId,_num = itemRefIdList[i],needList[i]
					self._payItemList[_refId] = gModelItem:GetNumByRefId(_refId)
					-- _num = _num * self._upLv
					table.insert(self._needItemList,{refId = _refId,num = _num})

					self:SetConsumeItemIcon(trans, LItemTypeConst.TYPE_ITEM, _refId, i)

					self:SetConsumeItemNameInfo(nameTrans, numTrans, _refId, _num, not network)

					printInfoN("needList = ",needList[i])
				else
					CS.ShowObject(trans,false)
				end
			end
			temp = string.replace(ccClientText(10063),self._upLv)
			--self:SetXUITextText(self.mOptTxt,temp)
			self:SetWndButtonText(self.mOptTxt,temp)
		elseif optType == 8 then
			self:SetWndText(self.mUpTips,ccClientText(10078))
			CS.ShowObject(self.mUpTips,true)
			CS.ShowObject(self.mOperateBtn,false)
		end
	end

	if not network then
		local skillGroup = heroStarRef.skillGroup
		self:RefreshSkilList(skillGroup,nil,1)
	end
end

function UISagaInfo:ShowRaecKeZhiInfo()
	local refId = self._refId
	local raceType = gModelHero:GetHeroType(refId)
	if raceType then
		local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
		if raceRef then
			local heroRaceImage = raceRef.heroRaceImage
			self:SetWndEasyImage(self.mTypeKeZhiImg,heroRaceImage,function()
				CS.ShowObject(self.mTypeKeZhiImg,true)
			end,true)

			local name = string.replace(ccClientText(10079),ccLngText(raceRef.name))
			self:SetWndText(self.mRaceTypeName,name)
		end
	end
end

-- 操作按钮
function UISagaInfo:UpOptBtnEvent(idx,btnTrans)
	if self._curOptIndex == idx then return end
	self._appointList = {}
	self._rangList = {}
	self._rangItemList = {}
	gModelHero:ClearUpStarSelHeroList()
	self._curOptIndex = idx
	self:UpBtnStatus()
	self._lastUpOptBtn = btnTrans
	local divShow = idx ~= 3
	CS.ShowObject(self.mLvAndStarDiv,divShow)
	CS.ShowObject(self.mTalentDiv,not divShow)
	local isShow
	if idx == 1 then
		isShow = true
		self:RefreshUpLvView()
	elseif idx == 2 then
		isShow = false
		self:RefreshUpStarView()
	elseif idx == 3 then
		self:GiftBtnEvent()
	end
	if idx ~= 3 then
		CS.ShowObject(self.mDressBtn,true)
		CS.ShowObject(self.mSkillShopBtn,false)
	end
	if isShow ~= nil then
		CS.ShowObject(self.mLvContent,isShow)
		CS.ShowObject(self.mStarContent,not isShow)
	end
end

function UISagaInfo:RefreshHeroAttr(attrList)
	if not table.isempty(attrList) then
		local heroAttrDef = self._heroAttrDef
		local Atk,maxHp,Def,Speed = attrList[1],attrList[2],attrList[3],attrList[4]
		Atk = math.floor(Atk + 0.5)
		maxHp = math.floor(maxHp + 0.5)
		Def = math.floor(Def + 0.5)
		Speed = math.floor(Speed + 0.5)
		local atkStr = gModelHero:GetAttributeNameById(heroAttrDef[1])..":".."<color=#9f835c>"..Atk.."</color>"
		local maxHpStr = gModelHero:GetAttributeNameById(heroAttrDef[2])..":".."<color=#9f835c>"..maxHp.."</color>"
		local defStr = gModelHero:GetAttributeNameById(heroAttrDef[3])..":".."<color=#9f835c>"..Def.."</color>"
		local speedStr = gModelHero:GetAttributeNameById(heroAttrDef[4])..":".."<color=#9f835c>"..Speed.."</color>"
		self:SetXUITextText(self.mAttr1,atkStr)
		self:SetXUITextText(self.mAttr2,speedStr)
		self:SetXUITextText(self.mAttr3,maxHpStr)
		self:SetXUITextText(self.mAttr4,defStr)
	end
end

function UISagaInfo:CutHero(curIndex)
	if self._curUIHeroObj and not self._curUIHeroObj:IsDpValid() then return end

	local index = self._heroIndex
	if not index then return end
	local lastNum = gModelHero:GetLastNum()
	local newIndex = index + curIndex
	if newIndex <= 0 then
		newIndex = lastNum
	elseif newIndex > lastNum then
		newIndex = 1
	end
	self._appointList = {}
	self._rangList = {}
	self._rangItemList = {}
	gModelHero:ClearUpStarSelHeroList()
	local data = gModelHero:GetHeroBagPos(newIndex)
	if not table.isempty(data) then
		local id = data.id
		curIndex = data.index
		local refId = gModelHero:GetRefIdById(id)
		self._refId = refId
		self._id = id
		self._heroIndex = curIndex
		-- 英雄切换动画
		self:CutHeroAni()
		self:Examine()
		self:RefreshTop()
		self:RefreshContent()
	end
end

function UISagaInfo:CheckRedPoint()
	self._upStatus = {}
	local haveGold,haveExp = gModelItem:GetNumByRefId(101001),gModelItem:GetNumByRefId(104001)
	local id = self._id
	local hero = gModelHero:GetHeroById(id)
	local serData = hero:GetServerData() 					-- 服务器数据
	local isResonance = serData.isResonance
	local refId,star,lv,grade = serData.refId,serData.star,serData.lv,serData.grade
	printInfoNR("======= id,refId,star,lv,grade = ",id,refId,star,lv,grade)
	local nextStar = star + 1
	local heroRef = gModelHero:GetHeroRef(refId) 				-- 英雄表
	local maxStar = heroRef.maxStar 					-- 星级上限

	local classType = heroRef.classType 				-- 阶级数据
	local classId = gModelHero:ConvertToHeroGradeId(classType,grade) 	-- 阶级Id
	local classRef = gModelHero:GetHeroClassById(classId) 	-- 阶级表
	local needLv = classRef.needLevel 				-- 升到下一阶的等级需求
	local needStar = classRef.needStar 				-- 升到下一阶的星级需求
	local needItem = classRef.needItem 				-- 升到下一阶的道具需求

	local heroStarRef = gModelHero:GetStarRefById(id)	-- 星级表

	local skinEffectId = heroStarRef.skinEffectId
	local showSkinBtn = not string.isempty(skinEffectId) and not self._noShowSkinBtn
	CS.ShowObject(self.mSkinBtn,showSkinBtn)
	if showSkinBtn then self:RefreshSkinRedPoint(id) end

	local maxLevel = heroStarRef.maxLevel 			-- 等级上限
	local optType = self:GetOptStatus(star,maxStar,lv,maxLevel,needLv,needStar)
	local show
	if isResonance ~= 1 then
		if optType == 5 then
			local needGold,needExp,addLv = gModelHero:GetUpNumLvPayItem(id,hero:GetLv(),classId,grade,1)
			show = false
			if needGold <= haveGold and needExp <= haveExp then
				show = true
			end
		elseif optType == 4 then
			if not string.isempty(needItem) then
				local itemList = {}
				local list = string.split(needItem,",")
				for i,v in ipairs(list) do
					v = string.split(v,"=")
					local itemRefId,itemNum = tonumber(v[2]),tonumber(v[3])
					itemList[itemRefId] = itemNum
				end
				show = true
				for k,v in pairs(itemList) do
					if not show then break end
					local haveItem = gModelItem:GetNumByRefId(k)
					show = v <= haveItem
				end
			end
		end
	else
		show = false
	end
	CS.ShowObject(self.mUpLvredPoint,show)

	local showStarRedPoint
	if maxStar == star then
		showStarRedPoint = false
	else
		local upStarAppoint = heroStarRef.upStarAppoint
		local upStarRange = heroStarRef.upStarRange
		local upStarItem = heroStarRef.upStarItem
		local fuse1,fuse2,fuse3 = true,true,true
		local data = {}
		if not string.isempty(upStarAppoint) then
			local appoint = string.split(upStarAppoint,",")
			for _i,_v in ipairs(appoint) do
				if not fuse1 then break end
				_v = string.split(_v,"=")
				local needHeroRefId,needHeroStar,needNum = tonumber(_v[1]),tonumber(_v[2]),tonumber(_v[3])
				local dataList = gModelHero:FilterHero(needHeroRefId,needHeroStar,nil,id,{})
				local haveNum = table.keysize(dataList)
				local tempList = {}
				local aaa = 0
				for key,val in pairs(dataList) do
					if aaa >= needNum then break end
					tempList[key] = val
					aaa = aaa + 1
				end
				table.insert(data,tempList)
				fuse1 = haveNum >= needNum
			end
		end
		if not string.isempty(upStarRange) then
			local range = string.split(upStarRange,",")
			for _i,_v in ipairs(range) do
				if not fuse2 then break end
				_v = string.split(_v,"=")
				local needHeroRefId,needHeroStar,needNum = tonumber(_v[1]),tonumber(_v[2]),tonumber(_v[3])
				local dataList,yinghunItemList = gModelHero:FilterHero(needHeroRefId,needHeroStar,needHeroRefId,id,{})
				local haveNum = table.keysize(dataList) + table.keysize(yinghunItemList)
				local selNum = 0
				for i,v in ipairs(data) do
					for k,val in pairs(v) do
						if dataList[k] then
							selNum = selNum + 1
						end
					end
				end
				haveNum = haveNum - selNum
				fuse2 = haveNum >= needNum
			end
		end
		if not string.isempty(upStarItem) then
			upStarItem = string.split(upStarItem,"=")
			local itemRefId,num = tonumber(upStarItem[2]),tonumber(upStarItem[3])
			local haveNum = gModelItem:GetNumByRefId(itemRefId)
			fuse3 = haveNum >= num
		end
		showStarRedPoint = fuse1 and fuse2 and fuse3
		local upStarLimit
		if maxStar < nextStar then
			upStarLimit = self._heroUpStarLimit[star]
		else
			upStarLimit = self._heroUpStarLimit[nextStar]
		end
		if upStarLimit then
			-- 魔镜等级小于限制等级，显示文字隐藏按钮
			local resonanceLevel = gModelResonance:GetResonanceLv()
			if resonanceLevel < upStarLimit then
				showStarRedPoint = false
			end
		end
	end
	CS.ShowObject(self.mUpStarredPoint,showStarRedPoint)
	self._upStatus = {
		[1] = show,
		[2] = showStarRedPoint,
	}
end

-- 刷新装备
function UISagaInfo:RefreshEquip(equipList)
	self._curEquipList = equipList
	local equipTransList = self._equipTransList
	for i = 1,self._openEquipNum do
		local trans = equipTransList[i]
		if trans then
			local data = equipList[i]
			local ishave = true
			if not data then
				ishave = false
				data = i
			end
			local baseClass = self._equipUIIconList[i]
			if not baseClass then
				baseClass = CommonIcon:New(self)
				self._equipUIIconList[i] = baseClass
				baseClass:Create(trans)
			end
			baseClass:SetCommonReward(LItemTypeConst.TYPE_EQUIP, data, nil)
			baseClass:EnableShowNum(false)
			self:SetIconClickScale(trans, true)
			self:SetWndClick(trans,function()
				if not ishave then
					GF.OpenWndUp("UIEqWear",{refId = data,heroId = self._id})
				else
					GF.OpenWndUp("UIEqInfo",{refId = data,heroId = self._id,OpenWay = true,showRedImg = true})
				end
			end)
			baseClass:DoApply()

--[[			local baseClass = EquipIcon:New(self)
			equipIconList[data] = baseClass
			baseClass:Create(trans,data,function()
				if not ishave then
					GF.OpenWndUp("UIEqWear",{refId = data,heroId = self._id})
				else
					GF.OpenWndUp("UIEqInfo",{refId = data,heroId = self._id,OpenWay = true,showRedImg = true})
				end
			end)]]
		end
	end
	self:SelGoodEquip()
end

function UISagaInfo:OnTimer(key)
	if key == self._loopHeroObjTimerKey then
		local time = Time.unscaledTime
		if self._curUIHeroObj then
			self._curUIHeroObj:OnRun(time)
		end
		if self._uiSkillCtrl then
			self._uiSkillCtrl:OnRun(time)
		end
	end
end
------------------------------------------------------------------

-- 升级操作和左右按钮调用
function UISagaInfo:RefreshContent(network)
	self:CheckRedPoint()
	local btnIndex = self._curOptIndex
	if btnIndex == 1 then
		self:RefreshUpLvView()
	elseif btnIndex == 2 then
		self:RefreshUpStarView()
	 elseif btnIndex == 3 then
		self:GiftBtnEvent()
	end
	if btnIndex ~= 3 then
		CS.ShowObject(self.mDressBtn,true)
		CS.ShowObject(self.mSkillShopBtn,false)
	end
	if not network then
		local serverData = gModelHero:GetHeroServerDataById(self._id)
		local isResonance = serverData.isResonance
		local heroAttr,heroEquip = gModelHero:GetHeroAttrAndEquipInfoById(self._id)
		if table.isempty(heroAttr) or isResonance == 1 then
			gModelHero:OnHeroAttributeReq(self._id)
		else
			self:DisposeHeroAttr()
		end
	end
end

function UISagaInfo:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeroUpLevelResp,function()
		self._payItemList = {}
		if not self._isUp then self._isUp = true end
		LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_LVUP_COMMON)
		self:CreateWndEffect(self.mUpEffectPb,"fx_ui_shengji_hero","fx_ui_shengji_hero",100,false,false,6)
		GF.ShowMessage(ccClientText(10018))
		self:RefreshUpLvView(true)
		self._isClick = false
	end)

	local pbId = LProtoHelper.GetProtoId("HeroUpLevelResp")
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList) self._isClick = false end)

	self:WndNetMsgRecv(LProtoIds.PowerShowResp,function(pb,ret)
		local showType = pb.type
		local _powers = pb.powers
		for i, v in ipairs(_powers) do
			local key = v.key
			if showType == 2 and key == self._id then
				local power = v.power
				self:SetXUITextText(self.mPowerTxt,LUtil.FormatHurtNumSpriteText(power,false))
			end
		end
	end)
	self:WndNetMsgRecv(LProtoIds.HeroUpGradeResp,function() self:RefreshContent(true) end)
	self:WndNetMsgRecv(LProtoIds.HeroUpStarResp,function()
		GF.ShowMessage(ccClientText(10019))
		local tab = {optType = 1,id = self._id,}
		GF.OpenWnd("UISagaUpOpt",tab)
		self._appointList = {} 				-- 指定英雄消耗
		self._rangList = {} 				-- 范围消耗
		self._rangItemList = {}
		self:RefreshTop(true)
		self:RefreshContent(true)
		self._isClick = false
	end)
	self:WndNetMsgRecv(LProtoIds.EquipUnloadResp,function() self:SelGoodEquip(true) end)
	self:WndNetMsgRecv(LProtoIds.OutfitUnloadResp,function() self:SelGoodOutfit() end)
	self:WndNetMsgRecv(LProtoIds.HeroAttributeResp,function(pb,ret)
		if pb.playerId == gLGameLogin:GetPlayerId() then self:DisposeHeroAttr() end
	end)
	self:WndNetMsgRecv(LProtoIds.HeroLockResp,function() self:RefreshTop() end)
	self:WndNetMsgRecv(LProtoIds.HeroSkinSelectResp,function()
		self._isChangeSkin = true
		self:RefreshContent(true)
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()																			-- 范围消耗
--[[		if self._curOptIndex == 3 then
			self:DisposeHeroAttr()
		else
			self:RefreshItemList()
		end
        if self._curOutfitList then self:RefreshOutfit(self._curOutfitList) end]]
		if self._curOptIndex ~= 3 then
			self:RefreshItemList()
		end
		self:DisposeHeroAttr()
	end)
	self:WndNetMsgRecv(LProtoIds.OutfitWearResp,function() self:SelGoodOutfit() end)
	self:WndNetMsgRecv(LProtoIds.RefreshDataResp,function() self:RefreshTop() end)
	self:WndNetMsgRecv(LProtoIds.HeroRebornResp,function(pb)
		self._isClick = false
		local heroId = pb.heroId
		if self._id == heroId then
			self:RefreshTop()
			self:RefreshContent()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.HeroRemoveFormationResp,function() self:RefreshContent(true) end)
end

function UISagaInfo:RefreshSkilList(curSkillGroup,nextSkillGroup,itype)
	local skillIdList = gModelHero:GetSkillIdListById(self._id)
	local skillTransList = self._skillTransList
	local skillIconList = self._skillIconList
	if not table.isempty(skillIconList) then
		skillIconList = {}
		self._skillIconList = skillIconList
	end
	if not table.isempty(skillIdList) then
		local hero = gModelHero:GetHeroById(self._id)
		local serData = hero:GetServerData()
		local grade = serData.grade
		local heroLv = serData.lv
		local refId = serData.refId
		local heroRef = gModelHero:GetHeroRef(refId)
		local classType
		if heroRef then classType = heroRef.classType end
		local nextSkillList
		local showUp = false
		if nextSkillGroup then
			showUp = true
			nextSkillList = string.split(nextSkillGroup,",")
		end
		local skillListLen = #skillIdList
		for i,v in ipairs(skillIdList) do
			local trans = skillTransList[i]
			if trans then
				local skillIconTrans = CS.FindTrans(trans,"SkillIcon")
				if skillIconTrans then
					local skillId = v.skillId
					local baseClass = skillIconList[i]
					if not baseClass then
						baseClass = SkillIcon:New(self)
						skillIconList[i] = baseClass
					end
					skillIconList[i] = baseClass
					local tempShowUp
					if showUp then
						local tempData = string.split(nextSkillList[i],"=")
						local nextSkillId = tonumber(tempData[1])
						if nextSkillId == skillId then
							tempShowUp = false
						else
							tempShowUp = true
						end
					end
					if tempShowUp == nil then tempShowUp = showUp end
					baseClass:SetSkillInfo(grade,tempShowUp,v.openClass,itype)
					baseClass:Create(skillIconTrans,skillId,function()
						gModelGeneral:OpenHeroSkillWnd({curSkillId = skillId,curSkillIdx = i,heroData = serData})
						--GF.OpenWnd("UIJNInfo",{skillId = skillId,heroId = self._id,needGrade = v.openClass,index = i})
					end)
				end
				CS.ShowObject(trans,true)
			end
		end
		for i = skillListLen + 1,4 do
			local trans = skillTransList[i]
			if trans then
				local baseClass = SkillIcon:New(self)
				local skillIconTrans = CS.FindTrans(trans,"SkillIcon")
				baseClass:SetShowIcon(false,false)
				baseClass:SetSkillInfo(nil,nil,nil,1)
				baseClass:Create(skillIconTrans,0,function() end)
				baseClass:SetIconAndIconBgGray(false)
				CS.ShowObject(trans,true)
			end
		end
	end
end

function UISagaInfo:SelGoodEquip(network)
	self._heightEquipList = {}
	local heightEquipList = self._heightEquipList
	local curEquipList = self._curEquipList
	local showRedPoint = false
	local notEquip = false 					-- 不存在更高级的装备
	CS.ShowObject(self.mRedImg,showRedPoint)
	for i = 1,self._openEquipNum do
		local eType = i
		local curEquipData = curEquipList[eType]
		local refId = gModelEquip:FindTypeEquipHeightScoreByType(i,curEquipData) 			-- 0：没有装备
		if not curEquipData and refId ~= 0 then
			table.insert(heightEquipList,refId)
			showRedPoint = true
		elseif refId ~= curEquipData and refId ~= 0 then
			table.insert(heightEquipList,refId)
			showRedPoint = true
		elseif refId == 0 then
			notEquip = true
		end
		CS.ShowObject(self._redEquipTransList[i],refId ~= 0 and refId ~= curEquipData)
	end
	CS.ShowObject(self.mRedImg,showRedPoint)
	local str
	if showRedPoint then
		str = ccClientText(11327)
	else
		if notEquip and table.isempty(curEquipList) then
			showRedPoint = true
			str = ccClientText(11327)
		else
			str = ccClientText(11328)
		end
	end
	self:SetXUITextText(self.mDressTxt,str)
	local img = self._dressBtnImgList[1]
	if showRedPoint then img = self._dressBtnImgList[2] end
	self:SetWndEasyImage(self.mDressBtn,img)
	self._showRedPoint = showRedPoint
end

function UISagaInfo:OnClickShare()
	local data = {
		root = self.mShareBtn,
		shareType = ModelChat.CHATSHARE_HERO,
		shareData = self._id,
	}
	gModelGeneral:OpenShareTip(data)
end

------------------------------------------------------------------
function UISagaInfo:SetConsumeHeroIcon(trans, refId, index, func, star, showMask, bRace)
	local iconTrans = CS.FindTrans(trans, "CommonUI/Icon")
	local commonUIList = self._commonUIList
	local uiIconClass = commonUIList[index]
	if not uiIconClass then
		uiIconClass = CommonIcon:New()
		commonUIList[index] = uiIconClass
		uiIconClass:Create(iconTrans)
		self:SetIconClickScale(iconTrans, true)
	end

	if bRace then
		uiIconClass:SetRaceData({id=refId, refId=refId, star=star, race=refId, needNum =1,hideTree = true })
	else
		uiIconClass:SetHeroDataSet({id=refId, refId=refId, star=star, level=1,hideTree = true})
	end
	uiIconClass:SetShowMaskOnly(showMask)
	uiIconClass:EnableShowNum(false)
	uiIconClass:SetNoShowLv(true)
	uiIconClass:DoApply()

	self:SetWndClick(iconTrans,func)

	return uiIconClass
end

function UISagaInfo:OnClickHeroSpine(heroObj)
	if self._curUIHeroObj == nil then return end
	if self._curUIHeroObj ~= heroObj then return end
	local spine = self._curUIHeroObj:GetDpObject()
	if not spine then return end
	local nowPlayAniName = spine:GetCurTrackEntryName()
	if nowPlayAniName == nil or nowPlayAniName == "idle" then
		local panelPlayEff = heroObj:RandomOneSkill()
		if not panelPlayEff then
			heroObj:PlayAttackAni()
			return
		end

		local skillCtr = self._uiSkillCtrl
		if skillCtr then
			skillCtr:Destroy()
			skillCtr = nil
		end

		skillCtr = LUISkillCtrl:New(self)
		self._uiSkillCtrl = skillCtr

		skillCtr:InitData(heroObj, panelPlayEff, self.mEffectPb, 0, 3, 250)
		skillCtr:PreLoadPlaySkill()
	end
end

function UISagaInfo:GetTalentStatus(talentList)
	local studyNum = 0
	for k,v in pairs(talentList) do
		local tempRef = gModelRune:GetSkillInfoByRefId(v)
		local upItem = string.split(tempRef.upItem,",")[1]
		if upItem then
			upItem = string.split(upItem,"=")
			local needRefId = tonumber(upItem[2])
			if needRefId then
				studyNum = studyNum + gModelItem:GetBagRuneItemByRefId(needRefId)
			end
		end
	end
	return studyNum
end

-- 0:开始 1:满星满等级 2:满星不满等级 3:不满星满等级(去升星) 4:升阶 5:升级 6:升星 7:满星提示 8:天赋界面技能预览 9:共鸣状态升级
function UISagaInfo:OperateEvent()
	local optType = self._optType
	local id = self._id
	if optType == 1 then
		GF.ShowMessage("英雄等级已达上限")
	elseif optType == 3 then	 				-- 前往升星界面
		self:UpOptBtnEvent(2,self._upOptBtnList[2])
	elseif optType == 4 then
		local func = function()
			GF.OpenWnd("UIUpde",{id = id})
		end
		self:UpOpt(func)
	elseif optType == 5 then	 				-- 升级协议
		if not self._isClick then
			local func = function()
				self._isClick = true
				gModelHero:OnHeroUpLevelReq(id,self._upLv)
			end
			self:UpOpt(func)
		else
			printInfoN("----- 防止点击过快")
		end
	elseif optType == 6 then
		local appointList,rangList,upItemList = self._appointList,self._rangList,self._upItemList
		for k,v in pairs(appointList) do
			if v.needNum > v.selNum then
				GF.ShowMessage(ccClientText(10054))
				return
			end
		end
		for k,v in pairs(rangList) do
			local selItemNum = 0
			local selItemData = self._rangItemList[k] or {}
			for _k,_v in pairs(selItemData) do
				selItemNum = selItemNum + _v
			end
			local selNum = v.selNum + selItemNum
			if v.needNum > selNum then
				GF.ShowMessage(ccClientText(10054))
				return
			end
		end
		for k,v in pairs(upItemList) do
			if v.needNum > v.selNum then
				gModelGeneral:OpenGetWayWnd({itemId = v.needRefId})
				return
			end
		end
		self._isClick = true
		gModelHero:CheckHeroHightHero(appointList,rangList,function()
			gModelHero:OnHeroUpStarReqByHeroInfoWnd(id,appointList,rangList,self._rangItemList) 		-- 由服务端判断材料是否足够
		end,function() self._isClick = false end)
	elseif optType == 7 then
		GF.ShowMessage(ccClientText(10009))
	elseif optType == 8 then
		GF.OpenWnd("UIReJNPreView")
	elseif optType == 9 then
		GF.ShowMessage(ccClientText(14723))
	end
end

function UISagaInfo:SetConsumeItemNameInfo(nameTrans, numTrans, refId, num, bShowName)
	if bShowName then
		local color = gModelItem:GetItemNameColor(refId)
		if color then self:SetXUITextTransColor(nameTrans,color) end
		local name = gModelItem:GetNameByRefId(refId)
		self:SetWndText(nameTrans,name)
	end
	local colorStr = self:GetColorStr(refId,num)
	self:SetWndText(numTrans,colorStr)
end

function UISagaInfo:SelGoodOutfit()
	self._heightEquipList = {}
	local heightEquipList = self._heightEquipList
	local outfitList = self._curOutfitList
	local showRedPoint = false 				-- 拥有高级装备
	local notEquip = false 					-- 不存在更高级的装备
	CS.ShowObject(self.mRedImg,showRedPoint)
	for i = 1,self._openEquipNum do
		local curOutfitData = outfitList[i]
		local isOutfit = true
		if not curOutfitData then
			isOutfit = false
			curOutfitData = i
		end
		local strongOutfit = gModelOutfit:FindStrongOutfit(curOutfitData,self._refId)
		if strongOutfit then
			table.insert(heightEquipList,{heroId = self._id,outfitId = strongOutfit.id})
			showRedPoint = true
			if notEquip then notEquip = false end
		else
			notEquip = true
		end
		local showStrongRedPoint = strongOutfit ~= nil
		if not showStrongRedPoint and isOutfit then
			showStrongRedPoint = gModelOutfit:ExamineOutfitIsUp(curOutfitData,self._refId)
		end
		CS.ShowObject(self._redEquipTransList[i],showStrongRedPoint)
	end
	CS.ShowObject(self.mRedImg,showRedPoint)
	local str
	if showRedPoint then
		str = ccClientText(11327)
	else
		if notEquip and table.isempty(outfitList) then
			showRedPoint = true
			str = ccClientText(11327)
		else
			str = ccClientText(11328)
		end
	end
	self:SetXUITextText(self.mDressTxt,str)
	local img = self._dressBtnImgList[1]
	if showRedPoint then img = self._dressBtnImgList[2] end
	self:SetWndEasyImage(self.mDressBtn,img)
	self._showRedPoint = showRedPoint
end

function UISagaInfo:UpBtnStatus()
	for i,v in ipairs(self._upOptBtnList) do
		local show = i == self._curOptIndex and 0 or 1
		self:SetWndTabStatus(v,show)
	end
end

function UISagaInfo:RefreshTalent(talentList)
	local showGiftRedPoint = false
	local talentRefIdList = self._talentRefIdList
	local talentTitleTransList = {self.mTalentName1,self.mTalentName2}
	local talentTransList = self._talentTransList
	local heroServerData = gModelHero:GetHeroServerDataById(self._id)
	for i = 1,2 do
		local pos = i + 2
		local runeRefId = talentRefIdList[i]
		local isLock = true
		local runePosRef = GameTable.MagicRunePosRef[runeRefId]
		local unlock = runePosRef.unlock
		local unlockTxt = ccLngText(runePosRef.text)
		unlock = string.split(unlock,"=")
		local condition = heroServerData.star
		if condition >= tonumber(unlock[2]) then isLock = false end
		local talentData = talentList[pos]
		local skillId = i
		local showTalentRedPoint = false
		if isLock then
			self:SetWndText(talentTitleTransList[i],unlockTxt)
		else
			local talentName = ""
			if talentData then
				if not showGiftRedPoint then
					showGiftRedPoint = gModelRune:IsEnoughUp(talentData)
				end
				local ref = gModelRune:GetSkillInfoByRefId(talentData)
				skillId = tonumber(ref.SkillId)
				local skillRef = gModelHero:GetSkillByStarId(skillId)
				if skillRef then
					talentName = ccLngText(skillRef.name)
				end
			else
				talentName = ccClientText(13252)
				local haveRuneItemNum = gModelItem:GetBagRuneItemAllNum()
				local studyNum = self:GetTalentStatus(talentList)
				haveRuneItemNum = haveRuneItemNum - studyNum
				showGiftRedPoint = haveRuneItemNum > 0
			end
			self:SetWndText(talentTitleTransList[i],talentName)
			showTalentRedPoint = true
		end
		local talentRedPoint = self._talentRedPointList[i]
		if showTalentRedPoint then
			if talentData then
				showTalentRedPoint = gModelRune:IsEnoughUp(talentData)
			else
				local haveRuneItemNum = gModelItem:GetBagRuneItemAllNum()
				local studyNum = self:GetTalentStatus(talentList)
				haveRuneItemNum = haveRuneItemNum - studyNum
				showTalentRedPoint = haveRuneItemNum > 0
			end
		end
		CS.ShowObject(talentRedPoint,showTalentRedPoint)
		local trans = talentTransList[i]
		local baseClass = SkillIcon:New(self)
		baseClass:ShowLock(isLock)
		if not isLock then
			baseClass:ShowAdd(talentData == nil)
		else
			baseClass:ShowAdd(false)
		end
		baseClass:Create(trans,skillId,function()
			if isLock then
				GF.ShowMessage(unlockTxt)
			else
				if skillId == i then
					local heroRef = gModelHero:GetHeroRef(self._refId)
					if heroRef then
						local heroJob = heroRef.careerType
						GF.OpenWnd("UITaltRealize",{HeroJob = heroJob,heroId = self._id,pos = pos,talentList = talentList})
					end
				else
					GF.OpenWnd("UITaltUp",{HeroId = self._id,pos = pos,TalentId = talentData})
				end
			end
		end)
	end
	CS.ShowObject(self.mGiftredPoint,showGiftRedPoint)
end

function UISagaInfo:RefreshRune(runeList)
	local runeRefIdList = self._runeRefIdList
	local runeTransList = self._runeTransList
	local heroServerData = gModelHero:GetHeroServerDataById(self._id)
	for i = 1,2 do
		local runeRefId = runeRefIdList[i]
		local isLock = true
		local runePosRef = GameTable.MagicRunePosRef[runeRefId]
		local unlock = runePosRef.unlock
		local unlockTxt = ccLngText(runePosRef.text)
		unlock = string.split(unlock,"=")
		local condition
		if i == 1 then
			condition = heroServerData.lv
		else
			condition = heroServerData.star
		end
		if condition >= tonumber(unlock[2]) then isLock = false end
		local trans = runeTransList[i]
		local runeData = runeList[i]
		local redPointTrans = self._redRuneTransList[i]
		local serverData = {}
		if runeData then serverData = runeData:GetServerData() end

		local serId = serverData.id or i
		if not isLock then
			if not serverData.id then
				local noWearNum = gModelRune:GetNoWearRuneNum()
				CS.ShowObject(redPointTrans,noWearNum > 0)
			else
				CS.ShowObject(redPointTrans,false)
			end
		else
			CS.ShowObject(redPointTrans,false)
		end
		local data = {
			id = serId,
			playerId = serverData.playerId,
			refId = serverData.refId,
			heroId = serverData.heroId,
			skillId = serverData.skillId,
			attrId = serverData.attrId,
			recast = serverData.recast,
			nextSkillId = serverData.nextSkillId,
			nextAttrId = serverData.nextAttrId,
		}

		self:SetWndClick(trans,function()
			if isLock then
				GF.ShowMessage(unlockTxt)
			else
				if serId == i then
					GF.OpenWnd("UIReWear",{runeId = serId,heroId = self._id,pos = i,wearList = runeList})
				else
					local data = {
						openWay = 2,
						runeData = serverData,
						leftFunc = function() gModelRune:OnRuneUnloadReq(self._id,serId,i) end,
						rightFunc = function() GF.OpenWnd("UIReWear",{runeId = serId,heroId = self._id,pos = i,wearList = runeList}) end
					}
					gModelGeneral:OpenRuneInfoTip(data)
				end
			end
		end)

		local baseClass = self._runeUIIconList[i]
		if not baseClass then
			baseClass = CommonIcon:New()
			self._runeUIIconList[i] = baseClass
			baseClass:Create(trans)
			self:SetIconClickScale(trans, true)
		end
		baseClass:SetRuneData(serverData)
		baseClass:SetRuneLock(isLock,unlockTxt)
		baseClass:DoApply()

	end
end

function UISagaInfo:ChangeBtnTxtColor(index)
	local selColor = "b9c9ebFF"
	local noselColor = "7f8bbfFF"
	for i,v in ipairs(self._upOptTxtList) do
		local color = noselColor
		if i == index then
			color = selColor
		end
		self:SetXUITextColor(v,LUtil.ColorByHex(color))
	end
end

-----------------------------------------------------------------
function UISagaInfo:SetConsumeItemIcon(trans, iType, refId, index)
	local iconTrans = CS.FindTrans(trans, "CommonUI/Icon")
	local commonUIList = self._commonUIList
	local uiIconClass = commonUIList[index]
	if not uiIconClass then
		uiIconClass = CommonIcon:New()
		commonUIList[index] = uiIconClass
		uiIconClass:Create(iconTrans)
		self:SetIconClickScale(iconTrans, true)
	end
	uiIconClass:SetCommonReward(iType, refId, 1)
	uiIconClass:EnableShowNum(false)
	uiIconClass:DoApply()

	self:SetWndClick(iconTrans,function() gModelGeneral:OpenGetWayWnd({itemId = refId}) end)
end

function UISagaInfo:StartHeroObjRunTimer()
	if self:IsTimerExist(self._loopHeroObjTimerKey) then return end
	self:TimerStart(self._loopHeroObjTimerKey,0, false, -1)
end

function UISagaInfo:SetConsumeHeroNameInfo(nameTrans, numTrans, needRefId, needStar, selNum, needNum)
	local name = gModelHero:GetHeroNameByRefId(needRefId,needStar)
	local color
	if not name then
		name = string.replace(ccClientText(10053),needStar)
		color = gModelItem:GetHeroColorByQuality(needStar)
	else
		color = gModelHero:GetHeroNameColorTableByRefId(needRefId,needStar)
	end
	if color then self:SetXUITextTransColor(nameTrans,color) end
	if not name then name = string.replace(ccClientText(10053),needStar) end
	self:SetWndText(nameTrans,name)

	local numStr = self:GetUpStarStar(selNum,needNum)
	self:SetWndText(numTrans,numStr)
end

function UISagaInfo:CutHeroAni()
	local aniEquipLeftList = self._aniEquipLeftList
	local aniEquipRightList = self._aniEquipRightList
	local leftFirstTrans,rightFirstTrans = aniEquipLeftList[1],aniEquipRightList[1]
	if leftFirstTrans and rightFirstTrans then
		local cutTime = 0.2
		for i = 1,#aniEquipLeftList do
			local leftTrans = aniEquipLeftList[i]
			local rightTrans = aniEquipRightList[i]
			local toLeftPos,toRightPos = leftTrans.localPosition,rightTrans.localPosition
			local fromLeftPos,fromRightPos = toLeftPos:Clone(),toRightPos:Clone()
			fromLeftPos.x = fromLeftPos.x - 100
			fromRightPos.x = fromRightPos.x + 100
			self:TweenSeq_AlphaCanvasTrans("leftAlpha" .. i, leftTrans, 0, 1,cutTime)
			self:TweenSeq_LocalMoveTrans("leftMove" .. i, leftTrans, fromLeftPos, toLeftPos,cutTime)

			self:TweenSeq_AlphaCanvasTrans("rightAlpha" .. i, leftTrans, 0, 1,cutTime)
			self:TweenSeq_LocalMoveTrans("rightMove" .. i, rightTrans, fromRightPos, toRightPos,cutTime)
		end
	end
end

function UISagaInfo:ResetTrans()
	local commonTransList = self._commonTransList
	--local commonNameList = self._commonNameList 			-- 名字
	local commonNumList = self._commonNumList	 			-- 数量
	local commonRedPointList = self._commonRedPointTransList
	for i = 1,#commonTransList do
		CS.ShowObject(commonTransList[i],false)
		--CS.ShowObject(commonNameList[i],false)
		CS.ShowObject(commonNumList[i],false)
		CS.ShowObject(commonRedPointList[i],false)
	end
end

function UISagaInfo:RebirthEvent()
	if self._isClick then return end
	local heroId = self._id
	local serData = gModelHero:GetHeroServerDataById(heroId) 					-- 服务器数据
	if not serData then return end
	local isCombat = serData.isCombat
	if isCombat == 1 then
		gModelFormation:OnHeroRemoveFormationReq(heroId,4,LGameUI.UI_SORTLAYER_UIBOTTOM,true)
	else
		local isResonance = serData.isResonance
		if isResonance == 1 then
			GF.ShowMessage(ccClientText(14444))
		else
			local lock = serData.lock
			if lock == 1 then
				GF.ShowMessage(ccClientText(14445))
			else
				local lv = serData.lv
				local heroLevelRebornMin = GameTable.CharacterConfigRef["heroLevelRebornMin"]
				if lv < heroLevelRebornMin then
					local str = string.replace(ccClientText(14446),heroLevelRebornMin)
					GF.ShowMessage(str)
				else
					local showTips = false
					local num = gModelHero:GetReborunNum()
					if GameTable.CharacterConfigRef["heroLevelRebornNum"] ~= -1 then
						if num >= GameTable.CharacterConfigRef["heroLevelRebornNum"] then
							GF.ShowMessage(ccClientText(14429))
						else
							showTips = true
						end
					else
						showTips = true
					end
					if showTips then
						local wndId = 50904
						if self._isOpenDay then wndId = 50905 end
						local func = function()
							if not self:IsWndValid() then return end
							gModelHero:OnHeroRebornReq(heroId)
							self._isClick = true
						end
						local leftFunc = function()

						end
						local itemList = {}
						table.insert(itemList,{
							heroData = {
								id = heroId,
								refId = serData.refId,
								star = serData.star,
								level = 1,
								skin = serData.skin,
								isResonance = isResonance,
							},
							itype = LItemTypeConst.TYPE_HERO
						})
						local tempList = gModelHero:GetPayItemNum(serData)
						for i,v in ipairs(tempList) do
							if v.itype == 2 then
								for index = 1,v.num do
									table.insert(itemList,{itemId = v.refId,count = v.num,itype = v.itype})
								end
							else
								table.insert(itemList,{itemId = v.refId,count = v.num,itype = v.itype or 1,id = v.id})
							end
						end
						local chongshengData = gModelHeroSpirit:GetChongshengData()
						if chongshengData then
							local rebornNeed = chongshengData.rebornNeed
							local curData = rebornNeed[num + 1]
							if not curData then curData = rebornNeed[#rebornNeed] end
							local needRefId,needNum = curData.refId,curData.num
							local name = gModelItem:GetNameByRefId(needRefId)
							local para = needNum .. name
							gModelGeneral:OpenUIOrdinTips({
								refId = wndId,
								itemList = itemList,
								func = func,
								leftFunc = leftFunc,
								closeFunc = leftFunc,
								para = {para},
								consume = {needNum, needRefId},
							})
						end
					end
				end
			end
		end
	end
end

function UISagaInfo:RefreshOutfit(outfitList)
	self._curOutfitList = outfitList
	local equipTransList = self._equipTransList
	for i = 1,self._openEquipNum do
		local effKey = "OutfitKey" .. i
		self:DestroyWndEffectByKey(effKey)
		local trans = equipTransList[i]
		if trans then
			local data = outfitList[i]
			local ishave = true
			if not data then
				ishave = false
				data = i
			elseif type(data) ~= "table" then
				ishave = false
				data = i
			end
			local baseClass = self._equipUIIconList[i]
			if not baseClass then
				baseClass = CommonIcon:New(self)
				self._equipUIIconList[i] = baseClass
				baseClass:Create(trans)
			end
			if ishave then
				baseClass:SetOutfitData(data)
				local outfitHeroRefId = data.heroRefId
				if outfitHeroRefId == self._refId then
					self:CreateWndEffect(trans,"fx_ui_zhuanshuzhuangbei",effKey,100,false,false,7)
				end
			else
				baseClass:SetCommonReward(LItemTypeConst.TYPE_OUTFIT, data, nil)
			end

			self:SetIconClickScale(trans, true)
			self:SetWndClick(trans,function()
				local heroData = gModelHero:GetHeroServerDataById(self._id)
				if ishave then
					gModelGeneral:OpenOutfitInfoTip({
						curSerData = data,
						outfitType = 4,
						heroData = heroData,
						wearList = outfitList,
						heroIndex = self._heroIndex,
					})
				else
					GF.OpenWndUp("WndOutfitWear",{
						outfitType = 1,
						heroData = heroData,
						wearList = outfitList,
						selOutfitType = data,
					})
				end
			end)
			baseClass:DoApply()
		end
	end
	self:SelGoodOutfit()
end

function UISagaInfo:DisposeHeroAttr()
	local heroAttr,heroEquip,heroRune,heroTalent,heroOutfitList = gModelHero:GetHeroAttrAndEquipInfoById(self._id)
	if heroAttr then
		local heroAttrDef = self._heroAttrDef
		local attrList = {}
		for i = 1,#heroAttrDef do
			local refId = heroAttrDef[i]
			attrList[i] = heroAttr[refId]
		end
		self:RefreshHeroAttr(attrList)
	end
--[[	local equipList = {}
	if heroEquip then
		for k,v in pairs(heroEquip) do
			local eType = gModelEquip:GetTypeByRefId(k)
			equipList[eType] = k
		end
	end
	self:RefreshEquip(equipList)]]
	local runeList = {}
	if heroRune then
		for k,v in pairs(heroRune) do runeList[k] = v end
	end
	self:RefreshRune(runeList)
	local talentList = {}
	if heroTalent then
		for k,v in pairs(heroTalent) do talentList[k] = v end
	end
	self:RefreshTalent(talentList)
	local outfitList = {}
	if heroOutfitList then
		for k,v in pairs(heroOutfitList) do
			outfitList[k] = v
		end
	end
	self:RefreshOutfit(outfitList)
end

-- 升星
function UISagaInfo:RefreshUpStarView()
	self._payItemList = {}
	self._baseClassList = {}
	CS.ShowObject(self.mUpBtnredPoint,false)
	CS.ShowObject(self.mLVBg,false)

	self:SetWndButtonGray(self.mOptTxt, false)

	local refId,id = self._refId,self._id
	local heroRef = gModelHero:GetHeroRef(refId) 				-- 英雄表
	local hero = gModelHero:GetHeroById(id) 					-- 英雄Info

	if not heroRef or not hero then return end

	local optType = 0 										-- 操作按钮状态
	local serData = hero:GetServerData() 					-- 服务器数据
	local curStar,isResonance,lv = serData.star,serData.isResonance,serData.lv
	local nextStar = curStar + 1
	local maxStar = heroRef.maxStar 							-- 星级上限
	local curHeroStarRef = gModelHero:GetStarRefById(id)
	if not curHeroStarRef then return end
	local heroNextStarRef = gModelHero:GetStarRefById(id,nextStar)	-- 获取下一星级表
	if not heroNextStarRef then 									-- 如果下一星级表不存在，则获取当前的星级表
		--nextStarId = nextStarId - 1
		heroNextStarRef = curHeroStarRef
	end
	if maxStar == curStar then
		optType = 7
	end
	--self:SetXUITextText(self.mOptTxt,ccClientText(10001))
	self:SetWndButtonText(self.mOptTxt,ccClientText(10001))
	self:SetXUITextText(self.mUpLvMaxTxt,ccClientText(10023))
	self:SetXUITextText(self.mLvTxt,ccClientText(10012))

	-------------------------------- 修改当前星级的星星 --------------------------------
	local curStarImg,curStarLv = gModelHero:GetHeroStarImg(curStar)
	local nextStarImg,nextStarLv = gModelHero:GetHeroStarImg(nextStar)
	for i = 1,5 do
		local curStarImgTrans = CS.FindTrans(self.mCurrStarList,"Star"..i)
		if curStarImgTrans then
			if curStarLv >= i then
				CS.ShowObject(curStarImgTrans,true)
				self:SetWndEasyImage(curStarImgTrans,curStarImg)
			else
				CS.ShowObject(curStarImgTrans,false)
			end
		end
		if optType == 7 then
			CS.ShowObject(self.mNextStarList,false)
		else
			CS.ShowObject(self.mNextStarList,true)
			local nextStarImgTrans = CS.FindTrans(self.mNextStarList,"Star"..i)
			if nextStarImgTrans then
				if nextStarLv >= i then
					CS.ShowObject(nextStarImgTrans,true)
					self:SetWndEasyImage(nextStarImgTrans,nextStarImg)
				else
					CS.ShowObject(nextStarImgTrans,false)
				end
			end
		end
	end
	local curMaxLv = curHeroStarRef.maxLevel
	local maxLv = heroNextStarRef.maxLevel
	-------------------------------- 修改当前星级的星星 --------------------------------
	-------------------------------- 获取上一星级的数据 --------------------------------
	-- 攻血成长提升
	local lastHeroStarRef = gModelHero:GetStarRefById(id,curStar - 1)
	if not lastHeroStarRef then
		lastHeroStarRef = curHeroStarRef
	end
	local curAtkVal = curHeroStarRef.atkVal
	local curHpVal = curHeroStarRef.maxhpVal
	local atkVal = heroNextStarRef.atkVal
	local hpVal = heroNextStarRef.maxhpVal
	local upAtkVal = (atkVal - curAtkVal) * 100
	local upHpVal = (hpVal - curHpVal) * 100
	local showLv = true
	self:SetWndText(self.mCurLvTxt,curMaxLv)
	if optType == 7 then
		curAtkVal,curHpVal = curAtkVal*100,curHpVal*100
		self:SetXUITextText(self.mGxczUpTxt,ccClientText(10052))
		local str = curAtkVal .. "%" .. "/" ..curHpVal .. "%"
		self:SetWndText(self.mCurUpTxt,str)
		CS.ShowObject(self.mStarAllow1,false)
	else
		self:SetXUITextText(self.mGxczUpTxt,ccClientText(10024))
		local str = upAtkVal .. "%" .. "/" .. upHpVal .. "%"
		showLv = false
		self:SetWndText(self.mNextLvTxt,maxLv)
		self:SetWndText(self.mNextUpTxt,str)
		CS.ShowObject(self.mStarAllow1,true)
	end
	-- 等级
	CS.ShowObject(self.mNextLvTxt,not showLv)
	CS.ShowObject(self.mStarAllow2,not showLv)
	-- 攻血
	CS.ShowObject(self.mCurUpTxt,showLv)
	CS.ShowObject(self.mNextUpTxt,not showLv)
	CS.ShowObject(self.mStarAllow3,not showLv)
	-------------------------------- 获取上一星级的数据 --------------------------------

	self:ResetTrans()
	local commonTransList = self._commonTransList 			-- 道具
	local commonNameList = self._commonNameList 			-- 名字
	local commonNumList = self._commonNumList	 			-- 数量
	local commonRedPointList = self._commonRedPointTransList

	local fuse
	if optType == 7 then
		CS.ShowObject(self.mUpTips,true)
		self:SetWndText(self.mUpTips,ccClientText(10009))
		CS.ShowObject(self.mConsumeBg,false)
		printInfoN("---- 星级已满")
		fuse = false
	else 													-- 升星操作
		CS.ShowObject(self.mConsumeBg,true)
		self:SetXUITextText(self.mConsumeTxt,ccClientText(10017))
		CS.ShowObject(self.mUpTips,false)
		local upStarAppoint = curHeroStarRef.upStarAppoint
		local upStarRange = curHeroStarRef.upStarRange
		local upStarItem = curHeroStarRef.upStarItem
		printInfoN("-------------------- upStarAppoint,upStarRange,upStarItem = ",upStarAppoint,upStarRange,upStarItem)
		local idx = 1
		local appHeroList,appSelHeroList,appRedPointList = {},{},{} 		-- 检测是否数据，筛选的数据，红点保存数据
		local selHeroList = {}
		local fuse1,fuse2,fuse3 = true,true,true 		-- 关乎升星页签和升星操作按钮的红点显示
		local allFuse1,allFuse2 = true,true 			-- 只做UICommon上的红点显示
		if not string.isempty(upStarAppoint) then
			local appoint = string.split(upStarAppoint,",")
			for i = 1,#appoint do
				local data = appoint[i]
				local val = string.split(data,"=")
				local needRefId,needStar,needNum = tonumber(val[1]),tonumber(val[2]),tonumber(val[3])
				local dataList = gModelHero:FilterHero(needRefId,needStar,nil,id,{})
				local haveNum = table.keysize(dataList)
				local tempList = {}
				local aaa = 0
				for key,value in pairs(dataList) do
					if aaa >= needNum then break end
					tempList[key] = value
					aaa = aaa + 1
				end
				table.insert(selHeroList,tempList)
				table.insert(appHeroList,{needRefId = needRefId,needStar = needStar,needNum = needNum})
				table.insert(appSelHeroList,dataList) 		-- 保存选择英雄的数据

				if fuse1 then
					fuse1 = haveNum >= needNum
				end
				allFuse1 = haveNum >= needNum

				printInfoN("-========== needRefId,needStar,needNum = ",needRefId,needStar,needNum)
				local trans,nameTrans,numTrans,redPointTrans = commonTransList[idx],commonNameList[idx],commonNumList[idx],commonRedPointList[idx]
				table.insert(appRedPointList,redPointTrans)

				if not self._appointList[i] then self._appointList[i] = {needRefId = needRefId,needNum = needNum,selList = {}} end

				-- 自动填充
				local sortSelList = gModelHero:SortFillHeroList(dataList)
				if #sortSelList ~= 0 then
					local autoSelNum = 0
					local selList = self._appointList[i].selList
					for selIdx,selHeroData in ipairs(sortSelList) do
						if selIdx > needNum then break end
						autoSelNum = autoSelNum + 1
						local autoSelId = selHeroData._id
						selList[autoSelId] = autoSelId
						gModelHero:SetSelHeroId(autoSelId)
					end
					CS.ShowObject(redPointTrans,#sortSelList < autoSelNum)
				else
					CS.ShowObject(redPointTrans,allFuse1)
				end

				local recordIndex = idx
				local clickFunc = function()
					local tab = {refId = needRefId,num = needNum,star = needStar,race = -1,selHeorId = id,selHeroList = self._appointList[i].selList,
								 func = function(appointList)
									 if not self:IsWndValid() then return end
									 local index = table.keysize(appointList)
									 local numStr = self:GetUpStarStar(index,needNum)
									 if not table.isempty(appointList) then
										 self._appointList[i].selList = {}
										 local list = self._appointList[i].selList
										 for k,v in pairs(appointList) do
											 list[v] = v
										 end
										 self:SetWndText(numTrans,numStr)
									 else
										 self._appointList[i].selList = appointList
										 self:SetWndText(numTrans,numStr)
									 end
									 local showRed = index < needNum
									 if showRed then
										 local tempDataList = gModelHero:FilterHero(needRefId,needStar,nil,id,{})
										 local tempLen = table.keysize(tempDataList)
										 local tempNum = needNum - index
										 showRed = tempLen >= tempNum
									 end
									 CS.ShowObject(redPointTrans,showRed)
									 if self._commonUIList[recordIndex] then
										 self._commonUIList[recordIndex]:ShowMaskOnly(index ~= needNum)
									 end
									 self._appointList[i].selNum = index
								 end
					}
					GF.OpenWnd("UISagaSelect",tab)
				end

				local selNum = table.keysize(self._appointList[i].selList)
				self._appointList[i].selNum = selNum

				local uiIconClass = self:SetConsumeHeroIcon(trans, needRefId, idx, clickFunc, needStar, selNum ~= needNum)
				self._baseClassList[i] = uiIconClass

				idx = idx + 1
				CS.ShowObject(trans,true)
				--CS.ShowObject(nameTrans,true)
				CS.ShowObject(numTrans,true)
				self:SetConsumeHeroNameInfo(nameTrans, numTrans, needRefId, needStar, selNum, needNum)
			end
		end
		if not string.isempty(upStarRange) then
			local rang = string.split(upStarRange,",")
			for i = 1,#rang do
				local data = rang[i]
				local val = string.split(data,"=")
				local needRefId,needStar,needNum = tonumber(val[1]),tonumber(val[2]),tonumber(val[3])

				if not self._rangList[i] then self._rangList[i] = {needRefId = needRefId,needNum = needNum,selList = {}} end
				if not self._rangItemList[i] then self._rangItemList[i] = {} end

				local dataList,yinghunItemList = gModelHero:FilterHero(needRefId,needStar,needRefId,id,self._rangList[i].selList)
				local haveNum = table.keysize(dataList) + table.keysize(yinghunItemList)
				local selHeroNum = 0
				for index,value in ipairs(selHeroList) do
					for key,heroData in pairs(value) do
						if dataList[key] then selHeroNum = selHeroNum + 1 end
					end
				end
				allFuse2 = haveNum >= needNum
				haveNum = haveNum - selHeroNum
				if fuse2 then
					fuse2 = haveNum >= needNum
				end

				printInfoN("-========== needRefId,needStar,needNum = ",needRefId,needStar,needNum)
				local trans,nameTrans,numTrans,redPointTrans = commonTransList[idx],commonNameList[idx],commonNumList[idx],commonRedPointList[idx]

				if needStar <= 3 then
					-- 自动填充
					local tempSelNum = 0
					local sortSelList = gModelHero:SortFillHeroList(dataList)
					if #sortSelList ~= 0 then
						local selList = self._rangList[i].selList
						for selIdx,selHeroData in ipairs(sortSelList) do
							if selIdx > needNum then break end
							tempSelNum = tempSelNum + 1
							local autoSelId = selHeroData._id
							selList[autoSelId] = autoSelId
							gModelHero:SetSelHeroId(autoSelId)
						end
					end
					local showRed = tempSelNum < needNum
					if showRed then
						local sortSelLen = #sortSelList
						showRed = sortSelLen >= needNum
					end
					CS.ShowObject(redPointTrans,showRed)
				else
					CS.ShowObject(redPointTrans,allFuse2)
				end

				local recordIndex = idx --idx 是在循环外面的， 后面会改值， 如果不用另外变量，闭包用的都是同一个idx
				local clickFunc = function()
					local tab = {refId = needRefId,num = needNum,star = needStar,race = needRefId,selHeorId = id,
								 selHeroList = self._rangList[i].selList,selItemList = table.clone(self._rangItemList[i]),
								 func = function(rangList,rangItemList)
									 if not self:IsWndValid() then return end
									 self._rangItemList[i] = {}
									 local rangIndex = table.keysize(rangList)
									 local index = rangIndex
									 for k,v in pairs(rangItemList) do
										 if v > 0 then
											 self._rangItemList[i][k] = v
										 else
											 self._rangItemList[i][k] = nil
										 end
										 index = index + v
									 end
									 local numStr = self:GetUpStarStar(index,needNum)
									 if not table.isempty(rangList) then
										 self._rangList[i].selList = {}
										 local list = self._rangList[i].selList
										 for k,v in pairs(rangList) do
											 list[v] = v
										 end
										 self:SetWndText(numTrans,numStr)
									 else
										 self._rangList[i].selList = rangList
										 self:SetWndText(numTrans,numStr)
									 end
									 if self._commonUIList[recordIndex] then
									 	self._commonUIList[recordIndex]:ShowMaskOnly(index ~= needNum)
									 end
									 --self._appointList[i].selList
									 for idxNum,idxData in ipairs(appSelHeroList) do
										 if not self._appointList then break end
										 local appBaseClass = self._baseClassList[idxNum]
										 local appListData = self._appointList[idxNum]
										 local selList = appListData.selList or {}
										 local appRedPointTrans = appRedPointList[idxNum]
										 local curSelNum,haveSelNum = 0,table.keysize(idxData)
										 local appData = appHeroList[idxNum]
										 local appNeedNum = appData.needNum
										 for idxKey,idxVal in pairs(idxData) do
											 if rangList[idxKey] then curSelNum = curSelNum + 1 end
										 end
										 local isShow = curSelNum < haveSelNum
										 local selListLen = table.keysize(selList)
										 if selListLen ~= 0 then
											 isShow = selListLen < appNeedNum
											 if isShow then
												 local tempNeedNum = appNeedNum - selListLen
												 local tempFilterList = gModelHero:FilterHero(appData.needRefId,appData.needStar,nil,id,{})
												 local tempFileterNum = table.keysize(tempFilterList)
												 isShow = tempFileterNum >= tempNeedNum
											 end
										 else
											 local tempFilterList = gModelHero:FilterHero(appData.needRefId,appData.needStar,nil,id,{})
											 local tempFileterNum = table.keysize(tempFilterList)
											 isShow = tempFileterNum >= appNeedNum
										 end
										 CS.ShowObject(appRedPointTrans,isShow)
										 if appBaseClass then
											 appBaseClass:ShowMaskOnly(selListLen ~= appNeedNum)
										 end
									 end
									 local showRed = index ~= needNum
									 if showRed then
										 local tempDataList,tempItemList = gModelHero:FilterHero(needRefId,needStar,needRefId,id,{})
										 local len = table.keysize(tempDataList) + table.keysize(tempItemList)
										 local tempNum = needNum - index
										 showRed = len >= tempNum
									 end
									 CS.ShowObject(redPointTrans,showRed)
									 self._rangList[i].selNum = rangIndex
								 end
					}
					GF.OpenWnd("UISagaSelect",tab)
				end

				local selNum = table.keysize(self._rangList[i].selList)
				self._rangList[i].selNum = selNum
				local uiIconClass = self:SetConsumeHeroIcon(trans, needRefId, idx, clickFunc, needStar, selNum ~= needNum, true)

				idx = idx + 1
				CS.ShowObject(trans,true)
				--CS.ShowObject(nameTrans,true)
				CS.ShowObject(numTrans,true)
				self:SetConsumeHeroNameInfo(nameTrans, numTrans, needRefId, needStar, selNum, needNum)
			end
		end
		self._upItemList = {}
		if not string.isempty(upStarItem) then
			local itemList = string.split(upStarItem,",")
			for i,v in ipairs(itemList) do
				local val = string.split(v,"=")
				local itype,itemRefId,itemNum = tonumber(val[1]),tonumber(val[2]),tonumber(val[3])
				if itype == 1 then
					self._payItemList[itemRefId] = gModelItem:GetNumByRefId(itemRefId)
				end
				local haveNum = gModelItem:GetNumByRefId(itemRefId)
				fuse3 = haveNum >= itemNum

				self._upItemList[i] = {needRefId = itemRefId,needNum = itemNum,selNum = gModelItem:GetNumByRefId(itemRefId)}
				local trans,nameTrans,numTrans = commonTransList[idx],commonNameList[idx],commonNumList[idx]

				self:SetConsumeItemIcon(trans, LItemTypeConst.TYPE_ITEM, itemRefId ,idx)

				idx = idx + 1
				CS.ShowObject(trans,true)
				--CS.ShowObject(nameTrans,true)
				CS.ShowObject(numTrans,true)

				self:SetConsumeItemNameInfo(nameTrans, numTrans, itemRefId, itemNum, true)
			end
		end
		fuse = fuse1 and fuse2 and fuse3
		optType = 6
	end
	CS.ShowObject(self.mUpBtnredPoint,fuse)
	printInfoN("============= optType = ",optType)
	self._optType = optType
	local curSkillGroup = curHeroStarRef.skillGroup
	local nextSkillGroup = heroNextStarRef.skillGroup
	if curStar == maxStar then
		CS.ShowObject(self.mResonanceTxt,false)
		CS.ShowObject(self.mOperateBtn,false)
	else
		local upStarLimit
		if maxStar < nextStar then
			upStarLimit = self._heroUpStarLimit[curStar]
		else
			upStarLimit = self._heroUpStarLimit[nextStar]
		end
		if upStarLimit then
			-- 魔镜等级小于限制等级，显示文字隐藏按钮
			local resonanceLevel = gModelResonance:GetResonanceLv()
			if resonanceLevel < upStarLimit then
				local limitStar = string.replace(ccClientText(14724), upStarLimit)
				self:SetWndText(self.mResonanceTxt, limitStar)
				CS.ShowObject(self.mResonanceTxt, true)
				isResonance = 1
				fuse = false
			else
				isResonance = 0
			end
			CS.ShowObject(self.mOperateBtn,isResonance ~= 1)
		else
			CS.ShowObject(self.mResonanceTxt, false)
			CS.ShowObject(self.mOperateBtn, true)
		end
	end
	CS.ShowObject(self.mUpStarredPoint,fuse)
	self:RefreshSkilList(curSkillGroup, nextSkillGroup, 2)
end

function UISagaInfo:CreateCurBtnEff()
	local seqTween
	self:TweenSeqKill(self._btnKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._btnKey,function(seq)
			local showTime = 0.5
			local leftPosition = -270
			local rightPosition = 270
			local movePostion = 10
			local leftBtnY = self.mLeftBtn.localPosition.y
			local rightBtnY = self.mRightBtn.localPosition.y
			self.mLeftBtn.localPosition = Vector3(leftPosition,leftBtnY,0)
			self.mRightBtn.localPosition = Vector3(rightPosition,rightBtnY,0)
			local leftBtnMove1 = self.mLeftBtn:DOLocalMoveX(leftPosition + movePostion,showTime)
			local leftBtnMove2 = self.mLeftBtn:DOLocalMoveX(leftPosition,showTime)
			local rightBtnMove1 = self.mRightBtn:DOLocalMoveX(rightPosition - movePostion,showTime)
			local rightBtnMove2 = self.mRightBtn:DOLocalMoveX(rightPosition,showTime)
			seq:Join(leftBtnMove1)
			seq:Join(rightBtnMove1)
			seq:AppendInterval(0)
			seq:Join(leftBtnMove2)
			seq:Join(rightBtnMove2)
			return seq
		end)
	end
	seqTween:SetLoops(-1,DG.Tweening.LoopType.Restart)
	seqTween:PlayForward()
	seqTween:OnComplete(function() self:TweenSeqKill(self._btnKey) end)
end

function UISagaInfo:GetHistory()
	local list = LWnd.GetHistory(self)
	local wndArgList = list.wndArgList
	wndArgList.refId = self._refId
	wndArgList.index = self._heroIndex
	wndArgList.id = self._id
	wndArgList.func = self._callFunc
	return list
end

function UISagaInfo:UpOpt(func)
	local gotoUp,lackRefId = true
	for i,v in ipairs(self._needItemList) do
		local tRefId = v.refId
		local haveNum = gModelItem:GetNumByRefId(tRefId)
		if haveNum < v.num then
			gotoUp = false
			lackRefId = tRefId
			break
		end
	end
	if gotoUp then
		if func then func() end
	else
		gModelGeneral:OpenGetWayWnd({itemId = lackRefId})
	end
end

function UISagaInfo:GetColorStr(refId,num)
	local allNum = gModelItem:GetNumByRefId(refId)
	local color = "30e055FF"
	if num > allNum then color = "c81212ff" end
	allNum = LUtil.NumberCoversion(allNum)
	num = LUtil.NumberCoversion(num)
	local str = string.replace(ccClientText(10065),color,allNum,num)
	return str
end

function UISagaInfo:Examine()
	local hideStarBtn
	local heroRef = gModelHero:GetHeroRef(self._refId)
	if heroRef then
		local initStar = heroRef.initStar
		local maxStar = heroRef.maxStar
		if initStar == maxStar then 			-- 隐藏升星按钮				-- 本身没办法升星的，不给显示星级相关
			hideStarBtn = true
		else
			hideStarBtn = false
		end
	end
	if hideStarBtn then
		CS.ShowObject(self._upOptBtnList[2],false)
		CS.ShowObject(self._upOptBtnList[3],false)
	else
		CS.ShowObject(self._upOptBtnList[2],true)
		CS.ShowObject(self._upOptBtnList[3],true)
	end
	if self._curOptIndex ~= 2 and self._curOptIndex ~= 3 then
		return
	else
		if hideStarBtn then self:UpOptBtnEvent(1,self._upOptBtnList[1]) end
	end
end

-- 左右按钮调用函数和进入界面的第一次调用
function UISagaInfo:RefreshTop(network)
	local id = self._id
	local refId = self._refId
	local ref = gModelHero:GetHeroRef(refId)
	if ref then
		local qualityIcon = ref.qualityIcon
		if qualityIcon then
			self:SetWndEasyImage(self.mQualityImg,qualityIcon,function() CS.ShowObject(self.mQualityImg,true) end)
		end
	end
	local raceImg = gModelHero:GetRaceImgById(id)
	if not string.isempty(raceImg) then self:SetWndEasyImage(self.mTypeImg,raceImg) end
	local color = gModelHero:GetHeroNameColor(id)
	local name = gModelHero:GetHeroNameById(id)
	if not string.isempty(name) then
		if color then self:SetXUITextColor(self.mHeroName,color) end
		self:SetXUITextText(self.mHeroName,name)
	end
	local careerName,careerImg = gModelHero:GetCareerImgAndNameById(id)
	if not string.isempty(careerName) then self:SetXUITextText(self.mJobName,careerName) end
	if not string.isempty(careerImg) then self:SetWndEasyImage(self.mRaceImg,careerImg) end
	local location = gModelHero:GetLocationById(id)
	if not string.isempty(location) then
		location = "["..location.."]"
		self:SetXUITextText(self.mLocationTxt,location)
	end
	local starTransList = self._starTransList
	for i = 1,#starTransList do
		local trans = starTransList[i]
		CS.ShowObject(trans,false)
	end
	local skin
	local hero = gModelHero:GetHeroServerDataById(id)
	local star
	if hero then
		star = hero.star
		skin = hero.skin
		local showEffId
		if skin and skin > 0 then
			showEffId = skin
		else
			showEffId = gModelHero:GetHeroEffectByRefId(refId,star)
		end
		local effRef = gModelHero:GetShowEffectById(showEffId)
		if effRef then
			local heroBg = effRef.heroBg
			if string.isempty(heroBg) then
				local raceId = gModelHero:GetHeroType(refId)
				if raceId then
					if self._raceId ~= raceId then
						self._raceId = raceId
						local raceRef = gModelHero:GetHeroRaceRefByRefId(raceId)
						if raceRef then
							heroBg = raceRef.heroBg
						end
					end
				end
			end
			self:SetWndEasyImage(self.mHeroBg,heroBg)
		end
		self:SetXUITextText(self.mPowerTxt,LUtil.FormatHurtNumSpriteText(hero.fightPower,false))
		local img,temp = gModelHero:GetHeroStarImg(star)
		for i = 1,temp do
			local trans = starTransList[i]
			self:SetWndEasyImage(trans,img)
			CS.ShowObject(trans,true)
		end
		if not network then
			local lock = hero.lock
			self._lockHero = lock
			local lockImg = "hero_ui_msg_btn_4"
			if lock == 1 then lockImg = "hero_ui_msg_btn_3" end
			self:SetWndEasyImage(self.mLockBtn,lockImg)
		end
	end

	if not network then
		self:ChangeHeroObject(id, refId)
	end
end

function UISagaInfo:InitEvent()
	self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function ()

		--self:WndClose()
	end)
	--self:WndEventRecv(EventNames.CLOSE_CURRENT_WND,function ()
    --
	--	self:WndClose()
	--end)
	self:SetWndClick(self.mSkillShopBtn,function()
		local functionId = gModelRune:GetConfig("talentShopJump")
		gModelFunctionOpen:Jump(functionId)
	end)
	local upOptBtnList = self._upOptBtnList
	for k,v in ipairs(upOptBtnList) do self:SetWndClick(v,function() self:UpOptBtnEvent(k,v) end,LSoundConst.CLICK_PAGE_COMMON) end
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	--self:SetWndClick(self.mShareMask,function() self:OnClickShareMask() end)
	self:SetWndClick(self.mShareBtn,function() self:OnClickShare() end)
	self:SetWndClick(self.mLeftBtn,function() self:CutHero(-1) end)
	self:SetWndClick(self.mRightBtn,function() self:CutHero(1) end)
	self:SetWndClick(self.mPVWBtn,function()
		--GF.OpenWndBottom("UISagaStarPre",{refId = self._refId})
		gModelGeneral:OpenHeroStarPre({refId = self._refId})
	end)
	self:SetWndClick(self.mLockBtn,function()
		local wndId = 10002
		if self._lockHero == 1 then wndId = 10003 end
		local func = function() gModelHero:OnHeroLockReq(self._id,self._lockHero) end
		gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func})
		--local openFunc = function() GF.OpenWnd("UIOrdinTip",{refId = wndId,func = func}) end
		--gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
	end)
	self:SetWndClick(self.mSkinBtn,function()
		gModelGeneral:OpenHeroSkin({refId = self._refId,id = self._id,func = function()
			if not self:IsWndValid() then return end
			if self._isChangeSkin then
				self:RefreshTop()
				self._isChangeSkin = false
			end
		end})
	end)
	self:SetWndClick(self.mStoryBtn,function()
		if self._openStory then
			GF.OpenWnd("UISagaBirth",{refId = self._refId})
		else
			GF.ShowMessage(ccClientText(10058))
		end
	end)
	self:SetWndClick(self.mCommentBtn,function()
	end)
	self:SetWndClick(self.mRebirthBtn,function() self:RebirthEvent() end)
	self:SetWndClick(self.mInfoBtn,function()
		if self._curOptIndex ~= 3 then
			local serverData = gModelHero:GetHeroServerDataById(self._id)
			local career
			if serverData then
				career = gModelHero:GetHeroCareerType(serverData.refId)
			end
			GF.OpenWnd("UISagaAttr",{id = self._id,career = career})
		else
			GF.OpenWnd("UIBzTips",{refId = 27})
		end
	end)
	self:SetWndClick(self.mDressBtn,function()
		if self._showRedPoint then
			local heightEquipList = self._heightEquipList
			if not table.isempty(heightEquipList) then
				--gModelEquip:OnEquipWearReq(self._id,heightEquipList)
				gModelOutfit:OnOutfitWearReq(heightEquipList)
			else
				GF.ShowMessage(ccClientText(11329))
			end
		else
--[[			local curEquipList = self._curEquipList
			if not table.isempty(curEquipList) then gModelEquip:OnEquipUnloadReq(self._id,curEquipList) end]]
			local curOutfitList = self._curOutfitList
			if not table.isempty(curOutfitList) then
				local unloadList = {}
				for k,v in pairs(curOutfitList) do
					table.insert(unloadList,{
						heroId = v.heroId,
						outfitId = v.id,
					})
				end
				gModelOutfit:OnOutfitUnloadReq(unloadList)
			end
		end
	end)
	-- 特殊处理，单击不适用SetWndClick
	self:SetWndClick(self.mOperateBtn.gameObject,function() self:OperateEvent() end)
	-- 长按升级
	self:SetWndLongClick(self.mOperateBtn,function()
		if self._optType == 5 or self._optType == 4 then self:OperateEvent() end
	end,0.2,true)
	self:SetWndClick(self.mQualityImg,function()
		GF.OpenWnd("UISagaQualitySow")
	end)
	self:SetWndClick(self.mTypeImg,function()
		CS.ShowObject(self.mTypeImgMask,true)
		self:ShowRaecKeZhiInfo()
	end)
	self:SetWndClick(self.mTypeImgMask,function() CS.ShowObject(self.mTypeImgMask,false) end)
end

function UISagaInfo:ChangeHeroObject(id, refId)
	local uiHeroObjList = self._uiHeroObjList
	if not uiHeroObjList then
		uiHeroObjList = {}
		self._uiHeroObjList = uiHeroObjList
	end

	if self._uiSkillCtrl then
		self._uiSkillCtrl:Destroy()
		self._uiSkillCtrl = nil
	end

	local pbName = gModelHero:GetHeroPrefabNameById(id)
	if not pbName then
		LogError("---- 没有找到动画")
		pbName = "Jianshi"
	end

	local newUIHeroObj = uiHeroObjList[pbName]

	local oldUIHeroObj = self._curUIHeroObj
	if oldUIHeroObj and newUIHeroObj ~= oldUIHeroObj then
		oldUIHeroObj:ShowHero(false)
	end

	if not newUIHeroObj then

		newUIHeroObj = LUIHeroObject:New(self)
		uiHeroObjList[pbName] = newUIHeroObj
		self._uiCacheHeroCnt = self._uiCacheHeroCnt + 1
		self._curUIHeroObj = newUIHeroObj

		newUIHeroObj:Create(self.mHeroPb,pbName,pbName)
		newUIHeroObj:SetScale(2.5)
		newUIHeroObj:SetClickFunc(function(...) self:OnClickHeroSpine(...) end)
		newUIHeroObj:SetDragFunc(function(...) self:OnDragHeroSpineEnd(...) end )

		newUIHeroObj:SetHeroData(id, refId, nil, nil,true)
		newUIHeroObj:ShowHero(true)
		newUIHeroObj:StartLoad()

		if(self._uiCacheHeroCnt > 15) then
			self:RemoveTheOlderCacheHeroObj(newUIHeroObj)
		end
	else
		self._curUIHeroObj = newUIHeroObj
		newUIHeroObj:SetHeroData(id, refId, nil, nil, true)
		newUIHeroObj:ShowHero(true)
	end

	self:StartHeroObjRunTimer()
end

function UISagaInfo:RefreshItemList()
	if self._isClick then return end
	local refresh = false
	for k,v in pairs(self._payItemList) do
		local nowNum = gModelItem:GetNumByRefId(k)
		if nowNum ~= v then
			refresh = true
			break
		end
	end
	if refresh then
		gModelHero:ClearUpStarSelHeroList()
		self._appointList = {} 																					-- 指定英雄消耗
		self._rangList = {}
		self._rangItemList = {}
		self:RefreshContent(true)
	end
end
------------------------------------------------------------------
return UISagaInfo