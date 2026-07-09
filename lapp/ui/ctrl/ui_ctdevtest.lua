---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UI_CTDevTest:LWnd
local UI_CTDevTest = LxWndClass("UI_CTDevTest", LWnd)
------------------------------------------------------------------

--- 绐楀彛鎴愬憳鍙橀噺鍒濆鍖?
--- 鎵€鏈夌敤鍒扮殑鍙橀噺閮介渶瑕佸湪姝ゅ０鏄庯紝鍒濆鍖栨暟鍊肩被鍨嬪敖閲忎笉瑕佷娇鐢╰able
------------------------------------------------------------------
function UI_CTDevTest:UI_CTDevTest()
	---@type table<number,CommonIcon>
	self._itemIconList = {}
end
------------------------------------------------------------------
--- 绐楀彛鍏抽棴
--- 澶勭悊鎴愬憳鍙橀噺閿€姣佸伐浣?
------------------------------------------------------------------
function UI_CTDevTest:OnWndClose()
	self:ClearCommonIconList(self._itemIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 绐楀彛鍒涘缓寮€濮?
--- 澶勭悊绐楀彛灞炴€ц缃垨涓€浜涙潯浠舵娴?
------------------------------------------------------------------
function UI_CTDevTest:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 绐楀彛鍒涘缓缁撴潫
--- 澶勭悊绐楀彛鏁版嵁鍒濆鍖?
------------------------------------------------------------------
function UI_CTDevTest:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:RegisterEvent()

	self.mVideoNameInput.text = "video_op_1.mp4"

	local effectName
	-- effectName = "fx_fengyouling_skill1_bullet"
	-- effectName = "fx_ui_shengli"
	-- effectName = "fx_xiongpiren_skill2"
	effectName = "fx_xiongpiren_skill2"
	effectName = "fx_muzhinanhai_skill2_hit"

	self.mEffectNameInput.text = effectName
	self.mSpineNameInput.text = "Xinyuanxinyu"

	self:SetWndText(self.mVerText,"Ver.1.6.22")
	
	self._tmpInValidStr = "<size=46><sprite index=20></size>馃榾馃槂馃榿馃ぃ馃槀馃槄馃槅馃榾馃槂馃槃馃榿馃ぃ馃槀馃槄馃槅鈽猴笍馃槉馃槆馃檪"
	self._tmpInValidStr1 = "馃榾馃槂馃榿馃ぃ馃槀馃槄馃槅馃榾馃槂馃槃馃榿馃ぃ馃槀馃槄馃槅鈽猴笍馃槉馃槆馃檪"
	self._tmpInValidStr2 = "<sprite index=20>馃榾馃槂馃榿馃ぃ馃槀馃槄馃槅馃榾馃槂馃槃馃榿馃ぃ馃槀馃槄馃槅鈽猴笍馃槉馃槆馃檪"
	self._tmpInValidStr3 = "<sprite index=20><sprite index=17><sprite index=19>"
	self._tmpIn = "聽" --鐗规畩瀛楃\u00a0
	self._tmpArrow = "鈫?"
end

function UI_CTDevTest:OnTraceItemDraw(list,item, itemdata, itempos, fromHeadTail)
	local text = CS.FindTrans(item,"XUIText")
	self:SetWndText(text,itemdata.data.."-"..tostring(itempos))
end

function UI_CTDevTest:OnTestPlaySpineScene()
	self:ClearAllDp()

	CS.ShowObject(self.mSpineBgObj,false)
	CS.ShowObject(self.mSpineNodeObj,false)

	local spineName = self.mSpineNameInput.text
	local sineDp = self._dpSpine
	if sineDp then
		self._dpSpine = nil
		sineDp:Destroy()
	end

	local sceneClass = GF.GetNowSceneClass()
	if not sceneClass or sceneClass.GetEffectNode == nil then return end
	local trans = sceneClass:GetSpineNode()
	if not trans then return end

	sineDp = LDisplaySpine:New()
	self._dpSpine = sineDp
	sineDp:CreateSpine(trans, spineName)
	sineDp:SetLoadedFunction(function()
		local dpTrans = sineDp:GetDisplayTrans()
		dpTrans.localPosition = Vector3.zero
		dpTrans.localScale = Vector3.one
		dpTrans.name = spineName
	end)
	sineDp:StartLoad()
end

function UI_CTDevTest:OnSuperScrollItemDraw(list,item, itemdata, itempos)
	local instanceId = item:GetInstanceID()
	local itemIconNew = self._itemIconList[instanceId]
	local icon = CS.FindTrans(item, "Icon")
	if not itemIconNew then
		itemIconNew = CommonIcon:New()
		self._itemIconList[instanceId] = itemIconNew
		itemIconNew:Create(icon)
	end

	itemIconNew:SetCommonReward(LItemTypeConst.TYPE_ITEM, itemdata.id, itemdata.num)

	itemIconNew:DoApply()

	local text = CS.FindTrans(item,"XUIText")
	self:SetWndText(text,"N"..tostring(itempos))
end

function UI_CTDevTest:OnTestPlayVideoUI()
	local videoName = self.mVideoNameInput.text
	--gLGameAudio:VideoPlayByClip(videoName,function()
	--	GF.ShowMessage("鎾斁缁撴潫 ...")
	--end)
	CS.ShowObject(self.mVideoUIRoot,true)
	gLGameVideo:PlayVideoClipUI(videoName,function()
		GF.ShowMessage("鎾斁缁撴潫 ...")
	end,self.mVideoUIRoot)
end

--[[
int startH = 0xD800 + 1;
int endH = 0xDBFF;
int startL = 0xDC00;
int endL = 0xDFFF;
List<int> lhList = new List<int>
{
startL,
endL,
};

UTF8Encoding utf8Encoding = new UTF8Encoding();
UnicodeEncoding unicodeEncoding= new UnicodeEncoding();

StringBuilder sbcode = new StringBuilder();
char[] tempbytes = new char[]{'\0','\0'};
for (int kh = startH; kh <= endH; kh++)
{
for (int l = 0; l < 2; l++)
{
int lh = lhList[l];
tempbytes[0] = (char)kh;
tempbytes[1] = (char)lh;

string temp = new string(tempbytes);

int unicode = Char.ConvertToUtf32(Convert.ToChar(kh), Convert.ToChar(lh));
sbcode.Append(Convert.ToString(unicode, 16));
sbcode.Append(" = ");

byte[] utf8Bytes = utf8Encoding.GetBytes(temp);
int utf8Len = utf8Bytes.Length;
int zeroLen = 4 - utf8Len;
while (zeroLen > 0)
{
sbcode.Append("00");
zeroLen--;
}
for (int k = 0; k < utf8Len; k++)
{
sbcode.Append(((int)utf8Bytes[k]).ToString("X2"));
}
sbcode.Append(" = ");
sbcode.Append(unicode);
sbcode.AppendLine();
}

sbcode.AppendLine();
}

YXFileUtil.FileWriteText("c:/testcode.txt",sbcode.ToString());
--]]

function UI_CTDevTest:HideAllNode()
	self:ClearAllDp()

	CS.ShowObject(self.mTestScrollNodeObj,false)
	CS.ShowObject(self.mTestVideoNodeObj,false)
	CS.ShowObject(self.mTestEffectNodeObj,false)
	CS.ShowObject(self.mTestSpineNodeObj,false)
	CS.ShowObject(self.mTestTextNodeObj,false)
	CS.ShowObject(self.mTestTraceSRNodeObj,false)
	CS.ShowObject(self.mVideoUIRoot,false)
	CS.ShowObject(self.mTestSuperRootObj,false)
end

function UI_CTDevTest:OnBtnSRTest2()
	local uiList = self._uiTestList
	local index = self._srTestAddIndex or 3
	uiList:AddData("I"..index,{data="I"..index,key="I"..index}, index)
	uiList:AddItemByDataPos(index)
	index = index + 1
	self._srTestAddIndex = index
end

------------------------------------------------------------------
---娴嬭瘯鍒楄〃
-----------------------------------------------------------------
function UI_CTDevTest:InitScrollList()
	local uiList = self._uiTestList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mXUIScrollRect)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnItemDraw(...)
		end)
		self._uiTestList = uiList
	end
end

---娴嬭瘯superscrollview
function UI_CTDevTest:InitSuperScroll()
	local superScrollList = self:GetUIScroll("SuperScroll_test1")
	local infoList = self:GetItemRefList()
	superScrollList:Create(self.mSuperScrollView,infoList,function (...) self:OnSuperScrollItemDraw(...) end, UIItemList.SUPER_GRID,true)
end

function UI_CTDevTest:TestCallTextSize()

	local width = self.mTestTextShow.preferredWidth
	local height = self.mTestTextShow.preferredHeight

	LogWarn("tmp text size ="..tostring(width .."|"..tostring(height)))

	width = self.mTestTextShow2.preferredWidth
	height = self.mTestTextShow2.preferredHeight
	LogWarn("ugui text size ="..tostring(width .."|"..tostring(height)))

end

function UI_CTDevTest:OnTestPlayEffectScene()
	self:ClearAllDp()

	CS.ShowObject(self.mEffectBgObj,false)
	CS.ShowObject(self.mEffectNodeObj,false)

	local effectName = self.mEffectNameInput.text
	local effDp = self._dpEffect
	if effDp then
		self._dpEffect = nil
		effDp:Destroy()
	end

	local sceneClass = GF.GetNowSceneClass()
	if not sceneClass or sceneClass.GetEffectNode == nil then return end
	local trans = sceneClass:GetEffectNode()
	if not trans then return end

	effDp = LDisplayEffect:New()
	self._dpEffect = effDp
	effDp:CreateEffect(trans, effectName)
	effDp:SetLoadedFunction(function()
		local dpTrans = effDp:GetDisplayTrans()
		dpTrans.localPosition = Vector3.zero
		dpTrans.localScale = Vector3.one
		dpTrans.name = effectName
	end)
	effDp:StartLoadEffect()
end

-----------------------------------------------------------------
---娴嬭瘯鏂囨湰emoji 鐗规畩瀛楃
-----------------------------------------------------------------
function UI_CTDevTest:TestCopyInputTextToText()
	local tst = self._tmpInValidStr2

	self.mTestTextShow.text = tst
	self.mTestTextShow2.text = tst

	local width = self.mTestTextShow.preferredWidth
	local height = self.mTestTextShow.preferredHeight

	LogWarn("tmp text size ="..tostring(width .."|"..tostring(height)))

	width = self.mTestTextShow2.preferredWidth
	height = self.mTestTextShow2.preferredHeight
	LogWarn("ugui text size ="..tostring(width .."|"..tostring(height)))
end

------------------------------------------------------------------
---娴嬭瘯鍏夋晥鎾斁
-----------------------------------------------------------------
function UI_CTDevTest:OnTestPlayEffectUI()
	self:ClearAllDp()

	local effectName = self.mEffectNameInput.text
	CS.ShowObject(self.mEffectBgObj,true)
	CS.ShowObject(self.mEffectNodeObj,true)
	self:DestroyWndEffectByKey("testEffect")
	self:CreateWndEffect(self.mEffectNodeObj.transform,effectName,"testEffect",100)
end

function UI_CTDevTest:OnBtnSRTest3()
	local uiList = self._uiTestList

	local idx = 3
	uiList:DelDataByIndex(idx)
	uiList:RemoveItemByDataPos(idx)
end

------------------------------------------------------------------
---娴嬭瘯spine鎾斁
-----------------------------------------------------------------
function UI_CTDevTest:OnTestPlaySpineUI()

	--self:ClearAllDp()

	local spineName = self.mSpineNameInput.text
	CS.ShowObject(self.mSpineBgObj,true)
	CS.ShowObject(self.mSpineNodeObj,true)
	local spine = self:FindWndSpineByKey("testSpine")
	local sceneCam = gLGameScene:GetCurrentSceneCamera()
	local uiCam = LGameUI.GetUICamera()

	if spine then
		local trans = spine:GetDisplayTrans()

		local bone = spine._skeleton.RootBone

		--场景0点在ui的位置
		local poszero = Vector3(0,0,0)
		local zerotoscreen = sceneCam:WorldToScreenPoint(poszero)
		local zerotoui = uiCam:ScreenToWorldPoint(zerotoscreen)
		print(string.format("zerotoui pos = %s, %s ", zerotoui.x, zerotoui.y))


		print(string.format("root bone pos = %s, %s , scale = %s, %s", bone.WorldX,bone.WorldY, bone.WorldScaleX, bone.WorldScaleY))
		print(string.format("spine pos = %s, %s", trans.position.x,trans.position.y))
		for k=1, 5 do
			bone = spine:GetBone("T"..tostring(k))
			local pos = Vector3(bone.WorldX, bone.WorldY, 0)
			print( "bone space pos = "..tostring(pos))

			--bone体系坐标相对场景0点在ui上的位置
			local screenPos = sceneCam:WorldToScreenPoint(pos)
			local uiPos = uiCam:ScreenToWorldPoint(screenPos)
			local finalPos = uiPos + trans.position - zerotoui --UI上最终的位置

			local go = CS.NewObject("name_img"..tostring(k), trans.parent)

			go.transform.position = spine:GetBoneUIPos("T"..tostring(k), sceneCam, uiCam)
		end
		return
	end
	self:DestroyWndSpineByKey("testSpine")
	self:CreateWndSpine(self.mSpineNodeObj.transform,spineName,"testSpine", nil, function (dpSpine)

	end)
end

function UI_CTDevTest:ClearAllDp()
	if self._dpSpine then
		self._dpSpine:Destroy()
		self._dpSpine = nil
	end

	if self._dpEffect then
		self._dpEffect:Destroy()
		self._dpEffect = nil
	end

	self:DestroyWndSpineByKey("testSpine")
	self:DestroyWndEffectByKey("testEffect")
end

function UI_CTDevTest:UpdateScrollList(dataCount)

	self._srTestAddIndex = 3
	local testDataList = self._testDataList
	if not testDataList then
		testDataList = {}
		self._testDataList = testDataList
	end
	local uiList = self._uiTestList
	uiList:RemoveAllData()
	for k=1,dataCount do
		local key = "N"..k
		uiList:AddData(key ,{data="N"..k,key=key},k)
	end
	uiList:RefreshList()
end

------------------------------------------------------------------
function UI_CTDevTest:GetItemRefList()
	if self._itemDataList then
		return self._itemDataList
	end
	local dataList = {}

	for k,itemRef in pairs(GameTable.PlayerItemRef) do
		local data = {id=itemRef.refId,num=1}
		data.text = data.id
		table.insert(dataList,data)
	end
	self._itemDataList = dataList
	table.sort(dataList,function(a,b)
		return a.id < b.id
	end)
	return dataList
end
------------------------------------------------------------------
---娴嬭瘯瑙嗛鎾斁
-----------------------------------------------------------------
function UI_CTDevTest:OnTestPlayVideo()
	local videoName = self.mVideoNameInput.text
	--gLGameAudio:VideoPlayByClip(videoName,function()
	--	GF.ShowMessage("鎾斁缁撴潫 ...")
	--end)
	--gLGameVideo:PlayVideoClip(videoName,function()
	--	GF.ShowMessage("鎾斁缁撴潫 ...")
	--end)

	GF.ChangeToMainScene()
end

function UI_CTDevTest:RegisterEvent()
	self:SetWndClick(self.mTestScrollObj,function(...)
		self:HideAllNode()
		CS.ShowObject(self.mTestScrollNodeObj,true)
		self:InitScrollList()
	end)

	self:SetWndClick(self.mTestVideoObj,function(...)
		self:HideAllNode()
		CS.ShowObject(self.mTestVideoNodeObj,true)
	end)

	self:SetWndClick(self.mTestEffObj,function(...)
		self:HideAllNode()
		CS.ShowObject(self.mTestEffectNodeObj,true)
	end)

	self:SetWndClick(self.mTestSpineObj,function(...)
		self:HideAllNode()
		CS.ShowObject(self.mTestSpineNodeObj,true)

	end)

	self:SetWndClick(self.mTestTraceSRObj,function(...)
		self:HideAllNode()
		CS.ShowObject(self.mTestTraceSRNodeObj,true)
		self:InitTraceScrollList()
	end)



	self:SetWndClick(self.mTestTextObj,function(...)
		self:HideAllNode()
		CS.ShowObject(self.mTestTextNodeObj,true)

	end)

	self:SetWndClick(self.mPlayVideoObj,function (...)
		self:OnTestPlayVideo()
	end)

	self:SetWndClick(self.mPlayVideoUIObj,function (...)
		self:OnTestPlayVideoUI()
	end)

	self:SetWndClick(self.mPlayEffectSceneObj,function (...)
		self:OnTestPlayEffectScene()
	end)

	self:SetWndClick(self.mPlayEffectUIObj,function (...)
		self:OnTestPlayEffectUI()
	end)

	self:SetWndClick(self.mPlaySpineSceneObj,function (...)
		self:OnTestPlaySpineScene()
	end)

	self:SetWndClick(self.mPlaySpineUIObj,function (...)
		self:OnTestPlaySpineUI()
	end)

	self:SetWndClick(self.mBtnSRTest1Obj,function(...)
		self:OnBtnSRTest1()
	end)

	self:SetWndClick(self.mBtnSRTest2Obj,function(...)
		self:OnBtnSRTest2()
	end)

	self:SetWndClick(self.mBtnSRTest3Obj,function(...)
		self:OnBtnSRTest3()
	end)


	self:SetWndClick(self.mTestTextApplyBtnObj,function(...)
		self:TestCopyInputTextToText()
	end)

	self:SetWndClick(self.mTestTextSizeBtnObj,function(...)
		self:TestCallTextSize()
	end)

	self:SetWndClick(self.mTestSuperObj,function(...)
		self:HideAllNode()
		CS.ShowObject(self.mTestSuperRootObj,true)
		self:InitSuperScroll()
	end)

	self:SetWndClick(self.mTestrebootObj,function(...)
		ReLoginGame()
	end)

	self:SetWndClick(self.mTestgcObj, function ()
		--LResRelease.CallBackClearUnusedAndGC(nil,true)
	end)

	self:SetWndClick(self.mTestinittmpObj, function ()
		CS.ClearAllBundle(true, function()
			CS.InitTextMesh()
		end)

	end)
end

function UI_CTDevTest:OnItemDraw(list,item, itemdata, itempos, fromHeadTail)
	local text = CS.FindTrans(item,"XUIText")
	self:SetWndText(text,itemdata.data.."-"..tostring(itempos))
end

function UI_CTDevTest:OnBtnSRTest1()
	self:UpdateScrollList(10)

end

------------------------------------------------------------------
---娴嬭瘯鍒楄〃2
-----------------------------------------------------------------
function UI_CTDevTest:InitTraceScrollList()
	local uiList = self._uiTraceList
	if not uiList then
		uiList = UIListTrace:New()
		uiList:Create(self,self.mUITraceSR)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnTraceItemDraw(...)
		end)
		self._uiTraceList = uiList
	end

	uiList:RemoveAllData()
	for k=1, 100 do
		uiList:AddData(k,{key=k,data="NT"..k})
	end
	uiList:RefreshList()
end
------------------------------------------------------------------
return UI_CTDevTest


