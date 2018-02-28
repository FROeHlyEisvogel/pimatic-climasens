module.exports ={
  title: "pimatic-climate-sensor config schemas"
  ClimateSensor: {
    title: "Climate Sensor config options"
    type: "object"
    extensions: ["xAttributeOptions"]
    properties:
      address:
        description: "Address of the Climate Sensor to connect Format:'xx:xx:xx:xx:xx:xx'"
        type: "string"
        default: ""
      interval:
        description: "Interval until presence lost in s"
        type: "number"
        default: 120
  }
}