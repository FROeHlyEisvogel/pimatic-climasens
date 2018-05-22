var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

module.exports = function(env) {
  var ClimaSens, ClimaSensPlugin, EventEmitter, Promise, events;
  Promise = env.require('bluebird');
  events = require('events');
  EventEmitter = require('events');
  ClimaSensPlugin = (function(superClass) {
    extend(ClimaSensPlugin, superClass);

    function ClimaSensPlugin() {
      this.removeFromScan = bind(this.removeFromScan, this);
      this.addToScan = bind(this.addToScan, this);
      this.init = bind(this.init, this);
      return ClimaSensPlugin.__super__.constructor.apply(this, arguments);
    }

    ClimaSensPlugin.prototype.init = function(app, framework, config1) {
      var deviceConfigDef, exec, spawn;
      this.framework = framework;
      this.config = config1;
      this.debug = this.config.debug;
      this.bluetoothInterface = this.config.bluetoothInterface || 'hci0';
      this.devices = [];
      this.discoverMode = false;
      this.discoveredPeripherals = [];
      exec = require('child_process').exec;
      spawn = require('child_process').spawn;
      exec('sudo hciconfig ' + this.bluetoothInterface + ' reset');
      setTimeout((function(_this) {
        return function() {
          env.logger.debug('Start scanner');
          return _this.hcitool_child = spawn('sudo', ['hcitool', '-i', _this.bluetoothInterface, 'lescan', '--passive', '--duplicates']);
        };
      })(this), 10);
      env.logger.debug('Start scanning');
      this.hcidump_child = spawn('sudo', ['hcidump', '-R', '-i', this.bluetoothInterface]);
      this.BLEreport = new EventEmitter;
      this.hcidump_child.stdout.on('data', (function(_this) {
        return function(data) {
          var BLEdata, rawCode, rawCodeInt, rawData;
          rawData = data.toString('utf8');
          rawData = rawData.replace(/\n|\r/g, "");
          rawData = rawData.replace(/ /g, "");
          rawData = rawData.replace(/>/g, "");
          rawCode = rawData.match(/.{1,2}/g);
          rawCodeInt = rawCode.map(function(num) {
            return parseInt(num, 16);
          });
          BLEdata = {
            address: rawCode[12] + ":" + rawCode[11] + ":" + rawCode[10] + ":" + rawCode[9] + ":" + rawCode[8] + ":" + rawCode[7],
            dataLength: rawCodeInt[17],
            DataFlag: rawCodeInt[18],
            companyID: rawCodeInt[19] | (rawCodeInt[20] << 8),
            manufacturingData: rawCodeInt.slice(19, 19 + rawCodeInt[17])
          };
          return _this.BLEreport.emit('BLEdata', BLEdata);
        };
      })(this));
      deviceConfigDef = require('./device-config-schema');
      this.framework.deviceManager.registerDeviceClass('ClimaSens', {
        configDef: deviceConfigDef.ClimaSens,
        createCallback: (function(_this) {
          return function(config, lastState) {
            var device;
            device = new ClimaSens(config, _this, lastState);
            _this.addToScan(config.address, device);
            return device;
          };
        })(this)
      });
      return this.framework.deviceManager.on('discover', (function(_this) {
        return function(eventData) {
          _this.framework.deviceManager.discoverMessage('pimatic-climate-sensor', 'Scanning for sensors');
          _this.discoveredPeripherals = [];
          _this.discoverMode = true;
          _this.BLEreport.on('BLEdata', function(BLEdata) {
            var config, ref;
            if (_this.discoverMode === true) {
              if (ref = BLEdata.address, indexOf.call(_this.discoveredPeripherals, ref) < 0) {
                if (!_this.devices[BLEdata.address]) {
                  if (BLEdata.DataFlag === 0xFF) {
                    _this.discoveredPeripherals.push(BLEdata.address);
                    env.logger.debug('Sensor %s found', BLEdata.address);
                    config = {
                      "class": 'ClimaSens',
                      address: BLEdata.address
                    };
                    return _this.framework.deviceManager.discoveredDevice('pimatic-climasens', '[' + BLEdata.address + '] ', config);
                  }
                }
              }
            } else {

            }
          });
          return setTimeout(function() {
            return _this.discoverMode = false;
          }, 20000);
        };
      })(this));
    };

    ClimaSensPlugin.prototype.addToScan = function(address, device) {
      env.logger.debug('Adding device %s', address);
      return this.devices[address] = device;
    };

    ClimaSensPlugin.prototype.removeFromScan = function(address) {
      env.logger.info('Removing device %s', address);
      if (this.devices[address]) {
        delete this.devices[address];
        return env.logger.info(address, 'removed');
      }
    };

    return ClimaSensPlugin;

  })(env.plugins.Plugin);
  ClimaSens = (function(superClass) {
    extend(ClimaSens, superClass);

    function ClimaSens(config, plugin1, lastState) {
      var ref, ref1, ref2, ref3, ref4, ref5, ref6;
      this.plugin = plugin1;
      this._resetPresence = bind(this._resetPresence, this);
      if (!this.config || Object.keys(this.config).length === 0) {
        this.config = config;
      }
      if (!this.plugin) {
        this.plugin = plugin;
      }
      this.id = this.config.id;
      this.name = this.config.name;
      this.address = this.config.address;
      this.interval = this.config.interval;
      this.ONlight = this.config.light;
      this.ONtemperature = this.config.temperature;
      this.ONhumidity = this.config.humidity;
      this.ONpressure = this.config.pressure;
      this.ONbattery = this.config.battery;
      this.ONcontact = this.config.contact;
      this.ONpresence = this.config.presence;
      this.ONbutton = this.config.button;
      if (this.ONlight === true) {
        this.addAttribute('light', {
          description: 'The measured brightness',
          type: 'number',
          unit: 'lx',
          acronym: ' Light:'
        });
      }
      if (this.ONtemperature === true) {
        this.addAttribute('temperature', {
          description: 'The measured temperature',
          type: 'number',
          unit: '°C',
          acronym: ' Temp:'
        });
      }
      if (this.ONhumidity === true) {
        this.addAttribute('humidity', {
          description: 'The measured moisture level',
          type: 'number',
          unit: '%',
          acronym: ' Humidity:'
        });
      }
      if (this.ONpressure === true) {
        this.addAttribute('pressure', {
          description: 'Relative air pressure',
          type: 'number',
          unit: 'hPa',
          acronym: ' Pressure:'
        });
      }
      if (this.ONbattery === true) {
        this.addAttribute('battery', {
          description: 'Battery status',
          type: 'number',
          unit: 'V',
          acronym: ' Battery:'
        });
      }
      if (this.ONcontact === true) {
        this.addAttribute('contact', {
          description: 'Contact status',
          type: 'boolean',
          lables: ['closed', 'open'],
          acronym: ' Contact:'
        });
      }
      if (this.ONpresence === true) {
        this.addAttribute('presence', {
          description: 'Presence of the device',
          type: 'boolean',
          lables: ['present', 'absent']
        });
      }
      if (this.ONbutton === true) {
        this.addAttribute('button', {
          description: 'button status',
          type: 'boolean',
          lables: ['true', 'false']
        });
      }
      this._light = (lastState != null ? (ref = lastState.light) != null ? ref.value : void 0 : void 0) || 0;
      this._temperature = (lastState != null ? (ref1 = lastState.temperature) != null ? ref1.value : void 0 : void 0) || 0.0;
      this._humidity = (lastState != null ? (ref2 = lastState.humidity) != null ? ref2.value : void 0 : void 0) || 0.0;
      this._pressure = (lastState != null ? (ref3 = lastState.pressure) != null ? ref3.value : void 0 : void 0) || 0.0;
      this._battery = (lastState != null ? (ref4 = lastState.battery) != null ? ref4.value : void 0 : void 0) || 0.0;
      this._contact = (lastState != null ? (ref5 = lastState.contact) != null ? ref5.value : void 0 : void 0) || false;
      this._button = this.id;
      this._presence = (lastState != null ? (ref6 = lastState.presence) != null ? ref6.value : void 0 : void 0) || false;
      this._presenceTimeout = setTimeout(this._resetPresence, this.interval * 1000);
      this.plugin.BLEreport.on('BLEdata', (function(_this) {
        return function(BLEdata) {
          if (BLEdata.address === _this.address) {
            _this._setPresence(true);
            _this.parseData(BLEdata.manufacturingData);
            return env.logger.debug(BLEdata.address + " " + BLEdata.manufacturingData);
          }
        };
      })(this));
      ClimaSens.__super__.constructor.call(this);
    }

    ClimaSens.prototype._resetPresence = function() {
      return this._setPresence(false);
    };

    ClimaSens.prototype._setPresence = function(value) {
      clearTimeout(this._resetPresenceTimeout);
      if (this._presence === true) {
        this._resetPresenceTimeout = setTimeout(this._resetPresence, this.interval * 1000);
      }
      if (this._presence === value) {
        return;
      }
      this._presence = value;
      return this.emit('presence', value);
    };

    ClimaSens.prototype.parseData = function(manufacturerData) {
      this._battery = ((manufacturerData[2] << 8) | manufacturerData[3]) / 1000;
      this.emit('battery', this._battery);
      this._light = (manufacturerData[6] << 8) | manufacturerData[7];
      this.emit('light', this._light);
      this._temperature = ((manufacturerData[8] << 8) | manufacturerData[9]) / 100;
      if (this._temperature > 327.68) {
        this._temperature = -655.36 + this._temperature;
      }
      this.emit('temperature', this._temperature);
      this._humidity = ((manufacturerData[10] << 8) | manufacturerData[11]) / 100;
      this.emit('humidity', this._humidity);
      this._pressure = ((manufacturerData[12] << 8) | manufacturerData[13]) / 10;
      this.emit('pressure', this._pressure);
      this._contact = manufacturerData[14] & 1;
      this.emit('contact', this._contact);
      this._button = (manufacturerData[14] & 2) >> 1;
      if (this._button === 1) {
        this.emit('button', true);
      }
      return env.logger.debug('temperature: %s °C , Light: %s lux , humidity: %s% , battery: %sV', this._temperature, this._light, this._humidity, this._battery);
    };

    ClimaSens.prototype.destroy = function() {
      this.plugin.removeFromScan(this.address);
      clearTimeout(this._resetPresenceTimeout);
      return ClimaSens.__super__.destroy.call(this);
    };

    ClimaSens.prototype.getTemperature = function() {
      return Promise.resolve(this._temperature);
    };

    ClimaSens.prototype.getLight = function() {
      return Promise.resolve(this._light);
    };

    ClimaSens.prototype.getHumidity = function() {
      return Promise.resolve(this._humidity);
    };

    ClimaSens.prototype.getPressure = function() {
      return Promise.resolve(this._pressure);
    };

    ClimaSens.prototype.getBattery = function() {
      return Promise.resolve(this._battery);
    };

    ClimaSens.prototype.getContact = function() {
      return Promise.resolve(this._contact);
    };

    ClimaSens.prototype.getButton = function() {
      return Promise.resolve(this._button);
    };

    ClimaSens.prototype.getPresence = function() {
      return Promise.resolve(this._presence);
    };

    return ClimaSens;

  })(env.devices.Device);
  env.devices.ClimaSens = ClimaSens;
  return new ClimaSensPlugin;
};
