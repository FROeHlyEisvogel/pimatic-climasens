module.exports = (env) ->
  Promise = env.require 'bluebird'
  events = require 'events'
  EventEmitter = require 'events'

  class ClimaSensPlugin extends env.plugins.Plugin
    
    init: (app, @framework, @config) =>
      @debug = @config.debug
      @bluetoothInterface = @config.bluetoothInterface or 'hci0'
      @devices = []
      @discoverMode = false
      @discoveredPeripherals = []
  
      exec = require('child_process').exec
      spawn = require('child_process').spawn

      # reset Bluetooth device
      exec 'sudo hciconfig ' + @bluetoothInterface + ' reset'
      
      setTimeout =>
        # start scanning after delay for device reset
        env.logger.debug 'Start scanner'
        @hcitool_child = spawn('sudo', ['hcitool', '-i', @bluetoothInterface, 'lescan', '--passive', '--duplicates'])
      , 10
      
      env.logger.debug 'Start scanning'
      @hcidump_child = spawn('sudo', ['hcidump', '-R', '-i', @bluetoothInterface])
      
      @BLEreport = new EventEmitter
      
      @hcidump_child.stdout.on 'data', (data) =>
        rawData = data.toString('utf8')
        rawData = rawData.replace(/\n|\r/g, "")  # Remove all new lines
        rawData = rawData.replace(/ /g, "")      # Remove all spaces
        rawData = rawData.replace(/>/g, "")      # Remove symbol
        rawCode = rawData.match(/.{1,2}/g)       # Convert to hex
        rawCodeInt = rawCode.map((num) ->
          parseInt num, 16
        )
        
        BLEdata =
          address: rawCode[12]+":"+rawCode[11]+":"+rawCode[10]+":"+rawCode[9]+":"+rawCode[8]+":"+rawCode[7]
          dataLength: rawCodeInt[17]
          DataFlag: rawCodeInt[18]
          companyID: (rawCodeInt[19] | (rawCodeInt[20] << 8))
          manufacturingData: rawCodeInt.slice(19,(19+rawCodeInt[17]))
        
        @BLEreport.emit 'BLEdata', BLEdata
      
      
      deviceConfigDef = require('./device-config-schema')
      
      @framework.deviceManager.registerDeviceClass('ClimaSens', {
        configDef: deviceConfigDef.ClimaSens,
        createCallback: (config, lastState) =>
          device = new ClimaSens(config, @, lastState)
          @addToScan config.address, device
          return device
      })
      
      @framework.deviceManager.on 'discover', (eventData) =>
          @framework.deviceManager.discoverMessage 'pimatic-climate-sensor', 'Scanning for sensors'
          @discoveredPeripherals = [];
          @discoverMode = true
          
          @BLEreport.on 'BLEdata', (BLEdata) =>
            if @discoverMode is true
              if BLEdata.address not in @discoveredPeripherals
                if not @devices[BLEdata.address]
                  if BLEdata.DataFlag == 0xFF
                    @discoveredPeripherals.push BLEdata.address

                    env.logger.debug 'Sensor %s found', BLEdata.address
                    config = {
                      class: 'ClimaSens',
                      address: BLEdata.address
                    }
                    @framework.deviceManager.discoveredDevice(
                      'pimatic-climasens', '[' + BLEdata.address + '] ', config
                    )
            else return

          setTimeout =>
            @discoverMode = false
          , 20000
      
    
    addToScan: (address, device) =>
      env.logger.debug 'Adding device %s', address
      @devices[address] = device

    removeFromScan: (address) =>
      env.logger.info 'Removing device %s', address
      if @devices[address]
        delete @devices[address]
        env.logger.info address, 'removed'
  
  
  class ClimaSens extends env.devices.Device
    
    constructor: (config, @plugin, lastState) ->
      if !@config || Object.keys(@config).length == 0
        @config = config
      if !@plugin
        @plugin = plugin
      
      @id = @config.id
      @name = @config.name
      @address = @config.address
      @interval = @config.interval
      
      @ONlight = @config.light
      @ONtemperature = @config.temperature
      @ONhumidity = @config.humidity
      @ONpressure = @config.pressure
      @ONbattery = @config.battery
      @ONcontact = @config.contact
      @ONpresence = @config.presence
      @ONbutton = @config.button
      
      if @ONlight is true
        @addAttribute('light', {
          description: 'The measured brightness'
          type: 'number'
          unit: 'lx'
          acronym: ' Light:'
        })
      if @ONtemperature is true
        @addAttribute('temperature', {
          description: 'The measured temperature'
          type: 'number'
          unit: '°C'
          acronym: ' Temp:'
        })
      if @ONhumidity is true
        @addAttribute('humidity', {
          description: 'The measured moisture level'
          type: 'number'
          unit: '%'
          acronym: ' Humidity:'
        })
      if @ONpressure is true
        @addAttribute('pressure', {
          description: 'Relative air pressure'
          type: 'number'
          unit: 'hPa'
          acronym: ' Pressure:'
        })
      if @ONbattery is true
        @addAttribute('battery', {
          description: 'Battery status'
          type: 'number'
          unit: 'V'
        acronym: ' Battery:'
        })
      if @ONcontact is true
        @addAttribute('contact', {
          description: 'Contact status'
          type: 'boolean'
          lables: ['closed', 'open']
          acronym: ' Contact:'
        })
      if @ONpresence is true
        @addAttribute('presence', {
          description: 'Presence of the device'
          type: 'boolean'
          lables: ['present', 'absent']
        })
      if @ONbutton is true
        @addAttribute('button', {
          description: 'button status'
          type: 'boolean'
          lables: ['true', 'false']
        })
      
      @_light = lastState?.light?.value or 0
      @_temperature = lastState?.temperature?.value or 0.0
      @_humidity = lastState?.humidity?.value or 0.0
      @_pressure = lastState?.pressure?.value or 0.0
      @_battery = lastState?.battery?.value or 0.0
      @_contact = lastState?.contact?.value or false
      @_button = @id
      
      @_presence = lastState?.presence?.value or false
      @_presenceTimeout = setTimeout @_resetPresence, @interval * 1000
      
      @plugin.BLEreport.on 'BLEdata', (BLEdata) =>
        if BLEdata.address == @address
          @_setPresence true
          @parseData BLEdata.manufacturingData
          env.logger.debug (BLEdata.address + " " + BLEdata.manufacturingData)
      
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
      
      @_contact = manufacturerData[14] & 1
      @emit 'contact', @_contact
      
      @_button = (manufacturerData[14] & 2) >> 1
      if @_button is 1
        @emit 'button', true
      
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
    getButton: -> Promise.resolve @_button
    getPresence: -> Promise.resolve @_presence

  
  env.devices.ClimaSens = ClimaSens
  
  return new ClimaSensPlugin
