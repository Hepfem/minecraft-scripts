local RED = 5
local GREEN = 1

local settingsLoaded = settings.load(".settings")

if not settingsLoaded or settings.get("platformMonitor.firstTimeSetupComplete", false) ~= true then
    print("Welcome to Platform Monitor 1.0. Please complete the first time setup.")

    print("Enter modem side (left, top, right, bottom, back)")
    write("> ")
    modemSide = read()

    print("Enter digital receiver side (left, top, right, bottom, back)")
    write("> ")
    receiverSide = read()

    print("Enter station name")
    write("> ")
    stationName = read()

    print("First time setup completed!")

    settings.set("platformMonitor.modemSide", modemSide)
    settings.set("platformMonitor.receiverSide", receiverSide)
    settings.set("platformMonitor.stationNamee", stationName)
    settings.set("platformMonitor.firstTimeSetupComplete", true)
    settings.save(".settings")
else
    modemSide = settings.get("platformMonitor.modemSide")
    receiverSide = settings.get("platformMonitor.receiverSide")
    stationName = settings.get("platformMonitor.stationNamee")
end

local modem = peripheral.wrap(modemSide)
local receiver = peripheral.wrap(receiverSide)
local station = stationName

print("Beginning platform track monitoring.")
modem.open(2)

function waitForRequestedTrain()
    print("Waiting for requested train to arrive...")

    while receiver.getAspect("platform") ~= RED do
        os.sleep(10)
    end

    print("Train arrived. Resuming platform track monitoring.")
end

function requestTrain()
    print("Requesting one from depot...")

    modem.transmit(1,2,station)

    local event, modemSide, senderChannel,
        replyChannel, message,
        senderDistance = os.pullEvent("modem_message")

    print(message)

    waitForRequestedTrain()
end

while true do
    if receiver.getAspect("platform") == GREEN then
        print("No train at platform, rechecking in 10 seconds.")
        os.sleep(10)

        if receiver.getAspect("platform") == GREEN then
            write("Still no train found. ")
            requestTrain()
        else
            print("Train found. Resuming platform track monitoring.")
        end
    end

    os.sleep(1)
end