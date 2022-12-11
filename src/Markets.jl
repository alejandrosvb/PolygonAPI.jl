#= Abstract -> MarketHoliday =#
struct MarketHoliday
    date::Date
    exchange::String
    name::String
    open::Union{TimeDateZone, Nothing}
    close::Union{TimeDateZone, Nothing}
    status::String 
end    

#Fix for optional close and open
#= MarketHoliday -> API =#
function MarketHoliday(d::Dict)
    date = Date(d["date"])
    exchange = d["exchange"]
    name =d["name"]
    open = "open" in keys(d) ? TimeDateZone(d["open"]) : nothing
    close = "close" in keys(d) ? TimeDateZone(d["close"]) : nothing
    status = d["status"]
    return MarketHoliday(date, exchange, name, open, close, status)
end

#= Julia -> API -> Julia =#
function get_market_holidays(c::Credentials)
    r = HTTP.get(join([ENDPOINT(c), "v1", "marketstatus", "upcoming?apiKey=", c.KEY_ID], '/', ""))
    return MarketHoliday.(JSON.parse(String(r.body)))
end

#= Abstract -> MarketStatus =#
struct MarketStatus
    afterHours::Bool
    currencies::Dict
    earlyHours::Bool
    exchanges::Dict
    market::String
    serverTime::TimeDateZone  
end

#= MarketStatus -> API =#
function MarketStatus(d::Dict)
    afterHours = d["afterHours"]
    currencies = d["currencies"]
    earlyHours = d["earlyHours"]
    exchanges = d["exchanges"]
    market = d["market"]
    serverTime = TimeDateZone(d["serverTime"])
    return MarketStatus(afterHours, currencies, earlyHours, exchanges, market, serverTime)
end

#= Julia -> API -> MarketStatus =#
function get_market_status(c::Credentials)
    r = HTTP.get(join([ENDPOINT(c), "v1", "marketstatus", "now?apiKey=", c.KEY_ID], '/', ""))
    return MarketStatus(JSON.parse(String(r.body)))
end

function get_time(timezone::String="America/New_York")
    est_time = TimeZone(timezone)
    time = now(est_time)
    return DateTime(time)
end
