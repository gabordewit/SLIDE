--[[
--[[
%% properties
%% events
%% globals
--]]
--[[ 
SLIDE Api
Author: Gabor de Wit
Github referece: https://github.com/gabordewit/SLIDE

Versions
1.0 Initial release

ToDo
- request realtime status of current slide to be reflected in Virtual device
- set holiday modes
- start calibration of device
--]]
--set environment variables that can be used to switch logger on/off.
debug = true
dryrun = true
testIndividualSlide = true
slideIdToTest = 1867
slideCommandToTest = "close"

function debuglogger(contentToLog)
    if (debug) then
        fibaro:debug(tostring(contentToLog))
    end
end

-- set userdata for SLIDE api including URL.
userName = ""
password = ""
slideApiUrl = "https://api.goslide.io/api"

-- set global userdata variable for storing tokens. for dryrun purposes it's possible to take the output and store here.
authData = {
    ["access_token"] = "",
    ["token_type"] = "Bearer",
    ["expires_at"] = "2020-03-10 09:48:38",
    ["expires_in"] = "2592000",
    ["refresh_token"] = "",
    ["household_id"] = "15"
}

-- global variable to set amount of slides
numberOfSlides = 0

-- set global householdata variable for storing slide information, including example data model
slides = {}

--[[ In orde to use the SLIDE api, a user needs to be authenticated with the platform. The data used needs to be provisioned
above. 
      --]]
function getToken()
    debuglogger("Calling getToken function for access")
    -- setup variables to include in the call - include json encoding
    local requestStr = {email = userName, password = password}
    local requestTringToJSON = json.encode(requestStr)
    debuglogger("RequestStr:" .. requestTringToJSON)
    local selfhttp = net.HTTPClient()
    local endPoint = "/auth/login"
    local headers = {
        ["content-type"] = "application/json",
        ["X-Requested-With"] = "XMLHttpRequest"
    }
    local url = slideApiUrl .. endPoint
    debuglogger(url)
    -- The actual request
    selfhttp:request(
        url,
        {
            options = {
                headers = headers,
                method = "POST",
                data = requestTringToJSON
            },
            success = function(resp)
                -- Check for response coming from API
                debuglogger("Got a response: " .. resp.data)
                decodedTokenResponse = json.decode(resp.data)

                -- Store retrieved JSON response in a map
                authData.access_token = decodedTokenResponse.access_token
                authData.token_type = decodedTokenResponse.token_type
                authData.expires_at = decodedTokenResponse.expires_at
                authData.expires_in = decodedTokenResponse.expires_in
                authData.household_id = decodedTokenResponse.household_id

                -- store json value in global token (if this is not a dryrun)
                if dryrun == false then
                    fibaro:setGlobal("Slidetoken", json.encode(authData))
                else
                    debuglogger("Performing dry-run, not storing tokense")
                end
                debuglogger("Token needed for upcoming request: " .. decodedGlobal.access_token)
                -- Loop over new values, evaluate if they are stored correctly
                for tokenKey, value in pairs(authData) do
                    debuglogger("Authdata key: " .. tokenKey .. ", stored value: " .. value)
                end
                -- to speed up onboarding in Fibaro we're also getting household information already.
                -- SLIDES will be provisioned in the virtual device so set that up first
                getHouseholdInfo()
            end,
            error = function(err)
                -- response = json.decode(err)
                fibaro:debug("error: " .. err)
            end
        }
    )
end

-- decoded global value for slidetoken
if dryrun then 
    fibaro:debug("Not requesting global variable due to dryrun")
    decodedGlobal = authData
else decodedGlobal = json.decode(fibaro:getGlobalValue("Slidetoken"))
end

--[[ This is one of the most important API's, as this API will allow you to set the technical id's of the  slides to use
in other API's. The data is store in a global variable.
      --]]
function getHouseholdInfo()
    debuglogger("Calling householdinfo for household paramters")
    local selfhttp = net.HTTPClient()
    local endPoint = "/slides/overview"
    local headers = {
        ["content-type"] = "application/json",
        ["X-Requested-With"] = "XMLHttpRequest",
        ["Authorization"] = "Bearer " .. decodedGlobal.access_token
    }
    local url = slideApiUrl .. endPoint
    debuglogger(url)
    selfhttp:request(
        url,
        {
            options = {
                headers = headers,
                method = "GET"
            },
            success = function(resp)
                debuglogger("Response on household call: " .. resp.data)
                decodedHouseholdResponse = json.decode(resp.data)

                for slideCount = 1, #decodedHouseholdResponse.slides do
                    debuglogger("Looping over slides in household, loop sequence: " .. slideCount .. " ID found: " .. decodedHouseholdResponse.slides[slideCount].id)

                    dataInHousehold = {
                        ["id"] = decodedHouseholdResponse.slides[slideCount].id,
                        ["device_name"] = decodedHouseholdResponse.slides[slideCount].device_name,
                        ["device_id"] = decodedHouseholdResponse.slides[slideCount].device_id,
                        ["zone_id"] = decodedHouseholdResponse.slides[slideCount].zone_id
                    }

                    -- setcounter on slide identifier
                    slideNumberID = "slide" .. slideCount
                    numberOfSlides = slideCount

                    -- merge the slide data to it's own ID
                    slides[slideNumberID] = dataInHousehold
                end

                -- store json values in global token, thhis needs to be set  before using these api's otherwise
                -- data is not available.
                if dryrun == false then
                    -- store slide data in a global variable - needs to be created first
                    fibaro:setGlobal("Slides", json.encode(slides))
                    -- store number of slides in global variable - needs to be created first
                    fibaro:setGlobal("Slidehousehold", numberOfSlides)
                elseif dryrun and testIndividualSlide then
                    debuglogger("Testing individual slide  in dryrun mode: " .. slideIdToTest)
                    setSlide(slideIdToTest, slideCommandToTest)
                else
                    debuglogger("Performing dry-run, not storing tokens or setting slides")
                end

                -- list the amount of slides in the house and list the individual slides
                debuglogger("Number of slides in household: " .. numberOfSlides)
                for slideNumber, value in pairs(slides) do
                    debuglogger("Slide ID to be stored in memory: " .. slideNumber)
                end
            end,
            error = function(err)
                --response = json.decode(err)
                fibaro:debug("error: " .. err)
            end
        }
    )
end

--[[ In orde to set an individual SLIDE , we can send a request to an individual slide
the api already supports the setting of anything other than close and open but this is open for VFID to use.
      --]]
function setSlide(slideId, command)
    debuglogger("Calling setslide for specific slide")
    local selfhttp = net.HTTPClient()
    local endPoint = "/slide/" .. slideId .. "/position"
    local requestStr = {pos = 1}
    if command == "open" then
        requestStr = {pos = 0}
    elseif command == "close" then
        requestStr = {pos = 1}
    else
        requestStr = {pos = command}
    end

    local requestTringToJSON = json.encode(requestStr)
    debuglogger("Request send to slide is: " .. requestTringToJSON)
    local headers = {
        ["content-type"] = "application/json",
        ["X-Requested-With"] = "XMLHttpRequest",
        ["Authorization"] = "Bearer " .. decodedGlobal.access_token
    }
    local url = slideApiUrl .. endPoint
    debuglogger(url)
    selfhttp:request(
        url,
        {
            options = {
                headers = headers,
                method = "POST",
                data = requestTringToJSON
            },
            success = function(resp)
                debuglogger("Response on set slide call: " .. resp.data)
                decodedSlideResponse = json.decode(resp.data)
            end,
            error = function(err)
                -- response = json.decode(err)
                fibaro:debug("error: " .. err)
            end
        }
    )
end

--[[ If needed the information of an individual slide can be called (e.g. to see if the slide is open etc. For use in
future operations.
      --]]
function getSlideInfo(slideId)
    debuglogger("Calling slide info for slide parameters")
    local selfhttp = net.HTTPClient()
    local endPoint = "/slides/" .. slideId
    local headers = {
        ["content-type"] = "application/json",
        ["X-Requested-With"] = "XMLHttpRequest",
        ["Authorization"] = "Bearer " .. decodedGlobal.access_token
    }
    local url = slideApiUrl .. endPoint
    debuglogger(url)
    selfhttp:request(
        url,
        {
            options = {
                headers = headers,
                method = "GET"
            },
            success = function(resp)
                debuglogger("Success on slide call: " .. resp.data)
                decodedSlideResponse = json.decode(resp.data)
                -- if slideId == 1867 then
                -- setSlide(slideId, "close")
                -- end
            end,
            error = function(err)
                -- response = json.decode(err)
                fibaro:debug("error: " .. err)
            end
        }
    )
end

--[[ The scene uses a input command mechanism as if it was an API. Using Fibaro's method of allowing virtual devices to
call a scene with input parameters, the scene van be triggered from virtual devices.
      --]]
args = fibaro:args()
if args ~= nil and args[1] == "requestNewToken" then
    request = args[1]
    print("request " .. request)
    getToken()
elseif args ~= nil and args[1] == "controlSlide" then
    request = args[1]
    slideToCommand = args[2]
    slideCommand = args[3]
    print("request " .. request)
    debuglogger("slideToCommand " .. slideToCommand)
    debuglogger("slideCommand " .. slideCommand)
    -- Check for existence of a token to be able to make calls
    if (decodedGlobal.access_token ~= "" and os.date("%Y-%m-%d %X") < decodedGlobal.expires_at) then
        --setSlide(slideToCommand, slideCommand)
        print("Token found and not expired, expiry date: " .. authData.expires_at)
    else
        -- getToken()
        print("No valid token found (not present or expired), triggering function to retrieve a new token")
    end
elseif dryrun then
    getToken()
else
    print("no commands or dry run request received")
end
