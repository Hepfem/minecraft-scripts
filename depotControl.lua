local RED = 5
local GREEN = 1

local modem = peripheral.wrap("back")
local controller = peripheral.wrap("bottom")
local receiver = peripheral.wrap("top")
local ticketMachine = peripheral.wrap("left")

local tracks = receiver.getSignalNames()
local destinations = {"test","spawn", "village", "daka", "depå"}
local requests = {}

function setupTicketMachine()
    ticketMachine.setManualPrintingAllowed(false)
    ticketMachine.setManualSelectionAllowed(false)

    for i = 1, #destinations do
        ticketMachine.setDestination(i, tostring(destinations[i]))
    end
end

function find(table, value)
    for k,v in pairs(table) do
        if v == value then
            return k
        end
    end
end

-- Ensure all tracks are set to hold
function lockAllTracks()
    for i = 1, #tracks do
        controller.setAspect(tracks[i], RED)
    end
end

function findOccupiedTrack()
    for i = 1, #tracks do
        if receiver.getAspect(tracks[i]) == RED then
            return tracks[i]
        end      
    end

    return nil
end

function setDestination(destination)
    print("Setting train destination to "..destination)

    local slot = find(destinations, destination)

    if slot == nil then
        print("Unknown destination, discarding request")
        return false
    end

    ticketMachine.setSelectedTicket(slot)
    ticketMachine.printTicket()

    return true
end

function sendTrain(trackToRelease)
    print("Waiting for exit track to empty...")

    while receiver.getAspect("exitTrack") ~= GREEN do
        os.sleep(1)
    end

    print("Releasing "..trackToRelease)

    controller.setAspect(trackToRelease, GREEN)
    os.sleep(2)

    print("Locking "..trackToRelease)
    controller.setAspect(trackToRelease, RED)
end

function mainLoop()
    while true do
        
        if #requests > 0 then

            local request = requests[1]

            print("Processing train request for destination "..request[3])

            local trackToRelease = findOccupiedTrack()

            if trackToRelease == nil then
                print("No trains in depot, discarding request")
                modem.transmit(request[2], request[1],
                    "No trains in depot, please try again later")
            else
                local result = setDestination(request[3])

                if result == true then
                    sendTrain(trackToRelease)
                    modem.transmit(request[2], request[1],
                        "Train departed from depot ("..math.ceil(request[4]).." blocks away)")
                else
                    modem.transmit(request[2], request[1],
                        "Unknown station, discarding request")
                end
            end

            table.remove(requests, 1)
        end

        os.sleep(0.2)
    end
end

function listenToRequests()
    modem.open(1)

    print("Waiting for train requests...")

    while true do
        local event, modemSide, senderChannel,
            replyChannel, message,
            senderDistance = os.pullEvent("modem_message")
        print("Train request received for destination "..message..", adding it to the processing que")
        
        local newRequest = {senderChannel, replyChannel, message, senderDistance}
        table.insert(requests, newRequest)
    end
end

-- Start
lockAllTracks()
setupTicketMachine()

parallel.waitForAll(mainLoop, listenToRequests)