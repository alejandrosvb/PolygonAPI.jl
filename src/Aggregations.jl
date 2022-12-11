using HTTP, JSON, UUIDs

abstract type AggTimeSpan end

struct minute <: AggTimeSpan end
struct hour <: AggTimeSpan end 
struct day <: AggTimeSpan end
struct week <: AggTimeSpan end
struct month <: AggTimeSpan end
struct quarter <: AggTimeSpan end
struct year <: AggTimeSpan end 

AggTimeSpan(::Type{minute}, x::String="minute") = x
AggTimeSpan(::Type{hour}, x::String="hour") = x
AggTimeSpan(::Type{day}, x::String="day") = x
AggTimeSpan(::Type{week}, x::String="week") = x
AggTimeSpan(::Type{month}, x::String="month") = x
AggTimeSpan(::Type{quarter}, x::String="quarter") = x
AggTimeSpan(::Type{year}, x::String="year") = x

# DATE_FIN = get_time()
# MAX_DATE = Dates.Year(10)
# DATE_INI = DATE_FIN - MAX_DATE
# DATE_FIN_DEF = Dates.format(DATE_FIN, "yyyy-mm-dd")
# DATE_INI_DEF = Dates.format(DATE_INI, "yyyy-mm-dd")
# DATE_INI_DEF = Dates.format(DATE_INI)
# d = unix2datetime(1626926400000//1000)
# typeof(d)
# Dates.format(d, "yyyy-mm-dd")


# typeof(DATE_FIN)

struct Bar
    ticker::Union{String, Nothing}
    close::Float64
    high::Float64
    low::Float64
    number::Union{Float64, Nothing}
    open::Float64
    timestamp::DateTime
    volume::Number
    weighted_volume::Union{Float64, Nothing}
    otc::Bool
end

function Bar(d::Dict{String, Any})
    ticker = "T" in keys(d) ? d["T"] : nothing
    close = d["c"]
    high = d["h"]
    low = d["l"]
    number = "n" in keys(d) ? d["n"] : nothing
    open = d["o"]
    timestamp = unix2datetime(d["t"]//1000)
    volume = d["v"]
    weighted_volume = "vw" in keys(d) ? d["vw"] : nothing
    otc = "otc" in keys(d) ? true : false
    return Bar(ticker, close, high, low, number, open, timestamp, volume, weighted_volume, otc)
end

struct Agg
    adjusted::Bool
    queryCount::Int
    request_id::Union{String, Nothing}
    results::Vector{Bar}
    resultsCount::Int
    status::String
    ticker::Union{String, Nothing}
end

function Agg(d::Dict{String, Any})
    adjusted = d["adjusted"]
    queryCount = d["queryCount"]
    request_id = "request_id" in keys(d) ? d["request_id"] : nothing
    results = Bar.(d["results"])
    resultsCount = d["resultsCount"]
    status = d["status"]
    ticker = "ticker" in keys(d) ? d["ticker"] : nothing
    return Agg(adjusted, queryCount, request_id, results, resultsCount, status, ticker)
end


function get_agg(
    c::             Credentials, 
    ticker::        String, 
    multiplier::    Int, 
    timespan::      Type{T} where {T<:AggTimeSpan}, 
    from::          String, 
    to::            String;
    adjusted::      Union{Bool, Nothing} = true,
    sorted::        Union{String, Nothing} = "desc",
    limit::         Union{Int, Nothing} = 5000
    )

    query = Dict()
    query["adjusted"] = adjusted === nothing ? nothing : string(adjusted)
    query["sorted"] = sorted === nothing ? nothing : string(sorted)
    query["limit"] = adjusted === nothing ? nothing : string(limit)

    timespan = AggTimeSpan(timespan)

    r = HTTP.get(join([ENDPOINT(c), "v2","aggs", "ticker", HTTP.URIs.escapeuri(string(ticker)), "range", 
    HTTP.URIs.escapeuri(string(multiplier)), HTTP.URIs.escapeuri(timespan), HTTP.URIs.escapeuri(string(from)),
    HTTP.URIs.escapeuri(string(to))], '/'), header = HEADER(c), query = query)
    return Agg(JSON.parse(String(r.body)))
end

function get_daily_aggs(
    c::             Credentials,
    date::          String;
    adjusted::      Union{Bool, String} = true,
    include_otc::   Union{Bool, String} = false
    )

    query = Dict()
    query["adjusted"] = adjusted === nothing ? nothing : string(adjusted)
    query["include_otc"] = include_otc === nothing ? nothing : string(include_otc)
    query["apiKey"] = c.KEY_ID

    r = HTTP.get(join([ENDPOINT(c), "v2","aggs", "grouped", "locale", "us", "market", "stocks", HTTP.URIs.escapeuri(date)], '/'), query = query)
    return Agg(JSON.parse(String(r.body)))
end

struct DailyBar
    afterHours::Float64
    close::Float64
    from::DateTime
    high::Float64
    low::Float64
    open::Float64
    preMarket::Float64
    status::String
    symbol::String
    volume::Int
    otc::Bool
end

function DailyBar(d::Dict)
    afterHours = d["afterHours"]
    close = d["close"]
    from = DateTime(d["from"])
    high = d["high"]
    low = d["low"]
    open = d["open"]
    preMarket = d["preMarket"]
    status = d["status"]
    symbol = d["symbol"]
    volume = d["volume"]
    otc = "otc" in keys(d) ? true : false
    return DailyBar(afterHours, close, from, high, low, open, preMarket, status, symbol, volume, otc)
end

function get_daily_bar(
    c::             Credentials,
    date::          String,
    stocksTicker::  String;
    adjusted::   Union{Bool, String} = true
    )

    query = Dict()
    query["adjusted"] = adjusted === nothing ? nothing : string(adjusted)
    query["apiKey"] = c.KEY_ID

    r = HTTP.get(join([ENDPOINT(c), "v1", "open-close", HTTP.URIs.escapeuri(stocksTicker), HTTP.URIs.escapeuri(date)], '/'), query = query)
    return DailyBar(JSON.parse(String(r.body)))
end

function get_previous_agg(
    c::             Credentials,
    stocksTicker:: String;
    adjusted::      Union{Bool, String} = true,
    )

    query = Dict()
    query["adjusted"] = adjusted === nothing ? nothing : string(adjusted)
    query["apiKey"] = c.KEY_ID

    r = HTTP.get(join([ENDPOINT(c), "v2","aggs", "ticker", HTTP.URIs.escapeuri(stocksTicker) , "prev"], '/'), query = query)
    return Agg(JSON.parse(String(r.body)))
end


# function get_stocks_info()
#     response = get_response(HTTP.request("GET", "https://api.polygon.io/v3/reference/tickers?type=CS&market=stocks&active=true&sort=ticker&order=asc&limit=1000&apiKey=Yu5Fm1NoakFcAQ5e7L_ghNIGOiqjq632"))
#     results = response["results"]
#     while "next_url" in keys(response)
#         next_url = response["next_url"]
#         response = get_response(HTTP.request("GET", next_url*KEY_URL))
#         results_next = response["results"]
#         append!(results, results_next)
#     end
#     return results
# end



# function get_snapshot(ticker, multiplier, timespan, date_ini, date_end)
#     try
#         response = get_response(HTTP.request("GET", "https://api.polygon.io/v2/aggs/ticker/$ticker/range/$multiplier/$timespan/$date_ini/$date_end))
#         results = response["results"]
#         println("The ticker $ticker has been requested successfuly")
#         snap = [Dict("ticker" => ticker, "o" => day["o"], "c" => day["c"], "l" => day["l"], "h" => day["h"], "v" => day["v"], "t" => day["t"]) for day in results]
#         return snap
#     catch e
#         println("Error $e found. Ignoring ticker $ticker...")
#         return "Failed"
#     end
# end
