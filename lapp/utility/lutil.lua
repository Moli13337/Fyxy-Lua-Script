-----------------------------------------------------------------
local Color = Color
local LStringUtil = LStringUtil
---@class LUtil
local LUtil = LxClass("LUtil", nil)
-----------------------------------------------------------------


-----------------------------------------------------------------
-- RGBA
-- ColorByHex("233776FF")
-----------------------------------------------------------------
function LUtil.ColorByHex(strHex)
    if string.startswith(strHex, "#") then
        strHex = string.sub(strHex, 2)
    end
    if (string.len(strHex) ~= 8) then
        if LOG_INFO_ENABLED then
            print("colorHex wrong length | " .. strHex)
        end
        return Color.New(0, 0, 0, 0)
    end
    local r, g, b, a
    r = tonumber(string.sub(strHex, 1, 2), 16) / 255
    g = tonumber(string.sub(strHex, 3, 4), 16) / 255
    b = tonumber(string.sub(strHex, 5, 6), 16) / 255
    a = tonumber(string.sub(strHex, 7, 8), 16) / 255
    return Color.New(r, g, b, a)
end
function LUtil.ColorByHex_6(strHex)
    if string.startswith(strHex, "#") then
        strHex = string.sub(strHex, 2)
    end
    if (string.len(strHex) ~= 6) then
        if LOG_INFO_ENABLED then
            print("colorHex_6 wrong length | " .. strHex)
        end
        return Color.New(0, 0, 0, 0)
    end
    local r, g, b
    r = tonumber(string.sub(strHex, 1, 2), 16) / 255
    g = tonumber(string.sub(strHex, 3, 4), 16) / 255
    b = tonumber(string.sub(strHex, 5, 6), 16) / 255
    return Color.New(r, g, b, 1)
end

function LUtil.GetYmdByTimestamp(timestamp)
    --获取年月日
    local _data = LUtil.OSDate("*t", timestamp)
    local y = _data.year
    local m = _data.month
    local d = _data.day
    return y, m, d
end

function LUtil.GetWeekByYmd(y, m, d)
    --获取星期几
    if m == 1 or m == 2 then
        m = m + 12
        y = y - 1
    end
    local m1, _ = math.modf(3 * (m + 1) / 5)
    local m2, _ = math.modf(y / 4)
    local m3, _ = math.modf(y / 100)
    local m4, _ = math.modf(y / 400)

    local iWeek = (d + 2 * m + m1 + y + m2 - m3 + m4) % 7
    local weekTab = {
        ["0"] = 1,
        ["1"] = 2,
        ["2"] = 3,
        ["3"] = 4,
        ["4"] = 5,
        ["5"] = 6,
        ["6"] = 7,
    }
    return weekTab[tostring(iWeek)]
end

function LUtil.GetWeekByTime(timestamp)
    timestamp = timestamp or GetTimestamp()
    local date = LUtil.OSDate("*t", timestamp)
    local week = date.wday
    if week == 1 then
        week = 7
    else
        week = week - 1
    end

    return week
end

function LUtil.IsToDay(timestamp)
    --是否是今天
    local today = LUtil.OSDate("*t", GetTimestamp())
    local other = LUtil.OSDate("*t", timestamp)
    if today.year == other.year and today.month == other.month and today.day == other.day then
        return true
    end
    return false
end

function LUtil.GetWeekTWOTimestamp(timestamp, week, hours)
    --获取下星期几时间戳
    timestamp = timestamp or GetTimestamp()
    local _data = LUtil.OSDate("*t", timestamp)
    local y = _data.year
    local m = _data.month
    local d = _data.day
    local _week = LUtil.GetWeekByTime(timestamp)
    local hour = hours or 0
    local n = 7 + week - _week
    local _timestamp = LUtil.OSTime({ year = y, month = m, day = d + n, hour = hour, min = 0, sec = 0 })
    return _timestamp
end

function LUtil.GetNextDayTimes(times, day, addHour, addMin, addSec)
    -- 获取第n天的时间戳
    day = day or 0
    addHour = addHour or 0
    addMin = addMin or 0
    addSec = addSec or 0
    times = times or GetTimestamp()
    local date = LUtil.OSDate("*t", times)
    local y = date.year
    local m = date.month
    local d = date.day
    local _timestamp = LUtil.OSTime({ year = y, month = m, day = d + day, hour = addHour, min = addMin, sec = addSec })
    return _timestamp
end

function LUtil.GetTimeByDateTable(year, month, day, hour, min, sec)
    hour = hour or 0
    min = min or 0
    sec = sec or 0
    local _timestamp = LUtil.OSTime({ year = year, month = month, day = day, hour = hour, min = min, sec = sec })
    return _timestamp
end

function LUtil.GetCurTimeDayNum(curTime)
    -- 获取天数
    local day = math.ceil(curTime / 86400)
    return day
end

function LUtil.FormatTimeStr(timestamp, formatStr)
    formatStr = formatStr or "%Y/%m/%d %H:%M:%S"
    timestamp = timestamp / 1000
    local date = LUtil.OSDate(formatStr, timestamp)
    return date
end

function LUtil.FormatTimespanThreeCn(timespan)
    local t1 = ccClientText(10304)
    local t2 = ccClientText(10305)
    local t3 = ccClientText(10306)
    local t4 = ccClientText(10355)
    if timespan > 86400 then
        local day = math.floor(timespan / 86400)
        local hour = math.floor(timespan / 3600) % 24
        local min = math.floor(timespan / 60) % 60
        return string.format("%d%s%d%s%d%s", day, t1, hour, t2, min, t3)
    else
        local hour = math.floor(timespan / 3600) % 24
        local min = math.floor(timespan / 60) % 60
        local sec = math.floor(timespan) % 60
        return string.format("%d%s%d%s%d%s", hour, t2, min, t3, sec, t4)
    end
end

-- 当前时间距离n天差多少时间戳
function LUtil.GetNDayTimeStr(times, day, addHour, addMin, addSec)
    local nDayTime = LUtil.GetNextDayTimes(times, day, addHour, addMin, addSec)
    local lostTime = nDayTime - GetTimestamp()
    return LUtil.FormatTimespanCn(lostTime)
end

function LUtil.FormatTimespanCn(timespan, timeTextIdList)
    local dTextId = timeTextIdList and timeTextIdList.dTextId or 10304
    local hTextId = timeTextIdList and timeTextIdList.hTextId or 10305
    local mTextId = timeTextIdList and timeTextIdList.mTextId or 10306
    local sTextId = timeTextIdList and timeTextIdList.sTextId or 10355
    local t1 = ccClientText(dTextId)
    local t2 = ccClientText(hTextId)
    local t3 = ccClientText(mTextId)
    local t4 = ccClientText(sTextId)
    if timespan > 86400 then
        local day = math.floor(timespan / 86400)
        local hour = math.floor(timespan / 3600) % 24
        return string.format("%d%s%d%s", day, t1, hour, t2)
    elseif timespan > 3600 then
        local hour = math.floor(timespan / 3600)
        local min = math.floor(timespan / 60) % 60
        return string.format("%d%s%d%s", hour, t2, min, t3)
    else
        local min = math.floor(timespan / 60)
        local sec = math.floor(timespan) % 60
        return string.format("%d%s%d%s", min, t3, sec, t4)
    end
end
-- XX天XX时XX分  或者 XX时XX分XX秒, 或者 XX分XX秒
function LUtil.FormatTimeToCn3(timespan)
    local t1 = ccClientText(10304)
    local t2 = ccClientText(10305)
    local t3 = ccClientText(10306)
    local t4 = ccClientText(10355)
    if timespan > 86400 then
        local day = math.floor(timespan / 86400)
        local hour = math.floor(timespan / 3600) % 24
        local min = math.floor(timespan / 60) % 60
        return string.format("%d%s%d%s%d%s", day, t1, hour, t2, min, t3)
    elseif timespan > 3600 then
        local hour = math.floor(timespan / 3600)
        local min = math.floor(timespan / 60) % 60
        local sec = math.floor(timespan) % 60
        return string.format("%d%s%d%s%d%s", hour, t2, min, t3, sec, t4)
    else
        local min = math.floor(timespan / 60)
        local sec = math.floor(timespan) % 60
        return string.format("%d%s%d%s", min, t3, sec, t4)
    end
end

-- XX天XX时XX分  或者 XX时XX分XX秒
function LUtil.FormatTimeToCn4(timespan)
    local t1 = ccClientText(10304)
    local t2 = ccClientText(10305)
    local t3 = ccClientText(10306)
    local t4 = ccClientText(10355)
    if timespan > 86400 then
        local day = math.floor(timespan / 86400)
        local hour = math.floor(timespan / 3600) % 24
        local min = math.floor(timespan / 60) % 60
        return string.format("%d%s%d%s%d%s", day, t1, hour, t2, min, t3)
    else
        local hour = math.floor(timespan / 3600)
        local min = math.floor(timespan / 60) % 60
        local sec = math.floor(timespan) % 60
        return string.format("%d%s%d%s%d%s", hour, t2, min, t3, sec, t4)
    end
end

--只取一个约等值 XX天 / XX时 / XX分 / XX秒
function LUtil.FormatTimeToCn1(timespan)
    local t1 = ccClientText(10304)
    local t2 = ccClientText(10305)
    local t3 = ccClientText(10306)
    local t4 = ccClientText(10355)
    if timespan > 86400 then
        local day = math.floor(timespan / 86400)
        return string.format("%d%s", day, t1)
    elseif timespan > 3600 then
        local hour = math.floor(timespan / 3600)
        return string.format("%d%s", hour, t2)
    elseif timespan > 60 then
        local min = math.floor(timespan / 60)
        return string.format("%d%s", min, t3)
    else
        local sec = math.floor(timespan)
        return string.format("%d%s", sec, t4)
    end
end

function LUtil.FormatTimespanToMin(timespan)
    local t1 = ccClientText(10304)
    local t2 = ccClientText(10305)
    local t3 = ccClientText(10306)
    if timespan > 86400 then
        local day = math.floor(timespan / 86400)
        local hour = math.floor(timespan / 3600) % 24
        return string.format("%d%s%d%s", day, t1, hour, t2)
    elseif timespan > 3600 then
        local hour = math.floor(timespan / 3600)
        local min = math.floor(timespan / 60) % 60
        return string.format("%d%s%d%s", hour, t2, min, t3)
    else
        local min = math.floor(timespan / 60)
        return string.format("%d%s", min, t3)
    end
end

function LUtil.FormatTimeToMin(timespan, offlineLimit)
    local t1 = ccClientText(10304)
    local t2 = ccClientText(10305)
    local t3 = ccClientText(10306)
    if timespan < 60 then
        return string.format("%d%s", 1, t3)
        --return ccClientText(10366)
    elseif timespan > 86400 then
        local day = math.floor(timespan / 86400)
        if offlineLimit and day > offlineLimit then
            day = offlineLimit
        end
        return string.format("%d%s", day, t1)
    elseif timespan > 3600 then
        local hour = math.floor(timespan / 3600)
        return string.format("%d%s", hour, t2)
    else
        local min = math.floor(timespan / 60)
        return string.format("%d%s", min, t3)
    end
end

function LUtil.FormatTimespanNumber(timespan)
    local hour = math.floor(timespan / 3600)
    local min = math.floor(timespan / 60) % 60
    local sec = math.floor(timespan) % 60
    return string.format("%02d:%02d:%02d", hour, min, sec)
end

function LUtil.FormatTimeSpanShop(timeSpan)
    if timeSpan >= 86400 then
        local day = math.floor(timeSpan / 86400)
        local left = math.floor(timeSpan) % 86400
        local hour = math.floor(left / 3600)
        local str = string.replace(ccClientText(10762), day, hour)
        return str
    else
        return LUtil.FormatTimespanNumber(timeSpan)
    end
end

--xx 天 00:00:00
function LUtil.FormatTimespanDetail(timespan)
    if timespan > 86400 then
        local day = math.floor(timespan / 86400)
        local left = math.floor(timespan) % 86400
        local str = string.format("%s %s %s", day, ccClientText(10304), LUtil.FormatTimespanNumber(left))
        return str
    else
        return LUtil.FormatTimespanNumber(timespan)
    end
end

--XXdXXh  XXhXXm XXmXXs
function LUtil.FormatTimespanToMin2(timespan)
    local t1 = "d"
    local t2 = "h"
    local t3 = "m"
    local t4 = "s"
    if timespan > 86400 then
        local day = math.floor(timespan / 86400)
        local hour = math.floor(timespan / 3600) % 24
        return string.format("%d%s%d%s", day, t1, hour, t2)
    elseif timespan > 3600 then
        local hour = math.floor(timespan / 3600)
        local min = math.floor(timespan / 60) % 60
        return string.format("%d%s%d%s", hour, t2, min, t3)
    else
        local min = math.floor(timespan / 60)
        local sec = math.floor(timespan) % 60
        return string.format("%d%s%d%s", min, t3, sec, t4)
    end
end

-- 获取时间格式  59:00    时：分
function LUtil.FormatTimespanToMin2New(timespan)
    if timespan > 86400 then
        local day = math.floor(timespan / 86400)
        local hour = math.floor(timespan / 3600) % 24
        return string.format("%02d:%02d", day, hour)
    elseif timespan > 3600 then
        local hour = math.floor(timespan / 3600)
        local min = math.floor(timespan / 60) % 60
        return string.format("%02d:%02d", hour, min)
    else
        local min = math.floor(timespan / 60)
        local sec = math.floor(timespan) % 60
        return string.format("%02d:%02d", min, sec)
    end
end

function LUtil.FormatTimespanToHourAndMin(timespan)
    local hour = math.floor(timespan / 3600)
    local min = math.floor(timespan / 60) % 60
    return string.format("%02d:%02d", hour, min)
end

function LUtil.FormatTimespanToHourAndMin2(timespan)
    local t1 = ccClientText(10305)
    local t2 = ccClientText(10306)
    local hour = math.floor(timespan / 3600)
    local min = math.floor(timespan / 60) % 60
    return string.format("%d%s%d%s", hour, t1, min, t2)
end

function LUtil.FormatYearMonthDay(timestamp)
    local y, m, d = LUtil.GetYmdByTimestamp(timestamp)--获取年月日
    return string.format("%02d-%02d-%02d", y, m, d)
end

-- 获取当天时间  23:59:00
function LUtil.FormatInTheDayTime(timestamp)
    timestamp = timestamp or GetTimestamp()
    local _data = LUtil.OSDate("*t", timestamp)
    local h = _data.hour
    local m = _data.min
    local s = _data.sec

    return string.format("%02d:%02d:%02d", h, m, s)
end

-- 获取剩余时间  1天 23:59:00
function LUtil.FormatInTheDayTime2(timespan)
    local t1 = ccClientText(10304)
    local day = math.floor(timespan / 86400)
    local hour = math.floor(timespan / 3600) % 24
    local min = math.floor(timespan / 60) % 60
    local sec = math.floor(timespan) % 60
    return string.format("%d%s %d:%d:%d", day, t1, hour, min, sec)
end

---2010.09.10
function LUtil.FormatTimestampSimple(timestamp)
    local y, m, d = LUtil.GetYmdByTimestamp(timestamp)
    return string.format("%d.%02d.%02d", y, m, d)
end


-- 获取剩余时间  1天 23:59:00
function LUtil.FormatChatTime(sendTime)
    local _data = LUtil.OSDate("*t", sendTime)
    local h = _data.hour
    local m = _data.min
    local timespan = GetTimestamp() - sendTime

    if timespan > 604800 then
        --超过7天  XXXX年X月X日 时：分
        local formatStr = ccClientText(18100)
        local startTime = LUtil.OSDate(formatStr, sendTime)

        local endTime = string.format("%02d:%02d", h, m)
        return string.format("%s %s", startTime, endTime)
    elseif timespan > 172800 then
        --2 - 7天  星期X 时：分
        local weekStr = LUtil.GetWeekStrByTime(sendTime)
        local endTime = string.format("%02d:%02d", h, m)
        return string.format("%s %s", weekStr, endTime)
    elseif timespan > 86400 then
        local endTime = string.format("%02d:%02d", h, m)
        return string.format("%s %s", ccClientText(11162), endTime)
    else
        return string.format("%02d:%02d", h, m)
    end
end

--大于一天   xx天xx时
--大于一小时 xx时xx分
--大于一分钟 xx分xx秒
--小于一分钟 xx秒
function LUtil.FormatTimeStr1(timespan)
    local t1 = ccClientText(10304)
    local t2 = ccClientText(10305)
    local t3 = ccClientText(10306)
    local t4 = ccClientText(10355)
    if timespan > 86400 then
        local day = math.floor(timespan / 86400)
        local hour = math.floor(timespan / 3600) % 24
        return day .. t1 .. hour .. t2
    elseif timespan > 3600 then
        local hour = math.floor(timespan / 3600)
        local min = math.floor(timespan / 60) % 60
        return hour .. t2 .. min .. t3
    elseif timespan > 60 then
        local min = math.floor(timespan / 60)
        local sec = math.floor(timespan) % 60
        return min .. t3 .. sec .. t4
    else
        return timespan .. t4
    end
end

function LUtil.FormatTimeStr2(timespan1, timespan2)
    timespan2 = timespan2 or GetTimestamp()
    local timeLeft = timespan2 - timespan1
    if timeLeft >= 86400 then
        local day = math.floor(timeLeft / 86400)
        return string.replace(ccClientText(43369), day)
    elseif timeLeft >= 3600 then
        local hour = math.floor(timeLeft / 3600)
        return string.replace(ccClientText(43368), hour)
    elseif timeLeft > 60 then
        local min = math.floor(timeLeft / 60)
        return string.replace(ccClientText(43367), min)
    else
        return ccClientText(43330)
    end
end

-----------------------------------------------------------------
---战斗伤害数字字符串获取
function LUtil.FormatHurtNumSpriteText(num, bNeedAdd, sizeRate, fixedInfo, addIndex, subIndex)
    if (num == 0) then
        return "<sprite index=0>"
    end
    local isNegative = num < 0
    num = math.abs(num)

    num = math.floor(num)
    local numStr = tostring(num)
    local list = {}
    addIndex = addIndex or 10
    subIndex = subIndex or 10
    if isNegative then
        table.insert(list, "<sprite index=" .. subIndex .. ">")
    elseif bNeedAdd then
        table.insert(list, "<sprite index=" .. addIndex .. ">")
    end
    local fmtStr = "<sprite index=%s>"
    local sizeFmtStr = "<size=%s%%>%s</size>"

    local numLen = #numStr

    local suffixStr
    if fixedInfo then
        local limitNum = fixedInfo.limit
        local fontindex = fixedInfo.fontindex
        local lastPos = fixedInfo.pos
        if (numLen > limitNum) then
            suffixStr = string.format(fmtStr, tostring(fontindex))
            numLen = numLen - lastPos
        end
    end
    for k = 1, numLen do
        local index = string.char(string.byte(numStr, k))
        local idxStr = string.format(fmtStr, tostring(index))
        if k == 1 and sizeRate then
            local sizeStr = string.format(sizeFmtStr, tostring(sizeRate), idxStr)
            idxStr = sizeStr
        end
        table.insert(list, idxStr)
    end
    if (not string.isempty(suffixStr)) then
        table.insert(list, suffixStr)
    end
    return table.concat(list, "")
end

---战斗伤害数字字符串获取(数值转换版)
--num = 战力值
--bNeedAdd = true（在最前面添加 + 号），false不添加
--sizeRate = 缩放比例,单位百分数，默认不缩放（100大小)
--defaultFontSize = text组件的默认字体大小(因为加入了大小不同的美术字，导致要额外装换下图片大小)
function LUtil.FormatCoversionHurtNumSpriteText(num, bNeedAdd, sizeRate, defaultFontSize, isRemoveRetainNumber, isNotSmallSymbol)
    local sizeFmtStr2 = "<size=%s%%>%s</size>"

    if (num == 0) then
        local str = "<sprite index=0>"
        if sizeRate then
            str = string.format(sizeFmtStr2, sizeRate, str)
        end
        return str
    end

    if not defaultFontSize then
        defaultFontSize = 14
    end

    if sizeRate then
        defaultFontSize = defaultFontSize * sizeRate / 100
    end

    local isNegative = num < 0
    num = math.abs(num)
    num = math.floor(num)
    --数值转换配置
    local numberLen, currRef, currNum, currNumberArr, currStr
    local toStr = tostring(num)
    local strArr = string.split(toStr, "+")--判断number是否超过位数
    if strArr[2] then
        numberLen = tonumber(strArr[2]) + 1
    else
        numberLen = #strArr[1]
    end

    local isForeign = gLGameLanguage:IsForeignVersion() and not gLGameLanguage:IsJapanVersion()
    for i = 1, #GameTable.NumberCoversionRef do
        local figure = GameTable.NumberCoversionRef[i].figure
        --[[		if isForeign then
                    if i == 2 then
                        figure = 5
                    elseif i == 3 then
                        figure = 7
                    end
                end]]

        figure = LUtil.GetNumberCoversionFigure(figure, i)

        if (numberLen >= figure) then
            currRef = GameTable.NumberCoversionRef[i]--判断区间，取当前区间的配置
        else
            break
        end
    end

    local numCoversionRefId = currRef.id
    local retainNumber = currRef.retainNumber--保留几位小数
    local divisor = currRef.divisor--幂
    --[[	if isForeign then
            if numCoversionRefId == 2 then
                divisor = 3
            elseif numCoversionRefId == 3 then
                divisor = 6
            end
        end]]

    divisor = LUtil.GetNumberCoversionDivisor(divisor, numCoversionRefId)

    if isRemoveRetainNumber then
        --不要小数
        retainNumber = 0
    end

    currNum = num / (10 ^ (divisor - retainNumber))

    local numArr = string.split(tostring(currNum), ".")--不进行四舍五入
    if (retainNumber > 0) then
        currNum = tonumber(numArr[1]) / (10 ^ retainNumber)
    else
        currNum = tonumber(numArr[1])
    end

    currNumberArr = string.split(tostring(currNum), ".")
    local dqLen = 0
    if currNumberArr[2] then
        for i = 1, retainNumber do
            if (tonumber(string.sub(currNumberArr[2], -i)) > 0) then
                break
            else
                dqLen = i
            end
        end
    end
    if dqLen > 0 then
        dqLen = #tostring(currNum) - dqLen
        currStr = string.sub(tostring(currNum), 0, dqLen)--去小数点最后一个0
    else
        currStr = tostring(currNum)
    end

    if isNotSmallSymbol then
        if numCoversionRefId == 1 then

        else

            currStr = currStr .. ccLngText(GameTable.NumberCoversionRef[numCoversionRefId].suffix)
        end

        return currStr
    end

    local sizeFmtStr = "<size=%s>%s</size>"

    ----应策划要求，去掉数字中插入的分号（,）
    --local decimals=#currNumberArr[1]/3--取小数点前的数,有几个3
    --local len=math.floor(decimals)
    --if decimals-len==0 then
    --	len=len-1
    --end

    --local commaStr = string.format(sizeFmtStr, defaultFontSize*0.5, "<voffset=-1.2em><sprite index=11></voffset>")
    --if len > 0 then
    --	for i = 1, len do
    --		--每3位数加","
    --		local cutOut=(3*i)+(i-1)
    --		local firstStr = LUtil.GetCoversionHurtNumSpriteTextByStr(string.sub(currStr,0,#currStr-cutOut), defaultFontSize)
    --		local endStr   = LUtil.GetCoversionHurtNumSpriteTextByStr(string.sub(currStr,-cutOut), defaultFontSize)
    --		currStr= firstStr..commaStr..endStr
    --	end
    --else
    --currStr = LUtil.GetCoversionHurtNumSpriteTextByStr(currStr, defaultFontSize,isNotSmallSymbol)

    --调整使用--伤害这边的字体统一不做处理
    currStr = LUtil.GetCoversionHurtNumSpriteTextByStr(currStr, defaultFontSize, gLGameLanguage:IsEnglishVersion())

    --end


    if isNegative then
        currStr = "<sprite index=10>" .. currStr
    elseif bNeedAdd then
        currStr = "<sprite index=10>" .. currStr
    end

    local suffixStr
    if numCoversionRefId == 1 then
        suffixStr = ""
    elseif numCoversionRefId == 2 then
        --万
        suffixStr = "<sprite index=14>"
    else
        --亿
        suffixStr = "<sprite index=13>"
    end
    currStr = currStr .. suffixStr

    if sizeRate then

        currStr = string.format(sizeFmtStr2, tostring(sizeRate), currStr)
    end

    return currStr
end

function LUtil.GetCoversionHurtNumSpriteTextByStr(numStr, defaultFontSize, isNotSmallSymbol)
    local fmtStr = "<sprite index=%s>"
    local sizeFmtStr = "<size=%s>%s</size>"
    --local decimalStr = string.format(sizeFmtStr, defaultFontSize*0.15, "   <voffset=-6em><sprite index=12></voffset>  ")
    local decimalStr = "<sprite index=12>"
    if gLGameLanguage:IsForeignVersion() and not gLGameLanguage:IsVieVersion() and not gLGameLanguage:IsJapanVersion() and not isNotSmallSymbol then
        decimalStr = string.format(sizeFmtStr, defaultFontSize * 0.15, "   <sprite index=12>  ")
    end
    local numLen = #numStr
    local list = {}
    local byteIndex
    for k = 1, numLen do
        byteIndex = string.byte(numStr, k)
        local idxStr
        if byteIndex == 46 then
            --小数点
            idxStr = decimalStr
        else
            local index = string.char(byteIndex)
            idxStr = string.format(fmtStr, tostring(index))
        end

        table.insert(list, idxStr)
    end
    return table.concat(list, "")
end

function LUtil.GetNumCoversionStrSprite(num, dotStr)
    local fmtStr = "<sprite index=%s>"
    local dotStr = dotStr or "<sprite index=12>"
    local numStr = tostring(num)
    local numLen = #numStr
    local list = {}
    local byteIndex
    for k = 1, numLen do
        byteIndex = string.byte(numStr, k)
        local idxStr
        if byteIndex == 46 then
            --小数点
            idxStr = dotStr
        else
            local index = string.char(byteIndex)
            idxStr = string.format(fmtStr, tostring(index))
        end
        table.insert(list, idxStr)
    end
    return table.concat(list, "")
end

function LUtil.FormatPowerNumSpriteText(num)
    local numStr = tostring(math.floor(math.abs(num)))
    local list = {}
    table.insert(list, "<sprite index=10>")
    local fmtStr = "<sprite index=%s>"
    for k = 1, #numStr do
        local index = string.char(string.byte(numStr, k))
        local idxStr = string.format(fmtStr, tostring(index))
        table.insert(list, idxStr)
    end
    return table.concat(list, "")
end

function LUtil.FormatPowerShowStr(power, cnRate, enRate, isNotSmallSymbol)
    local sizeRate = cnRate or 120
    if gLGameLanguage:IsJapanVersion() then
        sizeRate = enRate or 100
    elseif gLGameLanguage:IsForeignVersion() then
        sizeRate = enRate or 120
    end

    local isUseSpecialFormat =  (gLGameLanguage:IsSEALngRegion() or gLGameLanguage:IsAmericaRegion()) and (not gLGameLanguage:IsEnglishVersion())
    
    if not isUseSpecialFormat then 
        --判断越南地区
        isUseSpecialFormat = gLGameLanguage:IsVietnamRegion()  and ( gLGameLanguage:IsChineseVersion())  
    end 
    if isUseSpecialFormat then
        local str = "<color=#FFF7C8>#a1#</color>"
        local tempStr = LUtil.FormatCoversionHurtNumSpriteText(power, nil, sizeRate, 18, nil, true)
        str = string.replace(str, tempStr)
        return str
    end

    return LUtil.FormatCoversionHurtNumSpriteText(power, nil, sizeRate, 18, nil, isNotSmallSymbol)
end

function LUtil.FormatArtNumText(num)
    local numStr = tostring(math.floor(math.abs(num)))
    local list = {}
    local fmtStr = "<sprite index=%s>"
    for k = 1, #numStr do
        local index = string.char(string.byte(numStr, k))
        local idxStr = string.format(fmtStr, tostring(index))
        table.insert(list, idxStr)
    end
    return table.concat(list)
end

-----------------------------------------------------------------
local colorTable = {
    ["white"] = "#ffffff",
    ["blue"] = "#1b62a3",
    ["purple"] = "#9624ab",
    ["orange"] = "#d2730f",
    ["red"] = "#c81212",
    ["yellow"] = "#817900",
    ["black"] = "#734f22",
    ["grey"] = "#cbe3fa",
    ["green"] = "#139057",
    ["unselected"] = "#bfbddb",


    ["lightRed"] = "#c81212",
    ["lightBlue"] = "#e5e5e5",
    ["darkYellow"] = "#d2730f",
    ["midYellow"] = "#bfab80",
    ["lightYellow"] = "#fdfddd",
    ["pink"] = "#ffe3f9",
    ["darkGrey"] = "#7f8bbf",
    ["lightGrey"] = "#b9c9eb",
    ["normal"] = "#c5cced",
    ["lightGreen"] = "#139057",
    ["yellow_1"] = "#f5eac0",
    ["grey_1"] = "#9f835c",
    ["yellow_2"] = "#feeba7",
    ["grey_2"] = "#bfc4d9",
    ["black_2"] = "#272a35",
    ["red_1"] = "#f93636",
    ["storyActive"] = "#734F22",
    ["storyUnActive"] = "#5f6d7b",
    ["lightGreen_new"] = "#68e6ac", -- 新的部分用的绿色
}

function LUtil.GetColorByKey(color)
    return colorTable[color] or color
end

function LUtil.FormatColorStr(str, color)
    if (color) then
        local colorStr = LUtil.GetColorByKey(color)
        return string.format("<%s>%s</color>", colorStr, str)
    else
        return str
    end
end

function LUtil.FormatColorStrs(str1, str2, color)
    if (color) then
        local colorStr = LUtil.GetColorByKey(color)
        return string.format("<%s>%s</color>/%s", colorStr, str1, str2)
    else
        return string.format("%s/%s", str1, str2)
    end
end

function LUtil.FormatSizeStr(str, size)
    return string.format("<size=%s>%s</size>", size, str)
end

--去除文字中的颜色，timeNum = 次数，不填表示全部去除
function LUtil.RemoveAllColorStr(str, timeNum)
    local s = "<color=#(%x+)>"
    str = string.gsub(str, s, "", timeNum)

    local e = "</color>"
    str = string.gsub(str, e, "", timeNum)
    return str
end

------------------------------------------------------------------
function LUtil.GetRefItemData(itemDataStr)
    --获取奖励数据
    local dataArry = string.split(itemDataStr, "=")
    local list = { type = tonumber(dataArry[1]), refId = tonumber(dataArry[2]), count = tonumber(dataArry[3]) }
    list.itemId = list.refId
    list.itemNum = list.count
    list.itype = list.type
    list.itemType = list.type
    return list
end

function LUtil.GetRefItemFourData(itemDataStr)
    --获取奖励数据 类型，id，数量，是否特效
    local dataArry = string.split(itemDataStr, "=")
    local list = { type = tonumber(dataArry[1]), refId = tonumber(dataArry[2]), count = tonumber(dataArry[3]), bEff = tonumber(dataArry[4]) == 1 }
    list.itemId = list.refId
    list.itemNum = list.count
    list.itype = list.type
    list.itemType = list.type
    return list
end

function LUtil.GetRefItemDataList(itemDataStrList)
    local list = {}
    local dataArry = string.split(itemDataStrList, ",")
    for i, v in ipairs(dataArry) do
        local attr = LUtil.GetRefItemFourData(v)
        table.insert(list, attr)
    end
    return list
end

function LUtil.GetRefAttrData(attrDataStr)
    --获取属性数据
    local list = {}
    local attrDataArry = string.split(attrDataStr, ",")
    for i, v in ipairs(attrDataArry) do
        local attr = LUtil.GetRefAttr(v)
        table.insert(list, attr)
    end
    return list
end

function LUtil.GetRefAttr(attrStr)
    --获取属性
    local attrArry = string.split(attrStr, "=")
    local attr = {
        refId = tonumber(attrArry[1]),
        numType = tonumber(attrArry[2]),
        value = tonumber(attrArry[3])
    }
    return attr
end

------------------------------------------------------------------
---convert 字符表情数字为二进制
function LUtil.ChatInfoFaceDecToBin(msg)
    --聊天表情
    for v in string.gmatch(msg, "(#%d+#)") do
        local fID = string.match(v, "%d+")
        local ref = GameTable.ChattingFaceRef[tonumber(fID)]
        if (ref) then
            local numStr = ref.faceinstead2 or ""
            msg = string.gsub(msg, v, numStr, 1)
        end
    end
    return msg
end

---convert 字符表情数字解为十进制
function LUtil.ChatInfoFaceBinToDec(msg)
    local dataMap = gModelChat and gModelChat:GetFaceBinToFaceRefIdData()
    dataMap = dataMap or {}
    for v in string.gmatch(msg, "(#%d+#)") do
        local refId = dataMap[v]
        if refId then
            msg = string.gsub(msg, v, "#" .. tostring(refId) .. "#", 1)
        end
    end
    return msg
end

local faceFormat = "<size=%s><sprite index=%s></size>"

function LUtil.GetFaceStr(msg, size)
    --聊天表情
    for v in string.gmatch(msg, "(#%d+#)") do
        local fID = string.match(v, "%d+")
        local ref = GameTable.ChattingFaceRef[tonumber(fID)]
        local numStr = v
        if (ref) then
            if (ref.type == 1) then
                if size == -1 then
                    numStr = string.format("<sprite index=%s>", ref.rank)
                else
                    numStr = string.format(faceFormat, size, ref.rank)
                end
            end
        end
        msg = string.gsub(msg, v, numStr, 1)
    end
    return msg
end

---获取聊天大表情字ID
function LUtil.ChatInfoGetDaFace(msg)
    local text = string.match(msg, "#%d+#")
    if (text) then
        local fID = string.match(text, "%d+")
        local refId = tonumber(fID)
        local isDa = gModelChat:GetIsDaFace(refId)
        if (isDa) then
            return refId
        end
    end
    return 0
end

--检测信息是否只包含表情
function LUtil.CheckInfoOnlyFace(msg)
    local text = string.match(msg, "#%d+#")
    if not text then
        return false
    end

    text = string.gsub(msg, "#%d+#", "")
    text = string.gsub(text, " ", "")
    return string.isempty(text)
end

function LUtil.GetRichTexts(str)
    local capList = {}
    local start = 1
    local s, e, cap1, cap2, cap3 = string.find(str, "<(.-)>(.-)<(.-)>", start)
    while s and e do

        local data = {
            s = s,
            e = e,
            cap1 = cap1,
            cap2 = cap2,
            cap3 = cap3
        }
        table.insert(capList, data)
        start = e + 1
        s, e, cap1, cap2, cap3 = string.find(str, "<(.-)>(.-)<(.-)>", start)
    end
    return capList
end

function LUtil.FormatChatMsg(msg, name, emojiSize)
    local str = msg
    local text = string.match(msg, "%@" .. name)
    if (text) then
        str = string.gsub(str, text, "<u>" .. text .. "</u>", 1)
    end

    str = LUtil.GetFaceStr(str, emojiSize)
    return str
end

---解析后端josn数据--{key:value}
function LUtil.GetReplacedContent(content, para, shiftN, noticeRefId)
    if string.isempty(para) then
        return content
    end
    local pattern = JSON.decode(para)
    if (not pattern) then
        return content
    end
    local keys = {}
    if noticeRefId then
        --公告102特殊处理
        local noticesRef = GameTable.GameMailNoticesRef[noticeRefId]
        local transform = noticesRef.transform
        if not string.isempty(transform) then
            local arr = string.split(transform, "|")
            for i, v in ipairs(arr) do
                keys[v] = true
            end
        end
        if noticeRefId == 102 then
            local a2 = pattern.a2
            local arr = string.split(a2, "|")
            local a2Str = ""
            local ref = GameTable.LeaderboardingRef[tonumber(arr[1])]
            if ref then
                a2Str = ccLngText(ref.text)
            end
            if arr[2] then
                local markRef = GameTable.LeaderboardMarkRewardRef[tonumber(arr[2])]
                if markRef then
                    local stage = markRef.stage
                    a2Str = string.replace(a2Str, LUtil.NumberCoversion(stage))
                end
            end
            pattern.a2 = a2Str
        end
    end
    local t = {}
    if not string.isempty(shiftN) then
        local arr = string.split(shiftN, "|")
        for i, v in ipairs(arr) do
            pattern[v] = LUtil.NumberCoversion(tonumber(pattern[v]))
        end
    end

    for k, v in pairs(pattern) do
        local key = tostring(k)
        local value = tostring(v)
        if keys[key] then
            value = LUtil.NumberCoversion(tonumber(value))
        end
        if string.find(key, "c") or string.find(key, "b") then
            local dataArry = string.split(value, ".")
            local refId = dataArry[2]

            if not refId then
                --翻译文本id
                value = ccLngText(value)
            else
                -- 表格数据配置
                local ref = GameTable[dataArry[1]]
                ref = ref[tonumber(refId)]
                local arry = string.split(dataArry[3], "=")
                local name = ccLngText(ref[arry[1]])
                if (string.isempty(name)) then
                    name = ref[arry[1]]
                end
                if (arry[2] == "0") then
                    value = name
                else
                    value = name .. "*" .. arry[2]
                end
            end

            --为兼容旧的参数b， 将key = 'b'替换为'c'
            if string.find(key, "b") then
                key = string.gsub(key, 'b', 'c')
            end
        elseif string.find(key, 'd') then
            if gModelActivity then
                value = gModelActivity:GetLngNameById(v)
            end
        elseif string.find(key, "e") and not string.find(key, "key") then
            value = gModelItem:FormatItemListStr(v)
        elseif string.find(key, 'f') then
            value = gModelPay:GetPayPointSymbol(v)
        end
        t[key] = value
    end

    local ret = string.gsub(content, "#(%w+)#", t)
    return ret
end


-----------------------------------------------------------------
--数值转换
function LUtil.NumberCoversion(number, isSpecial)
    if not number then
        return 0
    end
    --数值转换配置
    local numberLen, currRef, currNum, currNumberArr, currStr
    local toStr = tostring(number)
    local strArr = string.split(toStr, "+")--判断number是否超过位数
    if strArr[2] then
        numberLen = tonumber(strArr[2]) + 1
    else
        numberLen = #strArr[1]
    end

    --local isForeign = gLGameLanguage:IsForeignVersion()
    for i = 1, #GameTable.NumberCoversionRef do
        local figure = GameTable.NumberCoversionRef[i].figure

        --[[		if isForeign then
                    if i == 2 then
                        figure = 5
                    elseif i == 3 then
                        figure = 7
                    end
                end]]

        figure = LUtil.GetNumberCoversionFigure(figure, i)
        if (numberLen >= figure) then
            --refId = i
            currRef = GameTable.NumberCoversionRef[i]--判断区间，取当前区间的配置
        else
            break
        end
    end
    local numCoversionRefId = currRef.id
    local retainNumber = currRef.retainNumber--保留几位小数
    local divisor = currRef.divisor--幂

    --[[	if isForeign then
            if numCoversionRefId == 2 then
                divisor = 3
            elseif numCoversionRefId == 3 then
                divisor = 6
            end
        end]]

    divisor = LUtil.GetNumberCoversionDivisor(divisor, numCoversionRefId)

    currNum = number / (10 ^ (divisor - retainNumber))

    local numArr = string.split(tostring(currNum), ".")--不进行四舍五入
    if (retainNumber > 0) then
        currNum = tonumber(numArr[1]) / (10 ^ retainNumber)
    else
        currNum = tonumber(numArr[1])
    end

    currNumberArr = string.split(tostring(currNum), ".")
    local dqLen = 0
    if currNumberArr[2] then
        for i = 1, retainNumber do
            if (tonumber(string.sub(currNumberArr[2], -i)) > 0) then
                break
            else
                dqLen = i
            end
        end
    end
    if dqLen > 0 then
        dqLen = #tostring(currNum) - dqLen
        currStr = string.sub(tostring(currNum), 0, dqLen)--去小数点最后一个0

    else
        currStr = tostring(currNum)
    end

    local decimals = #currNumberArr[1] / 3--取小数点前的数,有几个3
    local len = math.floor(decimals)
    if decimals - len == 0 then
        len = len - 1
    end

    ----应策划要求，去除数字中插入的 分号(,)
    --for i = 1, len do
    --	local cutOut=(3*i)+(i-1)
    --	currStr= string.sub(currStr,0,#currStr-cutOut)..",".. string.sub(currStr,-cutOut)--每3位数加","
    --end
    if gLGameLanguage:IsForeignRegion() and isSpecial then
        if numArr[2] then
            if numArr[1] % 10 == 0 then
                currStr = currStr .. ".0" .. numArr[2]
            else
                currStr = currStr .. numArr[2]
            end
        end
    end
    currStr = currStr .. ccLngText(currRef.suffix)
    return currStr
end

--战力转换
function LUtil.PowerNumberCoversion(powerNum)
    if not powerNum or powerNum == "" then
        return 0
    end
    local isForeign  =gLGameLanguage:IsForeignRegion()  and ( not gLGameLanguage:IsJapanRegion())
    if isForeign then
        local powerNum = checknumber(powerNum)
        if powerNum >= 1000000 then
            --阶限值 大于这个走另一个显示的接口
            return LUtil.NumberCoversion(powerNum)
        end
    end

    local power = LUtil.ToInteger(tonumber(powerNum))
    --return LUtil.NumberCoversion(power)
    return LUtil.GetPowerNumberCoversion(power)
end

--增加千位分隔符、百万分隔符，只处理整数
function LUtil.AddNumberSeparate(num)
    local str = tostring(num)
    local len = string.len(str)
    local t = {}
    local s = len % 3
    local temp = nil
    if s > 0 then
        temp = string.sub(str, 1, s)
        table.insert(t, temp)
    end
    for i = s + 3, len, 3 do
        temp = string.sub(str, i - 2, i)
        table.insert(t, temp)
    end
    local ret = table.concat(t, ",")
    return ret
end

local emojiPattern = {
    "[\240][\159][\140-\152][\128-\191]",
    "[\240][\159][\153][\128-\143]",
    "[\240][\159][\154-\155][\128-\191]",
    "[\226][\152-\172][\128-\191]",
    "[\226][\173][\128-\149]",
}

function LUtil.ReplaceEmoji(str)
    local ret = str
    for k, v in ipairs(emojiPattern) do
        ret = string.gsub(ret, v, "?")
    end
    return ret
end

function LUtil.IsNewDay(oldTime, newTime)
    local timeDif = newTime - oldTime
    if timeDif > 86400 then
        return true
    end
    local date = LUtil.OSDate("*t", oldTime)
    local oldDay = date.day
    date = LUtil.OSDate("*t", newTime)
    local newDay = date.day
    if newDay > oldDay then
        return true
    end
    return false
end

function LUtil.GetDayPast(startTime)
    return GetServerDayPast(startTime)
end
-----------------------------------------------------------------
function LUtil.GetHeroStarImg(star)
    local img, temp, index
    if star > 15 then
        img = "hero_icon_star4"
        temp = star - 15
        index = 4
    elseif star > 10 then
        img = "hero_icon_star3"
        temp = star - 10
        index = 3
    elseif star > 5 then
        temp = star - 5
        img = "hero_icon_star2"
        index = 2
    else
        img = "hero_icon_star1"
        temp = star
        index = 1
    end

    if temp > 5 then
        temp = temp % 5
        if temp == 0 then
            temp = 5
        end
    end

    return img, temp, index
end

--function LUtil.GetStarId(starType,starLv)
--	return starType * 100 + starLv
--end
------------------------------------------------------------------

function LUtil.ClearHashTable(t)
    if not t then
        return
    end
    for k, v in pairs(t) do
        if v.Destroy then
            v:Destroy()
        end
        t[k] = nil
    end
    t = nil
end

function LUtil.ClearLinearTable(t)
    if not t then
        return
    end
    for k, v in ipairs(t) do
        if v.Destroy then
            v:Destroy()
        end
        t[k] = nil
    end
    t = nil
end

------------------------------------------------------------------
function LUtil.GenerateSeqList(len)
    local tbl = {}
    for k = 1, len do
        table.insert(tbl, k)
    end
    return tbl
end

function LUtil.RandIntegerBetween(min, max)
    return LUtil.RandInteger(max - min + 1) + min - 1
end

---放大倍数随机
function LUtil.RandInteger(len)
    if len == 1 then
        return 1
    end
    local rand = math.random(1, len * 100)
    rand = rand % len + 1
    return rand
end
------------------------------------------------------------------
function LUtil.GetResonanceColor(isResonance)
    local color = "FFFFFFFF"
    local mat = "OPPOSansRMixB_000000_2"
    if isResonance == 1 then
        color = "ffe680FF"
        mat = "OPPOSansRMixB_8a0d00_2"
    end
    return color, mat
end

function LUtil.ConvertPixelPosToUnitPos(pos)
    return Vector3(pos.x * 0.01, pos.y * 0.01, (pos.z or 0) * 0.01)
end
-----------------------------------------------------------------
function LUtil.GetCloseTipsId()
    return 10103
end

local outlineMatMap = {
    ["black"] = "SourceHanSerifCN_000000_2",
    ["yellow"] = "SourceHanSerifCN_442a00_2",
    ["blue"] = "SourceHanSerifCN_132262_2",
    ["red"] = "SourceHanSerifCN_550b00_2",
    ["grey"] = "SourceHanSerifCN_000000_a",

}

function LUtil.GetOutLineMat(color)
    color = color or "black"
    return outlineMatMap[color]
end

function LUtil.GetWebViewMargin(pos0, pos1, camera)
    local poses = {}
    local screenPos = camera:WorldToScreenPoint(pos0)
    print(string.format("margin%s x %s,y %s", 1, screenPos.x, screenPos.y))
    table.insert(poses, screenPos)
    screenPos = camera:WorldToScreenPoint(pos1)
    print(string.format("margin%s x %s,y %s", 2, screenPos.x, screenPos.y))
    table.insert(poses, screenPos)

    local uWidth = UnityEngine.Screen.width
    local uHeight = UnityEngine.Screen.height

    local left = poses[1].x
    local bottom = poses[1].y
    local top = uHeight - poses[2].y
    local right = uWidth - poses[2].x

    if CS.IsOSAndroid() then
        local realRect = LNativeHelper.GetDeviceDisplayRect()
        if not string.isempty(realRect) then
            local arrResult = string.split(realRect, "|") or {}
            local rectW = tonumber(arrResult[1]) or 0
            local rectH = tonumber(arrResult[2]) or 0
            print(string.format("unity screen rect=%s|%s , device now rect %s|%s", uWidth, uHeight, rectW, rectH))
            if rectW > 0 and rectH > 0 then
                if rectW ~= uWidth then
                    local sx = rectW / uWidth
                    left = left * sx
                    right = right * sx
                end

                if rectH ~= uHeight then
                    local sy = rectH / uHeight
                    top = top * sy
                    bottom = bottom * sy
                end
            end
        end
    end

    local data = {
        left = math.floor(left),
        top = math.floor(top),
        right = math.floor(right),
        bottom = math.floor(bottom),
    }

    return data
end

function LUtil.CreateHyperContent(tran, text, msg, idList, hyperCreateFun, hyperClickFun)
    local replaceList = {}

    local index = 0
    local pattern = "(<a (%w+)>(.-)</a>)"
    for v1, v2, v3 in string.gmatch(text, pattern) do
        index = index + 1

        local data = {
            origin = v1,
            key = v2,
            value = v3,
        }
        replaceList[index] = data
    end

    local uiHyper
    if (index > 0) then
        uiHyper = hyperCreateFun(tran)
        if not uiHyper then
            return text
        end
    else
        return text
    end

    local pattern = JSON.decode(msg)
    local paraList = {}
    if pattern then
        for k, v in pairs(pattern) do
            local array = string.split(v, ";")
            paraList[k] = array
        end
    end

    local idxRecord = {}

    for i = 1, index do
        local data = replaceList[i]

        local key = data.key
        local value = ""

        local idx = idxRecord[key] --按key 分别累计序号
        if not idx then
            idx = 1
        else
            idx = idx + 1
        end
        idxRecord[key] = idx

        if key == "key2" then
            value = idList[idx]
        else
            local array = paraList[key]
            if array then
                value = array[idx]
            end
        end
        local mText = uiHyper:AddHyper(data.value, { func = hyperClickFun, para = { key = key, msg = value } })
        text = LUtil.ReplaceStrMeta(text, data.origin, mText)
    end

    return text
end

---自定义超链接文本去除
---支持<a key=123>跳转</a>
function LUtil.ConvertHyperToNormal(text)
    local replaceList = {}

    local index = 0
    local pattern = "(<a (%w+)=(.-)>(.-)</a>)"
    for v1, v2, v3, v4 in string.gmatch(text, pattern) do
        index = index + 1
        local data = {
            origin = v1,
            key = v2,
            para = v3,
            value = v4,
        }
        replaceList[index] = data
    end

    if index <= 0 then
        return text
    end

    local retStr = text
    for i = 1, index do
        local data = replaceList[i]
        retStr = LUtil.ReplaceStrMeta(retStr, data.origin, data.value)
    end
    return retStr
end

---超链接文本生成
---支持<link="http:www.abc123.com">网站</link>,<a key=123>跳转</a>
function LUtil.CreateHyperWithValue(tran, text, hyperCreateFun, hyperClickFun)
    local uiHyper = hyperCreateFun(tran)

    local linkPattern = "<link=\"(.-)\">.-</link>"
    for v in string.gmatch(text, linkPattern) do
        local key = v
        if string.find(v, "http") then
            uiHyper:AddHyperFun({ func = hyperClickFun, para = { key = ModelChat.HYPER_WEB_LINK, msg = key } }, key)
        end
    end

    local replaceList = {}

    local index = 0
    local pattern = "(<a (%w+)=(.-)>(.-)</a>)"
    for v1, v2, v3, v4 in string.gmatch(text, pattern) do
        index = index + 1
        local data = {
            origin = v1,
            key = v2,
            para = v3,
            value = v4,
        }
        replaceList[index] = data
    end

    if index <= 0 then
        return text
    end

    local retStr = text
    for i = 1, index do
        local data = replaceList[i]
        local mText = uiHyper:AddHyper(data.value, { func = hyperClickFun, para = { key = data.key, msg = data.para } })
        retStr = LUtil.ReplaceStrMeta(retStr, data.origin, mText)
    end
    return retStr
end

---单纯替换
function LUtil.ReplaceStrMeta(str, origin, repl)
    local metaSign = "[%(%)%+%-%*%?%[%]%^%$%.]"

    local repTab = {
        ["?"] = "%?",
        ["("] = "%(",
        [")"] = "%)",
        ["+"] = "%+",
        ["-"] = "%-",
        ["*"] = "%*",
        ["["] = "%[",
        ["]"] = "%]",
        ["^"] = "%^",
        ["$"] = "%$",
        ["."] = "%.",
    }

    local originPattern = string.gsub(origin, metaSign, repTab)
    return string.gsub(str, originPattern, repl)
end

function LUtil.GetRootName(path)
    if string.isempty(path) then
        return
    end
    local s, e = string.find(path, "/")
    if not s or not e then
        return
    end

    local str = string.sub(path, 1, s - 1)
    return str
end
function LUtil.GetRelativePath(path)
    if string.isempty(path) then
        return
    end
    local s, e = string.find(path, "/")
    if not s or not e then
        return
    end
    local len = string.len(path)
    local str = string.sub(path, s + 1, len)
    return str
end
function LUtil.GetCameraRange(x, y)
    local orthgraphicSize, designOrthgraphicSize = LUtil.GetCameraSize()

    local offsetAreaY = 0
    local safeArea = LNotchUtil.SafeArea
    if safeArea then
        local rate = safeArea.y / LNotchUtil.height
        offsetAreaY = rate * orthgraphicSize * 2
    end

    local min = x
    local max = y + (designOrthgraphicSize - orthgraphicSize) - offsetAreaY
    return Vector2.New(min, max)
end
function LUtil.GetCameraSize()
    local designWidth = LGameQuality.SCREEN_WIDTH_DESIGN-- 设计分辨率
    local designHeight = LGameQuality.SCREEN_HEIGHT_DESIGN-- 设计分辨率
    local pixelPreUnit = 100

    local designOrthgraphicSize = designHeight / pixelPreUnit * 0.5
    local orthgraphicSize = designOrthgraphicSize

    local UScreen = UnityEngine.Screen
    local screenWidth = UScreen.width
    local screenHeight = UScreen.height

    -- adapt by width
    local nowRate = screenWidth / screenHeight
    local designRate = designWidth / designHeight
    if (nowRate >= designRate) then

    else
        orthgraphicSize = designRate / nowRate * designOrthgraphicSize
    end

    return orthgraphicSize, designOrthgraphicSize
end

function LUtil.ToInteger(value)
    value = value or 0
    return math.floor(value)
end

function LUtil.GetCurPercent(dataList, curValue, startValue)
    startValue = startValue or 0
    local stageCnt = #dataList
    local curStage = 0
    for i = 1, stageCnt do
        if curValue < tonumber(dataList[i]) then
            break
        end
        curStage = i
    end
    local progress = 0
    if curStage == stageCnt then
        progress = 1
    else
        local startTimes = curStage == 0 and startValue or tonumber(dataList[curStage])
        local endTimes = tonumber(dataList[curStage + 1])
        progress = curStage / stageCnt + (curValue - startTimes) / (endTimes - startTimes) / stageCnt
    end

    progress = Mathf.Clamp(progress, 0, 1)

    return progress
end

function LUtil.GetPercentImpl(pointList, curValue)
    local stageCnt = #pointList
    local curStage = 1
    for i = 1, stageCnt do
        if curValue < tonumber(pointList[i]) then
            break
        end
        curStage = i
    end
    local progress = 0
    if curStage == stageCnt then
        progress = 1
    else
        local startValue = tonumber(pointList[curStage])
        local endValue = tonumber(pointList[curStage + 1])
        progress = (curStage - 1) / (stageCnt - 1) + (curValue - startValue) / (endValue - startValue) / (stageCnt - 1)
    end

    progress = Mathf.Clamp(progress, 0, 1)

    return progress
end

function LUtil.FormatVecKey(x, y)
    return string.format("%s|%s", x, y)
end

local imgToOutlineMap = {
    ["public_btn_1_1"] = "SourceHanSerifCN_132262_2",
    ["public_btn_1_2"] = "SourceHanSerifCN_442a00_2",
    ["public_btn_1_3"] = "SourceHanSerifCN_550b00_2",
    ["public_btn_ash_1"] = "SourceHanSerifCN_000000_a",
    ["public_btn_2_1"] = "SourceHanSerifCN_132262_2",
    ["public_btn_2_2"] = "SourceHanSerifCN_442a00_2",
    ["public_btn_2_3"] = "SourceHanSerifCN_550b00_2",
    ["public_btn_ash_2"] = "SourceHanSerifCN_000000_a",
    ["public_btn_3_1"] = "SourceHanSerifCN_132262_2",
    ["public_btn_3_2"] = "SourceHanSerifCN_442a00_2",
    ["public_btn_3_3"] = "SourceHanSerifCN_550b00_2",
    ["public_btn_ash_8"] = "SourceHanSerifCN_000000_a",
    ["public_btn_ash_8_1"] = "SourceHanSerifCN_000000_a",

}

local colorBtnImgMap = {
    ["blue_1"] = "public_btn_1_1",
    ["blue_2"] = "public_btn_2_1",
    ["blue_3"] = "public_btn_3_1",
    ["yellow_1"] = "public_btn_1_2",
    ["yellow_2"] = "public_btn_2_2",
    ["yellow_3"] = "public_btn_3_2",
    ["red_1"] = "public_btn_1_3",
    ["red_2"] = "public_btn_2_3",
    ["red_3"] = "public_btn_3_3",
    ["ash_1"] = "public_btn_ash_1",
    ["ash_2"] = "public_btn_ash_2",
    ["ash_3"] = "public_btn_ash_8",
    ["ash_4"] = "public_btn_ash_8_1",
}

function LUtil.GetOutlineMatByImg(imgPath)
    return imgToOutlineMap[imgPath]
end

function LUtil.GetGrayBtnImage(size)
    if size == 1 then
        return "public_btn_ash_1"
    elseif size == 2 then
        return "public_btn_ash_2"
    elseif size == 3 then
        return "public_btn_ash_8"
    end
end

function LUtil.GetBtnImg(btnType)
    return colorBtnImgMap[btnType]
end

------------------------------------------------------------------
---post 敏感信息b64 之后传输
function LUtil.MakeB64SendData(str)
    --if true then return str end
    if str == nil or str == "" then
        return str
    end
    local sIdx, eIdx = string.find(str, "?")
    local sendStr
    local preStr
    if sIdx and eIdx then
        preStr = string.sub(str, 1, sIdx - 1)
        sendStr = string.sub(str, eIdx + 1, -1)
    else
        preStr = ""
        sendStr = str
    end
    local encodeStr = CS.Base64Encode(sendStr)
    -- encodeStr = string.urlencode(encodeStr)
    local retStr = preStr .. "?bsdata=" .. encodeStr
    return retStr
end

local enMonthMap = {
    [1] = "Jan",
    [2] = "Feb",
    [3] = "Mar",
    [4] = "Apr",
    [5] = "May",
    [6] = "Jun",
    [7] = "Jul",
    [8] = "Aug",
    [9] = "Sep",
    [10] = "Oct",
    [11] = "Nov",
    [12] = "Dec",

}

function LUtil.GetMonthShow(m)
    if gLGameLanguage:IsUSAVersion() then
        return enMonthMap[m]
    else
        return m
    end
end

function LUtil.GetDayShow(d)
    if gLGameLanguage:IsUSAVersion() then
        return string.format("%sth", d)
    else
        return d
    end
end

function LUtil.OSDate(format, timestamp)
    local serverOffset = GetTimezone()
    --local clientOffset = MgrCenter.NetworkMgr:GetClientTimeZone()

    local temp = timestamp + serverOffset

    temp = math.max(0, temp)

    --return os.date(format,temp)

    return LUtil.GetDate(format, temp)
end

function LUtil.OSTime(timeTable)
    if not timeTable then
        return GetTimestamp()
    else
        local serverOffset = GetTimezone()
        local time = LUtil.GetTime(timeTable) - serverOffset
        return time
    end

end

function LUtil.GetTimeFromStr(str, delimiterStr)
    local strs = string.split(str, delimiterStr and delimiterStr or '-')
    local year = strs[1] and tonumber(strs[1]) or 1
    local month = strs[2] and tonumber(strs[2]) or 1
    local day = strs[3] and tonumber(strs[3]) or 1
    local hour = strs[4] and tonumber(strs[4]) or 0
    local min = strs[5] and tonumber(strs[5]) or 0

    local timeTable = {
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
    }

    return LUtil.OSTime(timeTable)
end

function LUtil.FormatPrinterData(str)


    str = string.gsub(str, "<br>", "\n")

    local capList = {}
    local start = 1
    local s, e, cap1, cap2, cap3 = string.find(str, "<(.-)>(.-)</(.-)>", start)
    while s and e do

        local data = {
            s = s,
            e = e,
            cap1 = cap1,
            cap2 = cap2,
            cap3 = cap3
        }
        table.insert(capList, data)

        start = e + 1
        s, e, cap1, cap2, cap3 = string.find(str, "<(.-)>(.-)</(.-)>", start)
    end

    start = 1
    local tempStr, strData
    local strDataList = {}
    local strLen = string.len(str)
    for k, v in ipairs(capList) do
        if v.s > start then
            tempStr = string.sub(str, start, v.s - 1)
            strData = {
                type = 1,
                str = tempStr,
            }
            table.insert(strDataList, strData)
        end

        strData = {
            type = 2,
            str = v.cap2,
            signS = v.cap1,
            signE = v.cap3,
        }
        table.insert(strDataList, strData)

        start = v.e + 1
    end

    if start <= strLen then
        tempStr = string.sub(str, start, strLen)
        strData = {
            type = 1,
            str = tempStr,
        }
        table.insert(strDataList, strData)
    end

    local len = 0
    for k, v in ipairs(strDataList) do
        len = len + LXFW.LxUtf8.cc_len(v.str)
    end

    local itor = function(value)
        --printInfoN("curLen "..value)
        local curLen = value
        local strList = {}
        local tempLen = 0
        local lastLen = 0
        local tempStr
        for k, v in ipairs(strDataList) do
            tempLen = LXFW.LxUtf8.cc_len(v.str) + tempLen
            if curLen >= tempLen then
                tempStr = v.str

                if v.type == 2 then
                    tempStr = string.format("<%s>%s</%s>", v.signS, tempStr, v.signE)
                end
                table.insert(strList, tempStr)
                if curLen == tempLen then
                    break
                end
            else
                tempStr = LXFW.LxUtf8.sub(v.str, 1, curLen - lastLen)

                if v.type == 2 then
                    tempStr = string.format("<%s>%s</%s>", v.signS, tempStr, v.signE)
                end
                table.insert(strList, tempStr)
                break
            end
            lastLen = tempLen
        end

        return table.concat(strList)

    end

    return len, itor
end

--------------------------------------------------------
--- 通用道具配置字符串转换成列表
function LUtil.ConvertCommonItemStrToList(str, delimiter)
    str = str or ""
    local itemList = {}
    delimiter = delimiter or ","
    local strList = string.split(str, delimiter)
    for i, v in ipairs(strList) do
        v = string.split(v, "=")
        table.insert(itemList, {
            itemType = tonumber(v[1]),
            itemId = tonumber(v[2]),
            itemNum = tonumber(v[3]),
        })
    end
    return itemList
end

function LUtil.ConvertCommonAttrStrToList(str, delimiter)
    str = str or ""
    local attrList = {}
    delimiter = delimiter or ","
    local strList = string.split(str, delimiter)
    for i, v in ipairs(strList) do
        v = string.split(v, "=")
        table.insert(attrList, {
            attrRefId = tonumber(v[1]),
            attrType = tonumber(v[2]),
            attrNum = tonumber(v[3]),
        })
    end
    return attrList
end
function LUtil.ConvertCommonAttrStrToMap(str, delimiter)
    str = str or ""
    local attrList = {}
    delimiter = delimiter or ","
    local strList = string.split(str, delimiter)
    for i, v in ipairs(strList) do
        v = string.split(v, "=")
        local id = tonumber(v[1])
        local type = tonumber(v[2])
        if not attrList[id] then
            attrList[id] = {}
        end
        attrList[id][type] = tonumber(v[3]) + (attrList[id][type] or 0)
    end
    return attrList
end

function LUtil.GetCommonAttrKeyList(attrList)
    attrList = attrList or {}
    local list = {}
    local attrRefId, attrType
    for i, v in ipairs(attrList) do
        attrRefId = v.attrRefId
        local attrTypeInfo = list[attrRefId]
        if not attrTypeInfo then
            attrTypeInfo = {}
            list[attrRefId] = attrTypeInfo
        end
        attrType = v.attrType
        local attrTypeNum = attrTypeInfo[attrType] or 0
        attrTypeInfo[attrType] = attrTypeNum + v.attrNum
    end
    return list
end

function LUtil.GetAddTwoAttrKeyList(attrKeyList1, attrKeyList2)
    local list = {}
    local attrRefId, attrType
    for k, v in pairs(attrKeyList1) do
        attrRefId = v.attrRefId or k
        local attrTypeInfo = list[attrRefId]
        if not attrTypeInfo then
            attrTypeInfo = {}
            list[attrRefId] = attrTypeInfo
        end
        for type, value in pairs(v or {}) do
            local attrTypeNum = attrTypeInfo[type] or 0
            attrTypeInfo[type] = attrTypeNum + value
        end
    end
    for k, v in pairs(attrKeyList2) do
        attrRefId = v.attrRefId or k
        local attrTypeInfo = list[attrRefId]
        if not attrTypeInfo then
            attrTypeInfo = {}
            list[attrRefId] = attrTypeInfo
        end
        for type, value in pairs(v or {}) do
            local attrTypeNum = attrTypeInfo[type] or 0
            attrTypeInfo[type] = attrTypeNum + value
        end
    end

    return list
end

function LUtil.GetTwoCommonAttrKeyList(attrList1, attrList2)
    local attrKeyList1 = LUtil.GetCommonAttrKeyList(attrList1)
    local attrKeyList2 = LUtil.GetCommonAttrKeyList(attrList2)
    return LUtil.GetAddTwoAttrKeyList(attrKeyList1, attrKeyList2)
end

function LUtil.GetContrastCommonAttrList(bAttrList, nAttrList)
    local attrKeyMap1 = LUtil.GetCommonAttrKeyList(bAttrList)
    local attrKeyMap2 = LUtil.GetCommonAttrKeyList(nAttrList)

    local list = {}
    for tRefId, tRefIdData in pairs(attrKeyMap2) do
        for attrType, attrNum in pairs(tRefIdData) do
            local bAttrValue = 0
            local bRefIdData = attrKeyMap1[tRefId]
            if bRefIdData and bRefIdData[attrType] then
                bAttrValue = bRefIdData[attrType]
            end
            table.insert(list, {
                attrRefId = tRefId,
                attrType = attrType,
                bAttrValue = bAttrValue,
                nAttrValue = attrNum,
            })
        end
    end

    return list
end

function LUtil.GetTwoCommonAttrAddSortList(attrList1, attrList2)
    local attrAddList = LUtil.GetTwoCommonAttrKeyList(attrList1, attrList2)
    local list = LUtil.MapAttrToListAttr(attrAddList)
    return list
end
function LUtil.MapAttrToListAttr(attrAddList)
    local list = {}
    for attrRefId, attrTypeInfo in pairs(attrAddList) do
        for attrType, attrNum in pairs(attrTypeInfo) do
            table.insert(list, {
                attrRefId = attrRefId,
                attrType = attrType,
                attrNum = attrNum,
            })
        end
    end
    return list
end

function LUtil.GetSortItemAllAddNumList(itemList)
    itemList = itemList or {}
    local itemKeyList = {}
    local itemType, itemId, itemNum
    for i, v in ipairs(itemList) do
        itemType, itemId = v.itemType or v.type, v.itemId or v.refId
        local itemTypeInfo = itemKeyList[itemType]
        if not itemTypeInfo then
            itemTypeInfo = {}
            itemKeyList[itemType] = itemTypeInfo
        end
        local itemIdInfo = itemTypeInfo[itemId] or 0
        itemNum = v.itemNum or v.count
        itemTypeInfo[itemId] = itemIdInfo + itemNum
    end
    local list = {}
    for tItemType, tItemTypeInfo in pairs(itemKeyList) do
        for tItemId, tItemNum in pairs(tItemTypeInfo) do
            table.insert(list, {
                itemType = tItemType,
                itemId = tItemId,
                itemNum = tItemNum,
            })
        end
    end
    return list
end

function LUtil.FilterEmoji(text)
    if string.isempty(text) then
        return ""
    end
    text = string.gsub(text, "\r", "")
    text = string.gsub(text, "\n", "")
    local str = CS.YXUtility.FilterEmoji(text, "?")
    return str
end
-----------------------------------------------------------------

function LUtil.GetNumberCoversionFigure(figure, index)
    --日语地区排除
    local isForeign = gLGameLanguage:IsForeignVersion() and (not gLGameLanguage:IsJapanRegion())
    if not isForeign then
        return figure
    end
    if index == 2 then
        figure = 5
    elseif index == 3 then
        figure = 7
    end
    return figure
end

function LUtil.GetNumberCoversionDivisor(divisor, numCoversionRefId)
    local isForeign = gLGameLanguage:IsForeignVersion() and (not gLGameLanguage:IsJapanRegion())
    if not isForeign then
        return divisor
    end
    if isForeign then
        if numCoversionRefId == 2 then
            divisor = 3
        elseif numCoversionRefId == 3 then
            divisor = 6
        end
    end
    return divisor
end

function LUtil.GetNumberDigit(number)
    local numberLen
    local toStr = tostring(number)
    local strArr = string.split(toStr, "+")--判断number是否超过位数
    if strArr[2] then
        numberLen = tonumber(strArr[2]) + 1
    else
        numberLen = #strArr[1]
    end
    return numberLen
end

function LUtil.ChangeNumberCoversion(number)
    local numberLen = LUtil.GetNumberDigit(number)
    local currRef
    local numCoversionRef = GameTable.NumberCoversionRef
    for i = 1, #numCoversionRef do
        local figure = LUtil.GetNumberCoversionFigure(numCoversionRef[i].figure, i)
        if numberLen >= figure then
            currRef = GameTable.NumberCoversionRef[i]--判断区间，取当前区间的配置
        else
            break
        end
    end
    local divisor = LUtil.GetNumberCoversionDivisor(currRef.divisor, currRef.id)
    local powerNum = 10 ^ divisor
    return math.floor(number / powerNum) * powerNum
end

---- 新战力显示
function LUtil.GetPowerNumberCoversion(number)
    if not number or number == "" then
        return 0
    end

    local numCoversionRef = GameTable.NumberCoversionRef
    local numCoversionRefLen = #numCoversionRef
    local maxRef = numCoversionRef[numCoversionRefLen]
    if not maxRef then
        return LUtil.NumberCoversion(number)
    end

    local numberLen = LUtil.GetNumberDigit(number)
    local figure = LUtil.GetNumberCoversionFigure(maxRef.figure, numCoversionRefLen)
    if numberLen < figure then
        return LUtil.NumberCoversion(number)
    end

    local divisor = LUtil.GetNumberCoversionDivisor(maxRef.divisor, maxRef.id)
    local powerN = 10 ^ divisor
    local currNum = number / powerN
    if currNum < 1 then
        return LUtil.NumberCoversion(number)
    end

    local firstNum = math.floor(currNum) * powerN
    local lastNum = LUtil.ChangeNumberCoversion(number % powerN)
    local strList = {}
    local numList = { firstNum, lastNum }
    for i, v in ipairs(numList) do
        table.insert(strList, LUtil.NumberCoversion(v))
    end
    return table.concat(strList, "")
end

function LUtil.GetWeekStrByTime(timestamp)
    local week = LUtil.GetWeekByTime(timestamp)
    local weekStrMap = {
        [1] = ccClientText(37529),
        [2] = ccClientText(37530),
        [3] = ccClientText(37531),
        [4] = ccClientText(37532),
        [5] = ccClientText(37533),
        [6] = ccClientText(37534),
        [7] = ccClientText(37535),
    }
    return weekStrMap[week]
end

LUtil.MONTH_TABLE = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

function LUtil.GetDate(format, time)
    format = format or "%m/%d/%y %H:%M:%S"
    format = string.gsub(format, "%%c", "%%m/%%d/%%y %%H:%%M:%%S")
    time = time or os.time()

    time = math.floor(time)

    time = math.max(0, time)

    local defaultTime = time
    local defaultDayTotal = math.floor(time / 86400)

    local year = 1970
    if time > 1577836800 then
        year = 2020
        time = time - 1577836800
    end

    local totalDay = math.floor(time / 86400)

    local month = 1
    local day = 1
    local dayCnt;
    while totalDay > 0 do
        dayCnt = LUtil.IsLeapYear(year) and 366 or 365

        if totalDay < dayCnt then
            break
        end
        year = year + 1
        totalDay = totalDay - dayCnt
    end

    local yday = totalDay

    local isLeap = LUtil.IsLeapYear(year)
    while totalDay > 0 do
        dayCnt = LUtil.MONTH_TABLE[month]
        if month == 2 and isLeap then
            dayCnt = 29
        end
        if totalDay < dayCnt then
            break
        end

        month = month + 1
        totalDay = totalDay - dayCnt
    end

    day = totalDay + 1

    local hour = math.floor(time % 86400 / 3600)
    local min = math.floor(time % 3600 / 60)
    local sec = math.floor(time % 60)

    local wday = LUtil.GetWeek(defaultTime)

    local timeTable = { year = year, month = month, day = day, hour = hour, min = min, sec = sec, wday = wday, yday = yday }

    if format == "*t" then
        return timeTable
    else
        local timeYearStart = defaultDayTotal - yday
        local weekNum = math.floor((timeYearStart - 4) / 7)
        local totalWeekNum = math.floor((defaultDayTotal - 4) / 7)

        local t = {
            m = string.format("%02d", month),
            d = string.format("%02d", day),
            y = year % 100,
            Y = year,
            H = string.format("%02d", hour),
            M = string.format("%02d", min),
            S = string.format("%02d", sec),
            w = wday,
            W = totalWeekNum - weekNum + 1,
        }
        local str = string.gsub(format, "%%([mdyYHMSwW])", t)
        return str
    end

end

---星期 1-7 1:周日
function LUtil.GetWeek(timestamp)
    local day = math.floor(timestamp / 86400)
    return (day + 4) % 7 + 1
end

---@return boolean 是否是周日
function LUtil.CheckIsWeekend(timestamp)
    local week = LUtil.GetWeekByTime(timestamp)
    return week == 6 or week == 7
end

function LUtil.GetTime(timeTable)
    local year = timeTable.year or 1970
    local month = timeTable.month or 1
    local day = timeTable.day or 1
    local hour = timeTable.hour or 0
    local min = timeTable.min or 0
    local sec = timeTable.sec or 0

    sec = math.max(0, sec)
    min = math.max(0, min)
    hour = math.max(0, hour)
    day = math.max(1, day)
    month = math.max(1, month)
    year = math.max(1970, year)

    local overflow = math.floor(sec / 60)
    min = min + overflow
    sec = math.floor(sec % 60)

    overflow = math.floor(min / 60)
    hour = overflow + hour
    min = math.floor(min % 60)

    overflow = math.floor(hour / 24)
    day = day + overflow
    hour = math.floor(hour % 24)

    local monthDay, isLeap
    while true do
        overflow = math.floor((month - 1) / 12)
        year = year + overflow
        month = math.floor((month - 1) % 12 + 1)
        monthDay = LUtil.MONTH_TABLE[month]
        isLeap = LUtil.IsLeapYear(year)
        if month == 2 and isLeap then
            monthDay = 29
        end
        if day <= monthDay then
            break
        end
        month = month + 1
        day = day - monthDay
    end

    local totalAdd = 0
    local start = 1970
    if year > 2020 then
        start = 2020
        totalAdd = 1577836800
    end

    local dayCnt
    dayCnt = 0
    for i = start, year - 1 do
        isLeap = LUtil.IsLeapYear(i)
        dayCnt = dayCnt + (isLeap and 366 or 365)
    end

    isLeap = LUtil.IsLeapYear(year)
    for i = 1, month - 1 do
        local monthDay = LUtil.MONTH_TABLE[i]
        if i == 2 and isLeap then
            monthDay = 29
        end
        dayCnt = dayCnt + monthDay
    end

    dayCnt = dayCnt + day - 1

    local total = dayCnt * 86400 + hour * 3600 + min * 60 + sec + totalAdd
    return total
end

function LUtil.IsLeapYear(year)
    if year % 400 == 0 then
        return true
    elseif year % 100 == 0 then
        return false
    elseif year % 4 == 0 then
        return true
    end
    return false
end

--特殊所有对应的图片
function LUtil.GetRankImg(rank)
    if rank == 1 then
        return "public_num_1"
    elseif rank == 2 then
        return "public_num_2"
    elseif rank == 3 then
        return "public_num_3"
    end
end

function LUtil.GetFormatCDTime(timespan,format)
    if timespan > 86400 then
        format = format or "%02d%s%02d%s"
        local day = math.floor(timespan / 86400)
        local hour = math.floor(timespan / 3600) % 24
        return string.format(format,day,ccClientText(10304),hour,ccClientText(10305))
    elseif timespan > 3600 then
        format = format or "%02d:%02d:%02d"
        local hour = math.floor(timespan / 3600)
        local min = math.floor(timespan / 60) % 60
        local sec = math.floor(timespan) % 60
        return string.format(format,hour,min,sec)
    else
        format = format or "%02d:%02d:%02d"
        local min = math.floor(timespan / 60)
        local sec = math.floor(timespan) % 60
        return string.format(format,"00",min,sec)
    end
end

function LUtil.CheckIsNextDayWithReset(stampA, stampB, resetHour)
    resetHour = resetHour or 0  -- 默认0点重置
    -- 将时间戳减去重置时间对应的秒数，使重置点成为新的“0点”
    local offset = resetHour * 3600
    local adjustedA = stampA - offset
    local adjustedB = stampB - offset

    local dateA = os.date("*t", adjustedA)
    local dateB = os.date("*t", adjustedB)

    return not (dateA.year == dateB.year and dateA.month == dateB.month and dateA.day == dateB.day)
end
-----------------------------------------------------------------
return LUtil