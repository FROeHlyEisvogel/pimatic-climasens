module.exports = {
  title: "pimatic-climasens config schemas"
  ClimaSens: {
    title: "ClimaSens config options"
    type: "object"
    extensions: ["xAttributeOptions"]
    properties:
      address:
        description: "Address of the ClimaSens to connect Format:'XX:XX:XX:XX:XX:XX'"
        type: "string"
        default: ""
      light:
        description: "Activate light"
        type: "boolean"
        default: "false"
      temperature:
        description: "Activate temperature"
        type: "boolean"
        default: "false"
      humidity:
        description: "Activate humidity"
        type: "boolean"
        default: "false"
      pressure:
        description: "Activate pressure"
        type: "boolean"
        default: "false"
      battery:
        description: "Activate battery"
        type: "boolean"
        default: "false"
      contact:
        description: "Activate contact"
        type: "boolean"
        default: "false"
      presence:
        description: "Activate presence"
        type: "boolean"
        default: "false"
      interval:
        description: "Interval until presence lost in s"
        type: "number"
        default: 120
      button:
        description: "Activate button"
        type: "boolean"
        default: false
  }
}