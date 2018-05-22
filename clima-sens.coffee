module.exports = (env) ->

  class ClimateSensorPlugin extends env.plugins.Plugin
    
    init: (app, @framework, @config) =>
      @debug = @config.debug
      @bluetoothInterface = @config.bluetoothInterface or 'hci0'
      @devices = []
      @discoverMode = false
      @discoveredPeripherals = []
      
      @noble = require 'noble'
      
      # Reset Bluetooth device
      exec = require('child_process').exec
      exec 'sudo hciconfig '+ @bluetoothInterface + ' reset'
      
      #Set Bluetooth Adapter
      switch @bluetoothInterface
        when 'hci0' then process.env.NOBLE_HCI_DEVICE_ID = 0
        when 'hci1' then process.env.NOBLE_HCI_DEVICE_ID = 1
        when 'hci2' then process.env.NOBLE_HCI_DEVICE_ID = 2
        when 'hci3' then process.env.NOBLE_HCI_DEVICE_ID = 3
        else process.env.NOBLE_HCI_DEVICE_ID = 0
      
      # Report all bluetooth events
      process.env.NOBLE_REPORT_ALL_HCI_EVENTS = 1
      
      deviceConfigDef = require('./device-config-schema')
      
<<<<<<< HEAD
      @framework.deviceManager.registerDeviceClass('ClimateSensor', {
        configDef: deviceConfigDef.ClimateSensor,
        createCallback: (config, lastState) =>
          device = new ClimateSensor(config, @, lastState)
=======
      @framework.deviceManager.registerDeviceClass('ClimaSens', {
        configDef: deviceConfigDef.ClimaSens,
        createCallback: (config, lastState) =>
          device = new ClimaSens(config, @, lastState)
>>>>>>> 4995ef4bb2b6fec5178d9fd946c74c37a79c7974
          @addToScan config.address, device
          return device
      })

      @framework.deviceManager.on 'discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-climate-sensor', 'Scanning for sensors'
        @discoverMode = true
        
        @noble.on 'discover', (peripheral) =>
          if @discoverMode is true
            if peripheral.address.toUpperCase() not in @discoveredPeripherals
              if not @devices[peripheral.address.toUpperCase()]
<<<<<<< HEAD
              #if peripheral.address.toUpperCase() not in @devices
=======
>>>>>>> 4995ef4bb2b6fec5178d9fd946c74c37a79c7974
                @discoveredPeripherals.push peripheral.address.toUpperCase()

                env.logger.debug 'Sensor %s found', peripheral.address.toUpperCase()
                config = {
<<<<<<< HEAD
                  class: 'ClimateSensor',
=======
                  class: 'ClimaSens',
>>>>>>> 4995ef4bb2b6fec5178d9fd946c74c37a79c7974
                  name: peripheral.address.toUpperCase(),
                  address: peripheral.address.toUpperCase()
                }
                @framework.deviceManager.discoveredDevice(
<<<<<<< HEAD
                  'pimatic-climate-sensor', peripheral.advertisement.localName + ' [' + peripheral.address.toUpperCase() + '] -> RSSI: ' + peripheral.rssi + 'dBm', config
=======
                  'pimatic-ClimaSens', peripheral.advertisement.localName + ' [' + peripheral.address.toUpperCase() + '] -> RSSI: ' + peripheral.rssi + 'dBm', config
>>>>>>> 4995ef4bb2b6fec5178d9fd946c74c37a79c7974
                )
          else return

        setTimeout =>
          @discoverMode = false
        , 20000
      
      @noble.on 'stateChange', (state) =>
        if state == 'poweredOn'
          @noble.startScanning([], true)
        else
          @noble.stopScanning()
    
    addToScan: (address, device) =>
      env.logger.debug 'Adding device %s', address
      @devices[address] = device

    removeFromScan: (address) =>
      env.logger.info 'Removing device %s', address
      if @devices[address]
        delete @devices[address]
        env.logger.info address, 'removed'

<<<<<<< HEAD
  class ClimateSensor extends env.devices.Device
=======
  class ClimaSens extends env.devices.Device
>>>>>>> 4995ef4bb2b6fec5178d9fd946c74c37a79c7974
    attributes:
      light:
        description: 'The measured brightness'
        type: 'number'
        unit: 'lx'
        acronym: ' Light:'
      temperature:
        description: 'The measured temperature'
        type: 'number'
        unit: '°C'
        acronym: ' Temp:'
      humidity:
        description: 'The measured moisture level'
        type: 'number'
        unit: '%'
        acronym: ' Humidity:'
      pressure:
        description: 'Relative air pressure'
        type: 'number'
        unit: 'hPa'
        acronym: ' Pressure:'
      battery:
        description: 'Battery status'
        type: 'number'
        unit: 'V'
        acronym: ' Battery:'
      contact:
        description: 'Contact status'
        type: 'boolean'
        lables: ['closed', 'open']
        acronym: ' Contact:'
      presence:
        description: 'Presence of the device'
        type: 'boolean'
        lables: ['present', 'absent']

    constructor: (config, @plugin, lastState) ->
      if !@config || Object.keys(@config).length == 0
        @config = config
      if !@plugin
        @plugin = plugin
      
      @id = @config.id
      @name = @config.name
      @address = @config.address
      @interval = @config.interval
      
      @_light = lastState?.light?.value or 0
      @_temperature = lastState?.temperature?.value or 0.0
      @_humidity = lastState?.humidity?.value or 0.0
      @_pressure = lastState?.pressure?.value or 0.0
      @_battery = lastState?.battery?.value or 0.0
      @_contact = lastState?.contact?.value or false
      
      @_presence = lastState?.presence?.value or false
      @_presenceTimeout = setTimeout @_resetPresence, @interval * 1000
      
      @plugin.noble.on 'discover', (peripheral) =>
        if peripheral.address.toUpperCase() == @address.toUpperCase()
          @_setPresence true
          manufacturerData = peripheral.advertisement.manufacturerData
          env.logger.debug manufacturerData
          @parseData manufacturerData
      
      super()

    _resetPresence: =>
      @_setPresence false
    
    _setPresence: (value) ->
      clearTimeout @_resetPresenceTimeout
      if @_presence is true
        @_resetPresenceTimeout = setTimeout @_resetPresence, @interval * 1000
      if @_presence is value then return
      @_presence = value
      @emit 'presence', value

    parseData: (manufacturerData) ->
      @_battery = ((manufacturerData[2] << 8) | manufacturerData[3]) / 1000
      @emit 'battery', @_battery
      
      @_light = ((manufacturerData[6] << 8) | manufacturerData[7])
      @emit 'light', @_light
      
      @_temperature = ((manufacturerData[8] << 8) | manufacturerData[9]) / 100
      if @_temperature > 327.68 then @_temperature = -655.36 + @_temperature
      @emit 'temperature', @_temperature
      
      @_humidity = ((manufacturerData[10] << 8) | manufacturerData[11]) / 100
      @emit 'humidity', @_humidity
      
      @_pressure = ((manufacturerData[12] << 8) | manufacturerData[13]) / 10
      @emit 'pressure', @_pressure
      
      @_contact = manufacturerData[14]
      @emit 'contact', @_contact
      
      env.logger.debug 'temperature: %s °C , Light: %s lux , humidity: %s% , battery: %sV', @_temperature, @_light, @_humidity, @_battery

    
    
    destroy: ->
      @plugin.removeFromScan @address
      clearTimeout(@_resetPresenceTimeout)
      super()

    getTemperature: -> Promise.resolve @_temperature
    getLight: -> Promise.resolve @_light
    getHumidity: -> Promise.resolve @_humidity
    getPressure: -> Promise.resolve @_pressure
    getBattery: -> Promise.resolve @_battery
    getContact: -> Promise.resolve @_contact
    getPresence: -> Promise.resolve @_presence

  
<<<<<<< HEAD
  env.devices.ClimateSensor = ClimateSensor
=======
  env.devices.ClimaSens = ClimaSens
>>>>>>> 4995ef4bb2b6fec5178d9fd946c74c37a79c7974
  
  return new ClimateSensorPlugin
