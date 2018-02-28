module.exports = {
  title: "ClimateSensor"
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
