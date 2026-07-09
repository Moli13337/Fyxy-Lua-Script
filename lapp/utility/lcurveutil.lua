--[[
--曲线生成工具
--]]
local Vector3 = Vector3
local YXBezier = CS.YXBezier
---@class LCurveUtil
local LCurveUtil = LxClass("LCurveUtil", nil)
------------------------------------------------------------------


------------------------------------------------------------------
-- 获取贝塞尔曲线对象
function LCurveUtil.NewBezier(from, to, time, ...)
	local points = { ... }
	local len = #points
	if 0 == len then
		return YXBezier.New(from, to, time)
	elseif 1 == len then
		return YXBezier.New(from, to, points[1], time)
	elseif 2 == len then
		return YXBezier.New(from, to, points[1], points[2], time)
	end
end

--香蕉球
function LCurveUtil.Banana(from, to, time)
	local distance = Vector3.Distance(from, to)
	local arcCount = LCurveUtil.arcCount or 1
	LCurveUtil.arcCount = arcCount + 1
	local left_right
	if arcCount % 2 == 0 then
		left_right = Vector3(distance * 2 / 4, 0, 0)
	else
		left_right = Vector3(-distance * 2 / 4, 0, 0)
	end
	local bezierTop = Vector3.Lerp(from, to, 3 / 5) + Vector3(0, distance * 2 / 4, 0) + left_right
	local bezier = LCurveUtil.NewBezier(from, to, time, bezierTop)
	return function(t)
		local p = bezier:NextPos(t)
		return p
	end
end

--直线
function LCurveUtil.Linear(from, to, time)
	local bezier = LCurveUtil.NewBezier(from, to, time)
	return function(t)
		local p = bezier:NextPos(t)
		return p
	end
end

function LCurveUtil.Parabola(from, to, time, face)
	if time <= 0 then
		--print('曲线点数量错误 = ' .. time)
		return function()
		end
	end
	face = face or 1
	local distance = Vector3.Distance(from, to)
	local bezierTop = Vector3.Lerp(from, to, 0.5) + Vector3(0, distance * 0.3, 0) * face
	local bezier = LCurveUtil.NewBezier(from, to, time, bezierTop)
	return function(t)
		local p = bezier:NextPos(t)
		return p
	end
end

--双抛物线
function LCurveUtil.Parabola_Double(from, to, time)
	if time <= 0 then
		--print('曲线点数量错误 = ' .. time)
		return function()
		end
	end
	local rate = 7 / 10
	local time1 = time * rate
	local time2 = time - time1
	local middle = Vector3.Lerp(from, to, nil)
	local bezier1 = LCurveUtil._NewParabola(from, middle, time1, 0.5, 0.5)
	local bezier2 = LCurveUtil._NewParabola(middle, to, time2, 0.5, 0.2)
	return function(t)
		local p
		if t < time1 then
			p = bezier1:NextPos(t)
		else
			p = bezier2:NextPos(t)
		end
		return p
	end
end

-- 生成抛物线贝塞尔
function LCurveUtil._NewParabola(from, to, count, farRatio, yRatio)
	local distance = Vector3.Distance(from, to)
	local bezierTop = Vector3.Lerp(from, to, farRatio) + Vector3(0, distance * yRatio, 0)
	return LCurveUtil.NewBezier(from, to, count, bezierTop)
end

--落叶球
function LCurveUtil.Fallen(from, to, time)
	local distance = Vector3.Distance(from, to)
	local bezierTop = Vector3.Lerp(from, to, 2 / 3) + Vector3(0, distance * 2 / 5, 0)
	local bezier = LCurveUtil.NewBezier(from, to, time, bezierTop)
	return function(t)
		local p = bezier:NextPos(t)
		return p
	end
end

--落叶球
function LCurveUtil.PopAndFallen(from, to, time)
	local distance = Vector3.Distance(from, to)
	local bezierTop = Vector3.Lerp(from, to, 1 / 4) + Vector3(0, distance * 3 / 5, 0)
	local bezier = LCurveUtil.NewBezier(from, to, time, bezierTop)
	return function(t)
		local p = bezier:NextPos(t)
		return p
	end
end

function LCurveUtil.BezierSecond(from,to,top,time)
	local bezier = LCurveUtil.NewBezier(from, to, time, top)
	return function(t)
		local p = bezier:NextPos(t)
		return p
	end
end

return LCurveUtil

