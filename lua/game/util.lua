local util = {}

local _hour8s = 8*3600
local _hour8ms = _hour8s*1000

function util.second2day(sec)
    return (sec+_hour8s)//86400
end
function util.msecond2day(msec)
    return (msec+_hour8ms)//86400000
end

function util.daybase(sec)
    return util.second2day(sec)*86400-_hour8s
end

function util.week(sec)
    local w = os.date("*t", sec).wday-1
    return w==0 and 7 or w
end

function util.weekbase(sec)
    local tm = os.date("*t", sec)
    local week = tm.wday-1
    if week==0 then
        week=7
    end
    sec = sec - (week-1)*24*3600
    return util.daybase(sec)
end

function util.changeweek(last, now)
    local w1 = util.weekbase(last)
    local w2 = util.weekbase(now)
    return w2~=w1, w2
end

function util.strftime(sec)
    local tm = os.date("*t", sec)
    return sformat("%04d%02d%02d-%02d:%02d:%02d", 
        tm.year, tm.month, tm.day, tm.hour, tm.min, tm.sec)
end
function util.lastdaybase(sec)
    sec = sec-24*3600
    return util.daybase(sec)
end

function util.lastweekbase(sec)
    local tm = os.date("*t", sec)
    local week = tm.wday-1
    if week==0 then
        week=7
    end
    sec = sec - (week+6)*24*3600
    return sec
end

function util.lastmonthbase(sec)
    local tm = os.date("*t", sec)
    if tm.month == 1 then
        tm.month = 12
        tm.year = tm.year-1
    else
        tm.month = tm.month-1
    end
    tm.day=1
    tm.hour=0
    tm.min=0
    tm.sec=0
    return os.time(tm)
end

return util
