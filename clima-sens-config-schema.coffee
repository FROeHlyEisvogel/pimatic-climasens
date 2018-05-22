module.exports = {
<<<<<<< HEAD
  title: "Pimatic-ClimaSens"
=======
  title: "pimatic-climasens"
>>>>>>> 4995ef4bb2b6fec5178d9fd946c74c37a79c7974
  type: "object"
  properties: {
    debug:
      description: "Debug mode. Writes debug messages to the Pimatic log, if set to true."
      type: "boolean"
      default: false
    bluetoothInterface:
      description: "The bluetooth interface"
      type: "string"
      default: "hci0"
  }
}
