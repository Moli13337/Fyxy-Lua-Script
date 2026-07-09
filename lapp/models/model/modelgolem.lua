---
--- Created by #UseName#.
--- DateTime: #DateTime#
---
------------------------------------------------------------------
---模块使用示例 需要在LModelManager的列表里填写名字
---创建完之后可以使用gModelGolem全局变量访问实例
------------------------------------------------------------------
LXImport("..Struct.StructGolemInfo")
LXImport("..Struct.StructGolemLockInfo")

local LModel = LModel
------------------------------------------------------------------
---@class ModelGolem:LModel
local ModelGolem = LxClass("ModelGolem", LModel)

ModelGolem.GolemConfigRef = "GolemConfigRef"


ModelGolem.SHOW_GOLEM_NUM = 4

ModelGolem.FUNCTIONOPEN_ID = 31000003-- 32000001

ModelGolem.GOLEM_SHOW_REFID = 2

--- n件套类型
ModelGolem.ACT_SKILL_NUM_ONE = 1
ModelGolem.ACT_SKILL_NUM_TWO = 2

--- n件套
ModelGolem.SUIT_WEAR_1 = 2
ModelGolem.SUIT_WEAR_2 = 4

ModelGolem.GOLEMDRAWING_CENTER = 0
ModelGolem.GOLEMDRAWING_LEFT = 1
ModelGolem.GOLEMDRAWING_RIGHT = 2

ModelGolem.ATTRSHOWTYPE_ICON = 1
ModelGolem.ATTRSHOWTYPE_SPINE = 2
ModelGolem.ATTRSHOWTYPE_EFFECT = 3

ModelGolem.GOLEMATTR_TYPE_GOLEM = 1				--- 属性请求，魔偶id
ModelGolem.GOLEMATTR_TYPE_HERO = 2				--- 属性请求，英雄id（该英雄佩戴的魔偶属性总和）


ModelGolem.GOLEM_STATUS_LOCK = 1				--- 锁定
ModelGolem.GOLEM_STATUS_UNLOCK = 2				--- 解锁

-------- 魔偶佩戴操作
ModelGolem.OPSTYPE_TYPE_WEAR = 1				--- 穿戴
ModelGolem.OPSTYPE_TYPE_DEMOUNT = 2				--- 卸下
ModelGolem.OPSTYPE_TYPE_REPLACE = 3				--- 替换

---------------------------------------------- 魔偶自动分解
ModelGolem.GOLEM_SMART_DISSOLVE_SEE_TYPE = 1			--- 查看
ModelGolem.GOLEM_SMART_DISSOLVE_SET_TYPE = 2			--- 设置

ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_ENTER = 1			--- 确定分解
ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CANCEL = 2			--- 取消分解

ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CHOOSE1 = 1			--- 1-3星自动分解
ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CHOOSE2 = 2			--- 4星自动分解

ModelGolem.GOLEM_SMART_DISSOLVE_LIST = {
	{
		dissolveType = ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CHOOSE1,
		dissolveStr = ccClientText(33231),
	},
	{
		dissolveType = ModelGolem.GOLEM_SMART_DISSOLVE_TYPE_CHOOSE2,
		dissolveStr = ccClientText(33232),
	},
}
---------------------------------------------- 魔偶自动分解



---------------------------------------------- 仓库界面筛选
ModelGolem.GOLEM_DIV_SORT = 1                    -- 套装
ModelGolem.GOLEM_DIV_SORT_NUM = 1                -- 套装筛选条数


ModelGolem.GOLEM_DIV_ATTR = 2                    -- 属性
ModelGolem.GOLEM_DIV_ATTR_PRIME = 1              -- 主属性
ModelGolem.GOLEM_DIV_ATTR_DEPUTY = 2             -- 副属性
ModelGolem.GOLEM_DIV_ATTR_PRIME_NUM = 1          -- 主属性最多选择数量
ModelGolem.GOLEM_DIV_ATTR_DEPUTY_NUM = 4         -- 副属性最多选择数量


ModelGolem.GOLEM_DIV_STATUS = 3                  -- 排序
ModelGolem.GOLEM_DIV_STATUS_NUM = 1              -- 排序筛选条数


ModelGolem.GOLEM_SORT_LVL = 1			-- 等级
ModelGolem.GOLEM_SORT_GETTIME = 2		-- 入手顺序
ModelGolem.GOLEM_SORT_ATTRTYPE = 3		-- 属性类型
ModelGolem.GOLEM_SORT_STAR = 4			-- 星级
---------------------------------------------- 仓库界面筛选


---------------------------------------------- 强化界面
ModelGolem.TYPE_MATERIAL_ITEM = 1				--- 经验道具
ModelGolem.TYPE_MATERIAL_GOLEM = 2				--- 魔偶
ModelGolem.TYPE_MATERIAL_ITEMGOLEM = 3			--- 魔偶素材，类似于魔偶


--- 0：批量使用
--- 1：为分离出来
ModelGolem.ITEM_USE_TYPE = 1


--- 属性初始化等级
ModelGolem.GOLEM_ATTRGROUP_INIT_LV = 0

--- 魔偶经验已满
ModelGolem.FULL_EXP = -1



---------------------------------------------- 重铸操作
ModelGolem.RECAST_SAVETYPE_CANCEL = 0			--- 取消
ModelGolem.RECAST_SAVETYPE_SAVE = 1				--- 保存


ModelGolem.RECAST_LOCKINFO_NUM = 1				--- 锁定个数

ModelGolem.LOCK_INFO_INDEX_START = 0			--- 锁定位置下标起始



ModelGolem.RECAST_TYPE_BASE = 1             	--- 基础重铸
ModelGolem.RECAST_TYPE_HIGH = 2             	--- 高级重铸

ModelGolem.TYPE_OPT_WEAR = 1					--- 穿戴
ModelGolem.TYPE_OPT_SEL = 2						--- 选择
ModelGolem.TYPE_OPT_CHANGE = 3					--- 切换
ModelGolem.TYPE_OPT_RECAST = 4					--- 重铸



--- 当玩家伙伴魔偶强化选中的魔偶时，切换到单个魔偶强化
ModelGolem.TYPE_GOLEM_USEHEO = 1

------------------------------------------------------------------
function ModelGolem:ModelGolem()
end

--模块初始化入口
--注册事件监听
--注册协议监听
--预处理数据
function ModelGolem:OnModelInit()
	--token_variant_auto_export_resp_recv
	self:ModelNetMsgRecv(LProtoIds.GolemBagResp,function(...) self:OnGolemBagResp(...) end)
	self:ModelNetMsgRecv(LProtoIds.GolemSlotResp,function(...) self:OnGolemSlotResp(...) end)
	self:ModelNetMsgRecv(LProtoIds.GolemWearResp,function(...) self:OnGolemWearResp(...) end)
	self:ModelNetMsgRecv(LProtoIds.GolemStrongResp,function(...) self:OnGolemStrongResp(...) end)
	self:ModelNetMsgRecv(LProtoIds.GolemDissolveResp,function(...) self:OnGolemDissolveResp(...) end)
	self:ModelNetMsgRecv(LProtoIds.GolemAttrResp,function(...) self:OnGolemAttrResp(...) end)
	self:ModelNetMsgRecv(LProtoIds.GolemSmartDissolveResp,function(...) self:OnGolemSmartDissolveResp(...) end)
	self:ModelNetMsgRecv(LProtoIds.GolemLockResp,function(...) self:OnGolemLockResp(...) end)
	self:ModelNetMsgRecv(LProtoIds.GolemRollbackResp,function(...) self:OnGolemRollbackResp(...) end)


	self:ModelEventRecv(EventNames.NET_ERROR_CODE,function (msgId,error)
		if error == 8808 then
			self:OnGolemError8808()
		end
	end)


	self:ModelNetMsgRecv(LProtoIds.GolemRecastResp,function(...) self:OnGolemRecastResp(...) end)
	self:ModelNetMsgRecv(LProtoIds.GolemAttrSaveResp,function(...) self:OnGolemAttrSaveResp(...) end)

	--token_variant_auto_export_resp_recv

	self:InitGolemConfigRef()
	--token_variant_auto_export_ref_init
	--
	self:InitGolemElementRef()
	self:InitGolemSuitRef()
	self:InitGolemAttrRef()
	self:InitGolemLvRef()
	self:InitGolemLocationRef()
	self:InitGolemStarLvRef()

	--token_variant_auto_export_ref_init
end

--在协议数据处理完之后需要调用finish
function ModelGolem:OnModelRequest()
	self:ModelFinish()
end


--------------------------------------------- req ---------------------------------------------
--token_variant_auto_export_req

--- 服务端主动下发
function ModelGolem:OnGolemBagReq()
	local pb = LProtoHelper.CreateProto(LProtoIds.GolemBagReq)
	SendMessage(pb,LProtoIds.GolemBagReq)
end

--- 魔偶槽位信息
function ModelGolem:OnGolemSlotReq(heroId)
	local pb = LProtoHelper.CreateProto(LProtoIds.GolemSlotReq)
	pb.heroId = heroId
	SendMessage(pb,LProtoIds.GolemSlotReq)
end

--- 魔偶佩戴操作
function ModelGolem:OnGolemWearReq(opsType,heroId,golemId)
	local pb = LProtoHelper.CreateProto(LProtoIds.GolemWearReq)
	pb.opsType = opsType
	pb.heroId = heroId
	for i,v in ipairs(golemId) do
		table.insert(pb.golemId,v)
	end
	SendMessage(pb,LProtoIds.GolemWearReq)
end

--- 魔偶强化
function ModelGolem:OnGolemStrongReq(golemId,expItem,consumeGolem)
	local pb = LProtoHelper.CreateProto(LProtoIds.GolemStrongReq)
	pb.golemId = golemId
	if expItem then
		pb.expItem = expItem
	end
	for i,v in ipairs(consumeGolem) do
		table.insert(pb.consumeGolem,v)
	end
	SendMessage(pb,LProtoIds.GolemStrongReq)
end

--- 魔偶分解
function ModelGolem:OnGolemDissolveReq(golemId)
	local pb = LProtoHelper.CreateProto(LProtoIds.GolemDissolveReq)
	for i,v in ipairs(golemId) do
		table.insert(pb.golemId,v)
	end
	SendMessage(pb,LProtoIds.GolemDissolveReq)
end

--- 查看魔偶属性
function ModelGolem:OnGolemAttrReq(type,id)
	local pb = LProtoHelper.CreateProto(LProtoIds.GolemAttrReq)
	pb.type = type
	pb.id = id
	SendMessage(pb,LProtoIds.GolemAttrReq)
end

function ModelGolem:OnGolemSmartDissolveReq(type,choose1,choose2)
	local pb = LProtoHelper.CreateProto(LProtoIds.GolemSmartDissolveReq)
	pb.type = type
	if choose1 then
		pb.choose1 = choose1
	end
	if choose2 then
		pb.choose2 = choose2
	end
	SendMessage(pb,LProtoIds.GolemSmartDissolveReq)
end

--- 魔偶锁定
function ModelGolem:OnGolemLockReq(opsType,golemId)
	local pb = LProtoHelper.CreateProto(LProtoIds.GolemLockReq)
	pb.opsType = opsType
	for i,v in ipairs(golemId) do
		table.insert(pb.golemId,v)
	end
	SendMessage(pb,LProtoIds.GolemLockReq)
end

--token_variant_auto_export_req

--- 魔偶重铸
function ModelGolem:OnGolemRecastReq(golemId,consumeGolemIdList,lockInfosList)
	local pb = LProtoHelper.CreateProto(LProtoIds.GolemRecastReq)
	pb.golemId = golemId
	for i,v in ipairs(consumeGolemIdList) do
		table.insert(pb.consumeGolemId,v)
	end
	local lockInfos = pb.lockInfos
	for i,v in ipairs(lockInfosList) do
		local lockInfo = lockInfos:add()
		lockInfo.attrType = v.attrType
		lockInfo.index = v.index
	end
	SendMessage(pb,LProtoIds.GolemRecastReq)
end

--- 魔偶属性保存
function ModelGolem:OnGolemAttrSaveReq(golemId,saveType)
	local pb = LProtoHelper.CreateProto(LProtoIds.GolemAttrSaveReq)
	pb.golemId = golemId
	pb.saveType = saveType
	SendMessage(pb,LProtoIds.GolemAttrSaveReq)
end

function ModelGolem:OnGolemRollbackReq(id)
	local pb = LProtoHelper.CreateProto(LProtoIds.GolemRollbackReq)
	pb.golemId = id
	SendMessage(pb,LProtoIds.GolemRollbackReq)
end

--------------------------------------------- resp ---------------------------------------------
--token_variant_auto_export_resp

---- 魔偶背包信息（服务端主动下发）
function ModelGolem:OnGolemBagResp(pb,ret)
	local golemList = self._golemList
	if not golemList then
		golemList = {}
		---@type table<string,StructGolemInfo>
		self._golemList = golemList
	end

	local syncType = pb.syncType
	--- 0=所有魔偶，1=刷新部分魔偶，2=新增魔偶，3=移除魔偶
	if syncType == 0 then
		golemList = {}
		self._golemList = golemList
	end

	local golemId,golemData
	local golem = pb.golem
	for i,v in ipairs(golem) do
		golemId = v.id
		if syncType == 2 then
			golemList[golemId] = nil
		else
			golemData = golemList[golemId]
			if not golemData then
				golemData = StructGolemInfo:New()
			end
			golemData:CreateByPb(v)
			golemList[golemId] = golemData
		end
	end
	self._golemList = golemList
end

--- 魔偶槽位界面
function ModelGolem:OnGolemSlotResp(pb,ret)
end

--- 魔偶佩戴
function ModelGolem:OnGolemWearResp(pb,ret)
	local golemId = pb.golemId
	if #golemId < 2 then
		if pb.opsType == ModelGolem.OPSTYPE_TYPE_REPLACE then
			--- 替换
			GF.ShowMessage(ccClientText(34806))
		end
		return
	end
	if pb.opsType == ModelGolem.OPSTYPE_TYPE_WEAR then
		--- 穿戴
		GF.ShowMessage(ccClientText(33294))
	elseif pb.opsType == ModelGolem.OPSTYPE_TYPE_DEMOUNT then
		--- 卸下
		GF.ShowMessage(ccClientText(33295))
	elseif pb.opsType == ModelGolem.OPSTYPE_TYPE_REPLACE then
		--- 替换
		GF.ShowMessage(ccClientText(34806))
	end
end

function ModelGolem:CheckIsLvUp(before,after)
	local beforeLv = self:GetGolemLvlByGolemInfo(before)
	local afterLv = self:GetGolemLvlByGolemInfo(after)
	return beforeLv ~= afterLv
end

--- 魔偶强化
function ModelGolem:OnGolemStrongResp(pb,ret)
	GF.ShowMessage(ccClientText(33275))
--[[	if not self:CheckIsLvUp(pb.before,pb.after) then
		return
	end
	local beforeGolem = self:GetGolemInfoFormPb(pb.before)
	local afterServer = self:GetGolemInfoFormPb(pb.after)
	self:OpenGolemUpLv({
		beforeGolem = beforeGolem,
		laterGolem = afterServer,
	})]]
end

--- 魔偶分解
function ModelGolem:OnGolemDissolveResp(pb,ret)
end

function ModelGolem:OnGolemAttrResp(pb,ret)
	local attrs = pb.attrs
	local attrList = LUtil.ConvertCommonAttrStrToList(attrs)
	if #attrList < 1 then return end
	local type = pb.type
	local id = pb.id
end

--- 魔偶自动分解
function ModelGolem:OnGolemSmartDissolveResp(pb,ret)
	if pb.type == ModelGolem.GOLEM_SMART_DISSOLVE_SET_TYPE then
		--- 设置
	end
end

--- 魔偶锁定
function ModelGolem:OnGolemLockResp(pb,ret)
	if pb.opsType == ModelGolem.GOLEM_STATUS_LOCK then
		--- 锁定
	elseif pb.opsType == ModelGolem.GOLEM_STATUS_UNLOCK then
		--- 解锁
	end
end

function ModelGolem:OnGolemRollbackResp()

end

--token_variant_auto_export_resp

function ModelGolem:OnGolemError8808()
	--gModelGeneral:OpenUIOrdinTips({refId = 310004})
	self:OpenBagFullTips()
end

--- 魔偶重铸
function ModelGolem:OnGolemRecastResp(pb)
	GF.ShowMessage(ccClientText(34826))
end

--- 魔偶属性保存
function ModelGolem:OnGolemAttrSaveResp(pb)
	if pb.saveType == ModelGolem.RECAST_SAVETYPE_CANCEL then
		GF.ShowMessage(ccClientText(34828))
	else
		GF.ShowMessage(ccClientText(34829))
	end
end

--------------------------------------------- initRef ---------------------------------------------
--token_variant_auto_initref
--
function ModelGolem:InitGolemElementRef()
	local initGolemElementRefList = {}
	local initGolemElementSuitList = {}
	local ref = GameTable.GolemElementRef
	local suit,attrGroupId,attrDeputyGroupId
	local attrGroupIdList,attrGroupIdListLen
	local attrDeputyGroupIdList,attrDeputyGroupIdListLen
	for k,v in pairs(ref) do
		suit = v.suit
		attrGroupId = v.attrGroupId
		attrGroupIdList = string.split(attrGroupId,",") or {}
		attrGroupIdListLen = #attrGroupIdList

		attrDeputyGroupId = v.attrDeputyGroupId
		attrDeputyGroupIdList = string.split(attrDeputyGroupId,",") or {}
		attrDeputyGroupIdListLen = #attrDeputyGroupIdList


		local data = {
			refId = v.refId,
			typeBig = v.typeBig,
			tabType = v.tabType,
			order = v.order,
			itemId = v.itemId,
			name = ccLngText(v.name),
			type = ccLngText(v.type),
			lvrGroupId = v.lvrGroupId,
			icon = v.icon,
			golemDrawing = v.golemDrawing,
			quality = v.quality,
			suit = suit,
			attrGroupId = attrGroupId,
			attrDeputyGroupId = attrDeputyGroupId,
			attrDeputyNum = v.attrDeputyNum,
			exp = v.exp,
			jump = v.jump,
			recastConsume = v.recastConsume,
			recastConsumeNoumenon = v.recastConsumeNoumenon,


			---- 数据拆分
			attrGroupIdList = attrGroupIdList,
			attrGroupIdListLen = attrGroupIdListLen,

			attrDeputyGroupIdList = attrDeputyGroupIdList,
			attrDeputyGroupIdListLen = attrDeputyGroupIdListLen,
		}
		initGolemElementRefList[k] = data

		local suitInfoList = initGolemElementSuitList[suit]
		if not suitInfoList then
			suitInfoList = {}
			initGolemElementSuitList[suit] = suitInfoList
		end
		table.insert(suitInfoList,data)
	end
	self._initGolemElementRefList = initGolemElementRefList
	self._initGolemElementSuitList = initGolemElementSuitList
end

function ModelGolem:InitGolemSuitRef()
	local initGolemSuitTypeList = {}
	local initGolemSuitRefList = {}
	local type
	local ref = GameTable.GolemSuitRef
	for k,v in pairs(ref) do
		type = v.type
		local data = {
			refId = v.refId,
			type = type,
			name = ccLngText(v.name),
			sort = v.sort,
			icon = v.icon,
			attr = LUtil.ConvertCommonAttrStrToList(v.attr),
			attrShow = v.attrShow,
			attrShowType = v.attrShowType,
			SkillId = v.SkillId,
			suitText = ccLngText(v.suitText),
			suitText1 = ccLngText(v.suitText1),
			golemDrawing = v.golemDrawing,
			power = v.power,
			showImgPos = v.showImgPos,
			showEffPos = v.showEffPos,
			showSpPos = v.showSpPos,
		}
		initGolemSuitRefList[k] = data

		local initGolemSuitTypeInfoList = initGolemSuitTypeList[type]
		if not initGolemSuitTypeInfoList then
			initGolemSuitTypeInfoList = {}
			initGolemSuitTypeList[type] = initGolemSuitTypeInfoList
		end
		table.insert(initGolemSuitTypeInfoList,data)
	end
	self._initGolemSuitRefList = initGolemSuitRefList
	self._initGolemSuitTypeList = initGolemSuitTypeList
end

function ModelGolem:InitGolemAttrRef()
	local initGolemAttrRefList = {}
	local initGolemAttrGroupIdList = {}
	local ref = GameTable.GolemAttrRef
	local attrGroupId,lv
	for k,v in pairs(ref) do
		attrGroupId = v.attrGroupId
		lv = v.lv
		local data = {
			refId = v.refId,
			attrGroupId = attrGroupId,
			lv = lv,
			attr = LUtil.ConvertCommonAttrStrToList(v.attr),
			rate = v.rate,
			nextAttr = v.nextAttr,

		}
		initGolemAttrRefList[k] = data

		local initGolemAttrGroupIdInfo = initGolemAttrGroupIdList[attrGroupId]
		if not initGolemAttrGroupIdInfo then
			initGolemAttrGroupIdInfo = {}
			initGolemAttrGroupIdList[attrGroupId] = initGolemAttrGroupIdInfo
		end
		initGolemAttrGroupIdInfo[lv] = data
	end
	self._initGolemAttrRefList = initGolemAttrRefList
	self._initGolemAttrGroupIdList = initGolemAttrGroupIdList
end

function ModelGolem:InitGolemLvRef()
	local initGolemLvRefList = {}
	local initGolemLvGroupKeyList = {}
	local initGolemLvGroupMaxLvList = {}
	local lvrGroupId,level,refId,nextLevel,needExp
	local ref = GameTable.GolemLvRef
	for k,v in pairs(ref) do
		lvrGroupId = v.lvrGroupId
		level = v.level
		refId = v.refId
		nextLevel = v.nextLevel
		needExp = v.needExp

		local data = {
			refId = refId,
			lvrGroupId = lvrGroupId,
			level = level,
			nextLevel = nextLevel,
			needExp = needExp,				--- 总经验
			score = v.score,
			consume = LUtil.ConvertCommonItemStrToList(v.consume),
		}
		initGolemLvRefList[k] = data

		local initGolemLvGroupList = initGolemLvGroupKeyList[lvrGroupId]
		if not initGolemLvGroupList then
			initGolemLvGroupList = {}
			initGolemLvGroupKeyList[lvrGroupId] = initGolemLvGroupList
		end
		initGolemLvGroupList[level] = {
			refId = refId,
			lvrGroupId = lvrGroupId,
			nextLevel = nextLevel,
			needExp = needExp,
			score = v.score,
		}

		if not initGolemLvGroupMaxLvList[lvrGroupId] then
			initGolemLvGroupMaxLvList[lvrGroupId] = {
				level = level,
				exp = needExp,
				refId = refId,
				nextLevel = nextLevel,
			}
		elseif initGolemLvGroupMaxLvList[lvrGroupId] and initGolemLvGroupMaxLvList[lvrGroupId].level < level then
			initGolemLvGroupMaxLvList[lvrGroupId].level = level
			initGolemLvGroupMaxLvList[lvrGroupId].exp = needExp
			initGolemLvGroupMaxLvList[lvrGroupId].refId = refId
			initGolemLvGroupMaxLvList[lvrGroupId].nextLevel = nextLevel
		end
	end
	self._initGolemLvRefList = initGolemLvRefList
	self._initGolemLvGroupKeyList = initGolemLvGroupKeyList
	self._initGolemLvGroupMaxLvList = initGolemLvGroupMaxLvList
end

function ModelGolem:InitGolemLocationRef()
	local initGolemLocationSortList = {}

	local initGolemLocationRefList = {}
	local ref = GameTable.GolemLocationRef
	for k,v in pairs(ref) do
		local data = {
			refId = v.refId,
			icon = v.icon,
		}
		initGolemLocationRefList[k] = data

		table.insert(initGolemLocationSortList,data)
	end

	table.sort(initGolemLocationSortList,function(a,b)
		return a.refId < b.refId
	end)
	self._initGolemLocationSortList = initGolemLocationSortList


	self._initGolemLocationRefList = initGolemLocationRefList
end

function ModelGolem:InitGolemStarLvRef()
	local initGolemStarLvRefList = {}
	local initGolemStarLvInfoList = {}
	local ref = GameTable.GolemStarLvRef
	local quality,lvNow
	for k,v in pairs(ref) do
		quality = v.quality
		lvNow = v.lvNow

		local data = {
			refId = v.refId,
			quality = quality,
			lvNow = lvNow,
			attr1Lv = v.attr1Lv,
			attr2Lv = v.attr2Lv,
			attr3Lv = v.attr3Lv,
		}
		initGolemStarLvRefList[k] = data

		local initGolemStarLvInfo = initGolemStarLvInfoList[quality]
		if not initGolemStarLvInfo then
			initGolemStarLvInfo = {}
			initGolemStarLvInfoList[quality] = initGolemStarLvInfo
		end
		initGolemStarLvInfo[lvNow] = data
	end
	self._initGolemStarLvRefList = initGolemStarLvRefList
	self._initGolemStarLvInfoList = initGolemStarLvInfoList
end
--token_variant_auto_initref

function ModelGolem:InitGolemConfigRef()
	local initGolemConfigRefList = {}
	local ref = GameTable.GolemConfigRef

	local attrMap = {}
	local attrList = {}
	local attrKeyList = {}
	local attr = string.split(ref.attr,"|")
	for i,v in ipairs(attr) do
		v = tonumber(v)
		table.insert(attrList,v)
		attrKeyList[v] = v
		attrMap[v] = v
	end
	initGolemConfigRefList.attr = attrList
	initGolemConfigRefList.attrKey = attrKeyList

	local attrDeputyList = {}
	local attrDeputyKeyList = {}
	local attrDeputy = string.split(ref.attrDeputy,"|")
	for i,v in ipairs(attrDeputy) do
		v = tonumber(v)
		table.insert(attrDeputyList,v)
		attrDeputyKeyList[v] = v
		attrMap[v] = v
	end
	initGolemConfigRefList.attrDeputy = attrDeputyList
	initGolemConfigRefList.attrDeputyKey = attrDeputyKeyList

	initGolemConfigRefList.attrMap = attrMap

	local attrShowList = {}
	local attrShowKeyList = {}
	local attrShow = string.split(ref.attrShow,"|")
	for i,v in ipairs(attrShow) do
		v = tonumber(v)
		table.insert(attrShowList,{
			attrRefId = v,
			attrType = 1,
			attrNum = 0,
		})
		attrShowKeyList[v] = v
	end
	initGolemConfigRefList.attrShow = attrShowList
	initGolemConfigRefList.attrShowKey = attrShowKeyList

	local expRestitutionList = {}
	local expRestitutionKeyList = {}
	local expRestitution = string.split(ref.expRestitution,"|")
	local star,ratio
	for i,v in ipairs(expRestitution) do
		v = string.split(v,"=")
		star = tonumber(v[1])
		ratio = tonumber(v[2])
		table.insert(expRestitutionList,{
			star = star,
			ratio = ratio,
		})
		expRestitutionKeyList[star] = ratio
	end
	initGolemConfigRefList.expRestitution = expRestitutionList
	initGolemConfigRefList.expRestitutionKey = expRestitutionKeyList

	self._configExpRestitutionKey = expRestitutionKeyList

	local expSelectList = {}
	local expSelect = string.split(ref.expSelect,"|")
	for i,v in ipairs(expSelect) do
		v = tonumber(v)
		table.insert(expSelectList,{
			intensifyLv = v,
		})
	end
	initGolemConfigRefList.expSelect = expSelectList

	local expSelectGroupList = {}
	local expSelectGroup = string.split(ref.expSelectGroup,"|")
	local lvlGroupId,lvlGroupLvStrList
	for i,v in ipairs(expSelectGroup) do
		v = string.split(v,"=")
		lvlGroupId = tonumber(v[1])
		lvlGroupLvStrList = string.split(v[2],",")
		local lvlGroupLvList = {}
		for idx,val in ipairs(lvlGroupLvStrList) do
			val = tonumber(val)
			table.insert(lvlGroupLvList,{
				intensifyLv = val,
			})
		end
		expSelectGroupList[lvlGroupId] = lvlGroupLvList
	end
	initGolemConfigRefList.expSelectGroup = expSelectGroupList

	local intensifyQualityList = {}
	local intensifyQuality = ref.intensifyQuality
	if not intensifyQuality then
		intensifyQuality = 5
	end
	if type(intensifyQuality) == "string" then
		intensifyQuality = string.split(intensifyQuality,",")
		for i,v in ipairs(intensifyQuality) do
			v = tonumber(v)
			intensifyQualityList[v] = v
		end
	else
		intensifyQualityList[intensifyQuality] = intensifyQuality
	end
	initGolemConfigRefList.intensifyQuality = intensifyQualityList


	local intensifyExpend = string.split(ref.intensifyExpend,"=")
	initGolemConfigRefList.intensifyExpend = {
		itemType = tonumber(intensifyExpend[1]),
		itemId = tonumber(intensifyExpend[2]),
		itemNum = tonumber(intensifyExpend[3]),
	}

	local recasteExpend = LUtil.ConvertCommonItemStrToList(ref.recasteExpend)
	initGolemConfigRefList.recasteExpend = recasteExpend

	self._initGolemConfigRefList = initGolemConfigRefList
end

----- 用于属性key值存储，如果没有数据，再初始化
function ModelGolem:GetGolemAttrKeyByRefId(refId)
	local initGolemAttrKeyMap = self._initGolemAttrKeyMap
	if not initGolemAttrKeyMap then
		initGolemAttrKeyMap = {}
		self._initGolemAttrKeyMap = initGolemAttrKeyMap
	end
	local data = initGolemAttrKeyMap[refId]
	if not data then
		data = {}
		local attrRefId,attrType
		local attr = self:GetGolemAttrAttrListByRefId(refId)
		for i,v in ipairs(attr) do
			attrRefId = v.attrRefId
			attrType = v.attrType
			local attrRefIdList = data[attrRefId]
			if not attrRefIdList then
				attrRefIdList = {}
				data[attrRefId] = attrRefIdList
			end
			local attrTypeNum = attrRefIdList[attrType] or 0
			attrRefIdList[attrType] = attrTypeNum + v.attrNum
		end
		initGolemAttrKeyMap[refId] = data
	end
	return data
end

--------------------------------------------- getPb ---------------------------------------------
function ModelGolem:GetGolemInfoFormPb(pb)
	local golemInfo = StructGolemInfo:New()
	golemInfo:CreateByPb(pb)
	return golemInfo
end

function ModelGolem:GetGolemLockInfoFormPb(pb)
	local golemLockInfo = StructGolemLockInfo:New()
	golemLockInfo:CreateByPb(pb)
	return golemLockInfo
end

function ModelGolem:GetGolemLockInfoFormData(data)
	local golemLockInfo = StructGolemLockInfo:New()
	golemLockInfo:SetData(data)
	return golemLockInfo
end
----------------------------------------- 获取结构数据
function ModelGolem:GetGolemIdByGolemInfo(golemInfo)
	return golemInfo.id
end

function ModelGolem:GetGolemRefIdByGolemInfo(golemInfo)
	return golemInfo.refId
end

function ModelGolem:GetGolemLvlRefIdByGolemInfo(golemInfo)
	return golemInfo.lvlRefId
end

function ModelGolem:GetGolemExpByGolemInfo(golemInfo)
	return golemInfo.exp					--- 拥有的总经验
end

function ModelGolem:GetGolemMainAttrGroupByGolemInfo(golemInfo)
	return golemInfo.mainAttrGroup
end

function ModelGolem:GetGolemViceAttrGroupByGolemInfo(golemInfo)
	return golemInfo.viceAttrGroup
end

function ModelGolem:GetGolemHeroIdByGolemInfo(golemInfo)
	return golemInfo.heroId
end

function ModelGolem:GetGolemLockStateByGolemInfo(golemInfo)
	return golemInfo.lockState
end

function ModelGolem:GetGolemIsLockByGolemInfo(golemInfo)
	return golemInfo.isLock
end

function ModelGolem:GetGolemRecastMainAttrByGolemInfo(golemInfo)
	return golemInfo.recastMainAttr
end

function ModelGolem:GetGolemRecastViceAttrGroupByGolemInfo(golemInfo)
	return golemInfo.recastViceAttrGroup
end

function ModelGolem:GetGolemLockInfoByGolemInfo(golemInfo)
	return golemInfo.lockInfo
end

----------------------------------------- 检查是否穿戴
function ModelGolem:CheckGolemIsWearByGolemInfo(golemInfo)
	return not string.isempty(golemInfo.heroId)
end

function ModelGolem:CheckGolemIsNotWearByGolemInfo(golemInfo)
	return string.isempty(golemInfo.heroId)
end

function ModelGolem:GetGolemAttrListByGolemInfo(attrGroup,showType)
	if not attrGroup then return {} end
	local attrList = {}
	for i,v in ipairs(attrGroup) do
		local attr = self:GetGolemAttrAttrListByRefId(v)
		for idx,val in ipairs(attr) do
			table.insert(attrList,{
				attrRefId = val.attrRefId,
				attrType = val.attrType,
				attrNum = val.attrNum,
				showType = showType,
				golemAttrRefId = v,
			})
		end
	end
	--table.sort(attrList,function(a, b)
	--	local sortA,sortB = self:GetCommonAttrSortFunc(a,b)
	--	return  sortA < sortB
	--end)
	return attrList
end


function ModelGolem:GetGolemMainAttrListByGolemInfo(golemInfo)
	local mainAttrGroup = self:GetGolemMainAttrGroupByGolemInfo(golemInfo)
	return self:GetGolemAttrListByGolemInfo(mainAttrGroup,ModelGolem.GOLEM_DIV_ATTR_PRIME)
end

function ModelGolem:GetGolemViceAttrListByGolemInfo(golemInfo)
	local viceAttrGroup = self:GetGolemViceAttrGroupByGolemInfo(golemInfo)
	return self:GetGolemAttrListByGolemInfo(viceAttrGroup,ModelGolem.GOLEM_DIV_ATTR_DEPUTY)
end

function ModelGolem:GetTwoAttrList(attrList1,attrList2)
	local attrList = {}
	for i,v in ipairs(attrList1) do
		table.insert(attrList,v)
	end
	for i,v in ipairs(attrList2) do
		table.insert(attrList,v)
	end
	return attrList
end

function ModelGolem:GetGolemAllAttrList(golemInfo)
	if not golemInfo then return {} end
	local mainAttrList = self:GetGolemMainAttrListByGolemInfo(golemInfo)
	local viceAttrList = self:GetGolemViceAttrListByGolemInfo(golemInfo)
	return self:GetTwoAttrList(mainAttrList,viceAttrList)
end

function ModelGolem:GetGolemAttrKeyByGolemInfo(golemInfo,attrSelType)
	local attrKeyMap = {}
	local attrGroup
	if attrSelType == ModelGolem.GOLEM_DIV_ATTR_DEPUTY then
		attrGroup = golemInfo.viceAttrGroup 
	elseif attrSelType == ModelGolem.GOLEM_DIV_ATTR_PRIME then
		attrGroup = golemInfo.mainAttrGroup
	end
	local retAttrKeyMap = {}
	for i,v in ipairs(attrGroup) do
		attrKeyMap = self:GetGolemAttrKeyByRefId(v)
		for attrRefId,attrRefIdInfo in pairs(attrKeyMap) do
			retAttrKeyMap[attrRefId] = attrRefIdInfo
		end
	end
	return retAttrKeyMap
end

function ModelGolem:CheckGolemAttrIsHaveRefIdByGolemInfo(golemInfo,keyMap,attrSelType)
	local attrKeyMap = self:GetGolemAttrKeyByGolemInfo(golemInfo,attrSelType)
	for attrRefId,attrRefIdInfo in pairs(attrKeyMap) do
		if keyMap[attrRefId] then
			return true
		end
	end
	return false
end

function ModelGolem:CheckGolemIsOpen(showTip)
	local cfg = GameTable.FeatureOpenRef[ModelGolem.FUNCTIONOPEN_ID]
	return gModelFunctionOpen:CheckIsOpened(ModelGolem.FUNCTIONOPEN_ID,showTip),cfg.show==1
end

function ModelGolem:GetTwoAttrContrastList(attrList1,attrList2)
	local attrKeyList = {}
	local attrRefId,attrType
	local beforeValue,laterValue
	for i,v in ipairs(attrList1) do
		attrRefId = v.attrRefId
		attrType = v.attrType
		local attrRefIdList = attrKeyList[attrRefId]
		if not attrRefIdList then
			attrRefIdList = {}
			attrKeyList[attrRefId] = attrRefIdList
		end
		local attrTypeNumInfo = attrRefIdList[attrType]
		if not attrTypeNumInfo then
			attrTypeNumInfo = {}
			attrRefIdList[attrType] = attrTypeNumInfo
		end
		beforeValue = attrTypeNumInfo.beforeValue or 0
		attrTypeNumInfo.beforeValue = beforeValue + v.attrNum
	end

	for i,v in ipairs(attrList2) do
		attrRefId = v.attrRefId
		attrType = v.attrType
		local attrRefIdList = attrKeyList[attrRefId]
		if not attrRefIdList then
			attrRefIdList = {}
			attrKeyList[attrRefId] = attrRefIdList
		end
		local attrTypeNumInfo = attrRefIdList[attrType]
		if not attrTypeNumInfo then
			attrTypeNumInfo = {}
			attrRefIdList[attrType] = attrTypeNumInfo
			attrTypeNumInfo.beforeValue = 0
		end
		laterValue = attrTypeNumInfo.laterValue or 0
		attrTypeNumInfo.laterValue = laterValue + v.attrNum
	end
	local list = {}
	for tAttrRefId,tAttrRefIdList in pairs(attrKeyList) do
		for tAttrType,tAttrTypeInfo in pairs(tAttrRefIdList) do
			table.insert(list,{
				attrRefId = tAttrRefId,
				attrType = tAttrType,
				beforeValue = tAttrTypeInfo.beforeValue or 0,
				laterValue = tAttrTypeInfo.laterValue or 0,
			})
		end
	end
	table.sort(list,function(a,b)
		local sortA,sortB = self:GetCommonAttrSortFunc(a,b)
		return  sortA < sortB
	end)
	return list
end

function ModelGolem:CheckGolemIsHaveRecastResultByGolemInfo(golemInfo)
	if not golemInfo then return false end
	local recastMainAttr = self:GetGolemRecastMainAttrByGolemInfo(golemInfo)
	local recastViceAttrGroup = self:GetGolemRecastViceAttrGroupByGolemInfo(golemInfo)
	return #recastMainAttr > 0 or #recastViceAttrGroup > 0
end

--- 服务端：魔偶重铸，保存/取消后，锁定信息是清理的
--- 如果有重铸数据，且 GolemInfo 结构中 lockInfo 字段有数据，则可以判断是高级重铸
function ModelGolem:GetGolemUseRecastTypeByGolemInfo(golemInfo)
	if not golemInfo then return end

	if not self:CheckGolemIsHaveRecastResultByGolemInfo(golemInfo) then return end

	local lockInfo = self:GetGolemLockInfoByGolemInfo(golemInfo)
	local isBaseType = #lockInfo < 1
	return isBaseType and ModelGolem.RECAST_TYPE_BASE or ModelGolem.RECAST_TYPE_HIGH
end

--------------------------------------------- getInitRef ---------------------------------------------
function ModelGolem:GetGolemElementConfigRefByRefId(refId)
	--- 配置表数据
	return GameTable.GolemElementRef[refId]
end

function ModelGolem:GetGolemElementConfigOrderByRefId(refId)
	local ref = GameTable.GolemElementRef[refId]
	if not ref then return 1 end
	return ref.order
end

function ModelGolem:GetGolemElementRefByRefId(refId)
	--- 初始化数据
	return self._initGolemElementRefList[refId]
end

function ModelGolem:GetGolemElementSuitListBySuit(suit)
	return self._initGolemElementSuitList[suit]
end

function ModelGolem:GetInitGolemSuitRefList()
	return self._initGolemSuitRefList
end

function ModelGolem:GetGolemSuitRefByRefId(refId)
	return self:GetInitGolemSuitRefList()[refId]
end

function ModelGolem:GetGolemSuitTypeList()
	return self._initGolemSuitTypeList
end

function ModelGolem:GetGolemAttrRefByRefId(refId)
	return self._initGolemAttrRefList[refId]
end

function ModelGolem:GetGolemAttrRefByAttrGroupIdAndLv(attrGroupId,lv)
	if not self._initGolemAttrGroupIdList[attrGroupId] then
		if LOG_INFO_ENABLED then
			printInfoNR("没有这个 attrGroupId = " .. attrGroupId)
		end
		return
	end
	return self._initGolemAttrGroupIdList[attrGroupId][lv]
end

function ModelGolem:GetGolemLvRefByLvRefId(refId)
	return self._initGolemLvRefList[refId]
end

function ModelGolem:GetGolemLvGroupMaxInfoByLvrGroupId(lvrGroupId)
	return self._initGolemLvGroupMaxLvList[lvrGroupId]
end

function ModelGolem:GetGolemLvGroupListByLvrGroupId(lvrGroupId)
	return self._initGolemLvGroupKeyList[lvrGroupId]
end

function ModelGolem:GetGolemLvInfoByLvrGroupIdAndLv(lvrGroupId,lv)
	local golemLvGroupList = self:GetGolemLvGroupListByLvrGroupId(lvrGroupId)
	return golemLvGroupList[lv]
end

function ModelGolem:GetGolemLvNeedExpByLvrGroupIdAndLv(lvrGroupId,lv)
	local info = self:GetGolemLvInfoByLvrGroupIdAndLv(lvrGroupId,lv)
	if not info then return end
	return info.needExp
end

function ModelGolem:GetGolemLocationRefSortList()
	return self._initGolemLocationSortList
end

function ModelGolem:GetGolemLocationRefByRefId(refId)
	return self._initGolemLocationRefList[refId]
end


function ModelGolem:GetGolemStarLvRefByRefId(refId)
	return self._initGolemStarLvRefList[refId]
end

function ModelGolem:GetInitGolemStarLvInfo(quality,lvNow)
	return self._initGolemStarLvInfoList[quality][lvNow]
end

function ModelGolem:GetGolemConfigRefByKey(key)
	if self._initGolemConfigRefList[key] then
		return self._initGolemConfigRefList[key]
	else
		return GameTable.GolemConfigRef[key]
	end
end

function ModelGolem:GetGolemPotency()
	local potency = self:GetGolemConfigRefByKey("potency")
	if not potency then
		if LOG_INFO_ENABLED then
			printInfoNR("暂时还没有配置 potency 字段，使用默认的2")
		end
		potency = ModelGolem.GOLEM_SHOW_REFID
	end
	return potency
end
--------------------------------------------- OpenWnd ---------------------------------------------

function ModelGolem:OpenGolemMain(argList)
	--- 魔偶主界面
	GF.OpenWnd("UIGolemMain",argList)
end

function ModelGolem:OpenGolemWarehouse(argList)
	--- 魔偶仓库
	GF.OpenWnd("UIGolemWarehouse",argList)
end

function ModelGolem:OpenGolemResolve()
	--- 魔偶分解
	GF.OpenWnd("UIGolemResolve")
end
function ModelGolem:OpenGolemResolveNew(argList)
	--- 魔偶分解
	GF.OpenWnd("UIGolemMainWin",argList)
end

function ModelGolem:OpenGolemSwitchHero(argList)
	--- 魔偶切换伙伴
	GF.OpenWnd("UIGolemSwitchHero",argList)
end

function ModelGolem:OpenGolemInfoTip(argList)
	--- 魔偶信息弹窗
	GF.OpenWnd("UIGolemInfoTip",argList)
end

function ModelGolem:OpenGolemIntensify(argList)
	--- 魔偶强化
	GF.OpenWnd("UIGolemMainWin",argList)--WndGolemIntensify
end

function ModelGolem:OpenGolemItemUse(argList)
	--- 魔偶道具使用弹窗
	GF.OpenWnd("UIGolemItemUse",argList)
end

function ModelGolem:OpenGolemUpLv(argList)
	--- 魔偶升级成功弹窗
	GF.OpenWnd("UIGolemUpLv",argList)
end

function ModelGolem:OpenGolemHeroAttrShow(argList)
	--- 魔偶英雄属性弹窗
	GF.OpenWnd("UIGolemHeroAttrShow",argList)
end

function ModelGolem:OpenGolemRecommend(argList)
	--- 魔偶推荐
	GF.OpenWnd("UIGolemRecommend",argList)
end

function ModelGolem:OpenGolemWear(argList)
	--- 魔偶装备
	GF.OpenWnd("UIGolemWear",argList)
end

function ModelGolem:OpenGolemItemUseAuto(argList)
	--- 魔偶一键选择
	GF.OpenWnd("UIGolemItemUseAuto",argList)
end

function ModelGolem:OpenGolemRecast(argList)
	--- 魔偶重铸
	GF.OpenWnd("UIGolemMainWin",argList)--WndGolemRecast
end

function ModelGolem:OpenGolemPreviewAttr(argList)
	--- 魔偶重铸
	GF.OpenWnd("UIGolemPreviewAttr",argList)
end

--------------------------------------------- getRef ---------------------------------------------

-------------------------------------------------------- GolemElementRef
function ModelGolem:GetGolemElementSuitByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.suit
end

function ModelGolem:GetGolemElementTypeByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.type
end

function ModelGolem:GetGolemElementSuitByGolemInfo(golemInfo)
	if not golemInfo then return end
	local refId = golemInfo.refId
	if not refId then return end
	return self:GetGolemElementSuitByRefId(refId)
end

function ModelGolem:GetGolemElementIconByRefId(refId)
	local ref = self:GetGolemRefIdByGolemInfo(refId)
	if not ref then return end
	return ref.icon
end

function ModelGolem:GetGolemElementIconAndIconBgByRefId(refId)
	local icon = self:GetGolemElementIconByRefId(refId)
	local quality = self:GetGolemElementQualityByRefId(refId)
	local iconBg = gModelItem:GetIconBgByQualityId(quality)
	return icon,iconBg
end

function ModelGolem:GetGolemElementNameByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.name
end

function ModelGolem:GetGolemElementNameByGolemInfo(golemInfo)
	if not golemInfo then return end
	local refId = golemInfo.refId
	if not refId then return end
	return self:GetGolemElementNameByRefId(refId)
end

function ModelGolem:GetGolemElementColorByRefId(refId)
	local quality = self:GetGolemElementQualityByRefId(refId)
	return gModelItem:GetColorByQualityId(quality,true)
end

function ModelGolem:GetGolemElementColorByGolemInfo(golemInfo)
	if not golemInfo then return end
	local refId = golemInfo.refId
	return self:GetGolemElementColorByRefId(refId)
end

-- quality字段是星级&品质，以防万一，后面拆成2个字段，直接分开写，获取品质
function ModelGolem:GetGolemElementQualityByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.trueQuality or ref.quality
end

-- quality字段是星级&品质，以防万一，后面拆成2个字段，直接分开写，获取星级
function ModelGolem:GetGolemElementStarByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.quality
end

function ModelGolem:GetGolemElementStarByGolemInfo(golemInfo)
	if not golemInfo then return end
	local refId = golemInfo.refId
	return self:GetGolemElementStarByRefId(refId)
end

function ModelGolem:GetGolemElementLvrGroupIdByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.lvrGroupId
end

function ModelGolem:GetGolemElementLvrGroupIdByGolemInfo(golemInfo)
	if not golemInfo then return end
	local refId = golemInfo.refId
	return self:GetGolemElementLvrGroupIdByRefId(refId)
end

function ModelGolem:GetGolemElementGolemDrawingByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.golemDrawing
end

function ModelGolem:GetGolemElementAttrDeputyNumByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.attrDeputyNum
end

function ModelGolem:GetGolemElementAttrDeputyNumByGolemInfo(golemInfo)
	local refId = golemInfo.refId
	return self:GetGolemElementAttrDeputyNumByRefId(refId)
end



function ModelGolem:GetGolemElementGolemDrawingByGolemInfo(golemInfo)
	if not golemInfo then return end
	local refId = golemInfo.refId
	return self:GetGolemElementGolemDrawingByRefId(refId)
end

function ModelGolem:GetGolemElementGolemDrawingIconByRefId(refId)
	local golemDrawing = self:GetGolemElementGolemDrawingByRefId(refId)
	if not golemDrawing then return end
	return self:GetGolemLocationIconByRefId(golemDrawing)
end

function ModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(golemInfo)
	if not golemInfo then return end
	local refId = golemInfo.refId
	return self:GetGolemElementGolemDrawingIconByRefId(refId)
end


function ModelGolem:GetGolemElementExpByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.exp
end


function ModelGolem:GetGolemElementExpByGolemInfo(golemInfo)
	local refId = golemInfo.refId
	return self:GetGolemElementExpByRefId(refId)
end

function ModelGolem:GetGolemElementItemIdByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.itemId
end

function ModelGolem:GetGolemElementTypeBigByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.typeBig
end

function ModelGolem:GetGolemElementTypeBigByGolemInfo(golemInfo)
	if not golemInfo then return end
	local refId = golemInfo.refId
	return self:GetGolemElementTypeBigByRefId(refId)
end

function ModelGolem:GetGolemElementRecastConsumeByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.recastConsume
end

function ModelGolem:GetGolemElementRecastConsumeNoumenonByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.recastConsumeNoumenon
end

function ModelGolem:GetGolemRecastConsumeNumByGolemInfo(golemInfo,recastType)
	if not golemInfo then return end
	local refId = golemInfo.refId
	if recastType == ModelGolem.RECAST_TYPE_BASE then
		local recastConsume = self:GetGolemElementRecastConsumeByRefId(refId)
		if not recastConsume then
			if LOG_INFO_ENABLED then
				printInfoNR("打印而已，莫慌  recastConsume 字段不存在，默认1")
			end
			recastConsume = 1
		end
		return recastConsume
	else
		local recastConsumeNoumenon = self:GetGolemElementRecastConsumeNoumenonByRefId(refId)
		if not recastConsumeNoumenon then
			if LOG_INFO_ENABLED then
				printInfoNR("打印而已，莫慌  recastConsumeNoumenon 字段不存在，默认1")
			end
			recastConsumeNoumenon = 1
		end
		return recastConsumeNoumenon
	end
end

function ModelGolem:GetGolemElementAttrGroupIdByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.attrGroupId
end

function ModelGolem:GetGolemElementattrGroupIdListByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.attrGroupIdList
end

function ModelGolem:GetGolemElementattrDeputyGroupIdListListByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.attrDeputyGroupIdList
end

function ModelGolem:GetGolemElementAttrGroupIdListLenByRefId(refId)
	local ref = self:GetGolemElementRefByRefId(refId)
	if not ref then return end
	return ref.attrGroupIdListLen
end

function ModelGolem:GetGolemElementAttrGroupIdListLenByGolemInfo(golemInfo)
	if not golemInfo then return 0 end

	local refId = golemInfo.refId
	if not refId then return 0 end

	local attrGroupIdListLen = self:GetGolemElementAttrGroupIdListLenByRefId(refId) or 0
	return attrGroupIdListLen
end

-------------------------------------------------------- GolemSuitRef
function ModelGolem:GetGolemSuitNameByRefId(refId)
	local ref = self:GetGolemSuitRefByRefId(refId)
	if not ref then return end
	return ref.name
end

function ModelGolem:GetGolemSuitNameByGolemInfo(golemInfo)
	local golemElementSuit = self:GetGolemElementSuitByGolemInfo(golemInfo)
	if not golemElementSuit then return end
	return self:GetGolemSuitNameByRefId(golemElementSuit)
end

function ModelGolem:GetGolemSuitIconByRefId(refId)
	local ref = self:GetGolemSuitRefByRefId(refId)
	if not ref then return end
	return ref.icon
end

function ModelGolem:GetGolemSuitIconByGolemInfo(golemInfo)
	local golemElementSuit = self:GetGolemElementSuitByGolemInfo(golemInfo)
	if not golemElementSuit then return end
	return self:GetGolemSuitIconByRefId(golemElementSuit)
end

function ModelGolem:GetGolemSuitSuitTextByRefId(refId)
	local ref = self:GetGolemSuitRefByRefId(refId)
	if not ref then return end
	local suitText = ref.suitText
	return suitText
end

function ModelGolem:GetGolemSuitSuitText1ByRefId(refId)
	local ref = self:GetGolemSuitRefByRefId(refId)
	if not ref then return end
	local suitText1 = ref.suitText1
	return suitText1
end

function ModelGolem:GetGolemSuitSuitTextAndSuitText1ByRefId(refId)
	local suitText = self:GetGolemSuitSuitTextByRefId(refId)
	local suitText1 = self:GetGolemSuitSuitText1ByRefId(refId)
	return suitText,suitText1
end

function ModelGolem:GetGolemSuitSuitTextAndSuitText1ByGolemInfo(golemInfo)
	if not golemInfo then return "","" end

	local suit = self:GetGolemElementSuitByGolemInfo(golemInfo)
	if not suit then return "","" end

	return self:GetGolemSuitSuitTextAndSuitText1ByRefId(suit)
end

function ModelGolem:GetGolemSuitAttrShowByRefId(refId)
	local ref = self:GetGolemSuitRefByRefId(refId)
	if not ref then return end
	return ref.attrShow
end

function ModelGolem:GetGolemSuitAttrShowTypeByRefId(refId)
	local ref = self:GetGolemSuitRefByRefId(refId)
	if not ref then return end
	return ref.attrShowType
end

function ModelGolem:GetGolemSuitAttrShowType4ByRefId(refId)
	local ref = self:GetGolemSuitRefByRefId(refId)
	if not ref then return end
	return ref.attrShowType4
end

function ModelGolem:GetGolemSuitGolemDrawingByRefId(refId)
	local ref = self:GetGolemSuitRefByRefId(refId)
	if not ref then return end
	return ref.golemDrawing
end


function ModelGolem:GetGolemSuitTypeNameByType(type)
	local initGolemSuitTypeList = self:GetGolemSuitTypeList()
	local initGolemSuitTypeInfoList = initGolemSuitTypeList[type]
	if not initGolemSuitTypeInfoList then return end
	if #initGolemSuitTypeInfoList < 1 then return end
	local first = initGolemSuitTypeInfoList[1]
	return first.name
end

function ModelGolem:GetGolemSuitShowPosByRefId(refId)
	local ref = self:GetGolemSuitRefByRefId(refId)
	if not ref then return "0,0" end
	local attrShowType = self:GetGolemSuitAttrShowTypeByRefId(refId)
	local showPos
	if attrShowType == ModelGolem.ATTRSHOWTYPE_ICON then
		showPos = ref.showImgPos
		if not showPos then
			if LOG_INFO_ENABLED then
				printInfoNR("如果图片类型显示位置不对，可以根据 showImgPos 字段， 为空为默认 0,0")
			end
		end
	elseif attrShowType == ModelGolem.ATTRSHOWTYPE_SPINE then
		showPos = ref.showSpPos
		if not showPos then
			if LOG_INFO_ENABLED then
				printInfoNR("如果 Spine 类型显示位置不对，可以根据 showSpPos 字段， 为空为默认 0,0")
			end
		end
	elseif attrShowType == ModelGolem.ATTRSHOWTYPE_EFFECT then
		showPos = ref.showEffPos
		if not showPos then
			if LOG_INFO_ENABLED then
				printInfoNR("如果 Effect 类型显示位置不对，可以根据 showEffPos 字段， 为空为默认 0,0")
			end
		end
	end
	if not showPos then
		showPos = "0,0"
	end
	return showPos
end
-------------------------------------------------------- GolemAttrRef
function ModelGolem:GetGolemAttrAttrListByRefId(refId)
	local ref = self:GetGolemAttrRefByRefId(refId)
	if not ref then return {} end
	return ref.attr
end

function ModelGolem:GetGolemAttrAttrGroupIdByRefId(refId)
	local ref = self:GetGolemAttrRefByRefId(refId)
	if not ref then return {} end
	return ref.attrGroupId
end

function ModelGolem:GetGolemAttrLvByRefId(refId)
	local ref = self:GetGolemAttrRefByRefId(refId)
	if not ref then return end
	return ref.lv
end


-------------------------------------------------------- GolemLvRef
function ModelGolem:GetGolemScoreByLevelRefId(lvlRefId)
	local ref = self:GetGolemLvRefByLvRefId(lvlRefId)
	if not ref then return end
	return ref.score
end

function ModelGolem:GetGolemScoreByGolemInfo(golemInfo)
	local lvlRefId = self:GetGolemLvlRefIdByGolemInfo(golemInfo)
	return self:GetGolemScoreByLevelRefId(lvlRefId)
end

function ModelGolem:GetGolemNextLevelByLevelRefId(lvlRefId)
	local ref = self:GetGolemLvRefByLvRefId(lvlRefId)
	if not ref then return end
	return ref.nextLevel
end

function ModelGolem:GetGolemNeedExpByLevelRefId(lvlRefId)
	local ref = self:GetGolemLvRefByLvRefId(lvlRefId)
	if not ref then return end
	return ref.needExp
end

function ModelGolem:GetGolemLvByLevelRefId(lvlRefId)
	local ref = self:GetGolemLvRefByLvRefId(lvlRefId)
	if not ref then return end
	return ref.level
end

function ModelGolem:GetGolemLvlByGolemInfo(golemInfo)
	local lvlRefId = self:GetGolemLvlRefIdByGolemInfo(golemInfo)
	return self:GetGolemLvByLevelRefId(lvlRefId)
end

function ModelGolem:GetGolemConsumeByLevelRefId(lvlRefId)
	local ref = self:GetGolemLvRefByLvRefId(lvlRefId)
	if not ref then return end
	return ref.consume
end

function ModelGolem:GetGolemConsumeByGolemInfo(golemInfo)
	local lvlRefId = self:GetGolemLvlRefIdByGolemInfo(golemInfo)
	return self:GetGolemConsumeByLevelRefId(lvlRefId)
end

function ModelGolem:GetGolemNextLevelRefIdByGolemInfo(golemInfo)
	local curlvlRefId = self:GetGolemLvlRefIdByGolemInfo(golemInfo)
	return self:GetGolemNextLevelByLevelRefId(curlvlRefId)
end

function ModelGolem:GetGolemNextLevelRefByGolemInfo(golemInfo)
	local nextLevel = self:GetGolemNextLevelRefIdByGolemInfo(golemInfo)
	return self:GetGolemLvRefByLvRefId(nextLevel)
end
-------------------------------------------------------- GolemLocationRef
function ModelGolem:GetGolemLocationIconByRefId(refId)
	local ref = self:GetGolemLocationRefByRefId(refId)
	if not ref then return end
	return ref.icon
end


--------------------------------------------- checkFunc ---------------------------------------------
function ModelGolem:CheckGolemActStatus(wearList)

end


--------------------------------------------- getServerData ---------------------------------------------
---
function ModelGolem:GetGolemList()
	return self._golemList or {}
end

--- 魔偶数据
function ModelGolem:GetGolemServerDataById(id)
	local golemList = self:GetGolemList()
	if not golemList then return end
	return golemList[id]
end

--- 激活套装列表，有{4件套}，{2件套,2件套}，{2件套}，{}的情况
function ModelGolem:GetGolemActSuitList(wearList)
	local suitTypeNumList = {}
	local suit
	for index,serverData in pairs(wearList) do
		suit = self:GetGolemElementSuitByGolemInfo(serverData)
		if suit then
			local skillNum = suitTypeNumList[suit] or 0
			suitTypeNumList[suit] = skillNum + 1
		end
	end
	local actSuitIdList = {}
	for suitType,suitNum in pairs(suitTypeNumList) do
		if suitNum >= ModelGolem.SUIT_WEAR_2 then
			table.insert(actSuitIdList,{
				suitRefId = suitType,
				actNum = suitNum,
				actType = ModelGolem.ACT_SKILL_NUM_TWO,
			})
		elseif suitNum >= ModelGolem.SUIT_WEAR_1 then
			table.insert(actSuitIdList,{
				suitRefId = suitType,
				actNum = suitNum,
				actType = ModelGolem.ACT_SKILL_NUM_ONE,
			})
		end
	end
	return actSuitIdList
end

--- 激活套装列表，有{4件套拆分成2个2件套}，{2件套,2件套}，{2件套}，{}的情况
function ModelGolem:GetGolemShowActSuitList(wearList)
    local actSuitList = self:GetGolemActSuitList(wearList)
	local showTypeList = {}
	local actType
	for i,v in ipairs(actSuitList) do
		actType = v.actType
		if actType == ModelGolem.ACT_SKILL_NUM_TWO then
			for idx = 1,2 do
				table.insert(showTypeList,{
					suitRefId = v.suitRefId,
					actNum = v.actNum,
					actType = actType,
				})
			end
		elseif actType == ModelGolem.ACT_SKILL_NUM_ONE then
			table.insert(showTypeList,{
				suitRefId = v.suitRefId,
				actNum = v.actNum,
				actType = actType,
			})
		end
	end
	return showTypeList
end

--- 套装显示列表
function ModelGolem:GetGolemActSuitShowList(wearList)
	if not wearList then return {} end
	local showList = {}
	local actType,suitTxt,showNumTxt,suitRefId
	local actSuitIdList = self:GetGolemActSuitList(wearList)
	for i,v in ipairs(actSuitIdList) do
		actType = v.actType
		suitRefId = v.suitRefId
		if actType == ModelGolem.ACT_SKILL_NUM_TWO then
			local icon = self:GetGolemSuitIconByRefId(suitRefId)
			local name = self:GetGolemSuitNameByRefId(suitRefId)
			suitTxt = self:GetGolemSuitSuitTextByRefId(suitRefId)
			showNumTxt = string.replace(ccClientText(33227),ModelGolem.SUIT_WEAR_1)
			table.insert(showList,{
				suitTxt = suitTxt,
				showNumTxt = showNumTxt,
				icon = icon,
				name = name,
				isAct = true
			})

			suitTxt = self:GetGolemSuitSuitText1ByRefId(suitRefId)
			showNumTxt = string.replace(ccClientText(33227),ModelGolem.SUIT_WEAR_2)
			table.insert(showList,{
				suitTxt = suitTxt,
				showNumTxt = showNumTxt,
				icon = icon,
				name = name,
				isAct = true,
			})
		elseif actType == ModelGolem.ACT_SKILL_NUM_ONE then
			suitTxt = self:GetGolemSuitSuitTextByRefId(suitRefId)
			showNumTxt = string.replace(ccClientText(33227),ModelGolem.SUIT_WEAR_1)
			table.insert(showList,{
				suitTxt = suitTxt,
				showNumTxt = showNumTxt,
				icon = self:GetGolemSuitIconByRefId(suitRefId),
				name = self:GetGolemSuitNameByRefId(suitRefId),
				isAct = true,
			})
			--table.insert(showList,{
			--	isAct = false,
			--	notAct = ccClientText(33272),
			--})
		end
	end
	if #showList < 1 then
		table.insert(showList,{
			isAct = false,
			notAct = ccClientText(33261),
		})
	end
	if #showList < 2 then
		table.insert(showList,{
			isAct = false,
			notAct = ccClientText(33272),
		})
	end
	return showList
end

function ModelGolem:GetGolemSuitList()
	local initGolemSuitTypeList = self:GetGolemSuitTypeList()
	local suitTypeList = {}
	for golemSuitType,golemSuitTypeList in pairs(initGolemSuitTypeList) do
		for idx,val in ipairs(golemSuitTypeList) do
			table.insert(suitTypeList,{
				refId = val.refId,
				name = val.name,
				sort = val.sort,
				type = golemSuitType,
			})
		end
	end
	table.sort(suitTypeList,function(a,b)
		return a.sort < b.sort
	end)
	return suitTypeList
end

--- 仓库的套装，使用套装表的type字段筛选，防止万一，加个字段判断，有可能是靠refId进行
function ModelGolem:GetWarehouseSuitTypeStatus()
	local suitTypeSort = self:GetGolemConfigRefByKey("suitTypeSort")
	if not suitTypeSort then
		--- 默认是type ， 0
		suitTypeSort = 0
	end
	return suitTypeSort
end

function ModelGolem:GetWarehouseSuitTypeKey(data)
	local suitTypeSort = self:GetWarehouseSuitTypeStatus()
	if suitTypeSort == 0 then
		return data.type
	elseif suitTypeSort == 1 then
		return data.refId
	end
end

--- 获取所有的部位的魔偶数据
function ModelGolem:GetAllGolemListByGolemDrawing(needGolemDrawing,notAddId)
	local golemList = self:GetGolemList()
	if not golemList then return {} end
	local list = {}
	local golemDrawing
	for golemId,golemInfo in pairs(golemList) do
		golemDrawing = self:GetGolemElementGolemDrawingByGolemInfo(golemInfo)
		if golemDrawing == needGolemDrawing then
			if not notAddId then
				table.insert(list,golemInfo)
			else
				if golemId ~= notAddId then
					table.insert(list,golemInfo)
				end
			end
		end
	end
	return list
end

--- 获取背包部位的魔偶数据
function ModelGolem:GetBagGolemListByGolemDrawing(needGolemDrawing)
	local golemList = self:GetGolemList()
	if not golemList then return {} end
	local list = {}
	local isInBag
	local golemDrawing
	for golemId,golemInfo in pairs(golemList) do
		isInBag = self:CheckGolemIsNotWearByGolemInfo(golemInfo)
		if isInBag then
			golemDrawing = self:GetGolemElementGolemDrawingByGolemInfo(golemInfo)
			if golemDrawing == needGolemDrawing then
				table.insert(list,golemInfo)
			end
		end
	end
	return list
end

--- 获取套装的魔偶数据
function ModelGolem:GetBagGolemListByGolemSuitId(needSuitId)
	local golemList = self:GetGolemList()
	if not golemList then return {} end
	local list = {}
	local isInBag
	local suit
	for golemId,golemInfo in pairs(golemList) do
		isInBag = self:CheckGolemIsNotWearByGolemInfo(golemInfo)
		if isInBag then
			suit = self:GetGolemElementSuitByGolemInfo(golemInfo)
			if suit == needSuitId then
				table.insert(list,golemInfo)
			end
		end
	end
	return list
end

function ModelGolem:GetBagGolemListByStar(needStar)
	local golemList = self:GetGolemList()
	if not golemList then return {} end
	local list = {}
	local isInBag
	local star
	for golemId,golemInfo in pairs(golemList) do
		isInBag = self:CheckGolemIsNotWearByGolemInfo(golemInfo)
		if isInBag then
			star = self:GetGolemElementStarByGolemInfo(golemInfo)
			if star == needStar then
				table.insert(list,golemInfo)
			end
		end
	end
	return list
end

---- 获取背包魔偶数据
function ModelGolem:GetGolemBagList(extraData)
	local golemList = self:GetGolemList()
	if not golemList then return {} end
	extraData = extraData or {}
	local needGolemDrawing = extraData.needGolemDrawing or -1--槽位
	local needGolemSuitId = extraData.needGolemSuitId or -1
	if needGolemDrawing > 0 then
		return self:GetBagGolemListByGolemDrawing(needGolemDrawing)
	elseif needGolemSuitId > 0 then
		return self:GetBagGolemListByGolemSuitId(needGolemSuitId)
	else
		local excludeMap = extraData.excludeMap or {}
		local list = {}
		local isInBag
		for golemId,golemInfo in pairs(golemList) do
			isInBag = self:CheckGolemIsNotWearByGolemInfo(golemInfo)
			if isInBag and not excludeMap[golemId] then
				table.insert(list,golemInfo)
			end
		end
		return list
	end
end

function ModelGolem:GetCommonAttrSortFunc(a,b)
	local attrRefIdA,attrRefIdB	 = a.attrRefId,b.attrRefId
	local attrTypeA,attrTypeB = a.attrType,b.attrType
	local sortA
	if attrTypeA == 1 then
		sortA = gModelHero:GetAttributeSortById(attrRefIdA)
	elseif attrTypeA == 2 then
		sortA = gModelHero:GetAttributeSort2ById(attrRefIdA)
	end
	local sortB
	if attrTypeB == 1 then
		sortB = gModelHero:GetAttributeSortById(attrRefIdB)
	elseif attrTypeB == 2 then
		sortB = gModelHero:GetAttributeSort2ById(attrRefIdB)
	end
	return  sortA , sortB
end

--- 排序筛选
function ModelGolem:GetSortAttrByGolemList(golemList,onlySortMainGroup,extraMap)
	if not golemList then return {} end
	extraMap = extraMap or {}

	local attrSortFunc = function(a,b)
		local sortA,sortB = self:GetCommonAttrSortFunc(a,b)
		return  sortA , sortB
	end

	---  先做主属性类型
	table.sort(golemList,function(a,b)
		local idA,idB = a.id,b.id
		if idA and idB then
			local extraStatusA = extraMap[idA] and 1 or 0
			local extraStatusB = extraMap[idB] and 1 or 0
			if extraStatusA ~= extraStatusB then
				return extraStatusA > extraStatusB
			end
		end
		local mainAttrGroupNumA,mainAttrGroupNumB = a.mainAttrGroupNum,b.mainAttrGroupNum
		if mainAttrGroupNumA ~= mainAttrGroupNumB then return mainAttrGroupNumA >mainAttrGroupNumB end
		local mainAttrListA,mainAttrListB = a.mainAttrList,b.mainAttrList
		local firstA = mainAttrListA[1]
		local firstB = mainAttrListB[1]
		local sortA,sortB = attrSortFunc(firstA,firstB)
		if sortA ~= sortB then return sortA < sortB end
		return firstA.attrNum > firstB.attrNum
	end)

	if not onlySortMainGroup then
		--- 再做副属性类型
		table.sort(golemList,function(a,b)
			local idA,idB = a.id,b.id
			if idA and idB then
				local extraStatusA = extraMap[idA] and 1 or 0
				local extraStatusB = extraMap[idB] and 1 or 0
				if extraStatusA ~= extraStatusB then
					return extraStatusA > extraStatusB
				end
			end
			local viceAttrGroupNumA,viceAttrGroupNumB = a.viceAttrGroupNum,b.viceAttrGroupNum
			if viceAttrGroupNumA ~= viceAttrGroupNumB then return viceAttrGroupNumA > viceAttrGroupNumB end
			local viceAttrListA,viceAttrListB = a.viceAttrList,b.viceAttrList
			for i = 1,viceAttrGroupNumA do
				local dataA = viceAttrListA[i]
				local dataB = viceAttrListB[i]
				local sortA,sortB = attrSortFunc(dataA,dataB)
				if sortA ~= sortB then return sortA < sortB end
				local attrNumA,attrNumB = dataA.attrNum,dataB.attrNum
				if attrNumA ~= attrNumB then return attrNumA > attrNumB end
			end
			return a.numId < b.numId
		end)
	end

	return golemList
end

function ModelGolem:GetGetTimeSortGolemList(allGolemList,useToNum,extraMap)
	extraMap = extraMap or {}
	if useToNum then
		table.sort(allGolemList,function(a,b)
			local idA,idB = a.id,b.id
			if idA and idB then
				local extraStatusA = extraMap[idA] and 1 or 0
				local extraStatusB = extraMap[idB] and 1 or 0
				if extraStatusA ~= extraStatusB then
					return extraStatusA > extraStatusB
				end
			end
			return tonumber(idA) > tonumber(idB)
		end)
	else
		table.sort(allGolemList,function(a,b)
			local idA,idB = a.id,b.id
			if idA and idB then
				local extraStatusA = extraMap[idA] and 1 or 0
				local extraStatusB = extraMap[idB] and 1 or 0
				if extraStatusA ~= extraStatusB then
					return extraStatusA > extraStatusB
				end
			end
			return a.numId > b.numId
		end)
	end
end

function ModelGolem:GetStarSortGolemList(allGolemList)
	table.sort(allGolemList,function(a,b)
		local starA,starB = a.star,b.star
		if starA ~= starB then return starA < starB end
	end)
end

function ModelGolem:GetLvlSortGolemList(allGolemList,extraMap)
	extraMap = extraMap or {}
	table.sort(allGolemList,function(a,b)
		local idA,idB = a.id,b.id
		if idA and idB then
			local extraStatusA = extraMap[idA] and 1 or 0
			local extraStatusB = extraMap[idB] and 1 or 0
			if extraStatusA ~= extraStatusB then
				return extraStatusA > extraStatusB
			end
		end
		local lvlA,lvlB = a.lvl,b.lvl
		if lvlA ~= lvlB then return lvlA > lvlB end
		local starA,starB = a.star,b.star
		if starA ~= starB then return starA > starB end
		local wearStatusA,wearStatusB = a.wearStatus,b.wearStatus
		if wearStatusA ~= wearStatusB then return wearStatusA > wearStatusB end
		return a.numId < b.numId
	end)
end

--- 通用的排序
function ModelGolem:GetGeneralSortGolemList(allGolemList)
--[[	table.sort(allGolemList,function(a,b)
		local starA,starB = a.star,b.star
		if starA and starB then
			if starA ~= starB then return starA > starB end
		end

		local wearStatusA,wearStatusB = a.wearStatus,b.wearStatus
		if wearStatusA ~= wearStatusB then return wearStatusA > wearStatusB end
		local lvlA,lvlB = a.lvl,b.lvl
		if lvlA ~= lvlB then return lvlA > lvlB end
		return a.numId < b.numId
	end)]]

--[[	----- 文档修改排序
	----- 魔偶经验高优先排序
	----- 魔偶本体星级低的优先排序
	----- 魔偶本体等级低的优先展示
	----- 根据魔偶的ID顺序由小到大排列
	----- 最后排列已装备魔偶
	table.sort(allGolemList,function(a,b)
		local expA,expB = a.exp,b.exp
		if expA ~= expB then return expA > expB end
		local starA,starB = a.star,b.star
		if starA ~= starB then return starA < starB end
		local lvlA,lvlB = a.lvl,b.lvl
		if lvlA ~= lvlB then return lvlA < lvlB end
		return a.numId < b.numId
	end)]]

--[[	----- 2023/2/20 修改
	----- 初始等级魔偶经验高优先排序
	----- 魔偶本体星级低的优先排序
	----- 魔偶本体等级低的优先展示
	----- 根据魔偶的ID顺序由小到大排列
	----- 最后排列已装备魔偶
	table.sort(allGolemList,function(a,b)
		local initExpA,initExpB = a.initExp,b.initExp
		if not initExpA then
			initExpA = self:GetGolemElementExpByRefId(self:GetGolemRefIdByGolemInfo(a))
		end
		if not initExpB then
			initExpB = self:GetGolemElementExpByRefId(self:GetGolemRefIdByGolemInfo(b))
		end
		if initExpA and initExpB then
			if initExpA ~= initExpB then
				return initExpA > initExpB
			end
		end
		local starA,starB = a.star,b.star
		if starA ~= starB then return starA < starB end
		local lvlA,lvlB = a.lvl,b.lvl
		if lvlA ~= lvlB then return lvlA < lvlB end
		return a.numId < b.numId
	end)]]

	----- 2023/2/22 根据文档修改
	----- 魔偶本体星级低的优先排序
	----- 魔偶本体等级低的优先展示
	----- 根据魔偶的ID顺序由小到大排列
	------- Golem表魔偶表refid
	----- 最后排列已装备魔偶
	table.sort(allGolemList,function(a,b)
		local starA,starB = a.star,b.star
		if starA ~= starB then
			return starA < starB
		end

		local lvlA,lvlB = a.lvl,b.lvl
		if lvlA ~= lvlB then
			return lvlA < lvlB
		end

		local refIdA,refIdB = a.refId,b.refId
		if refIdA ~= refIdB then
			return refIdA < refIdB
		end

		local wearStatusA,wearStatusB = a.wearStatus,b.wearStatus
		if wearStatusA ~= wearStatusB then
			return wearStatusA < wearStatusB
		end

		return a.numId < b.numId
	end)

end

function ModelGolem:GetWarehouseSortGolemList(allGolemList,extraMap)
	extraMap = extraMap or {}
--[[	table.sort(allGolemList,function(a,b)
		local idA,idB = a.id,b.id
		if idA and idB then
			local extraStatusA = extraMap[idA] and 1 or 0
			local extraStatusB = extraMap[idB] and 1 or 0
			if extraStatusA ~= extraStatusB then
				return extraStatusA > extraStatusB
			end
		end

		local starA,starB = a.star,b.star
		if starA and starB then
			if starA ~= starB then return starA > starB end
		end

		local wearStatusA,wearStatusB = a.wearStatus,b.wearStatus
		if wearStatusA ~= wearStatusB then return wearStatusA > wearStatusB end
		local lvlA,lvlB = a.lvl,b.lvl
		if lvlA ~= lvlB then return lvlA > lvlB end
		return a.numId < b.numId
	end)]]

--[[	----- 2023/2/22 根据文档修改
	----- 魔偶星级高的优先排列
	----- 魔偶强化等级优先排列
	----- 已装备魔偶最后排列
	----- 根据魔偶的ID顺序由小到大排列
	------- Golem表魔偶表refid

	table.sort(allGolemList,function(a,b)
		local idA,idB = a.id,b.id
		if idA and idB then
			local extraStatusA = extraMap[idA] and 1 or 0
			local extraStatusB = extraMap[idB] and 1 or 0
			if extraStatusA ~= extraStatusB then
				return extraStatusA > extraStatusB
			end
		end

		local starA,starB = a.star,b.star
		if starA and starB then
			if starA ~= starB then
				return starA > starB
			end
		end

		local lvlA,lvlB = a.lvl,b.lvl
		if lvlA ~= lvlB then
			return lvlA > lvlB
		end

		local wearStatusA,wearStatusB = a.wearStatus,b.wearStatus
		if wearStatusA ~= wearStatusB then
			return wearStatusA > wearStatusB
		end

		local refIdA,refIdB = a.refId,b.refId
		if refIdA ~= refIdB then
			return refIdA < refIdB
		end

		return a.numId < b.numId
	end)]]

	----- 2023/2/27 根据文档修改
	----- 魔偶星级高的优先排列
	----- 魔偶强化等级优先排列
	----- 根据魔偶的ID顺序由小到大排列
	------- Golem表魔偶表refid
	----- 已装备魔偶最后排列

	table.sort(allGolemList,function(a,b)
		local idA,idB = a.id,b.id
		if idA and idB then
			local extraStatusA = extraMap[idA] and 1 or 0
			local extraStatusB = extraMap[idB] and 1 or 0
			if extraStatusA ~= extraStatusB then
				return extraStatusA > extraStatusB
			end
		end

		local starA,starB = a.star,b.star
		if starA and starB then
			if starA ~= starB then
				return starA > starB
			end
		end

		local lvlA,lvlB = a.lvl,b.lvl
		if lvlA ~= lvlB then
			return lvlA > lvlB
		end

		local refIdA,refIdB = a.refId,b.refId
		if refIdA ~= refIdB then
			return refIdA < refIdB
		end

		--golemWearStatus = golemIsWear and 1 or 0
		local wearStatusA,wearStatusB = a.wearStatus,b.wearStatus
		if wearStatusA ~= wearStatusB then
			return wearStatusA < wearStatusB
		end

		return a.numId < b.numId
	end)
end


function ModelGolem:GetGeneralSortGolemList2(allGolemList)
	table.sort(allGolemList,function(a,b)
		local wearStatusA,wearStatusB = a.wearStatus,b.wearStatus
		if wearStatusA ~= wearStatusB then return wearStatusA > wearStatusB end
		local lvlA,lvlB = a.lvl,b.lvl
		if lvlA ~= lvlB then return lvlA > lvlB end
		return a.numId < b.numId
	end)
end

function ModelGolem:GetCommonDisposeGolemBagList(bagList)
	if not bagList then return {} end
	local allGolemList = {}
	local golemLvlRefId
	local golemRefId,golemLvl,golemWearHeroId,golemId,mainAttrGroup,viceAttrGroup,golemExp,golemLockState,golemIsLock
	local recastMainAttr,recastViceAttrGroup,golemLockInfo
	local golemStar,golemIsWear,golemWearStatus
	for i,v in ipairs(bagList) do
		---- 服务端数据
		golemRefId = v.refId
		golemLvlRefId =  v.lvlRefId
		golemLvl = self:GetGolemLvlByGolemInfo(v)
		golemWearHeroId = v.heroId or nil
		golemId = v.id
		mainAttrGroup = v.mainAttrGroup
		viceAttrGroup = v.viceAttrGroup
		golemExp = v.exp
		golemLockState = v.lockState
		golemIsLock = v.isLock
		recastMainAttr = v.recastMainAttr
		recastViceAttrGroup = v.recastViceAttrGroup
		golemLockInfo = v.lockInfo

		local mainAttrList = self:GetGolemAttrListByGolemInfo(mainAttrGroup)
		local viceAttrList = self:GetGolemAttrListByGolemInfo(viceAttrGroup)

		local recastMainAttrList = self:GetGolemAttrListByGolemInfo(recastMainAttr)
		local recastViceAttrList = self:GetGolemAttrListByGolemInfo(recastViceAttrGroup)



		---- 其他数据
		golemStar = self:GetGolemElementStarByRefId(golemRefId) or 0
		golemIsWear = not string.isempty(golemWearHeroId)
		golemWearStatus = golemIsWear and 1 or 0
		table.insert(allGolemList,{
			refId = golemRefId,
			lvlRefId = golemLvlRefId,
			lvl = golemLvl,
			heroId = golemWearHeroId,
			id = golemId,
			mainAttrGroup = mainAttrGroup,
			viceAttrGroup = viceAttrGroup,
			exp = golemExp,
			lockState = golemLockState,
			isLock = golemIsLock,
			recastMainAttr = recastMainAttr,
			recastViceAttrGroup = recastViceAttrGroup,
			lockInfo = golemLockInfo,

			star = golemStar,
			isWear = golemIsWear,
			wearStatus = golemWearStatus,
			numId = tonumber(golemId),
			mainAttrList = mainAttrList,
			viceAttrList = viceAttrList,
			mainAttrGroupNum = #mainAttrGroup,
			viceAttrGroupNum = #viceAttrGroup,

			recastMainAttrList = recastMainAttrList,
			recastViceAttrList = recastViceAttrList,
			recastMainAttrNum = #recastMainAttr,
			recastViceAttrGroupNum = #recastViceAttrGroup,

			initExp = self:GetGolemElementExpByRefId(golemRefId),
			itype = LItemTypeConst.TYPE_GOLEM,
			state = v.state,
		})
	end
	return allGolemList
end

ModelGolem.OPTSTATUS_WAREHOUSE_NORMAL = 1
ModelGolem.OPTSTATUS_WAREHOUSE_SEL = 2
ModelGolem.OPTSTATUS_WAREHOUSE_CHANGE = 3
ModelGolem.OPTSTATUS_WAREHOUSE_REPLACE = 4
ModelGolem.OPTSTATUS_WAREHOUSE_WEAR = 5
ModelGolem.OPTSTATUS_WAREHOUSE_RECAST = 6


--- 仓库界面筛选列表
----- 套装筛选 》 属性筛选 》 排序筛选
function ModelGolem:GetGolemWarehouseList(sortInfo,extraData)

	--- 操作状态
	---	1、穿戴数据
	---	2、筛选数据
	local optStatus = extraData.optStatus
	if not optStatus then
		optStatus = ModelGolem.OPTSTATUS_WAREHOUSE_NORMAL
	end


	local extraGolemIdMap = {}
	local golemTempList = {}

	if optStatus == ModelGolem.OPTSTATUS_WAREHOUSE_CHANGE then
		local golemList = self:GetGolemList()
		for k,v in pairs(golemList) do
			table.insert(golemTempList,v)
		end
	elseif optStatus == ModelGolem.OPTSTATUS_WAREHOUSE_REPLACE then
		local curSelGolemId = extraData.curSelGolemId
		local needGolemDrawing = extraData.needGolemDrawing or -1
		if needGolemDrawing > 0 then
			golemTempList = self:GetAllGolemListByGolemDrawing(needGolemDrawing,curSelGolemId)
		else
			golemTempList = self:GetGolemBagList(extraData)
		end
		if curSelGolemId then
			extraGolemIdMap[curSelGolemId] = true
		end
		if extraData.upIndexId then
			extraGolemIdMap[extraData.upIndexId] = true
		end
	elseif optStatus == ModelGolem.OPTSTATUS_WAREHOUSE_WEAR then
		local needGolemDrawing = extraData.needGolemDrawing or -1
		if needGolemDrawing > 0 then
			golemTempList = self:GetAllGolemListByGolemDrawing(needGolemDrawing)
		else
			golemTempList = self:GetGolemBagList(extraData)
		end
	elseif optStatus == ModelGolem.OPTSTATUS_WAREHOUSE_RECAST then
		local needStar = extraData.needStar or -1
		if needStar > 0 then
			golemTempList = self:GetBagGolemListByStar(needStar)
		else
			golemTempList = self:GetGolemBagList(extraData)
		end
	else
		golemTempList = self:GetGolemBagList(extraData)
	end
	if #golemTempList < 1 then return {} end

	sortInfo = sortInfo or {}

	--- 套装筛选			仅有1个
	local suitSortList = {}
	local suitSortInfo = sortInfo[ModelGolem.GOLEM_DIV_SORT] or {}
	local suitSortSelNum = suitSortInfo.selNum or 0
	if suitSortSelNum > 0 then
		local keyVal
		local keyMap = suitSortInfo.keyMap
		local ref,suit
		for i,v in ipairs(golemTempList) do
			suit = self:GetGolemElementSuitByRefId(v.refId)
			ref = self:GetGolemSuitRefByRefId(suit)
			keyVal = self:GetWarehouseSuitTypeKey(ref)
			if keyMap[keyVal] then
				table.insert(suitSortList,v)
			end
		end
	else
		for i,v in ipairs(golemTempList) do
			table.insert(suitSortList,v)
		end
	end

	--- 属性筛选
	local attrSortInfo = sortInfo[ModelGolem.GOLEM_DIV_ATTR] or {}

	--- 主属性筛选
	local attrPrimeSortList = {}
	local attrPrimeSortInfo = attrSortInfo[ModelGolem.GOLEM_DIV_ATTR_PRIME] or {}
	local attrPrimeSortSelNum = attrPrimeSortInfo.selNum or 0
	if attrPrimeSortSelNum > 0 then
		local isHaveAttr
		local keyMap = attrPrimeSortInfo.keyMap
		for i,v in ipairs(suitSortList) do
			isHaveAttr = self:CheckGolemAttrIsHaveRefIdByGolemInfo(v,keyMap,ModelGolem.GOLEM_DIV_ATTR_PRIME)
			if isHaveAttr then
				table.insert(attrPrimeSortList,v)
			end
		end
	else
		for i,v in ipairs(suitSortList) do
			table.insert(attrPrimeSortList,v)
		end
	end

	--- 副属性筛选
	local attrDeputySortList = {}
	local attrDeputySortInfo = attrSortInfo[ModelGolem.GOLEM_DIV_ATTR_DEPUTY] or {}
	local attrDeputySortSelNum = attrDeputySortInfo.selNum or 0
	if attrDeputySortSelNum > 0 then
		local isHaveAttr
		local keyMap = attrDeputySortInfo.keyMap
		for i,v in ipairs(attrPrimeSortList) do
			isHaveAttr = self:CheckGolemAttrIsHaveRefIdByGolemInfo(v,keyMap,ModelGolem.GOLEM_DIV_ATTR_DEPUTY)
			if isHaveAttr then
				table.insert(attrDeputySortList,v)
			end
		end
	else
		for i,v in ipairs(attrPrimeSortList) do
			table.insert(attrDeputySortList,v)
		end
	end

	local allGolemList = self:GetCommonDisposeGolemBagList(attrDeputySortList)

	--- 排序筛选 			仅有1个
	local statusSortInfo = sortInfo[ModelGolem.GOLEM_DIV_STATUS]
	local statusSortSelNum = statusSortInfo.selNum
	if statusSortSelNum > 0 then
		local keyList = {}
		local keyMap = statusSortInfo.keyMap
		for key,val in pairs(keyMap) do
			table.insert(keyList,val)
		end
		if #keyList > 0 then
			--- 等级排序
			local sortLvlFunc = function(a,b)
				local lvlA,lvlB = a.lvl,b.lvl
				if lvlA ~= lvlB then return lvlA > lvlB end
				local starA,starB = a.star,b.star
				if starA ~= starB then return starA > starB end
				local wearStatusA,wearStatusB = a.wearStatus,b.wearStatus
				if wearStatusA ~= wearStatusB then return wearStatusA > wearStatusB end
				return a.numId < b.numId
			end

			--- 入手顺序
			local sortGetTimeFunc = function(a,b)
				return a.numId > b.numId
			end

			local firstKey = keyList[1]
			if firstKey == ModelGolem.GOLEM_SORT_LVL then
				self:GetLvlSortGolemList(allGolemList,extraGolemIdMap)
				--table.sort(allGolemList,sortLvlFunc)
			elseif firstKey == ModelGolem.GOLEM_SORT_GETTIME then
				self:GetGetTimeSortGolemList(allGolemList,nil,extraGolemIdMap)
				--table.sort(allGolemList,sortGetTimeFunc)
			elseif firstKey == ModelGolem.GOLEM_SORT_ATTRTYPE then
				self:GetSortAttrByGolemList(allGolemList,nil,extraGolemIdMap)
			end
		end
	else
		self:GetWarehouseSortGolemList(allGolemList,extraGolemIdMap)
	end

--[[	local isInitSort = true
	if suitSortSelNum <= 0 then
		local arrtList = sortInfo[ModelGolem.GOLEM_DIV_ATTR]
		for i, v in pairs(arrtList) do
			if v.selNum > 0 then
				isInitSort = false
				break
			end
		end
		statusSortInfo = sortInfo[ModelGolem.GOLEM_DIV_STATUS] or {}
		isInitSort = isInitSort and statusSortInfo.selNum <= 0
	end
	if suitSortSelNum > 0 or isInitSort then
		self:GetWarehouseSortGolemList(allGolemList)
]]--[[	else
		self:GetGeneralSortGolemList2(allGolemList)]]--[[
	end]]

	return allGolemList
end


--- 获取仓库界面的描述文字
function ModelGolem:GetGolemSuitDescStr(golemInfo)
	if not golemInfo then return "" end
	local conStr = ccClientText(33227)
	local suitText,suitText1 = self:GetGolemSuitSuitTextAndSuitText1ByGolemInfo(golemInfo)
	local twoSuit = string.replace(conStr,ModelGolem.SUIT_WEAR_1)
	local showTwoSuitStr = string.replace(ccClientText(33252),twoSuit,suitText)
	local fourSuit = string.replace(conStr,ModelGolem.SUIT_WEAR_2)
	local showFourSuitStr = string.replace(ccClientText(33252),fourSuit,suitText1)
	return string.replace(ccClientText(33253),showTwoSuitStr,showFourSuitStr)
end


--- 获取仓库界面的描述文字列表
function ModelGolem:GetGolemDescStrList(golemInfo)
	if not golemInfo then return {} end
	local conStr = ccClientText(33227)
	local suitText,suitText1 = self:GetGolemSuitSuitTextAndSuitText1ByGolemInfo(golemInfo)
	local twoSuit = string.replace(conStr,ModelGolem.SUIT_WEAR_1)
	local fourSuit = string.replace(conStr,ModelGolem.SUIT_WEAR_2)
	return{
		{
			title = twoSuit,
			desc = suitText,
		},
		{
			title = fourSuit,
			desc = suitText1,
		},
	}

	--[[	local twoSuit = string.replace(conStr,ModelGolem.SUIT_WEAR_1)
        local showTwoSuitStr = string.replace(ccClientText(33252),twoSuit,suitText)
        local fourSuit = string.replace(conStr,ModelGolem.SUIT_WEAR_2)
        local showFourSuitStr = string.replace(ccClientText(33252),fourSuit,suitText1)
        return {
            showTwoSuitStr,showFourSuitStr
        }]]
end

--- 魔偶自动分解参数列表
function ModelGolem:GetGolemSmartDissolveList()
	return ModelGolem.GOLEM_SMART_DISSOLVE_LIST
end

-------------------------------------------------------------- 允许显示入口品质
--- 判断英雄品质是否显示魔偶入口
function ModelGolem:CheckHeroIsShowGolemEntranceByHeroQuality(quality)
	if not quality then return false end
	local heroQuality = self:GetGolemConfigRefByKey("heroQuality")
	return quality >= heroQuality
end

--- 通过英雄的结构去判断是否显示入口
function ModelGolem:CheckHeroIsShowEntranceByHeroStruct(hero)
	if not hero then return false end
	local quality = gModelHero:GetHeroInitQualityByRefId(hero:GetRefId())
	return self:CheckHeroIsShowGolemEntranceByHeroQuality(quality)
end

--- 通过英雄的数据去判断
function ModelGolem:CheckHeroIsShowEntranceByHeroServerData(heroServerData)
	if not heroServerData then return false end
	local quality = gModelHero:GetHeroInitQualityByRefId(heroServerData.refId)
	return self:CheckHeroIsShowGolemEntranceByHeroQuality(quality)
end

-------------------------------------------------------------- 允许穿戴的星级
--- 判断英雄的星级是否能穿戴
function ModelGolem:CheckHeroIsCanWearGolemByStar(star)
	if not star then return false end
	local heroLimitStar = self:GetGolemConfigRefByKey("heroStar")
	return star >= heroLimitStar
end

--- 通过英雄的结构去判断
function ModelGolem:CheckHeroIsWearByHeroStruct(hero)
	if not hero then return false end
	local star = hero:GetStar()
	return self:CheckHeroIsCanWearGolemByStar(star)
end

--- 通过英雄的数据去判断
function ModelGolem:CheckHeroIsWearByHeroServerData(heroServerData)
	if not heroServerData then return false end
	return self:CheckHeroIsCanWearGolemByStar(heroServerData.star)
end


function ModelGolem:CheckHeroIsShowAndWearByHeroServerData(heroServerData)
	local showEntrance = self:CheckHeroIsShowEntranceByHeroServerData(heroServerData)
	local showWear = self:CheckHeroIsWearByHeroServerData(heroServerData)
	return showEntrance and showWear
end


function ModelGolem:CheckHeroIsShowAndWearByHeroStruct(hero)
	local showEntrance = self:CheckHeroIsShowEntranceByHeroStruct(hero)
	local showWear = self:CheckHeroIsWearByHeroStruct(hero)
	return showEntrance and showWear
end

--- 切换英雄界面显示的英雄列表
function ModelGolem:GetCutGolemWearHeroList(raceType)
	local heroList = gModelHero:GetHeroList()
	if not heroList then return {} end
	raceType = raceType or UIHeroRaceList.ALL_RACE_REFID
	local list = {}
	for id,hero in pairs(heroList) do
		if self:CheckHeroIsWearByHeroStruct(hero) and self:CheckHeroIsShowEntranceByHeroStruct(hero) then
			if raceType == UIHeroRaceList.ALL_RACE_REFID then
				table.insert(list,hero:GetServerData())
			elseif raceType == gModelHero:GetHeroRace(hero:GetRefId()) then
				table.insert(list,hero:GetServerData())
			end
		end
	end
	table.sort(list,function(a,b)
		local starA,starB = a.star,b.star
		if starA ~= starB then return starA > starB end
		local lvA,lvB = a.lv,b.lv
		if lvA ~= lvB then return lvA > lvB end
		local fightPowerA,fightPowerB = a.fightPower,b.fightPower
		if fightPowerA ~= fightPowerB then return fightPowerA > fightPowerB end
		local refIdA,refIdB = a.refId,b.refId
		if refIdA ~= refIdB then return refIdA < refIdB end
		return a.id > b.id
	end)
	return list
end


function ModelGolem:ChangeGolemLockStatusByGolemInfo(golemInfo)
	if not golemInfo then return end
	local id = self:GetGolemIdByGolemInfo(golemInfo)
	local isLock = self:GetGolemIsLockByGolemInfo(golemInfo)
	local opsType = isLock and ModelGolem.GOLEM_STATUS_UNLOCK or ModelGolem.GOLEM_STATUS_LOCK
	local func = function()
		self:OnGolemLockReq(opsType,{id})
	end
	local wndId = isLock and 310002 or 310001
	gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func})
end

------ 道具使用界面的激活列表
function ModelGolem:GetGolemActItemUseList(golemInfo)
	local expSelectStatus = self:GetGolemConfigRefByKey("expSelectStatus")
	if not expSelectStatus then
		--- expSelectStatus = 0，激活等级列表为固定 expSelect 字段
		--- expSelectStatus = 1，激活等级列表为按照组来显示可升级的 expSelectGroup 字段
		expSelectStatus = 0
	end
	if expSelectStatus == 1 then
		local expSelectGroup = self:GetGolemConfigRefByKey("expSelectGroup")
		if expSelectGroup then
			local lvrGroupId = self:GetGolemElementLvrGroupIdByGolemInfo(golemInfo)
			if lvrGroupId then
				local lvlGroupLvList = expSelectGroup[lvrGroupId] or {}
				if #lvlGroupLvList > 0 then
					return lvlGroupLvList
				end
			end
		end
	end
	return self:GetGolemConfigRefByKey("expSelect")
end

--- 当前升到下一级所需经验
function ModelGolem:GetUpLvToNextNeedExpByGolemInfo(golemInfo)
	local exp = self:GetGolemExpByGolemInfo(golemInfo)
	local needExp = self:GetGolemNeedExpByLevelRefId(self:GetGolemLvlRefIdByGolemInfo(golemInfo))
	local loseExp = needExp - exp
	if loseExp < 1 then
		if not self:CheckGolemIsMaxLevelByGolemInfo(golemInfo) then
			local nextLvRefId = self:GetGolemNextLevelRefIdByGolemInfo(golemInfo)
			needExp = self:GetGolemNeedExpByLevelRefId(nextLvRefId)
			loseExp = needExp - exp
		end
	end
	return loseExp
end

function ModelGolem:GetUpLvToNextNeedExpByGolemInfoAndUseExp(golemInfo,addExp)
	local lvlRefId = self:GetGolemLvlRefIdByGolemInfo(golemInfo)
	local ref = self:GetGolemLvRefByLvRefId(lvlRefId)
	if not ref then return -1 end
	local needExp = ref.needExp
	local exp = self:GetGolemExpByGolemInfo(golemInfo)
	local curExp = exp + addExp
	if needExp > curExp then
		return needExp - curExp
	else
		local nextLevel = ref.nextLevel
		if nextLevel == ModelGolem.FULL_EXP then
			------ 已满级
			return -1
		else
			local func
			func = function(nextRef)
				if not nextRef then return end
				needExp = nextRef.needExp
				if curExp >= needExp then
					if nextRef.nextLevel == ModelGolem.FULL_EXP then
						return needExp - curExp
					else
						return func(self:GetGolemLvRefByLvRefId(nextRef.nextLevel))
					end
				else
					return needExp - curExp
				end
			end
			ref = self:GetGolemLvRefByLvRefId(nextLevel)
			local lastExp = func(ref)
			return lastExp
		end
	end
end

--- 当前升到等级所需经验值
function ModelGolem:GetUpLvNeedExpByInfo(info)
	local lvrGroupId = info.lvrGroupId
	local needExp = self:GetGolemLvNeedExpByLvrGroupIdAndLv(lvrGroupId,info.uplv)
	local curExp = info.exp
	return needExp - curExp
end

function ModelGolem:GetGolemItemChangeExpByItemId(itemId)
	local data = gModelItem:GetGolemExpItemInfoByRefId(itemId)
	if not data then return end
	return data.conversionExp
end

function ModelGolem:GetUseItemRewardExp(useNum,ietmToExp)
	return useNum * ietmToExp
end

--- 道具转换经验
function ModelGolem:GetUseItemToExp(info)
	if not info then return 0 end
	local itemId = info.itemId
	local useNum = info.useNum
	local itemChangeExp = self:GetGolemItemChangeExpByItemId(itemId)
	return self:GetUseItemRewardExp(useNum,itemChangeExp)
end

--- 魔偶转换经验
function ModelGolem:GetGolemInfoChangeToExp(golemInfo)
	local golemInitExp = self:GetGolemElementExpByGolemInfo(golemInfo)
	local quality = self:GetGolemElementQualityByRefId(golemInfo.refId)
	local exp = self:GetGolemExpByGolemInfo(golemInfo)
	local lastExp = 0
	if exp > 0 then
		local configExpRestitutionKey = self._configExpRestitutionKey
		local expRes = configExpRestitutionKey[quality] or 1
		lastExp = expRes * exp
--[[		local needExp = self:GetGolemNeedExpByLevelRefId(self:GetGolemLvlRefIdByGolemInfo(golemInfo))
		if upExp > needExp then
			local lost = (upExp - needExp) * expRes
			lastExp = needExp + lost
		else
			lastExp = upExp
		end]]
        --- 2023/03/16  jh:单个向下取整
        lastExp = math.floor(lastExp)
	end
	return golemInitExp + lastExp
end


function ModelGolem:GetUseItemToPayItemListByExp(itemExp)
	if itemExp < 1 then return {} end
	local intensifyExpend = self:GetGolemConfigRefByKey("intensifyExpend")
	local payList = {}
	local itemNum = intensifyExpend.itemNum
	local payNum = itemExp * itemNum
	table.insert(payList,{
		itemType = intensifyExpend.itemType,
		itemId = intensifyExpend.itemId,
		itemNum = payNum,
	})
	return payList
end

function ModelGolem:GetUseItemToPayItemList(info)
	local itemExp = self:GetUseItemToExp(info)
	return self:GetUseItemToPayItemListByExp(itemExp)
end

--- 魔偶消耗转换
function ModelGolem:GetGolemInfoChangeToPayItemList(golemInfo)
	if not golemInfo then return {} end
	local payItemList = {}
	local consume = self:GetGolemConsumeByGolemInfo(golemInfo)
	for i,v in ipairs(consume) do
		table.insert(payItemList,{
			itemType = v.itemType,
			itemId = v.itemId,
			itemNum = v.itemNum,
		})
	end
	return payItemList
end


--- 魔偶主界面属性列表		暂定，可由服务端推送
function ModelGolem:GetWearAllAttrList(slotServerDataList)
	local wearGolemList = {}
	for k,v in pairs(slotServerDataList) do
		table.insert(wearGolemList,v)
	end
	local attrList = {}
	for i,v in ipairs(wearGolemList) do
		local golemAttrList = self:GetGolemAllAttrList(v)
	end
	local actSuitList = self:GetGolemActSuitList(slotServerDataList)
	if #actSuitList > 0 then
		for i,v in ipairs(actSuitList) do

		end
	end
end

function ModelGolem:GetHeroGolemSkillByRefId(refId)
	local initGolemSkillList = self._initGolemSkillList
	if not initGolemSkillList then
		initGolemSkillList = {}
		self._initGolemSkillList = initGolemSkillList
	end
	local data = initGolemSkillList[refId]
	if not data then
		local ref = gModelHero:GetHeroRef(refId)
		if ref then
			data = {}
			local golemSkill = ref.golemSkill
			if type(golemSkill) == "string" then
				local golemSkillList = string.split(golemSkill,",")
				for i,v in ipairs(golemSkillList) do
					v = tonumber(v)
					data[v] = v
				end
			else
				if LOG_INFO_ENABLED then
					printInfoNR("如果英雄拥有多套推荐，可将 HeroRef 表中的 golemSkill 字段改为 string 类型并用 , 分割，其他逻辑不变，即可兼容多套")
				end
				data[golemSkill] = golemSkill
			end
			initGolemSkillList[refId] = data
		end
	end
	return data
end

function ModelGolem:GetHeroGolemSkillByHeroServerData(heroServerData)
	if not heroServerData then return end
	return self:GetHeroGolemSkillByRefId(heroServerData.refId)
end

function ModelGolem:CheckSuitIsHaveHeroRecommend(golemSkill,suitId)
	if not golemSkill or not suitId then return false end
	return golemSkill[suitId] ~= nil
end

function ModelGolem:CheckSuitIdIsHeroGolemSkillByHeroRefId(suitId,heroRefId)
	local golemSkill = self:GetHeroGolemSkillByRefId(heroRefId)
	if golemSkill then
		return self:CheckSuitIsHaveHeroRecommend(golemSkill,suitId)
	end
	return false
end

function ModelGolem:CheckSuitIdIsHeroGolemSkillByHeroServerData(suitId,heroServerData)
	if not heroServerData then return false end
	return self:CheckSuitIdIsHeroGolemSkillByHeroRefId(suitId,heroServerData.refId)
end


function ModelGolem:GetGolemLocationList(golemDrawing,golemList)
	if not golemDrawing then return {} end
	if not golemList then return {} end
	local list = {}
	for k,golemInfo in pairs(golemList) do
		if self:GetGolemElementGolemDrawingByGolemInfo(golemInfo) == golemDrawing then
            if not self:GetGolemIsLockByGolemInfo(golemInfo) then
                --- 一键穿戴必须排除锁定的魔偶
                table.insert(list,golemInfo)
            end
		end
	end
	return list
end

function ModelGolem:GetGolemListBySuitId(suit)
	local bagSuitList = self:GetBagGolemListByGolemSuitId(suit)
	if #bagSuitList < 1 then return end
	local locationKeyList = {}
	local initGolemLocationSortList = self:GetGolemLocationRefSortList()
	local isFull = true
	local refId
	for i,v in ipairs(initGolemLocationSortList) do
		refId = v.refId
		local locationList = self:GetGolemLocationList(refId,bagSuitList)
		if isFull then
			isFull = #locationList > 0
		end
		locationKeyList[refId] = locationList
	end
	return isFull,locationKeyList
end

function ModelGolem:GetGolemSlotRespSlotServerDataList(pb)
	local slotList = {
		[1] = pb.slot1,
		[2] = pb.slot2,
		[3] = pb.slot3,
		[4] = pb.slot4,
	}
	local slotId,slotServerData
	local slotServerDataList = {}
	for i = 1,ModelGolem.SHOW_GOLEM_NUM do
		slotId = slotList[i]
		if slotId then
			slotServerData = self:GetGolemServerDataById(slotId)
			if slotServerData then
				slotServerDataList[i] = slotServerData
			end
		end
	end
	return slotServerDataList
end

function ModelGolem:GetGolemIntensifyList(selSortType,excludeMap)
	local bagList = self:GetGolemBagList({
		excludeMap = excludeMap
	})
	if #bagList < 1 then return {} end

	--- 不展示当前玩家拥有最高星级的魔偶,intensifyQuality 字段 做为区分
	local intensifyQuality = self:GetGolemConfigRefByKey("intensifyQuality")
	local allGolemList = self:GetCommonDisposeGolemBagList(bagList)
	local useMaterialList = {}
	local golemStar
	for i,v in ipairs(allGolemList) do
		golemStar = self:GetGolemElementStarByGolemInfo(v)
		if not intensifyQuality[golemStar] then
			table.insert(useMaterialList,v)
		end
	end

	if selSortType then
		if selSortType == ModelGolem.GOLEM_SORT_LVL then
			--- 等级由大到小进行排序 -> 魔偶id 由小到大
			table.sort(useMaterialList,function(a,b)
				local lvlA,lvlB = a.lvl,b.lvl
				if lvlA ~= lvlB then
					return lvlA > lvlB
				end
				return a.numId < b.numId
			end)
		elseif selSortType == ModelGolem.GOLEM_SORT_GETTIME then
			self:GetGetTimeSortGolemList(useMaterialList)
		elseif selSortType == ModelGolem.GOLEM_SORT_ATTRTYPE then
			--self:GetSortAttrByGolemList(useMaterialList,true)
			--self:GetGeneralSortGolemList(useMaterialList)

			table.sort(useMaterialList,function(a,b)
				local mainAttrGroupNumA,mainAttrGroupNumB = a.mainAttrGroupNum,b.mainAttrGroupNum
				if mainAttrGroupNumA ~= mainAttrGroupNumB then return mainAttrGroupNumA >mainAttrGroupNumB end
				local mainAttrListA,mainAttrListB = a.mainAttrList,b.mainAttrList
				local firstA = mainAttrListA[1]
				local firstB = mainAttrListB[1]
				--- 属性类型顺序
				local sortA,sortB = self:GetCommonAttrSortFunc(firstA,firstB)
				if sortA ~= sortB then return sortA < sortB end
				--- 属性值顺序
				local attrNumA,attrNumB = firstA.attrNum,firstB.attrNum
				if attrNumA ~= attrNumB then return attrNumA > attrNumB end
				--- 默认排序
				local expA,expB = a.exp,b.exp
				if expA ~= expB then return expA > expB end
				local starA,starB = a.star,b.star
				if starA ~= starB then return starA < starB end
				local lvlA,lvlB = a.lvl,b.lvl
				if lvlA ~= lvlB then return lvlA < lvlB end
				return a.numId < b.numId
			end)

		elseif selSortType == ModelGolem.GOLEM_SORT_STAR then
			self:GetStarSortGolemList(useMaterialList)
		end
	else
		self:GetGeneralSortGolemList(useMaterialList)
	end
	return useMaterialList
end

function ModelGolem:CheckIsGolemItemSplit()
	local golemSplitStatus = self:GetGolemConfigRefByKey("golemSplitStatus")
	if not golemSplitStatus then
		if LOG_INFO_ENABLED then
			printInfoNR("魔偶素材道具使用分离状态字段 golemSplitStatus 未配置，默认使用分离 状态为1")
		end
		golemSplitStatus = ModelGolem.ITEM_USE_TYPE
	end
	return golemSplitStatus == 1
end


function ModelGolem:GetGolemLvGroupMaxInfoByGolemInfo(golemInfo)
	local lvrGroupId = self:GetGolemElementLvrGroupIdByGolemInfo(golemInfo)
	if not lvrGroupId then return end
	return self:GetGolemLvGroupMaxInfoByLvrGroupId(lvrGroupId)
end

function ModelGolem:CheckGolemIsMaxLevelByGolemInfo(golemInfo)
	local maxLvInfo = self:GetGolemLvGroupMaxInfoByGolemInfo(golemInfo)
	if not maxLvInfo then return false end
	local lvlRefId = self:GetGolemLvlRefIdByGolemInfo(golemInfo)
	local refId = maxLvInfo.refId
	return lvlRefId >= refId
end

function ModelGolem:GetAttrKeyList(allAttrList)
	local allAttrKeyList = {}
	local attrRefId,attrType
	local listSort = {}
	for i,v in ipairs(allAttrList) do
		attrRefId = v.attrRefId
		listSort[attrRefId] = i
		local attrRefIdInfo = allAttrKeyList[attrRefId]
		if not attrRefIdInfo then
			attrRefIdInfo = {}
			allAttrKeyList[attrRefId] = attrRefIdInfo
		end
		attrType = v.attrType
		local attrTypeNum = attrRefIdInfo[attrType] or 0
		attrRefIdInfo[attrType] = attrTypeNum + v.attrNum
	end
	return allAttrKeyList,listSort
end

--- 这个函数会与魔偶星级是否提升挂钩
function ModelGolem:GetNewMainAndViceAttrList(golemInfo,nextLv)
	if not golemInfo then return {} end
	local mainAttrGroupList = {}
	local mainAttrGroup = self:GetGolemMainAttrGroupByGolemInfo(golemInfo)
	local attrGroupId,nextAttrRef
	for i,v in ipairs(mainAttrGroup) do
		attrGroupId = self:GetGolemAttrAttrGroupIdByRefId(v)
		nextAttrRef = self:GetGolemAttrRefByAttrGroupIdAndLv(attrGroupId,nextLv)
		if nextAttrRef then
			table.insert(mainAttrGroupList,nextAttrRef.refId)
		end
	end

	local viceAttrGroupList = {}
	local viceAttrGroup = self:GetGolemViceAttrGroupByGolemInfo(golemInfo)

	local attrDeputyNum = self:GetGolemElementAttrDeputyNumByGolemInfo(golemInfo)
	if not attrDeputyNum then
		if LOG_INFO_ENABLED then
			printInfoNR("打印而已，莫慌！		GolemElementRef表 attrDeputyNum这个字段为空 refId = " .. golemInfo.refId)
		end
		attrDeputyNum = 3
	end
	--- 表格注释写星级，如果不对使用这个函数
	--- local quality = self:GetGolemElementStarByRefId(golemInfo.refId)
	local quality = self:GetGolemElementQualityByRefId(golemInfo.refId)
	local starLvInfo = self:GetInitGolemStarLvInfo(quality,nextLv)
	local upViceAttrList = {}
	if starLvInfo then
		local temp
		local constLvStr = "attr#a1#Lv"
		local fieldStr
		for i = 1,attrDeputyNum do
			fieldStr = string.replace(constLvStr,i)
			temp = starLvInfo[fieldStr]
			if temp then
				upViceAttrList[i] = {
					viceAttrLv = temp,
				}
			end
		end
	end

	local curViceAttrLv
	local indexUpViceAttr,viceAttrLv
	for i,v in ipairs(viceAttrGroup) do
		indexUpViceAttr = upViceAttrList[i]
		if indexUpViceAttr then
			viceAttrLv = indexUpViceAttr.viceAttrLv
			curViceAttrLv = self:GetGolemAttrLvByRefId(v)
			if viceAttrLv >= curViceAttrLv then
				attrGroupId = self:GetGolemAttrAttrGroupIdByRefId(v)
				nextAttrRef = self:GetGolemAttrRefByAttrGroupIdAndLv(attrGroupId,viceAttrLv)
				if nextAttrRef then
					table.insert(viceAttrGroupList,nextAttrRef.refId)
				end
			else
				table.insert(viceAttrGroupList,v)
			end
		end
	end

	local newMainAttrGroupAttrList = self:GetGolemAttrListByGolemInfo(mainAttrGroupList)
	local newViceAttrGroupAttrList = self:GetGolemAttrListByGolemInfo(viceAttrGroupList)

	return self:GetTwoAttrList(newMainAttrGroupAttrList,newViceAttrGroupAttrList)
end

--------------------------------------------------------------------------------------------

ModelGolem.UP_LV_STATUS_NOTEXP = -1
ModelGolem.UP_LV_STATUS_MAXLVL = -2

function ModelGolem:GetBeforeAndLastAttrList(allAttrKeyList,recordList,isLast,status)
	status = status or ModelGolem.UP_LV_STATUS_NOTEXP
	local retKeyList = recordList or {}
	local tNum
	for attrRefId,attrRefIdInfo in pairs(allAttrKeyList) do
		for attrType,attrTypeNum in pairs(attrRefIdInfo) do
			local attrRefIdRetKeyList = retKeyList[attrRefId]
			if not attrRefIdRetKeyList then
				attrRefIdRetKeyList = {}
				retKeyList[attrRefId] = attrRefIdRetKeyList
			end
			local attrTypeRetKeyList = attrRefIdRetKeyList[attrType]
			if not attrTypeRetKeyList then
				attrTypeRetKeyList = {}
				attrTypeRetKeyList.before = 0
				attrTypeRetKeyList.last = status
				attrRefIdRetKeyList[attrType] = attrTypeRetKeyList
			end
			if isLast then
				tNum = attrTypeRetKeyList.last
				if tNum == -1 then
					attrTypeRetKeyList.last = attrTypeNum
				else
					attrTypeRetKeyList.last = tNum + attrTypeNum
				end
			else
				tNum = attrTypeRetKeyList.before
				attrTypeRetKeyList.before = tNum + attrTypeNum
			end
		end
	end
	return retKeyList
end


function ModelGolem:GetAddExpShowInfo(golemInfo,addExp)
	if not golemInfo then return {} end
	local allAttrKeyList,listSort= self:GetAttrKeyList(self:GetGolemAllAttrList(golemInfo))
	local retKeyList = self:GetBeforeAndLastAttrList(allAttrKeyList)
	local maxLvInfo = self:GetGolemLvGroupMaxInfoByGolemInfo(golemInfo)
	local curlvlRefId = self:GetGolemLvlRefIdByGolemInfo(golemInfo)
    local changeBarStatus = false
	local nextLv,nextNeedExp,newLvlRefId
	local showFull = false
	if maxLvInfo and maxLvInfo.refId ~= curlvlRefId then
		if addExp > 0 then
			local curExp = self:GetGolemExpByGolemInfo(golemInfo)
			local newExp = curExp + addExp
			local ref = self:GetGolemLvRefByLvRefId(curlvlRefId)
			local maxRefId = maxLvInfo.refId
			local curNeedExp = ref.needExp
			if curNeedExp > newExp then
				newLvlRefId = ref.nextLevel
				if newLvlRefId and maxRefId ~= newLvlRefId then
					--nextLv = self:GetGolemLvByLevelRefId(newLvlRefId)
					nextNeedExp = self:GetGolemNeedExpByLevelRefId(curlvlRefId)
				end
			elseif curNeedExp == newExp then
				newLvlRefId = ref.nextLevel
				if newLvlRefId then
					nextLv = self:GetGolemLvByLevelRefId(newLvlRefId)
					if maxRefId ~= newLvlRefId then
						nextNeedExp = curNeedExp
						changeBarStatus = true
					elseif maxRefId == newLvlRefId then
						nextNeedExp = self:GetGolemNeedExpByLevelRefId(newLvlRefId)
					end
					local newAttrList = self:GetNewMainAndViceAttrList(golemInfo,nextLv)
					local newAllAttrKeyList = self:GetAttrKeyList(newAttrList)
					self:GetBeforeAndLastAttrList(newAllAttrKeyList,retKeyList,true)
				end
			else
				local func
				func = function(nextRef)
					if not nextRef then return curlvlRefId end
					local needExp = nextRef.needExp
					if newExp >= needExp then
						if nextRef.nextLevel == ModelGolem.FULL_EXP then
							return nextRef.refId
						else
							return func(self:GetGolemLvRefByLvRefId(nextRef.nextLevel))
						end
					else
						return nextRef.refId
					end
				end
				--local nextRef = self:GetGolemNextLevelRefByGolemInfo(golemInfo)
				newLvlRefId = func(ref)
				if newLvlRefId then
					nextLv = self:GetGolemLvByLevelRefId(newLvlRefId)
					nextNeedExp = self:GetGolemNeedExpByLevelRefId(newLvlRefId)
					local newAttrList = self:GetNewMainAndViceAttrList(golemInfo,nextLv)
					local newAllAttrKeyList = self:GetAttrKeyList(newAttrList)
					self:GetBeforeAndLastAttrList(newAllAttrKeyList,retKeyList,true)
					if maxRefId ~= newLvlRefId then
						changeBarStatus = true
					end
				end
			end
		end
	elseif maxLvInfo and maxLvInfo.refId == curlvlRefId then
		showFull = true
	end
	local retList = {}
	for attrRefId,attrRefIdInfo in pairs(retKeyList) do
		for attrType,attrTypeInfo in pairs(attrRefIdInfo) do
			table.insert(retList,{
				attrRefId = attrRefId,
				attrType = attrType,
				before = attrTypeInfo.before,
				last = attrTypeInfo.last,
				sort = listSort[attrRefId]
			})
		end
	end
	table.sort(retList,function(a,b)
		-- local sortA,sortB = self:GetCommonAttrSortFunc(a,b)
		return  a.sort < b.sort
	end)
	return {
		upLvChangeAttrList = retList,
		curlvlRefId = curlvlRefId,
		newLvlRefId = newLvlRefId,
		curLvl = self:GetGolemLvByLevelRefId(curlvlRefId),
		nextLv = nextLv,
		exp = self:GetGolemExpByGolemInfo(golemInfo),
		nextNeedExp = nextNeedExp,
        changeBarStatus = changeBarStatus,
		showFull = showFull,
	}
end

-----------------------------------------------------------------------------------------
function ModelGolem:OpenHeroGolemRecommendByHeroI(heroId)
	if not heroId then return end
	local heroServerData = gModelHero:GetHeroServerDataById(heroId)
	if not heroServerData then return end
	self:OpenHeroGolemRecommendByHeroServerData(heroServerData)
end

function ModelGolem:OpenHeroGolemRecommendByHeroServerData(heroServerData)
	local golemSkill = self:GetHeroGolemSkillByHeroServerData(heroServerData)
	if not golemSkill then return end
	local suit
	for k,v in pairs(golemSkill) do
		if suit then break end
		suit = v
	end
	--- 魔偶推荐
	self:OpenGolemRecommend({
		suitId = suit
	})
end

-----------------------------------------------------------------------------------------
function ModelGolem:GolemBagChangeToHeroGolemBagSelHeroId()
	local list = gModelHero:GetHaveHeroGolemList()
	--if #list < 1 then
	--	gModelHero:SaveHaveHeroGoleList()
	--	list = gModelHero:GetHaveHeroGolemList()
	--end
	if #list < 1 then
		return
	end
	local first = list[1]
	return first and first.id
end


function ModelGolem:GetHeroWearGolemListByHeroId(wearHeroId)
	if not wearHeroId then return {},{} end
	local golemList = self:GetGolemList()
	local wearList = {}
	local wearMap = {}
	local heroId,golemDrawing
	for golemId,golemInfo in pairs(golemList) do
		if self:CheckGolemIsWearByGolemInfo(golemInfo) then
			heroId = golemInfo.heroId
			if wearHeroId == heroId then
				golemDrawing = self:GetGolemElementGolemDrawingByGolemInfo(golemInfo)
				if golemDrawing then
					wearMap[golemDrawing] = golemId
					table.insert(wearList,{
						golemId = golemId,
						golemDrawing = golemDrawing,
						golemInfo = golemInfo,
					})
				end
			end
		end
	end
	table.sort(wearList,function(a,b)
		return a.golemDrawing < b.golemDrawing
	end)
	return wearMap,wearList
end

-----------------------------------------------------------------------------------------

function ModelGolem:GetConfigAttrShowList()
	return self:GetGolemConfigRefByKey("attrShow")
end

function ModelGolem:GetAutoSelWearGolemList(sortFunc)
	local bagList = self:GetGolemBagList()
	local bagPosList = {}
	local golemDrawing
	for i,v in ipairs(bagList) do
		if not gModelGolem:GetGolemIsLockByGolemInfo(v) then
			golemDrawing = self:GetGolemElementGolemDrawingByGolemInfo(v)
			local posList = bagPosList[golemDrawing]
			if not posList then
				posList = {}
				bagPosList[golemDrawing] = posList
			end
			table.insert(posList,{
				refId = self:GetGolemRefIdByGolemInfo(v),
				score = self:GetGolemScoreByGolemInfo(v),
				id = self:GetGolemIdByGolemInfo(v),
			})
		end
	end
	if sortFunc then
		for pos,posList in pairs(bagPosList) do
			table.sort(posList,sortFunc)
		end
	end
	local first
	local list = {}
	for pos,posList in pairs(bagPosList) do
		first = posList[1]
		list[pos] = first
	end
	return list
end


function ModelGolem:GetRecordSelMaterials(selMaterialsList)
	local selGolemNum = 0
	local recordSelMaterials = {}
	for useType,useTypeInfo in pairs(selMaterialsList) do
		local selMaterials = recordSelMaterials[useType]
		if not selMaterials then
			selMaterials = {}
			recordSelMaterials[useType] = selMaterials
		end
		local selIdList = useTypeInfo.selIdList
		if useType == ModelGolem.TYPE_MATERIAL_ITEM then
			for refId,useNum in pairs(selIdList) do
				selMaterials[refId] = useNum
			end
		elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
			for refId,selInfo in pairs(selIdList) do
				selMaterials[refId] = selInfo.useNum
			end
		elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
			for golemId,sGolemInfo in pairs(selIdList) do
				selMaterials[golemId] = sGolemInfo
				selGolemNum = selGolemNum + 1
			end
		end
	end
	return selGolemNum,recordSelMaterials
end

function ModelGolem:GetCanSelItemNum(materialsList,recordSelMaterials)
	local canSelItemNum = 0
	local useType,info,haveNum
	for i,v in ipairs(materialsList) do
		useType = v.useType
		info = v.info
		local recordSelInfo = recordSelMaterials[useType]
		if useType == ModelGolem.TYPE_MATERIAL_ITEM then
			haveNum = info.haveNum
			local itemId = info.itemId
			local selItemNum = recordSelInfo[itemId]
			local canUseNum
			if selItemNum then
				canUseNum = haveNum - selItemNum
			else
				canUseNum = haveNum
			end
			canUseNum = canUseNum > 0 and canUseNum or 0
			canSelItemNum = canSelItemNum + canUseNum
		elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
			haveNum = info.haveNum
			local itemId = info.itemId
			local selItemNum = recordSelInfo[itemId]
			local canUseNum
			if selItemNum then
				canUseNum = haveNum - selItemNum
			else
				canUseNum = haveNum
			end
			canUseNum = canUseNum > 0 and canUseNum or 0
			canSelItemNum = canSelItemNum + canUseNum
		end
	end
	return canSelItemNum
end

function ModelGolem:GetUseItemMap(data)
	if not data then return {} end

	local lastLvExp = data.lastLvExp or 0
	if lastLvExp <= 0 then return {} end

	local materialsList = data.materialsList or {}
	local recordSelMaterials = data.recordSelMaterials or {}
	local selGolemNum = data.selGolemNum or 0
	local selectUpper = data.selectUpper or self:GetGolemConfigRefByKey("selectUpper")
	local useMap = {}
	local conversionExp
	local sUseType,info,haveNum
	for i,v in ipairs(materialsList) do
		if lastLvExp <= 0 then break end
		sUseType = v.useType
		info = v.info
		local recordSelInfo = recordSelMaterials[sUseType]
		if sUseType == ModelGolem.TYPE_MATERIAL_ITEM or sUseType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
			haveNum = info.haveNum
			local itemId = info.itemId
			local selItemNum = recordSelInfo[itemId]
			local canUseNum
			if selItemNum then
				canUseNum = haveNum - selItemNum
			else
				canUseNum = haveNum
			end
			if canUseNum > 0 then
				local useInfo = useMap[sUseType]
				if not useInfo then
					useInfo = {}
					useMap[sUseType] = useInfo
				end
				conversionExp = info.conversionExp
				local canUseItemNum
				if conversionExp > lastLvExp then
					canUseItemNum = 1
					lastLvExp = -1
				else
					local tNum = math.floor(lastLvExp / conversionExp)
					if tNum > canUseNum then
						canUseItemNum = canUseNum
					else
						local tUpExp = tNum * conversionExp
						if lastLvExp - tUpExp > 0 then
							if tNum + 1 <= canUseNum then
								tNum = tNum + 1
							end
						end
						canUseItemNum = tNum
					end
					lastLvExp = lastLvExp - canUseItemNum * conversionExp
				end
				if sUseType == ModelGolem.TYPE_MATERIAL_ITEM then
					useInfo[itemId] = canUseItemNum
				elseif sUseType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM  then
					useInfo[itemId] = {
						useNum = canUseItemNum,
					}
				end
			end
		elseif sUseType == ModelGolem.TYPE_MATERIAL_GOLEM then
			if selGolemNum < selectUpper  then
				local serverData = info.serverData
				if serverData then
					local id = self:GetGolemIdByGolemInfo(serverData)
					if not recordSelInfo[id] then
						local golemChangeExp = self:GetGolemInfoChangeToExp(serverData)
						if golemChangeExp >= lastLvExp then
							lastLvExp = -1
						else
							lastLvExp = lastLvExp - golemChangeExp
						end
						local useInfo = useMap[sUseType]
						if not useInfo then
							useInfo = {}
							useMap[sUseType] = useInfo
						end
						useInfo[id] = serverData
						selGolemNum = selGolemNum + 1
					end
				end
			end
		end
	end
	useMap = self:SetRecordItemSelMaterialsMap(recordSelMaterials,useMap)
	return useMap
end

function ModelGolem:SetRecordItemSelMaterialsMap(recordSelMaterials,useMap)
	local record
	for useType,useTypeInfo in pairs(recordSelMaterials) do
		local useInfo = useMap[useType]
		if not useInfo then
			useInfo = {}
			useMap[useType] = useInfo
		end
		if useType == ModelGolem.TYPE_MATERIAL_ITEM then
			for refId,useNum in pairs(useTypeInfo) do
				record = useInfo[refId] or 0
				useInfo[refId] = record + useNum
			end
		elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
			for refId,useNum in pairs(useTypeInfo) do
				local recordInfo = useInfo[refId]
				if not recordInfo then
					recordInfo = {}
					recordInfo.useNum = 0
					useInfo[refId] = recordInfo
				end
				record = recordInfo.useNum or 0
				recordInfo.useNum = record + useNum
			end
		end
	end
	return useMap
end

---- 一键选择
function ModelGolem:GetKeyChoiceeItemList(golemInfo,materialsList,selMaterialsList,addExp)
	if not golemInfo then return {} end
	if not materialsList or #materialsList < 1 then
		GF.ShowMessage(ccClientText(33270))
		return {}
	end
	addExp = addExp or 0
	local upLvNeedExp = self:GetUpLvToNextNeedExpByGolemInfoAndUseExp(golemInfo,addExp)
	if not upLvNeedExp then return {} end
	if upLvNeedExp < 1 then
		GF.ShowMessage(ccClientText(34801))
		return {}
	end
	selMaterialsList = selMaterialsList or {}
	local selGolemNum,recordSelMaterials = self:GetRecordSelMaterials(selMaterialsList)
	local selectUpper = self:GetGolemConfigRefByKey("selectUpper")
	local canSelItemNum = self:GetCanSelItemNum(materialsList,recordSelMaterials)
	if canSelItemNum < 1 and selGolemNum >= selectUpper then
		--- 没有道具可选择，且魔偶选择的数量已到达配置的同时选择魔偶个数上限
		return {}
	end
	local useMap = self:GetUseItemMap({
		lastLvExp = upLvNeedExp,
		materialsList = materialsList,
		recordSelMaterials = recordSelMaterials,
		selGolemNum = selGolemNum,
		selectUpper = selectUpper,
	})
	return useMap
end


---- 一键升级高级版，升到满级所需材料
function ModelGolem:GetKeyChoiceeItemPlusList(golemInfo,materialsList,selMaterialsList,addExp)
	if not golemInfo then return {} end
	if not materialsList or #materialsList < 1 then
		GF.ShowMessage(ccClientText(33270))
		return {}
	end
	local maxLvInfo = self:GetGolemLvGroupMaxInfoByGolemInfo(golemInfo)
	if not maxLvInfo then return {} end
	addExp = addExp or 0
	local golemExp = self:GetGolemExpByGolemInfo(golemInfo)
	golemExp = golemExp + addExp
	local upMaxExp = maxLvInfo.exp
	local upLvNeedExp = upMaxExp - golemExp
	if upLvNeedExp <= 0 then
		GF.ShowMessage(ccClientText(34801))
		return {}
	end
	selMaterialsList = selMaterialsList or {}
	local selGolemNum,recordSelMaterials = self:GetRecordSelMaterials(selMaterialsList)
	local selectUpper = self:GetGolemConfigRefByKey("selectUpper")
	local canSelItemNum = self:GetCanSelItemNum(materialsList,recordSelMaterials)
	if canSelItemNum < 1 and selGolemNum >= selectUpper then
		--- 没有道具可选择，且魔偶选择的数量已到达配置的同时选择魔偶个数上限
		return {}
	end
	local useMap = self:GetUseItemMap({
		lastLvExp = upLvNeedExp,
		materialsList = materialsList,
		recordSelMaterials = recordSelMaterials,
		selGolemNum = selGolemNum,
		selectUpper = selectUpper,
	})
	return useMap
end

function ModelGolem:GetAutoKeyChoiceeItemList(golemInfo,materialsList,selMaterialsList,addExp)
	local autoSelAllMaterials = self:GetGolemConfigRefByKey("autoSelAllMaterials")
	if not autoSelAllMaterials then
		if LOG_INFO_ENABLED then
			printInfoNR("打印而已，莫慌  GolemConfigRef 表格没有配置 autoSelAllMaterials 字段用于一键选择，1 标识选择至满级，没有配置默认为1")
		end
		autoSelAllMaterials = 1
	end
	if autoSelAllMaterials == 1 then
		--- 直接选择至满级
		return self:GetKeyChoiceeItemPlusList(golemInfo,materialsList,selMaterialsList,addExp)
	else
		--- 升到下一级
		return self:GetKeyChoiceeItemList(golemInfo,materialsList,selMaterialsList,addExp)
	end
end


function ModelGolem:GetIntensifyAllGolem()
	local golemList = self:GetGolemList()
	local allGolemList = self:GetCommonDisposeGolemBagList(golemList)
	if #allGolemList < 1 then
		return {
			status = -1
		}
	end

	local canIntensifyList = {}
	for i,v in ipairs(allGolemList) do
		if self:CheckGolemIsUpLvByGolemInfo(v) then
			table.insert(canIntensifyList,v)
		end
	end
	if #canIntensifyList < 1 then
		self:GetWarehouseSortGolemList(allGolemList)

		local first = allGolemList[1]
		local id = self:GetGolemIdByGolemInfo(first)
		return {
			golemId = id,
			golemInfo = first,
			status = 1
		}
	else
		self:GetWarehouseSortGolemList(canIntensifyList)

		local first = canIntensifyList[1]
		local id = self:GetGolemIdByGolemInfo(first)
		return {
			golemId = id,
			golemInfo = first,
			status = 1
		}
	end
end


--- 强化界面 英雄魔偶强化切换至单个魔偶强化时
function ModelGolem:GetIntensifyGolemId()
	local bagList = self:GetGolemBagList()
	if #bagList < 1 then
		return self:GetIntensifyAllGolem()
	end

	local allGolemList = self:GetCommonDisposeGolemBagList(bagList)
	self:GetWarehouseSortGolemList(allGolemList)

	local first = allGolemList[1]
	local id = self:GetGolemIdByGolemInfo(first)
	return {
		golemId = id,
		golemInfo = first,
		status = 1
	}
end


function ModelGolem:JumpDreamKillWnd(wndName)
	if not gModelFunctionOpen:CheckIsOpened(31000001,true) then return end
	gModelFunctionOpen:Jump(31000001, wndName)
end

-----------------------------------------------------------------------------------------
ModelGolem.SHARE_LIST_LINK = ","
ModelGolem.SHARE_KEY_VALUE_LINK = ":"
ModelGolem.SHARE_DATA_LINK = ";"

--- 将结构转为分享数据
function ModelGolem:ServerDataChangeToShareData(golemInfo)
	if not golemInfo then return "" end
	local serverList = {
		"id" .. ModelGolem.SHARE_KEY_VALUE_LINK .. self:GetGolemIdByGolemInfo(golemInfo),
		"refId" .. ModelGolem.SHARE_KEY_VALUE_LINK .. golemInfo.refId,
		"lvlRefId" .. ModelGolem.SHARE_KEY_VALUE_LINK .. self:GetGolemLvlRefIdByGolemInfo(golemInfo),
		"exp" .. ModelGolem.SHARE_KEY_VALUE_LINK .. self:GetGolemExpByGolemInfo(golemInfo),
		"mainAttrGroup" .. ModelGolem.SHARE_KEY_VALUE_LINK .. table.concat(self:GetGolemMainAttrGroupByGolemInfo(golemInfo),ModelGolem.SHARE_LIST_LINK),
		"viceAttrGroup" .. ModelGolem.SHARE_KEY_VALUE_LINK .. table.concat(self:GetGolemViceAttrGroupByGolemInfo(golemInfo),ModelGolem.SHARE_LIST_LINK),
		"heroId" .. ModelGolem.SHARE_KEY_VALUE_LINK .. self:GetGolemHeroIdByGolemInfo(golemInfo),
		"lockState" .. ModelGolem.SHARE_KEY_VALUE_LINK .. self:GetGolemLockStateByGolemInfo(golemInfo),
	}
	local str = table.concat(serverList,ModelGolem.SHARE_DATA_LINK)
	return str
end

--- 将分享数据转为结构
function ModelGolem:ShareDataChangeToServerData(golemInfoStr)
	if not golemInfoStr then return end
	local golemInfo = {}
	local key,tList
	local tGolemInfoStr = string.split(golemInfoStr,ModelGolem.SHARE_DATA_LINK)
	for i,v in ipairs(tGolemInfoStr) do
		v = string.split(v,ModelGolem.SHARE_KEY_VALUE_LINK)
		key = v[1]
		if key == "mainAttrGroup" then
			local mainAttrGroup = {}
			tList = string.split(v[2],ModelGolem.SHARE_LIST_LINK)
			for idx,val in ipairs(tList) do
				table.insert(mainAttrGroup,tonumber(val))
			end
			golemInfo.mainAttrGroup = mainAttrGroup
		elseif key == "viceAttrGroup" then
			local viceAttrGroup = {}
			tList = string.split(v[2],ModelGolem.SHARE_LIST_LINK)
			for idx,val in ipairs(tList) do
				table.insert(viceAttrGroup,tonumber(val))
			end
			golemInfo.viceAttrGroup = viceAttrGroup
		elseif key == "refId" or key == "lvlRefId" or key == "exp" or key == "lockState" then
			golemInfo[key] = tonumber(v[2])
		else
			golemInfo[key] = v[2]
		end
	end
	golemInfo.isLock = golemInfo.lockState == 1
	return golemInfo
end


function ModelGolem:GetShareHeroGolemSuitShow(golemList)
	local actSuitIdList = self:GetGolemActSuitList(golemList)
	local showList = {}
	if #actSuitIdList > 0 then
		local actType,suitRefId,showNumTxt,suitIcon
		for i,v in ipairs(actSuitIdList) do
			actType = v.actType
			suitRefId = v.suitRefId
			suitIcon = self:GetGolemSuitIconByRefId(suitRefId)
			if actType == ModelGolem.ACT_SKILL_NUM_TWO then
				showNumTxt = string.replace(ccClientText(33227),ModelGolem.SUIT_WEAR_2)
			elseif actType == ModelGolem.ACT_SKILL_NUM_ONE then
				showNumTxt = string.replace(ccClientText(33227),ModelGolem.SUIT_WEAR_1)
			end
			table.insert(showList,{
				showNumTxt = showNumTxt,
				icon = suitIcon,
			})
		end
	end
	return showList
end


function ModelGolem:GetShareHeroGolemList(golemList)
	golemList = golemList or {}
	local golemDrawing
	local posGolemList = {}
	for k,v in pairs(golemList) do
		golemDrawing = self:GetGolemElementGolemDrawingByGolemInfo(v)
		posGolemList[golemDrawing] = v
	end
	local list = {}
	local serverData
	for i = 1,ModelGolem.SHOW_GOLEM_NUM do
		serverData = posGolemList[i]
		local data = {}
		local isEmpty = serverData == nil
		if not isEmpty then
			data.serverData = serverData
		end
		data.isEmpty = isEmpty
		table.insert(list,data)
	end
	return list
end

-----------------------------------------------------------------------------------------
function ModelGolem:GetUpLvItemList(extraList)
	local list = {}
	local golemItemList = gModelItem:GetGolemExpItemList()
	local refId,haveNum
	for i,v in ipairs(golemItemList) do
		refId = v.refId
		haveNum = gModelItem:GetNumByRefId(refId)
		if haveNum > 0 then
			if gModelItem:CheckIsGolemExpRefId(refId) then
				table.insert(list,{
					useType = ModelGolem.TYPE_MATERIAL_ITEM,
					info = {
						itemType = LItemTypeConst.TYPE_ITEM,
						itemId = refId,
						haveNum = haveNum,
						conversionExp = v.conversionExp,
						order = v.order,
					},
				})
			else
				table.insert(list,{
					useType = ModelGolem.TYPE_MATERIAL_ITEMGOLEM,
					info = {
						itemType = LItemTypeConst.TYPE_ITEM,
						itemId = refId,
						haveNum = haveNum,
						conversionExp = v.conversionExp,
						order = v.order,
					},
				})
			end
		end
	end
	local golemList = self:GetGolemIntensifyList(nil,extraList)
	for i,v in ipairs(golemList) do
		table.insert(list,{
			useType = ModelGolem.TYPE_MATERIAL_GOLEM,
			info = {
				serverData = v,
			},
		})
	end
	return list
end


--- 是否有可穿戴的装备
function ModelGolem:CheckPosCanWearGolemStatus(golemDrawing)
	local bagList = self:GetGolemBagList({
		needGolemDrawing = golemDrawing
	})
	return #bagList > 0
end


function ModelGolem:CheckGolemIsUpLvByGolemInfo(golemInfo)
	if not golemInfo then return false end
	local lostExp = self:GetUpLvToNextNeedExpByGolemInfo(golemInfo)
	if lostExp < 1 then return false end
	local id = self:GetGolemIdByGolemInfo(golemInfo)
	local materialsList = self:GetUpLvItemList({
		[id] = true,
	})
	if #materialsList < 1 then return false end
	local useType,info,conversionExp,haveNum,serverData,itemId
	local tempUseNum,canUseItemNum
	local recordPayMap = {}
	local golemId
	for i,v in ipairs(materialsList) do
		if lostExp < 1 then
			break
		end
		useType = v.useType
		info = v.info

		local recordPayInfo = recordPayMap[useType]
		if not recordPayInfo then
			recordPayInfo = {}
			recordPayMap[useType] = recordPayInfo
		end

		if useType == ModelGolem.TYPE_MATERIAL_GOLEM then
			serverData = info.serverData
			golemId = self:GetGolemIdByGolemInfo(serverData)
			recordPayInfo[golemId] = serverData

			local golemChangeExp = self:GetGolemInfoChangeToExp(serverData)
			if golemChangeExp >= lostExp then
				lostExp = -1
				break
			else
				lostExp = lostExp - golemChangeExp
			end
		else
			itemId = info.itemId
			conversionExp = info.conversionExp
			haveNum = info.haveNum
			local oldUseExpNum = recordPayInfo[itemId] or 0
			if conversionExp > lostExp then
				recordPayInfo[itemId] = oldUseExpNum + conversionExp
				lostExp = -1
				break
			else
				tempUseNum = math.floor(lostExp / conversionExp)
				if tempUseNum > haveNum then
					canUseItemNum = haveNum
				else
					local tUpExp = tempUseNum * conversionExp
					if lostExp - tUpExp > 0 then
						if tempUseNum + 1 <= haveNum then
							tempUseNum = tempUseNum + 1
						end
					end
					canUseItemNum = tempUseNum
				end
				local payExp = conversionExp * canUseItemNum
				recordPayInfo[itemId] = oldUseExpNum + payExp

				lostExp = lostExp - payExp
			end
		end
	end
	local payIsFull = lostExp < 1
	if payIsFull then
		local payKeyList = {}
		local payItemId,recordNum
		local recordFunc = function(tPayList)
			for i,v in ipairs(tPayList) do
				payItemId = v.itemId
				recordNum = payKeyList[payItemId] or 0
				payKeyList[payItemId] = recordNum + v.itemNum
			end
		end
		local tempList
		for tUseType,data in pairs(recordPayMap) do
			if tUseType == ModelGolem.TYPE_MATERIAL_GOLEM then
				for tGolemId,tGolemInfo in pairs(data) do
					tempList = self:GetGolemInfoChangeToPayItemList(tGolemInfo)
					recordFunc(tempList)
				end
			else
				for tItemId,tConversionExp in pairs(data) do
					tempList = self:GetUseItemToPayItemListByExp(tConversionExp)
					recordFunc(tempList)
				end
			end
		end

		local payList = {}
		for k,v in pairs(payKeyList) do
			table.insert(payList,{
				itemType = LItemTypeConst.TYPE_ITEM,
				itemId = k,
				itemNum = v,
			})
		end
		payIsFull = gModelGeneral:CheckItemListEnoughStatus(payList)
	end
	return payIsFull
end

function ModelGolem:CheckGolemIsCanUpLvStatus(golemInfo)
	if not self:CheckGolemIsOpen() then
		return false
	end
	if not golemInfo then
		return false
	end

	if not self:CheckGolemRedRecord(golemInfo.id) then
		return false
	end

	if self:CheckGolemIsMaxLevelByGolemInfo(golemInfo) then
		return false
	end
	return self:CheckGolemIsUpLvByGolemInfo(golemInfo)
end

function ModelGolem:InitGolemRedRecord()
	if self._golemRedRecord then
		return
	end

	local record = {}
	if not string.isempty(LPlayerPrefs.golemRedRecord) then
		record = JSON.decode(LPlayerPrefs.golemRedRecord)
	end

	self._golemRedRecord = record
end

function ModelGolem:SaveGolemRedRecord(id)
	self:InitGolemRedRecord()
	self._golemRedRecord[id]= GetTimestamp()

	local str = JSON.encode(self._golemRedRecord)
	LPlayerPrefs.SetGolemRedRecord(str)
end

function ModelGolem:CheckGolemRedRecord(id)
	self:InitGolemRedRecord()
	local record = self._golemRedRecord[id]
	if not record then
		return true
	end
	local dayPast = LUtil.GetDayPast(record)
	return dayPast > 1
end


function ModelGolem:CheckGolemIsCanUpLvStatusByHeroId(wearHeroId)
	if not self:CheckGolemIsOpen() then return false end
	if not wearHeroId then return false end
	local wearMap,wearList = self:GetHeroWearGolemListByHeroId(wearHeroId)
	if #wearList < 1 then return false end
	for i,v in ipairs(wearList) do
		if self:CheckGolemIsCanUpLvStatus(v.golemInfo) then return true end
	end
	return false
end

--- 通过结构去找
function ModelGolem:CheckHeroGolemStatusByHeroStruct(hero)
	if not self:CheckGolemIsOpen() then return false end
	if not hero then return false end
	if not self:CheckHeroIsShowAndWearByHeroStruct(hero) then
		return false
	end
	local heroId = hero:GetId()
	local wearMap,wearList = self:GetHeroWearGolemListByHeroId(heroId)
	--- 先判断部位是否有穿戴
	for i = 1,ModelGolem.SHOW_GOLEM_NUM do
		if not wearMap[i] and self:CheckPosCanWearGolemStatus(i) then
			return true
		end
	end
	return self:CheckGolemIsCanUpLvStatusByHeroId(heroId)
end

--- 通过英雄Id
function ModelGolem:CheckHeroGolemStatusByHeroId(heroId)
	if not self:CheckGolemIsOpen() then return false end
	if not heroId then return false end
	local heroStruct = gModelHero:GetHeroById(heroId)
	return self:CheckHeroGolemStatusByHeroStruct(heroStruct)
end

function ModelGolem:GetBagSaveNum()
	return self:GetGolemConfigRefByKey("golemBagLimit")
end

function ModelGolem:OpenBagFullTips(wndName)

	local gotoFunc = function()
		--[[			self:OpenGolemWarehouse({
                        viewType = 2,
                        optType = 2,
                    })]]
		--- jh   修改为跳转到背包
		local jumpId = 10700000
		if gModelFunctionOpen:CheckIsOpened(jumpId,true) then
			gModelFunctionOpen:Jump(jumpId, wndName)
		end
	end
	gModelGeneral:OpenUIOrdinTips({refId = 310005,func = gotoFunc})
end

function ModelGolem:CheckIsBagFull(addNum,func,wndName)
	if not addNum then
		if func then func() end
		return
	end
	local golemBagLimit = self:GetBagSaveNum()
	local bagList = self:GetGolemBagList()
	local newNum = #bagList + addNum
	if newNum > golemBagLimit then
		self:OpenBagFullTips(wndName)
	else
		if func then func() end
	end
end

function ModelGolem:OpenGolemResolveTips(golemInfo)
	if not golemInfo then return end
	if self:GetGolemIsLockByGolemInfo(golemInfo) then
		GF.ShowMessage(ccClientText(33296))
		return
	end
	local golemChangeExp = self:GetGolemInfoChangeToExp(golemInfo)
	local func = function()
		local id = self:GetGolemIdByGolemInfo(golemInfo)
		gModelGolem:OnGolemDissolveReq({id})
	end
	local itemName = gModelItem:GetNameByRefId(ModelItem.GOLEM_EXP_ITEM)
	local numStr = LUtil.NumberCoversion(golemChangeExp)
	local showStr = string.format("%s*%s",itemName,numStr)
	gModelGeneral:OpenUIOrdinTips({refId = 310007,para = {showStr},func = func})
end

-------------------------------------------------------------------------------------------------
--- 9.7
function ModelGolem:GetMaterialsChangeToExp(useType,info)
	if useType == ModelGolem.TYPE_MATERIAL_ITEM or useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
		return self:GetUseItemToExp({itemId = info.itemId,useNum = info.useNum})
	elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
		return self:GetGolemInfoChangeToExp(info.golemInfo)
	end
	return 0
end

function ModelGolem:GetMaterialsChangeToPayList(useType,info)
	if useType == ModelGolem.TYPE_MATERIAL_ITEM or useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
		return self:GetUseItemToPayItemList({itemId = info.itemId,useNum = info.useNum})
	elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
		return self:GetGolemInfoChangeToPayItemList(info.golemInfo)
	end
	return {}
end

function ModelGolem:GetAllPayMaterialsChangeToExp(selIntensifyMaterials)
	local useExpNum = 0
	local selIdList
	for useType,useTypeInfo in pairs(selIntensifyMaterials) do
		selIdList = useTypeInfo.selIdList
		if useType == ModelGolem.TYPE_MATERIAL_ITEM then
			if useTypeInfo.selNum > 0 then
				for itemId,useNum in pairs(selIdList) do
					useExpNum = useExpNum + self:GetMaterialsChangeToExp(useType,{itemId = itemId,useNum = useNum})
				end
			end
		elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
			for golemId,golemInfo in pairs(selIdList) do
				useExpNum = useExpNum + self:GetMaterialsChangeToExp(useType,{golemInfo = golemInfo})
			end
		elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
			if useTypeInfo.selNum > 0 then
				for itemId,useInfo in pairs(selIdList) do
					useExpNum = useExpNum + self:GetMaterialsChangeToExp(useType,{itemId = itemId,useNum = useInfo.useNum})
				end
			end
		end
	end
	return useExpNum
end

function ModelGolem:GetAllPayMaterialsChangeToPayList(selIntensifyMaterials)
	local selIdList
	local tempList
	local payKeyList = {}
	local payItemId,recordNum

	local recordFunc = function(tPayList)
		for i,v in ipairs(tPayList) do
			payItemId = v.itemId
			recordNum = payKeyList[payItemId] or 0
			payKeyList[payItemId] = recordNum + v.itemNum
		end
	end

	for useType,useTypeInfo in pairs(selIntensifyMaterials) do
		selIdList = useTypeInfo.selIdList
		if useType == ModelGolem.TYPE_MATERIAL_ITEM then
			if useTypeInfo.selNum > 0 then
				for itemId,useNum in pairs(selIdList) do
					tempList = self:GetMaterialsChangeToPayList(useType,{itemId = itemId,useNum = useNum})
					recordFunc(tempList)
				end
			end
		elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
			for golemId,golemInfo in pairs(selIdList) do
				tempList = self:GetMaterialsChangeToPayList(useType,{golemInfo = golemInfo})
				recordFunc(tempList)
			end
		elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
			if useTypeInfo.selNum > 0 then
				for itemId,useInfo in pairs(selIdList) do
					tempList = self:GetMaterialsChangeToPayList(useType,{itemId = itemId,useNum = useInfo.useNum})
					recordFunc(tempList)
				end
			end
		end
	end
	local payList = {}
	for k,v in pairs(payKeyList) do
		table.insert(payList,{
			itemType = LItemTypeConst.TYPE_ITEM,
			itemId = k,
			itemNum = v,
		})
	end
	return payList
end

function ModelGolem:GetGolemRecastMainAttrListByGolemInfo(golemInfo)
	local recastMainAttr = self:GetGolemRecastMainAttrByGolemInfo(golemInfo)
	return self:GetGolemAttrListByGolemInfo(recastMainAttr,ModelGolem.GOLEM_DIV_ATTR_PRIME)
end

function ModelGolem:GetGolemRecastViceAttrListByGolemInfo(golemInfo)
	local recastViceAttrGroup = self:GetGolemRecastViceAttrGroupByGolemInfo(golemInfo)
	return self:GetGolemAttrListByGolemInfo(recastViceAttrGroup,ModelGolem.GOLEM_DIV_ATTR_DEPUTY)
end

function ModelGolem:GetGolemRecastAllAttrList(golemInfo)
	if not golemInfo then return {} end
	local recastMainAttrList = self:GetGolemRecastMainAttrListByGolemInfo(golemInfo)
	local recastViceAttrList = self:GetGolemRecastViceAttrListByGolemInfo(golemInfo)
	return self:GetTwoAttrList(recastMainAttrList,recastViceAttrList)
end

function ModelGolem:GetGolemLockInfoNum(golemInfo)
	return ModelGolem.RECAST_LOCKINFO_NUM
end

function ModelGolem:GetGolemStars()
	return self:GetGolemConfigRefByKey("golemStars") or 5
end

function ModelGolem:GetRecastMaterialsList(extraData)
	extraData = extraData or {}
	local golemServerData = extraData.golemServerData
	local typeBig
	local ignoreId
	if golemServerData then
		ignoreId = self:GetGolemIdByGolemInfo(golemServerData)
		typeBig = self:GetGolemElementTypeBigByGolemInfo(golemServerData)
	end
	local recastType = extraData.recastType or ModelGolem.RECAST_TYPE_BASE
	local golemStars = self:GetGolemStars()
	local isInBag,isIns
	local golemStar
	local list = {}
	local golemList = self:GetGolemList()
	for golemId,golemInfo in pairs(golemList) do
		isInBag = self:CheckGolemIsNotWearByGolemInfo(golemInfo)
		if isInBag then
			if ignoreId then
				isIns = golemId ~= ignoreId
			else
				isIns = true
			end
			if isIns and typeBig then
				if recastType == ModelGolem.RECAST_TYPE_HIGH then
					--- 同名魔偶用 typeBig 字段区分
					isIns = typeBig == self:GetGolemElementTypeBigByGolemInfo(golemInfo)
				end
			end
			if isIns then
				golemStar = self:GetGolemElementStarByGolemInfo(golemInfo) or 0
				if golemStar >= golemStars then
					table.insert(list,golemInfo)
				end
			end
		end
	end
	local allGolemList = self:GetCommonDisposeGolemBagList(list)
	self:GetGeneralSortGolemList(allGolemList)
	return allGolemList
end


function ModelGolem:CheckGolemIsLevelFullByGolemInfo(golemInfo)
	if not golemInfo then return false end

	local maxLvInfo = self:GetGolemLvGroupMaxInfoByGolemInfo(golemInfo)
	if not maxLvInfo then return false end

	local level = maxLvInfo.level
	local golemLvl = self:GetGolemLvlByGolemInfo(golemInfo)
	return level == golemLvl
end

--- 排除了锁定的魔偶
function ModelGolem:GetAutoWearGolemBagList(extraData)
	extraData = extraData or {}
	local golemDrawingList = self:GetGolemBagList(extraData)
	if #golemDrawingList < 1 then return {} end
	local list = {}
	for i,v in ipairs(golemDrawingList) do
		if not self:GetGolemIsLockByGolemInfo(v) then
			table.insert(list,v)
		end
	end
	return list
end

function ModelGolem:CheckGolemHaveExtraExpByGolemInfo(golemInfo)
	if not golemInfo then return false end
	local exp = self:GetGolemExpByGolemInfo(golemInfo)
	if exp < 1 then return false end
	return true
end

function ModelGolem:GetResolveExpItemId()
	local resolveExpItemId = self:GetGolemConfigRefByKey("resolveExpItemId")
	if not resolveExpItemId then
		resolveExpItemId = ModelItem.GOLEM_EXP_ITEM
		if LOG_INFO_ENABLED then
			printInfoNR("GolemConfigRef 表可配置 resolveExpItemId 字段，表示分解获得道具，目前默认道具id为：" .. resolveExpItemId)
		end
	end
	return tonumber(resolveExpItemId)
end

function ModelGolem:CheckIsHaveResolveExp(consumeGolem,func)
	consumeGolem = consumeGolem or {}
	if #consumeGolem < 1 then
		if func then func() end
		return
	end
	local serverData
	local serverDataExpList = {}
	for i,v in ipairs(consumeGolem) do
		serverData = self:GetGolemServerDataById(v)
		if serverData then
			if self:CheckGolemHaveExtraExpByGolemInfo(serverData) then
				table.insert(serverDataExpList,serverData)
			end
		end
	end
	if #serverDataExpList < 1 then
		if func then func() end
		return
	end
	local resolveExpNum = 0
	for i,golemInfo in ipairs(serverDataExpList) do
		resolveExpNum = resolveExpNum + self:GetGolemInfoChangeToExp(golemInfo)
	end
	if resolveExpNum < 1 then
		if func then func() end
		return
	end
	local resolveExpItemId = self:GetResolveExpItemId()
	local resolveExpItemName = gModelItem:GetNameByRefId(resolveExpItemId)
	--local resolveExpNumStr = LUtil.NumberCoversion(resolveExpNum)
    --- 2023/03/16  jh:统一不转化 310024 和 310026
	local resolveExpNumStr = tostring(resolveExpNum)
	gModelGeneral:OpenUIOrdinTips({refId = 310024,para = {resolveExpItemName .. "*" .. resolveExpNumStr},func = func})
end

function ModelGolem:CheckIntensifyResolveExp(consumeGolem,func)
	self:CheckIsHaveResolveExp(consumeGolem,func)
end

function ModelGolem:CheckIntensifyHaveHeightGolem(consumeGolem,func)
	consumeGolem = consumeGolem or {}
	if #consumeGolem < 1 then
		if func then func() end
		return
	end
	local golemStars = self:GetGolemStars()
	local serverData,golemStar
	local heightGolemList = {}
	for i,v in ipairs(consumeGolem) do
		serverData = self:GetGolemServerDataById(v)
		if serverData then
			golemStar = self:GetGolemElementStarByGolemInfo(serverData)
			if golemStar >= golemStars then
				table.insert(heightGolemList,serverData)
			end
		end
	end
	if #heightGolemList < 1 then
		if func then func() end
		return
	end
	gModelGeneral:OpenUIOrdinTips({refId = 310025,func = func})
end


function ModelGolem:CheckRecastGolemResolveExp(consumeGolem,func)
	self:CheckIsHaveResolveExp(consumeGolem,func)
end


--- 魔偶转换经验
function ModelGolem:GetRecastGolemInfoChangeToExp(golemInfo)
	local exp = self:GetGolemExpByGolemInfo(golemInfo)
	local lastExp = 0
	if exp > 0 then
		local quality = self:GetGolemElementQualityByRefId(golemInfo.refId)
		local configExpRestitutionKey = self._configExpRestitutionKey
		local expRes = configExpRestitutionKey[quality] or 1
		lastExp = expRes * exp
        --- 2023/03/16  jh:单个向下取整
        lastExp = math.floor(lastExp)
	end
	return lastExp
end

function ModelGolem:CheckRecastGolemIsHaveIntensifyGolem(golemId,consumeGolemIdList,lockInfosList)
	lockInfosList = lockInfosList or {}
	local serverData
	local hasExpGolemList = {}
	for i,v in ipairs(consumeGolemIdList) do
		serverData = self:GetGolemServerDataById(v)
		if self:CheckGolemHaveExtraExpByGolemInfo(serverData) then
			table.insert(hasExpGolemList,serverData)
		end
	end
	local func = function()
		self:OnGolemRecastReq(golemId,consumeGolemIdList,lockInfosList)
	end
	if #hasExpGolemList < 1 then
		self:CheckRecastGolemResolveExp(consumeGolemIdList,func)
		return
	end
	local resolveExpNum = 0
	for i,golemInfo in ipairs(hasExpGolemList) do
		resolveExpNum = resolveExpNum + self:GetRecastGolemInfoChangeToExp(golemInfo)
	end
	if resolveExpNum < 1 then
		if func then func() end
		return
	end
	local resolveExpItemId = self:GetResolveExpItemId()
	local resolveExpItemName = gModelItem:GetNameByRefId(resolveExpItemId)
	--local resolveExpNumStr = LUtil.NumberCoversion(resolveExpNum)
    --- 2023/03/16  jh:统一不转化 310024 和 310026
    local resolveExpNumStr = tostring(resolveExpNum)
	gModelGeneral:OpenUIOrdinTips({refId = 310026,para = {resolveExpItemName .. "*" .. resolveExpNumStr},func = func})
end

--清理工作
--停止计时器之类的
function ModelGolem:OnModelClear()
end

function ModelGolem:IsStrengthed(id)
	local golem = self:GetGolemServerDataById(id)
	if golem.exp > 0 then
		return true
	end
	local lv = golem:GetLv()
	if lv and lv > 0 then
		return true
	end

	return false

end

function ModelGolem:GetBackGolemList()
	---@type StructGolemInfo[]
	local dataList = {}
	local golemList = self:GetGolemList()
	for k,v in pairs(golemList) do
		if self:IsStrengthed(v.id) then
			table.insert(dataList,v)
		end
	end

	table.sort(dataList,function (a,b)
		if a:GetLv() ~= b:GetLv() then
			return a:GetLv() > b:GetLv()
		end

		if a:GetStar() ~= b:GetStar() then
			return a:GetStar() > b:GetStar()
		end

		local aEquip = a:IsEquip() and 0 or 1
		local bEquip = b:IsEquip() and 0 or 1
		if aEquip ~= bEquip then
			return aEquip < bEquip
		end

		return a.refId < b.refId
	end)

	return dataList
end

function ModelGolem:GetReturnItem(id)
	local golem = self:GetGolemServerDataById(id)

	local totalExp = golem.exp

	local backItems = self:GetParaConfigValueImpl(ModelGolem.GolemConfigRef,"golemReturnItem",function (value) return LxDataHelper.ParseItem(value) end)

	for k,v in ipairs(backItems) do

		v.itemNum = totalExp * v.itemNum
	end

	return backItems
end

function ModelGolem:GetReturnConsume()
	return self:GetParaConfigValueImpl(ModelGolem.GolemConfigRef,"golemReturnExpend",function (value) return LxDataHelper.ParseItem_4(value) end)
end


function ModelGolem:GetSuitByType(type)
    local list = self._initGolemSuitTypeList[type]
    if not list then
        return
    end

    return list[1]
end

function ModelGolem:FormatDefaultGolem(refId)

	local ref = self:GetGolemElementRefByRefId(refId)

	local lvGroup = ref.lvrGroupId
	local lvRef = self:GetGolemLvInfoByLvrGroupIdAndLv(lvGroup,0)
	local default = {
		refId = refId,
		lvlRefId = lvRef.refId,
		lvl = 0,
		displayPos = gModelGolem:GetGolemElementGolemDrawingIconByRefId(refId),
	}

	return default
end

function ModelGolem:GetDefaultLvRef(refId)
	local ref = gModelGolem:GetGolemElementRefByRefId(refId)
	local lvGroup = ref.lvrGroupId
	local lvRef = gModelGolem:GetGolemLvInfoByLvrGroupIdAndLv(lvGroup,0)
	return lvRef
end

function ModelGolem:GetDefaultAttrRef(refId,lv)
	local ref = GameTable.GolemAttrRef[refId]
	if not ref then
		return
	end
	local attrGroupId = ref.attrGroupId
	return self:GetGolemAttrRefByAttrGroupIdAndLv(attrGroupId,lv)
end

return ModelGolem