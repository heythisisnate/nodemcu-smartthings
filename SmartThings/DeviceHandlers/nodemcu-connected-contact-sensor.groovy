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
    attribute "lanIp", "string"
    command "open"
    command "close"
    command "updateLanIp"
  }

  tiles {
    standardTile("contact", "device.contact", width: 2, height: 2) {
      state "open", label: '${name}', icon: "st.contact.contact.open", backgroundColor: "#ffa81e"
      state "closed", label: '${name}', icon: "st.contact.contact.closed", backgroundColor: "#79b821"
    }

    main "contact"
    details "contact"
  }
}

def open() {
  sendEvent(name: "contact", value: "open")
}

def close() {
  sendEvent(name: "contact", value: "closed")
}

def updateLanIp(value) {
  sendEvent(name: "lanIp", value: value)
}
