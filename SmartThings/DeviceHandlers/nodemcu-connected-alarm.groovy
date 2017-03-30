/**
 *  NodeMCU Cloud Connected Alarm
 *
 *  Copyright 2017 Nate Clark | @heythisisnate
 *
 *  A description of this project and documentaion can be found at:
 *  https://github.com/heythisisnate/nodemcu-smartthings-sensors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License. You may obtain a copy of the License at:
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
 *  on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
 *  for the specific language governing permissions and limitations under the License.
 *
 */

metadata {
  definition (name: "NodeMCU Connected Alarm", namespace: "heythisisnate", author: "Nate Clark") {
    capability "Alarm"
    command "sync"
  }

  tiles {
    standardTile("alarm", "device.alarm", decoration: "flat") {
      state "off", label:'${name}', action:"alarm.both", icon:"st.alarm.alarm.alarm"
      state "siren", label:'${name} on', action:"alarm.off", icon:"st.alarm.alarm.alarm", backgroundColor: "#ffa81e"
      state "strobe", label:'${name} on', action:"alarm.off", icon:"st.alarm.alarm.alarm", backgroundColor: "#ffa81e"
      state "both", label:'ALARM!', action:"alarm.off", icon:"st.alarm.alarm.alarm", backgroundColor: "#e86d13"
    }
    standardTile("siren", "device.alarm", inactiveLabel: false, decoration: "flat") {
      state "default", label:'', action:"alarm.siren", icon:"st.secondary.siren"
      state "siren", label:'', action:"alarm.off", icon:"st.secondary.siren", backgroundColor: "#ffa81e"
    }
    standardTile("strobe", "device.alarm", inactiveLabel: false, decoration: "flat") {
      state "default", label:'', action:"alarm.strobe", icon:"st.secondary.strobe"
      state "strobe", label:'', action:"alarm.off", icon:"st.secondary.strobe", backgroundColor: "#ffa81e"
    }
  }
  main "alarm"
  details "alarm", "siren", "strobe"
}

def both() {
  httpAction("both")
}

def siren() {
  httpAction("siren")
}

def strobe() {
  httpAction("strobe")
}

def off() {
  httpAction("off")
}

// parse events into attributes
def parse(String description) {
  def msg = parseLanMessage(description)
  createEvent(name: "alarm", value: msg.json?.alarm)
}

def sync(ip, port, mac) {
  def existingIp = getDataValue("ip")
  def existingPort = getDataValue("port")
  def existingMac = getDataValue("mac")
  def updated = false
  if (ip && ip != existingIp) {
    updateDataValue("ip", ip)
    updated = true
  }
  if (port && port != existingPort) {
    updateDataValue("port", port)
    updated = true
  }
  if (mac && mac != existingMac) {
    updateDataValue("mac", mac)
    updated = true
  }
  if (updated) {
    device.deviceNetworkId = ipToHex(ip, port)
  }
}

// accepts an IP and PORT string and converts it to a hex identifier
// for setting the SmartThings deviceNetworkId
private String ipToHex(String address, String port) {
  def octets 	= address.tokenize('.')
  def hex 		= ""

  octets.each {
    hex = hex + Integer.toHexString(it as Integer).toUpperCase()
  }
  hex = hex + ":" + Integer.toHexString(port as Integer).toUpperCase().padLeft(4,'0')
  return hex
}

private httpAction(action) {
  def result = new physicalgraph.device.HubAction(
    method: "POST",
    path: "/" + device.id + "/" + action,
    headers: [
      HOST: getDataValue("ip") + ":" + getDataValue("port")
    ]
  )
  log.debug result
  return result
}
