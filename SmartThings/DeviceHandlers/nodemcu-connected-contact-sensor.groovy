/**
 *  NodeMCU Cloud Connected Contact Sensor
 *
 *  Copyright 2017 Nate Clark | @heythisisnate
 *  
 *  A desccription of this project and documentaion can be found at:
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
  definition (name: "NodeMCU Connected Contact Sensor", namespace: "heythisisnate", author: "Nate") {
    capability "Contact Sensor"
    capability "Sensor"
    capability "Refresh"
    command "open"
    command "close"
    command "updateLanIp"
  }

  tiles {
    standardTile("contact", "device.contact", width: 2, height: 2) {
      state "open", label: '${name}', icon: "st.contact.contact.open", backgroundColor: "#ffa81e"
      state "closed", label: '${name}', icon: "st.contact.contact.closed", backgroundColor: "#79b821"
    }

    standardTile("refresh", "device.contact", width: 1, height: 1, decoration: "flat") {
      state "default", label: '', action:"refresh.refresh",
      icon:"st.secondary.refresh"
    }

    main "contact"
    details(["contact","refresh"])
  }
}

def parse(String data) {
  log.debug data
}

def open() {
  sendEvent(name: "contact", value: "open")
}

def close() {
  sendEvent(name: "contact", value: "closed")
}

def updateLanIp(value) {
  device.deviceNetworkId = ipToHex(value + ":80")
}

def refresh() {
  def result = new physicalgraph.device.HubAction(
    method: "GET",
    path: "/" + device.id,
    headers: [
      HOST: hexToIp(device.deviceNetworkId)
    ]
  )
  return result
}

// accepts a IP:PORT string and converts it to a hex identifier
// for setting the SmartThings deviceNetworkId
private String ipToHex(String ip) {
  def parts 	= ip.tokenize(':')
  def address = parts[0]
  def port 		= parts[1]
  def octets 	= address.tokenize('.')
  def hex 		= ""

  octets.each {
    hex = hex + Integer.toHexString(it as Integer).toUpperCase()
  }
  hex = hex + ":" + Integer.toHexString(port as Integer).toUpperCase().padLeft(4,'0')
  return hex
}

private Integer hexToInt(String hex) {
  return Integer.parseInt(hex,16)
}

// accepts a hex formatted deviceNetworkId and converts it to an IP:PORT string
private String hexToIp(String hex) {
  def address = [hexToInt(hex[0..1]), hexToInt(hex[2..3]), hexToInt(hex[4..5]), hexToInt(hex[6..7])].join(".")
  def port = hexToInt(hex[9..12])
  return address + ":" + port
}
