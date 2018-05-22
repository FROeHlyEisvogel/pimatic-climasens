module.exports ={
<<<<<<< HEAD
  title: "pimatic-ClimaSens config schemas"
=======
  title: "pimatic-climasens config schemas"
>>>>>>> 4995ef4bb2b6fec5178d9fd946c74c37a79c7974
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