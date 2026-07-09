---
--- Created by Administrator.
--- DateTime: 2023/10/6 10:55:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuBreakVdo:LWnd
local UISuBreakVdo = LxWndClass("UISuBreakVdo", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuBreakVdo:UISuBreakVdo()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuBreakVdo:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuBreakVdo:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuBreakVdo:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitUIEvent()
	self:SetStaticContent()
	self:InitEvent()
	self:OnWndRefresh()
end

function UISuBreakVdo:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootBgImage = self:FindWndTrans(AniRoot,"BgImage")
	local AniRootTitleImg = self:FindWndTrans(AniRoot,"TitleImg")
	local AniRootTitle = self:FindWndTrans(AniRoot,"title")
	local AniRootName = self:FindWndTrans(AniRoot,"name")
	local AniRootBtnDetail = self:FindWndTrans(AniRoot,"btnDetail")
	local btnDetailUIText = self:FindWndTrans(AniRootBtnDetail,"UIText")
	local AniRootPower = self:FindWndTrans(AniRoot,"power")
	local AniRootTag = self:FindWndTrans(AniRoot,"tag")


	local headTran = self:FindWndTrans(AniRoot,"HeadIcon")
	local playerData = itemdata:GetOppositePlayer(self._playerId)
	local playerInfo =
	{
		trans = headTran,
		icon = playerData.head,
		headFrame = playerData.headFrame,
		level = playerData.grade,
		func = function()
			gModelGeneral:PlayerShowReq(playerData.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}
	self:CreateHeadIconImpl(playerInfo)

	local str = string.replace(ccClientText(25112),itemdata.rank)
	self:SetWndText(AniRootTitle,str)

	self:SetWndText(AniRootName,playerData.name)
	local powerStr = string.replace(ccClientText(25113),LUtil.NumberCoversion(playerData.power))
	self:SetWndText(AniRootPower,powerStr)

	self:SetWndText(btnDetailUIText,ccClientText(25114))

	self:SetWndClick(AniRootBtnDetail,function () self:OpenDetail(itemdata) end)
	local winner = itemdata:GetWinnerPlayer()
	local isWin = winner.playerId == self._playerId
	local iconpath = isWin and "bestronger_txt_1" or "bestronger_txt_2"

	self:SetWndEasyImage(AniRootTag,iconpath)
end

function UISuBreakVdo:OpenDetail(itemdata)
	GF.OpenWnd("UIFightRecordMulti",{battleInfo = itemdata})
end

function UISuBreakVdo:OnDataRet(pb)

	local dataList = {}

	for k,v in ipairs(pb.infos) do
		local data = StructSimulateBattleInfo:New()
		data:CreateByPb(v)
		data.rank = pb.ranks[k]

		table.insert(dataList,data)
	end

	self._battleInfos = dataList

	self:RefreshList()
end

function UISuBreakVdo:RefreshList()

	local dataList  = self._battleInfos


	local uiList = self:FindUIScroll("uiList")
	if not uiList then
		uiList= self:GetUIScroll("uiList")
		uiList:Create(self.mReportList,dataList,function (...) self:OnDrawItem(...)  end,UIItemList.SUPER)
	else
		uiList:RefreshList(dataList)
	end

	uiList:DrawAllItems(false)
end

function UISuBreakVdo:InitEvent()
	self:WndNetMsgRecv(LProtoIds.SimulateCombatListResp,function (pb)
		self:OnDataRet(pb)
	end)
end

function UISuBreakVdo:SetStaticContent()
	local str =ccClientText(25111) --"突围赛录像"
	self:SetWndText(self.mLblBiaoti,str)

end

function UISuBreakVdo:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
end


function UISuBreakVdo:OnWndRefresh()
	local playerId = self:GetWndArg("playerId")
	self._playerId = playerId
	gModelSimuFight:OnSimulateCombatListReq(playerId)
end


------------------------------------------------------------------
return UISuBreakVdo


