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
1.0.1 Improved datamodel to limit amount global variables

ToDo
- request realtime status of current slide to be reflected in Virtual device
- set holiday modes
- start calibration of device
--]]
--set environment variables that can be used to switch logger on/off.
debug = true
dryrun = false
testIndividualSlide = false
slideIdToTest = 1867
slideCommandToTest = "close"

function debuglogger(contentToLog)
    if (debug) then
        fibaro:debug(tostring(contentToLog))
    end
end

-- set userdata for SLIDE api including URL and include sceneID.
userName = ""
password = ""
slideApiUrl = "https://api.goslide.io/api"

--[[ set global userdata variable for storing tokens. for dryrun purposes it's possible to take the output and store here.
Includes refresh_token that is currently not used yet.
--]]
authData = {
    ["access_token"] = "",
    ["token_type"] = "Bearer",
    ["expires_at"] = "2020-03-10 09:48:38",
    ["expires_in"] = "2592000",
    ["refresh_token"] = "",
    ["household_id"] = "15"
}

--[[ set global slides variable for storing slide information, including example data model
--]]
slides = {
    --[[
    ["slide1"] = {
        ["id"] = "1234",
        ["device_name"] = "superslide",
        ["device_id"] = "abc",
        ["zone_id"] = "kitchen",
        ["touch_go"] = false,
        ["device_info"] = {
            ["pos"] = 0.09
        }
    },
    ["slide2"] = {
        ["id"] = "5678",
        ["device_name"] = "superslider",
        ["device_id"] = "def",
        ["zone_id"] = "dining",
        ["touch_go"] = false,
        ["device_info"] = {
            ["pos"] = 0.09
        }
    },
    ["slidesInHousehold"] = 2,
    --]]
}

--[[ In orde to use the SLIDE api, a user needs to be authenticated with the platform. The data used needs to be provisioned
above. 
      --]]
function getToken(refreshHousehold)
    debuglogger("Calling getToken function for access")
    -- setup variables to include in the call - include json encoding
    local requestStr = {email = userName, password = password}
    local requestStringToJSON = json.encode(requestStr)
    debuglogger("RequestStr:" .. requestStringToJSON)
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
                data = requestStringToJSON
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
                -- set a small timer to ensure the data is properly stored and propagated
                if dryrun == false then
                    fibaro:setGlobal("Slidetoken", json.encode(authData))
                else
                    debuglogger("Performing dry-run, not storing tokens")
                end

                debuglogger("Token needed for upcoming request: " .. authData.access_token)
                -- Loop over new values, evaluate if they are stored correctly
                for tokenKey, value in pairs(authData) do
                    debuglogger("Authdata key: " .. tokenKey .. ", stored value: " .. value)
                end

                -- to speed up onboarding in Fibaro we're also getting household information already.
                -- SLIDES will be provisioned in the virtual device so set that up first
                if refreshHousehold then
                    debuglogger("Refresh of household triggered")
                    fibaro:sleep(1000)
                    getHouseholdInfo()
                else
                    debuglogger("Not refreshing household")
                end
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
    decodedGlobalToken = authData
elseif dryrun == false and fibaro:getGlobalValue("Slidetoken") ~= nil and fibaro:getGlobalValue("Slidetoken") ~= "0" then
    fibaro:debug("Requesting global variable to run authentication")
    retrieveToken = fibaro:getGlobalValue("Slidetoken")
    decodedGlobalToken = json.decode(retrieveToken)
else
    fibaro:debug("Warning, no global value set yet for Slidetoken")
end

--[[ This is one of the most important API's, as this API will allow you to set the technical id's of the  slides to use
in other API's. The data is store in a global variable. The data  used here is dependent on the values of the block above:
if dryrun is true it uses local variables from getToken, otherwise it retrieves data from global variables.
      --]]
function getHouseholdInfo()
  if dryrun then
    decodedGlobalToken = authData
    else 
    retrieveToken = fibaro:getGlobalValue("Slidetoken")
    decodedGlobalToken = json.decode(retrieveToken)
    end
    debuglogger("Calling householdinfo for household parameters")
    local selfhttp = net.HTTPClient()
    local endPoint = "/slides/overview"
    local headers = {
        ["content-type"] = "application/json",
        ["X-Requested-With"] = "XMLHttpRequest",
        ["Authorization"] = "Bearer " .. decodedGlobalToken.access_token
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
                    debuglogger(
                        "Looping over slides in api response, loop sequence: " ..
                            slideCount .. " ID found: " .. decodedHouseholdResponse.slides[slideCount].id
                    )

                    dataInHousehold = {
                        ["id"] = decodedHouseholdResponse.slides[slideCount].id,
                        ["device_name"] = decodedHouseholdResponse.slides[slideCount].device_name,
                        ["device_id"] = decodedHouseholdResponse.slides[slideCount].device_id,
                        ["zone_id"] = decodedHouseholdResponse.slides[slideCount].zone_id,
                        ["touch_go"] = decodedHouseholdResponse.slides[slideCount].touch_go,
                        ["device_info"] = decodedHouseholdResponse.slides[slideCount].device_info
                    }

                    -- fill the datastore with relevant data, this includes individual slides and total number of slides.
                    slideNumberID = "slide" .. slideCount
                    slides["slidesInHousehold"] = slideCount
                    slides[slideNumberID] = dataInHousehold
                end

                --[[ store json values in global token, this needs to be set  before using these api's otherwise
                data is not available.--]]
                if dryrun == false then
                    -- store slide data in a global variable - needs to be created first
                    fibaro:setGlobal("Slides", json.encode(slides))
                elseif dryrun and testIndividualSlide then
                    debuglogger("Testing individual slide  in dryrun mode: " .. slideIdToTest)
                    setSlide(slideIdToTest, slideCommandToTest)
                else
                    debuglogger("Performing dry-run, not storing tokens or setting slides")
                end

                --[[ list the amount of slides in the house and list the individual slides --]]
                debuglogger("Number of slides in household: " .. slides["slidesInHousehold"])
                for slideData, value in pairs(slides) do
                    debuglogger("Data to be stored in memory: " .. slideData)
                    debuglogger(value)
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

    local requestStringToJSON = json.encode(requestStr)
    debuglogger("Request send to slide is: " .. requestStringToJSON)
    local headers = {
        ["content-type"] = "application/json",
        ["X-Requested-With"] = "XMLHttpRequest",
        ["Authorization"] = "Bearer " .. decodedGlobalToken.access_token
    }
    local url = slideApiUrl .. endPoint
    debuglogger(url)
    selfhttp:request(
        url,
        {
            options = {
                headers = headers,
                method = "POST",
                data = requestStringToJSON
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
        ["Authorization"] = "Bearer " .. decodedGlobalToken.access_token
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
if dryrun then
    fibaro:debug("Request for dry run received")
    refreshHousehold = true
    getToken(refreshHousehold)
elseif args == nil then
    fibaro:debug("No commands or dry run request received")
elseif args ~= nil and args[1] == "requestNewToken" then
    request = args[1]
    refreshHousehold = args[2]
    fibaro:debug("Request " .. request)
    getToken(refreshHousehold)
elseif args ~= nil and args[1] == "controlSlide" then
    request = args[1]
    slideToCommand = args[2]
    slideCommand = args[3]
    fibaro:debug("Request " .. request)
    debuglogger("slideToCommand " .. slideToCommand)
    debuglogger("slideCommand " .. slideCommand)
    -- Check for existence of a token to be able to make calls
    if (decodedGlobalToken.access_token ~= "" and os.date("%Y-%m-%d %X") < decodedGlobalToken.expires_at) then
        setSlide(slideToCommand, slideCommand)
        fibaro:debug("Token found and not expired, expiry date: " .. authData.expires_at)
    else
        fibaro:debug("No valid token found (not present or expired), triggering function to retrieve a new token")
        fibaro:debug("The action you've intended to execute might have failed, please try again after token refresh")
        refreshHousehold = true
        getToken(refreshHousehold)
    end
elseif args ~= nil and args[1] == "refreshHousehold" then
    request = args[1]
    print("Request " .. request)
    -- Check for existence of a token to be able to make calls
    if (decodedGlobalToken.access_token ~= "" and os.date("%Y-%m-%d %X") < decodedGlobalToken.expires_at) then
        getHouseholdInfo()
    else
        fibaro:debug(
            "No valid token found (not present or expired), triggering function to retrieve a new token and refresh household"
        )
        refreshHousehold = true
        getToken(refreshHousehold)
    end
else
    fibaro:debug("Unknown error occurred, please check configuration syntax and virtual device configuration")
end
