local modem = peripheral.wrap("back")
local station = "test"

modem.open(2)

while true do
    print("Would you like to request a train? (y/n)")
    input = read()

    if input == "y" then
        print("Requesting train...")
        modem.transmit(1,2,station)

        local event, modemSide, senderChannel,
            replyChannel, message,
            senderDistance = os.pullEvent("modem_message")

        print(message)
    end
end