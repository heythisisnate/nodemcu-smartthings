/**
 *  NodeMCU Cloud Connected Motion Sensor
 *
 *  Copyright 2017 Nate Clark | @heythisisnate
 *  
 *  A description of this project and documentation can be found at:
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
  definition (name: "NodeMCU Connected Motion Sensor", namespace: "heythisisnate", author: "Nate") {
    capability "Motion Sensor"
    capability "Sensor"
    command "open"
    command "close"
  }

  tiles {
    standardTile("motion", "device.motion", width: 2, height: 2) {
      state "active", label: '${name}', icon: "st.motion.motion.active", backgroundColor: "#00a0dc"
      state "inactive", label: '${name}', icon: "st.motion.motion.inactive", backgroundColor: "#ffffff"
    }

    main "motion"
    details "motion"
  }
}

def open() {
  sendEvent(name: "motion", value: "active")
}

def close() {
  sendEvent(name: "motion", value: "inactive")
}
