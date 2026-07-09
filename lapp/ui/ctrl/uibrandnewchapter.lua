---
--- Created by Administrator.
--- DateTime: 2024/7/5 15:43:25
---
------------------------------------------------------------------
local LWnd = LWnd
local typeofCanvas = typeof(UnityEngine.Canvas)
---@class UIBrandNewChapter:LWnd
local UIBrandNewChapter = LxWndClass("UIBrandNewChapter", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandNewChapter:UIBrandNewChapter()
	self._effectKey = "newChapterEff"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandNewChapter:OnWndClose()
	LWnd.OnWndClose(self)
	self:TweenSeqKill(self._effectKey)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandNewChapter:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandNewChapter:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndClick(self.mImgMask,function() 
		self:CreateEffect(self.mEffectCloud,"guochangdonghua_2",nil,nil,function() 
			self:OnEffectLoaded()
		end)
	end)
	self.newChapterId = self:GetWndArg("newChapterId")
	self:initPanel()
end

function UIBrandNewChapter:CreateEffect(trans,effectName,effectKey,effectSize,endFunc)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans,effectName,effectKey,effectSize,false,false,nil,nil,nil,nil,nil,endFunc)
end

function UIBrandNewChapter:PlayEffect(isMaxChapter)
	local seqTween
	self:TweenSeqKill(self._effectKey)
	seqTween = self:TweenSeqCreate(self._effectKey,function(seq)
		local showTopTime = 0.8
		seq:AppendInterval(showTopTime)
		seq:AppendCallback(function ()
			CS.ShowObject(self.mItemTxt1,true)
			CS.ShowObject(self.mItemTxt2,true)
			if not isMaxChapter then CS.ShowObject(self.mItemTxt3,true) end
		end)
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
	end)
	gLGameAudio:PlaySound("SoundS_14")
end
function UIBrandNewChapter:initPanel()
	local newChapterId = self.newChapterId
	local chapterCfg = GameTable.BadgeGameChapRef[newChapterId]
	local chapterType = gModelBadgeGame:GetBadgeGameChapRefType(newChapterId)
	local starImgInfo = ModelBadgeGame.StarImgMap[chapterType]
	if starImgInfo then
		self:SetWndEasyImage(self.mStarImg,starImgInfo.Act)
	end

	local oldChapter = newChapterId-1
	local oldChapterInfo = gModelBadgeGame:GetChapterById(oldChapter)
	local oldChapterCfg = GameTable.BadgeGameChapRef[oldChapter]

	local starRef = LxDataHelper.ParseNumber_Sign(GameTable.BadgeGameConfigRef.boxStar)
	local maxStar = starRef[#starRef]
	local oldName = oldChapterCfg and ccLngText(oldChapterCfg.name) or ""
	local newName = chapterCfg and ccLngText(chapterCfg.name) or ""
	self:SetWndText(self.mItemTxt1,string.replace(ccClientText(40234),oldName))
	self:SetWndText(self.mTxtStarTitle,ccClientText(40235))
	if oldChapterInfo then self:SetWndText(self.mTxtStar,oldChapterInfo.starNum.."/"..maxStar)  end
	self:SetWndText(self.mItemTxt3,string.replace(ccClientText(40236),newName))
	self:SetWndText(self.mCloseInfo,ccClientText(41037))
	local isMaxChapter = chapterCfg.nextChapter<=0
	self:CreateEffect(self.mEffect,"fx_ui_glfx_tanchuang",nil,100,function(effObj)
		if effObj then
			local LH = self:FindWndTrans(effObj.transform,"LH")
			if LH then
				local instanceId = LH:GetInstanceID()
				local dpSpine = self:CreateWndSpine(LH,oldChapterCfg.LH,instanceId,true,function (dpLoaded)
					dpLoaded:PlayAnimation(0,"idle",true)
					dpLoaded:SetScale(0.01)

					local canvas = LH.gameObject:AddComponent(typeofCanvas)
					canvas.overrideSorting = true
					canvas.sortingLayerName = self:GetWndSortLayer()
					canvas.sortingOrder = self:GetWndSortOrder()+2
				end,true)
				dpSpine:StartLoad()
			end
			local wz1 = self:FindWndTrans(effObj.transform,"1")
			if wz1 then
				self.mItemTxt1:SetParent(wz1)
				self.mItemTxt1.localPosition = Vector3(0,0,0)
				local canvas = self.mItemTxt1.gameObject:AddComponent(typeofCanvas)
				canvas.overrideSorting = true
				canvas.sortingLayerName = self:GetWndSortLayer()
				canvas.sortingOrder = self:GetWndSortOrder()+6
				CS.ShowObject(self.mItemTxt1,false)
			end
			local wz2 = self:FindWndTrans(effObj.transform,"2")
			if wz2 then
				self.mItemTxt2:SetParent(wz2)
				self.mItemTxt2.localPosition = Vector3(0,0,0)
				local canvas = self.mItemTxt2.gameObject:AddComponent(typeofCanvas)
				canvas.overrideSorting = true
				canvas.sortingLayerName = self:GetWndSortLayer()
				canvas.sortingOrder = self:GetWndSortOrder()+6
				CS.ShowObject(self.mItemTxt2,false)
			end
			local wz3 = self:FindWndTrans(effObj.transform,"3")
			if wz3 and not isMaxChapter then
				self.mItemTxt3:SetParent(wz3)
				self.mItemTxt3.localPosition = Vector3(0,0,0)
				local canvas = self.mItemTxt3.gameObject:AddComponent(typeofCanvas)
				canvas.overrideSorting = true
				canvas.sortingLayerName = self:GetWndSortLayer()
				canvas.sortingOrder = self:GetWndSortOrder()+6
				CS.ShowObject(self.mItemTxt3,false)
			else
				CS.ShowObject(wz3,false)
			end

			self:PlayEffect(isMaxChapter)
		end
	end)
	self:CreateEffect(self.mEffectLove,"fx_ui_gongluefangxin")
end
function UIBrandNewChapter:OnEffectLoaded()
	local seq = self:GetSeqCom()
	local key = "guochangdonghua_2"
	local sequence = seq:CreateSeq(key)
	sequence:AppendInterval(0.8)
	sequence:OnComplete(function()
		seq:DeleteSeq(key)
		local newChapterId = self.newChapterId
		self:WndClose()
		GF.OpenWnd("UIBrandGameWin",{
			chapterId = newChapterId,
			chapterType = gModelBadgeGame:GetBadgeGameChapRefType(newChapterId),
			isSel = true,
		})
	end)
	sequence:PlayForward()
	CS.ShowObject(self.mEffect,false)
	CS.ShowObject(self.mCloseInfo,false)
end

return UIBrandNewChapter