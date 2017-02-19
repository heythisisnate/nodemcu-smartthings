/**
 *  NodeMCU Cloud Connected Smoke Detector
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
  definition (name: "NodeMCU Connected Smoke Detector", namespace: "heythisisnate", author: "Nate") {
    capability "Smoke Detector"
    command "open"
    command "close"
  }

  tiles {
    standardTile("smoke", "device.smoke", width: 2, height: 2) {
      state "detected", label: '${name}', icon: "st.alarm.smoke.smoke"
      state "clear", label: '${name}', icon: "st.alarm.smoke.clear"
    }

    main "smoke"
    details "smoke"
  }
}

def open() {
  sendEvent(name: "smoke", value: "detected")
}

def close() {
  sendEvent(name: "smoke", value: "clear")
}