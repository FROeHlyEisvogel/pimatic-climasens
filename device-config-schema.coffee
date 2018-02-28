module.exports ={
  title: "pimatic-ClimaSens config schemas"
  ClimaSens: {
    title: "ClimaSens config options"
    type: "object"
    extensions: ["xAttributeOptions"]
    properties:
      address:
        description: "Address of the ClimaSens to connect Format:'xx:xx:xx:xx:xx:xx'"
        type: "string"
        default: ""
      interval:
        description: "Interval until presence lost in s"
        type: "number"
        default: 120
  }
}